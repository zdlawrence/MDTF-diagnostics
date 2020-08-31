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

DIR_in0 = getenv("CLMREF")
DIR_in1 = getenv("WKDIR")
DIR_out = getenv("WKDIR")
lat0    = stringtofloat(getenv("LAT0"))

lat_var = getenv("lat_coord")

models = str_split(getenv("MODELS"), " ,") 
num_model=dimsizes(models)

thetao_var  = getenv("thetao_var")
lev_var = getenv("lev_coord")
lat_var = getenv("lat_coord")

ncs0="HYCOM.MFWT.clim.nc"

wks = gsn_open_wks("png",DIR_out+"/sum_MFWT_lats_y_plot")
if(num_model.le.20)then
  gsn_define_colormap(wks,"xbxu")
  colors=floattoint(fspan(2,21,num_model))
else
  gsn_define_colormap(wks,"amwg256")
  colors=floattoint(fspan(2,255,num_model))
end if
orders=ispan(1,num_model+2,1)

;====================================================================================================
; k = 0       1       2         3         4         5
;  upper, middle0, lower0, middle_min, lower_min, total  
; i = 0       1       2
;   Net, Positive, Negative
ks=(/5/)
is=(/0/)
factors = (/1/)

num_line=dimsizes(ks)
plot = new(num_model,graphic)
plot1= new(1        ,graphic)
plot2= new(1        ,graphic)

;---------------------------------------------------------------------------------------------------- reference
nc = DIR_in0+ncs0
;print("Loading ... "+nc)
fin = addfile(nc,"r")

kk=0
;do kk=0,num_line-1
   k=ks(kk)
   i=is(kk)
   REF = fin->MFWT(0,k,:,i)  ;;; T1 southward
   REF  = REF * factors(kk)
   LAT = fin->$lat_var$
   num_lat=dimsizes(LAT)

   if(isMonotonic(LAT).eq.-1)then
      LAT=LAT(::-1)
      REF=REF(::-1)
      REF&lat=LAT
   end if
   REF=where(LAT.lt.-34,REF@_FillValue,REF)
;end do

xmin=min(REF)
xmax=max(REF)
out=new((/num_model,num_lat/),"double",1e20)
;---------------------------------------------------------------------------------------------------- axis range
kk=0
;do kk=0,num_line-1
   k=ks(kk)
   i=is(kk)
do mm=0,num_model-1
   model=models(mm)
   DIR_in=DIR_in1+"model/netCDF/"

   nc=model+".MFWT.clim.nc"
;   print("Loading ... "+nc)
   fin = addfile(DIR_in+nc,"r")
   var = fin->MFWT(k,:,i)
   lat = fin->lat
   var  = var * factors(kk)
   var=where(lat.lt.-34,var@_FillValue,var)
   xmin= min( (/min(var),xmin/) )
   xmax= max( (/max(var),xmax/) )
   delete(var)
   delete(lat)
end do
;end do

dist = (xmax-xmin)*0.1
xmin = tointeger(xmin - dist - 0.5)
xmax = tointeger(xmax + dist + 0.5)
;res@trXMinF = xmin
;res@trXMaxF = xmax
res@tmYLPrecision      =2  
res@trYMinF = -0.8
res@trYMaxF = 0.8

;print(xmin+" "+xmax)
;---------------------------------------------------------------------------------------------------- models
kk=0
;do kk=0,num_line-1
   k=ks(kk)
   i=is(kk)
do mm=0,num_model-1
   model=models(mm)
   DIR_in=DIR_in1+"model/netCDF/"

   nc=model+".MFWT.clim.nc"
;   print("Loading ... "+nc)
   fin = addfile(DIR_in+nc,"r")
   var = fin->MFWT(k,:,i)
   var  = var * factors(kk)
   lat = fin->$lat_var$
   if(isMonotonic(lat).eq.-1)then
      lat=lat(::-1)
      var=var(::-1)
      var&lat=lat
   end if
   var=where(lat.lt.-34,var@_FillValue,var)

   res@xyLineColor = colors(mm)
   res@xyDashPattern = 0
   plot(mm) = gsn_csm_xy (wks,lat,var,res)
   out(mm,:)=linint1_n_Wrap(lat,var,False,LAT,0,0)
   delete(lat)
   delete(var)
end do
;end do
do mm=1,num_model-1
  overlay(plot(0),plot(mm))
end do

;---------------------------------------------------------------------------------------------------- plot model mean
MME=dim_avg_n_Wrap(out,0)
res@xyDashPattern = 1
res@xyLineColor = 1
res@xyLineThicknessF      = 5
plot1 = gsn_csm_xy (wks,LAT,MME,res)
overlay(plot(0),plot1)
delete(MME)
;---------------------------------------------------------------------------------------------------- plot reference
res@xyLineColor = 1
res@xyDashPattern = 0
res@xyLineThicknessF      = 5
plot2 = gsn_csm_xy (wks,LAT,REF,res)
overlay(plot(0),plot2)
delete(REF)

;---------------------------------------------------------------------------------------------------- legend
colorss=new(num_model+2,typeof(colors))
modelss=new(num_model+2,typeof(models))
dashess=orders
colorss(0:num_model-1)=(/colors/)
modelss(0:num_model-1)=(/models/)
dashess(0:num_model-1)=0
colorss(num_model)=1
modelss(num_model)="20-CMIP5 average"
dashess(num_model)=1
colorss(num_model+1)=1
modelss(num_model+1)="high-res. model"
dashess(num_model+1)=0
;print(dashess)

lgres                    = True
lgres@lgLineColors       = colorss
lgres@lgDashIndexes      = dashess
lgres@lgBoxLinesOn       = False
lgres@lgPerimOn          = False
lgres@lgLineThicknessF   = 5
lgres@lgItemType         = "Lines"        ; show lines only (default)
lgres@lgLabelFontHeightF = 0.08           ; legend label font thickness
lgres@vpWidthF           = 0.12            ; width of legend (NDC)
lgres@vpHeightF          = 0.64           ; height of legend (NDC)
;lgres@lgPerimThicknessF  = 2.0            ; thicken the box perimeter
lgres@lgMonoDashIndex    = False
lgres@lgItemOrder        = orders(::-1)-1
labels = modelss
nitems = dimsizes(labels)                 ; number of legend items

amres                  = True
amres@amJust           = "CenterCenter"  ; Use bottom right corner of box
amres@amParallelPosF   = 0.62            ; + left, - right
;amres@amOrthogonalPosF = 0.55            ; + up    - down
lbid = gsn_create_legend(wks,nitems,labels,lgres)
annoid = gsn_add_annotation(plot(0),lbid,amres)  ; add legend to plot

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
