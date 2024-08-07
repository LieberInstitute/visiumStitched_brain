library(spatialLIBD)
library(here)
library(tidyverse)
library(sessioninfo)

spe_path <- here(
    "processed-data", "04_example_data", "visiumStitched_brain_spe.rds"
)
plot_dir <- here("plots", "03_stitching")

ca_colors = c("#A33B20ff", "#e7bb4100", "#3d3b8eff")
names(ca_colors) = c("V13B23-283_C1", "V13B23-283_D1", "V13B23-283_A1")
ca_fill <- c("transparent", "#e7bb41ff", "transparent")
names(ca_fill) = names(ca_colors)
ca_shapes = c(19, 1, 3)
names(ca_shapes) = names(ca_colors)
cluster_colors = c(
    "#320d6d", "#BA1200", "#FFAE03", "#58A4B0", "#506DFF", "#305252",
    "#A28B45", "#111111", "#000000"
)

spe <- readRDS(spe_path)

#   Manually mirror rounded coordinates (simulate
#   SpatialExperiment::mirrorCoords(spe, axis = "h"))
spe$pxl_row_in_fullres_rounded <- dim(imgRaster(spe))[1] / scaleFactors(spe)[1] -
    spe$pxl_row_in_fullres_rounded

################################################################################
#   Array coordinates figure
################################################################################

this_plot_dir <- file.path(plot_dir, "array_coords_figure")
dir.create(this_plot_dir, showWarnings = FALSE)

#   Define axis range such that axes go from 0 to the max value in the data
#   (before mirroring things vertically)
max_x <- max(spatialCoords(spe)[, "pxl_col_in_fullres"])
min_x <- 0
max_y <- max(spatialCoords(spe)[, "pxl_row_in_fullres"]) +
    min(spatialCoords(spe)[, "pxl_row_in_fullres"])
min_y <- min(spatialCoords(spe)[, "pxl_row_in_fullres"])

p <- colData(spe) |>
    cbind(spatialCoords(spe)) |>
    as_tibble() |>
    ggplot(
        mapping = aes(
            x = pxl_col_in_fullres,
            y = min(pxl_row_in_fullres) + max(pxl_row_in_fullres) -
                pxl_row_in_fullres,
            color = capture_area,
            fill = capture_area
        )
    ) +
    geom_point(shape = 21, size = 0.5, stroke = 0.15) +
    coord_fixed(
        xlim = c(min_x, max_x),
        ylim = c(min_y, max_y)
    ) +
    scale_color_manual(values = ca_colors) +
    scale_fill_manual(values = ca_fill) +
    labs(color = "Capture area", fill = "Capture area") +
    guides(color = guide_legend(override.aes = list(size = 3)))
pdf(file.path(this_plot_dir, "transformed_coords.pdf"))
print(p)
dev.off()

p <- colData(spe) |>
    as_tibble() |>
    ggplot(
        mapping = aes(
            x = pxl_col_in_fullres_rounded,
            y = min(pxl_row_in_fullres_rounded) +
                max(pxl_row_in_fullres_rounded) -
                pxl_row_in_fullres_rounded,
            color = capture_area,
            fill = capture_area
        )
    ) +
    geom_point(shape = 21, size = 0.5, stroke = 0.15) +
    coord_fixed(
        xlim = c(min_x, max_x),
        ylim = c(min_y, max_y)
    ) +
    scale_color_manual(values = ca_colors) +
    scale_fill_manual(values = ca_fill) +
    labs(color = "Capture area", fill = "Capture area") +
    guides(color = guide_legend(override.aes = list(size = 3)))
pdf(file.path(this_plot_dir, "rounded_coords.pdf"))
print(p)
dev.off()

################################################################################
#   Spot plots figure: SLC17A7 + WM genes, PRECAST results, agreement of
#   PRECAST at overlaps
################################################################################

this_plot_dir <- file.path(plot_dir, "spot_plots_figure")
dir.create(this_plot_dir, showWarnings = FALSE)

#-------------------------------------------------------------------------------
#   Gene expression plots
#-------------------------------------------------------------------------------

slc <- rowData(spe)$gene_id[match("SLC17A7", rowData(spe)$gene_name)]
wm_genes <- rowData(spe)$gene_id[
    match(c("MBP", "GFAP", "PLP1", "AQP4"), rowData(spe)$gene_name)
]

pdf(file.path(this_plot_dir, "SLC17A7.pdf"))
vis_gene(spe, geneid = slc, is_stitched = TRUE)
dev.off()

pdf(file.path(this_plot_dir, "white_matter.pdf"))
vis_gene(spe, geneid = wm_genes, is_stitched = TRUE)
dev.off()

#-------------------------------------------------------------------------------
#   PRECAST results
#-------------------------------------------------------------------------------

#   Cluster assignments plotted normally with 'vis_clus', for stitched and
#   unstitched data at all values of k
for (this_k in c(2, 4, 8, 16, 24)) {
    for (stitched_var in c("stitched", "unstitched")) {
        cluster_var = sprintf("precast_k%s_%s", this_k, stitched_var)
        if (this_k <= 8) {
            #   Use custom colors for lower values of k
            p = vis_clus(
                    spe, clustervar = cluster_var,
                    is_stitched = TRUE, colors = cluster_colors
                ) +
                guides(fill = guide_legend(override.aes = list(size = 3)))
        } else {
            p = vis_clus(spe, clustervar = cluster_var, is_stitched = TRUE) +
                guides(fill = guide_legend(override.aes = list(size = 3)))
        }
    
        pdf(file.path(this_plot_dir, paste0(cluster_var, ".pdf")))
        print(p)
        dev.off()
    }
}

#-------------------------------------------------------------------------------
#   Agreement of PRECAST clusters at overlaps
#-------------------------------------------------------------------------------

precast_df <- colData(spe) |>
    as_tibble() |>
    #   Take just the first spot that overlaps
    mutate(overlap_key = sub(",.*", "", overlap_key)) |>
    #   Take the non-excluded spots that overlap one in-tissue spot
    filter(!exclude_overlapping, overlap_key != "", overlap_key %in% spe$key) |>
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

pdf(file.path(this_plot_dir, "precast_overlaps.pdf"))
print(p)
dev.off()

#   Add array coordinates
spot_df = colData(spe) |>
    as_tibble() |>
    select(c(key, array_row, array_col)) |>
    left_join(precast_df, by = 'key') |>
    mutate(is_match = original == overlap)

#   Spot plots colored by whether cluster assignments agree at a given array
#   coordinate. Plot for all k and for both stitched and unstitched data
for (this_k in c(2, 4, 8, 16, 24)) {
    for (this_stitched_var in c("stitched", "unstitched")) {
        p = spot_df |>
            filter(
                k == {{ this_k }}, stitched_var == {{ this_stitched_var }}
            ) |>
            ggplot(aes(x = array_row, y = 1 - array_col, color = is_match)) +
                geom_point(size = 0.7)

        pdf(
            file.path(
                this_plot_dir,
                sprintf("overlaps_k%s_%s.pdf", this_k, this_stitched_var)
            )
        )
        print(p)
        dev.off()
    }
}

session_info()
