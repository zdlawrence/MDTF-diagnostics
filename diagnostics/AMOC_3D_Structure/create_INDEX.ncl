load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"

begin

;=======================================  Variables Define =========================================

 DIR_in0 = (/ getenv("MONDIR"), getenv("OUTDIR")/)

 vo_var = getenv("VAR0")
 bas_var = getenv("bas_var")
 time_var = getenv("time_var")
 lev_var = getenv("lev_var")
 lat_var = getenv("lat_var")
 lon_var = getenv("lon_var")

 model=getenv("CASENAME")
 yymm=getenv("YYYYMM")
 yyyy=getenv("YYYY")

 ncs     = (/ model+"."+vo_var+".mon.nc", model+".BASIN_"+vo_var+".fx.nc"/)

  nc0  = DIR_in0(0) + ncs(0)
;  print("Now,the nc is: "+nc0)
  fin0 = addfile(nc0,"r")
  var = fin0->$vo_var$(0,:,:,:)
  var2= fin0->$vo_var$

  nc1  = DIR_in0(1) + ncs(1)
;  print("Now,the nc is: "+nc1)
  fin1 = addfile(nc1,"r")
  bas = fin1->$bas_var$
  lat1 = fin1->$lat_var$
  lon1 = fin1->$lon_var$

  var@_FillValue=1e20
  num_tim=dimsizes(var2(:,0,0,0))
  sit=new(dimsizes(var),"float",1e20)
  do t=0,num_tim-1
     sit = where(abs(var2(t,:,:,:)).gt.1e-6, 1, sit)
     ;;; if var is 0 at all times, then it's land
  end do

  tmp = conform_dims (dimsizes(sit),bas,(/1,2/)) 
  tmp = where(ismissing(sit),tmp@_FillValue,tmp)
;  printVarSummary(tmp)

  vit = tointeger(var)
;  copy_VarMeta(sit,vit)
  copy_VarMeta(var,vit)
  vit@_FillValue=0
;  printVarSummary(vit)
 
  vit = (/tointeger(tmp)/)
  num_lev=dimsizes(vit(:,0,0))

  vit@long_name  = "Index on T/V grids"
  vit@units  = "0Land,1Arc,2Atl,3Ind,4Pac,5-7Atl_Ind_Pac"

  if(model.eq."MRI-CGCM3" .or. model.eq."MIROC5")then
    vit(num_lev-1,:,:)=vit@_FillValue
  end if
 
       system("rm "+DIR_in0(1)+model+".INDEX_"+vo_var+".fx.nc")
  fout    = addfile(DIR_in0(1)+model+".INDEX_"+vo_var+".fx.nc","c")
  fout->$bas_var$ = vit
  fout->$lat_var$ = lat1
  fout->$lon_var$ = lon1

end
