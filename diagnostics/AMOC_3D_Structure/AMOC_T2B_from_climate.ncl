load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"

begTime = get_cpu_time()

DIR_in0=getenv("OUTDIR")
DIR_in1=getenv("OUTDIR")
DIR_in2=getenv("OUTDIR")
DIR_out=getenv("OUTDIR")

vmo_var = getenv("vmo_var")
bas_var = getenv("bas_var")
lat_var = getenv("lat_coord")
lev_bnds_var = getenv("lev_bnds_var")

model=getenv("CASENAME")
yymm=getenv("YYYYMM")
yyyy=getenv("YYYY")

ncs0 = model+".INDEX_vo.fx.nc"
ncs1 = model+"."+lat_var+"_vo.fx.nc"
ncs2 = model+"."+vmo_var+".clim.nc"

print("Loading ... "+ncs0)
print("Loading ... "+ncs1)
print("Loading ... "+ncs2)

fin0 = addfile(DIR_in0+ncs0,"r")
bas = fin0->$bas_var$

fin1 = addfile(DIR_in1+ncs1,"r")
lat  = fin1->$lat_var$

temp = bas
temp = where(bas.eq.2, bas, bas@_FillValue)

vit = dim_sum_n_Wrap(temp,2)
delete(temp)

fin2 = addfile(DIR_in2+ncs2,"r")
lev2 = fin2->$lev_bnds_var$
vmo  = fin2->$vmo_var$
if(max(vmo(0:1,:,:)).gt.1e7)then
   vmo  = vmo / 1e9
else if(max(vmo(0:1,:,:)).gt.1e4)then  
   vmo  = vmo / 1e6
end if
end if

;print("Load files time: " + (get_cpu_time() - begTime))

time=0.0
num_tim = 1
num_lev = dimsizes(vmo(:,0,0))
num_lat = dimsizes(vmo(0,:,0))

vmo_temp = vmo
vmo_temp = where(bas.eq.2,vmo,vmo@_FillValue)
delete(vmo)

moc = new((/num_tim,num_lev,num_lat,1/),float,-1.e30)

  psai_JK       = dim_sum_n_Wrap(vmo_temp,2)
  psai_JK_accum = new((/num_tim,num_lev,num_lat/),float,-1.e30)
  psai_JK_accum = 0.
;=============================================================================
  do k=0,num_lev-1
     psai_JK_accum(0,k,:) = (/dim_sum_n_Wrap(psai_JK(0:k,:),0)/)
  end do
;=============================================================================
  delete(psai_JK)

  do t=0,num_tim-1
     psai_JK_accum(t,:,:) = where(ismissing(vit), psai_JK_accum@_FillValue, psai_JK_accum(t,:,:))
  end do

;=============================================================================
 moc(:,:,:,0)=(/psai_JK_accum/)
;=============================================================================
;print("Compute Moc time: " + (get_cpu_time() - begTime))

moc!0  = "time"
moc!1  = "lev"
moc!2  = "lat"
moc!3  = "lon"
moc&time = time
moc&lev  = lev2(0:num_lev-1,1)
moc&lat  = lat
moc&lon  = 1
moc@long_name       = "moc"
moc&time@long_name  = "time"
moc&lev@long_name   = "Depth (m)"
moc&lat@long_name   = "latitude"
moc&lon@long_name   = "longitude"
moc@units           = "Sv"
moc&time@units      = "days since 1850-01-01 00:00"
moc&time@calendar   = "standard"
moc&lev@units       = "m"
moc&lat@units       = "degree_north"
moc&lon@units       = "1"

;printVarSummary(moc)
lev=tofloat(lev2(0:num_lev-1,1))
kdx=minind(abs(lev-500.))
idx=new(num_lev,"integer",-9999)
tmp=moc(:,0,:,0)
tmp=tmp@_FillValue
tmp@long_name="moc value"
tmp@units="Sv"
moc_max=tmp
moc_000=tmp
moc_min=tmp
tmp@long_name="moc depth"
tmp@units="m"
dep_max=tmp
dep_000=tmp
dep_min=tmp
delete(tmp)

do y=0,num_tim-1
do j=0,num_lat-1
   var=moc(y,:,j,0)
   tmp=var(kdx:num_lev-1)
   if(all(ismissing(tmp)))then
     continue
   end if
  ;------------------------------------ locate bottom c -----------------------------------------------
   idx=where(ismissing(var),0,1)
   c=sum(idx)
   c=c-1
  ;------------------------------------ locate maximum a ----------------------------------------------
  a=kdx+maxind(tmp)
  if(var(a).le.0 .or. a.eq.c)then
    continue
  end if
  ; at least 2 sea grids
  moc_max(y,j) = (/var(a)/)
  dep_max(y,j) = (/lev(a)/)
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
  dep_000(y,j) = (/lev(o)/)
  delete(tmp)
  ;------------------------------------ locate minimum b ----------------------------------------------
  if(o.ge.c)then
     continue
  end if
  ; at least 2 sea grids
  tmp=var(o:c)
  b=o+minind(tmp)
  moc_min(y,j) = (/var(b)/)
  dep_min(y,j) = (/lev(b)/)
  delete(tmp)
end do  
end do  
;=============================================================================
     system("rm "+DIR_out+model+".AMOC_T2B.clim.nc")
fout    = addfile(DIR_out+model+".AMOC_T2B.clim.nc","c")
fout->moc = moc
fout->moc_max = moc_max
fout->moc_000 = moc_000
fout->moc_min = moc_min
fout->dep_max = dep_max
fout->dep_000 = dep_000
fout->dep_min = dep_min

;print("Save files time: " + (get_cpu_time() - begTime))
