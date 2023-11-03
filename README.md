# cv-treedetection-eval

Exploration/Evaluation of DeepForest for Tree Detection

*These scripts are intended to provide a preliminary approach for performing tree detection with DeepForest on the OFO's Emerald Point dataset.*

## `run-deepforest-predictions` Scripts Folder

**`run-deepforest-eval-pipeline.R`:** This script runs a given set of DeepForest predict_tile hyperparameters through the DeepForest evaluation pipeline, starting from a set of parameters and ending with the corresponding f-score. It is designed to be run from the command line in the format: `Rscript --vanilla /ofo-share/repos-max/cv-treedetection-eval_max/run-deepforest-predictions/run-deepforest-eval-pipeline.R {in_ortho} {data_dir} {chm_dir} {patch_size} {patch_overlap} {ortho_resolution} {iou_threshold}`

**`run-deepforest-hyperparam-combinations.R`:** This script runs DeepForest (using predict_tile) on a forest orthomosaic on a range of a specified parameter via run-deepforest-prediction-from-command-line.py. It saves the detected tree bounding boxes as a .gpkg with the same name as the orthomosaic, followed by the parameter value.

**`run-deepforest-prediction-from-command-line.py`:** This script streamlines calling DeepForest from R, expecially calling it multiple times with different parameters. The script can be called from the command line and is a wrapper for several functions in DeepForest (primarily predict_tile and bboxes_to_shapefile). The structure of the command line call is: `python3 run-deepforest-prediction-from-command-line.py {orthomosaic file path} {window size} {output bounding box gpkg file path}`

**`convert-deepforest-bboxes-to-treetops.R`:** This script reads in bounding boxes (bboxes) of trees predicted by DeepForest and converts them to treetop points for comparison against a reference stem map. This process involves extracting heights from a CHM (since deepforest does not produce height estimates of trees). The user specifies a folder of bbox files (e.g., each one from a different run of deepforest) and a CHM. The script converts each bbox file to a corresponding treetop points file. Each bbox file to be processed is expected to be in the format: `*_bboxes.gpkg`. The script can optionally be called from the command line in the format: `Rscript --vanilla /ofo-share/repos-max/cv-treedetection-eval_max/run-deepforest-predictions/convert-deepforest-bboxes-to-treetops.R {BBOXES_DIR} {CHM_FILEPATH} {OUT_DIR}`

## `evaluate-single-params` Scripts Folder

**`eval-single-param-fscore.R`:** This script uses statistics from `run-tree-map-comparison.R` (a script that compares predicted and observed tree maps) to summarize data contained in "stats_ ... .csv" files. It aims to identify an optimal parameter for two tree categories (i.e. 10+, overstory and 10+/20+, all trees) based on the given parameter range.

## `evaluate-multi-params` Scripts Folder

**`run-deepforest-random-search.R`:** This script performs hyperparameter optimization with random search for DeepForest (using predict_tile). It searches across specified hyperparameter ranges for a specified number of iterations, calling run-deepforest-eval-pipeline.R for each hyperparameter combination.

**`eval-deepforest-random-search.R`:** This script uses f-scores from `run-tree-map-comparison.R` (a script that compares predicted and observed tree maps) to identify the highest performing hyperparameter combination from a random search. It also aims to visualize the f-scores according to hyperparameter combinations via a pairwise scatter plot and parallel coordinates plot.

## Data Files Associated with this Repo

Data files associated with this repo are on [Box](https://ucdavis.box.com/s/4uqts0zc8h52znl5avurjwntm2bn4w92) and on Jetstream2 at `/ofo-share/cv-treedetection-eval_data/`. Key files/folders the data folder: - `observed-trees/observed-trees.geojson`: The ground-mapped set of tree points to use as a reference for evaluating predicted treetops against - `perimeters/emerald-point-perimeter.geojson`: The perimeter of the ground-mapped area - `photogrammetry-outputs/emerald-point_10a-20230103T2008/`: The orthomosaic and CHM of the study area - `predicted-trees/`: The folder to put new sets of tree detections into (probably under a subfolder(s) with descriptive name) - `predicted-trees/lmf/lmf-best.gpkg`: A set of treetop points detected using a "traditional" CHM-based algorithm called LMF (local maximum filter), for testing of the tree-map-comparison scripts and to use as a baseline performance score in hopes of improving upon it with CV-based methods
