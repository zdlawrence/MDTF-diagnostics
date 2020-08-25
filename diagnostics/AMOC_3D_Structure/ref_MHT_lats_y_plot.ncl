begin
;***************************************************************************************************************************
;                                                       Shared Resoueses for the All Plots
;***************************************************************************************************************************
res                       = True
res@gsnDraw               = False
res@gsnFrame              = False

;--------------------------------------------------------------

;res@vpXF              = 0.15
;res@vpYF              = 0.95
;res@vpWidthF          = 0.6
;res@vpHeightF         = 0.6
res@xyLineThicknessF  = 2.0
res@tmXTLabelsOn      = False
res@tmXTOn            = False
res@trXMinF           = -38.
res@trXMaxF           = 80.
res@xyMarkLineMode    = "Lines"
res@xyLineThicknessF  = 2.0

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

DIR_in0=getenv("FIXREF")
DIR_in1=getenv("CLMREF")
DIR_out=getenv("FIGREF")
lat0   = stringtofloat(getenv("LAT0"))
models = str_split(getenv("MODELS"), " ,")

lat_var    = getenv("lat_var")

num_model=dimsizes(models)
;print("num_model: "+num_model)

ncs1=(/"HYCOM.MHT.clim.nc"/)

wks = gsn_open_wks("pdf",DIR_out+"ref_MHT_lats_y_plot")

if(num_model.le.20)then
  gsn_define_colormap(wks,"xbxu")
  colors=floattoint(fspan(1,21,num_model+1))
else
  gsn_define_colormap(wks,"amwg256")
  colors=floattoint(fspan(1,255,num_model))
end if

nc = DIR_in1+ncs1
;print("Loading ... "+nc)
fin1 = addfile(nc,"r")

;====================================================================================================
; k = 0       1       2         3         4         5   
;  upper, middle0, lower0, middle_min, lower_min, total  
; i = 0       1       2   
;   Net, Positive, Negative
;ks=(/5,0,1/)
;is=(/0,0,0/)
ks=(/5/)
is=(/0/)

num_line=dimsizes(ks)

LAT=ispan(-90,90,1)*1.0
LAT@longname="latitude"
LAT@units="degree"
num_lat=dimsizes(LAT)

pos1=" MHT "
neg1=" MHT~B~1~N~~F21~ "
neg2=" MHT~B~2~N~~F21~ "
Ystrings=(/pos1+"(PW)", neg1+"(PW)", neg2+"(PW)"/)
Xstrings=(/"Latitude","Latitude","Latitude"/)
ifXB=(/True,True,True/)
factors = (/1,1,1/)

plot= new((/num_model,num_line/),graphic)
plot0= new(num_line,graphic)
plot1= new(num_line,graphic)
out=new((/num_model,num_line,num_lat/),"double",1e20)

do nn=0,num_line-1
;====================================================================================================
   k=ks(nn)
   i=is(nn)
   ymin=new(1,"double")
   ymax=new(1,"double")
   ymin=min( (/ ymin, min(fin1->MHT(0,k,{-40:80},i)) /) )
   ymax=max( (/ ymax, max(fin1->MHT(0,k,{-40:80},i)) /) )
   res@tiXAxisString = Xstrings(nn)
   res@tiYAxisString = Ystrings(nn)
   res@tmXBLabelsOn  = ifXB(nn)
;   print("HYCOM: "+ymin+" "+ymax)

   do mm=0,num_model-1
      model=models(mm)
      DIR_in1=getenv("WKDIR")+"/MDTF_"+model+"/AMOC_3D_Structure/model/netCDF/"
      nc = DIR_in1+model+".MHT.clim.nc"
;      print("Loading ... "+nc)
      fin = addfile(nc,"r")
      var=fin->MHT(k,{-40:80},i)
      ymin=min( (/ ymin, min(var) /) )
      ymax=max( (/ ymax, max(var) /) )
;      print(model+": "+ymin+" "+ymax)
      delete(var)
   end do

   dist = (ymax-ymin)*0.1
   ymin = ymin - dist
   ymax = ymax + dist
;   res@trYMinF = ymin
;   res@trYMaxF = ymax
   res@trYMinF = -0.1
   res@trYMaxF = 1.5
;   print(ymin+" "+ymax)
   delete(ymax)
   delete(ymin)

;----------------------------------------------------------------------------------------------------
; 0:4, (,Smax], (Smax,S000], (S000,), (Smax,Smin], (Smin,)
; 0:3, net, pos, neg, abs

   res@xyDashPattern    = 0
;----------------------------------------------------------------------------------------------------
; MODELS
;----------------------------------------------------------------------------------------------------
   do mm=0,num_model-1
      model=models(mm)
      DIR_in1=getenv("WKDIR")+"/MDTF_"+model+"/AMOC_3D_Structure/model/netCDF/"
      nc = DIR_in1+model+".MHT.clim.nc"
      print("Loading ... "+nc)
      fin = addfile(nc,"r")
      var = fin->MHT(k,:,i)  ;;; T1 southward
      var = var * factors(nn)
      lat = fin->$lat_var$
      if(isMonotonic(lat).eq.-1)then
         lat=lat(::-1)
         var=var(::-1)
         var&lat=lat
      end if
      var=where(lat.lt.-34,var@_FillValue,var)
      res@xyLineColor = colors(mm)
