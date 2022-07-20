import numpy as np
from numpy import array
from skimage.io import imsave
from tkinter import filedialog as fd

from .channel_alignment_corrector import ChannelAlignmentCorrector
from ..image.registration.cross_correlation_elastic import calculate_translation_mask


# this class assumes that the image is a numpy array with shape = [n_channels, height, width]
# assumes that channels in an image that will be aligned using generated translation masks will be in the same order
class ChannelAlignmentEstimator(object):

    def __init__(self) -> None:
        self.translation_masks = None
        self.ccms = None

    def apply_elastic_transform(self, img_stack):
        corrector = ChannelAlignmentCorrector()
        return corrector.align_channels(img_stack, translation_masks=self.translation_masks)

    def calculate_translation(self, channel_to_align, ref_channel_img, max_shift, blocks_per_axis, min_similarity, method="subpixel"):
        translation_mask = calculate_translation_mask(channel_to_align, ref_channel_img, max_shift, blocks_per_axis, min_similarity, method=method)
        return translation_mask

    def save_translation_mask(self, path=None):
        if path is not None:
            imsave(path + ".tif", self.translation_masks)
        else:
            imsave(fd.asksaveasfilename(title="Save Translation Masks") + ".tif", self.translation_masks)

    def save_ccms(self, path=None):
        if path is not None:
            imsave(path + ".tif", self.ccms)
        else:
            imsave(fd.asksaveasfilename(title="Save Cross Correlation Maps") + ".tif", self.ccms)

    def estimate(self, img_stack: array, ref_channel: int, max_shift: float,
                 blocks_per_axis: int, min_similarity: float, method: str="subpixel",
                 save_translation_masks: bool=True, translation_mask_save_path: str=None,
                 save_ccms: bool=False, ccms_save_path: str=None,
                 apply: bool=False):

        channels_to_align = list(range(img_stack.shape[0]))
        channels_to_align.remove(ref_channel)

        if ref_channel > img_stack.shape[1]:
            print("Reference channel number cannot be bigger than number of channels!")
            return None

        self.translation_masks = np.zeros((img_stack.shape[0], img_stack.shape[1], img_stack.shape[2]*2))
        self.ccms = []

        for channel in channels_to_align:
            translation_mask, ccm = self.calculate_translation(img_stack[channel], img_stack[ref_channel], max_shift, blocks_per_axis, min_similarity, method=method)
            self.translation_masks[channel] = translation_mask
            self.ccms.append(ccm)

        self.ccms.insert(ref_channel, np.zeros((len(self.ccms[0]), len(self.ccms[0][0]))))
        self.ccms = np.array(self.ccms)

        if save_translation_masks:
            self.save_translation_mask(path=translation_mask_save_path)

        if save_ccms:
            self.save_ccms(path=ccms_save_path)

        if apply:
            return self.apply_elastic_transform(img_stack)
        else:
            return None


