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
;res@cnLineLabelBackgroundColor = "transparent" 
res@cnLabelMasking             = True
res@cnMissingValPerimOn        = True
;res@cnMissingValFillPattern    = 3 
;res@cnMissingValFillPattern    = "SolidFill" 
;res@cnMissingValFillColor      = "black"
res@cnMissingValFillColor      = "grey"
res@cnInfoLabelOn               = False
res@cnLevelSelectionMode        = "ExplicitLevels"      ; set manual contour levels

res@gsnFrame                   = False
res@gsnDraw                    = False
res@gsnSpreadColors            = True
;res@gsnSpreadColorEnd          = -3
res@gsnXAxisIrregular2Linear   = True
res@gsnLeftString              = ""
res@gsnRightString             = ""
res@gsnCenterString            = ""
res@gsnContourZeroLineThicknessF = 1.45                 ; Thick the zero line: Default: 1.0 
res@gsnContourNegLineDashPattern = 1                 ; set the Negtive lines' dash pattern Default: 0 (solid line)

res@lbLabelBarOn               = True 
res@lbOrientation              = "Vertical"
res@lbLabelAutoStride          = True
;res@pmLabelBarWidthF           = 0.12
;res@pmLabelBarHeightF          = 0.8 
res@pmLabelBarOrthogonalPosF   = -0.01

;res@tiYAxisFontHeightF          = 0.025    ; Default: 0.025
;res@tiXAxisFontHeightF          = 0.025    ; Default: 0.025

;res@tmXBLabelFontHeightF        = 0.03     ; Default: <dynamic> -- initially 0.02 for a viewport width of 0.6
;res@tmYLLabelFontHeightF        = 0.03     ; Default: <dynamic> -- initially 0.02 for a viewport width of 0.6

res@trYReverse                  = True
res@tiMainString          = ""
res@tiYAxisString         = "Depth (m)"
res@tiXAxisString         = "Latitude"

res@tmYROn                = False

;res@gsnCenterStringFontHeightF =0.028
;res@gsnRightStringFontHeightF  =0.028
;res@gsnLeftStringFontHeightF   =0.028
;res@gsnStringFontHeightF=0.028

res@trXMinF               = -40.
res@trXMaxF               = 80.
res@trYMinF               = 0.
res@trYMaxF               = 5600.
res@trYTensionF  = 30.
res@trXTensionF  = 30.

;res@vpHeightF             = 0.8
;res@vpWidthF              = 0.9
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;           resourse for upper plot
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
res_upper                       = res
;;res_upper@tiYAxisFontHeightF    = 0.03

;res_upper@tmYLMode              = "Explicit"
res_upper@tmYLMinorOn           = True
res_upper@tmXBLabelsOn          = False
res_upper@tmXBOn                = True 
res_upper@tmXTOn                = False

;res_upper@vpHeightF             = 0.4
;res_upper@vpWidthF              = 0.7
;res_upper@vpYF                 = 0.99
;res_upper@vpXF                 = 0.01

res_upper@gsnCenterString       = ""
res_upper@gsnRightString        = ""
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

res_cn@cnLevelSelectionMode     = "ExplicitLevels"      ; set manual contour levels
res_cn@cnInfoLabelOn            = False

;;; use res---cnLineDashSegLenF; Default: 'Randomized', together with 'Randomized' use res---cnLineLabelDensityF
;res_cn@cnLineLabelPlacementMode = "Constant"           
;;;useres---cnLineDashSegLenF; Default: 'Randomized', together with 'Randomized' use res---cnLineLabelDensityF
res_cn@cnLineLabelPlacementMode = "Computed"            
res_cn@cnLineLabelsOn           = True
res_cn@cnLineLabelBackgroundColor = -1
res_cn@cnLineLabelFontColor     = "black"
;res_cn@cnLineLabelFontHeightF   = 0.018                 ; Default: <dynamic> -- 0.012 for a viewport width of 0.6
res_cn@cnLineLabelFontThicknessF= 3.0                   ; Default: Default: 1.0
res_cn@cnLineLabelAngleF        = 0.
;res_cn@cnConstFLabelAngleF
;res_cn@cnHighLabelAngleF
;res_cn@cnInfoLabelAngleF
res_cn@cnLineLabelInterval      = 1                     ; default = 2

