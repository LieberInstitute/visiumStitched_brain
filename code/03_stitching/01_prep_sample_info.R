#   Create input images to Fiji, and write sample info for use later when
#   reading in Fiji outputs and building the SpatialExperiment

library(here)
library(tidyverse)
library(visiumStitched)
library(sessioninfo)

fiji_dir <- here(
    "processed-data", "03_stitching", "fiji"
)
info_out_path <- here(
    "processed-data", "03_stitching", "sample_info.csv"
)

sample_info <- tibble(
    group = "Br2719",
    capture_area = c("V13B23-283_A1", "V13B23-283_C1", "V13B23-283_D1"),
    fiji_xml_path = file.path(fiji_dir, paste0(group, ".xml")),
    fiji_image_path = file.path(fiji_dir, paste0(group, ".png")),
    spaceranger_dir = here(
        "processed-data", "01_spaceranger", capture_area, "outs", "spatial"
    )
)

in_dir <- file.path(fiji_dir, "input")
dir.create(in_dir, recursive = TRUE, showWarnings = FALSE)

rescale_fiji_inputs(sample_info, in_dir) |>
    write_csv(info_out_path)

session_info()
