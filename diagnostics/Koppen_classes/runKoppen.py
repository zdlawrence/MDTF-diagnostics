'''
Created on Oct 2, 2019

@author: Diyor.Zakirov
'''

from Koppen_Out import printGraph
import argparse


if __name__ == '__main__':
    parser = argparse.ArgumentParser(prog="Koppen")
    parser.add_argument("startYear", help="Start year of your climate.", type=int)
    parser.add_argument("endYear", help="End year of your climate.", type=int)
    parser.add_argument("referenceYear", help='Reference year.', type=int)
    parser.add_argument("temperature", help="Full path to a temperature netCDF file.")
    parser.add_argument("precipitation", help="Full path to a precipitation netCDF file.")
    parser.add_argument("calendar", help="Calendar choice: Gregorian, Julian, 365.")
    args = parser.parse_args()
    
    printGraph(args.startYear, args.endYear, args.referenceYear, args.temperature, args.precipitation)
    
    
    