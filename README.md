# techbleatsproj-2025
This is a techbleats project for year 2025

To run the pipeline in Jenkins:

docker pull jenkins/jenkins:lts

docker run -d -p 8080:8080 -p 50000:50000   --memory=3g --memory-swap=5g --name jenkins   -v jenkins_home:/var/jenkins_home   jenkins/jenkins:lts

docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword

Install terraform in docker container 

docker exec -u root -it 1f32674e7969 bash

sudo apt update
sudo apt install -y wget unzip
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip

unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/
terraform -version

Install aws cli in container 


