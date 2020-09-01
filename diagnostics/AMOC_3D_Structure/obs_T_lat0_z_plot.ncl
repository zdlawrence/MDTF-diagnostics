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

res@tiXAxisString             = "Pot. Temp. (~S~o~N~C)"
res@tiYAxisString             = "Depth (m)"

res@trXMinF = -2
res@trXMaxF = 25. 
res@trYMinF = 0 
res@trYMaxF = 5500
res@trYReverse = True

res@xyMarkLineMode   ="Lines"
res@xyDashPattern    = 0
res@xyLineThicknessF = 2.0

res@trYReverse                  = True
;res@gsnStringFontHeightF=0.028

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DIR_in0    = getenv("CLMREF")
DIR_in1    = getenv("OUTDIR")
DIR_in2    = getenv("OUTDIR")
DIR_out    = getenv("FIGREF")
lat0       = stringtofloat(getenv("LAT0"))

thetao_var = getenv("thetao_var")
lat_var    = getenv("lat_coord")
lev_var    = getenv("lev_coord")

models     = str_split(getenv("MODELS"), " ,")

num_model=dimsizes(models)
if(lat0.ge.0)then
  res@gsnCenterString = "Latitude: "+tostring_with_format(lat0,"%4.1f")+"~S~o~N~N"
else  
  res@gsnCenterString = "Latitude: "+tostring_with_format(abs(lat0),"%4.1f")+"~S~o~N~S"
end if

ncs0="WOA13.thetao_viv.clim.nc"
; ncs2=model+".INDEX_vo.fx.nc"

plot = new(num_model,graphic)
plot0= new(1,graphic)
plot1= new(1,graphic)

order=ispan(0,num_model-1,1)

wks   = gsn_open_wks("pdf",DIR_out+"obs_T_lat0_z_plot")
if(num_model.le.20)then
  gsn_define_colormap(wks,"xbxu")
  colors=floattoint(fspan(1,21,num_model+1))
else
  gsn_define_colormap(wks,"amwg256")
  colors=floattoint(fspan(1,255,num_model))
end if

  nc = DIR_in0+ncs0
  fil = addfile(nc,"r")
  LEV  = fil->depth
  LAT  = fil->$lat_var$
  num_lev=dimsizes(LEV)
  jjj=ind_nearest_coord(lat0,LAT,0)
  obs  = dim_avg_n_Wrap(fil->$thetao_var$(:,jjj,:),1)
  xmin=tointeger( min(obs) )
  xmax=tointeger( max(obs) )

out=new((/num_model,num_lev/),"double",1e20)

do mm=0,num_model-1
  model=models(mm)
  DIR_in1=getenv("WKDIR")+"model/netCDF/"
  nc = DIR_in1+model+".lat_vo.fx.nc"
  print("Loading ... "+nc)
  fin = addfile(nc,"r")
  lat = fin->$lat_var$
  jjj = minind(abs(lat-lat0))

  ncs2=model+".INDEX_vo.fx.nc"
  nc = DIR_in2+ncs2
  print("Now,the nc is:   "+nc)
  fin = addfile(nc,"r")
  viv = fin->$bas_var$(:,jjj,:)
  delete(viv@_FillValue)

  nc = DIR_in1+model+".thetao_viv.clim.nc"
  print("Loading ... "+nc)
  fin = addfile(nc,"r")
  tmp = fin->$thetao_var$(:,jjj,:)
  tmp = where(viv.eq.2,tmp,tmp@_FillValue)
  var = dim_avg_n_Wrap(tmp,1)
  if(max(var).gt.100)then
     var = var - 273.15
  end if
  delete(tmp)
  delete(viv)
;----------------------------------------------------------------------------------------------------
  xmin=tointeger( min( (/min(var),xmin/) ) )
  xmax=tointeger( max( (/max(var),xmax/) ) )  
  delete(lat)
  delete(var)
end do

dist = (xmax-xmin)*0.1
xmin = tointeger(xmin - dist - 0.5)
xmax = tointeger(xmax + dist + 0.5)
res@trXMinF = xmin
res@trXMaxF = xmax

do mm=0,num_model-1
  model=models(mm)
  DIR_in1=getenv("WKDIR")+"model/netCDF/"
  nc = DIR_in1+model+".lat_vo.fx.nc"
  print("Loading ... "+nc)
  fin = addfile(nc,"r")
  lat = fin->$lat_var$
  jjj = minind(abs(lat-lat0))

  nc = DIR_in1+model+".thetao_viv.clim.nc"
  print("Loading ... "+nc)
  fin = addfile(nc,"r")
  lev = fin->$lev_var$
  var = dim_avg_n_Wrap(fin->$thetao_var$(:,jjj,:),1)
  out(mm,:)=linint1_n_Wrap(lev,var,False,LEV,0,0)

  res@xyLineColor = colors(mm)
  printMinMax(var,False)
;  plot(mm) = gsn_csm_xy(wks,var,lev,res)
  delete(lat)
  delete(lev)
  delete(var)
end do
;do mm=1,num_model-1
;;   overlay(plot(0),plot(mm))
;end do

delete(res@xyLineColor)
res@xyDashPattern = 0
res@xyLineColor = "black"
res@xyLineThicknessF      = 3
  printMinMax(obs,False)
plot0 = gsn_csm_xy (wks,obs,LEV,res)

var  = dim_avg_n_Wrap(out,0)
res@xyDashPattern    = 1
res@xyLineColor = "black"
res@xyLineThicknessF      = 2.0
;plot1 = gsn_csm_xy (wks,var,LEV,res)
  printMinMax(var,False)

;overlay(plot(0),plot0)
;overlay(plot(0),plot1)

  lnres               = True
  mkres               = True
  txres               = True         ; Text resources
;  txres@txFontHeightF = 0.012
  txres@txJust        = "CenterLeft"
  xpos= 0.785
  if (num_model.le.20)then
     ypos=(65 + 3 *( ispan(0,num_model,1)-num_model/2 ) )/100.
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
  modelss(0)="WOA13"
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
lgres@lgLineColors       = (/"black"/)
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
labels = (/"WOA13"/)
nitems = dimsizes(labels)                 ; number of legend items

amres                  = True
amres@amJust           = "BottomRight"   ; Use bottom right corner of box 
amres@amParallelPosF   = 0.5 
amres@amOrthogonalPosF = 0.5 
lbid = gsn_create_legend(wks,nitems,labels,lgres)
annoid = gsn_add_annotation(plot0,lbid,amres)  ; add legend to plot
;====================================================================================================

;;;;;; Maximize output on the page and draw everything
pres=True
;pres@gsnPanelDebug =True
;maximize_output(wks,pres)  ; Maximize plot on page
draw(plot0)
frame(wks)
