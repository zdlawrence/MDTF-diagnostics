#!/usr/bin/env python
"""
Top-level script to compute and plot Koppen land climate classes.

Author/maintainer: Tom Jackson
This is a python port of work by Chris Dupuis, Diyor Zakirov and Raymond Menzel.

User-facing functions (besides __main__) are calc_koppen_classes(), 
koppen_plot() and write_nc_output().
"""
import os
import argparse
import collections
import operator
import netCDF4 as nc
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.patches import Patch
from matplotlib.colors import LinearSegmentedColormap
import cartopy.crs as ccrs
import Koppen
import climatology

# ----------------------------
# processing NetCDF data, computing climatologies and Koppen classes

def prep_taslut(file_var_name, ds, args):
    """Pre-process tas data before computing climatology. Convert units to C."""
    var = ds.variables[file_var_name]
    ans = var[:] # copy np.Array
    if len(var.dimensions) == 3:
        pass
    elif len(var.dimensions) == 4:
        known_axes = set([v for k,v in args.items() if k.endswith('_coord')])
        ax4_name = set(var.dimensions).difference(known_axes)
        ax4_name = list(ax4_name)[0]
        ax4_pos = var.dimensions.index(ax4_name)
        ax4 = ds.variables[ax4_name]
        ind4 = 0 # default slice
        try:
            lu_inds = ax4.getncattr('flag_values')
            if not isinstance(lu_inds, collections.Iterable):
                lu_inds = [int(s) for s in lu_inds.split()]
            lu_vals = ax4.getncattr('flag_meanings')
            if not isinstance(lu_vals, collections.Iterable):
                lu_vals = lu_vals.split()
            assert 'psl' in lu_vals
            ind4 = lu_inds[lu_vals.index('psl')]
        except:
            raise
        ans = np.squeeze(np.ma.take(ans, [ind4], axis=ax4_pos))
    else:
        raise Exception("Can't handle 'tas' with dimensions {}".format(var.dimensions))
        
    ans = np.ma.masked_invalid(ans)
    if hasattr(var, 'units') and 'k' not in var.units.lower():
        print('Warning, taslut not in Kelvin, assuming celsius')
    else:
        ans = np.ma.masked_less(ans, 0.0)
        ans = ans - 273.15
    return ans

def prep_pr(file_var_name, ds, args):
    """Pre-process pr data before computing climatology. 
    Convert units to mm/day."""
    ans = ds.variables[file_var_name][:]
    ans = np.ma.masked_invalid(ans)
    ans = np.ma.masked_less(ans, 0.0)
    
    # pr_conversion_factor is a MDTF env var that converts model units to MKS 
    # flux kg/m2/s (take as equiv to mm/s). Convert that to mm/day here.
    ans = ans * 86400.0 * float(args['pr_conversion_factor'])
    return ans