;res_cn@cnLineDashSegLenF       = 0.25                   ; Default: 0.15 (for a viewport width of 0.6)
;res_cn@cnLineLabelDensityF      = 0.2                   ; Default: 0.0
;res_cn@cnLineLabelDensityF      = 0.0                   ; Default: 0.0
;res_cn@cnLineThicknessF         = 1.0                  ; Default: 1.0
;res_cn@lbLabelStride            = 1 

res_cn@trYTensionF  = 30.
res_cn@trXTensionF  = 30.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;           resourse for Panel plot
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
resP                            = True
;resP@gsnMaximize                = True
resP@gsnPaperOrientation        = "landscape"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DIR_in0    = getenv("CLMREF")
DIR_in1    = getenv("FIXREF")
DIR_out    = getenv("FIGREF")

lev_var    = getenv("lev_var")
lat_var    = getenv("lat_var")

ncs=(/"HYCOM.AMOC_T2B.clim.nc"/)

print("loading ... "+ncs)

models=(/"HYCOM"/)

num_model=dimsizes(models)

wks   = gsn_open_wks("pdf",DIR_out+"ref_AMOCz_yz_plot")
gsn_define_colormap(wks,"NCV_jaisnd")

plot = new(num_model,graphic)
plt_con = new(num_model,graphic)
plt_mrk = new(num_model,graphic)
aaa     = new(num_model,graphic)
dum     = new(num_model,graphic)
txt     = new(num_model,graphic)
plt = new((/num_model/),graphic)
plt2= new((/num_model/),graphic)
plt3= new((/num_model/),graphic)

values = (/1000, 2000, 3000, 4000, 5000/)
cnLevels_Fill   = ispan(-28,28,1)
cnLevels_Line   = (/-30,-25,-20,-15,-10,-5,5,10,15,20,25,30/)
res_upper@cnLevels  = cnLevels_Fill
res_upper@gsnYAxisIrregular2Linear = True 
res_upper@tmYLMode                 = "Explicit"
res_upper@tmYLValues               = values
res_upper@tmYLMinorValues          = ispan(0,5000,200)
res_upper@tmYLLabels=(/"1000", "2000", "3000", "4000", "5000"/)

res_cn@cnLevels     = cnLevels_Line
res_cn@cnLevels     = cnLevels_Line

;-- polymarker resources
pmres                        =  True
pmres@gsMarkerColor          = "blue"
pmres@gsMarkerIndex = 16

  xpos=(/0.1,0.3,0.5,0.7,0.9/)+0.02
  ypos=(/0.815,0.605,0.4,0.195/)+0.12
do mm=0,num_model-1
  ;============================= load AMOC data and plot =============================
  nc  = ncs(mm)
  fin = addfile(DIR_in0+nc,"r")
  moc= fin->moc(0,:,:,0)
  lev= fin->$lev_var$
  dep_max= fin->dep_max(0,:)
  dep_000= fin->dep_000(0,:)
  dep_min= fin->dep_min(0,:)

  fin = addfile(DIR_in1+"HYCOM.lat_vo.fx.nc","r")
  lat= fin->$lat_var$
  if(lat(0).gt.lat(1))then
    lat=lat(::-1)
    moc=moc(:,::-1)
  end if
  moc&lat=(/lat/)

  res_upper@tmYLLabelsOn =True
  res_upper@tmXBLabelsOn =True

  res_upper@gsnLeftString          = "~F8~y~B~~F21~z~N~"
  res_upper@gsnCenterString        = models(mm)
  res_upper@gsnRightString         = "Sv"
  plot(mm) = gsn_csm_contour(wks,moc,res_upper)
  plt_con(mm) = gsn_csm_contour(wks,moc,res_cn)
  overlay(plot(mm),plt_con(mm))
  
  txres               = True                     ; text mods desired
;  txres@txFontHeightF = 0.01                     ; font smaller. default big

;txt(mm) = gsn_add_text(wks,plot(mm),models(mm),60,5000.,txres)
  a=mod(mm,5)
  b=mm/5
  xx=xpos(a)
  yy=ypos(b)
;  gsn_text_ndc(wks,models(mm),xx,yy,txres) 
  delete(xx)
  delete(yy)
  ;=============================     global maximum      =============================
  num_lat=dimsizes(lat)
  num_lev=dimsizes(lev)

  kdx=minind(abs(lev-500.))
  jdx=minind(abs(lat-20))
