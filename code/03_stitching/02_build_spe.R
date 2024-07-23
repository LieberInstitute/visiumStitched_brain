library(here)
library(tidyverse)
library(visiumStitched)
library(sessioninfo)
library(Matrix)
library(SpatialExperiment)
library(HDF5Array)
library(scran)
library(scater)
library(scry)
library(BiocParallel)
library(spatialLIBD)

info_path = here('processed-data', '03_stitching', 'sample_info.csv')
coords_dir = here('processed-data', '03_stitching', 'spe_inputs')
spe_dir = here('processed-data', '03_stitching', 'spe')
plot_dir = here('plots', '03_stitching')
gtf_path = "/dcs04/lieber/lcolladotor/annotationFiles_LIBD001/10x/refdata-gex-GRCh38-2024-A/genes/genes.gtf.gz"

wm_genes = c("MBP", "GFAP", "PLP1", "AQP4")

num_cores = as.numeric(Sys.getenv('SLURM_CPUS_ON_NODE'))
dir.create(coords_dir, showWarnings = FALSE)
dir.create(plot_dir, showWarnings = FALSE)

################################################################################
#   Build raw SpatialExperiment
################################################################################

sample_info = read_csv(info_path, show_col_types = FALSE)

#   Write transformed image, scalefactors, and coords to a temporary directory
message(Sys.time(), " - Processing Fiji outputs")
prep_fiji_coords(sample_info, coords_dir)
prep_fiji_image(sample_info, coords_dir)

message(Sys.time(), " - Building raw SPE")
spe = build_spe(sample_info, coords_dir = coords_dir, reference_gtf = gtf_path)

#   Fix orientation in response to wet-bench feedback
spe = mirrorObject(spe, axis = "h")

################################################################################
#   Filter, log normalize, and save
################################################################################

#   Filter SPE: take only spots in tissue, drop spots with 0 counts for all
#   genes, and drop genes with 0 counts in every spot
spe <- spe[
    rowSums(assays(spe)$counts) > 0,
    (colSums(assays(spe)$counts) > 0) & spe$in_tissue
]

message(Sys.time(), " - Running quickCluster()")
spe$scran_quick_cluster <- quickCluster(
    spe,
    BPPARAM = MulticoreParam(num_cores),
    block = spe$capture_area,
    block.BPPARAM = MulticoreParam(num_cores)
)

message(Sys.time(), " - Running computeSumFactors()")
spe <- computeSumFactors(
    spe,
    clusters = spe$scran_quick_cluster,
    BPPARAM = MulticoreParam(num_cores)
)

message("Quick cluster table:")
table(spe$scran_quick_cluster)

message("sizeFactors() summary:")
summary(sizeFactors(spe))

message(Sys.time(), " - Running logNormCounts()")
spe <- logNormCounts(spe)

#   Save a copy of the SPE with HDF5-backed assays, which will be important to
#   control memory consumption later
message(Sys.time(), " - Saving HDF5-backed object to control memory later")
spe = saveHDF5SummarizedExperiment(
    spe, dir = spe_dir, replace = TRUE, as.sparse = TRUE
)

################################################################################
#   Plot white matter genes to verify smooth transition across capture areas
################################################################################

wm_genes = rowData(spe)$gene_id[match(wm_genes, rowData(spe)$gene_name)]
p = vis_gene(
    spe, sampleid = unique(spe$sample_id)[1], geneid = wm_genes,
    multi_gene_method = 'pca', is_stitched = TRUE
)

pdf(file.path(plot_dir, 'white_matter.pdf'), width = 4, height = 8)
print(p)
dev.off()

session_info()
