#!/bin/bash

# UniFi Video Easy Installation Script.
# OS       | List of supported Distributions/OS
#
#          | Ubuntu Xenial Xerus ( 16.04 )
#          | Ubuntu Bionic Beaver ( 18.04 )
#          | Ubuntu Cosmic Cuttlefish ( 18.10 )
#          | Ubuntu Disco Dingo ( 19.04 )
#          | Ubuntu Eoan Ermine ( 19.10 )
#          | Ubuntu Focal Fossa ( 20.04 )
#          | Ubuntu Groovy Gorilla ( 20.10 )
#          | Debian Jessie ( 8 )
#          | Debian Stretch ( 9 )
#          | Debian Buster ( 10 )
#          | Debian Bullseye ( 11 )
#          | Linux Mint 13 ( Maya )
#          | Linux Mint 17 ( Qiana | Rebecca | Rafaela | Rosa )
#          | Linux Mint 18 ( Sarah | Serena | Sonya | Sylvia )
#          | Linux Mint 19 ( Tara | Tessa | Tina | Tricia )
#          | Linux Mint 20 ( Ulyana | Ulyssa )
#          | Linux Mint 4 ( Debbie )
#          | MX Linux 18 ( Continuum )
#          | Progress-Linux ( Engywuck )
#          | Parrot OS
#          | Elementary OS
#          | Kali Linux ( rolling )
#
# Version    | 3.4.2
# NVR        | 3.10.11
# Author     | Glenn Rietveld
# Email      | glennrietveld8@hotmail.nl
# Website    | https://GlennR.nl

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                           Color Codes                                                                                           #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

RESET='\033[0m'
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

if ! env | grep "LC_ALL\\|LANG" | grep -iq "en_US\\|C.UTF-8"; then
  header
  echo -e "${WHITE_R}#${RESET} Your language is not set to English ( en_US ), the script will temporarily set the language to English."
  echo -e "${WHITE_R}#${RESET} Information: This is done to prevent issues in the script.."
  export LC_ALL=C &> /dev/null
  set_lc_all=true
  sleep 3
fi

abort() {
  if [[ "${set_lc_all}" == 'true' ]]; then unset LC_ALL; fi
  echo -e "\\n\\n${RED}#########################################################################${RESET}\\n"
  echo -e "${WHITE_R}#${RESET} An error occurred. Aborting script..."
  echo -e "${WHITE_R}#${RESET} Please contact Glenn R. (AmazedMender16) on the Community Forums!\\n"
  echo -e "${WHITE_R}#${RESET} Creating support file..."
  mkdir -p "/tmp/EUS/support" &> /dev/null
  if dpkg -l lsb-release 2> /dev/null | grep -iq "^ii\\|^hi"; then lsb_release -a &> "/tmp/EUS/support/lsb-release"; fi
  df -h &> "/tmp/EUS/support/df"
  free -hm &> "/tmp/EUS/support/memory"
  uname -a &> "/tmp/EUS/support/uname"
  dpkg -l | grep "mongo\\|oracle\\|openjdk\\|unifi" &> "/tmp/EUS/support/unifi-packages"
  dpkg -l &> "/tmp/EUS/support/dpkg-list"
  echo "${architecture}" &> "/tmp/EUS/support/architecture"
  # shellcheck disable=SC2129
  sed -n '3p' "${script_location}" &>> "/tmp/EUS/support/script"
  grep "# Version" "${script_location}" | head -n1 &>> "/tmp/EUS/support/script"
  grep "# NVR" "${script_location}" | head -n1 &>> "/tmp/EUS/support/script"
  if dpkg -l tar 2> /dev/null | grep -iq "^ii\\|^hi"; then
    tar -cvf /tmp/eus_support.tar.gz "/tmp/EUS" "${eus_dir}" &> /dev/null && support_file="/tmp/eus_support.tar.gz"
  elif dpkg -l zip 2> /dev/null | grep -iq "^ii\\|^hi"; then
    zip -r /tmp/eus_support.zip "/tmp/EUS/*" "${eus_dir}/*" &> /dev/null && support_file="/tmp/eus_support.zip"
  fi
  if [[ -n "${support_file}" ]]; then echo -e "${WHITE_R}#${RESET} Support file has been created here: ${support_file} \\n"; fi
  exit 1
}

eus_dir='/usr/lib/EUS'

script_logo() {
  cat << "EOF"

  _______________ ___  _________  .___                 __         .__  .__   
  \_   _____/    |   \/   _____/  |   | ____   _______/  |______  |  | |  |  
   |    __)_|    |   /\_____  \   |   |/    \ /  ___/\   __\__  \ |  | |  |  
   |        \    |  / /        \  |   |   |  \\___ \  |  |  / __ \|  |_|  |__
  /_______  /______/ /_______  /  |___|___|  /____  > |__| (____  /____/____/
          \/                 \/            \/     \/            \/           

    Easy UniFi Video Install Script!
EOF
}


start_script() {
  script_location="${BASH_SOURCE[0]}"
  script_name=$(basename ${BASH_SOURCE[0]})
  mkdir -p "${eus_dir}/logs" 2> /dev/null
  mkdir -p /tmp/EUS/ 2> /dev/null
  mkdir -p /tmp/EUS/upgrade/ 2> /dev/null
  mkdir -p /tmp/EUS/dpkg/ 2> /dev/null
  header
  script_logo
  echo -e "\\n${WHITE_R}#${RESET} Starting the Easy UniFi Video Install Script.."
  echo -e "${WHITE_R}#${RESET} Thank you for using my Easy UniFi Video Install Script :-)\\n\\n"
  sleep 2
}
start_script

help_script() {
  if [[ "${script_option_help}" == 'true' ]]; then header; script_logo; else echo -e "${WHITE_R}----${RESET}\\n"; fi
  echo -e "    Easy UniFi Video Install script assistance\\n"
  echo -e "
  Script usage:
  bash ${script_name} [options]
  
  Script options:
    --skip                                  Skip any kind of manual input.
    --unifi-network                         Makes sure that mongodb is compatible with the UniFi Network Controller. ( 5.13.10 and newer )
    --unifi-network-legacy                  Makes sure that mongodb is compatible with the UniFi Network Controller. ( pre 5.13.10 )
    --custom-url [argument]                 Manually provide a UniFi Video download URL.
                                            example:
                                            --custom-url https://dl.ui.com/firmwares/ufv/v3.10.12/unifi-video.Ubuntu18.04_amd64.v3.10.12.deb
    --help                                  Shows this information :)\\n\\n
  Script options for UniFi Easy Encrypt:
    --v6                                    Run the script in IPv6 mode instead of IPv4.
    --email [argument]                      Specify what email address you want to use
                                            for renewal notifications.
                                            example:
                                            --email glenn@glennr.nl
    --fqdn [argument]                       Specify what domain name ( FQDN ) you want to use, you
                                            can specify multiple domain names with : as seperator, see
                                            the example below:
                                            --fqdn glennr.nl:www.glennr.nl
    --server-ip [argument]                  Specify the server IP address manually.
                                            example:
                                            --server-ip 1.1.1.1
    --retry [argument]                      Retry the unattended script if it aborts for X times.
                                            example:
                                            --retry 5
    --external-dns [argument]               Use external DNS server to resolve the FQDN.
                                            example:
                                            --external-dns 1.1.1.1
    --force-renew                           Force renew the certificates.
    --dns-challenge                         Run the script in DNS mode instead of HTTP.
                                            example:
                                            --private-key /tmp/PRIVATE.key
	--signed-certificate [argument]         Specify path to your signed certificate (paid certificate)
                                            example:
                                            --signed-certificate /tmp/SSL_CERTIFICATE.cer
    --chain-certificate [argument]          Specify path to your chain certificate (paid certificate)
                                            example:
                                            --chain-certificate /tmp/CHAIN.cer
    --intermediate-certificate [argument]   Specify path to your intermediate certificate (paid certificate)
                                            example:
                                            --intermediate-certificate /tmp/INTERMEDIATE.cer
    --own-certificate                       Requirement if you want to import your own paid certificates
                                            with the use of --skip.\\n\\n"
  exit 0
}

rm --force /tmp/EUS/script_options &> /dev/null
rm --force /tmp/EUS/le_script_options &> /dev/null
script_option_list=(-skip --skip --custom-url --unifi-network --unifi-network-legacy --v6 --ipv6 --email --mail --fqdn --domain-name --server-ip --server-address --external-dns --force-renew --renew --dns --dns-challenge --retry --help)

while [ -n "$1" ]; do
  case "$1" in
  -skip | --skip)
       script_option_skip=true
       echo "--skip" &>> /tmp/EUS/script_options
       echo "--skip" &>> /tmp/EUS/le_script_options;;
  --custom-url)
       if echo "${2}" | grep -iq "http[s]://.*ubnt.com/unifi/.*.deb\\|http[s]://.*ui.com/unifi/.*.deb"; then custom_url_down_provided=true; custom_download_url="${2}"; fi
       script_option_custom_url=true
       if [[ "${custom_url_down_provided}" == 'true' ]]; then echo "--custom-url ${2}" &>> /tmp/EUS/script_options; else echo "--custom-url" &>> /tmp/EUS/script_options; fi;;
  --unifi-network)
       install_mongodb_version='3.6'
       echo "--unifi-network" &>> /tmp/EUS/script_options;;
  --unifi-network-legacy)
       install_mongodb_version='3.4'
       echo "--unifi-network" &>> /tmp/EUS/script_options;;
  --custom-url)
       if echo "${2}" | grep -iq "http[s]://.*ubnt.com/unifi/.*.deb\\|http[s]://.*ui.com/unifi/.*.deb"; then custom_url_down_provided=true; custom_download_url="${2}"; fi
       script_option_custom_url=true
       if [[ "${custom_url_down_provided}" == 'true' ]]; then echo "--custom-url ${2}" &>> /tmp/EUS/script_options; else echo "--custom-url" &>> /tmp/EUS/script_options; fi;;
  --help)
       script_option_help=true
       help_script;;
  --v6 | --ipv6)
       echo "--v6" &>> /tmp/EUS/le_script_options;;
  --email | --mail)
       if [[ "${script_option_list[@]}" =~ ${2} ]]; then header_red; echo -e "${WHITE_R}#${RESET} Option ${1} requires a command argument... \\n\\n"; help_script; fi
       echo -e "--email ${2}" &>> /tmp/EUS/le_script_options
       shift;;
  --fqdn | --domain-name)
       if [[ "${script_option_list[@]}" =~ ${2} ]]; then header_red; echo -e "${WHITE_R}#${RESET} Option ${1} requires a command argument... \\n\\n"; help_script; fi
       echo -e "--fqdn ${2}" &>> /tmp/EUS/le_script_options
       fqdn_specified=true
       shift;;
  --server-ip | --server-address)
       if [[ "${script_option_list[@]}" =~ ${2} ]]; then header_red; echo -e "${WHITE_R}#${RESET} Option ${1} requires a command argument... \\n\\n"; help_script; fi
       echo -e "--server-ip ${2}" &>> /tmp/EUS/le_script_options
       shift;;
  --retry)
       if [[ "${script_option_list[@]}" =~ ${2} ]]; then header_red; echo -e "${WHITE_R}#${RESET} Option ${1} requires a command argument... \\n\\n"; help_script; fi
       echo -e "--retry ${2}" &>> /tmp/EUS/le_script_options
       shift;;
  --external-dns)
       echo -e "--external-dns" &>> /tmp/EUS/le_script_options;;
  --force-renew | --renew)
       echo -e "--force-renew" &>> /tmp/EUS/le_script_options;;
  --dns | --dns-challenge)
       echo -e "--dns-challenge" &>> /tmp/EUS/le_script_options;;
  --priv-key | --private-key)
       if [[ "${script_option_list[@]}" =~ ${2} ]]; then header_red; echo -e "${WHITE_R}#${RESET} Option ${1} requires a command argument... \\n\\n"; help_script; fi
       echo "--private-key ${2}" &>> /tmp/EUS/le_script_options
       shift;;
  --signed-crt | --signed-certificate)
       if [[ "${script_option_list[@]}" =~ ${2} ]]; then header_red; echo -e "${WHITE_R}#${RESET} Option ${1} requires a command argument... \\n\\n"; help_script; fi
       echo "--signed-certificate ${2}" &>> /tmp/EUS/le_script_options
       shift;;
  --chain-crt | --chain-certificate)
       if [[ "${script_option_list[@]}" =~ ${2} ]]; then header_red; echo -e "${WHITE_R}#${RESET} Option ${1} requires a command argument... \\n\\n"; help_script; fi
       echo "--chain-certificate ${2}" &>> /tmp/EUS/le_script_options
       shift;;
  --intermediate-crt | --intermediate-certificate)
       if [[ "${script_option_list[@]}" =~ ${2} ]]; then header_red; echo -e "${WHITE_R}#${RESET} Option ${1} requires a command argument... \\n\\n"; help_script; fi
       echo "--intermediate-certificate ${2}" &>> /tmp/EUS/le_script_options
       shift;;
  --own-certificate)
       echo "--own-certificate" &>> /tmp/EUS/le_script_options;;
  esac
  shift
done

# Check script options.
if [[ -f /tmp/EUS/script_options && -s /tmp/EUS/script_options ]]; then IFS=" " read -r script_options <<< "$(tr '\r\n' ' ' < /tmp/EUS/script_options)"; fi

if [[ "$(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "downloads-distro.mongodb.org")" -gt 0 ]]; then
  grep -riIl "downloads-distro.mongodb.org" /etc/apt/ &>> /tmp/EUS/repository/dead_mongodb_repository
  while read -r glennr_mongo_repo; do
    sed -i '/downloads-distro.mongodb.org/d' "${glennr_mongo_repo}" 2> /dev/null
	if ! [[ -s "${glennr_mongo_repo}" ]]; then
      rm --force "${glennr_mongo_repo}" 2> /dev/null
    fi
  done < /tmp/EUS/repository/dead_mongodb_repository
  rm --force /tmp/EUS/repository/dead_mongodb_repository
fi

if apt-key list 2>/dev/null | grep mongodb -B1 | grep -iq "expired:"; then
  wget -qO - https://www.mongodb.org/static/pgp/server-3.4.asc | apt-key add - &> /dev/null
fi

# shellcheck disable=SC2016
grep -io '${eus_dir}/logs/.*log' "${script_location}" | grep -v 'awk' | awk '!a[$0]++' &> /tmp/EUS/log_files
while read -r log_file; do
  if [[ -f "${log_file}" ]]; then
    log_file_size=$(stat -c%s "${log_file}")
    if [[ "${log_file_size}" -gt "10485760" ]]; then
      tail -n1000 "${log_file}" &> "${log_file}.tmp"
      cp "${log_file}.tmp" "${log_file}"; rm --force "${log_file}.tmp" &> /dev/null
    fi
  fi
