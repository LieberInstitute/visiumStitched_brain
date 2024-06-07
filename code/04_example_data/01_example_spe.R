#   Build a lightweight SpatialExperiment that can be used as data in the
#   visiumStitched package

library(here)
library(tidyverse)
library(sessioninfo)
library(Matrix)
library(SpatialExperiment)
library(HDF5Array)

spe_in_dir = here('processed-data', '03_stitching', 'spe')
spe_out_path = here('processed-data', '04_example_data', 'Visium_LS_spe.rds')
sr_subset_dir = here('processed-data', '04_example_data', ''
info_path = here('processed-data', '03_stitching', 'sample_info.csv')

dir.create(dirname(spe_out_path), showWarnings = FALSE)

#   Only include logcounts as a sparse in-memory matrix. Otherwise, save the
#   object as is
spe = loadHDF5SummarizedExperiment(spe_in_dir)
assays(spe) = list(logcounts = as(assays(spe)$logcounts, "dgCMatrix"))
saveRDS(spe, spe_out_path)

sample_info = read_csv(info_path, show_col_types = FALSE)

session_info()
