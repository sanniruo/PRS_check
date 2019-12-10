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
	
	String out_file = "/cromwell_root/" + study + "_"+ pheno + "_bestPRS.txt"
	command {
		Rscript /scripts/BestScores.R \
		--fileList=${write_tsv(score_list)} \
		--phenoFile=${phenofile} \
		--phenotype=${pheno} \
		--output /cromwell_root/ \
		--covarColList=${covarlist} \
		--label=${study}

		cut -f 1 -d " " AUCS_ordered_${study}_${pheno}.txt | grep -v baseline | head -n 1 | xargs -I [] cp [] ${out_file}
	}

	output {
        File aucs = "AUCS_ordered_${study}_${pheno}.txt"
        File correlation = "Correlations_${study}_${pheno}.txt"
        File score = out_file
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
