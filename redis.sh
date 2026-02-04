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

dnf module disable redis -y &>>$LOG_FILE
dnf module enable redis:7 -y
VALIDATE $? "Enabling redis 7"

dnf install redis -y &>>$LOG_FILE
VALIDATE $? "Install redis"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/redis/redis.conf
sed -i '/protected-mode/c\protected-mode no' /etc/redis/redis.conf
#or -- sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/ c protected-mode no' /etc/redis/redis.conf /  -e for extra comands 

VALIDATE $? "Allowing remote access"

systemctl enable redis 
systemctl start redis &>>$LOG_FILE

VALIDATE $? "Start redis"

