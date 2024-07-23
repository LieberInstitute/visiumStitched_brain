library(spatialLIBD)
library(here)
library(tidyverse)
library(sessioninfo)

ca_colors = c("#A33B20ff", "#e7bb4100", "#3d3b8eff")
names(ca_colors) = c("V13B23-283_C1", "V13B23-283_D1", "V13B23-283_A1")
ca_fill = c("#A33B2000", "#e7bb41ff", "#3d3b8e00")
names(ca_fill) = names(ca_colors)

plot_dir = here('plots', '03_stitching')

spe = fetch_data(type = "visiumStitched_brain_spe")

p = colData(spe) |>
    as_tibble() |>
    ggplot(
        mapping = aes(
            x = pxl_col_in_fullres_transformed,
            y = max(pxl_row_in_fullres_transformed) - pxl_row_in_fullres_transformed,
            color = capture_area,
            fill = capture_area
        )
    ) +
        geom_point(shape = 21, size = 0.5, stroke = 0.2) +
        coord_fixed() +
        scale_color_manual(values = ca_colors) +
        scale_fill_manual(values = ca_fill) +
        labs(color = "Capture area", fill = "Capture area") +
        guides(color = guide_legend(override.aes = list(size = 3)))
pdf(file.path(plot_dir, 'transformed_coords.pdf'))
print(p)
dev.off()

p = colData(spe) |>
    as_tibble() |>
    ggplot(
        mapping = aes(
            x = pxl_col_in_fullres_rounded,
            y = max(pxl_row_in_fullres_rounded) - pxl_row_in_fullres_rounded,
            color = capture_area,
            fill = capture_area
        )
    ) +
        geom_point(shape = 21, size = 0.5, stroke = 0.2) +
        coord_fixed() +
        scale_color_manual(values = ca_colors) +
        scale_fill_manual(values = ca_fill) +
        labs(color = "Capture area", fill = "Capture area")
pdf(file.path(plot_dir, 'rounded_coords.pdf'))
print(p)
dev.off()
