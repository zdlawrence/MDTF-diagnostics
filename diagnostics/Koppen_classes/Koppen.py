'''
Created on Oct 2, 2019

@author: Diyor.Zakirov, Raymond.Menzel
'''
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
        minor_p=collections.OrderedDict(sorted(kc.minor_p.items(), key=lambda t: t[1])),
        minor_t=collections.OrderedDict(sorted(kc.minor_t.items(), key=lambda t: t[1]))
    ) for kc in KoppenLabels
]
KoppenMajor = enum.IntEnum(
    'KoppenMajor', 
    [list(label.major.keys())[0] for label in KoppenLabels], 
    start=0
)
KoppenMinorP = enum.IntEnum(
    'KoppenMinorP', 
    [list(label.major.keys())[0]+k \
        for label in KoppenLabels for k in label.minor_p.keys()],
    start=0
)
KoppenMinorT = enum.IntEnum(
    'KoppenMinorT', 
    [list(label.major.keys())[0]+k \
        for label in KoppenLabels for k in label.minor_t.keys()],
    start=0
)
KoppenClass = enum.IntEnum(
    'KoppenClass', 
    [list(label.major.keys())[0]+k \
        for label in KoppenLabels for k in label.minor_t.keys()],
    start=1
)

class Koppen(object):
    P_thresh_cutoff = None

    def __init__(self, tas, pr, summer_is_apr_sep=None):
        month_axis = 0
        apr_sep_mask = [True if (m >= 4 and m <= 9) else False for m in range(1,13)]
        oct_mar_mask = [not m for m in apr_sep_mask]
        assert sum(apr_sep_mask) == 6
        assert sum(oct_mar_mask) == 6

        if not summer_is_apr_sep:
            summer_is_apr_sep = np.asarray(tas.apr_sep >= tas.oct_mar)
        else:
            assert summer_is_apr_sep.shape == pr.annual.shape

        self.P_ann = pr.annual
        self.T_ann = tas.annual
        self.T_max = np.amax(tas.monthly, axis=month_axis)
        self.T_min = np.amin(tas.monthly, axis=month_axis)
        self.n_warm = np.asarray(tas.monthly > 10.0).count_nonzero(axis=month_axis)
        self.P_min = np.amin(pr.monthly, axis=month_axis)

        P_AS_min = np.amin(pr.monthly, axis=month_axis, where=apr_sep_mask)
        P_OM_min = np.amin(pr.monthly, axis=month_axis, where=oct_mar_mask)
        P_AS_max = np.amax(pr.monthly, axis=month_axis, where=apr_sep_mask)
        P_OM_max = np.amax(pr.monthly, axis=month_axis, where=oct_mar_mask)
        self.P_smin = np.where(summer_is_apr_sep, P_AS_min, P_OM_min)
        self.P_wmin = np.where(summer_is_apr_sep, P_OM_min, P_AS_min)
        self.P_smax = np.where(summer_is_apr_sep, P_AS_max, P_OM_max)
        self.P_wmax = np.where(summer_is_apr_sep, P_OM_max, P_AS_max)
        
        self.P_thresh = self.p_thresh(pr, summer_is_apr_sep)
        self.masks = dict()

    def p_thresh(self, pr, summer_is_apr_sep):
        P_s_frac = np.where(summer_is_apr_sep, pr.apr_sep, pr.oct_mar) / pr.annual
        P_w_frac = np.where(summer_is_apr_sep, pr.oct_mar, pr.apr_sep) / pr.annual
        s_weight = (1.0 - P_w_frac) / (P_s_frac - P_w_frac)
        return np.select([
                s_weight * P_s_frac >= self.P_thresh_cutoff, 
                (1.0 - s_weight) * P_w_frac >= self.P_thresh_cutoff, 
                True
            ],[
                2.0 * self.T_ann + 28.0, 
                2.0 * self.T_ann, 
                2.0 * self.T_ann + 14.0
            ]
        )

    @staticmethod
    def mask_and(*conditions):
        if len(conditions) == 2:
            return np.logical_and(*conditions)
        else:
            return np.all(conditions, axis=0)

    @staticmethod
    def mask_or(*conditions):
        if len(conditions) == 2:
            return np.logical_or(*conditions)
        else:
            return np.any(conditions, axis=0)

    @staticmethod
    def mask_and_not(not_mask, *conditions):
        return np.logical_and.reduce(conditions + [np.logical_not(not_mask)])

    def major(self):
        pass

    def p_Tropical(self):
        d = self.masks
        d['Af_'] = (self.P_min >= 60.0)
        p_compare = (self.P_min >= 100.0 - self.P_ann / 25.0)
        d['Am_'] = self.mask_and_not(d['Af_'], p_compare)
        d['Aw_'] = self.mask_and_not(d['Af_'], np.logical_not(p_compare))

    def p_Arid(self):
        d = self.masks
        d['BW_'] = (self.P_ann < 5.0 * self.P_thresh)
        d['BS_'] = np.logical_not(d['BW_'])

    def p_Temperate(self):
        pass

    def p_Continental(self):
        pass

    def p_Polar(self):
        pass

    def t_Tropical(self):
        pass

    def t_Arid(self):
        d = self.masks
        d['B_h'] = (self.T_ann >= 18.0)
        d['B_k'] = np.logical_not(d['B_h'])

    def t_Temperate(self):
        TODO
        pass

    def t_Continental(self):
        d = self.masks
        d['D_a'] = (self.T_max >= 22.0)
        d['D_b'] = self.mask_and_not(d['D_a'], self.n_warm >= 4.0)

    def t_Polar(self):
        self.masks['Et'] = np.where(self.T_max >= 0.0, T, F)

    def make_zones(self):
        for maj in KoppenLabels:
            for minor_p in maj.minor_p:
                for minor_t in maj.minor_t:
                    mask = self.mask_and(d[maj], d[minor_p], d[minor_t])
                    ans[mask] = to_int(maj, minor_p, minor_t)
        return ans


    def minor(self, clim):
        numWarmMonths = clim.temperature[np.where(clim.temperature > 10.0)].size
        if numWarmMonths > 4:
            if clim.temperature_max > 22.0:
                return Match.Hot
            else:
                return Match.Warm
        elif clim.temperature_min < -38.0:
            return Match.Severe
        else:
            return Match.Cold

    def precip(self, clim):
        summerMax = clim.precip_max["summer"]
        winterMin = clim.precip_min["winter"]
        if summerMax > (10.0*winterMin):
            return Match.Monsoon
        summerMin = clim.precip_min["summer"]
        winterMax = clim.precip_max["winter"]
        if (winterMax > 3.0*summerMin) and (summerMin < 30.0):
            return Match.Mediterranean
        else:
            return Match.YearRound

    def arid(self, clim):
        annual_mean = self.annualMeanOf(clim.temperature)
        total_precip = clim.precipitation.sum()
        precipRatio = (clim.precip_total["spring"] + clim.precip_total["summer"])/total_precip
        if precipRatio >= 0.7:
            precipOffset = 10.0*annual_mean + 140.0
        elif precipRatio >= 0.3:
            precipOffset = 10.0*annual_mean + 70.0
        else:
            precipOffset = 10.0*annual_mean
        if total_precip < precipOffset:
            return Match.Arid
        elif (total_precip >= precipOffset) and (total_precip <= 2.0*precipOffset):
            return Match.SemiArid
        else:
            return Match.Moist

    def matchArid(self, clim):
        arid = self.arid(clim)
        major = self.major(clim)
        if arid == Match.Arid and (major == Match.Temperate or major == Match.Tropical):
            return "BWh"
        elif arid == Match.Arid and (major == Match.Continental or major == Match.Polar):
            return "BWk"
        elif arid == Match.SemiArid and (major == Match.Tropical or major == Match.Temperate):
            return "BSh"
        elif arid == Match.SemiArid and(major == Match.Continental or major == Match.Polar):
            return "BSk"
        return None

    def matchTropical(self, clim):
        val = clim.precipitation.min() >= 100.0 - (clim.precipitation.sum()*0.04)
        for i in clim.precipitation:
            if i < 60.0:
                if val:
                    return "Am"
                else:
                    return "Aw"
            else:
                return "Af"

    def matchContinental(self,clim):
        first_letter = {Match.Temperate : "C",
                        Match.Continental : "D"}
        second_letter = {Match.Monsoon : "w",
                         Match.Mediterranean : "s",
                         Match.YearRound : "f"}
        last_letter = {Match.Hot : "a",
                       Match.Warm : "b",
                       Match.Cold : "c",
                       Match.Severe : "d"}
        return first_letter[self.major(clim)] + second_letter[self.precip(clim)] + \
               last_letter[self.minor(clim)]

    def makeZones(self,clim):
        s = self.matchArid(clim)
        if s is not None:
            return s
        funcs = {Match.Tropical : self.matchTropical,
                 Match.Temperate : self.matchContinental,
                 Match.Continental : self.matchContinental,
                 Match.Polar : self.matchPolar}
        return funcs[self.major(clim)](clim)