done < /tmp/EUS/log_files
rm --force /tmp/EUS/log_files

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
    while read -r key; do
      echo -e "${WHITE_R}#${RESET} Key ${key} is missing.. adding!"
      http_proxy=$(env | grep -i "http.*Proxy" | cut -d'=' -f2 | sed 's/[";]//g')
      if [[ -n "$http_proxy" ]]; then
        apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --keyserver-options http-proxy="${http_proxy}" --recv-keys "$key" &> /dev/null && echo -e "${GREEN}#${RESET} Successfully added key ${key}!\\n" || fail_key=true
      elif [[ -f /etc/apt/apt.conf ]]; then
        apt_http_proxy=$(grep "http.*Proxy" /etc/apt/apt.conf | awk '{print $2}' | sed 's/[";]//g')
        if [[ -n "${apt_http_proxy}" ]]; then
          apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --keyserver-options http-proxy="${apt_http_proxy}" --recv-keys "$key" &> /dev/null && echo -e "${GREEN}#${RESET} Successfully added key ${key}!\\n" || fail_key=true
        fi
      else
        apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv "$key" &> /dev/null && echo -e "${GREEN}#${RESET} Successfully added key ${key}!\\n" || fail_key=true
      fi
      if [[ "${fail_key}" == 'true' ]]; then
        echo -e "${RED}#${RESET} Failed to add key ${key}!"
        echo -e "${WHITE_R}#${RESET} Trying different method to get key: ${key}"
        gpg -vvv --debug-all --keyserver keyserver.ubuntu.com --recv-keys "${key}" &> /tmp/EUS/keys/failed_key
        debug_key=$(grep "KS_GET" /tmp/EUS/keys/failed_key | grep -io "0x.*")
        wget -q "https://keyserver.ubuntu.com/pks/lookup?op=get&search=${debug_key}" -O- | gpg --dearmor > "/tmp/EUS/keys/EUS-${key}.gpg"
        mv "/tmp/EUS/keys/EUS-${key}.gpg" /etc/apt/trusted.gpg.d/ && echo -e "${GREEN}#${RESET} Successfully added key ${key}!\\n"
      fi
      sleep 1
    done < /tmp/EUS/keys/missing_keys
    rm --force /tmp/EUS/keys/missing_keys
    rm --force /tmp/EUS/keys/apt_update
    #header
    #echo -e "${WHITE_R}#${RESET} Running apt-get update again.\\n\\n"
    #sleep 2
    apt-get update &> /tmp/EUS/keys/apt_update
    if grep -qo 'NO_PUBKEY.*' /tmp/EUS/keys/apt_update; then
      if [[ "${hide_apt_update}" == 'true' ]]; then hide_apt_update=true; fi
      run_apt_get_update
    fi
  fi
}

cancel_script() {
  if [[ "${set_lc_all}" == 'true' ]]; then unset LC_ALL &> /dev/null; fi
  header
  echo -e "${WHITE_R}#${RESET} Cancelling the script!\\n\\n"
  exit 0
}

http_proxy_found() {
  header
  echo -e "${GREEN}#${RESET} HTTP Proxy found. | ${WHITE_R}${http_proxy}${RESET}\\n\\n"
}

remove_yourself() {
  if [[ "${set_lc_all}" == 'true' ]]; then unset LC_ALL &> /dev/null; fi
  if [[ "${delete_script}" == 'true' || "${script_option_skip}" == 'true' ]]; then if [[ -e "${script_location}" ]]; then rm --force "${script_location}" 2> /dev/null; fi; fi
}

arch=$(dpkg --print-architecture)
# Check for 64/32 bit
if ! [[ "${arch}" == "amd64" ]]; then
  clear
  header_red
  echo -e "${RED}#${RESET} UniFi-Video only supports amd64 systems, it does not support the '${arch}' architecture! \\n\\n"
  exit 1
fi

christmass_new_year() {
  date_d=$(date '+%d' | sed "s/^0*//g; s/\.0*/./g")
  date_m=$(date '+%m' | sed "s/^0*//g; s/\.0*/./g")
  if [[ "${date_m}" == '12' && "${date_d}" -ge '18' && "${date_d}" -lt '26' ]]; then
    echo -e "\\n${WHITE_R}----${RESET}\\n"
    echo -e "${WHITE_R}#${RESET} GlennR wishes you a Merry Christmas! May you be blessed with health and happiness!"
    christmas_message=true
  fi
  if [[ "${date_m}" == '12' && "${date_d}" -ge '24' && "${date_d}" -le '30' ]]; then
    if [[ "${christmas_message}" != 'true' ]]; then echo -e "\\n${WHITE_R}----${RESET}\\n"; fi
    if [[ "${christmas_message}" == 'true' ]]; then echo -e ""; fi
    date_y=$(date -d "+1 year" +"%Y")
    echo -e "${WHITE_R}#${RESET} HAPPY NEW YEAR ${date_y}"
    echo -e "${WHITE_R}#${RESET} May the new year turn all your dreams into reality and all your efforts into great achievements!"
    new_year_message=true
  elif [[ "${date_m}" == '12' && "${date_d}" == '31' ]]; then
    if [[ "${christmas_message}" != 'true' ]]; then echo -e "\\n${WHITE_R}----${RESET}\\n"; fi
    if [[ "${christmas_message}" == 'true' ]]; then echo -e ""; fi
    date_y=$(date -d "+1 year" +"%Y")
    echo -e "${WHITE_R}#${RESET} HAPPY NEW YEAR ${date_y}"
    echo -e "${WHITE_R}#${RESET} Tomorrow, is the first blank page of a 365 page book. Write a good one!"
    new_year_message=true
  fi
  if [[ "${date_m}" == '1' && "${date_d}" -le '5' ]]; then
    if [[ "${christmas_message}" != 'true' ]]; then echo -e "\\n${WHITE_R}----${RESET}\\n"; fi
    if [[ "${christmas_message}" == 'true' ]]; then echo -e ""; fi
    date_y=$(date '+%Y')
    echo -e "${WHITE_R}#${RESET} HAPPY NEW YEAR ${date_y}"
    echo -e "${WHITE_R}#${RESET} May this new year all your dreams turn into reality and all your efforts into great achievements"
    new_year_message=true
  fi
}

author() {
  christmass_new_year
  if [[ "${new_year_message}" == 'true' || "${christmas_message}" == 'true' ]]; then echo -e "\\n${WHITE_R}----${RESET}\\n"; fi
  echo -e "${WHITE_R}#${RESET} ${GRAY_R}Author   |  ${WHITE_R}Glenn R.${RESET}"
  echo -e "${WHITE_R}#${RESET} ${GRAY_R}Email    |  ${WHITE_R}glennrietveld8@hotmail.nl${RESET}"
  echo -e "${WHITE_R}#${RESET} ${GRAY_R}Website  |  ${WHITE_R}https://GlennR.nl${RESET}"
  echo -e "\\n\\n"
}

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
  if [[ "${os_codename}" =~ (precise|maya|luna) ]]; then repo_codename=precise; os_codename=precise
  elif [[ "${os_codename}" =~ (trusty|qiana|rebecca|rafaela|rosa|freya) ]]; then repo_codename=trusty; os_codename=trusty
  elif [[ "${os_codename}" =~ (xenial|sarah|serena|sonya|sylvia|loki) ]]; then repo_codename=xenial; os_codename=xenial
  elif [[ "${os_codename}" =~ (bionic|tara|tessa|tina|tricia|hera|juno) ]]; then repo_codename=bionic; os_codename=bionic
  elif [[ "${os_codename}" =~ (focal|ulyana|ulyssa) ]]; then repo_codename=focal; os_codename=focal
  elif [[ "${os_codename}" =~ (stretch|continuum) ]]; then repo_codename=stretch; os_codename=stretch
  elif [[ "${os_codename}" =~ (buster|debbie|parrot|engywuck-backports|engywuck) ]]; then repo_codename=buster; os_codename=buster
  elif [[ "${os_codename}" =~ (bullseye|kali-rolling) ]]; then repo_codename=bullseye; os_codename=bullseye
  else
    repo_codename="${os_codename}"
    os_codename="${os_codename}"
  fi
}
get_distro

if ! [[ "${os_codename}" =~ (xenial|sarah|serena|sonya|sylvia|bionic|tara|tessa|tina|tricia|cosmic|disco|eoan|focal|groovy|jessie|stretch|continuum|buster|bullseye) ]]; then
  clear
  header_red
  echo -e "${WHITE_R}#${RESET} This script is not made for your OS.."
  echo -e "${WHITE_R}#${RESET} Feel free to contact Glenn R. (AmazedMender16) on the Community Forums if you need help with installing UniFi Video."
  echo -e ""
  echo -e "OS_CODENAME = ${os_codename}"
  echo -e ""
  echo -e ""
  exit 1
fi

if ! grep -iq '^127.0.0.1.*localhost' /etc/hosts; then
  clear
  header_red
  echo -e "${WHITE_R}#${RESET} '127.0.0.1   localhost' does not exist in your /etc/hosts file."
  echo -e "${WHITE_R}#${RESET} You will most likely see NVR startup issues if it doesn't exist..\\n\\n"
  read -rp $'\033[39m#\033[0m Do you want to add "127.0.0.1   localhost" to your /etc/hosts file? (Y/n) ' yes_no
  case "$yes_no" in
      [Yy]*|"")
          echo -e "${WHITE_R}----${RESET}\\n"
          echo -e "${WHITE_R}#${RESET} Adding '127.0.0.1       localhost' to /etc/hosts"
          sed  -i '1i # ------------------------------' /etc/hosts
          sed  -i '1i 127.0.0.1       localhost' /etc/hosts
          sed  -i '1i # Added by GlennR EUS script' /etc/hosts && echo -e "${WHITE_R}#${RESET} Done..\\n\\n"
          sleep 3;;
      [Nn]*) ;;
  esac
fi

if [[ $(echo "${PATH}" | grep -c "/sbin") -eq 0 ]]; then
  #PATH=/sbin:/bin:/usr/bin:/usr/sbin:/usr/local/sbin:/usr/local/bin
  #PATH=$PATH:/usr/sbin
  PATH="$PATH:/sbin:/bin:/usr/bin:/usr/sbin:/usr/local/sbin:/usr/local/bin"
fi

if ! [[ -d /etc/apt/sources.list.d ]]; then mkdir -p /etc/apt/sources.list.d; fi
if ! [[ -d /tmp/EUS/keys ]]; then mkdir -p /tmp/EUS/keys; fi

unifi_video_package=$(dpkg -l | grep "unifi-video" | awk '{print $1}' | tr '[:upper:]' '[:lower:]')
if [[ -n "${unifi_video_package}" ]]; then
  if [[ "${unifi_video_package}" != "ii" ]]; then
    header_red
    echo -e "${RED}#${RESET} You have a broken UniFi Video installation...\\n\\n${WHITE}#${RESET} Removing the broken UniFi Video installation..."
    if dpkg --remove --force-remove-reinstreq unifi-video &>> "${eus_dir}/logs/broken_unifi.log"; then echo -e "${GREEN}#${RESET} Successfully removed the broken UniFi Video installation!"; else echo -e "${RED}#${RESET} Failed to remove the broken UniFi Video installation!"; fi
    sleep 3  
  fi
fi

# Check if --show-progrss is supported in wget version
if wget --help | grep -q '\--show-progress'; then echo "--show-progress" &>> /tmp/EUS/wget_option; fi
if [[ -f /tmp/EUS/wget_option && -s /tmp/EUS/wget_option ]]; then IFS=" " read -r -a wget_progress <<< "$(tr '\r\n' ' ' < /tmp/EUS/wget_option)"; fi

# Check if UniFi Video is already installed.
if dpkg -l | grep "unifi-video" | grep -q "^ii\\|^hi"; then
  header
  echo -e "${WHITE_R}#${RESET} UniFi-Video is already installed on your system!${RESET}"
  echo -e "${WHITE_R}#${RESET} Please upgrade to the latest release manually via CLI or The UI.${RESET}"
  exit 0
fi

dpkg_locked_message() {
  header_red
  echo -e "${WHITE_R}#${RESET} dpkg is locked.. Waiting for other software managers to finish!"
  echo -e "${WHITE_R}#${RESET} If this is everlasting please contact Glenn R. (AmazedMender16) on the Community Forums!\\n\\n"
  sleep 5
  if [[ -z "$dpkg_wait" ]]; then
    echo "glennr_lock_active" >> /tmp/glennr_lock
  fi
}

dpkg_locked_60_message() {
  header
  echo -e "${WHITE_R}#${RESET} dpkg is already locked for 60 seconds..."
  echo -e "${WHITE_R}#${RESET} Would you like to force remove the lock?\\n\\n"
}

# Check if dpkg is locked
if dpkg -l psmisc 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
  while fuser /var/lib/dpkg/lock /var/lib/apt/lists/lock /var/cache/apt/archives/lock >/dev/null 2>&1; do
    dpkg_locked_message
    if [[ $(grep -c "glennr_lock_active" /tmp/glennr_lock) -ge 12 ]]; then
      rm --force /tmp/glennr_lock 2> /dev/null
      dpkg_locked_60_message
      if [[ "${script_option_skip}" != 'true' ]]; then read -rp $'\033[39m#\033[0m Do you want to proceed with removing the lock? (Y/n) ' yes_no; fi
      case "$yes_no" in
          [Yy]*|"")
            killall apt apt-get 2> /dev/null
            rm --force /var/lib/apt/lists/lock 2> /dev/null
            rm --force /var/cache/apt/archives/lock 2> /dev/null
            rm --force /var/lib/dpkg/lock* 2> /dev/null
            dpkg --configure -a 2> /dev/null
            DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install --fix-broken 2> /dev/null;;
          [Nn]*) dpkg_wait=true;;
      esac
    fi
  done;
else
  dpkg -i /dev/null 2> /tmp/glennr_dpkg_lock; if grep -q "locked.* another" /tmp/glennr_dpkg_lock; then dpkg_locked=true; rm --force /tmp/glennr_dpkg_lock 2> /dev/null; fi
  while [[ "${dpkg_locked}" == 'true'  ]]; do
    unset dpkg_locked
    dpkg_locked_message
    if [[ $(grep -c "glennr_lock_active" /tmp/glennr_lock) -ge 12 ]]; then
      rm --force /tmp/glennr_lock 2> /dev/null
      dpkg_locked_60_message
      if [[ "${script_option_skip}" != 'true' ]]; then read -rp $'\033[39m#\033[0m Do you want to proceed with force removing the lock? (Y/n) ' yes_no; fi
      case "$yes_no" in
          [Yy]*|"")
            pgrep "apt" >> /tmp/EUS/apt
            while read -r glennr_apt; do
              kill -9 "$glennr_apt" 2> /dev/null
            done < /tmp/EUS/apt
            rm --force /tmp/EUS/apt 2> /dev/null
            rm --force /var/lib/apt/lists/lock 2> /dev/null
            rm --force /var/cache/apt/archives/lock 2> /dev/null
            rm --force /var/lib/dpkg/lock* 2> /dev/null
            dpkg --configure -a 2> /dev/null
            DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install --fix-broken 2> /dev/null;;
          [Nn]*) dpkg_wait=true;;
      esac
    fi
    dpkg -i /dev/null 2> /tmp/glennr_dpkg_lock; if grep -q "locked.* another" /tmp/glennr_dpkg_lock; then dpkg_locked=true; rm --force /tmp/glennr_dpkg_lock 2> /dev/null; fi
  done;
  rm --force /tmp/glennr_dpkg_lock 2> /dev/null
fi

script_version_check() {
  if dpkg -l curl 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
    version=$(grep -i "# NVR" "${script_location}" | head -n 1 | awk '{print $4}' | cut -d'-' -f1)
    script_online_version_dots=$(curl "https://get.glennr.nl/unifi-video/install/unifi-video-${version}.sh" -s | grep "# Version" | head -n 1 | awk '{print $4}')
    script_local_version_dots=$(grep "# Version" "${script_location}" | head -n 1 | awk '{print $4}')
    script_online_version="${script_online_version_dots//./}"
    script_local_version="${script_local_version_dots//./}"
    # Script version check.
    if [[ "${script_online_version::3}" -gt "${script_local_version::3}" ]]; then
      header_red
      echo -e "${WHITE_R}#${RESET} You're currently running script version ${script_local_version_dots} while ${script_online_version_dots} is the latest!"
      echo -e "${WHITE_R}#${RESET} Downloading and executing version ${script_online_version_dots} of the Easy Installation Script..\\n\\n"
      sleep 3
      rm --force "${script_location}" 2> /dev/null
      rm --force "unifi-video-${version}.sh" 2> /dev/null
      # shellcheck disable=SC2086
      wget -q "${wget_progress[@]}" "https://get.glennr.nl/unifi-video/install/unifi-video-${version}.sh" && bash "unifi-video-${version}.sh" ${script_options[@]}; exit 0
    fi
  else
    curl_missing=true
  fi
}
script_version_check

