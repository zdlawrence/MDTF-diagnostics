import os
import collections
import unittest
# import mock # define mock os.environ so we don't mess up real env vars
import netCDF4 as nc
import numpy as np
import Koppen


class TestKoppenClasses(unittest.TestCase):
    def _koppen_wrapper(self, expected_result, temp, precip):
        assert len(temp) == 12
        assert len(precip) == 12
        apr_sep_mask = [m <= 4 and m >= 9 for m in range(1,13)]
        oct_mar_mask = [m >= 10 or m <= 3 for m in range(1,13)]
        KoppenAverages = collections.namedtuple('KoppenAverages', 
            ['annual', 'apr_sep', 'oct_mar', 'monthly']
        )
        tas_months = np.expand_dims(np.expand_dims(np.ma.masked_array(temp),1),2)
        tas_clim = KoppenAverages(
            annual = np.ma.average(tas_months, axis=0),
            apr_sep = np.ma.average(tas_months[apr_sep_mask, Ellipsis], axis=0),
            oct_mar = np.ma.average(tas_months[oct_mar_mask, Ellipsis], axis=0),
            monthly = tas_months
        )
        pr_months = np.expand_dims(np.expand_dims(np.ma.masked_array(precip),1),2)
        pr_clim = KoppenAverages(
            annual = np.ma.sum(pr_months, axis=0),
            apr_sep = np.ma.sum(pr_months[apr_sep_mask, Ellipsis], axis=0),
            oct_mar = np.ma.sum(pr_months[oct_mar_mask, Ellipsis], axis=0),
            monthly = pr_months
        )
        n_hemisphere_mask = np.full((1,1), True, dtype=np.bool)
        koppen = Koppen.Koppen_GFDL(tas_clim, pr_clim, summer_is_apr_sep=n_hemisphere_mask)
        k_class = koppen.make_classes()
        self.assertEqual(k_class[1,1], Koppen.KoppenClass[expected_result].value)

    def test_Af(self):   
        self._koppen_wrapper(
            'Af',
            [20.0,21.0,23.0,21.0,23.0,26.0,20.0,21.0,19.0,22.0,23.0,21.0],
            [72.4,83.32,85.38,79.53,81.79,82.01,82.11,81.94,79.88,75.89,74.56,72.43],
        )

    def test_Am(self):   
        self._koppen_wrapper(
            'Am',
            [20.0,21.0,23.0,21.0,23.0,26.0,20.0,21.0,19.0,22.0,23.0,21.0],
            [55.4, 83.32, 95.38, 121.53, 161.79, 162.01, 162.11, 161.94, 129.88, 105.89, 84.56, 62.43]
        )        

    def test_Aw(self):   
        self._koppen_wrapper(
            'Aw',
            [20.0,   21.0,   23.0,   21.0,    23.0,    26.0,    20.0,    21.0,   19.0,   22.0,  23.0,  21.0],
            [2.4, 13.32, 25.38, 49.53, 121.79, 182.01, 193.11, 181.94, 49.88, 35.89, 4.56, 2.43]
        )

    def test_BSh(self):
        self._koppen_wrapper(
            'BSh',
            [-2.0,    1.0,    3.0,   10.0,   13.0,   16.0,   20.0,   21.0,   19.0,   12.0,    3.0,    1.0],
            [12.4, 13.32, 15.38, 19.53, 21.79, 22.01, 22.11, 21.94, 19.88, 15.89, 14.56, 12.43]
        )

    def test_BSk(self):
        self._koppen_wrapper(
            'BSk', 
            [-4.0,    1.0,    3.0,   10.0,   13.0,   16.0,   20.0,   21.0,   19.0,   12.0,    3.0,    1.0],
            [12.4, 13.32, 15.38, 19.53, 21.79, 22.01, 22.11, 21.94, 19.88, 15.89, 14.56, 12.43]
        )

    def test_BWh(self):       
        self._koppen_wrapper(
            'BWh',
            [ -2.0,1.0,3.0,10.0,13.0,16.0,20.0,21.0,19.0,12.0,3.0,1.0],
            [2.4, 3.32, 5.38, 9.53, 11.79, 12.01, 12.11, 9.94, 5.88, 1.89, 1.56, 1.43]
        )

    def test_BWk(self):      
        self._koppen_wrapper(
            'BWk',
            [ -4.0,1.0,3.0,10.0,13.0,16.0,20.0,21.0,19.0,12.0,3.0, 1.0],
            [2.4, 3.32, 5.38, 9.53, 11.79, 12.01, 12.11, 9.94, 5.88, 1.89, 1.56, 1.43]
        )

    def test_Cfa(self):    
        self._koppen_wrapper(
            'Cfa',
            [  -2.0,     1.0,    3.0,   10.0,   13.0,  16.0,  20.0,  22.1,   19.0,   12.0,    3.0,    1.0],
            [50.4, 44.32, 45.38, 51.53, 62.79, 78.01, 79.11, 78.94, 69.88, 61.89, 54.56, 53.43]
        )

    def test_Cfb(self):     
        self._koppen_wrapper(
            'Cfb',
            [  -2.0,     1.0,    3.0,   10.0,   13.0,  16.0,  20.0,  20.1,   19.0,   12.0,    3.0,    1.0],
            [50.4, 44.32, 45.38, 51.53, 62.79, 78.01, 79.11, 78.94, 69.88, 61.89, 54.56, 53.43]
        )

    def test_Cfc(self):               
        self._koppen_wrapper(
            'Cfc',
            [  -2.0,     1.0,    3.0,    5.0,    7.3,   9.0,  12.0,  11.0,    9.5,    6.0,    2.0,    1.0],
            [50.4, 44.32, 45.38, 51.53, 62.79, 78.01, 79.11, 78.94, 69.88, 61.89, 54.56, 53.43]
        )

    def test_Cwa(self):               
        self._koppen_wrapper(
            'Cwa',
            [ -2.0,   1.0,    3.0,   10.0,   13.0,   16.0,   20.0,    22.1,   19.0,   12.0,    3.0,   1.0],
            [9.11, 8.94, 19.88, 25.89, 34.56, 79.43, 120.4, 110.32, 45.38, 19.53, 10.79, 8.01]
        )

    def test_Cwb(self):               
        self._koppen_wrapper(
            'Cwb',
            [ -2.0,   1.0,    3.0,   10.0,   13.0,   16.0,   20.0,    20.1,   19.0,   12.0,    3.0,    1.0],
            [9.11, 8.94, 19.88, 25.89, 34.56, 79.43, 120.4, 110.32, 45.38, 19.53, 10.79, 8.01]
        )

    def test_Cwc(self):           
        self._koppen_wrapper(
            'Cwc',
            [ -2.0,   1.0,    3.0,    5.0,    7.3,    9.0,   12.0,    11.0,    9.5,    6.0,    2.0,   1.0],
            [9.11, 8.94, 19.88, 25.89, 34.56, 79.43, 120.4, 110.32, 45.38, 19.53, 10.79, 8.01]
        )

    def test_Csa(self):           
        self._koppen_wrapper(
            'Csa',
            [  -2.0,     1.0,    3.0,   10.0,   13.0,  16.0,  20.0,  22.1,   19.0,   12.0,    3.0,    1.0],
            [120.4, 110.32, 45.38, 19.53, 10.79, 8.01, 9.11, 8.94, 19.88, 25.89, 34.56, 79.43]
        )

    def test_Csb(self):           
        self._koppen_wrapper(
            'Csb',
            [  -2.0,     1.0,    3.0,   10.0,   13.0,  16.0,  20.0,  20.0,   19.0,   12.0,    3.0,    1.0],
            [120.4, 110.32, 45.38, 19.53, 10.79, 8.01, 9.11, 8.94, 19.88, 25.89, 34.56, 79.43]
        )

    def test_Csc(self):           
        self._koppen_wrapper(
            'Csc',
            [  -2.0,     1.0,    3.0,    5.0,    7.3,   9.0,  12.0,  11.0,    9.5,    6.0,    2.0,    1.0],
            [120.4, 110.32, 45.38, 19.53, 10.79, 8.01, 9.11, 8.94, 19.88, 25.89, 34.56, 79.43]
        )

    def test_Dfa(self):           
        self._koppen_wrapper(
            'Dfa',
            [  -4.0,     1.0,    3.0,   10.0,   13.0,  16.0,  20.0,  22.1,   19.0,   12.0,    3.0,    1.0],
            [50.4, 44.32, 45.38, 51.53, 62.79, 78.01, 79.11, 78.94, 69.88, 61.89, 54.56, 53.43]
        )

    def test_Dfb(self):           
        self._koppen_wrapper(
            'Dfb',
            [ -4.0,     1.0,    3.0,   10.0,   13.0,  16.0,  20.0,  20.1,   19.0,   12.0,    3.0,    1.0],
            [50.4, 44.32, 45.38, 51.53, 62.79, 78.01, 79.11, 78.94, 69.88, 61.89, 54.56, 53.43]
        )

    def test_Dfc(self):           
        self._koppen_wrapper(
            'Dfc',
            [  -4.0,     1.0,    3.0,    5.0,    7.3,   9.0,  12.0,  11.0,    9.5,    6.0,    2.0,    1.0],
            [50.4, 44.32, 45.38, 51.53, 62.79, 78.01, 79.11, 78.94, 69.88, 61.89, 54.56, 53.43]
        )

    def test_Dfd(self):           
        self._koppen_wrapper(
            'Dfd',
            [-40.0,    -35.0,  -33.0,  -10.0,   -8.0,  -5.0,   2.0,   11.0,   -3.0,  -12.0,  -20.0,  -29.0],
            [50.4, 44.32, 45.38, 51.53, 62.79, 78.01, 79.11, 78.94, 69.88, 61.89, 54.56, 53.43]
        )

    def test_Dwa(self):   
        self._koppen_wrapper(
            'Dwa',
            [ -4.0,   1.0,    3.0,   10.0,   13.0,   16.0,   20.0,    22.1,   19.0,   12.0,    3.0,   1.0],
            [9.11, 8.94, 19.88, 25.89, 34.56, 79.43, 120.4, 110.32, 45.38, 19.53, 10.79, 8.01]
        )

    def test_Dwb(self):           
        self._koppen_wrapper(
            'Dwb',
            [ -4.0,   1.0,    3.0,   10.0,   13.0,   16.0,   20.0,    20.1,   19.0,   12.0,    3.0,    1.0],
            [9.11, 8.94, 19.88, 25.89, 34.56, 79.43, 120.4, 110.32, 45.38, 19.53, 10.79, 8.01]
        )

    def test_Dwc(self):           
        self._koppen_wrapper(
            'Dwc',
            [ -4.0,   1.0,    3.0,    5.0,    7.3,    9.0,   12.0,    11.0,    9.5,    6.0,    2.0,   1.0],
            [9.11, 8.94, 19.88, 25.89, 34.56, 79.43, 120.4, 110.32, 45.38, 19.53, 10.79, 8.01]
        )

    def test_Dwd(self):           
        self._koppen_wrapper(
            'Dwd',
            [-40.0,    -35.0,  -33.0,  -10.0,   -8.0,  -5.0,   2.0,   11.0,   -3.0,  -12.0,  -20.0,  -29.0],
            [9.11, 8.94, 19.88, 25.89, 34.56, 79.43, 120.4, 110.32, 45.38, 19.53, 10.79, 8.01]
        )

    def test_Dsa(self):           
        self._koppen_wrapper(
            'Dsa',
            [  -4.0,     1.0,    3.0,   10.0,   13.0,  16.0,  20.0,  22.1,   19.0,   12.0,    3.0,    1.0],
            [120.4, 110.32, 45.38, 19.53, 10.79, 8.01, 9.11, 8.94, 19.88, 25.89, 34.56, 79.43]
        )

    def test_Dsb(self):           
        self._koppen_wrapper(
            'Dsb',
            [  -4.0,     1.0,    3.0,   10.0,   13.0,  16.0,  20.0,  20.0,   19.0,   12.0,    3.0,    1.0],
            [120.4, 110.32, 45.38, 19.53, 10.79, 8.01, 9.11, 8.94, 19.88, 25.89, 34.56, 79.43]
        )

    def test_Dsc(self):           
        self._koppen_wrapper(
            'Dsc',
            [  -4.0,     1.0,    3.0,    5.0,    7.3,   9.0,  12.0,  11.0,    9.5,    6.0,    2.0,    1.0],
            [120.4, 110.32, 45.38, 19.53, 10.79, 8.01, 9.11, 8.94, 19.88, 25.89, 34.56, 79.43]
        )

    def test_Dsd(self):           
        self._koppen_wrapper(
            'Dsd',
            [-40.0,    -35.0,  -33.0,  -10.0,   -8.0,  -5.0,   2.0,   11.0,   -3.0,  -12.0,  -20.0,  -29.0],
            [120.4, 110.32, 45.38, 19.53, 10.79, 8.01, 9.11, 8.94, 19.88, 25.89, 34.56, 79.43]
        )

    def test_ET(self):           
        self._koppen_wrapper(
            'ET',
            [-40.0,    -35.0,  -33.0,  -10.0,   -8.0,  -5.0,   2.0,   1.0,   -3.0,  -12.0,  -20.0,  -29.0],
            [120.4, 110.32, 45.38, 19.53, 10.79, 8.01, 9.11, 8.94, 19.88, 25.89, 34.56, 79.43]
        )

    def test_Ef(self):           
        self._koppen_wrapper(
            'EF',
            [-40.0,    -35.0,  -33.0,  -10.0,   -8.0,  -5.0,  -2.0,  -1.0,   -3.0,  -12.0,  -20.0,  -29.0],
            [120.4, 110.32, 45.38, 19.53, 10.79, 8.01, 9.11, 8.94, 19.88, 25.89, 34.56, 79.43]
        )

# ---------------------------------------------------

if __name__ == '__main__':
    unittest.main()
