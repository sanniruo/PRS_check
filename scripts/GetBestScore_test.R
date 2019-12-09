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

for(i in 1:nrow(d)){
  data<-fread(d$V1[i])
  cmd = paste0("data$PRS_",i,"<-data$SCORE1_AVG*data$NMISS_ALLELE_CT")
  eval(parse(text=cmd))
  data<-data[,c(2,6)]
  cmd<-ifelse(i == 1, "dat<-data", "dat<-left_join(dat, data)")
  eval(parse(text=cmd))
}

## Calculate auc:
## Read in phenotype file:
cmd = paste0("pheno<-fread('zcat ",phenoFile,"')")
eval(parse(text=cmd))
names(dat)[1]<-"FINNGENID"
if(phenotype%in%names(pheno)){
  list_of_phenotypes<-c("FINNGENID", phenotype, covariates)
  pheno<-select(pheno, list_of_phenotypes)
  dat<-left_join(dat, pheno)
  
  covariatesONE<-c()
  for(i in 1:length(covariates)){
    covariatesONE = paste0(covariatesONE, paste0("+",covariates[i]))
  }
  
  aucs<-c()
  for(i in 1:nrow(d)){
    cmd = paste0("logit<-glm(",phenotype,"~PRS_",i,"+",covariatesONE,", data = dat, family = 'binomial')")
    eval(parse(text=cmd))
    aucs[i]<-auc(logit)
  }
  
  cmd = paste0("logit_baseline<-glm(dat$",phenotype,"~",covariatesONE,", data = dat, family = 'binomial')")
  eval(parse(text=cmd))
  auc_baseline<-auc(logit_baseline)

  aucs_all<-cbind(aucs, auc_baseline)
  files<-cbind(d$V1, "baseline")
  
  aucs_ordered<-order(aucs_all)
  m<-match(aucs_ordered, aucs_all)
  files_ordered<-files[m]
  
  data_to_print<-data-frame(PRS_file=files_ordered, AUCS = aucs_ordered)
  cmd=paste0("write.table(data_to_print, '",output,"/AUCS_ordered_",label,"",phenotype,".txt', row.names = F, col.names = F, quote = F)")
  eval(parse(text=cmd))
  
} else{
  print("No phenotype found, no AUC plot.")
}
