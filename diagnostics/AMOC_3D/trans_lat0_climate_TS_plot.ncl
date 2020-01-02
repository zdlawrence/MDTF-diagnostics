load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"

sigs=(/30.1, 30.3, 30.5, 30.7, 30.9, 31.1, 31.3, 31.5, 31.7, 31.9, 32.1, 32.3, 32.5, 32.7, 32.9, 33.1, 33.3, 33.5, 33.7, 33.9, 34.1, 34.3, 34.5, 34.7, 34.9, 35.1, 35.3, 35.5, 35.7, 35.9, 36.01, 36.03, 36.05, 36.07, 36.09, 36.11, 36.13, 36.15, 36.17, 36.19, 36.21, 36.23, 36.25, 36.27, 36.29, 36.31, 36.33, 36.35, 36.37, 36.39, 36.41, 36.43, 36.45, 36.47, 36.49, 36.51, 36.53, 36.55, 36.57, 36.59, 36.61, 36.63, 36.65, 36.67, 36.69, 36.71, 36.73, 36.75, 36.77, 36.79, 36.81, 36.83, 36.85, 36.87, 36.89, 36.91, 36.93, 36.95, 36.97, 36.99, 37.01, 37.03, 37.05, 37.07, 37.09, 37.11, 37.13, 37.15, 37.17, 37.19, 37.21, 37.23, 37.25, 37.27, 37.29, 37.31, 37.33, 37.35, 37.37, 37.39/)
sig_bnds=(/30.0, 30.2, 30.4, 30.6, 30.8, 31, 31.2, 31.4, 31.6, 31.8, 32, 32.2, 32.4, 32.6, 32.8, 33, 33.2, 33.4, 33.6, 33.8, 34, 34.2, 34.4, 34.6, 34.8, 35, 35.2, 35.4, 35.6, 35.8, 36, 36.02, 36.04, 36.06, 36.08, 36.1, 36.12, 36.14, 36.16, 36.18, 36.2, 36.22, 36.24, 36.26, 36.28, 36.3, 36.32, 36.34, 36.36, 36.38, 36.4, 36.42, 36.44, 36.46, 36.48, 36.5, 36.52, 36.54, 36.56, 36.58, 36.6, 36.62, 36.64, 36.66, 36.68, 36.7, 36.72, 36.74, 36.76, 36.78, 36.8, 36.82, 36.84, 36.86, 36.88, 36.9, 36.92, 36.94, 36.96, 36.98, 37, 37.02, 37.04, 37.06, 37.08, 37.1, 37.12, 37.14, 37.16, 37.18, 37.2, 37.22, 37.24, 37.26, 37.28, 37.3, 37.32, 37.34, 37.36, 37.38, 37.4/)

DIR_out    = getenv("FIGDIR")
lat0_str   = getenv("LAT0")
lat0       = stringtofloat(getenv("LAT0"))
model=getenv("CASENAME")
yymm=getenv("YYYYMM")
yyyy=getenv("YYYY")
DIR_in0    = getenv("OUTDIR")
DIR_in1    = getenv("OUTDIR")
DIR_in2    = getenv("OUTDIR")
DIR_in3    = getenv("OUTDIR")
DIR_in4    = getenv("OUTDIR")
DIR_in5    = getenv("OUTDIR")

thetao_var = getenv("thetao_var")
so_var = getenv("so_var")
lat_var = getenv("lat_var")


wks   = gsn_open_wks("pdf",DIR_out+"trans_lat0_climate_TS_plot")
gsn_define_colormap(wks,"BlRe")
;***************************************************************************************************************************
;              resource for public
;***************************************************************************************************************************
res                      = True
res@gsnFrame             = False
res@gsnDraw              = False
;res@vpHeightF            = 0.8
;res@vpWidthF             = 0.9
;res@vpXF                 = 0.2
;res@vpYF                 = 0.8
;res@gsnMaximize          = True
res@tmYROn               = False
res@tmXTOn               = False

res@trXMinF = 34
res@trXMaxF = 38 
res@trYMinF = -2 
res@trYMaxF = 32  
;res@trXMinF = 34.7
;res@trXMaxF = 37.7 
;res@trYMinF = 0 
;res@trYMaxF = 30  
res@gsnLeftString        = ""+lat0
res@gsnCenterString      = model
res@gsnRightString       = "Sv"

res@cnInfoLabelOn        = False
;res@gsnStringFontHeightF=0.028

