#!/usr/bin/env Rscript

req_packages <- c("ModelMetrics","data.table", "tidyr", "dplyr", "ggplot2", "ggpubr", "optparse", "qqman", "purrr", "glue", "fs", "R.utils", "devtools")
for (pack in req_packages) {
    if(!require(pack,character.only = TRUE)) {
        install.packages(pack, repos = "http://cran.us.r-project.org")
    }
}
