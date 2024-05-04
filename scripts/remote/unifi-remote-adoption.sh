#!/bin/bash

# UniFi Easy Remote Adoption Script
# Version  | 1.0.0
# Author   | Glenn Rietveld
# Email    | glennrietveld8@hotmail.nl
# Website  | https://GlennR.nl

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                           Color Codes                                                                                           #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

RESET='\033[0m'
YELLOW='\033[1;33m'
#GRAY='\033[0;37m'
#WHITE='\033[1;37m'
GRAY_R='\033[39m'
WHITE_R='\033[39m'
RED='\033[1;31m' # Light Red.
GREEN='\033[1;32m' # Light Green.
#BOLD='\e[1m'

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                           Start Checks                                                                                          #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

netmask_converter() {
  # shellcheck disable=SC2086
  subnet_mask="0" var="0""$( printf '%o' ${1//./ } )"
  while [ "${var}" -gt "0" ]; do
    # shellcheck disable=SC2219
    let subnet_mask+=$((var%2)) 'var>>=1'
  done
  echo /"${subnet_mask}"
}

header() {
  clear
  clear
  echo -e "${GREEN}#########################################################################${RESET}\\n"
}

header_red() {
  clear
  clear
  echo -e "${RED}#########################################################################${RESET}\\n"
}

# Check for root (SUDO).
if [[ "$EUID" -ne 0 ]]; then
  header_red
  echo -e "${WHITE_R}#${RESET} The script need to be run as root...\\n\\n"
  echo -e "${WHITE_R}#${RESET} For Ubuntu based systems run the command below to login as root"
  echo -e "${GREEN}#${RESET} sudo -i\\n"
  echo -e "${WHITE_R}#${RESET} For Debian based systems run the command below to login as root"
  echo -e "${GREEN}#${RESET} su\\n\\n"
  exit 1
fi

if ! grep -iq "udm" /usr/lib/version &> /dev/null; then
  if ! env | grep "LC_ALL\\|LANG" | grep -iq "en_US\\|C.UTF-8"; then
    header
    echo -e "${WHITE_R}#${RESET} Your language is not set to English ( en_US ), the script will temporarily set the language to English."
    echo -e "${WHITE_R}#${RESET} Information: This is done to prevent issues in the script.."
    export LC_ALL=C &> /dev/null
    set_lc_all="true"
    sleep 3
  fi
fi

abort() {
  if [[ "${set_lc_all}" == 'true' ]]; then unset LC_ALL; fi
  echo -e "\\n\\n${RED}#########################################################################${RESET}\\n"
  echo -e "${WHITE_R}#${RESET} An error occurred. Aborting script..."
  echo -e "${WHITE_R}#${RESET} Please contact Glenn R. (AmazedMender16) on the UI Community Forums!"
  echo -e "${WHITE_R}#${RESET} UI Community Thread: https://community.ui.com/questions/ccbc7530-dd61-40a7-82ec-22b17f027776 \\n"
  echo -e "${WHITE_R}#${RESET} Creating support file..."
  mkdir -p "/tmp/EUS/support" &> /dev/null
  if dpkg -l lsb-release 2> /dev/null | grep -iq "^ii\\|^hi"; then lsb_release -a &> "/tmp/EUS/support/lsb-release"; fi
  df -h &> "/tmp/EUS/support/df"
  free -hm &> "/tmp/EUS/support/memory"
  uname -a &> "/tmp/EUS/support/uname"
  dpkg -l | grep "mongo\\|oracle\\|openjdk\\|unifi\\|temurin" &> "/tmp/EUS/support/unifi-packages"
  dpkg -l &> "/tmp/EUS/support/dpkg-list"
  dpkg --print-architecture &> "/tmp/EUS/support/architecture"
  # shellcheck disable=SC2129
  sed -n '3p' "${script_location}" &>> "/tmp/EUS/support/script"
  grep "# Version" "${script_location}" | head -n1 &>> "/tmp/EUS/support/script"
  support_file_time="$(date +%Y%m%d_%H%M_%S%N)"
  if dpkg -l tar 2> /dev/null | grep -iq "^ii\\|^hi"; then
    tar czvfh "/tmp/eus_support_${support_file_time}.tar.gz" --exclude="${eus_dir}/unifi_db" "/tmp/EUS" "${eus_dir}" "/usr/lib/unifi/logs" "/etc/apt/sources.list" "/etc/apt/sources.list.d/"&> /dev/null
    support_file="/tmp/eus_support_${support_file_time}.tar.gz"
  elif dpkg -l zip 2> /dev/null | grep -iq "^ii\\|^hi"; then
    zip -r "/tmp/eus_support_${support_file_time}.zip" "/tmp/EUS/" "${eus_dir}/" "/usr/lib/unifi/logs/" "/etc/apt/sources.list" "/etc/apt/sources.list.d/" -x "${eus_dir}/unifi_db/*" &> /dev/null
    support_file="/tmp/eus_support_${support_file_time}.zip"
  fi
  if [[ -n "${support_file}" ]]; then echo -e "${WHITE_R}#${RESET} Support file has been created here: ${support_file} \\n"; fi
  exit 1
}

