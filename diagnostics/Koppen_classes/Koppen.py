'''
Created on Oct 2, 2019

@author: Diyor.Zakirov, Raymond.Menzel
'''
import numpy as np
from enum import Enum

class Match(Enum):
    Cold = 1
    Warm = 2
    Hot = 3
    Severe = 4
    Tropical = 5
    Temperate = 6
    Polar = 7
    Continental = 8
    Monsoon = 9
    Mediterranean = 10
    YearRound = 11
    Arid = 12
    SemiArid = 13
    Moist = 14
    Desert = 15


class Koppen(object):
    def __init__(self, daysInFebruary):
        self.daysInMonths = np.array([31.0, daysInFebruary, 31.0, 30.0, 31.0, 30.0,
                                      31.0, 31.0, 30.0, 31.0, 30.0, 31.0])
        self.total_days = self.daysInMonths.sum()

    def annualMeanOf(self, vals):
        return sum(vals[:]*self.daysInMonths[:])/self.total_days

    def major(self, clim):
        tMin = clim.temperature_min
        if tMin > 18.0:
            return Match.Tropical
        elif tMin > -3.0:
            return Match.Temperate
        elif clim.temperature_max < 10.0:
            return Match.Polar
        else:
            return Match.Continental

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

    def matchPolar(self, clim):
        if clim.temperature_max < 0.0:
            return "EF"
        else:
            return "ET"

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
        
                
    
    
                 
        
    
                
            
            
        
    
    
    
    
    
    
    
    
    
    
    
      
        
            
        
        
    
    
        
        