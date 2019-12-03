#!/usr/bin/env Rscript

options(stringsAsFactors=F)

## load R libraries
library(optparse)
library(data.table)
library(dplyr)
library(ModelMetrics)

option_list <- list(
  make_option("--fileList", type="character",default="",
              help="Text file including file names in two columns. No header."),
  make_option("--phenoFile", type="character",default="",
              help="Name of the file containing disease and covariates. Contains ID-column 'FINNGENID'. In gzipped format."),
  make_option("--phenotype", type="character",default="",
              help="Name of the phenotype."),
  make_option("--covarColList", type="character", default="",
              help="list of covariates (comma separated)"),
  make_option("--label", type="character", default="",
              help="Optional label. Default = ''"),
  make_option("--output", type="character",default="",
              help="Name of the output directory."))

parser <- OptionParser(usage="%prog [options]", option_list=option_list)
args <- parse_args(parser, positional_arguments = 0)
opt <- args$options
print(opt)

strsplits <- function(x, splits, ...)
{
  for (split in splits)
  {
    x <- unlist(strsplit(x, split, ...))
  }
  return(x[!x == ""]) # Remove empty values
}

## Input variables
#args <- commandArgs(TRUE)
fileList <- opt$fileList
output <- opt$output
phenoFile <- opt$phenoFile
phenotype <- opt$phenotype
label<-ifelse(opt$label == "", opt$label, paste0(opt$label, "_"))
covariates <- strsplit(opt$covarColList,",")[[1]]
title = paste0(label, phenotype)
## Read in first file
d<-fread(fileList, header = F)

causals<-c()
for(i in 1:nrow(d)){
  data<-fread(d$V1[i])
  causal_new<-ifelse(grepl("-inf", d$V1[i]), gsub(".*-\\s*|.txt.*", "", d$V1[i]), gsub(".*p\\s*|.txt.*", "", d$V1[i]))
  causals<-cbind(causals, c(causal_new))
  causal_new<-as.numeric(causal_new)
  cmd = paste0("data$GRS_p",causal_new,"<-data$SCORE1_AVG*data$NMISS_ALLELE_CT")
  eval(parse(text=cmd))
  data<-data[,c(2,6)]
  cmd<-ifelse(i == 1, "dat<-data", "dat<-left_join(dat, data)")
  eval(parse(text=cmd))
}

print(causals)
