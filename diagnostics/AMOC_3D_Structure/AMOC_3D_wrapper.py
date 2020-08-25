# AMOC 3D Structure Diagnostic wrapper
# Code received for this POD was written to the standards of the v1.0 MDTF 
# package. Rather than make extensive changes to the POD's code, we call this
# wrapper script as the top-level entry point instead.

import os
import runpy

# Set paths as env vars
# os.path.join to null string adds a terminal '/' if not present

os.environ["SRCDIR"] = os.path.join(os.environ["POD_HOME"], "")
os.environ["HTMDIR"] = os.path.join(os.environ["POD_HOME"], "htmls")

# in v1.0, this was a comma-delimited string of model names; only run one model
# per POD invocation now
os.environ["MODELS"] = os.environ["CASENAME"].replace(' ', '_')

# obs data paths
os.environ["REFDIR"] = os.path.join(os.environ["OBS_DATA"], "")
os.environ["CLMREF"] = os.path.join(os.environ["OBS_DATA"], "clim", "")
os.environ["FIXREF"] = os.path.join(os.environ["OBS_DATA"], "fx", "")

# model data paths
os.environ["MONDIR"] = os.path.join(os.environ["DATADIR"], "mon", "")
os.environ["FIXDIR"] = os.path.join(os.environ["DATADIR"], "fx", "")

# paths for output files in POD's working directory
os.environ["QTSDIR"] = os.path.join(os.environ["WK_DIR"], "")
os.environ["PNGDIR"] = os.path.join(os.environ["WK_DIR"], "model", "")
os.environ["FIGDIR"] = os.path.join(os.environ["WK_DIR"], "model", "PS", "")
os.environ["OUTDIR"] = os.path.join(os.environ["WK_DIR"], "model", "netCDF", "")
os.environ["TMPDIR"] = os.path.join(os.environ["WK_DIR"], "model", "netCDF", "mon_yr", "")
os.environ["FIGREF"] = os.path.join(os.environ["WK_DIR"], "obs", "PS", "")
os.environ["PNGREF"] = os.path.join(os.environ["WK_DIR"], "obs", "")

# Call top-level POD scripts from current process
# ==============================================================================
# 1.  Pre-processing for CMIP5_Atlantic_QTS
##     create unified Ocean BASIN index, extract latitude coordinates and dx dy dz
#     This requires model output data. 
# 2.  Project volume transport onto Temperature/Salinity plane
#     AMOC structures on depth, density, temperature and salinity coordinates
#     This requires AMOC_3D_Structure Pre-processing data
#     the code is in NCL
# ==============================================================================
runpy.run_path(os.path.join(os.environ["SRCDIR"], "basin_lat_dxdydz.py"))
runpy.run_path(os.path.join(os.environ["SRCDIR"], "AMOC_3D_Structure.py"))
runpy.run_path(os.path.join(os.environ["SRCDIR"], "obs_AMOC_3D_Structure.py"))
