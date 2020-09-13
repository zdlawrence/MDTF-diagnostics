# ======================================================================
# recover_vmo_by_vo.py
#
#   Calculate volume transport from velocity
#    as part of functionality provided by (AMOC_3D_Structure.py)
#
#   Version 1 revision 2 8-Jan-2017 Fuchang Wang (FSU/COAPS)
#   Contributors: 
#   PI: Xiaobiao Xu (FSU/COAPS)
#
#   Equation:
#    Volume Transport = velocity * x-interval * z-interval
#    V = v * dx * dz
#  
#   Generates plots of:
#    (1) surface volume transport (vmo_xy_plot.ncl) 
#   
#   Depends on the following scripts:
#    (1) recover_vmo_by_vo.ncl
#    (2) get_dxdydz_LatLon.py
#    
#   The following 3 model variables are required:
#     (1) meridional volume transport or mass transport (vmo, units: m^3/s or kg/s)
#          if (1) not provided in model output, this package will automatically 
#          calculate (1) using (2)
#     (2) x-interval and z-interval (dx,dz, units: m) (get_dxdydz_LatLon.py)
#     (3) meridional velocity (vo, units: m/s)
#
# Defaults for selecting years, etc. that can be altered by user are in:
#  mdtf.py
#
# OPEN SOURCE COPYRIGHT Agreement TBA
# ======================================================================

def recover_vmo_by_vo(model,DIR_in,DIR_out):
    '''
    ----------------------------------------------------------------------
    Note
       Volume Transport
    ----------------------------------------------------------------------
    '''
    import os
    import glob
    import shutil 
    import subprocess
    from post_process import execute_ncl_calculate
#    print model,DIR_in,DIR_out
    ncs = glob.glob(os.environ["MONDIR"]+model+"."+os.environ["vmo_var"]+".mon*.nc")
    num_vmo_files=len(ncs)
    if num_vmo_files > 0:
        script=os.environ["SRCDIR"]+"split_vmo_into_yearly.ncl"
        ncs = glob.glob(os.environ["MONDIR"]+model+"."+os.environ["vmo_var"]+".mon*.nc")
    else:              
        script=os.environ["SRCDIR"]+"recover_vmo_by_vo.ncl"
        ncs = glob.glob(os.environ["MONDIR"]+model+"."+os.environ["vo_var"]+".mon*.nc")

    ncs.sort()
    for nc in ncs:
        print("COMPUTING Volume Transport ...")
        execute_ncl_calculate(script)
