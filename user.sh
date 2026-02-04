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

dnf module disable nodejs -y
dnf module enable nodejs:20 -y
VALIDATE $? "Enable nodejs - 20"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "Install nodejs"

id roboshop
if [ $? -ne 0 ]; then
useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
VALIDATE $? "User creation"
else
echo "User allready exist"
fi

mkdir -p /app 

curl -L -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip 
VALIDATE $? "Downloading user code"

cd /app
VALIDATE $? "Moving to app directory"

rm -rf /app/*
VALIDATE $? "Removing existing code"

unzip /tmp/user.zip &>>$LOGS_FILE
VALIDATE $? "Uzip user code"

cd /app 
npm install 
VALIDATE $? "npm install"

cp $SCRIPT_DIR/user.service /etc/systemd/system/user.service

VALIDATE $? "Created systemctl service"

systemctl daemon-reload
systemctl enable user  &>>$LOGS_FILE
systemctl start user
VALIDATE $? "Starting and enabling user"