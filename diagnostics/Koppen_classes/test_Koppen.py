'''
Created on Oct 2, 2019

@author: Diyor.Zakirov
'''
from Koppen import Koppen,Hemisphere
from Climate import Climate
import numpy as np


if __name__ == '__main__':
    kp = Koppen()        
    
    myAf = Climate(28.25, Hemisphere.NORTHERN,
                   np.array([20.0,21.0,23.0,21.0,23.0,26.0,20.0,21.0,19.0,22.0,23.0,21.0]),
                   np.array([72.4,83.32,85.38,79.53,81.79,82.01,82.11,81.94,79.88,75.89,74.56,72.43]))
    
    myAm = Climate(28.25, Hemisphere.NORTHERN,
                   np.array([20.0,21.0,23.0,21.0,23.0,26.0,20.0,21.0,19.0,22.0,23.0,21.0]),
                   np.array([55.4, 83.32, 95.38, 121.53, 161.79, 162.01, 162.11, 161.94, 129.88, 105.89, 84.56, 62.43]))
    
    myAw = Climate(28.25, Hemisphere.NORTHERN,
                   np.array([20.0,   21.0,   23.0,   21.0,    23.0,    26.0,    20.0,    21.0,   19.0,   22.0,  23.0,  21.0]),
                   np.array([2.4, 13.32, 25.38, 49.53, 121.79, 182.01, 193.11, 181.94, 49.88, 35.89, 4.56, 2.43]))
    
    
    myBSh = Climate(28.25, Hemisphere.NORTHERN,
                   np.array([-2.0,    1.0,    3.0,   10.0,   13.0,   16.0,   20.0,   21.0,   19.0,   12.0,    3.0,    1.0]),
                   np.array([12.4, 13.32, 15.38, 19.53, 21.79, 22.01, 22.11, 21.94, 19.88, 15.89, 14.56, 12.43]))
    
    myBSk = Climate(28.25, Hemisphere.NORTHERN,
                   np.array([-4.0,    1.0,    3.0,   10.0,   13.0,   16.0,   20.0,   21.0,   19.0,   12.0,    3.0,    1.0]),
                   np.array([12.4, 13.32, 15.38, 19.53, 21.79, 22.01, 22.11, 21.94, 19.88, 15.89, 14.56, 12.43]))
    
    myBWh = Climate(28.25, Hemisphere.NORTHERN,
                   np.array([ -2.0,1.0,3.0,10.0,13.0,16.0,20.0,21.0,19.0,12.0,3.0,1.0]),
                   np.array([2.4, 3.32, 5.38, 9.53, 11.79, 12.01, 12.11, 9.94, 5.88, 1.89, 1.56, 1.43]))
    
    myBWk = Climate(28.25, Hemisphere.NORTHERN,
                   np.array([ -4.0,1.0,3.0,10.0,13.0,16.0,20.0,21.0,19.0,12.0,3.0, 1.0]),
                   np.array( [2.4, 3.32, 5.38, 9.53, 11.79, 12.01, 12.11, 9.94, 5.88, 1.89, 1.56, 1.43]))
    
    
    myCfa = Climate(28.25, Hemisphere.NORTHERN,
                   np.array([  -2.0,     1.0,    3.0,   10.0,   13.0,  16.0,  20.0,  22.1,   19.0,   12.0,    3.0,    1.0]),
                   np.array([50.4, 44.32, 45.38, 51.53, 62.79, 78.01, 79.11, 78.94, 69.88, 61.89, 54.56, 53.43]))
    
    myCfb = Climate(28.25, Hemisphere.NORTHERN,
                   np.array([  -2.0,     1.0,    3.0,   10.0,   13.0,  16.0,  20.0,  20.1,   19.0,   12.0,    3.0,    1.0]),
                   np.array( [50.4, 44.32, 45.38, 51.53, 62.79, 78.01, 79.11, 78.94, 69.88, 61.89, 54.56, 53.43]))
    
    myCfc = Climate(28.25, Hemisphere.NORTHERN,
                   np.array([  -2.0,     1.0,    3.0,    5.0,    7.3,   9.0,  12.0,  11.0,    9.5,    6.0,    2.0,    1.0]),
                   np.array([50.4, 44.32, 45.38, 51.53, 62.79, 78.01, 79.11, 78.94, 69.88, 61.89, 54.56, 53.43]))
    
    myCwa = Climate(28.25, Hemisphere.NORTHERN,
                   np.array([ -2.0,   1.0,    3.0,   10.0,   13.0,   16.0,   20.0,    22.1,   19.0,   12.0,    3.0,   1.0]),
                   np.array([9.11, 8.94, 19.88, 25.89, 34.56, 79.43, 120.4, 110.32, 45.38, 19.53, 10.79, 8.01]))
    
    myCwb = Climate(28.25, Hemisphere.NORTHERN,
                   np.array([ -2.0,   1.0,    3.0,   10.0,   13.0,   16.0,   20.0,    20.1,   19.0,   12.0,    3.0,    1.0]),
                   np.array([9.11, 8.94, 19.88, 25.89, 34.56, 79.43, 120.4, 110.32, 45.38, 19.53, 10.79, 8.01]))
    
    myCwc = Climate(28.25, Hemisphere.NORTHERN,
                   np.array([ -2.0,   1.0,    3.0,    5.0,    7.3,    9.0,   12.0,    11.0,    9.5,    6.0,    2.0,   1.0]),
                   np.array([9.11, 8.94, 19.88, 25.89, 34.56, 79.43, 120.4, 110.32, 45.38, 19.53, 10.79, 8.01]))
    
    myCsa = Climate(28.25, Hemisphere.NORTHERN,
                   np.array([  -2.0,     1.0,    3.0,   10.0,   13.0,  16.0,  20.0,  22.1,   19.0,   12.0,    3.0,    1.0]),
                   np.array([120.4, 110.32, 45.38, 19.53, 10.79, 8.01, 9.11, 8.94, 19.88, 25.89, 34.56, 79.43]))
    
    myCsb = Climate(28.25, Hemisphere.NORTHERN,
                   np.array([  -2.0,     1.0,    3.0,   10.0,   13.0,  16.0,  20.0,  20.0,   19.0,   12.0,    3.0,    1.0]),
                   np.array([120.4, 110.32, 45.38, 19.53, 10.79, 8.01, 9.11, 8.94, 19.88, 25.89, 34.56, 79.43]))
    
    myCsc = Climate(28.25, Hemisphere.NORTHERN,
                   np.array([  -2.0,     1.0,    3.0,    5.0,    7.3,   9.0,  12.0,  11.0,    9.5,    6.0,    2.0,    1.0]),
                   np.array([120.4, 110.32, 45.38, 19.53, 10.79, 8.01, 9.11, 8.94, 19.88, 25.89, 34.56, 79.43]))
    
    
    myDfa = Climate(28.25,Hemisphere.NORTHERN,
                    np.array([  -4.0,     1.0,    3.0,   10.0,   13.0,  16.0,  20.0,  22.1,   19.0,   12.0,    3.0,    1.0]),
                    np.array([50.4, 44.32, 45.38, 51.53, 62.79, 78.01, 79.11, 78.94, 69.88, 61.89, 54.56, 53.43]))
    
    myDfb = Climate(28.25,Hemisphere.NORTHERN,
                    np.array([ -4.0,     1.0,    3.0,   10.0,   13.0,  16.0,  20.0,  20.1,   19.0,   12.0,    3.0,    1.0]),
                    np.array([50.4, 44.32, 45.38, 51.53, 62.79, 78.01, 79.11, 78.94, 69.88, 61.89, 54.56, 53.43]))
    
    myDfc = Climate(28.25,Hemisphere.NORTHERN,
                    np.array([  -4.0,     1.0,    3.0,    5.0,    7.3,   9.0,  12.0,  11.0,    9.5,    6.0,    2.0,    1.0]),
                    np.array([50.4, 44.32, 45.38, 51.53, 62.79, 78.01, 79.11, 78.94, 69.88, 61.89, 54.56, 53.43]))
    
    myDfd = Climate(28.25,Hemisphere.NORTHERN,
                    np.array([-40.0,    -35.0,  -33.0,  -10.0,   -8.0,  -5.0,   2.0,   11.0,   -3.0,  -12.0,  -20.0,  -29.0]),
                    np.array([50.4, 44.32, 45.38, 51.53, 62.79, 78.01, 79.11, 78.94, 69.88, 61.89, 54.56, 53.43]))
    
    myDwa = Climate(28.25,Hemisphere.NORTHERN,
                    np.array([ -4.0,   1.0,    3.0,   10.0,   13.0,   16.0,   20.0,    22.1,   19.0,   12.0,    3.0,   1.0]),
                    np.array([9.11, 8.94, 19.88, 25.89, 34.56, 79.43, 120.4, 110.32, 45.38, 19.53, 10.79, 8.01]))
    
    myDwb = Climate(28.25,Hemisphere.NORTHERN,
                    np.array([ -4.0,   1.0,    3.0,   10.0,   13.0,   16.0,   20.0,    20.1,   19.0,   12.0,    3.0,    1.0]),
                    np.array([9.11, 8.94, 19.88, 25.89, 34.56, 79.43, 120.4, 110.32, 45.38, 19.53, 10.79, 8.01]))
    
    myDwc = Climate(28.25,Hemisphere.NORTHERN,
                    np.array([ -4.0,   1.0,    3.0,    5.0,    7.3,    9.0,   12.0,    11.0,    9.5,    6.0,    2.0,   1.0]),
                    np.array([9.11, 8.94, 19.88, 25.89, 34.56, 79.43, 120.4, 110.32, 45.38, 19.53, 10.79, 8.01]))
    
    myDwd = Climate(28.25,Hemisphere.NORTHERN,
                    np.array([-40.0,    -35.0,  -33.0,  -10.0,   -8.0,  -5.0,   2.0,   11.0,   -3.0,  -12.0,  -20.0,  -29.0]),
                    np.array([9.11, 8.94, 19.88, 25.89, 34.56, 79.43, 120.4, 110.32, 45.38, 19.53, 10.79, 8.01]))
    
    myDsa = Climate(28.25,Hemisphere.NORTHERN,
                    np.array([  -4.0,     1.0,    3.0,   10.0,   13.0,  16.0,  20.0,  22.1,   19.0,   12.0,    3.0,    1.0]),
                    np.array([120.4, 110.32, 45.38, 19.53, 10.79, 8.01, 9.11, 8.94, 19.88, 25.89, 34.56, 79.43]))
    
    myDsb = Climate(28.25,Hemisphere.NORTHERN,
                    np.array([  -4.0,     1.0,    3.0,   10.0,   13.0,  16.0,  20.0,  20.0,   19.0,   12.0,    3.0,    1.0]),
                    np.array([120.4, 110.32, 45.38, 19.53, 10.79, 8.01, 9.11, 8.94, 19.88, 25.89, 34.56, 79.43]))
    
    myDsc = Climate(28.25,Hemisphere.NORTHERN,
                    np.array([  -4.0,     1.0,    3.0,    5.0,    7.3,   9.0,  12.0,  11.0,    9.5,    6.0,    2.0,    1.0]),
                    np.array([120.4, 110.32, 45.38, 19.53, 10.79, 8.01, 9.11, 8.94, 19.88, 25.89, 34.56, 79.43]))
    
    myDsd = Climate(28.25,Hemisphere.NORTHERN,
                    np.array([-40.0,    -35.0,  -33.0,  -10.0,   -8.0,  -5.0,   2.0,   11.0,   -3.0,  -12.0,  -20.0,  -29.0]),
                    np.array([120.4, 110.32, 45.38, 19.53, 10.79, 8.01, 9.11, 8.94, 19.88, 25.89, 34.56, 79.43]))
    
    
    myET = Climate(28.25, Hemisphere.NORTHERN,
                   np.array([-40.0,    -35.0,  -33.0,  -10.0,   -8.0,  -5.0,   2.0,   1.0,   -3.0,  -12.0,  -20.0,  -29.0]),
                   np.array([120.4, 110.32, 45.38, 19.53, 10.79, 8.01, 9.11, 8.94, 19.88, 25.89, 34.56, 79.43]))
    
    myEF = Climate(28.25, Hemisphere.NORTHERN,
                   np.array([-40.0,    -35.0,  -33.0,  -10.0,   -8.0,  -5.0,  -2.0,  -1.0,   -3.0,  -12.0,  -20.0,  -29.0]),
                   np.array([120.4, 110.32, 45.38, 19.53, 10.79, 8.01, 9.11, 8.94, 19.88, 25.89, 34.56, 79.43]))

    
    print(kp.makeZones(myAf))
    print(kp.makeZones(myAm))
    print(kp.makeZones(myAw))
    print(kp.makeZones(myBWh))
    print(kp.makeZones(myBWk))
    print(kp.makeZones(myBSh))
    print(kp.makeZones(myBSk))
    print(kp.makeZones(myCsa))
    print(kp.makeZones(myCsb))
    print(kp.makeZones(myCsc))
    print(kp.makeZones(myCwa))
    print(kp.makeZones(myCwb))
    print(kp.makeZones(myCwc))
    print(kp.makeZones(myCfa))
    print(kp.makeZones(myCfb))
    print(kp.makeZones(myCfc))
    print(kp.makeZones(myDsa))
    print(kp.makeZones(myDsb))
    print(kp.makeZones(myDsc))
    print(kp.makeZones(myDsd))
    print(kp.makeZones(myDwa))
    print(kp.makeZones(myDwb))
    print(kp.makeZones(myDwc))
    print(kp.makeZones(myDwd))
    print(kp.makeZones(myDfa))
    print(kp.makeZones(myDfb))
    print(kp.makeZones(myDfc))
    print(kp.makeZones(myDfd))
    print(kp.makeZones(myET))
    print(kp.makeZones(myEF))

    

    
    
    