if [[ -z "${install_mongodb_version}" ]]; then install_mongodb_version='4.2'; fi

libcurl_check() {
  if dpkg -l | grep "^ii" | grep -iq libcurl4; then install_mongodb_version='3.6'; fi
}
libcurl_check

mongodb_array=("3.6 3.4")
if ! dpkg -l | grep "unifi " | grep -iq "^ii\\|^hi" && [[ "${script_option_skip}" != 'true' ]] && [[ ! "${mongodb_array[@]}" =~ "${install_mongodb_version}" ]]; then
  clear
  header
  echo -e "  What UniFi Network Controller version are you planning to install?  \\n\\n"
  echo -e " [   ${WHITE_R}1${RESET}   ]  |  I don't want to install UniFi Network."
  echo -e " [   ${WHITE_R}2${RESET}   ]  |  5.13.10 or newer"
  echo -e " [   ${WHITE_R}3${RESET}   ]  |  Pre 5.13.10"
  echo -e " [   ${WHITE_R}4${RESET}   ]  |  Cancel\\n\\n"
  read -rp $'Your choice | \033[39m' MONGODB_VERSION_QUESTION
  case "$MONGODB_VERSION_QUESTION" in
      1);;
      2) install_mongodb_version='3.6';;
      3) install_mongodb_version='3.4';;
      4|*) cancel_script;;
  esac
fi

custom_url_question() {
  header
  echo -e "${WHITE_R}#${RESET} Please enter the UniFi Video download URL below."
  read -rp $'\033[39m#\033[0m ' custom_download_url
  custom_url_download_check
}

custom_url_upgrade_check() {
  custom_controller_version=$(echo "${custom_download_url}" | grep -io "3.*" | cut -d'-' -f1 | cut -d'/' -f1)
  echo -e "\\n${WHITE_R}----${RESET}\\n"
  echo -e "${YELLOW}#${RESET} The script will now install UniFi Video version: ${custom_controller_version}!" && sleep 3
  custom_url_check=success
}

custom_url_download_check() {
  if echo "${custom_download_url}" | grep -iq "http[s]://.*ubnt.com/firmwares/ufv/.*.deb\\|http[s]://.*ui.com/firmwares/ufv/.*.deb"; then
    if [[ "${repo_codename}" == 'xenial' ]]; then
      grep_url="Ubuntu16.04"
    elif [[ "${repo_codename}" =~ (bionic|cosmic|disco|eoan|focal|groovy) ]]; then
      grep_url="Ubuntu18.04"
    elif [[ "${repo_codename}" == "jessie" ]]; then
      grep_url="Debian8"
    elif [[ "${repo_codename}" =~ (stretch|buster|bullseye) ]]; then
      grep_url="Debian9"
    fi
    if ! echo "${custom_download_url}" | grep -iq "${grep_url}"; then
      header_red
      echo -e "${WHITE_R}#${RESET} You did not provide a download that fits your $(lsb_release -is) ( $(lsb_release -ds) ) release."
      read -rp $'\033[39m#\033[0m Do you want to provide the script with another URL? (Y/n) ' yes_no
      case "$yes_no" in
          [Yy]*|"") custom_url_question; return 0;;
          [Nn]*) return 0;;
      esac
    fi
    mkdir -p /tmp/EUS/downloads &> /dev/null
    unifi_temp="$(mktemp --tmpdir=/tmp/EUS/downloads unifi_video_XXXXX.deb)"
    header
    echo -e "${WHITE_R}#${RESET} Downloading the UniFi Video release..."
    if ! wget "${wget_progress[@]}" -qO "$unifi_temp" "${custom_download_url}"; then
      header_red
      echo -e "\\n${WHITE_R}#${RESET} The URL you provided cannot be downloaded.. Please provide a working URL."
      sleep 3
      custom_url_question
    else
      echo -e "\\n${GREEN}#${RESET} Successfully downloaded the UniFi Video release!"
      sleep 2
      custom_url_upgrade_check
    fi
  else
    header_red
    echo -e "${WHITE_R}#${RESET} You did not provide a UniFi Video download URL from Ubiquiti's download servers."
    read -rp $'\033[39m#\033[0m Do you want to provide the script with another URL? (Y/n) ' yes_no
    case "$yes_no" in
        [Yy]*|"") custom_url_question;;
        [Nn]*) ;;
    esac
  fi
}

if [[ "${script_option_custom_url}" == 'true' ]]; then custom_url_question; fi

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                        Required Packages                                                                                        #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

# Install needed packages if not installed
install_required_packages() {
  sleep 2
  installing_required_package=yes
  header
  echo -e "${WHITE_R}#${RESET} Installing required packages for the script..\\n"
  hide_apt_update=true
  run_apt_get_update
  sleep 2
}
apt_get_install_package() {
  if [[ "${old_openjdk_version}" == 'true' ]]; then
    apt_get_install_package_variable="update"
    apt_get_install_package_variable_2="updated"
  else
    apt_get_install_package_variable="install"
    apt_get_install_package_variable_2="installed"
  fi
  hide_apt_update=true
  run_apt_get_update
  echo -e "\\n------- ${required_package} installation ------- $(date +%F-%R) -------\\n" &>> "${eus_dir}/logs/apt.log"
  echo -e "${WHITE_R}#${RESET} Trying to ${apt_get_install_package_variable} ${required_package}..."
  if DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "${required_package}" &>> "${eus_dir}/logs/apt.log"; then echo -e "${GREEN}#${RESET} Successfully ${apt_get_install_package_variable_2} ${required_package}! \\n" && sleep 2; else echo -e "${RED}#${RESET} Failed to ${apt_get_install_package_variable} ${required_package}! \\n"; abort; fi
  unset required_package
}
if ! dpkg -l sudo 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
  if [[ "${installing_required_package}" != 'yes' ]]; then install_required_packages; fi
  echo -e "${WHITE_R}#${RESET} Installing sudo..."
  if ! DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install sudo &>> "${eus_dir}/logs/required.log"; then
    echo -e "${RED}#${RESET} Failed to install sudo in the first run...\\n"
    if [[ "${repo_codename}" =~ (precise|trusty|xenial) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ ${repo_codename}-security main") -eq 0 ]]; then
        echo -e "deb http://nl.archive.ubuntu.com/ubuntu/ ${repo_codename}-security main" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${repo_codename}" =~ (bionic|cosmic|disco|eoan|focal|groovy) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu ${repo_codename} main") -eq 0 ]]; then
        echo -e "deb http://nl.archive.ubuntu.com/ubuntu ${repo_codename} main" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${repo_codename}" =~ (stretch|jessie|buster|bullseye) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian ${repo_codename} main") -eq 0 ]]; then
        echo -e "deb http://ftp.nl.debian.org/debian ${repo_codename} main" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    fi
    required_package="sudo"
    apt_get_install_package
  else
    echo -e "${GREEN}#${RESET} Successfully installed sudo! \\n" && sleep 2
  fi
fi
if ! dpkg -l lsb-release 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
  if [[ "${installing_required_package}" != 'yes' ]]; then install_required_packages; fi
  echo -e "${WHITE_R}#${RESET} Installing lsb-release..."
  if ! DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install lsb-release &>> "${eus_dir}/logs/required.log"; then
    echo -e "${RED}#${RESET} Failed to install lsb-release in the first run...\\n"
    if [[ "${repo_codename}" =~ (precise|trusty|xenial|bionic|cosmic|disco|eoan|focal|groovy) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ ${repo_codename} main universe") -eq 0 ]]; then
        echo -e "deb http://nl.archive.ubuntu.com/ubuntu/ ${repo_codename} main universe" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${repo_codename}" =~ (jessie|stretch|buster|bullseye) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian ${repo_codename} main") -eq 0 ]]; then
        echo -e "deb http://ftp.nl.debian.org/debian ${repo_codename} main" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    fi
    required_package="lsb-release"
    apt_get_install_package
  else
    echo -e "${GREEN}#${RESET} Successfully installed lsb-release! \\n" && sleep 2
  fi
fi
if ! dpkg -l net-tools 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
  if [[ "${installing_required_package}" != 'yes' ]]; then install_required_packages; fi
  echo -e "${WHITE_R}#${RESET} Installing net-tools..."
  if ! DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install net-tools &>> "${eus_dir}/logs/required.log"; then
    echo -e "${RED}#${RESET} Failed to install net-tools in the first run...\\n"
    if [[ "${repo_codename}" =~ (precise|trusty|xenial|bionic|cosmic|disco|eoan|focal|groovy) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu ${repo_codename} main") -eq 0 ]]; then
        echo -e "deb http://nl.archive.ubuntu.com/ubuntu ${repo_codename} main" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${repo_codename}" =~ (jessie|stretch|buster|bullseye) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian ${repo_codename} main") -eq 0 ]]; then
        echo -e "deb http://ftp.nl.debian.org/debian ${repo_codename} main" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    fi
    required_package="net-tools"
    apt_get_install_package
  else
    echo -e "${GREEN}#${RESET} Successfully installed net-tools! \\n" && sleep 2
  fi
fi
if ! dpkg -l apt-transport-https 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
  if [[ "${installing_required_package}" != 'yes' ]]; then install_required_packages; fi
  echo -e "${WHITE_R}#${RESET} Installing apt-transport-https..."
  if ! DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install apt-transport-https &>> "${eus_dir}/logs/required.log"; then
    echo -e "${RED}#${RESET} Failed to install apt-transport-https in the first run...\\n"
    if [[ "${repo_codename}" =~ (precise|trusty|xenial) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://security.ubuntu.com/ubuntu ${repo_codename}-security main") -eq 0 ]]; then
        echo -e "deb http://security.ubuntu.com/ubuntu ${repo_codename}-security main" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${repo_codename}" =~ (bionic|cosmic) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://security.ubuntu.com/ubuntu ${repo_codename}-security main universe") -eq 0 ]]; then
        echo -e "deb http://security.ubuntu.com/ubuntu ${repo_codename}-security main universe" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${repo_codename}" =~ (disco|eoan|focal|groovy) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu ${repo_codename} main universe") -eq 0 ]]; then
        echo -e "deb http://nl.archive.ubuntu.com/ubuntu ${repo_codename} main universe" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${repo_codename}" == "jessie" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://security.debian.org/debian-security ${repo_codename}/updates main") -eq 0 ]]; then
        echo -e "deb http://security.debian.org/debian-security ${repo_codename}/updates main" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${repo_codename}" =~ (stretch|buster|bullseye) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian ${repo_codename} main") -eq 0 ]]; then
        echo -e "deb http://ftp.nl.debian.org/debian ${repo_codename} main" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    fi
    required_package="apt-transport-https"
    apt_get_install_package
  else
    echo -e "${GREEN}#${RESET} Successfully installed apt-transport-https! \\n" && sleep 2
  fi
fi
if ! dpkg -l software-properties-common 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
  if [[ "${installing_required_package}" != 'yes' ]]; then install_required_packages; fi
  echo -e "${WHITE_R}#${RESET} Installing software-properties-common..."
  if ! DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install software-properties-common &>> "${eus_dir}/logs/required.log"; then
    echo -e "${RED}#${RESET} Failed to install software-properties-common in the first run...\\n"
    if [[ "${repo_codename}" == "precise" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://security.ubuntu.com/ubuntu ${repo_codename}-security main") -eq 0 ]]; then
        echo -e "deb http://security.ubuntu.com/ubuntu ${repo_codename}-security main" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${repo_codename}" =~ (trusty|xenial|bionic|cosmic|disco|eoan|focal|groovy) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu ${repo_codename} main") -eq 0 ]]; then
        echo -e "deb http://nl.archive.ubuntu.com/ubuntu ${repo_codename} main" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${repo_codename}" =~ (jessie|stretch|buster|bullseye) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian ${repo_codename} main") -eq 0 ]]; then
        echo -e "deb http://ftp.nl.debian.org/debian ${repo_codename} main" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    fi
    required_package="software-properties-common"
    apt_get_install_package
  else
    echo -e "${GREEN}#${RESET} Successfully installed software-properties-common! \\n" && sleep 2
  fi
fi
if ! dpkg -l curl 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
  if [[ "${installing_required_package}" != 'yes' ]]; then install_required_packages; fi
  echo -e "${WHITE_R}#${RESET} Installing curl..."
  if ! DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install curl &>> "${eus_dir}/logs/required.log"; then
    echo -e "${RED}#${RESET} Failed to install curl in the first run...\\n"
    if [[ "${repo_codename}" =~ (precise|trusty|xenial|bionic|cosmic) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://security.ubuntu.com/ubuntu ${repo_codename}-security main") -eq 0 ]]; then
        echo -e "deb http://security.ubuntu.com/ubuntu ${repo_codename}-security main" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${repo_codename}" =~ (disco|eoan|focal|groovy) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu ${repo_codename} main") -eq 0 ]]; then
        echo -e "deb http://nl.archive.ubuntu.com/ubuntu ${repo_codename} main" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${repo_codename}" == "jessie" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://security.debian.org/debian-security ${repo_codename}/updates main") -eq 0 ]]; then
        echo -e "deb http://security.debian.org/debian-security ${repo_codename}/updates main" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${repo_codename}" =~ (stretch|buster|bullseye) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian ${repo_codename} main") -eq 0 ]]; then
        echo -e "deb http://ftp.nl.debian.org/debian ${repo_codename} main" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    fi
    required_package="curl"
    apt_get_install_package
  else
    echo -e "${GREEN}#${RESET} Successfully installed curl! \\n" && sleep 2
  fi
fi
if ! dpkg -l dirmngr 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
  if [[ "${installing_required_package}" != 'yes' ]]; then install_required_packages; fi
  echo -e "${WHITE_R}#${RESET} Installing dirmngr..."
  if ! DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install dirmngr &>> "${eus_dir}/logs/required.log"; then
    echo -e "${RED}#${RESET} Failed to install dirmngr in the first run...\\n"
    if [[ "${repo_codename}" =~ (precise|trusty|xenial|bionic|cosmic|disco|eoan|focal|groovy) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ ${repo_codename} universe") -eq 0 ]]; then
        echo -e "deb http://nl.archive.ubuntu.com/ubuntu/ ${repo_codename} universe" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ ${repo_codename} main restricted") -eq 0 ]]; then
        echo -e "deb http://nl.archive.ubuntu.com/ubuntu/ ${repo_codename} main restricted" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${repo_codename}" =~ (jessie|stretch|buster|bullseye) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian ${repo_codename} main") -eq 0 ]]; then
        echo -e "deb http://ftp.nl.debian.org/debian ${repo_codename} main" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    fi
    required_package="dirmngr"
    apt_get_install_package
  else
    echo -e "${GREEN}#${RESET} Successfully installed dirmngr! \\n" && sleep 2
  fi
