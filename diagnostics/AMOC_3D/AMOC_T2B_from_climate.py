# ======================================================================
# AMOC_T2B_from_climate.py
#
#   Calculate Stream Function on Depth
#    as part of functionality provided by (AMOC_3D_Structure.py)
#
#   Version 1 revision 2 8-Jan-2017 Fuchang Wang (FSU/COAPS)
#   Contributors: 
#   PI: Xiaobiao Xu (FSU/COAPS)
#
#   Equation:
#    Stream Function = definite integral of volume transport along x-direction
#               then indefinite integral along z-direction
#                  z  xb
#     Psai(y,z) = S  S  vmo(x,y,z) * dx * dz 
#                  0  xa 
#  
#   Generates plots of:
#    (1) stream function of each model (AMOCz_yz_plot.ncl)
#   
#   Depends on the following scripts:
#    (1) recover_vmo_by_vo.py
#    (2) create_BASIN_INDEX.py
#    (3) lat_extract.py
#
#    
# OPEN SOURCE COPYRIGHT Agreement TBA
# ======================================================================

def AMOC_T2B_from_climate(model,DIR_in,DIR_out):
    '''
    ----------------------------------------------------------------------
    Note
       Volume Transport
    ----------------------------------------------------------------------
    '''
    import os
    import shutil
    from post_process import execute_ncl_calculate
    script=os.environ["SRCDIR"]+"AMOC_T2B_from_climate.ncl"
    sname=os.path.splitext(os.path.basename(script))[0]
    nc = os.environ["OUTDIR"]+model+"."+os.environ["vmo_var"]+".clim.nc"
    if os.path.isfile(nc):
        ncl=os.environ["SRCDIR"]+sname+"_"+model+".ncl"
        shutil.copy(script,ncl)
        print("COMPUTING AMOCz")
        execute_ncl_calculate(ncl)
        os.system("rm -f "+ncl)
