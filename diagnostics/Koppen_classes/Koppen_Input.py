'''
Created on Oct 23, 2019

@author: Diyor.Zakirov
'''
import os
import collections
import math
import netCDF4 as nc
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.patches import Patch
from matplotlib.colors import LinearSegmentedColormap
import cartopy.crs as ccrs
import Koppen
import climatology

def copy_axis(ax_name, src_ds, dst_ds, bounds=True):
    """Copy Dimension and associated Variable from one one netCDF4 Dataset to 
    another, since this isn't provided directly by the netCDF4 module. If 
    Based on discussion in https://stackoverflow.com/a/49592545.
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
            dst_ds.createVariable(var_name, var.datatype, var.dimensions)
            # copy variable attributes first, all at once via dictionary
            dst_ds[var_name].setncatts(src_ds[var_name].__dict__)
            # copy data
            dst_ds[var_name][:] = src_ds[var_name][:]
        else:
            # netcdf library doesn't implement deleting variables, so no overwrite
            assert var.shape == dst_ds.variables[var_name].shape

    _copy_dimension(ax_name)
    if ax_name in src_ds.variables:
        _copy_variable(ax_name)
    if bounds:
        ax_bnds_name = ax_name+'_bnds'
        if ax_bnds_name in src_ds.variables:
            _copy_variable(ax_bnds_name)
            for dim in src_ds.variables[ax_bnds_name].dimensions:
                _copy_dimension(dim)
                if dim in src_ds.variables:
                    _copy_variable(dim)


class NCCommonAxis(object):
    """Class for working with a collection of netCDF Datasets (assumed to be one
    Dataset per variable) on a set of common axes. 
    """
    def __init__(self, **ds_dict):
        self.ds_dict = ds_dict

        self.my_ax_names = collections.OrderedDict()
        _d = {'time_coord':'time', 'lat_coord':'lat', 'lon_coord':'lon'}
        for k,v in _d.items():
            self.my_ax_names[k] = v

        self.file_var_names = dict()
        self.file_ax_names = collections.OrderedDict()
        self.names_from_envvars()

        # used for in-memory storage only, but netCDF4 requires we pass a filename
        self.common_axes = nc.Dataset('dummy_filename.nc', diskless=True, persist=False)
        self.common_dtype = np.float64

    # -----------------------------------------------------------

    def names_from_envvars(self):
        for envvar_name, ds in self.ds_dict.items():
            assert envvar_name in os.environ
            self.file_var_names[envvar_name] = os.environ[envvar_name]
            assert self.file_var_names[envvar_name] in ds.variables
        
        for envvar_name in self.my_ax_names:
            assert envvar_name in os.environ
            self.file_ax_names[envvar_name] = os.environ[envvar_name]

    def collect_axes(self):
        for ds in self.ds_dict.values():
            self.copy_axes(ds, self.common_axes, bounds=False)

            for k in my_ax_names:
            old_ax = file_ax_names[k]
            new_ax = my_ax_names[k]
            dst_ds.renameVariable(old_ax, new_ax)
            dst_ds.renameDimension(old_ax, new_ax)

    def get_axis(self, my_ax_name):
        pass


def prep_taslut(ds, file_var_name):
    file_ax_names = {'time_coord':'time', 'lat_coord':'lat', 'lon_coord':'lon'}
    
    var = ds.variables[file_var_name]
    ans = var[:] # copy np.Array
    if len(var.dimensions) == 3:
        pass
    elif len(var.dimensions) == 4:
        ax4_name = set(var.dimensions).difference(set(file_ax_names.values()))
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

def prep_pr(ds, file_var_name):
    ans = ds.variables[file_var_name][:]
    ans = np.ma.masked_invalid(ans)
    ans = np.ma.masked_less(ans, 0.0)
    
    ans = ans * 86400.0 # assume flux kg/m2/s (mm/s), convert to mm/day
    return ans

KoppenAverages = namedtuple('KoppenAverages', 
    ['annual', 'apr_sep', 'oct_mar', 'monthly']
)
def run_koppen(foo):
    tas_ds = nc.Dataset('atmos_cmip.200001-200412.tas.nc', 'r', keepweakref=True)
    landmask_ds = XXX
    tas = prep_taslut(tas_ds, 'tasLut')
    clim = climatology.Climatology(date_range, 'tasLut', tas_ds, var=tas)
    tas_clim = KoppenAverages(
        annual = clim.mean_annual(tas),
        apr_sep = clim.custom_season_mean(tas, 4, 9),
        oct_mar = clim.custom_season_mean(tas, 10, 3),
        monthly = clim.mean_monthly(tas)
    )
    tas_ds.close()

    pr_ds = nc.Dataset('atmos_cmip.200001-200412.pr.nc', 'r', keepweakref=True)
    pr = prep_pr(pr_ds, 'pr')
    clim = climatology.Climatology(date_range, 'pr', pr_ds, var=pr)
    pr_clim = KoppenAverages(
        annual = clim.total_annual(pr),
        apr_sep = clim.custom_season_total(pr, 4, 9),
        oct_mar = clim.custom_season_total(pr, 10, 3),
        monthly = clim.total_monthly(pr)
    )
    pr_ds.close()

    koppen = Koppen(tas_clim, pr_clim, summer_is_apr_sep=None)
    koppen.make_classes()


# -------------------------------------

koppen_colors = {
        "Af":  (  0,   0, 255),
        "Am":  (  0, 120, 255),
        "Aw":  ( 70, 170, 250),
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

def munge_ax(ds, bnds_name, shape):
    # pcolormap wants X, Y to be rectangle bounds (so longer than array being
    # plotted by one entry) and also doesn't automatically broadcast.
    ax_var = ds.variables[bnds_name][:]
    if np.ma.is_masked(ax_var):
        assert np.ma.count_masked(ax_var) == 0
        ax_var = ax_var.filled()
    ax = np.append(ax_var[:,0], ax_var[-1,1])
    # add a new singleton axis along whichever axis (0 or 1) *doesn't* match 
    # length of ax_var
    new_ax_pos = 1 - shape.index(ax_var.shape[0])
    ax = np.expand_dims(ax, axis=new_ax_pos)
    return np.broadcast_to(ax, (shape[0]+1, shape[1]+1))

def koppen_plot(var, ds):
    lat = munge_ax(ds, 'lat_bnds', var.shape)
    lon = munge_ax(ds, 'lon_bnds', var.shape)
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
        Patch(facecolor=get_color(i), edgecolor='k', label=Koppen.KoppenClass(i).name) \
        for i in k_range
    ]
    for k_cls in ('Cfc', 'Csc', 'Cwc','ET'):
        # pad out shorter legend columns with blank swatches
        idx = [p.get_label() for p in legend_entries].index(k_cls)
        legend_entries.insert(idx + 1, Patch(facecolor='w', edgecolor='w', label=''))

    fig = plt.figure(figsize=(20, 10))
    ax = plt.gca(projection=ccrs.PlateCarree(), )
    ax.pcolormesh(lon, lat, var, cmap=c_map, transform=ccrs.PlateCarree())
    ax.coastlines()
    ax.set_global()
    ax_extents = ax.get_extent()
    ax.set_xticks(np.arange(ax_extents[0], ax_extents[1]+1.0, 90.0))
    ax.set_yticks(np.arange(ax_extents[2], ax_extents[3]+1.0, 45.0))
    ax.set_title('<CASENAME> Koppen classes, <date_range>',fontsize='x-large')
    
    # Set legend outside axes: https://stackoverflow.com/a/43439132
    # Don't make a figure legend because that might get cut off when plot is
    # saved (current known issue in matplotlib) or we might be working within
    # a subplot.
    _leg = ax.legend(
        handles=legend_entries, fontsize='large'frameon=False, ncol=9,
        loc='upper center', borderaxespad=0, bbox_to_anchor=(0.0, -0.25, 1.0, 0.2)
    )
    # Expand legend bounding box downward: https://stackoverflow.com/a/46711725
    fontsize = fig.canvas.get_renderer().points_to_pixels(_leg._fontsize)
    pad = 2*(_leg.borderaxespad + _leg.borderpad) * fontsize
    _leg._legend_box.set_height(_leg.get_bbox_to_anchor().height - pad)

    plt.show()


if __name__ == '__main__':
    pass
    #start = timeit.default_timer()
    #pool = mp.Pool(mp.cpu_count())
    #cProfile.run('netcdfToKoppen(1920,1950,1850)')
    #netcdfToKoppen(1920,1950,1850)
    #pool.close()
    #stop = timeit.default_timer()
    #print("Whole time: ", stop - start)
    
    
    