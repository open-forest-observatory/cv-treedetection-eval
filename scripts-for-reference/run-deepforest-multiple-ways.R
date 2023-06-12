# Run deepforest on a forest orthomosaic, testing multiple different window sizes
# Saves the detected tree bounding boxes as a .gpkg with the same name as the orthomosaic, followed by the window size.
# The input and output file paths are set in this script under the header #### CONSTANTS ####

library(tidyverse)


#### CONSTANTS ####

ORTHO_FILEPATH = "/path/to/orthomosaic.tif"      # Path to the orthomosaic to detect trees from
OUT_DIR = "path/to/save/tree/detections/"   # Path to the directory to save the results (detected trees) to


#### MAIN ####

if(!dir.exists(OUT_DIR)) {
  dir.create(OUT_DIR, recursive = TRUE)
}

# The DeepForest window sizes to test
window_sizes = c(500, 1000, 1250, 1500, 1750, 2000, 2500, 3000, 4000, 5000) |> rev()


### Convenience functions for formatting numbers in filenames

# Pad with 5-digit leading zero to integer
pad_5dig = function(x) {
  x = as.numeric(as.character(x))
  str_pad(x, width = 5, side = "left", pad = "0")
}


# get the filename to use for saving (same as the ortho name)
file_minus_extension = str_sub(ORTHO_FILEPATH,1,-5)
fileparts = str_split(file_minus_extension,fixed("/"))[[1]]
filename_only = fileparts[length(fileparts)]

# loop through all window sizes and run DeepForest for each one
for(window_size in window_sizes) {
  
  bbox_gpkg_out = paste0(OUT_DIR, "/bboxes_", filename_only, "_", "dpf", "_", window_size |> pad_5dig(), ".gpkg")
  
  cat("\nStarting detection for", bbox_gpkg_out, "\n")
  
  # if it already exists, skip
  if(file.exists(bbox_gpkg_out)) {
    cat("Already exists. Skipping.\n")
    next()
  }
  
  # put together the command line call and call it
  call = paste("python3 /ofo-share/utils/run-deepforest-prediction-from-command-line.py", ORTHO_FILEPATH, window_size, bbox_gpkg_out, sep = " ")
  system(call)
  
}