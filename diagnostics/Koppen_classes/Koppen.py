import collections
import enum
import numpy as np

KoppenTuple = collections.namedtuple(
    'KoppenTuple', 
    ['major','minor_p','minor_t']
)
KoppenLabels = [
    KoppenTuple(
        major = {'Tropical': 'A'},
        minor_p = {
            'Rainforest': 'f',
            'Monsoon': 'm',
            'SavannaDryWinter': 'w',
            'SavannaDrySummer': 's'
        },
        minor_t = {'None': ''}
    ),
    KoppenTuple(
        major = {'Arid': 'B'},
        minor_p = {
            'Desert': 'W',
            'Steppe': 'S'
        },
        minor_t = {
            'Hot': 'h',
            'Cold': 'k'
        }
    ),
    KoppenTuple(
        major = {'Temperate': 'C'},
        minor_p = {
            'DrySummer': 's',
            'DryWinter': 'w',
            'WithoutDrySeason': 'f'
        },
        minor_t = {
            'HotSummer': 'a',
            'WarmSummer': 'b',
            'ColdSummer': 'c'
        }
    ),
    KoppenTuple(
        major = {'Continental': 'D'},
        minor_p = {
            'DrySummer': 's',
            'DryWinter': 'w',
            'WithoutDrySeason': 'f'
        },
        minor_t = {
            'HotSummer': 'a',
            'WarmSummer': 'b',
            'ColdSummer': 'c',
            'VeryColdWinter': 'd'
        }
    ),
    KoppenTuple(
        major = {'Polar': 'E'},
        minor_p = {'None': ''},
        minor_t = {
            'Tundra': 'T',
            'EternalFrost': 'F'
        }
    )
]
# sort above alphabetically by letter to ensure code always maps to same integer
KoppenLabels = [
    KoppenTuple(
        major=kc.major,
        minor_p=collections.OrderedDict(
            sorted(kc.minor_p.items(), key=lambda t: t[1])
        ),
        minor_t=collections.OrderedDict(
            sorted(kc.minor_t.items(), key=lambda t: t[1])
        )
    ) for kc in KoppenLabels
]
# Generate Enum mapping integers used to label output to corresponding 
# Koppen codes (eg "Csc").
KoppenClass = enum.IntEnum(
    'KoppenClass', 
    [
        maj + p + t \
        for label in KoppenLabels for maj in label.major.values() \
        for p in label.minor_p.values() for t in label.minor_t.values()
    ],
    start=1
)

