load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"

begTime = get_cpu_time()
sigs=(/30.1, 30.3, 30.5, 30.7, 30.9, 31.1, 31.3, 31.5, 31.7, 31.9, 32.1, 32.3, 32.5, 32.7, 32.9, 33.1, 33.3, 33.5, 33.7, 33.9, 34.1, 34.3, 34.5, 34.7, 34.9, 35.1, 35.3, 35.5, 35.7, 35.9, 36.01, 36.03, 36.05, 36.07, 36.09, 36.11, 36.13, 36.15, 36.17, 36.19, 36.21, 36.23, 36.25, 36.27, 36.29, 36.31, 36.33, 36.35, 36.37, 36.39, 36.41, 36.43, 36.45, 36.47, 36.49, 36.51, 36.53, 36.55, 36.57, 36.59, 36.61, 36.63, 36.65, 36.67, 36.69, 36.71, 36.73, 36.75, 36.77, 36.79, 36.81, 36.83, 36.85, 36.87, 36.89, 36.91, 36.93, 36.95, 36.97, 36.99, 37.01, 37.03, 37.05, 37.07, 37.09, 37.11, 37.13, 37.15, 37.17, 37.19, 37.21, 37.23, 37.25, 37.27, 37.29, 37.31, 37.33, 37.35, 37.37, 37.39/)
sig_bnds=(/30.0, 30.2, 30.4, 30.6, 30.8, 31, 31.2, 31.4, 31.6, 31.8, 32, 32.2, 32.4, 32.6, 32.8, 33, 33.2, 33.4, 33.6, 33.8, 34, 34.2, 34.4, 34.6, 34.8, 35, 35.2, 35.4, 35.6, 35.8, 36, 36.02, 36.04, 36.06, 36.08, 36.1, 36.12, 36.14, 36.16, 36.18, 36.2, 36.22, 36.24, 36.26, 36.28, 36.3, 36.32, 36.34, 36.36, 36.38, 36.4, 36.42, 36.44, 36.46, 36.48, 36.5, 36.52, 36.54, 36.56, 36.58, 36.6, 36.62, 36.64, 36.66, 36.68, 36.7, 36.72, 36.74, 36.76, 36.78, 36.8, 36.82, 36.84, 36.86, 36.88, 36.9, 36.92, 36.94, 36.96, 36.98, 37, 37.02, 37.04, 37.06, 37.08, 37.1, 37.12, 37.14, 37.16, 37.18, 37.2, 37.22, 37.24, 37.26, 37.28, 37.3, 37.32, 37.34, 37.36, 37.38, 37.4/)

DIR_in0=getenv("OUTDIR")
DIR_in1=getenv("OUTDIR")
DIR_in2=getenv("TMPDIR")
DIR_out=getenv("TMPDIR")
model=getenv("CASENAME")
yymm=getenv("YYYYMM")
yyyy=getenv("YYYY")
year0=getenv("YEAR0")

time_var = getenv("time_coord")
lat_var = getenv("lat_coord")

ncs0 = "TMP.sigma2.fx.nc"
ncs1 = model+"."+lat_var+"_vo.fx.nc"
ncs2 = model+".trans_"+yyyy+".yr.nc"

year=year0

fin0 = addfile(DIR_in0+ncs0,"r")
sig = fin0->sig2(0,:,:,0)
sig = sig - 1000.

fin1 = addfile(DIR_in1+ncs1,"r")
lat  = fin1->$lat_var$

fin2 = addfile(DIR_in2+ncs2,"r")
time = fin2->$time_var$
theta= fin2->theta
salt = fin2->salt

tmt=dimsizes(time)
zmt=dimsizes(theta)
smt=dimsizes(salt)
jmt=dimsizes(lat)
rmt = dimsizes(sigs)

moc = new((/tmt,100,jmt,1/),float,1e20)

do t=0,tmt-1
   vmo  = fin2->trans(t,:,:,:)
   tim = time(t)
   rrr=sig
