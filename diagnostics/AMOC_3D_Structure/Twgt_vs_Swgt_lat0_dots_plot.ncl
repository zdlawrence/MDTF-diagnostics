load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"

begin
;----------------------------------------------------------------------
; Set some plot resources
;----------------------------------------------------------------------
res                    = True
res@gsnDraw            = False       ; Don't draw plot
res@gsnFrame           = False       ; Don't advance frame
;res@vpXF              = 0.12
;res@vpYF              = 0.95
;res@vpWidthF          = 0.7 
;res@vpHeightF         = 0.525
res@tmBorderThicknessF= 3
res@tmXTMajorThicknessF=3
res@tmXTMinorThicknessF=2
res@tmXBMajorThicknessF=3
res@tmXBMinorThicknessF=2
res@tmYLMajorThicknessF=3
res@tmYLMinorThicknessF=2
res@tmYRMajorThicknessF=3
res@tmYRMinorThicknessF=2
;res@tmYLAutoPrecision  =False
;res@tmYLPrecision      =2  
;res@tmXBPrecision      =2  

res2=res

;---Resources for X/Y axes.
res@trYMinF            =  2.
res@trYMaxF            =  21.
res@trXMinF            =  34.8
res@trXMaxF            =  37.2
res@tiXAxisString     = ""
res@tiYAxisString     = ""
;res@tiYAxisOffsetXF   = 0.02

;====================================================================================================
resc  =res
resc@gsnFrame             = False
resc@gsnDraw              = False
resc@tmYROn               = False
resc@tmXTOn               = False
resc@gsnLeftString              = ""
resc@gsnRightString             = ""
resc@gsnCenterString            = ""

resc@cnInfoLabelOn        = False
resc@cnLevelSelectionMode = "ExplicitLevels"  ; use explicit levels
resc@cnLinesOn            = True
resc@cnLineThicknessF     = 2
resc@cnLineLabelsOn       = True
resc@cnLineLabelFontHeightF=0.012
;resc@cnLineLabelFontThicknessF=3

;resc@cnLineLabelPlacementMode ="Computed"
;resc@cnLineLabelDensityF      =0.5

resc@cnLineLabelPlacementMode ="Constant"
resc@cnLineDashSegLenF        =0.3

resc@cnLevels = (/27.65/)

DIR_in     = getenv("OUTDIR")
DIR_in0    = getenv("WKDIR")
DIR_in1    = getenv("CLMREF")
DIR_out    = getenv("WKDIR")
lat0       = stringtofloat(getenv("LAT0"))

if(lat0.ge.0)then
  res@gsnCenterString = "Latitude: "+tostring_with_format(lat0,"%4.1f")+"~S~o~N~N"
else  
  res@gsnCenterString = "Latitude: "+tostring_with_format(abs(lat0),"%4.1f")+"~S~o~N~S"
end if

thetao_var  = getenv("thetao_var")
lev_var = getenv("lev_coord")
lat_var = getenv("lat_coord")

models = str_split(getenv("MODELS"), " ,") 
num_model=dimsizes(models)

;====================================================================================================

order=ispan(0,num_model-1,1)
marker=(/3,4,5,6,7,8,10,11,12,16,3,4,5,6,7,8,10,11,12,16/)
res@xyMarkLineMode     = "Markers"
res@xyMarkerThicknessF = 3.
res@xyMonoMarkerColor  = False
res@xyMarkers          = marker
res@xyMarkerColors     = "white"
;====================================================================================================

plot  = new((/num_model,3/),graphic)
plot0 = new(3,graphic)
plot1 = new(3,graphic)
plot2 = new(3,graphic)

wks = gsn_open_wks("png",DIR_out+"/Twgt_vs_Swgt_lat0_dots_plot")
if(num_model.le.20)then
  gsn_define_colormap(wks,"xbxu")
  colors=floattoint(fspan(2,21,num_model+1))