class Koppen(object):
    """Parent class containing common logic for different conventions used for
    Koppen classes. Can't be used directly; instead use one of the child classes
    below corresponding to a specific convention.
    """
    P_thresh_cutoff = None

    def __init__(self, tas, pr, summer_is_apr_sep=None):
        """Compute intermediate variables used for Koppen classification.

        Args:
            tas: namedtuple of monthly, seasonal, annual climatologies for tas.
            pr: namedtuple of monthly, seasonal, annual climatologies for pr.
            summer_is_apr_sep: (boolean numpy Array, optional) Dimensions must be
                equal to spatial dimensions of tas/pr. If provided, take "summer"
                to be Apr-Sep in the locations where True (otherwise "summer" is
                Oct-Mar). If ommitted, define "summer" to be the season with
                highest mean tas (out of {apr-sep, oct-mar}.)
        """
        month_axis = 0
        apr_sep_mask = [True if (m >= 4 and m <= 9) else False for m in range(1,13)]
        oct_mar_mask = [not m for m in apr_sep_mask]
        assert sum(apr_sep_mask) == 6
        assert sum(oct_mar_mask) == 6

        if not summer_is_apr_sep:
            summer_is_apr_sep = (tas.apr_sep >= tas.oct_mar)
        else:
            assert summer_is_apr_sep.shape == pr.annual.shape

        self.P_ann = pr.annual
        self.T_ann = tas.annual
        self.T_max = np.ma.max(tas.monthly, axis=month_axis)
        self.T_min = np.ma.min(tas.monthly, axis=month_axis)
        t_temp = np.ma.filled(tas.monthly, fill_value = 0.0) # only used in next line
        self.n_warm = np.count_nonzero(t_temp > 10.0, axis=month_axis)
        self.P_min = np.ma.min(pr.monthly, axis=month_axis)

        # can't use 'where' kwarg on maskedarrays; workaround
        p_temp = np.ma.take(pr.monthly, apr_sep_mask, axis=month_axis)
        P_AS_min = np.ma.min(p_temp, axis=month_axis)
        P_AS_max = np.ma.max(p_temp, axis=month_axis)
        p_temp = np.ma.take(pr.monthly, oct_mar_mask, axis=month_axis)
        P_OM_min = np.ma.min(p_temp, axis=month_axis)
        P_OM_max = np.ma.max(p_temp, axis=month_axis)
        self.P_smin = np.ma.where(summer_is_apr_sep, P_AS_min, P_OM_min)
        self.P_wmin = np.ma.where(summer_is_apr_sep, P_OM_min, P_AS_min)
        self.P_smax = np.ma.where(summer_is_apr_sep, P_AS_max, P_OM_max)
        self.P_wmax = np.ma.where(summer_is_apr_sep, P_OM_max, P_AS_max)
        
        self.P_thresh = self.p_thresh(pr, summer_is_apr_sep)
        self.input_mask = np.logical_or(
            np.ma.getmaskarray(tas.annual),
            np.ma.getmaskarray(pr.annual)
        )
        self.latlon_shape = pr.annual.shape
        self.all_true = np.full(self.latlon_shape, True, dtype=np.bool)

    def p_thresh(self, pr, summer_is_apr_sep):
        p_summer = np.ma.where(summer_is_apr_sep, pr.apr_sep, pr.oct_mar)
        p_winter = np.ma.where(summer_is_apr_sep, pr.oct_mar, pr.apr_sep)
        ans = 2.0 * self.T_ann + 14.0 # default value
        ans = np.ma.where(
            p_summer >= self.P_thresh_cutoff * pr.annual, 
            2.0 * self.T_ann + 28.0, 
            ans
        )
        ans = np.ma.where(
            p_winter >= self.P_thresh_cutoff * pr.annual, 
            2.0 * self.T_ann, 
            ans
        )
        return ans

    @staticmethod
    def _and(*conditions, and_not=None):
        if and_not is not None:
            return np.ma.all(list(conditions) + [np.logical_not(and_not)], axis=0)
        else:
            return np.ma.all(conditions, axis=0)

    @staticmethod
    def _not(*conditions):
        return np.logical_not(np.ma.any(conditions, axis=0))

    def major(self, d):
        # implemented in child classes since conventions define this differently
        raise NotImplementedError() 

    def p_Tropical(self, d):
        # implemented in child classes since conventions define this differently
        raise NotImplementedError() 

    def p_Arid(self, d):
        d['AridDesert'] = (self.P_ann < 5.0 * self.P_thresh)
        d['AridSteppe'] = self._not(d['AridDesert'])

    def p_Temperate(self, d):
        # implemented in child classes since conventions define this differently
        raise NotImplementedError() 

    def p_Continental(self, d):
        # same as Temperate in all conventions
        d['ContinentalDrySummer'] = d['TemperateDrySummer']
        d['ContinentalDryWinter'] = d['TemperateDryWinter']
        d['ContinentalWithoutDrySeason'] = d['TemperateWithoutDrySeason']

    def p_Polar(self, d):
        d['PolarNone'] = self.all_true

    def t_Tropical(self, d):
        d['TropicalNone'] = self.all_true

    def t_Arid(self, d):
        d['AridHot'] = (self.T_ann >= 18.0)
        d['AridCold'] = self._not(d['AridHot'])

    def t_Temperate(self, d):
        d['TemperateHotSummer'] = d['ContinentalHotSummer']
        d['TemperateWarmSummer'] = d['ContinentalWarmSummer']
        d['TemperateColdSummer'] = np.logical_or(
            d['ContinentalColdSummer'], 
            d['ContinentalVeryColdWinter']
        )

    def t_Continental(self, d):
        d['ContinentalHotSummer'] = (self.T_max >= 22.0)
        d['ContinentalWarmSummer'] = self._and(
            self.n_warm >= 4.0, 
            and_not=d['ContinentalHotSummer']
        )
        not_mask = self._not(d['ContinentalHotSummer'], d['ContinentalWarmSummer'])
        d['ContinentalVeryColdWinter'] = self._and(
            self.T_min < -38.0, 
            not_mask
        )
        d['ContinentalColdSummer'] = self._not(
            d['ContinentalHotSummer'], 
            d['ContinentalWarmSummer'],
            d['ContinentalVeryColdWinter']
        )

    def t_Polar(self, d):
        d['PolarTundra'] = (self.T_max >= 0.0)
        d['PolarEternalFrost'] = self._not(d['PolarTundra'])

    def make_classes(self):
        """Compute Koppen classes.
        
        Returns:
            numpy Array of dtype ubyte and dimensions equal to spatial dimensions 
            of tas/pr. Each entry labels the Koppen class for that cell according 
            to the values in the KoppenClass enum (eg. KoppenClass['Csc'].value). 
            Entries of 0 correspond to masked, missing or invalid data.
        """
        classes = np.zeros(self.latlon_shape, dtype=np.ubyte) # maps onto netcdf UBYTE
        d = dict()
        # split each criterion into its own function, to make it clear where
        # conventions (child classes) differ.
        self.major(d)
        self.p_Tropical(d)
        self.p_Arid(d)
        self.p_Temperate(d)
        self.p_Polar(d)
        self.t_Tropical(d)
        self.t_Arid(d)
        self.t_Continental(d)
        self.t_Polar(d)

        self.p_Continental(d)
        self.t_Temperate(d)
        for label in KoppenLabels:
            for maj, code in label.major.items():
                for p_name, p_code in label.minor_p.items():
                    for t_name, t_code in label.minor_t.items():
                        mask = self._and(d[maj], d[maj+p_name], d[maj+t_name])
                        classes[mask] = KoppenClass[code + p_code + t_code].value
        classes[self.input_mask] = 0
        return classes


