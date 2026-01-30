#!/bin/bash

LOG_FOLDER="/var/log/roboshop"
LOG_FILE="$LOG_FOLDER/$0.log"

N="\e[0m"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
B="\e[34m"

USER_ID=$(id -u)

if [ $USER_ID -ne 0 ]; then
echo "$R Run this script with Root account $N" | tee -a $LOG_FILE
exit 1
fi

mkdir -p $LOG_FOLDER

VALIDATE(){
    if [ $1 -eq 0 ]; then
        echo "$2 ....$G SUCCESS $N" | tee -a $LOG_FILE
        else
        echo "$2 .... $R FAILED $N" | tee -a $LOG_FILE
        exit 1
    fi
}

cp mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Copying mongo.repo"

dnf install mongodb-org -y &>>$LOG_FILE
VALIDATE $? "Installing mongoDB"

systemctl enable mongod &>>$LOG_FILE
VALIDATE $? "Enabling mongodb"

systemctl start mongod 
VALIDATE $? "Starting mongodb"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
VALIDATE $? "Allowing remote connection"

systemctl restart mongod 
VALIDATE $? "restarting mongod"