;      printMinMax(var,False)
;      plot(mm,nn) = gsn_csm_xy (wks,lat,var,res)
      out(mm,nn,:)=linint1_n_Wrap(lat,var,False,LAT,0,0)
      delete(var)
      delete(lat)
   end do

   var  = dim_avg_n_Wrap(out,0)
   res@xyLineColor = 1
   res@xyDashPattern    = 1
;   plot0(nn) = gsn_csm_xy (wks,LAT,var(nn,:),res)
   delete(var)

;----------------------------------------------------------------------------------------------------
; HYCOM
;----------------------------------------------------------------------------------------------------
   res@xyDashPattern    = 0
   var = fin1->MHT(0,k,:,i)  ;;; T1 southward
   var = var * factors(nn)
   lat = fin1->$lat_var$
   if(isMonotonic(lat).eq.-1)then
      lat=lat(::-1)
      var=var(::-1)
      var&lat=lat
   end if
   var=where(lat.lt.-34,var@_FillValue,var)
   delete(res@xyLineColor)
   res@xyLineColor = "blue"
;   res@gsnCenterString        = "HYCOM"
   plot1(nn) = gsn_csm_xy (wks,lat,var,res)
   delete(var)
   delete(lat)

;   do mm=1,num_model-1
;     overlay(plot(0,nn),plot(mm,nn))
;   end do

;   overlay(plot(0,nn),plot1(nn))
;   overlay(plot(0,nn),plot0(nn))
end do ;;; panel loop

  lnres               = True
  mkres               = True
  txres               = True         ; Text resources
;  txres@txFontHeightF = 0.012
  txres@txJust        = "CenterLeft"
  xpos= 0.700
;  xpos= 0.785
  if (num_model.le.20)then
     ypos=(50 + 3 *( ispan(0,num_model,1)-num_model/2 ) )/100.
  else
     ypos=fspan(0.35,0.95,num_model+1)
  end if
  ypos=ypos(::-1)

  mstring = "_"
  fontnum = 30
  xoffset = 0.0
  yoffset = 0.0
  ratio   = 1.0
  size    = 1.0
  angle   = 0.0

  new_index = NhlNewMarker(wks, mstring, fontnum, xoffset, yoffset, ratio, size, angle)

  colorss=new(num_model+1,typeof(colors))
  modelss=new(num_model+1,typeof(models))
  colorss(0)=1
  modelss(0)="HYCOM"
  colorss(1:num_model)=(/colors(1:num_model)/)
  modelss(1:num_model)=(/models/)

  do mm=0,num_model
     mkres@gsMarkerThicknessF = 3.0
     mkres@gsMarkerSizeF      = 0.015
     mkres@gsMarkerIndex      = new_index
     mkres@gsMarkerColor      = colorss(mm)
     lnres@gsLineColor = colorss(mm)
     lnres@gsLineThicknessF = 3
     lnres@gsLineDashPattern= 1
     xxx = xpos
     yyy = ypos(mm)
;     gsn_polymarker_ndc(wks,           xxx,yyy,mkres)
;;     gsn_polyline_ndc(wks,xxx,yyy,lnres)
;     gsn_text_ndc(wks,modelss(mm), xxx+0.02,yyy,txres)
  end do
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
    dum(i) = gsn_add_polygon(wks,plot1,(/x0(i),x1(i),x2(i),x3(i),x4(i)/),(/y0(i),y1(i),y2(i),y3(i),y4(i)/),gres)
    dum(i) = gsn_add_polyline(wks,plot1,(/x0(i),x1(i),x2(i),x3(i),x4(i)/),(/y0(i),y1(i),y2(i),y3(i),y4(i)/),gres)
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
    centers(t)   = gsn_add_polymarker(wks,plot1,xx(t),yy(t),polyres)
    error_bar(t) = gsn_add_polyline(wks,plot1,(/xx(t),xx(t)/),(/yy(t)+dd(t),yy(t)-dd(t)/), polyres)
  end do

delete(xx)
delete(yy)
delete(dd)
  xx=(/26.5,65.4/)
  yy=(/1.25,0.3/)
  polyres@gsMarkerSizeF     = .06
  polyres@gsMarkerColor     = "black"
  dot0 = gsn_add_polymarker(wks,plot1,xx,yy,polyres)

;====================================================================================================
resP=True
;resP@gsnMaximize                = True
resP@gsnPaperOrientation        = "landscape"
;resP@gsnPanelDebug =True
;resP@gsnPanelYF=(/0.975, 0.663, 0.350/)+0.02
;resP@tiMainString="HYCOM"
;gsn_panel(wks,plot(0,:),(/3,1/),resP)
gsn_panel(wks,plot1,(/1,1/),resP)
;print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
end
