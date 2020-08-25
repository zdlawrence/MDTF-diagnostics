load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/calendar_decode2.ncl"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DIR_in0    = getenv("OUTDIR")
DIR_in1    = getenv("MONDIR")
DIR_in2    = getenv("TMPDIR")
DIR_out    = getenv("TMPDIR")
STAYR      = stringtointeger(getenv("STAYR"))
ENDYR      = stringtointeger(getenv("ENDYR"))

thetao_var = getenv("thetao_var")
so_var = getenv("so_var")
vmo_var = getenv("vmo_var")
bas_var = getenv("bas_var")
time_var = getenv("time_coord")

model=getenv("CASENAME")
yymm=getenv("YYYYMM")
yyyy=getenv("YYYY")

ncs0  = (/model+".INDEX_vo.fx.nc"/)
ncs1  = (/model+"."+thetao_var+".mon.nc", model+"."+so_var+".mon.nc"/)
ncs2  = model+"."+vmo_var+"_"+yymm+".mon.nc"

;----------------------------------STAYR--------------------------------------ENDYR------------------               
;-----------------------yyyy0------yyyy0------yyyy0-----------------yyyy1-----yyyy1-----yyyy1--------               
; Time starts from:       +          0          0                    end       end       -                 

ncI  = DIR_in0+ncs0(0)

ncT  = DIR_in1+ncs1(0)
print("Loading ... "+ncT)
finT = addfile(ncT,"r") 

time=finT->$time_var$
tmt=dimsizes(time)
ymt=tmt/12

years=tointeger(floor(cd_calendar(time,4)))
yyyy0=years(0)
yyyy1=years(tmt-1)

ncS = DIR_in1+ncs1(1)
finS = addfile(ncS,"r") 

ncV = DIR_in2+ncs2
finV = addfile(ncV,"r") 

step0=minind(abs(years-tointeger(yyyy)))
step0=step0+1
step1=step0+11
;----------------------------------------------------------------------------------------------------
print("Processing ... "+yymm)

fo=DIR_out+model+"."+thetao_var+"_viv_"+yymm+".mon.nc"
system("rm -f "+fo)
system("cdo --no_warnings -ifthen "+ncI+" -remapbil,"+ncI+" -fillmiss2 -setctomiss,0 -selvar,"+thetao_var+" -seltimestep,"+step0+"/"+step1+" "+ncT+" "+fo)

fo=DIR_out+model+"."+so_var+"_viv_"+yymm+".mon.nc"
system("rm -f "+fo)
system("cdo --no_warnings -ifthen "+ncI+" -remapbil,"+ncI+" -fillmiss2 -setctomiss,0 -selvar,"+so_var+" -seltimestep,"+step0+"/"+step1+" "+ncS+" "+fo)

;----------------------------------------------------------------------------------------------------
fNames = getfilevarnames(finV)
numf=dimsizes(fNames)
;print(""+fNames)

;print("==============================")
var=finV->$vmo_var$(0:0,0:0,0:0,0:0)
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
   vvv=finV->$fNames(v)$!0
   if(all( vNames.ne.fNames(v)) .and. fNames(v).ne."vmo" .and. vvv.ne."time")then
      Names(n)=fNames(v)
      n=n+1
   end if
end do

vmo=finV->$vmo_var$

;----------------------------------------------------------------------------------------------------
thetao=finT->$thetao_var$

fo=DIR_out+model+"."+thetao_var+"_viv_"+yymm+".mon.nc"
fino = addfile(fo,"r") 
ttt = fino->$thetao_var$
copy_VarCoords(vmo,ttt)
copy_VarAtts(thetao,ttt)
fo=DIR_out+model+"."+thetao_var+"_viv_"+yymm+".mon.nc"
system("rm -f "+fo)
fout = addfile(fo,"c")
;=============================================================================
do n=0,nums-1
;   print(""+Names(n))
   if(Names(n).ne."")then
     fout->$Names(n)$ = finV->$Names(n)$
   end if
end do
  fout->$thetao_var$ = ttt
delete(thetao)  
delete(ttt)  
;----------------------------------------------------------------------------------------------------
so=finS->$so_var$

fo=DIR_out+model+"."+so_var+"_viv_"+yymm+".mon.nc"
fino = addfile(fo,"r") 
sss = fino->$so_var$
copy_VarCoords(vmo,sss)
copy_VarAtts(so,sss)
fo=DIR_out+model+"."+so_var+"_viv_"+yymm+".mon.nc"
system("rm -f "+fo)
fout = addfile(fo,"c")
;=============================================================================
do n=0,nums-1
;   print(""+Names(n))
   if(Names(n).ne."")then
     fout->$Names(n)$ = finV->$Names(n)$
   end if
end do
  fout->$so_var$ = sss
delete(so)  
delete(sss)  