fi
if ! dpkg -l wget 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
  if [[ "${installing_required_package}" != 'yes' ]]; then install_required_packages; fi
  echo -e "${WHITE_R}#${RESET} Installing wget..."
  if ! DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install wget &>> "${eus_dir}/logs/required.log"; then
    echo -e "${RED}#${RESET} Failed to install wget in the first run...\\n"
    if [[ "${repo_codename}" =~ (precise|trusty|xenial|bionic|cosmic) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://security.ubuntu.com/ubuntu ${repo_codename}-security main") -eq 0 ]]; then
        echo -e "deb http://security.ubuntu.com/ubuntu ${repo_codename}-security main" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${repo_codename}" =~ (disco|eoan|focal|groovy) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu ${repo_codename} main") -eq 0 ]]; then
        echo -e "deb http://nl.archive.ubuntu.com/ubuntu ${repo_codename} main" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${repo_codename}" == "jessie" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://security.debian.org/debian-security ${repo_codename}/updates main") -eq 0 ]]; then
        echo -e "deb http://security.debian.org/debian-security ${repo_codename}/updates main" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${repo_codename}" =~ (stretch|buster|bullseye) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian ${repo_codename} main") -eq 0 ]]; then
        echo -e "deb http://ftp.nl.debian.org/debian ${repo_codename} main" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    fi
    required_package="wget"
    apt_get_install_package
  else
    echo -e "${GREEN}#${RESET} Successfully installed wget! \\n" && sleep 2
  fi
fi
if ! dpkg -l netcat 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
  if [[ "${installing_required_package}" != 'yes' ]]; then install_required_packages; fi
  echo -e "${WHITE_R}#${RESET} Installing netcat..."
  if ! DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install netcat &>> "${eus_dir}/logs/required.log"; then
    echo -e "${RED}#${RESET} Failed to install netcat in the first run...\\n"
    if [[ "${repo_codename}" =~ (precise|trusty|xenial|bionic|cosmic|disco|eoan|focal|groovy) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ ${repo_codename} universe") -eq 0 ]]; then
        echo -e "deb http://nl.archive.ubuntu.com/ubuntu/ ${repo_codename} universe" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${repo_codename}" =~ (jessie|stretch|buster|bullseye) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian ${repo_codename} main") -eq 0 ]]; then
        echo -e "deb http://ftp.nl.debian.org/debian ${repo_codename} main" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    fi
    required_package="netcat"
    apt_get_install_package
  else
    echo -e "${GREEN}#${RESET} Successfully installed netcat! \\n" && sleep 2
  fi
  netcat_installed=true
fi
if ! dpkg -l haveged 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
  if [[ "${installing_required_package}" != 'yes' ]]; then install_required_packages; fi
  echo -e "${WHITE_R}#${RESET} Installing haveged..."
  if ! DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install haveged &>> "${eus_dir}/logs/required.log"; then
    echo -e "${RED}#${RESET} Failed to install haveged in the first run...\\n"
    if [[ "${repo_codename}" =~ (precise|trusty|xenial|bionic|cosmic|disco|eoan|focal|groovy) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ ${repo_codename} universe") -eq 0 ]]; then
        echo -e "deb http://nl.archive.ubuntu.com/ubuntu/ ${repo_codename} universe" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${repo_codename}" =~ (jessie|stretch|buster|bullseye) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian ${repo_codename} main") -eq 0 ]]; then
        echo -e "deb http://ftp.nl.debian.org/debian ${repo_codename} main" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    fi
    required_package="haveged"
    apt_get_install_package
  else
    echo -e "${GREEN}#${RESET} Successfully installed haveged! \\n" && sleep 2
  fi
fi
if ! dpkg -l psmisc 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
  if [[ "${installing_required_package}" != 'yes' ]]; then install_required_packages; fi
  echo -e "${WHITE_R}#${RESET} Installing psmisc..."
  if ! DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install psmisc &>> "${eus_dir}/logs/required.log"; then
    echo -e "${RED}#${RESET} Failed to install psmisc in the first run...\\n"
    if [[ "${repo_codename}" == "precise" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ ${repo_codename}-updates main restricted") -eq 0 ]]; then
        echo -e "deb http://nl.archive.ubuntu.com/ubuntu/ ${repo_codename}-updates main restricted" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${repo_codename}" =~ (trusty|xenial|bionic|cosmic|disco|eoan|focal|groovy) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ ${repo_codename} universe") -eq 0 ]]; then
        echo -e "deb http://nl.archive.ubuntu.com/ubuntu/ ${repo_codename} universe" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${repo_codename}" =~ (jessie|stretch|buster|bullseye) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian ${repo_codename} main") -eq 0 ]]; then
        echo -e "deb http://ftp.nl.debian.org/debian ${repo_codename} main" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    fi
    required_package="psmisc"
    apt_get_install_package
  else
    echo -e "${GREEN}#${RESET} Successfully installed psmisc! \\n" && sleep 2
  fi
fi
if ! dpkg -l gnupg 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
  if [[ "${installing_required_package}" != 'yes' ]]; then install_required_packages; fi
  echo -e "${WHITE_R}#${RESET} Installing gnupg..."
  if ! DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install gnupg &>> "${eus_dir}/logs/required.log"; then
    echo -e "${RED}#${RESET} Failed to install gnupg in the first run...\\n"
    if [[ "${repo_codename}" =~ (precise|trusty|xenial) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ ${repo_codename}-security main") -eq 0 ]]; then
        echo -e "deb http://nl.archive.ubuntu.com/ubuntu/ ${repo_codename}-security main" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${repo_codename}" =~ (bionic|cosmic) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://security.ubuntu.com/ubuntu ${repo_codename}-security main universe") -eq 0 ]]; then
        echo -e "deb http://security.ubuntu.com/ubuntu ${repo_codename}-security main universe" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${repo_codename}" =~ (disco|eoan|focal|groovy) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ ${repo_codename} main universe") -eq 0 ]]; then
        echo -e "deb http://nl.archive.ubuntu.com/ubuntu/ ${repo_codename} main universe" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${repo_codename}" =~ (jessie|stretch|buster|bullseye) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian ${repo_codename} main") -eq 0 ]]; then
        echo -e "deb http://ftp.nl.debian.org/debian ${repo_codename} main" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    fi
    required_package="gnupg"
    apt_get_install_package
  else
    echo -e "${GREEN}#${RESET} Successfully installed gnupg! \\n" && sleep 2
  fi
fi
if ! dpkg -l perl 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
  if [[ "${installing_required_package}" != 'yes' ]]; then
    install_required_packages
  fi
  echo -e "${WHITE_R}#${RESET} Installing perl..."
  if ! DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install perl &>> "${eus_dir}/logs/required.log"; then
    echo -e "${RED}#${RESET} Failed to install perl in the first run...\\n"
    if [[ "${repo_codename}" =~ (precise|trusty|xenial|bionic|cosmic) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://security.ubuntu.com/ubuntu ${repo_codename}-security main") -eq 0 ]]; then
        echo -e "deb http://security.ubuntu.com/ubuntu ${repo_codename}-security main" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${repo_codename}" =~ (disco|eoan|focal|groovy) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu ${repo_codename} main") -eq 0 ]]; then
        echo -e "deb http://nl.archive.ubuntu.com/ubuntu ${repo_codename} main" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${repo_codename}" == "jessie" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://security.debian.org/debian-security ${repo_codename}/updates main") -eq 0 ]]; then
        echo -e "deb http://security.debian.org/debian-security ${repo_codename}/updates main" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${repo_codename}" =~ (stretch|buster|bullseye) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian ${repo_codename} main") -eq 0 ]]; then
        echo -e "deb http://ftp.nl.debian.org/debian ${repo_codename} main" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    fi
    required_package="perl"
    apt_get_install_package
  else
    echo -e "${GREEN}#${RESET} Successfully installed perl! \\n" && sleep 2
  fi
fi
if [[ "${fqdn_specified}" == 'true' ]]; then
  if ! dpkg -l dnsutils 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
    if [[ "${installing_required_package}" != 'yes' ]]; then install_required_packages; fi
    echo -e "${WHITE_R}#${RESET} Installing dnsutils..."
    if ! DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install dnsutils &>> "${eus_dir}/logs/required.log"; then
      echo -e "${RED}#${RESET} Failed to install dnsutils in the first run...\\n"
      if [[ "${repo_codename}" =~ (precise|trusty|xenial) ]]; then
        if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://security.ubuntu.com/ubuntu ${repo_codename}-security main") -eq 0 ]]; then
          echo -e "deb http://security.ubuntu.com/ubuntu ${repo_codename}-security main" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
        fi
      elif [[ "${repo_codename}" =~ (bionic|cosmic|disco|eoan|focal|groovy) ]]; then
        if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu ${repo_codename} main") -eq 0 ]]; then
          echo -e "deb http://nl.archive.ubuntu.com/ubuntu ${repo_codename} main" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
        fi
      elif [[ "${repo_codename}" == "jessie" ]]; then
        if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://security.debian.org/debian-security ${repo_codename}/updates main") -eq 0 ]]; then
          echo -e "deb http://security.debian.org/debian-security ${repo_codename}/updates main" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
        fi
      elif [[ "${repo_codename}" =~ (stretch|buster|bullseye) ]]; then
        if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian ${repo_codename} main") -eq 0 ]]; then
          echo -e "deb http://ftp.nl.debian.org/debian ${repo_codename} main" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
        fi
      fi
      required_package="dnsutils"
      apt_get_install_package
    else
      echo -e "${GREEN}#${RESET} Successfully installed dnsutils! \\n" && sleep 2
    fi
  fi
fi
if [[ "${curl_missing}" == 'true' ]]; then script_version_check; fi

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                            Variables                                                                                            #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

dpkg -l | grep "mongo-tools\\|mongodb\\|mongodb-org" | awk '{print $3}' | sed 's/.*://' | sed 's/-.*//g' &> /tmp/EUS/mongodb_versions
mongodb_version_installed=$(sort -V /tmp/EUS/mongodb_versions | tail -n 1)
rm --force /tmp/EUS/mongodb_versions &> /dev/null
first_digits_mongodb_version_installed=$(echo "${mongodb_version_installed}" | cut -d'.' -f1)
second_digits_mongodb_version_installed=$(echo "${mongodb_version_installed}" | cut -d'.' -f2)
#
if [[ "${custom_url_check}" == 'success' ]]; then
  unifi_clean=$(echo "${custom_download_url}" | grep -io "3.*" | cut -d'-' -f1 | cut -d'/' -f1)
  unifi_secret=$(echo "${custom_download_url}" | grep -io "3.*" | cut -d'/' -f1)
else
  unifi_clean=$(grep -i "# NVR" "${script_location}" | head -n 1 | awk '{print $4}' | cut -d'-' -f1)
  unifi_secret=$(grep -i "# NVR" "${script_location}" | head -n 1 | awk '{print $4}')
fi
first_digits_unifi=$(echo "${unifi_clean}" | cut -d'.' -f1)
second_digits_unifi=$(echo "${unifi_clean}" | cut -d'.' -f2)
third_digits_unifi=$(echo "${unifi_clean}" | cut -d'.' -f3)
#
mongodb_supported_check() {
  mongodb_array=("3.6 3.4")
  if [[ "${first_digits_unifi}" -ge '3' && "${second_digits_unifi}" -ge '10' && "${third_digits_unifi}" -ge '0' ]] && [[ ! "${mongodb_array[@]}" =~ "${install_mongodb_version}" ]]; then
    mongo_version_supported="4.2.999"
    first_digits_mongodb_version_supported="4"
    second_digits_mongodb_version_supported="2"
    mongo_version_supported_2="4.3"
    mongo_version_supported_3="42"
    if [[ "${first_digits_mongodb_version_installed}" == '3' && "${second_digits_mongodb_version_installed}" -le '6' ]]; then mongodb_supported=true ;fi
  elif [[ "${first_digits_unifi}" -ge '3' && "${second_digits_unifi}" -ge '10' && "${third_digits_unifi}" -ge '0' && "${install_mongodb_version}" == '3.6' ]]; then
    mongo_version_supported="3.6.999"
    first_digits_mongodb_version_supported="3"
    second_digits_mongodb_version_supported="6"
    mongo_version_supported_2="4.0"
    mongo_version_supported_3="36"
    if [[ "${first_digits_mongodb_version_installed}" == '3' && "${second_digits_mongodb_version_installed}" -le '6' ]]; then mongodb_supported=true ;fi
  else
    mongo_version_supported="3.4.999"
    first_digits_mongodb_version_supported="3"
    second_digits_mongodb_version_supported="4"
    mongo_version_supported_2="3.6"
    mongo_version_supported_3="34"
  fi
}
mongodb_supported_check
#
system_memory=$(awk '/MemTotal/ {printf( "%.0f\n", $2 / 1024 / 1024)}' /proc/meminfo)
system_swap=$(awk '/SwapTotal/ {printf( "%.0f\n", $2 / 1024 / 1024)}' /proc/meminfo)
#system_free_disk_space=$(df -h / | grep "/" | awk '{print $4}' | sed 's/G//')
system_free_disk_space=$(df -k / | awk '{print $4}' | tail -n1)
#
#SERVER_IP=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1' | head -1)
#SERVER_IP=$(/sbin/ifconfig | grep 'inet ' | grep -v '127.0.0.1' | head -n1 | awk '{print $2}' | head -1 | sed 's/.*://')
SERVER_IP=$(ip addr | grep -A8 -m1 MULTICAST | grep -m1 inet | cut -d' ' -f6 | cut -d'/' -f1)
if [[ -z "${SERVER_IP}" ]]; then SERVER_IP=$(hostname -I | head -n 1 | awk '{ print $NF; }'); fi
if command -v jq &> /dev/null; then
  PUBLIC_SERVER_IP="$(curl --silent https://api.glennr.nl/api/geo | jq -r '."address"')"
else
  PUBLIC_SERVER_IP="$(curl --silent https://api.glennr.nl/api/geo | grep -oP '(?<="address":")[^"]+')"
fi
architecture=$(dpkg --print-architecture)
get_distro
#
#JAVA8=$(dpkg -l | grep -c "openjdk-8-jre-headless\\|oracle-java8-installer")
mongodb_version=$(dpkg -l | grep "mongodb-server\|mongodb-org-server" | awk '{print $3}' | sed 's/.*://' | sed 's/-.*//' | sed 's/\.//g')

unsupported_java_installed=''
openjdk_8_installed=''
remote_controller=''
debian_64_mongo=''
debian_32_run_fix=''
unifi_dependencies=''

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                             Checks                                                                                              #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

if [ "${system_free_disk_space}" -lt "5000000" ]; then
  header_red
  echo -e "${WHITE_R}#${RESET} Free disk space is below 5GB.. Please expand the disk size!"
  echo -e "${WHITE_R}#${RESET} I recommend expanding to atleast 10GB\\n\\n"
  if [[ "${script_option_skip}" != 'true' ]]; then
    read -rp "Do you want to proceed at your own risk? (Y/n)" yes_no
    case "$yes_no" in
        [Yy]*|"") ;;
        [Nn]*) cancel_script;;
    esac
  else
    cancel_script
  fi
fi