else
  gsn_define_colormap(wks,"amwg256")
  colors=floattoint(fspan(2,255,num_model))
end if

;---------------------------------------------------------------------------------------------------- reference
nc  = "TMP.sigma0.fx.nc"
fin = addfile(DIR_in+"/"+nc,"r")
sig = fin->sig0(0,:,:,0)
sig = sig - 1000.
plotc0= gsn_csm_contour(wks,sig,resc)
;plotc1= gsn_csm_contour(wks,sig,resc)
;plotc2= gsn_csm_contour(wks,sig,resc)

;---------------------------------------------------------------------------------------------------- reference
  nc = "HYCOM.thetao_wgt.clim.nc"
  print("Loading ... "+DIR_in1+nc)
  fin= addfile(DIR_in1+nc,"r")
  lat= fin->lat
  jjj=ind_nearest_coord(lat0,lat,0)
  tmp=fin->thetao(0,:,jjj,:)
  tt0=where(abs(tmp).gt.50, tmp@_FillValue,tmp )
  delete(tmp)

  nc = "HYCOM.so_wgt.clim.nc"
  print("Loading ... "+nc)
  fin= addfile(DIR_in1+nc,"r")
  lat= fin->lat
  jjj=ind_nearest_coord(lat0,lat,0)
  tmp=fin->so(0,:,jjj,:)
  ss0=where(abs(tmp).gt.50, tmp@_FillValue,tmp )
  delete(tmp)
;---------------------------------------------------------------------------------------------------- model
tt=new((/5,4,num_model/),"double",1e20)
ss=new((/5,4,num_model/),"double",1e20)

do mm=0,num_model-1
  model=models(mm)
  DIR_in=DIR_in0+"model/netCDF/"
  nc=model+".thetao_wgt.clim.nc"
  fin = addfile(DIR_in+nc,"r")
  latT=fin->lat
  jjj=ind_nearest_coord(lat0,latT,0)
  tmp=fin->thetao(:,jjj,:)
  replace_ieeenan (tmp, tmp@_FillValue, 0)
  tmp=where(abs(tmp).gt.50, tmp@_FillValue,tmp )
  tt(:,:,mm)=tmp
  delete(latT)
  delete(tmp)

  DIR_in=DIR_in0+"model/netCDF/"
  nc=model+".so_wgt.clim.nc"
  fin = addfile(DIR_in+nc,"r")
  latS=fin->lat
  jjj=ind_nearest_coord(lat0,latS,0)
  tmp=fin->so(:,jjj,:)
  replace_ieeenan (tmp, tmp@_FillValue, 0)
  tmp=where(abs(tmp).gt.50, tmp@_FillValue,tmp )
  ss(:,:,mm)=tmp
  delete(latS)
  delete(tmp)
end do

res@tiXAxisString     = "Salinity (psu)"
res@gsMarkerColor     = 0
res@tiYAxisString     = "Pot. Temp. (~S~o~N~C)"
res@tmYROn               = False
plot0(0) = gsn_csm_xy (wks,ss(0,0,:),tt(0,0,:),res)
res@tiYAxisString=""
;plot0(1) = gsn_csm_xy (wks,ss(0,0,:),tt(0,0,:),res)
;plot0(2) = gsn_csm_xy (wks,ss(0,0,:),tt(0,0,:),res)
  
res@tiXAxisString        = ""
res@tiYAxisString        = ""
res@tmYLLabelsOn         = False
res@tmYLOn               = False
res@gsMarkerThicknessF = 2.0 
res@gsMarkerSizeF      = 0.015
;---------------------------------------------------------------------------------------------------- plot
   ; 0:4, (,Smax], (Smax,S000], (S000,), (Smax,Smin], (Smin,)
   ; 0:3, net, pos, neg, abs 

