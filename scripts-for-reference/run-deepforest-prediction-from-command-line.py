# This script can be called from the command line. It is a wrapper for several functions in DeepForest (primarily predict_tile and bboxes_to_shapefile).
# This streamlines calling DeepForest from R, expecially calling it multiple times with different parameters.
# The structure of the command line call is: `python3 run-deepforest-prediction-from-command-line.py {orthomosaic file path} {window size} {output bounding box gpkg file path}`

from deepforest import main
from deepforest import get_data
from deepforest import utilities
import os
import sys
import rasterio as rio
import numpy as  np
from pathlib import Path


# Get parameters from command line arguments if running from command line, otherwise use hard-coded testing parameters
in_ortho = sys.argv[1]         # orthomosaic file path
patch_size = int(sys.argv[2])  # deepforest patch size
out_boxes_gpkg = sys.argv[3]  # output geopackage file path

# For testing (when running interactively):
# in_ortho = "/ofo-share/metashape-version-effect/data/meta200/drone/L1/metashape-version-effect_config_10b_2_4_moderate_50_usgs-filter_20230104T1912_ortho_dtm.tif"
# patch_size = 1000
# out_boxes_gpkg = "/ofo-share/metashape-version-effect/data/meta200/drone/L3/temp_deepforest_bboxes/bboxes_metashape-version-effect_config_15b_2_2_mild_50_usgs-filter_20230105T0315_ortho_dtm_dpf_0.000_0.000_0.000_0.000_00.gpkg"

# Read in ortho and select the right bands, in the right order
r = rio.open(in_ortho)
df = r.read()
df = df[:3,:,:]
rolled_df = np.rollaxis(df, 0,3)

# Initialize deepforest model
m = main.deepforest()
m.use_release()

# Run tree prediction
boxes = m.predict_tile(image=rolled_df, patch_size=patch_size, patch_overlap = 0.3)

# Need to set an attribute of the detected tree bounding boxes to contain the ortho filename
boxes["image_path"] = in_ortho

# Create the output directory if it doesn't exist
Path(out_boxes_gpkg).parent.mkdir(parents=True, exist_ok=True)

# Save the detected tree bounding boxes to shapefile
shp = utilities.boxes_to_shapefile(boxes, root_dir="", projected=True)
shp.to_file(out_boxes_gpkg)
