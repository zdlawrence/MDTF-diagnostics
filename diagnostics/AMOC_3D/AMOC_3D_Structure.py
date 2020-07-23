#   Version 1 revision 3 8-Jan-2017 Fuchang Wang (FSU/COAPS)
#   Contributors: 
#   PI: Xiaobiao Xu (FSU/COAPS)
#
#   Currently consists of following functionalities:
#    (1) Calculate volume transport from velocity (recover_vmo_by_vo.py)
#    (2) Calculate yearly mean from monthly data (monthly_to_yearly.py)
#    (3) Calculate long-term mean from yearly data (yearly_to_climate.py)
#    (4) Calculate Stream Functionion on Depth coordinate (AMOC_T2B_from_climate.py)
#    (5) Interpolate Tracer grid to Velocity grid (interp_vit_to_viv_monthly.py)
#    (6) Project Transport (V) onto Temperature/Salinity (T/S)plane (trans_lats_monthly.py)
#    (7) Calculate Stream Functionion on Density coordinate (AMOC_qts_from_yearly.py)
#    (8) Transport weighted Temperature and Salinity (trans_wgt_TS_yearly.py)
#    (9) Meridional Heat Transport (MHT) and Freshwater Transport (MFWT) (MHT_MFWT_qts_from_yearly.py)
#    (10) Ploting results (AMOC_3D_Structure_plot.py)
#    (11) Ploting observation or high-resolution HYCOM results (obs_AMOC_3D_Structure.py)
#
#   All scripts of this package can be found under
#    /var_code/AMOC_3D_Structure
#    & data under /obs_data/AMOC_3D_Structure
#
#   The following Python packages are required:
#    os,glob,shutil,subprocess

#   Use Anaconda:
#    These Python packages are already included in the standard installation
#
#   The following 3 3-D (lat-lon-time) model fields are required:
#     (1) precipitation rate (units: mm/s = kg/m^2/s)
#     (2) column water vapor (CWV, or precipitable water vapor; units mm = kg/m^2)
#     (3) mass-weighted column average temperature (units: K) 
#          or column-integrated saturation specific humidity (units mm = kg/m^2)
#          with column being 1000-200 hPa by default 
#    Since (3) is not standard model output yet, this package will automatically
#    calculate (3) if the follwoing 4-D (lat-lon-pressure-time) model field is available:
#     (4) air temperature (units: K)
#
#   Reference: 
#    Xu X., P. B. Rhines, and E. P. Chassignet (2016): Temperature-Salinity Structure of the North Atlantic Circulation and Associated Heat and Freshwater Transports. J. Cli., 29, 7723-7742, doi: 10.1175/JCLI-D-15-0798.1
#
# OPEN SOURCE COPYRIGHT Agreement TBA
# ======================================================================
# Import standard Python packages

import os
import glob
import commands

from recover_vmo_by_vo import recover_vmo_by_vo
from monthly_to_yearly import monthly_to_yearly
from yearly_to_climate import yearly_to_climate
from AMOC_T2B_from_climate import AMOC_T2B_from_climate
from interp_vit_to_viv_monthly import interp_vit_to_viv_monthly
from trans_lats_monthly import trans_lats_monthly
from AMOC_qts_from_yearly import AMOC_qts_from_yearly
from trans_wgt_TS_yearly import trans_wgt_TS_yearly
from MHT_MFWT_qts_from_yearly import MHT_MFWT_qts_from_yearly
from AMOC_3D_Structure_plot import single_ncl_test
from post_process import create_html
from post_process import create_html2
from post_process import create_html3
from post_process import convert_pdf2png
from post_process import mv_mon_yr
from post_process import execute_ncl_calculate

#============================================================
#  file exists?
#============================================================   
model=os.environ["CASENAME"]
DIR_in=os.environ["MONDIR"]
DIR_out=os.environ["OUTDIR"]

missing_file=0
if len(glob.glob(os.environ["MONDIR"]+model+"."+os.environ["vo_var"]+".mon*.nc"))==0:
   print("Velocity data missing!")
   missing_file=missing_file+1
if len(glob.glob(os.environ["MONDIR"]+model+"."+os.environ["vmo_var"]+".mon*.nc"))==0:
   print("Volume Transport NOT provided, will computed by Velocity!")
   missing_file=missing_file+1

if missing_file==2:
   print(" No transport or velocity provided. AMOC_3D_Structure will NOT be executed!")
   exit()

#============================================================
# create html of QTS Figures together

recover_vmo_by_vo(model,DIR_in,DIR_out)
os.environ["which_mean"] = "occur_times"
monthly_to_yearly(model,DIR_in,DIR_out,"vmo","vmo")
yearly_to_climate(model,DIR_in,DIR_out,"vmo","vmo")
AMOC_T2B_from_climate(model,DIR_in,DIR_out)
interp_vit_to_viv_monthly(model,DIR_in,DIR_out)
monthly_to_yearly(model,DIR_in,DIR_out,"thetao_viv","thetao")
yearly_to_climate(model,DIR_in,DIR_out,"thetao_viv","thetao")
monthly_to_yearly(model,DIR_in,DIR_out,"so_viv","so")
yearly_to_climate(model,DIR_in,DIR_out,"so_viv","so")
trans_lats_monthly(model,DIR_in,DIR_out)
os.environ["which_mean"] = "total_times"
monthly_to_yearly(model,DIR_in,DIR_out,"trans","trans")
yearly_to_climate(model,DIR_in,DIR_out,"trans","trans")

