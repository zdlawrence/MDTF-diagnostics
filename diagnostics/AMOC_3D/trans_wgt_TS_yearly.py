# ======================================================================
# trans_wgt_TS_yearly.py
#
#   Calculate Volume Transport weighted Temperature and Salinity
#    as part of functionality provided by (AMOC_3D_Structure.py)
#
#   Version 1 revision 2 8-Jan-2017 Fuchang Wang (FSU/COAPS)
#   Contributors: 
#   PI: Xiaobiao Xu (FSU/COAPS)
#
#   Equation:
#    The mean Temperature/Salinity (T/s) wighted by volume transport (V) within layers
#     bounded by certain densities (r)
#    At specific time and latitude:
#     Q(T,S) + r(T,S) --> Q(r)
#            upper_r                     upper_r
#    Twgt = S       Q(T,S) * T * dr  /  S       Q(T,S) * dr  
#            lower_r                     lower_r
#    Similarly for Swgt 
#  
#   Generates plots of:
#    (1) Qave, (Q1_Q2South_Q3North_lats.ncl)
#    (2) Twgt, (T1North_T2South_T3North_lats.ncl)
#    (3) Swgt, (S1North_S2South_S3North_lats.ncl)
#   
#   The following 3 variables are required:
#     (1) 2D Density r(T,S) (sig2, units: "kg/m^3", TMP.sigma2.fx.ncl)
#     (2) 3D Stream Function on Density (moc, units: Sv = 1e6 m^3/s or 1e9 kg/s, AMOC_qts_from_yearly.py)
#     (3) 4D Volume Transport onto T/S (trans, m^3/s, trans_lats_monthly.py + monthly_to_yearly.py)
#    
# OPEN SOURCE COPYRIGHT Agreement TBA
# ======================================================================

def trans_wgt_TS_yearly(model):
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
    script=os.environ["SRCDIR"]+"trans_wgt_TS_yearly.ncl"
    sname=os.path.splitext(os.path.basename(script))[0]
    ncs = glob.glob(os.environ["TMPDIR"]+model+".trans_????-????.yr.nc")
    num_vmo_files=len(ncs)
    if num_vmo_files > 0:
        for nc in ncs:
    #          print nc
            npos = nc.index('.yr.nc')
            yyyymm = nc[npos-9:npos]
            yyyy0 = yyyymm[0:4]
            yyyy1 = yyyymm[5:9]
            print yyyymm, yyyy0, yyyy1

            ncl=os.environ["SRCDIR"]+sname+"_"+model+"_"+yyyymm+".ncl"
            shutil.copy(script,ncl)
            os.environ["YYYYMM"] = yyyymm
            os.environ["YEAR0"] = yyyy0
            print("COMPUTING Yearly Mean from Monthly ... "+model)
            execute_ncl_calculate(ncl)
            os.system("rm -f "+ncl)
