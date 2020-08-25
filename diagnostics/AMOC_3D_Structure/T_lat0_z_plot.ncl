load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"

;***************************************************************************************************************************
;                   resource for public
;***************************************************************************************************************************
res = True

res@gsnFrame           = False
res@gsnDraw            = False
;res@vpHeightF          = 0.8
;res@vpWidthF           = 0.8

res@gsnLeftString              = ""
res@gsnRightString             = ""
res@gsnCenterString            = ""
res@tiXAxisString        = ""
res@tiYAxisString        = ""

;res@vpXF              = 0.15
;res@vpYF              = 0.95
;res@vpWidthF          = 0.6
;res@vpHeightF         = 0.6
;res@tmBorderThicknessF= 3
;res@tmXTMajorThicknessF=3
;res@tmXTMinorThicknessF=2
;res@tmXBMajorThicknessF=3
;res@tmXBMinorThicknessF=2
;res@tmYLMajorThicknessF=3
;res@tmYLMinorThicknessF=2
;res@tmYRMajorThicknessF=3
;res@tmYRMinorThicknessF=2

res@tiXAxisString             = "Pot. Temp. (~S~o~N~C)"
res@tiYAxisString             = "Depth (m)"

res@trXMinF = -2
res@trXMaxF = 25. 
res@trYMinF = 0 
res@trYMaxF = 5500
res@trYReverse = True

res@xyMarkLineMode   ="Lines"
res@xyDashPattern    = 0
res@xyLineThicknessF = 2.0

res@trYReverse                  = True
;res@gsnStringFontHeightF=0.028

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;           resourse for upper plot
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
res_upper                       = res

;res_upper@vpYF                 = 0.8
;res_upper@vpXF                 = 0.2

res_upper@gsnCenterString            = "26N"

res_bottom                      = res 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DIR_in0    = getenv("CLMREF")
DIR_in1    = getenv("OUTDIR")
DIR_in2    = getenv("OUTDIR")
DIR_out    = getenv("FIGDIR")
lat0       = stringtofloat(getenv("LAT0"))

thetao_var = getenv("thetao_var")
lev_var = getenv("lev_coord")
lat_var = getenv("lat_coord")
bas_var = getenv("bas_var")

model=getenv("CASENAME")
yymm=getenv("YYYYMM")
yyyy=getenv("YYYY")

models=(/model/)

ncs0="WOA13.thetao_viv.clim.nc"
ncs1=model+".thetao_viv.clim.nc"
ncs2=model+".INDEX_vo.fx.nc"

num_model=dimsizes(models)
if(lat0.ge.0)then
  res@gsnCenterString = "Latitude: "+tostring_with_format(lat0,"%4.1f")+"~S~o~N~N"
else  
  res@gsnCenterString = "Latitude: "+tostring_with_format(abs(lat0),"%4.1f")+"~S~o~N~S"
end if

plot = new(num_model,graphic)
plot1 = new(1,graphic)

order=ispan(0,num_model-1,1)
marker=mod(order,16)+1
colors=ispan(2,21,1)
;colors=floattoint(fspan(1,255,num_model))

wks   = gsn_open_wks("pdf",DIR_out+"T_lat0_z_plot")
gsn_define_colormap(wks,"xbxu")
;gsn_define_colormap(wks,"amwg256")

  nc = DIR_in1+model+"."+lat_var+"_vo.fx.nc"
  print("Now,the nc is:   "+nc)
  fin = addfile(nc,"r")
  lat = fin->$lat_var$
  jjj = minind(abs(lat-lat0))

  nc = DIR_in2+ncs2
  print("Now,the nc is:   "+nc)
  fin = addfile(nc,"r")
  viv = fin->$bas_var$(:,jjj,:)
  delete(viv@_FillValue)

  nc = DIR_in1+ncs1
  print("Now,the nc is:   "+nc)
  fin = addfile(nc,"r")
  lev = fin->$lev_var$
  tmp = fin->$thetao_var$(:,jjj,:)
  tmp = where(viv.eq.2,tmp,tmp@_FillValue)
  var = dim_avg_n_Wrap(tmp,1)
  if(max(var).gt.100)then
     var = var - 273.15
  end if
  delete(tmp)
  delete(viv)
;  printVarSummary(var)
;  print(""+var)

  res@xyLineColor = "red"
  plot = gsn_csm_xy(wks,var,lev,res)

  nc = DIR_in0+ncs0
  fil = addfile(nc,"r")
  LEV  = fil->depth
  LAT  = fil->$lat_var$
  jjj=ind_nearest_coord(lat0,LAT,0)
  tmp  = dim_avg_n_Wrap(fil->$thetao_var$(:,jjj,:),1)
  res@xyDashPattern = 0
  res@xyLineColor = "black"
  res@xyLineThicknessF      = 3
  plot1 = gsn_csm_xy (wks,tmp,LEV,res)
  overlay(plot,plot1)
  delete(tmp)

lgres                    = True
lgres@lgLineColors       = (/"red","black"/)
lgres@lgBoxLinesOn       = False
lgres@lgPerimOn          = False
lgres@lgLineThicknessF   = 3
lgres@lgItemType         = "Lines"        ; show lines only (default)
;lgres@lgLabelFontHeightF = .08            ; legend label font thickness
lgres@vpWidthF           = 0.18           ; width of legend (NDC)
lgres@vpHeightF          = 0.15           ; height of legend (NDC)
lgres@lgPerimThicknessF  = 2.0            ; thicken the box perimeter
lgres@lgMonoDashIndex    = True
lgres@lgDashIndex        = 0
labels = (/model,"WOA13"/)
nitems = dimsizes(labels)                 ; number of legend items

amres                  = True
amres@amJust           = "BottomRight"   ; Use bottom right corner of box
amres@amParallelPosF   = 0.5
amres@amOrthogonalPosF = 0.5
lbid = gsn_create_legend(wks,nitems,labels,lgres)
annoid = gsn_add_annotation(plot,lbid,amres)  ; add legend to plot
;====================================================================================================

;;;;;; Maximize output on the page and draw everything
pres=True
;pres@gsnPanelDebug =True
;maximize_output(wks,pres)  ; Maximize plot on page
draw(plot)
frame(wks)
