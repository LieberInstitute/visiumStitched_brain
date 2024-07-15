library("rsconnect")
library("here")

spe_path = here('processed-data', '04_example_data', 'Visium_LS_spe.rds')

## Or you can go to your shinyapps.io account and copy this
## Here we do this to keep our information hidden.
# load(here("code", "deploy_app_k09", ".deploy_info.Rdata"), verbose = TRUE)
# rsconnect::setAccountInfo(
#     name = deploy_info$name,
#     token = deploy_info$token,
#     secret = deploy_info$secret
# )

## You need this to enable shinyapps to install Bioconductor packages
options(repos = BiocManager::repositories())

## Deploy the app, that is, upload it to shinyapps.io
rsconnect::deployApp(
    appDir = here("code", "05_shiny"),
    appFiles = c(
        "app.R",
        "Visium_LS_spe.rds",
        withr::with_dir(here("code", "05_shiny"), dir("www", full.names = TRUE))
    ),
    appName = "Visium Lateral Septum",
    account = "libd",
    server = "shinyapps.io"
)
