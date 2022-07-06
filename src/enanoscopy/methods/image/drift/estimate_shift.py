import numpy as np
from scipy.interpolate import griddata
from scipy.optimize import minimize
from scipy.interpolate import interp2d


# TODO refactor to not create a new griddata object on every iteration
class GetMaxOptimizer(object):

    def __init__(self, slice_ccm) -> None:
        self.slice_ccm = slice_ccm
        self.w = slice_ccm.shape[1]
        self.h = slice_ccm.shape[0]
        self.interpolator = interp2d(np.array(range(self.slice_ccm.shape[0])),
                                     np.array(self.slice_ccm.shape[1]),
                                     self.slice_ccm.reshape((self.slice_ccm.shape[0] * self.slice_ccm.shape[1])))
        
    def get_interpolated_px_value(self, coords):
        points = [(y, x) for y in range(self.slice_ccm.shape[0]) for x in range(self.slice_ccm.shape[1])]
        values = self.slice_ccm.reshape((self.slice_ccm.shape[0] * self.slice_ccm.shape[1]))

        return -griddata(points, values, coords, method="cubic")

    def get_interpolated_px_value_optimized(self, coords):
        return -self.interpolator(coords[0], coords[1])

    def get_max(self):
        y_max, x_max = np.unravel_index(self.slice_ccm.argmax(), self.slice_ccm.shape)
        minimizer = minimize(self.get_interpolated_px_value, np.array([y_max, x_max]), method="Nelder-Mead", options={"maxiter": 1000})
        return minimizer.x

