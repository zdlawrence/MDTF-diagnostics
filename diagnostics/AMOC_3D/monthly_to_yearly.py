# ======================================================================
# monthly_to_yearly.py
#
#   Calculate yearly mean from monthly data
#    as part of functionality provided by (AMOC_3D_Structure.py)
#
#   Version 1 revision 2 8-Jan-2017 Fuchang Wang (FSU/COAPS)
#   Contributors: 
#   PI: Xiaobiao Xu (FSU/COAPS)
#
#   Equation:
#    average = sum[var(Jan:Dec)] / time
#     ignore   missing grid: time = total_times, ie. 12
#     consider missing grid: time = occur times, ie. <= 12
#     user spesify os.environ["which_mean"] to which one
#  
#   Used for variables:
#    (1) Volume Transport (vmo)
#    (2) Temperature (thetao)
#    (3) Salinity (so)
#    (4) Transport(Temperature, Salinity) (trans)
#   
#   Depends on the following scripts:
#    (1) monthly_to_yearly.ncl
#    
# OPEN SOURCE COPYRIGHT Agreement TBA
# ======================================================================

def monthly_to_yearly(model,DIR_in,DIR_out,fname,vname):
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
    script=os.environ["SRCDIR"]+"monthly_to_yearly.ncl"
    sname=os.path.splitext(os.path.basename(script))[0]
    ncs = glob.glob(os.environ["TMPDIR"]+model+"."+fname+"_??????-??????.mon*.nc")
    num_vmo_files=len(ncs)
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
            os.environ["YYYY"] = yyyy0+"-"+yyyy1
            os.environ["VAR0"] = vname
            os.environ["STR0"] = fname
            print("COMPUTING Yearly Mean from Monthly ... "+vname)
            execute_ncl_calculate(ncl)
            os.system("rm -f "+ncl)
