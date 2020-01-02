# ======================================================================
# lat_extract.py
#
#   Extract model's latitudes
#    as part of functionality provided by (basin_lat_dxdydz.py)
#
#   Version 1 revision 2 8-Jan-2017 Fuchang Wang (FSU/COAPS)
#   Contributors: 
#   PI: Xiaobiao Xu (FSU/COAPS)
#
#   Methos:
#    Extract latitudes within Atlantic domain
#     For Lat/Lon grid, it's provided;
#     For curvlinear grids, it's the i-direction mean latitudes
#      within Atlantic domain.
#  
#   Generates plots of:
#    (1) model's latitude (lat_plot.ncl)
#   
#   Depends on the following scripts:
#    (1) create_BASIN_INDEX.py
#
#   The following 3 variables are required:
#     (1) 2D basin mask of model (ind, units: "1", create_BASIN_INDEX.py)
#     (2) 4D velocity (vo, units: m/s, models outputs)
#     (3) 4D salinity (so, units: psu or g/kg or kg/kg, models outputs)
#    
# OPEN SOURCE COPYRIGHT Agreement TBA
# ======================================================================

#============================================================
# get_Atlantic_lat
#============================================================
def lat_extract(model,fname):
    '''
    ----------------------------------------------------------------------
    Note
        extract averaged latitudes along Atlantic basin
    ----------------------------------------------------------------------
    '''
    import os
    import shutil
    from post_process import execute_ncl_calculate
#    print nc
    script=os.environ["SRCDIR"]+"lat_extract_"+fname+".ncl"
    ncl=os.environ["SRCDIR"]+"lat_extract_"+fname+"_"+model+".ncl"
    shutil.copy(script,ncl)
    print("Extracting Atlantic Latitude ...")
    execute_ncl_calculate(ncl)
    os.system("rm -f "+ncl)
