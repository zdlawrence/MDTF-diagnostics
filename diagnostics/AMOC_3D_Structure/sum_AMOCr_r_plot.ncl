load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"

;***************************************************************************************************************************
;                   resource for public
;***************************************************************************************************************************
res = True

res@gsnFrame           = False
res@gsnDraw            = False
;res@vpHeightF          = 0.8
;res@vpWidthF           = 0.8

res@gsnLeftString              = ""
res@gsnRightString             = ""
res@gsnCenterString            = ""
res@tiXAxisString        = ""
res@tiYAxisString        = ""

;res@vpXF              = 0.15
;res@vpYF              = 0.95
;res@vpWidthF          = 0.6
;res@vpHeightF         = 0.6
;res@tmBorderThicknessF= 3
;res@tmXTMajorThicknessF=3
;res@tmXTMinorThicknessF=2
;res@tmXBMajorThicknessF=3
;res@tmXBMinorThicknessF=2
;res@tmYLMajorThicknessF=3
;res@tmYLMinorThicknessF=2
;res@tmYRMajorThicknessF=3
;res@tmYRMinorThicknessF=2
res@tmYROn             = False

res@tiXAxisString             = "Streamfunction (Sv)"
res@tiYAxisString             = "Pot. Density ~F8~s~B~2~N~"

;res@gsnYAxisIrregular2Linear = True
res@tmYLMode                 = "Explicit"
res@trYMinF = 0 
res@trYMaxF = 99
res@tmYLValues            = ispan(9,99,10)
res@tmYLMinorValues       = ispan(4,99,5)
res@trXTensionF  = 30. 
res@trYTensionF  = 30. 
res@trYReverse                  = True

levs=(/30.1, 30.3, 30.5, 30.7, 30.9, 31.1, 31.3, 31.5, 31.7, 31.9, 32.1, 32.3, 32.5, 32.7, 32.9, 33.1, 33.3, 33.5, 33.7, 33.9, 34.1, 34.3, 34.5, 34.7, 34.9, 35.1, 35.3, 35.5, 35.7, 35.9, 36.01, 36.03, 36.05, 36.07, 36.09, 36.11, 36.13, 36.15, 36.17, 36.19, 36.21, 36.23, 36.25, 36.27, 36.29, 36.31, 36.33, 36.35, 36.37, 36.39, 36.41, 36.43, 36.45, 36.47, 36.49, 36.51, 36.53, 36.55, 36.57, 36.59, 36.61, 36.63, 36.65, 36.67, 36.69, 36.71, 36.73, 36.75, 36.77, 36.79, 36.81, 36.83, 36.85, 36.87, 36.89, 36.91, 36.93, 36.95, 36.97, 36.99, 37.01, 37.03, 37.05, 37.07, 37.09, 37.11, 37.13, 37.15, 37.17, 37.19, 37.21, 37.23, 37.25, 37.27, 37.29, 37.31, 37.33, 37.35, 37.37, 37.39/)
res@tmYLLabels = tostring_with_format(levs(9:99:10),"%5.2f")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;---------------------------------------------------------------------------------------------------- Enviromental variables
DIR_ina    = getenv("FIXREF")
DIR_in0    = getenv("CLMREF")
DIR_in1    = getenv("WKDIR")
DIR_out    = getenv("FIGREF")
lat0       = stringtofloat(getenv("LAT0"))
models = str_split(getenv("MODELS"), " ,")
num_model=dimsizes(models)

thetao_var  = getenv("thetao_var")
lev_var = getenv("lev_coord")
lat_var = getenv("lat_coord")

if(lat0.ge.0)then
  res@gsnCenterString = "Latitude: "+tostring_with_format(lat0,"%4.1f")+"~S~o~N~N"
else  
  res@gsnCenterString = "Latitude: "+tostring_with_format(abs(lat0),"%4.1f")+"~S~o~N~S"
end if

ncsa="HYCOM.lat_vo.fx.nc"
ncs0="HYCOM.AMOC_qts.clim.nc"

