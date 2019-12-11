# PRS-check-pipeline
Pipeline for 1) comparing two sets of variants by their prediction accuracy of the PRS calculated using ldpred (Check) 2) getting best predicting PRS-files and AUCs for all the PRS (BestScores).

## Pre-requirements
Designed to be run with Cromwell on Google Cloud but the underlying bash/python scripts could alternatively be run on another environment. See docker/Dockerfile for list of required tools and packages if not using Docker.

Latest pre-built container image: eu.gcr.io/finngen-refinery-dev/calc-prs:0.06

## Check- pipeline
### Usage instructions
To run the pipeline described below, use scripts/Check.wdl and corresponding scripts/Check.json file. This runs the Check.R Rscript.

### Workflow
- Step1: Reads the list of PRS files (only plink2- output format .sscore accepted). On the first column should be the PRS files from the first variant set, and on the second column from the second variant set.
- Step2: Calculates AUCs for each of the PRS (when phenotype is found from file gs://r4_data/pheno/R4_COV_PHENO_V1.txt.gz) adjusting for the covariates stated in the covarList-part (note: causal fractions used should be stated in the names of the PRS-files as _pCausalFraction (e.g. _p0.04))
- Step3: Plots AUC plots with two curves: one for each set of variants
- Step4: Plots scatter plot for each causal fraction (adding correlation coefficient into the title), comparing the two sets of variants 

## BestScores- pipeline
### Usage instructions
To run the pipeline described below, use scripts/BestScores.wdl and corresponding scripts/BestScores.json file. This runs the BestScores.R Rscript and copies the best predicting PRS-file.

### Workflow
- Step1: Reads the list of PRS files (only plink2- output format .sscore accepted)
- Step2: Calculates AUC for each PRS (when phenotype is found from file gs://r4_data/pheno/R4_COV_PHENO_V1.txt.gz) adjusting for the covariates stated in the covarList-part
- Step3: Writes AUC file with PRS-files and corresponding AUCs (orderes by AUC, best predicting PRS-file on the top)
- Step 4: Writes correlation matrix for each of the PRSs.
- Step 5: Copies the best predicting PRS-file
