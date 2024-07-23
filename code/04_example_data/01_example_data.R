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
library(scater)

spe_in_dir = here('processed-data', '03_stitching', 'spe')
spe_out_path = here('processed-data', '04_example_data', 'visiumStitched_brain_spe.rds')
sr_subset_dir = here('processed-data', '04_example_data', 'spaceranger_subset')
sr_subset_zip = here(
    'processed-data', '04_example_data', 'visiumStitched_brain_spaceranger.zip'
)
sr_full_dir = here('processed-data', '01_spaceranger')
info_path = here('processed-data', '03_stitching', 'sample_info.csv')
fiji_out_image = here(
    'processed-data', '03_stitching', 'fiji', 'Br2719.png'
)
fiji_out_xml = here(
    'processed-data', '03_stitching', 'fiji', 'Br2719.xml'
)
fiji_out_zip = here(
    'processed-data', '04_example_data', 'visiumStitched_brain_fiji_out.zip'
)
precast_paths = here(
    'processed-data', '03_stitching', 'precast_out',
    sprintf('PRECAST_k%s.csv', c(2, 4, 8))
)

dir.create(dirname(spe_out_path), showWarnings = FALSE)
stopifnot(dirname(fiji_out_image) == dirname(fiji_out_xml))

################################################################################
#   Prepare SpatialExperiment
################################################################################

#   Only include logcounts as a sparse in-memory matrix. Otherwise, save the
#   object as is
spe = loadHDF5SummarizedExperiment(spe_in_dir)
assays(spe) = list(logcounts = as(assays(spe)$logcounts, "dgCMatrix"))

#   Read in PRECAST results for all values of k and combine in wide format
cluster_df_list = list()
for (precast_path in precast_paths) {
    cluster_df_list[[precast_path]] = read_csv(
            precast_path, show_col_types = FALSE
        ) |>
        select(key, cluster) |>
        mutate(
            k = as.numeric(
                str_extract(precast_path, 'PRECAST_k([0-9]+)', group = 1)
            )
        )
}
cluster_df = do.call(rbind, cluster_df_list) |>
    pivot_wider(
        names_from = k, values_from = cluster, names_prefix = 'precast_k'
    )

#   Add PRECAST results to colData
temp = colnames(spe)
colData(spe) = colData(spe) |>
    as_tibble() |>
    left_join(cluster_df, by = 'key') |>
    DataFrame()
colnames(spe) = temp

#   Add 10 PCs to reducedDims()
spe = runPCA(spe, ncomponents = 10, name = 'PCA')

saveRDS(spe, spe_out_path)

################################################################################
#   Prepare zip files: Spaceranger and Fiji outputs
################################################################################

sample_info = read_csv(info_path, show_col_types = FALSE)

src_dir = as.character(
    outer(
        dirname(sample_info$spaceranger_dir),
        c('raw_feature_bc_matrix', 'spatial', 'analysis'),
        FUN = file.path
    )
)
stopifnot(all(dir.exists(src_dir)))

dest_dir = str_replace(src_dir, sr_full_dir, sr_subset_dir)
sapply(dirname(dest_dir), dir.create, recursive = TRUE, showWarnings = FALSE)

#   Create directory structure of spaceranger contents to host, then create the
#   zip archive from it
all(file.symlink(src_dir, dest_dir))

setwd(sr_subset_dir)
system(sprintf('zip -9 -r %s .', sr_subset_zip))

#   Zip Fiji outputs
setwd(dirname(fiji_out_image))
system(
    sprintf(
        'zip -9 %s %s %s',
        fiji_out_zip,
        basename(fiji_out_xml),
        basename(fiji_out_image)
    )
)

session_info()
