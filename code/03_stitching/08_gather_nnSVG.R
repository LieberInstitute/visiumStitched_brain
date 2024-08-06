library(SpatialExperiment)
library(here)
library(tidyverse)
library(sessioninfo)
library(HDF5Array)

spe_dir <- here("processed-data", "03_stitching", "spe")
unstitched_dir = here("processed-data", "03_stitching", "nnSVG_out_unstitched")
stitched_dir = here("processed-data", "03_stitching", "nnSVG_out")
num_svgs = 500

spe <- loadHDF5SummarizedExperiment(spe_dir)

################################################################################
#   Read in and gather vector of SVGs for stitched and unstitched cases
################################################################################

#   Read in SVGs for each capture area
nn_out_list <- list()
for (sample_id in unique(spe$capture_area)) {
    nn_out_list[[sample_id]] <- file.path(
            unstitched_dir, paste0(sample_id, ".csv")
        ) |>
        read.csv() |>
        as_tibble() |>
        mutate(sample_id = sample_id)
}

#   Order by average rank of each gene across capture areas
unstitched_svgs <- do.call(rbind, nn_out_list) |>
    group_by(gene_id) |>
    summarize(nnsvg_avg_rank = mean(rank)) |>
    arrange(nnsvg_avg_rank) |>
    pull(gene_id)

stitched_svgs = read_csv(
        file.path(stitched_dir, 'Br2719.csv'), show_col_types = FALSE
    ) |>
    arrange(rank) |>
    pull(gene_id)

################################################################################
#   Assess similarity of stitched and unstitched SVGs
################################################################################

#   Take 10 evenly spaced numbers of SVGs, and for each, calculate the
#   proportion in the top N SVGs shared between stitched and unstitched
agree_df = tibble(
    num_genes = min(length(stitched_svgs), length(unstitched_svgs)) *
        seq(10) / 10
) |>
    mutate(
        prop_shared = sapply(
            num_genes,
            function(x) {
                length(
                    intersect(
                        head(unstitched_svgs, n = x),
                        head(stitched_svgs, n = x)
                    )
                ) / x
            }
        )
    )

#   Not even plotting, since the proportion clearly hovers at 0.9
message("Proportion of top N SVGs shared between stitched and unstitched:")
print(agree_df)

################################################################################
#   Export top SVGs
################################################################################

stitched_svgs |>
    head(n = num_svgs) |>
    writeLines(
        con = file.path(stitched_dir, sprintf('top%s_SVGs.txt', num_svgs))
    )

unstitched_svgs |>
    head(n = num_svgs) |>
    writeLines(
        con = file.path(unstitched_dir, sprintf('top%s_SVGs.txt', num_svgs))
    )

session_info()
