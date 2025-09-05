
# need to build R template. use r-base 4.2.0
# Based off: https://github.com/openanalytics/r-base/blob/master/Dockerfile
# FROM r-base:4.4.0
FROM r-base:4.5.0
# FROM rocker/r-ver:latest
# FROM rocker/shiny-verse:latest

# Set environment variables
# ENV SHINY_ENV="production"
	
## MSstatsShiny stuff ----------------------------------------------------------
# system libraries of general use

RUN apt-get update && apt-get install -y \
    sudo \
    gcc \
    libcurl4-gnutls-dev \
    libcurl4 \
    libcairo2-dev \
    libxt-dev \
    libssl-dev \
    libssh2-1-dev\
    cmake \
    libxml2-dev \
    libxslt1-dev \
    zlib1g-dev

# install basic R functionalities - Need to reduce dependecies...
RUN R -e "install.packages('RCurl')"
RUN R -e "install.packages('BiocManager')"

# install Bioconductor specific packages
RUN R -e "BiocManager::install(version='devel', ask = FALSE)"
RUN R -e "BiocManager::install('MSstatsShiny')"
# RUN R -e "install.packages(c('remotes'))"
# RUN R -e "remotes::install_github('https://github.com/Vitek-Lab/MSstatsShiny/tree/devel')"

# copy the Rprofile.site set up file to the image.
# this make sure your Shiny app will run on the port expected by
# ShinyProxy and also ensures that one will be able to connect to
# the Shiny app from the outside world
COPY Rprofile.site /usr/lib/R/etc/

# instruct Docker to expose port 3838 to the outside world
# (otherwise it will not be possible to connect to the Shiny application)
EXPOSE 3838

# finally, instruct how to launch the Shiny app when the container is started
# CMD ["R", "-e", "MSstatsShiny::launch_MSstatsShiny(port=3838, host='0.0.0.0')"]
CMD ["R", "-e", "MSstatsShiny::launch_MSstatsShiny(port=3838, host='0.0.0.0')"]
