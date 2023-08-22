# Title: Run DeepForest Hyperparameter Optimization With Random Search
# Description: This script performs hyperparameter optimization with random search
#              for DeepForest (using predict_tile). It searches across specified
#              hyperparameter ranges for a specified number of iterations, calling 
#              run-deepforest-eval-pipeline.R for each hyperparameter combination.

#### CONSTANTS ####
IN_ORTHO_DIR = "/ofo-share/cv-treedetection-eval_data/photogrammetry-outputs/emerald-point_10a-20230103T2008/ortho.tif" # path to the orthomosaic to detect trees from
OUT_DIR = "/ofo-share/repos-max/multi-param-data" # path to the directory to save the results (detected trees) to
CHM_DIR = "/ofo-share/cv-treedetection-eval_data/photogrammetry-outputs/emerald-point_10a-20230103T2008/chm.tif" # where to get the CHM (canopy height model) for assigning heights to the treetops
OBSERVED_TREES_DIR = "/ofo-share/cv-treedetection-eval_data/observed-trees/observed-trees.geojson"
PLOT_BOUND_DIR = "/ofo-share/cv-treedetection-eval_data/perimeters/emerald-point-perimeter.geojson"

NUM_COMBINATIONS = 20
PATCH_SIZE_RANGE = seq(1000, 2000)
PATCH_OVERLAP_RANGE = seq(0.2, 0.4, length.out=NUM_COMBINATIONS)
ORTHO_RESOLUTION_RANGE = seq(0.8, 1.2, length.out=NUM_COMBINATIONS)
IOU_THRESHOLD_RANGE = seq(0.2, 0.3, length.out=NUM_COMBINATIONS)


#### RANDOM SEARCH ####
# generate random hyperparameter combination
for (i in 1:NUM_COMBINATIONS) {
  patch_size = sample(PATCH_SIZE_RANGE, 1)
  patch_overlap = round(sample(PATCH_OVERLAP_RANGE, 1), 2)
  ortho_resolution = round(sample(ORTHO_RESOLUTION_RANGE, 1), 2)
  iou_threshold = round(sample(IOU_THRESHOLD_RANGE, 1), 2)
  
  call = paste("Rscript --vanilla /ofo-share/repos-max/cv-treedetection-eval_max/run-deepforest-predictions/run-deepforest-eval-pipeline.R", IN_ORTHO_DIR, OUT_DIR, CHM_DIR, OBSERVED_TREES_DIR, PLOT_BOUND_DIR, patch_size, patch_overlap, ortho_resolution, iou_threshold, sep = " ")
  system(call)
}