eus_directories() {
  if uname -a | tr '[:upper:]' '[:lower:]' | grep -iq "cloudkey\\|uck\\|ubnt-mtk"; then
    eus_dir='/srv/EUS'
  elif grep -iq "UCKP\\|UCKG2\\|UCK" /usr/lib/version &> /dev/null; then
    eus_dir='/srv/EUS'
  else
    eus_dir='/usr/lib/EUS'
  fi
  mkdir -p "${eus_dir}/logs"
  mkdir -p "${eus_dir}"
  mkdir -p "/tmp/EUS"
}

script_logo() {
  cat << "EOF"
  _______________ ___  _________     _____       .___             __   
  \_   _____/    |   \/   _____/    /  _  \    __| _/____ _______/  |_ 
   |    __)_|    |   /\_____  \    /  /_\  \  / __ |/  _ \\____ \   __\
   |        \    |  / /        \  /    |    \/ /_/ (  <_> )  |_> >  |  
  /_______  /______/ /_______  /  \____|__  /\____ |\____/|   __/|__|  
          \/                 \/           \/      \/      |__|         

EOF
}

start_script() {
  script_location="${BASH_SOURCE[0]}"
  script_name=$(basename "${BASH_SOURCE[0]}")
  eus_directories
  header
  script_logo
  echo -e "    UniFi Easy Remote Adoption Script!"
  echo -e "\\n${WHITE_R}#${RESET} Starting the Easy Remote Adoption Script.."
  echo -e "${WHITE_R}#${RESET} Thank you for using my Easy Remote Adoption Script :-)\\n\\n"
  sleep 4
}
start_script

help_script() {
  if [[ "${script_option_help}" == 'true' ]]; then header; script_logo; else echo -e "${WHITE_R}----${RESET}\\n"; fi
  echo -e "    UniFi Easy Remote Adoption Script assistance\\n"
  echo -e "
  Script usage:
    bash ${script_name} [options]
  
  Script options:
    --subnet                    Specify the subnet where the unadopted UniFi Devices exist.
                                  example:
                                  --subnet 192.168.0.0/24
    --domain-name               Specify the domain name/FQDN of the UniFi Network Application Server.
                                  example:
                                  --domain-name unifi.example.com
    --ip-address                Specify the IP address of the UniFi Network Application Server.
                                  example:
                                  --ip-address 66.55.44.33
    --inform-port               Specify the Inform Port used by your UniFi Network Application Server.
                                  example:
                                  --inform-port 8080
    --help                      Shows this information :)\\n\\n"
  exit 0
}

rm --force /tmp/EUS/script_options &> /dev/null
script_option_list=(--subnet --fqdn --domain-name --ip --ip-address --port --inform-port --help)

while [ -n "$1" ]; do
  case "$1" in
  --subnet)
       for option in "${script_option_list[@]}"; do
         if [[ "${2}" == "${option}" ]]; then header_red; echo -e "${WHITE_R}#${RESET} Option ${1} requires a command argument... \\n\\n"; help_script; fi
       done
       echo -e "--subnet ${2}" &>> /tmp/EUS/script_options
       subnet="${2}"
       shift;;
  --fqdn | --domain-name)
       for option in "${script_option_list[@]}"; do
         if [[ "${2}" == "${option}" ]]; then header_red; echo -e "${WHITE_R}#${RESET} Option ${1} requires a command argument... \\n\\n"; help_script; fi
       done
       echo -e "--domain-name ${2}" &>> /tmp/EUS/script_options
       fqdn="${2}"
       shift;;
  --ip | --ip-address)
       for option in "${script_option_list[@]}"; do
         if [[ "${2}" == "${option}" ]]; then header_red; echo -e "${WHITE_R}#${RESET} Option ${1} requires a command argument... \\n\\n"; help_script; fi
       done
       echo -e "--ip-address ${2}" &>> /tmp/EUS/script_options
       ip="${2}"
       shift;;
  --port | --inform-port)
       for option in "${script_option_list[@]}"; do
         if [[ "${2}" == "${option}" ]]; then header_red; echo -e "${WHITE_R}#${RESET} Option ${1} requires a command argument... \\n\\n"; help_script; fi
       done
       echo -e "--port ${2}" &>> /tmp/EUS/script_options
       port="${2}"
       shift;;
  --help)
       script_option_help="true"
       help_script;;
  esac
  shift
