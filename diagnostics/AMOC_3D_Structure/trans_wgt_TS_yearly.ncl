load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"


DIR_in0    = getenv("OUTDIR")
DIR_in1    = getenv("TMPDIR")
DIR_in2    = getenv("TMPDIR")
DIR_out    = getenv("TMPDIR")

thetao_var = getenv("thetao_var")
so_var = getenv("so_var")
time_var = getenv("time_coord")
lat_var = getenv("lat_coord")

model=getenv("CASENAME")
yymm=getenv("YYYYMM")
yyyy=getenv("YYYY")
year0=getenv("YEAR0")

ncs0="TMP.sigma2.fx.nc"
ncs1=model+".AMOC_qts_"+yyyy+".yr.nc"
ncs2=model+".trans_"+yyyy+".yr.nc"

eps=1e-5
;====================================================================================================
nc  = DIR_in0+ncs0
print("Loading ... "+nc)
fin = addfile(nc,"r") 
sig2= fin->sig2(0,:,:,0)
sig2= sig2 - 1000.

nc  = DIR_in1+ncs1
print("Loading ... "+nc)
fin1 = addfile(nc,"r") 

nc  = DIR_in2+ncs2
print("Loading ... "+nc)
fin2 = addfile(nc,"r") 
theta = fin2->theta
salt  = fin2->salt 
lat = fin2->$lat_var$
num_theta=dimsizes(theta)
num_salt =dimsizes(salt )
num_lat  =dimsizes(lat  )

time= fin1->$time_var$
ymt=dimsizes(time)

year=year0

tt  =conform_dims((/num_theta,num_salt,num_lat/),theta,(/0/))
ss  =conform_dims((/num_theta,num_salt,num_lat/),salt ,(/1/))
sig =conform_dims((/num_theta,num_salt,num_lat/),sig2   ,(/0,1/))

do y=0,ymt-1
   yyyy=year+"-"+year
   year=year+1

   moc = fin1->moc(y,:,:,0)
   sig_max = fin1->sig_max(y,:)
   sig_000 = fin1->sig_000(y,:)
   sig_min = fin1->sig_min(y,:)
   moc_000 = fin1->moc_000(y,:)
   
   trans = fin2->trans(y,:,:,:)
   
   Tavg=new((/1,5,num_lat,4/),"float",1e20)
   Savg=new((/1,5,num_lat,4/),"float",1e20)
   Qavg=new((/1,5,num_lat,4/),"float",1e20)

   Smax=conform_dims((/num_theta,num_salt,num_lat/),sig_max,(/2/))
   S000=conform_dims((/num_theta,num_salt,num_lat/),sig_000,(/2/))
   Smin=conform_dims((/num_theta,num_salt,num_lat/),sig_min,(/2/))
   vit =new((/num_theta,num_salt,num_lat/),"integer",-9999)
   sit =new((/num_theta,num_salt,num_lat/),"integer",-9999)

   dist=S000
   dist=abs(sig-S000)
   S=sig_000
   T=sig_000
   VT_offset=moc_000
   VS_offset=moc_000
   do j=0,num_lat-1
      X=dist(:,:,j)
      if(all(ismissing(X)))then
        continue
      end if
      dims = dimsizes(X)
      x1d = ndtooned(X)
      inds = ind_resolve(minind (x1d), dims)
      ilat = inds(0,0)
      ilon = inds(0,1)
      T(j) = (/theta(ilat)/)
      S(j) = (/salt(ilon)/)
   end do
   VT_offset=moc_000*T
   VS_offset=moc_000*S

   ; 0:4, (,Smax], (Smax,S000], (S000,), (Smax,Smin], (Smin,)
   ; 0:3, net, pos, neg, abs
   
   lat0=26.5
   jjj =ind_nearest_coord(lat0,lat,0)
