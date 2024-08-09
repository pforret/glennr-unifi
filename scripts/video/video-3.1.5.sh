#!/bin/bash

# UniFi-Video 3.1.5 auto installation script.
# OS       | Xenial
# Version  | 3.0.5
# Author   | Glenn Rietveld
# Email    | glennrietveld8@hotmail.nl
# Website  | https://GlennR.nl

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                           Color Codes                                                                                           #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

RESET='\033[0m'
GRAY='\033[0;37m'
WHITE='\033[1;37m'
GRAY_R='\033[39m'
WHITE_R='\033[39m'
RED='\033[1;31m' # Light Red.
GREEN='\033[1;32m' # Light Green.
BOLD='\e[1m'

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                           Start Checks                                                                                          #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

# Check for root (SUDO).
if [ "$EUID" -ne 0 ]; then
  clear
  clear
  echo -e "${RED}#########################################################################${RESET}"
  echo ""
  echo -e "${WHITE_R}#${RESET} The script need to be run as root..."
  echo ""
  echo ""
  echo -e "${WHITE_R}#${RESET} For Ubuntu based systems run the command below to login as root"
  echo -e "${GREEN}#${RESET} sudo -i"
  echo ""
  echo -e "${WHITE_R}#${RESET} For Debian based systems run the command below to login as root"
  echo -e "${GREEN}#${RESET} su"
  echo ""
  echo ""
  exit 1
fi

abort()
{
  echo -e "\n${RED}###############################################################\n\n          An error occurred. Aborting script..\nPlease contact Glenn R. (AmazedMender16) on the Community Forums!\n\n${RESET}"
  exit 1
}

if [[ $(echo $PATH | grep -c "/sbin") -eq 0 ]]; then
  #PATH=/sbin:/bin:/usr/bin:/usr/sbin:/usr/local/sbin:/usr/local/bin
  PATH=$PATH:/usr/sbin
fi

# Install needed packages if not installed
clear
clear
echo -e "${GREEN}######################################################${RESET}"
echo -e "${GREEN}#                                                    #${RESET}"
echo -e "${GREEN}#  ${RESET}Checking if all required packages are installed!  ${GREEN}#"
echo -e "${GREEN}#                                                    #${RESET}"
echo -e "${GREEN}######################################################${RESET}"
echo ""
echo ""
if [ $(dpkg-query -W -f='${Status}' sudo 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
  apt-get install sudo -y
  if [[ $? > 0 ]]; then
    if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -P -c "^deb http://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu xenial main") -eq 0 ]]; then
      echo deb http://nl.archive.ubuntu.com/ubuntu xenial main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      apt-get update
      apt-get install sudo -y || abort
    fi
  fi
fi
if [ $(dpkg-query -W -f='${Status}' lsb-release 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
  apt-get install lsb-release -y
  if [[ $? > 0 ]]; then
    if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -P -c "^deb http://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu xenial main") -eq 0 ]]; then
      echo deb http://nl.archive.ubuntu.com/ubuntu xenial main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      apt-get update
      apt-get install lsb-release -y || abort
    fi
  fi
fi
if [ $(dpkg-query -W -f='${Status}' net-tools 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
  apt-get install net-tools -y
  if [[ $? > 0 ]]; then
    if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -P -c "^deb http://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu xenial main") -eq 0 ]]; then
      echo deb http://nl.archive.ubuntu.com/ubuntu xenial main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      apt-get update
      apt-get install net-tools -y || abort
    fi
  fi
