load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/calendar_decode2.ncl"

DIR_in0 = getenv("MONDIR")
DIR_in1 = getenv("OUTDIR")
DIR_in2 = getenv("OUTDIR")
DIR_out = getenv("TMPDIR")

vo_var = getenv("vo_var")
vmo_var = getenv("vmo_var")
bas_var = getenv("bas_var")
time_var = getenv("time_coord")
lev_var = getenv("lev_coord")
lat_var = getenv("lat_coord")
lon_var = getenv("lon_coord")

model=getenv("CASENAME")
yymm=getenv("YYYYMM")
yyyy=getenv("YYYY")

setfileoption("nc","Format","LargeFile") 

ncs0 = model+"."+vo_var+".mon.nc"
ncs1 = model+".dxdydz_vo.fx.nc"
ncs2 = model+".INDEX_vo.fx.nc"

;----------------------------------STAYR--------------------------------------ENDYR------------------    
;-----------------------yyyy0------yyyy0------yyyy0-----------------yyyy1-----yyyy1-----yyyy1--------    
; Time starts from:       +          0          0                    end       end       -    

print("Loading ... "+ncs0)
fin0 = addfile(DIR_in0+ncs0,"r")

lev      = dble2flt(fin0->$lev_var$)
lev      = abs(lev)
lat      = dble2flt(fin0->$lat_var$)
lon      = dble2flt(fin0->$lon_var$)
time=fin0->$time_var$
tmt=dimsizes(time)
ymt=tmt/12

years=tointeger(floor(cd_calendar(time,4)))
yyyy0=years(0)
yyyy1=years(tmt-1)

print("Loading ... "+ncs1)
fin1 = addfile(DIR_in1+ncs1,"r")
print("Loading ... "+ncs2)
fin2 = addfile(DIR_in2+ncs2,"r")

dx = fin1->dx
dz = fin1->dz

;***************************************************************************************************************************
do y=0,ymt-1
   year=yyyy0+y
   yyyymm=year+"01-"+year+"12"
   print("Processing ... "+yyyymm)
   ta=y*12
   tb=ta+11

   vo  = fin0->$vo_var$(ta:tb,:,:,:)
   vo@_FillValue=1e20
   tmv=dimsizes(vo(:,0,0,0))

   num_tim = dimsizes(vo(:,0,0,0))
   num_lev = dimsizes(vo(0,:,0,0))
   num_lat = dimsizes(vo(0,0,:,0))
   num_lon = dimsizes(vo(0,0,0,:))
   
   bas = fin2->$bas_var$
   do t=0,num_tim-1
      vo(t,:,:,:) = where(bas.lt.0.5,vo@_FillValue,vo(t,:,:,:))
   end do
   
   dx_conform = conform_dims( (/num_tim,num_lev,num_lat,num_lon/), dx, (/1,2,3/) )
   dz_conform = conform_dims( (/num_tim,num_lev,num_lat,num_lon/), dz, (/1,2,3/) )
   
   vmo = vo
   vmo = (/vo * dx_conform * dz_conform/)
   if(max(abs(vmo(0,0:1,:,:))).gt.1e7)then
      vmo = vmo / 1e9
   else
      vmo = vmo / 1e6
   end if
   vmo@long_name="Meridional Volume Transport"
   vmo@units="m^3/s"
   ;----------------------------------------------------------------------------------------------------
   fNames = getfilevarnames(fin0)
   numf=dimsizes(fNames)
   ;print(""+fNames)
   
   var=fin0->$vo_var$(0:0,0:1,0:1,0:1)
   vNames=getVarDimNames(var)
   delete(var)
   
   numv=dimsizes(vNames)
   ;print(""+vNames)
   
   ;print("==============================")
   nums=numf-numv-1
   Names=fNames(0:nums)
   Names=""
   n=0
   do v=0,numf-1
      vvv=fin0->$fNames(v)$!0
      if(all( vNames.ne.fNames(v)) .and. fNames(v).ne."vo" .and. vvv.ne."time")then
         Names(n)=fNames(v)
         n=n+1
      end if
   end do   
   
   ;print(""+Names)
   ;----------------------------------------------------------------------------------------------------
   fout = addfile(DIR_out+model+"."+vmo_var+"_"+yyyymm+".mon.nc","c")
   ;=============================================================================
   do n=0,nums-1
      if(Names(n).eq."")then
         break
      end if
      ;   print(""+Names(n))
      fout->$Names(n)$ = fin0->$Names(n)$
   end do
   fout->$vmo_var$ = vmo
   
   delete(vmo)
end do ;;; year loop
