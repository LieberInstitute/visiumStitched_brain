#   Out of internal interest, compare agreement of cluster assignments at
#   overlapping spots for various values of k, for BayesSpace vs PRECAST, and
#   for stitching vs. not stitching

library(here)
library(tidyverse)
library(sessioninfo)
library(SpatialExperiment)
library(HDF5Array)

spe_in_dir <- here("processed-data", "03_stitching", "spe")
plot_dir = here("plots", "03_stitching")
cluster_paths = c(
    list.files(
        here('processed-data', '03_stitching', 'precast_out'), full.names = TRUE
    ),
    list.files(
        here('processed-data', '03_stitching', 'precast_out_unstitched'),
        full.names = TRUE
    ),
    list.files(
        here('processed-data', '03_stitching', 'bayesspace_out'),
        full.names = TRUE
    )
)

spe = loadHDF5SummarizedExperiment(spe_in_dir)

#   Read in all cluster assignments by BayesSpace and PRECAST, using HVGs and
#   SVGs, stitched and unstitched, and for all k
cluster_df_list = list()
for (cluster_path in cluster_paths) {
    cluster_df_list[[cluster_path]] = read_csv(
            cluster_path, show_col_types = FALSE
        ) |>
        mutate(
            k = as.integer(
                str_extract(basename(cluster_path), 'k([0-9]+)', group = 1)
            ),
            gene_var = ifelse(
                grepl('SVG\\.csv$', cluster_path),
                "SVG",
                "HVG"
            ),
            stitched_var = ifelse(
                grepl('unstitched', cluster_path),
                "unstitched",
                "stitched"
            ),
            method = str_extract(cluster_path, 'precast|bayesspace')
        ) |>
        #   Rename any occurences of 'cluster_assignment' to 'cluster'
        #   (BayesSpace uses the former and PRECAST the latter)
        rename_with(
            ~ sub("cluster_assignment", "cluster", .x)
        ) |>
        select(key, cluster, k, gene_var, stitched_var, method)
}

#   Combine into one long-format tibble, then add cluster assignment of the
#   first overlapping spot where applicable
cluster_df <- do.call(rbind, cluster_df_list) |>
    #   Add overlap info from colData
    left_join(
        colData(spe) |>
            as_tibble() |>
            select(key, overlap_key, exclude_overlapping),
        by = 'key'
    ) |>
    dplyr::rename(cluster_original = cluster) |>
    #   Grouping here changes the behavior of the upcoming 'match',
    #   causing it to match the cluster assignment for the specific
    #   combination of variables (not the first occurence!)
    group_by(k, gene_var, stitched_var, method) |>
    mutate(
        #   Take just the first spot that overlaps
        overlap_key = sub(",.*", "", overlap_key),
        #   Note the grouped use of 'match'
        cluster_overlap = cluster_original[match(overlap_key, key)]
    ) |>
    ungroup() |>
    #   Take the non-excluded spots that overlap one in-tissue spot from a
    #   different capture area
    filter(
        !exclude_overlapping,
        overlap_key != "",
        overlap_key %in% spe$key,
        str_split_i(key,  '-1_', 2) != str_split_i(overlap_key,  '-1_', 2)
    )

p = cluster_df |>
    group_by(k, gene_var, stitched_var, method) |>
    summarize(match_rate = mean(cluster_original == cluster_overlap)) |>
    ggplot(aes(x = k, y = match_rate, color = stitched_var, linetype = gene_var)) +
        geom_point() +
        geom_line() +
        facet_wrap(~method) +
        theme_bw(base_size = 15) +
        labs(y = "Match Rate", linetype = "Gene Input", color = "Stitching")
pdf(file.path(plot_dir, 'agreement_at_overlaps.pdf'))
print(p)
dev.off()

session_info()