plot = new(num_model,graphic)
plot1 = new(1,graphic)
plot2 = new(1,graphic)

wks   = gsn_open_wks("pdf",DIR_out+"/sum_AMOCr_r_plot")
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
;print(""+dimsizes(colors))
orders=ispan(1,num_model+2,1)

;---------------------------------------------------------------------------------------------------- reference
nc = DIR_ina+"/"+ncsa
;print("Loading ... "+nc)
fin = addfile(nc,"r")
LAT  = fin->$lat_var$
jjj=ind_nearest_coord(lat0,LAT,0)

nc = DIR_in0+ncs0
;print("Loading ... "+nc)
fin = addfile(nc,"r")
REF  = fin->AMOC(0,:,jjj,0)

LEV=ispan(0,99,1)*1.0
LEV@_FillValue=-9999
REF&lev= (/LEV/)  
num_lev=dimsizes(LEV)

out=new((/num_model,num_lev/),"double",1e20)

;---------------------------------------------------------------------------------------------------- axis range
xmin=min(REF)
xmax=max(REF)
do mm=0,num_model-1
  model=models(mm)
  DIR_in=DIR_in1+"model/netCDF/"

  nc = model+"."+lat_var+"_vo.fx.nc"
;  print("Loading ... "+nc)
  fin = addfile(DIR_in+nc,"r")
  lat = fin->$lat_var$
  jjj = minind(abs(lat-lat0))

  nc=model+".AMOC_qts.clim.nc"
;  print("Loading ... "+nc)
  fin = addfile(DIR_in+nc,"r")
  var = fin->moc(:,jjj,0)
  xmin= min( (/min(var),xmin/) )
  xmax= max( (/max(var),xmax/) )
  delete(var)
  delete(lat)
end do

dist = (xmax-xmin)*0.1
xmin = tointeger(xmin - dist - 0.5)
xmax = tointeger(xmax + dist + 0.5)
res@trXMinF = xmin
res@trXMaxF = xmax
res@tmXBPrecision      =2

;print(xmin+" "+xmax)
;---------------------------------------------------------------------------------------------------- plot
do mm=0,num_model-1
  model=models(mm)
  DIR_in=DIR_in1+"model/netCDF/"

  nc = model+"."+lat_var+"_vo.fx.nc"
;  print("Loading ... "+nc)
  fin = addfile(DIR_in+nc,"r")
  lat = fin->$lat_var$
  jjj = minind(abs(lat-lat0))

  nc=model+".AMOC_qts.clim.nc"
  fin = addfile(DIR_in+nc,"r")
  var = fin->moc(:,jjj,0)
  var&lev= (/LEV/)
  out(mm,:)=var
  res@xyLineColor = colors(mm)
  plot(mm) = gsn_csm_xy(wks,var,var&lev,res)
  delete(var)
  delete(lat)
end do

do mm=1,num_model-1
  overlay(plot(0),plot(mm))
end do

;---------------------------------------------------------------------------------------------------- plot model mean
; MME=dim_avg_n_Wrap(out,0)
; res@xyDashPattern = 1
; res@xyLineColor = 1
; res@xyLineThicknessF      = 5
; plot1 = gsn_csm_xy (wks,MME,LEV,res)
; overlay(plot(0),plot1)
; delete(MME)
;---------------------------------------------------------------------------------------------------- plot reference
res@xyDashPattern = 0
res@xyLineColor = 1
res@xyLineThicknessF      = 5
plot2 = gsn_csm_xy (wks,REF,LEV,res)
overlay(plot(0),plot2)
delete(REF)

;---------------------------------------------------------------------------------------------------- legend
colorss=new(num_model+1,typeof(colors))
modelss=new(num_model+1,typeof(models))
dashess=ispan(1,num_model+1,1)
colorss(0:num_model-1)=(/colors/)
modelss(0:num_model-1)=(/models/)
dashess(0:num_model-1)=0
colorss(num_model)=1
modelss(num_model)="WOA13"
dashess(num_model)=0
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

;;;;;; Maximize output on the page and draw everything
pres=True
draw(plot(0))
frame(wks)
