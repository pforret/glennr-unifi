#!/bin/bash

# UniFi Network Application Fail2ban configuration.
# Version  | 2.0.6
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

eus_directories() {  if uname -a | tr '[:upper:]' '[:lower:]' | grep -iq "cloudkey\\|uck\\|ubnt-mtk"; then
    eus_dir='/srv/EUS'
  elif grep -iq "UCKP\\|UCKG2\\|UCK" /usr/lib/version &> /dev/null; then
    eus_dir='/srv/EUS'
  else
    eus_dir='/usr/lib/EUS'
  fi
  mkdir -p "${eus_dir}"
  mkdir -p "${eus_dir}/logs"
  if ! [[ -d "/etc/apt/keyrings" ]]; then if ! install -m "0755" -d "/etc/apt/keyrings" &>> "${eus_dir}/logs/keyrings-directory-creation.log"; then if ! mkdir -m "0755" -p "/etc/apt/keyrings" &>> "${eus_dir}/logs/keyrings-directory-creation.log"; then echo -e "${RED}#${RESET} Failed to create \"/etc/apt/keyrings\"..."; abort; fi; fi; if ! [[ -s "${eus_dir}/logs/keyrings-directory-creation.log" ]]; then rm --force "${eus_dir}/logs/keyrings-directory-creation.log"; fi; fi
  mkdir -p "/tmp/EUS"
}

script_logo() {
  cat << "EOF"
  _______________ ___  _________  ___________      .__.__   __________________                
  \_   _____/    |   \/   _____/  \_   _____/____  |__|  |  \_____  \______   \_____    ____  
   |    __)_|    |   /\_____  \    |    __) \__  \ |  |  |   /  ____/|    |  _/\__  \  /    \ 
   |        \    |  / /        \   |     \   / __ \|  |  |__/       \|    |   \ / __ \|   |  \
  /_______  /______/ /_______  /   \___  /  (____  /__|____/\_______ \______  /(____  /___|  /
          \/                 \/        \/        \/                 \/      \/      \/     \/ 

EOF
}

start_script() {
  script_location="${BASH_SOURCE[0]}"
  eus_directories
  header
  script_logo
  echo -e "    UniFi Easy Fail2Ban Script!"
  echo -e "\\n${WHITE_R}#${RESET} Starting the Easy Fail2Ban Script.."
  echo -e "${WHITE_R}#${RESET} Thank you for using my Easy Fail2Ban Script :-)\\n\\n"
  sleep 4
}
start_script

# Check if --show-progrss is supported in wget version
if wget --help | grep -q '\--show-progress'; then if ! grep -q "show-progress" /tmp/EUS/wget_option &> /dev/null; then echo "--show-progress" &>> /tmp/EUS/wget_option; fi; fi
if [[ -f /tmp/EUS/wget_option && -s /tmp/EUS/wget_option ]]; then IFS=" " read -r -a wget_progress <<< "$(tr '\r\n' ' ' < /tmp/EUS/wget_option)"; rm --force /tmp/EUS/wget_option &> /dev/null; fi

# Check if --allow-change-held-packages is supported in apt
architecture=$(dpkg --print-architecture)
get_apt_options() {
  if [[ "${remove_apt_options}" == "true" ]]; then get_apt_option_arguments="false"; unset apt_options; fi
  if [[ "${get_apt_option_arguments}" != "false" ]]; then
    if [[ "$(dpkg -l apt | grep ^"ii" | awk '{print $2,$3}' | awk '{print $2}' | cut -d'.' -f1)" -ge "1" ]] || [[ "$(dpkg -l apt | grep ^"ii" | awk '{print $2,$3}' | awk '{print $2}' | cut -d'.' -f1)" == "1" ]] && [[ "$(dpkg -l apt | grep ^"ii" | awk '{print $2,$3}' | awk '{print $2}' | cut -d'.' -f2)" -ge "1" ]]; then if ! grep -q "allow-change-held-packages" /tmp/EUS/apt_option &> /dev/null; then echo "--allow-change-held-packages" &>> /tmp/EUS/apt_option; fi; fi
    if [[ -f /tmp/EUS/apt_option && -s /tmp/EUS/apt_option ]]; then IFS=" " read -r -a apt_options <<< "$(tr '\r\n' ' ' < /tmp/EUS/apt_option)"; rm --force /tmp/EUS/apt_option &> /dev/null; fi
  fi
  unset get_apt_option_arguments
}
get_apt_options

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
  if [[ -z "$(command -v lsb_release)" ]] || [[ "${skip_use_lsb_release}" == 'true' ]]; then
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
      skip_use_lsb_release="true"
      get_distro
      return
    fi
  fi
  if [[ "${os_codename}" =~ ^(precise|maya|luna)$ ]]; then repo_codename=precise; os_codename=precise
  elif [[ "${os_codename}" =~ ^(trusty|qiana|rebecca|rafaela|rosa|freya)$ ]]; then repo_codename=trusty; os_codename=trusty
  elif [[ "${os_codename}" =~ ^(xenial|sarah|serena|sonya|sylvia|loki)$ ]]; then repo_codename=xenial; os_codename=xenial
  elif [[ "${os_codename}" =~ ^(bionic|tara|tessa|tina|tricia|hera|juno)$ ]]; then repo_codename=bionic; os_codename=bionic
  elif [[ "${os_codename}" =~ ^(focal|ulyana|ulyssa|uma|una)$ ]]; then repo_codename=focal; os_codename=focal
  elif [[ "${os_codename}" =~ ^(jammy|vanessa|vera|victoria|virginia)$ ]]; then repo_codename=jammy; os_codename=jammy
  elif [[ "${os_codename}" =~ ^(stretch|continuum)$ ]]; then repo_codename=stretch; os_codename=stretch
  elif [[ "${os_codename}" =~ ^(buster|debbie|parrot|engywuck-backports|engywuck|deepin)$ ]]; then repo_codename=buster; os_codename=buster
  elif [[ "${os_codename}" =~ ^(bullseye|kali-rolling|elsie|ara)$ ]]; then repo_codename=bullseye; os_codename=bullseye
  elif [[ "${os_codename}" =~ ^(bookworm|lory|faye)$ ]]; then repo_codename=bookworm; os_codename=bookworm
  else
    repo_codename="${os_codename}"
  fi
}
get_distro

