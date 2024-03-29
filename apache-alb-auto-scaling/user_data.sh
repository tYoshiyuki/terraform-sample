#!/bin/bash
# -x to display the command to be executed
set -x

# Redirect /var/log/user-data.log and /dev/console
exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1

# Apache HTTP Server
sudo dnf install httpd -y

touch /var/www/html/index.html
echo "Apache ALB AutoScaling Sample!" | tee -a /var/www/html/index.html

sudo systemctl start httpd
sudo systemctl enable httpd

# NOTE ユーザーデータとCodeDeployの動作順序を保証するため CodeDeploy Agent は最後に動かす必要がある
# CodeDeploy Agent
# Install necessary packages
sudo dnf install ruby -y

# Install CodeDeploy Agent
cd /home/ec2-user
wget https://aws-codedeploy-ap-northeast-1.s3.ap-northeast-1.amazonaws.com/latest/install
chmod +x ./install
./install auto
systemctl status codedeploy-agent
cat /opt/codedeploy-agent/.version
