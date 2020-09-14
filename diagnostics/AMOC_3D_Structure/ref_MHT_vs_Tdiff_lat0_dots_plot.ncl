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
res@vpXF              = 0.12
res@vpYF              = 0.95
res@vpWidthF          = 0.7
res@vpHeightF         = 0.525
res@tmBorderThicknessF= 3
res@tmXTMajorThicknessF=3
res@tmXTMinorThicknessF=2
res@tmXBMajorThicknessF=3
res@tmXBMinorThicknessF=2
res@tmYLMajorThicknessF=3
res@tmYLMinorThicknessF=2
res@tmYRMajorThicknessF=3
res@tmYRMinorThicknessF=2
res@tmYLAutoPrecision  =False
res@tmYLPrecision      =2
res@tmXBPrecision      =2

res2=res

;---Resources for X/Y axes.
res@trXMinF            =  10.0
res@trXMaxF            =  32.0
res@trYMinF            =  -0.7
res@trYMaxF            =  0.0
res@tiXAxisString     = "Temperature Difference (~S~o~N~C)"
res@tiYAxisString     = "Heat Transport (PW)"
res@tiYAxisOffsetXF   = 0.02

res1=res

DIR_in0    = getenv("CLMREF")
DIR_in1    = getenv("CLMREF")
DIR_out    = getenv("FIGREF")
lat0       = stringtofloat(getenv("LAT0"))
models = str_split(getenv("CMIP5_CLIM_MODELS"), " ,")

num_model=dimsizes(models)
;print(""+models)
;print(""+num_model)

MHT=new((/num_model/),"double",1e20)
Tdiff=new((/num_model/),"double",1e20)

;order=ispan(0,num_model-1,1)
;marker=mod(order,10)+3
marker=(/3,4,5,6,7,8,10,11,12,16,3,4,5,6,7,8,10,11,12,16/)

res@xyMarkLineMode     = "Markers"
res@xyMarkerSizeF      = 0.01
res@xyMarkerThicknessF = 2.
res@xyMonoMarkerColor  = False
res@xyMarkers          = marker
res@xyMarkerColors     = "white"

res0=res
res0@gsMarkerThicknessF = 5.0
res0@gsMarkerSizeF      = 0.02
delete(res0@gsnDraw)
delete(res0@gsnFrame)
  
rrr=new(118,double,1e20)
yyy=new(118,float,1e20)
;do j=1,118
do j=1,1
;  lat0=-30.+(j-1)*1 
;  lat0=26

  yyy(j-1)=lat0

do mm=0,num_model-1
  model=models(mm)
  DIR_in=DIR_in0
  nc=model+".MHT.clim.nc"
  fil = addfile(DIR_in+nc,"r")
  latT=fil->lat
  jjj=minind(abs(lat0-latT))
  tmp=fil->MHT(0,jjj,0)
  if(max(abs(tmp)).gt.100)then
    tmp=tmp/1e3
  end if
  if(max(abs(tmp)).gt.100)then
    tmp=tmp/1e3
  end if
  MHT(mm)=tmp
  delete(tmp)

  nc=model+".thetao_wgt.clim.nc"
  fil =  addfile(DIR_in+nc,"r")
  tmp1 = fil->thetao(0,jjj,3)
  tmp2 = fil->thetao(3,jjj,3)
  tmp = tmp1
  tmp = tmp1 - tmp2
  replace_ieeenan (tmp, tmp@_FillValue, 0)
  Tdiff(mm)=tmp
  print(models(mm)+" "+latT(jjj)+" "+MHT(mm)+" "+Tdiff(mm))
  delete(latT)
  delete(tmp)
  delete(tmp1)
  delete(tmp2)
end do  ;;; model loop
;printMinMax(MHT,False)
;printMinMax(Tdiff,False)

plot  = new(num_model,graphic)
plot0 = new(1,graphic)
plot1 = new(1,graphic)
plot2 = new(1,graphic)
plot3 = new(1,graphic)
plot4 = new(1,graphic)

wks = gsn_open_wks("pdf",DIR_out+"/ref_MHT_vs_Tdiff_lat0_dots")
if(num_model.le.20)then
  gsn_define_colormap(wks,"xbxu")
  colors=floattoint(fspan(2,21,num_model+1))
else
  gsn_define_colormap(wks,"amwg256")
  colors=floattoint(fspan(2,255,num_model))
end if
print(""+dimsizes(colors))

