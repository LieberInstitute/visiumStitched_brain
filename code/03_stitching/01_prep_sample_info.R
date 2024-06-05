#   Create input images to ImageJ, and write sample info for use later when
#   reading in ImageJ outputs and building the SpatialExperiment

library(here)
library(tidyverse)
library(visiumStitched)
library(sessioninfo)

imagej_dir = here(
    'processed-data', '03_stitching', 'imagej'
)
info_out_path = here(
    'processed-data', '03_stitching', 'sample_info.csv'
)

sample_info = tibble(
    group = "Br2719",
    capture_area = c("V13B23-283_A1", "V13B23-283_C1", "V13B23-283_D1"),
    imagej_xml_path = file.path(imagej_dir, paste0(group, '.xml')),
    imagej_image_path = file.path(imagej_dir, paste0(group, '.png')),
    spaceranger_dir = here(
        'processed-data', '01_spaceranger', capture_area, 'outs', 'spatial'
    )
)

in_dir = file.path(imagej_dir, 'input')
dir.create(in_dir, recursive = TRUE, showWarnings = FALSE)

rescale_imagej_inputs(sample_info, in_dir) |>
    write_csv(info_out_path)

session_info()