class Koppen_Kottek06(Koppen):
    """Koppen classification as used in Kottek et al., "World Map of the 
    Koppen-Geiger climate classification updated", Meteorologische Zeitschrift. 
    15 (3): 259–263 (2006); https://doi.org/10.1127%2F0941-2948%2F2006%2F0130. 
    """
    P_thresh_cutoff = 2.0/3.0

    def major(self, d):
        d['Arid'] = (self.P_ann < 10.0 * self.P_thresh)
        d['Polar'] = self._and(
            self.T_max <= 10.0, 
            and_not = d['Arid']
        )
        not_arid_or_polar = self._not(d['Arid'], d['Polar'])
        d['Tropical'] = self._and(
            self.T_min >= 18.0, 
            not_arid_or_polar
        )
        d['Temperate'] = self._and(
            self.T_min > -3.0, 
            self.T_min < 18.0, 
            not_arid_or_polar
        )
        d['Continental'] = self._and(
            self.T_min <= -3.0, 
            not_arid_or_polar
        )

    def p_Tropical(self, d):
        d['TropicalMonsoon'] = (self.P_min >= 100.0 - self.P_ann / 25.0)
        not_monsoon = self._not(d['TropicalMonsoon'])
        d['TropicalRainforest'] = self._and(
            self.P_min >= 60.0, 
            not_monsoon
        )
        d['TropicalSavannaDryWinter'] = self._and(
            self.P_smin < 60.0, 
            not_monsoon
        )
        d['TropicalSavannaDrySummer'] = self._and(
            self.P_wmin < 60.0,
            not_monsoon
        )

    def p_Temperate(self, d):
        d['TemperateDrySummer'] = self._and(
            self.P_smin < self.P_wmin, 
            self.P_smin < 40.0, 
            self.P_smin < self.P_wmax / 3.0
        )
        d['TemperateDryWinter'] = self._and(
            self.P_wmin < self.P_smin, 
            self.P_wmin < self.P_smax / 10.0
        )
        d['TemperateWithoutDrySeason'] = self._not(
            d['TemperateDrySummer'], 
            d['TemperateDryWinter']
        )

class Koppen_Peel07(Koppen):
    """Koppen classification as used in Peel, Finlayson & McMahon, "Updated 
    world map of the Koppen–Geiger climate classification," Hydrol. Earth Syst. 
    Sci. 11 (5): 1633–1644 (2007); https://doi.org/10.5194%2Fhess-11-1633-2007. 
    """
    P_thresh_cutoff = 0.7

    def major(self, d):
        d['Arid'] = (self.P_ann < 10.0 * self.P_thresh)
        not_arid = self._not(d['Arid'])
        d['Tropical'] = self._and(
            self.T_min >= 18.0, 
            not_arid
        )
        d['Temperate'] = self._and(
            self.T_max > 10.0, 
            self.T_min < 18.0, 
            self.T_min >= 0.0, 
            not_arid
        )
        d['Continental'] = self._and(
            self.T_max > 10.0, 
            self.T_min < 0.0, 
            not_arid
        )
        d['Polar'] = self._and(
            self.T_max <= 10.0, 
            not_arid
        )

    def p_Tropical(self, d):
        d['TropicalRainforest'] = (self.P_min >= 60.0)
        p_compare = (self.P_min >= 100.0 - self.P_ann / 25.0)
        d['TropicalMonsoon'] = self._and(p_compare, and_not=d['TropicalRainforest'])
        d['TropicalSavannaDryWinter'] = self._and(self._not(p_compare), and_not=d['TropicalRainforest'])
        d['TropicalSavannaDrySummer'] = self._not(self.all_true) # category not used

    def p_Temperate(self, d):
        d['TemperateDrySummer'] = self._and(
            self.P_smin < 40.0, 
            self.P_smin < self.P_wmax / 3.0
        )
        d['TemperateDryWinter'] = (self.P_wmin < self.P_smax / 10.0)
        d['TemperateWithoutDrySeason'] = self._not(
            d['TemperateDrySummer'], 
            d['TemperateDryWinter']
        )

