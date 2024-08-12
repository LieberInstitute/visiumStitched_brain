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

spe <- loadHDF5SummarizedExperiment(spe_in_dir)

## From
## https://bioconductor.org/packages/release/bioc/vignettes/scran/inst/doc/scran.html#3_Variance_modelling
dec <- modelGeneVar(spe, block = spe$capture_area)
top_hvgs <- getTopHVGs(dec, prop = 0.1)

spe = runPCA(spe, subset_row = top_hvgs, ncomponents = 50)
spe <- RunHarmony(spe, "capture_area", verbose = FALSE)

saveHDF5SummarizedExperiment(spe, spe_out_dir)
writeLines(top_hvgs, con = hvg_out_path)
