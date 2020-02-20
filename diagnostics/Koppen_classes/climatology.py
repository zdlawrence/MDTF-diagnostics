import os
import collections
import datetime
import netCDF4 as nc
import numpy as np

class Climatology(object):
    def __init__(self, n_vars, common_axes, dtype=np.float64):
        """Allocate blank arrays to hold all data. Do this so we only have to 
        have complete timeseries for a single in memory at once.
        """
        self.dtype = dtype
        self.time = common_axes.variables['time']
        self.n_lat = common_axes.variables['lat'].size
        self.n_lon = common_axes.variables['lon'].size

        if not isinstance(date_ranges[0], collections.Iterable):
            date_ranges = [date_ranges]
        self.date_ranges = date_ranges

        self.annual = np.ma.masked_all(
            (len(date_ranges), len(arrs), self.n_lat, self.n_lon),
            dtype=dtype
        )
        self.monthly = np.ma.masked_all(
            (len(date_ranges), len(arrs), 12, self.n_lat, self.n_lon),
            dtype=dtype
        )

    def get_year_inds(self, date_range, time_var):
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

    def day_weights(self, date_range, calendar='standard', dtype=np.float64):
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

    def monthly_climatology(self, x, days_per_month, i_start=None, i_end=None):
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

    def make_climatologies(self, date_ranges, arrs, axes):
        """Driver script to assemble monthly climatologies for any number of variables
        provided on common axes (passed as a dict through 'axes'.) 'arrs' is a list
        of numpy arrays (assumed to be (time x lat x lon)) to compute climatologies 
        for. 
        """

        for i, date_rng in enumerate(date_ranges):
            i_start, i_end = get_year_inds(date_rng, axes['time'])
            day_wts = day_weights(date_rng, calendar=axes['time'].calendar, dtype=dtype)
            for j, var in enumerate(arrs):
                # hard-coded 0 because we apply along time axis of var
                clims[i, j, :,:,:] = np.apply_along_axis(
                    monthly_climatology, 0, var, day_wts, i_start, i_end
                )
        return clims