res0=res
res0@cnFillMode           = "CellFill"
res0@cnFillOn             = True
res0@cnLevelSelectionMode = "ExplicitLevels"
;res0@cnLevels             = (/ (/ispan(-50,-5,5)/100./), (/ispan(-50,50,5)/1000./), (/ispan(5,50,5)/100./) /)
;res0@cnLevels             = ispan(-50,50,5)/100.
res0@cnLevels             = (/-0.5,-0.45,-0.4,-0.35,-0.3,-0.25,-0.2,-0.15,-0.1,-0.09,-0.08,-0.07,-0.06,-0.05,-0.04,-0.03,-0.02,-0.01,0,0.01,0.02,0.03,0.04,0.05,0.06,0.07,0.08,0.09,0.1,0.15,0.2,0.25,0.3,0.35,0.4,0.45,0.5/)
res0@cnLineLabelsOn       = False
res0@cnLinesOn            = False
;res0@lbLabelFontHeightF   = 0.012
res0@lbLabelBarOn               = True
res0@lbOrientation              = "Vertical"
res0@lbLabelAutoStride          = True
;res0@pmLabelBarWidthF           = 0.12
;res0@pmLabelBarHeightF          = 0.8 
res0@pmLabelBarOrthogonalPosF   = -0.02
res0@lbLabelStride              = 2

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;      resourse for Panel plot
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
resP                            = True
;resP@gsnMaximize                = True
;resP@gsnPanelLabelBar           = True
;;resP@lbLabelFontHeightF         = 0.007
;resP@gsnPanelYWhiteSpacePercent = 0.5
;resP@gsnPanelXWhiteSpacePercent = 0.5
;resP@gsnPanelCenter = False
;resP@lbOrientation              = "Vertical"
;resP@pmLabelBarWidthF           = 0.10
;resP@pmLabelBarHeightF          = 0.804
;resP@pmLabelBarOrthogonalPosF   = -0.02 
;resP@pmLabelBarParallelPosF     = -0.009
;resP@lbLabelStride              = 2

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


ncs0=(/"TMP.sigma2.fx.nc"/)
ncs1=(/model+".trans.clim.nc"/)
ncs2=(/model+".AMOC_qts.clim.nc"/)
ncs3=(/model+".trans_avg.clim.nc"/)
ncs4=(/model+"."+thetao_var+"_wgt.clim.nc"/)
ncs5=(/model+"."+so_var+"_wgt.clim.nc"/)

models=(/model/)

;***************************************************************************************************************************
;***************************************************************************************************************************
nc=DIR_in0+ncs0
print("Loading ... "+nc)
fin = addfile(nc,"r") 
sig = fin->sig2(0,:,:,0)
sig = sig - 1000.

resc=res
resc@cnLevelSelectionMode = "ExplicitLevels"  ; use explicit levels
resc@cnLinesOn            = True 
resc@cnLineThicknessF     = 2
resc@cnLineLabelsOn       = True 
;resc@cnLineLabelFontHeightF=0.015
;resc@cnLineLabelFontThicknessF=3 
resc@cnLineLabelPlacementMode ="Computed"
resc@cnLineLabelDensityF      =0.2
resc@cnLineLabelBackgroundColor =-1

txtres               = True                            
;txtres@txFontHeightF = 0.03
;txtres@txFontThicknessF = 3

num_model=dimsizes(models)
plot = new(num_model,graphic)
plotc= new(num_model,graphic)
plotd= new(num_model,graphic)
mb   = new((/num_model,3/),graphic)
nb   = new((/num_model,3/),graphic)
txt  = new(num_model,graphic)
text = new((/num_model,3,2/),graphic)
txt2 = new((/num_model,3,2/),graphic)
txt3 = new((/num_model,3,2/),graphic)

maxs=new(num_model,"double",1e20)
m00s=new(num_model,"double",1e20)
mins=new(num_model,"double",1e20)

xpos=(/0.16,0.33,0.51,0.67,0.83/)
ypos=(/0.89,0.685,0.485,0.285/)

do mm=0,num_model-1

  nc=DIR_in1+ncs1(mm)
  print("Loading ... "+nc)
  fin = addfile(nc,"r") 
  lat = fin->$lat_var$
  jjj=ind_nearest_coord(lat0,lat,0)
  delete(lat)
  trans = fin->trans(:,:,jjj)
  if(all(ismissing(trans)))then
    continue
  end if

  res0@tmXBLabelsOn=True 
  res0@tiXAxisString        = "Salinity (S) psu"
  res0@tmYLLabelsOn=True
  res0@tiYAxisString        = "Pot. Temp. (~S~o~N~C)"