def calc_koppen_classes(date_range, tas_ds, pr_ds, convention='Peel07', args=None):
    """Compute Koppen classes from tas and pr, provided as netCDF Datasets.

    Args:
        date_range: Two-element list of [start year, end year] to average over. 
            Intervals are inclusive.
        tas_ds: (netCDF4 Dataset): tas data.
        pr_ds: (netCDF4 Dataset): pr data.
        args: (dict, optional): Config options set if this is being called from
            the command-line or the MDTF diagnostics framework.

    Returns:
        numpy Array of dtype ubyte and dimensions equal to spatial dimensions of
        tas/pr. Each entry labels the Koppen class for that cell according to
        the values in the Koppen.KoppenClass enum 
        (eg. Koppen.KoppenClass['Csc'].value). Entries of 0 correspond to masked,
        missing or invalid data.
    """
    KoppenAverages = collections.namedtuple('KoppenAverages', 
        ['annual', 'apr_sep', 'oct_mar', 'monthly']
    )
    if args is None:
        # assume we're being called interactively
        args = args_from_envvars(use_environ=False)
        args['tas_var'] = check_nc_names(args['tas_var'], tas_ds)
        args['pr_var'] = check_nc_names(args['pr_var'], pr_ds)
    tas = prep_taslut(args['tas_var'], tas_ds, args)
    clim = climatology.Climatology(date_range, args['tas_var'], tas_ds, var=tas)
    tas_clim = KoppenAverages(
        annual = clim.mean_annual(tas),
        apr_sep = clim.custom_season_mean(tas, 4, 9),
        oct_mar = clim.custom_season_mean(tas, 10, 3),
        monthly = clim.mean_monthly(tas)
    )
    del tas

    pr = prep_pr(args['pr_var'], pr_ds, args)
    clim = climatology.Climatology(date_range, args['pr_var'], pr_ds, var=pr)
    pr_clim = KoppenAverages(
        annual = clim.total_annual(pr),
        apr_sep = clim.custom_season_total(pr, 4, 9),
        oct_mar = clim.custom_season_total(pr, 10, 3),
        monthly = clim.total_monthly(pr)
    )
    del pr

    if convention == 'Peel07':
        koppen = Koppen.Koppen_Peel07(tas_clim, pr_clim, summer_is_apr_sep=None)
    else:
        lats = pr_ds.variables[args['lat_coord']][:]
        assert np.amax(lats) > 0.0
        assert np.amin(lats) < 0.0
        lats = np.expand_dims(lats, axis=1)
        n_hemisphere_mask = np.broadcast_to((lats >= 0.0), pr_clim.annual.shape)
        
        if convention == 'Kottek06':
            koppen = Koppen.Koppen_Kottek06(tas_clim, pr_clim, 
                summer_is_apr_sep=n_hemisphere_mask)
        elif convention == 'GFDL':
            koppen = Koppen.Koppen_GFDL(tas_clim, pr_clim, 
                summer_is_apr_sep=n_hemisphere_mask)
        else:
            raise ValueError("Unrecognized convention '{}'".format(convention))
    return koppen.make_classes()

# -------------------------------------
# plotting koppen classes

koppen_colors = {
        "Af":  (  0,   0, 255),
        "Am":  (  0, 120, 255),
        "Aw":  ( 70, 170, 250),
        "As":  ( 70, 170, 250),
        "BWh": (255,   0,   0),
        "BWk": (255, 150, 150),
        "BSh": (245, 165,   0),
        "BSk": (255, 220, 100),
        "Csa": (255, 255,   0),
        "Csb": (198, 199,   0),
        "Csc": (150, 150,   0),
        "Cwa": (150, 255, 150),
        "Cwb": ( 99, 199,  99),
        "Cwc": ( 50, 150,  50),
        "Cfa": (200, 255,  80),
        "Cfb": (102, 255,  51),
        "Cfc": ( 50, 199,   0),
        "Dsa": (255,   0, 254),
        "Dsb": (198,   0, 199),
        "Dsc": (150,  50, 149),
        "Dsd": (150, 100, 149),
        "Dwa": (171, 177, 255),
        "Dwb": ( 90, 199, 219),
        "Dwc": ( 76,  81, 181),
        "Dwd": ( 50,   0, 135),
        "Dfa": (  0, 255, 255),
        "Dfb": ( 56, 199, 255),
        "Dfc": (  0, 126, 125),
        "Dfd": (  0,  69,  94),
        "ET":  (178, 178, 178),
        "EF":  (104, 104, 104)
    }
def get_color(i):
    key = Koppen.KoppenClass(i).name
    return tuple([rgb / 255.0 for rgb in koppen_colors[key]])