fi
if [ $(dpkg-query -W -f='${Status}' apt-transport-https 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
  apt-get install apt-transport-https -y
  if [[ $? > 0 ]]; then
    if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://security.ubuntu.com/ubuntu xenial-security main") -eq 0 ]]; then
	  echo deb http://security.ubuntu.com/ubuntu xenial-security main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      apt-get update
      apt-get install apt-transport-https -y || abort
    fi
  fi
fi
if [ $(dpkg-query -W -f='${Status}' software-properties-common 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
  apt-get install software-properties-common -y
  if [[ $? > 0 ]]; then
    if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -P -c "^deb http://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu xenial main") -eq 0 ]]; then
	  echo deb http://nl.archive.ubuntu.com/ubuntu xenial main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
	  apt-get update
	  apt-get install software-properties-common -y || abort
	fi
  fi
fi
if [ $(dpkg-query -W -f='${Status}' curl 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
  apt-get install curl -y
  if [[ $? > 0 ]]; then
    if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://security.ubuntu.com/ubuntu xenial-security main") -eq 0 ]]; then
	  echo deb http://security.ubuntu.com/ubuntu xenial-security main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
	  apt-get update
	  apt-get install curl -y || abort
	fi
  fi
fi
if [ $(dpkg-query -W -f='${Status}' dirmngr 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
  apt-get install dirmngr -y
  if [[ $? > 0 ]]; then
    if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://security.ubuntu.com/ubuntu xenial-security main") -eq 0 ]]; then
	  echo deb http://security.ubuntu.com/ubuntu xenial-security main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
	  apt-get update
	  apt-get install dirmngr -y || abort
	fi
  fi
fi
if [ $(dpkg-query -W -f='${Status}' wget 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
  apt-get install wget -y
  if [[ $? > 0 ]]; then
    if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://security.ubuntu.com/ubuntu xenial-security main") -eq 0 ]]; then
	  echo deb http://security.ubuntu.com/ubuntu xenial-security main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      apt-get update
      apt-get install wget -y || abort
    fi
  fi
fi
if [ $(dpkg-query -W -f='${Status}' netcat 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
  apt-get install netcat -y
  if [[ $? > 0 ]]; then
    if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://security.ubuntu.com/ubuntu xenial main universe") -eq 0 ]]; then
	  echo deb http://security.ubuntu.com/ubuntu xenial main universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      apt-get update
      apt-get install netcat -y || abort
    fi
  fi
fi

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                             Values                                                                                              #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

MONGODB_ORG_SERVER=$(dpkg -l | grep "mongodb-org-server" | awk '{print $3}' | sed 's/.*://' | sed 's/-.*//g')
MONGODB_ORG_MONGOS=$(dpkg -l | grep "mongodb-org-mongos" | awk '{print $3}' | sed 's/.*://' | sed 's/-.*//g')
MONGODB_ORG_SHELL=$(dpkg -l | grep "mongodb-org-shell" | awk '{print $3}' | sed 's/.*://' | sed 's/-.*//g')
MONGODB_ORG_TOOLS=$(dpkg -l | grep "mongodb-org-tools" | awk '{print $3}' | sed 's/.*://' | sed 's/-.*//g')
MONGODB_ORGN=$(dpkg -l | grep "mongodb-org" | awk '{print $3}' | sed 's/.*://' | sed 's/-.*//g')
MONGODB_SERVER=$(dpkg -l | grep "mongodb-server" | awk '{print $3}' | sed 's/.*://' | sed 's/-.*//g')
MONGODB_CLIENTS=$(dpkg -l | grep "mongodb-clients" | awk '{print $3}' | sed 's/.*://' | sed 's/-.*//g')
MONGODB_SERVER_CORE=$(dpkg -l | grep "mongodb-server-core" | awk '{print $3}' | sed 's/.*://' | sed 's/-.*//g')
MONGO_TOOLS=$(dpkg -l | grep "mongo-tools" | awk '{print $3}' | sed 's/.*://' | sed 's/-.*//g')
#
SYSTEM_MEMORY=$(awk '/MemTotal/ {printf( "%.0f\n", $2 / 1024 / 1024)}' /proc/meminfo)
SYSTEM_SWAP=$(awk '/SwapTotal/ {printf( "%.0f\n", $2 / 1024 / 1024)}' /proc/meminfo)
#SYSTEM_FREE_DISK=$(df -h / | grep "/" | awk '{print $4}' | sed 's/G//')
SYSTEM_FREE_DISK=$(df -k / | awk '{print $4}' | tail -n1)
#
#SERVER_IP=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1' | head -1)
#SERVER_IP=$(/sbin/ifconfig | grep 'inet ' | grep -v '127.0.0.1' | head -n1 | awk '{print $2}' | head -1 | sed 's/.*://')
SERVER_IP=$(ip addr | grep -A8 -m1 MULTICAST | grep -m1 inet | cut -d' ' -f6 | cut -d'/' -f1)
if command -v jq &> /dev/null; then
  PUBLIC_SERVER_IP="$(curl --silent https://api.glennr.nl/api/geo | jq -r '."address"')"
else
  PUBLIC_SERVER_IP="$(curl --silent https://api.glennr.nl/api/geo | grep -oP '(?<="address":")[^"]+')"
fi
ARCHITECTURE=$(uname -m)
OS_NAME=$(lsb_release -cs)
OS_RELEASE=$(lsb_release -rs)
OS_DESC=$(lsb_release -ds)
#
JAVA7=$(dpkg -l | grep -c "openjdk-7-jre-headless\|oracle-java7-installer")
MONGODB_SERVER_INSTALLED=$(dpkg -l | grep -c "mongodb-server\|mongodb-org-server")
MONGODB_VERSION=$(dpkg -l | grep "mongodb-server\|mongodb-org-server" | awk '{print $3}' | sed 's/.*://' | sed 's/-.*//' | sed 's/\.//g')

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                             Checks                                                                                              #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

# Check for Ubuntu Release
if [[ $OS_RELEASE != "16.04" && $OS_DESC != "Linux Mint 18"* ]]; then
  echo -e "${RED}################################################################################################################${RESET}"
  echo ""
  echo "                                    You seem to have ${OS_DESC}"
  echo "                                   This script is made for Ubuntu 16.04"
  echo ""
  echo "                               Please download the correct script for your OS."
  echo "                                            Cancelling script"
  echo ""
  rm $0
  exit 1
fi

# Check for 64/32 bit
if [ $ARCHITECTURE != 'x86_64' ]; then
  clear
  echo -e "${RED}########################################################${RESET}"
  echo -e "${RED}#                                                      #${RESET}"
  echo -e "${RED}#               ${RESET}32 bit system detected!                ${RED}#${RESET}"
  echo -e "${RED}#      ${RESET}UniFi-Video only supports 64 bit systems!       ${RED}#${RESET}"
  echo -e "${RED}#                                                      #${RESET}"
  echo -e "${RED}#                ${RESET}Cancelling the script!                ${RED}#${RESET}"
  echo -e "${RED}#                                                      #${RESET}"
  echo -e "${RED}########################################################${RESET}"
  echo ""
  sleep 10
  exit 0
fi

if [ $SYSTEM_FREE_DISK -lt "5242880" ]; then
  clear
  echo -e "${RED}################################################################################################################${RESET}"
  echo ""
  echo "                           Free disk space is below 5GB.. Please expand the disk size!"
  echo "                                      I recommend expanding to atleast 10GB"
  echo ""
  echo "                                            Cancelling script"
  exit 1
fi

# Check if dpkg is locked
if [ $(dpkg-query -W -f='${Status}' psmisc 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
  apt-get update; apt-get upgrade -y || abort
  apt-get install psmisc -y
  if [[ $? > 0 ]]; then
    if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -P -c "^deb http://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu xenial main") -eq 0 ]]; then
	  echo deb http://nl.archive.ubuntu.com/ubuntu xenial main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
	  apt-get update
      apt-get install psmisc -y || abort
	fi
  fi
fi
while 
fuser /var/{lib/{dpkg,apt/lists},cache/apt/archives}/lock >/dev/null 2>&1
do
  clear
  echo -e "${RED}################################################################################################################${RESET}"
  echo ""
  echo "                        dpkg is locked.. Waiting for other software managers to finish!"
  echo "             If this is everlasting please contact Glenn R. (AmazedMender16) on the Community Forums!"
  sleep 10
done

# Check if UniFi-Video is already installed.
if [ $(dpkg-query -W -f='${Status}' unifi-video 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
  clear
  clear
  echo -e "${RED}###############################################################${RESET}"
  echo ""
  echo ""
  echo -e "${WHITE_R}#${RESET} UniFi-Video is already installed."
  echo -e "${WHITE_R}#${RESET} Upgrade UniFi-Video manually or via the UI."
  echo ""
  echo ""
  exit 0
fi

# MongoDB version check.
if [[ $MONGODB_ORG_SERVER > "3.4.999" || $MONGODB_ORG_MONGOS > "3.4.999" || $MONGODB_ORG_SHELL > "3.4.999" || $MONGODB_ORG_TOOLS > "3.4.999" || $MONGODB_ORG > "3.4.999" || $MONGODB_SERVER > "3.4.999" || $MONGODB_CLIENTS > "3.4.999" || $MONGODB_SERVER_CORE > "3.4.999" || $MONGO_TOOLS > "3.4.999" ]]; then
  clear
  if ! (whiptail --title "GlennR Installation Script" --yesno "\n An unsupported MongoDB package was detected on your system!\n   UniFi-Video will not work without the correct packages\n          Can we proceed to uninstall MongoDB?" 13 65)
  then
    clear
    echo -e "${RED}#####################################################${RESET}"
	echo -e "${RED}#                                                   #${RESET}"
	echo -e "${RED}#  ${RESET}You chose to keep your current MongoDB version!  ${RED}#${RESET}"
	echo -e "${RED}#              ${RESET}Cancelling the script!               ${RED}#${RESET}"
	echo -e "${RED}#                                                   #${RESET}"
	echo -e "${RED}#####################################################${RESET}"
    exit 0
  else
    clear
	echo -e "${RED}################################################################################################################${RESET}"
    echo ""
	if [ $(dpkg -l | awk '{print $2}' | grep -c "unifi-video") -eq 1 ]; then
	  echo -e "                         ${RED}Doing this may damage your UniFi-Video installation!${RESET}"
    fi
	if [ $(dpkg -l | awk '{print $2}' | grep -c "unifi") -eq 1 ]; then
	  echo -e "                            ${RED}Doing this may damage your UniFi installation!${RESET}"
    fi
	echo "                      This is required in order for UniFi to work on your system!"
    echo "              Make sure you have a backup of your UniFi Controller settings on your desktop!"
    echo ""
    echo "                   ! This will also uninstall any other package depending on MongoDB !"
	echo ""
	echo ""
	read -p "Do you want to proceed with uninstalling MongoDB? (Y/n)" yes_no
	case "${yes_no}" in
	    [Yy]*|"")
		  clear
          echo -e "${GREEN}#####################################################${RESET}"
          echo -e "${GREEN}#                                                   #${RESET}"
          echo -e "${GREEN}#               ${RESET}Uninstalling MongoDB!               ${GREEN}#${RESET}"
		  if [ $(dpkg -l | awk '{print $2}' | grep -c "unifi-video") -eq 1 ]; then
            echo -e "${GREEN}#    ${RESET}Removing UniFi-Video to keep system files!     ${GREEN}#${RESET}"
          fi
		  if [ $(dpkg -l | awk '{print $2}' | grep -c "unifi") -eq 1 ]; then
            echo -e "${GREEN}#       ${RESET}Removing UniFi to keep system files!        ${GREEN}#${RESET}"
          fi
		  echo -e "${GREEN}#                                                   #${RESET}"
          echo -e "${GREEN}#####################################################${RESET}"
          echo ""
          sleep 3
          rm /etc/apt/sources.list.d/mongo*.list
          if [ $(dpkg-query -W -f='${Status}' unifi-video 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
            dpkg --remove --force-remove-reinstreq unifi-video || abort
          fi
          if [ $(dpkg-query -W -f='${Status}' unifi 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
            dpkg --remove --force-remove-reinstreq unifi || abort
          fi
          apt-get purge mongo* -y
          if [[ $? > 0 ]]; then
            clear
            echo -e "${RED}#####################################################${RESET}"
	        echo -e "${RED}#                                                   #${RESET}"
	        echo -e "${RED}#           ${RESET}Failed to uninstall MongoDB!            ${RED}#${RESET}"
	        echo -e "${RED}#   ${RESET}Uninstalling MongoDB with different actions!    ${RED}#${RESET}"
	        echo -e "${RED}#                                                   #${RESET}"
	        echo -e "${RED}#####################################################${RESET}"
            echo ""
            sleep 2
			apt-get --fix-broken install -y || apt-get install -f -y
			apt-get autoremove -y
		    if [ $(dpkg-query -W -f='${Status}' mongodb-org 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
			  dpkg --remove --force-remove-reinstreq mongodb-org || abort
			fi
		    if [ $(dpkg-query -W -f='${Status}' mongodb-org-tools 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
			  dpkg --remove --force-remove-reinstreq mongodb-org-tools || abort
			fi
			if [ $(dpkg-query -W -f='${Status}' mongodb-org-server 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
			  dpkg --remove --force-remove-reinstreq mongodb-org-server || abort
			fi
		    if [ $(dpkg-query -W -f='${Status}' mongodb-org-mongos 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
			  dpkg --remove --force-remove-reinstreq mongodb-org-mongos || abort
			fi
		    if [ $(dpkg-query -W -f='${Status}' mongodb-org-shell 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
			  dpkg --remove --force-remove-reinstreq mongodb-org-shell || abort
			fi
		    if [ $(dpkg-query -W -f='${Status}' mongodb-server 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
			  dpkg --remove --force-remove-reinstreq mongodb-server || abort
			fi
		    if [ $(dpkg-query -W -f='${Status}' mongodb-clients 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
			  dpkg --remove --force-remove-reinstreq mongodb-clients || abort
			fi
		    if [ $(dpkg-query -W -f='${Status}' mongodb-server-core 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
			  dpkg --remove --force-remove-reinstreq mongodb-server-core || abort
			fi
		    if [ $(dpkg-query -W -f='${Status}' mongo-tools 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
			  dpkg --remove --force-remove-reinstreq mongo-tools || abort
			fi
		  fi
	      apt-get autoremove -y || abort
		  apt-get clean -y || abort
		  apt-get update;;
	    [Nn]*)
		    clear
            echo -e "${RED}#####################################################${RESET}"
            echo -e "${RED}#                                                   #${RESET}"
            echo -e "${RED}#              ${RESET}Cancelling the script!               ${RED}#${RESET}"
            echo -e "${RED}#                                                   #${RESET}"
            echo -e "${RED}#####################################################${RESET}"
            exit 1;;
	esac
  fi
fi

# Memory and Swap file.
if [ $SYSTEM_MEMORY -lt "2" ]; then
  clear
  echo -e "${GREEN}########################################################${RESET}"
  echo -e "${GREEN}#                                                      #${RESET}"
  echo -e "${GREEN}#       ${RESET}SYSTEM MEMORY is lower than recommended!       ${GREEN}#${RESET}"
  echo -e "${GREEN}#               ${RESET}Checking for swap file!                ${GREEN}#${RESET}"
  echo -e "${GREEN}#                                                      #${RESET}"
  echo -e "${GREEN}########################################################${RESET}"
  echo ""
  sleep 2
  if [ $SYSTEM_FREE_DISK -gt "4194304" ]; then
    if [ $SYSTEM_SWAP == "0" ]; then
      clear
      echo -e "${GREEN}########################################################${RESET}"
      echo -e "${GREEN}#                                                      #${RESET}"
      echo -e "${GREEN}#                  ${RESET}Creating swap file!                 ${GREEN}#${RESET}"
      echo -e "${GREEN}#                                                      #${RESET}"
      echo -e "${GREEN}########################################################${RESET}"
	  echo ""
	  sleep 2
      dd if=/dev/zero of=/swapfile bs=2048 count=1048576
      chmod 600 /swapfile
      mkswap /swapfile
      swapon /swapfile
      echo "/swapfile swap swap defaults 0 0" | tee -a /etc/fstab
    else
      clear
      echo -e "${GREEN}########################################################${RESET}"
      echo -e "${GREEN}#                                                      #${RESET}"
      echo -e "${GREEN}#              ${RESET}Swap file already exists!               ${GREEN}#${RESET}"
      echo -e "${GREEN}#                                                      #${RESET}"
      echo -e "${GREEN}########################################################${RESET}"
	  echo ""
	  sleep 2
    fi
  else
    clear
    echo -e "${RED}########################################################${RESET}"
	echo -e "${RED}#                                                      #${RESET}"
    echo -e "${RED}#    ${RESET}Not enough free disk space for the swap file!     ${RED}#${RESET}"
    echo -e "${RED}#             ${RESET}Skipping swap file creation!             ${RED}#${RESET}"
	echo -e "${RED}#                                                      #${RESET}"
    echo -e "${RED}#    ${RESET}I highly recommend upgrading the system memory    ${RED}#${RESET}"
    echo -e "${RED}#     ${RESET}to atleast 2GB and expanding the disk space!     ${RED}#${RESET}"
    echo -e "${RED}#                                                      #${RESET}"
    echo -e "${RED}########################################################${RESET}"
	echo ""
	sleep 8
  fi
fi

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                 Installation Script starts here                                                                                 #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

clear
echo -e "${GREEN}######################################################${RESET}"
echo -e "${GREEN}#                                                    #${RESET}"
echo -e "${GREEN}#    ${RESET}Getting the latest patches for your machine!    ${GREEN}#"
echo -e "${GREEN}#           ${RESET}Installing required packages!            ${GREEN}#"
echo -e "${GREEN}#                                                    #${RESET}"
echo -e "${GREEN}######################################################${RESET}"
echo ""
sleep 2
apt-get update
DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' upgrade || abort
DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' dist-upgrade || abort
apt-get autoremove -y || abort
apt-get autoclean -y || abort

# MongoDB check
MONGODB_SERVER_INSTALLED=$(dpkg -l | grep -c "mongodb-server\|mongodb-org-server")

clear
echo -e "${GREEN}########################################################${RESET}"
echo -e "${GREEN}#                                                      #${RESET}"
echo -e "${GREEN}#  ${RESET}Updates/Requires packages successfully installed!   ${GREEN}#${RESET}"
echo -e "${GREEN}#                ${RESET}Installing MongoDB!                   ${GREEN}#${RESET}"
echo -e "${GREEN}#                                                      #${RESET}"
echo -e "${GREEN}########################################################${RESET}"
echo ""
sleep 2
if [ $MONGODB_SERVER_INSTALLED -eq 1 ]; then
  echo -e "${GREEN}########################################################${RESET}"
  echo -e "${GREEN}#                                                      #${RESET}"
  echo -e "${GREEN}#            ${RESET}MongoDB is already installed!             ${GREEN}#${RESET}"
  echo -e "${GREEN}#                                                      #${RESET}"
  echo -e "${GREEN}########################################################${RESET}"
  echo ""
  echo ""
  sleep 2
else
  sed -i '/mongodb/d' /etc/apt/sources.list
  if [ -f /etc/apt/sources.list.d/mongodb*.list ]; then
    rm /etc/apt/sources.list.d/mongodb*
  fi
  if [ ! -z "$http_proxy" ]; then
    clear
    echo -e "${GREEN}#########################################################################${RESET}"
    echo ""
    echo -e "${GREEN}#${RESET} HTTP Proxy found. | ${WHITE_R}${http_proxy}${RESET}"
    echo ""
    echo ""
    apt-key adv --keyserver keyserver.ubuntu.com --keyserver-options http-proxy=${http_proxy} --recv-keys 0C49F3730359A14518585931BC711F9BA15703C6
  elif [ -f /etc/apt/apt.conf ]; then
	apt_http_proxy=$(grep http.*Proxy /etc/apt/apt.conf | awk '{print $2}' | sed 's/[";]//g')
    if [[ apt_http_proxy ]]; then
      clear
      echo -e "${GREEN}#########################################################################${RESET}"
      echo ""
      echo -e "${GREEN}#${RESET} HTTP Proxy found. | ${WHITE_R}${apt_http_proxy}${RESET}"
      echo ""
      echo ""
      apt-key adv --keyserver keyserver.ubuntu.com --keyserver-options http-proxy=${apt_http_proxy} --recv-keys 0C49F3730359A14518585931BC711F9BA15703C6
    fi
  else
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 0C49F3730359A14518585931BC711F9BA15703C6
  fi
  if [[ $? > 0 ]]; then
    curl -LO https://www.mongodb.org/static/pgp/server-3.4.asc || abort
	gpg --import server-3.4.asc || abort
	rm server-3.4.asc
    if command -v jq &> /dev/null; then
      if [[ "$(curl --silent "https://api.glennr.nl/api/mongodb-release?version=3.4" | jq -r '.expired')" == 'true' ]]; then trusted_mongodb_repo=" trusted=yes"; fi
    else
      if [[ "$(curl --silent "https://api.glennr.nl/api/mongodb-release?version=3.4" | grep -oP '(?<="expired":")[^"]+')" == 'true' ]]; then trusted_mongodb_repo=" trusted=yes"; fi
    fi
  fi
  echo "deb [ arch=amd64,arm64${trusted_mongodb_repo} ] http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.4 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-3.4.list || abort
  apt-get update
  apt-get install mongodb-org -y || abort
fi

clear
echo -e "${GREEN}########################################################${RESET}"
echo -e "${GREEN}#                                                      #${RESET}"
echo -e "${GREEN}#      ${RESET}MongoDB has been installed successfully!        ${GREEN}#${RESET}"
echo -e "${GREEN}#                ${RESET}Installing OpenJDK 7!                 ${GREEN}#${RESET}"
echo -e "${GREEN}#                                                      #${RESET}"
echo -e "${GREEN}########################################################${RESET}"
echo ""
sleep 2
if [[ $(cat /etc/environment | grep "JAVA_HOME") ]]; then
  sed -i 's/^JAVA_HOME/#JAVA_HOME/' /etc/environment
fi
if [ $JAVA7 -eq 1 ]; then
  echo -e "${GREEN}########################################################${RESET}"
  echo -e "${GREEN}#                                                      #${RESET}"
  echo -e "${GREEN}#            ${RESET}JAVA 7 is already installed!              ${GREEN}#${RESET}"
  echo -e "${GREEN}#                                                      #${RESET}"
  echo -e "${GREEN}########################################################${RESET}"
  sleep 2
else
  if [ $(dpkg-query -W -f='${Status}' openjdk-7-jre-headless 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
    apt-get install openjdk-7-jre-headless -y
    if [[ $? > 0 ]]; then
      add-apt-repository ppa:openjdk-r/ppa -y || abort
      apt-get update
	  apt-get install openjdk-7-jre-headless -y || abort
    fi
  fi
fi

# Check what java got installed.
if [[ $(dpkg-query -W -f='${Status}' oracle-java7-installer 2>/dev/null | grep -c "ok installed") -eq 1 ]] || [[ $(dpkg-query -W -f='${Status}' openjdk-7-jre-headless 2>/dev/null | grep -c "ok installed") -eq 1 ]]; then
  if [ -f /etc/default/unifi ]; then
    if [[ $(cat /etc/default/unifi | grep "^JAVA_HOME") ]]; then
      sed -i 's/^JAVA_HOME/#JAVA_HOME/' /etc/default/unifi
    fi
      echo "JAVA_HOME="$( readlink -f "$( which java )" | sed "s:bin/.*$::" )"" >> /etc/default/unifi
    else
	  echo "JAVA_HOME="$( readlink -f "$( which java )" | sed "s:bin/.*$::" )"" >> /etc/environment
	  source /etc/environment
  fi
fi

clear
echo -e "${GREEN}########################################################${RESET}"
echo -e "${GREEN}#                                                      #${RESET}"
echo -e "${GREEN}#       ${RESET}JAVA 7 has been installed successfully!        ${GREEN}#${RESET}"
echo -e "${GREEN}#         ${RESET}Installing UniFi-Video Dependencies!         ${GREEN}#${RESET}"
echo -e "${GREEN}#                                                      #${RESET}"
echo -e "${GREEN}########################################################${RESET}"
echo ""
sleep 2
apt-get update
apt-get install binutils ca-certificates-java java-common -y
apt-get install jsvc libcommons-daemon-java -y
if [[ $? > 0 ]]; then
  clear
  echo -e "${RED}########################################################${RESET}"
  echo -e "${RED}#                                                      #${RESET}"
  echo -e "${RED}#      ${RESET}Failed to install UniFi-Video dependencies!     ${RED}#${RESET}"
  echo -e "${RED}#       ${RESET}Creating a backup of your sources.list!        ${RED}#${RESET}"
  echo -e "${RED}#   ${RESET}Adding required repository to the sources.list!    ${RED}#${RESET}"
  echo -e "${RED}#                                                      #${RESET}"
  echo -e "${RED}#         ${RESET}Installing UniFi-Video Dependencies!         ${RED}#${RESET}"
  echo -e "${RED}#                                                      #${RESET}"
  echo -e "${RED}########################################################${RESET}"
  echo ""
  sleep 2
  if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -P -c "^deb http://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu xenial main universe") -eq 0 ]]; then
    echo deb http://nl.archive.ubuntu.com/ubuntu xenial main universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
	apt-get update
  fi
  apt-get install binutils ca-certificates-java java-common -y || abort
  apt-get install jsvc libcommons-daemon-java -y || abort
fi

clear
echo -e "${GREEN}#############################################################${RESET}"
echo -e "${GREEN}#                                                           #${RESET}"
echo -e "${GREEN}# ${RESET}UniFi-Video dependencies has been installed successfully! ${GREEN}#${RESET}"
echo -e "${GREEN}#               ${RESET}Installing UniFi-Video 3.1.5!               ${GREEN}#${RESET}"
echo -e "${GREEN}#                                                           #${RESET}"
echo -e "${GREEN}#############################################################${RESET}"
echo ""
sleep 2
if [ -f unifi-video_3.1.5~Ubuntu14.04_amd64.deb* ]; then
  rm unifi-video_3.1.5~Ubuntu14.04_amd64.deb*
fi
wget http://dl.ui.com/firmwares/unifi-video/3.1.5/unifi-video_3.1.5~Ubuntu14.04_amd64.deb || abort
dpkg -i unifi-video_3.1.5~Ubuntu14.04_amd64.deb || abort
rm ./unifi-video_3.1.5~Ubuntu14.04_amd64.deb || abort
service unifi-video start || abort

# Check if MongoDB service is enabled
if [ ${MONGODB_VERSION::2} -ge '26' ]; then
  SERVICE_MONGODB=$(systemctl is-enabled mongod)
  if [ $SERVICE_MONGODB = 'disabled' ]; then
    systemctl enable mongod 2>/dev/null || { echo -e "${RED}#${RESET} Failed to enable service | MongoDB"; sleep 3; }
  fi
else
  SERVICE_MONGODB=$(systemctl is-enabled mongodb)
  if [ $SERVICE_MONGODB = 'disabled' ]; then
    systemctl enable mongodb 2>/dev/null || { echo -e "${RED}#${RESET} Failed to enable service | MongoDB"; sleep 3; }
  fi
fi

# Check if controller is reachable via public IP.
timeout 1 nc -zv ${PUBLIC_SERVER_IP} 7443 &> /dev/null && REMOTE_CONTROLLER=true

if [[ $(dpkg -l | grep "unifi-video" | grep -c "ii") -eq 1 ]]; then
  clear
  echo -e "${GREEN}###############################################################${RESET}"
  echo ""
  echo ""
  echo -e "${GREEN}#${RESET} UniFi-Video 3.1.5 has been installed successfully"
  if [[ ${REMOTE_CONTROLLER} = 'true' ]]; then
    echo -e "${GREEN}#${RESET} Your controller address: ${WHITE_R}https://$PUBLIC_SERVER_IP:7443${RESET}"
  else
    echo -e "${GREEN}#${RESET} Your controller address: ${WHITE_R}https://$SERVER_IP:7443${RESET}"
  fi
  echo ""
  echo ""
  systemctl is-active -q unifi-video && echo -e "${GREEN}#${RESET} UniFi-Video is active ( running )" || echo -e "${RED}#${RESET} UniFi-Video failed to start... Please contact Glenn R. (AmazedMender16) on the Community Forums!"
  echo -e "${GREEN}#${RESET} CTRL + C to exit UniFi Status"
  echo ""
  echo ""
  echo -e "${WHITE_R}#${RESET} ${GRAY_R}Author   |  ${WHITE_R}Glenn R.${RESET}"
  echo -e "${WHITE_R}#${RESET} ${GRAY_R}Email    |  ${WHITE_R}glennrietveld8@hotmail.nl${RESET}"
  echo -e "${WHITE_R}#${RESET} ${GRAY_R}Website  |  ${WHITE_R}https://GlennR.nl${RESET}"
  echo ""
  echo ""
  echo ""
  rm $0
  service unifi-video status
else
  clear
  echo -e "${RED}###############################################################${RESET}"
  echo ""
  echo ""
  echo " Failed to successfully install UniFi-Video 3.1.5"
  echo ""
  echo -e " ${RED}Please contact Glenn R. (AmazedMender16) on the Community Forums!${RESET}"
  echo ""
  echo ""
fi