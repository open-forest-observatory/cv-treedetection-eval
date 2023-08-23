# Title: Preliminary Single Parameter Tree Detection Evaluation
# Description: This script uses statistics from run-tree-map-comparison.R (a
#              script that compares predicted and observed tree maps) to summarize
#              data contained in "stats_ ... .csv" files. It aims to identify an
#              optimal parameter for two tree categories (i.e. 10+, overstory and
#              10+/20+, all trees) based on the given parameter range.

library(tidyverse)

#### CONSTANTS ####
STATS_DIR = "..." # path to folder containing match_stats.csv files
OUT_DIR = "..." # path to save plot png

PLOT_FILE_NAME = "...-plot" # file name to assign to plot png
SINGLE_PARAM = "..." # the parameter of interest

MIN_HEIGHT_COR = 0.85 # minimum acceptable height correlation
MAX_SEN_PRE_DIFF = 0.5 # maximum acceptable difference between sensitivity and precision


#### DATA LOADING ####
if(!dir.exists(OUT_DIR)) {
  dir.create(OUT_DIR, recursive = TRUE)
}

# load stats CSV files and paths
stats_files = list.files(STATS_DIR)
stats_paths = file.path(STATS_DIR, stats_files)

# read and clean CSV files
stats = stats_paths %>%
  # read stats CSV files into one dataframe
  map_dfr(read_csv) %>%
  # calculate the absolute difference between sensitivity and precision
  mutate(sen_pre_difference = abs(sensitivity - precision)) %>%
  # remove unneeded stats
  select(predicted_tree_dataset_name, canopy_position, height_cat, f_score, height_cor,
         sen_pre_difference)


#### DATA PROCESSING ####
# calculate mean stats of all tree categories (10+/20+, all/overstory)
all_cat_stats = stats %>%
  group_by(predicted_tree_dataset_name) %>%
  summarise(across(where(is.numeric), mean, .names = "mean_{.col}")) %>%
  ungroup()

# combine and finish cleaning stats dataframe
stats = stats %>%
  # filter stats to contain only 10+, overstory tree category
  filter(canopy_position == "overstory" & height_cat == "10+") %>%
  # merge stats (10+, overstory) and all_cat_stats (10+/20+, all/overstory)
  merge(all_cat_stats, by = "predicted_tree_dataset_name") %>%
  # extract the single parameter name from file name
  mutate({{SINGLE_PARAM}} := as.numeric(str_extract(predicted_tree_dataset_name,
                                                    "\\d*\\.?\\d+$"))) %>% # change as needed
  # remove canopy_position and height_cat columns
  select(-canopy_position, -height_cat, -predicted_tree_dataset_name)

# verify height correlations and sensitivity/precision differences
height_cor_are_passing = all(stats$height_cor > MIN_HEIGHT_COR) &
                         all(stats$mean_height_cor > MIN_HEIGHT_COR)
diff_are_passing = all(stats$sen_pre_difference < MAX_SEN_PRE_DIFF) &
                   all(stats$sen_pre_difference < MAX_SEN_PRE_DIFF)

# print out status of height correlations and sensitivity/precision differences
height_cor_msg = paste("Height Correlations are above", MIN_HEIGHT_COR, ":",
                       height_cor_are_passing)
diff_msg = paste("Sensitivity - Precision Differences are below", MAX_SEN_PRE_DIFF,
                 ":", diff_are_passing)
cat(height_cor_msg, "\n", diff_msg)


#### PLOTTING ####
# plot f scores and mean f scores
optimal_param = stats[[SINGLE_PARAM]][which.max(stats$f_score)]
p = ggplot(stats, aes(x = .data[[SINGLE_PARAM]], y = f_score)) +
    geom_line(aes(color = "10+ Overstory F Score")) +
    geom_line(aes(y = mean_f_score, color = "10+/20+ All F Score")) +
    labs(x = SINGLE_PARAM, y = "F Score", 
         title = paste("F Score vs.", SINGLE_PARAM, "- Single Parameter Evaluation")) +
    scale_color_manual(values = c("#1f78b4", "#33a02c"), 
                       labels = c("10+ Overstory F Score", "10+/20+ All F Score")) +
    theme_minimal() +
    theme(plot.title = element_text(hjust = 0.5), aspect.ratio = 1/2) + 
    geom_text(
      x = optimal_param,
      y = max(stats$f_score),
      label = paste("Optimal Parameter:", optimal_param),
      hjust = 0, # adjust as needed
      vjust = 10, # adjust as needed
    ) +
    guides(color = guide_legend(title = NULL))

# save plot
ggsave(file.path(OUT_DIR, paste0(PLOT_FILE_NAME, ".png")), plot = p, width = 10,
       height = 5)

