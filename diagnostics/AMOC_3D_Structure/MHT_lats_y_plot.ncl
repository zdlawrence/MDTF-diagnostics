begin
;***************************************************************************************************************************
;                                                       Shared Resoueses for the All Plots
;***************************************************************************************************************************
  res                       = True
  res@gsnDraw               = False
  res@gsnFrame              = False

  res@trXMinF               = -38
  res@trXMaxF               = 70.
;----------------------------- T1 -----------------------------
  res@trYMinF               = -0.1
  res@trYMaxF               = 1.5
;--------------------------------------------------------------

  ;res@vpXF              = 0.15
  ;res@vpYF              = 0.95
  ;res@vpWidthF          = 0.6
  ;res@vpHeightF         = 0.6

  res@xyLineThicknessF      = 2.0

;  res@tiYAxisFontHeightF      = 0.025
;  res@tiXAxisFontHeightF      = 0.025
  res@tiXAxisString             = "Latitude"
  res@tiYAxisString             = "MHT (PW)"
;  res@tiYAxisString             = "~F8~q~S~+~N~~H-17~~B~1~N~~F21~ (~S~o~N~C)"

  res@tmXTLabelsOn            = False
  res@tmXTOn                  = False

;res@tmBorderThicknessF= 3
;res@tmXTMajorThicknessF=3
;res@tmXTMinorThicknessF=2
;res@tmXBMajorThicknessF=3
;res@tmXBMinorThicknessF=2
;res@tmYLMajorThicknessF=3
;res@tmYLMinorThicknessF=2
;res@tmYRMajorThicknessF=3
;res@tmYRMinorThicknessF=2
;res@gsnStringFontHeightF=0.028

DIR_in0 = getenv("OUTDIR")
DIR_in1 = getenv("CLMREF")
DIR_out = getenv("FIGDIR")
lat0    = stringtofloat(getenv("LAT0"))

lat_var = getenv("lat_coord")

model=getenv("CASENAME")
yymm=getenv("YYYYMM")
yyyy=getenv("YYYY")

models=(/model/)
num_model=dimsizes(models)

ncs0=(/model+".MHT.clim.nc"/)
ncs1=(/"HYCOM.MHT.clim.nc"/)

wks = gsn_open_wks("pdf",DIR_out+"MHT_lats_y_plot")
;if(num_model.le.20)then
;  gsn_define_colormap(wks,"xbxu")
;  colors=floattoint(fspan(1,21,num_model+1))
;else
;  gsn_define_colormap(wks,"amwg256")
;  colors=floattoint(fspan(1,255,num_model))
;end if
gsn_define_colormap(wks,"amwg256")

LAT=ispan(-90,90,1)*1.0
LAT@longname="latitude"
LAT@units="degree"
num_lat=dimsizes(LAT)

;res@gsnCenterString = model

;====================================================================================================
; k = 0       1       2         3         4         5
;  upper, middle0, lower0, middle_min, lower_min, total  
; i = 0       1       2
;   Net, Positive, Negative
ks=(/5/)
is=(/0/)
DashPatterns = (/0,0/)
factors = (/1,1/)
colors=(/"black","red","blue"/)

num_line=dimsizes(ks)
plot = new(num_line,graphic)
plot1= new(num_line,graphic)
out=new((/num_line,num_lat/),"double",1e20)

nc = DIR_in0+ncs0
print("Loading ... "+nc)
fil = addfile(nc,"r")

do mm=0,num_line-1
   k=ks(mm)
   i=is(mm)
   var = fil->MHT(k,:,i)  ;;; T1 southward
   var  = var * factors(mm)
   lat = fil->$lat_var$
   if(isMonotonic(lat).eq.-1)then
      lat=lat(::-1)
      var=var(::-1)
      var&lat=lat
   end if
   var=where(lat.lt.-34,var@_FillValue,var)
   res@xyLineColor = colors(1)
   res@xyDashPattern = DashPatterns(mm)  
