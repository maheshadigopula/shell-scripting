APPUSER=roboshop
LOGFILE="/tmp/$COMPONENT.log"


stat() {
    if [ $1 -eq 0 ]; then 
        echo -e "\e[32m Success \e[0m "
    else 
        echo -e "\e[31m failure \e[0m"
    fi 
}

ID=$(id -u)
if [ $ID -ne 0 ]; then
    echo -e "\e[31mYou need to script either as a root user or with a sudo privilege \e[0m"
    exit 1
fi

PYTHON() {
    echo -n "Installing python and other dependencies :"
    yum install python36 gcc python3-devel -y &>> $LOGFILE
    stat $?

    CREATE_USER
    
    DOWNLAOD_AND_EXTRACT

    echo -n "Installing $COMPONENT Dependencies :"
    cd /home/$APPUSER/$COMPONENT
    pip3 install -r requirements.txt &>> $LOGFILE
    stat $?

    USER_ID=$(id -u $APPUSER)
    GROUP_ID=$(id -g $APPUSER)

    echo -n "Updating the UID and GID in the $COMPONENT.ini file :"
    sed -i -e "/^uid/ c uid=$USER_ID" -e "/^gid/ c gid=$GROUP_ID" /home/$APPUSER/$COMPONENT/$COMPONENT.ini
    stat $?

    CONFIGURE_SERVICE

}

JAVA() {
    echo -n "Installing Maven :"
    yum install maven -y &>> $LOGFILE
    stat $?

    CREATE_USER
    DOWNLAOD_AND_EXTRACT

    echo -n "Generating the artifacts :"
    cd /home/$APPUSER/$COMPONENT
    mvn clean package &>> $LOGFILE
    mv target/$COMPONENT-1.0.jar $COMPONENT.jar &>> $LOGFILE
    stat $?

    CONFIGURE_SERVICE
}


NODEJS() {

    echo -n "Configuring NodeJS Repo :"
    curl --silent --location https://rpm.nodesource.com/setup_16.x | sudo bash -  &>> $LOGFILE
    yum install nodejs -y &>> $LOGFILE
    stat $?



}

CREATE_USER() {
    id ${APPUSER} &>> $LOGFILE
    if [ $? -ne 0 ]; then
        echo -n "Creating Application User ${APPUSER} :"
        useradd ${APPUSER}  &>> $LOGFILE
        stat $?
    fi
}


DOWNLAOD_AND_EXTRACT() {
    echo -n "Downloading the ${COMPONENT} :"
    curl -s -L -o /tmp/${COMPONENT}.zip "https://github.com/stans-robot-project/${COMPONENT}/archive/main.zip" &>> ${LOGFILE}
    stat $?

    echo -n "Cleaning and Extarcting ${COMPONENT} :"
    rm -rf ./home/${APPUSER} ${COMPONENT}
    cd /home/${APPUSER}
    unzip -o /tmp/${COMPONENT}.zip &>> ${LOGFILE}
    stat $?

    echo -n "Changing the ownership to ${APPUSER} :" 
    mv /home/$APPUSER/$COMPONENT-main /home/$APPUSER/$COMPONENT &>> ${LOGFILE}
    chown -R $APPUSER:$APPUSER /home/${APPUSER}/${COMPONENT}
    stat $?
}

NPM_INSTALL() {
    echo -n "Installing ${COMPONENT} Dependencies :"
    cd /home/${APPUSER}/${COMPONENT}
    npm install &>> ${LOGFILE}
    stat $?
}

CONFIGURE_SERVICE() {
    echo -n "Configuring ${COMPONENT} Dependencies :"
    mv /home/${APPUSER}/${COMPONENT}/systemd.service  /etc/systemd/system/${COMPONENT}.service &>> ${LOGFILE}
    sed -i -e 's/AMQPHOST/172.31.0.196/' -e 's/USERHOST/172.31.0.29/' -e 's/CARTHOST/172.31.0.157/' -e 's/DBHOST/172.31.0.70/' -e 's/CARTENDPOINT/172.31.0.157/' -e 's/MONGO_DNSNAME/172.31.0.40/' -e 's/REDIS_ENDPOINT/172.31.0.147/' -e 's/MONGO_ENDPOINT/172.31.0.40/' -e 's/CATALOGUE_ENDPOINT/172.31.0.232/' /etc/systemd/system/${COMPONENT}.service &>> ${LOGFILE}
    stat $?

    echo -n "Restarting ${COMPONENT} Service :"
    systemctl daemon-reload &>> ${LOGFILE}
    systemctl start ${COMPONENT} &>> ${LOGFILE}
    systemctl enable ${COMPONENT} &>> ${LOGFILE}
    stat $?

    echo -e "\e[33m______ $COMPONENT Configuration Completed _________ \e[0m"
}




