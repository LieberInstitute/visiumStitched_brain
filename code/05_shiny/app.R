library("spatialLIBD")
library("markdown") ## Hm... to avoid this error
# 2021-11-11T05:30:49.941401+00:00 shinyapps[5096402]: Listening on http://127.0.0.1:32863
# 2021-11-11T05:30:50.218127+00:00 shinyapps[5096402]: Warning: Error in loadNamespace: there is no package called ‘markdown’
# 2021-11-11T05:30:50.222437+00:00 shinyapps[5096402]:   111: <Anonymous>

## spatialLIBD uses golem
options("golem.app.prod" = TRUE)

## You need this to enable shinyapps to install Bioconductor packages
options(repos = BiocManager::repositories())

## Load the spe object
spe <- readRDS('visiumStitched_brain_spe.rds')
vars <- colnames(colData(spe))

## Deploy the website
spatialLIBD::run_app(
    spe,
    title = "visiumStitched_brain",
    spe_discrete_vars = c(
        "ManualAnnotation",
        vars[grep("^precast_k[248]$", vars)],
        "scran_quick_cluster"
    ),
    spe_continuous_vars = c(
        "sum_umi",
        "sum_gene",
        "expr_chrM",
        "expr_chrM_ratio"
    ),
    default_cluster = "precast_k2",
    docs_path = "www"
)
