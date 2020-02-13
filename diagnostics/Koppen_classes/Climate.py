'''
Created on Sep 25, 2019

@author: Diyor.Zakirov, Raymond.Menzel
'''

class Climate(object):
    
    def __init__(self, daysInFebruary, hemisphere, temperature, precipitation):
        self.daysInFebruary = daysInFebruary
        self.hemisphere = hemisphere
        self.temperature = temperature
        self.precipitation = precipitation
        self.temperature_max = max(temperature)
        self.temperature_min = min(temperature)
        self.precip_max = {}
        self.precip_min = {}
        self.precip_total = {}

        winter = {"Northern" : [0, 1, 2], "Southern" : [6, 7, 8]}
        spring = {"Northern" : [3, 4, 5], "Southern" : [9, 10, 11]}
        summer = {"Northern" : [6, 7, 8], "Southern" : [0, 1, 2]}
        names = ("winter", "spring", "summer")
        seasons = (winter, spring, summer)
        for name, season in zip(names, seasons):
            s = season[hemisphere]
            self.precip_max[name] = max(self.precipitation[s[0]:s[-1]+1])
            self.precip_min[name] = min(self.precipitation[s[0]:s[-1]+1])
            self.precip_total[name] = sum(self.precipitation[s[0]:s[-1]+1])