done

# Set variables if empty.
if [[ -z "${port}" ]]; then port="8080"; fi
if [[ -z "${subnet}" ]]; then subnet="$(route -n | grep 'U[ \t]' | awk '{print $1}' | head -n1)$(netmask_converter "$(route -n | grep 'U[ \t]' | awk '{print $3}' | head -n1)")"; fi
if [[ -z "${fqdn}" && -z "${ip}" ]]; then header_red; echo -e "${WHITE_R}#${RESET} You must specify the UniFi Network Application IP or FQDN/Domain Name... \\n\\n"; help_script; fi
if [[ -z "${fqdn}" && -n "${ip}" ]]; then fqdn="${ip}"; fi

# Check script options.
if [[ -f /tmp/EUS/script_options && -s /tmp/EUS/script_options ]]; then IFS=" " read -r script_options <<< "$(tr '\r\n' ' ' < /tmp/EUS/script_options)"; fi

# Check if --show-progrss is supported in wget version
if wget --help | grep -q '\--show-progress'; then if ! grep -q "show-progress" /tmp/EUS/wget_option &> /dev/null; then echo "--show-progress" &>> /tmp/EUS/wget_option; fi; fi
if [[ -f /tmp/EUS/wget_option && -s /tmp/EUS/wget_option ]]; then IFS=" " read -r -a wget_progress <<< "$(tr '\r\n' ' ' < /tmp/EUS/wget_option)"; rm --force /tmp/EUS/wget_option &> /dev/null; fi

# Check if --allow-change-held-packages is supported in apt
# Disabled for arm64 due to MongoDB 4.4 issues
architecture=$(dpkg --print-architecture)
if ! [[ "${architecture}" == "arm64" ]]; then
  if [[ "$(dpkg -l apt | grep ^"ii" | awk '{print $2,$3}' | awk '{print $2}' | cut -d'.' -f1)" -ge "1" ]] || [[ "$(dpkg -l apt | grep ^"ii" | awk '{print $2,$3}' | awk '{print $2}' | cut -d'.' -f1)" == "1" ]] && [[ "$(dpkg -l apt | grep ^"ii" | awk '{print $2,$3}' | awk '{print $2}' | cut -d'.' -f2)" -ge "1" ]]; then if ! grep -q "allow-change-held-packages" /tmp/EUS/apt_option &> /dev/null; then echo "--allow-change-held-packages" &>> /tmp/EUS/apt_option; fi; fi
  if [[ -f /tmp/EUS/apt_option && -s /tmp/EUS/apt_option ]]; then IFS=" " read -r -a apt_options <<< "$(tr '\r\n' ' ' < /tmp/EUS/apt_option)"; rm --force /tmp/EUS/apt_option &> /dev/null; fi
fi

find "${eus_dir}/logs/" -printf "%f\\n" | grep '.*.log' | awk '!a[$0]++' &> /tmp/EUS/log_files
while read -r log_file; do
  if [[ -f "${eus_dir}/logs/${log_file}" ]]; then
    log_file_size=$(stat -c%s "${eus_dir}/logs/${log_file}")
    if [[ "${log_file_size}" -gt "10485760" ]]; then
      tail -n1000 "${eus_dir}/logs/${log_file}" &> "${log_file}.tmp"
      mv "${eus_dir}/logs/${log_file}.tmp" "${eus_dir}/logs/${log_file}"
    fi
  fi
done < /tmp/EUS/log_files
rm --force /tmp/EUS/log_files

