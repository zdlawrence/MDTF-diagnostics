load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"

begTime = get_cpu_time()

DIR_in1=getenv("OUTDIR")
DIR_in2=getenv("TMPDIR")
DIR_out=getenv("TMPDIR")
time_var = getenv("time_var")
lat_var = getenv("lat_var")

model=getenv("CASENAME")
yymm=getenv("YYYYMM")
yyyy=getenv("YYYY")

ncs1 = model+"."+lat_var+"_vo.fx.nc"
ncs2 = model+".trans_"+yyyy+".yr.nc"

nc=DIR_in1+ncs1
print("Loading ... "+nc)
fin1 = addfile(nc,"r")
lat  = fin1->$lat_var$

nc=DIR_in2+ncs2
print("Loading ... "+nc)
fin2 = addfile(nc,"r")
time = fin2->$time_var$
theta= fin2->theta
salt = fin2->salt

tmt=dimsizes(time)
zmt=dimsizes(theta)
smt=dimsizes(salt)
jmt=dimsizes(lat)

moc = new((/tmt,zmt,jmt,1/),float,1e20)

do t=0,tmt-1
   vmo  = fin2->trans(t,:,:,:)
;   print("Load files time: " + (get_cpu_time() - begTime))
do j=0,jmt-1
   if(all(ismissing(vmo(:,:,j))))then
      continue
      ;;; kick out No-Atlantic latitudes
   end if
   do z=0,zmt-1
      if(.not.all(ismissing(vmo(z,:,j))))then
         c=z
      end if
   end do
   ;;; c is the warmest grid at this latitudes
do z=0,c
   moc(t,z,j,0)=sum(-vmo(0:z,:,j))
end do ;;; z loop
end do ;;; j loop
end do ;;; t loop

;print("Compute Moc time: " + (get_cpu_time() - begTime))

theta@long_name="temperature"
theta@units    ="Deg C"
;theta@positive ="down"
lon =0.0
lon@long_name="longitude"
lon@units    ="degree_east"

moc!0  = "time"
moc!1  = "lev"
moc!2  = "lat"
moc!3  = "lon"
moc&time = time
moc&lev  = theta
moc&lat  = lat
moc&lon  = lon
moc@long_name       = "moc"
moc@units           = "Sv"

;printVarSummary(moc)

idx=new(zmt,"integer",-9999)
tmp=moc(:,0,:,0)
;printVarSummary(tmp)
tmp=tmp@_FillValue

tmp@long_name="moc value"
tmp@units="Sv"
moc_max=tmp
moc_000=tmp
moc_min=tmp

tmp@long_name="moc theta"
tmp@units="m"
the_max=tmp
the_000=tmp
the_min=tmp
delete(tmp)

ttt=theta(::-1)
zdx=minind(abs(ttt-10.0))

do y=0,tmt-1
do j=0,jmt-1
   var=moc(y,::-1,j,0)
   tmp=var(zdx:zmt-1)
   if(all(ismissing(tmp)))then
     continue
     ;;; kick out Non-Atlantic latitudes
   end if
  ;------------------------------------ locate bottom c -----------------------------------------------
   z=zmt-1
   do while(ismissing(var(z)))
      z=z-1
   end do
   if(z.lt.zdx)then
      continue
      ;;; kick out too shallow 
   end if
   c=z
  ;------------------------------------ locate maximum a ----------------------------------------------
  a=zdx+maxind(tmp)
  if(var(a).le.0 .or. a.eq.c)then
    continue
  end if
  ; at least 2 sea grids
  moc_max(y,j) = (/var(a)/)
  the_max(y,j) = (/ttt(a)/)
  delete(tmp)
  ;------------------------------------ locate zeros o ------------------------------------------------
  tmp=var(a:c)
  o=c
  do k=a,c-1
     if(var(k)*var(k+1).lt.0)then
        o=k
        break
     end if
  end do
  moc_000(y,j) = (/var(o)/)
  the_000(y,j) = (/ttt(o)/)
  delete(tmp)
  ;------------------------------------ locate minimum b ----------------------------------------------
  if(o.ge.c)then
     continue
  end if
  ; at least 2 sea grids
  tmp=var(o:c)
  b=o+minind(tmp)
  moc_min(y,j) = (/var(b)/)
  the_min(y,j) = (/ttt(b)/)
  delete(tmp)
end do  
end do  
;=============================================================================
     system("rm "+DIR_out+model+".AMOCT_qts_"+yyyy+".yr.nc")
fout    = addfile(DIR_out+model+".AMOCT_qts_"+yyyy+".yr.nc","c")
fout->moc = moc
fout->moc_max = moc_max
fout->moc_000 = moc_000
fout->moc_min = moc_min
fout->the_max = the_max
fout->the_000 = the_000
fout->the_min = the_min

;print("Save files time: " + (get_cpu_time() - begTime))
