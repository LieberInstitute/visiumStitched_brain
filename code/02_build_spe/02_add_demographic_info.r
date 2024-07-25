library(SpatialExperiment)
library(dplyr)
library(here)

d1 = read.csv(here("raw-data","sample_info","Big_240_DLPFC_Dissections.csv"))
d2 = read.csv(here("raw-data","sample_info","MDD_BPD_VisiumHE.csv"))
demo = left_join(d2, d1[,c("brain","age","sex","condition")], by="brain")

load(here::here("code", "REDCap", "REDCap_MBv.rda")) #don't know where this came from
demo = left_join(demo, REDCap_MBv[,c("slide","sample","array")], by=c("brain"="sample", "array"))

save(demo, file=here("raw-data","sample_info","MBv_demographics_combined.csv"))

load(here("processed-data","02_build_spe","spe_raw.Rdata"))

check.sample_id = setdiff(unique(spe$sample_id),unique(paste(demo$slide, demo$array, sep="_")))
if(length(check.sample_id)>0) {
cat("The following sample IDs were present in the spe object but not the demographic info:\n")
cat(check.sample_id)
cat("\n")
stop("Sample ID mismatch between demographics and spe object.")
}

mdata = cbind.data.frame(colData(spe),
do.call(rbind, lapply(strsplit(spe$sample_id, split="_"), function(x) cbind.data.frame("slide"=x[[1]],"position"=x[[2]]))))

mdata = left_join(mdata, demo, by=c("slide","position"="array"))

colData(spe) = cbind(colData(spe)[,c("key","sample_id")],
	mdata[,c("slide","position","brain","mbv_sample","age","sex","condition")],
	colData(spe)[,c("in_tissue","array_row","array_col",
	"sum_umi","sum_gene","expr_chrM","expr_chrM_ratio")])

save(spe, file=here("processed-data","02_build_spe","spe_demo.Rdata"))
