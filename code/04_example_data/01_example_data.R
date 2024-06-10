#   Build a lightweight but complete SpatialExperiment to host as data through
#   spatialLIBD and for examples in the visiumStitched package. Use symlinks to
#   create a directory containing just the spaceranger components needed by
#   visiumStitched::build_spe() (also to host through spatialLIBD as an
#   ExperimentHub package)

library(here)
library(tidyverse)
library(sessioninfo)
library(Matrix)
library(SpatialExperiment)
library(HDF5Array)

spe_in_dir = here('processed-data', '03_stitching', 'spe')
spe_out_path = here('processed-data', '04_example_data', 'Visium_LS_spe.rds')
sr_subset_dir = here('processed-data', '04_example_data', 'spaceranger_subset')
sr_full_dir = here('processed-data', '01_spaceranger')
info_path = here('processed-data', '03_stitching', 'sample_info.csv')

dir.create(dirname(spe_out_path), showWarnings = FALSE)

#   Only include logcounts as a sparse in-memory matrix. Otherwise, save the
#   object as is
spe = loadHDF5SummarizedExperiment(spe_in_dir)
assays(spe) = list(logcounts = as(assays(spe)$logcounts, "dgCMatrix"))
saveRDS(spe, spe_out_path)

sample_info = read_csv(info_path, show_col_types = FALSE)

src_dir = as.character(
    outer(
        dirname(sample_info$spaceranger_dir), 
        c('raw_feature_bc_matrix', 'spatial'),
        FUN = file.path
    )
)
stopifnot(all(dir.exists(src_dir)))

dest_dir = str_replace(src_dir, sr_full_dir, sr_subset_dir)
sapply(dirname(dest_dir), dir.create, recursive = TRUE, showWarnings = FALSE)

all(file.symlink(src_dir, dest_dir))

session_info()
