#!/usr/bin/python
def single_ncl_test(model):
    '''
    ----------------------------------------------------------------------
    Note
       Volume Transport
    ----------------------------------------------------------------------
    '''
    import os
    import shutil
    from post_process import execute_ncl_calculate

#====================================================================================================

    script=os.environ["SRCDIR"]+"AMOCS_S_plot.ncl"
    sname=os.path.splitext(os.path.basename(script))[0]
    ncl=os.environ["SRCDIR"]+sname+"_"+model+".ncl"
    shutil.copy(script,ncl)
    print("Ploting Stream Function on Salinity at 26.5 ... "+model)
    execute_ncl_calculate(ncl)
    os.system("rm -f "+ncl)

    script=os.environ["SRCDIR"]+"AMOCT_T_plot.ncl"
    sname=os.path.splitext(os.path.basename(script))[0]
    ncl=os.environ["SRCDIR"]+sname+"_"+model+".ncl"
    shutil.copy(script,ncl)
    print("Ploting Stream Function on Temperature at 26.5 ... "+model)
    execute_ncl_calculate(ncl)
    os.system("rm -f "+ncl)

    script=os.environ["SRCDIR"]+"AMOCr_r_plot.ncl"
    sname=os.path.splitext(os.path.basename(script))[0]
    ncl=os.environ["SRCDIR"]+sname+"_"+model+".ncl"
    shutil.copy(script,ncl)
    print("Ploting Stream Function on Density at 26.5 ... "+model)
    execute_ncl_calculate(ncl)
    os.system("rm -f "+ncl)

    script=os.environ["SRCDIR"]+"Qavg_lats_y_plot.ncl"
    sname=os.path.splitext(os.path.basename(script))[0]
    ncl=os.environ["SRCDIR"]+sname+"_"+model+".ncl"
    shutil.copy(script,ncl)
    print("Ploting Qavg along y ... " + model)
    execute_ncl_calculate(ncl)
    os.system("rm -f "+ncl)

    script=os.environ["SRCDIR"]+"Twgt_lats_y_plot.ncl"
    sname=os.path.splitext(os.path.basename(script))[0]
    ncl=os.environ["SRCDIR"]+sname+"_"+model+".ncl"
    shutil.copy(script,ncl)
    print("Ploting Twgt along y ... " + model)
    execute_ncl_calculate(ncl)
    os.system("rm -f "+ncl)

    script=os.environ["SRCDIR"]+"Swgt_lats_y_plot.ncl"
    sname=os.path.splitext(os.path.basename(script))[0]
    ncl=os.environ["SRCDIR"]+sname+"_"+model+".ncl"
    shutil.copy(script,ncl)
    print("Ploting Swgt along y ... " + model)
    execute_ncl_calculate(ncl)
    os.system("rm -f "+ncl)

    script=os.environ["SRCDIR"]+"AMOCz_yz_plot.ncl"
    sname=os.path.splitext(os.path.basename(script))[0]
    ncl=os.environ["SRCDIR"]+sname+"_"+model+".ncl"
    shutil.copy(script,ncl)
    print("PLOTING AMOCz ..." + model)
    execute_ncl_calculate(ncl)
    os.system("rm -f    "+ncl)

    script=os.environ["SRCDIR"]+"AMOCr_yr_plot.ncl"
    sname=os.path.splitext(os.path.basename(script))[0]
    ncl=os.environ["SRCDIR"]+sname+"_"+model+".ncl"
    shutil.copy(script,ncl)
    print("PLOTING AMOCz ... " + model)
    execute_ncl_calculate(ncl)
    os.system("rm -f    "+ncl)

    script=os.environ["SRCDIR"]+"AMOCT_yT_plot.ncl"
    sname=os.path.splitext(os.path.basename(script))[0]
    ncl=os.environ["SRCDIR"]+sname+"_"+model+".ncl"
    shutil.copy(script,ncl)
    print("PLOTING AMOCT ... " + model)
    execute_ncl_calculate(ncl)
    os.system("rm -f    "+ncl)

    script=os.environ["SRCDIR"]+"AMOCS_yS_plot.ncl"
    sname=os.path.splitext(os.path.basename(script))[0]
    ncl=os.environ["SRCDIR"]+sname+"_"+model+".ncl"
    shutil.copy(script,ncl)
    print("PLOTING AMOCS ... " + model)
    execute_ncl_calculate(ncl)
    os.system("rm -f    "+ncl)    

    script=os.environ["SRCDIR"]+"Q_lat0_z_plot.ncl"
    sname=os.path.splitext(os.path.basename(script))[0]
    ncl=os.environ["SRCDIR"]+sname+"_"+model+".ncl"
    shutil.copy(script,ncl)
    print("Ploting Q at "+os.environ["LAT0"]+" ... " + model)
    execute_ncl_calculate(ncl)
    os.system("rm -f "+ncl)

    script=os.environ["SRCDIR"]+"S_lat0_z_plot.ncl"
    sname=os.path.splitext(os.path.basename(script))[0]
    ncl=os.environ["SRCDIR"]+sname+"_"+model+".ncl"
    shutil.copy(script,ncl)
    print("Ploting S profile at "+os.environ["LAT0"]+" ... " + model)
    execute_ncl_calculate(ncl)
    os.system("rm -f "+ncl)

    script=os.environ["SRCDIR"]+"T_lat0_z_plot.ncl"
    sname=os.path.splitext(os.path.basename(script))[0]
    ncl=os.environ["SRCDIR"]+sname+"_"+model+".ncl"
    shutil.copy(script,ncl)
    print("Ploting T profile at "+os.environ["LAT0"]+" ... " + model)
    execute_ncl_calculate(ncl)
    os.system("rm -f "+ncl)

    script=os.environ["SRCDIR"]+"thetao_lat0_climate_xz_plot.ncl"
    sname=os.path.splitext(os.path.basename(script))[0]
    ncl=os.environ["SRCDIR"]+sname+"_"+model+".ncl"
    shutil.copy(script,ncl)
    print("Ploting T xz section at "+os.environ["LAT0"]+" ... " + model)
    execute_ncl_calculate(ncl)
    os.system("rm -f "+ncl)

    script=os.environ["SRCDIR"]+"so_lat0_climate_xz_plot.ncl"
    sname=os.path.splitext(os.path.basename(script))[0]
    ncl=os.environ["SRCDIR"]+sname+"_"+model+".ncl"
    shutil.copy(script,ncl)
    print("Ploting S xz section at "+os.environ["LAT0"]+" ... " + model)
    execute_ncl_calculate(ncl)
    os.system("rm -f "+ncl)

    script=os.environ["SRCDIR"]+"vmo_lat0_climate_xz_plot.ncl"
    sname=os.path.splitext(os.path.basename(script))[0]
    ncl=os.environ["SRCDIR"]+sname+"_"+model+".ncl"
    shutil.copy(script,ncl)
    print("Ploting Q xz section at "+os.environ["LAT0"]+" ... " + model)
    execute_ncl_calculate(ncl)
    os.system("rm -f "+ncl)

    script=os.environ["SRCDIR"]+"trans_lat0_climate_TS_plot.ncl"
    sname=os.path.splitext(os.path.basename(script))[0]
    ncl=os.environ["SRCDIR"]+sname+"_"+model+".ncl"
    shutil.copy(script,ncl)
    print("Ploting Q(T,S) at "+os.environ["LAT0"]+" ... " + model)
    execute_ncl_calculate(ncl)
    os.system("rm -f "+ncl)    

    script=os.environ["SRCDIR"]+"MHT_lats_y_plot.ncl"
    sname=os.path.splitext(os.path.basename(script))[0]
    ncl=os.environ["SRCDIR"]+sname+"_"+model+".ncl"
    shutil.copy(script,ncl)
    print("Ploting MHT along latitudes ... "+model)
    execute_ncl_calculate(ncl)
    os.system("rm -f "+ncl)

    script=os.environ["SRCDIR"]+"MFWT_lats_y_plot.ncl"
    sname=os.path.splitext(os.path.basename(script))[0]
    ncl=os.environ["SRCDIR"]+sname+"_"+model+".ncl"
    shutil.copy(script,ncl)
    print("Ploting MFWT along latitudes ... "+model)
    execute_ncl_calculate(ncl)
    os.system("rm -f "+ncl)
