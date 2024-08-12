library(getopt)
library(sessioninfo)
library(here)
library(PRECAST)
library(HDF5Array)
library(Seurat)
library(tidyverse)
library(Matrix)
library(SpatialExperiment)

# Import command-line parameters
spec <- matrix(
    c(
        "k", "k", "1", "numeric", "Number of clusters",
        "input_genes", "i", "1", "character", "'HVG' or 'SVG'"
    ),
    ncol = 5, byrow = TRUE
)
opt <- getopt(spec)

print("Using the following parameters:")
print(opt)

spe_dir <- here("processed-data", "03_stitching", "spe")
if (opt$input_genes == "HVG") {
    out_path <- here(
        "processed-data", "03_stitching", "precast_out",
        sprintf("PRECAST_k%s.csv", opt$k)
    )
    hvg_path = here("processed-data", "03_stitching", "HVGs.txt")
} else {
    out_path <- here(
        "processed-data", "03_stitching", "precast_out",
        sprintf("PRECAST_k%s_SVG.csv", opt$k)
    )
    svg_path = here(
        "processed-data", "03_stitching", "nnSVG_out", "top500_SVGs.txt"
    )
}

set.seed(1)
dir.create(dirname(out_path), showWarnings = FALSE)

spe <- loadHDF5SummarizedExperiment(spe_dir)

#   PRECAST expects array coordinates in 'row' and 'col' columns
spe$row <- spe$array_row
spe$col <- spe$array_col

#   Create a list of (just one) Seurat object at the group level
seu_list <- lapply(
    unique(spe$group),
    function(group) {
        small_spe <- spe[, spe$group == group]

        CreateSeuratObject(
            #   Bring into memory to greatly improve speed
            counts = as(assays(small_spe)$counts, "dgCMatrix"),
            meta.data = as.data.frame(colData(small_spe)),
            project = "visiumStitched_brain"
        )
    }
)

#   Run PRECAST using either HVGs or SVGs as input.
if (opt$input_genes == "HVG") {
    pre_obj <- CreatePRECASTObject(
        seuList = seu_list,
        selectGenesMethod = NULL,
        customGenelist = readLines(hvg_path),
        #   Here defaults are multiplied by 3 to reflect the fact that we're
        #   including spots from 3 capture areas, not 1
        premin.spots = 60,
        postmin.spots = 45
    )
} else {
    pre_obj <- CreatePRECASTObject(
        seuList = seu_list,
        selectGenesMethod = NULL,
        customGenelist = readLines(svg_path),
        #   Here defaults are multiplied by 3 to reflect the fact that we're
        #   including spots from 3 capture areas, not 1. Note that really,
        #   'premin.spots' and 'postmin.spots' were meant to be set to 0 to
        #   not perform additional filtering of input SVGs, but by
        #   coincidence, the actual values were low enough to retain all SVGs
        premin.spots = 60,
        postmin.spots = 45
    )
}

#   Setting platform to "Visium" just means to use array indices, which should
#   work fine despite the abnormal/ "artificial" capture area we've created by
#   stitching
pre_obj <- AddAdjList(pre_obj, platform = "Visium")

#   Following https://feiyoung.github.io/PRECAST/articles/PRECAST.BreastCancer.html,
#   which involves overriding some default values, though the implications are not
#   documented
pre_obj <- AddParSetting(
    pre_obj,
    Sigma_equal = FALSE, verbose = TRUE, maxIter = 30
)

#   Fit model
pre_obj <- PRECAST(pre_obj, K = opt$k)
pre_obj <- SelectModel(pre_obj)
pre_obj <- IntegrateSpaData(pre_obj, species = "Human")

#   Extract PRECAST results, clean up column names, and export to CSV
pre_obj@meta.data |>
    rownames_to_column("key") |>
    as_tibble() |>
    select(-orig.ident) |>
    rename_with(~ sub("_PRE_CAST", "", .x)) |>
    write_csv(out_path)

session_info()
