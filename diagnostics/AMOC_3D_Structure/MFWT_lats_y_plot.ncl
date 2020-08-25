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
  res@trYMinF               = -0.8
  res@trYMaxF               = 0.8
;--------------------------------------------------------------

  ;res@vpXF              = 0.15
  ;res@vpYF              = 0.95
  ;res@vpWidthF          = 0.6
  ;res@vpHeightF         = 0.6

  res@xyLineThicknessF      = 2.0

;  res@tiYAxisFontHeightF      = 0.025
;  res@tiXAxisFontHeightF      = 0.025
  res@tiXAxisString             = "Latitude"
  res@tiYAxisString             = "MFWT (Sv)"
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

DIR_in0=getenv("OUTDIR")
DIR_in1=getenv("CLMREF")
DIR_out=getenv("FIGDIR")
lat0       = stringtofloat(getenv("LAT0"))

lat_var = getenv("lat_var")

model=getenv("CASENAME")
yymm=getenv("YYYYMM")
yyyy=getenv("YYYY")

models=(/model/)
num_model=dimsizes(models)

ncs0=(/model+".MFWT.clim.nc"/)
ncs1=(/"HYCOM.MFWT.clim.nc"/)

wks = gsn_open_wks("pdf",DIR_out+"MFWT_lats_y_plot")
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
fil = addfile(nc,"r")
do mm=0,num_line-1
   k=ks(mm)
   i=is(mm)
   var = fil->MFWT(k,:,i)  ;;; T1 southward
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
   var = fin1->MFWT(0,k,:,i)  ;;; T1 southward
   var  = var * factors(mm)
   lat = fin1->$lat_var$
   if(isMonotonic(lat).eq.-1)then
      lat=lat(::-1)
      var=var(::-1)
      var&lat=lat
   end if
   var=where(lat.lt.-34,var@_FillValue,var)
;   res@xyLineColor = colors(0)
   res@xyLineColor = colors(2)
   res@xyDashPattern = DashPatterns(mm)  
;   printMinMax(var,False)
   plot1(mm) = gsn_csm_xy (wks,lat,var,res)
   jjj=ind_nearest_coord(lat0,lat,0)
;   print(models+ " " + var(jjj)) 
   delete(var)
   delete(lat)
end do

do mm=1,num_line-1
;  overlay(plot(0),plot(mm))
end do

do mm=0,num_line-1
  overlay(plot(0),plot1(mm))
end do

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
;pos1="MFWT "
;neg1="MFWT~B~ 1~N~ "
;neg2="MFWT~B~ 2~N~ "
;labels = (/neg2+model,neg1+model,pos1+model/)
labels = (/pos1+model, pos1+"HYCOM"/)
nitems = dimsizes(labels)

amres                  = True
amres@amJust           = "BottomLeft"   ; Use bottom right corner of box 
amres@amParallelPosF   = -0.2 
amres@amOrthogonalPosF = 0.5
lbid0 = gsn_create_legend(wks,nitems,labels,lgres)
annoid0 = gsn_add_annotation(plot(0),lbid0,amres)  ; add legend to plot

;amres@amParallelPosF   = -0.35
;amres@amOrthogonalPosF = -0.43
;amres@amSide           = "Top"
;amres@amJust           = "CenterCenter"
;lgres@lgDashIndexes      = (/1,1,1/)
;labels = (/neg2+"HYCOM", neg1+"HYCOM", pos1+"HYCOM"/)
;lbid1 = gsn_create_legend(wks,nitems,labels,lgres)
;amres@amParallelPosF   = -0.05
;annoid1 = gsn_add_annotation(plot(0),lbid1,amres)  ; add legend to plot
;====================================================================================================
;************************************************
; add error bars
;************************************************
  polyres                   = True                       ; marker resources
  polyres@gsMarkerIndex     = 6                         ; index for circle
  polyres@gsMarkerColor     = "black"
  polyres@gsMarkerSizeF     = .012
  polyres@gsLineThicknessF  = 2 
  polyres@gsMarkerThicknessF= 2
  xx=(/58,58,55,45,45,35,35,24,24,24, 11,-11,-11,-12,-19, 23/)
  yy=-(/13,30,17,25,26,39,49, 3,44,53,-12, 23, 15, 33, 10,-12/)/100.

  mb  = gsn_add_polymarker(wks,plot(0),xx,yy,polyres)

delete(xx)
delete(yy)
  polyres@gsMarkerIndex     = 9 
  polyres@gsMarkerSizeF     = .015
  xx=(/59, 53, 45, 36,  24,-16,-24/)
  yy=-(/588,383,387,405,349,253,-95/)/1000.

  kb  = gsn_add_polymarker(wks,plot(0),xx,yy,polyres)

delete(xx)
delete(yy)
  polyres@gsMarkerIndex     = 16
  polyres@gsMarkerColor     = "black"
  polyres@gsMarkerSizeF     = .015
  xx=(/26.5,65.4/)
  yy=(/-0.37,-0.14/)

  db  = gsn_add_polymarker(wks,plot(0),xx,yy,polyres)
delete(xx)
delete(yy)
;=============================== add zero line ===============================
  plx = (/res@trXMinF,res@trXMaxF/)
  ply = (/0,0/)

  plres = True
  plres@gsLineDashPattern = 2
  plres@gsLineColor = "black"
  dum1 = gsn_add_polyline(wks, plot(0), plx, ply, plres)

;====================================================================================================

;;;;;; Maximize output on the page and draw everything
pres=True
;pres@gsnPanelDebug =True
;maximize_output(wks,pres)  ; Maximize plot on page
draw(plot(0))
frame(wks)

;print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
end
