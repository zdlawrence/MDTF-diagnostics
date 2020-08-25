load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"

DIR_in0=getenv("MONDIR")
DIR_in1=getenv("FIXDIR")
DIR_in3=getenv("DIR_IN3")
DIR_out=getenv("OUTDIR")

thetao_var = getenv("thetao_var")
so_var = getenv("so_var")
vo_var = getenv("VAR0")
time_var = getenv("time_coord")
lev_var = getenv("lev_coord")
lat_var = getenv("lat_coord")
lon_var = getenv("lon_coord")
time_bnds_var = getenv("time_bnds_var")
lev_bnds_var = getenv("lev_bnds_var")
deptho_var = getenv("deptho_var")
thkcello_var = getenv("thkcello_var")

model=getenv("CASENAME")
yymm=getenv("YYYYMM")
yyyy=getenv("YYYY")
deptho_nc=getenv("DEPTHO")
thkcello_nc=getenv("THKCELLO")

ncs0 = model+"."+vo_var+".mon.nc"
ncs1 = deptho_nc
ncs3 = thkcello_nc

setfileoption("nc","Format","LargeFile")

fin0 = addfile(DIR_in0+ncs0,"r")
fin1 = addfile(DIR_in1+ncs1,"r")

tim0 = fin0->$time_var$
num_tim=dimsizes(tim0)
if (isfilepresent(DIR_in3+ncs3)) then
fin3 = addfile(DIR_in3+ncs3,"r")
if (isfilevar(fin3, time_var)) then
  tim3 = fin3->$time_var$
  num_tim=min((/dimsizes(tim0),dimsizes(tim3)/))
end if
end if

vo  = fin0->$vo_var$(0:num_tim-1,:,:,:)
;----------------------------------------------------------------------------------------------------
fNames = getfilevarnames(fin0)
numf=dimsizes(fNames)
   
var=fin0->$vo_var$(0,0:1,0:1,0:1)
vNames=getVarDimNames(var)
delete(var)
   
numv=dimsizes(vNames)
   
nums=numf-numv-1
Names=fNames(0:nums)
Names=""
n=0 
do v=0,numf-1
   vvv=fin0->$fNames(v)$!0
   if(all( vNames.ne.fNames(v)) .and. fNames(v).ne.vo_var .and. vvv.ne."time")then
      Names(n)=fNames(v)
      n=n+1
   end if
end do

;----------------------------------------------------------------------------------------------------

deptho=fin1->$deptho_var$
deptho=abs(deptho)

tim      = dble2flt(fin0->$time_var$(0:num_tim-1))
;tim_bnds = dble2flt(fin0->$time_bnds_var$(0:num_tim-1,:))

lev      = dble2flt(fin0->$lev_var$)
lev_bnds = dble2flt(fin0->$lev_bnds_var$)
lev      = abs(lev)
lev_bnds = abs(lev_bnds)

if ( lev(0) .gt. lev(1) )then
   lev = lev(::-1)
   lev_bnds = lev_bnds(::-1,:)
   vo = vo(:,::-1,:,:)
end if

lat0     = dble2flt(fin0->$lat_var$)

lon0     = dble2flt(fin0->$lon_var$)     

num_tim = dimsizes(vo(:,0,0,0))
num_lev = dimsizes(vo(0,:,0,0))
num_lat = dimsizes(vo(0,0,:,0))
num_lon = dimsizes(vo(0,0,0,:))

if(dimsizes(dimsizes(lat0)).eq.1)then
   lat1=conform_dims( (/num_lat,num_lon/), lat0, (/0/) )
   lon1=conform_dims( (/num_lat,num_lon/), lon0, (/1/) )
else
   lat1=lat0   
   lon1=lon0   
end if   

lat2=lat1
lon2=lon1

lat2(:,0:num_lon-2)=lat1(:,1:num_lon-1)
lon2(:,0:num_lon-2)=lon1(:,1:num_lon-1)
lat2(:,num_lon-1)=lat1(:,0)
lon2(:,num_lon-1)=lon1(:,0)
dx_tmp=gc_latlon(lat1,lon1,lat2,lon2,2,3)
dx=lat1
dx(:,0)=(dx_tmp(:,0)+dx_tmp(:,num_lon-1))/2.
dx(:,1:num_lon-1)=(dx_tmp(:,0:num_lon-2)+dx_tmp(:,1:num_lon-1))/2.
dx_conform = conform_dims( (/num_tim,num_lev,num_lat,num_lon/), dx, (/2,3/) )

