# Title: Evaluate DeepForest Random Search Hyperparameter Combinations
# Description: This script uses f-scores from run-tree-map-comparison.R (a
#              script that compares predicted and observed tree maps) to identify
#              the highest performing hyperparameter combination from a random search.
#              It also aims to visualize the f-scores according to hyperparameter
#              combinations via a pairwise scatter plot and parallel coordinates plot.

library(tidyverse)
library(GGally)
library(viridis)
library(hrbrthemes)

#### CONSTANTS ####
STATS_DIR = "/ofo-share/repos-max/multi-param-data" # path to folder that contains stat csv files
OUT_DIR = "/ofo-share/repos-max/multi-param-data/plots" # path to save plot pngs

PAIRWISE_PLOT_NAME = "pairwise-scatter-plot" # file name to assign to plot png
PARALLEL_PLOT_NAME = "parallel-coordinates-plot "# file name to assign to plot png


#### DATA LOADING ####
if(!dir.exists(OUT_DIR)) {
  dir.create(OUT_DIR, recursive = TRUE)
}

# load stats CSV files and paths
stats_files = list.files(STATS_DIR, pattern = "^stats.*\\.csv$")
stats_paths = file.path(STATS_DIR, stats_files)

# read and clean CSV files
stats = stats_paths %>%
  # read stats CSV files into one dataframe
  map_dfr(read_csv) %>%
  # calculate the absolute difference between sensitivity and precision
  mutate(sen_pre_difference = abs(sensitivity - precision)) %>%
  # remove unneeded columns
  select(predicted_tree_dataset_name, canopy_position, height_cat, f_score, height_cor,
         sen_pre_difference) %>%
  # remove unneeded rows
  filter(canopy_position == "overstory" & height_cat == "10+")


#### DATA PROCESSING ####
stats = stats %>%
  # extract hyperparameter values from csv file name
  separate(predicted_tree_dataset_name,
           into = c("ttops", "ortho", "patch_size", "patch_overlay", "ortho_resolution", "iso_threshold"),
           sep = "_", extra = "merge", fill = "right") %>%
  # remove prefix columns
  select(-ttops, -ortho) %>%
  # convert from character to numerical values
  mutate(across(c(patch_size, patch_overlay, ortho_resolution, iso_threshold),
                ~ as.numeric(gsub("[A-Z]+-", "", .))))

# find the row with the highest f_score
optimal_combination = stats[which.max(stats$f_score), ]

# extract hyperparameter values from the row with highest f-score
best_patch_size = optimal_combination$patch_size
best_patch_overlay = optimal_combination$patch_overlay
best_ortho_resolution = optimal_combination$ortho_resolution
best_iso_threshold = optimal_combination$iso_threshold

# display the optimal hyperparameter combination
cat("Optimal Hyperparameter Combination:\n")
cat("Patch Size:", best_patch_size, "\n")
cat("Patch Overlay:", best_patch_overlay, "\n")
cat("Ortho Resolution:", best_ortho_resolution, "\n")
cat("ISO Threshold:", best_iso_threshold, "\n")
cat("F-Score:", optimal_combination$f_score, "\n")

#### PLOTTING ####
# create a pairwise scatter plot
plot_data = select(stats, patch_size, patch_overlay, ortho_resolution, iso_threshold,
                   f_score)
pairwise_plot = ggpairs(plot_data, lower=list(continuous=wrap("points", size=0.6))) +
  labs(title="DeepForest Random Search Pairwise Scatter Plot")

# save the plot as a PNG file
pairwise_plot_name = paste0(OUT_DIR, "/", PAIRWISE_PLOT_NAME, ".png")
ggsave(pairwise_plot_name, plot=pairwise_plot, width=8, height=6)

# create a parallel coordinates plot
parallel_plot = ggparcoord(plot_data, showPoints=TRUE, scale="uniminmax",
  title="DeepForest Random Search Parallel Coordinate Plot",
  alphaLines=0.3, groupColumn = "f_score") +
  scale_color_viridis(option = "F") +
  theme_ipsum() +
  theme(plot.title = element_text(size=10))

# save the plot as a PNG file
parallel_plot_name = paste0(OUT_DIR, "/", PARALLEL_PLOT_NAME, ".png")
ggsave(parallel_plot_name, plot=parallel_plot, width=8, height=6)
