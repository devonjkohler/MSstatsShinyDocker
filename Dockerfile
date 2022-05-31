
# need to build R template. Done manually for R4.2
# Based off: https://github.com/openanalytics/r-base/blob/master/Dockerfile
FROM ubuntu:20.04

# add the maintainer of this Docker image (this should be you in this case)
LABEL maintainer "Devon Kohler <kohler.d@northeastern.edu>"

# Add user to 'staff' group, granting them write privileges to /usr/local/lib/R/site.library
RUN useradd docker \
	&& mkdir /home/docker \
	&& chown docker:docker /home/docker \
	&& addgroup docker staff

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
	    apt-utils \
		ed \
		less \
		locales \
		vim-tiny \
		wget \
		ca-certificates \
		apt-transport-https \
		gsfonts \
		gnupg2 \
	&& rm -rf /var/lib/apt/lists/*

# Configure default locale, see https://github.com/rocker-org/rocker/issues/19
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
	&& locale-gen en_US.utf8 \
	&& /usr/sbin/update-locale LANG=en_US.UTF-8

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8

## Use Debian unstable via pinning -- new style via APT::Default-Release
RUN echo "deb http://http.debian.net/debian sid main" > /etc/apt/sources.list.d/debian-unstable.list \
        && echo 'APT::Default-Release "testing";' > /etc/apt/apt.conf.d/default \
        && echo 'APT::Install-Recommends "false";' > /etc/apt/apt.conf.d/90local-no-recommends

ENV R_BASE_VERSION 4.2.0

# Now install R and littler, and create a link for littler in /usr/local/bin
# Also set a default CRAN repo, and make sure littler knows about it too
RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		littler \
                r-cran-littler \
		r-base=${R_BASE_VERSION}* \
                r-base-core=${R_BASE_VERSION}* \
		r-base-dev=${R_BASE_VERSION}* \
		r-recommended=${R_BASE_VERSION}* \
        && echo 'options(repos = c(CRAN = "https://cloud.r-project.org/"), download.file.method = "libcurl")' >> /etc/R/Rprofile.site \
        && echo 'source("/etc/R/Rprofile.site")' >> /etc/littler.r \
	&& ln -s /usr/share/doc/littler/examples/install.r /usr/local/bin/install.r \
	&& ln -s /usr/share/doc/littler/examples/install2.r /usr/local/bin/install2.r \
	&& ln -s /usr/share/doc/littler/examples/installGithub.r /usr/local/bin/installGithub.r \
	&& ln -s /usr/share/doc/littler/examples/testInstalled.r /usr/local/bin/testInstalled.r \
	&& install.r docopt \
	&& rm -rf /tmp/downloaded_packages/ /tmp/*.rds \
	&& rm -rf /var/lib/apt/lists/*
	
## MSstatsShiny stuff ----------------------------------------------------------
# system libraries of general use
RUN apt-get update && apt-get install -y \
    sudo \
    pandoc \
    pandoc-citeproc \
    libcurl4-gnutls-dev \
    libcairo2-dev \
    libxt-dev \
    libxml2-dev\
    libssl-dev \
    libssh2-1-dev \
    libssl1.0

RUN apt-get update && apt-get -y install cmake protobuf-compiler

# install basic shiny functionality to R
RUN R -e "install.packages(c('shiny', 'shinyBS', 'shinybusy', 'shinyjs', 'uuid',  'DT', 'knitr', 'plotly', 'ggrepel', 'gplots', 'tidyverse', 'data.table', 'BiocManager'))"

# install R dependencies of the euler app
RUN R -e "BiocManager::install(c('MSstatsTMT', 'biomaRt'))"

# copy the example euler app (with the ui.R and server.R files)
# onto the image in folder /root/euler
RUN mkdir /home/MSstats-Shiny
COPY MSstats-Shiny /home/MSstats-Shiny

# copy the Rprofile.site set up file to the image.
# this make sure your Shiny app will run on the port expected by
# ShinyProxy and also ensures that one will be able to connect to
# the Shiny app from the outside world
COPY Rprofile.site /usr/local/lib/R/etc/

# instruct Docker to expose port 3838 to the outside world
# (otherwise it will not be possible to connect to the Shiny application)
EXPOSE 3838

# finally, instruct how to launch the Shiny app when the container is started
CMD ["R", "-e", "shiny::runApp('/home/MSstats-Shiny')"]