;   printMinMax(var,False)
   plot(mm) = gsn_csm_xy (wks,lat,var,res)
   jjj=ind_nearest_coord(lat0,lat,0)
;   print(models+ " " + var(jjj)) 
   out(mm,:)=linint1_n_Wrap(lat,var,False,LAT,0,0)
   delete(var)
   delete(lat)
end do

nc = DIR_in1+ncs1
print("Loading ... "+nc)
fin1 = addfile(nc,"r")

DashPatterns = (/0,0/)
do mm=0,num_line-1
   k=ks(mm)
   i=is(mm)
   var = fin1->MHT(0,k,:,i)  ;;; T1 southward
   var  = var * factors(mm)
   lat = fin1->$lat_var$
   if(isMonotonic(lat).eq.-1)then
      lat=lat(::-1)
      var=var(::-1)
      var&lat=lat
   end if
   var=where(lat.lt.-34,var@_FillValue,var)
   res@xyLineColor = colors(2)
   res@xyDashPattern = DashPatterns(mm)  
;   printMinMax(var,False)
   plot1(mm) = gsn_csm_xy (wks,lat,var,res)
   jjj=ind_nearest_coord(lat0,lat,0)
;   print(models+ " " + var(jjj)) 
   delete(var)
   delete(lat)
end do

;do mm=1,num_line-1
;  overlay(plot(0),plot(mm))
;end do

do mm=0,num_line-1
  overlay(plot(0),plot1(mm))
end do

;====================================================================================================
lgres                    = True
lgres@lgLineColors       = (/colors(1), colors(2)/)
lgres@lgBoxLinesOn       = False
lgres@lgPerimOn          = False
lgres@lgLineThicknessF   = 3 
lgres@lgItemType         = "Lines"        ; show lines only (default)
;lgres@lgLabelFontHeightF = .08            ; legend label font thickness
lgres@vpWidthF           = 0.18           ; width of legend (NDC)
lgres@vpHeightF          = 0.15           ; height of legend (NDC)
lgres@lgPerimOn          = False
lgres@lgPerimThicknessF  = 2.0            ; thicken the box perimeter
lgres@lgMonoDashIndex    = False
lgres@lgDashIndexes      = (/0,0/)
pos1=""
;pos1=" MHT "
;neg1=" MHT~B~ 1~N~ "
;neg2="-MHT~B~ 2~N~ "
;labels = (/neg2+model,neg1+model,pos1+model/)
labels = (/pos1+model, pos1+"HYCOM"/)
nitems = dimsizes(labels)

amres                  = True
amres@amJust           = "BottomLeft"   ; Use bottom right corner of box 
amres@amParallelPosF   = -0.1 
amres@amOrthogonalPosF = 0.5
lbid0 = gsn_create_legend(wks,nitems,labels,lgres)
annoid0 = gsn_add_annotation(plot(0),lbid0,amres)  ; add legend to plot

;amres@amSide           = "Top"
;amres@amJust           = "CenterCenter"
;amres@amParallelPosF   = -0.35
;amres@amOrthogonalPosF = -0.43
;lgres@lgDashIndexes      = (/1,1,1/)
;labels = (/neg2+"HYCOM", neg1+"HYCOM", pos1+"HYCOM"/)
;labels = (/pos1+"HYCOM"/)
;lbid1 = gsn_create_legend(wks,nitems,labels,lgres)
;amres@amParallelPosF   = -0.05
;annoid1 = gsn_add_annotation(plot(0),lbid1,amres)  ; add legend to plot
;====================================================================================================
  gres                 = True
  gres@gsLineColor     = "black"
  gres@gsFillBackgroundColor = "Transparent"