# MongoDB version check.
if [[ "${first_digits_mongodb_version_installed}" -gt "${first_digits_mongodb_version_supported}" || "${second_digits_mongodb_version_installed}" -gt "${second_digits_mongodb_version_supported}" && "${mongodb_supported}" != 'true' ]]; then
  header_red
  echo -e "${WHITE_R}#${RESET} UniFi Video does not support MongoDB ${mongo_version_supported_2} or newer.."
  echo -e "${WHITE_R}#${RESET} Do you want to uninstall the unsupported MongoDB version?\\n"
  echo -e "${WHITE_R}#${RESET} This will also uninstall any other package depending on MongoDB!"
  echo -e "${WHITE_R}#${RESET} I highly recommend creating a backup/snapshot of your machine/VM\\n\\n"
  read -rp "Do you want to proceed with uninstalling MongoDB? (Y/n)" yes_no
  case "$yes_no" in
      [Yy]*|"")
        header
        echo -e "${WHITE_R}#${RESET} Preparing unsupported mongodb uninstall... \\n"
        if dpkg -l | grep "unifi " | grep -q "^ii\\|^hi"; then echo -e "${WHITE_R}#${RESET} Removing UniFi to keep system files! \\n"; fi
        if dpkg -l | grep "unifi-video" | grep -q "^ii\\|^hi"; then echo -e "${WHITE_R}#${RESET} Removing UniFi-Video to keep system files! \\n"; fi
        sleep 3
        rm --force /etc/apt/sources.list.d/mongo*.list &> /dev/null
        if dpkg -l | grep "unifi " | grep -q "^ii\\|^hi"; then dpkg --remove --force-remove-reinstreq unifi || abort; fi
        if dpkg -l | grep "unifi-video" | grep -q "^ii\\|^hi"; then dpkg --remove --force-remove-reinstreq unifi-video || abort; fi
        mkdir -p /tmp/EUS/mongodb/
        rm --force /tmp/EUS/mongodb/uninstall_failed &> /dev/null
        dpkg -l | grep -i "mongo" | awk '{print $2}' &> /tmp/EUS/mongodb/uninstall
        while read -r mongodb_package_purge; do
          echo -e "${WHITE_R}#${RESET} Purging ${mongodb_package_purge}..."
          if apt-get purge "${mongodb_package_purge}" -y &> /tmp/EUS/mongodb/uninstall.log; then echo -e "${GREEN}#${RESET} Successfully purged ${mongodb_package_purge}! \\n"; else echo "${mongodb_package_purge}" &>> /tmp/EUS/mongodb/uninstall_failed; fi
        done < /tmp/EUS/mongodb/uninstall
        if [[ -f /tmp/EUS/mongodb/uninstall_failed && -s /tmp/EUS/mongodb/uninstall_failed ]]; then
          header_red
          echo -e "${WHITE_R}#${RESET} Uninstalling MongoDB with different actions!\\n\\n"
          sleep 2
          apt-get --fix-broken install -y || apt-get install -f -y
          apt-get autoremove -y
          while read -r mongodb_package; do
            echo -e "${WHITE_R}#${RESET} Force removing ${mongodb_package}..."
            if dpkg --remove --force-remove-reinstreq "${mongodb_package}" &> /tmp/EUS/mongodb/uninstall.log; then echo -e "${GREEN}#${RESET} Successfully removed ${mongodb_package}! \\n"; else  echo -e "${RED}#${RESET} Failed to remove ${mongodb_package}... \\n"; abort; fi
          done < /tmp/EUS/mongodb/uninstall_failed
        fi
        echo -e "${WHITE_R}#${RESET} Running apt-get autoremove..."
        if apt-get -y autoremove &>> "${eus_dir}/logs/apt-cleanup.log"; then echo -e "${GREEN}#${RESET} Successfully ran apt-get autoremove! \\n"; else echo -e "${RED}#${RESET} Failed to run apt-get autoremove"; fi
        echo -e "${WHITE_R}#${RESET} Running apt-get autoclean..."
        if apt-get -y autoclean &>> "${eus_dir}/logs/apt-cleanup.log"; then echo -e "${GREEN}#${RESET} Successfully ran apt-get autoclean! \\n"; else echo -e "${RED}#${RESET} Failed to run apt-get autoclean"; fi
        sleep 3;;
      [Nn]*) cancel_script;;
  esac
fi

# Memory and Swap file.
if [[ "${system_swap}" == "0" && "${system_memory}" -lt "2" ]]; then
  header_red
  echo -e "${WHITE_R}#${RESET} System memory is lower than recommended!"
  echo -e "${WHITE_R}#${RESET} Creating swap file.\\n"
  sleep 2
  if [[ "${system_free_disk_space}" -ge "10000000" ]]; then
    echo -e "${WHITE_R}---${RESET}\\n"
    echo -e "${WHITE_R}#${RESET} You have more than 10GB of free disk space!"
    echo -e "${WHITE_R}#${RESET} We are creating a 2GB swap file!\\n"
    dd if=/dev/zero of=/swapfile bs=2048 count=1048576 &>/dev/null
    chmod 600 /swapfile &>/dev/null
    mkswap /swapfile &>/dev/null
    swapon /swapfile &>/dev/null
    echo "/swapfile swap swap defaults 0 0" | tee -a /etc/fstab &>/dev/null
  elif [[ "${system_free_disk_space}" -ge "5000000" ]]; then
    echo -e "${WHITE_R}---${RESET}\\n"
    echo -e "${WHITE_R}#${RESET} You have more than 5GB of free disk space."
    echo -e "${WHITE_R}#${RESET} We are creating a 1GB swap file..\\n"
    dd if=/dev/zero of=/swapfile bs=1024 count=1048576 &>/dev/null
    chmod 600 /swapfile &>/dev/null
    mkswap /swapfile &>/dev/null
    swapon /swapfile &>/dev/null
    echo "/swapfile swap swap defaults 0 0" | tee -a /etc/fstab &>/dev/null
  elif [[ "${system_free_disk_space}" -ge "4000000" ]]; then
    echo -e "${WHITE_R}---${RESET}\\n"
    echo -e "${WHITE_R}#${RESET} You have more than 4GB of free disk space."
    echo -e "${WHITE_R}#${RESET} We are creating a 256MB swap file..\\n"
    dd if=/dev/zero of=/swapfile bs=256 count=1048576 &>/dev/null
    chmod 600 /swapfile &>/dev/null
    mkswap /swapfile &>/dev/null
    swapon /swapfile &>/dev/null
    echo "/swapfile swap swap defaults 0 0" | tee -a /etc/fstab &>/dev/null
  elif [[ "${system_free_disk_space}" -lt "4000000" ]]; then
    echo -e "${WHITE_R}---${RESET}\\n"
    echo -e "${WHITE_R}#${RESET} Your free disk space is extremely low!"
    echo -e "${WHITE_R}#${RESET} There is not enough free disk space to create a swap file..\\n"
    echo -e "${WHITE_R}#${RESET} I highly recommend upgrading the system memory to atleast 2GB and expanding the disk space!"
    echo -e "${WHITE_R}#${RESET} The script will continue the script at your own risk..\\n"
   sleep 10
  fi
else
  header
  echo -e "${WHITE_R}#${RESET} A swap file already exists!\\n\\n"
  sleep 2
fi

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                  Ask to keep script or delete                                                                                   #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

script_removal() {
  header
  read -rp $'\033[39m#\033[0m Do you want to keep the script on your system after completion? (Y/n) ' yes_no
  case "$yes_no" in
      [Yy]*|"") ;;
      [Nn]*) delete_script=true;;
  esac
}

if [[ "${script_option_skip}" != 'true' ]]; then
  script_removal
fi

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                 Installation Script starts here                                                                                 #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

apt_mongodb_check() {
  MONGODB_ORG_CACHE=$(apt-cache madison mongodb-org | awk '{print $3}' | sort -V | tail -n 1 | sed 's/\.//g')
  MONGODB_CACHE=$(apt-cache madison mongodb | awk '{print $3}' | sort -V | tail -n 1 | sed 's/-.*//' | sed 's/.*://' | sed 's/\.//g')
  MONGO_TOOLS_CACHE=$(apt-cache madison mongo-tools | awk '{print $3}' | sort -V | tail -n 1 | sed 's/-.*//' | sed 's/.*://' | sed 's/\.//g')
}

system_upgrade() {
  if [[ -f /tmp/EUS/upgrade/upgrade_list && -s /tmp/EUS/upgrade/upgrade_list ]]; then
    while read -r package; do
      echo -e "\\n------- updating ${package} ------- $(date +%F-%R) -------\\n" &>> "${eus_dir}/logs/upgrade.log"
      echo -ne "\r${WHITE_R}#${RESET} Updating package ${package}..."
      if DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' --only-upgrade install "${package}" &>> "${eus_dir}/logs/upgrade.log"; then echo -e "\r${GREEN}#${RESET} Successfully updated package ${package}!"; else if tail -n1 /usr/lib/EUS/logs/upgrade.log | grep -ioq "Packages were downgraded and -y was used without --allow-downgrades" "${eus_dir}/logs/upgrade.log"; then if DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' --only-upgrade --allow-downgrades install "${package}" &>> "${eus_dir}/logs/upgrade.log"; then echo -e "\r${GREEN}#${RESET} Successfully updated package ${package}!"; continue; else echo -e "\r${RED}#${RESET} Something went wrong during the update of package ${package}... \\n${RED}#${RESET} The script will continue with an apt-get upgrade...\\n"; break; fi; fi; echo -e "\r${RED}#${RESET} Something went wrong during the update of package ${package}... \\n${RED}#${RESET} The script will continue with an apt-get upgrade...\\n"; break; fi
    done < /tmp/EUS/upgrade/upgrade_list
  fi
  echo -e "\\n------- apt-get upgrade ------- $(date +%F-%R) -------\\n" &>> "${eus_dir}/logs/upgrade.log"
  echo -e "${WHITE_R}#${RESET} Running apt-get upgrade..."
  if DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' upgrade &>> "${eus_dir}/logs/upgrade.log"; then echo -e "${GREEN}#${RESET} Successfully ran apt-get upgrade! \\n"; else echo -e "${RED}#${RESET} Failed to run apt-get upgrade"; abort; fi
  echo -e "\\n------- apt-get dist-upgrade ------- $(date +%F-%R) -------\\n" &>> "${eus_dir}/logs/upgrade.log"
  echo -e "${WHITE_R}#${RESET} Running apt-get dist-upgrade..."
  if DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' dist-upgrade &>> "${eus_dir}/logs/upgrade.log"; then echo -e "${GREEN}#${RESET} Successfully ran apt-get dist-upgrade! \\n"; else echo -e "${RED}#${RESET} Failed to run apt-get dist-upgrade"; abort; fi
  echo -e "${WHITE_R}#${RESET} Running apt-get autoremove..."
  if apt-get -y autoremove &>> "${eus_dir}/logs/apt-cleanup.log"; then echo -e "${GREEN}#${RESET} Successfully ran apt-get autoremove! \\n"; else echo -e "${RED}#${RESET} Failed to run apt-get autoremove"; fi
  echo -e "${WHITE_R}#${RESET} Running apt-get autoclean..."
  if apt-get -y autoclean &>> "${eus_dir}/logs/apt-cleanup.log"; then echo -e "${GREEN}#${RESET} Successfully ran apt-get autoclean! \\n"; else echo -e "${RED}#${RESET} Failed to run apt-get autoclean"; fi
  sleep 3
}

rm --force /tmp/EUS/dpkg/mongodb_list &> /dev/null
rm --force /tmp/EUS/upgrade/upgrade_list &> /dev/null
header
echo -e "${WHITE_R}#${RESET} Checking if your system is up-to-date...\\n" && sleep 1
hide_apt_update=true
run_apt_get_update
apt_mongodb_check
if [[ "${MONGODB_ORG_CACHE::2}" -gt "${mongo_version_supported_3}" ]]; then
  dpkg -l | awk '/ii.*mongodb-org/ {print $2}' &> /tmp/EUS/dpkg/mongodb_list
  if [[ -f /tmp/EUS/dpkg/mongodb_list && -s /tmp/EUS/dpkg/mongodb_list ]]; then
    while read -r package; do
      echo "${package} hold" | dpkg --set-selections &> /dev/null
    done < /tmp/EUS/dpkg/mongodb_list
  fi
fi
if [[ "${MONGODB_CACHE::2}" -gt "${mongo_version_supported_3}" || "${MONGO_TOOLS_CACHE::2}" -gt "${mongo_version_supported_3}" ]]; then
  dpkg -l | grep -v 'mongodb-org' | awk '/ii.*mongodb-|ii.*mongo-tools/ {print $2}' &> /tmp/EUS/dpkg/mongodb_list
  if [[ -f /tmp/EUS/dpkg/mongodb_list && -s /tmp/EUS/dpkg/mongodb_list ]]; then
    while read -r package; do
      echo "${package} hold" | dpkg --set-selections &> /dev/null
    done < /tmp/EUS/dpkg/mongodb_list
  fi
fi
echo -e "${WHITE_R}#${RESET} The package(s) below can be upgraded!"
echo -e "\\n${WHITE_R}----${RESET}\\n"
rm --force /tmp/EUS/upgrade/upgrade_list &> /dev/null
{ apt-get --just-print upgrade 2>&1 | perl -ne 'if (/Inst\s([\w,\-,\d,\.,~,:,\+]+)\s\[([\w,\-,\d,\.,~,:,\+]+)\]\s\(([\w,\-,\d,\.,~,:,\+]+)\)? /i) {print "$1 ( \e[1;34m$2\e[0m -> \e[1;32m$3\e[0m )\n"}';} | while read -r line; do echo -en "${WHITE_R}-${RESET} $line\n"; echo -en "$line\n" | awk '{print $1}' &>> /tmp/EUS/upgrade/upgrade_list; done;
if [[ -f /tmp/EUS/upgrade/upgrade_list ]]; then number_of_updates=$(wc -l < /tmp/EUS/upgrade/upgrade_list); else number_of_updates='0'; fi
if [[ "${number_of_updates}" == '0' ]]; then echo -e "${WHITE_R}#${RESET} There are were no packages that need an upgrade..."; fi
echo -e "\\n${WHITE_R}----${RESET}\\n"
if [[ "${script_option_skip}" != 'true' ]]; then
  read -rp $'\033[39m#\033[0m Do you want to proceed with updating your system? (Y/n) ' yes_no
else
  echo -e "${WHITE_R}#${RESET} Performing the updates!"
fi
case "$yes_no" in
    [Yy]*|"") echo -e "\\n${WHITE_R}----${RESET}\\n"; system_upgrade;;
    [Nn]*) ;;
esac
if [[ -f /tmp/EUS/dpkg/mongodb_list && -s /tmp/EUS/dpkg/mongodb_list ]]; then
  while read -r service; do
    echo "${service} install" | dpkg --set-selections 2> /dev/null
  done < /tmp/EUS/dpkg/mongodb_list
fi
rm --force /tmp/EUS/dpkg/mongodb_list &> /dev/null
rm --force /tmp/EUS/upgrade/upgrade_list &> /dev/null