;   print(jjj+" "+lat(jjj)+" "+sig_max(jjj)+" "+sig_000(jjj)+" "+sig_min(jjj))
   ;====================================================================================================
   trans_abs=abs(trans)
   VT=trans
   VS=trans
   VT_abs=trans_abs
   VS_abs=trans_abs
   
   VT=trans*tt
   VS=trans*ss
   VT_abs=trans_abs*tt
   VS_abs=trans_abs*ss
   ;====================================================================================================
   ;  upper layer
   vit=where(sig+eps.le.Smax,1,vit@_FillValue)
   
   ;----------------------------------------------------------------------------------------------------
   ;  absolute
   Tsum=dim_sum_n_Wrap(dim_sum_n_Wrap(VT_abs*vit,0),0)
   Ssum=dim_sum_n_Wrap(dim_sum_n_Wrap(VS_abs*vit,0),0)
   wgt =dim_sum_n_Wrap(dim_sum_n_Wrap(trans_abs*vit,0),0)
   
   Tavg(0,0,:,3)=where(.not.ismissing(wgt),Tsum/wgt,Tavg@_FillValue)
   Savg(0,0,:,3)=where(.not.ismissing(wgt),Ssum/wgt,Savg@_FillValue)
   Qavg(0,0,:,3)=(/wgt/)
   
   ;----------------------------------------------------------------------------------------------------
   ;  net
   Tsum=dim_sum_n_Wrap(dim_sum_n_Wrap(VT*vit,0),0)
   Ssum=dim_sum_n_Wrap(dim_sum_n_Wrap(VS*vit,0),0)
   wgt =dim_sum_n_Wrap(dim_sum_n_Wrap(trans*vit,0),0)
   
   Tavg(0,0,:,0)=where(.not.ismissing(wgt),Tsum/wgt,Tavg@_FillValue)
   Savg(0,0,:,0)=where(.not.ismissing(wgt),Ssum/wgt,Savg@_FillValue)
   Qavg(0,0,:,0)=(/wgt/)
   
   ;----------------------------------------------------------------------------------------------------
   ;  positive
   sit=where(trans.gt.0,1,sit@_FillValue)
   
   Tsum=dim_sum_n_Wrap(dim_sum_n_Wrap(VT*vit*sit,0),0)
   Ssum=dim_sum_n_Wrap(dim_sum_n_Wrap(VS*vit*sit,0),0)
   wgt =dim_sum_n_Wrap(dim_sum_n_Wrap(trans*vit*sit,0),0)
   
   Tavg(0,0,:,1)=where(.not.ismissing(wgt),Tsum/wgt,Tavg@_FillValue)
   Savg(0,0,:,1)=where(.not.ismissing(wgt),Ssum/wgt,Savg@_FillValue)
   Qavg(0,0,:,1)=(/wgt/)
   
   ;----------------------------------------------------------------------------------------------------
   ;  negative
   sit=where(trans.le.0,1,sit@_FillValue)
   
   Tsum=dim_sum_n_Wrap(dim_sum_n_Wrap(VT*vit*sit,0),0)
   Ssum=dim_sum_n_Wrap(dim_sum_n_Wrap(VS*vit*sit,0),0)
   wgt =dim_sum_n_Wrap(dim_sum_n_Wrap(trans*vit*sit,0),0)
   
   Tavg(0,0,:,2)=where(.not.ismissing(wgt),Tsum/wgt,Tavg@_FillValue)
   Savg(0,0,:,2)=where(.not.ismissing(wgt),Ssum/wgt,Savg@_FillValue)
   Qavg(0,0,:,2)=(/wgt/)
   
   ;====================================================================================================
   ;  Middle layer 000
   vit=where(sig.gt.Smax .and. sig+eps.le.S000,1,vit@_FillValue)
