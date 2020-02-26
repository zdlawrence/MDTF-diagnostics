import collections
import datetime
import math
import netCDF4 as nc
import numpy as np

class Climatology(object):
    def __init__(self, var, time_var, date_range):
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
        # parse time axis info
        self.t_units = time_var.units
        self.calendar = time_var.calendar.lower().replace(' ', '_')
        avg_timestep = np.average(np.diff(time_var))
        if avg_timestep < 8.0:
            do_day_weights = False # sub-monthly
        elif avg_timestep < 32.0:
            do_day_weights = True # monthly frequency
        else:
            raise ValueError('Data needs to be monthly or greater frequency.')
        self._half_step = datetime.timedelta(days=math.ceil(avg_timestep / 2.0))

        self.dtype = var.dtype
        self.start_dt, self.end_dt = self._parse_input_dates(date_range)
        try:
            self.t_axis_pos = var.dimensions.index(time_var.name)
            self.latlon_dims = list(var.shape)
            del self.latlon_dims[self.t_axis_pos]
        except (AssertionError, ValueError) as exc:
            print('Error in dimensions of {}:'.format(var.name))
            print('{}: {} -> {}'.format(var.name, var.dimensions, var.shape))
            print(exc)
            raise exc
        try:
            n_dims = len(var.shape)
            t_slice = self.get_timeslice(time_var)
            self.var_slices = [slice(None)] * n_dims # no way to do this with np.take??
            self.var_slices[self.t_axis_pos] = t_slice
            # don't store refs to var itself in object, to allow GC
        except (AssertionError, ValueError) as exc:
            print('Error in parsing time axis for {}:'.format(var.name))
            print(exc)
            raise exc

        dts = [self.num2date(t) for t in time_var[t_slice]]
        self.months = np.array([dt.month for dt in dts], dtype=np.int8)
        if do_day_weights:
            yr_mons = [(dt.year, dt.month) for dt in dts]
            self.day_weights = np.array([
                    self.days_per_month(*ym, self.calendar) for ym in yr_mons
                ], dtype=self.dtype
            )
        else:
            self.day_weights = None

    def num2date(self, num):
        return nc.num2date(num, self.t_units, calendar=self.calendar)

    def date2num(self, dt):
        return nc.date2num(dt, self.t_units, calendar=self.calendar)

    @staticmethod
    def days_per_month(year, month, calendar):
        # http://cfconventions.org/Data/cf-conventions/cf-conventions-1.8/cf-conventions.html#calendar
        def _is_leap(year, calendar):
            if calendar in ('noleap', 'no_leap', '365day', '365_day'):
                return False
            elif calendar in ('allleap', 'all_leap', '366day', '366_day'):
                return True

            is_julian_leap = (year % 4 == 0)
            if calendar in ('julian', 'proleptic_julian', 'prolepticjulian'):
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
        
        assert month > 0 and month <= 12
        if calendar in ('360day', '360_day'):
            return 30
        if month == 2:
            if _is_leap(year, calendar):
                return 29
            else:
                return 28
        elif month in (1, 3, 5, 7, 8, 10, 12):
            return 31
        else:
            return 30

    def _parse_input_dates(self, date_range):
        def _parse_date(dt):
            if hasattr(dt, 'year'):
                yr = dt.year
            else:
                yr = int(dt)
            if hasattr(dt, 'month'):
                mon = dt.month
            else:
                mon = None
            return (yr, mon)

        assert date_range[1] >= date_range[0]
        (start_yr, start_mon) = _parse_date(date_range[0])
        if not start_mon:
            start_mon = 1
        (end_yr, end_mon) = _parse_date(date_range[1])
        if not end_mon:
            end_mon = 12
        end_day = self.days_per_month(end_yr, end_mon, self.calendar)
        return (
            datetime.datetime(start_yr, start_mon,       1, 0, 0, 0),
            datetime.datetime(  end_yr,   end_mon, end_day, 0, 0, 0)
        )

    def get_timeslice(self, time_var):
        """Find indices in a netcdf date axis (of form "days since <ref date>")
        corresponding to start and end (inclusive) of a range of years.
        """
        try:
            range_start_n2 = self.date2num(self.start_dt + self._half_step)
            assert range_start_n2 > time_var[0] # bounds check; caught below
            range_start_n = self.date2num(self.start_dt)
            i_start = np.searchsorted(time_var, range_start_n, side='left')

            range_end_n2 = self.date2num(self.end_dt - self._half_step)
            assert range_end_n2 < time_var[-1] # bounds check; caught below
            range_end_n = self.date2num(self.end_dt)
            i_end = np.searchsorted(time_var, range_end_n, side='right')
        except AssertionError:
            raise ValueError(("Variable time axis ({}-{}) doesn't cover requested "
                "date range ({}-{}).").format(
                    self.num2date(time_var[0]), self.num2date(time_var[-1]),
                    self.start_dt, self.end_dt
            ))
        return slice(i_start, i_end)

    def get_monthly(self, var):
        """Given same NetCDF4 Variable used to initialize object, return average
        for each month over entire analysis period.
        
        If var has dimensions (t x n_lat x n_lon), returned array will have
        dimensions (12 x n_lat x n_lon), regardless of which axis is the time
        axis.
        """
        vv = var[self.var_slices]
        dims = tuple([12] + self.latlon_dims)
        ans_slice = [slice(None)] * len(dims)
        ans = np.ma.masked_all(dims, dtype=self.dtype)
        # Small number of months, so no need to optimize this loop
        for m in range(1,13):
            new_wts = np.where(self.months == m, self.day_weights, 0.0)
            ans_slice[0] = slice(m)
            ans[tuple(ans_slice)] = np.ma.average(
                vv, axis=self.t_axis_pos, weights=new_wts
            )
        return ans

    def get_season(self, var, months_in_season):
        """Given same NetCDF4 Variable used to initialize object and a list of
        months in the season, return average for the season over entire 
        analysis period.
        """
        vv = var[self.var_slices]
        mask = [(m in months_in_season) for m in self.months]
        new_wts = np.where(mask, self.day_weights, 0.0)
        return np.ma.average(
            vv, axis=self.t_axis_pos, weights=new_wts
        )

    def get_seasons(self, var, month_labels):
        """Given same NetCDF4 Variable used to initialize object and a list of
        lists defining seasons, return average for each season over entire 
        analysis period.

        The first axis of the answer will always correspond to the entries in
        month_labels. For example, with month_labels = [(12,1,2), (6,7,8)],
        ans[0, :,:,...] will be the DJF average and ans[1, :,:,...] will be the
        JJA average.
        """
        dims = tuple([len(month_labels)] + self.latlon_dims)
        ans_slice = [slice(None)] * len(dims)
        ans = np.ma.masked_all(dims, dtype=self.dtype)
        # Small number of seasons, so no need to optimize this loop
        for idx, label in enumerate(month_labels):
            ans_slice[0] = slice(idx)
            ans[tuple(ans_slice)] = self.get_season(var, label)
        return ans

    def get_mean(self, var):
        """Given same NetCDF4 Variable used to initialize object, return average
        over entire analysis period.
        
        If var has dimensions (t x n_lat x n_lon), returned array will have
        dimensions (n_lat x n_lon) (true regardless of which axis is the time
        axis).
        """
        vv = var[self.var_slices] # should only be a view, not a copy
        return np.ma.average(
            vv, axis=self.t_axis_pos, weights=self.day_weights
        )
