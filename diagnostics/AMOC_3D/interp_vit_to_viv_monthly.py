# ======================================================================
# interp_vit_to_viv_monthly.py
#
#   Interpolate Tracer grid onto Velocity grid
#    as part of functionality provided by (AMOC_3D_Structure.py)
#
#   Version 1 revision 2 8-Jan-2017 Fuchang Wang (FSU/COAPS)
#   Contributors: 
#   PI: Xiaobiao Xu (FSU/COAPS)
#
#   Equation:
#    Where is sea in V-grid but land in T-grid, set as average of nearby valid values
#
#   Generates input for:
#    (1) Transport(Temperature,Salinity) (trans_lats_monthly.py)
#         inconsistence occurs at cosatal areas between T-grid and V-grid, 
#         here volume transport cannot be ingnored, need handle carefully.
#  
#   Depends on the following scripts:
#    (1) create_BASIN_INDEX.py
#    (2) recover_vmo_by_vo.py
#
#   The following 5 variables are required:
#     (1) 3D T-grid mask (ind, units: "1", create_BASIN_INDEX.py)
#     (2) 3D V-grid mask (ind, units: "1", create_BASIN_INDEX.py)
#     (3) 4D Temperature (thetao, units: K or degC, model standard output)
#     (4) 4D Salinity    (so, units: psu or g/kg or g/g, model standard output)
#     (5) 4D Volume Transport (vmo, m^3/s or kg/s, model standard output or recover_vmo_by_vo.py)
#    
# OPEN SOURCE COPYRIGHT Agreement TBA
# ======================================================================

def interp_vit_to_viv_monthly(model,DIR_in,DIR_out):
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
    script=os.environ["SRCDIR"]+"interp_vit_to_viv_monthly.ncl"
    sname=os.path.splitext(os.path.basename(script))[0]
    ncs = glob.glob(os.environ["TMPDIR"]+model+"."+os.environ["vmo_var"]+"_??????-??????.mon*.nc")
    num_vmo_files=len(ncs)
    if num_vmo_files > 0:
       for nc in ncs:
          print "nc: "+nc
          npos = nc.index('.mon')
          yyyymm = nc[npos-13:npos]
          yyyy0 = yyyymm[0:4]
          yyyy1 = yyyymm[7:11]
          print yyyymm, yyyy0, yyyy1          

          ncl=os.environ["SRCDIR"]+sname+"_"+model+".ncl"
          shutil.copy(script,ncl)
          os.environ["YYYY"] = yyyy0
          os.environ["YYYYMM"] = yyyymm
          print("COMPUTING interpolation from T-grid to V-grid")
          execute_ncl_calculate(ncl)
          os.system("rm -f "+ncl)
