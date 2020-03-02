'''
Created on Oct 23, 2019

@author: Diyor.Zakirov
'''
import os
import collections
import netCDF4 as nc
import numpy as np
import matplotlib.pyplot as plt
from mpl_toolkits.basemap import Basemap
from Koppen import Koppen
from Climate import Climate

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
    var = ds.variables[file_var_name]
    if len(var.dimensions) == 3:
        pass # ok
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
            assert 'psl' in lu_vals:
            ind4 = lu_inds[lu_vals.index('psl')]
        except:
            raise
        var = np.take(var, ind4, axis=ax4_pos)
    else:
        raise Exception("Can't handle 'tas' with dimensions {}".format(var.dimensions))
    var = verify_3d_axes(var)
        
    if hasattr(var, 'units') and 'k' not in var.units.lower():
        print('Warning, taslut not in Kelvin, assuming celsius')
    else:
        var = var - 273.15
        
    var = np.ma.masked_invalid(var)
    var = np.ma.masked_less(var, 0.0)
    return var

def prep_pr(ds, file_var_name):
    var = ds.variables[file_var_name]
    
    # TODO: units
    
    var = np.ma.masked_invalid(var)
    var = np.ma.masked_less(var, 0.0)
    return var

KoppenAverages = namedtuple('KoppenAverages', 
    ['annual', 'apr_sep', 'oct_mar', 'monthly']
)

def run_koppen(foo):
    apr_sep_months = tuple(range(4,10)) # 4-9 inclusive, python conventions
    oct_mar_months = tuple(set(range(1,13)).difference(apr_sep_months))

    tas_ds = nc.Dataset('atmos_cmip.200001-200412.tas.nc', 'r', keepweakref=True)
    landmask_ds = XXX
    tas = prep_taslut(tas_ds, 'tas_var')
    clim = climatology.Climatology(tas, tas_time, date_range)
    tas_clim = KoppenAverages(
        annual = clim.get_mean(tas)
        apr_sep = None
        oct_mar = None
        monthly = clim.get_monthly(tas)
    )
    tas_ds.close()

    pr_ds = nc.Dataset('atmos_cmip.200001-200412.pr.nc', 'r', keepweakref=True)
    pr = prep_pr(pr_ds, 'pr_var')
    clim = climatology.Climatology(pr, pr_time, date_range)
    pr_clim = KoppenAverages(
        annual = clim.get_mean(pr)
        apr_sep = clim.get_season(pr, apr_sep_months)
        oct_mar = clim.get_season(pr, oct_mar_months)
        monthly = clim.get_monthly(pr)
    )
    pr_ds.close()




def netcdfToKoppen(startYear, endYear, referenceYear,tempFile, precipFile, calendar = "Gregorian"):
    temperature = nc.Dataset(tempFile, "r")
    precipitation = nc.Dataset(precipFile, "r")
    
    tArr = temperature.variables['tasLut'][:,:,:].transpose()
    pArr = precipitation.variables['pr'][:,:,:].transpose()
    
    totalTime = 0
    
    lat_arr = temperature.variables['lat'][:]
    hemisphere = []
    for i in lat_arr:
        if i >= 0:
            hemisphere.append("Northern")
        else:
            hemisphere.append("Southern")

    start = 12 * (startYear - referenceYear) - 1
    end = start + 12 * (endYear - startYear)
    
    temp = np.arange(start,end)
    fDays = np.zeros(0)
    for i in temp:
        fDays = np.append(fDays,daysInFebruary(i, calendar))
    fDaysMean = np.mean(fDays)
    for i in range(0,360):
        if(((i/360)*100)%5 == 0):
            print((i/360)*100)
        for j in range(0,180):
            t = np.empty(0)
            t = np.append(t, tArr[i,j,range(start,end)])
            if t[0] == -1:
                zonesList[i][j] = (255. / 255.,255. / 255.,255. / 255.0)
            else:
                p = np.empty(0)
                p = np.append(p, pArr[i,j,range(start,end)])
                
                tClim = climatology(t, startYear, calendar) - 273.15
                pClim = climatology(p, startYear,calendar) * 86400 * [31,fDaysMean,31,30,31,30,31,31,30,31,30,31]
                
                clim = Climate(fDaysMean,hemisphere[j],tClim,pClim)
                kp = Koppen(fDaysMean)
                    
                #time1 = timeit.default_timer()
                data = testColors[kp.makeZones(clim)]
                #time2 = timeit.default_timer()
                
                for index, value in enumerate(data):
                    zonesList[i][j][index]= value / 255.
                 
                #totalTime += time2-time1
                
    return zonesList             

# -------------------------------------

testColors = {
        "Af":(0.,0.,255.),
        "Am":(0.,120.,255.),
        "Aw":(70.,170.,250.),
        "BWh":(255.,0.,0.),
        "BWk":(255.,150.,150.),
        "BSh":(245.,165.,0.),
        "BSk":(255.,220.,100.),
        "Csa":(255.,255.,0.),
        "Csb":(198.,199.,0.),
        "Csc":(150.,150.,0.),
        "Cwa":(150.,255.,150.),
        "Cwb":(99.,199.,99.),
        "Cwc":(50.,150.,50.),
        "Cfa":(200.,255.,80.),
        "Cfb":(102.,255.,51.),
        "Cfc":(50.,199.,0.),
        "Dsa":(255.,0.,254.),
        "Dsb":(198.,0.,199.),
        "Dsc":(150.,50.,149.),
        "Dsd":(150.,100.,149.),
        "Dwa":(171.,177.,255.),
        "Dwb":(90.,199.,219.),
        "Dwc":(76.,81.,181.),
        "Dwd":(50.,0.,135.),
        "Dfa":(0.,255.,255.),
        "Dfb":(56.,199.,255.),
        "Dfc":(0.,126.,125.),
        "Dfd":(0.,69.,94.),
        "ET": (178.,178.,178.),
        "EF": (104.,104.,104.),
    }

def printGraph(startYear, endYear, referenceYear, tempFile, precipFile, calendar="Gregorian"):
    dataTest = [[[0 for k in range(3)] for j in range(180)] for i in range(360)]

    fig = plt.figure(num=None, figsize=(12, 16))
    
    data = netcdfToKoppen(startYear,endYear,referenceYear,tempFile,precipFile,calendar)
    dataFlip = list(map(list,zip(*data)))
    m=Basemap(projection='cyl',lat_ts=10,llcrnrlon=0,
               urcrnrlon=360,llcrnrlat=-90,urcrnrlat=90,
               resolution='c')
    
    m.drawcoastlines()
    
    plt.imshow(dataFlip,interpolation='nearest', origin='lower', extent=[0,360,-90,90])

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
    
    
    