# ======================================================================
# MHT_MFWT_qts_from_yearly.py
#
#   Calculate Meridional Heat Transport and Freshwater Transport
#    as part of functionality provided by (AMOC_3D_Structure.py)
#
#   Version 1 revision 2 8-Jan-2017 Fuchang Wang (FSU/COAPS)
#   Contributors: 
#   PI: Xiaobiao Xu (FSU/COAPS)
#
#   Equation:
#    MHT: Intergral of Transport Q(T,S) * Temperature (T) * Density (rho0) * specific heat capacity (Cp)
#     within layers bounded by certain densities (r)
#    At specific time and latitude:
#     Q(T,S) + r(T,S) --> Q(r)
#            upper_r
#    MHT = S       Q(T,S) * T * Rho0 * Cp * dr, Rho0 * Cp ~ 0.0041
#            lower_r
#            upper_r
#    MFWT= S       Q(T,S) * S / S0 * dr, S0 ~ 34.9  
#            lower_r
#  
#   Generates plots of:
#    (1) Meridional Heat Transport       ( MHT_lats_y_plot.ncl)
#    (2) Meridional Freshwater Transport (MFWT_lats_y_plot.ncl)
#   
#   The following 3 variables are required:
#     (1) 2D Density r(T,S) (sig2, units: "kg/m^3", TMP.sigma2.fx.ncl)
#     (2) 3D Stream Function on Density (moc, units: Sv = 1e6 m^3/s or 1e9 kg/s, AMOC_qts_from_yearly.py)
#     (3) 4D Volume Transport onto T/S (trans, m^3/s, trans_lats_monthly.py + monthly_to_yearly.py)
#    
# OPEN SOURCE COPYRIGHT Agreement TBA
# ======================================================================

def MHT_MFWT_qts_from_yearly(model,ncl_script):
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

            script=os.environ["SRCDIR"]+ncl_script
            sname=os.path.splitext(os.path.basename(script))[0]
            ncl=os.environ["SRCDIR"]+sname+"_"+model+"_"+yyyymm+".ncl"
            shutil.copy(script,ncl)
            os.environ["YYYY"] = yyyy0+"-"+yyyy1
            os.environ["YEAR0"] = yyyy0
            print("COMPUTING MHT & MFWT from QTS ... "+model)
            execute_ncl_calculate(ncl)
            os.system("rm -f "+ncl)