def munge_ax(ax_name, ds, data_shape):
    """Convert Dataset axes into a format accepted by 
    matplotlib.pyplot.pcolormap. """
    # pcolormap wants X, Y to be rectangle bounds (so longer than array being
    # plotted by one entry) and also doesn't automatically broadcast.
    bnds_name = bounds_name(ax_name, ds)
    if bnds_name:
        ax_var = ds.variables[bnds_name][:]
        if np.ma.is_masked(ax_var):
            assert np.ma.count_masked(ax_var) == 0
            ax_var = ax_var.filled()
        ax_bnds = np.append(ax_var[:,0], ax_var[-1,1])
    else:
        # can't find bounds; compute midpoints from scratch
        ax_var = ds.variables[ax_name][:]
        if np.ma.is_masked(ax_var):
            assert np.ma.count_masked(ax_var) == 0
            ax_var = ax_var.filled()
        ax_bnds = [(ax_var[i] + ax_var[i+1]) / 2.0 for i in range(len(ax_var)-1)]
        first_step = abs(ax_var[1] - ax_var[0]) / 2.0
        last_step = abs(ax_var[-2] - ax_var[-1]) / 2.0
        ax_bnds.insert(0, ax_var[0] - first_step)
        ax_bnds.append(ax_var[-1] + last_step)
        ax_bnds = np.array(ax_bnds)

    # add a new singleton axis along whichever axis (0 or 1) *doesn't* match 
    # length of ax_var, then broadcast into that axis 
    new_ax_pos = 1 - data_shape.index(ax_var.shape[0])
    ax_bnds = np.expand_dims(ax_bnds, axis=new_ax_pos)
    return np.broadcast_to(ax_bnds, (data_shape[0]+1, data_shape[1]+1))

def koppen_plot(var, ds, args=None):
    """Plot Koppen classes with legend, using colors defined above.

    Args:
        var: (numpy Array) output of calc_koppen_classes().
        ds: (netCDF4 Dataset) Dataset containing lat/lon axis information.
        args: (dict, optional) Config options set if this is being called from
            the command-line or the MDTF diagnostics framework.
    """
    if args is None:
        # assume we're being called interactively
        args = args_from_envvars(use_environ=False)
        title_str = 'Koppen classes'
    else:
        title_str = '{CASENAME} Koppen classes, {FIRSTYR}-{LASTYR}'.format(**args)
    lat = munge_ax(args['lat_coord'], ds, var.shape)
    lon = munge_ax(args['lon_coord'], ds, var.shape)
    var = np.ma.masked_equal(var, 0)

    k_range = range(
        min(Koppen.KoppenClass).value, 
        max(Koppen.KoppenClass).value + 1
    )
    color_list = [get_color(i) for i in k_range]
    c_map = LinearSegmentedColormap.from_list(
        'koppen_colors', color_list, N=len(color_list)
    )
    legend_entries = [
        Patch(facecolor=get_color(i), edgecolor='k', 
            label=Koppen.KoppenClass(i).name) for i in k_range
    ]
    for k_cls in ('Cfc', 'Csc', 'Cwc','ET'):
        # pad out shorter legend columns with blank swatches
        idx = [p.get_label() for p in legend_entries].index(k_cls)
        legend_entries.insert(idx + 1, Patch(facecolor='w', edgecolor='w', label=''))

    fig = plt.figure(figsize=(16, 8))
    ax = plt.gca(projection=ccrs.PlateCarree())
    ax.pcolormesh(lon, lat, var, cmap=c_map, transform=ccrs.PlateCarree())
    ax.coastlines()
    ax.set_global()
    ax_extents = ax.get_extent()
    ax.set_xticks(np.arange(ax_extents[0], ax_extents[1]+1.0, 90.0))
    ax.set_yticks(np.arange(ax_extents[2], ax_extents[3]+1.0, 45.0))
    ax.set_title(title_str, fontsize='x-large')
    
    # Set legend outside axes: https://stackoverflow.com/a/43439132
    # Don't make a figure legend because that might get cut off when plot is
    # saved (current known issue in matplotlib) or we might be working within
    # a subplot.
    _leg = ax.legend(
        handles=legend_entries, fontsize='large', frameon=False, 
        loc='upper center', ncol=9,
        borderaxespad=0, bbox_to_anchor=(0.0, -0.25, 1.0, 0.2)
    )
    # Expand legend bounding box downward: https://stackoverflow.com/a/46711725
    fontsize = fig.canvas.get_renderer().points_to_pixels(_leg._fontsize)
    pad = 2 * (_leg.borderaxespad + _leg.borderpad) * fontsize
    _leg._legend_box.set_height(_leg.get_bbox_to_anchor().height - pad)

    if 'ps_out_path' in args:
        plt.savefig(args['ps_out_path'], bbox_inches='tight')
    else:
        # assume we're being called interactively
        plt.show()