get_repo_url() {
  unset archived_repo
  if [[ "${os_codename}" != "${repo_codename}" ]]; then os_codename="${repo_codename}"; os_codename_changed="true"; fi
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
    if [[ "${os_codename}" =~ (precise|trusty|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble) ]]; then
      if curl -s "${http_or_https}://old-releases.ubuntu.com/ubuntu/dists/" | grep -iq "${os_codename}" 2> /dev/null; then archived_repo="true"; fi
      if [[ "${architecture}" =~ (amd64|i386) ]]; then
        if [[ "${archived_repo}" == "true" ]]; then repo_url="${http_or_https}://old-releases.ubuntu.com/ubuntu"; else repo_url="http://archive.ubuntu.com/ubuntu"; fi
      else
        if [[ "${archived_repo}" == "true" ]]; then repo_url="${http_or_https}://old-releases.ubuntu.com/ubuntu"; else repo_url="http://ports.ubuntu.com"; fi
      fi
    elif [[ "${os_codename}" =~ (jessie|stretch|buster|bullseye|bookworm|trixie|forky) ]]; then
      if curl -s "${http_or_https}://archive.debian.org/debian/dists/" | grep -iq "${os_codename}" 2> /dev/null; then archived_repo="true"; fi
      if [[ "${archived_repo}" == "true" ]]; then repo_url="${http_or_https}://archive.debian.org/debian"; else repo_url="${http_or_https}://ftp.debian.org/debian"; fi
      if [[ "${architecture}" == 'armhf' ]]; then
        if curl -s "${http_or_https}://legacy.raspbian.org/raspbian/dists/" | grep -iq "${os_codename}" 2> /dev/null; then archived_raspbian_repo="true"; fi
        if [[ "${archived_raspbian_repo}" == "true" ]]; then raspbian_repo_url="${http_or_https}://legacy.raspbian.org/raspbian"; else raspbian_repo_url="${http_or_https}://archive.raspbian.org/raspbian"; fi
      fi
    fi
  else
    if [[ "${os_codename}" =~ (precise|trusty|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble) ]]; then
      repo_url="http://archive.ubuntu.com/ubuntu"
    elif [[ "${os_codename}" =~ (jessie|stretch|buster|bullseye|bookworm|trixie|forky) ]]; then
      repo_url="${http_or_https}://archive.debian.org/debian"
      if [[ "${architecture}" == 'armhf' ]]; then
        raspbian_repo_url="${http_or_https}://archive.raspbian.org/raspbian"
      fi
    fi
  fi
}
get_repo_url

