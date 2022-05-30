
# build the Docker image from the base image 'openanalytics/r-base'
# this is an Ubuntu 16.04 LTS with a recent R version.
# this image is available on Docker hub at https://hub.docker.com/r/openanalytics/r-base/
FROM openanalytics/r-base

# add the maintainer of this Docker image (this should be you in this case)
LABEL maintainer "Devon Kohler <kohler.d@northeastern.edu>"

# system libraries of general use
RUN apt-get update && apt-get install -y \
    sudo \
    pandoc \
    pandoc-citeproc \
    libcurl4-gnutls-dev \
    libcairo2-dev \
    libxt-dev \
    libssl-dev \
    libssh2-1-dev \
    libssl1.0

# install basic shiny functionality to R
RUN R -e "install.packages(c('shiny', 'shinyBS', 'shinybusy', 'shinyjs', 'uuid',  'DT', 'knitr', 'plotly', 'ggrepel', 'gplots', 'tidyverse', 'data.table', 'BiocManager'))"

# install R dependencies of the euler app
RUN R -e "BiocManager::install(c('MSstatsTMT', 'biomaRt'))"

# copy the example euler app (with the ui.R and server.R files)
# onto the image in folder /root/euler
RUN mkdir /root/MSstats-Shiny
COPY MSstats-Shiny /root/MSstats-Shiny

# copy the Rprofile.site set up file to the image.
# this make sure your Shiny app will run on the port expected by
# ShinyProxy and also ensures that one will be able to connect to
# the Shiny app from the outside world
COPY Rprofile.site /usr/lib/R/etc/

# instruct Docker to expose port 3838 to the outside world
# (otherwise it will not be possible to connect to the Shiny application)
EXPOSE 3838

# finally, instruct how to launch the Shiny app when the container is started
CMD ["R", "-e", "shiny::runApp('/root/MSstats-Shiny')"]
