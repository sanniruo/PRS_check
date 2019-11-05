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
  make_option("--variantSet1", type="character", default="Variantset1",
              help="Optional name of the 1st variant set. Default = 'Variantset1'"),
  make_option("--variantSet2", type="character", default="Variantset2",
              help="Optional name of the 2nd variant set. Default = 'Variantset2'"),
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
variantSet1 <-opt$variantSet1
variantSet2 <-opt$variantSet2
label<-ifelse(label == "", opt$label, paste0(opet$label, "_"))
covariates <- strsplit(opt$covarColList,",")[[1]]

## Read in first file
d<-fread(fileList, header = F)

causals<-c()
for(i in 1:nrow(d)){
  data1<-fread(d$V1[i])
  causal_new<-ifelse(grepl("inf", d$V1[i]), gsub(".*-\\s*|.txt.*", "", d$V1[i]), gsub(".*p\\s*|.txt.*", "", d$V1[i]))
  causals<-cbind(causals, c(causal_new))
  causal_new<-as.numeric(causal_new)
  cmd = paste0("data1$varset1_GRS_p",causal_new,"<-data1$SCORE1_AVG*data1$NMISS_ALLELE_CT")
  eval(parse(text=cmd))
  data1<-data1[,c(2,6)]
  cmd<-ifelse(i == 1, "dat1<-data1", "dat1<-left_join(dat1, data1)")
  eval(parse(text=cmd))
}

causals<-c()
for(i in 1:nrow(d)){
  data2<-fread(d$V2[i])
  causal_new<-ifelse(grepl("inf", d$V2[i]), gsub(".*-\\s*|.txt.*", "", d$V2[i]), gsub(".*p\\s*|.txt.*", "", d$V2[i]))
  causals<-cbind(causals, c(causal_new))
  causal_new<-as.numeric(causal_new)
  cmd = paste0("data2$varset2_GRS_p",causal_new,"<-data2$SCORE1_AVG*data2$NMISS_ALLELE_CT")
  eval(parse(text=cmd))
  data2<-data2[,c(2,6)]
  cmd<-ifelse(i == 1, "dat2<-data2", "dat2<-left_join(dat2, data2)")
  eval(parse(text=cmd))
}

dat<-left_join(dat1,  dat2)
causals<-c(causals)

caus_numr<-as.numeric(causals)
causals<-causals[order(caus_numr)]
caus_numr<-caus_numr[order(caus_numr)]


## Scatter plots:
correlations<-c()
for(i in 1:length(caus_numr)){
  cmd = paste0("max = max(dat$varset1_GRS_p",caus_numr[i],", dat$varset2_GRS_p",caus_numr[i],")")
  eval(parse(text=cmd))
  cmd = paste0("min = min(dat$varset1_GRS_p",caus_numr[i],", dat$varset2_GRS_p",caus_numr[i],")")
  eval(parse(text=cmd))
  cmd = paste0("corr = round(cor(dat$varset1_GRS_p",caus_numr[i],", dat$varset2_GRS_p",caus_numr[i],"),3)")
  eval(parse(text=cmd))
  main = paste0("Causal fraction = ",caus_numr[i],", correlation = ", corr,"")
  cmd=paste0("pdf('",output,"/PRS_comparison_",label,"",phenotype,"_p",caus_numr[i],".pdf',10, 10)")
  eval(parse(text=cmd))
  cmd = paste0("plot(dat$varset1_GRS_p",caus_numr[i],", dat$varset2_GRS_p",caus_numr[i],", xlab = '",variantSet1,"', ylab = '",variantSet2,"', ylim =c(min, max), xlim =c(min, max), pch = 16, main = main)")
  eval(parse(text=cmd))
  abline(0,1)
  dev.off()
  correlations[i]<-corr
}

cmd = paste0("pdf('",output,"/Correlation_vs_causal_fractions_",label,"",phenotype,".pdf', 10, 10)")
eval(parse(text=cmd))
plot(1:length(caus_numr), correlations, ylab = "Correlation", xlab = "Causal fraction", type = "b", xaxt = 'n')
axis(at= 1:length(caus_numr), side = 1, labels =caus_numr)
dev.off()

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
  
  aucs_variantset1<-c()
  for(i in 1:length(caus_numr)){
    cmd = paste0("logit<-glm(",phenotype,"~varset1_GRS_p",caus_numr[i],"",covariatesONE,", data = dat, family = 'binomial')")
    eval(parse(text=cmd))
    aucs_variantset1[i]<-auc(logit)
  }
  
  aucs_variantset2<-c()
  for(i in 1:length(caus_numr)){
    cmd = paste0("logit<-glm(dat$",phenotype,"~dat$varset2_GRS_p",caus_numr[i],"",covariatesONE,", data = dat, family = 'binomial')")
    eval(parse(text=cmd))
    aucs_variantset2[i]<-auc(logit)
  }
  cmd = paste0("logit_baseline<-glm(dat$",phenotype,"~",covariatesONE,", data = dat, family = 'binomial')")
  eval(parse(text=cmd))
  auc_baseline<-auc(logit_baseline)
  
  auc_plot_min<-min(auc_baseline, aucs_variantset1, aucs_variantset2)
  auc_plot_max<-max(auc_baseline, aucs_variantset1, aucs_variantset2)
  
  ## AUC plot
  cmd = paste0("pdf('",output,"/AUC_plot_",label,"",phenotype,".pdf', 12, 10)")
  eval(parse(text=cmd))
  plot(aucs_variantset1, type = "b", ylim = c(auc_plot_min-0.01*auc_plot_min, auc_plot_max+0.01*auc_plot_max), xaxt = "n", xlab = "Causal fraction", ylab = "Are Under Curve (AUC)", col = "cornflowerblue", lwd = 2)
  lines(aucs_variantset2, type = "b", col = "tomato", lwd = 2)
  abline(h = auc_baseline, col = "red", lty = 2)
  axis(1, at = 1:length(causals), labels = caus_numr)
  cmd =paste0("legend('topleft', legend = c('",variantSet1,"', '",variantSet2,"'), col = c('cornflowerblue', 'tomato'), lty = 1, lwd = 2)")
  eval(parse(text=cmd))
  dev.off()
  
}
else{print("Phenotype missing. No AUC plot.")}
