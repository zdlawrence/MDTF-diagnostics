#!/usr/bin/python
# ======================================================================
# create_BASIN.py
#
#    Create Surface land/basin Mask
#    as part of functionality provided by (basin_lat_dxdydz.py)
#
#    Version 1 revision 2 8-Jan-2017 Fuchang Wang (FSU/COAPS)
#    Contributors: 
#    PI: Xiaobiao Xu (FSU/COAPS)
#
#    Method:
#    Predefined basin Mask with 0.1 degree resolution (LICOM) is used as reference
#     (1) Assign nearest LICOM geographical mask to model's (i,j)
#         if (i,j) is sea in model but land in LICOM, we use assign nearby basin index to this grid
#     (2) keep land/sea is land/sea in model  
#       Usually, variables's value over land is set missing; but in some models they are set to 0,
#       like velocity, makeing it hard to distinguish (i,j) is land or not. However, if it's sea,
#       it won't be 0 forever and won't be 0 within all column.
#       
#    Generates plots of:
#    (1) xy map of basin mask (basin_xy_plot.ncl)
#
#    The following 3 variables are required:
#     (1) 2D referenced basin mask (ind, units: "1", /obs_data/basin_lat_dxdydz/)
#     (2) 4D velocity (vo, units: m/s, models outputs)
#     (3) 4D salinity (so, units: psu or g/kg or kg/kg, models outputs)
#    
# OPEN SOURCE COPYRIGHT Agreement TBA
# ======================================================================
def create_BASIN(model,DIR_out,fname):
    '''
    ----------------------------------------------------------------------
    Note
        surface basin index
    ----------------------------------------------------------------------
    '''
    import os
    import shutil
    from post_process import execute_ncl_calculate
    script=os.environ["SRCDIR"]+"create_BASIN_step1.ncl"
    sname=os.path.splitext(os.path.basename(script))[0]
    ncl=os.environ["SRCDIR"]+sname+"_"+fname+".ncl"
    shutil.copy(script,ncl)
    os.environ["VAR0"] = fname

    print("Initializing Surface BASIN INDEX ...")
    execute_ncl_calculate(ncl)
    os.system("rm -f "+ncl)

    script=os.environ["SRCDIR"]+"create_BASIN_step3.ncl"
    sname=os.path.splitext(os.path.basename(script))[0]
    ncl=os.environ["SRCDIR"]+sname+"_"+fname+".ncl"
    shutil.copy(script,ncl)
    print("Finalizing Surface BASIN INDEX ...")
    execute_ncl_calculate(ncl)
    os.system("rm -f "+ncl)

    fp2=open(os.environ["OUTDIR"]+model+".BASIN_"+fname+"_step.txt","r")
    num=fp2.readline()[0:-1]
    fp2.close()
    os.rename(DIR_out+model+".BASIN_"+fname+"_step"+num+".nc", DIR_out+model+".BASIN_"+fname+".fx.nc")
    os.system("rm -f "+DIR_out+model+".BASIN_"+fname+"_step*.nc")
    os.system("rm -f "+DIR_out+model+".BASIN_"+fname+"_step.txt")

# ======================================================================
# create_INDEX.py
#
#    Create 3D land/basin Mask
#    as part of functionality provided by (basin_lat_dxdydz.py)
#
#    Version 1 revision 2 8-Jan-2017 Fuchang Wang (FSU/COAPS)
#    Contributors: 
#    PI: Xiaobiao Xu (FSU/COAPS)
#
#    Method:
#    Use calculated model's basin Mask as reference
#     (1) Assign all levels' mask same as surface
#     (2) Identify model's land grids and set them to missing value
#       For those whose variables over land is 0 instead of missing value, how to identify land?
#       same as create_BASIN.py does. If all time-span and all column are 0, then it is land.
#       
#    Depends on the following scripts:
#    (1) create_BASIN.py
#
#    The following 3 variables are required:
#     (1) 2D calculated basin mask (ind, units: "1", create_BASIN.py)
#     (2) 4D velocity (vo, units: m/s, models outputs)
#     (3) 4D salinity (so, units: psu or g/kg or kg/kg, models outputs)
#    
# OPEN SOURCE COPYRIGHT Agreement TBA
# ======================================================================
def create_INDEX(model,DIR_out,fname):
    '''
    ----------------------------------------------------------------------
    Note
        3D basin index
    ----------------------------------------------------------------------
    '''
    import os
    import shutil
    from post_process import execute_ncl_calculate
    script=os.environ["SRCDIR"]+"create_INDEX.ncl"
    sname=os.path.splitext(os.path.basename(script))[0]
    ncl=os.environ["SRCDIR"]+sname+"_"+fname+".ncl"
    shutil.copy(script,ncl)
    os.environ["VAR0"] = fname
    print("COMPUTING 3D BASIN INDEX ...")
    execute_ncl_calculate(ncl)
    os.system("rm -f    "+ncl)