;  res0@tiYAxisString        = "Pot. Temp. (~F8~q~N~~F21~) ~S~o~N~C"

  if(max(abs(trans)).gt.10)then
    trans=trans/1000.
  end if

  if(max(abs(trans)).gt.10)then
    trans=trans/1000.
  end if

  nc  = DIR_in2+ncs2(mm)
  print("Loading ... "+nc)
  fin = addfile(nc,"r") 
  maxs(mm)=(/fin->sig_max(jjj)/)
  m00s(mm)=(/fin->sig_000(jjj)/)
  mins(mm)=(/fin->sig_min(jjj)/)

;====================================================================================================
  plot(mm)  = gsn_csm_contour(wks,trans,res0)
  resc@cnLevels = (/maxs(mm)/)
  plotc(mm) = gsn_csm_contour(wks,sig,resc)
  resc@cnLevels = (/m00s(mm)/)
  plotd(mm) = gsn_csm_contour(wks,sig,resc)
  overlay(plot(mm),plotc(mm))
  overlay(plot(mm),plotd(mm))
  label = models(mm)
  txtres@txFontColor      = "black"
;  txt(mm) = gsn_add_text(wks,plot(mm),models(mm),36,0,txtres)

  ttres               = True                     ; text mods desired
;  ttres@txFontHeightF = 0.01                     ; font smaller. default big 
  a=mod(mm,5)
  b=mm/5
  xx=xpos(a)
  yy=ypos(b)
;  gsn_text_ndc(wks,models(mm),xx,yy,ttres) 
  delete(xx)
  delete(yy)

;  txtres@txFontColor      = "black"
;  text1= gsn_add_text(wks,plot(mm),tostring_with_format(maxs(mm),"%5.2f"),33,4,txtres)
;  text2= gsn_add_text(wks,plot(mm),tostring_with_format(m00s(mm),"%5.2f"),36.5,3,txtres)
  delete(trans)
;====================================================================================================
; k = 0       1       2         3         4 
;  upper, middle0, lower0, middle_min, lower_min  
; i = 0       1       2         3
;   Net, Positive, Negative, absolute
  ks=(/0,1,2/)
  is=(/1,2/)
  nc  = DIR_in3+ncs3(mm)
  print("Loading ... "+nc)
  fin3= addfile(nc,"r") 
  trans= fin3->trans(ks,jjj,is)
  if(max(trans).gt.100)then
    trans=trans/1000.
  end if
;  print(models(mm)+" "+trans(0,0)+" "+trans(0,1)+" "+trans(1,0)+" "+trans(1,1)+" "+trans(2,0)+" "+trans(2,1))

  nc  = DIR_in4+ncs4(mm)
  print("Loading ... "+nc)
  fin4= addfile(nc,"r") 
  thetao= fin4->$thetao_var$(ks,jjj,is)

  nc  = DIR_in5+ncs5(mm)
;  print("Now,the nc is:   "+nc)
  print("Loading ... "+nc)
  fin5= addfile(nc,"r") 
  so= fin5->$so_var$(ks,jjj,is)
;====================================================================================================
  polyres                   = True                       ; marker resources
  polyres@gsMarkerSizeF     = 0.012
  polyres@gsLineThicknessF  = 1 
  
  polyres@gsMarkerIndex     = 16                         ; index for circle
  polyres@gsMarkerColor     = "magenta"
  xx=(/so(0,0)/) 
  yy=(/thetao(0,0)/)
  mb(mm,0) = gsn_add_polymarker(wks,plot(mm),xx,yy,polyres)
  polyres@gsMarkerColor     = "blue"
  xx=(/so(0,1)/) 
  yy=(/thetao(0,1)/)
  nb(mm,0)  = gsn_add_polymarker(wks,plot(mm),xx,yy,polyres)

  polyres@gsMarkerThicknessF= 1 
  polyres@gsMarkerIndex     = 16
  polyres@gsMarkerColor     = "magenta"
  xx=(/so(1,0)/) 
  yy=(/thetao(1,0)/)
  mb(mm,1) = gsn_add_polymarker(wks,plot(mm),xx,yy,polyres)
  polyres@gsMarkerColor     = "blue"
  xx=(/so(1,1)/) 
  yy=(/thetao(1,1)/)
  nb(mm,1)  = gsn_add_polymarker(wks,plot(mm),xx,yy,polyres)

  polyres@gsMarkerIndex     = 16
  polyres@gsMarkerColor     = "magenta"
  xx=(/so(2,0)/) 
  yy=(/thetao(2,0)/)
;  mb(mm,2) = gsn_add_polymarker(wks,plot(mm),xx,yy,polyres)
  polyres@gsMarkerColor     = "blue"
  xx=(/so(2,1)/) 
  yy=(/thetao(2,1)/)