add_repositories() {
  # shellcheck disable=SC2154
  if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb ${add_repositories_http_or_https}://$(echo "${repo_url}" | sed -e 's/https\:\/\///g' -e 's/http\:\/\///g')${repo_url_arguments} ${repo_codename}${repo_arguments}") -eq 0 ]]; then
    if [[ "${apt_key_deprecated}" == 'true' ]]; then
      if [[ -n "${repo_key}" && -n "${repo_key_name}" ]]; then
        if gpg --no-default-keyring --keyring "/etc/apt/keyrings/${repo_key_name}.gpg" --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys "${repo_key}" &> /dev/null; then
          signed_by_value_repo_key="[ /etc/apt/keyrings/${repo_key_name}.gpg ] "
        else
          echo -e "${RED}#{WHITE_R} Failed to add repository key ${repo_key}...\\n"
          abort
        fi
      fi
    else
      missing_key="${repo_key}"
      if [[ -n "${missing_key}" ]]; then
        if ! echo -e "${missing_key}" &>> /tmp/EUS/keys/missing_keys; then
          echo -e "${RED}#{WHITE_R} Failed to add missing key \"${missing_key}\" to \"/tmp/EUS/keys/missing_keys\"...\\n"
        fi
      fi
    fi
    if ! echo -e "deb ${signed_by_value_repo_key}${repo_url}${repo_url_arguments} ${repo_codename}${repo_arguments}" &>> /etc/apt/sources.list.d/glennr-install-script.list; then
      echo -e "${RED}#{WHITE_R} Failed to add repository...\\n"
      abort
    fi
    unset missing_key
    unset repo_key
    unset repo_key_name
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

remove_yourself() {
  if [[ "${set_lc_all}" == 'true' ]]; then unset LC_ALL &> /dev/null; fi
  if [[ "${delete_script}" == 'true' ]]; then if [[ -e "${script_location}" ]]; then rm --force "${script_location}" 2> /dev/null; fi; fi
}

cancel_script() {
  header
  echo -e "${WHITE_R}#${RESET} Cancelling the script!\\n\\n"
  author
  remove_yourself
  exit 0
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

script_online_version_dots=$(curl -s https://get.glennr.nl/unifi/extra/unifi-fail2ban.sh | grep -i "# Version" | head -n 1 | cut -d'|' -f2 | sed 's/ //g')
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
  rm --force unifi-fail2ban.sh 2> /dev/null
  # shellcheck disable=SC2068
  wget -q "${wget_progress[@]}" https://get.glennr.nl/unifi/extra/unifi-fail2ban.sh && bash unifi-fail2ban.sh; exit 0
fi

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                           Script Start                                                                                          #
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

if ! dpkg -l fail2ban 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
  if [[ "${installing_required_package}" != 'yes' ]]; then
    install_required_packages
  fi
  echo -e "${WHITE_R}#${RESET} Installing fail2ban..."
  if ! DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install fail2ban &>> "${eus_dir}/logs/required.log"; then
    echo -e "${RED}#${RESET} Failed to install fail2ban in the first run...\\n"
    if [[ "${repo_codename}" =~ (precise|trusty|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic) ]]; then
      repo_arguments=" universe"
      add_repositories
      repo_arguments=" main restricted"
    elif [[ "${repo_codename}" =~ (jessie|stretch|buster|bullseye|bookworm|trixie|forky) ]]; then
      repo_arguments=" main"
    fi
    add_repositories
    required_package="fail2ban"
    apt_get_install_package
  else
    echo -e "${GREEN}#${RESET} Successfully installed fail2ban! \\n" && sleep 2
  fi
fi

script_removal() {
  if [[ "${installing_required_package}" != 'yes' ]]; then
    echo -e "${GREEN}---${RESET}\\n"
  else
    header
  fi
  read -rp $'\033[39m#\033[0m Do you want to keep the script on your system after completion? (Y/n) ' yes_no
  case "$yes_no" in
      [Yy]*|"") ;;
      [Nn]*) delete_script="true";;
  esac
}
script_removal

maxretry_question() {
  header
  echo -e "${WHITE_R}#${RESET} After how many attempts should we block the connection?"
  echo ""
  echo -e " [   ${WHITE_R}1${RESET}   ]  |  3 Retries ( default )"
  echo -e " [   ${WHITE_R}2${RESET}   ]  |  6 Retries"
  echo -e " [   ${WHITE_R}3${RESET}   ]  |  I want to specify the number myself"
  echo -e " [   ${WHITE_R}4${RESET}   ]  |  Cancel\\n\\n"
  read -rp $'Your choice | \033[39m' maxretry_choice
  case "${maxretry_choice}" in
      1*|"") max_retry='3';;
      2*) max_retry='6' ;;
      3*)
        header
        echo -e "${WHITE_R}#${RESET} After how many attempts should we block the connection? \\n"
        read -n 2 -rp $'Amount of retries | \033[39m' amount
        if ! [[ "${amount}" =~ ^[0-9]{1,2}$ ]]; then
          clear
          header_red
          echo -e "${WHITE_R}#${RESET} '${amount}' is not a valid format, please only use numbers (0-9) with a maximum of 2..." && sleep 3
          maxretry_question
        fi
        max_retry="${amount}";;
      4|*) cancel_script;;
  esac
}
maxretry_question

