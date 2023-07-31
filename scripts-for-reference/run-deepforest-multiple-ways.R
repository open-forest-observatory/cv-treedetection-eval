# Title: Run Deepforest Multiple Ways
# Description: This script runs DeepForest (using predict_tile) on a forest orthomosaic
#              on a range of a specified parameter via run-deepforest-prediction-
#              from-command-line.py. It saves the detected tree bounding boxes as
#              a .gpkg with the same name as the orthomosaic, followed by the parameter
#              value.
# Credit: Largely based on a script developed by Derek Young

library(tidyverse)

#### CONSTANTS ####
ORTHO_FILEPATH = ".../ortho.tif" # path to the orthomosaic to detect trees from
OUT_DIR = "..." # path to the directory to save the results (detected trees) to

SINGLE_PARAM = "..." # the parameter of interest (i.e. ortho_resolution, window_size, patch_overlap, iou_threshold)
SINGLE_PARAM_RANGE = c() # a vector of the single parameter values


#### MAIN ####
# assign parameters to default values
param_values = list(
  ortho_resolution = 1,
  window_size = 1250,
  patch_overlap = 0.25,
  iou_threshold = 0.15
)

# check if single_param is correctly set to an included parameter
allowed_params = c("ortho_resolution", "window_size", "patch_overlap", "iou_threshold")
if (!(SINGLE_PARAM %in% allowed_params)) {
  stop(paste("Error: Invalid parameter. Allowed parameters are:", paste(allowed_params, collapse = ", ")))
}

# make out directory if needed
if(!dir.exists(OUT_DIR)) {
  dir.create(OUT_DIR, recursive = TRUE)
}

# pad with 5-digit leading zero to integer
pad_5dig = function(x) {
  x = as.numeric(as.character(x))
  str_pad(x, width = 5, side = "left", pad = "0")
}

# get the filename to use for saving (same as the ortho name)
file_minus_extension = str_sub(ORTHO_FILEPATH,1,-5)
fileparts = str_split(file_minus_extension,fixed("/"))[[1]]
filename_only = fileparts[length(fileparts)]

# loop through all window sizes and run DeepForest for each one
for(single_param_value in SINGLE_PARAM_RANGE) {
  # reassign current parameter of interest
  param_values[[SINGLE_PARAM]] = single_param_value
  
  # make bbox file name
  bbox_gpkg_out = paste0(OUT_DIR, "/bboxes_", filename_only, "_", "dpf", "_",
                         single_param_value |> pad_5dig(), ".gpkg")
  
  cat("\nStarting detection for", bbox_gpkg_out, "\n")
  
  # if it already exists, skip
  if(file.exists(bbox_gpkg_out)) {
    cat("Already exists. Skipping.\n")
    next()
  }
  
  # construct and call command line
  call = paste("python3 /ofo-share/repos-max/cv-treedetection-eval_max/scripts-for-reference/run-deepforest-prediction-from-command-line.py", ORTHO_FILEPATH, param_values$window_size, param_values$patch_overlap, param_values$ortho_resolution, param_values$iou_threshold, bbox_gpkg_out, sep = " ")
  system(call)
}

