library("rsconnect")
library("here")

## Or you can go to your shinyapps.io account and copy this
## Here we do this to keep our information hidden.
# load(here("code", "05_shiny", ".deploy_info.Rdata"), verbose = TRUE)
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
        withr::with_dir(here("code", "05_shiny"), dir("spe", full.names = TRUE)),
        withr::with_dir(here("code", "05_shiny"), dir("www", full.names = TRUE))
    ),
    appName = "visiumStitched_brain",
    account = "libd",
    server = "shinyapps.io"
)
