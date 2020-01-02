load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"

;***************************************************************************************************************************
;                   resource for public
;***************************************************************************************************************************
res                            = True
res@cnFillOn                   = True
res@cnLinesOn                  = False
res@cnLineLabelsOn             = False
res@cnLabelMasking             = False
res@cnMissingValPerimOn        = False
res@cnMissingValFillColor      = "grey"
res@cnInfoLabelOn               = False
res@cnLevelSelectionMode        = "ExplicitLevels"

res@gsnFrame                   = False
res@gsnDraw                    = False
res@gsnSpreadColors            = True
res@gsnSpreadColorEnd          = -3
res@gsnXAxisIrregular2Linear   = True
res@gsnLeftString              = ""
res@gsnRightString             = ""
res@gsnCenterString            = ""
res@gsnContourZeroLineThicknessF = 1.45                 ; Thick the zero line: Default: 1.0 
res@gsnContourNegLineDashPattern = 1                 ; set the Negtive lines' dash pattern Default: 0 (solid line)

res@lbLabelBarOn               = False

;res@tiYAxisFontHeightF          = 0.025    ; Default: 0.025
;res@tiXAxisFontHeightF          = 0.025    ; Default: 0.025

;res@tmXBLabelFontHeightF        = 0.02     ; Default: <dynamic> -- initially 0.02 for a viewport width of 0.6
;res@tmYLLabelFontHeightF        = 0.02     ; Default: <dynamic> -- initially 0.02 for a viewport width of 0.6

res@trYReverse                  = True
res@tiMainString          = ""
res@tiYAxisString         = ""
res@tiXAxisString         = ""

res@tmYROn                = False
res@tmYLOn                = True 

;res@gsnCenterStringFontHeightF =0.028
;res@gsnRightStringFontHeightF  =0.028
;res@gsnLeftStringFontHeightF   =0.028
;res@gsnStringFontHeightF=0.028

;res@vpWidthF             = 0.9
;res@vpHeightF            = 0.8
;***************************************************************************************************************************
;           resourse for upper plot
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
res0                       = res
;;res0@tiYAxisFontHeightF    = 0.03

res0@tmYLMode              = "Explicit"
res0@tmYLMinorOn           = True
res0@tmXBLabelsOn          = True 
res0@tmXBOn                = True 
res0@tmXTOn                = False
res0@cnLineLabelsOn       = False
res0@cnLinesOn            = False
;res0@lbLabelFontHeightF   = 0.012
;res0@vpXF                 = 0.2
res0@cnFillMode           = "CellFill"
res0@cnFillOn             = True
res0@cnLevelSelectionMode = "ExplicitLevels"
res0@lbLabelBarOn               = True
res0@lbOrientation              = "Vertical"
res0@lbLabelAutoStride          = True
;res0@pmLabelBarWidthF           = 0.12
;res0@pmLabelBarHeightF          = 0.8
res0@pmLabelBarOrthogonalPosF   = -0.02
;res0@lbLabelStride              = 2


;***************************************************************************************************************************
;           resource for contour line plot
;***************************************************************************************************************************
res_cn                          = True
res_cn@gsnDraw                  = False                 ; don't draw
res_cn@gsnFrame                 = False                 ; don't advance frame
res_cn@gsnAddCyclic             = False
res_cn@gsnContourZeroLineThicknessF = 2                 ; Thick the zero line: Default: 1.0
res_cn@gsnContourNegLineDashPattern = 1                 ; set the Negtive lines' dash pattern Default: 0 (solid line)
res_cn@gsnLeftString              = ""
res_cn@gsnRightString             = ""
res_cn@gsnCenterString            = ""

res_cn@cnLevelSelectionMode     = "ExplicitLevels"
res_cn@cnInfoLabelOn            = False

