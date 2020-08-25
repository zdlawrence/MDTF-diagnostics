begin
;***************************************************************************************************************************
;                                                       Shared Resoueses for the All Plots
;***************************************************************************************************************************
  res                       = True
  res@gsnDraw               = False
  res@gsnFrame              = False

;--------------------------------------------------------------

  ;res@vpXF              = 0.15
  ;res@vpYF              = 0.99
  ;res@vpWidthF          = 0.6
  ;res@vpHeightF         = 0.6
  res@xyLineThicknessF      = 2.0
  res@tmXTLabelsOn            = False
  res@tmXTOn                  = False
res@trXMinF               = -38.
res@trXMaxF               = 80.
res@xyMarkLineMode   ="Lines"
res@xyLineThicknessF = 2.0

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

DIR_in0=getenv("CLMREF")
DIR_out=getenv("FIGREF")
lat0       = stringtofloat(getenv("LAT0"))
models     = str_split(getenv("MODELS"), " ,")

so_var     = getenv("so_var")
lat_var    = getenv("lat_coord")

num_model=dimsizes(models)

ncs0=(/"HYCOM.so_wgt.clim.nc"/)

wks = gsn_open_wks("pdf",DIR_out+"ref_Swgt_lats_y_plot")
if(num_model.le.20)then
  gsn_define_colormap(wks,"xbxu")
  colors=floattoint(fspan(1,21,num_model+1))
else
  gsn_define_colormap(wks,"amwg256")
  colors=floattoint(fspan(1,255,num_model))
end if

nc = DIR_in0+ncs0
print("Loading ... "+nc)
fin0 = addfile(nc,"r")

ks=(/0,0,1,1/)
is=(/1,2,1,2/)

num_line=dimsizes(ks)

LAT=ispan(-90,90,1)*1.0
LAT@longname="latitude"
LAT@units="degree"
num_lat=dimsizes(LAT)

pos1=" S~S~+~N~~H-17~~B~  1~N~~F21~ "
neg1=" S~S~-~N~~H-17~~B~  1~N~~F21~ "
pos2=" S~S~+~N~~H-17~~B~  2~N~~F21~ "
neg2=" S~S~-~N~~H-17~~B~  2~N~~F21~ "
pos1="Salinity "
neg1="Salinity "
pos2="Salinity "
neg2="Salinity "
Tstrings=(/"Upper Northward", "Upper Southward", "Lower Northward", "Lower Southward"/)
Ystrings=(/pos1+"(psu)", neg1+"(psu)", pos2+"(psu)", neg2+"(psu)"/)
Xstrings=(/"","","Latitude","Latitude"/)
ifXB=(/False,False,True,True/)
factors = (/1,1,1,1/)

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
   ymin=min( (/ ymin, min(abs(fin0->$so_var$(0,k,{-40:80},i))) /) )
   ymax=max( (/ ymax, max(fin0->$so_var$(0,k,{-40:80},i)) /) )
   res@gsnCenterString=Tstrings(nn)
   res@tiXAxisString = Xstrings(nn)
   res@tiYAxisString = Ystrings(nn)
   res@tmXBLabelsOn  = ifXB(nn)
;   print("HYCOM: "+ymin+" "+ymax)

   do mm=0,num_model-1
      model=models(mm)
      DIR_in1=getenv("WKDIR")+"/MDTF_"+model+"/AMOC_3D_Structure/model/netCDF/"
      nc = DIR_in1+model+".so_wgt.clim.nc"
      print("Loading ... "+nc)
      fin = addfile(nc,"r")
      var=fin->$so_var$(k,{-40:80},i)
      ymin=min( (/ ymin, min(abs(var)) /) )
      ymax=max( (/ ymax, max(abs(var)) /) )
;      print(model+": "+ymin+" "+ymax)
      delete(var)
   end do

   dist = (ymax-ymin)*0.1
   ymin = ymin - dist
   ymax = ymax + dist
;   res@trYMinF = ymin
;   res@trYMaxF = ymax
   res@trYMinF = 32.5
   res@trYMaxF = 37.0
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
      nc = DIR_in1+model+".so_wgt.clim.nc"
      print("Loading ... "+nc)
      fin = addfile(nc,"r")
      var = fin->$so_var$(k,:,i)  ;;; T1 southward
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
      plot(mm,nn) = gsn_csm_xy (wks,lat,var,res)
      out(mm,nn,:)=linint1_n_Wrap(lat,var,False,LAT,0,0)
      delete(var)
      delete(lat)
   end do

   var  = dim_avg_n_Wrap(out,0)
   res@xyDashPattern    = 1
   plot0(nn) = gsn_csm_xy (wks,LAT,var(nn,:),res)
   delete(var)

;----------------------------------------------------------------------------------------------------
; HYCOM
;----------------------------------------------------------------------------------------------------
   res@xyDashPattern    = 0
   var = fin0->$so_var$(0,k,:,i)  ;;; T1 southward
   var = var * factors(nn)
   lat = fin0->$lat_var$
   if(isMonotonic(lat).eq.-1)then
      lat=lat(::-1)
      var=var(::-1)
      var&lat=lat
   end if
   var=where(lat.lt.-34,var@_FillValue,var)
   res@xyLineColor = 1
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
resP=True
;resP@gsnMaximize                = True
;resP@gsnPaperOrientation        = "landscape"
resP@tiMainString               = "Transport weighted Salinity"
;resP@gsnPanelDebug =True
resP@gsnPanelYF=(/-1,-1,0.49,0.49/)
;gsn_panel(wks,plot(0,:),(/3,1/),resP)
resP@gsnPanelYWhiteSpacePercent = 0.01
gsn_panel(wks,plot1,(/2,2/),resP)
;print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
end
