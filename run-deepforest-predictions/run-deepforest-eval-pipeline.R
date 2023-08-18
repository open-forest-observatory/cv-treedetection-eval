# Title: Run A Hyperparameter Combination Through the Parameter Evaluation Pipeline
# Description: This script runs a given set of DeepForest predict_tile hyperparameters
#              through the DeepForest evaluation pipeline, starting from an orthomosaic
#              and ending with the parameters' corresponding f-score. When run from
#              the command line, the call is in the format: Rscript --vanilla
#              /ofo-share/utils/tree-map-comparison/run-tree-map-comparison.R
#              {observed tree points file path} {predicted tree points directory path}

# access the command line call
hyperparam_args = commandArgs(trailingOnly=TRUE)

# check the number of hyperparameters passed in
if (length(hyperparam_args) != 4) {
  stop("Wrong number of hyperparameters provided in command call - please provide 4")
}

# access hyperparameter values
in_ortho = as.character(hyperparam_args[1])
patch_size = as.numeric(hyperparam_args[2])
patch_overlap = as.numeric(hyperparam_args[3])
ortho_resolution = as.numeric(hyperparam_args[4])
iou_threshold = as.numeric(command_args[5])
bbox_gpkg_out = as.character(command_args[6])


# call run-deepforest-prediction-from-command-line.py with params
cat("\nStarting detection for", bbox_gpkg_out, "\n")

call = paste("python3 /ofo-share/repos-max/cv-treedetection-eval_max/run-deepforest-predictions/run-deepforest-prediction-from-command-line.py", in_ortho, patch_size, patch_overlap, ortho_resolution, iou_threshold, bbox_gpkg_out, sep = " ")
system(call)

# call convert-deepforest-bboxes-to-treetops.R

# run-tree-map-comparison.R - save comparison stats to specified file location