;;; use res---cnLineDashSegLenF; Default: 'Randomized', together with 'Randomized' use res---cnLineLabelDensityF
;res_cn@cnLineLabelPlacementMode = "Constant"           
;;;useres---cnLineDashSegLenF; Default: 'Randomized', together with 'Randomized' use res---cnLineLabelDensityF
res_cn@cnLineLabelPlacementMode = "Computed"            
res_cn@cnLineLabelsOn           = True
res_cn@cnLineLabelBackgroundColor = -1
res_cn@cnLineLabelFontColor     = "black"
;res_cn@cnLineLabelFontHeightF   = 0.012                 ; Default: <dynamic> -- 0.012 for a viewport width of 0.6
res_cn@cnLineLabelFontThicknessF= 2.0                   ; Default: Default: 1.0
res_cn@cnLineLabelAngleF        = 0.
;res_cn@cnConstFLabelAngleF
;res_cn@cnHighLabelAngleF
;res_cn@cnInfoLabelAngleF
res_cn@cnLineLabelInterval      = 1                     ; default = 2

;res_cn@cnLineDashSegLenF       = 0.25                   ; Default: 0.15 (for a viewport width of 0.6)
res_cn@cnLineLabelDensityF      = 0.2                   ; Default: 0.0
;res_cn@cnLineLabelDensityF      = 0.0                   ; Default: 0.0
;res_cn@cnLineThicknessF         = 1.0                  ; Default: 1.0
;res_cn@lbLabelStride            = 1 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;           resourse for Panel plot
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
resP                            = True
;resP@gsnMaximize                = True
;resP@lbLabelStride             = 4 
;resP@gsnPanelLabelBar           = True
;resP@pmLabelBarDisplayMode       = "Always" ; turn on color bar
;resP@pmLabelBarSide              = "Right" ; put it on the bottom of plot
;resP@pmLabelBarWidthF           = 0.08
;resP@pmLabelBarHeightF          = 0.74
;resP@pmLabelBarOrthogonalPosF   = 0.00
;resP@pmLabelBarParallelPosF     = -0.01 

;resP@lbLabelBarOn               = True                  ; turn on individual cb's
;resP@lbOrientation              = "Vertical"         ; individual lb's orientaion
;resP@lbOrientation              = "Horizontal"         ; individual lb's orientaion
;;resP@lbLabelFontHeightF         = 0.018

res0@gsnXAxisIrregular2Linear = True 
res0@tmXBMode                 = "Explicit"
res0@tmXBValues               = ispan(-80,20,20)
res0@tmXBMinorValues          = ispan(-90,20,5)
res0@tmXBLabels=(/"80W", "60W", "40W", "20W", "0", "20E"/)

values=ispan(0,6000,1000)
res0@gsnYAxisIrregular2Linear = True 
res0@tmYLMode                 = "Explicit"
res0@tmYLValues               = values
res0@tmYLMinorValues          = ispan(0,6000,200)
res0@tmYLLabels=(/"0", "1000", "2000", "3000", "4000", "5000", "6000"/)
res0@trYMinF = 0.
res0@trYMaxF = 5400
res0@trXMinF = -98
res0@trXMaxF = -15 
;res0@cnFillMode           = "CellFill"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
YEAR="186001-186412"
Aind=3

debug=1
which=0

DIR_in2    = getenv("CLMREF")
DIR_out    = getenv("FIGREF")
lat0       = stringtofloat(getenv("LAT0"))

thetao_var = getenv("thetao_var")
lat_var = getenv("lat_var")
lon_var = getenv("lon_var")

ncs2=(/"WOA13.thetao_viv.clim.nc"/)
models=(/"WOA13"/)

xpos=(/0.230,0.365,0.51,0.65,0.80/)
ypos=(/0.865,0.679,0.492,0.305/)

wks   = gsn_open_wks("pdf",DIR_out+"obs_thetao_lat0_climate_xz_plot")
gsn_define_colormap(wks,"ncl_default")
;gsn_reverse_colormap(wks)

cnLevels_Fill   = ispan(0,26,1)
res0@cnLevels  = cnLevels_Fill
res0@gsnRightString        = ""
res0@gsnLeftString         = ""

res_cn@cnLevels     = (/2,4,10,15,22/)

num_model=dimsizes(models)
plot = new((/num_model/),graphic)
plot0= new((/num_model/),graphic)
txt  = new(num_model,graphic)

