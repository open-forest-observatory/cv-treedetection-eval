# cv-treedetection-eval

Evaluation of computer vision-based tools for tree detection

## Scripts in `scripts-for-reference/`

These scripts are intended to provide a starting point and examples for performing tree detection with DeepForest on the OFO's Emerald Point dataset.

**`run-deepforest-prediction-from-command-line.py`:** This script does not need to be run directly. It is a helper script for `run-deepforest-multiple-ways.R`. This script can be called from the command line. It is a wrapper for several functions in DeepForest (primarily [predict_tile](https://deepforest.readthedocs.io/en/latest/source/deepforest.html#deepforest.main.deepforest.predict_tile) and bboxes_to_shapefile). This streamlines calling DeepForest from R, expecially calling it multiple times with different parameters. The structure of the command line call is: `python3 run-deepforest-prediction-from-command-line.py {orthomosaic file path} {window size} {output bounding box gpkg file path}`

**`run-deepforest-multiple-ways.R`:** Runs DeepForest on a forest orthomosaic, testing multiple different window sizes (a parameter of DeepForest tree detection) as specified within the script. It saves the detected tree bounding boxes as a series of .gpkg files with the same name as the orthomosaic, followed by the window size. The input and output file paths are set in this script under the header "CONSTANTS".

**`convert-deepforest-bboxes-to-treetops.R`:** Reads in bounding boxes (bboxes) of trees predicted by DeepForest and converts them to treetop points for comparison against a reference stem map. Part of this process involves extracting heights from a CHM (since deepforest does not produce height estimates of trees). The user specifies a folder of bbox files (e.g., each one from a different run of deepforest) and a CHM. The script converts each bbox set to a corresponding treetop points file. Each bbox file to be processed is expected to be in the format: `*_bboxes.gpkg`.

## Data files associated with this repo

Data files associated with this repo are on [Box](https://ucdavis.box.com/s/4uqts0zc8h52znl5avurjwntm2bn4w92) and on Jetstream2 at `/ofo-share/cv-treedetection-eval_data/`. Key files/folders the data folder: - `observed-trees/observed-trees.geojson`: The ground-mapped set of tree points to use as a reference for evaluating predicted treetops against - `perimeters/emerald-point-perimeter.geojson`: The perimeter of the ground-mapped area - `photogrammetry-outputs/emerald-point_10a-20230103T2008/`: The orthomosaic and CHM of the study area - `predicted-trees/`: The folder to put new sets of tree detections into (probably under a subfolder(s) with descriptive name) - `predicted-trees/lmf/lmf-best.gpkg`: A set of treetop points detected using a "traditional" CHM-based algorithm called LMF (local maximum filter), for testing of the tree-map-comparison scripts and to use as a baseline performance score in hopes of improving upon it with CV-based methods

## To do

-   Run [DeepForest](https://deepforest.readthedocs.io/en/latest/index.html) tree detection on the Emerald Point orthomosaic (see below) wtih different combinations of the following parameters:
    -   patch_size (aka "window size" in the scripts above) - parameter of `predict_tile`
        -   the script `run-deepforest-multiple-ways.R` is already set up to run tree detection with a range of patch sizes
    -   patch_overlap - parameter of `predict_tile`
    -   other parameters of `predict_tile`?
    -   resolution of the provided orthomosaic
-   Compare the DeepForest tree detections against the ground-measured reference tree map using the scripts in the repo [tree-map-comparison](https://github.com/open-forest-observatory/tree-map-comparison)
    -   This repo is already cloned to `/ofo-share/utils/tree-map-comparison`
    -   Try first filtering out predicted trees with a low confidence score (and test different filter thresholds)
-   Repeat the above with [Detectree2](https://github.com/PatBall1/detectree2), its relevant parameters, and different resolutions of the orthomosaic
