# cython: infer_types=True, wraparound=False, nonecheck=False, boundscheck=False, cdivision=True, language_level=3, profile=False, autogen_pxd=False

import numpy as np
cimport numpy as np

from cython.parallel import parallel, prange

from libc.math cimport sqrt, pow
from .__opencl__ import cl, cl_array
from .__liquid_engine__ import LiquidEngine
from .__interpolation_tools__ import check_image

cdef extern from "_c_sr_radial_gradient_convergence.h":
    float _c_calculate_rgc(int xM, int yM, float* imIntGx, float* imIntGy, int colsM, int rowsM, int magnification, float Gx_Gy_MAGNIFICATION, float fwhm, float tSO, float tSS, float sensitivity) nogil

class RadialGradientConvergence(LiquidEngine):
    """
    Radial gradient convergence using the NanoPyx Liquid Engine
    """

    def __init__(self, clear_benchmarks=False, testing=False):
        self._designation = "RadialGradientConvergence"
        super().__init__(clear_benchmarks=clear_benchmarks, testing=testing,
                        unthreaded_=False, threaded_=True, threaded_static_=True, 
                        threaded_dynamic_=True, threaded_guided_=True, opencl_=True)


    def run(self, gradient_col_interp, gradient_row_interp, image_interp, magnification: int = 5, radius: float = 1.5, sensitivity: float = 1 , doIntensityWeighting: bool = True, run_type = None): 
        gradient_col_interp = check_image(gradient_col_interp)
        gradient_row_interp = check_image(gradient_row_interp)
        image_interp = check_image(image_interp)
        return self._run(gradient_col_interp, gradient_row_interp, image_interp, magnification, radius, sensitivity, doIntensityWeighting, run_type=run_type)
    

    def benchmark(self, gradient_col_interp, gradient_row_interp, image_interp, magnification: int = 5, radius: float = 1.5, sensitivity: float = 1 , doIntensityWeighting: bool = True):
        gradient_col_interp = check_image(gradient_col_interp)
        gradient_row_interp = check_image(gradient_row_interp)
        image_interp = check_image(image_interp)
        return super().benchmark(gradient_col_interp, gradient_row_interp, image_interp, magnification, radius, sensitivity, doIntensityWeighting)
    

    # tag-start: _le_radial_gradient_convergence.RadialGradientConvergence._run_unthreaded
    def _run_unthreaded(self, float[:,:,:] gradient_col_interp, float[:,:,:] gradient_row_interp, float[:,:,:] image_interp, magnification, radius, sensitivity, doIntensityWeighting):

        cdef float sigma = radius / 2.355
        cdef float fwhm = radius
        cdef float tSS = 2 * sigma * sigma
        cdef float tSO = 2 * sigma + 1
        cdef float Gx_Gy_MAGNIFICATION = 2.0
        cdef int _magnification = magnification
        cdef float _sensitivity = sensitivity
        cdef int _doIntensityWeighting = doIntensityWeighting

        cdef int nFrames = gradient_col_interp.shape[0]
        cdef int rowsM = <int>(gradient_row_interp.shape[1] / Gx_Gy_MAGNIFICATION)
        cdef int colsM = <int>(gradient_row_interp.shape[2] / Gx_Gy_MAGNIFICATION)

        cdef float [:,:,:] rgc_map = np.zeros((nFrames, rowsM, colsM), dtype=np.float32)

        cdef int f, rM, cM
        with nogil:
            for f in range(nFrames):
                    for rM in range(_magnification*2, rowsM - _magnification*2): 
                        for cM in range(_magnification*2, colsM - _magnification*2):
                            if _doIntensityWeighting:
                                rgc_map[f, rM, cM] = _c_calculate_rgc(cM, rM, &gradient_col_interp[f,0,0], &gradient_row_interp[f,0,0], colsM, rowsM, _magnification, Gx_Gy_MAGNIFICATION,  fwhm, tSO, tSS, _sensitivity) * image_interp[f, rM, cM] 
                            else:
                                rgc_map[f, rM, cM] = _c_calculate_rgc(cM, rM, &gradient_col_interp[f,0,0], &gradient_row_interp[f,0,0], colsM, rowsM, _magnification, Gx_Gy_MAGNIFICATION,  fwhm, tSO, tSS, _sensitivity)
        return rgc_map
        # tag-end

    # tag-copy:  _le_radial_gradient_convergence.RadialGradientConvergence._run_unthreaded; replace("_run_unthreaded", "_run_threaded"); replace("range(_magnification*2, rowsM - _magnification*2)", "prange(_magnification*2, rowsM - _magnification*2)")
    def _run_threaded(self, float[:,:,:] gradient_col_interp, float[:,:,:] gradient_row_interp, float[:,:,:] image_interp, magnification, radius, sensitivity, doIntensityWeighting):

        cdef float sigma = radius / 2.355
        cdef float fwhm = radius
        cdef float tSS = 2 * sigma * sigma
        cdef float tSO = 2 * sigma + 1
        cdef float Gx_Gy_MAGNIFICATION = 2.0
        cdef int _magnification = magnification
        cdef float _sensitivity = sensitivity
        cdef int _doIntensityWeighting = doIntensityWeighting

        cdef int nFrames = gradient_col_interp.shape[0]
        cdef int rowsM = <int>(gradient_row_interp.shape[1] / Gx_Gy_MAGNIFICATION)
        cdef int colsM = <int>(gradient_row_interp.shape[2] / Gx_Gy_MAGNIFICATION)

        cdef float [:,:,:] rgc_map = np.zeros((nFrames, rowsM, colsM), dtype=np.float32)

        cdef int f, rM, cM
        with nogil:
            for f in range(nFrames):
                    for rM in prange(_magnification*2, rowsM - _magnification*2): 
                        for cM in range(_magnification*2, colsM - _magnification*2):
                            if _doIntensityWeighting:
                                rgc_map[f, rM, cM] = _c_calculate_rgc(cM, rM, &gradient_col_interp[f,0,0], &gradient_row_interp[f,0,0], colsM, rowsM, _magnification, Gx_Gy_MAGNIFICATION,  fwhm, tSO, tSS, _sensitivity) * image_interp[f, rM, cM] 
                            else:
                                rgc_map[f, rM, cM] = _c_calculate_rgc(cM, rM, &gradient_col_interp[f,0,0], &gradient_row_interp[f,0,0], colsM, rowsM, _magnification, Gx_Gy_MAGNIFICATION,  fwhm, tSO, tSS, _sensitivity)
        return rgc_map
        # tag-end

    # tag-copy:  _le_radial_gradient_convergence.RadialGradientConvergence._run_unthreaded; replace("_run_unthreaded", "_run_threaded_static"); replace("range(_magnification*2, rowsM - _magnification*2)", 'prange(_magnification*2, rowsM - _magnification*2, schedule="static")')
    def _run_threaded_static(self, float[:,:,:] gradient_col_interp, float[:,:,:] gradient_row_interp, float[:,:,:] image_interp, magnification, radius, sensitivity, doIntensityWeighting):

        cdef float sigma = radius / 2.355
        cdef float fwhm = radius
        cdef float tSS = 2 * sigma * sigma
        cdef float tSO = 2 * sigma + 1
        cdef float Gx_Gy_MAGNIFICATION = 2.0
        cdef int _magnification = magnification
        cdef float _sensitivity = sensitivity
        cdef int _doIntensityWeighting = doIntensityWeighting

        cdef int nFrames = gradient_col_interp.shape[0]
        cdef int rowsM = <int>(gradient_row_interp.shape[1] / Gx_Gy_MAGNIFICATION)
        cdef int colsM = <int>(gradient_row_interp.shape[2] / Gx_Gy_MAGNIFICATION)

        cdef float [:,:,:] rgc_map = np.zeros((nFrames, rowsM, colsM), dtype=np.float32)

        cdef int f, rM, cM
        with nogil:
            for f in range(nFrames):
                    for rM in prange(_magnification*2, rowsM - _magnification*2, schedule="static"): 
                        for cM in range(_magnification*2, colsM - _magnification*2):
                            if _doIntensityWeighting:
                                rgc_map[f, rM, cM] = _c_calculate_rgc(cM, rM, &gradient_col_interp[f,0,0], &gradient_row_interp[f,0,0], colsM, rowsM, _magnification, Gx_Gy_MAGNIFICATION,  fwhm, tSO, tSS, _sensitivity) * image_interp[f, rM, cM] 
                            else:
                                rgc_map[f, rM, cM] = _c_calculate_rgc(cM, rM, &gradient_col_interp[f,0,0], &gradient_row_interp[f,0,0], colsM, rowsM, _magnification, Gx_Gy_MAGNIFICATION,  fwhm, tSO, tSS, _sensitivity)
        return rgc_map
        # tag-end

    # tag-copy:  _le_radial_gradient_convergence.RadialGradientConvergence._run_unthreaded; replace("_run_unthreaded", "_run_threaded_dynamic"); replace("range(_magnification*2, rowsM - _magnification*2)", 'prange(_magnification*2, rowsM - _magnification*2, schedule="dynamic")')
    def _run_threaded_dynamic(self, float[:,:,:] gradient_col_interp, float[:,:,:] gradient_row_interp, float[:,:,:] image_interp, magnification, radius, sensitivity, doIntensityWeighting):

        cdef float sigma = radius / 2.355
        cdef float fwhm = radius
        cdef float tSS = 2 * sigma * sigma
        cdef float tSO = 2 * sigma + 1
        cdef float Gx_Gy_MAGNIFICATION = 2.0
        cdef int _magnification = magnification
        cdef float _sensitivity = sensitivity
        cdef int _doIntensityWeighting = doIntensityWeighting

        cdef int nFrames = gradient_col_interp.shape[0]
        cdef int rowsM = <int>(gradient_row_interp.shape[1] / Gx_Gy_MAGNIFICATION)
        cdef int colsM = <int>(gradient_row_interp.shape[2] / Gx_Gy_MAGNIFICATION)

        cdef float [:,:,:] rgc_map = np.zeros((nFrames, rowsM, colsM), dtype=np.float32)

        cdef int f, rM, cM
        with nogil:
            for f in range(nFrames):
                    for rM in prange(_magnification*2, rowsM - _magnification*2, schedule="dynamic"): 
                        for cM in range(_magnification*2, colsM - _magnification*2):
                            if _doIntensityWeighting:
                                rgc_map[f, rM, cM] = _c_calculate_rgc(cM, rM, &gradient_col_interp[f,0,0], &gradient_row_interp[f,0,0], colsM, rowsM, _magnification, Gx_Gy_MAGNIFICATION,  fwhm, tSO, tSS, _sensitivity) * image_interp[f, rM, cM] 
                            else:
                                rgc_map[f, rM, cM] = _c_calculate_rgc(cM, rM, &gradient_col_interp[f,0,0], &gradient_row_interp[f,0,0], colsM, rowsM, _magnification, Gx_Gy_MAGNIFICATION,  fwhm, tSO, tSS, _sensitivity)
        return rgc_map
        # tag-end

    # tag-copy:  _le_radial_gradient_convergence.RadialGradientConvergence._run_unthreaded; replace("_run_unthreaded", "_run_threaded_guided"); replace("range(_magnification*2, rowsM - _magnification*2)", 'prange(_magnification*2, rowsM - _magnification*2, schedule="guided")')
    def _run_threaded_guided(self, float[:,:,:] gradient_col_interp, float[:,:,:] gradient_row_interp, float[:,:,:] image_interp, magnification, radius, sensitivity, doIntensityWeighting):

        cdef float sigma = radius / 2.355
        cdef float fwhm = radius
        cdef float tSS = 2 * sigma * sigma
        cdef float tSO = 2 * sigma + 1
        cdef float Gx_Gy_MAGNIFICATION = 2.0
        cdef int _magnification = magnification
        cdef float _sensitivity = sensitivity
        cdef int _doIntensityWeighting = doIntensityWeighting

        cdef int nFrames = gradient_col_interp.shape[0]
        cdef int rowsM = <int>(gradient_row_interp.shape[1] / Gx_Gy_MAGNIFICATION)
        cdef int colsM = <int>(gradient_row_interp.shape[2] / Gx_Gy_MAGNIFICATION)

        cdef float [:,:,:] rgc_map = np.zeros((nFrames, rowsM, colsM), dtype=np.float32)

        cdef int f, rM, cM
        with nogil:
            for f in range(nFrames):
                    for rM in prange(_magnification*2, rowsM - _magnification*2, schedule="guided"): 
                        for cM in range(_magnification*2, colsM - _magnification*2):
                            if _doIntensityWeighting:
                                rgc_map[f, rM, cM] = _c_calculate_rgc(cM, rM, &gradient_col_interp[f,0,0], &gradient_row_interp[f,0,0], colsM, rowsM, _magnification, Gx_Gy_MAGNIFICATION,  fwhm, tSO, tSS, _sensitivity) * image_interp[f, rM, cM] 
                            else:
                                rgc_map[f, rM, cM] = _c_calculate_rgc(cM, rM, &gradient_col_interp[f,0,0], &gradient_row_interp[f,0,0], colsM, rowsM, _magnification, Gx_Gy_MAGNIFICATION,  fwhm, tSO, tSS, _sensitivity)
        return rgc_map
        # tag-end

    
    def _run_opencl(self, gradient_col_interp, gradient_row_interp, image_interp, magnification, radius, sensitivity, doIntensityWeighting, dict device):

        # gradient gxgymag*mag*size
        # image_interp = mag*size
        # output = image_interp

        cl_ctx = cl.Context([device['device']])
        cl_queue = cl.CommandQueue(cl_ctx)

        code = self._get_cl_code("_le_radial_gradient_convergence.cl", device['DP'])

        cdef float sigma = radius / 2.355
        cdef float fwhm = radius
        cdef float tSS = 2 * sigma * sigma
        cdef float tSO = 2 * sigma + 1
        cdef float Gx_Gy_MAGNIFICATION = 2.0
        cdef int _magnification = magnification
        cdef float _sensitivity = sensitivity
        cdef int _doIntensityWeighting = doIntensityWeighting

        cdef int nFrames = gradient_col_interp.shape[0]
        cdef int rows_interpolated = <int>(gradient_row_interp.shape[1] / Gx_Gy_MAGNIFICATION)
        cdef int cols_interpolated = <int>(gradient_row_interp.shape[2] / Gx_Gy_MAGNIFICATION)

        grad_col_int_in = cl_array.to_device(cl_queue, np.asarray(gradient_col_interp, dtype=np.float32))
        grad_row_int_in = cl_array.to_device(cl_queue, np.asarray(gradient_row_interp, dtype=np.float32))
        image_interp_in = cl_array.to_device(cl_queue, np.asarray(image_interp, dtype=np.float32))
        rgc_map_out = cl_array.zeros(cl_queue, (nFrames, rows_interpolated, cols_interpolated), dtype=np.float32)

        # Grid size
        lowest_row = _magnification*2 
        highest_row = rows_interpolated - _magnification*2

        lowest_col = _magnification*2
        highest_col =  cols_interpolated - _magnification*2

        prg = cl.Program(cl_ctx, code).build() 

        prg.calculate_rgc(cl_queue, 
                    (nFrames, highest_row - lowest_row, highest_col - lowest_col), 
                    None, 
                    grad_col_int_in.data,
                    grad_row_int_in.data,
                    image_interp_in.data,
                    rgc_map_out.data,
                    np.int32(cols_interpolated), 
                    np.int32(rows_interpolated), 
                    np.int32(_magnification), 
                    np.float32(Gx_Gy_MAGNIFICATION), 
                    np.float32(fwhm), 
                    np.float32(tSO), 
                    np.float32(tSS), 
                    np.float32(_sensitivity), 
                    np.int32(_doIntensityWeighting) )
        
        cl_queue.finish()        
        
        return np.asarray(rgc_map_out.get(),dtype=np.float32)
        




