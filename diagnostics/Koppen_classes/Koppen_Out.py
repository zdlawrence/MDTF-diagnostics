'''
Created on Oct 2, 2019

@author: Diyor.Zakirov
'''
from Koppen import Koppen
from Climate import Climate
import numpy as np 
from Koppen_Input import netcdfToKoppen
import matplotlib.pyplot as plt
from mpl_toolkits.basemap import Basemap

def printGraph(startYear, endYear, referenceYear, tempFile, precipFile, calendar="Gregorian"):
    dataTest = [[[0 for k in range(3)] for j in range(180)] for i in range(360)]

    fig = plt.figure(num=None, figsize=(12, 16))
    
    data = netcdfToKoppen(startYear,endYear,referenceYear,tempFile,precipFile,calendar)
    dataFlip = list(map(list,zip(*data)))
    m=Basemap(projection='cyl',lat_ts=10,llcrnrlon=0,
               urcrnrlon=360,llcrnrlat=-90,urcrnrlat=90,
               resolution='c')
    
    m.drawcoastlines()
    
    plt.imshow(dataFlip,interpolation='nearest', origin='lower', extent=[0,360,-90,90])

    plt.show()