mongodb_34_key() {
  echo -e "${WHITE_R}#${RESET} Adding key for MongoDB 3.4..."
  if wget -qO - https://www.mongodb.org/static/pgp/server-3.4.asc | apt-key add - &> /dev/null; then echo -e "${GREEN}#${RESET} Successfully added key for MongoDB 3.4! \\n"; else abort; fi
  if command -v jq &> /dev/null; then
    if [[ "$(curl --silent "https://api.glennr.nl/api/mongodb-release?version=3.4" | jq -r '.expired')" == 'true' ]]; then trusted_mongodb_repo=" trusted=yes"; fi
  else
    if [[ "$(curl --silent "https://api.glennr.nl/api/mongodb-release?version=3.4" | grep -oP '(?<="expired":")[^"]+')" == 'true' ]]; then trusted_mongodb_repo=" trusted=yes"; fi
  fi
}

mongodb_36_key() {
  echo -e "${WHITE_R}#${RESET} Adding key for MongoDB 3.6..."
  if wget -qO - https://www.mongodb.org/static/pgp/server-3.6.asc | apt-key add - &> /dev/null; then echo -e "${GREEN}#${RESET} Successfully added key for MongoDB 3.6! \\n"; else abort; fi
  if command -v jq &> /dev/null; then
    if [[ "$(curl --silent "https://api.glennr.nl/api/mongodb-release?version=3.6" | jq -r '.expired')" == 'true' ]]; then trusted_mongodb_repo=" trusted=yes"; fi
  else
    if [[ "$(curl --silent "https://api.glennr.nl/api/mongodb-release?version=3.6" | grep -oP '(?<="expired":")[^"]+')" == 'true' ]]; then trusted_mongodb_repo=" trusted=yes"; fi
  fi
}

mongodb_42_key() {
  echo -e "${WHITE_R}#${RESET} Adding key for MongoDB 4.2..."
  if wget -qO - https://www.mongodb.org/static/pgp/server-4.2.asc | apt-key add - &> /dev/null; then echo -e "${GREEN}#${RESET} Successfully added key for MongoDB 4.2! \\n"; else abort; fi
  if command -v jq &> /dev/null; then
    if [[ "$(curl --silent "https://api.glennr.nl/api/mongodb-release?version=4.2" | jq -r '.expired')" == 'true' ]]; then trusted_mongodb_repo=" trusted=yes"; fi
  else
    if [[ "$(curl --silent "https://api.glennr.nl/api/mongodb-release?version=4.2" | grep -oP '(?<="expired":")[^"]+')" == 'true' ]]; then trusted_mongodb_repo=" trusted=yes"; fi
  fi
}

if [[ "${os_codename}" =~ (disco|eoan|focal|groovy) ]]; then
  header
  echo -e "${WHITE_R}#${RESET} Installing a required package..\\n" && sleep 2
  libssl_temp="$(mktemp --tmpdir=/tmp libssl1.0.2_XXXXX.deb)" || abort
  libssl_url=$(curl -s http://security.ubuntu.com/ubuntu/pool/main/o/openssl1.0/ | grep -io "libssl1.0.0.*amd64.deb" | sed '/u5_/d' | cut -d'"' -f1 | tail -n1)
  echo -e "${WHITE_R}#${RESET} Downloading libssl..."
  wget "${wget_progress[@]}" -qO "$libssl_temp" "http://security.ubuntu.com/ubuntu/pool/main/o/openssl1.0/${libssl_url}" || abort
  echo -e "\\n${WHITE_R}#${RESET} Installing libssl..."
  if dpkg -i "$libssl_temp" &>> "${eus_dir}/logs/mongodb_install.log"; then echo -e "${GREEN}#${RESET} Successfully installed libssl! \\n"; else echo -e "${RED}#${RESET} Failed to install libssl...\\n"; abort; fi
  rm --force "$libssl_temp" 2> /dev/null
fi

libcurl_check
mongodb_supported_check
header
echo -e "${WHITE_R}#${RESET} Preparing for MongoDB installation..."
sleep 2
if ! dpkg -l | grep "^ii\\|^hi" | grep -iq "mongodb-server\\|mongodb-org-server"; then
  echo ""
  if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "mongodb.org") -gt 0 ]]; then
    grep -riIl "mongodb.org" /etc/apt/ >> /tmp/EIS_mongodb_repositories
    while read -r EUS_repositories; do
      sed -i '/mongodb.org/d' "${EUS_repositories}" 2> /dev/null
      if ! [[ -s "${EUS_repositories}" ]]; then
        rm --force "${EUS_repositories}" 2> /dev/null
      fi
    done < /tmp/EIS_mongodb_repositories
    rm --force /tmp/EIS_mongodb_repositories 2> /dev/null
  fi
  if [[ "${os_codename}" =~ (precise|maya) ]]; then
    mongodb_34_key
    echo "deb [ arch=amd64${trusted_mongodb_repo} ] https://repo.mongodb.org/apt/ubuntu precise/mongodb-org/3.4 multiverse" &> /etc/apt/sources.list.d/mongodb-org-3.4.list || abort
    hide_apt_update=true
    run_apt_get_update
    echo -e "${WHITE_R}#${RESET} Installing mongodb-org version ${mongo_version_supported::3}..."
    if DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install mongodb-org &>> "${eus_dir}/logs/mongodb_install.log"; then echo -e "${GREEN}#${RESET} Successfully installed mongodb-org version 3.4! \\n"; else echo -e "${RED}#${RESET} Failed to install mongodb-org version 3.4...\\n"; abort; fi
  elif [[ "${os_codename}" =~ (trusty|qiana|rebecca|rafaela|rosa) && "${architecture}" =~ (amd64|arm64) ]]; then
    if [[ "${mongo_version_supported}" == "4.2.999" ]]; then
      mongodb_42_key
    elif [[ "${mongo_version_supported}" == "3.6.999" ]]; then
      mongodb_36_key
    else
      mongodb_34_key
    fi
    echo "deb [ arch=amd64${trusted_mongodb_repo} ] https://repo.mongodb.org/apt/ubuntu trusty/mongodb-org/${mongo_version_supported::3} multiverse" &> "/etc/apt/sources.list.d/mongodb-org-${mongo_version_supported::3}.list" || abort
    hide_apt_update=true
    run_apt_get_update
    echo -e "${WHITE_R}#${RESET} Installing mongodb-org version ${mongo_version_supported::3}..."
    if DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install mongodb-org &>> "${eus_dir}/logs/mongodb_install.log"; then echo -e "${GREEN}#${RESET} Successfully installed mongodb-org version ${mongo_version_supported::3}! \\n"; else echo -e "${RED}#${RESET} Failed to install mongodb-org version ${mongo_version_supported::3}...\\n"; abort; fi
  elif [[ "${os_codename}" =~ (xenial|bionic|cosmic|disco|eoan|focal|groovy|sarah|serena|sonya|sylvia|tara|tessa|tina|tricia) ]]; then
    if [[ "${mongo_version_supported}" == "4.2.999" ]]; then
      mongodb_42_key
    elif [[ "${mongo_version_supported}" == "3.6.999" ]]; then
      mongodb_36_key
    else
      mongodb_34_key
    fi
    echo "deb [ arch=amd64,arm64${trusted_mongodb_repo} ] https://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/${mongo_version_supported::3} multiverse" &> "/etc/apt/sources.list.d/mongodb-org-${mongo_version_supported::3}.list" || abort
    hide_apt_update=true
    run_apt_get_update
    echo -e "${WHITE_R}#${RESET} Installing mongodb-org version ${mongo_version_supported::3}..."
    if DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install mongodb-org &>> "${eus_dir}/logs/mongodb_install.log"; then echo -e "${GREEN}#${RESET} Successfully installed mongodb-org version ${mongo_version_supported::3}! \\n"; else echo -e "${RED}#${RESET} Failed to install mongodb-org version ${mongo_version_supported::3}...\\n"; abort; fi
  elif [[ "${os_codename}" =~ (jessie|stretch|continuum|buster|bullseye) ]]; then
    if [[ "${os_codename}" == "jessie" ]]; then
      echo "deb [${trusted_mongodb_repo} ] https://repo.mongodb.org/apt/debian jessie/mongodb-org/${mongo_version_supported::3} main" &> "/etc/apt/sources.list.d/mongodb-org-${mongo_version_supported::3}.list" || abort
      debian_64_mongo=install
    elif [[ "${os_codename}" =~ (stretch|continuum|buster|bullseye) ]]; then
      echo "deb [ arch=amd64,arm64${trusted_mongodb_repo} ] https://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/${mongo_version_supported::3} multiverse" &> "/etc/apt/sources.list.d/mongodb-org-${mongo_version_supported::3}.list" || abort
      libssl_temp="$(mktemp --tmpdir=/tmp libssl1.0.2_XXXXX.deb)" || abort
      libssl_url=$(curl -s http://security.ubuntu.com/ubuntu/pool/main/o/openssl1.0/ | grep -io "libssl1.0.0.*amd64.deb" | sed '/u5_/d' | cut -d'"' -f1 | tail -n1)
      echo -e "${WHITE_R}#${RESET} Downloading libssl..."
      wget "${wget_progress[@]}" -qO "$libssl_temp" "http://security.ubuntu.com/ubuntu/pool/main/o/openssl1.0/${libssl_url}" || abort
      echo -e "\\n${WHITE_R}#${RESET} Installing libssl..."
      if dpkg -i "$libssl_temp" &>> "${eus_dir}/logs/mongodb_install.log"; then echo -e "${GREEN}#${RESET} Successfully installed libssl! \\n"; else echo -e "${RED}#${RESET} Failed to install libssl...\\n"; abort; fi
      rm --force "$libssl_temp" 2> /dev/null
      debian_64_mongo=install
    fi
    if [ "${debian_64_mongo}" == 'install' ]; then
      if [[ "${mongo_version_supported}" == "4.2.999" ]]; then
        mongodb_42_key
      elif [[ "${mongo_version_supported}" == "3.6.999" ]]; then
        mongodb_36_key
      else
        mongodb_34_key
      fi
      hide_apt_update=true
      run_apt_get_update
      echo -e "${WHITE_R}#${RESET} Installing mongodb-org version ${mongo_version_supported::3}..."
      if DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install mongodb-org &>> "${eus_dir}/logs/mongodb_install.log"; then echo -e "${GREEN}#${RESET} Successfully installed mongodb-org version ${mongo_version_supported::3}! \\n"; else echo -e "${RED}#${RESET} Failed to install mongodb-org version ${mongo_version_supported::3}...\\n"; abort; fi
    fi
  else
    header_red
    echo -e "${RED}#${RESET} The script is unable to grab your OS ( or does not support it )"
    echo "${architecture}"
    echo "${os_codename}"
    abort
  fi
else
  echo -e "${GREEN}#${RESET} MongoDB is already installed! \\n"
fi
sleep 3

openjdk_version=$(dpkg -l | grep "^ii\\|^hi" | grep "openjdk-8" | awk '{print $3}' | grep "^8u" | sed 's/-.*//g' | sed 's/8u//g' | grep -o '[[:digit:]]*' | sort -V | tail -n 1)
if dpkg -l | grep "^ii\\|^hi" | grep -iq "openjdk-8"; then
  if [[ "${openjdk_version}" -lt '131' ]]; then
    old_openjdk_version=true
  fi
fi
if ! dpkg -l | grep "^ii\\|^hi" | grep -iq "openjdk-8" || [[ "${old_openjdk_version}" == 'true' ]]; then
  if [[ "${old_openjdk_version}" == 'true' ]]; then
    header_red
    echo -e "${RED}#${RESET} OpenJDK 8 is to old...\\n" && sleep 2
    openjdk_variable="Updating"
    openjdk_variable_2="Updated"
    openjdk_variable_3="Update"
  else
    header
    echo -e "${GREEN}#${RESET} Preparing OpenJDK 8 installation...\\n" && sleep 2
    openjdk_variable="Installing"
    openjdk_variable_2="Installed"
    openjdk_variable_3="Install"
  fi
  sleep 2
  if apt-cache policy openjdk-8-jre-headless | awk '/Candidate/{print $2}' | grep -iq "8u282"; then install_older_openjdk=true; fi
  if [[ "${repo_codename}" =~ (precise|trusty|xenial|bionic|cosmic) ]]; then
    echo -e "${WHITE_R}#${RESET} ${openjdk_variable} openjdk-8-jre-headless..."
    if [[ "${install_older_openjdk}" != 'true' ]]; then
      if ! DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install openjdk-8-jre-headless &> /dev/null || [[ "${old_openjdk_version}" == 'true' ]]; then
        echo -e "${RED}#${RESET} Failed to ${openjdk_variable_3} openjdk-8-jre-headless in the first run...\\n"
        if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ppa.launchpad.net/openjdk-r/ppa/ubuntu ${repo_codename} main") -eq 0 ]]; then
          echo "deb http://ppa.launchpad.net/openjdk-r/ppa/ubuntu ${repo_codename} main" >> /etc/apt/sources.list.d/glennr-install-script.list || abort
          echo "EB9B1D8886F44E2A" &>> /tmp/EUS/keys/missing_keys
        fi
        required_package="openjdk-8-jre-headless"
        apt_get_install_package
      else
        echo -e "${GREEN}#${RESET} Successfully ${openjdk_variable_2} openjdk-8-jre-headless! \\n" && sleep 2
      fi
    else
      rm --force /tmp/EUS/java/* &> /dev/null
      mkdir -p /tmp/EUS/java/ &> /dev/null
      if [[ "${repo_codename}" =~ (precise|trusty|xenial) ]]; then
        curl -qo /tmp/EUS/java/openjdk-8-jre-headless_8u275-b01.deb "https://launchpadlibrarian.net/505954362/openjdk-8-jre-headless_8u275-b01-0ubuntu1~16.04_amd64.deb" &>> "${eus_dir}/logs/openjdk_download.log"
      elif [[ "${repo_codename}" =~ (bionic|cosmic) ]]; then
        curl -qo /tmp/EUS/java/openjdk-8-jre-headless_8u275-b01.deb "https://launchpadlibrarian.net/505954411/openjdk-8-jre-headless_8u275-b01-0ubuntu1~18.04_amd64.deb" &>> "${eus_dir}/logs/openjdk_download.log"
      fi
      if ! DEBIAN_FRONTEND='noninteractive' apt-get -y -f -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install /tmp/EUS/java/openjdk-8-jre-headless_8u275-b01.deb &> /dev/null; then
        echo -e "${RED}#${RESET} Failed to install an older version of openjdk-8-jre-headless..."; abort
      else
        echo -e "${GREEN}#${RESET} Successfully installed openjdk-8-jre-headless! \\n" && sleep 2
      fi
    fi
  elif [[ "${repo_codename}" =~ (disco|eoan|focal|groovy) ]]; then
    echo -e "${WHITE_R}#${RESET} ${openjdk_variable} openjdk-8-jre-headless..."
    if [[ "${install_older_openjdk}" != 'true' ]]; then
      if ! DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install openjdk-8-jre-headless &> /dev/null || [[ "${old_openjdk_version}" == 'true' ]]; then
        echo -e "${RED}#${RESET} Failed to ${openjdk_variable_3} openjdk-8-jre-headless in the first run...\\n"
        if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://security.ubuntu.com/ubuntu bionic-security main universe") -eq 0 ]]; then
          echo "deb http://security.ubuntu.com/ubuntu bionic-security main universe" >> /etc/apt/sources.list.d/glennr-install-script.list || abort
        fi
        required_package="openjdk-8-jre-headless"
        apt_get_install_package
      else
        echo -e "${GREEN}#${RESET} Successfully ${openjdk_variable_2} openjdk-8-jre-headless! \\n" && sleep 2
      fi
    else
      rm --force /tmp/EUS/java/* &> /dev/null
      mkdir -p /tmp/EUS/java/ &> /dev/null
      if [[ "${repo_codename}" =~ (disco|eoan|focal|groovy) ]]; then
        curl -qo /tmp/EUS/java/openjdk-8-jre-headless_8u275-b01.deb "https://launchpadlibrarian.net/505955801/openjdk-8-jre-headless_8u275-b01-0ubuntu1~20.04_amd64.deb" &>> "${eus_dir}/logs/openjdk_download.log"
      fi
      if ! DEBIAN_FRONTEND='noninteractive' apt-get -y -f -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install /tmp/EUS/java/openjdk-8-jre-headless_8u275-b01.deb &> /dev/null; then
        echo -e "${RED}#${RESET} Failed to install an older version of openjdk-8-jre-headless..."; abort
      else
        echo -e "${GREEN}#${RESET} Successfully installed openjdk-8-jre-headless! \\n" && sleep 2
      fi
    fi
  elif [[ "${os_codename}" == "jessie" ]]; then
    echo -e "${WHITE_R}#${RESET} ${openjdk_variable} openjdk-8-jre-headless..."
    if ! DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install -t jessie-backports openjdk-8-jre-headless &> /dev/null || [[ "${old_openjdk_version}" == 'true' ]]; then
      echo -e "${RED}#${RESET} Failed to ${openjdk_variable_3} openjdk-8-jre-headless in the first run...\\n"
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -P -c "^deb http[s]*://archive.debian.org/debian jessie-backports main") -eq 0 ]]; then
        echo deb http://archive.debian.org/debian jessie-backports main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
        http_proxy=$(env | grep -i "http.*Proxy" | cut -d'=' -f2 | sed 's/[";]//g')
        if [[ -n "$http_proxy" ]]; then
          apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --keyserver-options http-proxy="${http_proxy}" --recv-keys 8B48AD6246925553 7638D0442B90D010 || abort
        elif [[ -f /etc/apt/apt.conf ]]; then
          apt_http_proxy=$(grep "http.*Proxy" /etc/apt/apt.conf | awk '{print $2}' | sed 's/[";]//g')
          if [[ -n "${apt_http_proxy}" ]]; then
            apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --keyserver-options http-proxy="${apt_http_proxy}" --recv-keys 8B48AD6246925553 7638D0442B90D010 || abort
          fi
        else
          apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 8B48AD6246925553 7638D0442B90D010 || abort
        fi
        echo -e "${WHITE_R}#${RESET} Running apt-get update..."
        required_package="openjdk-8-jre-headless"
        if apt-get update -o Acquire::Check-Valid-Until=false &> /dev/null; then echo -e "${GREEN}#${RESET} Successfully ran apt-get update! \\n"; else echo -e "${RED}#${RESET} Failed to ran apt-get update! \\n"; abort; fi
        echo -e "\\n------- ${required_package} installation ------- $(date +%F-%R) -------\\n" &>> "${eus_dir}/logs/apt.log"
        if DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install -t jessie-backports openjdk-8-jre-headless &>> "${eus_dir}/logs/apt.log"; then echo -e "${GREEN}#${RESET} Successfully installed ${required_package}! \\n" && sleep 2; else echo -e "${RED}#${RESET} Failed to install ${required_package}! \\n"; abort; fi
        sed -i '/jessie-backports/d' /etc/apt/sources.list.d/glennr-install-script.list
        unset required_package
      fi
    fi
  elif [[ "${os_codename}" =~ (stretch|continuum) ]]; then
    echo -e "${WHITE_R}#${RESET} ${openjdk_variable} openjdk-8-jre-headless..."
    if ! DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install openjdk-8-jre-headless &> /dev/null || [[ "${old_openjdk_version}" == 'true' ]]; then
      echo -e "${RED}#${RESET} Failed to ${openjdk_variable_3} openjdk-8-jre-headless in the first run...\\n"
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ppa.launchpad.net/openjdk-r/ppa/ubuntu xenial main") -eq 0 ]]; then
        echo "deb http://ppa.launchpad.net/openjdk-r/ppa/ubuntu xenial main" >> /etc/apt/sources.list.d/glennr-install-script.list || abort
        echo "EB9B1D8886F44E2A" &>> /tmp/EUS/keys/missing_keys
      fi
      required_package="openjdk-8-jre-headless"
      apt_get_install_package
    else
      echo -e "${GREEN}#${RESET} Successfully ${openjdk_variable_2} openjdk-8-jre-headless! \\n" && sleep 2
    fi
  elif [[ "${repo_codename}" =~ (buster|bullseye) ]]; then
    echo -e "${WHITE_R}#${RESET} ${openjdk_variable} openjdk-8-jre-headless..."
    if ! DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install openjdk-8-jre-headless &> /dev/null || [[ "${old_openjdk_version}" == 'true' ]]; then
      echo -e "${RED}#${RESET} Failed to ${openjdk_variable_3} openjdk-8-jre-headless in the first run...\\n"
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ftp.nl.debian.org/debian stretch main") -eq 0 ]]; then
        echo "deb http://ftp.nl.debian.org/debian stretch main" >> /etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
      required_package="openjdk-8-jre-headless"
      apt_get_install_package
    else
      echo -e "${GREEN}#${RESET} Successfully ${openjdk_variable_2} openjdk-8-jre-headless! \\n" && sleep 2
    fi
  else
    header_red
    echo -e "${RED}Please manually install JAVA 8 on your system!${RESET}\\n"
    echo -e "${RED}OS Details:${RESET}\\n"
    echo -e "${RED}$(lsb_release -a)${RESET}\\n"
    exit 0
  fi
else
  header
  echo -e "${GREEN}#${RESET} Preparing OpenJDK 8 installation..."
  echo -e "${WHITE_R}#${RESET} OpenJDK 8 is already installed! \\n"
fi
sleep 3

if dpkg -l | grep "^ii\\|^hi" | grep -iq "openjdk-8"; then
  openjdk_8_installed=true
fi
if dpkg -l | grep "^ii\\|^hi" | grep -i "openjdk-.*-\\|oracle-java.*" | grep -vq "openjdk-8\\|oracle-java8"; then
  unsupported_java_installed=true
fi

if [[ "${openjdk_8_installed}" == 'true' && "${unsupported_java_installed}" == 'true' && "${script_option_skip}" != 'true' ]]; then
  header_red
  echo -e "${WHITE_R}#${RESET} Unsupported JAVA version(s) are detected, do you want to uninstall them?"
  echo -e "${WHITE_R}#${RESET} This may remove packages that depend on these java versions."
  read -rp $'\033[39m#\033[0m Do you want to proceed with uninstalling the unsupported JAVA version(s)? (y/N) ' yes_no
  case "$yes_no" in
       [Yy]*)
          rm --force /tmp/EUS/java/* &> /dev/null
          mkdir -p /tmp/EUS/java/ &> /dev/null
          mkdir -p "${eus_dir}/logs/" &> /dev/null
          header
          echo -e "${WHITE_R}#${RESET} Uninstalling unsupported JAVA versions..."
          echo -e "\\n${WHITE_R}----${RESET}\\n"
          sleep 3
          dpkg -l | grep "^ii\\|^hi" | awk '/openjdk-.*/{print $2}' | cut -d':' -f1 | grep -v "openjdk-8" &>> /tmp/EUS/java/unsupported_java_list_tmp
          dpkg -l | grep "^ii\\|^hi" | awk '/oracle-java.*/{print $2}' | cut -d':' -f1 | grep -v "oracle-java8" &>> /tmp/EUS/java/unsupported_java_list_tmp
          awk '!a[$0]++' /tmp/EUS/java/unsupported_java_list_tmp >> /tmp/EUS/java/unsupported_java_list; rm --force /tmp/EUS/java/unsupported_java_list_tmp 2> /dev/null
          echo -e "\\n------- $(date +%F-%R) -------\\n" &>> "${eus_dir}/logs/java_uninstall.log"
          while read -r package; do
            apt-get remove "${package}" -y &>> "${eus_dir}/logs/java_uninstall.log" && echo -e "${WHITE_R}#${RESET} Successfully removed ${package}." || echo -e "${WHITE_R}#${RESET} Failed to remove ${package}."
          done < /tmp/EUS/java/unsupported_java_list
          rm --force /tmp/EUS/java/unsupported_java_list &> /dev/null
          echo -e "\\n" && sleep 3;;
       [Nn]*|"") ;;
  esac
fi

if dpkg -l | grep "^ii\\|^hi" | grep -iq "openjdk-8"; then
  update_java_alternatives=$(update-java-alternatives --list | grep "^java-1.8.*openjdk" | awk '{print $1}' | head -n1)
  if [[ -n "${update_java_alternatives}" ]]; then
    update-java-alternatives --set "${update_java_alternatives}" &> /dev/null
  fi
  update_alternatives=$(update-alternatives --list java | grep "java-8-openjdk" | awk '{print $1}' | head -n1)
  if [[ -n "${update_alternatives}" ]]; then
    update-alternatives --set java "${update_alternatives}" &> /dev/null
  fi
  header
  echo -e "${WHITE_R}#${RESET} Updating the ca-certificates..." && sleep 2
  rm /etc/ssl/certs/java/cacerts 2> /dev/null
  update-ca-certificates -f &> /dev/null && echo -e "${GREEN}#${RESET} Successfully updated the ca-certificates\\n" && sleep 2
fi

if dpkg -l | grep "^ii\\|^hi" | grep -iq "openjdk-8"; then
  java_home_readlink="JAVA_HOME=$( readlink -f "$( command -v java )" | sed "s:bin/.*$::" )"
  if [[ -f /etc/default/unifi ]]; then
    current_java_home=$(grep "^JAVA_HOME" /etc/default/unifi)
    if [[ -n "${java_home_readlink}" ]]; then
      if [[ "${current_java_home}" != "${java_home_readlink}" ]]; then
        sed -i 's/^JAVA_HOME/#JAVA_HOME/' /etc/default/unifi
        echo "${java_home_readlink}" >> /etc/default/unifi
      fi
    fi
  else
    current_java_home=$(grep "^JAVA_HOME" /etc/environment)
    if [[ -n "${java_home_readlink}" ]]; then
      if [[ "${current_java_home}" != "${java_home_readlink}" ]]; then
        sed -i 's/^JAVA_HOME/#JAVA_HOME/' /etc/environment
        echo "${java_home_readlink}" >> /etc/environment
        # shellcheck disable=SC1091
        source /etc/environment
      fi
    fi
  fi
fi

header
echo -e "${WHITE_R}#${RESET} Preparing installation of the UniFi Video dependencies...\\n"
sleep 2
echo -e "\\n------- dependency installation ------- $(date +%F-%R) -------\\n" &>> "${eus_dir}/logs/apt.log"
if [[ "${os_codename}" =~ (precise|maya|trusty|qiana|rebecca|rafaela|rosa|xenial|sarah|serena|sonya|sylvia|bionic|tara|tessa|tina|tricia|cosmic|disco|eoan|focal|groovy|stretch|continuum|buster|bullseye) ]]; then
  echo -e "${WHITE_R}#${RESET} Installing binutils, ca-certificates-java and java-common..."
  if DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install binutils ca-certificates-java java-common &>> "${eus_dir}/logs/apt.log"; then echo -e "${GREEN}#${RESET} Successfully installed binutils, ca-certificates-java and java-common! \\n"; else echo -e "${RED}#${RESET} Failed to install binutils, ca-certificates-java and java-common in the first run...\\n"; unifi_dependencies=fail; fi
  echo -e "${WHITE_R}#${RESET} Installing jsvc and libcommons-daemon-java..."
  if DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install jsvc libcommons-daemon-java &>> "${eus_dir}/logs/apt.log"; then echo -e "${GREEN}#${RESET} Successfully installed jsvc and libcommons-daemon-java! \\n"; else echo -e "${RED}#${RESET} Failed to install jsvc and libcommons-daemon-java in the first run...\\n"; unifi_dependencies=fail; fi
elif [[ "${os_codename}" == 'jessie' ]]; then
  echo -e "${WHITE_R}#${RESET} Installing binutils, ca-certificates-java and java-common..."
  if DEBIAN_FRONTEND='noninteractive' apt-get -y --force-yes -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install binutils ca-certificates-java java-common &>> "${eus_dir}/logs/apt.log"; then echo -e "${GREEN}#${RESET} Successfully installed binutils, ca-certificates-java and java-common! \\n"; else echo -e "${RED}#${RESET} Failed to install binutils, ca-certificates-java and java-common in the first run...\\n"; unifi_dependencies=fail; fi
  echo -e "${WHITE_R}#${RESET} Installing jsvc and libcommons-daemon-java..."
  if DEBIAN_FRONTEND='noninteractive' apt-get -y --force-yes -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install jsvc libcommons-daemon-java &>> "${eus_dir}/logs/apt.log"; then echo -e "${GREEN}#${RESET} Successfully installed jsvc and libcommons-daemon-java! \\n"; else echo -e "${RED}#${RESET} Failed to install jsvc and libcommons-daemon-java in the first run...\\n"; unifi_dependencies=fail; fi
fi
if [[ "${unifi_dependencies}" == 'fail' ]]; then
  if [[ "${repo_codename}" =~ (precise|trusty|xenial|bionic|cosmic|disco|eoan|focal|groovy) ]]; then
    if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -P -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu ${repo_codename} main universe") -eq 0 ]]; then
      echo "deb http://nl.archive.ubuntu.com/ubuntu ${repo_codename} main universe" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
    fi
  elif [[ "${os_codename}" =~ (jessie|stretch|buster|bullseye) ]]; then
    if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -P -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian ${repo_codename} main") -eq 0 ]]; then
      echo "deb http://ftp.nl.debian.org/debian ${repo_codename} main" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
    fi
  fi
  hide_apt_update=true
  run_apt_get_update
  if [[ "${os_codename}" =~ (precise|maya|trusty|qiana|rebecca|rafaela|rosa|xenial|sarah|serena|sonya|sylvia|bionic|tara|tessa|tina|tricia|cosmic|disco|eoan|focal|groovy|stretch|continuum|buster|bullseye) ]]; then
  echo -e "${WHITE_R}#${RESET} Installing binutils, ca-certificates-java and java-common..."
    if DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install binutils ca-certificates-java java-common &>> "${eus_dir}/logs/apt.log"; then echo -e "${GREEN}#${RESET} Successfully installed binutils, ca-certificates-java and java-common! \\n"; else echo -e "${RED}#${RESET} Failed to install binutils, ca-certificates-java and java-common in the first run...\\n"; abort; fi
  echo -e "${WHITE_R}#${RESET} Installing jsvc and libcommons-daemon-java..."
    if DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install jsvc libcommons-daemon-java &>> "${eus_dir}/logs/apt.log"; then echo -e "${GREEN}#${RESET} Successfully installed jsvc and libcommons-daemon-java! \\n"; else echo -e "${RED}#${RESET} Failed to install jsvc and libcommons-daemon-java in the first run...\\n"; abort; fi
  elif [[ "${os_codename}" == 'jessie' ]]; then
  echo -e "${WHITE_R}#${RESET} Installing binutils, ca-certificates-java and java-common..."
    if DEBIAN_FRONTEND='noninteractive' apt-get -y --force-yes -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install binutils ca-certificates-java java-common &>> "${eus_dir}/logs/apt.log"; then echo -e "${GREEN}#${RESET} Successfully installed binutils, ca-certificates-java and java-common! \\n"; else echo -e "${RED}#${RESET} Failed to install binutils, ca-certificates-java and java-common in the first run...\\n"; abort; fi
  echo -e "${WHITE_R}#${RESET} Installing jsvc and libcommons-daemon-java..."
    if DEBIAN_FRONTEND='noninteractive' apt-get -y --force-yes -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install jsvc libcommons-daemon-java &>> "${eus_dir}/logs/apt.log"; then echo -e "${GREEN}#${RESET} Successfully installed jsvc and libcommons-daemon-java! \\n"; else echo -e "${RED}#${RESET} Failed to install jsvc and libcommons-daemon-java in the first run...\\n"; abort; fi
  fi
fi
sleep 3

header
if [[ "${repo_codename}" == 'xenial' ]]; then
  unifi_video_download_url="https://dl.ui.com/firmwares/ufv/v${unifi_clean}/unifi-video.Ubuntu16.04_amd64.v${unifi_clean}.deb"
elif [[ "${repo_codename}" =~ (bionic|cosmic|disco|eoan|focal|groovy) ]]; then
  unifi_video_download_url="https://dl.ui.com/firmwares/ufv/v${unifi_clean}/unifi-video.Ubuntu18.04_amd64.v${unifi_clean}.deb"
elif [[ "${repo_codename}" == "jessie" ]]; then
  unifi_video_download_url="https://dl.ui.com/firmwares/ufv/v${unifi_clean}/unifi-video.Debian8_amd64.v${unifi_clean}.deb"
elif [[ "${repo_codename}" =~ (stretch|buster|bullseye) ]]; then
  unifi_video_download_url="https://dl.ui.com/firmwares/ufv/v${unifi_clean}/unifi-video.Debian9_amd64.v${unifi_clean}.deb"
fi
echo -e "${WHITE_R}#${RESET} Installing your UniFi Video ( ${WHITE_R}${unifi_clean}${RESET} )...\\n"
sleep 2
if [[ "${script_option_custom_url}" != 'true' ]]; then
  unifi_temp="$(mktemp --tmpdir=/tmp unifi_video_"${unifi_clean}"_XXX.deb)"
  echo -e "${WHITE_R}#${RESET} Downloading UniFi Video..."
  if wget "${wget_progress[@]}" -qO "$unifi_temp" "${unifi_video_download_url}"; then echo -e "${GREEN}#${RESET} Successfully downloaded UniFi Video version ${unifi_clean}! \\n"; else echo -e "${RED}#${RESET} Failed to download UniFi Video version ${unifi_clean}...\\n"; abort; fi
else
  echo -e "${GREEN}#${RESET} UniFi Video version ${WHITE_R}${unifi_clean}${RESET} has already been downloaded!"
fi
echo -e "${WHITE_R}#${RESET} Installing UniFi Video..."
if DEBIAN_FRONTEND=noninteractive dpkg -i "$unifi_temp" &>> "${eus_dir}/logs/unifi_install.log"; then
  echo -e "${GREEN}#${RESET} Successfully installed UniFi Video! \\n"
else
  echo -e "${RED}#${RESET} Failed to install UniFi Video...\\n"
  abort
fi
rm --force "$unifi_temp" 2> /dev/null
service unifi-video start || abort
sleep 3

# Check if MongoDB service is enabled
if ! [[ "${os_codename}" =~ (precise|maya|trusty|qiana|rebecca|rafaela|rosa) ]]; then
  if [ "${mongodb_version::2}" -ge '26' ]; then
    SERVICE_MONGODB=$(systemctl is-enabled mongod)
    if [ "$SERVICE_MONGODB" = 'disabled' ]; then
      systemctl enable mongod 2>/dev/null || { echo -e "${RED}#${RESET} Failed to enable service | MongoDB"; sleep 3; }
    fi
  else
    SERVICE_MONGODB=$(systemctl is-enabled mongodb)
    if [ "$SERVICE_MONGODB" = 'disabled' ]; then
      systemctl enable mongodb 2>/dev/null || { echo -e "${RED}#${RESET} Failed to enable service | MongoDB"; sleep 3; }
    fi
  fi
  # Check if UniFi Video service is enabled
  SERVICE_UNIFI=$(systemctl is-enabled unifi-video)
  if [ "$SERVICE_UNIFI" = 'disabled' ]; then
    systemctl enable unifi-video 2>/dev/null || { echo -e "${RED}#${RESET} Failed to enable service | UniFi Video"; sleep 3; }
  fi
fi

if [[ "${script_option_skip}" != 'true' ]]; then
  header
  echo -e "${WHITE_R}#${RESET} Would you like to update UniFi Video via APT?"
  read -rp $'\033[39m#\033[0m Do you want the script to add the source list file? (Y/n) ' yes_no
  case "$yes_no" in
      [Yy]*|"")
        header
        echo -e "${WHITE_R}#${RESET} Adding source list..."
        sleep 3
        sed -i '/unifi-video/d' /etc/apt/sources.list
        rm --force /etc/apt/sources.list.d/unifi-video.list 2> /dev/null
        cat << EOF >/etc/apt/sources.list.d/unifi-video.list
deb [arch=amd64] http://www.ubnt.com/downloads/unifi-video/apt-3.x xenial ubiquiti
EOF

        # Add UniFi Video signing key
        echo "-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG v1.4.10 (GNU/Linux)

mQENBE6x1soBCACl5VYDwqVHP7ZTVknVdwMUgM2I++8wNAYVE7AuX9wDisKe6jcx
3UFQMp9K2NzYG5c8KiuGAFj4XKFZyYm6+AWQefC0N2rYJWPIM1hBPuql4iwOaHIC
4QLnAFupHIY7+HWWBDiEo1ANH0mOj5mYtO30jtMgu3xdxqXGKuh65KqmV+lbaF6f
ruh6KwAFCj2/JTUPY3k9efNoyx0Cv6wmFfknLh7AAvf6K/0Sfc4oUCVNhdheNI5R
JY+QOThJCGnNeM2D4Xw0dq/6Kwgx9yTXXZ0a9zN6Aow8Y2HGr+JC1lBT30ss07YF
XxXtYnz5Jb/agBTPYM5f5LDm3o4VT+WGwZMzABEBAAG0J2FpclZpc2lvbiBkZXZl
bG9wZXJzIDxzdXBwb3J0QHVibnQuY29tPokBOAQTAQIAIgUCTrHWygIbAwYLCQgH
AwIGFQgCCQoLBBYCAwECHgECF4AACgkQl7RrhYLGVx4uqQf+NyNwUx33kzO+6q4T
Eyt66BSsjmFp9sVqa4aOxIB1NPLFwefVYQUb58tFIIpWLNFw/qEoRb6Bu6Bz2L50
X7Q6WN5MDkD1ddjCzraIB9qVdEIS5z9AYgmSR6Rz2/V/iaL2ByP7X7ic1atWepb0
p1GXRtsA0TT6fD2fxkZF1E7r4NzW+MYmCDXQ40Aj8cM+LZZlqRfQQBb3nhQ62WLX
1JtQNo0bBJMrpkZqrv0cSMN3E3Ff+dgHLlVBzZrip8vQ1Hbl+LOOgrtH6DEyPow9
vDtoEZYQcmR01FAY5haAi9/Qyubw7ZAIGabHRNI71Hy4VVAEIsGSWCaWecED/2r9
hEEUXw==
=DQ7r
-----END PGP PUBLIC KEY BLOCK-----" | apt-key add - &> /dev/null && echo -e "${GREEN}#${RESET} Successfully added UniFi Video source list! \\n"
        hide_apt_update=true
        run_apt_get_update;;
      [Nn]*) ;;
  esac
fi

if dpkg -l ufw | grep -q "^ii\\|^hi"; then
  if ufw status verbose | awk '/^Status:/{print $2}' | grep -xq "active"; then
    header
    echo -e "${WHITE_R}#${RESET} Uncomplicated Firewall ( UFW ) seems to be active."
    echo -e "${WHITE_R}#${RESET} Checking if all required ports are added!"
    rm -rf /tmp/EUS/ports/* &> /dev/null
    mkdir -p /tmp/EUS/ports/ &> /dev/null
    ssh_port=$(awk '/Port/{print $2}' /etc/ssh/sshd_config | head -n1)
    unifi_ports=(7080/tcp 7443/tcp)
    echo -e "7080/tcp\\n7443/tcp" &>> /tmp/EUS/ports/all_ports
    echo -e "${ssh_port}" &>> /tmp/EUS/ports/all_ports
    ufw status verbose &>> /tmp/EUS/ports/ufw_list
    while read -r port; do
      port_number_only=$(echo "${port}" | cut -d'/' -f1)
      # shellcheck disable=SC1117
      if ! grep "^${port_number_only}\b\\|^${port}\b" /tmp/EUS/ports/ufw_list | grep -iq "ALLOW IN"; then
        required_port_missing=true
      fi
      # shellcheck disable=SC1117
      if ! grep -v "(v6)" /tmp/EUS/ports/ufw_list | grep "^${port_number_only}\b\\|^${port}\b" | grep -iq "ALLOW IN"; then
        required_port_missing=true
      fi
    done < /tmp/EUS/ports/all_ports
    if [[ "${required_port_missing}" == 'true' ]]; then
      echo -e "\\n${WHITE_R}----${RESET}\\n\\n"
      echo -e "${WHITE_R}#${RESET} We are missing required ports.."
      if [[ "${script_option_skip}" != 'true' ]]; then
        read -rp $'\033[39m#\033[0m Do you want to add the required ports for UniFi Video? (Y/n) ' yes_no
      else
        echo -e "${WHITE_R}#${RESET} Adding required UniFi Video ports.."
        sleep 2
      fi
      case "${yes_no}" in
         [Yy]*|"")
            echo -e "\\n${WHITE_R}----${RESET}\\n\\n"
            for port in "${unifi_ports[@]}"; do
              port_number=$(echo "${port}" | cut -d'/' -f1)
              ufw allow "${port}" &> "/tmp/EUS/ports/${port_number}"
              if [[ -f "/tmp/EUS/ports/${port_number}" && -s "/tmp/EUS/ports/${port_number}" ]]; then
                if grep -iq "added" "/tmp/EUS/ports/${port_number}"; then
                  echo -e "${WHITE_R}#${RESET} Successfully added port ${port} to UFW."
                fi
                if grep -iq "skipping" "/tmp/EUS/ports/${port_number}"; then
                  echo -e "${WHITE_R}#${RESET} Port ${port} was already added to UFW."
                fi
              fi
            done
            if [[ -f /etc/ssh/sshd_config && -s /etc/ssh/sshd_config ]]; then
              if ! ufw status verbose | grep -v "(v6)" | grep "${ssh_port}" | grep -iq "ALLOW IN"; then
                echo -e "\\n${WHITE_R}----${RESET}\\n\\n${WHITE_R}#${RESET} Your SSH port ( ${ssh_port} ) doesn't seem to be in your UFW list.."
                if [[ "${script_option_skip}" != 'true' ]]; then
                  read -rp $'\033[39m#\033[0m Do you want to add your SSH port to the UFW list? (Y/n) ' yes_no
                else
                  echo -e "${WHITE_R}#${RESET} Adding port ${ssh_port}.."
                  sleep 2
                fi
                case "${yes_no}" in
                   [Yy]*|"")
                      echo -e "\\n${WHITE_R}----${RESET}\\n"
                      ufw allow "${ssh_port}" &> "/tmp/EUS/ports/${ssh_port}"
                      if [[ -f "/tmp/EUS/ports/${ssh_port}" && -s "/tmp/EUS/ports/${ssh_port}" ]]; then
                        if grep -iq "added" "/tmp/EUS/ports/${ssh_port}"; then
                          echo -e "${WHITE_R}#${RESET} Successfully added port ${ssh_port} to UFW."
                        fi
                        if grep -iq "skipping" "/tmp/EUS/ports/${ssh_port}"; then
                          echo -e "${WHITE_R}#${RESET} Port ${ssh_port} was already added to UFW."
                        fi
                      fi;;
                   [Nn]*|*) ;;
                esac
              fi
            fi;;
         [Nn]*|*) ;;
      esac
    else
      echo -e "\\n${WHITE_R}----${RESET}\\n\\n${WHITE_R}#${RESET} All required ports already exist!"
    fi
    echo -e "\\n\\n" && sleep 2
  fi
fi

if [[ -z "${SERVER_IP}" ]]; then
  SERVER_IP=$(ip addr | grep -A8 -m1 MULTICAST | grep -m1 inet | cut -d' ' -f6 | cut -d'/' -f1)
fi

# Check if UniFi Video is reachable via public IP.
timeout 1 nc -zv "${PUBLIC_SERVER_IP}" "7443" &> /dev/null && remote_controller=true

if [[ "${remote_controller}" == 'true' ]] && [[ "${script_option_skip}" != 'true' || "${fqdn_specified}" == 'true' ]]; then
  echo -e "--install-script" &>> /tmp/EUS/le_script_options
  if [[ -f /tmp/EUS/le_script_options && -s /tmp/EUS/le_script_options ]]; then IFS=" " read -r le_script_options <<< "$(tr '\r\n' ' ' < /tmp/EUS/le_script_options)"; fi
  header
  le_script=true
  echo -e "${WHITE_R}#${RESET} Your UniFi Video NVR seems to be exposed to the internet. ( port 7443 is open )"
  echo -e "${WHITE_R}#${RESET} It's recommend to secure your UniFi Video NVR with a SSL certficate.\\n"
  echo -e "${WHITE_R}#${RESET} Requirements:"
  echo -e "${WHITE_R}-${RESET} A domain name and A record pointing to the UniFi Video NVR."
  echo -e "${WHITE_R}-${RESET} Port 80 needs to be open ( port forwarded )\\n\\n"
  if [[ "${script_option_skip}" != 'true' ]]; then read -rp $'\033[39m#\033[0m Do you want to download and execute my UniFi Easy Encrypt Script? (Y/n) ' yes_no; fi
  case "$yes_no" in
      [Yy]*|"")
          # shellcheck disable=SC2086
          rm --force unifi-easy-encrypt.sh &> /dev/null; wget "${wget_progress[@]}" -q https://get.glennr.nl/unifi/extra/unifi-easy-encrypt.sh && bash unifi-easy-encrypt.sh ${le_script_options[@]};;
      [Nn]*) ;;
  esac
fi

if [[ "${netcat_installed}" == 'true' ]]; then
  header
  echo -e "${WHITE_R}#${RESET} The script installed netcat, we do not need this anymore.\\n"
  echo -e "${WHITE_R}#${RESET} Uninstalling netcat..."
  apt-get purge netcat -y &> /dev/null && echo -e "${GREEN}#${RESET} Successfully uninstalled netcat." || echo -e "${RED}#${RESET} Failed to uninstall netcat."
  sleep 2
fi

if dpkg -l | grep "unifi-video" | grep -q "^ii\\|^hi"; then
  header
  echo -e "${GREEN}#${RESET} UniFi Video ${unifi_clean} has been installed successfully"
  if [[ "${remote_controller}" = 'true' ]]; then
    echo -e "${GREEN}#${RESET} Your UniFi Video NVR address: ${WHITE_R}https://$PUBLIC_SERVER_IP:7443${RESET}"
    if [[ "${le_script}" == 'true' ]]; then
      if [[ -d /usr/lib/EUS/ ]]; then
        if [[ -f /usr/lib/EUS/server_fqdn_install && -s /usr/lib/EUS/server_fqdn_install ]]; then
          controller_fqdn_le=$(tail -n1 /usr/lib/EUS/server_fqdn_install)
          rm --force /usr/lib/EUS/server_fqdn_install &> /dev/null
        fi
      elif [[ -d /srv/EUS/ ]]; then
        if [[ -f /srv/EUS/server_fqdn_install && -s /srv/EUS/server_fqdn_install ]]; then
          controller_fqdn_le=$(tail -n1 /srv/EUS/server_fqdn_install)
          rm --force /srv/EUS/server_fqdn_install &> /dev/null
        fi
      fi
      if [[ -n "${controller_fqdn_le}" ]]; then
        echo -e "${GREEN}#${RESET} Your UniFi Video NVR FQDN: ${WHITE_R}https://$controller_fqdn_le:7443${RESET}"
      fi
    fi
  else
    echo -e "${GREEN}#${RESET} Your UniFi Video NVR address: ${WHITE_R}https://$SERVER_IP:7443${RESET}"
  fi
  echo -e "\\n"
  if [[ "${os_codename}" =~ (precise|maya|trusty|qiana|rebecca|rafaela|rosa) ]]; then
    service unifi-video status | grep -q running && echo -e "${GREEN}#${RESET} UniFi Video is active ( running )" || echo -e "${RED}#${RESET} UniFi Video failed to start... Please contact Glenn R. (AmazedMender16) on the Community Forums!"
  else
    systemctl is-active -q unifi-video && echo -e "${GREEN}#${RESET} UniFi Video is active ( running )" || echo -e "${RED}#${RESET} UniFi Video failed to start... Please contact Glenn R. (AmazedMender16) on the Community Forums!"
  fi
  echo -e "\\n"
  author
  remove_yourself
else
  header_red
  echo -e "\\n${RED}#${RESET} Failed to successfully install UniFi Video ${unifi_clean}"
  echo -e "${RED}#${RESET} Please contact Glenn R. (AmazedMender16) on the Community Forums!${RESET}\\n\\n"
  remove_yourself
fi