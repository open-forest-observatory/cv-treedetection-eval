# Title: Run Deepforest Multiple Ways
# Description: This script runs DeepForest (using predict_tile) on a forest orthomosaic
#              on a range of a specified parameter via run-deepforest-prediction-
#              from-command-line.py. It saves the detected tree bounding boxes as
#              a .gpkg with the same name as the orthomosaic, followed by the parameter
#              value.
# Credit: Largely based on a script developed by Derek Young

library(tidyverse)

#### CONSTANTS ####
# path to the orthomosaic to detect trees from
ORTHO_FILEPATH = "/ofo-share/cv-treedetection-eval_data/photogrammetry-outputs/emerald-point_10a-20230103T2008/ortho.tif"
# path to the directory to save the results (detected trees) to
OUT_DIR = "/ofo-share/repos-max/cv-treedetection-eval_max/single-param-data/bboxes/ortho-resolution"

WINDOW_SIZE = 1250  # the DeepForest window size(s) to test
PATCH_OVERLAP = 0.25 # the DeepForest patch overlap(s) to test
ORTHO_RESOLUTION = c(0.5, 0.55, 0.6, 0.65, 0.7, 0.75, 0.8, 0.85, 0.9, 0.95) # the orthomosaic resolution(s) to test
SINGLE_PARAM_RANGE = ORTHO_RESOLUTION # the parameter of interest


#### MAIN ####
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
for(single_param in SINGLE_PARAM_RANGE) {
  
  # reassign argument values
  if (length(SINGLE_PARAM_RANGE) == length(PATCH_OVERLAP)) {
    patch_overlap = single_param
    window_size = WINDOW_SIZE
    ortho_resolution = ORTHO_RESOLUTION
  } else if (length(SINGLE_PARAM_RANGE) == length(WINDOW_SIZE)) {
    patch_overlap = PATCH_OVERLAP
    window_size = single_param
    ortho_resolution = ORTHO_RESOLUTION
  } else if (length(SINGLE_PARAM_RANGE) == length(ORTHO_RESOLUTION)) {
    patch_overlap = PATCH_OVERLAP
    window_size = WINDOW_SIZE
    ortho_resolution = single_param
  } else {
    print("Unable to determine parameter of interest. Please ensure one parameter
           is a vector representing the desired parameter range.")
    break
  }
  
  bbox_gpkg_out = paste0(OUT_DIR, "/bboxes_", filename_only, "_", "dpf", "_",
                         single_param |> pad_5dig(), ".gpkg")
  
  cat("\nStarting detection for", bbox_gpkg_out, "\n")
  
  # if it already exists, skip
  if(file.exists(bbox_gpkg_out)) {
    cat("Already exists. Skipping.\n")
    next()
  }
  
  # put together the command line call and call it
  call = paste("python3 /ofo-share/repos-max/cv-treedetection-eval_max/scripts-for-reference/run-deepforest-prediction-from-command-line.py", ORTHO_FILEPATH, window_size, patch_overlap, ortho_resolution, bbox_gpkg_out, sep = " ")
  system(call)
}

