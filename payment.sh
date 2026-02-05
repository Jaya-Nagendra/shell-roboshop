OG_FOLDER="/var/log/roboshop"
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

dnf install python3 gcc python3-devel -y &>>$LOG_FILE
VALIDATE $? "Install python"

id roboshop
if [ $? -ne 0 ]; then
useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
VALIDATE $? "User creation"
else
echo "User allready exist"
fi

mkdir -p /app &>>$LOG_FILE

curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip  &>>$LOG_FILE
VALIDATE $? "download code"

rm -rf /app/*

cd /app 
unzip /tmp/payment.zip &>>$LOG_FILE
VALIDATE $? "unzip code"

cd /app 
pip3 install -r requirements.txt &>>$LOG_FILE
VALIDATE $? "install dependencies"

cp $SCRIPT_DIR/payment.service /etc/systemd/system/payment.service
VALIDATE $? "Created systemctl service"

systemctl daemon-reload
systemctl enable payment  &>>$LOG_FILE
systemctl start payment
VALIDATE $? "Start payment"