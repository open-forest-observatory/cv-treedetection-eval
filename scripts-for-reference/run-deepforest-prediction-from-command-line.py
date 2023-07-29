# Title: Command Line Deepforest Prediction
# Description: This script streamlines calling DeepForest from R, expecially
#              calling it multiple times with different parameters. The script can
#              be called from the command line and is a wrapper for several functions
#              in DeepForest (primarily predict_tile and bboxes_to_shapefile).
# Credit: Largely based on a script developed by Derek Young

from deepforest import main
from deepforest import get_data
from deepforest import utilities
import os
import sys
import rasterio as rio
import numpy as  np
from skimage.transform import resize
from pathlib import Path

# resize helper functions
def resize_orthomosaic(orthomosaic, new_resolution):
    """
    Resize the orthomosaic to a new resolution by dividing it into patches, resizing each patch, and stitching them back together.

    Parameters:
        orthomosaic (numpy array): The original orthomosaic as a 3D numpy array with shape (height, width, num_channels).
        new_resolution (float): The desired new resolution for the orthomosaic.

    Returns:
        numpy array: The resized orthomosaic as a 3D numpy array with shape (new_height, new_width, num_channels).
    """
    original_height, original_width, num_channels = orthomosaic.shape
    new_height = int(original_height * new_resolution)
    new_width = int(original_width * new_resolution)

    # Calculate the number of patches in each dimension
    patch_height = 512  # Adjust this value based on your preference and system memory
    patch_width = 512   # Adjust this value based on your preference and system memory
    num_patches_height = int(np.ceil(new_height / patch_height))
    num_patches_width = int(np.ceil(new_width / patch_width))

    # Initialize the resized orthomosaic with NaN values
    resized_ortho = np.full((new_height, new_width, num_channels), np.nan)

    # Resize each patch and place it in the corresponding location in the resized orthomosaic
    for row in range(num_patches_height):
        for col in range(num_patches_width):
            start_h, end_h = get_patch_start_end(row, patch_height, new_height)
            start_w, end_w = get_patch_start_end(col, patch_width, new_width)

            patch = orthomosaic[start_h:end_h, start_w:end_w, :]
            resized_patch = resize(patch, (end_h - start_h, end_w - start_w, num_channels))
            resized_ortho[start_h:end_h, start_w:end_w, :] = resized_patch

    return resized_ortho

def get_patch_start_end(patch_idx, patch_size, image_size):
    """
    Calculate the starting and ending indices of a patch based on the patch index, patch size, and image size.

    Parameters:
        patch_idx (int): The index of the patch.
        patch_size (int): The size of the patch.
        image_size (int): The size of the entire image.

    Returns:
        tuple: A tuple containing the starting and ending indices of the patch.
    """
    start = patch_idx * patch_size
    end = min(start + patch_size, image_size)
    return start, end


# Get parameters from command line arguments if running from command line, otherwise use hard-coded testing parameters
in_ortho = sys.argv[1]           # orthomosaic file path
patch_size = int(sys.argv[2])    # deepforest patch size
patch_overlap = float(sys.argv[3]) # deepforest patch overlap
ortho_resolution = float(sys.argv[4]) # orthomosaic resolution
out_boxes_gpkg = sys.argv[5]     # output geopackage file path

# For testing (when running interactively):
# in_ortho = "/ofo-share/metashape-version-effect/data/meta200/drone/L1/metashape-version-effect_config_10b_2_4_moderate_50_usgs-filter_20230104T1912_ortho_dtm.tif"
# patch_size = 1000
# out_boxes_gpkg = "/ofo-share/metashape-version-effect/data/meta200/drone/L3/temp_deepforest_bboxes/bboxes_metashape-version-effect_config_15b_2_2_mild_50_usgs-filter_20230105T0315_ortho_dtm_dpf_0.000_0.000_0.000_0.000_00.gpkg"

# Read in ortho and select the right bands, in the right order
r = rio.open(in_ortho)
df = r.read()
df = df[:3, :, :]
rolled_df = np.rollaxis(df, 0, 3)

# Ensure the current and desired ortho resolution match
if ortho_resolution != 1:
    resized_df = resize_orthomosaic(df, ortho_resolution)
else:
    resized_df = rolled_df

# Initialize deepforest model
m = main.deepforest()
m.use_release()

# Run tree prediction
boxes = m.predict_tile(image=resized_df, patch_size=patch_size, patch_overlap=patch_overlap)

# Need to set an attribute of the detected tree bounding boxes to contain the ortho filename
boxes["image_path"] = in_ortho

# Create the output directory if it doesn't exist
Path(out_boxes_gpkg).parent.mkdir(parents=True, exist_ok=True)

# Save the detected tree bounding boxes to shapefile
shp = utilities.boxes_to_shapefile(boxes, root_dir="", projected=True)
shp.to_file(out_boxes_gpkg)