# class Koppen_GFDL(Koppen):
#     P_thresh_cutoff = 0.7

#     def major(self, d):
#         # if tMin > 18.0:
#         #     return Match.Tropical
#         # elif tMin > -3.0:
#         #     return Match.Temperate
#         # elif clim.temperature_max < 10.0:
#         #     return Match.Polar
#         # else:
#         #     return Match.Continental
#         d['Arid'] = (self.P_ann < 10.0 * self.P_thresh)
#         not_arid = self._not(d['Arid'])
#         d['Tropical'] = self._and(
#             self.T_min > 18.0,
#             not_arid
#         )
#         d['Temparate'] = self._and(
#             self.T_min <= 18.0,
#             self.T_min > -3.0,
#             not_arid
#         )
#         d['Polar'] = self._and(
#             self.T_min <= -3.0,
#             self.T_max < 10.0,
#             not_arid
#         )
#         d['Continental'] = self._and(
#             self.T_min <= -3.0,
#             self.T_max >= 10.0,
#             not_arid 
#         )
    
#     def minor(self, clim):
#         numWarmMonths = clim.temperature[np.where(clim.temperature > 10.0)].size
#         if numWarmMonths > 4:
#             if clim.temperature_max > 22.0:
#                 return Match.Hot
#             else:
#                 return Match.Warm
#         elif clim.temperature_min < -38.0:
#             return Match.Severe
#         else:
#             return Match.Cold

#     def precip(self, clim):
#         summerMax = clim.precip_max["summer"]
#         winterMin = clim.precip_min["winter"]
#         if summerMax > (10.0*winterMin):
#             return Match.Monsoon
#         summerMin = clim.precip_min["summer"]
#         winterMax = clim.precip_max["winter"]
#         if (winterMax > 3.0*summerMin) and (summerMin < 30.0):
#             return Match.Mediterranean
#         else:
#             return Match.YearRound

#     def arid(self, clim):
#         annual_mean = self.annualMeanOf(clim.temperature)
#         total_precip = clim.precipitation.sum()
#         precipRatio = (clim.precip_total["spring"] + clim.precip_total["summer"])/total_precip
#         if precipRatio >= 0.7:
#             precipOffset = 10.0*annual_mean + 140.0
#         elif precipRatio >= 0.3:
#             precipOffset = 10.0*annual_mean + 70.0
#         else:
#             precipOffset = 10.0*annual_mean
#         if total_precip < precipOffset:
#             return Match.Arid
#         elif (total_precip >= precipOffset) and (total_precip <= 2.0*precipOffset):
#             return Match.SemiArid
#         else:
#             return Match.Moist

#     def matchArid(self, clim):
#         arid = self.arid(clim)
#         major = self.major(clim)
#         if arid == Match.Arid and (major == Match.Temperate or major == Match.Tropical):
#             return "BWh"
#         elif arid == Match.Arid and (major == Match.Continental or major == Match.Polar):
#             return "BWk"
#         elif arid == Match.SemiArid and (major == Match.Tropical or major == Match.Temperate):
#             return "BSh"
#         elif arid == Match.SemiArid and(major == Match.Continental or major == Match.Polar):
#             return "BSk"
#         return None

#     def matchTropical(self, clim):
#         val = clim.precipitation.min() >= 100.0 - (clim.precipitation.sum()*0.04)
#         for i in clim.precipitation:
#             if i < 60.0:
#                 if val:
#                     return "Am"
#                 else:
#                     return "Aw"
#             else:
#                 return "Af"

#     def matchContinental(self,clim):
#         first_letter = {Match.Temperate : "C",
#                         Match.Continental : "D"}
#         second_letter = {Match.Monsoon : "w",
#                          Match.Mediterranean : "s",
#                          Match.YearRound : "f"}
#         last_letter = {Match.Hot : "a",
#                        Match.Warm : "b",
#                        Match.Cold : "c",
#                        Match.Severe : "d"}
#         return first_letter[self.major(clim)] + second_letter[self.precip(clim)] + \
#                last_letter[self.minor(clim)]

#     def makeZones(self,clim):
#         s = self.matchArid(clim)
#         if s is not None:
#             return s
#         funcs = {Match.Tropical : self.matchTropical,
#                  Match.Temperate : self.matchContinental,
#                  Match.Continental : self.matchContinental,
#                  Match.Polar : self.matchPolar}
#         return funcs[self.major(clim)](clim)
