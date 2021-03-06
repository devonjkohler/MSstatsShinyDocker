
# need to build R template. use r-base 4.2.0
# Based off: https://github.com/openanalytics/r-base/blob/master/Dockerfile
FROM r-base:4.2.0
	
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

# install basic R functionalities - Need to reduce dependecies...
RUN R -e "install.packages(c('shiny', 'shinyBS', 'shinybusy', 'shinyjs', 'uuid', 'DT', 'knitr', 'plotly', 'ggrepel', 'gplots', 'tidyverse', 'data.table', 'BiocManager'))"

# install Bioconductor specific packages
RUN R -e "BiocManager::install(c('MSstatsTMT', 'biomaRt'))"

# copy the app onto the image in folder /root/
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