do mm=0,num_model-1
  nc  = DIR_in2+ncs2(mm)
  print("Loading ... "+nc)
  fin = addfile(nc,"r")
  lat = fin->$lat_var$
  jjj=ind_nearest_coord(lat0,lat,0)
  thetao  = fin->$thetao_var$
  if(max(thetao(0:1,:,:)).gt.100)then
     thetao = thetao - 273.15
  end if
;  printMinMax(thetao,False)

  lev  = fin->depth
  lon  = fin->$lon_var$

  num_lev=dimsizes(thetao(:,0,0))
  num_lat=dimsizes(thetao(0,:,0))
  num_lon=dimsizes(thetao(0,0,:))

  lon = where(lon.gt.180,lon-360,lon) 
  lon = where(lon.lt.-180,lon+360,lon) 

  if(dimsizes(dimsizes(lon)).eq.2)then
    dlon = lon(jjj,:)
  else
    dlon = lon
  end if

  ii0=minind(abs(-98-dlon))
  ii1=minind(abs(-15-dlon))

  if(ii1.lt.ii0)then
    print("Pacific Centered")
    numx=(num_lon-1-ii0+1)+(ii1)+1
    tmp=new((/num_lev,numx/),"double",1e20)
    tmp(:,0:num_lon-ii0-1)=(/thetao(:,jjj,ii0:num_lon-1)/)
    tmp(:,num_lon-ii0:numx-1)=(/thetao(:,jjj,0:ii1)/)
    xxx=new(numx,"double",1e20)
    xxx(0:num_lon-ii0-1)=dlon(ii0:num_lon-1)
    xxx(num_lon-ii0:numx-1)=dlon(0:ii1)
    tmp!0="lev"
    tmp!1="lon"
    tmp&lev=lev
    tmp&lon=xxx
  else
    print("Atlantic Centered")
    numx=ii1-ii0+1
    tmp=new((/num_lev,numx/),"double",1e20)
    tmp(:,0:numx-1)=(/thetao(:,jjj,ii0:ii1)/)
    xxx=new(numx,"double",1e20)
    xxx(0:numx-1)=dlon(ii0:ii1)
    tmp!0="lev"
    tmp!1="lon"
    tmp&lev=lev
    tmp&lon=xxx
  end if

  res0@tmXBLabelsOn=True
  res0@tiXAxisString        = "Longitude"
  res0@tmYLLabelsOn=True
  res0@tiYAxisString        = "Depth (m)"
  res0@gsnCenterString       = models(mm)
  res0@gsnLeftString       = "Pot. Temp."
  res0@gsnRightString       = "~S~o~N~C"


  plot(mm) = gsn_csm_contour(wks,tmp,res0)
  plot0(mm) = gsn_csm_contour(wks,tmp,res_cn)
  overlay(plot(mm),plot0(mm))

  ttres               = True                     ; text mods desired
;  ttres@txFontHeightF = 0.01                     ; font smaller. default big 
  a=mod(mm,5)
  b=mm/5
  xx=xpos(a)
  yy=ypos(b)
;  gsn_text_ndc(wks,models(mm),xx,yy,ttres) 
  delete(xx)
  delete(yy)

  delete(lev)
  delete(lat)
  delete(lon)
  delete(dlon)
  delete(thetao)
  delete(tmp)
  delete(xxx)
end do

;***************************************************************************************************************************
;resP@gsnPanelDebug =True
;resP@gsnPanelXF=(/0.152, 0.295,    -1, 0.579, 0.722, \
;                  0.152, 0.295,    -1, 0.579, 0.722, \
;                  0.152, 0.295,    -1, 0.579, 0.722, \
;                  0.152, 0.295,    -1, 0.579, 0.722 /)
;resP@gsnPanelYF=(/0.858, 0.858, 0.858, 0.858, 0.858, \
;                  0.672, 0.672, 0.672, 0.672, 0.672, \
;                  -1   , -1   ,    -1,  -1  ,  -1  , \
;                  0.297, 0.297, 0.297, 0.297, 0.297 /)
;gsn_panel(wks,plot,(/4,5/),resP)
gsn_panel(wks,plot,(/1,1/),resP)
