#   Version 1 revision 3 8-Jan-2017 Fuchang Wang (FSU/COAPS)
#   Contributors: 
#   PI: Xiaobiao Xu (FSU/COAPS)
#
#   Currently consists of following functionalities:
#    (1) Create surface/3D mask field (create_BASIN_INDEX.py)
#    (2) Extract model's latitudes (lat_extract.py)
#    (3) Calculate models' x-intervals y-intervals and z-intervals (get_dxdydz_LatLon.py)
#    (4) Ploting latitudinal MHT and MFWT (MHT_MFWT_lats_y_plot.py)
#
#   All scripts of this package can be found under
#    /var_code/basin_lat_dxdydz
#    & data under /obs_data/basin_lat_dxdydz
#
#   The following Python packages are required:
#    os,glob,shutil,subprocess

#   Use Anaconda:
#    These Python packages are already included in the standard installation
#
#   The following 2 4-D (lat-lon-lev-time) model fields are required:
#     (1) meridional velocity, units: m/s)
#     (2) salinity (so, units: psu, g/kg, kg/kg)
#
#   Reference: 
#    Xu X., P. B. Rhines, and E. P. Chassignet (2016): Temperature-Salinity Structure of the North Atlantic Circulation and Associated Heat and Freshwater Transports. J. Cli., 29, 7723-7742, doi: 10.1175/JCLI-D-15-0798.1
#
# OPEN SOURCE COPYRIGHT Agreement TBA
# ======================================================================
# Import standard Python packages
import os
import glob

from create_BASIN_INDEX import create_BASIN
from create_BASIN_INDEX import create_INDEX
from lat_extract        import lat_extract  
from get_dxdydz_LatLon  import get_dxdydz_LatLon

#============================================================
#  file exists?
#============================================================   
model=os.environ["CASENAME"]
DIR_in=os.environ["MONDIR"]
DIR_out=os.environ["OUTDIR"]

if len(glob.glob(os.environ["OUTDIR"]+model+".*.fx.nc"))==8:
   print("BASIN INDEX lat dxdydz exists. Skip package basin_lat_dxdydz.py")
   exit()
else:
   print("Creating BASIN INDEX lat dxdydz ...")


vo_nc = os.environ["MONDIR"]+os.environ["CASENAME"]+"."+os.environ["vo_var"]+".mon.nc"
so_nc = os.environ["MONDIR"]+os.environ["CASENAME"]+"."+os.environ["so_var"]+".mon.nc"
missing_file=0
if not os.path.isfile(vo_nc):
    print("Required Velocity data missing!")
    print(vo_nc)
    missing_file=1
if not os.path.isfile(so_nc):
    print("Required Salinity data missing!")
    print(so_nc)
    missing_file=1

if missing_file==1:
    print("basin_lat_dxdydz will NOT be executed!")
#============================================================
# Call NCL code here
#============================================================
fname="vo"
create_BASIN(model,DIR_out,fname)
create_INDEX(model,DIR_out,fname)
lat_extract(model,fname)
get_dxdydz_LatLon(model,fname)

fname="so"
create_BASIN(model,DIR_out,fname)
create_INDEX(model,DIR_out,fname)
lat_extract(model,fname)
get_dxdydz_LatLon(model,fname)

print("**************************************************")
print("basin_lat_dxdydz Package (basin_lat_dxdydz.py) Executed!")
print("**************************************************")