res@trYMinF   =  toint((min(MHT)-0.05)*10.)/10.
res@trYMaxF   =  toint((max(MHT)+0.05)*10.)/10.
res@trXMinF   =  toint((min(Tdiff)-0.5)*10.)/10.
res@trXMaxF   =  toint((max(Tdiff)+0.5)*10.)/10.
print("&&&&&&&&&&&&&&&&&&&&&&&&"+res@trYMinF+ " "+res@trYMaxF)
print("&&&&&&&&&&&&&&&&&&&&&&&&"+res@trXMinF+ " "+res@trXMaxF)
plot0 = gsn_csm_xy (wks,Tdiff,MHT,res)
printMinMax(Tdiff,False)
printMinMax(MHT,False)
do mm=0,num_model-1
  res0@gsMarkerIndex = marker(mm)
  res0@gsMarkerColor = colors(mm)
  plot(mm) = gsn_add_polymarker(wks,plot0,Tdiff(mm),MHT(mm),res0)
end do
res0@gsMarkerIndex = 4 
res0@gsMarkerColor = 1 
plot4 = gsn_add_polymarker(wks,plot0,avg(Tdiff),avg(MHT),res0)
;======================================================================
; qq(m,k,i)
; m ---> model
; k ---> Upper, Middle, Lower
; i ---> All, Pos, Neg
;======================================================================
x=Tdiff 
y=MHT
x0=avg(x)
y0=avg(y)
rc =  regline_stats(x,y)
rrr(j-1)=(/rc/)

nx   = num_model
pltarry = new ( (/1,nx/), typeof(x))
pltarry(0,:) = rc@Yest

res1@xyMarkLineModes= "Lines"
res1@xyDashPatterns = 0  ; solid line 
res1@xyLineThicknesses   = (/1/)
res1@xyLineColors   = (/"black"/)
res1@trXMinF   =  res@trXMinF
res1@trXMaxF   =  res@trXMaxF
plot1  = gsn_csm_xy (wks,x,pltarry,res1) ; create plot
overlay(plot0,plot1)
delete(pltarry)

txres = True ; Text resources
txres@txFontHeightF = 0.012
txres@txJust= "CenterLeft"
xpos = 0.3
if(abs(rc@tval(1)).gt.2.093)then
sig="Yes"
else
sig="No"
end if

rcf=sprintf("%5.2f",rc*100.)
tval=sprintf("%5.2f",rc@tval(1))

ypos = 0.25
;gsn_text_ndc(wks,"Reg Coef="+rcf+" "+sig, xpos,ypos,txres)
;print("Reg Coef="+rcf*100.)
yintercept=sprintf("%6.2f",rc@yintercept*100.)
print("Y="+rcf+"*X+"+yintercept)
ypos = 0.2
;gsn_text_ndc(wks,"Tval="+tval+" Tref=1.734", xpos,ypos,txres)
if(abs(rc@tval(1)).gt.2.093)then
  sig="Yes"
else
  sig="No"
end if
print(lat0+" Tval="+tval+" "+sig)
delete(ypos)
delete(rc)

;----------------------------------------------------------------------
; Draw some markers and text.
;----------------------------------------------------------------------

plres = True
plres@gsLineColor = "black"
plres@gsLineDashPattern = 16
plres@gsLineThicknessF = 3 
xx=(/0.,0./)
yy=(/res@trYMinF,res@trYMaxF/)
xx=(/res@trXMinF,res@trXMaxF/)
;yy=(/0.,0./)
;======================================= hycom =======================================
nc = "HYCOM.MHT.clim.nc"
fil = addfile(DIR_in1+nc,"r")
latT=fil->lat
jjj=minind(abs(lat0-latT))
delete(latT)
tmp=fil->MHT(0,0,jjj,0)
if(max(abs(tmp)).gt.100)then
  tmp=tmp/1e3
end if
if(max(abs(tmp)).gt.100)then
  tmp=tmp/1e3
end if
MHT0=tmp
delete(tmp)

nc = "HYCOM.thetao_wgt.clim.nc"
;print("Now,the nc is: "+nc)
fil= addfile(DIR_in1+nc,"r")
lat= fil->lat
jjj=ind_nearest_coord(lat0,lat,0)
tmp1 = fil->thetao(0,0,jjj,3)
tmp2 = fil->thetao(0,3,jjj,3)
Tdiff0 = tmp1
Tdiff0 = tmp1 - tmp2
delete(lat)
res0@gsMarkerIndex = 16
res0@gsMarkerColor = 1 
plot3 = gsn_add_polymarker(wks,plot0,Tdiff0,MHT0,res0)

;====================================================================================================
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
modelss(num_model+1)="This model:~C~"+getenv("CASENAME")

xpos= 0.85
ypos=fspan(0.425,0.95,num_model+2)
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
;----------------------------------------------------------------------------------------------------
txres               = True                     ; text mods desired
txres@txFontHeightF = 0.035
txres@txFontColor   = "black"
;txt = gsn_add_text(wks,plot0,"c)",11.0,-0.05,txres)
;----------------------------------------------------------------------------------------------------

pres=True
pres@gsnPanelDebug =True
maximize_output(wks,pres)
end do   ;;; lat loop

end