;  printVarSummary(moc)
;  print(kdx+" "+jdx+" "+num_lev+" "+num_lat)
;  delete(tmp)
  tmp=moc(kdx:num_lev-1,jdx:num_lat-1)
;  printVarSummary(tmp)

  dims = dimsizes(tmp)
  x1d  = ndtooned(tmp)
  inds = ind_resolve(maxind (x1d), dims)
  ilev = inds(0,0)
  ilat = inds(0,1)
  moc_max = max(tmp)
  lev_max = moc&lev(ilev+kdx)
  lat_max = moc&lat(ilat+jdx)
;  print(moc_max+", "+lev_max+", "+lat_max)
  delete(tmp)

;  print(" MODEL, AMOC_max,  Depth_of_max     Latitude_of_max")
;  print(models(mm)+" "+moc_max+", "+lev_max+", "+lat_max)
  pmres@gsMarkerSizeF          =  0.005
  plt_mrk(mm) = gsn_add_polymarker(wks, plot(mm), lat_max, lev_max, pmres) 

  ;============================= add global maximum line =============================
  x = lat_max
  y = lev_max
  pmres@gsMarkerIndex = 16
  aaa(mm) = gsn_add_polymarker(wks, plot(mm), x, y, pmres)
  delete(x)
  delete(y)

;  jdx=minind(abs(lat-26.))
   jdx=ilat+jdx
  lat_max=lat(jdx)

  plres = True
  plres@gsLineColor = "grey"
  plres@gsLineThicknessF = 3
  xx=(/lat_max,lat_max/)
  yy=(/0,6000/)
  dum(mm) = gsn_add_polyline(wks, plot(mm), xx, yy, plres)
  delete(xx)
  delete(yy)

if(1.lt.0)then
  jdx=minind(abs(lat-14.95))
  lat_max = lat(jdx)

  tmp=moc(kdx:num_lev-1,jdx)
  kdx=kdx+maxind(tmp)
  lev_max = lev(kdx)
  x = lat_max
  y = lev_max
  bbb = gsn_add_polymarker(wks, plot(mm), x, y, pmres)
  delete(tmp)
  delete(x)
  delete(y)

  plres = True
  plres@gsLineColor = "green"
  plres@gsLineThicknessF = 3
  xx=(/lat_max,lat_max/)
  yy=(/0,99/)
  dum = gsn_add_polyline(wks, plot(mm), xx, yy, plres)
  delete(xx)
  delete(yy)
end if

  ;============================= add marks at bounds     =============================
  pmres@gsMarkerColor          = "blue"
  pmres@gsMarkerSizeF          =  0.001

  pmres2 = pmres
  pmres2@gsMarkerColor          = "black"

  pmres3 = pmres
  pmres3@gsMarkerColor          = "red"

;  jdx=minind(abs(lat-26))

  ;------------------------------------ locate maximum ------------------------------------------------
  plt(mm) = gsn_add_polymarker(wks, plot(mm), lat, dep_max, pmres)
;  plt2(mm) = gsn_add_polymarker(wks, plot(mm), lat, dep_000, pmres2)
;  plt3(mm) = gsn_add_polymarker(wks, plot(mm), lat, dep_max, pmres3)
  ;------------------------------------ locate minimum ------------------------------------------------

  delete(moc)
  delete(lev)
  delete(lat)
  delete(x1d)
  delete(moc_max)
  delete(lev_max)
  delete(lat_max)
  delete(dep_max)
  delete(dep_000)
  delete(dep_min)
end do  ;;; model loop

;strs=(/"5", "4", "3", "2", "1", "0"/)
;strs=(/"0", "1", "2", "3", "4", "5"/)
xx=(/0.1,  0.1,  0.1,  0.1,  0.1,  0.1/)-0.09
yy=fspan(75.5,91,6)/100.+0.01
;gsn_text_ndc(wks,strs,xx,yy,txres) 
yy=yy-0.206
;gsn_text_ndc(wks,strs,xx,yy,txres) 
yy=yy-0.207
;gsn_text_ndc(wks,strs,xx,yy,txres) 
yy=yy-0.207
;gsn_text_ndc(wks,strs,xx,yy,txres) 
gsn_panel(wks,plot,(/1,1/),resP)