header
echo -e "${WHITE_R}#${RESET} Creating the UniFi Fail2Ban filter..."
if ! [[ -d "/etc/fail2ban/filter.d/" ]]; then if ! mkdir -p "/etc/fail2ban/filter.d/"; then header_red; echo -e "${RED}#${RESET} Failed to create required Fail2Ban Filter directory..."; abort; fi; fi
tee /etc/fail2ban/filter.d/unifi.conf &>/dev/null <<EOL
[INCLUDES]
before = common.conf
[Definition]
failregex = ^(.*)Failed admin login for (.*) from <HOST>$
ignoreregex =
EOL
if [[ -e "/etc/fail2ban/filter.d/unifi.conf" ]]; then
  echo -e "${GREEN}#${RESET} Successfully created the UniFi Fail2Ban filter! \\n"
  sleep 2
else
  echo -e "${RED}#${RESET} Failed to create the UniFi Fail2Ban filter...\\n"
  abort
fi

echo -e "${WHITE_R}#${RESET} Creating the UniFi Fail2Ban jail configuration..."
if ! [[ -d "/etc/fail2ban/jail.d/" ]]; then if ! mkdir -p "/etc/fail2ban/jail.d/"; then header_red; echo -e "${RED}#${RESET} Failed to create required Fail2Ban Jail directory..."; abort; fi; fi
unifi_https_port="$(grep -Eio ^"unifi.https.port=[0-9]{1,5}" /usr/lib/unifi/data/system.properties | cut -d'=' -f2)"
if [[ -z "${unifi_https_port}" ]]; then unifi_https_port="8443"; fi
tee /etc/fail2ban/jail.d/unifi.conf &>/dev/null <<EOL
[unifi]
enabled = true
filter = unifi
port = ${unifi_https_port}
logpath = $(readlink -f /usr/lib/unifi/logs/server.log)
maxretry = ${max_retry}
bantime = 600
findtime = 900
action = iptables[name="unifi", port="${unifi_https_port}"]
EOL
if [[ -e "/etc/fail2ban/jail.d/unifi.conf" ]]; then
  echo -e "${GREEN}#${RESET} Successfully created the UniFi Fail2Ban jail configuration! \\n"
  sleep 2
else
  echo -e "${RED}#${RESET} Failed to create the UniFi Fail2Ban jail configuration...\\n"
  abort
fi

echo -e "${WHITE_R}#${RESET} Restarting Fail2Ban..."
if service fail2ban restart &>> "${eus_dir}/logs/fail2ban.log"; then
  echo -e "${GREEN}#${RESET} Successfully restarted Fail2Ban! You're now protected! \\n"
  echo -e "${WHITE_R}#${RESET} Make sure your Management Log Level is set to More/Verbose or Debug."
  echo -e "${WHITE_R}#${RESET} Settings > System > Advanced > Logging Levels (disable Auto)\\n\\n"
  author
  remove_yourself
else
  echo -e "${RED}#${RESET} Failed to restart fail2ban...\\n"
  abort
fi