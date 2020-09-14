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

res@xyMarkLineMode   ="Lines"
res@xyDashPattern    = 0 
res@xyLineThicknessF = 2.0 
res@tiXAxisString             = "Streamfunction (Sv)"
res@tiYAxisString             = "Salinity (psu)"

res@trYReverse                  = True

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;---------------------------------------------------------------------------------------------------- Enviromental variables
DIR_ina    = getenv("FIXREF")
DIR_in0    = getenv("CLMREF")
DIR_in1    = getenv("WKDIR")
DIR_out    = getenv("FIGREF")
lat0       = stringtofloat(getenv("LAT0"))
models = str_split(getenv("MODELS"), " ,")
num_model=dimsizes(models)

so_var  = getenv("so_var")
lev_var = getenv("lev_coord")
lat_var = getenv("lat_coord")

if(lat0.ge.0)then
  res@gsnCenterString = "Latitude: "+tostring_with_format(lat0,"%4.1f")+"~S~o~N~N"
else  
  res@gsnCenterString = "Latitude: "+tostring_with_format(abs(lat0),"%4.1f")+"~S~o~N~S"
end if

ncsa="HYCOM.lat_vo.fx.nc"
ncs0="HYCOM.AMOCS_qts.clim.nc"

plot = new(num_model,graphic)
plot1 = new(1,graphic)
plot2 = new(1,graphic)

wks   = gsn_open_wks("pdf",DIR_out+"/sum_AMOCS_S_plot")
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
REF  = fin->moc(0,:,jjj,0)
LEV  = fin->$lev_var$
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

  nc=model+".AMOCS_qts.clim.nc"
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
res@trYMinF = 34.0
res@trYMaxF = 38.0
res@tmYLPrecision      =2

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

  nc=model+".AMOCS_qts.clim.nc"
  fin = addfile(DIR_in+nc,"r")
  var = fin->moc(:,jjj,0)
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
MME=dim_avg_n_Wrap(out,0)
res@xyDashPattern = 1
res@xyLineColor = 1
res@xyLineThicknessF      = 5
plot1 = gsn_csm_xy (wks,MME,LEV,res)
overlay(plot(0),plot1)
delete(MME)
;---------------------------------------------------------------------------------------------------- plot reference
res@xyDashPattern = 0
res@xyLineColor = 1
res@xyLineThicknessF      = 5
plot2 = gsn_csm_xy (wks,REF,LEV,res)
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
modelss(num_model+1)="WOA13"
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

;;;;;; Maximize output on the page and draw everything
pres=True
draw(plot(0))
frame(wks)
