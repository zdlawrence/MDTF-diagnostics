load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"

begTime = get_cpu_time()

DIR_in0=getenv("TMPDIR")
DIR_out=getenv("OUTDIR")
which=getenv("which_mean")

time_var = getenv("time_var")

model=getenv("CASENAME")
yymm=getenv("YYYYMM")
yyyy=getenv("YYYY")
str0=getenv("STR0")
var0=getenv("VAR0")

setfileoption("nc","Format","LargeFile")

files = systemfunc("ls "+DIR_in0+model+"."+str0+"_????-????.yr.nc")
f=addfiles(files,"r")
tmt=dimsizes(f[:]->$time_var$)

print("Loading ... "+files)

;print("----------------------------- "+model+" --------------------------------------")
ListSetType (f, "cat")        ; concatenate (=default)

if(which .eq. "occur_times")then
  vmo= dim_avg_n_Wrap(f[:]->$var0$,0)
else
  vmo= dim_sum_n_Wrap(f[:]->$var0$,0)
  vmo= vmo/tmt
end if  

vmo@_FillValue=1e20
;printVarSummary(vmo)

fNames = getfilevarnames(f[0])
numf=dimsizes(fNames)
;print(""+fNames)

;print("==============================")
var=f[0]->$var0$(0:0,0:1,0:1,0:0)
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
   vvv=f[0]->$fNames(v)$!0
   if(all( vNames.ne.fNames(v)) .and. fNames(v).ne.var0 .and. vvv.ne."time")then
      Names(n)=fNames(v)
      n=n+1
   end if
end do   

numo=nums-n
if(numo.ne.0)then
oNames=fNames(0:numo-1)
if(n.eq.0)then
   do v=0,numf-1
      if(all( vNames.ne.fNames(v)) .and. fNames(v).ne.var0)then
         oNames(n)=fNames(v)
         n=n+1
      end if
   end do   
else   
   do v=0,numf-1
      if( all( vNames.ne.fNames(v)) .and. fNames(v).ne.var0 .and. all(Names.ne.fNames(v)) )then
         oNames(n)=fNames(v)
         n=n+1
      end if
   end do   
end if
end if

;print("numo="+numo)
;print("Extra Coords:"+Names)
;print("Out variables: "+oNames)

  system("rm "+DIR_out+model+"."+str0+".clim.nc")
fout = addfile(DIR_out+model+"."+str0+".clim.nc","c")
do n=0,nums-1
   if(Names(n).eq."")then
      break
   end if
;   print(""+Names(n))
   fout->$Names(n)$ = f[0]->$Names(n)$
end do
fout->$var0$  = vmo
if(numo.ne.0)then
do n=0,numo-1
   if(oNames(n).eq."")then
      break
   end if
;   print(""+oNames(n))
   if(which .eq. "occur_times")then
      var=dim_avg_n_Wrap(f[:]->$oNames(n)$,0)
   else
      var=dim_sum_n_Wrap(f[:]->$oNames(n)$,0)
      var=var/tmt
   end if
   fout->$oNames(n)$ = var
   delete(var)
end do
end if