;  gres@gsFillColor     = "yellow"
;  gres@tfPolyDrawOrder = "Draw"  ; this can be used for polylines, polymarkers, or polygons

  x0 = (/65,     59,   53,   45,   40,   36,   24,    8,   -5,  -11,  -15,  -19,  -23/)
  x1 = (/65,     59,   53,   45,   40,   36,   24,    8,   -5,  -11,  -15,  -19,  -23/)
  x2 = (/67,     60,   56,   48,   41,   38,   26,   11,    0,  -12,  -16,  -20,  -25/)
  x3 = (/67,     60,   56,   48,   41,   38,   26,   11,    0,  -12,  -16,  -20,  -25/)
  x4 = (/65,     59,   53,   45,   40,   36,   24,    8,   -5,  -11,  -15,  -19,  -23/)
  y0 = (/0.26, 0.25, 0.29, 0.34, 0.66, 0.66, 0.93, 0.74, 0.51, 0.30, 0.18, 0.41, 0.15/)
  y1 = (/0.32, 0.61, 0.67, 0.82, 0.88, 1.10, 1.47, 1.40, 1.15, 0.82, 0.60, 0.75, 0.53/)
  y2 = (/0.32, 0.61, 0.67, 0.82, 0.88, 1.10, 1.47, 1.40, 1.15, 0.82, 0.60, 0.75, 0.53/)
  y3 = (/0.26, 0.25, 0.29, 0.34, 0.66, 0.66, 0.93, 0.74, 0.51, 0.30, 0.18, 0.41, 0.15/)
  y4 = (/0.26, 0.25, 0.29, 0.34, 0.66, 0.66, 0.93, 0.74, 0.51, 0.30, 0.18, 0.41, 0.15/)
  num_poly=dimsizes(x0)
  dum = new(num_poly,graphic)
  do i=0,num_poly-1
    dum(i) = gsn_add_polygon(wks,plot(0),(/x0(i),x1(i),x2(i),x3(i),x4(i)/),(/y0(i),y1(i),y2(i),y3(i),y4(i)/),gres)
    dum(i) = gsn_add_polyline(wks,plot(0),(/x0(i),x1(i),x2(i),x3(i),x4(i)/),(/y0(i),y1(i),y2(i),y3(i),y4(i)/),gres)
  end do

;************************************************
; add error bars
;************************************************  
  polyres                   = True                       ; marker resources
  polyres@gsMarkerIndex     = 1                          ; index for circle
  polyres@gsMarkerSizeF     = .001                       ; size 
  polyres@gsMarkerColor     = "black"                     ; size 
  polyres@gsLineThicknessF  = 2 
  polyres@gsLineColor       = "black"
  
;  xx=(/66.5, 59.5, 54.5, 46.5, 40.5, 37.0, 25.0, 15.5, 9.5,  -2.5, -11.5, -15.5, -19.5, -24.0/) 
;  yy=(/0.29, 0.43, 0.48, 0.58, 0.77, 0.88, 1.20, 1.05, 1.07, 0.83,  0.56,  0.39,  0.58,  0.34/)
;  dd=(/0.03, 0.18, 0.19, 0.24, 0.11, 0.22, 0.22, 0.21, 0.33, 0.32,  0.26,  0.21,  0.17,  0.19/)

  xx=(/15.55/)
  yy=(/1.05/)
  dd=(/0.21/)

  num_bar=dimsizes(xx)
  error_bar = new(num_bar,graphic)
  centers = new(num_bar,graphic)
  do t=0,num_bar-1
;print(""+t)
    centers(t)   = gsn_add_polymarker(wks,plot(0),xx(t),yy(t),polyres)
    error_bar(t) = gsn_add_polyline(wks,plot(0),(/xx(t),xx(t)/),(/yy(t)+dd(t),yy(t)-dd(t)/), polyres)
  end do

delete(xx)
delete(yy)
delete(dd)
  xx=(/26.5,65.4/)
  yy=(/1.25,0.3/)
  polyres@gsMarkerSizeF     = .06
  polyres@gsMarkerColor     = "black"
  dot0 = gsn_add_polymarker(wks,plot(0),xx,yy,polyres)
;====================================================================================================
;;;;;; Maximize output on the page and draw everything
pres=True
;pres@gsnPanelDebug =True
;maximize_output(wks,pres)  ; Maximize plot on page
draw(plot(0))
frame(wks)

;print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
end
