APPUSER=roboshop
LOGFILE="/tmp/$COMPONENT.log"

stat() {

    if [ $1 -eq 0 ]; then
        echo -e "\e[32mSuccess\e[0m"
    else
        echo -e "\e[32mFailure\e[0m"
    fi
}
