import netCDF4 as nc
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.patches import Patch
from matplotlib.colors import LinearSegmentedColormap
import cartopy.crs as ccrs
import nc_utils

Peel07_colors = {
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

def get_color(k_class, lookup_table=Peel07_colors):
    return tuple([rgb / 255.0 for rgb in lookup_table[k_class]])

def munge_ax(ax_name, ds, data_shape):
    """Convert Dataset axes into a format accepted by 
    matplotlib.pyplot.pcolormap. """
    # pcolormap wants X, Y to be rectangle bounds (so longer than array being
    # plotted by one entry) and also doesn't automatically broadcast.
    bnds_name = nc_utils.bounds_name(ax_name, ds)
    if bnds_name:
        ax_var = nc_utils.unmask_axis(ds.variables[bnds_name])
        ax_bnds = np.append(ax_var[:,0], ax_var[-1,1])
    else:
        # can't find bounds; compute midpoints from scratch
        ax_var = nc_utils.unmask_axis(ds.variables[ax_name])
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

# --------------------------------------

def koppen_plot(koppen_obj, ds, args=None):
    """Plot Koppen classes with legend, using colors defined above.

    Args:
        koppen_obj: (instance of Koppen) output of calc_koppen_classes().
        ds: (netCDF4 Dataset) Dataset containing lat/lon axis information.
        args: (dict, optional) Config options set if this is being called from
            the command-line or the MDTF diagnostics framework.
    """
    if args is None:
        # assume we're being called interactively
        args = {'time_coord':'time', 'lat_coord':'lat', 'lon_coord':'lon'}
        title_str = 'Koppen classes'
    else:
        title_str = '{CASENAME} Koppen classes, {FIRSTYR}-{LASTYR}'.format(**args)
    var = np.ma.masked_equal(koppen_obj.classes, 0)
    lat = munge_ax(args['lat_coord'], ds, var.shape)
    lon = munge_ax(args['lon_coord'], ds, var.shape)

    color_list = [get_color(cl.name) for cl in koppen_obj.KoppenClass]
    c_map = LinearSegmentedColormap.from_list(
        'koppen_colors', color_list, N=len(color_list)
    )
    legend_entries = [
        Patch(facecolor=get_color(cl.name), edgecolor='k', label=cl.name) \
            for cl in koppen_obj.KoppenClass
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
