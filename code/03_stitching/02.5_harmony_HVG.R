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
svg_stitched_path = here(
    "processed-data", "03_stitching", "nnSVG_out", "top500_SVGs.txt"
)
svg_unstitched_path = here(
    "processed-data", "03_stitching", "nnSVG_out_unstitched", "top500_SVGs.txt"
)

spe <- loadHDF5SummarizedExperiment(spe_in_dir)

## From
## https://bioconductor.org/packages/release/bioc/vignettes/scran/inst/doc/scran.html#3_Variance_modelling
#   Not blocking by capture area, since we're interested in variation across
#   the whole brain region, not each capture area
dec <- modelGeneVar(spe)
top_hvgs <- getTopHVGs(dec, prop = 0.1)

#   Read in SVGs (stitched and unstitched)
svgs_stitched = readLines(svg_stitched_path)
svgs_unstitched = readLines(svg_unstitched_path)

#   Run versions of PCA subset to HVGs and to SVGs (stitched and unstitched).
#   Note that HVGs don't have stitched and unstitched versions, since stitching
#   is inherently a spatial operation
spe = runPCA(spe, subset_row = top_hvgs, ncomponents = 50, name = "PCA_HVG")
spe = runPCA(
    spe, subset_row = svgs_stitched, ncomponents = 50, name = "PCA_SVG_stitched"
)
spe = runPCA(
    spe, subset_row = svgs_unstitched, ncomponents = 50,
    name = "PCA_SVG_unstitched"
)

#   Run Harmony on all 3 versions of PCA
reducedDims(spe)$PCA = reducedDims(spe)$PCA_HVG
spe <- RunHarmony(
    spe, group.by.vars = "capture_area", reduction.save = "HARMONY_HVG",
    verbose = FALSE
)

reducedDims(spe)$PCA = reducedDims(spe)$PCA_SVG_stitched
spe <- RunHarmony(
    spe, group.by.vars = "capture_area",
    reduction.save = "HARMONY_SVG_stitched", verbose = FALSE
)

reducedDims(spe)$PCA = reducedDims(spe)$PCA_SVG_unstitched
spe <- RunHarmony(
    spe, group.by.vars = "capture_area",
    reduction.save = "HARMONY_SVG_unstitched", verbose = FALSE
)

reducedDims(spe)$PCA = NULL
saveHDF5SummarizedExperiment(spe, spe_out_dir)
writeLines(top_hvgs, con = hvg_out_path)

session_info()
