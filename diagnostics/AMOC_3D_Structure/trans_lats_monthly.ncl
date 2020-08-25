load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DIR_in     = getenv("OUTDIR")
DIR_in0    = getenv("TMPDIR")
DIR_in1    = getenv("TMPDIR")
DIR_in2    = getenv("TMPDIR")
DIR_out    = getenv("TMPDIR")

thetao_var = getenv("thetao_var")
so_var = getenv("so_var")
vmo_var = getenv("vmo_var")
bas_var = getenv("bas_var")
time_var = getenv("time_coord")
lat_var = getenv("lat_coord")

DT = stringtofloat(getenv("DT"))
DS = stringtofloat(getenv("DS"))

model=getenv("CASENAME")
yymm=getenv("YYYYMM")
yyyy=getenv("YYYY")
year0=getenv("YEAR0")

print(DT+" "+DS)
zmt=tointeger(34./DT)
smt=tointeger(6./DS)
print(zmt+" "+smt)
thetas = fspan(-2.+DT/2., 32.-DT/2., zmt)
  salt = fspan(32.+DS/2., 38.-DS/2., smt)
   eps = 1e-6

INDEXs= model+".INDEX_vo.fx.nc"
lats  = model+"."+lat_var+"_vo.fx.nc"
ncs0  = model+"."+thetao_var+"_viv_"+yymm+".mon.nc"
ncs1  = model+"."+so_var+"_viv_"+yymm+".mon.nc"
ncs2  = model+"."+vmo_var+"_"+yymm+".mon.nc"

year=year0
;setfileoption("nc","Format","LargeFile")

;***************************************************************************************************************************
  nc  = DIR_in+lats
  print("loading ... "+nc)
  fin = addfile(nc,"r") 
  lat = fin->$lat_var$

  nc  = DIR_in+INDEXs
  print("loading ... "+nc)
  fin = addfile(nc,"r") 
  viv = fin->$bas_var$
  delete(viv@_FillValue)

  nc  = DIR_in0+ncs0
  print("loading ... "+nc)
  fin0 = addfile(nc,"r") 

  nc  = DIR_in1+ncs1
  print("loading ... "+nc)
  fin1 = addfile(nc,"r") 

  nc  = DIR_in2+ncs2
  print("loading ... "+nc)
  fin2 = addfile(nc,"r") 

  tmv=dimsizes(fin2->$time_var$)
  ymt=tmv/12
do y=0,ymt-1
  print("Processing ... "+year)
  yyyymm=year+"01-"+year+"12"
  year=year+1
  ta=y*12  
  tb=y*12+11
  time=fin2->$time_var$(ta:tb)
  tmv=dimsizes(time)

  thetao = fin0->$thetao_var$(ta:tb,:,:,:)
  if(max(thetao(0,0:1,:,:)).gt.100)then
     thetao= thetao - 273.15
  end if

  so = fin1->$so_var$(ta:tb,:,:,:)
  if(max(so(0,0:1,:,:)).lt.10)then
     so= so * 1000.
  end if

  vmo = fin2->$vmo_var$(ta:tb,:,:,:)
  if(max(abs(vmo(0,0:1,:,:))).gt.1e7)then
     vmo= vmo/1e9
  end if
  if(max(abs(vmo(0,0:1,:,:))).gt.1e4)then
     vmo= vmo/1e6
  end if

;print("==================== Data Loading OK ====================")
;----------------------------------------------------------------------------------------------------
  tmv = dimsizes(vmo(:,0,0,0))
  kmv = dimsizes(vmo(0,:,0,0))
  jmv = dimsizes(vmo(0,0,:,0))
  imv = dimsizes(vmo(0,0,0,:))

;----------------------------------------------------------------------------------------------------
   trans = new((/12,zmt,smt,jmv/),  "float", 1e20)
     sit = new((/12,zmt,smt,jmv/),"integer",-9999)
   trans = 0
    sit  = 0

do t=0,tmv-1
  thetao(t,:,:,:)=where(viv.eq.2,thetao(t,:,:,:),thetao@_FillValue)
      so(t,:,:,:)=where(viv.eq.2,    so(t,:,:,:),    so@_FillValue)
     vmo(t,:,:,:)=where(viv.eq.2,   vmo(t,:,:,:),   vmo@_FillValue)
end do

;print("==================== BASIN Setting OK ====================")
N2=num(viv.eq.2)
Nv=0

do i=0,imv-1
   if(all(viv(0,:,i).ne.2))then
      continue
      ;; kick out Pacific, Indian etc.
   end if
do j=0,jmv-1
   if(all(viv(:,j,i).ne.2))then
      continue
      ;; kick out land column
   end if
do k=0,kmv-1
   if(viv(k,j,i).ne.2)then
      continue
      ;; kick out land surounding Atlantic.
   end if
;----------------------------------------------------------------------------------------------------
do t=0,tmv-1
;   if(ismissing(vmo(t,k,j,i)) .or. ismissing(thetao(t,k,j,i)) .or. ismissing(so(t,k,j,i)))then
   if(ismissing(vmo(t,k,j,i)))then
     continue
    ;; in case sea/land varies with time.
   end if
   Nv=Nv+1
   z = minind(abs(thetao(t,k,j,i)+eps-thetas))
   s = minind(abs(so(t,k,j,i)+eps-salt))
;   print("t,k,j,i,T,z"+t+" "+k+" "+j+" "+i+" "+thetao(t,k,j,i)+" "+z)
   trans(t,z,s,j) = trans(t,z,s,j) + vmo(t,k,j,i)
   sit  (t,z,s,j) = sit  (t,z,s,j) + 1 
end do ;;; t loop
end do ;;; i loop
end do ;;; k loop
end do ;;; j loop

;print(N2+" "+Nv/tmv)

  thetas@long_name = "theta"
    salt@long_name = "salt"
  thetas@units     = "DegC"
    salt@units     = "psu"
  trans=where(sit.gt.0,trans,trans@_FillValue)
  trans!0="time"
  trans!1="theta"
  trans!2="salt"
  trans!3="lat"
  trans&time  = time
  trans&theta = thetas
  trans&salt  = salt
  trans&lat   = lat
  trans@long_name="V(T,S)"
  trans@units    ="Sv"
;  printVarSummary(trans)
;----------------------------------------------------------------------------------------------------
    system("rm "+DIR_out+model+".trans_"+yyyymm+".mon.nc")
  fout = addfile(DIR_out+model+".trans_"+yyyymm+".mon.nc","c")
  ;=============================================================================
  fout->trans = trans

  delete(thetao)
  delete(so)
  delete(vmo)
  delete(trans)
  delete(sit)
end do ;;; year loop
