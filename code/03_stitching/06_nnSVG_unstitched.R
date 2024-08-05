library(SpatialExperiment)
library(here)
library(tidyverse)
library(sessioninfo)
library(HDF5Array)
library(Matrix)
library(nnSVG)

spe_dir <- here("processed-data", "03_stitching", "spe")

message(Sys.time(), " | Loading SpatialExperiment")
spe <- loadHDF5SummarizedExperiment(spe_dir)
sample_id <- levels(spe$capture_area)[
    as.integer(Sys.getenv("SLURM_ARRAY_TASK_ID"))
]

out_path <- here(
    "processed-data", "03_stitching", "nnSVG_out_unstitched",
    paste0(sample_id, ".csv")
)

set.seed(0)
dir.create(dirname(out_path), showWarnings = FALSE)

#-------------------------------------------------------------------------------
#   Subset to this sample and bring into memory for speed
#-------------------------------------------------------------------------------

message(Sys.time(), " | Subsetting to this capture area and bringing into memory")
spe <- spe[, spe$capture_area == sample_id]
assays(spe) <- list(
    counts = as(assays(spe)$counts, "dgCMatrix"),
    logcounts = as(assays(spe)$logcounts, "dgCMatrix")
)

#-------------------------------------------------------------------------------
#   Use unstitched spatial coordinates
#-------------------------------------------------------------------------------

spatialCoords(spe)[,'pxl_col_in_fullres'] = as.integer(
    spe$pxl_col_in_fullres_original
)
spatialCoords(spe)[,'pxl_row_in_fullres'] = as.integer(
    spe$pxl_row_in_fullres_original
)

#-------------------------------------------------------------------------------
#   Filter lowly expressed and mitochondrial genes
#-------------------------------------------------------------------------------

message(Sys.time(), " | Filtering genes and spots")
spe <- filter_genes(
    spe,
    filter_genes_ncounts = 3,
    filter_genes_pcspots = 0.5,
    filter_mito = TRUE
)
message("Dimensions of spe after filtering:")
print(dim(spe))

#-------------------------------------------------------------------------------
#   Run nnSVG and export results
#-------------------------------------------------------------------------------

message(Sys.time(), " | Running nnSVG")
spe <- nnSVG(spe)

message(Sys.time(), " | Exporting results")
write_csv(as_tibble(rowData(spe)), out_path)

session_info()
