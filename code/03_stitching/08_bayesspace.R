library(getopt)
library(sessioninfo)
library(here)
library(SpatialExperiment)
library(BayesSpace)
library(tidyverse)
library(HDF5Array)

# Import command-line parameters
spec <- matrix(
    c(
        c("stitched_var", "gene_var", "k"),
        c("s", "g", "k"),
        rep("1", 3),
        c("character", "character", "integer"),
        rep("Add variable description here", 3)
    ),
    ncol = 5
)
opt <- getopt(spec)

print("Using the following parameters:")
print(opt)

spe_dir <- here("processed-data", "03_stitching", "spe_harmony")
out_path = here(
    "processed-data", "03_stitching", "bayesspace_out",
    sprintf('k%s_%s_%s.csv', opt$k, opt$stitched_var, opt$gene_var)
)

#   Name of harmony dimension to use as input 
if (opt$gene_var == "HVG") {
    harmony_name = "HARMONY_HVG"
} else {
    harmony_name = sprintf("HARMONY_%s_%s", opt$stitched_var, opt$gene_var)
}

set.seed(1)
dir.create(dirname(out_path), showWarnings = FALSE)

spe = loadHDF5SummarizedExperiment(spe_dir)

if (opt$stitched_var == "unstitched") {
    #   Treat capture areas as spatially separate by isolating each in its own
    #   range of 'array_row'
    offset_row <- as.numeric(factor(spe$capture_area)) * 100
    spe$row = spe$array_row_original + offset_row
    spe$col = spe$array_col_original
} else {
    #   Use stitched array coordinates
    spe$row = spe$array_row
    spe$col = spe$array_col
}

## Set the BayesSpace metadata using code from
## https://github.com/edward130603/BayesSpace/blob/master/R/spatialPreprocess.R#L43-L46
metadata(spe)$BayesSpace.data <- list(platform = "Visium", is.enhanced = FALSE)

#   Run main clustering step
message("Running spatialCluster()")
Sys.time()
spe <- spatialCluster(spe, use.dimred = harmony_name, q = opt$k)
Sys.time()

#   Write cluster assigments (along with spot key) to CSV
colData(spe) |>
    as_tibble() |>
    select(key, spatial.cluster) |>
    rename(cluster_assignment = spatial.cluster) |>
    write_csv(out_path)

session_info()

## This script was made using slurmjobs version 1.2.2
## available from http://research.libd.org/slurmjobs/
