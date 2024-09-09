library(visiumStitched)
library(tidyverse)
library(here)
library(sessioninfo)

source(here('code', '06_array_coordinates', 'alternative_algorithms.R'))

coords_path = here(
    'processed-data', '03_stitching', 'spe_inputs', 'Br2719',
    'tissue_positions.csv'
)
sf_path = here(
    'processed-data', '03_stitching', 'spe_inputs', 'Br2719',
    'scalefactors_json.json'
)
plot_dir = here('plots', '06_array_coordinates')

dir.create(plot_dir, showWarnings = FALSE)

#   Read in stitched coordinates and add capture area
coords = read_csv(coords_path, show_col_types = FALSE) |>
    mutate(capture_area = stringr::str_split_i(key, '-1_', 2))

#   Calculate inter-spot distance from SpaceRanger info
INTER_SPOT_DIST_M = 100e-6
SPOT_DIAMETER_JSON_M <- 65e-6
sr_json = rjson::fromJSON(file = sf_path)
px_per_m <- sr_json$spot_diameter_fullres / SPOT_DIAMETER_JSON_M
inter_spot_dist_px <- INTER_SPOT_DIST_M * px_per_m

################################################################################
#   Map to array coords with each algorithm, tracking both error metrics
################################################################################

orig = coords |>
    visiumStitched:::.fit_to_array(inter_spot_dist_px) |>
    mutate(algorithm = "current") |>
    get_shared_neighbors(coords) |>
    select(key, algorithm, shared_neighbors, matches('^pxl'))

no_dup = coords |>
    fit_euclidean(inter_spot_dist_px) |>
    mutate(algorithm = "no_duplicates") |>
    arrange(key) |>
    get_shared_neighbors(coords |> arrange(key)) |>
    select(key, algorithm, shared_neighbors, matches('^pxl'))

no_dup_ser = coords |>
    fit_euclidean(inter_spot_dist_px) |>
    serialize_coords(inter_spot_dist_px) |>
    mutate(algorithm = "no_duplicates_serialized") |>
    arrange(key) |>
    get_shared_neighbors(coords |> arrange(key)) |>
    select(key, algorithm, shared_neighbors, matches('^pxl'))

mapped_coords = rbind(orig, no_dup, no_dup_ser) |>
    mutate(
        euclidean_err = (
            (pxl_col_in_fullres - pxl_col_in_fullres_rounded) ** 2 +
            (pxl_row_in_fullres - pxl_row_in_fullres_rounded) ** 2
        ) ** 0.5 / inter_spot_dist_px
    )

################################################################################
#   Plot each error metric for each algorithm 
################################################################################

p = ggplot(mapped_coords, aes(x = 1, y = euclidean_err, color = algorithm)) +
    geom_boxplot(outlier.shape = NA) +
    facet_wrap(~algorithm) +
    labs(y = "Euclidean Error") +
    coord_cartesian(ylim = c(0, 1.3))
pdf(file.path(plot_dir, 'euclidean_error.pdf'))
print(p)
dev.off()

p = ggplot(mapped_coords, aes(x = 1, y = shared_neighbors, color = algorithm)) +
    geom_boxplot(outlier.shape = NA) +
    facet_wrap(~algorithm) +
    labs(y = "Fraction of Retained Neighbors")
pdf(file.path(plot_dir, 'shared_neighbors.pdf'))
print(p)
dev.off()

session_info()