# Get distro.
get_distro() {
  if [[ -z "$(command -v lsb_release)" ]]; then
    if [[ -f "/etc/os-release" ]]; then
      if grep -iq VERSION_CODENAME /etc/os-release; then
        os_codename=$(grep VERSION_CODENAME /etc/os-release | sed 's/VERSION_CODENAME//g' | tr -d '="' | tr '[:upper:]' '[:lower:]')
      elif ! grep -iq VERSION_CODENAME /etc/os-release; then
        os_codename=$(grep PRETTY_NAME /etc/os-release | sed 's/PRETTY_NAME=//g' | tr -d '="' | awk '{print $4}' | sed 's/\((\|)\)//g' | sed 's/\/sid//g' | tr '[:upper:]' '[:lower:]')
        if [[ -z "${os_codename}" ]]; then
          os_codename=$(grep PRETTY_NAME /etc/os-release | sed 's/PRETTY_NAME=//g' | tr -d '="' | awk '{print $3}' | sed 's/\((\|)\)//g' | sed 's/\/sid//g' | tr '[:upper:]' '[:lower:]')
        fi
      fi
    fi
  else
    os_codename=$(lsb_release -cs | tr '[:upper:]' '[:lower:]')
    if [[ "${os_codename}" == 'n/a' ]]; then
      os_codename=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
    fi
  fi
  if [[ "${os_codename}" =~ ^(precise|maya|luna)$ ]]; then repo_codename=precise; os_codename=precise
  elif [[ "${os_codename}" =~ ^(trusty|qiana|rebecca|rafaela|rosa|freya)$ ]]; then repo_codename=trusty; os_codename=trusty
  elif [[ "${os_codename}" =~ ^(xenial|sarah|serena|sonya|sylvia|loki)$ ]]; then repo_codename=xenial; os_codename=xenial
  elif [[ "${os_codename}" =~ ^(bionic|tara|tessa|tina|tricia|hera|juno)$ ]]; then repo_codename=bionic; os_codename=bionic
  elif [[ "${os_codename}" =~ ^(focal|ulyana|ulyssa|uma|una)$ ]]; then repo_codename=focal; os_codename=focal
  elif [[ "${os_codename}" =~ ^(jammy|vanessa|vera|victoria)$ ]]; then repo_codename=jammy; os_codename=jammy
  elif [[ "${os_codename}" =~ ^(stretch|continuum)$ ]]; then repo_codename=stretch; os_codename=stretch
  elif [[ "${os_codename}" =~ ^(buster|debbie|parrot|engywuck-backports|engywuck|deepin)$ ]]; then repo_codename=buster; os_codename=buster
  elif [[ "${os_codename}" =~ ^(bullseye|kali-rolling|elsie|ara)$ ]]; then repo_codename=bullseye; os_codename=bullseye
  else
    repo_codename="${os_codename}"
  fi
}
get_distro

get_repo_url() {
  unset archived_repo
  if dpkg -l apt-transport-https 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
    http_or_https="https"
    add_repositories_http_or_https="http[s]*"
    if [[ "${copied_source_files}" == 'true' ]]; then
      while read -r revert_https_repo_needs_http_file; do
        if [[ "${revert_https_repo_needs_http_file}" == 'source.list' ]]; then
          mv "${revert_https_repo_needs_http_file}" "/etc/apt/source.list" &>> "${eus_dir}/logs/revert-https-repo-needs-http.log"
        else
          mv "${revert_https_repo_needs_http_file}" "/etc/apt/source.list.d/$(basename "${revert_https_repo_needs_http_file}")" &>> "${eus_dir}/logs/revert-https-repo-needs-http.log"
        fi
      done < <(find "${eus_dir}/repositories" -type f -name "*.list")
    fi
  else
    http_or_https="http"
    add_repositories_http_or_https="http"
  fi
  if dpkg -l curl 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
    if [[ "${os_codename}" =~ (precise|trusty|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic) ]]; then
      if curl -s http://old-releases.ubuntu.com/ubuntu/dists/ | grep -iq "${os_codename}" 2> /dev/null; then archived_repo="true"; fi
      if [[ "${archived_repo}" == "true" ]]; then repo_url="http://old-releases.ubuntu.com/ubuntu"; else repo_url="http://archive.ubuntu.com/ubuntu"; fi
    elif [[ "${os_codename}" =~ (jessie|stretch|buster|bullseye|bookworm|trixie|forky) ]]; then
      if curl -s http://archive.debian.org/debian/dists/ | grep -iq "${os_codename}" 2> /dev/null; then archived_repo="true"; fi
      if [[ "${archived_repo}" == "true" ]]; then repo_url="${http_or_https}://archive.debian.org/debian"; else repo_url="${http_or_https}://ftp.debian.org/debian"; fi
    fi
  else
    if [[ "${os_codename}" =~ (precise|trusty|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic) ]]; then
      repo_url="http://archive.ubuntu.com/ubuntu"
    elif [[ "${os_codename}" =~ (jessie|stretch|buster|bullseye|bookworm|trixie|forky) ]]; then
      repo_url="${http_or_https}://archive.debian.org/debian"
    fi
  fi
}
get_repo_url