;  nb(mm,2)  = gsn_add_polymarker(wks,plot(mm),xx,yy,polyres)
;====================================================================================================
  vmo_strs=tostring_with_format((/trans/), "%4.2f")+ " Sv"
  ttt_strs=tostring_with_format((/thetao/),"%4.2f")
  sss_strs=tostring_with_format((/so/),    "%4.2f")
  ts0_strs="[ "+tostring_with_format((/thetao/),"%4.2f")+", "+tostring_with_format((/so/),"%4.2f")+" ]"
  delete(trans)

  txres                 = True
  txres@txFontHeightF = 0.01
  txres@txFontThicknessF = 1
  txres@txFontColor = "magenta"
;==================== layer1 positive ====================
  xxx = 35.3
  yyy = 20.0
  text(mm,0,0) = gsn_add_text(wks,plot(mm),vmo_strs(0,0), xxx, yyy,txres)

;==================== layer2 positive ====================
  xxx = 36.3
  yyy = 5.0
  text(mm,1,0) = gsn_add_text(wks,plot(mm),vmo_strs(1,0), xxx, yyy,txres)
;==================== layer3 positive ====================
  p2x=-1.0
  p2y= 0.0
;  text(mm,2,0) = gsn_add_text(wks,plot(mm),vmo_strs(2,0), xxx, yyy,txres)
;  xxx = (/so(:,0)+p2x/)
;  yyy = (/thetao(:,0)+p2y/)

  txres@txFontColor = "blue"
;==================== layer1 negative ====================
  xxx = 35.3
  yyy = 18.0
  text(mm,0,1) = gsn_add_text(wks,plot(mm),vmo_strs(0,1), xxx, yyy,txres)
;==================== layer2 negative ====================
  xxx = 37.1
  yyy = 5.0
  text(mm,1,1) = gsn_add_text(wks,plot(mm),vmo_strs(1,1), xxx, yyy,txres)
;==================== layer3 negative ====================
  n2x=1.5
  n2y=-1.0
;  xxx = (/so(:,1)+n2x/)
;  yyy = (/thetao(:,1)+n2y/)
;  text(mm,2,1) = gsn_add_text(wks,plot(mm),vmo_strs(2,1), xxx, yyy,txres)

;----------------------------------------------------------------------------------------------------
;                              S,T
;----------------------------------------------------------------------------------------------------
  disx=-0.1
  disy=-2.0
  txres@txFontColor = "magenta"
;  xxx = (/so(:,0)+p0x+disx/)
;  yyy = (/thetao(:,0)+p0y+disy/)
;  txt2(mm,0,0) = gsn_add_text(wks,plot(mm),ts0_strs(0,0), xxx, yyy,txres)
;  xxx = (/so(:,0)+p1x+disx/)
;  yyy = (/thetao(:,0)+p1y+disy/)
;  txt2(mm,1,0) = gsn_add_text(wks,plot(mm),ts0_strs(1,0), xxx, yyy,txres)
;  xxx = (/so(:,0)+p2x+disx/)
;  yyy = (/thetao(:,0)+p2y+disy/)
;  txt2(mm,2,0) = gsn_add_text(wks,plot(mm),ts0_strs(2,0), xxx, yyy,txres)

  txres@txFontColor = "blue"
;  xxx = (/so(:,1)+n0x+disx/)
;  yyy = (/thetao(:,1)+n0y+disy/)
;  txt2(mm,0,1) = gsn_add_text(wks,plot(mm),ts0_strs(0,1), xxx, yyy,txres)
;  xxx = (/so(:,1)+n1x+disx/)
;  yyy = (/thetao(:,1)+n1y+disy/)
;  txt2(mm,1,1) = gsn_add_text(wks,plot(mm),ts0_strs(1,1), xxx, yyy,txres)
;  xxx = (/so(:,1)+n2x+disx/)
;  yyy = (/thetao(:,1)+n2y+disy/)
;  txt2(mm,2,1) = gsn_add_text(wks,plot(mm),ts0_strs(2,1), xxx, yyy,txres)
;====================================================================================================
end do

;print(models+" "+maxs+" "+m00s+" "+mins)

;resP@gsnPanelDebug =True
;resP@gsnPanelXF=(/0.092, 0.256,    -1, 0.583, 0.747, \
;                  0.092, 0.256,    -1, 0.583, 0.747, \
;                  0.092, 0.256,    -1, 0.583, 0.747, \
;                  0.092, 0.256,    -1, 0.583, 0.747 /)
;resP@gsnPanelYF=(/0.900, 0.900, 0.900, 0.900, 0.900, \
;                  0.697, 0.697, 0.697, 0.697, 0.697, \
;                  -1   , -1   ,    -1,  -1  ,  -1  , \ 
;                  0.295, 0.295, 0.295, 0.295, 0.295 /)
gsn_panel(wks,plot,(/1,1/),resP)
