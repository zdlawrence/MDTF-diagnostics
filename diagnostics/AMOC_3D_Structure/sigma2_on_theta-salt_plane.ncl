load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"

begTime = get_cpu_time()

test=True

;---------------------------------------------------------------------
        a0  =  9.9984085444849347e+02
        a1  =  7.3471625860981584e+00
        a2  = -5.3211231792841769e-02
        a3  =  3.6492439109814549e-04
        a4  =  2.5880571023991390e+00
        a5  = -6.7168282786692355e-03
        a6  =  1.9203202055760151e-03
        a7  =  1.1798263740430364e-02
        a8  =  9.8920219266399117e-08
        a9  =  4.6996642771754730e-06
        a10 = -2.5862187075154352e-08
        a11 = -3.2921414007960662e-12

        b0  =  1.0000000000000000e+00
        b1  =  7.2815210113327091e-03
        b2  = -4.4787265461983921e-05
        b3  =  3.3851002965802430e-07
        b4  =  1.3651202389758572e-10
        b5  =  1.7632126669040377e-03
        b6  = -8.8066583251206474e-06
        b7  = -1.8832689434804897e-10
        b8  =  5.7463776745432097e-06
        b9  =  1.4716275472242334e-09
        b10 =  6.7103246285651894e-06
        b11 = -2.4461698007024582e-17
        b12 = -9.1534417604289062e-18
;---------------------------- DIR & ncs ------------------------------
DIR_out    = getenv("OUTDIR")

DT = stringtofloat(getenv("DT"))
DS = stringtofloat(getenv("DS"))

model=getenv("CASENAME")
yymm=getenv("YYYYMM")
yyyy=getenv("YYYY")

print(DT+" "+DS)
zmt=tointeger(34./DT)
smt=tointeger(6./DS)
print(zmt+" "+smt)
theta = fspan(-2.+DT/2., 32.-DT/2., zmt)
 salt = fspan(32.+DS/2., 38.-DS/2., smt)
  eps = 1e-6

;print("--------------- Read Data OK ---------------")

t = new((/1,zmt,smt,1/),"float",1e20)
s = new((/1,zmt,smt,1/),"float",1e20)

t = conform_dims(dimsizes(t),theta,(/1/))
s = conform_dims(dimsizes(s), salt,(/2/))

p=2000.
     t2  = t*t
     sp5 = sqrt(s)
     pt = p*t

;num0=new(dimsizes(t),double,1e20)
;den0=new(dimsizes(t),double,1e20)
;sig2=new(dimsizes(t),double,1e20)
num0=t
den0=t
sig2=t
num0=1e20
den0=1e20
sig2=1e20

epsln=1e-20

num0 = a0 + t*(a1 + t*(a2+a3*t) ) \
          + s*(a4 + a5*t  + a6*s) \
          + p*(a7 + a8*t2 + a9*s + p*(a10+a11*t2))

den0 = b0 + t*(b1 + t*(b2 + t*(b3 + t*b4)))       \
          + s*(b5 + t*(b6 + b7*t2) + sp5*(b8 + b9*t2)) \
          + p*(b10 + pt*(b11*t2 + b12*p))

sig2 = num0/(epsln+den0)
print("Density compute OK: " + (get_cpu_time() - begTime))

tim=0.0
tim@long_name = "time"
tim@units = "days since 1860-01-01 00:00:00"

theta@long_name = "theta"
theta@units = "DegC"

salt@long_name = "Salinity"
salt@units = "psu"

lat=0.0
lat@long_name = "latitude"
lat@units = "degree_north"

sig2!0="time"
sig2!1="theta"
sig2!2="salt"
sig2!3="lat"
sig2@long_name="potential density"
sig2@units="kg/m^3"
sig2&time=tim
sig2&theta=theta
sig2&salt=salt
sig2&lat=lat
;printVarSummary(sig2)
;---------------------------------------------------------------------
  system("rm "+DIR_out+"TMP.sigma2.fx.nc")
fout = addfile(DIR_out+"TMP.sigma2.fx.nc","c")
;=============================================================================
fout->sig2 = sig2

print("Plot generation time: " + (get_cpu_time() - begTime))
