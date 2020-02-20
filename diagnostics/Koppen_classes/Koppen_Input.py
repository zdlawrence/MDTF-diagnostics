'''
Created on Oct 23, 2019

@author: Diyor.Zakirov
'''
import os
import collections
import datetime
import netCDF4 as nc
import numpy as np
from Koppen import Koppen
from Climate import Climate

#temperature = Dataset("/home/Diyor.Zakirov/tasLut.nc", "r")
#precipitation = Dataset("/home/Diyor.Zakirov/pr.nc", "r")

zonesList = [[[0 for i in range(3)] for x in range(180)] for y in range(360)]

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

def get_year_inds(date_range, time_var):
    """Find indices in a netcdf date axis (of form "days since <ref date>")
    corresponding to start and end (inclusive) of a range of years.
    """
    assert date_range[1] >= date_range[0]
    # search instead of index math just to be sure
    dt = datetime.datetime(date_range[0], 1, 1, 0, 0, 0)
    nc_num = nc.date2num(dt, time_var.units, calendar=time_var.calendar)
    i_start = np.searchsorted(time_var, nc_num, side='left')
    
    dt = datetime.datetime(date_range[1], 12, 31, 0, 0, 0)
    nc_num = nc.date2num(dt, time_var.units, calendar=time_var.calendar)
    i_end = np.searchsorted(time_var, nc_num, side='right')
    
    assert len(time_var[i_start:i_end]) == (date_range[1] - date_range[0] + 1)*12
    return (i_start, i_end)

def day_weights(date_range, calendar='standard', dtype=np.float64):
    """Given an (inclusive) range of years, output a numpy array of days per 
    month, handling all calendars recognized by CF conventions.
    Dimensions are (# of years x 12).
    """
    # http://cfconventions.org/Data/cf-conventions/cf-conventions-1.8/cf-conventions.html#calendar
    def _is_leap(year):
        if calendar in ('noleap', 'no_leap', '365day', '365_day'):
            return False
        elif calendar in ('allleap', 'all_leap', '366day', '366_day'):
            return True

        year = int(year)
        is_julian_leap = (year % 4 == 0)
        if calendar == 'julian':
            return is_julian_leap
        is_gregorian_leap = (year % 4 == 0 and year % 100 != 0) or (year % 400 == 0)
        if calendar in ('proleptic_gregorian', 'prolepticgregorian'):
            return is_gregorian_leap
        elif calendar in ('gregorian', 'standard'):
            if year > 1582:
                return is_gregorian_leap
            else:
                return is_julian_leap
        else:
            raise NotImplementedError('Unsupported calendar {}'.format(calendar))
    
    def _do_one_year(year):
        if calendar in ('360day', '360_day'):
            return [30] * 12
        if _is_leap(year):
            feb_days = 29
        else:
            feb_days = 28
        return [31, feb_days, 31, 30, 31, 30,
                31,       31, 30, 31, 30, 31]
    
    return np.array(
        [_do_one_year(yr) for yr in range(date_range[0], date_range[1] + 1)],
        dtype=dtype
    )

def monthly_climatology(x, days_per_month, i_start=None, i_end=None):
    """Given 1D monthly timeseries x and 2D array of days per month returned by
    day_weights(), return 1D vector of annual and monthly averages for all 
    years in input.

    Pack annual and monthly data together for efficiency. 

    Eg: if date range is 2000-2002, x should have 3*12 = 36 entries 
    (= averages for respective months). Output[0] will be average of x over entire
    entire period, output[1] will be average over {Jan '00, Jan '01, Jan '02}, etc.
    """
    xx = x.view()
    if i_start:
        xx = xx[i_start, i_end]
    # shape of -1 means "as many rows as needed"
    x_by_month = xx.reshape((-1, 12), order='C')
    mean = np.average(x_by_month, weights=days_per_month)
    monthly_means = np.average(x_by_month, weights=days_per_month, axis=0)
    # 0'th element is annual mean, 1-12 are now monthly means
    return np.insert(monthly_means, 0, mean)

def make_climatologies(date_ranges, arrs, axes):
    """Driver script to assemble monthly climatologies for any number of variables
    provided on common axes (passed as a dict through 'axes'.) 'arrs' is a list
    of numpy arrays (assumed to be (time x lat x lon)) to compute climatologies 
    for. 
    """
    if not isinstance(date_ranges[0], collections.Iterable):
        date_ranges = [date_ranges]
    dtype = np.find_common_type([var.dtype for var in arrs])
    # hard-coded 13 because monthly_climatology() gives monthly avgs + annual avg
    clims = np.ma.masked_all(
        (len(date_ranges), len(arrs), 13, len(axes['lat']), len(axes['lon'])),
        dtype=dtype
    )
    for i, date_rng in enumerate(date_ranges):
        i_start, i_end = get_year_inds(date_rng, axes['time'])
        day_wts = day_weights(date_rng, calendar=axes['time'].calendar, dtype=dtype)
        for j, var in enumerate(arrs):
            # hard-coded 0 because we apply along time axis of var
            clims[i, j, :,:,:] = np.apply_along_axis(
                monthly_climatology, 0, var, day_wts, i_start, i_end
            )
    return clims
    
# -------------------------------------

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
    
if __name__ == '__main__':
    pass
    #start = timeit.default_timer()
    #pool = mp.Pool(mp.cpu_count())
    #cProfile.run('netcdfToKoppen(1920,1950,1850)')
    #netcdfToKoppen(1920,1950,1850)
    #pool.close()
    #stop = timeit.default_timer()
    #print("Whole time: ", stop - start)
    
    
    