;   print(theta+" "+vit(:,75,jjj)*sig(:,75,jjj)+" "+dim_sum_n_Wrap(trans(:,:,jjj)*vit(:,:,jjj),1))
   ;exit
   
   ;----------------------------------------------------------------------------------------------------
   ;  absolute
   Tsum=dim_sum_n_Wrap(dim_sum_n_Wrap(VT_abs*vit,0),0)
   Ssum=dim_sum_n_Wrap(dim_sum_n_Wrap(VS_abs*vit,0),0)
   wgt =dim_sum_n_Wrap(dim_sum_n_Wrap(trans_abs*vit,0),0)
   Tsum=Tsum+VT_offset
   Ssum=Ssum+VS_offset
   wgt=wgt+moc_000

   Tavg(0,1,:,3)=where(.not.ismissing(wgt),Tsum/wgt,Tavg@_FillValue)
   Savg(0,1,:,3)=where(.not.ismissing(wgt),Ssum/wgt,Savg@_FillValue)
   Qavg(0,1,:,3)=(/wgt/)
   
   ;----------------------------------------------------------------------------------------------------
   ;  net
   Tsum=dim_sum_n_Wrap(dim_sum_n_Wrap(VT*vit,0),0)
   Ssum=dim_sum_n_Wrap(dim_sum_n_Wrap(VS*vit,0),0)
   wgt =dim_sum_n_Wrap(dim_sum_n_Wrap(trans*vit,0),0)
   Tsum = Tsum - VT_offset
   Ssum = Ssum - VS_offset
   wgt  = wgt - moc_000
   
   Tavg(0,1,:,0)=where(.not.ismissing(wgt),Tsum/wgt,Tavg@_FillValue)
   Savg(0,1,:,0)=where(.not.ismissing(wgt),Ssum/wgt,Savg@_FillValue)
   Qavg(0,1,:,0)=(/wgt/)
   
   ;----------------------------------------------------------------------------------------------------
   ;  positive
   sit=where(trans.gt.0,1,sit@_FillValue)
   
   Tsum=dim_sum_n_Wrap(dim_sum_n_Wrap(VT*vit*sit,0),0) 
   Ssum=dim_sum_n_Wrap(dim_sum_n_Wrap(VS*vit*sit,0),0)
   wgt =dim_sum_n_Wrap(dim_sum_n_Wrap(trans*vit*sit,0),0)
   
   Tavg(0,1,:,1)=where(.not.ismissing(wgt),Tsum/wgt,Tavg@_FillValue)
   Savg(0,1,:,1)=where(.not.ismissing(wgt),Ssum/wgt,Savg@_FillValue)
   Qavg(0,1,:,1)=(/wgt/)
   
   ;----------------------------------------------------------------------------------------------------
   ;  negative
   sit=where(trans.le.0,1,sit@_FillValue)
   
   Tsum=dim_sum_n_Wrap(dim_sum_n_Wrap(VT*vit*sit,0),0)
   Ssum=dim_sum_n_Wrap(dim_sum_n_Wrap(VS*vit*sit,0),0)
   wgt =dim_sum_n_Wrap(dim_sum_n_Wrap(trans*vit*sit,0),0)
   Tsum = Tsum - VT_offset
   Ssum = Ssum - VS_offset
   wgt  = wgt - moc_000
   
   Tavg(0,1,:,2)=where(.not.ismissing(wgt),Tsum/wgt,Tavg@_FillValue)
   Savg(0,1,:,2)=where(.not.ismissing(wgt),Ssum/wgt,Savg@_FillValue)
   Qavg(0,1,:,2)=(/wgt/)
   
