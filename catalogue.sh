#!/bin/bash

LOG_FOLDER="/var/log/roboshop"
LOG_FILE="$LOG_FOLDER/$0.log"

N="\e[0m"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
B="\e[34m"

SCRIPT_DIR=$PWD
MONGODB_HOST=mongodb.ljnag.space

USER_ID=$(id -u)

if [ $USER_ID -ne 0 ]; then
echo -e "$R Run this script with Root account $N" | tee -a $LOG_FILE
exit 1
fi

mkdir -p $LOG_FOLDER

VALIDATE(){
    if [ $1 -eq 0 ]; then
        echo -e "$2 ....$G SUCCESS $N" | tee -a $LOG_FILE
        else
        echo -e "$2 .... $R FAILED $N" | tee -a $LOG_FILE
        exit 1
    fi
}


dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "node module disabled"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "node module enabled"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "Install node"

id roboshop
if [ $? -ne 0 ]; then
useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
VALIDATE $? "User creation"
else
echo "User allready exist"
fi

mkdir -p /app 

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip 
VALIDATE $? "Applicatoin download"

cd /app 

rm -rf /app/*
VALIDATE $? "Removing existing code"

unzip /tmp/catalogue.zip &>>$LOG_FILE
VALIDATE $? "Unziped the file"

npm install &>>$LOG_FILE
VALIDATE $? "npm install"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "Service file copy"

systemctl daemon-reload
systemctl enable catalogue &>>$LOG_FILE
systemctl start catalogue
VALIDATE $? "Catalogue start"

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo

dnf install mongodb-mongosh -y

mongosh --host $MONGODB_HOST </app/db/master-data.js

systemctl restart catalogue
VALIDATE $? "Restarting catalogue"