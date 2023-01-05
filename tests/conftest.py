
import random

import numpy as np
import pytest

from nanopyx.core.transform.image_add_random_noise import (addRamp, addSquares,
                                                           getRamp, getSquares)
from nanopyx.core.utils.imagegenerator.beads import generate_timelapse_drift
from nanopyx.data.examples.download import ExampleDataManager


@pytest.fixture
def random_image_with_ramp_squares():
    w = random.randint(32, 64)
    h = random.randint(32, 64)
    image = np.zeros((w, h), dtype="float32")
    addRamp(image, 1000)
    addSquares(image, 100, nSquares=10)
    return image

@pytest.fixture
def random_image_with_ramp():
    return getRamp(64, 64)

@pytest.fixture
def random_image_with_squares():
    return getSquares(128, 64, nSquares=10)

@pytest.fixture
def random_timelapse_w_drift():
    return generate_timelapse_drift(n_objects=5, shape=(200, 150, 150), drift=1)

@pytest.fixture
def downloader():
    return ExampleDataManager()
