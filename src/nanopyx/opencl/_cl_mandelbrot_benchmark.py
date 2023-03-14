import numpy as np
import pyopencl as cl
import pyopencl.array as cl_array

from . import get_fastest_device, get_kernel_txt


def mandelbrot(
    size: int,
    max_iter: int,
    divergence: float = 4,
):
    """
    Creates a mandelbrot set using OpenCL
    :param size: Size of the mandelbrot set
    :param max_iter: Maximum number of iterations
    :param divergence: The divergence threshold
    :return: The mandelbrot set
    """

    fastest_device = get_fastest_device()
    ctx = cl.Context([fastest_device])
    queue = cl.CommandQueue(ctx)

    # Create the mandelbrot set
    mandelbrot = cl_array.zeros(queue, (size, size), dtype=np.int32)

    # Create the kernel
    kernel_txt = get_kernel_txt(__file__)
    prg = cl.Program(ctx, kernel_txt).build()

    # Run the kernel
    prg.mandelbrot(
        queue,
        mandelbrot.shape,
        None,
        mandelbrot.data,
        np.int32(max_iter),
        np.float32(divergence),
    )
    queue.finish()

    return mandelbrot.get()
