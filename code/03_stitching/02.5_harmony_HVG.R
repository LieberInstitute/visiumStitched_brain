library(sessioninfo)
library(here)
library(HDF5Array)
library(SpatialExperiment)
library(harmony)
library(scran)
library(scater)

set.seed(1)

spe_in_dir <- here("processed-data", "03_stitching", "spe")
spe_out_dir <- here("processed-data", "03_stitching", "spe_harmony")
hvg_out_path = here("processed-data", "03_stitching", "HVGs.txt")

spe <- loadHDF5SummarizedExperiment(spe_dir)

saveHDF5SummarizedExperiment(spe, spe_out_dir)
writeLines(top_hvgs, con = hvg_out_path)
