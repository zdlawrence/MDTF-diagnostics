load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"

DIR_in0 = getenv("MONDIR")
DIR_in1 = getenv("OUTDIR")
DIR_out = getenv("OUTDIR")

so_var = getenv("so_var")
bas_var = getenv("bas_var")
lat_var = getenv("lat_coord")
lon_var = getenv("lon_coord")

model=getenv("CASENAME")
yymm=getenv("YYYYMM")
yyyy=getenv("YYYY")

ncs0 = model+"."+so_var+".mon.nc"
ncs1 = model+".BASIN_so.fx.nc"

setfileoption("nc","Format","LargeFile")

fin0 = addfile(DIR_in0+ncs0,"r")
fin1 = addfile(DIR_in1+ncs1,"r")

lat = fin0->$lat_var$
num_lat=dimsizes(dimsizes(lat))

if(num_lat.eq.2)then
   bas = fin1->$bas_var$
   lon = fin1->$lon_var$
   num_lat=dimsizes(lat(:,0))

   nn=num_lat/2
;---------------------------- select 30w as reference latitude ---------------------------
   dlon = where(lon.lt.360,lon+360,lon)
   dlon = mod(dlon,360) ; then 0<=dlon<360.
   ilon = minind(abs(dlon(nn,:)-330.))
   rrr = lat(:,ilon)
;------------------- select Averaged Atlantice Basin reference latitude -------------------
   tmp = lat 
   tmp@_FillValue = 1e20
   tmp = where(bas.eq.2 .or. bas.eq.5, lat, tmp@_FillValue)
;------------------------------------------------------------------------------------------
   nn=num_lat/2
   if(rrr(nn).gt.rrr(nn+1))then
      isNorth2South=True
      rrr=(/rrr(::-1)/)
   else
      isNorth2South=False
   end if

;-------------------------- 90S~EQ --------------------------
;--- locate minind and northernmost reversed grid, js and jn
;--- step = [lat(jn) - lat(js)] / (jn-js)
;--- 90S~js, interval= min(step, [lat(js)+90 ] / js)
;--- then 90S~EQ should be Monotonic
;--- same method can be applied to EQ~90N
;--- if jn<=js means no inMonotonic occur whthin js~EQ, then
;--- 90S~js should be handeled seprately.
;-------------------------------------------------------------
   rrr@_FillValue=-1e6
   flag=rrr(0:nn-1)
   flag=rrr(1:nn) - rrr(0:nn-1)
   j=nn-1
   do while(j.ge.0)
      if(ismissing(flag(j)))then
        j=j-1
        continue
      end if
      if(flag(j).le.0)then
        break
      end if
      j=j-1
   end do
   jn=j+2

   js=minind(rrr)
   if(js.eq.0 .and.jn.eq.1)then
      continue
   else if(jn.gt.js)then
      step = abs(rrr(js)-rrr(jn))/(jn-js)
      do j=js,jn
         rrr(j)=rrr(jn)-step*(jn-j)
      end do
      step=min((/step, (90.-abs(rrr(js)))/js/))
      do j=0,js
         rrr(j)=rrr(js)-step*(js-j)
      end do
   else
      step = abs(rrr(js)-rrr(js+1))
      step=min((/step, (90.-abs(rrr(js)))/js/))
      do j=0,js
         rrr(j)=rrr(js)-step*(js-j)
      end do
   end if
   end if
   delete(flag)
  
;----------------------- EQ~90N -----------------------
;--- locate maxind and southernmost reversed grid, jn and js
;--- step = [lat(jn) - lat(js)] / (jn-js)
;--- 90S~js, interval= min(step, [lat(js)+90 ] / js)
;--- if jn<=js means no inMonotonic occur whthin EQ~jn, then
;--- jn~90N should be handeled seprately.
;--- then EQ~90N should be Monotonic

   flag=rrr(nn:num_lat-2)
   flag=rrr(nn+1:num_lat-1) - rrr(nn:num_lat-2)
   do j=0,num_lat-2-nn
      if(ismissing(flag(j)))then
        continue
      end if
      if(flag(j).le.0)then
        break
      end if
   end do
   js=j-2+nn

   jn=maxind(rrr)
   if(jn.eq.num_lat-1 .and. js.eq.num_lat-3)then
      continue
   else if(jn.gt.js)then
      step = abs(rrr(js)-rrr(jn))/(jn-js)
      do j=js,jn
         rrr(j)=rrr(jn)-step*(jn-j)
      end do
      if(jn.lt.num_lat-1)then
         step=min((/step, (90.-abs(rrr(jn)))/(num_lat-1-jn)/))
         do j=jn,num_lat-1
            rrr(j)=rrr(jn)+step*(j-jn)
         end do
      end if
   else
      step = abs(rrr(jn)-rrr(jn-1))
      step=min((/step, (90.-abs(rrr(jn)))/jn/))
      do j=jn,num_lat-1
         rrr(j)=rrr(jn)+step*(j-jn)
      end do
   end if
  end if
   delete(flag)
   delete(rrr@_FillValue)

   if(isMonotonic(rrr).eq.0)then
     aaa = rrr(1:num_lat-1) - rrr(0:num_lat-2)
     exit
   end if

   if(isNorth2South)then
     rrr=(/-rrr/)
   end if
end if   

if(num_lat.eq.1)then
   rrr=lat
end if

  system("rm "+DIR_out+model+"."+lat_var+"_so.fx.nc")
fout = addfile(DIR_out+model+"."+lat_var+"_so.fx.nc","c")
;=============================================================================
fout->$lat_var$ = rrr