lat2(0:num_lat-2,:)=lat1(1:num_lat-1,:)
lon2(0:num_lat-2,:)=lon1(1:num_lat-1,:)
dy_tmp=gc_latlon(lat1(0:num_lat-2,:),lon1(0:num_lat-2,:),lat2(0:num_lat-2,:),lon2(0:num_lat-2,:),2,3)

dy=lat1
dy(0,:)=(/dy_tmp(0,:)/)
dy(num_lat-1,:)=(/dy_tmp(num_lat-2,:)/)
dy(1:num_lat-2,:)=(dy_tmp(0:num_lat-3,:)+dy_tmp(1:num_lat-2,:))/2.
dy_conform = conform_dims( (/num_tim,num_lev,num_lat,num_lon/), dy, (/2,3/) )

dz = dble2flt(lev)

dz = lev_bnds(:,1) - lev_bnds(:,0)
dz = abs(dz)
dz_conform = conform_dims( (/num_tim,num_lev,num_lat,num_lon/), dz, 1 )
dz_conform@_FillValue = 1.e9

do i=0,num_lon-1
do j=0,num_lat-1
   if(ismissing(deptho(j,i)))then
      continue
   end if

   k=0
   do while(k.le.num_lev-1 .and. lev_bnds(k,1).lt.deptho(j,i))
      k = k +1
   end do
   if(k.le.num_lev-1)then
;     dz_conform(:,k,j,i)=abs(deptho(j,i) - lev_bnds(k,0))
   end if
end do
end do

if (isfilepresent(DIR_in3+ncs3)) then
   print("==================== "+ncs3+" exists. We will use it instead of our own ====================")
   delete(dz_conform)
   delete(dz)
   fin3 = addfile(DIR_in3+ncs3,"r")

   dimh = dimsizes(getfilevardimsizes(fin3,thkcello_var))
   if(dimh.eq.4) then
      thkcello = fin3->$thkcello_var$(0:num_tim-1,:,:,:)

      num_lat2=dimsizes(thkcello(0,0,:,0))

      dz_conform=thkcello(:,:,0:num_lat-1,:)
      do j=0,num_lat-1
         jn=min((/j+1,num_lat2-1/))
         dz_conform(:,:,j,:)=dim_min_n(thkcello(:,:,j:jn,:),2)
      end do
   else
      print("====================   fixed  ====================")
      thkcello = fin3->$thkcello_var$

      num_lat2=dimsizes(thkcello(0,:,0))

      dz=thkcello(:,0:num_lat-1,:)
      do j=0,num_lat-1
         jn=min((/j+1,num_lat2-1/))
         dz(:,j,:)=dim_min_n(thkcello(:,j:jn,:),1)
      end do
      dz_conform = conform_dims( (/num_tim,num_lev,num_lat,num_lon/), dz, (/1,2,3/) )
   end if
end if

copy_VarMeta(vo,dx_conform)
copy_VarMeta(vo,dy_conform)
copy_VarMeta(vo,dz_conform)

dx_conform@long_name="dx"
dy_conform@long_name="dy"
dz_conform@long_name="dz"
dx_conform@units    ="m"
dy_conform@units    ="m"
dz_conform@units    ="m"

setfileoption("nc","Format","LargeFile")

  system("rm "+DIR_out+model+".dxdydz_"+vo_var+".fx.nc")
fout = addfile(DIR_out+model+".dxdydz_"+vo_var+".fx.nc","c")
;=============================================================================
do n=0,nums-1
   if(Names(n).eq."")then
      break
   end if
   fout->$Names(n)$ = fin0->$Names(n)$
end do
fout->dx = dx_conform(0,:,:,:)
fout->dy = dy_conform(0,:,:,:)
fout->dz = dz_conform(0,:,:,:)
