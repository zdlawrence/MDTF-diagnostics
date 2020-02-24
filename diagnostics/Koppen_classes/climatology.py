import os
import collections
import datetime
import netCDF4 as nc
import numpy as np

class Climatology(object):
    def __init__(self, var, time_var, date_range, do_monthly=True, do_annual=True):
        """Compute monthly and annual climatologies for a single variable.

        Args:
            var: NetCDF4 `Variable` to compute averages of.
            time_var: NetCDF4 `Variable` corresponding to the 'time' dimension of 
                `var`.
            date_range: Two-element list of [start year, end year]. Intervals 
                are inclusive.
            do_monthly: True to compute monthly climatologies.
            do_annual: True to compute annual climatologies.
        """
        assert date_range[1] >= date_range[0]
        self.start_yr = date_range[0]
        self.end_yr = date_range[1]
        self.dtype = var.dtype
        try:
            t_start, t_end = self.get_year_inds(time_var)
            t_slice = slice(t_start, t_end)
            day_wts = self.day_weights(time_var)
        except Exception as exc:
            print('Error in parsing time axis for {}:'.format(var.name))
            print(exc)
            raise exc
        try:
            t_axis_pos = var.dimensions.index(time_var.name)
            assert t_axis_pos
        except AssertionError:
            print('Error in dimensions of {}:'.format(var.name))
            print('{}: {} -> {}'.format(var.name, var.dimensions, var.shape))
            raise

        if do_monthly:
            self.monthly = np.apply_along_axis(
                self.monthly_climatology, t_axis_pos, var, day_wts, t_slice
            )
        else:
            self.monthly = None

        if do_annual:
            day_wts = day_wts.flatten(order='C')
            self.annual = np.apply_along_axis(
                self.annual_climatology, t_axis_pos, var, day_wts, t_slice
            )
        else:
            self.annual = None

    def get_year_inds(self, time_var):
        """Find indices in a netcdf date axis (of form "days since <ref date>")
        corresponding to start and end (inclusive) of a range of years.
        """
        units = time_var.units
        calendar = time_var.calendar.lower()
        expected_len = 12 * (self.end_yr - self.start_yr + 1)
        # search instead of index math just to be sure
        dt = datetime.datetime(self.start_yr, 1, 1, 0, 0, 0)
        nc_num = nc.date2num(dt, units, calendar=calendar)
        i_start = np.searchsorted(time_var, nc_num, side='left')
        
        dt = datetime.datetime(self.end_yr, 12, 31, 0, 0, 0)
        nc_num = nc.date2num(dt, units, calendar=calendar)
        i_end = np.searchsorted(time_var, nc_num, side='right')
        
        if len(time_var[i_start:i_end]) < expected_len:
            start_dt = nc.num2date(time_var[0], units, calendar=calendar)
            end_dt = nc.num2date(time_var[-1], units, calendar=calendar)
            raise ValueError(("File time axis ({}-{}) doesn't cover requested "
                "date range ({}-{})").format(start_dt, end_dt, self.start_yr, self.end_yr))
        elif len(time_var[i_start:i_end]) > expected_len:
            raise ValueError("File time axis not at monthly frequency.")
        return (i_start, i_end)

    def day_weights(self, time_var):
        """Given an (inclusive) range of years, output a numpy array of days per 
        month, handling all calendars recognized by CF conventions.
        Dimensions are (# of years x 12).
        """
        # http://cfconventions.org/Data/cf-conventions/cf-conventions-1.8/cf-conventions.html#calendar
        def _is_leap(year, calendar):
            if calendar in ('noleap', 'no_leap', '365day', '365_day'):
                return False
            elif calendar in ('allleap', 'all_leap', '366day', '366_day'):
                return True

            is_julian_leap = (year % 4 == 0)
            if calendar == 'julian':
                return is_julian_leap
            is_gregorian_leap = (year % 4 == 0 and year % 100 != 0) \
                or (year % 400 == 0)
            if calendar in ('proleptic_gregorian', 'prolepticgregorian'):
                return is_gregorian_leap
            elif calendar in ('gregorian', 'standard'):
                if year > 1582:
                    return is_gregorian_leap
                else:
                    return is_julian_leap
            else:
                raise NotImplementedError(
                    "Unsupported calendar '{}'".format(calendar)
                )
        
        def _do_one_year(year, calendar):
            if calendar in ('360day', '360_day'):
                return [30] * 12
            if _is_leap(year, calendar):
                feb_days = 29
            else:
                feb_days = 28
            return [31, feb_days, 31, 30, 31, 30,
                    31,       31, 30, 31, 30, 31]
        
        cal = time_var.calendar.lower()
        return np.array(
            [_do_one_year(yr, cal) for yr in range(self.start_yr, self.end_yr + 1)],
            dtype=self.dtype
        )

    def monthly_climatology(self, x, days_per_month, slice=None):
        """Given 1D monthly timeseries x and 2D array of days per month returned
        by day_weights(), return 1D vector of monthly averages for years in input 
        specified by indices, or all years if these aren't specified.

        Eg: if date range is 2000-2002, x should have 3*12 = 36 entries 
        (= averages for respective months). Output[0] will be average of x over
        {Jan '00, Jan '01, Jan '02}, etc.
        """
        xx = x.view()
        if slice is not None:
            xx = xx[slice]
        # shape of -1 means "as many rows as needed"
        x_by_month = xx.reshape((-1, 12), order='C')
        return np.ma.average(x_by_month, weights=days_per_month, axis=0)

    def annual_climatology(self, x, days_per_month, slice=None):
        """Given 1D monthly timeseries x and 1D array of days per month returned 
        by flattening day_weights(), return annual average for years in input 
        specified by indices, or all years if these aren't specified.

        Eg: if date range is 2000-2002, x should have 3*12 = 36 entries 
        (= averages for respective months). Output will be average of x over
        entire period.
        """
        xx = x.view()
        if slice is not None:
            xx = xx[slice]
        return np.ma.average(xx, weights=days_per_month)
