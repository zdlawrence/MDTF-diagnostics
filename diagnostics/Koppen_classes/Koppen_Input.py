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

class NCCopyMixin(object):
    """Collection of methods to copy items from one netcdf Dataset to another,
    since this isn't provided directly by the netCDF4 module.
    Based on discussion in https://stackoverflow.com/a/49592545.
    """
    @staticmethod
    def copy_variable(var_name, src_ds, dst_ds):
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

    @staticmethod
    def copy_dimension(dim_name, src_ds, dst_ds):
        assert dim_name in src_ds.dimensions
        dim = src_ds.dimensions[dim_name]
        if dim_name not in dst_ds.dimensions:
            dst_ds.createDimension(
                dim_name, (dim.size if not dim.isunlimited() else None)
            )
        else:
            # netcdf library doesn't implement deleting dimensions, so no overwrite
            assert dim.size == dst_ds.dimensions[dim_name].size

    @staticmethod
    def copy_axes(src_ds, dst_ds, bounds=True):
        for dim_name in src_ds.dimensions:
            NCCopyMixin.copy_dimension(dim_name, src_ds, dst_ds)
            if dim_name in src_ds.variables:
                NCCopyMixin.copy_variable(dim_name, src_ds, dst_ds)

        if not bounds:
            return
        bounds_vars = [v for v in src_ds.variables if v.lower().endswith('_bnds')]
        for var_name in bounds_vars:
            NCCopyMixin.copy_variable(var_name, src_ds, dst_ds)

    @staticmethod
    def copy_dataset(src_ds, dst_ds,
        copy_attrs=True, dimensions=None, variables=None, exclude_variables=None):
        def _coerce_to_iter(x):
            return (x if isinstance(x, collections.Iterable) else [x])

        if dimensions is None:
            dimensions = src_ds.dimensions
        else:
            dimensions = _coerce_to_iter(dimensions)
        if variables is None:
            variables = src_ds.variables
        else:
            variables = _coerce_to_iter(variables)
        if exclude_variables is not None:
            exclude_variables = set(_coerce_to_iter(exclude_variables))
            variables = set(variables).difference(exclude_variables)

        # copy global attributes all at once via dictionary
        if copy_attrs:
            dst_ds.setncatts(src_ds.__dict__)
        for name in dimensions:
            NCCopyMixin.copy_dimension(name, src_ds, dst_ds)
        for name in variables:
            NCCopyMixin.copy_variable(name, src_ds, dst_ds)


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
    
    
    