;   print(Tavg(0,1,jjj,2)+" "+Savg(0,1,jjj,2)+" "+Qavg(0,1,jjj,2))
   ;====================================================================================================
   ;  Lower layer
   vit=where(sig.gt.S000,1,vit@_FillValue)
   
   ;----------------------------------------------------------------------------------------------------
   ;  absolute
   Tsum=dim_sum_n_Wrap(dim_sum_n_Wrap(VT_abs*vit,0),0)
   Ssum=dim_sum_n_Wrap(dim_sum_n_Wrap(VS_abs*vit,0),0)
   wgt =dim_sum_n_Wrap(dim_sum_n_Wrap(trans_abs*vit,0),0)
   Tsum=Tsum-VT_offset
   Ssum=Ssum-VS_offset
   wgt=wgt-moc_000
   
   Tavg(0,2,:,3)=where(.not.ismissing(wgt),Tsum/wgt,Tavg@_FillValue)
   Savg(0,2,:,3)=where(.not.ismissing(wgt),Ssum/wgt,Savg@_FillValue)
   Qavg(0,2,:,3)=(/wgt/)
   
   ;----------------------------------------------------------------------------------------------------
   ;  net
   Tsum=dim_sum_n_Wrap(dim_sum_n_Wrap(VT*vit,0),0)
   Ssum=dim_sum_n_Wrap(dim_sum_n_Wrap(VS*vit,0),0)
   wgt =dim_sum_n_Wrap(dim_sum_n_Wrap(trans*vit,0),0)
   Tsum = Tsum + VT_offset
   Ssum = Ssum + VS_offset
   wgt  = wgt + moc_000
   
   Tavg(0,2,:,0)=where(.not.ismissing(wgt),Tsum/wgt,Tavg@_FillValue)
   Savg(0,2,:,0)=where(.not.ismissing(wgt),Ssum/wgt,Savg@_FillValue)
   Qavg(0,2,:,0)=(/wgt/)
   
   ;----------------------------------------------------------------------------------------------------
   ;  positive
   sit=where(trans.gt.0,1,sit@_FillValue)
   
   Tsum=dim_sum_n_Wrap(dim_sum_n_Wrap(VT*vit*sit,0),0)
   Ssum=dim_sum_n_Wrap(dim_sum_n_Wrap(VS*vit*sit,0),0)
   wgt =dim_sum_n_Wrap(dim_sum_n_Wrap(trans*vit*sit,0),0)
   
   Tavg(0,2,:,1)=where(.not.ismissing(wgt),Tsum/wgt,Tavg@_FillValue)
   Savg(0,2,:,1)=where(.not.ismissing(wgt),Ssum/wgt,Savg@_FillValue)
   Qavg(0,2,:,1)=(/wgt/)
   
   ;----------------------------------------------------------------------------------------------------
   ;  negative
   sit=where(trans.le.0,1,sit@_FillValue)
   
   Tsum=dim_sum_n_Wrap(dim_sum_n_Wrap(VT*vit*sit,0),0)
   Ssum=dim_sum_n_Wrap(dim_sum_n_Wrap(VS*vit*sit,0),0)
   wgt =dim_sum_n_Wrap(dim_sum_n_Wrap(trans*vit*sit,0),0)
   Tsum = Tsum + VT_offset
   Ssum = Ssum + VS_offset
   wgt  = wgt + moc_000
   
   Tavg(0,2,:,2)=where(.not.ismissing(wgt),Tsum/wgt,Tavg@_FillValue)
   Savg(0,2,:,2)=where(.not.ismissing(wgt),Ssum/wgt,Savg@_FillValue)
   Qavg(0,2,:,2)=(/wgt/)
   
   ;====================================================================================================
   ;  Middle layer min
   vit=where(sig.gt.Smax .and. sig+eps.le.Smin,1,vit@_FillValue)
   
   ;----------------------------------------------------------------------------------------------------
   ;  absolute
   Tsum=dim_sum_n_Wrap(dim_sum_n_Wrap(VT_abs*vit,0),0)
   Ssum=dim_sum_n_Wrap(dim_sum_n_Wrap(VS_abs*vit,0),0)
   wgt =dim_sum_n_Wrap(dim_sum_n_Wrap(trans_abs*vit,0),0)
   
   Tavg(0,3,:,3)=where(.not.ismissing(wgt),Tsum/wgt,Tavg@_FillValue)
   Savg(0,3,:,3)=where(.not.ismissing(wgt),Ssum/wgt,Savg@_FillValue)
   Qavg(0,3,:,3)=(/wgt/)
   
   ;----------------------------------------------------------------------------------------------------
   ;  net
   Tsum=dim_sum_n_Wrap(dim_sum_n_Wrap(VT*vit,0),0)
   Ssum=dim_sum_n_Wrap(dim_sum_n_Wrap(VS*vit,0),0)
   wgt =dim_sum_n_Wrap(dim_sum_n_Wrap(trans*vit,0),0)
   
   Tavg(0,3,:,0)=where(.not.ismissing(wgt),Tsum/wgt,Tavg@_FillValue)
   Savg(0,3,:,0)=where(.not.ismissing(wgt),Ssum/wgt,Savg@_FillValue)
   Qavg(0,3,:,0)=(/wgt/)
   
   ;----------------------------------------------------------------------------------------------------
   ;  positive
   sit=where(trans.gt.0,1,sit@_FillValue)
   
   Tsum=dim_sum_n_Wrap(dim_sum_n_Wrap(VT*vit*sit,0),0)
   Ssum=dim_sum_n_Wrap(dim_sum_n_Wrap(VS*vit*sit,0),0)
   wgt =dim_sum_n_Wrap(dim_sum_n_Wrap(trans*vit*sit,0),0)
   
   Tavg(0,3,:,1)=where(.not.ismissing(wgt),Tsum/wgt,Tavg@_FillValue)
   Savg(0,3,:,1)=where(.not.ismissing(wgt),Ssum/wgt,Savg@_FillValue)
   Qavg(0,3,:,1)=(/wgt/)
   
   ;----------------------------------------------------------------------------------------------------
   ;  negative
   sit=where(trans.le.0,1,sit@_FillValue)
   
   Tsum=dim_sum_n_Wrap(dim_sum_n_Wrap(VT*vit*sit,0),0)
   Ssum=dim_sum_n_Wrap(dim_sum_n_Wrap(VS*vit*sit,0),0)
   wgt =dim_sum_n_Wrap(dim_sum_n_Wrap(trans*vit*sit,0),0)
   
   Tavg(0,3,:,2)=where(.not.ismissing(wgt),Tsum/wgt,Tavg@_FillValue)
   Savg(0,3,:,2)=where(.not.ismissing(wgt),Ssum/wgt,Savg@_FillValue)
   Qavg(0,3,:,2)=(/wgt/)
   
   ;====================================================================================================
   ;  Lower layer min
   vit=where(sig.gt.Smin,1,vit@_FillValue)
