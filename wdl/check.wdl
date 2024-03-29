workflow prs_check {
	
	String docker
	File prs_data 
	Array[Array[String]] data_list = read_tsv(prs_data)
	scatter (data in data_list) {
	call check {
		input:
		name = data[0],
		pheno = data[1],
		docker = docker
		}	
	}
}

task check {
	String docker
	String pheno
	String name

	File phenofile
	Int pheno_size = ceil(size(phenofile,"GB"))
	String covarlist

	String score_root
	String study = sub(name,".munged.gz","")
	String label_root = sub(score_root,"STUDY",study)
	File scores = sub(label_root,"PHENO",pheno)
	Array[Array[File]] score_list=read_tsv(scores)
	Int score_size = ceil(size(score_list[0][0],"GB"))*10

	Int disk_size = pheno_size + score_size +1
	String? variantset1
	String vs1=if defined(variantset1) then "--variantSet1="+ variantset1  else ""
	String? variantset2
	String vs2=if defined(variantset2) then "--variantSet2="+ variantset2 else ""

	command {
		Rscript /scripts/check.R \
		--fileList=${write_tsv(score_list)} \
		--phenoFile=${phenofile} \
		--phenotype=${pheno} \
		--output /cromwell_root/ \
		--covarColList=${covarlist} \
		--label=${study} \
		${vs1} \
		${vs2} \
	}

	output {
		Array[File] out_files=glob("/cromwell_root/*.pdf")
	}

	runtime{
		docker:"${docker}"
		memory:"4 GB"
		cpu:2
		disks:"local-disk ${disk_size} HDD"
		preemptible:1
		zone:"europe-west-1b" 
	}

}