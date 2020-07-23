# ======================================================================
# monthly_to_yearly.py
#
#   Project volume transport onto Temperature and Salinity plane Q(T,S)
#    as part of functionality provided by (AMOC_3D_Structure.py)
#
#   Version 1 revision 2 8-Jan-2017 Fuchang Wang (FSU/COAPS)
#   Contributors: 
#   PI: Xiaobiao Xu (FSU/COAPS)
#
#   Equation:
#    double integral of volume transport(V, vmo) along Temperature(T, thetao) and Salinity(s, so) intervals 
#     at specific time and latitude:
#               T+dT/2  s+ds/2
#     Q(T,S) = S       S      V(x,z) * dT * dS
#               T-dT/2  s-ds/2
#     Note: T(x,z),s(x,z), S is symbol for integral 
#  
#   Depends on the following scripts:
#    (1) recover_vmo_by_vo.py
#    (2) interp_vit_to_viv_monthly.py
#    (2) lat_extract.py
#    (2) create_BASIN_INDEX.py
#
#   The following 5 variables are required:
#     (1) 3D T-grid mask (ind, units: "1", create_BASIN_INDEX.py)
#     (2) 1D y axis latitude( lat, units: "degrees_north", lat_extract.py)
#     (3) 4D V-grid Temperature (thetao, units: K or degC, interp_vit_to_viv_monthly.py)
#     (4) 4D V-grid Salinity    (so, units: psu or g/kg or g/g, interp_vit_to_viv_monthly.py)
#     (5) 4D Volume Transport (vmo, m^3/s or kg/s, model standard output or recover_vmo_by_vo.py)
#    
# OPEN SOURCE COPYRIGHT Agreement TBA
# ======================================================================

def trans_lats_monthly(model,DIR_in,DIR_out):
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
    ncs = glob.glob(os.environ["TMPDIR"]+model+"."+os.environ["vmo_var"]+"_??????-??????.mon*.nc")
    num_vmo_files=len(ncs)
    script=os.environ["SRCDIR"]+"trans_lats_monthly.ncl"
    sname=os.path.splitext(os.path.basename(script))[0]
    if num_vmo_files > 0:
        for nc in ncs:
    #          print nc
            npos = nc.index('.mon.nc')
            yyyymm = nc[npos-13:npos]
            yyyy0 = yyyymm[0:4]
            yyyy1 = yyyymm[7:11]
            print yyyymm, yyyy0, yyyy1

            ncl=os.environ["SRCDIR"]+sname+"_"+model+"_"+yyyymm+".ncl"
            shutil.copy(script,ncl)
            os.environ["YYYYMM"] = yyyymm
            os.environ["YEAR0"] = yyyy0
            print("Projecting vmo onto T/S plane ...")
            execute_ncl_calculate(ncl)
            os.system("rm -f "+ncl)
