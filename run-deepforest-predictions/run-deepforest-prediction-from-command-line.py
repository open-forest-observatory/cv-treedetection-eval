# Title: Run Command Line Deepforest Predictions
# Description: This script streamlines calling DeepForest from R, expecially
#              calling it multiple times with different parameters. The script can
#              be called from the command line and is a wrapper for several functions
#              in DeepForest (primarily predict_tile and bboxes_to_shapefile). The
#              structure of the command line call is:
#              `python3 run-deepforest-prediction-from-command-line.py
#              {orthomosaic file path} {window size} {output bounding box gpkg file path}
# Credit: Largely based on a script developed by Derek Young for OFO

from deepforest import main
from deepforest import get_data
from deepforest import utilities
import os
import sys
import rasterio as rio
import numpy as  np
from pathlib import Path
from PIL import Image


def resize_ortho(original_ortho, resize_factor):
  """
    Resize the orthomosaic image by the specified resize factor.

    Args:
        original_ortho (numpy.ndarray): The original orthomosaic as a numpy array.
        resize_factor (float): The factor by which to resize the orthomosaic
                               (e.g. 0.8 for 80% resolution).

    Returns:
        resized_ortho_array (numpy.ndarray): The resized orthomosaic as a numpy array.
  """
  # if line below is commented, large orthos may not be resized (DecompressionBombError)
  # if line below is uncommented, resizing large orthos may use excessive memory and processing
  Image.MAX_IMAGE_PIXELS = None
  
  image = Image.fromarray(original_ortho.astype(np.uint8)) # create the PIL image from the numpy array
  
  original_width, original_height = image.size # get the original width and height
  new_width = int(original_width * resize_factor) # calculate the new width
  new_height = int(original_height * resize_factor) # calculate the new height
  
  resized_ortho = image.resize((new_width, new_height), Image.LANCZOS) # resize the image
  resized_ortho_array = np.array(resized_ortho)
  return resized_ortho_array


# Get parameters from command line arguments if running from command line, otherwise use hard-coded testing parameters
in_ortho = sys.argv[1]           # orthomosaic file path
patch_size = int(sys.argv[2])    # deepforest patch size
patch_overlap = float(sys.argv[3]) # deepforest patch overlap
ortho_resolution = float(sys.argv[4]) # orthomosaic resolution
iou_threshold = float(sys.argv[5]) # minimum iou overlap to be suppressed
out_boxes_gpkg = sys.argv[6]     # output geopackage file path

# For testing (when running interactively):
# in_ortho = "/ofo-share/metashape-version-effect/data/meta200/drone/L1/metashape-version-effect_config_10b_2_4_moderate_50_usgs-filter_20230104T1912_ortho_dtm.tif"
# patch_size = 1000
# out_boxes_gpkg = "/ofo-share/metashape-version-effect/data/meta200/drone/L3/temp_deepforest_bboxes/bboxes_metashape-version-effect_config_15b_2_2_mild_50_usgs-filter_20230105T0315_ortho_dtm_dpf_0.000_0.000_0.000_0.000_00.gpkg"

# Read in ortho and select the right bands, in the right order
r = rio.open(in_ortho)
df = r.read()
df = df[:3, :, :]
rolled_df = np.rollaxis(df, 0, 3)

# Resize ortho
resized_df = resize_ortho(rolled_df, ortho_resolution)

# Initialize deepforest model
m = main.deepforest()
m.use_release()

# Run tree prediction
boxes = m.predict_tile(image=resized_df, patch_size=patch_size, patch_overlap=patch_overlap, iou_threshold=iou_threshold)

# Need to set an attribute of the detected tree bounding boxes to contain the ortho filename
boxes["image_path"] = in_ortho

# Create the output directory if it doesn't exist
Path(out_boxes_gpkg).parent.mkdir(parents=True, exist_ok=True)

# Save the detected tree bounding boxes to shapefile
shp = utilities.boxes_to_shapefile(boxes, root_dir="", projected=True)
shp.to_file(out_boxes_gpkg)
