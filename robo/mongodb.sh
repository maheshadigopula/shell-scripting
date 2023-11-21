#!/bin/bash

source robo/common.sh

COMPONENT=mongodb


echo -e "\e[32m________Configuration Started________\e[0m"

echo -n "Downloading $COMPONENT:"
curl -s -o /etc/yum.repos.d/mongodb.repo https://raw.githubusercontent.com/stans-robot-project/mongodb/main/mongo.repo
stat $?


echo -n "Installing $COMPONENT:"
yum install -y mongodb-org &>>$Logfile
stat $?

echo -n "Starting $COMPONENT:"
systemctl enable mongod &>>$Logfile
systemctl start mongod &>>$Logfile
stat $?

echo -n -e "whitelisting the ${COMPONENT} :"
sed -i -e 's/127.0.0.1/0.0.0.0/' /etc/mongod.conf
stat $?



