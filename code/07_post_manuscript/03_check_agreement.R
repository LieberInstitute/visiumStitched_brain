library(spatialLIBD)
library(HDF5Array)
library(here)
library(tidyverse)
library(sessioninfo)

spe_dir <- here("processed-data", "07_post_manuscript", "spe")
plot_dir <- here("plots", "07_post_manuscript")
precast_paths <- c(
    here(
        'processed-data', "07_post_manuscript", 'precast_out',
        sprintf('PRECAST_k%s_SVG.csv', c(2, 4, 8, 16, 24))
    ),
    here(
        'processed-data', '03_stitching', 'precast_out_unstitched',
        sprintf('PRECAST_k%s_SVG.csv', c(2, 4, 8, 16, 24))
    )
)

################################################################################
#   Add PRECAST results to the SpatialExperiment
################################################################################

spe <- loadHDF5SummarizedExperiment(spe_dir)

#   Read in PRECAST results for all values of k (both stitched and unstitched)
#   and combine in wide format
cluster_df_list = list()
for (precast_path in precast_paths) {
    cluster_df_list[[precast_path]] <- read_csv(
            precast_path, show_col_types = FALSE
        ) |>
        select(key, cluster) |>
        mutate(
            k = as.numeric(
                str_extract(precast_path, 'PRECAST_k([0-9]+)', group = 1)
            ),
            stitched_var = ifelse(
                grepl('unstitched', precast_path),
                "unstitched",
                "stitched"
            )
        )
}
cluster_df <- do.call(rbind, cluster_df_list) |>
    pivot_wider(
        names_from = c(k, stitched_var), values_from = cluster,
        names_glue = 'precast_k{k}_{stitched_var}'
    )

#   Add PRECAST results to colData
temp <- colnames(spe)
colData(spe) <- colData(spe) |>
    as_tibble() |>
    left_join(cluster_df, by = "key") |>
    DataFrame()
colnames(spe) <- temp

#   Quickly check k = 8 results
for (cluster_var in c('precast_k8_stitched', 'precast_k8_unstitched')) {
    p = vis_clus(spe, clustervar = cluster_var, is_stitched = TRUE)
    pdf(file.path(plot_dir, sprintf("%s.pdf", cluster_var)))
    print(p)
    dev.off()
}

################################################################################
#   Agreement of PRECAST clusters at overlaps
################################################################################

precast_df <- colData(spe) |>
    as_tibble() |>
    #   Take just the first spot that overlaps
    mutate(overlap_key = sub(",.*", "", overlap_key)) |>
    #   Take the non-excluded spots that overlap one in-tissue spot from a
    #   different capture area
    filter(
        !exclude_overlapping,
        overlap_key != "",
        overlap_key %in% spe$key,
        str_split_i(key,  '-1_', 2) != str_split_i(overlap_key,  '-1_', 2)
    ) |>
    select(key, overlap_key, matches('^precast_k[0-9]+')) |>
    #   Append '_original' to the PRECAST clustering results, to signify these
    #   are the results for the non-excluded spots
    rename_with(
        ~ ifelse(grepl("^precast_k[0-9]+", .x), paste0(.x, "_original"), .x)
    ) |>
    #   Effectively removes spots where PRECAST has not assigned a cluster
    #   identity
    na.omit()

#   Add in cluster assignments for all k values at overlapping spots
precast_df <- cbind(
        precast_df,
        colData(spe)[match(precast_df$overlap_key, spe$key),] |>
            as_tibble() |>
            select(matches('^precast_k[0-9]+')) |>
            rename_with(~ paste0(.x, "_overlap"))
    ) |>
    as_tibble() |>
    #   The colnames now include info about the capture area (original vs.
    #   overlap), value of k, and whether the input data was stitched.
    #   Pivot longer to break into 4 columns: capture
    #   area (source), k, is stitched, and the cluster identity (assignment)
    pivot_longer(
        cols = matches("^precast_k[0-9]+_"),
        names_to = c("k", "stitched_var", "source"),
        names_pattern = "^precast_k([0-9]+)_(stitched|unstitched)_(overlap|original)$",
        values_to = "cluster_assignment"
    ) |>
    #   Pivot wider so we can compare the cluster identities for the original
    #   and overlapping spots side by side
    pivot_wider(
        names_from = "source", values_from = "cluster_assignment"
    ) |>
    #   Fix a data type
    mutate(k = as.integer(k)) |>
    #   Rarely, an overlapping spot but not the original may have been dropped
    #   as input to PRECAST; simply drop rows with this situation
    na.omit()

#   Plot the proportion of (unique) spots that match their overlapping spot.
#   Each boxplot contains all donors, and we split by value of k
p <- precast_df |>
    group_by(k, stitched_var) |>
    summarize(match_rate = mean(original == overlap)) |>
    ungroup() |>
    ggplot(mapping = aes(x = k, y = match_rate, color = stitched_var)) +
        geom_line() +
        geom_point() +
        labs(
            x = "PRECAST k Value", y = "Proportion of Matches",
            color = "Input Data"
        ) +
        coord_cartesian(ylim = c(0, 1)) +
        theme_bw(base_size = 24)

pdf(file.path(plot_dir, "precast_overlaps.pdf"))
print(p)
dev.off()

#   Compare agreement at k = 8
temp = precast_df |>
    filter(k == 8) |>
    group_by(stitched_var) |>
    summarize(match_rate = mean(original == overlap)) |>
    ungroup()

a = temp |> filter(stitched_var == 'unstitched') |> pull(match_rate)
b = temp |> filter(stitched_var == 'stitched') |> pull(match_rate)
message(
    sprintf(
        "At k = 8, agreement of PRECAST assignments was %s for unstitched and %s for stitched (%s%% increase)",
        a, b, 100 * b / a - 100
    )
)

session_info()
