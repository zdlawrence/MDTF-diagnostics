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

        # don't store refs to var itself in object, to allow GC
        self.dtype = var.dtype
        self.var_slice = [slice(None)] * len(var.shape)
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
            self.start_inds, self.end_inds = self.get_date_range_indices(date_range, time_var)
        except (AssertionError, ValueError) as exc:
            print('Error in parsing time axis for {}:'.format(var.name))
            print(exc)
            raise exc

        dts = [self.num2date(t) for t in time_var]
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
            return (29 if _is_leap(year, calendar) else 28)
        elif month in (1, 3, 5, 7, 8, 10, 12):
            return 31
        else:
            return 30

    def get_date_range_indices(self, date_range, time_var):
        def _parse_date(dt, default_month):
            yr = (dt.year if hasattr(dt, 'year') else int(dt))
            mon = (dt.month if hasattr(dt, 'month') else default_month)
            return (yr, mon)

        def _increment_month(yr, mon, delta_months):
            ym = (12* yr + mon - 1)
            y, m = divmod(ym + delta_months, 12)
            return (y, m+1)

        assert date_range[1] >= date_range[0]
        (start_yr, start_mon) = _parse_date(date_range[0], 1)
        (end_yr, end_mon) = _parse_date(date_range[1], 12)

        start_yms = [_increment_month(start_yr, start_mon, t) for t in range(12)]
        end_yms = [_increment_month(end_yr, end_mon, -t) for t in range(12)]
        return (
            [self.get_start_index(time_var, *ym) for ym in start_yms]
            [self.get_end_index(time_var, *ym) for ym in end_yms]
        )

    def get_start_index(self, time_var, start_yr, start_mon):
        start_dt = datetime.datetime(start_yr, start_mon, 1, 0, 0, 0)
        if time_var[0] > self.date2num(start_dt + self._half_step):
            raise ValueError(("Variable time axis ({}-{}) starts after requested "
                "date range start ({}).").format(
                    self.num2date(time_var[0]), self.num2date(time_var[-1]),
                    start_dt
            ))
        return np.searchsorted(time_var, self.date2num(start_dt), side='left')

    def get_end_index(self, time_var, end_yr, end_mon):
        end_day = self.days_per_month(end_yr, end_mon, self.calendar)
        end_dt = datetime.datetime(end_yr, end_mon, end_day, 23, 59, 59)
        if time_var[-1] < self.date2num(end_dt - self._half_step):
            raise ValueError(("Variable time axis ({}-{}) ends before requested "
                "date range end ({}).").format(
                    self.num2date(time_var[0]), self.num2date(time_var[-1]),
                    end_dt
            ))
        return np.searchsorted(time_var, self.date2num(end_dt), side='right')

    # ---------------------------------------------------

    def in_month_interval(m, m_start, m_end):
        if m_start < m_end:
            return (m_start <= m) and (m <= m_end)
        else: # eg DJF has m_start = 12, m_end = 2
            return (m_start <= m) or (m <= m_end)

    def _calc_mean_or_total(self, var, weights, do_total=False):
        """Given same NetCDF4 Variable used to initialize object, compute 
        weighted average or total over entire analysis period.
        """ 
        vv = var[self.var_slices]
        if do_total:
            # numpy doesn't have tensordot for masked arrays. Instead of doing
            # bookkeeping for mask explicitly, just multiply average by sum of
            # weights.
            avg, weight_sum = np.ma.average(
                vv, axis=self.t_axis_pos, weights=weights, returned=True
            )
            return avg * weight_sum
        else:
            # compute weighted mean
            return np.ma.average(
                vv, axis=self.t_axis_pos, weights=weights
            )

    def _calc_season(self, var, months_in_season, do_total=False):
        """Given same NetCDF4 Variable used to initialize object and a list of
        months in the season, return average for the season over entire 
        analysis period.
        """
        # zero out weights for non-selected months
        if isinstance(months_in_season, collections.Iterable) \
            and len(months_in_season) == 1:
            months_in_season = months_in_season[0]
        if not isinstance(months_in_season, collections.Iterable):
            # single month case: can broadcast __eq__ but not __contains__
            new_wts = np.where(self.months == months_in_season, self.day_weights, 0.0)
        else:
            # multiple months
            mask = [(m in months_in_season) for m in self.months]
            new_wts = np.where(mask, self.day_weights, 0.0)
        return self._calc_mean_or_total(var, new_wts, do_total=do_total)

    def _calc_seasons(self, var, month_labels, do_total=False):
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
            ans[tuple(ans_slice)] = self._calc_season(var, label, do_total=do_total)
        return ans

    def monthly_means(self, var):
        """Mean of var for each month, averaged over all years in period. """
        return self._calc_seasons(var, list(range(1,13)), do_total=False)

    def monthly_totals(self, var):
        """Total of var for each month, averaged over all years in period. """
        return self._calc_seasons(var, list(range(1,13)), do_total=True)

    def mean(self, var):
        """Mean of var over entire analysis period. """
        return self._calc_mean_or_total(var, self.day_weights, do_total=False)

    def total(self, var):
        """Total of var over entire analysis period. """
        return self._calc_mean_or_total(var, self.day_weights, do_total=True)
