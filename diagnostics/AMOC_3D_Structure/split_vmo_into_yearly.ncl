load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/calendar_decode2.ncl"

DIR_in0 = getenv("MONDIR")
DIR_out = getenv("TMPDIR")


vmo_var = getenv("vmo_var")
time_var = getenv("time_coord")

model=getenv("CASENAME")
yymm=getenv("YYYYMM")
yyyy=getenv("YYYY")

setfileoption("nc","Format","LargeFile") 
ncs0 = model+"."+vmo_var+".mon.nc"

;----------------------------------STAYR--------------------------------------ENDYR------------------    
;-----------------------yyyy0------yyyy0------yyyy0-----------------yyyy1-----yyyy1-----yyyy1--------    
; Time starts from:       +          0          0                    end       end       -    


print("Loading ... "+ncs0)
fin0 = addfile(DIR_in0+ncs0,"r")
time=fin0->$time_var$
tmt=dimsizes(time)
ymt=tmt/12

years=tointeger(floor(cd_calendar(time,4)))
yyyy0=years(0)
yyyy1=years(tmt-1)

;***************************************************************************************************************************
do y=0,ymt-1
   year=yyyy0+y
   yyyymm=year+"01-"+year+"12"
   print("Processing ... "+yyyymm)
   ta=y*12
   tb=ta+11

   vmo  = fin0->$vmo_var$(ta:tb,:,:,:)
   vmo@_FillValue=1e20
   tim  = dble2flt(time(ta:tb))
   if(max(abs(vmo(0,0:1,:,:))).gt.1e7)then
      vmo = vmo / 1e9
   else if(max(abs(vmo(0,0:1,:,:))).lt.1e2)then
      vmo = vmo
   else
      vmo = vmo / 1e6
   end if
   end if
   vmo@long_name="Meridional Volume Transport"
   vmo@units="Sv"
   ;----------------------------------------------------------------------------------------------------
   fNames = getfilevarnames(fin0)
   numf=dimsizes(fNames)
   
   var=fin0->$vmo_var$(0:0,0:1,0:1,0:1)
   vNames=getVarDimNames(var)
   delete(var)
   
   numv=dimsizes(vNames)
   
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
   ;----------------------------------------------------------------------------------------------------
   
     system("rm "+DIR_out+model+"."+vmo_var+"_"+yyyymm+".mon.nc")
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
