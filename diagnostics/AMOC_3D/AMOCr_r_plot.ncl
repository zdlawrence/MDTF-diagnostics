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
;res@vpWidthF           = 0.9

;res@gsnStringFontHeightF=0.028
res@gsnLeftString              = ""
res@gsnRightString             = ""
res@gsnCenterString            = ""
res@tiXAxisString        = ""
res@tiYAxisString        = ""

;res@vpXF              = 0.15
;res@vpYF              = 0.95
;res@vpWidthF          = 0.6
;;res@vpHeightF         = 0.6
;res@tmBorderThicknessF= 3
;res@tmXTMajorThicknessF=3
;res@tmXTMinorThicknessF=2
;res@tmXBMajorThicknessF=3
;res@tmXBMinorThicknessF=2
;res@tmYLMajorThicknessF=3
;res@tmYLMinorThicknessF=2
;res@tmYRMajorThicknessF=3
;res@tmYRMinorThicknessF=2

res@xyMarkLineMode   ="Lines"
res@xyDashPattern    = 0
res@xyLineThicknessF = 2.0

res@tiXAxisString             = "Streamfunction (Sv)"
res@tiYAxisString             = "Pot. Density ~F8~s~B~2~N~"

res@gsnYAxisIrregular2Linear = True
res@tmYLMode                 = "Explicit"
res@trYMinF = 0 
res@trYMaxF = 99
res@tmYLValues            = ispan(9,99,10)
res@tmYLMinorValues       = ispan(4,99,5)
res@trXTensionF  = 30. 
res@trYTensionF  = 30.
res@trYReverse                  = True


levs=(/30.1, 30.3, 30.5, 30.7, 30.9, 31.1, 31.3, 31.5, 31.7, 31.9, 32.1, 32.3, 32.5, 32.7, 32.9, 33.1, 33.3, 33.5, 33.7, 33.9, 34.1, 34.3, 34.5, 34.7, 34.9, 35.1, 35.3, 35.5, 35.7, 35.9, 36.01, 36.03, 36.05, 36.07, 36.09, 36.11, 36.13, 36.15, 36.17, 36.19, 36.21, 36.23, 36.25, 36.27, 36.29, 36.31, 36.33, 36.35, 36.37, 36.39, 36.41, 36.43, 36.45, 36.47, 36.49, 36.51, 36.53, 36.55, 36.57, 36.59, 36.61, 36.63, 36.65, 36.67, 36.69, 36.71, 36.73, 36.75, 36.77, 36.79, 36.81, 36.83, 36.85, 36.87, 36.89, 36.91, 36.93, 36.95, 36.97, 36.99, 37.01, 37.03, 37.05, 37.07, 37.09, 37.11, 37.13, 37.15, 37.17, 37.19, 37.21, 37.23, 37.25, 37.27, 37.29, 37.31, 37.33, 37.35, 37.37, 37.39/)
res@tmYLLabels = tostring_with_format(levs(9:99:10),"%5.2f")


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DIR_in0    = getenv("FIXREF")
DIR_in1    = getenv("CLMREF")
DIR_in2    = getenv("OUTDIR")
DIR_in3    = getenv("OUTDIR")
DIR_in     = getenv("OUTDIR")
DIR_out    = getenv("FIGDIR")
lat0       = stringtofloat(getenv("LAT0"))

lev_var = getenv("lev_var")
lat_var = getenv("lat_var")

model=getenv("CASENAME")
yymm=getenv("YYYYMM")
yyyy=getenv("YYYY")

if(lat0.ge.0)then
  res@gsnCenterString = "Latitude: "+tostring_with_format(lat0,"%4.1f")+"~S~o~N~N"
else  
  res@gsnCenterString = "Latitude: "+tostring_with_format(abs(lat0),"%4.1f")+"~S~o~N~S"
end if
models=(/model/)

nc0="HYCOM.lat_vo.fx.nc"
nc1="HYCOM.AMOC_qts.clim.nc"
nc2=model+"."+lat_var+"_vo.fx.nc"
nc3=model+".AMOC_qts.clim.nc"

num_model=dimsizes(models)

plot = new(num_model,graphic)
plot1 = new(1,graphic)

wks   = gsn_open_wks("pdf",DIR_out+"AMOCr_r_plot")
gsn_define_colormap(wks,"xbxu")
;gsn_define_colormap(wks,"amwg256")

  nc = DIR_in0+nc0
  print("Loading ... "+nc)
  fin = addfile(nc,"r")
  lat = fin->$lat_var$
  jjj = minind(abs(lat-lat0))
  delete(lat)

  nc = DIR_in1+nc1
  print("Loading ... "+nc)
  fin = addfile(nc,"r")
  lev = fin->$lev_var$
  tmp = fin->AMOC(0,:,jjj,0)

  lev2=ispan(0,99,1)*1.0
  lev2@_FillValue=-9999
  tmp&lev= (/lev2/)  
  delete(lev)

  nc = DIR_in2+nc2
  print("Loading ... "+nc)
  fin = addfile(nc,"r")
  lat = fin->$lat_var$
  jjj = minind(abs(lat-lat0))
  delete(lat)

  nc = DIR_in3+nc3
  print("Loading ... "+nc)
  fin = addfile(nc,"r")
  lev = fin->$lev_var$
  var = fin->moc(:,jjj,0)
  var&lev= (/lev2/)  
  delete(lev)

;----------------------------------------------------------------------------------------------------  
  xmin=tointeger( min( (/min(var),min(tmp)/) ) - 0.5)
  xmax=tointeger( max( (/max(var),max(tmp)/) ) + 0.5)
  dist = (xmax-xmin)*0.1
  xmin = tointeger(xmin - dist - 0.5)
  xmax = tointeger(xmax + dist + 0.5)
  res@trXMinF = xmin
  res@trXMaxF = xmax
;----------------------------------------------------------------------------------------------------  
  res@xyLineColor = "red"
  plot = gsn_csm_xy(wks,var,lev2,res)

  res@xyDashPattern = 0
  res@xyLineColor = "blue"
  res@xyLineThicknessF      = 3
  plot1 = gsn_csm_xy (wks,tmp,lev2,res)
  overlay(plot,plot1)
  delete(tmp)

lgres                    = True
lgres@lgLineColors       = (/"red","blue"/)
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
labels = (/model,"HYCOM"/)
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
