#!/bin/bash

LOG_FOLDER="/var/log/roboshop"
LOG_FILE="$LOG_FOLDER/$0.log"

N="\e[0m"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
B="\e[34m"

SCRIPT_DIR=$PWD

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

dnf install golang -y &>>$LOG_FILE
VALIDATE $? "Install golang"
  
id roboshop
if [ $? -ne 0 ]; then
useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
VALIDATE $? "User creation"
else
echo "User allready exist"
fi

mkdir -p /app 

curl -L -o /tmp/dispatch.zip https://roboshop-artifacts.s3.amazonaws.com/dispatch-v3.zip  &>>$LOG_FILE
VALIDATE $? "Download code"

rm -rf /app/*

cd /app 
unzip /tmp/dispatch.zip &>>$LOG_FILE
VALIDATE $? "unzip code"

cd /app 
go mod init dispatch &>>$LOG_FILE
go get  &>>$LOG_FILE
go build &>>$LOG_FILE
VALIDATE $? "Build code"

cp $SCRIPT_DIR/dispatch.sh /etc/systemd/system/dispatch.service  &>>$LOG_FILE
VALIDATE $? "Copy systemctl service"

systemctl daemon-reload
systemctl enable dispatch &>>$LOG_FILE
systemctl start dispatch
VALIDATE $? "Enable and start"