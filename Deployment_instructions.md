
# Instructions for updating MSstatsShiny application

This repository is used to deploy the MSstatsShiny R-shiny application on 
[MSstatsShiny.com](www.MSstatsShiny.com). To deploy changes to the application 
please follow the steps below.

1. Make any updates directly to the shiny application in the repository: https://github.com/Vitek-Lab/MSstats-shiny
2. Copy the app version you want to deploy into the MSstats-Shiny folder in this repo. Push updates to main branch.
3. Log onto the server.
4. Navigate to the MSstatsShinyDocker repository subfolder.
5. Pull repository updates.
6. Build a new docker image - "sudo docker build -t <image name> ."
7. Navigate to the shinyproxy/target folder and edit the application.yml file to launch your new image (just replace the old image name with the new one)
8. In the same folder launch Shinyproxy - "sudo java -jar shinyproxy-2.6.1.jar"
9. Use command "sudo docker images" to find old image and delete using "sudo docker image rm -f <old id>"