do mm=0,num_model-1
  res@gsMarkerIndex = marker(mm)
  res@gsMarkerColor = colors(mm)
  plot(mm,0) = gsn_add_polymarker(wks,plot0(0),ss(0:3:3,3,mm),tt(0:3:3,3,mm),res)  ;;; Layered abs T/S
;  plot(mm,1) = gsn_add_polymarker(wks,plot0(1),ss(0:3:3,1,mm),tt(0:3:3,1,mm),res)  ;;; Layered pos T/S
;  plot(mm,2) = gsn_add_polymarker(wks,plot0(2),ss(0:3:3,2,mm),tt(0:3:3,2,mm),res)  ;;; Layered neg T/S
end do

res@gsMarkerIndex = 4 
res@gsMarkerColor = 1
res@gsMarkerThicknessF = 5.0 
MMES=dim_avg_n_Wrap(ss,2)
MMET=dim_avg_n_Wrap(tt,2)
plot2(0) = gsn_add_polymarker(wks,plot0(0),MMES(0:3:3,3),MMET(0:3:3,3),res) 
;plot2(1) = gsn_add_polymarker(wks,plot0(1),MMES(0:3:3,1),MMET(0:3:3,1),res) 
;plot2(2) = gsn_add_polymarker(wks,plot0(2),MMES(0:3:3,2),MMET(0:3:3,2),res) 
delete(ss)
delete(tt)

res@gsMarkerIndex = 16
res@gsMarkerColor = 1
plot1(0) = gsn_add_polymarker(wks,plot0(0),ss0(0:3:3,3),tt0(0:3:3,3),res) 
;plot1(1) = gsn_add_polymarker(wks,plot0(1),ss0(0:3:3,1),tt0(0:3:3,1),res) 
;plot1(2) = gsn_add_polymarker(wks,plot0(2),ss0(0:3:3,2),tt0(0:3:3,2),res) 

;----------------------------------------------------------------------
; Draw some individual labelbars.
;----------------------------------------------------------------------
mkres = True
txres = True ; Text resources
txres@txFontHeightF = 0.012
txres@txJust= "CenterLeft"

markers=new(num_model+2,typeof(marker))
colorss=new(num_model+2,typeof(colors))
modelss=new(num_model+2,typeof(models))
markers(0:num_model-1)=(/marker/)
colorss(0:num_model)=(/colors/)
modelss(0:num_model-1)=(/models/)
markers(num_model)=4
colorss(num_model)=1
modelss(num_model)="20-CMIP5 average"
markers(num_model+1)=16
colorss(num_model+1)=1
modelss(num_model+1)="high-res. model"

xpos= 0.815
ypos=fspan(0.205,0.80,num_model+2)
ypos=ypos(::-1)
;print(""+ypos)
do mm=0,num_model+1
  mkres@gsMarkerThicknessF = 3.0 
  mkres@gsMarkerSizeF= 0.015
  mkres@gsMarkerIndex= markers(mm)
  mkres@gsMarkerColor= colorss(mm)
;  mkres@gsMarkerIndex= marker(mm)
;  mkres@gsMarkerColor= colors(mm)
  xx0 = xpos
  yy0 = ypos(mm)
; print("x,y:"+xx0+""+yy0)
  gsn_polymarker_ndc(wks, xx0,yy0,mkres)
  gsn_text_ndc(wks,modelss(mm), xx0+0.02,yy0,txres)
end do

;overlay(plot0(0),plotc0)
;overlay(plot0(1),plotc1)
;overlay(plot0(2),plotc2)

resP=True
;resP@gsnMaximize                = True
;resP@gsnPaperOrientation        = "landscape"
resP@gsnPanelDebug =True
resP@gsnPanelXF=(/0.135, -1., 0.683/)
;resP@gsnPanelYF=(/0.90/)
;gsn_panel(wks,plot0,(/3,1/),resP)
;gsn_panel(wks,plot0(0),(/1,1/),resP)

pres=True
pres@gsnPanelDebug =True
maximize_output(wks,pres)
end
