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
import climatology
import Koppen
import Koppen_plots as plots

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

    print('Compute {tas_var} climatology'.format(**args))
    tas = prep_taslut(args['tas_var'], tas_ds, args)
    clim = climatology.Climatology(date_range, args['tas_var'], tas_ds, var=tas)
    tas_clim = KoppenAverages(
        annual = clim.mean_annual(tas),
        apr_sep = clim.custom_season_mean(tas, 4, 9),
        oct_mar = clim.custom_season_mean(tas, 10, 3),
        monthly = clim.mean_monthly(tas)
    )
    del tas

    print('Compute {pr_var} climatology'.format(**args))
    pr = prep_pr(args['pr_var'], pr_ds, args)
    clim = climatology.Climatology(date_range, args['pr_var'], pr_ds, var=pr)
    pr_clim = KoppenAverages(
        annual = clim.total_annual(pr),
        apr_sep = clim.custom_season_total(pr, 4, 9),
        oct_mar = clim.custom_season_total(pr, 10, 3),
        monthly = clim.total_monthly(pr)
    )
    del pr

    print('Computing Koppen classes ({convention} convention)'.format(**args))
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
    _ = koppen.make_classes()
    return koppen

# -------------------------------------
# netcdf utilities and output

def check_nc_names(name, ds):
    if name in ds.variables:
        return name
    # else return name of highest-dimensional Variable in Dataset, under the
    # assumption that's the variable of interest
    d = {k:len(v.shape) for k,v in ds.variables.items()}
    return max(d.items(), key=operator.itemgetter(1))[0]

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
    bnds_name = plots.bounds_name(ax_name, src_ds)
    if bnds_name:
        for dim in src_ds.variables[bnds_name].dimensions:
            _copy_dimension(dim)
            if dim in src_ds.variables:
                _copy_variable(dim)
        _copy_variable(bnds_name)

def write_nc_output(nc_out_path, koppen_obj, ds, args=None):
    """Write Koppen classes to a NetCDF file.

    Args:
        nc_out_path: (str) Destination path.
        koppen_obj: (instance of Koppen) output of calc_koppen_classes().
        ds: (netCDF4 Dataset) Dataset containing lat/lon axis information.
        args: (dict, optional) Config options set if this is being called from
            the command-line or the MDTF diagnostics framework.
    """
    if args is None:
        # assume we're being called interactively
        args = args_from_envvars(use_environ=False)
    enum_dict = {cl.name : cl.value for cl in koppen_obj.KoppenClass}
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
    class_var[:] = koppen_obj.classes
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
    args['tas_var'] = check_nc_names(args['tas_var'], tas_ds)
    print('Found {tas_var} at {tas_path}'.format(**args))
    pr_ds = nc.Dataset(args['pr_path'], 'r', keepweakref=True)
    args['pr_var'] = check_nc_names(args['pr_var'], pr_ds)
    print('Found {pr_var} at {pr_path}'.format(**args))

    koppen = calc_koppen_classes(date_range, tas_ds, pr_ds, args['convention'], args)
    if args['save_nc']:
        print('Writing netcdf file to {nc_out_path}'.format(**args))
        write_nc_output(args['nc_out_path'], koppen, pr_ds, args)
    if not args['no_plot']:
        print('Writing plot to {ps_out_path}'.format(**args))
        plots.koppen_plot(koppen, pr_ds, args)

    tas_ds.close()
    pr_ds.close()
    