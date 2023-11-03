# Title: Run A Hyperparameter Combination Through the Parameter Evaluation Pipeline
# Description: This script runs a given set of DeepForest predict_tile hyperparameters
#              through the DeepForest evaluation pipeline, starting from a set of
#              parameters and ending with the parameters' corresponding f-score.
#              It is designed to be run from the command line in the format: Rscript
#              --vanilla /ofo-share/repos-max/cv-treedetection-eval_max/run-deepforest-predictions
#              /run-deepforest-eval-pipeline.R {in_ortho} {data_dir} {chm_dir}
#              {patch_size} {patch_overlap} {ortho_resolution} {iou_threshold}

#### CONSTANTS ####
# constants only need to be changed if location of scripts change
RUN_DEEPFOREST_PREDICTION_FROM_COMMAND_LINE_DIR = "/ofo-share/repos-max/cv-treedetection-eval_max/run-deepforest-predictions/run-deepforest-prediction-from-command-line.py"
CONVERT_DEEPFOREST_BBOXES_TO_TREETOPS_DIR = "/ofo-share/repos-max/cv-treedetection-eval_max/run-deepforest-predictions/convert-deepforest-bboxes-to-treetops.R"
RUN_TREE_MAP_COMPARISON_DIR = "/ofo-share/utils/tree-map-comparison/run-tree-map-comparison.R"


#### SCRIPT CALLING PREPARATION ####
# access the command line call
hyperparam_args = commandArgs(trailingOnly=TRUE)

# verify the number of arguments passed in
if (length(hyperparam_args) != 9) {
  stop("Error: Invalid number of arugments provided.")
}

# assign hyperparameter values
in_ortho = hyperparam_args[1]
data_dir = hyperparam_args[2]
chm_dir = hyperparam_args[3]
observed_trees_dir = hyperparam_args[4]
plot_bound_dir = hyperparam_args[5]
patch_size = hyperparam_args[6]
patch_overlap = hyperparam_args[7]
ortho_resolution = hyperparam_args[8]
iou_threshold = hyperparam_args[9]

# define a function to create/clear directories
create_clear_dir = function(new_subdir) {
  cur_dir = paste0(data_dir, "/", new_subdir)
  if (dir.exists(cur_dir)) {
    unlink(cur_dir, recursive=TRUE)
  }
  dir.create(cur_dir)
  return(cur_dir)
}

# create/clear directories
bbox_gpkg_folder = create_clear_dir("temp-bboxes")
ttop_gpkg_folder = create_clear_dir("temp-ttops")
stats_gpkg_folder = create_clear_dir("temp-stats")

# create base name - (e.g. PS-1200 refers to a patch size of 1200)
base_name = paste0("PS-", patch_size, "_PO-", patch_overlap, "_OR-", ortho_resolution, 
                   "_IT-", iou_threshold)


#### SCRIPT CALLING ####
# define a function to call external scripts
call_script = function(command, script_path, args) {
  call = paste(command, script_path, paste(args, collapse = " "), sep = " ")
  system(call)
}

# call run-deepforest-prediction-from-command-line.py
bbox_gpkg_out = paste0(bbox_gpkg_folder,"/bboxes_ortho_", base_name, ".gpkg")
cat("\n", base_name, ": Running DeepForest Prediction From Command Line...", "\n")
call_script("python3", RUN_DEEPFOREST_PREDICTION_FROM_COMMAND_LINE_DIR,
            c(in_ortho, patch_size, patch_overlap, ortho_resolution, iou_threshold,
              bbox_gpkg_out))

# call convert-deepforest-bboxes-to-treetops.R
cat("\n", base_name, ": Converting DeepForest bboxes to Treetops...", "\n")
call_script("Rscript --vanilla", CONVERT_DEEPFOREST_BBOXES_TO_TREETOPS_DIR,
                     c(bbox_gpkg_folder, chm_dir, ttop_gpkg_folder))

# call run-tree-map-comparison.R
cat("\n", base_name, ": Running Tree Map Comparison", "\n")
call_script("Rscript --vanilla", RUN_TREE_MAP_COMPARISON_DIR,
                     c(observed_trees_dir, ttop_gpkg_folder, plot_bound_dir,
                       ttop_gpkg_folder, stats_gpkg_folder))

# move resulting statistics csv out of temp-stats
cur_csv_dir = paste0(stats_gpkg_folder, "/tree_detection_evals/stats_ttops_ortho_",
                     base_name, ".csv")
new_csv_dir = paste0(data_dir, "/stats_", base_name, ".csv")
file.rename(cur_csv_dir, new_csv_dir)
