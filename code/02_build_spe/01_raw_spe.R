setwd("/dcs05/lieber/lcolladotor/visiumStitched_LIBD1070/LS_visiumStitched/")
suppressPackageStartupMessages({
    library("here")
    library("SpatialExperiment")
    library("spatialLIBD")
    library("rtracklayer")
    library("lobstr")
    library("sessioninfo")
})

## Define some info for the samples
load(here::here("code", "REDCap", "REDCap_LS.rda"))

# sample_info <- data.frame(dateImg = as.Date(REDCap_dACC$date))
# sample_info$experimenterImg <- as.factor(REDCap_dACC$experimenter_img)
sample_info <- data.frame(slide = as.factor(REDCap_LS$slide))
sample_info$array <- as.factor(REDCap_LS$array)
sample_info$brnum <- as.factor(sapply(strsplit(REDCap_LS$sample, "-"), `[`, 1))
sample_info$species <- as.factor(REDCap_LS$species)
sample_info$replicate <- as.factor(REDCap_LS$serial)
sample_info$sample_id <- paste(sample_info$slide, sample_info$array, sep = "_")
sample_info$sample_path <- file.path(here::here("processed-data", "01_spaceranger"), sample_info$sample_id, "outs")

# list4spe = c('V13F27-338','V13F27-348', 'V13Y10-020','V13Y10-021', 'V13Y10-022','V13Y10-023')
# sample_info = sample_info[sample_info$slide %in% list4spe,]

## discard barnyard samples
# stopifnot(all(file.exists(sample_info$sample_path)))

# sample_info_human = sample_info[which(sample_info$species == "human"),]
# sample_info_mouse = sample_info[which(sample_info$species == "mouse"),]
# Define the donor info using information from
# donor_info <- read.csv(file.path(here::here("raw-data", "sample_info_Visium", "demographicInfo_Geo.csv")), header = TRUE, stringsAsFactors = FALSE)
#
# ## check if all donor info included
# setdiff(sample_info_human$brnum,donor_info$brnum)
#
# ## Combine sample info with the donor info
# sample_info_human <- merge(sample_info_human, donor_info)

## Build basic SPE
Sys.time()
spe <- read10xVisiumWrapper(
    sample_info$sample_path,
    sample_info$sample_id,
    type = "sparse",
    data = "raw",
    images = c("lowres", "detected", "aligned"),
    load = TRUE,
    reference_gtf = file.path("/dcs04/lieber/lcolladotor/annotationFiles_LIBD001/10x/refdata-gex-GRCh38-2024-A/", "genes", "genes.gtf.gz")
)
Sys.time()
save(spe, file = here::here("processed-data", "02_build_spe", "spe_raw.Rdata"))

# Sys.time()
# spe <- read10xVisiumWrapper(
#     sample_info_mouse$sample_path,
#     sample_info_mouse$sample_id,
#     type = "sparse",
#     data = "raw",
#     images = c("lowres", "hires", "detected", "aligned"),
#     load = TRUE,
#     reference_gtf = file.path("/dcs04/lieber/lcolladotor/annotationFiles_LIBD001/10x/refdata-gex-mm10-2020-A/","genes", "genes.gtf")
# )
# Sys.time()
# save(spe, file = here::here("processed-data", "02_build_spe", "spe_raw_human.Rdata"))

## Add the study design info
# add_design <- function(spe) {
#     new_col <- merge(colData(spe), sample_info)
#     ## Fix order
#     new_col <- new_col[match(spe$key, new_col$key), ]
#     stopifnot(identical(new_col$key, spe$key))
#     rownames(new_col) <- rownames(colData(spe))
#     colData(spe) <-
#         new_col[, -which(colnames(new_col) == "sample_path")]
#     return(spe)
# }
# spe <- add_design(spe)
#
# # dir.create(here::here("processed-data", "pilot_data_checks"), showWarnings = FALSE)
# save(spe, file = here::here("processed-data", "02_build_spe", "spe_raw.Rdata"))
#
# ## Read in cell counts and segmentation results
# segmentations_list <-
#   lapply(sample_info$sample_id, function(sampleid) {
#     file <-
#       here(
#         "processed-data",
#         "01_spaceranger",
#         sampleid,
#         "outs",
#         "spatial",
#         "tissue_spot_counts.csv"
#       )
#     if (!file.exists(file)) {
#       return(NULL)
#     }
#     x <- read.csv(file)
#     x$key <- paste0(x$barcode, "_", sampleid)
#     return(x)
#   })
#
# ## Merge them (once the these files are done, this could be replaced by an rbind)
# segmentations <-
#   Reduce(function(...) {
#     merge(..., all = TRUE)
#   }, segmentations_list[lengths(segmentations_list) > 0])
#
# ## Add the information
# segmentation_match <- match(spe$key, segmentations$key)
# segmentation_info <-
#   segmentations[segmentation_match, -which(
#     colnames(segmentations) %in% c("barcode", "tissue", "row", "col", "imagerow", "imagecol", "key")
#   )]
# colData(spe) <- cbind(colData(spe), segmentation_info)
#
# ## Remove genes with no data
# no_expr <- which(rowSums(counts(spe)) == 0)
# length(no_expr)
# # [1] 6345
# length(no_expr) / nrow(spe) * 100
# # [1] 17.33559
# spe <- spe[-no_expr, ]
#
#
# ## For visualizing this later with spatialLIBD
# spe$overlaps_tissue <-
#   factor(ifelse(spe$in_tissue, "in", "out"))
#
# ## Save with and without dropping spots outside of the tissue
# #spe_raw <- spe
#
# save(spe, file = here::here("processed-data", "02_build_spe", "spe_raw.Rdata"))
#
# ## Size in Gb
# lobstr::obj_size(spe)
# # 2.07GB
#
#
# ## Now drop the spots outside the tissue
# spe_raw <- spe
# spe <- spe_raw[, spe_raw$in_tissue]
# dim(spe)
# # [1] 36601 37298
# ## Remove spots without counts
# if (any(colSums(counts(spe)) == 0)) {
#   message("removing spots without counts for spe")
#   spe <- spe[, -which(colSums(counts(spe)) == 0)]
#   dim(spe)
# }
#
# # removing spots without counts for spe
# # [1] 30256 37290
#
# lobstr::obj_size(spe)
# # 2.04 GB
#
# save(spe, file = here::here("processed-data", "02_build_spe", "spe.Rdata"))
#
# ## Reproducibility information
# print("Reproducibility information:")
# Sys.time()
# proc.time()
# options(width = 120)
# session_info()