class Koppen_Kottek06(Koppen):
    P_thresh_cutoff = 2.0/3.0

    def major(self):
        a = dict()
        a['Arid'] = (self.P_ann < 10.0 * self.P_thresh)
        a['Polar'] = self.mask_and_not(a['Arid'], self.T_max <= 10.0)

        exception_mask = self.mask_or(a['Arid'], a['Polar'])
        a['Tropical'] = self.mask_and_not(exception_mask, self.T_min >= 18.0)
        a['Temparate'] = self.mask_and_not(exception_mask,
            self.T_min > -3.0, self.T_min < 18.0
        )
        a['Continental'] = self.mask_and_not(exception_mask,
            self.T_min <= -3.0
        )


class Koppen_Peel07(Koppen):
    P_thresh_cutoff = 0.7

    def major(self):
        a = dict()
        a['Arid'] = (self.P_ann < 10.0 * self.P_thresh)

        exception_mask = a['Arid']
        a['Tropical'] = self.mask_and_not(exception_mask, self.T_min >= 18.0)
        a['Temparate'] = self.mask_and_not(exception_mask,
            self.T_max > 10.0, self.T_min > 0, self.T_min < 18.0
        )
        a['Continental'] = self.mask_and_not(exception_mask,
            self.T_max > 10.0, self.T_min <= 0
        )
        a['Polar'] = self.mask_and_not(exception_mask, self.T_max <= 10.0)


