# ======================================================================
# yearly_to_climate.py
#
#   Calculate long-term mean from yearly data
#    as part of functionality provided by (AMOC_3D_Structure.py)
#
#   Version 1 revision 2 8-Jan-2017 Fuchang Wang (FSU/COAPS)
#   Contributors: 
#   PI: Xiaobiao Xu (FSU/COAPS)
#
#   Equation:
#    average = sum[var] / time
#     ignore   missing grid: time = total_times, ie. number of years
#     consider missing grid: time = occur times, ie. <= total_times
#     user spesify os.environ["which_mean"] to which one
#  
#   Used for variables:
#    (1) Volume Transport (vmo)
#    (2) Temperature (thetao)
#    (3) Salinity (so)
#    (4) Transport(Temperature, Salinity) (trans)
#    (5) Stream Function on Density (moc)
#    (6) Stream Function on Temperature (moc)
#    (7) Stream Function on Salinity (moc)
#    (8) Layered Transport (trans)
#    (9) Transport weighted Temperature (thetao)
#    (10) Transport weighted Salinity (thetao)
#    (11) Meridional Heat Transport (MHT)
#    (12) Meridional Freshwater Transport (MFWT)
#   
#   Depends on the following scripts:
#    (1) monthly_to_yearly.ncl
#    
# OPEN SOURCE COPYRIGHT Agreement TBA
# ======================================================================
#!/usr/bin/python

def yearly_to_climate(model,DIR_in,DIR_out,fname,vname):
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
    script=os.environ["SRCDIR"]+"yearly_to_climate.ncl"
    ncs = glob.glob(os.environ["TMPDIR"]+model+"."+fname+"_????-????.yr.nc")
    ncs.sort()
    num_vmo_files=len(ncs)
    if num_vmo_files > 0:
        os.environ["STR0"] = fname
        os.environ["VAR0"] = vname
        print("COMPUTING Yearly to Climate ... "+vname)
        execute_ncl_calculate(script)
