load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"

begTime = get_cpu_time()

DIR_in1=getenv("OUTDIR")
DIR_in2=getenv("TMPDIR")
DIR_out=getenv("TMPDIR")
time_var = getenv("time_coord")
lat_var = getenv("lat_coord")

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

moc = new((/tmt,smt,jmt,1/),float,1e20)

do t=0,tmt-1
   vmo  = fin2->trans(t,:,:,:)
;   print("Load files time: " + (get_cpu_time() - begTime))
do j=0,jmt-1
   if(all(ismissing(vmo(:,:,j))))then
      continue
      ;;; kick out No-Atlantic latitudes
   end if
   do s=0,smt-1
      if(.not.all(ismissing(vmo(:,s,j))))then
         c=s
      end if
   end do
   ;;; c is the Freshest grid at this latitudes
do s=0,c
   moc(t,s,j,0)=sum(-vmo(:,0:s,j))
end do ;;; z loop
end do ;;; j loop
end do ;;; t loop

;print("Compute Moc time: " + (get_cpu_time() - begTime))

salt@long_name="Salinity"
salt@units    ="psu"
;salt@positive ="down"
lon =0.0
lon@long_name="longitude"
lon@units    ="degree_east"

moc!0  = "time"
moc!1  = "lev"
moc!2  = "lat"
moc!3  = "lon"
moc&time = time
moc&lev  = salt
moc&lat  = lat
moc&lon  = lon
moc@long_name       = "moc"
moc@units           = "Sv"

;printVarSummary(moc)

idx=new(smt,"integer",-9999)
tmp=moc(:,0,:,0)
;printVarSummary(tmp)
tmp=tmp@_FillValue

tmp@long_name="moc value"
tmp@units="Sv"
moc_max=tmp
moc_000=tmp
moc_min=tmp

tmp@long_name="moc salt"
tmp@units="m"
sal_max=tmp
sal_000=tmp
sal_min=tmp
delete(tmp)

sss=salt(::-1)
sdx=minind(abs(sss-35.0))

do y=0,tmt-1
do j=0,jmt-1
   var=moc(y,::-1,j,0)
   tmp=var(sdx:smt-1)
   if(all(ismissing(tmp)))then
     continue
     ;;; kick out Non-Atlantic latitudes
   end if
  ;------------------------------------ locate bottom c -----------------------------------------------
   s=smt-1
   do while(ismissing(var(s)))
      s=s-1
   end do
   if(s.lt.sdx)then
      continue
      ;;; kick out too shallow 
   end if
   c=s
  ;------------------------------------ locate maximum a ----------------------------------------------
  a=sdx+maxind(tmp)
  if(var(a).le.0 .or. a.eq.c)then
    continue
  end if
  ; at least 2 sea grids
  moc_max(y,j) = (/var(a)/)
  sal_max(y,j) = (/sss(a)/)
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
  sal_000(y,j) = (/sss(o)/)
  delete(tmp)
  ;------------------------------------ locate minimum b ----------------------------------------------
  if(o.ge.c)then
     continue
  end if
  ; at least 2 sea grids
  tmp=var(o:c)
  b=o+minind(tmp)
  moc_min(y,j) = (/var(b)/)
  sal_min(y,j) = (/sss(b)/)
  delete(tmp)
end do ;;; lat  loop
end do ;;; year loop
;=============================================================================
     system("rm "+DIR_out+model+".AMOCS_qts_"+yyyy+".yr.nc")
fout    = addfile(DIR_out+model+".AMOCS_qts_"+yyyy+".yr.nc","c")
fout->moc = moc
fout->moc_max = moc_max
fout->moc_000 = moc_000
fout->moc_min = moc_min
fout->sal_max = sal_max
fout->sal_000 = sal_000
fout->sal_min = sal_min

;print("Save files time: " + (get_cpu_time() - begTime))