script=os.environ["SRCDIR"]+"sigma0_on_theta-salt_plane.ncl"
execute_ncl_calculate(script)
script=os.environ["SRCDIR"]+"sigma2_on_theta-salt_plane.ncl"
execute_ncl_calculate(script)

os.environ["which_mean"] = "total_times"
AMOC_qts_from_yearly(model,"AMOC_qts_from_yearly.ncl")
yearly_to_climate(model,DIR_in,DIR_out,"AMOC_qts","moc")
AMOC_qts_from_yearly(model,"AMOCT_qts_from_yearly.ncl")
yearly_to_climate(model,DIR_in,DIR_out,"AMOCT_qts","moc")
AMOC_qts_from_yearly(model,"AMOCS_qts_from_yearly.ncl")
yearly_to_climate(model,DIR_in,DIR_out,"AMOCS_qts","moc")

trans_wgt_TS_yearly(model)
os.environ["which_mean"] = "occur_times"
yearly_to_climate(model,DIR_in,DIR_out,"thetao_wgt","thetao")
yearly_to_climate(model,DIR_in,DIR_out,    "so_wgt","so")
yearly_to_climate(model,DIR_in,DIR_out, "trans_avg","trans")

MHT_MFWT_qts_from_yearly(model,"MHT_MFWT_qts_from_yearly.ncl")
os.environ["which_mean"] = "occur_times"
yearly_to_climate(model,DIR_in,DIR_out, "MHT","MHT")
yearly_to_climate(model,DIR_in,DIR_out, "MFWT","MFWT")

#============================================================
# ploting ...
#============================================================
single_ncl_test(model)

#============================================================
# move monthly and yearly files to mon_yr/
#============================================================
#mv_mon_yr(model)

#============================================================
# create html of QTS Figures individually
#============================================================
create_html(model)

#============================================================
# convert pdf to png
#============================================================
convert_pdf2png()

#============================================================
(status, num_png) = commands.getstatusoutput("find "+os.environ["WKDIR"]+" -depth -name 'MFWT_lats_y_plot.png' | wc -l")
num_model=str(len(os.environ["MODELS"].split()))
if num_png==num_model:
#   create_html3()
#   exit()
   script=os.environ["SRCDIR"]+"sum_Q_lat0_z_plot.ncl"
   execute_ncl_calculate(script)
   script=os.environ["SRCDIR"]+"sum_T_lat0_z_plot.ncl"
   execute_ncl_calculate(script)
   script=os.environ["SRCDIR"]+"sum_S_lat0_z_plot.ncl"
   execute_ncl_calculate(script)
   script=os.environ["SRCDIR"]+"Twgt_vs_Swgt_lat0_dots_plot.ncl"
   execute_ncl_calculate(script)
   script=os.environ["SRCDIR"]+"sum_AMOCr_r_plot.ncl"
   execute_ncl_calculate(script)
   script=os.environ["SRCDIR"]+"sum_AMOCT_T_plot.ncl"
   execute_ncl_calculate(script)
   script=os.environ["SRCDIR"]+"sum_AMOCS_S_plot.ncl"
   execute_ncl_calculate(script)
   script=os.environ["SRCDIR"]+"sum_S_lat0_z_plot.ncl"
   execute_ncl_calculate(script)
   script=os.environ["SRCDIR"]+"sum_Qavg_lats_y_plot.ncl"
   execute_ncl_calculate(script)
   script=os.environ["SRCDIR"]+"sum_Twgt_lats_y_plot.ncl"
   execute_ncl_calculate(script)
   script=os.environ["SRCDIR"]+"sum_Swgt_lats_y_plot.ncl"
   execute_ncl_calculate(script)
   script=os.environ["SRCDIR"]+"sum_MHT_lats_y_plot.ncl"
   execute_ncl_calculate(script)
   script=os.environ["SRCDIR"]+"sum_MFWT_lats_y_plot.ncl"
   execute_ncl_calculate(script)
   script=os.environ["SRCDIR"]+"MFWT_vs_AMOCr_lat0_dots_plot.ncl"
   execute_ncl_calculate(script)
   script=os.environ["SRCDIR"]+"MHT_vs_AMOCr_lat0_dots_plot.ncl"
   execute_ncl_calculate(script)
   script=os.environ["SRCDIR"]+"MFWT_vs_Sdiff_lat0_dots_plot.ncl"
   execute_ncl_calculate(script)
   script=os.environ["SRCDIR"]+"MHT_vs_Tdiff_lat0_dots_plot.ncl"
   execute_ncl_calculate(script)
#   create_html2()
   create_html3()
#   exit()

print("**************************************************")
print("AMOC_3D_Structure Package (AMOC_3D_Structure.py) Executed!")
print("**************************************************")
