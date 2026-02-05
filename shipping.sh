#!/bin/bash

LOG_FOLDER="/var/log/roboshop"
LOG_FILE="$LOG_FOLDER/$0.log"

N="\e[0m"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
B="\e[34m"
MSQL_HOST=mysql.ljnag.space
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

dnf install maven -y &>>$LOG_FILE
VALIDATE $? "Install maven"

id roboshop
if [ $? -ne 0 ]; then
useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
VALIDATE $? "User creation"
else
echo "User allready exist"
fi

mkdir -p /app  &>>$LOG_FILE

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip 
VALIDATE $? "Download shipping"

rm -rf /app/*
cd /app 
unzip /tmp/shipping.zip 
VALIDATE $? "unzip shipping"

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service

cd /app 
mvn clean package  &>>$LOG_FILE
VALIDATE $? "maven clean shipping"
mv target/shipping-1.0.jar shipping.jar  &>>$LOG_FILE
VALIDATE $? "moving and renaming shipping"


systemctl daemon-reload
VALIDATE $? "reload shipping"

dnf install mysql -y  &>>$LOG_FILE
VALIDATE $? "install mysqql"

mysql -h $MYSQL_HOST -uroot -pRoboShop@1 -e 'use cities'
if [ $? -ne 0 ]; then

mysql -h $MSQL_HOST -uroot -pRoboShop@1 < /app/db/schema.sql &>>$LOG_FILE
VALIDATE $? "load schema"

mysql -h $MSQL_HOST -uroot -pRoboShop@1 < /app/db/app-user.sql  &>>$LOG_FILE
VALIDATE $? "load user"

mysql -h $MSQL_HOST -uroot -pRoboShop@1 < /app/db/master-data.sql &>>$LOG_FILE
VALIDATE $? "load data"

else
    echo -e "data is already loaded ... $Y SKIPPING $N"
fi

systemctl enable shipping 
systemctl start shipping &>>$LOG_FILE
VALIDATE $? "enable start shipping"