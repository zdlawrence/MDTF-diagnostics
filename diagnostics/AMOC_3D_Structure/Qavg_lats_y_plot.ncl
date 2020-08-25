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

DIR_in0=getenv("OUTDIR")
DIR_in1=getenv("CLMREF")
DIR_out=getenv("FIGDIR")
lat0       = stringtofloat(getenv("LAT0"))

lat_var = getenv("lat_coord")

model=getenv("CASENAME")
yymm=getenv("YYYYMM")
yyyy=getenv("YYYY")

models=(/model/)

num_model=dimsizes(models)

ncs1=(/"HYCOM.trans_avg.clim.nc"/)

wks = gsn_open_wks("pdf",DIR_out+"Qavg_lats_y_plot")

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

ks=(/0,0,1,1/)
is=(/1,2,1,2/)

num_line=dimsizes(ks)

LAT=ispan(-90,90,1)*1.0
LAT@longname="latitude"
LAT@units="degree"
num_lat=dimsizes(LAT)

pos1="  Q~S~+~N~~H-17~~B~  1~N~~F21~ "
neg1=" -Q~S~-~N~~H-17~~B~  1~N~~F21~ "
pos2="  Q~S~+~N~~H-17~~B~  2~N~~F21~ "
neg2=" -Q~S~-~N~~H-17~~B~  2~N~~F21~ "
pos1="Transport "
neg1="Transport "
pos2="Transport "
neg2="Transport "
Tstrings=(/"Upper Northward", "- Upper Southward", "Lower Northward", "- Lower Southward"/)
Ystrings=(/pos1+"(Sv)", neg1+"(Sv)", pos2+"(Sv)", neg2+"(Sv)"/)
Xstrings=(/"","","Latitude","Latitude"/)
ifXB=(/False,False,True,True/)
factors = (/1,-1,1,-1/)

plot= new((/num_model,num_line/),graphic)
plot0= new(num_line,graphic)
plot1= new(num_line,graphic)
out=new((/num_model,num_line,num_lat/),"double",1e20)

do nn=0,num_line-1
   print("===================================================================================================="+nn)
   k=ks(nn)
   i=is(nn)
   ymin=fin1->trans(0,0,0,0)
   ymax=fin1->trans(0,0,0,0)
   ymin=min( (/ ymin, min(abs(fin1->trans(0,k,{-40:80},i))) /) )
   ymax=max( (/ ymax, max(fin1->trans(0,k,{-40:80},i)) /) )
   res@gsnCenterString=Tstrings(nn)
   res@tiXAxisString = Xstrings(nn)
   res@tiYAxisString = Ystrings(nn)
   res@tmXBLabelsOn  = ifXB(nn)
   print("HYCOM: "+ymin+" "+ymax)

   dist = (ymax-ymin)*0.1
   ymin = tointeger(ymin - dist - 0.5)
   ymax = tointeger(ymax + dist + 0.5)
if(nn.eq.0)then   
   res@trYMinF = ymin
   res@trYMaxF = ymax
   print(ymin+" "+ymax)
end if   
   res@trYMinF = -2.
   res@trYMaxF = 54.

   do mm=0,num_model-1
      model=models(mm)
      nc = DIR_in0+model+".trans_avg.clim.nc"
;      print("Loading ... "+nc)
      fin = addfile(nc,"r")
      var=fin->trans(k,:,i)
      ymin=min( (/ ymin, min(abs(var)) /) )
      ymax=max( (/ ymax, max(abs(var)) /) )
      print(model+": "+ymin+" "+ymax)
      delete(var)
   end do

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
      nc = DIR_in0+model+".trans_avg.clim.nc"
      print("Loading ... "+nc)
      fin = addfile(nc,"r")
      var = fin->trans(k,:,i)  ;;; T1 southward
      var = var * factors(nn)
      lat = fin->$lat_var$
      if(isMonotonic(lat).eq.-1)then
         lat=lat(::-1)
         var=var(::-1)
         var&lat=lat
      end if
      var=where(lat.lt.-34,var@_FillValue,var)
      res@xyLineColor = colors(mm+1)
      printMinMax(var,False)
      plot(mm,nn) = gsn_csm_xy (wks,lat,var,res)
      out(mm,nn,:)=linint1_n_Wrap(lat,var,False,LAT,0,0)
      delete(var)
      delete(lat)
   end do

   var  = dim_avg_n_Wrap(out,0)
   res@xyDashPattern    = 1
;   plot0(nn) = gsn_csm_xy (wks,LAT,var(nn,:),res)
   delete(var)

;----------------------------------------------------------------------------------------------------
; HYCOM
;----------------------------------------------------------------------------------------------------
   res@xyDashPattern    = 0
   var = fin1->trans(0,k,:,i)  ;;; T1 southward
   var = var * factors(nn)
   lat = fin1->$lat_var$
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

   overlay(plot(0,nn),plot1(nn))
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

lgres                    = True
lgres@lgLineColors       = (/colors(1), colors(0)/)
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
amres@amJust           = "BottomLeft"   ; Use bottom right corner of box 
amres@amParallelPosF   = -0.5 
amres@amOrthogonalPosF = 0.5 
lbid = gsn_create_legend(wks,nitems,labels,lgres)
annoid = gsn_add_annotation(plot(0,0),lbid,amres)  ; add legend to plot
;====================================================================================================
resP=True
;resP@gsnMaximize                = True
;resP@gsnPaperOrientation        = "landscape"
resP@tiMainString               = "Layered Transport"
;resP@gsnPanelDebug =True
resP@gsnPanelYF=(/-1,-1,0.49,0.49/)
resP@gsnPanelYWhiteSpacePercent = 0.01
gsn_panel(wks,plot(0,:),(/2,2/),resP)
;gsn_panel(wks,plot1    ,(/2,2/),resP)
;print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
end
