begin
;***************************************************************************************************************************
;                                                       Shared Resoueses for the All Plots
;***************************************************************************************************************************
  res                       = True
  res@gsnDraw               = False
  res@gsnFrame              = False

;--------------------------------------------------------------

;  res@vpXF              = 0.2
;  res@vpYF              = 0.8
;  res@vpWidthF          = 0.5
;  res@vpHeightF         = 0.5
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

;res@tmYLLabelDeltaF =-0.5
;res@tiDeltaF        = 1.0

DIR_in0=getenv("CLMREF")
DIR_in1=getenv("WKDIR")
DIR_out=getenv("FIGREF")
lat0       = stringtofloat(getenv("LAT0"))
models = str_split(getenv("MODELS"), " ,") 
num_model=dimsizes(models)

thetao_var  = getenv("thetao_var")
lev_var = getenv("lev_coord")
lat_var = getenv("lat_coord")

ncs0="HYCOM.trans_avg.clim.nc"

wks = gsn_open_wks("pdf",DIR_out+"/sum_Qavg_lats_y_plot")

if(num_model.le.20)then
  gsn_define_colormap(wks,"xbxu")
  if(num_model.eq.1)then
    colors=(/2/)
  else
    colors=floattoint(fspan(2,21,num_model))
  end if
else
  gsn_define_colormap(wks,"amwg256")
  colors=floattoint(fspan(2,255,num_model))
end if
orders=ispan(1,num_model+2,1)

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

nc = DIR_in0+ncs0
;print("Loading ... "+nc)
fin0 = addfile(nc,"r")

do nn=0,num_line-1
   if(nn.eq.1 .or. nn.eq.3)then
      res@tmYLOn       = False
      res@tmYROn       = False
      res@tmYLLabelsOn = False
      res@tiYAxisString = ""
   else
      res@tmYLOn       = True
      res@tmYROn       = False
      res@tmYLLabelsOn = True
      res@tiYAxisString = Ystrings(nn)
   end if
;   print("===================================================================================================="+nn)
   k=ks(nn)
   i=is(nn)
   ymin=fin0->trans(0,0,0,0)
   ymax=fin0->trans(0,0,0,0)
   ymin=min( (/ ymin, min(abs(fin0->trans(0,k,{-40:80},i))) /) )
   ymax=max( (/ ymax, max(fin0->trans(0,k,{-40:80},i)) /) )
   res@gsnCenterString=Tstrings(nn)
   res@tiXAxisString = Xstrings(nn)
   res@tmXBLabelsOn  = ifXB(nn)
;   print("HYCOM: "+ymin+" "+ymax)

   dist = (ymax-ymin)*0.1
   ymin = tointeger(ymin - dist - 0.5)
   ymax = tointeger(ymax + dist + 0.5)
if(nn.eq.0)then   
   res@trYMinF = ymin
   res@trYMaxF = ymax
;   print(ymin+" "+ymax)
end if   
   res@trYMinF = -2.
   res@trYMaxF = 58.

   do mm=0,num_model-1
      model=models(mm)
      DIR_in=DIR_in1+"model/netCDF/"
      nc=model+".trans_avg.clim.nc"
;      print("Loading ... "+nc)
      fin = addfile(DIR_in+nc,"r")
      var=fin->trans(k,:,i)
      ymin=min( (/ ymin, min(abs(var)) /) )
      ymax=max( (/ ymax, max(abs(var)) /) )
;      print(model+": "+ymin+" "+ymax)
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
   res@xyLineThicknessF = 2.0
   do mm=0,num_model-1
      model=models(mm)
      DIR_in=DIR_in1+"model/netCDF/"
      nc=model+".trans_avg.clim.nc"
;      print("Loading ... "+nc)
      fin = addfile(DIR_in+nc,"r")
      var = fin->trans(k,:,i)  ;;; T1 southward
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

   ; var  = dim_avg_n_Wrap(out,0)
   ; res@xyLineThicknessF = 5.0
   ; res@xyDashPattern    = 1
   ; res@xyLineColor      = 1
   ; plot0(nn) = gsn_csm_xy (wks,LAT,var(nn,:),res)
   ; delete(var)

;----------------------------------------------------------------------------------------------------
; HYCOM
;----------------------------------------------------------------------------------------------------
   res@xyLineThicknessF = 5.0
   res@xyDashPattern    = 0
   res@xyLineColor      = 1
   var = fin0->trans(0,k,:,i)  ;;; T1 southward
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

   do mm=1,num_model-1
     overlay(plot(0,nn),plot(mm,nn))
   end do

   overlay(plot(0,nn),plot1(nn))
   ; overlay(plot(0,nn),plot0(nn))
end do ;;; panel loop

;---------------------------------------------------------------------------------------------------- legend
colorss=new(num_model+1,typeof(colors))
modelss=new(num_model+1,typeof(models))
dashess=ispan(1,num_model+1,1)
colorss(0:num_model-1)=(/colors/)
modelss(0:num_model-1)=(/models/)
dashess(0:num_model-1)=0
colorss(num_model)=1
modelss(num_model)="HYCOM"
dashess(num_model)=0
;print(dashess)

lgres                    = True
lgres@lgBoxLinesOn       = False
lgres@lgPerimOn          = False
lgres@lgLineThicknessF   = 5 
lgres@lgItemType         = "Lines"        ; show lines only (default)
lgres@lgLabelFontHeightF = 0.08           ; legend label font thickness
lgres@vpWidthF           = 0.15            ; width of legend (NDC)
lgres@vpHeightF          = 0.66          ; height of legend (NDC)
;lgres@lgPerimThicknessF  = 2.0            ; thicken the box perimeter
lgres@lgMonoDashIndex    = False
labels = modelss
nitems = dimsizes(labels)                 ; number of legend items
; half=orders(0:nitems/2-1)-1
; lgres@lgItemOrder        = half(::-1)
; lgres@lgLineColors       = colorss(0:nitems/2-1)
; lgres@lgDashIndexes      = dashess(0:nitems/2-1)
; lbid0= gsn_create_legend(wks,nitems/2,labels(0:nitems/2-1),lgres)
; lgres@lgLineColors       = colorss(nitems/2:nitems-1)
; lgres@lgDashIndexes      = dashess(nitems/2:nitems-1)
; lbid1= gsn_create_legend(wks,nitems/2,labels(nitems/2:nitems-1),lgres)
lgres@lgLineColors       = colorss
lgres@lgDashIndexes      = dashess
lbid0= gsn_create_legend(wks,nitems,labels,lgres)
amres                  = True
amres@amJust           = "CenterCenter"  ; Use bottom right corner of box 
amres@amParallelPosF   = 0.64            ; + left, - right
; amres@amOrthogonalPosF =  0.015           ; + up    - down
annoid0= gsn_add_annotation(plot(0,1),lbid0,amres)  ; add legend to plot
; amres@amOrthogonalPosF = -0.015           ; + up    - down
; annoid1= gsn_add_annotation(plot(0,3),lbid1,amres)  ; add legend to plot

;---------------------------------------------------------------------------------------------------- legend
resP=True
;resP@gsnMaximize                = False
resP@tiMainString               = "Layered Transport"
;resP@gsnPanelDebug =True
resP@gsnPanelXF=(/-1,0.49,-1,0.49/)
resP@gsnPanelYF=(/-1,-1,0.49,0.49/)
resP@gsnPanelYWhiteSpacePercent = 0.01
resP@gsnPanelXWhiteSpacePercent = 3
gsn_panel(wks,plot(0,:),(/2,2/),resP)
;gsn_panel(wks,plot1    ,(/2,2/),resP)
;print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
end
