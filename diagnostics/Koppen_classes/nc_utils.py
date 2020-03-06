"""Misc. utility functions for working with numpy arrays obtained from netCDF4
Datasets. Collected here in a separate file to avoid circular imports in the 
rest of the code.
"""
import operator
import netCDF4 as nc
import numpy as np

def check_dependent_var_name(name, ds):
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

def unmask_axis(ax_var):
    ax_copy = ax_var[:]
    if np.ma.is_masked(ax_copy):
        assert np.ma.count_masked(ax_copy) == 0
        return ax_copy.filled()
    else:
        return ax_copy

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
    