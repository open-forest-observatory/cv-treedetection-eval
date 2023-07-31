# Title: Convert DeepForest Bounding Boxes to Treetop Points
# Description: This script reads in bounding boxes (bboxes) of trees predicted by
#              DeepForest and converts them to treetop points for comparison against
#              a reference stem map. This process involves extracting heights from
#              a CHM (since deepforest does not produce height estimates of trees).
#              The user specifies a folder of bbox files (e.g., each one from a 
#              different run of deepforest) and a CHM. The script converts each bbox
#              file to a corresponding treetop points file. Each bbox file to be
#              processed is expected to be in the format: `*_bboxes.gpkg`.

library(terra)
library(tidyverse)
library(sf)


#### CONSTANTS ####

BBOXES_DIR = "/ofo-share/repos-max/cv-treedetection-eval_max/single-param-data/bboxes/ortho-resolution" # where are the predicted deepforest tree bboxes
CHM_FILEPATH = "/ofo-share/cv-treedetection-eval_data/photogrammetry-outputs/emerald-point_10a-20230103T2008/chm.tif" # where to get the CHM (canopy height model) for assigning heights to the treetops
OUT_DIR = "/ofo-share/repos-max/cv-treedetection-eval_max/single-param-data/ttops/ortho_resolution" # where to store the resulting ttops files

# Load the bboxes files
bboxes_files = list.files(BBOXES_DIR, pattern="^bboxes.*gpkg$", full.names=TRUE)

# Create output directory
if(!dir.exists(OUT_DIR)) {
  dir.create(OUT_DIR, recursive = TRUE)
}

# For each set of bboxes, convert to treetop points
for(bboxes_file in bboxes_files) {
  
  ## get the filename to use for saving the treetop points
  file_minus_extension = str_sub(bboxes_file,1,-6)
  fileparts = str_split(file_minus_extension,fixed("/"))[[1]]
  filename_only = fileparts[length(fileparts)]
  # change 'bboxes' to 'ttops'
  filename_only = str_replace(filename_only, fixed("bboxes"), "ttops")
  out_filepath = paste0(OUT_DIR, "/", filename_only, ".gpkg")
  
  cat("\nConverting bboxes to ttops for:", out_filepath, "\n")
  
  # skip if alredy exists
  if(file.exists(out_filepath)) {
    cat("Already exists. Skipping.\n")
    next()
  }
  
  # load bboxes
  bboxes = st_read(bboxes_file)
  
  # load the CHM
  chm = rast(CHM_FILEPATH)
  
  # get bbox centroids (ttops)
  ttops = st_centroid(bboxes)
  
  ### get a zone within which to get canopy height (as max value within zone)
  ## want a circle with a radius equal to the short dimension of the bbox
  
  # get the radius of the largest inscribed circle, then make a new circle of that size, centered on the centroid of the bbox
  inscr_circles = st_inscribed_circle(st_geometry(bboxes), dTolerance = 1)
  inscr_circles = st_as_sf(inscr_circles)
  # for some reason the above creates two sets of inscribed circles, one with empty geometry, so remove those
  inscr_circles = inscr_circles |> filter(!st_is_empty(inscr_circles))
  circle_areas = st_area(inscr_circles)
  inscr_circles$comp_area = circle_areas
  radii = sqrt(circle_areas/3.14)
  inscr_circles$comp_radius = radii
  circles = st_buffer(ttops, radii)
  
  #### was the prediction a sliver (long skinny rectangular box)? Use this to attribute the output.
  bbox_area = st_area(bboxes)
  is_sliver = circle_areas < (bbox_area/3)
  
  #### get the height
  height = terra::extract(chm, circles, fun = "max")
  
  #### save the attributes back to ttops
  ttops$height = height[,2]
  ttops$is_sliver = is_sliver
  
  # remove ttops below 5 m height
  ttops = ttops |>
    filter(height >= 5)
  
  st_write(ttops, out_filepath, delete_dsn=TRUE)
  
}