do j=0,jmt-1
   vvv=vmo(:,:,j)
   rrr=where(ismissing(vvv),sig@_FillValue,sig)
   r0=max(rrr)
   if(ismissing(r0))then
      continue
   end if
;   print(""+r0)
   r=1
   do while(r0.gt.sig_bnds(r).and.r.lt.rmt)
      r=r+1
   end do
   c=r-1
   tmp=vvv
do r=0,c
   tmp=where(sig.lt.sig_bnds(r+1),vvv,vvv@_FillValue)
   moc(t,r,j,0)=sum(tmp)
end do ;;; r loop
   delete(vvv)
   delete(tmp)
end do ;;; j loop
end do ;;; t loop

;print("Compute Moc time: " + (get_cpu_time() - begTime))

sigs@long_name="sig2"
sigs@units    ="kg/m^3"
sigs@positive ="down"
lon =0.0
lon@long_name="longitude"
lon@units    ="degree_east"

moc!0  = "time"
moc!1  = "lev"
moc!2  = "lat"
moc!3  = "lon"
moc&time = time
moc&lev  = sigs
moc&lat  = lat
moc&lon  = lon
moc@long_name       = "moc"
moc@units           = "Sv"

;printVarSummary(moc)

idx=new(rmt,"integer",-9999)
tmp=moc(:,0,:,0)
tmp=tmp@_FillValue

tmp@long_name="moc value"
tmp@units="Sv"
moc_max=tmp
moc_000=tmp
moc_min=tmp

tmp@long_name="moc sigs"
tmp@units="m"
sig_max=tmp
sig_000=tmp
sig_min=tmp
delete(tmp)

if(model .eq. "MIROC-ESM" )then
   rdx=minind(abs(sigs-36.1))
else   
   rdx=minind(abs(sigs-35.5))
end if   

do y=0,tmt-1
do j=0,jmt-1
   var=moc(y,:,j,0)
   tmp=var(rdx:rmt-1)
   if(all(ismissing(tmp)))then
     continue
     ;;; kick out Non-Atlantic latitudes
   end if
  ;------------------------------------ locate bottom c -----------------------------------------------
   r=rmt-1
   do while(ismissing(var(r)))
      r=r-1
   end do
   if(r.lt.rdx)then
      continue
      ;;; kick out too shallow 
   end if
   c=r
  ;------------------------------------ locate maximum a ----------------------------------------------
  a=rdx+maxind(tmp)
  if(var(a).le.0 .or. a.eq.c)then
    continue
  end if
  ; at least 2 sea grids
  moc_max(y,j) = (/var(a)/)
  sig_max(y,j) = (/sig_bnds(a+1)/)
  delete(tmp)
  ;------------------------------------ locate zeros o ------------------------------------------------
  tmp=var(a:c)
  o=c
  do k=a,c-1
     if(var(k)*var(k+1).lt.0)then
        o=k
        if(abs(var(k)).gt.abs(var(k+1)))then
           o=k+1
        end if        
        break
     end if
  end do
  moc_000(y,j) = (/var(o)/)
  sig_000(y,j) = (/sig_bnds(o+1)/)
  delete(tmp)
  ;------------------------------------ locate minimum b ----------------------------------------------
  if(o.ge.c)then
     continue
  end if
  ; at least 2 sea grids
  tmp=var(o:c)
  b=o+minind(tmp)
  moc_min(y,j) = (/var(b)/)
  sig_min(y,j) = (/sig_bnds(b+1)/)
  delete(tmp)
end do ;;; lat  loop
end do ;;; year loop
;=============================================================================
fout    = addfile(DIR_out+model+".AMOC_qts_"+yyyy+".yr.nc","c")
fout->moc = moc
fout->moc_max = moc_max
fout->moc_000 = moc_000
fout->moc_min = moc_min
fout->sig_max = sig_max
fout->sig_000 = sig_000
fout->sig_min = sig_min

;print("Save files time: " + (get_cpu_time() - begTime))
