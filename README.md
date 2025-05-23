# MSstatsShinyDocker
Contains the docker image for MSstatsShiny

# Instructions for updating MSstatsShiny application

This repository is used to deploy the MSstatsShiny R-shiny application on 
[MSstatsShiny.com](www.MSstatsShiny.com). To deploy changes to the application 
please follow the steps below.

1. Make any updates directly to the shiny application in the repository: https://github.com/Vitek-Lab/MSstatsshiny
2. Connect to the Shiny server through these steps:
    1. Log into the Lab AWS account [here](https://d-9067c3039d.awsapps.com/start/#/).
    2. In the AWS Management Console, go to the EC2 service.
    3. In the left sidebar, click Instances.
    4. Locate the running instance you want to connect to and click its Instance ID.
    5. At the top of the instance details page, click the Connect button.
    6. Under the EC2 Instance Connect tab, ensure the default username is set to ubuntu.
3. Navigate to the MSstatsShinyDocker repository subfolder.
4. Pull repository updates with `git pull`
5. Build a new docker image - "sudo docker build --no-cache -t \<image name\> ."
6. Edit the application.yml file under /etc/shinyproxy/application.yml to launch your new image (just replace the old image name with the new one)
    1. Run `sudo chmod g+w /etc/shinyproxy/application.yml` to ensure you have permissions to edit the file
7. The application is currently run using ".deb". To end this you need to run "ps aux | grep java" and kill the "shinyproxy" process using "sudo kill -9 \<id\>". You also need to stop the docker. Run "sudo docker container ls" to find the running container. Kill it using "docker stop \<id\>"
8. Now launch Shinyproxy - navigate to ~/shinyproxy/target and run "sudo dpkg -i shinyproxy_2.6.1_amd64.deb"
    1. Run `sudo chmod o+rx shinyproxy` to ensure you have permissions to access the shinyproxy folder
9. If the the appplication throws 500 error it might be because that there is an existing container using the start port. Kill all the existing containers using the command "sudo systemctl restart docker"
10. Use command "sudo docker images" to find old image and delete using "sudo docker image rm -f \<old id\>"

## What if your system runs out of space
1. It is highly likely that the space is occupied by docker files, run this command `sudo find / -type f -size +10M -exec ls -lh {} \;` and see the files that take up most of the memory. If most of the files have the prefix path something like /docker/overaly2/ then it is docker that is eating uo your machine.
2. Warning, these steps will remove all your docker network, containers, images etc. Proceed ahead carefully.
3. Stop docker first: "sudo systemctl stop docker"
4. Prune and delete docker directory run: "docker system prune" and "sudo rm -rf /var/lib/docker"
5. This should remove all the files and your system should be mostly empty, run this command to verify "df -hT"
5. Start docker "sudo systemctl start docker". Try running/building your image again. If docker throws some error saying "/var/lib/docker/tmp not a file or directory" restart the docker process again by running "sudo systemctl restart docker"