# -------------------------------------
# netcdf utilities and output

def check_nc_names(name, ds):
    if name in ds.variables:
        return name
    # else return name of highest-dimensional Variable in Dataset, under the
    # assumption that's the variable of interest
    d = {k:len(v.shape) for k,v in ds.variables.items()}
    return max(d.items(), key=operator.itemgetter(1))[0]

def bounds_name(ax_name, ds):
    if hasattr(ds.variables[ax_name], 'bounds'):
        ax_bnds = ds.variables[ax_name].bounds
    else:
        ax_bnds = ax_name + '_bnds'
    return (ax_bnds if ax_bnds in ds.variables else None)

def copy_nc_axis(ax_name, src_ds, dst_ds):
    """Copy Dimension and associated Variable(s) from one one netCDF4 Dataset to 
    another. Based on discussion in https://stackoverflow.com/a/49592545.
    """
    def _copy_dimension(dim_name):
        assert dim_name in src_ds.dimensions
        dim = src_ds.dimensions[dim_name]
        if dim_name not in dst_ds.dimensions:
            dst_ds.createDimension(
                dim_name, (dim.size if not dim.isunlimited() else None)
            )
        else:
            # netcdf library doesn't implement deleting dimensions, so no overwrite
            assert dim.size == dst_ds.dimensions[dim_name].size

    def _copy_variable(var_name):
        assert var_name in src_ds.variables
        var = src_ds.variables[var_name]
        if var_name not in dst_ds.variables:
            new_var = dst_ds.createVariable(var_name, var.datatype, var.dimensions)
            # copy variable attributes first, all at once via dictionary
            new_var.setncatts(var.__dict__)
            # copy data
            new_var[:] = var[:]
        else:
            # netcdf library doesn't implement deleting variables, so no overwrite
            assert var.shape == dst_ds.variables[var_name].shape

    _copy_dimension(ax_name)
    if ax_name in src_ds.variables:
        _copy_variable(ax_name)
    bnds_name = bounds_name(ax_name, src_ds)
    if bnds_name:
        for dim in src_ds.variables[bnds_name].dimensions:
            _copy_dimension(dim)
            if dim in src_ds.variables:
                _copy_variable(dim)
        _copy_variable(bnds_name)

def write_nc_output(nc_out_path, classes, ds, args=None):
    """Write Koppen classes to a NetCDF file.

    Args:
        nc_out_path: (str) Destination path.
        classes: (numpy Array) output of calc_koppen_classes().
        ds: (netCDF4 Dataset) Dataset containing lat/lon axis information.
        args: (dict, optional) Config options set if this is being called from
            the command-line or the MDTF diagnostics framework.
    """
    if args is None:
        # assume we're being called interactively
        args = args_from_envvars(use_environ=False)
    enum_dict = {cl.name : cl.value for cl in Koppen.KoppenClass}
    enum_dict['None'] = 0

    out_ds = nc.Dataset(nc_out_path, 'w', data_model=ds.data_model)
    # copy global attributes except those that may be source variable specific
    global_atts = {k:v for k,v in ds.__dict__.items() \
        if not k.startswith(('variable', args['pr_var'], args['tas_var']))}
    out_ds.setncatts(global_atts)
    copy_nc_axis(args['lat_coord'], ds, out_ds)
    copy_nc_axis(args['lon_coord'], ds, out_ds)
    class_var = out_ds.createVariable('Koppen', 
        'u1', # match NC UBYTE dtype used in classes array
        dimensions=(args['lat_coord'], args['lon_coord']),
        fill_value=0 # enum value for masked/missing data
    )
    class_var[:] = classes
    # encode class labels in variable attribute
    str_ = ' '.join([str(i) for i in enum_dict.values()])
    class_var.setncattr_string('flag_values', str_)
    str_ = ' '.join([str(i) for i in enum_dict.keys()])
    class_var.setncattr('flag_meanings', str_)
    out_ds.close()

