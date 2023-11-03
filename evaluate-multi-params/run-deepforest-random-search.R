# Title: Run DeepForest Hyperparameter Optimization With Random Search
# Description: This script performs hyperparameter optimization with random search
#              for DeepForest (using predict_tile). It searches across specified
#              hyperparameter ranges for a specified number of iterations, calling 
#              run-deepforest-eval-pipeline.R for each hyperparameter combination.

#### CONSTANTS ####
IN_ORTHO_DIR = "/ofo-share/cv-treedetection-eval_data/photogrammetry-outputs/emerald-point_10a-20230103T2008/ortho.tif" # path to the orthomosaic to detect trees from
OUT_DIR = "..." # path to the directory to save the results
CHM_DIR = "/ofo-share/cv-treedetection-eval_data/photogrammetry-outputs/emerald-point_10a-20230103T2008/chm.tif" # path to the CHM (canopy height model)
OBSERVED_TREES_DIR = "/ofo-share/cv-treedetection-eval_data/observed-trees/observed-trees.geojson" # path to the observed trees
PLOT_BOUND_DIR = "/ofo-share/cv-treedetection-eval_data/perimeters/emerald-point-perimeter.geojson" # path to the plot boundary

NUM_COMBINATIONS = 25 # the number of random search iterations
PATCH_SIZE_RANGE = seq(1000, 2000)
PATCH_OVERLAP_RANGE = seq(0.2, 0.4, length.out=NUM_COMBINATIONS)
ORTHO_RESOLUTION_RANGE = seq(0.8, 1.2, length.out=NUM_COMBINATIONS)
IOU_THRESHOLD_RANGE = seq(0.2, 0.3, length.out=NUM_COMBINATIONS)


#### RANDOM SEARCH ####
# generate random hyperparameter combination
for (i in 1:NUM_COMBINATIONS) {
  # sample random values from the provided parameter value ranges
  patch_size = sample(PATCH_SIZE_RANGE, 1)
  patch_overlap = round(sample(PATCH_OVERLAP_RANGE, 1), 2)
  ortho_resolution = round(sample(ORTHO_RESOLUTION_RANGE, 1), 2)
  iou_threshold = round(sample(IOU_THRESHOLD_RANGE, 1), 2)
  
  # call run-deepforest-eval-pipeline.R with the sampled parameter values
  call = paste("Rscript --vanilla /ofo-share/repos-max/cv-treedetection-eval_max/run-deepforest-predictions/run-deepforest-eval-pipeline.R", IN_ORTHO_DIR, OUT_DIR, CHM_DIR, OBSERVED_TREES_DIR, PLOT_BOUND_DIR, patch_size, patch_overlap, ortho_resolution, iou_threshold, sep = " ")
  system(call)
}

