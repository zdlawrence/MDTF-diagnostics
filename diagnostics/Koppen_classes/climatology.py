import os
import collections
import datetime
import netCDF4 as nc
import numpy as np

class Climatology(object):
    def __init__(self, var_names, date_ranges, common_axes, dtype=np.float64, 
        do_monthly=True, do_annual=True):
        """Allocate blank arrays to hold all data. Do this so we only have to 
        have complete timeseries for a single in memory at once.
        """
        self.var_names = var_names
        self.dtype = dtype
        self.time = common_axes.variables['time']
        self.calendar = self.time.calendar
        _latlon_dims = [
            common_axes.variables['lat'].size,
            common_axes.variables['lon'].size
        ]

        if not isinstance(date_ranges[0], collections.Iterable):
            date_ranges = [date_ranges]
        self.date_ranges = date_ranges
        self.multi_range = (len(date_ranges) > 1)
        _range_dims = [len(date_ranges), len(var_names)]

        if do_annual:
            self.annual = np.ma.masked_all(
                tuple(_range_dims + _latlon_dims), dtype=dtype
            )
        else:
            self.annual = None
        if do_monthly:
            self.monthly = np.ma.masked_all(
                tuple(_range_dims + [12] + _latlon_dims), dtype=dtype
            )
        else:
            self.monthly = None

    def get_year_inds(self, date_range):
        """Find indices in a netcdf date axis (of form "days since <ref date>")
        corresponding to start and end (inclusive) of a range of years.
        """
        assert date_range[1] >= date_range[0]
        # search instead of index math just to be sure
        dt = datetime.datetime(date_range[0], 1, 1, 0, 0, 0)
        nc_num = nc.date2num(dt, self.time.units, calendar=self.calendar)
        i_start = np.searchsorted(self.time, nc_num, side='left')
        
        dt = datetime.datetime(date_range[1], 12, 31, 0, 0, 0)
        nc_num = nc.date2num(dt, self.time.units, calendar=self.calendar)
        i_end = np.searchsorted(self.time, nc_num, side='right')
        
        assert len(self.time[i_start:i_end]) \
            == (date_range[1] - date_range[0] + 1)*12
        return (i_start, i_end)

    def day_weights(self, date_range):
        """Given an (inclusive) range of years, output a numpy array of days per 
        month, handling all calendars recognized by CF conventions.
        Dimensions are (# of years x 12).
        """
        # http://cfconventions.org/Data/cf-conventions/cf-conventions-1.8/cf-conventions.html#calendar
        def _is_leap(year):
            if self.calendar in ('noleap', 'no_leap', '365day', '365_day'):
                return False
            elif self.calendar in ('allleap', 'all_leap', '366day', '366_day'):
                return True

            year = int(year)
            is_julian_leap = (year % 4 == 0)
            if self.calendar == 'julian':
                return is_julian_leap
            is_gregorian_leap = (year % 4 == 0 and year % 100 != 0) \
                or (year % 400 == 0)
            if self.calendar in ('proleptic_gregorian', 'prolepticgregorian'):
                return is_gregorian_leap
            elif self.calendar in ('gregorian', 'standard'):
                if year > 1582:
                    return is_gregorian_leap
                else:
                    return is_julian_leap
            else:
                raise NotImplementedError(
                    "Unsupported calendar '{}'".format(self.calendar)
                )
        
        def _do_one_year(year):
            if self.calendar in ('360day', '360_day'):
                return [30] * 12
            if _is_leap(year):
                feb_days = 29
            else:
                feb_days = 28
            return [31, feb_days, 31, 30, 31, 30,
                    31,       31, 30, 31, 30, 31]
        
        return np.array(
            [_do_one_year(yr) for yr in range(date_range[0], date_range[1] + 1)],
            dtype=self.dtype
        )

    def monthly_climatology(self, x, days_per_month, i_start=None, i_end=None):
        """Given 1D monthly timeseries x and 2D array of days per month returned
        by day_weights(), return 1D vector of monthly averages for years in input 
        specified by indices, or all years if these aren't specified.

        Eg: if date range is 2000-2002, x should have 3*12 = 36 entries 
        (= averages for respective months). Output[0] will be average of x over
        {Jan '00, Jan '01, Jan '02}, etc.
        """
        xx = x.view()
        if i_start:
            xx = xx[i_start, i_end]
        # shape of -1 means "as many rows as needed"
        x_by_month = xx.reshape((-1, 12), order='C')
        return np.average(x_by_month, weights=days_per_month, axis=0)

    def annual_climatology(self, x, days_per_month, i_start=None, i_end=None):
        """Given 1D monthly timeseries x and 1D array of days per month returned 
        by flattening day_weights(), return annual average for years in input 
        specified by indices, or all years if these aren't specified.

        Eg: if date range is 2000-2002, x should have 3*12 = 36 entries 
        (= averages for respective months). Output will be average of x over
        entire period.
        """
        xx = x.view()
        if i_start:
            xx = xx[i_start, i_end]
        return np.average(xx, weights=days_per_month)

    def make_climatologies(self, var):
        """Driver script to assemble climatologies for any number of variables
        provided on common axes (passed as a dict through 'axes'.) 'arrs' is a list
        of numpy arrays (assumed to be (time x lat x lon)) to compute climatologies 
        for. 
        """
        j = self.var_names.index(var.name)
        assert j # is not empty; name was found
        for i, date_rng in enumerate(self.date_ranges):
            t_start, t_end = self.get_year_inds(date_rng)
            day_wts = self.day_weights(date_rng)
            # hard-coded 0 below because we apply along time axis of var
            if self.monthly:
                self.monthly[i, j, :,:,:] = np.apply_along_axis(
                    self.monthly_climatology, 0, var, day_wts, t_start, t_end
                )
            if self.annual:
                day_wts.reshape(-1, order='C') # synonym for flatten
                self.annual[i, j, :,:] = np.apply_along_axis(
                    self.annual_climatology, 0, var, day_wts, t_start, t_end
                )
            
