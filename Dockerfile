# building docker image to host all needed to run R scripts in the portable mode

FROM ubuntu:16.04

MAINTAINER VladimirZhbanko <vladimir.zhbanko@gmail.com>

# Initialize apt sources
RUN \
  echo 'DPkg::Post-Invoke {"/bin/rm -f /var/cache/apt/archives/*.deb || true";};' | tee /etc/apt/apt.conf.d/no-cache && \
  echo "deb http://ap-northeast-1.ec2.archive.ubuntu.com/ubuntu xenial main universe" >> /etc/apt/sources.list && \
  echo "deb http://cran.cnr.berkeley.edu/bin/linux/ubuntu xenial/" >> /etc/apt/sources.list.d/cran.list && \
  apt-get update -q -y && \
  apt-get dist-upgrade -y && \
  apt-get clean && \
  rm -rf /var/cache/apt/* 

# Install base ubuntu packages for H2o-3
RUN \
  DEBIAN_FRONTEND=noninteractive apt-get install -y wget curl s3cmd libffi-dev libxml2-dev libssl-dev libcurl4-openssl-dev libfreetype6 libfreetype6-dev libfontconfig1 libfontconfig1-dev build-essential chrpath libssl-dev libxft-dev git unzip python-pip python-dev python-virtualenv libmysqlclient-dev texlive texlive-fonts-extra texlive-htmlxml python3 python3-dev python3-pip python3-virtualenv software-properties-common python-software-properties texinfo texlive-bibtex-extra texlive-formats-extra texlive-generic-extra

# Install Oracle Java8 or Java7
RUN \
  add-apt-repository -y ppa:webupd8team/java && \
  apt-get update -q -y && \
  echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
  echo debconf shared/accepted-oracle-license-v1-1 seen true | debconf-set-selections && \  
  DEBIAN_FRONTEND=noninteractive apt-get install -y oracle-java8-installer
#     DEBIAN_FRONTEND=noninteractive apt-get install -y oracle-java7-installer && \

# Install nodeJS
RUN \
  curl -sL https://deb.nodesource.com/setup_10.x | bash - && \
  apt-get update -q -y && \
  apt-get install -y nodejs

# Install R
RUN \
  apt-get install -y --force-yes r-base r-base-dev

# Install python dependencies
RUN \
  wget https://raw.githubusercontent.com/h2oai/h2o-3/master/h2o-py/requirements.txt && \
  /usr/bin/pip install --upgrade pip && \
  /usr/bin/pip install -r requirements.txt && \
  /usr/bin/pip3 install --upgrade pip && \
  /usr/bin/pip3 install -r requirements.txt && \
  rm requirements.txt 

# Install R dependencies
RUN \
  useradd -m -c "H2o AI" jenkins -s /bin/bash && \
  wget https://s3.amazonaws.com/h2o-r/linux/LiblineaR_1.94-2.tar.gz && \
  R -e 'chooseCRANmirror(graphics=FALSE, ind=54);install.packages(c("R.utils", "AUC", "mlbench", "Hmisc", "flexclust", "randomForest", "bit64", "HDtweedie", "RCurl", "jsonlite", "statmod", "devtools", "roxygen2", "testthat", "Rcpp", "fpc", "RUnit", "ade4", "glmnet", "gbm", "ROCR", "e1071", "ggplot2", "LiblineaR", "survival"))'

RUN \
## Workaround for LiblineaR problem
  R CMD INSTALL LiblineaR_1.94-2.tar.gz

# Create users
RUN \
  useradd -m -c "H2o AI" h2oai -s /bin/bash
  

# Expose ports for services
EXPOSE 54321
EXPOSE 8080


## create directories
RUN mkdir -p /01_data
RUN mkdir -p /02_code
RUN mkdir -p /03_output

## copy files
COPY 02_code/install_packages.R /install_packages.R

## install R-packages
RUN Rscript /install_packages.R