if (all(ismissing(vit)))then
   continue   
   ;----------------------------------------------------------------------------------------------------
   ;  absolute
   Tsum=dim_sum_n_Wrap(dim_sum_n_Wrap(VT_abs*vit,0),0)
   Ssum=dim_sum_n_Wrap(dim_sum_n_Wrap(VS_abs*vit,0),0)
   wgt =dim_sum_n_Wrap(dim_sum_n_Wrap(trans_abs*vit,0),0)
   
   Tavg(0,4,:,3)=where(.not.ismissing(wgt),Tsum/wgt,Tavg@_FillValue)
   Savg(0,4,:,3)=where(.not.ismissing(wgt),Ssum/wgt,Savg@_FillValue)
   Qavg(0,4,:,3)=(/wgt/)
   
   ;----------------------------------------------------------------------------------------------------
   ;  net
   Tsum=dim_sum_n_Wrap(dim_sum_n_Wrap(VT*vit,0),0)
   Ssum=dim_sum_n_Wrap(dim_sum_n_Wrap(VS*vit,0),0)
   wgt =dim_sum_n_Wrap(dim_sum_n_Wrap(trans*vit,0),0)
   
   Tavg(0,4,:,0)=where(.not.ismissing(wgt),Tsum/wgt,Tavg@_FillValue)
   Savg(0,4,:,0)=where(.not.ismissing(wgt),Ssum/wgt,Savg@_FillValue)
   Qavg(0,4,:,0)=(/wgt/)
   
   ;----------------------------------------------------------------------------------------------------
   ;  positive
   sit=where(trans.gt.0,1,sit@_FillValue)
   
   Tsum=dim_sum_n_Wrap(dim_sum_n_Wrap(VT*vit*sit,0),0)
   Ssum=dim_sum_n_Wrap(dim_sum_n_Wrap(VS*vit*sit,0),0)
   wgt =dim_sum_n_Wrap(dim_sum_n_Wrap(trans*vit*sit,0),0)
   
   Tavg(0,4,:,1)=where(.not.ismissing(wgt),Tsum/wgt,Tavg@_FillValue)
   Savg(0,4,:,1)=where(.not.ismissing(wgt),Ssum/wgt,Savg@_FillValue)
   Qavg(0,4,:,1)=(/wgt/)
   
   ;----------------------------------------------------------------------------------------------------
   ;  negative
   sit=where(trans.le.0,1,sit@_FillValue)
   
   Tsum=dim_sum_n_Wrap(dim_sum_n_Wrap(VT*vit*sit,0),0)
   Ssum=dim_sum_n_Wrap(dim_sum_n_Wrap(VS*vit*sit,0),0)
   wgt =dim_sum_n_Wrap(dim_sum_n_Wrap(trans*vit*sit,0),0)
   Tavg(0,4,:,2)=where(.not.ismissing(wgt),Tsum/wgt,Tavg@_FillValue)
   Savg(0,4,:,2)=where(.not.ismissing(wgt),Ssum/wgt,Savg@_FillValue)
   Qavg(0,4,:,2)=(/wgt/)
