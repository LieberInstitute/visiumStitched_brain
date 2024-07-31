#   A version of 03_precast.* but using capture area as sample ID and initial
#   array coordinates from spaceranger

library(getopt)
library(sessioninfo)
library(here)
library(PRECAST)
library(HDF5Array)
library(Seurat)
library(tidyverse)
library(Matrix)
library(SpatialExperiment)

# Import command-line parameters (value of k)
spec <- matrix(c("k", "k", "1", "numeric", "Number of clusters"), ncol = 5)
opt <- getopt(spec)

print("Using the following parameters:")
print(opt)

spe_dir = here('processed-data', '03_stitching', 'spe')
out_path = here(
    'processed-data', '03_stitching', 'precast_out_unstitched',
    sprintf('PRECAST_k%s.csv', opt$k)
)

num_hvgs = 2000

set.seed(1)
dir.create(dirname(out_path), showWarnings = FALSE)

spe = loadHDF5SummarizedExperiment(spe_dir)

#   PRECAST expects array coordinates in 'row' and 'col' columns. Use unstitched
#   coordinates intentionally
spe$row = spe$array_row_original
spe$col = spe$array_col_original

#   Create a list of (just one) Seurat object at the group level
seu_list = lapply(
    unique(spe$group),
    function(group) {
        small_spe = spe[, spe$group == group]

        CreateSeuratObject(
            #   Bring into memory to greatly improve speed
            counts = as(assays(small_spe)$counts, "dgCMatrix"),
            meta.data = as.data.frame(colData(small_spe)),
            project = 'visiumStitched_brain'
        )
    }
)

pre_obj = CreatePRECASTObject(
    seuList = seu_list,
    selectGenesMethod = "HVGs",
    gene.number = num_hvgs
)

pre_obj <- AddAdjList(pre_obj, platform = "Visium")

#   Following https://feiyoung.github.io/PRECAST/articles/PRECAST.BreastCancer.html,
#   which involves overriding some default values, though the implications are not
#   documented
pre_obj <- AddParSetting(
    pre_obj, Sigma_equal = FALSE, verbose = TRUE, maxIter = 30
)

#   Fit model
pre_obj <- PRECAST(pre_obj, K = opt$k)
pre_obj <- SelectModel(pre_obj)
pre_obj = IntegrateSpaData(pre_obj, species = "Human")

#   Extract PRECAST results, clean up column names, and export to CSV
pre_obj@meta.data |>
    rownames_to_column("key") |>
    as_tibble() |>
    select(-orig.ident) |>
    rename_with(~ sub('_PRE_CAST', '', .x)) |>
    write_csv(out_path)

session_info()