# -------------------------------------
# driver

def args_from_envvars(use_environ=True):
    names = {
        'tas_var':'tas', 'pr_var': 'pr', 
        'pr_conversion_factor':'1',
        'time_coord':'time', 'lat_coord':'lat', 'lon_coord':'lon'
    }
    if use_environ:
        for k,v in names.items():
            names[k] = os.environ.get(k, v)
    return names

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--FIRSTYR', '-Y', type=int,
        default=int(os.environ.get('FIRSTYR', 0))
    )
    parser.add_argument('--LASTYR', '-Z', type=int,
        default=int(os.environ.get('LASTYR', 0))
    )
    parser.add_argument('--CASENAME', '-n', type=str,
        default=os.environ.get('CASENAME','')
    )
    parser.add_argument('--convention', type=str,
        choices=['Peel07', 'Kottek06', 'GFDL'],
        default='Peel07'
    )
    parser.add_argument('--save_nc', action='store_true',
        default=(os.environ.get('save_nc','0') != '0')
    )
    parser.add_argument('--no_plot', action='store_true')
    parser.add_argument('--output', '-o', type=str,
        default=""
    )
    parser.add_argument('--tas', '-t', type=str, default="", dest='tas_path')
    parser.add_argument('--pr', '-p', type=str, default="", dest='pr_path')
    args = vars(parser.parse_args())
    args.update(args_from_envvars())
    if not args['tas_path']:
        args['tas_path'] = os.path.join(
            os.environ.get('DATADIR', '.'), 'mon',
            '{CASENAME}.{tas_var}.mon.nc'.format(**args)
        )
    if not args['pr_path']:
        args['pr_path'] = os.path.join(
            os.environ.get('DATADIR', '.'), 'mon',
            '{CASENAME}.{pr_var}.mon.nc'.format(**args)
        )
    if not args['output']:
        if 'WK_DIR' in os.environ:
            args['nc_out_path'] = os.path.join(
                os.environ['WK_DIR'], 'model', 'netcdf', 'koppen_classes.nc'
            )
            args['ps_out_path'] = os.path.join(
                os.environ['WK_DIR'], 'model', 'PS', 'koppen_classes.eps'
            )
        else: 
            nc_out_path = os.path.join(os.getcwd(), 'koppen_classes.nc')
            ps_out_path = os.path.join(os.getcwd(), 'koppen_classes.eps')
    else:
        (dir_, file_) = os.path.split(args['output'])
        (file_, _) = os.path.splitext(file_)
        args['nc_out_path'] = os.path.join(dir_, file_+'.nc')
        args['ps_out_path'] = os.path.join(dir_, file_+'.eps')

    date_range = (args['FIRSTYR'], args['LASTYR'])
    tas_ds = nc.Dataset(args['tas_path'], 'r', keepweakref=True)
    pr_ds = nc.Dataset(args['pr_path'], 'r', keepweakref=True)
    args['tas_var'] = check_nc_names(args['tas_var'], tas_ds)
    args['pr_var'] = check_nc_names(args['pr_var'], pr_ds)

    classes = calc_koppen_classes(date_range, tas_ds, pr_ds, args['convention'], args)
    if args['save_nc']:
        write_nc_output(args['nc_out_path'], classes, pr_ds, args)
    if not args['no_plot']:
        koppen_plot(classes, pr_ds, args)

    tas_ds.close()
    pr_ds.close()
    