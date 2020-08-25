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

res@tiXAxisString             = "Streamfunction (Sv)"
res@tiYAxisString             = "Pot. Temp. (~S~o~N~C)"
;res@tiYAxisString             = "Pot. Temp. ~F8~q~N~~F21~ (~S~o~N~C)"

res@trYReverse = True

res@xyMarkLineMode   ="Lines"
res@xyDashPattern    = 0
res@xyLineThicknessF = 2.0

res@trYReverse                  = True
;res@gsnStringFontHeightF=0.028


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DIR_in0    = getenv("CLMREF")
DIR_in1    = getenv("FIXREF")
DIR_out    = getenv("FIGREF")
lat0       = stringtofloat(getenv("LAT0"))

lat_var    = getenv("lat_var")
lev_var    = getenv("lev_var")

if(lat0.ge.0)then
  res@gsnCenterString = "Latitude: "+tostring_with_format(lat0,"%4.1f")+"~S~o~N~N"
else  
  res@gsnCenterString = "Latitude: "+tostring_with_format(abs(lat0),"%4.1f")+"~S~o~N~S"
end if
models=(/"HYCOM"/)

ncs1="HYCOM.lat_vo.fx.nc"
ncs =(/"HYCOM.AMOCT_qts.clim.nc"/)

num_model=dimsizes(models)

plot = new(num_model,graphic)
plot1 = new(1,graphic)

wks   = gsn_open_wks("pdf",DIR_out+"ref_AMOCT_T_plot")
gsn_define_colormap(wks,"xbxu")
;gsn_define_colormap(wks,"amwg256")

  nc = DIR_in1+ncs1
  print("Loading ... "+nc)
  fin = addfile(nc,"r")
  lat = fin->$lat_var$
  jjj = minind(abs(lat-lat0))

  nc = DIR_in0+ncs(0)
  print("Loading ... "+nc)
  fin = addfile(nc,"r")
  lev = fin->$lev_var$
  var = fin->moc(0,:,jjj,0)

;----------------------------------------------------------------------------------------------------  
  xmin=tointeger( min(var) - 0.5)
  xmax=tointeger( max(var) + 0.5)
  dist = (xmax-xmin)*0.1
  xmin = tointeger(xmin - dist - 0.5)
  xmax = tointeger(xmax + dist + 0.5)
  res@trXMinF = xmin
  res@trXMaxF = xmax
  res@trYMinF = min(lev)
  res@trYMaxF = max(lev)
;----------------------------------------------------------------------------------------------------  
  res@xyLineColor = "blue"
  plot = gsn_csm_xy(wks,var,lev,res)


lgres                    = True
lgres@lgLineColors       = (/"blue"/)
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
labels = (/"HYCOM"/)
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
