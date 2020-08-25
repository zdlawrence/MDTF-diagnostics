begin

;---------------------------------------  Variables Define ---------------------------------------

DIR_in0 = (/ getenv("FIXREF"), getenv("MONDIR") /)
DIR_out = (/ getenv("OUTDIR") /)
vars    = (/ getenv("bas_var"), getenv("VAR0") /)


bas_var = getenv("bas_var")
vo_var = getenv("VAR0")
time_var = getenv("time_coord")
lev_var = getenv("lev_coord")
lat_var = getenv("lat_coord")
lon_var = getenv("lon_coord")

model=getenv("CASENAME")
yymm=getenv("YYYYMM")
yyyy=getenv("YYYY")

ncs     = (/ "LICOM.BASIN.fx.nc", model+"."+vo_var+".mon.nc" /)
;---------------------------------------  Loading Data    ---------------------------------------
nc0  = DIR_in0(0) + ncs(0)
print("Loading ... "+nc0)
fin0 = addfile(nc0,"r")


lat0 = fin0->$lat_var$
lon0 = fin0->$lon_var$

nc1  = DIR_in0(1) + ncs(1)
print("Loading ... "+nc1)
fin1 = addfile(nc1,"r")
num_tim = dimsizes(fin1->$time_var$)
num_tim=min((/num_tim,12/))

;-------------- lev ---------------
var  = fin1->$vars(1)$(0,:,0,0)
lev  = var!0
lev1 = fin1->$lev_var$
num_lev = dimsizes(lev1)
delete(var)

;-------------- var ---------------
var0 = fin0->$vars(0)$
tmp  = fin1->$vars(1)$(0:num_tim-1,0:num_lev-2,:,:)
tmp@_FillValue=-9999
tmp  = abs(tmp)*100.
var1 = tmp(0,0,:,:)
var1 = dim_sum_n_Wrap(dim_sum_n_Wrap(tmp,0),0)

;-------------- lat ---------------
lat1 = fin1->$lat_var$
;-------------- lon ---------------
lon1 = fin1->$lon_var$

vit = tointeger(var1)
copy_VarMeta(var1,vit)
vit@_FillValue = -9999

num0 = 0

numx = dimsizes(var1(0,:))
numy = dimsizes(var1(:,0))

nlat = dimsizes(dimsizes(lat1))

do i=0,numx-1
do j=0,numy-1

   if(ismissing(var1(j,i)).or.vit(j,i).eq.0)then
      vit(j,i)=vit@_FillValue
     continue
   end if
   ;;; Below Coarse Grid is Sea
   ;;; num0 counts if High-Resoluton is Land
   ;;; vit: -9999 where Coarse is land, 0 if High-Resoluton is Land; num0 is the number of 0s in vit
   ;;; step3 inspect where vit is 0 and try to eliminate it, by which makes num0 to 0

;---------------- for MIROC4h -----------------
   if(tmp(0,0,j,i).eq.5)then
      vit(j,i)=vit@_FillValue
      continue
   end if
;---------------------------------------------

   if(nlat.eq.2)then
      rlat1=lat1(j,i)
      rlon1=lon1(j,i)
   else
      rlat1=lat1(j)
      rlon1=lon1(i)
   end if
    
   if(rlon1.lt.0)then
      rlon1 = rlon1+360.
   end if

   j_rlat = ind_nearest_coord (rlat1, lat0, 0)
   i_rlon = ind_nearest_coord (rlon1, lon0, 0)
 
   if(var0(j_rlat,i_rlon).eq.0)then
      num0 = num0 + 1
      vit(j,i)=0
   else
      vit(j,i)=(/var0(j_rlat,i_rlon)/)
   end if
     
end do 
end do 

vit@long_name  = "Index on T grids"
vit@units  = "0Land,1Arc,2Atl,3Ind,4Pac,5-7Atl_Ind_Pac in SO"

fout = addfile(DIR_out+model+".BASIN_"+vo_var+"_step1.nc","c")
fout->$bas_var$ = vit
fout->$lat_var$ = lat1
fout->$lon_var$ = lon1

asciiwrite (DIR_out+model+".BASIN_"+vo_var+"_step.txt", 1)

end