end if      
   ;====================================================================================================
   tmp=Tavg
   tmp!0="time"
   tmp!1="lev"
   tmp!2="lat"
   tmp!3="lon"
   tmp&time=0.
   tmp&time@long_name="time"
   tmp&time@units    ="days since 1850-01-01 00:00"
   tmp&lev=(/0.,1.,2.,3.,4./)
   tmp&lev@long_name="lev"
   tmp&lev@units    ="m"
   tmp&lon=(/0.,1.,2.,3./)
   tmp&lon@long_name="longitude"
   tmp&lon@units    ="degrees_east"
   tmp&lat  =lat  
   
   copy_VarMeta(tmp,Tavg)
   copy_VarMeta(tmp,Savg)
   copy_VarMeta(tmp,Qavg)
   
   Tavg@long_name="Temperature"
   Savg@long_name="Salinity"
   Qavg@long_name="Transport"
   Tavg@units    ="Deg C"
   Savg@units    ="psu"
   Qavg@units    ="Sv"
   
   tmp&time@long_name="time"
   tmp&time@units    ="days since 1850-01-01 00:00"
   
   system("rm -f "+DIR_out+model+"."+thetao_var+"_wgt_"+yyyy+".yr.nc")
   fout  = addfile(DIR_out+model+"."+thetao_var+"_wgt_"+yyyy+".yr.nc","c")
   fout->$thetao_var$ = Tavg
   
   system("rm -f "+DIR_out+model+"."+so_var+"_wgt_"+yyyy+".yr.nc")
   fout  = addfile(DIR_out+model+"."+so_var+"_wgt_"+yyyy+".yr.nc","c")
   fout->$so_var$ = Savg
   
   system("rm -f "+DIR_out+model+".trans_avg_"+yyyy+".yr.nc")
   fout  = addfile(DIR_out+model+".trans_avg_"+yyyy+".yr.nc","c")
   fout->trans = Qavg

   delete(Tavg)
   delete(Savg)
   delete(Qavg)
   delete(Smax)
   delete(S000)
   delete(Smin)
   delete(vit)
   delete(sit)
   
end do   
