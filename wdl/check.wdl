workflow prs_check {
	
	String docker
	call check {
		input:
		docker = docker
	}	
}

task check {
	String docker

	String pheno
	File phenofile
	String covarlist

	File scores
	Array[Array[File]] score_list=read_tsv(scores)
	String? variantset1
	String vs1=if defined(variantset1) then "--variantSet1="+ variantset1  else ""
	String? variantset2
	String vs2=if defined(variantset2) then "--variantSet2="+ variantset2 else ""

	command {
		Rscript /scripts/check.R \
		--fileList=${write_tsv(score_list)} \
		--phenoFile=${phenofile} \
		--phenotype=${pheno} \
		--output /cromwell_root/results/ \
		--covarColList=${covarlist} \
		${vs1} \
		${vs2}
	}

	output {
		Array[File] out_files=glob("/cromwell_root/results/*.pdf")
	}

	runtime{
		docker:"${docker}"
		memory:"4 GB"
		cpu:2
		disks:"local-disk 1 HDD"
		preemptible:1
		zone:"europe-west-1b" 
	}

}