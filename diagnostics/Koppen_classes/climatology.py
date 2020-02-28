import collections
import datetime
import math
import netCDF4 as nc
import numpy as np

class Climatology(object):
    def __init__(self, date_range, ds, var_name, time_name='time', truncate=False):
        """Compute monthly and annual climatologies for a single variable.

        Args:
            date_range: Two-element list of [start year, end year]. Intervals 
                are inclusive.
            ds: NetCDF4 Dataset containing variable and its axes.
            var_name: Name of the variable.
            time_name: Name of the time axis.
        """
        self.truncate = truncate
        # don't store refs to var itself in object, to allow GC
        assert var_name in ds
        var = ds.variables[var_name]
        self.dtype = var.dtype
        self.var_dim = len(var.shape)

        # parse time axis info
        assert time_name in ds.variables
        time_var = ds.variables[time_name]
        self.t_units = time_var.units
        self.calendar = time_var.calendar.lower().replace(' ', '_')
        self.t_weights = self.get_t_weights(ds, time_name)
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
            self.start_ym, self.end_ym, self.trailing_ym = \
                self.get_date_range_ym(time_var, *date_range)
            self.start_y, self.start_m = self._from_ym(self.start_ym)
            self.end_y, self.end_m = self._from_ym(self.end_ym)
            self.lookup = self.get_date_range_indices(time_var)
        except (AssertionError, ValueError) as exc:
            print('Error in parsing time axis for {}:'.format(var.name))
            print(exc)
            raise exc

    def num2date(self, num):
        return nc.num2date(num, self.t_units, calendar=self.calendar)

    def date2num(self, dt):
        return nc.date2num(dt, self.t_units, calendar=self.calendar)

    @staticmethod
    def _to_ym(y, m):
        # combine year & month to monotonic count of months, simplifies math
        return 12 * y + m - 1

    @staticmethod
    def _from_ym(ym):
        # inverse of _to_ym
        y, m = divmod(ym, 12)
        return (y, m+1)

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
            return (29 if _is_leap(year, calendar) else 28)
        elif month in (1, 3, 5, 7, 8, 10, 12):
            return 31
        else:
            return 30

    def get_t_weights(self, ds, time_name):
        time_var = ds.variables[time_name]
        # check for axes that may have info we need
        var_names = {(s.lower().replace('_','')) : s for s in ds.variables.keys()}
        if 'averagedt' in var_names:
            ax = ds.variables[var_names['averagedt']]
            assert ax.shape == time_var.shape
            ax_copy = ax[:] # no copy() method for netCDF4 Variables
            return ax_copy
        if hasattr(time_var, 'bounds'):
            time_bnds = time_var.bounds
        else:
            time_bnds = time_name + '_bnds'
        if time_bnds in ds.variables:
            bnds_var = ds.variables[time_bnds]
            return np.diff(bnds_var, axis=bnds_var.shape.index(2))

        # didn't find info in Dataset, compute manually
        avg_timestep = np.average(np.diff(time_var))
        if avg_timestep < 8.0:
            # sub-monthly frequency
            # can't just return None for no weighting, since weights are time-sliced
            # could optimize for this case, though
            return np.ones(time_var.shape, dtype=self.dtype)
        elif avg_timestep < 32.0:
            # monthly frequency
            dts = [self.num2date(t) for t in time_var]
            yr_mons = [(dt.year, dt.month) for dt in dts]
            return np.array([
                    self.days_per_month(*ym, self.calendar) for ym in yr_mons
                ], dtype=self.dtype
            )
        else:
            raise ValueError('Data needs to be monthly or greater frequency.')

    def get_date_range_ym(self, time_var, range_start, range_end):
        def _parse_date(dt, default_month):
            y = (dt.year if hasattr(dt, 'year') else int(dt))
            m = (dt.month if hasattr(dt, 'month') else default_month)
            return self._to_ym(y, m)

        assert range_start <= range_end
        r_start_ym = _parse_date(range_start, 1)
        r_end_ym = _parse_date(range_end, 12)

        f_start_dt = self.num2date(time_var[0])
        f_end_dt = self.num2date(time_var[-1])
        f_start_ym = _parse_date(f_start_dt, 1)
        f_end_ym = _parse_date(f_end_dt, 12)
        if f_start_ym > r_start_ym:
            raise ValueError(("Variable time axis ({}-{}) starts after requested "
                "date range start {}.").format(f_start_dt, f_end_dt, self._from_ym(r_start_ym))
            )
        if f_end_ym < r_end_ym:
            raise ValueError(("Variable time axis ({}-{}) ends before requested "
                "date range end {}.").format(f_start_dt, f_end_dt, self._from_ym(r_end_ym))
            )
        return r_start_ym, r_end_ym, min(f_end_ym, r_end_ym+12)

    def get_start_index(self, time_var, start_yr, start_mon):
        start_dt = datetime.datetime(start_yr, start_mon, 1, 0, 0, 0)
        return np.searchsorted(time_var, self.date2num(start_dt), side='left')

    def get_end_index(self, time_var, end_yr, end_mon):
        end_day = self.days_per_month(end_yr, end_mon, self.calendar)
        end_dt = datetime.datetime(end_yr, end_mon, end_day, 23, 59, 59)
        return np.searchsorted(time_var, self.date2num(end_dt), side='right')

    def get_date_range_indices(self, time_var):
        lookup = np.zeros((self.trailing_ym - self.start_ym + 1, 2), dtype=np.intp)
        for ym in range(self.start_ym, self.trailing_ym):
            y, m = self._from_ym(ym)
            i = ym - self.start_ym
            lookup[i,0] = self.get_start_index(time_var, y, m)
            lookup[i,1] = self.get_end_index(time_var, y, m)
        return lookup

    # ---------------------------------------------------

    def _calc_season(self, var, season_start, duration, do_total=False):
        """Given same NetCDF4 Variable used to initialize object and a list of
        months in the season, return average of (average/total for the season) 
        over entire analysis period.
        """
        start_yms = [self._to_ym(y, season_start) \
            for y in range(self.start_y, self.end_y + 1)]
        end_yms = [ym + duration for ym in start_yms]

        if end_yms[0] < self.start_ym:
            # first season outside date range; start following year instead
            del start_yms[0]
            del end_yms[0]
        elif start_yms[0] < self.start_ym and self.start_ym < end_yms[0]:
            # start of date range is in middle of first season
            if self.truncate and not do_total:
                # truncate season to start of range
                start_yms[0] = self.start_ym
            else:
                # start following year
                del start_yms[0]
                del end_yms[0]
        else:
            pass # normal case, season starts after range

        if end_yms[-1] < self.end_ym:
            pass # normal case, season ends before range
        elif start_yms[-1] < self.end_ym and self.end_ym < end_yms[-1]:
            # end of date range is in middle of last season
            if self.truncate and not do_total:
                # truncate season to end of range
                end_yms[-1] = self.end_ym
            else:
                # stop previous year
                del start_yms[-1]
                del end_yms[-1]
        else:
            # date range ends before last season; stop with previous year's season
            del start_yms[-1]
            del end_yms[-1]

        assert len(start_yms) == len(end_yms)
        n_years = len(start_yms)
        t_slices = [slice(
                self.lookup[start_yms[i] - self.start_ym, 0],
                self.lookup[end_yms[i] - self.start_ym, 1]
            ) for i in range(n_years)]
        ans_slice = [slice(None)] * self.var_dim
        var_slice = [slice(None)] * self.var_dim
        dims = tuple([n_years] + self.latlon_dims)
        season_avgs = np.ma.zeros(dims, dtype=self.dtype)
        season_wts = np.zeros(dims, dtype=self.dtype)

        for i in range(n_years):
            # average over one season. No easy way to do this with numpy as we 
            # want to handle the case of daily data, where season lengths may 
            # differ year to year.
            ans_slice[0] = slice(i)
            var_slice[self.t_axis_pos] = t_slices[i]
            season_avgs[ans_slice], season_wts[ans_slice] = np.ma.average(
                var[var_slice], weights=self.t_weights[t_slices[i]], 
                axis=self.t_axis_pos, returned=True
            )
        if do_total:
            # numpy doesn't have tensordot for masked arrays. Instead of doing
            # bookkeeping for mask explicitly, just multiply average by sum of
            # weights to get total.
            season_avgs *= season_wts
        return np.ma.average(season_avgs, weights=season_wts, axis=0)

    def _calc_seasons(self, var, month_labels, do_total=False):
        """Given same NetCDF4 Variable used to initialize object and a list of
        tuples defining seasons, return average for each season over entire 
        analysis period.

        The first axis of the answer will always correspond to the entries in
        month_labels. For example, with month_labels = [(12,2), (6,8)],
        ans[0, :,:,...] will be the DJF average and ans[1, :,:,...] will be the
        JJA average.
        """
        dims = tuple([len(month_labels)] + self.latlon_dims)
        ans_slice = [slice(None)] * len(dims)
        ans = np.ma.masked_all(dims, dtype=self.dtype)
        # Small number of seasons, so no need to optimize this loop
        for idx, label in enumerate(month_labels):
            ans_slice[0] = slice(idx)
            duration = (label[1] - label[0]) % 12
            ans[ans_slice] = \
                self._calc_season(var, label[0], duration, do_total=do_total)
        return ans

    def mean_monthly(self, var):
        """Mean of var for each month, averaged over all years in period. """
        return self._calc_seasons(var, [(m,m) for m in range(1,13)], do_total=False)

    def total_monthly(self, var):
        """Total of var for each month, averaged over all years in period. """
        return self._calc_seasons(var, [(m,m) for m in range(1,13)], do_total=True)

    def mean_annual(self, var):
        """Mean of var for each year, averaged over all years in period. """
        return self._calc_seasons(var, [(1,12)], do_total=False)

    def total_annual(self, var):
        """Total of var for each year, averaged over all years in period. """
        return self._calc_seasons(var, [(1,12)], do_total=True)