add_repositories() {
  # shellcheck disable=SC2154
  if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb ${add_repositories_http_or_https}://$(echo -e "${repo_url}" | sed -e 's/https\:\/\///g' -e 's/http\:\/\///g')${repo_url_arguments} ${repo_codename}${repo_arguments}") -eq 0 ]]; then
    if ! echo -e "deb ${repo_url}${repo_url_arguments} ${repo_codename}${repo_arguments}" &>> /etc/apt/sources.list.d/glennr-install-script.list; then
      echo -e "${RED}#{WHITE_R} Failed to add repository...\\n"
      abort
    fi
    if [[ -n "${missing_key}" ]]; then if ! echo -e "${missing_key}" &>> /tmp/EUS/keys/missing_keys; then echo -e "${RED}#{WHITE_R} Failed to add missing key \"${missing_key}\" to \"/tmp/EUS/keys/missing_keys\"...\\n"; fi; fi
    unset missing_key
    unset repo_url_arguments
  fi
  if [[ "${add_repositories_http_or_https}" == 'http' ]]; then
    if ! [[ -d "${eus_dir}/repositories" ]]; then if ! mkdir -p "${eus_dir}/repositories"; then echo -e "${RED}#${RESET} Failed to create required EUS Repositories directory..."; fi; fi
    while read -r https_repo_needs_http_file; do
      if [[ -d "${eus_dir}/repositories" ]]; then 
        cp "${https_repo_needs_http_file}" "${eus_dir}/repositories/$(basename "${https_repo_needs_http_file}")" &>> "${eus_dir}/logs/https-repo-needs-http.log"
        copied_source_files="true"
      fi
      sed -i '/https/{s/^/#/}' "${https_repo_needs_http_file}" &>> "${eus_dir}/logs/https-repo-needs-http.log"
      sed -i 's/##/#/g' "${https_repo_needs_http_file}" &>> "${eus_dir}/logs/https-repo-needs-http.log"
    done < <(grep -ril "^deb https*://$(echo -e "${repo_url}" | sed -e 's/https\:\/\///g' -e 's/http\:\/\///g') ${repo_codename}${repo_arguments}" /etc/apt/sources.list /etc/apt/sources.list.d/*)
  fi
}

# Check if system runs Unifi OS
if dpkg -l unifi-core 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
  header_red
  echo -e "${GREEN}#${RESET} This script shouldn't be ran on UniFi OS Consoles... \\n" && sleep 2
  exit 0
fi

run_apt_get_update() {
  if ! [[ -d /tmp/EUS/keys ]]; then mkdir -p /tmp/EUS/keys; fi
  if ! [[ -f /tmp/EUS/keys/missing_keys && -s /tmp/EUS/keys/missing_keys ]]; then
    if [[ "${hide_apt_update}" == 'true' ]]; then
      echo -e "${WHITE_R}#${RESET} Running apt-get update..."
      if apt-get update &> /tmp/EUS/keys/apt_update; then echo -e "${GREEN}#${RESET} Successfully ran apt-get update! \\n"; else echo -e "${YELLOW}#${RESET} Something went wrong during running apt-get update! \\n"; fi
      unset hide_apt_update
    else
      apt-get update 2>&1 | tee /tmp/EUS/keys/apt_update
    fi
    grep -o 'NO_PUBKEY.*' /tmp/EUS/keys/apt_update | sed 's/NO_PUBKEY //g' | tr ' ' '\n' | awk '!a[$0]++' &> /tmp/EUS/keys/missing_keys
  fi
  if [[ -f /tmp/EUS/keys/missing_keys && -s /tmp/EUS/keys/missing_keys ]]; then
    #header
    #echo -e "${WHITE_R}#${RESET} Some keys are missing.. The script will try to add the missing keys."
    #echo -e "\\n${WHITE_R}----${RESET}\\n"
    if dpkg -l dirmngr 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
      while read -r key; do
        echo -e "${WHITE_R}#${RESET} Key ${key} is missing.. adding!"
        http_proxy=$(env | grep -i "http.*Proxy" | cut -d'=' -f2 | sed 's/[";]//g')
        if [[ -n "$http_proxy" ]]; then
          apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --keyserver-options http-proxy="${http_proxy}" --recv-keys "$key" &> /dev/null && echo -e "${GREEN}#${RESET} Successfully added key ${key}!\\n" || fail_key="true"
        elif [[ -f /etc/apt/apt.conf ]]; then
          apt_http_proxy=$(grep "http.*Proxy" /etc/apt/apt.conf | awk '{print $2}' | sed 's/[";]//g')
          if [[ -n "${apt_http_proxy}" ]]; then
            apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --keyserver-options http-proxy="${apt_http_proxy}" --recv-keys "$key" &> /dev/null && echo -e "${GREEN}#${RESET} Successfully added key ${key}!\\n" || fail_key="true"
          fi
        else
          apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv "$key" &> /dev/null && echo -e "${GREEN}#${RESET} Successfully added key ${key}!\\n" || fail_key="true"
        fi
        if [[ "${fail_key}" == 'true' ]]; then
          echo -e "${RED}#${RESET} Failed to add key ${key}... \\n"
          echo -e "${WHITE_R}#${RESET} Trying different method to get key: ${key}"
          gpg -vvv --debug-all --keyserver keyserver.ubuntu.com --recv-keys "${key}" &> /tmp/EUS/keys/failed_key
          debug_key=$(grep "KS_GET" /tmp/EUS/keys/failed_key | grep -io "0x.*")
          if wget -q "https://keyserver.ubuntu.com/pks/lookup?op=get&search=${debug_key}" -O- | gpg --dearmor > "/tmp/EUS/keys/EUS-${key}.gpg"; then
            mv "/tmp/EUS/keys/EUS-${key}.gpg" /etc/apt/trusted.gpg.d/ && echo -e "${GREEN}#${RESET} Successfully added key ${key}!\\n"
          else
            echo -e "${RED}#${RESET} Failed to add key ${key}... \\n"
          fi
        fi
        sleep 1
      done < /tmp/EUS/keys/missing_keys
      rm --force /tmp/EUS/keys/missing_keys
      rm --force /tmp/EUS/keys/apt_update
    else
      echo -e "${WHITE_R}#${RESET} Keys appear to be missing..." && sleep 1
      echo -e "${YELLOW}#${RESET} Required package dirmngr is missing... cannot recover keys... \\n"
    fi
    #header
    #echo -e "${WHITE_R}#${RESET} Running apt-get update again.\\n\\n"
    #sleep 2
    apt-get update &> /tmp/EUS/keys/apt_update
    if dpkg -l dirmngr 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
      if grep -qo 'NO_PUBKEY.*' /tmp/EUS/keys/apt_update; then
        if [[ "${hide_apt_update}" != 'true' ]]; then hide_apt_update="true"; fi
        run_apt_get_update
      fi
    fi
  fi
}

christmass_new_year() {
  date_d=$(date '+%d' | sed "s/^0*//g; s/\.0*/./g")
  date_m=$(date '+%m' | sed "s/^0*//g; s/\.0*/./g")
  if [[ "${date_m}" == '12' && "${date_d}" -ge '18' && "${date_d}" -lt '26' ]]; then
    echo -e "\\n${WHITE_R}----${RESET}\\n"
    echo -e "${WHITE_R}#${RESET} GlennR wishes you a Merry Christmas! May you be blessed with health and happiness!"
    christmas_message="true"
  fi
  if [[ "${date_m}" == '12' && "${date_d}" -ge '24' && "${date_d}" -le '30' ]]; then
    if [[ "${christmas_message}" != 'true' ]]; then echo -e "\\n${WHITE_R}----${RESET}\\n"; fi
    if [[ "${christmas_message}" == 'true' ]]; then echo -e ""; fi
    date_y=$(date -d "+1 year" +"%Y")
    echo -e "${WHITE_R}#${RESET} HAPPY NEW YEAR ${date_y}"
    echo -e "${WHITE_R}#${RESET} May the new year turn all your dreams into reality and all your efforts into great achievements!"
    new_year_message="true"
  elif [[ "${date_m}" == '12' && "${date_d}" == '31' ]]; then
    if [[ "${christmas_message}" != 'true' ]]; then echo -e "\\n${WHITE_R}----${RESET}\\n"; fi
    if [[ "${christmas_message}" == 'true' ]]; then echo -e ""; fi
    date_y=$(date -d "+1 year" +"%Y")
    echo -e "${WHITE_R}#${RESET} HAPPY NEW YEAR ${date_y}"
    echo -e "${WHITE_R}#${RESET} Tomorrow, is the first blank page of a 365 page book. Write a good one!"
    new_year_message="true"
  fi
  if [[ "${date_m}" == '1' && "${date_d}" -le '5' ]]; then
    if [[ "${christmas_message}" != 'true' ]]; then echo -e "\\n${WHITE_R}----${RESET}\\n"; fi
    if [[ "${christmas_message}" == 'true' ]]; then echo -e ""; fi
    date_y=$(date '+%Y')
    echo -e "${WHITE_R}#${RESET} HAPPY NEW YEAR ${date_y}"
    echo -e "${WHITE_R}#${RESET} May this new year all your dreams turn into reality and all your efforts into great achievements"
    new_year_message="true"
  fi
}

author() {
  if [[ -f "/etc/apt/sources.list.d/glennr-install-script.list" ]]; then
    awk '{print $3}' /etc/apt/sources.list.d/glennr-install-script.list | awk '!a[$0]++' | sed "/${os_codename}/d" | sed 's/ //g' &> /tmp/EUS/sourcelist
    while read -r sourcelist_os_codename; do
      sed -i "/${sourcelist_os_codename}/d" /etc/apt/sources.list.d/glennr-install-script.list &> /dev/null
    done < /tmp/EUS/sourcelist
    rm --force /tmp/EUS/sourcelist &> /dev/null
    if ! [[ -s "/etc/apt/sources.list.d/glennr-install-script.list" ]]; then
      rm --force /etc/apt/sources.list.d/glennr-install-script.list &> /dev/null
    fi
  fi
  christmass_new_year
  if [[ "${new_year_message}" == 'true' || "${christmas_message}" == 'true' ]]; then echo -e "\\n${WHITE_R}----${RESET}\\n"; fi
  if [[ "${archived_repo}" == 'true' ]]; then echo -e "\\n${WHITE_R}----${RESET}\\n\\n${RED}# ${RESET}Looks like you're using a ${RED}EOL/unsupported${RESET} OS Release (${os_codename})\\n${RED}# ${RESET}Please update to a supported release...\\n"; fi
  echo -e "${WHITE_R}#${RESET} ${GRAY_R}Author   |  ${WHITE_R}Glenn R.${RESET}"
  echo -e "${WHITE_R}#${RESET} ${GRAY_R}Email    |  ${WHITE_R}glennrietveld8@hotmail.nl${RESET}"
  echo -e "${WHITE_R}#${RESET} ${GRAY_R}Website  |  ${WHITE_R}https://GlennR.nl${RESET}\\n\\n"
}

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                          Script Update                                                                                          #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

script_online_version_dots=$(curl -s https://get.glennr.nl/unifi/tools/unifi-remote-adoption.sh | grep -i "# Version" | head -n 1 | cut -d'|' -f2 | sed 's/ //g')
script_local_version_dots=$(grep -i "# Version" "${script_location}" | head -n 1 | cut -d'|' -f2 | sed 's/ //g')
script_online_version="${script_online_version_dots//./}"
script_local_version="${script_local_version_dots//./}"

# Script version check.
if [[ "${script_online_version::3}" -gt "${script_local_version::3}" ]]; then
  header_red
  echo -e "${WHITE_R}#${RESET} You're currently running script version ${script_local_version_dots} while ${script_online_version_dots} is the latest!"
  echo -e "${WHITE_R}#${RESET} Downloading and executing version ${script_online_version_dots} of the Easy UniFi Device Set Inform Script..\\n\\n"
  sleep 3
  rm --force "${script_location}" 2> /dev/null
  rm --force unifi-remote-adoption.sh 2> /dev/null
  # shellcheck disable=SC2068
  wget -q "${wget_progress[@]}" https://get.glennr.nl/unifi/tools/unifi-remote-adoption.sh && bash unifi-remote-adoption.sh ${script_options[@]}; exit 0
fi

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                        Required Packages                                                                                        #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

install_required_packages() {
  sleep 2
  installing_required_package=yes
  header
  echo -e "${WHITE_R}#${RESET} Installing required packages for the script..\\n"
  hide_apt_update="true"
  run_apt_get_update
  sleep 2
}
apt_get_install_package() {
  unset update_ca_certificates_ran
  apt_get_install_package_variable="install"
  apt_get_install_package_variable_2="installed"
  hide_apt_update="true"
  run_apt_get_update
  echo -e "\\n------- ${required_package} installation ------- $(date +%F-%R) -------\\n" &>> "${eus_dir}/logs/apt.log"
  echo -e "${WHITE_R}#${RESET} Trying to ${apt_get_install_package_variable} ${required_package}..."
  if DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg6::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "${required_package}" &>> "${eus_dir}/logs/apt.log"; then
    echo -e "${GREEN}#${RESET} Successfully ${apt_get_install_package_variable_2} ${required_package}! \\n"
    sleep 2
  else
    echo -e "${RED}#${RESET} Failed to ${apt_get_install_package_variable} ${required_package}...\\n"
    abort
  fi
  unset required_package
}

if ! dpkg -l nmap 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
  if [[ "${installing_required_package}" != 'yes' ]]; then
    install_required_packages
  fi
  echo -e "${WHITE_R}#${RESET} Installing nmap..."
  if ! DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install nmap &>> "${eus_dir}/logs/required.log"; then
    echo -e "${RED}#${RESET} Failed to install nmap in the first run...\\n"
    if [[ "${repo_codename}" =~ (precise|trusty|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic) ]]; then
      repo_arguments=" universe"
      add_repositories
      repo_arguments=" main restricted"
    elif [[ "${repo_codename}" =~ (jessie|stretch|buster|bullseye|bookworm|trixie|forky) ]]; then
      repo_arguments=" main"
    fi
    add_repositories
    required_package="nmap"
    apt_get_install_package
  else
    echo -e "${GREEN}#${RESET} Successfully installed nmap! \\n" && sleep 2
  fi
fi
if ! dpkg -l sshpass 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
  if [[ "${installing_required_package}" != 'yes' ]]; then
    install_required_packages
  fi
  echo -e "${WHITE_R}#${RESET} Installing sshpass..."
  if ! DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install sshpass &>> "${eus_dir}/logs/required.log"; then
    echo -e "${RED}#${RESET} Failed to install sshpass in the first run...\\n"
    if [[ "${repo_codename}" =~ (precise|trusty|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic) ]]; then
      repo_arguments=" universe"
      add_repositories
      repo_arguments=" main restricted"
    elif [[ "${repo_codename}" =~ (jessie|stretch|buster|bullseye|bookworm|trixie|forky) ]]; then
      repo_arguments=" main"
    fi
    add_repositories
    required_package="sshpass"
    apt_get_install_package
  else
    echo -e "${GREEN}#${RESET} Successfully installed sshpass! \\n" && sleep 2
  fi
fi

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                            Variables                                                                                            #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

declare -a unifi_default_credentials=('ui/ui' 'ubnt/ubnt');

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                         Finding devices                                                                                         #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

header
echo -e "${WHITE_R}#${RESET} Searching for devices on network ${subnet} that are listening on port 10001/udp..."
while read -r device_ip; do
  if [[ "${found_message}" != 'true' ]]; then echo -e "${GREEN}#${RESET} Succesfully found devices that are listening on port 10001/udp... \\n"; found_message="true"; fi
  while read -r default_credentials; do
    username="$(echo -e "${default_credentials}" | cut -d'/' -f1)"
    password="$(echo -e "${default_credentials}" | cut -d'/' -f2)"
    echo -ne "\\r${WHITE_R}#${RESET} Attempting to SSH into ${device_ip} with credentials \"${default_credentials}\"...                   "
    if timeout 5 sshpass -p "${password}" ssh -q -o StrictHostKeyChecking=no "${username}"@"${device_ip}" "mca-cli-op set-inform http://${fqdn}:${port}/inform" &> /dev/null; then
      echo -e "\\r${GREEN}#${RESET} Succesfully told ${device_ip} to reach out to ${fqdn}!                    \\n"
      break
    else
      echo -ne "\\r${RED}#${RESET} Failed to SSH into ${device_ip} with credentials \"${default_credentials}\"...                          "
      sleep 1
    fi
  done < <(printf '%s\n' "${unifi_default_credentials[@]}")
done < <(nmap -n -sU -p10001,22 "${subnet}" -oG - | awk '/10001\/open/{print $2}')
echo -ne "\\r${GREEN}#${RESET} All devices that the script found should now be pointing to ${fqdn}!                    \\n\\n\\n"
author