class Koppen_GFDL(Koppen):
    P_thresh_cutoff = 0.7

    def major(self):
        # if tMin > 18.0:
        #     return Match.Tropical
        # elif tMin > -3.0:
        #     return Match.Temperate
        # elif clim.temperature_max < 10.0:
        #     return Match.Polar
        # else:
        #     return Match.Continental
        a = dict()
        a['Arid'] = (self.P_ann < 10.0 * self.P_thresh)
        exception_mask = a['Arid']

        a['Tropical'] = self.mask_and_not(exception_mask, self.T_min > 18.0)
        a['Temparate'] = self.mask_and_not(exception_mask,
            self.T_min > -3.0, self.T_min <= 18.0
        )
        a['Polar'] = self.mask_and_not(exception_mask,
                self.T_max < 10.0, self.T_min <= -3.0
        )
        a['Continental'] = self.mask_and_not(exception_mask,
            self.T_max >= 10.0, self.T_min <= -3.0
        )

    def minor(self, clim):
        numWarmMonths = clim.temperature[np.where(clim.temperature > 10.0)].size
        if numWarmMonths > 4:
            if clim.temperature_max > 22.0:
                return Match.Hot
            else:
                return Match.Warm
        elif clim.temperature_min < -38.0:
            return Match.Severe
        else:
            return Match.Cold
