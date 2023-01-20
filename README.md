# MSstatsShinyDocker
Contains the docker image for MSstatsShiny

# Instructions for updating MSstatsShiny application

This repository is used to deploy the MSstatsShiny R-shiny application on 
[MSstatsShiny.com](www.MSstatsShiny.com). To deploy changes to the application 
please follow the steps below.

1. Make any updates directly to the shiny application in the repository: https://github.com/Vitek-Lab/MSstatsshiny
2. Log onto the server.
3. Navigate to the MSstatsShinyDocker repository subfolder.
4. Pull repository updates.
5. Build a new docker image - "sudo docker build --no-cache -t \<image name\> ."
6. Edit the application.yml file under /etc/shinyproxy/application.yml to launch your new image (just replace the old image name with the new one)
7. The application is currently run using ".deb". To end this you need to run "ps aux | grep java" and kill the "shinyproxy" process using "sudo kill -9 \<id\>". You also need to stop the docker. Run "sudo docker container ls" to find the running container. Kill it using "docker stop \<id\>"
9. Now launch Shinyproxy - navigate to ~/shinyproxy/target and run "sudo dpkg -i shinyproxy_2.6.1_amd64.deb"
10. If the the appplication throws 500 error it might be because that there is an existing container using the start port. Kill all the existing containers using the command "sudo systemctl restart docker"
11. Use command "sudo docker images" to find old image and delete using "sudo docker image rm -f \<old id\>"
