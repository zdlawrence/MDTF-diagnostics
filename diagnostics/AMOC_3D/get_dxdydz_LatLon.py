#!/usr/bin/python
# ======================================================================
# get_dxdydz_LatLon.py
#
#   Calculate x/y/z intervals of each model
#    as part of functionality provided by (basin_lat_dxdydz.py)
#
#   Version 1 revision 2 8-Jan-2017 Fuchang Wang (FSU/COAPS)
#   Contributors: 
#   PI: Xiaobiao Xu (FSU/COAPS)
#
#   Method:
#    Using gc_latlon function in NCL to calculate adjacent grids' great circle distance
#  
#   Generates plots of:
#    (1) x-direction intervals (dx_xy_plot.ncl)
#    (2) y-direction intervals (dy_xy_plot.ncl)
#    (3) z-direction intervals (dz_xy_plot.ncl)
#   
#   The following 3 model's outputs are required:
#     (1) 3D/4D thickness of layers (thkcello, units: m)
#     (2) 3D bathymetry (depth, units: m)
#     (3) 4D velocity (vo, units: m/s)
#    
# OPEN SOURCE COPYRIGHT Agreement TBA
# ======================================================================

#============================================================
# get_Atlantic_lat
#============================================================
def get_dxdydz_LatLon(model,fname):
    '''
    ----------------------------------------------------------------------
    Note
        extract averaged latitudes along Atlantic basin
    ----------------------------------------------------------------------
    '''
    import os
    import glob
    import shutil 
    import subprocess
    from post_process import execute_ncl_calculate
    print("Processing get_dxdydz_LatLon ...")
    dz4d=""
    num0=len(glob.glob(os.environ["MONDIR"]+model+"."+os.environ["thkcello_var"]+".mon.nc"))
    if num0== 1:
       dz4d="True"
    num1=len(glob.glob(os.environ["FIXDIR"]+model+"."+os.environ["thkcello_var"]+".fx.nc"))
    if num1== 1:
       dz4d="False"

    nc=os.environ["FIXDIR"]+model+"."+os.environ["deptho_var"]+".fx.nc"
    os.environ["DEPTHO"]=os.path.basename(nc)

    script=os.environ["SRCDIR"]+"get_dxdydz_LatLon.ncl"
    sname=os.path.splitext(os.path.basename(script))[0]
    ncl=os.environ["SRCDIR"]+sname+"_"+model+"_"+fname+".ncl"
    shutil.copy(script,ncl)

    os.environ["DIR_IN3"] = os.environ["FIXDIR"]
    os.environ["THKCELLO"]= model+".thkcello.fx.nc"
    if dz4d == "True":
       nc=os.environ["MONDIR"]+model+"."+os.environ["thkcello_var"]+".mon.nc"
       os.environ["THKCELLO"]=os.path.basename(nc)
       os.environ["DIR_IN3"] = os.environ["MONDIR"]
       fix="True"
    elif dz4d == "False":
       nc=os.environ["FIXDIR"]+model+"."+os.environ["thkcello_var"]+".fx.nc"
       os.environ["THKCELLO"]=os.path.basename(nc)
       fix="True"
    else:
       fix="False"

    os.environ["VAR0"] = fname
        
    print("COMPUTING Grid Size ...")
    execute_ncl_calculate(ncl)
    os.system("rm -f "+ncl)

#    if (fix == "True" and fname != "vo"):
#       script2=os.environ["SRCDIR"]+"interp_vit_to_viv_dxdydz.ncl"
#       sname=os.path.splitext(os.path.basename(script2))[0]
#       ncl=os.environ["SRCDIR"]+sname+"_"+model+"_"+fname+".ncl"
#       shutil.copy(script2,ncl)
#       print("Interpolating T-grid to V-grid ...")
#       execute_ncl_calculate(ncl)
#       os.system("rm -f "+ncl)
