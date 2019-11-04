FROM ubuntu:16.04

LABEL name="BIOINFORMATICS"
LABEL maintainer="jkarjala@broadinstitute.org"

ENV LC_ALL C.UTF-8
ENV LANG C.UTF-8

RUN apt-get update

RUN apt-get upgrade --yes

RUN apt-get install wget gawk curl lsb-core make gcc g++ cmake gfortran libreadline6 libreadline6-dev \
    libz-dev libbz2-dev liblzma-dev zlib1g-dev libpcre3-dev libssl-dev libcurl4-openssl-dev \
    libopenblas-dev default-jre unzip bzip2 libboost-all-dev \
    libpng-dev libcairo2-dev python3-pip mercurial libxml2-dev --yes

RUN apt-get clean

RUN curl -LO https://github.com/samtools/htslib/releases/download/1.9/htslib-1.9.tar.bz2 && \
    tar -xvjf htslib-1.9.tar.bz2 && cd htslib-1.9 && \
    ./configure && make && make install && cd .. && rm -rf htslib-1.9*

RUN hg clone -b beta https://gavinband@bitbucket.org/gavinband/qctool && \
    cd qctool && ./waf-1.5.18 configure && ./waf-1.5.18 && \
    mv build/release/qctool_v2* /usr/local/bin/qctool && cd .. && rm -rf qctool

RUN hg clone https://bitbucket.org/gavinband/bgen && \
    cd bgen && ./waf configure && ./waf && \
    mv build/apps/bgenix build/apps/cat-bgen /usr/local/bin/ && cd .. && rm -rf bgen

RUN curl -LO https://github.com/samtools/bcftools/releases/download/1.9/bcftools-1.9.tar.bz2 && \
    tar -xvjf bcftools-1.9.tar.bz2 && cd bcftools-1.9 && \
    ./configure && make && make install && cd .. && rm -rf bcftools-1.9*

RUN mkdir plink && cd plink && curl -O http://s3.amazonaws.com/plink1-assets/plink_linux_x86_64_latest.zip && \
    unzip plink_linux_x86_64_latest.zip && mv plink /usr/local/bin && rm * && \
    curl -O http://s3.amazonaws.com/plink2-assets/plink2_linux_avx2_latest.zip && \
    unzip plink2_linux_avx2_latest.zip && mv plink2 /usr/local/bin && cd .. && rm -rf plink

RUN curl -O http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/liftOver && chmod a+x liftOver && mv liftOver /usr/local/bin && \
    curl -O http://hgdownload.soe.ucsc.edu/goldenPath/hg19/liftOver/hg19ToHg38.over.chain.gz && \
    curl -O http://hgdownload.soe.ucsc.edu/goldenPath/hg38/liftOver/hg38ToHg19.over.chain.gz && \
    mkdir liftover && mv *.chain.gz liftover/

RUN curl -O https://cloud.r-project.org/src/base/R-3/R-3.6.1.tar.gz && \
    tar xvzf R-3.6.1.tar.gz && \
    cd R-3.6.1 && \
    ./configure --with-x=no --with-blas="-lopenblas" && \
    make && mkdir -p /usr/local/lib/R/lib && make install && cd .. && rm -rf R-3.6.1*

RUN mkdir plink2 && cd plink2 && curl -O s3.amazonaws.com/plink2-assets/plink2_linux_x86_64_latest.zip && \
    unzip plink2_linux_x86_64_latest.zip && mv plink2 /usr/local/bin && rm * && \
    curl -O http://s3.amazonaws.com/plink2-assets/plink2_linux_avx2_latest.zip && \
    unzip plink2_linux_avx2_latest.zip && mv plink2 /usr/local/bin && cd .. && rm -rf plink2

ADD ./docker/install_packages.R /usr/local/bin/
ADD ./docker/requirements.txt .


RUN chmod a+x /usr/local/bin/install_packages.R && \
    install_packages.R

RUN pip3 install -r requirements.txt && rm requirements.txt

RUN apt-get remove mercurial default-jre --yes && apt autoremove --yes && apt-get clean

ADD scripts ../scripts
