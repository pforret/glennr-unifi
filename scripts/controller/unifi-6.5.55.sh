#!/bin/bash

# UniFi Network Application/OS Server Easy Installation Script.

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                        List of supported Distributions/Operating Systems                                                                        #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

#                       | Ubuntu Precise Pangolin ( 12.04 )
#                       | Ubuntu Trusty Tahr ( 14.04 )
#                       | Ubuntu Utopic Unicorn ( 14.10 )
#                       | Ubuntu Vivid Vervet ( 15.04 )
#                       | Ubuntu Wily Werewolf ( 15.10 )
#                       | Ubuntu Xenial Xerus ( 16.04 )
#                       | Ubuntu Yakkety Yak ( 16.10 )
#                       | Ubuntu Zesty Zapus ( 17.04 )
#                       | Ubuntu Artful Aardvark ( 17.10 )
#                       | Ubuntu Bionic Beaver ( 18.04 )
#                       | Ubuntu Cosmic Cuttlefish ( 18.10 )
#                       | Ubuntu Disco Dingo ( 19.04 )
#                       | Ubuntu Eoan Ermine ( 19.10 )
#                       | Ubuntu Focal Fossa ( 20.04 )
#                       | Ubuntu Groovy Gorilla ( 20.10 )
#                       | Ubuntu Hirsute Hippo ( 21.04 )
#                       | Ubuntu Impish Indri ( 21.10 )
#                       | Ubuntu Jammy Jellyfish ( 22.04 )
#                       | Ubuntu Kinetic Kudu ( 22.10 )
#                       | Ubuntu Lunar Lobster ( 23.04 )
#                       | Ubuntu Mantic Minotaur ( 23.10 )
#                       | Ubuntu Noble Numbat ( 24.04 )
#                       | Ubuntu Oracular Oriole ( 24.10 )
#                       | Ubuntu Plucky Puffin ( 25.04 )
#                       | Ubuntu Questing Quokka ( 25.10 )
#                       | Ubuntu Resolute Raccoon ( 26.04 )
#                       | Debian Jessie ( 8 )
#                       | Debian Stretch ( 9 )
#                       | Debian Buster ( 10 )
#                       | Debian Bullseye ( 11 )
#                       | Debian Bookworm ( 12 )
#                       | Debian Trixie ( 13 )
#                       | Debian Forky ( 14 )
#                       | Linux Mint 13 ( Maya )
#                       | Linux Mint 17 ( Qiana | Rebecca | Rafaela | Rosa )
#                       | Linux Mint 18 ( Sarah | Serena | Sonya | Sylvia )
#                       | Linux Mint 19 ( Tara | Tessa | Tina | Tricia )
#                       | Linux Mint 20 ( Ulyana | Ulyssa | Uma | Una )
#                       | Linux Mint 21 ( Vanessa | Vera | Victoria | Virginia )
#                       | Linux Mint 22 ( Wilma | Xia | Zara | Zena )
#                       | Linux Mint 2 ( Betsy )
#                       | Linux Mint 3 ( Cindy )
#                       | Linux Mint 4 ( Debbie )
#                       | Linux Mint 5 ( Elsie )
#                       | Linux Mint 6 ( Faye )
#                       | Linux Mint 7 ( Gigi )
#                       | MX Linux 18 ( Continuum )
#                       | BunsenLabs Linux ( Boron | Beryllium | Lithium | Helium )
#                       | Devuan ( ASCII | Beowulf | Chimaera | Daedalus | Excalibur | Freia )
#                       | Progress-Linux ( Engywuck )
#                       | Parrot OS ( Lory )
#                       | Elementary OS
#                       | Kaisen Linux
#                       | Deepin Linux ( Beige )
#                       | Pearl Linux ( Scootski | Cade | Preslee )
#                       | PikaOS ( Nest )
#                       | SparkyLinux ( Tyche | Nibiru | Po Tolo | Orion Belt | The Seven Sisters | Tiamat )
#                       | PureOS ( Crimson | Byzantium | Amber )
#                       | UnionTech OS Desktop 20
#                       | Kali Linux ( rolling )
#                       | Trisquel ( Toutatis | Belenos | Flidas | Etiona | Nabia | Aramo | Ecne )
#                       | Netrunner ( Shockworm | Vapour | Tiger | Xenon )
#                       | Pardus ( Yirmibes | Yirmiuc )

###################################################################################################################################################################################################

# Script                | UniFi Network/OS Easy Installation Script
# Version               | 9.0.2
# Script Version        | 9.0.9
# Application version   | 6.5.55
# Debian Repo version   | 6.5.55-16678-1
# UOS Server version    | 5.0.6
# Author                | Glenn Rietveld
# Email                 | glennrietveld8@hotmail.nl
# Website               | https://GlennR.nl

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                           Color Codes                                                                                           #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

RESET='\033[0m'
YELLOW='\033[1;33m'
WHITE_R='\033[39m' # Same as GRAY_R for terminals with white background.
GRAY_R='\033[39m'
RED='\033[1;31m' # Light Red.
GREEN='\033[1;32m' # Light Green.

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                           Start Checks                                                                                          #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

header() {
  if [[ "${script_option_debug}" != 'true' ]]; then clear; clear; fi
  echo -e "${GREEN}#########################################################################${RESET}\\n"
}

header_red() {
  if [[ "${script_option_debug}" != 'true' ]]; then clear; clear; fi
  echo -e "${RED}#########################################################################${RESET}\\n"
}

# Exit script if not using bash.
if [ -z "$BASH_VERSION" ]; then
  script_name="$(basename "$0")"
  clear; clear; printf "\033[1;31m#########################################################################\033[0m\n"
  printf "\n\033[39m#\033[0m The script requires to be ran with bash, run the command printed below... \\n"
  printf "\033[39m#\033[0m bash %s %s\n\n" "${script_name}" "$*"
  exit 1
fi

# Check for root (SUDO).
if [[ "$EUID" -ne 0 ]]; then
  header_red
  echo -e "${GRAY_R}#${RESET} The script need to be run as root...\\n\\n"
  echo -e "${GRAY_R}#${RESET} For Ubuntu based systems run the command below to login as root"
  echo -e "${GREEN}#${RESET} sudo -i\\n"
  echo -e "${GRAY_R}#${RESET} For Debian based systems run the command below to login as root"
  echo -e "${GREEN}#${RESET} su\\n\\n"
  exit 1
fi

# Unset environment variables.
if [[ -n "${PAGER}" ]]; then unset PAGER; fi
if [[ -n "${LESS}" ]]; then unset LESS; fi

if [[ "$(ps -p 1 -o comm=)" != 'systemd' ]]; then
  header_red
  echo -e "${YELLOW}#${RESET} This setup appears to be using \"$(ps -p 1 -o comm=)\" instead of \"systemd\"..."
  echo -e "${YELLOW}#${RESET} The script has limited functionality on \"$(ps -p 1 -o comm=)\" systems and UniFi OS Server is not supported..."
  limited_functionality="true"
  sleep 10
fi

if ! "$(which dpkg)" -l unifi-core 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
  if ! env | grep "LC_ALL\\|LANG" | grep -iq "en_US\\|C.UTF-8\\|en_GB.UTF-8" || locale 2> /dev/null | grep -iq "Cannot set" 2> /dev/null; then
    header
    echo -e "${GRAY_R}#${RESET} Your language is not set to English ( en_US ), the script will temporarily set the language to English."
    echo -e "${GRAY_R}#${RESET} Information: This is done to prevent issues in the script.."
    original_lang="$LANG"
    original_lcall="$LC_ALL"
    if [[ -e "/etc/locale.gen" ]]; then
      sed -i '/^#.*en_US.UTF-8 UTF-8/ s/^#.*\(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen 2> /dev/null
      if ! grep -q '^en_US.UTF-8 UTF-8' /etc/locale.gen; then echo 'en_US.UTF-8 UTF-8' &>> /etc/locale.gen; fi
    fi
    if ! locale -a 2> /dev/null | grep -iq "en_US.UTF-8"; then locale-gen en_US.UTF-8 &> /dev/null; fi
    if locale -a 2> /dev/null | grep -iq "^C.UTF-8$"; then eus_lts="C.UTF-8"; elif locale -a 2> /dev/null | grep -iq "^en_US.UTF-8$"; then eus_lts="en_US.UTF-8"; else eus_lts="en_US.UTF-8"; fi
    export LANG="${eus_lts}" &> /dev/null
    export LC_ALL=C &> /dev/null
    set_lc_all="true"
    sleep 3
  fi
fi

cleanup_codename_mismatch_repos() {
  get_distro
  if [[ -n "$(command -v jq)" ]]; then
    list_of_distro_versions="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/list-versions?list-all" 2> /dev/null | jq -r '.[]' 2> /dev/null)"
  else
    list_of_distro_versions="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/list-versions?list-all" 2> /dev/null | sed -e 's/\[//g' -e 's/\]//g' -e 's/ //g' -e 's/,//g' | grep .)"
  fi
  found_codenames=()
  if [[ -f "/etc/apt/sources.list.d/glennr-install-script.list" ]]; then
    while IFS= read -r line; do
      while read -r codename; do
        if [[ "$line" == *"$codename"* && "$codename" != "$os_codename" ]]; then
          found_codenames+=("$codename")
        fi
      done <<< "${list_of_distro_versions}"
    done < <(grep -v '^[[:space:]]*$' "/etc/apt/sources.list.d/glennr-install-script.list")
    IFS=$'\n' read -r -d '' -a unique_found_codenames < <(printf "%s\n" "${found_codenames[@]}" | sort -u && printf '\0')
    if [[ "${#unique_found_codenames[@]}" -gt "0" ]]; then
      for codename in "${unique_found_codenames[@]}"; do
        sed -i "/$codename/d" "/etc/apt/sources.list.d/glennr-install-script.list" >/dev/null 2>&1
      done
    fi
  fi
  if [[ -f "/etc/apt/sources.list.d/glennr-install-script.sources" ]]; then
    while IFS= read -r line; do
      while read -r codename; do
        if [[ "$line" == *"$codename"* && "$codename" != "$os_codename" ]]; then
          found_codenames+=("$codename")
        fi
      done <<< "${list_of_distro_versions}"
    done < <(grep -v '^[[:space:]]*$' "/etc/apt/sources.list.d/glennr-install-script.sources")
    IFS=$'\n' read -r -d '' -a unique_found_codenames < <(printf "%s\n" "${found_codenames[@]}" | sort -u && printf '\0')
    if [[ "${#unique_found_codenames[@]}" -gt "0" ]]; then
      for codename in "${unique_found_codenames[@]}"; do
        entry_block_start_line="$(awk '!/^#/ && /Types:/ { types_line=NR } /'"${codename}"'/ && !/^#/ && !seen[types_line]++ { print types_line }' "/etc/apt/sources.list.d/glennr-install-script.sources" | head -n1)"
        entry_block_end_line="$(awk -v start_line="$entry_block_start_line" 'NR > start_line && NF == 0 { print NR-1; exit } END { if (NR > start_line && NF > 0) print NR }' "/etc/apt/sources.list.d/glennr-install-script.sources")"
        sed -i "${entry_block_start_line},${entry_block_end_line}d" "/etc/apt/sources.list.d/glennr-install-script.sources" &>/dev/null
      done
    fi
  fi
}

cleanup_unifi_repos() {
  repo_file_patterns=( "ui.com\\/downloads" "ubnt.com\\/downloads" )
  while read -r repo_file; do
    for pattern in "${repo_file_patterns[@]}"; do
      sed -e "/${pattern}/ s/^#*/#/g" -i "${repo_file}"
    done
  done < <(find /etc/apt/ -type f -name "*.list" -exec grep -ilE 'ui.com|ubnt.com' {} +)
  # Handle .sources files if using DEB822 format
  while read -r sources_file; do
    for pattern in "${repo_file_patterns[@]}"; do
      entry_block_start_line="$(awk '!/^#/ && /Types:/ { types_line=NR } /'"${pattern}"'/ && !/^#/ && !seen[types_line]++ { print types_line }' "${sources_file}" | head -n1)"
      entry_block_end_line="$(awk -v start_line="$entry_block_start_line" 'NR > start_line && NF == 0 { print NR-1; exit } END { if (NR > start_line && NF > 0) print NR }' "${sources_file}")"
      sed -i "${entry_block_start_line},${entry_block_end_line}s/^\([^#]\)/# \1/" "${sources_file}" &>/dev/null
    done
  done < <(find /etc/apt/sources.list.d/ -type f -name "*.sources")
}
if [[ "$(find /etc/apt/ -type f \( -name "*.sources" -o -name "*.list" \) -exec grep -lE '^[^#]*\b(ui|ubnt)\.com' {} + | wc -l)" -gt "1" ]]; then cleanup_unifi_repos; fi

check_dns() {
  system_dns_servers="($(grep -s '^nameserver' /etc/resolv.conf /run/systemd/resolve/resolv.conf | awk '{print $2}'))"
  local domains=("mongodb.com" "repo.mongodb.org" "pgp.mongodb.com" "ubuntu.com" "ui.com" "ubnt.com" "glennr.nl" "raspbian.org" "adoptium.org")
  local target_domain="$1"
  if [[ -n "${target_domain}" ]]; then domains=("${target_domain}"); fi
  if command -v host &> /dev/null; then
    dns_check_command="host"
  elif command -v ping &> /dev/null; then
    dns_check_command="ping -c 1 -W2"
  else
    echo -e "$(date +%F-%T.%6N) | No DNS check command available (host or ping)..." &>> "${eus_dir}/logs/dns-check.log"
    return 1
  fi
  if [[ -n "${dns_check_command}" ]]; then
    for domain in "${domains[@]}"; do
      if ! ${dns_check_command} "${domain}" &> /dev/null; then
        echo -e "$(date +%F-%T.%6N) | Failed to resolve ${domain}..." &>> "${eus_dir}/logs/dns-check.log"
        local dns_servers=("1.1.1.1" "8.8.8.8")
        for dns_server in "${dns_servers[@]}"; do
          if ! grep -qF "${dns_server}" /etc/resolv.conf; then
            if echo "nameserver ${dns_server}" | tee -a /etc/resolv.conf >/dev/null; then
              echo -e "$(date +%F-%T.%6N) | Added ${dns_server} to /etc/resolv.conf..." &>> "${eus_dir}/logs/dns-check.log"
              if ${dns_check_command} "${domain}" &> /dev/null; then
                echo -e "$(date +%F-%T.%6N) | Successfully resolved ${domain} after adding ${dns_server}." &>> "${eus_dir}/logs/dns-check.log"
                return 0
              fi
            fi
          fi
        done
        return 1
      fi
    done
  fi
  return 0
}

check_for_block_page() {
  local code loc domain=""
  if command -v curl >/dev/null 2>&1; then
    read -r code loc < <(curl -ksS -o /dev/null --max-redirs 0 -w '%{http_code} %{redirect_url}\n' "https://api.glennr.nl/api/ssl-check")
  elif command -v wget >/dev/null 2>&1; then
    local headers
    headers="$(wget --no-check-certificate --max-redirect=0 --server-response -qO- "https://api.glennr.nl/api/ssl-check" 2>&1)"
    code="$(grep -m1 'HTTP/' <<< "$headers" | awk '{print $2}')"
    loc="$(grep -i '^  Location:' <<< "$headers" | head -n1 | awk '{print $2}' | tr -d '\r')"
  else
    echo -e "$(date +%F-%T.%6N) | Neither curl nor wget is available..." &>> "${eus_dir}/logs/block-page-check.log"
    return 1
  fi
  loc="${loc%$'\r'}"
  if [[ "${loc}" == http*://* ]]; then
    domain="${loc#*://}"
    domain="${domain%%/*}"
  fi
  if [[ "${code}" =~ ^30(1|2|7|8)$ && -n "${domain}" && ! "${domain}" =~ (^|\.)glennr\.nl$ ]]; then
    echo -e "$(date +%F-%T.%6N) | Traffic is being redirected/forwarded to \"${loc}\" with HTTP code ${code}..." &>> "${eus_dir}/logs/block-page-check.log"
    if [[ "${script_option_skip}" != "true" ]]; then
      header_red
      printf '%b#%b Your setup/firewall appears to be blocking or redirecting calls to "*.glennr.nl"...\n' "${RED}" "${RESET}"
      printf '%b#%b Traffic is being redirected/forwarded to the location below via HTTP code %s...\n' "${RED}" "${RESET}" "${code}"
      printf '%b#%b destination: %s\n\n' "${RED}" "${RESET}" "${loc}"
      read -rp '# Did you add "*.glennr.nl" to the allow/exclusion list? (Y/n) ' yes_no
      case "$yes_no" in
        [Nn]*) header_red; printf '# The script will continue, but you may experience unexpected results due to blocked calls...\n'; sleep 5;;
        *) return;;
      esac
      start_script_header
    fi
  fi
}

check_repository_key_permissions() {
  if [[ "$(stat -c %a "${repository_key_location}")" != "644" ]]; then
    if chmod 644 "${repository_key_location}" &>> "${eus_dir}/logs/update-repository-key-permissions.log"; then
      echo -e "$(date +%F-%T.%6N) | Successfully updated the permissions for ${repository_key_location} to 644!" &>> "${eus_dir}/logs/update-repository-key-permissions.log"
    else
      echo -e "$(date +%F-%T.%6N) | Failed to set the permissions for ${repository_key_location} to 644..." &>> "${eus_dir}/logs/update-repository-key-permissions.log"
    fi
  fi
  unset repository_key_location
}

check_apt_listbugs() {
  if "$(which dpkg)" -l apt-listbugs 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui" && [[ -e "/etc/apt/apt.conf.d/10apt-listbugs" && "${apt_listbugs_deactivated}" != 'true' ]]; then
    IFS=$'\n' read -r -d '' -a lines < <(grep -n -v '^//' /etc/apt/apt.conf.d/10apt-listbugs | awk -F':' '{print $1}' && printf '\0')
    for line in "${lines[@]}"; do sed -i "${line}s/^/\/\/ EUS Disabled \/\/ /" /etc/apt/apt.conf.d/10apt-listbugs 2> /dev/null; done
    apt_listbugs_deactivated="true"
  elif [[ "${apt_listbugs_deactivated}" == 'true' ]]; then
    sed -i 's/^\/\/ EUS Disabled \/\/ //' /etc/apt/apt.conf.d/10apt-listbugs 2> /dev/null
  fi
}

validate_http_proxy() {
  local proxy="$1"
  if [[ "${proxy}" =~ ^(http|https):// ]]; then
    local host_port="${proxy#*://}"
    local host="${host_port%%:*}"
    local port="${host_port##*:}"
    if command -v getent >/dev/null 2>&1; then
      if ! getent hosts "${host}" >/dev/null; then
        echo -e "$(date +%F-%T.%6N) | Invalid proxy detected: ${proxy} (Unresolvable hostname via getent)" &>> "${eus_dir}/logs/http-proxy.log"
        return 1
      fi
    else
      if command -v host >/dev/null 2>&1; then
        if ! host "${host}" >/dev/null 2>&1; then
          echo -e "$(date +%F-%T.%6N) | Invalid proxy detected: ${proxy} (Unresolvable hostname via host)" &>> "${eus_dir}/logs/http-proxy.log"
          return 1
        fi
      else
        echo -e "$(date +%F-%T.%6N) | Warning: Neither getent nor host found, skipping hostname validation." &>> "${eus_dir}/logs/http-proxy.log"
      fi
    fi
    if ! [[ "${port}" =~ ^[0-9]+$ ]]; then
      echo -e "$(date +%F-%T.%6N) | Invalid proxy detected: ${proxy} (Invalid port: ${port})" &>> "${eus_dir}/logs/http-proxy.log"
      return 1
    fi
    if (echo > "/dev/tcp/${host}/${port}") 2>/dev/null; then
      return 0 # Proxy is valid
    else
      echo -e "$(date +%F-%T.%6N) | Invalid proxy detected: ${proxy} (Port unreachable)" &>> "${eus_dir}/logs/http-proxy.log"
      return 1
    fi
  else
    echo -e "$(date +%F-%T.%6N) | Invalid proxy detected: ${proxy} (Incorrect format)" &>> "${eus_dir}/logs/http-proxy.log"
    return 1
  fi
}

locate_http_proxy() {
  env_proxies="$(grep -sE "^[^#]*http_proxy|^[^#]*https_proxy" "/etc/environment" 2> /dev/null | awk -F '=' '{print $2}' | tr -d '"')"
  profile_proxies="$(find /etc/profile.d/ -type f -exec sh -c 'grep -E "^[^#]*http_proxy|^[^#]*https_proxy" "$1" | awk -F "=" "{print \$2}" | tr -d "\"" ' _ {} \;)"
  apt_proxies="$(grep -siE "^[^#]*proxy" /etc/apt/apt.conf /etc/apt/apt.conf.d/* 2> /dev/null | awk -F '"' '{print $2}')"
  wget_proxies="$(grep -sE "^[^#]*http_proxy|^[^#]*https_proxy" "/etc/wgetrc" 2> /dev/null | awk -F '=' '{print $2}' | tr -d '"')"
  if [[ -n "${env_proxies}" ]] || [[ -n "${profile_proxies}" ]] || [[ -n "${apt_proxies}" ]] || [[ -n "${wget_proxies}" ]]; then
    mapfile -t all_proxies < <(printf "%s\n" "${env_proxies}" "${profile_proxies}" "${apt_proxies}" "${wget_proxies}" | sed 's:/*$::' | sort -u | grep -v '^$')
    valid_proxies=()
    for proxy in "${all_proxies[@]}"; do
      if validate_http_proxy "${proxy}"; then
        valid_proxies+=("${proxy}")
      fi
    done
    http_proxy="${valid_proxies[-1]}"
    if [[ -n "$(command -v jq)" && -e "${eus_dir}/db/db.json" ]]; then
      if [[ "$(dpkg-query --showformat='${version}' --show jq 2> /dev/null | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
        json_proxies="$(printf '%s\n' "${valid_proxies[@]}" | jq -R -s 'split("\n") | map(select(length > 0))')"
        jq --argjson proxies "$json_proxies" '.database."http-proxy" = $proxies' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
      else
        json_proxies="$(printf '%s\n' "${valid_proxies[@]}" | awk '{ printf "\"%s\",\n", $0 }' | sed '$s/,$//' | sed -e '1s/^/[/' -e '$s/$/]/')"
        jq '.database["http-proxy"] = '"$json_proxies"'' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
      fi
      eus_database_move
    fi
    if [[ -n "${http_proxy}" ]]; then noproxy_curl_argument=('--noproxy' '127.0.0.1,localhost'); fi
    if [[ -z "${env_proxies}" && -n "${http_proxy}" ]]; then curl_proxy_arg=('--proxy' "${http_proxy}"); fi
  fi
}

set_curl_arguments() {
  locate_http_proxy
  if [[ "$(command -v jq)" ]]; then ssl_check_status="$(curl "${curl_proxy_arg[@]}" --silent "https://api.glennr.nl/api/ssl-check" 2> /dev/null | jq -r '.status' 2> /dev/null)"; else ssl_check_status="$(curl "${curl_proxy_arg[@]}" --silent "https://api.glennr.nl/api/ssl-check" 2> /dev/null | grep -oP '(?<="status":")[^"]+')"; fi
  if [[ "${ssl_check_status}" != "OK" ]]; then
    if [[ -e "/etc/ssl/certs/" ]]; then
      if [[ "$(command -v jq)" ]]; then ssl_check_status="$(curl "${curl_proxy_arg[@]}" --silent --capath /etc/ssl/certs/ "https://api.glennr.nl/api/ssl-check" 2> /dev/null | jq -r '.status' 2> /dev/null)"; else ssl_check_status="$(curl "${curl_proxy_arg[@]}" --silent --capath /etc/ssl/certs/ "https://api.glennr.nl/api/ssl-check" 2> /dev/null | grep -oP '(?<="status":")[^"]+')"; fi
      if [[ "${ssl_check_status}" == "OK" ]]; then curl_args="--capath /etc/ssl/certs/"; fi
    fi
    if [[ -z "${curl_args}" && "${ssl_check_status}" != "OK" ]]; then curl_args="--insecure"; fi
  fi
  if [[ -z "${curl_args}" ]]; then curl_args="--silent"; elif [[ "${curl_args}" != *"--silent"* ]]; then curl_args+=" --silent"; fi
  if [[ -n "${curl_proxy_arg[*]}" ]]; then curl_args+=" ${curl_proxy_arg[*]}"; fi
  if [[ "${curl_args}" != *"--show-error"* ]]; then curl_args+=" --show-error"; fi
  if [[ "${curl_args}" != *"--retry"* ]]; then curl_args+=" --retry 3"; fi
  IFS=' ' read -r -a curl_argument <<< "${curl_args}"
  trimmed_args="${curl_args//--silent/}"
  trimmed_args="$(echo "$trimmed_args" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
  IFS=' ' read -r -a nos_curl_argument <<< "${trimmed_args}"
}
if [[ "$(command -v curl)" ]]; then set_curl_arguments; fi

check_unifi_folder_permissions() {
  while read -r target; do
    echo -e "\\nPermissions for target: ${target}" &>> "/tmp/EUS/support/${check_unifi_folder_permissions_state}-folder-permisisons"
    ls -lL "${target}" &>> "/tmp/EUS/support/${check_unifi_folder_permissions_state}-folder-permisisons"
    if [[ -d "${target}" ]]; then
      ls -l "${target}"/* &>> "/tmp/EUS/support/${check_unifi_folder_permissions_state}-folder-permisisons"
    fi
  done < <(find "/usr/lib/unifi" -maxdepth 1)
}

check_docker_setup() {
  if [[ -f /.dockerenv ]] || grep -sq '/docker/' /proc/1/cgroup || { command -v pgrep &>/dev/null && (pgrep -f "^dockerd" &>/dev/null || pgrep -f "^containerd" &>/dev/null); }; then docker_setup="true"; container_system="true"; else docker_setup="false"; fi
  if [[ -n "$(command -v jq)" && -e "${eus_dir}/db/db.json" ]]; then
    if [[ "$(dpkg-query --showformat='${version}' --show jq 2> /dev/null | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
      jq '."database" += {"docker-container": "'"${docker_setup}"'"}' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
    else
      jq --arg docker_setup "$docker_setup" '.database = (.database + {"docker-container": $docker_setup})' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
    fi
    eus_database_move
  fi
}

check_lxc_setup() {
  if grep -sqE '(/lxc/|/lxd/)' /proc/1/cgroup 2>/dev/null || tr '\0' '\n' </proc/1/environ 2>/dev/null | grep -sqE '^container=(lxc|lxd)$'; then lxc_setup="true"; container_system="true"; else lxc_setup="false"; fi
  if [[ -n "$(command -v jq)" && -e "${eus_dir}/db/db.json" ]]; then
    if [[ "$(dpkg-query --showformat='${version}' --show jq 2> /dev/null | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
      jq '."database" += {"lxc-container": "'"${lxc_setup}"'"}' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
    else
      jq --arg lxc_setup "$lxc_setup" '.database = (.database + {"lxc-container": $lxc_setup})' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
    fi
    eus_database_move
  fi
}

check_wsl_setup() {
  if grep -qi microsoft /proc/version; then wsl_setup="true"; container_system="true"; else wsl_setup="false"; fi
  if [[ -n "$(command -v jq)" && -e "${eus_dir}/db/db.json" ]]; then
    if [[ "$(dpkg-query --showformat='${version}' --show jq 2> /dev/null | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
      jq '."database" += {"wsl-container": "'"${wsl_setup}"'"}' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
    else
      jq --arg wsl_setup "$wsl_setup" '.database = (.database + {"wsl-container": $wsl_setup})' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
    fi
    eus_database_move
  fi
}

update_eus_db() {
  if [[ -n "$(command -v jq)" && -e "${eus_dir}/db/db.json" ]]; then
    if [[ -n "${script_local_version_dots}" ]]; then
      if [[ "$(dpkg-query --showformat='${version}' --show jq 2> /dev/null | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
        jq '.scripts."'"${script_name}"'" |= if .["versions-ran"] | index("'"${script_local_version_dots}"'") | not then .["versions-ran"] += ["'"${script_local_version_dots}"'"] else . end' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
      else
        jq --arg script_name "$script_name" --arg script_local_version_dots "$script_local_version_dots" '.scripts[$script_name] |= (if (.["versions-ran"] | map(select(. == $script_local_version_dots)) | length == 0) then .["versions-ran"] += [$script_local_version_dots] else . end)' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
      fi
      eus_database_move
    fi
    if [[ -z "${abort_reason}" ]]; then
      if [[ "$(dpkg-query --showformat='${version}' --show jq 2> /dev/null | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
        script_success="$(jq -r '.scripts."'"${script_name}"'".success' "${eus_dir}/db/db.json")"
      else
        script_success="$(jq --arg script_name "$script_name"  -r '.scripts[$script_name]["success"]' "${eus_dir}/db/db.json")"
      fi
      ((script_success=script_success+1))
      if [[ "$(dpkg-query --showformat='${version}' --show jq 2> /dev/null | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
        jq --arg script_success "${script_success}" '."scripts"."'"${script_name}"'" += {"success": "'"${script_success}"'"}' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
      else
        jq --arg script_name "$script_name" --arg script_success "$script_success" '.scripts[$script_name] += {"success": $script_success}' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
      fi
      eus_database_move
    fi
    if [[ "${update_at_support_file}" != 'true' ]]; then
      if [[ "$(dpkg-query --showformat='${version}' --show jq 2> /dev/null | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
        script_total_runs="$(jq -r '.scripts."'"${script_name}"'"."total-runs"' "${eus_dir}/db/db.json")"
      else
        script_total_runs="$(jq --arg script_name "$script_name"  -r '.scripts[$script_name]["total-runs"]' "${eus_dir}/db/db.json")"
      fi
      ((script_total_runs=script_total_runs+1))
      if [[ "$(dpkg-query --showformat='${version}' --show jq 2> /dev/null | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
        jq --arg script_total_runs "${script_total_runs}" '."scripts"."'"${script_name}"'" += {"total-runs": "'"${script_total_runs}"'"}' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
      else
        jq --arg script_name "$script_name" --arg script_total_runs "$script_total_runs" '.scripts[$script_name] |= (. + {"total-runs": $script_total_runs})' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
      fi
      eus_database_move
    fi
    if [[ "${update_at_start_script}" == 'true' ]]; then
      if [[ "$(dpkg-query --showformat='${version}' --show jq 2> /dev/null | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
        jq '."scripts"."'"${script_name}"'" += {"last-run": "'"$(date +%s)"'"}' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
      else
        jq --arg script_name "$script_name" --arg last_run "$(date +%s)" '.scripts[$script_name] |= (. + {"last-run": $last_run})' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
      fi
      eus_database_move
      unset update_at_start_script
    fi
    json_system_dns_servers="$(echo "$system_dns_servers" | sed 's/[()]//g' | tr ' ' '\n' | jq -R . | jq -s . | jq -c .)"
    if [[ "$(dpkg-query --showformat='${version}' --show jq 2> /dev/null | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
      jq --argjson dns "$json_system_dns_servers" '.database["name-servers"] = $dns' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
    else
      jq '.database["name-servers"] = '"$json_system_dns_servers"'' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
    fi
    eus_database_move
    unset update_at_support_file
  fi
  check_docker_setup
  check_lxc_setup
  check_wsl_setup
  locate_http_proxy
}

eus_database_move() {
  if [[ -z "${eus_database_move_file}" ]]; then eus_database_move_file="${eus_dir}/db/db.json"; eus_database_move_log_file="${eus_dir}/logs/eus-database-management.log"; fi
  if [[ -s "${eus_database_move_file}.tmp" ]] && jq . "${eus_database_move_file}.tmp" >/dev/null 2>&1; then
    mv "${eus_database_move_file}.tmp" "${eus_database_move_file}" &>> "${eus_database_move_log_file}"
  else
    if ! [[ -s "${eus_database_move_file}.tmp" ]]; then
      echo -e "$(date +%F-%T.%6N) | \"${eus_database_move_file}.tmp\" is empty." >> "${eus_database_move_log_file}"
    else
      echo -e "$(date +%F-%T.%6N) | \"${eus_database_move_file}.tmp\" does not contain valid JSON. Contents:" >> "${eus_database_move_log_file}"
      cat "${eus_database_move_file}.tmp" >> "${eus_database_move_log_file}"
    fi
  fi
  unset eus_database_move_file
}

get_timezone() {
  if command -v timedatectl >/dev/null 2>&1; then timezone="$(timedatectl | grep -i 'Time zone' | awk '{print $3}')"; if [[ -n "$timezone" ]]; then return; fi; fi
  if [[ -L /etc/localtime ]]; then timezone="$(readlink /etc/localtime | awk -F'/zoneinfo/' '{print $2}')"; if [[ -n "$timezone" ]]; then return; fi; fi
  if [[ -f /etc/timezone ]]; then timezone="$(cat /etc/timezone)"; if [[ -n "$timezone" ]]; then return; fi; fi
  timezone="$(date +"%Z")"; if [[ -n "$timezone" ]]; then return; fi
}

support_file() {
  if [[ "${update_at_support_file}" != 'true' ]]; then update_at_support_file="true"; update_eus_db; fi
  get_timezone
  if [[ "${set_lc_all}" == 'true' ]]; then if [[ -n "${original_lang}" ]]; then export LANG="${original_lang}"; else unset LANG; fi; if [[ -n "${original_lcall}" ]]; then export LC_ALL="${original_lcall}"; else unset LC_ALL; fi; fi
  if [[ "${script_option_support_file}" == 'true' ]]; then header; abort_reason="Support File script option was issued"; fi
  echo -e "${GRAY_R}#${RESET} Creating support file..."
  eus_directory_location="/tmp/EUS"
  eus_create_directories "support"
  check_unifi_folder_permissions_state="abort-install"
  if [[ -d "/usr/lib/unifi" ]]; then check_unifi_folder_permissions; fi
  if "$(which dpkg)" -l lsb-release 2> /dev/null | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then lsb_release -a &> "/tmp/EUS/support/lsb-release"; else cat /etc/os-release &> "/tmp/EUS/support/os-release"; fi
  if [[ -n "$(command -v jq)" && "$(dpkg-query --showformat='${version}' --show jq 2> /dev/null | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
    df -hP | awk 'BEGIN {print"{\"disk-usage\":["}{if($1=="Filesystem")next;if(a)print",";print"{\"mount\":\""$6"\",\"size\":\""$2"\",\"used\":\""$3"\",\"avail\":\""$4"\",\"use%\":\""$5"\"}";a++;}END{print"]}";}' | jq &> "/tmp/EUS/support/disk-usage.json"
  else
    df -h &> "/tmp/EUS/support/df"
  fi
  uname -a &> "/tmp/EUS/support/uname-results"
  {
    echo -e "-----( lscpu )----- \n"; lscpu 2> /dev/null
    echo -e "-----( /proc/cpuinfo )----- \n"; cat /proc/cpuinfo 2> /dev/null
  } >> "/tmp/EUS/support/cpu-details.log"
  dmesg &> "/tmp/EUS/support/dmesg.log"
  {
    echo -e "-----( locale )----- \n"; locale 2> /dev/null
    echo -e "-----( locale --all-locales )----- \n"; locale --all-locales 2> /dev/null
    echo -e "-----( cat /etc/default/locale )----- \n"; cat /etc/default/locale 2> /dev/null
    echo -e "-----( cat /etc/locale.gen )----- \n"; cat /etc/locale.gen 2> /dev/null
    echo -e "-----( cat /etc/locale.alias )----- \n"; cat /etc/locale.alias 2> /dev/null
  } >> "/tmp/EUS/support/locale-results.log"
  {
    echo -e "-----( env )----- \n"; env 2> /dev/null
    echo -e "-----( cat /etc/environment )----- \n"; cat /etc/environment 2> /dev/null
  } >> "/tmp/EUS/support/environment-results.log"
  {
    echo -e "-----( --get-selections )----- \n"; update-alternatives --get-selections 2> /dev/null
    echo -e "-----( --display java )----- \n"; update-alternatives --display java 2> /dev/null
    echo -e "-----( JAVA_HOME results )----- \n"; grep -r 'JAVA_HOME' /etc/ 2> /dev/null
    echo -e "-----( readlink java )----- \n"; readlink -f /usr/bin/java 2> /dev/null
  } >> "/tmp/EUS/support/java-details.log"
  grep -is '^unifi:' /etc/passwd /etc/group &> "/tmp/EUS/support/unifi-user-group-results"
  find /usr/sbin -name "unifi*" -type f -print0 | xargs -0 -I {} sh -c 'echo "\n------[ {} ]------\n"; cat "{}"; echo;' &> "/tmp/EUS/support/unifi-helper-results"
  ps -p $$ -o command= &> "/tmp/EUS/support/script-usage"
  echo "$PATH" &> "/tmp/EUS/support/PATH"
  cp "${script_location}" "/tmp/EUS/support/${script_file_name}" &> /dev/null
  "$(which dpkg)" -l | grep "mongo\\|oracle\\|openjdk\\|unifi\\|temurin" &> "/tmp/EUS/support/unifi-packages-list"
  "$(which dpkg)" -l &> "/tmp/EUS/support/dpkg-packages-list"
  journalctl -u unifi -p debug --since "1 week ago" --no-pager &> "/tmp/EUS/support/ujournal.log"
  journalctl --since yesterday &> "/tmp/EUS/support/journal.log"
  if [[ -e "/tmp/EUS/support/no-disk-space-info" ]]; then rm --force "/tmp/EUS/support/no-disk-space-info" &> /dev/null; fi
  while read -r ood_dir; do
    {
      echo -e "-----( du -sh ${ood_dir} )----- \n" &>> "/tmp/EUS/support/no-disk-space-info"
      du -sh "${ood_dir}"
      echo -e "-----( df -h ${ood_dir} )----- \n" &>> "/tmp/EUS/support/no-disk-space-info"
      df -h "${ood_dir}"
      echo -e "-----( df -hi ${ood_dir} )----- \n" &>> "/tmp/EUS/support/no-disk-space-info"
      df -hi "${ood_dir}"
    }	&>> "/tmp/EUS/support/no-disk-space-info"
  done < <(grep -i "no space left on device" "${eus_dir}"/logs/* | grep -oP '(?<=to )/[^: ]+' | sort -u)
  if [[ "$(command -v timedatectl)" ]]; then
    {
      echo -e "-----( timedatectl )----- \n"
      if timedatectl --help | grep -ioq "\--all" 2> /dev/null; then timedatectl --all --no-pager 2> /dev/null; else timedatectl --no-pager 2> /dev/null; fi
      if timedatectl --help | grep -ioq "show-timesync" 2> /dev/null; then echo -e "\n-----( timedatectl show-timesync )----- \n"; timedatectl show-timesync --no-pager 2> /dev/null; fi
      if timedatectl --help | grep -ioq "timesync-status" 2> /dev/null; then echo -e "\n-----( timedatectl timesync-status )----- \n"; timedatectl timesync-status --no-pager 2> /dev/null; fi
    } >> "/tmp/EUS/support/timedatectl"
  fi
  ps axjf &> "/tmp/EUS/support/process-tree"
  if [[ "$(command -v netstat)" ]]; then netstat -tulp &> "/tmp/EUS/support/netstat-results.log"; fi
  if [[ "$(command -v ss)" ]]; then ss -ltnp &> "/tmp/EUS/support/ss-results.log"; fi
  {
    echo -e "-----( Is systemd PID 1? )----- \n"; ps -p1 -o comm= 2> /dev/null
    echo -e "-----( Can we talk to systemd? )----- \n"; systemctl is-system-running 2> /dev/null
    echo -e "-----( Is logind up? )----- \n"; systemctl status systemd-logind 2> /dev/null
    echo -e "-----( Does loginctl work at all? )----- \n"; loginctl seat-status 2>/dev/null || loginctl 2>/dev/null || echo "loginctl not working" 2> /dev/null
    echo -e "-----( Is dbus running? )----- \n"; systemctl status dbus --no-pager 2>/dev/null || pgrep -x dbus-daemon >/dev/null
  } >> "/tmp/EUS/support/systemd-status.log"
  #
  lsblk -iJ -fs &> "/tmp/EUS/support/disk-layout.json"
  if [[ -n "$(command -v jq)" ]]; then
    system_hostname="$(uname --nodename)"
    system_kernel_name="$(uname --kernel-name)"
    system_kernel_release="$(uname --kernel-release)"
    system_kernel_version="$(uname --kernel-version)"
    system_machine="$(uname --machine)"
    system_hardware="$(uname --hardware-platform)"
    system_os="$(uname --operating-system)"
    if [[ -n "$(command -v runlevel)" ]]; then system_runlevel="$(runlevel | awk '{print $2}')"; else system_runlevel="command not found"; fi
    process_with_pid_1="$(ps -p 1 -o comm=)"
    cpu_cores="$(grep -ic processor /proc/cpuinfo)"
    cpu_usage="$(awk '{u=$2+$4; t=$2+$4+$5; if (NR==1){u1=u; t1=t;} else print ($2+$4-u1) * 100 / (t-t1) "%"; }' <(grep 'cpu ' /proc/stat) <(sleep 1;grep 'cpu ' /proc/stat))"
    cpu_architecture="$("$(which dpkg)" --print-architecture)"
    cpu_type="$(uname -p)"
    mem_total="$(grep "^MemTotal:" /proc/meminfo | awk '{print $2}')"
    mem_free="$(grep "^MemFree:" /proc/meminfo | awk '{print $2}')"
    mem_available="$(grep "^MemAvailable:" /proc/meminfo | awk '{print $2}')"
    mem_used="$(($(grep "^MemTotal:" /proc/meminfo | awk '{print $2}') - $(grep "MemAvailable" /proc/meminfo | awk '{print $2}')))"
    mem_used_percentage="$(awk "BEGIN {printf \"%.2f\", ((${mem_total} - ${mem_available}) / ${mem_total}) * 100}")"
    mem_buffers="$(grep "^Buffers:" /proc/meminfo | awk '{print $2}')"
    mem_cached="$(grep "^Cached:" /proc/meminfo | awk '{print $2}')"
    mem_active="$(grep "^Active:" /proc/meminfo | awk '{print $2}')"
    mem_inactive="$(grep "^Inactive:" /proc/meminfo | awk '{print $2}')"
    mem_dirty="$(grep "^Dirty:" /proc/meminfo | awk '{print $2}')"
    swap_total="$(grep "^SwapTotal:" /proc/meminfo | awk '{print $2}')"
    swap_free="$(grep "^SwapFree:" /proc/meminfo | awk '{print $2}')"
    swap_used="$(($(grep "^SwapTotal:" /proc/meminfo | awk '{print $2}') - $(grep "SwapFree" /proc/meminfo | awk '{print $2}')))"
    swap_cached="$(grep "^SwapCached:" /proc/meminfo | awk '{print $2}')"
    if [[ "$(dpkg-query --showformat='${version}' --show jq 2> /dev/null | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
      jq -n \
        --argjson "system-stats" "$( 
          jq -n \
            --argjson "system" "$( 
              jq -n \
                --arg system_hostname "${system_hostname}" \
                --arg system_kernel_name "${system_kernel_name}" \
                --arg system_kernel_release "${system_kernel_release}" \
                --arg system_kernel_version "${system_kernel_version}" \
                --arg system_machine "${system_machine}" \
                --arg system_hardware "${system_hardware}" \
                --arg system_os "${system_os}" \
                --arg timezone "${timezone}" \
                --arg system_runlevel "${system_runlevel}" \
                --arg process_with_pid_1 "${process_with_pid_1}" \
                "{ \"hostname\" : \"$system_hostname\", \"kernel-name\" : \"$system_kernel_name\", \"kernel-release\" : \"$system_kernel_release\", \"kernel-version\" : \"$system_kernel_version\", \"machine\" : \"$system_machine\", \"hardware\" : \"$system_hardware\", \"operating-system\" : \"$system_os\", \"timezone\" : \"$timezone\", \"runlevel\" : \"$system_runlevel\", \"init\" : \"$process_with_pid_1\" }" \
                '$ARGS.named'
              )" \
            '$ARGS.named' \
          jq -n \
            --argjson "cpu" "$( 
              jq -n \
                --arg cpu_usage "${cpu_usage}" \
                --arg cpu_cores "${cpu_cores}" \
                --arg cpu_architecture "${cpu_architecture}" \
                --arg cpu_type "${cpu_architecture}" \
                "{ \"usage\" : \"$cpu_usage\", \"cores\" : \"$cpu_cores\", \"architecture\" : \"$cpu_architecture\", \"type\" : \"$cpu_type\" }" \
                '$ARGS.named'
              )" \
            '$ARGS.named' \
          jq -n \
            --argjson "memory" "$( 
              jq -n \
                --arg mem_total "${mem_total}" \
                --arg mem_free "${mem_free}" \
                --arg mem_available "${mem_available}" \
                --arg mem_used "${mem_used}" \
                --arg mem_used_percentage "${mem_used_percentage}" \
                --arg mem_buffers "${mem_buffers}" \
                --arg mem_cached "${mem_cached}" \
                --arg mem_active "${mem_active}" \
                --arg mem_inactive "${mem_inactive}" \
                --arg mem_dirty "${mem_dirty}" \
                "{ \"total\" : \"$mem_total\", \"free\" : \"$mem_free\", \"available\" : \"$mem_available\", \"used\" : \"$mem_used\", \"used_percentage\" : \"$mem_used_percentage\", \"buffers\" : \"$mem_buffers\", \"cached\" : \"$mem_cached\", \"active\" : \"$mem_active\", \"inactive\" : \"$mem_inactive\", \"dirty\" : \"$mem_dirty\" }" \
                '$ARGS.named'
              )" \
            '$ARGS.named' \
          jq -n \
            --argjson "swap" "$( 
              jq -n \
                --arg swap_total "${swap_total}" \
                --arg swap_free "${swap_free}" \
                --arg swap_used "${swap_used}" \
                --arg swap_cached "${swap_cached}" \
                "{ \"total\" : \"$swap_total\", \"free\" : \"$swap_free\", \"used\" : \"$swap_used\", \"cached\" : \"$swap_cached\" }" \
                '$ARGS.named'
              )" \
            '$ARGS.named'
          )" \
        '$ARGS.named' &> "/tmp/EUS/support/sysstat.json"
    else
      jq -n \
        --arg system_hostname "${system_hostname}" \
        --arg system_kernel_name "${system_kernel_name}" \
        --arg system_kernel_release "${system_kernel_release}" \
        --arg system_kernel_version "${system_kernel_version}" \
        --arg system_machine "${system_machine}" \
        --arg system_hardware "${system_hardware}" \
        --arg system_os "${system_os}" \
        --arg timezone "${timezone}" \
        --arg system_runlevel "${system_runlevel}" \
        --arg process_with_pid_1 "${process_with_pid_1}" \
        --arg cpu_usage "${cpu_usage}" \
        --arg cpu_cores "${cpu_cores}" \
        --arg cpu_architecture "${cpu_architecture}" \
        --arg cpu_type "${cpu_type}" \
        --arg mem_total "${mem_total}" \
        --arg mem_free "${mem_free}" \
        --arg mem_available "${mem_available}" \
        --arg mem_used "${mem_used}" \
        --arg mem_used_percentage "${mem_used_percentage}" \
        --arg mem_buffers "${mem_buffers}" \
        --arg mem_cached "${mem_cached}" \
        --arg mem_active "${mem_active}" \
        --arg mem_inactive "${mem_inactive}" \
        --arg mem_dirty "${mem_dirty}" \
        --arg swap_total "${swap_total}" \
        --arg swap_free "${swap_free}" \
        --arg swap_used "${swap_used}" \
        --arg swap_cached "${swap_cached}" \
        '{
          system: {
            hostname: $system_hostname,
            "kernel-name": $system_kernel_name,
            "kernel-release": $system_kernel_release,
            "kernel-version": $system_kernel_version,
            machine: $system_machine,
            hardware: $system_hardware,
            "operating-system": $system_os,
            "timezone": $timezone,
            runlevel: $system_runlevel,
            init: $process_with_pid_1
          },
          cpu: {
            usage: $cpu_usage,
            cores: $cpu_cores,
            architecture: $cpu_architecture,
            type: $cpu_type
          },
          memory: {
            total: $mem_total,
            free: $mem_free,
            available: $mem_available,
            used: $mem_used,
            "used-percentage": $mem_used_percentage,
            buffers: $mem_buffers,
            cached: $mem_cached,
            active: $mem_active,
            inactive: $mem_inactive,
            dirty: $mem_dirty
          },
          swap: {
            total: $swap_total,
            free: $swap_free,
            used: $swap_used,
            cached: $swap_cached
          }
        }' &> "/tmp/EUS/support/sysstat.json"
    fi
  fi
  find "${eus_dir}" -type d -print -o -type f -print &> "/tmp/EUS/support/dirs_and_files"
  # Create a copy of the system.properties file and remove any mongodb PII
  if [[ -d "/usr/lib/unifi/data/" ]]; then
    while read -r system_properties_files; do
      {
        echo -e "\n-----( ${system_properties_files} )----- \n"
        cat "${system_properties_files}"
      } >> "/tmp/EUS/support/unifi.system.properties"
    done < <(find /usr/lib/unifi/data/ -name "system.properties*" -type f)
    if grep -sqE 'mongo\.password|mongo\.uri' "/tmp/EUS/support/unifi.system.properties"; then sed -i -e '/mongo.password/d' -e '/mongo.uri/d' "/tmp/EUS/support/unifi.system.properties"; echo "# Removed mongo.password and mongo.uri for privacy reasons" >> "/tmp/EUS/support/unifi.system.properties"; fi
  fi
  if [[ "${unifi_core_system}" != 'true' && -n "$(apt-cache search debsums | awk '/debsums/{print$1}')" ]]; then
    if ! [[ "$(command -v debsums)" ]]; then "${EUS_APT_ENV[@]}" env DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install debsums &>> "${eus_dir}/logs/apt.log"; fi
    if [[ "$(command -v debsums)" ]]; then debsums -c &> "/tmp/EUS/support/debsums-check-results"; fi
  fi
  support_file_time="$(date +%Y%m%d-%H%M-%S%N)"
  if [[ -n "$(command -v jq)" && -f "${eus_dir}/db/db.json" ]]; then support_file_uuid="$(jq -r '.database.uuid' "${eus_dir}/db/db.json")-"; fi
  if "$(which dpkg)" -l xz-utils 2> /dev/null | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
    support_file="/tmp/eus-support-${support_file_uuid}${support_file_time}.tar.xz"
    support_file_name="$(basename "${support_file}")"
    if [[ "$(dpkg-query --showformat='${version}' --show jq 2> /dev/null | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
      jq '.scripts."'"${script_name}"'" |= . + {"support": (.support + {("'"${support_file_name}"'"): {"abort-reason": "'"${abort_reason}"'","upload-results": ""}})}' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
    else
      jq --arg script_name "$script_name" --arg support_file_name "$support_file_name" --arg abort_reason "$abort_reason" '.scripts[$script_name] |= (. + {support: ((.support // {}) + {($support_file_name): {"abort-reason": $abort_reason,"upload-results": ""}})})' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
    fi
    eus_database_move
    tar cJvfh "${support_file}" --exclude="${eus_dir}/go.tar.gz" --exclude="${eus_dir}/unifi_db" --exclude="${eus_dir}/tmp" --exclude="/usr/lib/unifi/logs/remote" "/tmp/EUS" "${eus_dir}" "/usr/lib/unifi/logs" "/etc/apt/sources.list" "/etc/apt/sources.list.d/" "/etc/apt/preferences" "/etc/apt/keyrings" "/etc/apt/trusted.gpg.d/" "/etc/apt/preferences.d/" "/etc/default/unifi" "/etc/environment" "/var/log/dpkg.log"* "/etc/systemd/system/unifi.service.d/" "/lib/systemd/system/unifi.service" "/usr/lib/unifi/data/db/version" "/var/lib/uosserver/" &> /dev/null
  elif "$(which dpkg)" -l zstd 2> /dev/null | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
    support_file="/tmp/eus-support-${support_file_uuid}${support_file_time}.tar.zst"
    support_file_name="$(basename "${support_file}")"
    if [[ "$(dpkg-query --showformat='${version}' --show jq 2> /dev/null | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
      jq '.scripts."'"${script_name}"'" |= . + {"support": (.support + {("'"${support_file_name}"'"): {"abort-reason": "'"${abort_reason}"'","upload-results": ""}})}' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
    else
      jq --arg script_name "$script_name" --arg support_file_name "$support_file_name" --arg abort_reason "$abort_reason" '.scripts[$script_name] |= (. + {support: ((.support // {}) + {($support_file_name): {"abort-reason": $abort_reason,"upload-results": ""}})})' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
    fi
    eus_database_move
    tar --use-compress-program=zstd -cvf "${support_file}" --exclude="${eus_dir}/go.tar.gz" --exclude="${eus_dir}/unifi_db" --exclude="${eus_dir}/tmp" --exclude="/usr/lib/unifi/logs/remote" "/tmp/EUS" "${eus_dir}" "/usr/lib/unifi/logs" "/etc/apt/sources.list" "/etc/apt/sources.list.d/" "/etc/apt/preferences" "/etc/apt/keyrings" "/etc/apt/trusted.gpg.d/" "/etc/apt/preferences.d/" "/etc/default/unifi" "/etc/environment" "/var/log/dpkg.log"* "/etc/systemd/system/unifi.service.d/" "/lib/systemd/system/unifi.service" "/usr/lib/unifi/data/db/version" "/var/lib/uosserver/" &> /dev/null
  elif "$(which dpkg)" -l tar 2> /dev/null | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
    support_file="/tmp/eus-support-${support_file_uuid}${support_file_time}.tar.gz"
    support_file_name="$(basename "${support_file}")"
    if [[ "$(dpkg-query --showformat='${version}' --show jq 2> /dev/null | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
      jq '.scripts."'"${script_name}"'" |= . + {"support": (.support + {("'"${support_file_name}"'"): {"abort-reason": "'"${abort_reason}"'","upload-results": ""}})}' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
    else
      jq --arg script_name "$script_name" --arg support_file_name "$support_file_name" --arg abort_reason "$abort_reason" '.scripts[$script_name] |= (. + {support: ((.support // {}) + {($support_file_name): {"abort-reason": $abort_reason,"upload-results": ""}})})' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
    fi
    eus_database_move
    tar czvfh "${support_file}" --exclude="${eus_dir}/go.tar.gz" --exclude="${eus_dir}/unifi_db" --exclude="${eus_dir}/tmp" --exclude="/usr/lib/unifi/logs/remote" "/tmp/EUS" "${eus_dir}" "/usr/lib/unifi/logs" "/etc/apt/sources.list" "/etc/apt/sources.list.d/" "/etc/apt/preferences" "/etc/apt/keyrings" "/etc/apt/trusted.gpg.d/" "/etc/apt/preferences.d/" "/etc/default/unifi" "/etc/environment" "/var/log/dpkg.log"* "/etc/systemd/system/unifi.service.d/" "/lib/systemd/system/unifi.service" "/usr/lib/unifi/data/db/version" "/var/lib/uosserver/" &> /dev/null
  elif "$(which dpkg)" -l zip 2> /dev/null | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
    support_file="/tmp/eus-support-${support_file_uuid}${support_file_time}.zip"
    support_file_name="$(basename "${support_file}")"
    if [[ "$(dpkg-query --showformat='${version}' --show jq 2> /dev/null | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
      jq '.scripts."'"${script_name}"'" |= . + {"support": (.support + {("'"${support_file_name}"'"): {"abort-reason": "'"${abort_reason}"'","upload-results": ""}})}' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
    else
      jq --arg script_name "$script_name" --arg support_file_name "$support_file_name" --arg abort_reason "$abort_reason" '.scripts[$script_name] |= (. + {support: ((.support // {}) + {($support_file_name): {"abort-reason": $abort_reason,"upload-results": ""}})})' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
    fi
    eus_database_move
    zip -r "${support_file}" "/tmp/EUS/" "${eus_dir}/" "/usr/lib/unifi/logs/" "/etc/apt/sources.list" "/etc/apt/sources.list.d/" "/etc/apt/preferences" "/etc/apt/keyrings" "/etc/apt/trusted.gpg.d/" "/etc/apt/preferences.d/" "/etc/default/unifi" "/etc/environment" "/var/log/dpkg.log"* "/etc/systemd/system/unifi.service.d/" "/lib/systemd/system/unifi.service" "/usr/lib/unifi/data/db/version" "/var/lib/uosserver/" -x "${eus_dir}/go.tar.gz" -x "${eus_dir}/unifi_db/*" -x "${eus_dir}/tmp" -x "/usr/lib/unifi/logs/remote" &> /dev/null
  fi
  if [[ -n "${support_file}" ]]; then
    echo -e "${GRAY_R}#${RESET} Support file has been created here: ${support_file} \\n"
    if [[ -n "$(command -v jq)" && -f "${eus_dir}/db/db.json" ]]; then
      if [[ "$(jq -r '.database["support-file-upload"]' "${eus_dir}/db/db.json")" != 'true' ]]; then
        read -rp $'\033[39m#\033[0m Do you want to upload the support file so that Glenn R. can review it and improve the script? (Y/n) ' yes_no
        case "$yes_no" in
             [Nn]*) ;;
             *) eus_support_one_time_upload="true";;
        esac
      fi
      if [[ "$(jq -r '.database["support-file-upload"]' "${eus_dir}/db/db.json")" == 'true' ]] || [[ "${eus_support_one_time_upload}" == 'true' ]]; then
        upload_result="$(curl "${curl_argument[@]}" -X POST -F "file=@${support_file}" "https://api.glennr.nl/api/eus-support" 2> /dev/null | jq -r '.[]' 2> /dev/null)"
        if [[ "$(dpkg-query --showformat='${version}' --show jq 2> /dev/null | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
          jq '.scripts."'"${script_name}"'".support."'"${support_file_name}"'"."upload-results" = "'"${upload_result}"'"' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
        else
          jq --arg script_name "$script_name" --arg support_file_name "$support_file_name" --arg upload_result "$upload_result" '.scripts[$script_name].support[$support_file_name]["upload-results"] = $upload_result' "${eus_dir}/db/db.json"
        fi
        eus_database_move
        if grep -sqE -m 1 "Error while running DB migration" "/usr/lib/unifi/logs/server.log"; then
          ubk_files=()
          while read -r dir; do
            ubk_file="$(find "$dir" -type f -name "*.unf" -printf "%T@ %p\n" 2>/dev/null | sort -nr | head -n 1 | awk '{print $2}')"
            if [[ -f "${ubk_file}" ]]; then ubk_files+=("${ubk_file}"); fi
          done < <(find "$(readlink -f /usr/lib/unifi/data)" -type d -name "*backup*")
          if (( "${#ubk_files[@]}" )); then
            if "$(which dpkg)" -l xz-utils 2> /dev/null | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
              tar cJvfh "/tmp/additional-data-${support_file_name}" "${ubk_files[@]}" &> /dev/null
            elif "$(which dpkg)" -l zstd 2> /dev/null | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
              tar --use-compress-program=zstd -cvf "/tmp/additional-data-${support_file_name}" "${ubk_files[@]}" &> /dev/null
            elif "$(which dpkg)" -l tar 2> /dev/null | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
              tar czvfh "/tmp/additional-data-${support_file_name}" "${ubk_files[@]}" &> /dev/null
            elif "$(which dpkg)" -l zip 2> /dev/null | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
              zip -r "/tmp/additional-data-${support_file_name}" "${ubk_files[@]}" &> /dev/null
            fi
            if [[ "$(dpkg-query --showformat='${version}' --show jq 2> /dev/null | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
              jq '.scripts."'"${script_name}"'" |= . + {"support": (.support + {("'"additional-data-${support_file_name}"'"): {"abort-reason": "'"${abort_reason}"'","upload-results": ""}})}' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
            else
              jq --arg script_name "$script_name" --arg support_file_name "additional-data-${support_file_name}" --arg abort_reason "$abort_reason" '.scripts[$script_name] |= (. + {support: ((.support // {}) + {($support_file_name): {"abort-reason": $abort_reason,"upload-results": ""}})})' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
            fi
            eus_database_move
            upload_result="$(curl "${curl_argument[@]}" -X POST -F "file=@/tmp/additional-data-${support_file_name}" "https://api.glennr.nl/api/eus-support" 2> /dev/null | jq -r '.[]' 2> /dev/null)"
            rm --force "/tmp/additional-data-${support_file_name}" &> /dev/null
            if [[ "$(dpkg-query --showformat='${version}' --show jq 2> /dev/null | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
              jq '.scripts."'"${script_name}"'".support."'"additional-data-${support_file_name}"'"."upload-results" = "'"${upload_result}"'"' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
            else
              jq --arg script_name "$script_name" --arg support_file_name "additional-data-${support_file_name}" --arg upload_result "$upload_result" '.scripts[$script_name].support[$support_file_name]["upload-results"] = $upload_result' "${eus_dir}/db/db.json"
            fi
            eus_database_move
          fi
        fi
      else
        upload_result="skipped"
        if [[ "$(dpkg-query --showformat='${version}' --show jq 2> /dev/null | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
          jq '.scripts."'"${script_name}"'".support."'"${support_file_name}"'"."upload-results" = "'"${upload_result}"'"' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
        else
          jq --arg script_name "$script_name" --arg support_file_name "$support_file_name" --arg upload_result "$upload_result" '.scripts[$script_name].support[$support_file_name]["upload-results"] = $upload_result' "${eus_dir}/db/db.json"
        fi
        eus_database_move
      fi
    fi
  fi
  if [[ "${script_option_support_file}" == 'true' ]]; then exit 0; fi
}

abort() {
  if [[ -n "${abort_reason}" && "${abort_function_skip_reason}" != 'true' ]]; then echo -e "${RED}#${RESET} ${abort_reason}.. \\n"; fi
  if [[ -n "$(command -v jq)" && -f "${eus_dir}/db/db.json" ]]; then
    if [[ "$(dpkg-query --showformat='${version}' --show jq 2> /dev/null | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
      script_aborts="$(jq -r '.scripts."'"${script_name}"'".aborts' "${eus_dir}/db/db.json")"
    else
      script_aborts="$(jq --arg script_name "$script_name" -r '.scripts[$script_name].aborts' "${eus_dir}/db/db.json")"
    fi
    ((script_aborts=script_aborts+1))
    if [[ "$(dpkg-query --showformat='${version}' --show jq 2> /dev/null | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
      jq --arg script_aborts "${script_aborts}" '."scripts"."'"${script_name}"'" += {"aborts": "'"${script_aborts}"'"}' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
    else
      jq --arg script_name "$script_name" --arg script_aborts "$script_aborts" '.scripts[$script_name] += {"aborts": $script_aborts}' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
    fi
    eus_database_move
  fi
  if [[ "${set_lc_all}" == 'true' ]]; then if [[ -n "${original_lang}" ]]; then export LANG="${original_lang}"; else unset LANG; fi; if [[ -n "${original_lcall}" ]]; then export LC_ALL="${original_lcall}"; else unset LC_ALL; fi; fi
  if [[ "${stopped_unattended_upgrade}" == 'true' ]]; then systemctl start unattended-upgrades &>> "${eus_dir}/logs/unattended-upgrades.log"; unset stopped_unattended_upgrade; fi
  if [[ -f /tmp/EUS/services/stopped_list && -s /tmp/EUS/services/stopped_list ]]; then
    while read -r service; do
      echo -e "\\n${GRAY_R}#${RESET} Starting ${service}.."
      if [[ "${limited_functionality}" == 'true' ]]; then
        if service "${service}" start &>> "${eus_dir}/logs/abort-script-service-start.log"; then echo -e "${GREEN}#${RESET} Successfully started ${service}!"; else echo -e "${RED}#${RESET} Failed to start ${service}!"; fi
      else
        if systemctl start "${service}" &>> "${eus_dir}/logs/abort-script-service-start.log"; then echo -e "${GREEN}#${RESET} Successfully started ${service}!"; else echo -e "${RED}#${RESET} Failed to start ${service}!"; fi
      fi
    done < /tmp/EUS/services/stopped_list
  fi
  echo -e "\\n\\n${RED}#########################################################################${RESET}\\n"
  if [[ "$(df -B1 / | awk 'NR==2{print $4}')" -le '5368709120' ]]; then echo -e "${YELLOW}#${RESET} You only have $(df -B1 / | awk 'NR==2{print $4}' | awk '{ split( "B KB MB GB TB PB EB ZB YB" , v ); s=1; while( $1>1024 && s<9 ){ $1/=1024; s++ } printf "%.1f %s", $1, v[s] }') of disk space available on \"/\"... \\n"; fi
  if [[ -e "/usr/lib/unifi/logs/server.log" ]]; then if grep -ioq "Invalid access at address.*Bus error" "/usr/lib/unifi/logs/server.log"; then  echo -e "${GRAY_R}#${RESET} You've got \"Invalid access at address\" messages in your logs, this is often caused by bad storage or bad memory... \\n"; fi; fi
  echo -e "${GRAY_R}#${RESET} An error occurred. Aborting script..."
  echo -e "${GRAY_R}#${RESET} Please contact Glenn R. (AmazedMender16) on the UI Community Forums!"
  echo -e "${GRAY_R}#${RESET} UI Community Thread: https://community.ui.com/questions/ccbc7530-dd61-40a7-82ec-22b17f027776 \\n"
  support_file
  update_eus_db
  cleanup_codename_mismatch_repos
  exit 1
}

eus_create_directories() {
  for dir_name in "$@"; do
    if ! [[ -d "${eus_directory_location}/${dir_name}" ]]; then 
      if ! [[ -d "${eus_dir}/logs" ]]; then 
        if ! mkdir -p "${eus_directory_location}/${dir_name}"; then 
          abort_reason="Failed to create directory ${eus_directory_location}/${dir_name}."; header_red; abort
        fi 
      else 
        if ! mkdir -p "${eus_directory_location}/${dir_name}" &>> "${eus_dir}/logs/create-directories.log"; then 
          abort_reason="Failed to create directory ${eus_directory_location}/${dir_name}."; header_red; abort
       fi 
      fi 
    fi
  done
  eus_directory_location="${eus_dir}"
}

eus_tmp_deb_check() {
  eus_tmp_deb_create_attempts="${eus_tmp_deb_create_attempts:-0}"
  local deb_var="${eus_tmp_deb_var}"
  # shellcheck disable=SC2034
  local deb_name="${eus_tmp_deb_name}"
  if [[ -n "${!deb_var}" && -e "${!deb_var}" ]]; then
    echo -e "$(date +%F-%T.%6N) | EUS temporary deb file for variable '${deb_var}' already exists: ${!deb_var}" &>> "${eus_dir}/logs/create-tmp-dir-file.log"
    return 0
  elif [[ -z "${!deb_var}" ]]; then
    eval "${deb_var}=\"\$(mktemp --tmpdir=\"\${eus_tmp_directory_location}\" \"\${deb_name}_XXXXX.deb\" 2>> \"\${eus_dir}/logs/create-tmp-dir-file.log\")\""
    echo -e "$(date +%F-%T.%6N) | Creating EUS temporary deb file for variable '${deb_var}': ${!deb_var}" &>> "${eus_dir}/logs/create-tmp-dir-file.log"
  fi
  if [[ -e "${!deb_var}" ]]; then
    if [[ "${!deb_var}" != "${eus_tmp_created_deb_location}" ]]; then
      eus_tmp_created_deb_location="${!deb_var}"
      echo -e "$(date +%F-%T.%6N) | EUS temporary deb file for variable '${deb_var}' created: ${!deb_var}" &>> "${eus_dir}/logs/create-tmp-dir-file.log"
    fi
  else
    unset "${deb_var}"
    ((eus_tmp_deb_create_attempts++))
    if [[ "${eus_tmp_deb_create_attempts}" -le "3" ]]; then
      echo -e "$(date +%F-%T.%6N) | Retrying to create the EUS temporary deb file for variable '${deb_var}'... (Attempt ${eus_tmp_deb_create_attempts})" &>> "${eus_dir}/logs/create-tmp-dir-file.log"
      eus_tmp_deb_check
    else
      echo -e "$(date +%F-%T.%6N) | Failed to create the EUS temporary deb file for variable '${deb_var}' after 3 attempts..." &>> "${eus_dir}/logs/create-tmp-dir-file.log"
      abort_reason="Failed to create the EUS temporary deb file for variable '${deb_var}' after 3 attempts."
      abort
    fi
  fi
}

eus_tmp_directory_check() {
  if [[ "${eus_tmp_directory_cleanup_done}" != 'true' ]] || [[ "${eus_tmp_directory_cleanup}" == 'true' ]]; then find "${eus_dir}/tmp/" -mindepth 1 -maxdepth 1 -type d -exec rm -rf {} + 2> /dev/null; eus_tmp_directory_cleanup_done="true"; fi
  if [[ "${eus_tmp_directory_cleanup}" == 'true' ]]; then return 0; fi
  eus_tmp_directory_create_attempts="${eus_tmp_directory_create_attempts:-0}"
  if [[ -n "${eus_tmp_directory_location}" && -d "${eus_tmp_directory_location}" ]]; then
    echo -e "$(date +%F-%T.%6N) | EUS temporary directory already exists: ${eus_tmp_directory_location}" &>> "${eus_dir}/logs/create-tmp-dir-file.log"
    if [[ -n "${eus_tmp_deb_var}" && -n "${eus_tmp_deb_name}" ]]; then eus_tmp_deb_check; fi
    return 0
  elif [[ -z "${eus_tmp_directory_location}" ]]; then
    eus_tmp_directory_location="$(mktemp -d "$(date +%Y%m%d)_XXXXX" --tmpdir="${eus_dir}/tmp/" 2>> "${eus_dir}/logs/create-tmp-dir-file.log")"
    echo -e "$(date +%F-%T.%6N) | Creating EUS temporary directory: ${eus_tmp_directory_location}" &>> "${eus_dir}/logs/create-tmp-dir-file.log"
  fi
  if [[ -d "${eus_tmp_directory_location}" ]]; then
    if [[ "${eus_tmp_directory_location}" != "${eus_tmp_created_directory_location}" ]]; then eus_tmp_created_directory_location="${eus_tmp_directory_location}"; echo -e "$(date +%F-%T.%6N) | EUS temporary directory created: ${eus_tmp_directory_location}" &>> "${eus_dir}/logs/create-tmp-dir-file.log"; fi
  else
    unset eus_tmp_directory_location
    ((eus_tmp_directory_create_attempts++))
    if [[ "${eus_tmp_directory_create_attempts}" -le 3 ]]; then
      echo -e "$(date +%F-%T.%6N) | Retrying to create the EUS temporary directory... (Attempt ${eus_tmp_directory_create_attempts})" &>> "${eus_dir}/logs/create-tmp-dir-file.log"
      eus_tmp_directory_check
    else
      echo -e "$(date +%F-%T.%6N) | Failed to create the EUS temporary directory after 3 attempts..." &>> "${eus_dir}/logs/create-tmp-dir-file.log"
      abort_reason="Failed to create the EUS temporary directory after 3 attempts."
      abort
    fi
  fi
  if [[ -n "${eus_tmp_deb_var}" && -n "${eus_tmp_deb_name}" ]]; then eus_tmp_deb_check; fi
}

eus_directories() {
  if uname -a | tr '[:upper:]' '[:lower:]' | grep -iq "cloudkey\\|uck\\|ubnt-mtk"; then
    eus_dir='/srv/EUS'
    is_cloudkey="true"
  elif grep -iq "UCKP\\|UCKG2\\|UCK" /usr/lib/version &> /dev/null; then
    eus_dir='/srv/EUS'
    is_cloudkey="true"
  elif "$(which dpkg)" -l unifi-core 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
    eus_dir='/srv/EUS'
  else
    eus_dir='/usr/lib/EUS'
    is_cloudkey="false"
  fi
  if [[ "${eus_dir}" == '/srv/EUS' ]]; then if findmnt -no OPTIONS "$(df --output=target /srv | tail -1)" | grep -ioq "ro"; then eus_dir='/usr/lib/EUS'; fi; fi
  eus_directory_location="${eus_dir}"
  eus_create_directories "db" "logs" "tmp"
  eus_tmp_directory_check
  if ! rm -rf /tmp/EUS &> /dev/null; then abort_reason="Failed to remove /tmp/EUS."; header_red; abort; fi
  eus_directory_location="/tmp/EUS"
  eus_create_directories "upgrade" "dpkg" "repository"
  grep -sriIl "unifi-[0-9].[0-9]" /etc/apt/sources.list* &> /tmp/EUS/repository/unifi-repo-file
  if [[ "${is_cloudkey}" == "true" ]]; then if grep -iq "UCK.mtk7623" /usr/lib/version &> /dev/null; then cloudkey_generation="1"; fi; fi
  if ! [[ -d "/etc/apt/keyrings" ]]; then if ! install -m "0755" -d "/etc/apt/keyrings" &>> "${eus_dir}/logs/keyrings-directory-creation.log"; then if ! mkdir -p "/etc/apt/keyrings" &>> "${eus_dir}/logs/keyrings-directory-creation.log"; then abort_reason="Failed to create /etc/apt/keyrings."; abort; fi; fi; if ! [[ -s "${eus_dir}/logs/keyrings-directory-creation.log" ]]; then rm --force "${eus_dir}/logs/keyrings-directory-creation.log"; fi; fi
  if [[ "$(command -v stat)" ]]; then tmp_permissions="$(stat -c '%a' /tmp)"; echo -e "$(date +%F-%T.%6N) | \"/tmp\" has permissions \"${tmp_permissions}\"..." &>> "${eus_dir}/logs/update-tmp-permissions.log"; fi
  # shellcheck disable=SC2012
  if [[ "${tmp_permissions}" != '1777' ]]; then if [[ -z "${tmp_permissions}" ]]; then echo -e "$(date +%F-%T.%6N) | \"/tmp\" has permissions \"$(ls -ld /tmp | awk '{print $1}')\"..." &>> "${eus_dir}/logs/update-tmp-permissions.log"; fi; chmod 1777 /tmp &>> "${eus_dir}/logs/update-tmp-permissions.log"; fi
  if [[ -n "$(find /etc/apt/sources.list.d/ -name "*.sources" -print -quit 2>/dev/null)" ]]; then use_deb822_format="true"; fi
  if [[ "${use_deb822_format}" == 'true' ]]; then source_file_format="sources"; else source_file_format="list"; fi
}

script_logo() {
  cat << "EOF"

  _______________ ___  _________  .___                 __         .__  .__   
  \_   _____/    |   \/   _____/  |   | ____   _______/  |______  |  | |  |  
   |    __)_|    |   /\_____  \   |   |/    \ /  ___/\   __\__  \ |  | |  |  
   |        \    |  / /        \  |   |   |  \\___ \  |  |  / __ \|  |_|  |__
  /_______  /______/ /_______  /  |___|___|  /____  > |__| (____  /____/____/
          \/                 \/            \/     \/            \/           

EOF
}

start_script_header() {
  header
  script_logo
  echo -e "    Easy UniFi Network Application/OS Server Install Script"
  echo -e "\\n${GRAY_R}#${RESET} Starting the Easy UniFi Install Script.."
  echo -e "${GRAY_R}#${RESET} Thank you for using my Easy UniFi Install Script :-)\\n\\n"
}

start_script() {
  script_location="${BASH_SOURCE[0]}"
  if ! [[ -f "${script_location}" ]]; then header_red; echo -e "${YELLOW}#${RESET} The script needs to be saved on the disk in order to work properly, please follow the instructions...\\n${YELLOW}#${RESET} Usage: curl -sO https://get.glennr.nl/unifi/install/install_latest/unifi-latest.sh && bash unifi-latest.sh\\n\\n"; exit 1; fi
  script_file_name="$(basename "${BASH_SOURCE[0]}")"
  script_name="$(grep -i "# Script" "${script_location}" | head -n 1 | cut -d'|' -f2 | sed -e 's/^ //g')"
  eus_directories
  start_script_header
  if [[ "${update_at_start_script}" != 'true' ]]; then update_at_start_script="true"; update_eus_db; fi
  if pgrep -f unattended-upgrade &> /dev/null; then if systemctl stop unattended-upgrades &>> "${eus_dir}/logs/unattended-upgrades.log"; then stopped_unattended_upgrade="true"; fi; fi
}
start_script
check_dns
check_apt_listbugs
check_for_block_page

help_script() {
  check_apt_listbugs
  if [[ "${script_option_help}" == 'true' ]]; then header; script_logo; else echo -e "${GRAY_R}----${RESET}\\n"; fi
  echo -e "    Easy UniFi Network Application/OS Server Install Script assistance\\n"
  echo -e "
  Script usage:
  bash ${script_file_name} [options]
  
  Script options:
    --skip                                  Skip any kind of manual input.
    --install-unifi-os-server               Automatically choose to install the UniFi OS Server software.
    --install-network-application           Automatically choose to install the UniFi Network Application software.
    --skip-swap                             Skip swap file check/creation.
    --add-repository                        Add UniFi Repository if --skip is used.
    --local-install                         Inform script that it's a local UniFi Network installation, to open port 10001/udp ( discovery ).
    --check-ssh-port                        Check and add the SSH port to the UFW Allow list if it's not present.
    --custom-url [argument]                 Manually provide a UniFi Network Application download URL.
                                            example:
                                            --custom-url https://dl.ui.com/unifi/7.4.162/unifi_sysvinit_all.deb
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
    --dns-provider                          Specify your DNS server provider.
                                            example:
                                            --dns-provider ovh
                                            Supported providers: cloudflare, digitalocean, dnsimple, dnsmadeeasy, gehirn, google, linode, luadns, nsone, ovh, rfc2136, route53, sakuracloud
    --dns-provider-credentials              Specify where the API credentials of your DNS provider are located.
                                            example:
                                            --dns-provider-credentials ~/.secrets/EUS/ovh.ini
    --private-key [argument]                Specify path to your private key (paid certificate)
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
                                            with the use of --skip.
    --run-easy-encrypt                      Run the UniFi Easy Encrypt script if an FQDN is specified via --fqdn.
    --support-file                          Generate a support file for debugging by Glenn R.\\n\\n"
  exit 0
}

rm --force /tmp/EUS/script_options &> /dev/null
rm --force /tmp/EUS/le_script_options &> /dev/null
script_option_list=(-skip --skip --install-unifi-os-server --install-uos --install-network-application --install-net --skip-swap --add-repository --local --local-controller --local-install --check-ssh-port --custom-url --help --v6 --ipv6 --email --mail --fqdn --domain-name --server-ip --server-address --retry --external-dns --force-renew --renew --dns --dns-challenge --dns-provider --dns-provider-credentials --debug --run-easy-encrypt --support-file)
dns_provider_list=(cloudflare digitalocean dnsimple dnsmadeeasy gehirn google linode luadns nsone ovh rfc2136 route53 sakuracloud)
dns_multi_provider_list=(akamaiedgedns alibabaclouddns allinkl amazonlightsail arvancloud auroradns autodns azuredns bindman bluecat brandit bunny checkdomain civo cloudru clouddns cloudns cloudxns conoha constellix derakcloud desecio designatednsaasforopenstack dnshomede domainoffensive domeneshop dreamhost duckdns dyn dynu easydns efficientip epik exoscale externalprogram freemyip gcore gandi gandilivedns glesys godaddy hetzner hostingde hosttech httprequest httpnet hurricaneelectricdns hyperone ibmcloud iijdnsplatformservice infoblox infomaniak internetinitiativejapan internetbs inwx ionos ipv64 iwantmyname joker joohoisacmedns liara liquidweb loopia metaname mydnsjp mythicbeasts namecom namecheap namesilo nearlyfreespeechnet netcup netlify nicmanager nifcloud njalla nodion opentelekomcloud oraclecloud pleskcom porkbun powerdns rackspace rcodezero regru rimuhosting scaleway selectel servercow simplycom sonic stackpath tencentclouddns transip ukfastsafedns ultradns variomedia vegadns vercel versionl versioeu versiouk vinyldns vkcloud vscale vultr webnames websupport wedos yandex360 yandexcloud yandexpdd zoneee zonomi)

while [ -n "$1" ]; do
  case "$1" in
  -skip | --skip)
       script_option_skip="true"
       echo "--skip" &>> /tmp/EUS/script_options
       echo "--skip" &>> /tmp/EUS/le_script_options;;
  --install-unifi-os-server | --install-uos)
       script_option_install_uos="true"
       echo "--install-unifi-os-server" &>> /tmp/EUS/script_options;;
  --install-network-application | --install-net)
       script_option_install_net="true"
       echo "--install-network-application" &>> /tmp/EUS/script_options;;
  --skip-swap)
       script_option_skip_swap="true"
       echo "--skip-swap" &>> /tmp/EUS/script_options;;
  --add-repository)
       script_option_add_repository="true"
       echo "--add-repository" &>> /tmp/EUS/script_options;;
  --local | --local-controller | --local-install)
       script_option_local_install="true"
       echo "--local-install" &>> /tmp/EUS/script_options;;
  --check-ssh-port)
       ufw_append_ssh_port="true"
       echo "--check-ssh-port" &>> /tmp/EUS/script_options;;
  --custom-url)
       if [[ -n "${2}" ]]; then if echo "${2}" | grep -ioq ".deb"; then custom_url_down_provided="true"; custom_download_url="${2}"; else header_red; echo -e "${RED}#${RESET} Provided URL does not have the 'deb' extension...\\n"; help_script; fi; fi
       script_option_custom_url="true"
       if [[ "${custom_url_down_provided}" == 'true' ]]; then echo "--custom-url ${2}" &>> /tmp/EUS/script_options; else echo "--custom-url" &>> /tmp/EUS/script_options; fi;;
  --help)
       script_option_help="true"
       help_script;;
  --v6 | --ipv6)
       echo "--v6" &>> /tmp/EUS/le_script_options;;
  --email | --mail)
       for option in "${script_option_list[@]}"; do
         if [[ "${2}" == "${option}" ]]; then header_red; echo -e "${GRAY_R}#${RESET} Option ${1} requires a command argument... \\n\\n"; help_script; fi
       done
       echo -e "--email ${2}" &>> /tmp/EUS/le_script_options
       shift;;
  --fqdn | --domain-name)
       for option in "${script_option_list[@]}"; do
         if [[ "${2}" == "${option}" ]]; then header_red; echo -e "${GRAY_R}#${RESET} Option ${1} requires a command argument... \\n\\n"; help_script; fi
       done
       echo -e "--fqdn ${2}" &>> /tmp/EUS/le_script_options
       fqdn_specified="true"
       shift;;
  --server-ip | --server-address)
       for option in "${script_option_list[@]}"; do
         if [[ "${2}" == "${option}" ]]; then header_red; echo -e "${GRAY_R}#${RESET} Option ${1} requires a command argument... \\n\\n"; help_script; fi
       done
       echo -e "--server-ip ${2}" &>> /tmp/EUS/le_script_options
       shift;;
  --retry)
       for option in "${script_option_list[@]}"; do
         if [[ "${2}" == "${option}" ]]; then header_red; echo -e "${GRAY_R}#${RESET} Option ${1} requires a command argument... \\n\\n"; help_script; fi
       done
       echo -e "--retry ${2}" &>> /tmp/EUS/le_script_options
       shift;;
  --external-dns)
       for option in "${script_option_list[@]}"; do
         if [[ "${2}" == "${option}" ]]; then echo -e "--external-dns" &>> /tmp/EUS/le_script_options; else echo -e "--external-dns ${2}" &>> /tmp/EUS/le_script_options; fi
       done;;
  --force-renew | --renew)
       echo -e "--force-renew" &>> /tmp/EUS/le_script_options;;
  --dns | --dns-challenge)
       echo -e "--dns-challenge" &>> /tmp/EUS/le_script_options;;
  --dns-provider)
       for option in "${script_option_list[@]}"; do
         if [[ "${2}" == "${option}" ]]; then header_red; echo -e "${GRAY_R}#${RESET} Option ${1} requires a command argument... \\n\\n"; help_script; fi
       done
       for dns_provider_check in "${dns_provider_list[@]}"; do if [[ "${dns_provider_check}" == "$2" ]]; then supported_provider="true"; break; fi; done
       for dns_provider_check in "${dns_multi_provider_list[@]}"; do if [[ "${dns_provider_check}" == "$2" ]]; then supported_provider="true"; break; fi; done
       if [[ "${supported_provider}" != 'true' ]]; then header_red; echo -e "${GRAY_R}#${RESET} DNS Provider ${2} is not supported... \\n\\n"; help_script; fi
       echo "--dns-provider ${2}" &>> /tmp/EUS/le_script_options;;
  --dns-provider-credentials)
       for option in "${script_option_list[@]}"; do
         if [[ "${2}" == "${option}" ]]; then header_red; echo -e "${GRAY_R}#${RESET} Option ${1} requires a command argument... \\n\\n"; help_script; fi
       done
       echo "--dns-provider-credentials ${2}" &>> /tmp/EUS/le_script_options;;
  --priv-key | --private-key)
       for option in "${script_option_list[@]}"; do
         if [[ "${2}" == "${option}" ]]; then header_red; echo -e "${GRAY_R}#${RESET} Option ${1} requires a command argument... \\n\\n"; help_script; fi
       done
       echo "--private-key ${2}" &>> /tmp/EUS/le_script_options
       shift;;
  --signed-crt | --signed-certificate)
       for option in "${script_option_list[@]}"; do
         if [[ "${2}" == "${option}" ]]; then header_red; echo -e "${GRAY_R}#${RESET} Option ${1} requires a command argument... \\n\\n"; help_script; fi
       done
       echo "--signed-certificate ${2}" &>> /tmp/EUS/le_script_options
       shift;;
  --chain-crt | --chain-certificate)
       for option in "${script_option_list[@]}"; do
         if [[ "${2}" == "${option}" ]]; then header_red; echo -e "${GRAY_R}#${RESET} Option ${1} requires a command argument... \\n\\n"; help_script; fi
       done
       echo "--chain-certificate ${2}" &>> /tmp/EUS/le_script_options
       shift;;
  --intermediate-crt | --intermediate-certificate)
       for option in "${script_option_list[@]}"; do
         if [[ "${2}" == "${option}" ]]; then header_red; echo -e "${GRAY_R}#${RESET} Option ${1} requires a command argument... \\n\\n"; help_script; fi
       done
       echo "--intermediate-certificate ${2}" &>> /tmp/EUS/le_script_options
       shift;;
  --own-certificate)
       echo "--own-certificate" &>> /tmp/EUS/le_script_options;;
  --run-easy-encrypt)
       run_easy_encrypt="true";;
  --debug)
       script_option_debug="true";;
  --support-file)
       script_option_support_file="true"
       support_file;;
  esac
  shift
done

# Check script options.
if [[ -f /tmp/EUS/script_options && -s /tmp/EUS/script_options ]]; then IFS=" " read -r script_options <<< "$(tr '\r\n' ' ' < /tmp/EUS/script_options)"; fi

# Create EUS database.
create_eus_database() {
  eus_create_directories "db"
  if [[ -z "$(command -v jq)" ]]; then return "1"; fi
  if ! [[ -s "${eus_dir}/db/db.json" ]] || ! jq empty "${eus_dir}/db/db.json" > /dev/null 2>&1; then
    uuid="$(cat /proc/sys/kernel/random/uuid 2>> /dev/null)"; if [[ -z "${uuid}" ]]; then uuid="$(uuidgen -r 2>> /dev/null)"; fi
    architecture="$("$(which dpkg)" --print-architecture)"
    jq -n \
      --arg uuid "${uuid}" \
      --arg os_codename "${os_codename}" \
      --arg architecture "${architecture}" \
      --arg script_name "${script_name}" \
      '
      {
        "database": {
          "uuid": "'"${uuid}"'",
          "support-file-upload": "false",
          "opt-in-requests": "0",
          "opt-in-rotations": "0",
          "distribution": "'"${os_codename}"'",
          "architecture": "'"${architecture}"'"
        },
        "scripts": {
          "'"${script_name}"'": {
            "aborts": "0",
            "success": "0",
            "total-runs": "0",
            "last-run": "'"$(date +%s)"'",
            "versions-ran": ["'"$(grep -im1 "# Script Version" "${script_location}" | awk -F'|' '{gsub(/[[:space:]]/, "", $2); print $2}')"'"],
            "support": {}
          }
        }
      }
      | if "'"${script_name}"'" == "UniFi Network Easy Update Script" or "'"${script_name}"'" == "UniFi Network Easy Installation Script" then
          .scripts["'"${script_name}"'"] |= . + {
            (
              if "'"${script_name}"'" == "UniFi Network Easy Update Script" then
                "upgrade-path"
              elif "'"${script_name}"'" == "UniFi Network Easy Installation Script" then
                "install-version"
              else
                empty
              end
            ): []
          }
        else
          .
        end
    ' &> "${eus_dir}/db/db.json"
  else
    jq --arg script_name "${script_name}" '
      .scripts |=
      if has("'"${script_name}"'") then
        .
      else
        .["'"${script_name}"'"] = {
          "aborts": "0",
          "success": "0",
          "total-runs": "0",
          "last-run": "'"$(date +%s)"'",
          "versions-ran": ["'"$(grep -im1 "# Script Version" "${script_location}" | awk -F'|' '{gsub(/[[:space:]]/, "", $2); print $2}')"'"],
          "support": {}
        } +
        (
          if "'"${script_name}"'" == "UniFi Network Easy Update Script" then
            {"upgrade-path": []}
          elif "'"${script_name}"'" == "UniFi Network Easy Installation Script" then
            {"install-version": []}
          else
            {}
          end
        )
      end
    '  "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
    eus_database_move
  fi
}
create_eus_database

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

# Original release of the Glenn R. APT Repository was /ubuntu and /debian, decided to get rid of that.
glennr_mongod_original_check() {
  while read -r glennr_repo_list; do
    if grep -qriIl "apt.glennr.nl/debian" "${glennr_repo_list}"; then
      sed -i 's/\/debian/\/repo/g' "${glennr_repo_list}" &> /dev/null
    elif grep -qriIl "apt.glennr.nl/ubuntu" "${glennr_repo_list}"; then
      sed -i 's/\/debian/\/repo/g' "${glennr_repo_list}" &> /dev/null
    fi
  done < <(grep -riIl "apt.glennr.nl/debian\\|apt.glennr.nl/ubuntu" /etc/apt/)
}
if grep -qriIl "apt.glennr.nl/debian\\|apt.glennr.nl/ubuntu" /etc/apt/; then glennr_mongod_original_check; fi

# Glenn R. MongoDB repository changes
glennr_mongod_repository_check() {
  if [[ "$(jq -r '.database["glennr-mongod-repository-check"]' "${eus_dir}/db/db.json" 2> /dev/null)" -lt "1733356800" ]]; then
    while read -r glennr_repo_list; do
      if [[ "${glennr_mongod_repository_check_date}" != "true" ]]; then echo -e "\\n------- $(date +%F-%T.%6N) -------\\n" &>> "${eus_dir}/logs/glennr-apt-repository-update.log"; glennr_mongod_repository_check_date="true"; fi
      if [[ "$("$(which dpkg)" -l apt | grep ^"ii" | awk '{print $2,$3}' | awk '{print $2}' | cut -d'.' -f1)" -gt "1" ]] || [[ "$("$(which dpkg)" -l apt | grep ^"ii" | awk '{print $2,$3}' | awk '{print $2}' | cut -d'.' -f1)" == "1" && "$("$(which dpkg)" -l apt | grep ^"ii" | awk '{print $2,$3}' | awk '{print $2}' | cut -d'.' -f2)" -ge "6" ]]; then
        apt-get update -o Dir::Etc::SourceList="${glennr_repo_list}" --allow-releaseinfo-change &>> "${eus_dir}/logs/glennr-apt-repository-update.log"
      else
        apt-get update -o Dir::Etc::SourceList="${glennr_repo_list}" &>> "${eus_dir}/logs/glennr-apt-repository-update.log"
      fi
    done < <(grep -riIl "apt.glennr.nl" /etc/apt/)
    glennr_mongod_repository_check_time="$(date +%s)"
    if [[ "$(dpkg-query --showformat='${version}' --show jq 2> /dev/null | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
      jq --arg glennr_mongod_repository_check_time "${glennr_mongod_repository_check_time}" '."database" += {"glennr-mongod-repository-check": "'"${glennr_mongod_repository_check_time}"'"}' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
    else
      jq --arg glennr_mongod_repository_check_time "$glennr_mongod_repository_check_time" '.database += {"glennr-mongod-repository-check": $glennr_mongod_repository_check_time}' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
    fi
    eus_database_move
  fi
}
if grep -qriIl "apt.glennr.nl" /etc/apt/; then glennr_mongod_repository_check; fi

# Remove older mongodb-key-check-time value, now lives in db.json
if [[ -e "${eus_dir}/data/mongodb-key-check-time" ]]; then rm --force "${eus_dir}/data/mongodb-key-check-time"; if [[ -d "${eus_dir}/data/" && -z "$(ls -A "${eus_dir}/data/")" ]]; then rmdir "${eus_dir}/data"; fi; fi

# Check if DST_ROOT certificate exists
if grep -siq "^mozilla/DST_Root" /etc/ca-certificates.conf; then
  echo -e "${GRAY_R}#${RESET} Detected DST_Root certificate..."
  if sed -i '/^mozilla\/DST_Root_CA_X3.crt$/ s/^/!/' /etc/ca-certificates.conf; then
    echo -e "${GREEN}#${RESET} Successfully commented out the DST_Root certificate! \\n"
    update-ca-certificates &> /dev/null
  else
    echo -e "${RED}#${RESET} Failed to comment out the DST_Root certificate... \\n"
  fi
fi

# Check if apt-key is deprecated
aptkey_depreciated() {
  if [[ "$("$(which dpkg)" -l apt | grep ^"ii" | awk '{print $2,$3}' | awk '{print $2}' | cut -d'.' -f1)" -gt "2" ]] || [[ "$("$(which dpkg)" -l apt | grep ^"ii" | awk '{print $2,$3}' | awk '{print $2}' | cut -d'.' -f1)" == "2" && "$("$(which dpkg)" -l apt | grep ^"ii" | awk '{print $2,$3}' | awk '{print $2}' | cut -d'.' -f2)" -ge "2" ]]; then apt_key_deprecated="true"; fi
  if [[ "${apt_key_deprecated}" != 'true' ]]; then
    apt-key list >/tmp/EUS/aptkeylist 2>&1
    if grep -ioq "apt-key is deprecated" /tmp/EUS/aptkeylist; then apt_key_deprecated="true"; fi
    rm --force /tmp/EUS/aptkeylist
  fi
}
aptkey_depreciated

# Cleanup EUS logs
while read -r log_file; do
  if [[ -f "${log_file}" ]]; then
    log_file_size="$(stat -c%s "${log_file}")"
    if [[ "${log_file_size}" -gt "10485760" ]]; then
      tail -n1000 "${log_file}" &> "${log_file}.tmp"
      mv "${log_file}.tmp" "${log_file}"
    fi
  fi
done < <(find "${eus_dir}/logs/" -type f 2> /dev/null)

check_package_cache_file_corruption() {
  if ls /tmp/EUS/apt/*.log 1> /dev/null 2>&1; then
    if grep -ioqE '^E: The package cache file is corrupted\\|^E: Problem with MergeList\\|^E: Unable to parse package file\\|Splitting up .* into data and signature failed' /tmp/EUS/apt/*.log; then
      rm -r /var/lib/apt/lists/* &> "${eus_dir}/logs/package-cache-corruption.log"
      mkdir /var/lib/apt/lists/partial &> "${eus_dir}/logs/package-cache-corruption.log"
      repository_changes_applied="true"
    fi
  fi
}

check_extended_states_corruption() {
  while IFS= read -r log_file; do
    if [[ -e "/var/lib/apt/extended_states" ]]; then
      mv "/var/lib/apt/extended_states" "/var/lib/apt/extended_states.EUS-corruption-detect-$(date +%s).bak" &>> "${eus_dir}/logs/apt-extended-states-corruption.log"
      repository_changes_applied="true"
    fi
    sed -i "s|Unable to parse package file /var/lib/apt/extended_states|Unable to parse package file (completed) /var/lib/apt/extended_states|g" "${log_file}" 2>> "${eus_dir}/logs/apt-extended-states-corruption.log"
  done < <(grep -slE '^E: Unable to parse package file /var/lib/apt/extended_states' /tmp/EUS/apt/*.log "${eus_dir}"/logs/*.log | sort -u 2>> /dev/null)
}

https_died_unexpectedly_check() {
  while IFS= read -r log_file; do
    if [[ -n "${GNUTLS_CPUID_OVERRIDE}" ]] && grep -sq "GNUTLS_CPUID_OVERRIDE=" "/etc/environment" &> /dev/null; then
      previous_value="$(grep "GNUTLS_CPUID_OVERRIDE=" "/etc/environment" | cut -d '=' -f2)"
      if [[ "${https_died_unexpectedly_check_logged_1}" != 'true' ]] && [[ "${previous_value}" == "0x1" ]]; then echo -e "$(date +%F-%T.%6N) | Previous GNUTLS_CPUID_OVERRIDE value is: ${previous_value}" &>> "${eus_dir}/logs/https-died-unexpectedly.log"; https_died_unexpectedly_check_logged_1="true"; fi
      if [[ "${previous_value}" != "0x1" ]]; then
        if sed -i 's/^GNUTLS_CPUID_OVERRIDE=.*/GNUTLS_CPUID_OVERRIDE=0x1/' "/etc/environment" &>> "${eus_dir}/logs/https-died-unexpectedly.log"; then
          echo -e "$(date +%F-%T.%6N) | Successfully updated GNUTLS_CPUID_OVERRIDE to 0x1!" &>> "${eus_dir}/logs/https-died-unexpectedly.log"
          # shellcheck disable=SC1091
          source /etc/environment
          repository_changes_applied="true"
        else
          echo -e "$(date +%F-%T.%6N) | Failed to update GNUTLS_CPUID_OVERRIDE to 0x1..." &>> "${eus_dir}/logs/https-died-unexpectedly.log"
        fi
      fi
    else
      echo -e "$(date +%F-%T.%6N) | Adding \"export GNUTLS_CPUID_OVERRIDE=0x1\" to /etc/environment..." &>> "${eus_dir}/logs/https-died-unexpectedly.log"
      if echo "export GNUTLS_CPUID_OVERRIDE=0x1" &>> /etc/environment; then
        echo -e "$(date +%F-%T.%6N) | Successfully added \"export GNUTLS_CPUID_OVERRIDE=0x1\" to /etc/environment..." &>> "${eus_dir}/logs/https-died-unexpectedly.log"
        # shellcheck disable=SC1091
        source /etc/environment
        repository_changes_applied="true"
      else
        echo -e "$(date +%F-%T.%6N) | Failed to add \"export GNUTLS_CPUID_OVERRIDE=0x1\" to /etc/environment..." &>> "${eus_dir}/logs/https-died-unexpectedly.log"
      fi
    fi
    sed -i "s/Method https has died unexpectedly\!/Method https has died unexpectedly (completed)\!/g" "${log_file}" 2>> "${eus_dir}/logs/https-died-unexpectedly.log"
  done < <(grep -slE '^E: Method https has died unexpectedly!' /tmp/EUS/apt/*.log "${eus_dir}"/logs/*.log | sort -u 2>> /dev/null)
}

check_time_date_for_repositories() {
  if ls /tmp/EUS/apt/*.log 1> /dev/null 2>&1; then
    if grep -ioqE '^E: Release file for .* is not valid yet \(invalid for another' /tmp/EUS/apt/*.log; then
      get_timezone
      if [[ -n "$(command -v jq)" ]]; then current_api_time="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/current-time?timezone=${timezone}" 2> /dev/null | jq -r '."current_time_ns"' 2> /dev/null | sed '/null/d')"; else current_api_time="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/current-time?timezone=${timezone}" 2> /dev/null | grep -o '"current_time_ns":"[^"]*"' | cut -d'"' -f4)"; fi
      if [[ "${current_api_time}" != "$(date +"%Y-%m-%d %H:%M")" ]]; then
        if command -v timedatectl &> /dev/null; then
          ntp_status="$(timedatectl show --property=NTP 2> /dev/null | awk -F '[=]' '{print $2}')"
          if [[ -z "${ntp_status}" ]]; then ntp_status="$(timedatectl status 2> /dev/null | grep -i ntp | cut -d':' -f2 | sed -e 's/ //g')"; fi
          if [[ -z "${ntp_status}" ]]; then ntp_status="$(timedatectl status 2> /dev/null | grep "systemd-timesyncd" | awk -F '[:]' '{print$2}' | sed -e 's/ //g')"; fi
          if [[ "${ntp_status}" == 'yes' ]]; then if "$(which dpkg)" -l systemd-timesyncd 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then timedatectl set-ntp false &>> "${eus_dir}/logs/invalid-time.log"; fi; fi
          if [[ -n "$(command -v jq)" ]]; then
            timedatectl set-time "$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/current-time?timezone=${timezone}" 2> /dev/null | jq -r '."current_time"' 2> /dev/null | sed '/null/d')" &>> "${eus_dir}/logs/invalid-time.log"
          else
            timedatectl set-time "$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/current-time?timezone=${timezone}" 2> /dev/null | grep -o '"current_time":"[^"]*"' | cut -d'"' -f4)" &>> "${eus_dir}/logs/invalid-time.log"
          fi
          if "$(which dpkg)" -l systemd-timesyncd 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then timedatectl set-ntp true &>> "${eus_dir}/logs/invalid-time.log"; fi
          repository_changes_applied="true"
        elif command -v date &> /dev/null; then
          if [[ -n "$(command -v jq)" ]]; then
            date +%Y%m%d -s "$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/current-time?timezone=${timezone}" 2> /dev/null | jq -r '."current_time"' 2> /dev/null | sed '/null/d' | cut -d' ' -f1)" &>> "${eus_dir}/logs/invalid-time.log"
            date +%T -s "$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/current-time?timezone=${timezone}" 2> /dev/null | jq -r '."current_time"' 2> /dev/null | sed '/null/d' | cut -d' ' -f2)" &>> "${eus_dir}/logs/invalid-time.log"
          else
            date +%Y%m%d -s "$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/current-time?timezone=${timezone}" 2> /dev/null | grep -o '"current_time":"[^"]*"' | cut -d'"' -f4 | cut -d' ' -f1)" &>> "${eus_dir}/logs/invalid-time.log"
            date +%T -s "$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/current-time?timezone=${timezone}" 2> /dev/null | grep -o '"current_time":"[^"]*"' | cut -d'"' -f4 | cut -d' ' -f2)" &>> "${eus_dir}/logs/invalid-time.log"
          fi
          repository_changes_applied="true"
        fi
      fi
    fi
  fi
}

cleanup_malformed_repositories() {
  if ls /tmp/EUS/apt/*.log 1> /dev/null 2>&1; then
    while IFS= read -r line; do
      if [[ "${cleanup_malformed_repositories_found_message}" != 'true' ]]; then
        echo -e "${GRAY_R}#${RESET} There appear to be malformed repositories..."
        cleanup_malformed_repositories_found_message="true"
      fi
      cleanup_malformed_repositories_file_path="$(echo "${line}" | sed -n 's/.*\(in sources file \|in source file \|in source list \|in list file \)\([^ ]*\).*/\2/p')"
      cleanup_malformed_repositories_line_number="$(echo "${line}" | cut -d':' -f2 | cut -d' ' -f1)"
      if [[ -f "${cleanup_malformed_repositories_file_path}" ]]; then
        echo -e "$(date +%F-%T.%6N) | Backing up file before modification: ${cleanup_malformed_repositories_file_path}" &>> "${eus_dir}/logs/cleanup-malformed-repository-lists.log"
        {
          echo "----- BEGIN ORIGINAL FILE: ${cleanup_malformed_repositories_file_path} -----"
          cat "${cleanup_malformed_repositories_file_path}"
          echo "----- END ORIGINAL FILE: ${cleanup_malformed_repositories_file_path} -----"
        } &>> "${eus_dir}/logs/cleanup-malformed-repository-lists.log"
        if [[ "${cleanup_malformed_repositories_file_path}" == *".sources" ]]; then
          # Handle deb822 format
          entry_block_start_line="$(awk -v cleanup_line="${cleanup_malformed_repositories_line_number}" 'BEGIN { block = 0; in_block = 0; start_line = 0 } /^[^#]/ { if (!in_block) { start_line = NR; in_block = 1; } } /^$/ { if (in_block) { block++; in_block = 0; if (block == cleanup_line) { print start_line; } } } END { if (in_block) { block++; if (block == cleanup_line) { print start_line; } } }' "${cleanup_malformed_repositories_file_path}")"
          entry_block_end_line="$(awk -v start_line="$entry_block_start_line" ' NR > start_line && NF == 0 { print NR-1; found=1; exit } NR > start_line { last_non_blank=NR } END { if (!found) print last_non_blank }' "${cleanup_malformed_repositories_file_path}")"
          if [[ -z "${entry_block_end_line}" ]]; then entry_block_end_line="${entry_block_start_line}"; fi
          sed -i "${entry_block_start_line},${entry_block_end_line}s/^/#/" "${cleanup_malformed_repositories_file_path}" &>> "${eus_dir}/logs/cleanup-malformed-repository-lists.log"
        elif [[ "${cleanup_malformed_repositories_file_path}" == *".list" ]]; then
          # Handle regular format
          sed -i "${cleanup_malformed_repositories_line_number}s/^/#/" "${cleanup_malformed_repositories_file_path}" &>> "${eus_dir}/logs/cleanup-malformed-repository-lists.log"
        else
          mv "${cleanup_malformed_repositories_file_path}" "${eus_dir}/repository/$(basename "${cleanup_malformed_repositories_file_path}").corrupted" &>> "${eus_dir}/logs/cleanup-malformed-repository-lists.log"
        fi
        cleanup_malformed_repositories_changes_made="true"
        echo -e "$(date +%F-%T.%6N) | Malformed repository commented out in '${cleanup_malformed_repositories_file_path}' at line $cleanup_malformed_repositories_line_number" &>> "${eus_dir}/logs/cleanup-malformed-repository-lists.log"
      else
        echo -e "$(date +%F-%T.%6N) | Warning: Invalid file path '${cleanup_malformed_repositories_file_path}'. Skipping." &>> "${eus_dir}/logs/cleanup-malformed-repository-lists.log"
      fi
    done < <(grep -E '^E: Malformed entry |^E: Malformed line |^E: Malformed stanza |^E: Type .* is not known on line' /tmp/EUS/apt/*.log | awk -F': Malformed entry |: Malformed line |: Malformed stanza |: Type .*is not known on line ' '{print $2}' | sort -u 2>> /dev/null)
    if [[ "${cleanup_malformed_repositories_changes_made}" = 'true' ]]; then
      echo -e "${GREEN}#${RESET} The malformed repositories have been commented out! \\n"
      repository_changes_applied="true"
    fi   
    unset cleanup_malformed_repositories_found_message
    unset cleanup_malformed_repositories_changes_made
  fi
}

cleanup_duplicated_repositories() {
  if ls /tmp/EUS/apt/*.log 1> /dev/null 2>&1; then
    while IFS= read -r line; do
      if [[ "${cleanup_duplicated_repositories_found_message}" != 'true' ]]; then
        echo -e "${GRAY_R}#${RESET} There appear to be duplicated repositories..."
        cleanup_duplicated_repositories_found_message="true"
      fi
      cleanup_duplicated_repositories_file_path="$(echo "${line}" | cut -d':' -f1)"
      cleanup_duplicated_repositories_line_number="$(echo "${line}" | cut -d':' -f2 | cut -d' ' -f1)"
      if [[ -f "${cleanup_duplicated_repositories_file_path}" ]]; then
        echo -e "$(date +%F-%T.%6N) | Backing up file before modification: ${cleanup_duplicated_repositories_file_path}" &>> "${eus_dir}/logs/cleanup-duplicate-repository-lists.log"
        {
          echo "----- BEGIN ORIGINAL FILE: ${cleanup_duplicated_repositories_file_path} -----"
          cat "${cleanup_duplicated_repositories_file_path}"
          echo "----- END ORIGINAL FILE: ${cleanup_duplicated_repositories_file_path} -----"
        } &>> "${eus_dir}/logs/cleanup-duplicate-repository-lists.log"
        if [[ "${cleanup_duplicated_repositories_file_path}" == *".sources" ]]; then
          # Handle deb822 format
          entry_block_start_line="$(awk 'BEGIN { block = 0 } { if ($0 ~ /^Types:/) { block++ } if (block == '"$cleanup_duplicated_repositories_line_number"') { print NR; exit } }' "${cleanup_duplicated_repositories_file_path}")"
          entry_block_end_line="$(awk -v start_line="$entry_block_start_line" ' NR > start_line && NF == 0 { print NR-1; found=1; exit } NR > start_line { last_non_blank=NR } END { if (!found) print last_non_blank }' "${cleanup_duplicated_repositories_file_path}")"
          if [[ -z "${entry_block_end_line}" ]]; then entry_block_end_line="${entry_block_start_line}"; fi
          sed -i "${entry_block_start_line},${entry_block_end_line}s/^\([^#]\)/# \1/" "${cleanup_duplicated_repositories_file_path}" &>> "${eus_dir}/logs/cleanup-duplicate-repository-lists.log"
        elif [[ "${cleanup_duplicated_repositories_file_path}" == *".list" ]]; then
          # Handle regular format
          sed -i "${cleanup_duplicated_repositories_line_number}s/^/#/" "${cleanup_duplicated_repositories_file_path}" &>> "${eus_dir}/logs/cleanup-duplicate-repository-lists.log"
        fi
        cleanup_duplicated_repositories_changes_made="true"
        echo -e "$(date +%F-%T.%6N) | Duplicates commented out in '${cleanup_duplicated_repositories_file_path}' at line $cleanup_duplicated_repositories_line_number" &>> "${eus_dir}/logs/cleanup-duplicate-repository-lists.log"
      else
        echo -e "$(date +%F-%T.%6N) | Warning: Invalid file path '${cleanup_duplicated_repositories_file_path}'. Skipping." &>> "${eus_dir}/logs/cleanup-duplicate-repository-lists.log"
      fi
    done < <(grep -E '^W: Target .+ is configured multiple times in ' "/tmp/EUS/apt/"*.log | awk -F' is configured multiple times in ' '{print $2}' | sort -u 2>> /dev/null)
    if [[ "${cleanup_duplicated_repositories_changes_made}" = 'true' ]]; then
      echo -e "${GREEN}#${RESET} The duplicated repositories have been commented out! \\n"
      repository_changes_applied="true"
    fi
    unset cleanup_duplicated_repositories_found_message
    unset cleanup_duplicated_repositories_changes_made
  fi
}

cleanup_unavailable_repositories() {
  if ls /tmp/EUS/apt/*.log 1> /dev/null 2>&1; then
    if ! [[ -e "${eus_dir}/logs/upgrade.log" ]]; then return; fi
    while read -r domain; do
      if grep -isq "certificate verification" "/tmp/EUS/apt/"*.log && [[ "${force_http_repositories}" != 'true' ]]; then force_http_repositories="true"; fi
      if ! grep -sq "^#.*${domain}" /etc/apt/sources.list /etc/apt/sources.list.d/*.list /etc/apt/sources.list.d/*.sources 2> /dev/null; then
        if [[ "${cleanup_unavailable_repositories_found_message}" != 'true' ]]; then
          echo -e "${GRAY_R}#${RESET} There are repositories that are causing issues..."
          cleanup_unavailable_repositories_found_message="true"
        fi
        for file in /etc/apt/sources.list.d/*.sources; do
          if grep -sq "${domain}" "${file}"; then
            entry_block_start_line="$(awk '!/^#/ && /Types:/ { types_line=NR } /'"${domain}"'/ && !/^#/ && !seen[types_line]++ { print types_line }' "${file}" | head -n1)"
            entry_block_end_line="$(awk -v start_line="$entry_block_start_line" 'NR > start_line && NF == 0 { print NR-1; exit } END { if (NR > start_line && NF > 0) print NR }' "${file}")"
            if [[ -z "${entry_block_end_line}" ]]; then entry_block_end_line="${entry_block_start_line}"; fi
            sed -i "${entry_block_start_line},${entry_block_end_line}s/^\([^#]\)/# \1/" "${file}" &>> "${eus_dir}/logs/cleanup-unavailable-repository-lists.log"
            cleanup_unavailable_repositories_changes_made="true"
            echo -e "$(date +%F-%T.%6N) | Unavailable repository with domain ${domain} has been commented out in '${file}'" &>> "${eus_dir}/logs/cleanup-unavailable-repository-lists.log"
          fi
        done
        if sed -i -e "/^[^#].*${domain}/ s|^deb|# deb|g" /etc/apt/sources.list /etc/apt/sources.list.d/*.list &>> "${eus_dir}/logs/cleanup-unavailable-repository-lists.log"; then
          cleanup_unavailable_repositories_changes_made="true"
          echo -e "$(date +%F-%T.%6N) | Unavailable repository with domain ${domain} has been commented out" &>> "${eus_dir}/logs/cleanup-unavailable-repository-lists.log"
        fi
      fi
    done < <(awk '/Unauthorized|Failed/ {for (i=1; i<=NF; i++) if ($i ~ /^https?:\/\/([^\/]+)/) {split($i, parts, "/"); print parts[3]}}' "/tmp/EUS/apt/"*.log | sort -u 2>> /dev/null)
    if [[ "${cleanup_unavailable_repositories_changes_made}" = 'true' ]]; then
      echo -e "${GREEN}#${RESET} Repositories causing errors have been commented out! \\n"
      repository_changes_applied="true"
    fi
    unset cleanup_unavailable_repositories_found_message
    unset cleanup_unavailable_repositories_changes_made
  fi
}

cleanup_conflicting_repositories() {
  if ls /tmp/EUS/apt/*.log 1> /dev/null 2>&1; then
    while IFS= read -r logfile; do
      while IFS= read -r line; do
        if [[ ${line} == *"Conflicting values set for option Trusted regarding source"* ]]; then
          if [[ "${cleanup_conflicting_repositories_found_message_1}" != 'true' ]]; then
            echo -e "${GRAY_R}#${RESET} There appear to be repositories with conflicting details..."
            cleanup_conflicting_repositories_found_message_1="true"
          fi
          # Extract the conflicting source URL and remove trailing slash
          source_url="$(echo "${line}" | grep -oP 'source \Khttps?://[^ /]*' | sed -e 's/ //g' -e 's/http[s]:\/\///g')"
          # Extract package name and version from the conflicting source URL
          package_name="$(echo "${line}" | awk -F'/' '{print $(NF-1)}' | sed 's/ //g')"
          version="$(echo "${line}" | awk -F'/' '{print $NF}' | sed 's/ //g')"
          # Loop through each file and awk to comment out the conflicting source
          while read -r file_with_conflict; do
            if [[ "${cleanup_conflicting_repositories_message_1}" != 'true' ]]; then
              echo -e "$(date +%F-%T.%6N) | Conflicting Trusted values for ${source_url}" &>> "${eus_dir}/logs/trusted-repository-conflict.log"
              cleanup_conflicting_repositories_message_1="true"
            fi
            if [[ "${file_with_conflict}" == *".sources" ]]; then
              # Handle deb822 format
              entry_block_start_line="$(awk -v source_url="${source_url}" '!/^#/ && /Types:/ { types_line=NR } index($0, source_url) && !/^#/ && !seen[types_line]++ { print types_line }' "${file_with_conflict}" | head -n1)"
              entry_block_end_line="$(awk -v start_line="$entry_block_start_line" 'NR > start_line && NF == 0 { print NR-1; exit } END { if (NR > start_line && NF > 0) print NR }' "${file_with_conflict}")"
              if [[ -z "${entry_block_end_line}" ]]; then entry_block_end_line="${entry_block_start_line}"; fi
              sed -i "${entry_block_start_line},${entry_block_end_line}s/^\([^#]\)/# \1/" "${file_with_conflict}" &>> "${eus_dir}/logs/trusted-repository-conflict.log"
            elif [[ "${file_with_conflict}" == *".list" ]]; then
              # Handle regular format
              if awk -v source="${source_url}" -v package="${package_name}" -v ver="${version}" '
                $0 ~ source && $0 ~ package && $0 ~ ver {
                  if ($0 !~ /^#/) {
                    print "#" $0;
                  } else {
                    print $0;
                  }
                  next
                } 
                1' "${file_with_conflict}" &> tmpfile; then mv tmpfile "${file_with_conflict}" &> /dev/null; cleanup_conflicting_repositories_changes_made="true"; fi
            fi
            echo -e "$(date +%F-%T.%6N) | awk command executed for ${file_with_conflict}" &>> "${eus_dir}/logs/trusted-repository-conflict.log"
          done < <(grep -sl "^deb.*${source_url}.*${package_name}.*${version}\\|^URIs: .*${source_url}" /etc/apt/sources.list /etc/apt/sources.list.d/* /etc/apt/sources.list.d/*.sources | awk '!NF || !seen[$0]++')
          break
        elif [[ ${line} == *"Conflicting values set for option Signed-By regarding source"* ]]; then
          if [[ "${cleanup_conflicting_repositories_found_message_2}" != 'true' ]]; then
            echo -e "${GRAY_R}#${RESET} There appear to be repositories with conflicting details..."
            cleanup_conflicting_repositories_found_message_2="true"
          fi
          # Extract the conflicting source URL and keys
          conflicting_source="$(echo "${line}" | grep -oP 'https?://[^ ]+' | sed -e 's/\/$//' -e 's/http[s]:\/\///g')"  # Remove trailing slash and http[s]://
          key1="$(echo "${line}" | grep -oP '/\S+\.gpg' | head -n 1 | sed 's/ //g')"
          key2="$(echo "${line}" | grep -oP '!= \S+\.gpg' | sed 's/!= //g' | sed 's/ //g')"
          # Loop through each file and awk to comment out the conflicting source
          while read -r file_with_conflict; do
            if [[ "${cleanup_conflicting_repositories_message_2}" != 'true' ]]; then
              echo -e "$(date +%F-%T.%6N) | Conflicting Signed-By values for ${conflicting_source}" &>> "${eus_dir}/logs/signed-by-repository-conflict.log"
              echo -e "$(date +%F-%T.%6N) | Conflicting keys: ${key1} != ${key2}" &>> "${eus_dir}/logs/signed-by-repository-conflict.log"
              cleanup_conflicting_repositories_message_2="true"
            fi
            if [[ "${file_with_conflict}" == *".sources" ]]; then
              # Handle deb822 format
              entry_block_start_line="$(awk -v conflicting_source="${conflicting_source}" '!/^#/ && /Types:/ { types_line=NR } index($0, conflicting_source) && !/^#/ && !seen[types_line]++ { print types_line }' "${file_with_conflict}" | head -n1)"
              entry_block_end_line="$(awk -v start_line="$entry_block_start_line" 'NR > start_line && NF == 0 { print NR-1; exit } END { if (NR > start_line && NF > 0) print NR }' "${file_with_conflict}")"
              if [[ -z "${entry_block_end_line}" ]]; then entry_block_end_line="${entry_block_start_line}"; fi
              sed -i "${entry_block_start_line},${entry_block_end_line}s/^\([^#]\)/# \1/" "${file_with_conflict}" &>> "${eus_dir}/logs/trusted-repository-conflict.log"
            elif [[ "${file_with_conflict}" == *".list" ]]; then
              # Handle regular format
              if awk -v source="${conflicting_source}" -v key1="${key1}" -v key2="${key2}" '
                !/^#/ && $0 ~ source && ($0 ~ key1 || $0 ~ key2) {
                  print "#" $0;
                  next
                } 
                1' "${file_with_conflict}" &> tmpfile; then mv tmpfile "${file_with_conflict}" &> /dev/null; cleanup_conflicting_repositories_changes_made="true"; fi
            fi
            echo -e "$(date +%F-%T.%6N) | awk command executed for ${file_with_conflict}" &>> "${eus_dir}/logs/signed-by-repository-conflict.log"
          done < <(grep -sl "^deb.*${conflicting_source}\\|^URIs: .*${conflicting_source}" /etc/apt/sources.list /etc/apt/sources.list.d/* /etc/apt/sources.list.d/*.sources | awk '!NF || !seen[$0]++')
          break
        fi
      done < "${logfile}"
    done < <(grep -il "Conflicting values set for option Trusted regarding source\|Conflicting values set for option Signed-By regarding source" "/tmp/EUS/apt/"*.log 2>> /dev/null)
    if [[ "${cleanup_conflicting_repositories_changes_made}" = 'true' ]]; then
      echo -e "${GREEN}#${RESET} Repositories causing errors have been commented out! \\n"
      repository_changes_applied="true"
    fi
    unset cleanup_conflicting_repositories_found_message_1
    unset cleanup_conflicting_repositories_found_message_2
    unset cleanup_conflicting_repositories_changes_made
  fi
}

eus_apt_sha1_needed() {
  grep -qsiE 'SHA1 is not considered secure|Policy rejected|second pre-image resistance|sqv returned an error code' /tmp/EUS/apt/apt-update.log
}

eus_apt_sha1_enable() {
  [[ -n "$EUS_APT_SHA1_POLICY_FILE" ]] && return 0
  echo -e "$(date +%F-%T.%6N) | Enabling SHA-1 workaround for apt." &>> "${eus_dir}/logs/apt-sha1-workaround.log"
  if [[ "${silent_run_apt_get_update}" != "true" ]]; then
    echo -e "${GRAY_R}#${RESET} Enabling SHA-1 workaround for apt..."
  fi
  EUS_APT_SHA1_POLICY_FILE="$(mktemp)" || {
    echo -e "$(date +%F-%T.%6N) | Failed to enable the SHA-1 workaround (mktemp)." &>> "${eus_dir}/logs/apt-sha1-workaround.log"
    return 1
  }
  printf '%s\n' '[hash_algorithms]' 'sha1 = "always"' > "$EUS_APT_SHA1_POLICY_FILE" || {
    echo -e "$(date +%F-%T.%6N) | Failed to enable the SHA-1 workaround (write policy)." &>> "${eus_dir}/logs/apt-sha1-workaround.log"
    return 1
  }
  chmod 0644 "$EUS_APT_SHA1_POLICY_FILE" 2>/dev/null || true
  if [[ -r "$EUS_APT_SHA1_POLICY_FILE" ]]; then
    EUS_APT_ENV=( env APT_SEQUOIA_CRYPTO_POLICY="$EUS_APT_SHA1_POLICY_FILE" )
    echo -e "$(date +%F-%T.%6N) | Successfully enabled the SHA-1 workaround." &>> "${eus_dir}/logs/apt-sha1-workaround.log"
    if [[ "${silent_run_apt_get_update}" != "true" ]]; then
      echo -e "${GREEN}#${RESET} Successfully enabled the SHA-1 workaround! \\n"
    fi
    return 0
  fi
  echo -e "$(date +%F-%T.%6N) | Failed to enable the SHA-1 workaround (policy not readable)." &>> "${eus_dir}/logs/apt-sha1-workaround.log"
  if [[ "${silent_run_apt_get_update}" != "true" ]]; then
    echo -e "${RED}#${RESET} Failed to enable the SHA-1 workaround... \\n"
  fi
  return 1
}

eus_apt_sha1_disable() {
  [[ -z "$EUS_APT_SHA1_POLICY_FILE" ]] && return 0
  echo -e "$(date +%F-%T.%6N) | Disabling the SHA-1 workaround for apt." &>> "${eus_dir}/logs/apt-sha1-workaround.log"
  if [[ "${silent_run_apt_get_update}" != "true" ]]; then
    echo -e "${GRAY_R}#${RESET} Disabling the SHA-1 workaround for apt..."
  fi
  if rm -f "$EUS_APT_SHA1_POLICY_FILE"; then
    EUS_APT_SHA1_POLICY_FILE=""
    EUS_APT_ENV=()
    echo -e "$(date +%F-%T.%6N) | Successfully disabled the SHA-1 workaround." &>> "${eus_dir}/logs/apt-sha1-workaround.log"
    if [[ "${silent_run_apt_get_update}" != "true" ]]; then
      echo -e "${GREEN}#${RESET} Successfully disabled the SHA-1 workaround! \\n"
    fi
    return 0
  fi
  echo -e "$(date +%F-%T.%6N) | Failed to disable the SHA-1 workaround." &>> "${eus_dir}/logs/apt-sha1-workaround.log"
  if [[ "${silent_run_apt_get_update}" != "true" ]]; then
    echo -e "${RED}#${RESET} Failed to disable the SHA-1 workaround... \\n"
  fi
  return 1
}

trap eus_apt_sha1_disable EXIT

run_apt_get_update_with_sha1_fallback() {
  eus_apt_sha1_disable
  run_apt_get_update
  if eus_apt_sha1_needed; then
    echo -e "$(date +%F-%T.%6N) | SHA-1 signature rejection detected; retrying apt-get update with workaround." &>> "${eus_dir}/logs/apt-sha1-workaround.log"
    if eus_apt_sha1_enable; then
      run_apt_get_update
      eus_apt_sha1_disable
    fi
  fi
}

run_apt_get_update() {
  eus_directory_location="/tmp/EUS"
  eus_create_directories "apt"
  if [[ "${run_with_apt_fix_missing}" == 'true' ]] || [[ -z "${afm_first_run}" ]]; then apt_fix_missing_option="--fix-missing"; afm_first_run="1"; unset run_with_apt_fix_missing; IFS=' ' read -r -a apt_fix_missing <<< "${apt_fix_missing_option}"; fi
  if [[ "${silent_run_apt_get_update}" != "true" ]]; then echo -e "${GRAY_R}#${RESET} Running apt-get update..."; fi
  echo -e "\\n------- $(date +%F-%T.%6N) -------\\n" &>> "${eus_dir}/logs/apt-update.log"
  if "${EUS_APT_ENV[@]}" apt-get update "${apt_fix_missing[@]}" 2>&1 | tee -a "${eus_dir}/logs/apt-update.log" > /tmp/EUS/apt/apt-update.log; then
    if [[ "${PIPESTATUS[0]}" -eq "0" ]]; then
      if [[ "${silent_run_apt_get_update}" != "true" ]]; then echo -e "${GREEN}#${RESET} Successfully ran apt-get update! \\n"; fi
    else
      if [[ "${silent_run_apt_get_update}" != "true" ]]; then echo -e "${YELLOW}#${RESET} Something went wrong during running apt-get update! \\n"; fi
    fi
  fi
  if grep -ioq "fix-missing" /tmp/EUS/apt/apt-update.log; then run_with_apt_fix_missing="true"; return; else unset apt_fix_missing; fi
  grep -o 'NO_PUBKEY.*' /tmp/EUS/apt/apt-update.log | sed 's/NO_PUBKEY //g' | tr ' ' '\n' | awk '!a[$0]++' &> /tmp/EUS/apt/missing_keys
  if [[ -s "/tmp/EUS/apt/missing_keys_done" || -s "/tmp/EUS/apt/missing_keys_failed" ]]; then
    while read -r key_done; do
      if grep -ioq "${key_done}" /tmp/EUS/apt/missing_keys; then sed -i "/${key_done}/d" /tmp/EUS/apt/missing_keys; fi
    done < <(cat /tmp/EUS/apt/missing_keys_done /tmp/EUS/apt/missing_keys_failed 2> /dev/null)
  fi
  if [[ -s /tmp/EUS/apt/missing_keys ]]; then
    if "$(which dpkg)" -l dirmngr 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
      while read -r key; do
        if [[ -z "${key}" ]]; then continue; fi
        if [[ "${silent_run_apt_get_update}" != "true" ]]; then echo -e "${GRAY_R}#${RESET} Key ${key} is missing.. adding!"; fi
        locate_http_proxy
        if [[ -n "$http_proxy" ]]; then
          if apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --keyserver-options http-proxy="${http_proxy}" --recv-keys "$key" &>> "${eus_dir}/logs/key-recovery.log"; then
            echo "${key}" &>> /tmp/EUS/apt/missing_keys_done
            unset fail_key
            if [[ "${silent_run_apt_get_update}" != "true" ]]; then echo -e "${GREEN}#${RESET} Successfully added key ${key}!\\n"; fi
          else
            fail_key="true"
          fi
        elif [[ -f /etc/apt/apt.conf ]]; then
          apt_http_proxy="$(grep "http.*Proxy" /etc/apt/apt.conf | awk '{print $2}' | sed 's/[";]//g')"
          if [[ -n "${apt_http_proxy}" ]]; then
            if apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --keyserver-options http-proxy="${apt_http_proxy}" --recv-keys "$key" &>> "${eus_dir}/logs/key-recovery.log"; then
              echo "${key}" &>> /tmp/EUS/apt/missing_keys_done
              unset fail_key
              if [[ "${silent_run_apt_get_update}" != "true" ]]; then echo -e "${GREEN}#${RESET} Successfully added key ${key}!\\n"; fi
            else
              fail_key="true"
            fi
          fi
        else
          if apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv "$key" &>> "${eus_dir}/logs/key-recovery.log"; then echo "${key}" &>> /tmp/EUS/apt/missing_keys_done; if [[ "${silent_run_apt_get_update}" != "true" ]]; then echo -e "${GREEN}#${RESET} Successfully added key ${key}!\\n"; fi; else fail_key="true"; fi
        fi
        if [[ "${fail_key}" == 'true' ]]; then
          if [[ "${silent_run_apt_get_update}" != "true" ]]; then echo -e "${RED}#${RESET} Failed to add key ${key}... \\n"; fi
          if [[ "${silent_run_apt_get_update}" != "true" ]]; then echo -e "${GRAY_R}#${RESET} Trying different method to get key: ${key}"; fi
          gpg -vvv --debug-all --keyserver keyserver.ubuntu.com --recv-keys "${key}" &> /tmp/EUS/apt/failed_key
          debug_key="$(grep "KS_GET" /tmp/EUS/apt/failed_key | grep -io "0x.*")"
          if curl "${curl_argument[@]}" "https://keyserver.ubuntu.com/pks/lookup?op=get&search=${debug_key}" | gpg -o "/tmp/EUS/apt/EUS-${key}.gpg" --dearmor --yes &> /dev/null; then
            if mv "/tmp/EUS/apt/EUS-${key}.gpg" /etc/apt/trusted.gpg.d/; then
              if [[ "${silent_run_apt_get_update}" != "true" ]]; then echo -e "${GREEN}#${RESET} Successfully added key ${key}!\\n"; fi
              repository_key_location="/etc/apt/trusted.gpg.d/EUS-${key}.gpg"
              check_repository_key_permissions
              echo "${key}" &>> /tmp/EUS/apt/missing_keys_done
            else
              if [[ "${silent_run_apt_get_update}" != "true" ]]; then echo -e "${RED}#${RESET} Failed to add key ${key}... \\n"; fi
              echo "${key}" &>> /tmp/EUS/apt/missing_keys_failed
            fi
          else
            if [[ "${silent_run_apt_get_update}" != "true" ]]; then echo -e "${RED}#${RESET} Failed to add key ${key}... \\n"; fi
            echo "${key}" &>> /tmp/EUS/apt/missing_keys_failed
          fi
          unset fail_key
        fi
        sleep 1
      done < /tmp/EUS/apt/missing_keys
    else
      if [[ "${silent_run_apt_get_update}" != "true" ]]; then echo -e "${GRAY_R}#${RESET} Keys appear to be missing..."; fi; sleep 1
      if [[ "${silent_run_apt_get_update}" != "true" ]]; then echo -e "${YELLOW}#${RESET} Required package dirmngr is missing... cannot recover keys... \\n"; fi
    fi
    "${EUS_APT_ENV[@]}" apt-get update &> /tmp/EUS/apt/apt-update.log
    if "$(which dpkg)" -l dirmngr 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then if grep -qo 'NO_PUBKEY.*' /tmp/EUS/apt/apt-update.log; then run_apt_get_update; fi; fi
  fi
  check_package_cache_file_corruption
  check_extended_states_corruption
  https_died_unexpectedly_check
  check_time_date_for_repositories
  cleanup_malformed_repositories
  cleanup_duplicated_repositories
  cleanup_unavailable_repositories
  cleanup_conflicting_repositories
  if [[ "${repository_changes_applied}" == 'true' ]]; then unset repository_changes_applied; run_apt_get_update_with_sha1_fallback; fi
  unset silent_run_apt_get_update
}

check_add_mongodb_repo_variable() {
  if [[ -e "/tmp/EUS/mongodb/check_add_mongodb_repo_variable" ]]; then rm --force "/tmp/EUS/mongodb/check_add_mongodb_repo_variable" &> /dev/null; fi
  check_add_mongodb_repo_variables=( "add_mongodb_30_repo" "add_mongodb_32_repo" "add_mongodb_34_repo" "add_mongodb_36_repo" "add_mongodb_40_repo" "add_mongodb_42_repo" "add_mongodb_44_repo" "add_mongodb_50_repo" "add_mongod_50_repo" "add_mongodb_60_repo" "add_mongod_60_repo" "add_mongodb_70_repo" "add_mongod_70_repo" "add_mongodb_80_repo" "add_mongod_80_repo" )
  for mongodb_repo_variable in "${check_add_mongodb_repo_variables[@]}"; do if [[ "${!mongodb_repo_variable}" == 'true' ]]; then if echo "${mongodb_repo_variable}" &>> /tmp/EUS/mongodb/check_add_mongodb_repo_variable; then unset "${mongodb_repo_variable}"; fi; fi; done
}

reverse_check_add_mongodb_repo_variable() {
  local add_mongodb_repo_variable
  if [[ -e "/tmp/EUS/mongodb/check_add_mongodb_repo_variable" ]]; then
    while read -r add_mongodb_repo_variable; do
      declare -n add_mongodb_xx_repo="$add_mongodb_repo_variable"
      # shellcheck disable=SC2034
      add_mongodb_xx_repo="true"
    done < "/tmp/EUS/mongodb/check_add_mongodb_repo_variable"
  fi
}

# https://github.com/AmazedMender16/mongodb-no-avx-patch
add_glennr_mongod_repo() {
  check_dns apt.glennr.nl
  if [[ "${force_http_repositories}" != 'true' ]]; then repo_http_https="https"; else repo_http_https="http"; fi
  glennr_mongod_v="$("$(which dpkg)" -l | grep "${gr_mongod_name}" | grep -i "^ii\\|^hi\\|^ri\\|^pi\\|^ui" | awk '{print $3}' | sed 's/\.//g' | sed 's/.*://' | sed 's/-.*//g' | sed 's/+.*//g' | sort -V | tail -n 1)"
  if [[ "${glennr_mongod_v::2}" == '50' ]] || [[ "${add_mongod_50_repo}" == 'true' ]]; then
    mongod_version_major_minor="5.0"
    mongod_repo_type="mongod/5.0"
  fi
  if [[ "${glennr_mongod_v::2}" == '60' ]] || [[ "${add_mongod_60_repo}" == 'true' ]]; then
    mongod_version_major_minor="6.0"
    mongod_repo_type="mongod/6.0"
  fi
  if [[ "${glennr_mongod_v::2}" == '70' ]] || [[ "${add_mongod_70_repo}" == 'true' ]]; then
    mongod_version_major_minor="7.0"
    mongod_repo_type="mongod/7.0"
  fi
  if [[ "${glennr_mongod_v::2}" == '80' ]] || [[ "${add_mongod_80_repo}" == 'true' ]]; then
    mongod_version_major_minor="8.0"
    mongod_repo_type="mongod/8.0"
  fi
  if [[ "${os_codename}" =~ (stretch) ]]; then
    mongod_codename="repo stretch"
  elif [[ "${os_codename}" =~ (buster|bullseye|bookworm|trixie|forky) ]]; then
    mongod_codename="repo ${os_codename}"
  elif [[ "${os_codename}" =~ (unstable) ]]; then
    mongod_codename="repo forky"
  elif [[ "${os_codename}" =~ (utopic|vivid|wily|yakkety|zesty|artful|xenial|sarah|serena|sonya|sylvia|loki) ]]; then
    mongod_codename="repo xenial"
  elif [[ "${os_codename}" =~ (bionic|tara|tessa|tina|tricia|hera|juno) ]]; then
    mongod_codename="repo bionic"
  elif [[ "${os_codename}" =~ (focal|groovy|hirsute|impish) ]]; then
    mongod_codename="repo focal"
  elif [[ "${os_codename}" =~ (jammy|kinetic|lunar|mantic) ]]; then
    mongod_codename="repo jammy"
  elif [[ "${os_codename}" =~ (noble|oracular) ]]; then
    mongod_codename="repo noble"
  elif [[ "${os_codename}" =~ (plucky|questing|resolute) ]]; then
    mongod_codename="repo plucky"
  else
    mongod_codename="repo xenial"
  fi
  if [[ "${try_http_glennr_mongod_repo}" == 'true' ]]; then repo_http_https="http"; try_http_glennr_mongod_repo_text_1=" using the HTTP protocol"; try_http_glennr_mongod_repo_text_2=" with the HTTP protocol"; fi
  if [[ -n "${mongod_version_major_minor}" ]]; then
    if ! gpg --list-packets "/etc/apt/keyrings/apt-glennr.gpg" &> /dev/null; then
      echo -e "${GRAY_R}#${RESET} Adding key for the Glenn R. APT Repository..."
      aptkey_depreciated
      if [[ "${apt_key_deprecated}" == 'true' ]]; then
        echo -e "$(date +%F-%T.%6N) | apt.glennr.nl repository key.\\n" &>> "${eus_dir}/logs/repository-keys.log"
        if curl "${curl_argument[@]}" -fSL "${repo_http_https}://get.glennr.nl/apt/keys/apt-glennr.asc" 2>&1 | tee -a "${eus_dir}/logs/repository-keys.log" | gpg -o "/etc/apt/keyrings/apt-glennr.gpg" --dearmor --yes &> /dev/null; then
          glennr_curl_exit_status="${PIPESTATUS[0]}"
          glennr_gpg_exit_status="${PIPESTATUS[2]}"
          if [[ "${glennr_curl_exit_status}" -eq "0" && "${glennr_gpg_exit_status}" -eq "0" && -s "/etc/apt/keyrings/apt-glennr.gpg" ]]; then
            echo -e "${GREEN}#${RESET} Successfully added the key for the Glenn R. APT Repository! \\n"
            signed_by_value=" signed-by=/etc/apt/keyrings/apt-glennr.gpg"; deb822_signed_by_value="\nSigned-By: /etc/apt/keyrings/apt-glennr.gpg"
            repository_key_location="/etc/apt/keyrings/apt-glennr.gpg"; check_repository_key_permissions
          else
            abort_reason="Failed to add the key for the Glenn R. APT Repository."
            abort
          fi
        fi
      else
        echo -e "$(date +%F-%T.%6N) | apt.glennr.nl repository key.\\n" &>> "${eus_dir}/logs/repository-keys.log"
        if curl "${curl_argument[@]}" -fSL "${repo_http_https}://get.glennr.nl/apt/keys/apt-glennr.asc" 2>&1 | tee -a "${eus_dir}/logs/repository-keys.log" | apt-key add - &> /dev/null; then
          glennr_curl_exit_status="${PIPESTATUS[0]}"
          glennr_apt_key_exit_status="${PIPESTATUS[2]}"
          if [[ "${glennr_curl_exit_status}" -eq "0" && "${glennr_apt_key_exit_status}" -eq "0" ]]; then
            echo -e "${GREEN}#${RESET} Successfully added the key for the Glenn R. APT Repository! \\n"
          else
            abort_reason="Failed to add the key for the Glenn R. APT Repository."
            abort
          fi
        fi
      fi
    else
      if [[ "${apt_key_deprecated}" == 'true' ]]; then signed_by_value=" signed-by=/etc/apt/keyrings/apt-glennr.gpg"; deb822_signed_by_value="\nSigned-By: /etc/apt/keyrings/apt-glennr.gpg"; fi
    fi
    echo -e "${GRAY_R}#${RESET} Adding the Glenn R. APT repository for mongod ${mongod_version_major_minor}${try_http_glennr_mongod_repo_text_1}..."
    if [[ "${architecture}" == 'arm64' ]]; then arch="arch=arm64"; elif [[ "${architecture}" == 'amd64' ]]; then arch="arch=amd64"; else arch="arch=amd64,arm64"; fi
    if [[ "${use_deb822_format}" == 'true' ]]; then
      # DEB822 format
      mongod_repo_entry="Types: deb\nURIs: ${repo_http_https}://apt.glennr.nl/$(echo "${mongod_codename}" | awk -F" " '{print $1}')\nSuites: $(echo "${mongod_codename}" | awk -F" " '{print $2}')\nComponents: ${mongod_repo_type}\nArchitectures: ${arch//arch=/}${deb822_signed_by_value}"
    else
      # Traditional format
      mongod_repo_entry="deb [ ${arch}${signed_by_value} ] ${repo_http_https}://apt.glennr.nl/${mongod_codename} ${mongod_repo_type}"
    fi
    if echo -e "${mongod_repo_entry}" &> "/etc/apt/sources.list.d/glennr-mongod-${mongod_version_major_minor}.${source_file_format}"; then
      echo -e "${GREEN}#${RESET} Successfully added the Glenn R. APT repository for mongod ${mongod_version_major_minor}${try_http_glennr_mongod_repo_text_2}!\\n"
      glennr_mongod_repository_check
      if [[ "${mongodb_key_update}" != 'true' ]]; then
        run_apt_get_update_with_sha1_fallback
        mongod_upgrade_to_version_with_dot="$(apt-cache policy "${gr_mongod_name}" | grep -i "${mongo_version_max_with_dot}" | grep -i Candidate | sed -e 's/ //g' -e 's/*//g' | cut -d':' -f2)"
        if [[ -z "${mongod_upgrade_to_version_with_dot}" ]]; then mongod_upgrade_to_version_with_dot="$(apt-cache policy "${gr_mongod_name}" | grep -i "${mongo_version_max_with_dot}" | sed -e 's/500//g' -e 's/-1//g' -e 's/100//g' -e 's/ //g' -e '/http/d' -e 's/*//g' | cut -d':' -f2 | sed '/mongod/d' | sed 's/*//g' | sort -r -V | head -n 1)"; fi
        if [[ -z "${mongod_upgrade_to_version_with_dot}" && "${try_http_glennr_mongod_repo}" != "true" ]]; then try_http_glennr_mongod_repo="true"; add_glennr_mongod_repo; return; fi
        mongod_upgrade_to_version="${mongod_upgrade_to_version_with_dot//./}"
        if [[ "${mongod_upgrade_to_version::2}" == "${mongo_version_max}" ]]; then
          install_mongod_version="${mongod_upgrade_to_version_with_dot}"
          install_mongod_version_with_equality_sign="=${mongod_upgrade_to_version_with_dot}"
        fi
      fi
    else
      abort_reason="Failed to add the Glenn R. APT repository for mongod ${mongod_version_major_minor}${try_http_glennr_mongod_repo_text_2}."
      abort
    fi
  fi
  unset glennr_mongod_v
  unset signed_by_value
  unset deb822_signed_by_value
  unset try_http_glennr_mongod_repo_text_1
  unset try_different_mongodb_repo_test_2
}

add_extra_repo_mongodb() {
  unset repo_component
  unset repo_url
  if [[ "${os_codename}" =~ (precise|trusty|utopic|vivid|wily|yakkety|zesty|artful|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing|resolute) ]]; then
    if [[ "${architecture}" =~ (amd64|i386) ]]; then
      if [[ "${add_extra_repo_mongodb_security}" == 'true' ]]; then
        get_repo_url_security_url="true"
        get_repo_url
        repo_codename_argument="-security"
        repo_component="main"
      fi
    else
      repo_url="${http_or_https}://ports.ubuntu.com"
    fi
  fi
  if [[ -z "${repo_component}" ]]; then repo_component="main"; fi
  if [[ -z "${repo_url}" ]]; then get_repo_url; fi
  repo_codename="${add_extra_repo_mongodb_codename}"
  get_repo_url
  add_repositories
  unset add_extra_repo_mongodb_security
  unset add_extra_repo_mongodb_codename
}

add_mongodb_repo() {
  if [[ "${glennr_compiled_mongod}" == 'true' ]] || "$(which dpkg)" -l "${gr_mongod_name}" 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then add_glennr_mongod_repo; fi
  check_dns repo.mongodb.org
  # if any "add_mongodb_xx_repo" is true, (set skip_mongodb_org_v to true, this is disabled).
  mongodb_add_repo_variables=( "add_mongodb_30_repo" "add_mongodb_32_repo" "add_mongodb_34_repo" "add_mongodb_36_repo" "add_mongodb_40_repo" "add_mongodb_42_repo" "add_mongodb_44_repo" "add_mongodb_50_repo" "add_mongod_50_repo" "add_mongodb_60_repo" "add_mongod_60_repo" "add_mongodb_70_repo" "add_mongod_70_repo" "add_mongodb_80_repo" "add_mongod_80_repo" )
  for add_repo_variable in "${mongodb_add_repo_variables[@]}"; do if [[ "${!add_repo_variable}" == 'true' ]]; then mongodb_add_repo_variables_true_statements+=("${add_repo_variable}"); fi; done
  if [[ "${mongodb_key_update}" == 'true' ]]; then skip_mongodb_org_v="true"; fi
  if [[ "${skip_mongodb_org_v}" != 'true' ]]; then
    if "$(which dpkg)" -l "${gr_mongod_name}" 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
      mongodb_org_v="$("$(which dpkg)" -l | grep "${gr_mongod_name}" | grep -i "^ii\\|^hi\\|^ri\\|^pi\\|^ui" | awk '{print $3}' | sed 's/\.//g' | sed 's/.*://' | sed 's/-.*//g' | sed 's/+.*//g' | sort -V | tail -n 1)"
    else
      mongodb_org_v="$("$(which dpkg)" -l | grep "mongodb-org-server" | grep -i "^ii\\|^hi\\|^ri\\|^pi\\|^ui" | awk '{print $3}' | sed 's/\.//g' | sed 's/.*://' | sed 's/-.*//g' | sed 's/+.*//g' | sort -V | tail -n 1)"
    fi
  fi
  if [[ "${force_http_repositories}" != 'true' ]]; then repo_http_https="https"; else repo_http_https="http"; fi
  if [[ "${mongodb_org_v::2}" == '30' ]] || [[ "${add_mongodb_30_repo}" == 'true' ]]; then
    if [[ "${architecture}" == "arm64" ]]; then add_mongodb_34_repo="true"; unset add_mongodb_30_repo; fi
    mongodb_version_major_minor="3.0"
    if [[ "${os_codename}" =~ (precise) ]]; then
      mongodb_codename="ubuntu precise"
      mongodb_repo_type="multiverse"
    elif [[ "${os_codename}" =~ (trusty|utopic|vivid|wily|yakkety|zesty|artful|qiana|rebecca|rafaela|rosa|utopic|vivid|wily|yakkety|zesty|artful) ]]; then
      mongodb_codename="ubuntu trusty"
      mongodb_repo_type="multiverse"
    elif [[ "${os_codename}" == "wheezy" ]]; then
      mongodb_codename="debian wheezy"
      mongodb_repo_type="main"
    else
      mongodb_codename="ubuntu trusty"
      mongodb_repo_type="multiverse"
    fi
  fi
  if [[ "${mongodb_org_v::2}" == '32' ]] || [[ "${add_mongodb_32_repo}" == 'true' ]]; then
    if [[ "${architecture}" == "arm64" ]]; then add_mongodb_34_repo="true"; unset add_mongodb_32_repo; fi
    mongodb_version_major_minor="3.2"
    if [[ "${os_codename}" =~ (trusty|utopic|vivid|wily|yakkety|zesty|artful|qiana|rebecca|rafaela|rosa|utopic|vivid|wily|yakkety|zesty|artful) ]]; then
      mongodb_codename="ubuntu trusty"
      mongodb_repo_type="multiverse"
    elif [[ "${os_codename}" == "jessie" ]]; then
      mongodb_codename="debian jessie"
      mongodb_repo_type="main"
    else
      mongodb_codename="ubuntu xenial"
      mongodb_repo_type="multiverse"
    fi
  fi
  if [[ "${mongodb_org_v::2}" == '34' ]] || [[ "${add_mongodb_34_repo}" == 'true' ]]; then
    mongodb_version_major_minor="3.4"
    if [[ "${os_codename}" =~ (trusty|utopic|vivid|wily|yakkety|zesty|artful|qiana|rebecca|rafaela|rosa|utopic|vivid|wily|yakkety|zesty|artful) ]]; then
      mongodb_codename="ubuntu trusty"
      mongodb_repo_type="multiverse"
    elif [[ "${os_codename}" == "jessie" ]]; then
      mongodb_codename="debian jessie"
      mongodb_repo_type="main"
    else
      mongodb_codename="ubuntu xenial"
      mongodb_repo_type="multiverse"
    fi
  fi
  if [[ "${mongodb_org_v::2}" == '36' ]] || [[ "${add_mongodb_36_repo}" == 'true' ]]; then
    mongodb_version_major_minor="3.6"
    if [[ "${try_different_mongodb_repo}" == 'true' ]] || [[ "${architecture}" != "amd64" ]]; then
      if [[ "${os_codename}" =~ (trusty|utopic|vivid|wily|yakkety|zesty|artful|qiana|rebecca|rafaela|rosa|utopic|vivid|wily|yakkety|zesty|artful) ]]; then
        mongodb_codename="ubuntu trusty"
        mongodb_repo_type="multiverse"
      elif [[ "${os_codename}" =~ (xenial|sarah|serena|sonya|sylvia|bionic|tara|tessa|tina|tricia|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing|resolute|stretch|buster|bullseye|bookworm|trixie|forky|unstable) ]]; then
        mongodb_codename="ubuntu xenial"
        mongodb_repo_type="multiverse"
      elif [[ "${os_codename}" =~ (bionic|tara|tessa|tina|tricia|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing|resolute|bullseye|bookworm|trixie|forky|unstable) ]]; then
        mongodb_codename="ubuntu bionic"
        mongodb_repo_type="multiverse"
      else
        mongodb_codename="ubuntu xenial"
        mongodb_repo_type="multiverse"
      fi
    else
      if [[ "${os_codename}" =~ (trusty|utopic|vivid|wily|yakkety|zesty|artful|qiana|rebecca|rafaela|rosa|utopic|vivid|wily|yakkety|zesty|artful) ]]; then
        mongodb_codename="ubuntu xenial"
        mongodb_repo_type="multiverse"
      elif [[ "${os_codename}" =~ (xenial|sarah|serena|sonya|sylvia|bionic|tara|tessa|tina|tricia|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing|resolute) ]]; then
        mongodb_codename="ubuntu xenial"
        mongodb_repo_type="multiverse"
      elif [[ "${os_codename}" == "jessie" ]]; then
        mongodb_codename="debian jessie"
        mongodb_repo_type="main"
      elif [[ "${os_codename}" =~ (stretch|buster|bullseye|bookworm|trixie|forky|unstable) ]]; then
        mongodb_codename="debian stretch"
        mongodb_repo_type="main"
      else
        mongodb_codename="ubuntu xenial"
        mongodb_repo_type="multiverse"
      fi
    fi
  fi
  if [[ "${mongodb_org_v::2}" == '40' ]] || [[ "${add_mongodb_40_repo}" == 'true' ]]; then
    mongodb_version_major_minor="4.0"
    if [[ "${try_different_mongodb_repo}" == 'true' ]] || [[ "${architecture}" != "amd64" ]]; then
      if [[ "${os_codename}" =~ (trusty|utopic|vivid|wily|yakkety|zesty|artful|qiana|rebecca|rafaela|rosa|utopic|vivid|wily|yakkety|zesty|artful) ]]; then
        mongodb_codename="ubuntu trusty"
        mongodb_repo_type="multiverse"
      elif [[ "${os_codename}" =~ (xenial|sarah|serena|sonya|sylvia) ]]; then
        mongodb_codename="ubuntu xenial"
        mongodb_repo_type="multiverse"
      elif [[ "${os_codename}" =~ (bionic|tara|tessa|tina|tricia|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing|resolute|bullseye|bookworm|trixie|forky|unstable) ]]; then
        mongodb_codename="ubuntu bionic"
        mongodb_repo_type="multiverse"
      else
        mongodb_codename="ubuntu xenial"
        mongodb_repo_type="multiverse"
      fi
    else
      if [[ "${os_codename}" =~ (trusty|utopic|vivid|wily|yakkety|zesty|artful|qiana|rebecca|rafaela|rosa|utopic|vivid|wily|yakkety|zesty|artful) ]]; then
        mongodb_codename="ubuntu trusty"
        mongodb_repo_type="multiverse"
      elif [[ "${os_codename}" =~ (xenial|sarah|serena|sonya|sylvia) ]]; then
        mongodb_codename="ubuntu xenial"
        mongodb_repo_type="multiverse"
      elif [[ "${os_codename}" =~ (bionic|tara|tessa|tina|tricia|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing|resolute) ]]; then
        mongodb_codename="ubuntu bionic"
        mongodb_repo_type="multiverse"
      elif [[ "${os_codename}" == "jessie" ]]; then
        mongodb_codename="debian jessie"
        mongodb_repo_type="main"
      elif [[ "${os_codename}" =~ (stretch|buster|bullseye|bookworm|trixie|forky|unstable) ]]; then
        mongodb_codename="debian stretch"
        mongodb_repo_type="main"
      else
        mongodb_codename="ubuntu xenial"
        mongodb_repo_type="multiverse"
      fi
    fi
  fi
  if [[ "${mongodb_org_v::2}" == '42' ]] || [[ "${add_mongodb_42_repo}" == 'true' ]]; then
    mongodb_version_major_minor="4.2"
    if [[ "${try_different_mongodb_repo}" == 'true' ]] || [[ "${architecture}" != "amd64" ]]; then
      if [[ "${os_codename}" =~ (stretch|buster|bullseye|bookworm|trixie|forky|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing|resolute) ]]; then
        mongodb_codename="ubuntu bionic"
        mongodb_repo_type="multiverse"
      else
        mongodb_codename="ubuntu xenial"
        mongodb_repo_type="multiverse"
      fi
    else
      if [[ "${os_codename}" =~ (stretch) ]]; then
        mongodb_codename="debian stretch"
        mongodb_repo_type="main"
      elif [[ "${os_codename}" =~ (buster|bullseye|bookworm|trixie|forky|unstable) ]]; then
        mongodb_codename="debian buster"
        mongodb_repo_type="main"
      elif [[ "${os_codename}" =~ (xenial|sarah|serena|sonya|sylvia|loki) ]]; then
        mongodb_codename="ubuntu xenial"
        mongodb_repo_type="multiverse"
      elif [[ "${os_codename}" =~ (bionic|tara|tessa|tina|tricia|hera|juno|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing|resolute) ]]; then
        mongodb_codename="ubuntu bionic"
        mongodb_repo_type="multiverse"
      else
        mongodb_codename="ubuntu xenial"
        mongodb_repo_type="multiverse"
      fi
    fi
  fi
  if [[ "${mongodb_org_v::2}" == '44' ]] || [[ "${add_mongodb_44_repo}" == 'true' ]]; then
    mongodb_version_major_minor="4.4"
    if [[ "${avx_compatible}" != "true" ]]; then mongo_version_locked="4.4.18"; fi
    if [[ "${try_different_mongodb_repo}" == 'true' ]] || [[ "${architecture}" != "amd64" ]]; then
      if [[ "${os_codename}" =~ (stretch|bionic|tara|tessa|tina|tricia|hera|juno) ]]; then
        mongodb_codename="ubuntu bionic"
        mongodb_repo_type="multiverse"
      elif [[ "${os_codename}" =~ (buster|bullseye|bookworm|trixie|forky|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing|resolute) ]]; then
        mongodb_codename="ubuntu focal"
        mongodb_repo_type="multiverse"
      else
        mongodb_codename="ubuntu xenial"
        mongodb_repo_type="multiverse"
      fi
    else
      if [[ "${os_codename}" =~ (stretch) ]]; then
        mongodb_codename="debian stretch"
        mongodb_repo_type="main"
      elif [[ "${os_codename}" =~ (buster|bullseye|bookworm|trixie|forky|unstable) ]]; then
        mongodb_codename="debian buster"
        mongodb_repo_type="main"
      elif [[ "${os_codename}" =~ (xenial|sarah|serena|sonya|sylvia|loki) ]]; then
        mongodb_codename="ubuntu xenial"
        mongodb_repo_type="multiverse"
      elif [[ "${os_codename}" =~ (bionic|tara|tessa|tina|tricia|hera|juno) ]]; then
        mongodb_codename="ubuntu bionic"
        mongodb_repo_type="multiverse"
      elif [[ "${os_codename}" =~ (focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing|resolute) ]]; then
        mongodb_codename="ubuntu focal"
        mongodb_repo_type="multiverse"
      else
        mongodb_codename="ubuntu xenial"
        mongodb_repo_type="multiverse"
      fi
    fi
  fi
  if [[ "${mongodb_org_v::2}" == '50' ]] || [[ "${add_mongodb_50_repo}" == 'true' ]]; then
    mongodb_version_major_minor="5.0"
    if [[ "${try_different_mongodb_repo}" == 'true' ]] || [[ "${architecture}" != "amd64" ]]; then
      if [[ "${os_codename}" =~ (stretch|buster|bullseye|bookworm|trixie|forky|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing|resolute) ]]; then
        mongodb_codename="ubuntu focal"
        mongodb_repo_type="multiverse"
      else
        mongodb_codename="ubuntu xenial"
        mongodb_repo_type="multiverse"
      fi
    else
      if [[ "${os_codename}" =~ (stretch) ]]; then
        mongodb_codename="debian stretch"
        mongodb_repo_type="main"
      elif [[ "${os_codename}" =~ (buster) ]]; then
        mongodb_codename="debian buster"
        mongodb_repo_type="main"
      elif [[ "${os_codename}" =~ (bullseye|bookworm|trixie|forky|unstable) ]]; then
        mongodb_codename="debian bullseye"
        mongodb_repo_type="main"
      elif [[ "${os_codename}" =~ (xenial|sarah|serena|sonya|sylvia|loki) ]]; then
        mongodb_codename="ubuntu xenial"
        mongodb_repo_type="multiverse"
      elif [[ "${os_codename}" =~ (bionic|tara|tessa|tina|tricia|hera|juno) ]]; then
        mongodb_codename="ubuntu bionic"
        mongodb_repo_type="multiverse"
      elif [[ "${os_codename}" =~ (focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing|resolute) ]]; then
        mongodb_codename="ubuntu focal"
        mongodb_repo_type="multiverse"
      else
        mongodb_codename="ubuntu xenial"
        mongodb_repo_type="multiverse"
      fi
    fi
  fi
  if [[ "${mongodb_org_v::2}" == '60' ]] || [[ "${add_mongodb_60_repo}" == 'true' ]]; then
    mongodb_version_major_minor="6.0"
    if [[ "${try_different_mongodb_repo}" == 'true' ]] || [[ "${architecture}" != "amd64" ]]; then
      if [[ "${os_codename}" =~ (stretch|buster|bullseye|bookworm|trixie|forky|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing|resolute) ]]; then
        mongodb_codename="ubuntu jammy"
        mongodb_repo_type="multiverse"
      else
        mongodb_codename="ubuntu xenial"
        mongodb_repo_type="multiverse"
      fi
    else
      if [[ "${os_codename}" =~ (stretch|buster) ]]; then
        mongodb_codename="debian buster"
        mongodb_repo_type="main"
      elif [[ "${os_codename}" =~ (bullseye|bookworm|trixie|forky|unstable) ]]; then
        mongodb_codename="debian bullseye"
        mongodb_repo_type="main"
      elif [[ "${os_codename}" =~ (xenial|sarah|serena|sonya|sylvia|loki) ]]; then
        mongodb_codename="ubuntu xenial"
        mongodb_repo_type="multiverse"
      elif [[ "${os_codename}" =~ (bionic|tara|tessa|tina|tricia|hera|juno) ]]; then
        mongodb_codename="ubuntu bionic"
        mongodb_repo_type="multiverse"
      elif [[ "${os_codename}" =~ (focal|groovy|hirsute|impish) ]]; then
        mongodb_codename="ubuntu focal"
        mongodb_repo_type="multiverse"
      elif [[ "${os_codename}" =~ (jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing|resolute) ]]; then
        mongodb_codename="ubuntu jammy"
        mongodb_repo_type="multiverse"
      else
        mongodb_codename="ubuntu xenial"
        mongodb_repo_type="multiverse"
      fi
    fi
  fi
  if [[ "${mongodb_org_v::2}" == '70' ]] || [[ "${add_mongodb_70_repo}" == 'true' ]]; then
    mongodb_version_major_minor="7.0"
    if [[ "${try_different_mongodb_repo}" == 'true' ]] || [[ "${architecture}" != "amd64" ]]; then
      if [[ "${os_codename}" =~ (stretch|buster|bullseye|focal|groovy|hirsute|impish) ]]; then
        mongodb_codename="ubuntu focal"
        mongodb_repo_type="multiverse"
        if [[ "${os_codename}" =~ (stretch|buster) ]]; then
          add_extra_repo_mongodb_codename="bullseye"
          add_extra_repo_mongodb
        fi
      elif [[ "${os_codename}" =~ (bookworm|trixie|forky|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing|resolute) ]]; then
        mongodb_codename="ubuntu jammy"
        mongodb_repo_type="multiverse"
      else
        mongodb_codename="ubuntu focal"
        mongodb_repo_type="multiverse"
        if [[ "${os_codename}" =~ (xenial|sarah|serena|sonya|sylvia|loki|bionic|tara|tessa|tina|tricia|hera|juno) ]]; then
          add_extra_repo_mongodb_security="true"
          add_extra_repo_mongodb_codename="focal"
          add_extra_repo_mongodb
          add_extra_repo_mongodb_codename="focal"
          add_extra_repo_mongodb
        fi
      fi
    else
      if [[ "${os_codename}" =~ (stretch|buster) ]]; then
        mongodb_codename="ubuntu focal"
        mongodb_repo_type="multiverse"
        if [[ "${os_codename}" =~ (stretch|buster) ]]; then
          add_extra_repo_mongodb_codename="bullseye"
          add_extra_repo_mongodb
        fi
      elif [[ "${os_codename}" =~ (bullseye) ]]; then
        mongodb_codename="debian bullseye"
        mongodb_repo_type="main"
      elif [[ "${os_codename}" =~ (bookworm|trixie|forky|unstable) ]]; then
        mongodb_codename="debian bookworm"
        mongodb_repo_type="main"
      elif [[ "${os_codename}" =~ (xenial|sarah|serena|sonya|sylvia|loki|bionic|tara|tessa|tina|tricia|hera|juno|focal|groovy|hirsute|impish) ]]; then
        mongodb_codename="ubuntu focal"
        mongodb_repo_type="multiverse"
        if [[ "${os_codename}" =~ (xenial|sarah|serena|sonya|sylvia|loki|bionic|tara|tessa|tina|tricia|hera|juno) ]]; then
          add_extra_repo_mongodb_security="true"
          add_extra_repo_mongodb_codename="focal"
          add_extra_repo_mongodb
          add_extra_repo_mongodb_codename="focal"
          add_extra_repo_mongodb
        fi
      elif [[ "${os_codename}" =~ (jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing|resolute) ]]; then
        mongodb_codename="ubuntu jammy"
        mongodb_repo_type="multiverse"
      else
        mongodb_codename="ubuntu focal"
        mongodb_repo_type="multiverse"
      fi
    fi
  fi
  if [[ "${mongodb_org_v::2}" == '80' ]] || [[ "${add_mongodb_80_repo}" == 'true' ]]; then
    mongodb_version_major_minor="8.0"
    if [[ "${try_different_mongodb_repo}" == 'true' ]] || [[ "${architecture}" != "amd64" ]]; then
      if [[ "${os_codename}" =~ (stretch|buster|bullseye|focal|groovy|hirsute|impish) ]]; then
        mongodb_codename="ubuntu focal"
        mongodb_repo_type="multiverse"
        if [[ "${os_codename}" =~ (stretch|buster) ]]; then
          add_extra_repo_mongodb_codename="bullseye"
          add_extra_repo_mongodb
        fi
      elif [[ "${os_codename}" =~ (jammy|kinetic|lunar|mantic|bookworm) ]]; then
        mongodb_codename="ubuntu jammy"
        mongodb_repo_type="multiverse"
      elif [[ "${os_codename}" =~ (trixie|forky|noble|oracular|plucky|questing|resolute) ]]; then
        mongodb_codename="ubuntu noble"
        mongodb_repo_type="multiverse"
      else
        mongodb_codename="ubuntu focal"
        mongodb_repo_type="multiverse"
        if [[ "${os_codename}" =~ (xenial|sarah|serena|sonya|sylvia|loki|bionic|tara|tessa|tina|tricia|hera|juno) ]]; then
          add_extra_repo_mongodb_security="true"
          add_extra_repo_mongodb_codename="focal"
          add_extra_repo_mongodb
          add_extra_repo_mongodb_codename="focal"
          add_extra_repo_mongodb
        fi
      fi
    else
      if [[ "${os_codename}" =~ (stretch|buster) ]]; then
        mongodb_codename="ubuntu focal"
        mongodb_repo_type="multiverse"
        if [[ "${os_codename}" =~ (stretch|buster) ]]; then
          add_extra_repo_mongodb_codename="bullseye"
          add_extra_repo_mongodb
        fi
      elif [[ "${os_codename}" =~ (bullseye|bookworm|trixie|forky|unstable) ]]; then
        mongodb_codename="debian bookworm"
        mongodb_repo_type="main"
      elif [[ "${os_codename}" =~ (xenial|sarah|serena|sonya|sylvia|loki|bionic|tara|tessa|tina|tricia|hera|juno|focal|groovy|hirsute|impish) ]]; then
        mongodb_codename="ubuntu focal"
        mongodb_repo_type="multiverse"
        if [[ "${os_codename}" =~ (xenial|sarah|serena|sonya|sylvia|loki|bionic|tara|tessa|tina|tricia|hera|juno) ]]; then
          add_extra_repo_mongodb_security="true"
          add_extra_repo_mongodb_codename="focal"
          add_extra_repo_mongodb
          add_extra_repo_mongodb_codename="focal"
          add_extra_repo_mongodb
        fi
      elif [[ "${os_codename}" =~ (jammy|kinetic|lunar|mantic) ]]; then
        mongodb_codename="ubuntu jammy"
        mongodb_repo_type="multiverse"
      elif [[ "${os_codename}" =~ (noble|oracular|plucky|questing|resolute) ]]; then
        mongodb_codename="ubuntu noble"
        mongodb_repo_type="multiverse"
      else
        mongodb_codename="ubuntu focal"
        mongodb_repo_type="multiverse"
      fi
    fi
  fi
  if [[ "$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/mongodb-release?version=${mongodb_version_major_minor}" 2> /dev/null | jq -r '.expired' 2> /dev/null)" == 'true' ]]; then trusted_mongodb_repo=" trusted=yes"; deb822_trusted_mongodb_repo="\nTrusted: yes"; fi
  mongodb_key_check_time="$(date +%s)"
  if [[ "$(dpkg-query --showformat='${version}' --show jq 2> /dev/null | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
    jq --arg mongodb_key_check_time "${mongodb_key_check_time}" '."database" += {"mongodb-key-last-check": "'"${mongodb_key_check_time}"'"}' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
  else
    jq --arg mongodb_key_check_time "$mongodb_key_check_time" '.database += {"mongodb-key-last-check": $mongodb_key_check_time}' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
  fi
  eus_database_move
  if [[ "${try_different_mongodb_repo}" == 'true' ]]; then try_different_mongodb_repo_test="a different"; try_different_mongodb_repo_test_2="different "; else try_different_mongodb_repo_test="the"; try_different_mongodb_repo_test_2=""; fi
  if [[ "${try_http_mongodb_repo}" == 'true' ]]; then repo_http_https="http"; try_different_mongodb_repo_test="the HTTP instead of HTTPS"; try_different_mongodb_repo_test_2="HTTP "; else try_different_mongodb_repo_test="the"; try_different_mongodb_repo_test_2=""; fi
  if [[ -n "${mongodb_version_major_minor}" ]]; then
    if gpg --list-packets "/etc/apt/keyrings/mongodb-server-${mongodb_version_major_minor}.gpg" &> /dev/null && [[ "${mongodb_key_update}" != 'true' ]]; then if [[ "$(gpg --show-keys --with-colons "/etc/apt/keyrings/mongodb-server-${mongodb_version_major_minor}.gpg" 2> /dev/null | awk -F':' '$1=="pub"{print $7}' | head -n1)" -le "$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/mongodb-release?version=${mongodb_version_major_minor}" 2> /dev/null | jq -r '.updated' 2> /dev/null)" ]]; then expired_existing_mongodb_key="true"; fi; fi
    if [[ "${mongodb_version_major_minor}" != "4.4" ]]; then unset mongo_version_locked; fi
    if ! gpg --list-packets "/etc/apt/keyrings/mongodb-server-${mongodb_version_major_minor}.gpg" &> /dev/null || [[ "${expired_existing_mongodb_key}" == 'true' ]] || [[ "${mongodb_key_update}" == 'true' ]] || [[ "${try_different_mongodb_repo}" == 'true' ]] || [[ "${try_http_mongodb_repo}" == 'true' ]]; then
      echo -e "${GRAY_R}#${RESET} Adding key for MongoDB ${mongodb_version_major_minor}..."
      aptkey_depreciated
      if [[ "${apt_key_deprecated}" == 'true' ]]; then
        echo -e "$(date +%F-%T.%6N) | pgp.mongodb.com repository key.\\n" &>> "${eus_dir}/logs/repository-keys.log"
        if curl "${curl_argument[@]}" -fSL "${repo_http_https}://pgp.mongodb.com/server-${mongodb_version_major_minor}.asc" 2>&1 | tee -a "${eus_dir}/logs/repository-keys.log" | gpg -o "/etc/apt/keyrings/mongodb-server-${mongodb_version_major_minor}.gpg" --dearmor --yes &> /dev/null; then
          mongodb_curl_exit_status="${PIPESTATUS[0]}"
          mongodb_gpg_exit_status="${PIPESTATUS[2]}"
          if [[ "${mongodb_curl_exit_status}" -eq "0" && "${mongodb_gpg_exit_status}" -eq "0" && -s "/etc/apt/keyrings/mongodb-server-${mongodb_version_major_minor}.gpg" ]]; then
            echo -e "${GREEN}#${RESET} Successfully added the key for MongoDB ${mongodb_version_major_minor}! \\n"
            signed_by_value=" signed-by=/etc/apt/keyrings/mongodb-server-${mongodb_version_major_minor}.gpg"; deb822_signed_by_value="\nSigned-By: /etc/apt/keyrings/mongodb-server-${mongodb_version_major_minor}.gpg"
            repository_key_location="/etc/apt/keyrings/mongodb-server-${mongodb_version_major_minor}.gpg"; check_repository_key_permissions
          else
            echo -e "$(date +%F-%T.%6N) | www.mongodb.org repository key.\\n" &>> "${eus_dir}/logs/repository-keys.log"
            if curl "${curl_argument[@]}" -fSL "${repo_http_https}://www.mongodb.org/static/pgp/server-${mongodb_version_major_minor}.asc" 2>&1 | tee -a "${eus_dir}/logs/repository-keys.log" | gpg -o "/etc/apt/keyrings/mongodb-server-${mongodb_version_major_minor}.gpg" --dearmor --yes &> /dev/null; then
              mongodb_curl_exit_status="${PIPESTATUS[0]}"
              mongodb_gpg_exit_status="${PIPESTATUS[2]}"
              if [[ "${mongodb_curl_exit_status}" -eq "0" && "${mongodb_gpg_exit_status}" -eq "0" && -s "/etc/apt/keyrings/mongodb-server-${mongodb_version_major_minor}.gpg" ]]; then
                echo -e "${GREEN}#${RESET} Successfully added the key for MongoDB ${mongodb_version_major_minor}! \\n"
                signed_by_value=" signed-by=/etc/apt/keyrings/mongodb-server-${mongodb_version_major_minor}.gpg"; deb822_signed_by_value="\nSigned-By: /etc/apt/keyrings/mongodb-server-${mongodb_version_major_minor}.gpg"
                repository_key_location="/etc/apt/keyrings/mongodb-server-${mongodb_version_major_minor}.gpg"; check_repository_key_permissions
              else
                echo -e "$(date +%F-%T.%6N) | pgp.mongodb.com repository key.\\n" &>> "${eus_dir}/logs/repository-keys.log"
                if curl "${curl_argument[@]}" --insecure -fSL "${repo_http_https}://pgp.mongodb.com/server-${mongodb_version_major_minor}.asc" 2>&1 | tee -a "${eus_dir}/logs/repository-keys.log" | gpg -o "/etc/apt/keyrings/mongodb-server-${mongodb_version_major_minor}.gpg" --dearmor --yes &> /dev/null; then
                  mongodb_curl_exit_status="${PIPESTATUS[0]}"
                  mongodb_gpg_exit_status="${PIPESTATUS[2]}"
                  if [[ "${mongodb_curl_exit_status}" -eq "0" && "${mongodb_gpg_exit_status}" -eq "0" && -s "/etc/apt/keyrings/mongodb-server-${mongodb_version_major_minor}.gpg" ]]; then
                    echo -e "${GREEN}#${RESET} Successfully added the key for MongoDB ${mongodb_version_major_minor}! \\n"
                    signed_by_value=" signed-by=/etc/apt/keyrings/mongodb-server-${mongodb_version_major_minor}.gpg"; deb822_signed_by_value="\nSigned-By: /etc/apt/keyrings/mongodb-server-${mongodb_version_major_minor}.gpg"
                    repository_key_location="/etc/apt/keyrings/mongodb-server-${mongodb_version_major_minor}.gpg"; check_repository_key_permissions
                  else
                    abort_reason="Failed to add the key for MongoDB ${mongodb_version_major_minor}."
                    abort
                  fi
                fi
              fi
            fi
          fi
        fi
      else
        echo -e "$(date +%F-%T.%6N) | pgp.mongodb.com repository key.\\n" &>> "${eus_dir}/logs/repository-keys.log"
        if curl "${curl_argument[@]}" -fSL "${repo_http_https}://pgp.mongodb.com/server-${mongodb_version_major_minor}.asc" 2>&1 | tee -a "${eus_dir}/logs/repository-keys.log" | apt-key add - &> /dev/null; then
          mongodb_curl_exit_status="${PIPESTATUS[0]}"
          mongodb_apt_key_exit_status="${PIPESTATUS[2]}"
          if [[ "${mongodb_curl_exit_status}" -eq "0" && "${mongodb_apt_key_exit_status}" -eq "0" ]]; then
            echo -e "${GREEN}#${RESET} Successfully added the key for MongoDB ${mongodb_version_major_minor}! \\n"
          else
            echo -e "$(date +%F-%T.%6N) | www.mongodb.org repository key.\\n" &>> "${eus_dir}/logs/repository-keys.log"
            if curl "${curl_argument[@]}" -fSL "${repo_http_https}://www.mongodb.org/static/pgp/server-${mongodb_version_major_minor}.asc" 2>&1 | tee -a "${eus_dir}/logs/repository-keys.log" | apt-key add - &> /dev/null; then
              mongodb_curl_exit_status="${PIPESTATUS[0]}"
              mongodb_apt_key_exit_status="${PIPESTATUS[2]}"
              if [[ "${mongodb_curl_exit_status}" -eq "0" && "${mongodb_apt_key_exit_status}" -eq "0" ]]; then
                echo -e "${GREEN}#${RESET} Successfully added the key for MongoDB ${mongodb_version_major_minor}! \\n"
              else
                echo -e "$(date +%F-%T.%6N) | pgp.mongodb.com repository key.\\n" &>> "${eus_dir}/logs/repository-keys.log"
                if curl "${curl_argument[@]}" --insecure -fSL "${repo_http_https}://pgp.mongodb.com/server-${mongodb_version_major_minor}.asc" 2>&1 | tee -a "${eus_dir}/logs/repository-keys.log" | apt-key add - &> /dev/null; then
                  mongodb_curl_exit_status="${PIPESTATUS[0]}"
                  mongodb_apt_key_exit_status="${PIPESTATUS[2]}"
                  if [[ "${mongodb_curl_exit_status}" -eq "0" && "${mongodb_apt_key_exit_status}" -eq "0" ]]; then
                    echo -e "${GREEN}#${RESET} Successfully added the key for MongoDB ${mongodb_version_major_minor}! \\n"
                  else
                    abort_reason="Failed to add the key for MongoDB ${mongodb_version_major_minor}."
                    abort
                  fi
                fi
              fi
            fi
          fi
        fi
      fi
    else
      if [[ "${apt_key_deprecated}" == 'true' ]]; then signed_by_value=" signed-by=/etc/apt/keyrings/mongodb-server-${mongodb_version_major_minor}.gpg"; deb822_signed_by_value="\nSigned-By: /etc/apt/keyrings/mongodb-server-${mongodb_version_major_minor}.gpg"; fi
    fi
    echo -e "${GRAY_R}#${RESET} Adding ${try_different_mongodb_repo_test} MongoDB ${mongodb_version_major_minor} repository..."
    if [[ "${architecture}" == 'arm64' ]]; then arch="arch=arm64"; elif [[ "${architecture}" == 'amd64' ]]; then arch="arch=amd64"; else arch="arch=amd64,arm64"; fi
    if [[ "${use_deb822_format}" == 'true' ]]; then
      # DEB822 format
      mongodb_repo_entry="Types: deb\nURIs: ${repo_http_https}://repo.mongodb.org/apt/$(echo "${mongodb_codename}" | awk -F" " '{print $1}')\nSuites: $(echo "${mongodb_codename}" | awk -F" " '{print $2}')/mongodb-org/${mongodb_version_major_minor}\nComponents: ${mongodb_repo_type}${deb822_signed_by_value}\nArchitectures: ${arch//arch=/}${deb822_trusted_mongodb_repo}"
    else
      # Traditional format
      mongodb_repo_entry="deb [ ${arch}${signed_by_value}${trusted_mongodb_repo} ] ${repo_http_https}://repo.mongodb.org/apt/${mongodb_codename}/mongodb-org/${mongodb_version_major_minor} ${mongodb_repo_type}"
    fi
    if echo -e "${mongodb_repo_entry}" &> "/etc/apt/sources.list.d/mongodb-org-${mongodb_version_major_minor}.${source_file_format}"; then
      echo -e "${GREEN}#${RESET} Successfully added the ${try_different_mongodb_repo_test_2}MongoDB ${mongodb_version_major_minor} repository!\\n" && sleep 2
      if [[ "${mongodb_key_update}" != 'true' ]]; then
        run_apt_get_update_with_sha1_fallback
        mongodb_org_upgrade_to_version_with_dot="$(apt-cache policy mongodb-org-server | grep -i "${mongo_version_max_with_dot}" | grep -i Candidate | sed -e 's/ //g' -e 's/*//g' | cut -d':' -f2)"
        if [[ -z "${mongodb_org_upgrade_to_version_with_dot}" ]]; then mongodb_org_upgrade_to_version_with_dot="$(apt-cache policy mongodb-org-server | grep -i "${mongo_version_max_with_dot}" | sed -e 's/500//g' -e 's/-1//g' -e 's/100//g' -e 's/ //g' -e '/http/d' -e 's/*//g' | cut -d':' -f2 | sed '/mongodb/d' | sort -r -V | head -n 1)"; fi
        if [[ "${mongodb_downgrade_process}" == "true" && -n "${previous_mongodb_version_with_dot}" ]]; then
          unset mongodb_org_upgrade_to_version_with_dot
          mongodb_org_upgrade_to_version_with_dot="$(apt-cache policy mongodb-org-server | grep -i "${previous_mongodb_version_with_dot}" | grep -i Candidate | sed -e 's/ //g' -e 's/*//g' | cut -d':' -f2)"
          if [[ -z "${mongodb_org_upgrade_to_version_with_dot}" ]]; then mongodb_org_upgrade_to_version_with_dot="$(apt-cache policy mongodb-org-server | grep -i "${previous_mongodb_version_with_dot}" | sed -e 's/500//g' -e 's/-1//g' -e 's/100//g' -e 's/ //g' -e '/http/d' -e 's/*//g' | cut -d':' -f2 | sed '/mongodb/d' | sort -r -V | head -n 1)"; fi
        fi
        if [[ -z "${mongodb_org_upgrade_to_version_with_dot}" && "${try_http_mongodb_repo}" != "true" ]]; then try_http_mongodb_repo="true"; add_mongodb_repo; return; fi
        mongodb_org_upgrade_to_version="${mongodb_org_upgrade_to_version_with_dot//./}"
        if [[ -n "${mongo_version_locked}" ]]; then install_mongodb_version="${mongo_version_locked}"; install_mongodb_version_with_equality_sign="=${mongo_version_locked}"; fi
        if [[ "${mongodb_org_upgrade_to_version::2}" == "${mongo_version_max}" ]] || [[ "${mongodb_downgrade_process}" == "true" ]]; then
          if [[ -z "${mongo_version_locked}" ]]; then
            install_mongodb_version="${mongodb_org_upgrade_to_version_with_dot}"
            install_mongodb_version_with_equality_sign="=${mongodb_org_upgrade_to_version_with_dot}"
          fi
        fi
      fi
    else
      abort_reason="Failed to add the ${try_different_mongodb_repo_test_2}MongoDB ${mongodb_version_major_minor} repository."
      abort
    fi
  fi
  unset skip_mongodb_org_v
  unset signed_by_value
  unset deb822_signed_by_value
  unset deb822_trusted_mongodb_repo
  unset trusted_mongodb_repo
}

unifi_core_system_check() {
  # Check if system runs Unifi OS
  if "$(which dpkg)" -l unifi-core 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
    unifi_core_system="true"
    unifi_core_glennr_api="&host=uos&architecture=$("$(which dpkg)" --print-architecture)"
    if grep -sq unifi-native /mnt/.rofs/var/lib/dpkg/status; then unifi_native_system="true"; unifi_core_glennr_api="&host=uos-native&architecture=$("$(which dpkg)" --print-architecture)"; fi
    if [[ -f /proc/ubnthal/system.info ]]; then if grep -iq "shortname" /proc/ubnthal/system.info; then unifi_core_device="$(grep "shortname" /proc/ubnthal/system.info | sed 's/shortname=//g')"; fi; fi
    if [[ -f /etc/motd && -s /etc/motd && -z "${unifi_core_device}" ]]; then unifi_core_device="$(grep -io "welcome.*" /etc/motd | sed -e 's/Welcome //g' -e 's/to //g' -e 's/the //g' -e 's/!//g')"; fi
    if [[ -f /usr/lib/version && -s /usr/lib/version && -z "${unifi_core_device}" ]]; then unifi_core_device="$(cut -d'.' -f1 /usr/lib/version)"; fi
    if [[ -z "${unifi_core_device}" ]]; then unifi_core_device='Unknown device'; fi
  fi
}

unifi_native_unsupported_check() {
  if [[ "${unifi_native_system}" != 'true' ]] && "$(which dpkg)" -l unifi-native 2> /dev/null; then
    check_dpkg_lock
    echo -e "${GRAY_R}#${RESET} Removing the UniFi Network Native Application..."
    if "${EUS_APT_ENV[@]}" env DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' purge unifi-native &>> "${eus_dir}/logs/unifi-native-uninstall.log"; then
      echo -e "${GREEN}#${RESET} Successfully purged the UniFi Network Native Application! \\n"
    else
      if "$(which dpkg)" --remove --force-remove-reinstreq unifi-native &>> "${eus_dir}/logs/unifi-native-uninstall.log"; then
        echo -e "${GREEN}#${RESET} Successfully force removed the UniFi Network Native Application! \\n"
      else
        abort_reason="Failed to purge the UniFi Network Native Application from a non-native device."
        abort
      fi
    fi
  fi
}

network_install_file_name_check() {
  # Decide on Network Application file to download.
  if [[ "${unifi_core_system}" == 'true' ]]; then
    if [[ "${unifi_native_system}" == 'true' ]]; then
      unifi_deb_file_name="unifi-native_sysvinit"
    else
      unifi_deb_file_name="unifi-uos_sysvinit"
    fi
  else
    unifi_deb_file_name="unifi_sysvinit_all"
  fi
}

cancel_script() {
  silent_run_apt_get_update="true"
  eus_apt_sha1_disable
  if [[ "${set_lc_all}" == 'true' ]]; then if [[ -n "${original_lang}" ]]; then export LANG="${original_lang}"; else unset LANG; fi; if [[ -n "${original_lcall}" ]]; then export LC_ALL="${original_lcall}"; else unset LC_ALL; fi; fi
  if [[ "${stopped_unattended_upgrade}" == 'true' ]]; then systemctl start unattended-upgrades &>> "${eus_dir}/logs/unattended-upgrades.log"; unset stopped_unattended_upgrade; fi
  if [[ "${script_option_skip}" == 'true' ]]; then
    echo -e "\\n${GRAY_R}#########################################################################${RESET}\\n"
  elif [[ "${cancel_script_without_clearing_error}" == 'true' ]]; then
    echo -e "\\n${GRAY_R}#########################################################################${RESET}\\n"
  else
    header
  fi
  echo -e "${GRAY_R}#${RESET} Cancelling the script!\\n\\n"
  author
  update_eus_db
  cleanup_codename_mismatch_repos
  remove_yourself
  exit 0
}

http_proxy_found() {
  header
  echo -e "${GREEN}#${RESET} HTTP Proxy found. | ${GRAY_R}${http_proxy}${RESET}\\n\\n"
}

remove_yourself() {
  if [[ "${set_lc_all}" == 'true' ]]; then if [[ -n "${original_lang}" ]]; then export LANG="${original_lang}"; else unset LANG; fi; if [[ -n "${original_lcall}" ]]; then export LC_ALL="${original_lcall}"; else unset LC_ALL; fi; fi
  if [[ "${stopped_unattended_upgrade}" == 'true' ]]; then systemctl start unattended-upgrades &>> "${eus_dir}/logs/unattended-upgrades.log"; unset stopped_unattended_upgrade; fi
  if [[ "$(jq -r '.database["keep-script-on-system"]' "${eus_dir}/db/db.json")" == "false" || "${script_option_skip}" == 'true' ]]; then if [[ -e "${script_location}" ]]; then rm --force "${script_location}" 2> /dev/null; fi; fi
}

christmass_new_year() {
  date_d=$(date '+%d' | sed "s/^0*//g; s/\.0*/./g")
  date_m=$(date '+%m' | sed "s/^0*//g; s/\.0*/./g")
  if [[ "${date_m}" == '12' && "${date_d}" -ge '18' && "${date_d}" -lt '26' ]]; then
    echo -e "\\n${GRAY_R}----${RESET}\\n"
    echo -e "${GRAY_R}#${RESET} GlennR wishes you a Merry Christmas! May you be blessed with health and happiness!"
    christmas_message="true"
  fi
  if [[ "${date_m}" == '12' && "${date_d}" -ge '24' && "${date_d}" -le '30' ]]; then
    if [[ "${christmas_message}" != 'true' ]]; then echo -e "\\n${GRAY_R}----${RESET}\\n"; fi
    if [[ "${christmas_message}" == 'true' ]]; then echo -e ""; fi
    date_y=$(date -d "+1 year" +"%Y")
    echo -e "${GRAY_R}#${RESET} HAPPY NEW YEAR ${date_y}"
    echo -e "${GRAY_R}#${RESET} May the new year turn all your dreams into reality and all your efforts into great achievements!"
    new_year_message="true"
  elif [[ "${date_m}" == '12' && "${date_d}" == '31' ]]; then
    if [[ "${christmas_message}" != 'true' ]]; then echo -e "\\n${GRAY_R}----${RESET}\\n"; fi
    if [[ "${christmas_message}" == 'true' ]]; then echo -e ""; fi
    date_y=$(date -d "+1 year" +"%Y")
    echo -e "${GRAY_R}#${RESET} HAPPY NEW YEAR ${date_y}"
    echo -e "${GRAY_R}#${RESET} Tomorrow, is the first blank page of a 365 page book. Write a good one!"
    new_year_message="true"
  fi
  if [[ "${date_m}" == '1' && "${date_d}" -le '5' ]]; then
    if [[ "${christmas_message}" != 'true' ]]; then echo -e "\\n${GRAY_R}----${RESET}\\n"; fi
    if [[ "${christmas_message}" == 'true' ]]; then echo -e ""; fi
    date_y=$(date '+%Y')
    echo -e "${GRAY_R}#${RESET} HAPPY NEW YEAR ${date_y}"
    echo -e "${GRAY_R}#${RESET} May this new year all your dreams turn into reality and all your efforts into great achievements"
    new_year_message="true"
  fi
}

author() {
  silent_run_apt_get_update="true"
  eus_apt_sha1_disable
  eus_tmp_directory_cleanup="true"; eus_tmp_directory_check
  check_apt_listbugs
  update_eus_db
  cleanup_codename_mismatch_repos
  christmass_new_year
  if [[ "${new_year_message}" == 'true' || "${christmas_message}" == 'true' ]]; then echo -e "\\n${GRAY_R}----${RESET}\\n"; fi
  if [[ "${archived_repo}" == 'true' && "${unifi_core_system}" != 'true' ]]; then echo -e "\\n${WHITE_R}----${RESET}\\n\\n${RED}#${RESET} ${RESET}System Notice: ${WHITE_R}Unsupported OS Version Detected${RESET}! \\n${RED}#${RESET} ${RESET}Your operating system release (${WHITE_R}${os_codename}${RESET}) has reached End of Life (EOL) and is no longer supported by its creators.\\n${RED}#${RESET} ${RESET}To ensure security and compatibility, please update to a more current release...\\n"; fi
  if [[ "${archived_repo}" == 'true' && "${unifi_core_system}" == 'true' ]]; then echo -e "\\n${GRAY_R}----${RESET}\\n\\n${RED}#${RESET} ${RESET}Please update to the latest UniFi OS Release!\\n"; fi
  if [[ "${stopped_unattended_upgrade}" == 'true' ]]; then systemctl start unattended-upgrades &>> "${eus_dir}/logs/unattended-upgrades.log"; unset stopped_unattended_upgrade; fi
  echo -e "${GRAY_R}#${RESET} ${GRAY_R}Author   |  ${WHITE_R}Glenn R.${RESET}"
  echo -e "${GRAY_R}#${RESET} ${GRAY_R}Email    |  ${WHITE_R}glennrietveld8@hotmail.nl${RESET}"
  echo -e "${GRAY_R}#${RESET} ${GRAY_R}Website  |  ${WHITE_R}https://GlennR.nl${RESET}\\n\\n"
}

# Set architecture
architecture="$("$(which dpkg)" --print-architecture)"
if [[ "${architecture}" == 'i686' ]]; then architecture="i386"; fi
if [[ "${architecture}" == 'arm64' ]]; then gr_mongod_name="mongod-armv8"; fi
if [[ "${architecture}" == 'amd64' ]]; then gr_mongod_name="mongod-amd64"; fi
if [[ -z "${gr_mongod_name}" ]]; then gr_mongod_name="mongod-armv8"; echo -e "$(date +%F-%T.%6N) | Variable gr_mongod_name was empty..." &>> "${eus_dir}/logs/variables.log"; fi
if [[ -n "$(command -v jq)" && -e "${eus_dir}/db/db.json" ]]; then
  if [[ "$(dpkg-query --showformat='${version}' --show jq 2> /dev/null | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
    jq '."database" += {"architecture": "'"${architecture}"'"}' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
  else
    jq --arg architecture "$architecture" '.database.architecture = $architecture' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
  fi
  eus_database_move
fi

# Check AVX or not
if [[ "${architecture}" != 'arm64' ]]; then
  if ( ! (lscpu 2>/dev/null | grep -iq "avx") && (lscpu 2>/dev/null | grep -iq "sse4_2") ) || ( ! (grep -iq "avx" /proc/cpuinfo) && (grep -iq "sse4_2" /proc/cpuinfo) ); then glennr_mongod_compatible="true"; fi
  if (lscpu 2>/dev/null | grep -iq "avx2") || (grep -iq "avx2" /proc/cpuinfo); then avx_compatible="true"; glennr_mongod_compatible="true"; fi
  if (lscpu 2>/dev/null | grep -iq "avx") || (grep -iq "avx" /proc/cpuinfo); then avx_compatible="true"; glennr_mongod_compatible="true"; fi
  if ( (lscpu 2>/dev/null | grep -iq "avx") && (lscpu 2>/dev/null | grep -iq "sse4_2") ) || ( (grep -iq "avx" /proc/cpuinfo) && (grep -iq "sse4_2" /proc/cpuinfo) ); then official_mongodb_compatible="true"; fi
else  
  if ! (lscpu 2>/dev/null | grep -iq "avx") || ! grep -iq "avx" /proc/cpuinfo; then glennr_mongod_compatible="true"; fi
fi

# Get distro.
get_distro() {
  if [[ -z "$(command -v lsb_release)" ]] || [[ "${skip_use_lsb_release}" == 'true' ]]; then
    if [[ -f "/etc/os-release" ]]; then
      if grep -iq VERSION_CODENAME /etc/os-release; then
        os_codename="$(grep VERSION_CODENAME /etc/os-release | sed 's/VERSION_CODENAME//g' | tr -d '="' | tr '[:upper:]' '[:lower:]')"
        os_id="$(grep ^"ID=" /etc/os-release | sed 's/ID//g' | tr -d '="' | tr '[:upper:]' '[:lower:]')"
      elif ! grep -iq VERSION_CODENAME /etc/os-release; then
        os_codename="$(grep PRETTY_NAME /etc/os-release | sed 's/PRETTY_NAME=//g' | tr -d '="' | awk '{print $4}' | sed 's/\((\|)\)//g' | sed 's/\/sid//g' | tr '[:upper:]' '[:lower:]')"
        os_id="$(grep -io "debian\\|ubuntu" /etc/os-release | tr '[:upper:]' '[:lower:]' | head -n1)"
        if [[ -z "${os_codename}" ]]; then
          os_codename="$(grep PRETTY_NAME /etc/os-release | sed 's/PRETTY_NAME=//g' | tr -d '="' | awk '{print $3}' | sed 's/\((\|)\)//g' | sed 's/\/sid//g' | tr '[:upper:]' '[:lower:]')"
        fi
      fi
    fi
  else
    os_codename="$(lsb_release --codename --short | tr '[:upper:]' '[:lower:]')"
    os_id="$(lsb_release --id --short | tr '[:upper:]' '[:lower:]')"
    if [[ "${os_codename}" == 'n/a' ]] || [[ -z "${os_codename}" ]]; then
      skip_use_lsb_release="true"
      get_distro
      return
    elif [[ "${os_codename}" == 'lts' ]]; then
      os_codename="$(grep -io "wheezy\\|jessie\\|stretch\\|buster\\|bullseye\\|bookworm\\|trixie\\|forky\\|precise\\|trusty\\|xenial\\|bionic\\|cosmic\\|disco\\|eoan\\|focal\\|groovy\\|hirsute\\|impish\\|jammy\\|kinetic\\|lunar\\|mantic\\|noble\\|oracular\\|plucky\\|questing\\|resolute" /etc/os-release | tr '[:upper:]' '[:lower:]' | awk '!NF || !seen[$0]++' | head -n1)"
    fi
  fi
  if [[ "${unsupported_no_modify}" != 'true' ]]; then
    if [[ ! "${os_id}" =~ (ubuntu|debian) ]] && [[ -e "/etc/os-release" ]]; then os_id="$(grep -io "debian\\|ubuntu" /etc/os-release | tr '[:upper:]' '[:lower:]' | head -n1)"; fi
    if [[ "${os_codename}" =~ ^(precise|maya|luna|toutatis)$ ]]; then repo_codename="precise"; os_codename="precise"; os_id="ubuntu"
    elif [[ "${os_codename}" =~ ^(trusty|qiana|rebecca|rafaela|rosa|freya|belenos)$ ]]; then repo_codename="trusty"; os_codename="trusty"; os_id="ubuntu"
    elif [[ "${os_codename}" =~ ^(xenial|sarah|serena|sonya|sylvia|loki|flidas)$ ]]; then repo_codename="xenial"; os_codename="xenial"; os_id="ubuntu"
    elif [[ "${os_codename}" =~ ^(bionic|tara|tessa|tina|tricia|hera|juno|etiona)$ ]]; then repo_codename="bionic"; os_codename="bionic"; os_id="ubuntu"
    elif [[ "${os_codename}" =~ ^(focal|ulyana|ulyssa|uma|una|odin|jolnir|nabia)$ ]]; then repo_codename="focal"; os_codename="focal"; os_id="ubuntu"
    elif [[ "${os_codename}" =~ ^(jammy|vanessa|vera|victoria|virginia|horus|cade|aramo)$ ]]; then repo_codename="jammy"; os_codename="jammy"; os_id="ubuntu"
    elif [[ "${os_codename}" =~ ^(noble|wilma|xia|zara|zena|scootski|circe|ecne)$ ]]; then repo_codename="noble"; os_codename="noble"; os_id="ubuntu"
    elif [[ "${os_codename}" =~ ^(oracular)$ ]]; then repo_codename="oracular"; os_codename="oracular"; os_id="ubuntu"
    elif [[ "${os_codename}" =~ ^(plucky)$ ]]; then repo_codename="plucky"; os_codename="plucky"; os_id="ubuntu"
    elif [[ "${os_codename}" =~ ^(questing)$ ]]; then repo_codename="questing"; os_codename="questing"; os_id="ubuntu"
    elif [[ "${os_codename}" =~ ^(resolute)$ ]]; then repo_codename="resolute"; os_codename="resolute"; os_id="ubuntu"
    elif [[ "${os_codename}" =~ ^(jessie|betsy)$ ]]; then repo_codename="jessie"; os_codename="jessie"; os_id="debian"
    elif [[ "${os_codename}" =~ ^(stretch|continuum|helium|cindy|tyche|ascii)$ ]]; then repo_codename="stretch"; os_codename="stretch"; os_id="debian"
    elif [[ "${os_codename}" =~ ^(buster|debbie|parrot|engywuck-backports|engywuck|deepin|lithium|beowulf|po-tolo|nibiru|amber|eagle)$ ]]; then repo_codename="buster"; os_codename="buster"; os_id="debian"
    elif [[ "${os_codename}" =~ ^(bullseye|kali-rolling|elsie|ara|beryllium|chimaera|orion-belt|byzantium|xenon|tiger)$ ]]; then repo_codename="bullseye"; os_codename="bullseye"; os_id="debian"
    elif [[ "${os_codename}" =~ ^(bookworm|lory|faye|boron|beige|preslee|daedalus|crimson|vapour|shockworm|yirmiuc)$ ]]; then repo_codename="bookworm"; os_codename="bookworm"; os_id="debian"
    elif [[ "${os_codename}" =~ ^(trixie|excalibur|seven-sisters|gigi|yirmibes)$ ]]; then repo_codename="trixie"; os_codename="trixie"; os_id="debian"
    elif [[ "${os_codename}" =~ ^(forky|freia|tiamat)$ ]]; then repo_codename="forky"; os_codename="forky"; os_id="debian"
    elif [[ "${os_codename}" =~ ^(unstable|rolling|nest)$ ]]; then repo_codename="unstable"; os_codename="unstable"; os_id="debian"
    else
      repo_codename="${os_codename}"
    fi
    if [[ -n "$(command -v jq)" && "$(jq -r '.database.distribution' "${eus_dir}/db/db.json")" != "${os_codename}" ]]; then
      if [[ "$(dpkg-query --showformat='${version}' --show jq 2> /dev/null | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
        jq '."database" += {"distribution": "'"${os_codename}"'"}' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
      else
        jq --arg os_codename "$os_codename" '.database.distribution = $os_codename' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
      fi
      eus_database_move
    fi
  fi
}
get_distro

get_repo_url() {
  unset archived_repo
  if [[ "${os_codename}" != "${repo_codename}" ]]; then os_codename="${repo_codename}"; os_codename_changed="true"; fi
  if "$(which dpkg)" -l apt 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then apt_package_version="$(dpkg-query --showformat='${version}' --show apt 2> /dev/null | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)"; fi
  if "$(which dpkg)" -l apt-transport-https 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui" && [[ "${force_http_repositories}" != 'true' ]] || [[ "${apt_package_version::2}" -ge "15" && "${force_http_repositories}" != 'true' ]]; then
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
  if "$(which dpkg)" -l curl 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
    if [[ "$(command -v jq)" ]]; then distro_api_status="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/distro?status" 2> /dev/null | jq -r '.availability' 2> /dev/null)"; else distro_api_status="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/distro?status" 2> /dev/null | grep -oP '(?<="availability":")[^"]+')"; fi
    if [[ "${distro_api_status}" == "OK" ]]; then
      if [[ "${http_or_https}" == "http" ]]; then api_repo_url_procotol="&protocol=insecure"; fi
      if [[ "${use_raspberrypi_repo}" == 'true' ]]; then os_id="raspbian"; if [[ "${architecture}" == 'arm64' ]]; then repo_arch_value="arch=arm64"; fi; unset use_raspberrypi_repo; fi
      distro_api_output="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/distro?distribution=${os_id}&version=${os_codename}&architecture=${architecture}${api_repo_url_procotol}" 2> /dev/null)"
      if [[ "$(command -v jq)" ]]; then archived_repo="$(echo "${distro_api_output}" | jq -r '.codename_eol')"; else archived_repo="$(echo "${distro_api_output}" | grep -oP '"codename_eol":\s*\K[^,}]+')"; fi
      if [[ "${get_repo_url_security_url}" == "true" ]]; then get_repo_url_url_argument="security_repository"; unset get_repo_url_security_url; else get_repo_url_url_argument="repository"; fi
      if [[ "$(command -v jq)" ]]; then repo_url="$(echo "${distro_api_output}" | jq -r ".${get_repo_url_url_argument}")"; else repo_url="$(echo "${distro_api_output}" | grep -oP "\"${get_repo_url_url_argument}\":\s*\"\K[^\"]+")"; fi
      distro_api="true"
    else
      if [[ "${os_codename}" =~ (precise|trusty|utopic|vivid|wily|yakkety|zesty|artful|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing|resolute) ]]; then
        if curl "${curl_argument[@]}" "${http_or_https}://old-releases.ubuntu.com/ubuntu/dists/" 2> /dev/null | grep -iq "${os_codename}" 2> /dev/null; then archived_repo="true"; fi
        if [[ "${architecture}" =~ (amd64|i386) ]]; then
          if [[ "${archived_repo}" == "true" ]]; then
            repo_url="${http_or_https}://old-releases.ubuntu.com/ubuntu"
          else
            if [[ "${get_repo_url_security_url}" == "true" ]]; then
              repo_url="${http_or_https}://security.ubuntu.com/ubuntu"
              unset get_repo_url_security_url
            else
              repo_url="${http_or_https}://archive.ubuntu.com/ubuntu"
            fi
          fi
        else
          if [[ "${archived_repo}" == "true" ]]; then repo_url="${http_or_https}://old-releases.ubuntu.com/ubuntu"; else repo_url="${http_or_https}://ports.ubuntu.com"; fi
        fi
      elif [[ "${os_codename}" =~ (wheezy|jessie|stretch|buster|bullseye|bookworm|trixie|forky|unstable) ]]; then
        if curl "${curl_argument[@]}" "${http_or_https}://archive.debian.org/debian/dists/" 2> /dev/null | grep -iq "${os_codename}" 2> /dev/null; then archived_repo="true"; fi
        if [[ "${archived_repo}" == "true" ]]; then repo_url="${http_or_https}://archive.debian.org/debian"; else repo_url="${http_or_https}://deb.debian.org/debian"; fi
        if [[ "${architecture}" == 'armhf' ]]; then
          repo_arch_value="arch=armhf"
          if curl "${curl_argument[@]}" "${http_or_https}://legacy.raspbian.org/raspbian/dists/" 2> /dev/null | grep -iq "${os_codename}" 2> /dev/null; then archived_raspbian_repo="true"; fi
          if [[ "${archived_raspbian_repo}" == "true" ]]; then raspbian_repo_url="${http_or_https}://legacy.raspbian.org/raspbian"; else raspbian_repo_url="${http_or_https}://archive.raspbian.org/raspbian"; fi
        fi
        if [[ "${use_raspberrypi_repo}" == 'true' ]]; then
          if [[ "${architecture}" == 'arm64' ]]; then repo_arch_value="arch=arm64"; fi
          if curl "${curl_argument[@]}" "${http_or_https}://legacy.raspbian.org/raspbian/dists/" 2> /dev/null | grep -iq "${os_codename}" 2> /dev/null; then archived_repo="true"; fi
          if [[ "${archived_repo}" == "true" ]]; then repo_url="${http_or_https}://legacy.raspbian.org/raspbian"; else repo_url="${http_or_https}://archive.raspberrypi.org/debian"; fi
          unset use_raspberrypi_repo
        fi
      fi
    fi
  else
    if [[ "${os_codename}" =~ (precise|trusty|utopic|vivid|wily|yakkety|zesty|artful|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing|resolute) ]]; then
      repo_url="${http_or_https}://archive.ubuntu.com/ubuntu"
    elif [[ "${os_codename}" =~ (wheezy|jessie|stretch|buster|bullseye|bookworm|trixie|forky|unstable) ]]; then
      repo_url="${http_or_https}://deb.debian.org/debian"
      if [[ "${architecture}" == 'armhf' ]]; then
        raspbian_repo_url="${http_or_https}://archive.raspbian.org/raspbian"
      fi
    fi
  fi
}
get_repo_url

cleanup_archived_repos() {
  if [[ "${archived_repo}" == "true" ]]; then
    repo_patterns=( "deb.debian.org\\/debian ${os_codename}" "deb.debian.org\\/debian\\/ ${os_codename}" "ftp.*.debian.org\\/debian ${os_codename}" "ftp.*.debian.org\\/debian ${os_codename}" "ftp.*.debian.org\\/debian\\/ ${os_codename}" "security.debian.org ${os_codename}" "security.debian.org\\/ ${os_codename}" "security.debian.org\\/debian-security ${os_codename}" "security.debian.org\\/debian-security\\/ ${os_codename}" "ftp.debian.org\\/debian ${os_codename}" "ftp.debian.org\\/debian\\/ ${os_codename}" "http.debian.net\\/debian ${os_codename}" "http.debian.net\\/debian\\/ ${os_codename}" "\\*.archive.ubuntu.com\\/ubuntu ${os_codename}" "\\*.archive.ubuntu.com\\/ubuntu\\/ ${os_codename}" "archive.ubuntu.com\\/ubuntu ${os_codename}" "archive.ubuntu.com\\/ubuntu\\/ ${os_codename}" "security.ubuntu.com\\/ubuntu ${os_codename}" "security.ubuntu.com\\/ubuntu\\/ ${os_codename}" "archive.raspbian.org\\/raspbian ${os_codename}" "archive.raspbian.org\\/raspbian\\/ ${os_codename}" "archive.raspberrypi.org\\/raspbian ${os_codename}" "archive.raspberrypi.org\\/raspbian\\/ ${os_codename}" "httpredir.debian.org\\/debian ${os_codename}" "httpredir.debian.org\\/debian\\/ ${os_codename}" )
    # Handle .list files
    while read -r list_file; do
      for pattern in "${repo_patterns[@]}"; do
        sed -Ei "/^#*${pattern}/!s|^(${pattern})|#\1|g" "${list_file}"
      done
    done < <(find /etc/apt/ -type f -name "*.list")
    while read -r sources_file; do
      for pattern in "${repo_patterns[@]}"; do
        entry_block_start_line="$(awk '!/^#/ && /Types:/ { types_line=NR } /'"${pattern}"'/ && !/^#/ && !seen[types_line]++ { print types_line }' "${sources_file}" | head -n1)"
        entry_block_end_line="$(awk -v start_line="$entry_block_start_line" 'NR > start_line && NF == 0 { print NR-1; exit } END { if (NR > start_line && NF > 0) print NR }' "${sources_file}")"
        if [[ -n "${entry_block_start_line}" && -n "${entry_block_end_line}" ]]; then
          sed -i "${entry_block_start_line},${entry_block_end_line}s/^\([^#]\)/# \1/" "${sources_file}" &>/dev/null
        fi
      done
    done < <(find /etc/apt/sources.list.d/ -type f -name "*.sources")
  fi
}
cleanup_archived_repos

unset_add_repositories_variables(){
  unset repo_key_name
  unset repo_url_arguments
  unset repo_codename_argument
  unset repo_component
  unset signed_by_value_repo_key
  unset repo_arch_value
  unset add_repositories_source_list_override
  if [[ "${os_id}" == "raspbian" ]]; then get_distro; fi
}

unset_section_variables() {
  unset section
  unset section_types
  unset section_components
  unset section_suites
  unset section_url
  unset section_enabled
}

add_repositories() {
  # Check if repository is already added
  if grep -sq "^deb .*http\?s\?://$(echo "${repo_url}" | sed -e 's/https\:\/\///g' -e 's/http\:\/\///g')${repo_url_arguments}\?/\? ${repo_codename}${repo_codename_argument} ${repo_component}" /etc/apt/sources.list /etc/apt/sources.list.d/*.list /etc/apt/sources.list.d/*.sources; then
    echo -e "$(date +%F-%T.%6N) | \"${repo_url}${repo_url_arguments} ${repo_codename}${repo_codename_argument} ${repo_component}\" was found, not adding to repository lists. $(grep -srIl "^deb .*http\?s\?://$(echo "${repo_url}" | sed -e 's/https\:\/\///g' -e 's/http\:\/\///g')${repo_url_arguments}\?/\? ${repo_codename}${repo_codename_argument} ${repo_component}" /etc/apt/sources.list /etc/apt/sources.list.d/*.list /etc/apt/sources.list.d/*.sources)..." &>> "${eus_dir}/logs/already-found-repository.log"
    unset_add_repositories_variables
    return  # Repository already added, exit function
  elif find /etc/apt/sources.list.d/ -name "*.sources" | grep -ioq /etc/apt; then
    repo_component_trimmed="${repo_component#"${repo_component%%[![:space:]]*}"}" # remove leading space
    while IFS= read -r repository_file; do
      last_line_repository_file="$(tail -n1 "${repository_file}")"
      while IFS= read -r line || [[ -n "${line}" ]]; do
        if [[ -z "${line}" || "${last_line_repository_file}" == "${line}" ]]; then
          if [[ -n "$section" ]]; then
            section_types="$(grep -oPm1 'Types: \K.*' <<< "$section")"
            section_url="$(grep -oPm1 'URIs: \K.*' <<< "$section" | grep -i "http\?s\?://$(echo "${repo_url}" | sed -e 's/https\:\/\///g' -e 's/http\:\/\///g')${repo_url_arguments}\?/\?")"
            section_suites="$(grep -oPm1 'Suites: \K.*' <<< "$section")"
            section_components="$(grep -oPm1 'Components: \K.*' <<< "$section")"
            section_enabled="$(grep -oPm1 'Enabled: \K.*' <<< "$section")"
            if [[ -z "${section_enabled}" ]]; then section_enabled="yes"; fi
            if [[ -n "${section_url}" && "${section_enabled}" == 'yes' && "${section_types}" == *"deb"* && "${section_suites}" == "${repo_codename}${repo_codename_argument}" && "${section_components}" == *"${repo_component_trimmed}"* ]]; then
              echo -e "$(date +%F-%T.%6N) | URIs: $section_url Types: $section_types Suites: $section_suites Components: $section_components was found, not adding to repository lists..." &>> "${eus_dir}/logs/already-found-repository.log"
              unset_add_repositories_variables
              unset_section_variables
              return
            fi
            unset_section_variables
          fi
        else
          section+="${line}"$'\n'
        fi
      done < "${repository_file}"
    done < <(find /etc/apt/sources.list.d/ -name "*.sources" | grep -i /etc/apt)
  fi
  # Override the source list
  if [[ -n "${add_repositories_source_list_override}" ]]; then
    add_repositories_source_list="/etc/apt/sources.list.d/${add_repositories_source_list_override}.${source_file_format}"
  else
    add_repositories_source_list="/etc/apt/sources.list.d/glennr-install-script.${source_file_format}"
  fi
  # Add repository key if required
  if [[ "${apt_key_deprecated}" == 'true' && -n "${repo_key}" && -n "${repo_key_name}" ]]; then
    eus_directory_location="/tmp/EUS"
    eus_create_directories "apt"
    if gpg --no-default-keyring --keyring "/etc/apt/keyrings/${repo_key_name}.gpg" --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys "${repo_key}" &> /tmp/EUS/apt/repository-key.log; then
      signed_by_value_repo_key="signed-by=/etc/apt/keyrings/${repo_key_name}.gpg"
      repository_key_location="/etc/apt/keyrings/${repo_key_name}.gpg"; check_repository_key_permissions
    else
      abort_reason="Failed to add repository key ${repo_key} (${repo_key_name}.gpg)."
      abort
    fi
  fi
  # Handle Debian versions
  if [[ "${os_codename}" =~ (wheezy|jessie|stretch|buster|bullseye|bookworm|trixie|forky|unstable) && "$(command -v jq)" ]]; then
    os_version_number="$(lsb_release -rs | tr '[:upper:]' '[:lower:]' | cut -d'.' -f1)"
    check_debian_version="${os_version_number}"
    if echo "${repo_url}" | grep -ioq "archive.debian"; then 
      check_debian_version="${os_version_number}-archive"
    elif echo "${repo_url_arguments}" | grep -ioq "security.debian"; then 
      check_debian_version="${os_version_number}-security"
    fi
    if [[ "$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/debian-release?version=${check_debian_version}" 2> /dev/null | jq -r '.expired' 2> /dev/null)" == 'true' ]]; then 
      if [[ "${use_deb822_format}" == 'true' ]]; then
        deb822_trusted="\nTrusted: yes"
      else
        signed_by_value_repo_key+=" trusted=yes"
      fi
    fi
  fi
  # Prepare repository entry
  if [[ -n "${signed_by_value_repo_key}" && -n "${repo_arch_value}" ]]; then
    local brackets="[${signed_by_value_repo_key}${repo_arch_value}] "
  else
    local brackets=""
  fi
  # Attempt to find the repository signing key for Debian/Ubuntu.
  if [[ -z "${signed_by_value_repo_key}" && "${use_deb822_format}" == 'true' ]] && echo "${repo_url}" | grep -ioq "ports.ubuntu\\|archive.ubuntu\\|security.ubuntu\\|deb.debian"; then
    signed_by_value_repo_key_find="$(echo "${repo_url}" | sed -e 's/https\:\/\///g' -e 's/http\:\/\///g' -e 's/\/.*//g' -e 's/\.com//g' -e 's/\./-/g' -e 's/\./-/g' -e 's/deb-debian/archive-debian/g' -e 's/security-ubuntu/archive-ubuntu/g' -e 's/ports-ubuntu/archive-ubuntu/g' -e 's/old-releases/archive-ubuntu/g' | awk -F'-' '{print $2 "-" $1}')"
    if [[ -n "${signed_by_value_repo_key_find}" ]]; then
      if [[ "${repo_codename_argument//-/}" == "security" ]]; then signed_by_value_repo_security="${repo_codename_argument}"; else unset signed_by_value_repo_security; fi
      if [[ "${os_id}" == "debian" ]]; then
        if [[ "${signed_by_value_repo_security//-/}" == "security" ]]; then
          signed_by_value_repo_key="signed-by=$(find /usr/share/keyrings/ /etc/apt/keyrings/ -name "${signed_by_value_repo_key_find}-${repo_codename}${signed_by_value_repo_security}*" | sed '/removed/d' | head -n1)"
        else
          signed_by_value_repo_key="signed-by=$(find /usr/share/keyrings/ /etc/apt/keyrings/ -name "${signed_by_value_repo_key_find}-${repo_codename}*" ! -name "*security*" | sed '/removed/d' | head -n1)"
        fi
      else
        signed_by_value_repo_key="signed-by=$(find /usr/share/keyrings/ /etc/apt/keyrings/ -name "${signed_by_value_repo_key_find}*" | sed '/removed/d' | head -n1)"
      fi
    fi
  fi
  # Determine format
  if [[ "${use_deb822_format}" == 'true' ]]; then
    repo_component_trimmed="${repo_component#"${repo_component%%[![:space:]]*}"}" # remove leading space
    repo_entry="Types: deb\nURIs: ${repo_url}${repo_url_arguments}\nSuites: ${repo_codename}${repo_codename_argument}\nComponents: ${repo_component_trimmed}"
    if [[ -n "${signed_by_value_repo_key}" ]]; then repo_entry+="\nSigned-By: ${signed_by_value_repo_key/signed-by=/}"; fi
    if [[ -n "${repo_arch_value}" ]]; then repo_entry+="\nArchitectures: ${repo_arch_value//arch=/}"; fi
    if [[ -n "${deb822_trusted}" ]]; then repo_entry+="${deb822_trusted}"; fi
    repo_entry+="\n"
  else
    repo_entry="deb ${brackets}${repo_url}${repo_url_arguments} ${repo_codename}${repo_codename_argument} ${repo_component}"
  fi
  # Add repository to sources list
  if echo -e "${repo_entry}" >> "${add_repositories_source_list}"; then
    echo -e "$(date +%F-%T.%6N) | Successfully added \"${repo_entry}\" to ${add_repositories_source_list}!" &>> "${eus_dir}/logs/added-repository.log"
  else
    abort_reason="Failed to add repository."
    abort
  fi
  # Handle HTTP repositories
  if [[ "${add_repositories_http_or_https}" == 'http' ]]; then
    eus_create_directories "repositories"
    while read -r https_repo_needs_http_file; do
      if [[ -d "${eus_dir}/repositories" ]]; then 
        cp "${https_repo_needs_http_file}" "${eus_dir}/repositories/$(basename "${https_repo_needs_http_file}")" &>> "${eus_dir}/logs/https-repo-needs-http.log"
        copied_source_files="true"
      fi
      sed -i '/https/{s/^/#/}' "${https_repo_needs_http_file}" &>> "${eus_dir}/logs/https-repo-needs-http.log"
      sed -i 's/##/#/g' "${https_repo_needs_http_file}" &>> "${eus_dir}/logs/https-repo-needs-http.log"
    done < <(grep -sril "^deb https*://$(echo "${repo_url}" | sed -e 's/https\:\/\///g' -e 's/http\:\/\///g') ${repo_codename}${repo_codename_argument} ${repo_component}" /etc/apt/sources.list /etc/apt/sources.list.d/*)
  fi 
  # Clean up unset variables
  unset_add_repositories_variables
  # Check if OS codename changed and reset variables
  if [[ "${os_codename_changed}" == 'true' ]]; then 
    unset os_codename_changed
    get_distro
    get_repo_url
  else
    if [[ "${os_id}" == "raspbian" ]]; then get_distro; fi
  fi
}

get_unifi_application_status() {
  local host="${1:-localhost}"   # default to localhost if no arg is passed
  local url="${status_api_protocol}://${host}:${dmport}/status"
  if [[ "${unifi_core_system}" == 'true' ]]; then
    if [[ -n "$(command -v jq)" ]]; then
      application_up="$(curl --silent --insecure "${url}" | jq -r '.meta.server_running' 2> /dev/null)"
      if [[ -z "${application_up}" ]]; then application_up="$(curl "${noproxy_curl_argument[@]}" --silent --insecure --connect-timeout 1 "${url}" | jq -r '.meta.server_running' 2> /dev/null)"; fi
    else
      application_up="$(curl --silent --insecure --connect-timeout 1 "${url}" | grep -o '"server_running":[^,]*' | awk -F ':' '{print $2}')"
      if [[ -z "${application_up}" ]]; then application_up="$(curl "${noproxy_curl_argument[@]}" --silent --insecure --connect-timeout 1 "${url}" | grep -o '"server_running":[^,]*' | awk -F ':' '{print $2}')"; fi
    fi
  else
    if [[ -n "$(command -v jq)" ]]; then
      application_up="$(curl --silent --insecure "${url}" | jq -r '.meta.up' 2> /dev/null)"
      if [[ -z "${application_up}" ]]; then application_up="$(curl "${noproxy_curl_argument[@]}" --silent --insecure --connect-timeout 1 "${url}" | jq -r '.meta.up' 2> /dev/null)"; fi
    else
      application_up="$(curl --silent --insecure --connect-timeout 1 "${url}" | grep -o '"up":[^,]*' | awk -F ':' '{print $2}')"
      if [[ -z "${application_up}" ]]; then application_up="$(curl "${noproxy_curl_argument[@]}" --silent --insecure --connect-timeout 1 "${url}" | grep -o '"up":[^,]*' | awk -F ':' '{print $2}')"; fi
    fi
  fi
}

get_uos_server_status() {
  local host="${1:-localhost}"  # default to localhost if no arg is passed
  local url="https://${host}:${uos_server_web_port}/api/system"
  if [[ -n "$(command -v jq)" ]]; then
    application_up="$(curl --silent --insecure "${url}" | jq -r ''.deviceState // .isSetup'' 2> /dev/null)"
    if [[ -z "${application_up}" ]]; then application_up="$(curl "${noproxy_curl_argument[@]}" --silent --insecure --connect-timeout 1 "${url}" | jq -r ''.deviceState // .isSetup'' 2> /dev/null)"; fi
  else
    application_up="$(curl --silent --insecure --connect-timeout 1 "${url}" | grep -oE '"(deviceState|isSetup)":[^,]*' | awk -F ':' '{print $2}')"
    if [[ -z "${application_up}" ]]; then application_up="$(curl "${noproxy_curl_argument[@]}" --silent --insecure --connect-timeout 1 "${url}" | grep -oE '"(deviceState|isSetup)":[^,]*' | awk -F ':' '{print $2}')"; fi
  fi
  if [[ -n "${application_up}" ]]; then application_up="true"; fi
}

get_unifi_api_ports() {
  if [[ "${unifi_core_system}" == 'true' ]]; then
    dmport="8081"
    status_api_protocol="http"
  else
    if grep -sioq "^unifi.https.port" "/usr/lib/unifi/data/system.properties"; then dmport="$(awk '/^unifi.https.port/' /usr/lib/unifi/data/system.properties | cut -d'=' -f2)"; else dmport="8443"; fi
    status_api_protocol="https"
  fi
}
get_unifi_api_ports

if ! grep -iq '^127.0.0.1.*localhost' /etc/hosts; then
  if [[ "${script_option_debug}" != 'true' ]]; then clear; fi
  header_red
  echo -e "${GRAY_R}#${RESET} '127.0.0.1   localhost' does not exist in your /etc/hosts file."
  echo -e "${GRAY_R}#${RESET} You will most likely see application startup issues if it doesn't exist..\\n\\n"
  while true; do
    read -rp $'\033[39m#\033[0m Do you want to add "127.0.0.1   localhost" to your /etc/hosts file? (Y/n) ' yes_no
    case "$yes_no" in
        [Yy]*|"")
            echo -e "${GRAY_R}----${RESET}\\n"
            echo -e "${GRAY_R}#${RESET} Adding '127.0.0.1       localhost' to /etc/hosts"
            sed  -i '1i # ------------------------------' /etc/hosts
            sed  -i '1i 127.0.0.1       localhost' /etc/hosts
            sed  -i '1i # Added by GlennR EUS script' /etc/hosts && echo -e "${GRAY_R}#${RESET} Done..\\n\\n"
            sleep 3
            break;;
        [Nn]*)
            break;;
        *)
            echo -e "\\n${RED}#${RESET} Invalid input, please answer Yes or No (y/n)...\\n"
            sleep 3;;
    esac
  done
fi

check_mongodb_installed() {
  unset mongodb_installed
  "$(which dpkg)" -l | grep -E "(mongodb-server|mongodb-org-server|mongod-armv8|mongod-amd64)[[:space:]]" | grep "^ii\\|^hi" | awk '{print $3}' | sed -e 's/.*://' -e 's/-.*//' -e 's/+.*//' &> /tmp/EUS/mongodb_versions
  if ! [[ -s "/tmp/EUS/mongodb_versions" ]]; then
    if [[ -n "$(command -v mongod)" ]]; then
      if "${mongocommand}" --port 27117 --eval "print(\"waited for connection\")" &> /dev/null; then
        "$(which mongod)" --quiet --eval "db.version()" | sed 's/\.//g' | sed 's/.*://' | sed 's/-.*//g' &> /tmp/EUS/mongodb_versions
      else
        "$(which mongod)" --version --quiet | tr '[:upper:]' '[:lower:]' | sed -e '/db version/d' -e '/mongodb shell/d' -e 's/build info: //g' | jq -r '.version' &> /tmp/EUS/mongodb_versions
      fi
    fi
  fi
  mongodb_version_installed="$(sort -V /tmp/EUS/mongodb_versions | tail -n 1)"
  mongodb_version_installed_no_dots="${mongodb_version_installed//./}"
  if [[ -n "${mongodb_version_installed}" ]]; then mongodb_installed="true"; fi
  if "$(which dpkg)" -l | grep "^ii\\|^hi" | grep -iq "mongodb-server$\\|mongodb-org-server"; then mongodb_installed="true"; fi
  rm --force /tmp/EUS/mongodb_versions &> /dev/null
  first_digit_mongodb_version_installed="$(echo "${mongodb_version_installed}" | cut -d'.' -f1)"
  second_digit_mongodb_version_installed="$(echo "${mongodb_version_installed}" | cut -d'.' -f2)"
}

check_and_add_to_path() {
  local directory="$1"
  if ! echo "${PATH}" | grep -qE "(^|:)$directory(:|$)"; then
    export PATH="$directory:$PATH"
    echo "$(date +%F-%T.%6N) | Added $directory to PATH" &>> "${eus_dir}/logs/path.log"
  fi
}
check_and_add_to_path "/usr/local/sbin"
check_and_add_to_path "/usr/sbin"
check_and_add_to_path "/sbin"

update_script() {
  check_apt_listbugs
  header_red
  echo -e "${GRAY_R}#${RESET} You're currently running script version ${local_version} while ${online_version} is the latest!"
  echo -e "${GRAY_R}#${RESET} Downloading and executing version ${online_version} of the script...\\n\\n"
  echo -e "$(date +%F-%T.%6N) | Updating script \"${script_name}\" from version \"${local_version}\" to \"${online_version}\"..." &>> "${eus_dir}/logs/script-update.log"
  sleep 2
  if [[ -n "$(command -v jq)" ]]; then
    online_sha256sum="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/latest-script-version?script=unifi-install&version=${install_version}" 2> /dev/null | jq -r '.checksums.sha256sum' 2> /dev/null | sed '/null/d')"
  else
    online_sha256sum="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/latest-script-version?script=unifi-install&version=${install_version}" 2> /dev/null | grep -oP '"sha256sum"\s*:\s*"\K[^"]+')"
  fi
  if curl "${curl_argument[@]}" -o "${script_location}.tmp" "https://get.glennr.nl/unifi/install/${install_script_name}.sh"; then
    if [[ -n "${online_sha256sum}" && "$(command -v sha256sum)" ]]; then
      local_checksum="$(sha256sum "${script_location}.tmp" 2> /dev/null | awk '{print $1}')"
      if [[ "${local_checksum}" != "${online_sha256sum}" ]]; then
        for attempt in {1..5}; do
          if [[ -n "$(command -v jq)" ]]; then
            online_sha256sum_latest="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/latest-script-version?script=unifi-install&version=${install_version}" 2> /dev/null | jq -r '.checksums.sha256sum' 2> /dev/null | sed '/null/d')"
          else
            online_sha256sum_latest="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/latest-script-version?script=unifi-install&version=${install_version}" 2> /dev/null | grep -oP '"sha256sum"\s*:\s*"\K[^"]+')"
          fi
          if [[ -n "${online_sha256sum_latest}" ]]; then online_sha256sum="${online_sha256sum_latest}"; unset online_sha256sum_latest; fi
          local_checksum="$(sha256sum "${script_location}.tmp" 2> /dev/null | awk '{print $1}')"
          if [[ "${local_checksum}" == "${online_sha256sum}" ]]; then
            echo -e "$(date +%F-%T.%6N) | Successfully updated script \"${script_name}\" from version \"${local_version}\" to \"${online_version}\"!" &>> "${eus_dir}/logs/script-update.log"
            rm --force "${script_location}" 2> /dev/null
            # shellcheck disable=SC2068
            mv "${script_location}.tmp" "${script_location}" && bash "${script_location}" ${script_options[@]}
            exit 0
          else
            echo -e "$(date +%F-%T.%6N) | Local script file SHA256 is \"${local_checksum}\" while it should be \"${online_sha256sum}\" (attempt ${attempt}/5)..." &>> "${eus_dir}/logs/script-update.log"
            echo -e "${RED}#${RESET} Checksum mismatch (attempt ${attempt}/5), retrying download..."
            sleep 5
            curl "${curl_argument[@]}" -o "${script_location}.tmp" "https://get.glennr.nl/unifi/install/${install_script_name}.sh"
          fi
        done
        abort_reason="Failed to update the script, checksum mismatch"
        abort
      else
        echo -e "$(date +%F-%T.%6N) | Successfully updated script \"${script_name}\" from version \"${local_version}\" to \"${online_version}\"!" &>> "${eus_dir}/logs/script-update.log"
        rm --force "${script_location}" 2> /dev/null
        # shellcheck disable=SC2068
        mv "${script_location}.tmp" "${script_location}" && bash "${script_location}" ${script_options[@]}
        exit 0
      fi
    else
      if [[ -n "${online_sha256sum}" ]]; then
        echo -e "$(date +%F-%T.%6N) | Variable \"online_sha256sum\" is empty..." &>> "${eus_dir}/logs/script-update.log"
      elif [[ "$(command -v sha256sum)" ]]; then
        echo -e "$(date +%F-%T.%6N) | Unknown command \"sha256sum\"..." &>> "${eus_dir}/logs/script-update.log"
      fi
      rm --force "${install_script_name}.sh" 2> /dev/null
      # shellcheck disable=SC2068
      curl "${curl_argument[@]}" --remote-name "https://get.glennr.nl/unifi/install/${install_script_name}.sh" && bash "${install_script_name}.sh" ${script_options[@]}; exit 0
    fi
  fi
}

script_type_check() {
  if [[ "$(command -v jq)" ]]; then latest_application_release_api_status="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/latest-application-release?status" 2> /dev/null | jq -r '.availability' 2> /dev/null)"; else latest_application_release_api_status="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/latest-application-release?status" 2> /dev/null | grep -oP '(?<="availability":")[^"]+')"; fi
  if [[ "${latest_application_release_api_status}" == "OK" ]]; then
    if [[ -n "$(command -v jq)" ]]; then latest_network_release="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/latest-application-release?app=network&version=latest" 2> /dev/null | jq -r '.latest_release' 2> /dev/null)"; else latest_network_release="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/latest-application-release?app=network&version=latest" 2> /dev/null | sed -n 's/.*"latest_release":"\([^"]*\)".*/\1/p')"; fi
    if [[ -n "$(command -v jq)" ]]; then latest_uos_server_release="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/latest-application-release?app=unifi-os-server&version=latest" 2> /dev/null | jq -r '.latest_release' 2> /dev/null)"; else latest_uos_server_release="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/latest-application-release?app=unifi-os-server&version=latest" 2> /dev/null | sed -n 's/.*"latest_release":"\([^"]*\)".*/\1/p')"; fi
  fi
  if [[ "${latest_network_release}" != "${net_version}" ]]; then
    install_script_name="unifi-${net_version}"
    install_version="${net_version}"
  elif [[ "${latest_uos_server_release}" != "${uos_version}" ]]; then
    install_script_name="unifi-os-server-${uos_version}"
    install_version="uos-${uos_version}"
  else
    install_script_name="unifi-os-server-${uos_version}"
    install_version="uos-${uos_version}"
  fi
}

script_version_check() {
  local local_version
  local online_version
  net_version="$(grep -im1 '# Application version' "$script_location" | awk -F'[|-]' '{gsub(/[[:space:]]/, "", $2); print $2}')"
  uos_version="$(grep -im1 '# UOS Server version' "$script_location" | awk -F'[|-]' '{gsub(/[[:space:]]/, "", $2); print $2}')"
  script_type_check
  local_version="$(grep -im1 "# Script Version" "${script_location}" | awk -F'|' '{gsub(/[[:space:]]/, "", $2); print $2}')"
  if [[ -n "$(command -v jq)" ]]; then
    online_version="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/latest-script-version?script=unifi-install" 2> /dev/null | jq -r '."latest-script-version"' 2> /dev/null)"
  else
    online_version="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/latest-script-version?script=unifi-install" 2> /dev/null | grep -oP '(?<="latest-script-version":")[0-9.]+')"
  fi
  IFS='.' read -r -a local_parts <<< "${local_version}"
  IFS='.' read -r -a online_parts <<< "${online_version}"
  local max_length=$(( ${#local_parts[@]} > ${#online_parts[@]} ? ${#local_parts[@]} : ${#online_parts[@]} ))
  for ((i = 0; i < max_length; i++)); do
    local local_segment="${local_parts[$i]:-0}"
    local online_segment="${online_parts[$i]:-0}"
    if (( local_segment < online_segment )); then
      update_script
      return
    elif (( local_segment > online_segment )); then
      return
    fi
  done
}
if [[ "$(command -v curl)" ]]; then script_version_check; fi

if ! [[ "${os_codename}" =~ (precise|maya|trusty|utopic|vivid|wily|yakkety|zesty|artful|qiana|rebecca|rafaela|rosa|xenial|sarah|serena|sonya|sylvia|bionic|tara|tessa|tina|tricia|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing|resolute|wheezy|jessie|stretch|buster|bullseye|bookworm|trixie|forky|unstable) ]]; then
  if [[ -e "/etc/os-release" ]]; then full_os_details="$(sed ':a;N;$!ba;s/\n/\\n/g' /etc/os-release | sed 's/"/\\"/g')"; fi
  if [[ -z "$(which apt)" ]]; then non_apt_based_linux="true"; fi
  unsupported_no_modify="true"
  get_distro
  if [[ "${non_apt_based_linux}" != 'true' ]]; then distro_support_missing_report="$(curl "${curl_argument[@]}" -X POST -H "Content-Type: application/json" -d "{\"distribution\": \"${os_id}\", \"codename\": \"${os_codename}\", \"script-name\": \"${script_name}\", \"full-os-details\": \"${full_os_details}\"}" https://api.glennr.nl/api/missing-distro-support 2> /dev/null | jq -r '.[]' 2> /dev/null)"; fi
  if [[ "${script_option_debug}" != 'true' ]]; then clear; fi
  header_red
  if [[ "${distro_support_missing_report}" == "OK" ]]; then
    echo -e "${GRAY_R}#${RESET} The script does not (yet) support ${os_id} ${os_codename}, and Glenn R. has been informed about it..."
  else
    if [[ "${non_apt_based_linux}" != 'true' ]]; then
      echo -e "${GRAY_R}#${RESET} The script does not yet support ${os_id} ${os_codename}..."
    else
      echo -e "${GRAY_R}#${RESET} It looks like you're a using a linux distribution (${os_id} ${os_codename}) that doesn't use the APT package manager. \\n${GRAY_R}#${RESET} the script is only made for distros based on the APT package manager..."
    fi
  fi
  echo -e "${GRAY_R}#${RESET} Feel free to contact Glenn R. (AmazedMender16) on the UI Community if you need help with installing your UniFi Network Application.\\n\\n"
  author
  exit 1
fi

if ! [[ -d /etc/apt/sources.list.d ]]; then mkdir -p /etc/apt/sources.list.d; fi

version_ge() {
  [[ "$(printf '%s\n' "$1" "$2" | sort -V | head -n1)" == "$2" ]]
}

cmp_symbol() {
  if version_ge "$1" "$2"; then echo ">="; else echo "<"; fi
}

eus_database_update_broken_install() {
  if [[ "$(dpkg-query --showformat='${version}' --show jq 2> /dev/null | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
    jq '.scripts."'"$script_name"'" += {"recovery": {"broken-install": {"script-version": "'"$(grep -im1 "# Script Version" "${script_location}" | awk -F'|' '{gsub(/[[:space:]]/, "", $2); print $2}' | cut -d'-' -f1)"'", "status": "'"$("$(which dpkg)" -l | grep "unifi " | awk '{print $1}')"'", "unifi-version": "'"${broken_unifi_install_version}"'", "previous-mongodb-version": "'"${last_known_good_mongodb_version}"'", "previous-installed-mongodb-version": "'"${last_known_installed_mongodb_version}"'", "detected-date": "'"$(date +%s)"'"}}}' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
  else
    jq --arg script_name "$script_name" --arg script_version "$(grep -im1 "# Script Version" "${script_location}" | awk -F'|' '{gsub(/[[:space:]]/, "", $2); print $2}' | cut -d'-' -f1)" --arg status "$($(which dpkg) -l | grep 'unifi ' | awk '{print $1}')" --arg unifi_version "$broken_unifi_install_version" --arg previous_mongodb_version "$last_known_good_mongodb_version" --arg previous_installed_mongodb_version "$last_known_installed_mongodb_version" --arg detected_date "$(date +%s)" '.scripts[$script_name] += {"recovery": {"broken-install": {"script-version": $script_version,"status": $status,"unifi-version": $unifi_version,"previous-mongodb-version": $previous_mongodb_version,"previous-installed-mongodb-version": $previous_installed_mongodb_version,"detected-date": $detected_date}}}' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
  fi
  eus_database_move
}

broken_packages_check() {
  local broken_packages
  if [[ -d "/tmp/EUS/apt/" ]]; then apt-get check &> /tmp/EUS/apt/apt-check.log; fi
  broken_packages="$(apt-get check 2>&1 | grep -iV "you might" | grep -i "Broken" | awk '{print $2}')"
  if [[ -n "${broken_packages}" ]] || tail -n5 "${eus_dir}/logs/"* | grep -iq "Try 'sudo apt --fix-broken install' with no packages\\|Try 'apt --fix-broken install' with no packages"; then
    echo -e "${GRAY_R}#${RESET} Broken packages found: ${broken_packages}. Attempting to fix..." | tee -a "${eus_dir}/logs/broken-packages.log"
    if "${EUS_APT_ENV[@]}" env DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install --fix-broken &>> "${eus_dir}/logs/broken-packages.log"; then
      echo -e "${GREEN}#${RESET} Successfully fixed the broken packages! \\n" | tee -a "${eus_dir}/logs/broken-packages.log"
    else
      echo -e "${RED}#${RESET} Failed to fix the broken packages! \\n" | tee -a "${eus_dir}/logs/broken-packages.log"
    fi
    while read -r log_file; do
      sed -i 's/--fix-broken install/--fix-broken install (completed)/g' "${log_file}" &> /dev/null
    done < <(find "${eus_dir}/logs/" -maxdepth 1 -type f -exec grep -Eil "Try 'sudo apt --fix-broken install' with no packages|Try 'apt --fix-broken install' with no packages" {} \;)
  fi
}

# Add default repositories
check_default_repositories() {
  get_repo_url
  if [[ "${repo_codename}" =~ (precise|trusty|utopic|vivid|wily|yakkety|zesty|artful|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing|resolute) ]]; then
    if [[ "${repo_codename}" =~ (precise|trusty|utopic|vivid|wily|yakkety|zesty|artful|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish) ]]; then repo_component="main universe multiverse"; add_repositories; fi
    if [[ "${repo_codename}" =~ (jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing|resolute) ]]; then repo_component="main universe multiverse"; add_repositories; fi
    repo_codename_argument="-security"
    repo_component="main universe multiverse"
  elif [[ "${repo_codename}" =~ (wheezy|jessie|stretch|buster|bullseye|bookworm|trixie|forky|unstable) ]]; then
    if [[ "${repo_codename}" =~ (wheezy|jessie|stretch|buster) ]]; then repo_url_arguments="-security/"; repo_codename_argument="/updates"; repo_component="main"; add_repositories; fi
    if [[ "${repo_codename}" =~ (bullseye|bookworm|trixie|forky|unstable) ]]; then repo_url_arguments="-security/"; repo_codename_argument="-security"; repo_component="main"; add_repositories; fi
    repo_component="main"
  fi
  add_repositories
}

attempt_recover_broken_packages_removal_question() {
  while true; do
    if [[ "${script_option_skip}" != 'true' ]]; then read -rp $'\033[39m#\033[0m Do you allow the script to remove the broken packages? (Y/n) ' yes_no; fi
    case "$yes_no" in
         [Yy]*|"") attempt_recover_broken_packages_remove="true"; break;;
         [Nn]*) attempt_recover_broken_packages_remove="false"; break;;
         *) echo -e "\\n${RED}#${RESET} Invalid input, please answer Yes or No (y/n)...\\n"; sleep 3;;
    esac
  done
}

attempt_recover_broken_packages() {
  while IFS= read -r log_file; do
    while IFS= read -r broken_package; do
      broken_package="$(echo "${broken_package}" | xargs)"
      echo -e "\\n------- $(date +%F-%T.%6N) -------\\n" &>> "${eus_dir}/logs/attempt-recover-broken-packages.log"
      if ! dpkg -l | awk '{print $2}' | grep -iq "${broken_package}"; then echo -e "Failed to locate ${broken_package} in dpkg list..." &>> "${eus_dir}/logs/attempt-recover-broken-packages.log"; continue; fi
      echo -e "${GRAY_R}#${RESET} Attempting to recover broken packages..."
      check_dpkg_lock
      if "${EUS_APT_ENV[@]}" env DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_downgrade_option[@]}" "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install -f &>> "${eus_dir}/logs/attempt-recover-broken-packages.log"; then
        echo -e "${GREEN}#${RESET} Successfully attempted to recover broken packages! \\n"
      else
        echo -e "${RED}#${RESET} Failed to attempt to recover broken packages...\\n"
        failed_attempt_recover_broken_packages="true"
        declare -A vars
        vars["broken_$broken_package"]="true"
        broken_package_key="broken_$broken_package"
      fi
      check_dpkg_lock
      if ! dpkg --get-selections | grep -q "^${broken_package}\s*hold$"; then
        echo -e "${GRAY_R}#${RESET} Attempting to prevent ${broken_package} from screwing over apt..."
        check_dpkg_lock
        if echo "${broken_package} hold" | "$(which dpkg)" --set-selections &>> "${eus_dir}/logs/attempt-recover-broken-packages.log"; then
          echo -e "${GREEN}#${RESET} Successfully prevented ${broken_package} from screwing over apt! \\n"
        else
          echo -e "${RED}#${RESET} Failed to prevent ${broken_package} from screwing over apt...\\n"
        fi
      fi
      force_dpkg_configure="true"
      if [[ "${dpkg_interrupted_attempt_recover_broken_check}" != 'true' ]]; then check_dpkg_interrupted; fi
      if [[ "${attempt_recover_broken_packages_remove}" != 'true' ]]; then attempt_recover_broken_packages_removal_question; fi
      if [[ "${failed_attempt_recover_broken_packages}" == 'true' && "${vars[$broken_package_key]}" == 'true' && "${attempt_recover_broken_packages_remove}" == 'true' ]] && apt-mark showmanual | grep -ioq "^$broken_package$"; then
        echo -e "\\n${GRAY_R}#${RESET} Removing the ${broken_package} package so that the files are kept on the system..."
        check_dpkg_lock
        if "$(which dpkg)" --remove --force-remove-reinstreq "${broken_package}" &>> "${eus_dir}/logs/attempt-recover-broken-packages.log"; then
          echo -e "${GREEN}#${RESET} Successfully removed the ${broken_package} package! \\n"
          unset "${vars[$broken_package_key]}"
        else
          echo -e "${RED}#${RESET} Failed to remove the ${broken_package} package...\\n"
        fi
        force_dpkg_configure="true"
        check_dpkg_interrupted
      fi
    done < <(awk 'tolower($0) ~ /errors were encountered while processing/ {flag=1; next} flag { if ($0 ~ /^[ \t]+/) { gsub(/^[ \t]+/, "", $0); print $0 } else { flag=0 } }' "${log_file}" | sort -u | tr -d '\r')
    sed -i "s/Errors were encountered while processing:/Errors were encountered while processing (completed):/g" "${log_file}" 2>> "${eus_dir}/logs/attempt-recover-broken-packages-sed.log"
  done < <(grep -slE '^Errors were encountered while processing:' /tmp/EUS/apt/*.log "${eus_dir}"/logs/*.log | sort -u 2>> /dev/null)
  check_dpkg_interrupted
}

check_unmet_dependencies() {
  if ls /tmp/EUS/apt/*.log 1> /dev/null 2>&1; then
    while IFS= read -r log_file; do
      while read -r dependency; do
        if [[ "${check_unmet_dependencies_repositories_added}" != "true" ]]; then check_default_repositories; check_unmet_dependencies_repositories_added="true"; fi
        dependency_no_version="$(echo "${dependency}" | awk -F' ' '{print $1}')"
        dependency="$(echo "${dependency}" | tr -d '()' | tr -d ',' | sed -e 's/ *= */=/g' -e 's/~//g')"
        if echo "${dependency}" | grep -ioq ">="; then dependency_to_install="${dependency_no_version}"; else dependency_to_install="${dependency}"; fi
        if [[ -n "${dependency_to_install}" ]]; then
          echo -e "Attempting to install unmet dependency: ${dependency_to_install} \\n" &>> "${eus_dir}/logs/unmet-dependency.log"
          if "${EUS_APT_ENV[@]}" env DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "${dependency_to_install}" &>> "${eus_dir}/logs/unmet-dependency.log"; then
            sed -i "s/Depends: ${dependency_no_version}/Depends (completed): ${dependency_no_version}/g" "${log_file}" 2>> "${eus_dir}/logs/unmet-dependency-sed.log"
          else
            if [[ -n "$(command -v jq)" ]]; then
              list_of_distro_versions="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/list-versions?distribution=${os_id}" 2> /dev/null | jq -r '.[]' 2> /dev/null)"
            else
              list_of_distro_versions="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/list-versions?distribution=${os_id}" 2> /dev/null | sed -e 's/\[//g' -e 's/\]//g' -e 's/ //g' -e 's/,//g' | grep .)"
            fi
            while read -r version; do
              add_repositories_source_list_override="glennr-install-script-unmet"
              repo_codename="${version}"
              repo_component="main"
              get_repo_url
              add_repositories
              if [[ "${os_id}" == "ubuntu" && "${distro_api}" == "true" ]]; then
                get_repo_url_security_url="true"
                get_repo_url
                repo_codename_argument="-security"
                repo_component="main"
                add_repositories
              elif [[ "${os_id}" == "debian" && "${distro_api}" == "true" ]]; then
                repo_url_arguments="-security/"
                repo_codename_argument="-security"
                repo_component="main"
                add_repositories
              fi
              silent_run_apt_get_update="true"
              run_apt_get_update_with_sha1_fallback
              if "${EUS_APT_ENV[@]}" env DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "${dependency_to_install}" &>> "${eus_dir}/logs/unmet-dependency.log"; then
                echo -e "\\nSuccessfully installed ${dependency} after adding the repositories for ${version} \\n" &>> "${eus_dir}/logs/unmet-dependency.log"
                sed -i "s/Depends: ${dependency_no_version}/Depends (completed): ${dependency_no_version}/g" "${log_file}" 2>> "${eus_dir}/logs/unmet-dependency-sed.log"
                rm --force "/etc/apt/sources.list.d/glennr-install-script-unmet.${source_file_format}" &> /dev/null
                break
              fi
            done <<< "${list_of_distro_versions}"
            cleanup_codename_mismatch_repos
            if [[ -e "/etc/apt/sources.list.d/glennr-install-script-unmet.${source_file_format}" ]]; then rm --force "/etc/apt/sources.list.d/glennr-install-script-unmet.${source_file_format}" &> /dev/null; fi
          fi
        fi
      done < <(grep "Depends:" "${log_file}" | sed 's/.*Depends: //' | sed -e 's/ but it.*//' -e 's/).*//' | sort | uniq)
      while read -r breaking_package; do
        echo -e "${GRAY_R}#${RESET} Attempting to prevent ${breaking_package} from screwing over apt..."
        if echo "${breaking_package} hold" | "$(which dpkg)" --set-selections &>> "${eus_dir}/logs/unmet-dependency-break.log"; then
          echo -e "${GREEN}#${RESET} Successfully prevented ${breaking_package} from screwing over apt! \\n"
          sed -i "s/Breaks: ${breaking_package}/Breaks (completed): ${breaking_package}/g" "${log_file}" 2>> "${eus_dir}/logs/unmet-dependency-break-sed.log"
        else
          echo -e "${RED}#${RESET} Failed to prevent ${breaking_package} from screwing over apt...\\n"
        fi
      done < <(grep -is "Breaks:" "${log_file}" | sed -E 's/^(.*) : Breaks: ([^ ]+).*/\1\n\2/' | sed 's/^[ \t]*//' | sort | uniq)
    done < <(grep -slE '^E: Unable to correct problems, you have held broken packages.|^The following packages have unmet dependencies' /tmp/EUS/apt/*.log "${eus_dir}"/logs/*.log | sort -u 2>> /dev/null)
  fi
}

check_dpkg_interrupted() {
  if "$(which dpkg)" --audit 2> /dev/null | grep -iq "The following packages" 2> /dev/null || [[ "${force_dpkg_configure}" == 'true' ]] || [[ -e "/var/lib/dpkg/info/*.status" ]] || tail -n5 "${eus_dir}/logs/"* | grep -iq "you must manually run 'sudo dpkg --configure -a' to correct the problem\\|you must manually run 'dpkg --configure -a' to correct the problem"; then
    echo -e "\\n------- $(date +%F-%T.%6N) -------\\n" &>> "${eus_dir}/logs/dpkg-interrupted.log"
    echo -e "${GRAY_R}#${RESET} Looks like dpkg was interrupted... running \"dpkg --configure -a\"..." | tee -a "${eus_dir}/logs/dpkg-interrupted.log"
    if DEBIAN_FRONTEND=noninteractive "$(which dpkg)" --configure -a &>> "${eus_dir}/logs/dpkg-interrupted.log"; then
      echo -e "${GREEN}#${RESET} Successfully ran \"dpkg --configure -a\"! \\n"
      unset failed_attempt_recover_broken_packages
    else
      echo -e "${RED}#${RESET} Failed to run \"dpkg --configure -a\"...\\n"
      if [[ "${failed_attempt_recover_broken_packages}" == 'true' ]]; then dpkg_interrupted_attempt_recover_broken_check="true"; attempt_recover_broken_packages; unset failed_attempt_recover_broken_packages; unset dpkg_interrupted_attempt_recover_broken_check; fi
    fi
    while read -r log_file; do
      sed -i 's/--configure -a/--configure -a (completed)/g' "${log_file}" &> /dev/null
    done < <(find "${eus_dir}/logs/" -maxdepth 1 -type f -exec grep -Eil "you must manually run 'sudo dpkg --configure -a' to correct the problem|you must manually run 'dpkg --configure -a' to correct the problem" {} \;)
    unset force_dpkg_configure
  fi
}

check_dpkg_lock() {
  local lock_files=( "/var/lib/dpkg/lock" "/var/lib/apt/lists/lock" "/var/cache/apt/archives/lock" )
  local lock_owner
  for lock_file in "${lock_files[@]}"; do
    if command -v lsof &>/dev/null; then
      lock_owner="$(lsof -F p "${lock_file}" 2>/dev/null | grep -oP '(?<=^p).*')"
    elif command -v fuser &>/dev/null; then
      lock_owner="$(fuser "${lock_file}" 2>/dev/null)"
    fi
    if [[ -n "${lock_owner}" ]]; then
      IFS=$'\n' read -rd '' -a lock_owner_array <<< "$lock_owner"
      if [[ "${#lock_owner_array[@]}" -eq "2" ]]; then
        lock_owner_message="${lock_owner_array[0]} and ${lock_owner_array[1]}"
      else
        lock_owner_message="${lock_owner_array[0]}"
        for ((i = 1; i < "${#lock_owner_array[@]}" - 1; i++)); do lock_owner_message+=", ${lock_owner_array[i]}"; done
        if [[ "${#lock_owner_array[@]}" -gt "1" ]]; then lock_owner_message+=" and ${lock_owner_array[-1]}"; fi
      fi
      echo -e "${GRAY_R}#${RESET} $(echo "${lock_file}" | cut -d'/' -f4) is currently locked by process ${lock_owner_message}... We'll give it 2 minutes to finish."
      echo -e "$(date +%F-%T.%6N) | $(echo "${lock_file}" | cut -d'/' -f4) is currently locked by process ${lock_owner_message}... We'll give it 2 minutes to finish." &>> "${eus_dir}/logs/dpkg-lock.log"
      local timeout="120"
      local start_time
      start_time="$(date +%s)"
      while true; do
        kill -0 "${lock_owner_array[@]}" &>/dev/null
        local kill_result="$?"
        if [[ "$kill_result" -eq "0" ]]; then
          local current_time
          current_time="$(date +%s)"
          local elapsed_time="$((current_time - start_time))"
          if [[ "${elapsed_time}" -ge "${timeout}" ]]; then
            process_killed="true"
            echo -e "$(date +%F-%T.%6N) | Timeout reached. Killing process ${lock_owner_message} forcefully." &>> "${eus_dir}/logs/dpkg-lock.log"
            echo -e "${YELLOW}#${RESET} Timeout reached. Killing process ${lock_owner_message} forcefully. \\n"
            kill -9 "${lock_owner_array[@]}" &>> "${eus_dir}/logs/dpkg-lock.log"
            rm -f "${lock_file}" &>> "${eus_dir}/logs/dpkg-lock.log"
            break
          else
            sleep 1
          fi
        else
          echo -e "${GREEN}#${RESET} $(echo "${lock_file}" | cut -d'/' -f4) is no longer locked! \\n"
          echo -e "$(date +%F-%T.%6N) | $(echo "${lock_file}" | cut -d'/' -f4) is no longer locked!" &>> "${eus_dir}/logs/dpkg-lock.log"
          break
        fi
      done
      if [[ "${process_killed}" == 'true' ]]; then DEBIAN_FRONTEND=noninteractive "$(which dpkg)" --configure -a 2>/dev/null; fi
      check_dpkg_lock
      broken_packages_check
      return
    fi
  done
  check_dpkg_interrupted
}

network_install_broken_install_check() {
  # Check if we should handle broken UniFi installation process if we found old database files.
  if [[ -d "/usr/lib/unifi/logs/" ]]; then unifi_logs_location="$(readlink -f /usr/lib/unifi/logs)"; else unifi_logs_location="/var/log/unifi"; fi
  if [[ -d "${unifi_logs_location}" ]]; then
    if [[ "$(command -v zgrep)" ]]; then grep_command="zgrep"; else grep_command="grep"; fi
    if [[ "$(du -b "${unifi_logs_location}/mongod.log" 2> /dev/null | awk '{print$1}')" -gt "5368709120 " ]]; then grep_matches="-m 10"; fi
    while read -r found_mongodb_version; do
      found_mongodb_version_fd="$(echo "${found_mongodb_version}" | cut -d'.' -f1)"
      found_mongodb_version_sd="$(echo "${found_mongodb_version}" | cut -d'.' -f2)"
      found_mongodb_version_td="$(echo "${found_mongodb_version}" | cut -d'.' -f3)"
      while read -r file; do
        if ! "${grep_command}" -A100 -aE "${found_mongodb_version_fd}\.${found_mongodb_version_sd}\.${found_mongodb_version_td}" "${file}" | sed -n "/${found_mongodb_version_fd}\.${found_mongodb_version_sd}\.${found_mongodb_version_td}/,/SERVER RESTARTED/p" | sed -e "1s/^.*${found_mongodb_version_fd}\.${found_mongodb_version_sd}\.${found_mongodb_version_td} //; /^SERVER RESTARTED/d" | grep -sqiaE "This version of MongoDB is too recent to start up on the existing data files|This may be due to an unsupported upgrade or downgrade.|UPGRADE PROBLEM|Cannot start server with an unknown storage engine|unsupported WiredTiger file version|DBException in initAndListen, terminating"; then
          last_known_good_mongodb_version="${found_mongodb_version}"
          echo -e "$(date +%F-%T.%6N) | Last known good MongoDB version is \"${last_known_good_mongodb_version}\" found in \"${file}\"!" &>> "${eus_dir}/logs/mongodb-unsupported-version-change-locate.log"
          continue
        else
          if [[ -n "${last_known_good_mongodb_version}" && "${last_known_good_mongodb_version}" == "${found_mongodb_version}" ]]; then unset last_known_good_mongodb_version; fi
          echo -e "$(date +%F-%T.%6N) | \"${found_mongodb_version}\" is marked as bad in \"${file}\"..." &>> "${eus_dir}/logs/mongodb-unsupported-version-change-locate.log"; wait; break
        fi
      done < <(find "${unifi_logs_location}/" -maxdepth 1 -type f -print0 | while IFS= read -r -d '' file; do if "${grep_command}" ${grep_matches:+${grep_matches}} -Eial "db version v${found_mongodb_version}|buildInfo\":{\"version\":\"${found_mongodb_version}\"" "$file" > /dev/null 2>&1; then if [[ -e "$file" ]]; then stat --format '%Y %n' "$file"; fi; fi; done | sort -nr | awk '{print $2}')
      if [[ -n "${last_known_good_mongodb_version}" ]]; then wait; break; fi
    done < <(find "${unifi_logs_location}/" -maxdepth 1 -type f -print0 | xargs -0 "${grep_command}" ${grep_matches:+${grep_matches}} -sEioa "db version v[0-9].[0-9].[0-9]{1,2}|buildInfo\":{\"version\":\"[0-9].[0-9].[0-9]{1,2}\"" | sed -e 's/^.*://' -e 's/db version v//g' -e 's/buildInfo":{"version":"//g' -e 's/"//g' | sort -rV | uniq)
    if [[ -z "${last_known_good_mongodb_version}" ]] && "$(which dpkg)" -l | grep -E "(mongodb-server|mongodb-org-server|mongod-armv8|mongod-amd64)[[:space:]]" | grep -viq "^ii\\|^hi"; then
      get_unifi_api_ports
      get_unifi_application_status
      if [[ "${application_up}" != 'true' ]]; then
        if [[ "$(find "${unifi_logs_location}/" -maxdepth 1 -type f -print0 | wc -l)" == "0" ]] || [[ "$(find "${unifi_logs_location}/" -type f -name "mongod.log*" | wc -l)" == "0" ]]; then 
          last_known_installed_mongodb_version="$("$(which dpkg)" -l | grep -E "(mongodb-server|mongodb-org-server|mongod-armv8|mongod-amd64)[[:space:]]" | grep -vi "^ii\\|^hi" | awk '{print $3}' | sed -e 's/.*://' -e 's/-.*//g' -e 's/+.*//g')"
        fi
      fi
    fi
    if [[ -n "${last_known_good_mongodb_version}" ]]; then
      echo -e "$(date +%F-%T.%6N) | Using last known good MongoDB version \"${last_known_good_mongodb_version}\" from the MongoDB logs!" &>> "${eus_dir}/logs/mongodb-unsupported-version-change-locate.log"
      previous_mongodb_version="${last_known_good_mongodb_version//./}"
      previous_mongodb_version_with_dot="${last_known_good_mongodb_version}"
    else
      last_known_good_mongodb_version_eus_db="$(jq -r '.scripts["UniFi Network Easy Update Script"].tasks | to_entries[] | select(.key | startswith("mongodb-upgrade")) | .value[] | select(.status == "success") | .to' "${eus_dir}/db/db.json" 2> /dev/null | sort -V | tail -n1)"
      if [[ -z "${last_known_good_mongodb_version_eus_db}" ]]; then
        if [[ -e "${eus_dir}/logs/mongodb-unsupported-version-change-locate.log" ]]; then
          mapfile -t eus_marked_bad_versions < <("${grep_command}" -E '"[0-9]+\.[0-9]+\.[0-9]+" .* bad' "${eus_dir}/logs/mongodb-unsupported-version-change-locate.log" | sed -E 's/.*"([0-9]+\.[0-9]+\.[0-9]+)".*/\1/' | sort -rV | uniq)
          mapfile -t dpkg_log_mongodb_server_versions < <(find /var/log/ -maxdepth 1 -type f -name "dpkg*" -print0 | xargs -0 "${grep_command}" ${grep_matches:+${grep_matches}} -sEia "upgrade mongodb-org-server|upgrade mongodb-server|upgrade mongod-armv8|upgrade mongod-amd64" | awk '{for(i=1;i<NF;i++) if ($i == "upgrade") {print $(i+2); break}}' | cut -d':' -f2 | sed -E 's/-.*//' | sort -rV | uniq)
          for version in "${dpkg_log_mongodb_server_versions[@]}"; do
            if [[ ! " ${eus_marked_bad_versions[*]} " =~ ${version} ]]; then
              dpkg_log_mongodb_server="${version}"
              break
            fi
          done
        fi
      fi
      if [[ -n "${last_known_good_mongodb_version_eus_db}" ]]; then
        echo -e "$(date +%F-%T.%6N) | Using last known good MongoDB version \"${last_known_good_mongodb_version_eus_db}\" from the EUS database!" &>> "${eus_dir}/logs/mongodb-unsupported-version-change-locate.log"
        previous_mongodb_version="${previous_mongodb_version_with_dot//./}"
        previous_mongodb_version_with_dot="${last_known_good_mongodb_version_eus_db}"
      elif [[ -n "${dpkg_log_mongodb_server}" ]]; then
        echo -e "$(date +%F-%T.%6N) | Using last known good MongoDB version \"${dpkg_log_mongodb_server}\" from the dpkg logs!" &>> "${eus_dir}/logs/mongodb-unsupported-version-change-locate.log"
        previous_mongodb_version="${dpkg_log_mongodb_server//./}"
        previous_mongodb_version_with_dot="${dpkg_log_mongodb_server}"
      elif [[ -n "${last_known_installed_mongodb_version}" ]]; then
        echo -e "$(date +%F-%T.%6N) | Using MongoDB version \"${last_known_installed_mongodb_version}\" as that was already installed!" &>> "${eus_dir}/logs/mongodb-unsupported-version-change-locate.log"
        previous_mongodb_version="${last_known_installed_mongodb_version//./}"
        previous_mongodb_version_with_dot="${last_known_installed_mongodb_version}"
      else
        if [[ -e "${eus_dir}/logs/mongodb-unsupported-version-change-locate.log" ]]; then
          dynamic_bad_mongodb_versions=()
          while IFS= read -r line; do
            dynamic_bad_mongodb_versions+=("${line}")
          done < <(sed -n 's/.*"\([^"]*\)" is marked as bad.*/\1/p' "${eus_dir}/logs/mongodb-unsupported-version-change-locate.log" | sort -r | uniq)
          while read -r eus_db_mongodb_version; do
            if [[ ! "${dynamic_bad_mongodb_versions[*]}" =~ ${eus_db_mongodb_version} ]]; then
              previous_mongodb_version="${eus_db_mongodb_version//./}"
              previous_mongodb_version_with_dot="${eus_db_mongodb_version}"
              echo -e "$(date +%F-%T.%6N) | Last known good MongoDB version is \"${eus_db_mongodb_version}\" found in the EUS database!" &>> "${eus_dir}/logs/mongodb-unsupported-version-change-locate.log"
              break
            fi
          done < <(jq -r '.scripts."UniFi Network Easy Update Script".tasks | to_entries[] | select(.key | startswith("mongodb-upgrade")) | .value[].from' "${eus_dir}/db/db.json" 2> /dev/null | sort -r | uniq)
        fi
      fi
    fi
    if "$(which dpkg)" -l | grep -E "(mongodb-server|mongodb-org-server|mongod-armv8|mongod-amd64)[[:space:]]" | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui" && [[ -n "${previous_mongodb_version}" ]]; then
      recovery_check_mongodb_server_version="$("$(which dpkg)" -l | grep -E "(mongodb-server|mongodb-org-server|mongod-armv8|mongod-amd64)[[:space:]]" | grep "^ii\\|^hi\\|^ri\\|^pi\\|^ui\\|^iU" | awk '{print $3}' | sed -e 's/.*://' -e 's/-.*//' -e 's/+.*//' -e 's/\.//g')"
      if [[ "${recovery_check_mongodb_server_version::2}" != "${previous_mongodb_version::2}" ]]; then recovery_required="true"; fi
    fi
  fi
}

minimum_required_mongodb_version_check() {
  if [[ "$(command -v jq)" ]]; then minimum_required_api_status="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/unifi-package-versions?status" 2> /dev/null | jq -r '.availability' 2> /dev/null)"; else minimum_required_api_status="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/unifi-package-versions?status" 2> /dev/null | grep -oP '(?<="availability":")[^"]+')"; fi
  if [[ "${minimum_required_api_status}" == "OK" ]]; then
    if [[ -n "$(command -v jq)" ]]; then
      minimum_required_mongodb_version="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/unifi-package-versions?unifi-version=${unifi_version}" | jq -r '."minimum_required_mongodb_version"')"
    else
      minimum_required_mongodb_version="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/unifi-package-versions?unifi-version=${unifi_version}" | sed -n 's/.*"minimum_required_mongodb_version":\s*"\([^"]*\)".*/\1/p')"
    fi
  else
    first_digit_unifi_version="$(echo "${unifi_version}" | cut -d'.' -f1)"
    second_digit_unifi_version="$(echo "${unifi_version}" | cut -d'.' -f2)"
    if [[ "${first_digit_unifi_version}" -gt '7' ]] || [[ "${first_digit_unifi_version}" == '7' && "${second_digit_unifi_version}" -ge '5' ]]; then minimum_required_mongodb_version="36"; fi
    if [[ "${first_digit_unifi_version}" == '7' && "${second_digit_unifi_version}" == '4' ]]; then minimum_required_mongodb_version="26"; fi
  fi
}

network_install_broken_install_recovery() {
  unifi_package="$("$(which dpkg)" -l | grep "unifi " | awk '{print $1}' | tr '[:upper:]' '[:lower:]')"
  if ! [[ "${unifi_package}" =~ (hi|ii) ]]; then if [[ -e "/usr/lib/unifi/data/db/version" ]]; then recovery_required="true"; elif [[ -e "/var/lib/unifi/db/version" ]]; then recovery_required="true"; fi; fi
  if [[ -e "/usr/lib/unifi/data/db/version" ]]; then unifi_db_version_path="/usr/lib/unifi/data/db/version"; elif [[ -e "/var/lib/unifi/db/version" ]]; then unifi_db_version_path="/var/lib/unifi/db/version"; fi
  if [[ -n "${unifi_package}" ]] || [[ "${recovery_required}" == 'true' ]]; then
    if ! [[ "${unifi_package}" =~ (hi|ii) ]] || [[ "${recovery_required}" == 'true' ]]; then
      check_mongodb_installed
      broken_unifi_install="true"
      header_red
      echo -e "${RED}#${RESET} You have a broken UniFi Network Application installation...\\n"
      if [[ -e "${unifi_db_version_path}" ]]; then broken_unifi_install_version1="$(head -n1 "${unifi_db_version_path}")"; fi
      broken_unifi_install_version2="$(grep -saEio "UniFi [0-9].[0-9].[0-9]{1,3}" "${unifi_logs_location}/server.log"* | sed 's/UniFi //g' | sort -V | tail -n1 | sed 's/^.*://')"
      broken_unifi_install_version3="$("$(which dpkg)" -l unifi | tail -n1 | awk '{print $3}' | cut -d"-" -f1)"
      broken_unifi_install_versions=("${broken_unifi_install_version1}" "${broken_unifi_install_version2}" "${broken_unifi_install_version3}")
      while read -r unifi_version; do
        unset minimum_required_mongodb_version
        minimum_required_mongodb_version_check
        if [[ "${mongodb_version_installed_no_dots::2}" -lt "${minimum_required_mongodb_version}" ]]; then
          continue
        else
          if [[ "$(command -v jq)" ]]; then supported_upgrade_api_status="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/supported-upgrade?status" 2> /dev/null | jq -r '.availability' 2> /dev/null)"; else supported_upgrade_api_status="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/supported-upgrade?status" 2> /dev/null | grep -oP '(?<="availability":")[^"]+')"; fi
          if [[ "${supported_upgrade_api_status}" == "OK" && -n "${broken_unifi_install_version1}" ]]; then
            if [[ "$(command -v jq)" ]]; then net_update_supported="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/supported-upgrade?app=network&current_version=${broken_unifi_install_version1}&new_version=${unifi_version}" 2> /dev/null | jq -r '.supported' 2> /dev/null | sed '/null/d' 2> "${eus_dir}/logs/glennr-api.log")"; else net_update_supported="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/supported-upgrade?app=network&current_version=${broken_unifi_install_version1}&new_version=${unifi_version}" 2> /dev/null | grep -oP '(?<="supported":")[^"]+')"; fi
            if [[ "${net_update_supported}" == 'true' ]]; then
              broken_unifi_install_version="${unifi_version}"
            elif [[ "${net_update_supported}" == 'false' ]]; then
              if [[ "$(command -v jq)" ]]; then unifi_next_possible_version="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/supported-upgrade?app=network&current_version=${broken_unifi_install_version1}&new_version=${unifi_version}" 2> /dev/null | jq -r '.next_possible_version' 2> /dev/null | sed '/null/d' 2> "${eus_dir}/logs/glennr-api.log")"; else unifi_next_possible_version="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/supported-upgrade?app=network&current_version=${broken_unifi_install_version1}&new_version=${unifi_version}" 2> /dev/null | grep -oP '(?<="next_possible_version":")[^"]+')"; fi
              if [[ -n "${unifi_next_possible_version}" ]]; then
                broken_unifi_install_version="${unifi_next_possible_version}"
              else
                broken_unifi_install_version="${unifi_version}"
              fi
            fi
          else
            broken_unifi_install_version="${unifi_version}"
          fi
        fi
      done < <(printf "%s\n" "${broken_unifi_install_versions[@]}" | sort -V | awk '!seen[$0]++')
      if [[ -z "${broken_unifi_install_version}" ]]; then broken_unifi_install_version="$(printf "%s\n" "${broken_unifi_install_versions[@]}" | sort -V | tail -n1)"; fi
      if [[ -n "${broken_unifi_install_version}" ]]; then
        broken_unifi_install_version_first_digit="$(echo "${broken_unifi_install_version}" | cut -d"." -f1)"
        broken_unifi_install_version_second_digit="$(echo "${broken_unifi_install_version}" | cut -d"." -f2)"
        broken_unifi_install_version_third_digit="$(echo "${broken_unifi_install_version}" | cut -d"." -f3)"
        if [[ -n "$(command -v jq)" && "${unifi_core_system}" != 'true' ]]; then
          unifi_download_link="$(curl "${curl_argument[@]}" "https://fw-update.ui.com/api/firmware-latest?filter=eq~~version_major~~${broken_unifi_install_version_first_digit}&filter=eq~~version_minor~~${broken_unifi_install_version_second_digit}&filter=eq~~version_patch~~${broken_unifi_install_version_third_digit}&filter=eq~~platform~~debian" 2> /dev/null | jq -r "._embedded.firmware[]._links.data.href" 2> /dev/null | sed '/null/d' 2> "${eus_dir}/logs/locate-download.log")"
          unifi_br_sha256sum="$(curl "${curl_argument[@]}" "https://fw-update.ui.com/api/firmware-latest?filter=eq~~version_major~~${broken_unifi_install_version_first_digit}&filter=eq~~version_minor~~${broken_unifi_install_version_second_digit}&filter=eq~~version_patch~~${broken_unifi_install_version_third_digit}&filter=eq~~platform~~debian" 2> /dev/null | jq -r "._embedded.firmware[0].sha256_checksum" 2> /dev/null | sed '/null/d' 2> "${eus_dir}/logs/locate-download.log")"
        fi
        if [[ "$(curl "${curl_argument[@]}" https://api.glennr.nl/api/application-release?status 2> /dev/null | jq -r '.[]' 2> /dev/null)" == "OK" ]]; then
          if [[ -n "$(command -v jq)" ]]; then
            unifi_gr_api_download_link="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/application-release?app=network&version=${broken_unifi_install_version}${unifi_core_glennr_api}" | jq -r '.download_link' | sed '/null/d' 2> "${eus_dir}/logs/locate-download.log")"
            unifi_gr_download_link="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/application-release?app=network&version=${broken_unifi_install_version}&server=archive${unifi_core_glennr_api}" | jq -r '.download_link' | sed '/null/d' 2> "${eus_dir}/logs/locate-download.log")"
          else
            unifi_gr_api_download_link="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/application-release?app=network&version=${broken_unifi_install_version}${unifi_core_glennr_api}" | grep -oP '(?<="download_link":")[^"]*' | sed '/null/d' 2> "${eus_dir}/logs/locate-download.log")"
            unifi_gr_download_link="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/application-release?app=network&version=${broken_unifi_install_version}&server=archive${unifi_core_glennr_api}" | grep -oP '(?<="download_link":")[^"]*' | sed '/null/d' 2> "${eus_dir}/logs/locate-download.log")"
          fi
          unifi_br_sha256sum="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/application-release?app=network&version=${broken_unifi_install_version}${unifi_core_glennr_api}" | jq -r '.sha256sum' | sed '/null/d' 2> "${eus_dir}/logs/locate-download.log")"
        fi
        if [[ -n "${unifi_download_link}" || -n "${unifi_gr_api_download_link}" || -n "${unifi_gr_download_link}" ]]; then
          echo -e "${GRAY_R}#${RESET} Checking if we need to change the version that the script will install..."
          unifi_deb_dl_urls=("${unifi_download_link}" "${unifi_gr_api_download_link}" "${unifi_gr_download_link}")
          for unifi_download_link in "${unifi_deb_dl_urls[@]}"; do
            eus_tmp_deb_name="${unifi_deb_file_name}_${broken_unifi_install_version}"
            eus_tmp_deb_var="unifi_temp"
            eus_tmp_directory_check
            echo -e "$(date +%F-%T.%6N) | Downloading ${unifi_download_link} to ${unifi_temp}" &>> "${eus_dir}/logs/unifi-broken-install-download.log"
            if curl "${nos_curl_argument[@]}" --output "$unifi_temp" "${unifi_download_link}" &>> "${eus_dir}/logs/unifi-broken-install-download.log"; then
              if command -v sha256sum &> /dev/null; then
                if [[ "$(sha256sum "$unifi_temp" | awk '{print $1}')" == "${unifi_br_sha256sum}" ]]; then
                  unifi_network_application_downloaded="true"
                  echo -e "${GREEN}#${RESET} The script will install UniFi Network Application version ${broken_unifi_install_version}! \\n"; break
                else
                  echo -e "$(date +%F-%T.%6N) | The file downloaded via ${unifi_download_link} did not have sha256sum \"${unifi_br_sha256sum}\"..." &>> "${eus_dir}/logs/unifi-download.log"; continue
                fi
              elif command -v dpkg-deb &> /dev/null; then
                if dpkg-deb --info "${unifi_temp}" &> /dev/null; then
                  unifi_network_application_downloaded="true"
                  echo -e "${GREEN}#${RESET} The script will install UniFi Network Application version ${broken_unifi_install_version}! \\n"; break
                else
                  echo -e "$(date +%F-%T.%6N) | The file downloaded via ${unifi_download_link} was not a debian file format..." &>> "${eus_dir}/logs/unifi-download.log"; continue
                fi
              else
                unifi_network_application_downloaded="true"
                echo -e "${GREEN}#${RESET} The script will install UniFi Network Application version ${broken_unifi_install_version}! \\n"; break
              fi
            else
              continue
            fi
          done
          if [[ "${unifi_network_application_downloaded}" != "true" ]]; then echo -e "${RED}#${RESET} Failed to change the version to UniFi Network Application ${broken_unifi_install_version}...\\n"; fi
        fi
        sleep 3
      fi
      if [[ -z "$("$(which dpkg)" -l | grep "unifi " | awk '{print $1}' | tr '[:upper:]' '[:lower:]' | cut -c 3-)" ]] && [[ "${unifi_network_application_downloaded}" == 'true' ]]; then
        if [[ "${limited_functionality}" != 'true' ]]; then systemctl disable -q unifi &>> "${eus_dir}/logs/broken_unifi.log"; broken_unifi_service_disabled="true"; fi
        echo -e "${WHITE}#${RESET} Performing a required reinstall of the unifi package..."
        check_dpkg_lock
        echo "unifi unifi/has_backup boolean true" 2> /dev/null | debconf-set-selections
        if DEBIAN_FRONTEND=noninteractive "$(which dpkg)" --force-confold --force-all --no-triggers -i "${unifi_temp}" &>> "${eus_dir}/logs/broken_unifi.log"; then
          echo -e "${GREEN}#${RESET} Successfully reinstalled the unifi package! \\n"
        else
          echo -e "${RED}#${RESET} Failed to reinstall the unifi package...\\n"
        fi
        if [[ "${broken_unifi_service_disabled}" == 'true' ]]; then systemctl enable -q unifi &>> "${eus_dir}/logs/broken_unifi.log"; fi
      fi
      echo -e "${WHITE}#${RESET} Removing the broken UniFi Network Application installation..."
      check_dpkg_lock
      if "$(which dpkg)" --remove --force-remove-reinstreq unifi &>> "${eus_dir}/logs/broken_unifi.log"; then
        echo -e "${GREEN}#${RESET} Successfully removed the broken UniFi Network Application installation! \\n"
      else
        echo -e "${RED}#${RESET} Failed to remove the broken UniFi Network Application installation...\\n"
      fi
      if [[ -n "$(command -v jq)" ]]; then eus_database_update_broken_install; else eus_database_update_broken_install_check="true"; fi
    fi
  fi
}

get_apt_options() {
  if [[ "${remove_apt_options}" == "true" ]]; then get_apt_option_arguments="false"; unset apt_options; fi
  if [[ "${get_apt_option_arguments}" != "false" ]]; then
    if [[ "$("$(which dpkg)" -l apt | grep ^"ii" | awk '{print $2,$3}' | awk '{print $2}' | cut -d'.' -f1)" -gt "1" ]] || [[ "$("$(which dpkg)" -l apt | grep ^"ii" | awk '{print $2,$3}' | awk '{print $2}' | cut -d'.' -f1)" == "1" && "$("$(which dpkg)" -l apt | grep ^"ii" | awk '{print $2,$3}' | awk '{print $2}' | cut -d'.' -f2)" -ge "1" ]]; then if ! grep -q "allow-change-held-packages" /tmp/EUS/apt_option &> /dev/null; then echo "--allow-change-held-packages" &>> /tmp/EUS/apt_option; fi; fi
    if [[ "${add_apt_option_no_install_recommends}" == "true" ]]; then if ! grep -q "--no-install-recommends" /tmp/EUS/apt_option &> /dev/null; then echo "--no-install-recommends" &>> /tmp/EUS/apt_option; fi; fi
    if [[ -f /tmp/EUS/apt_option && -s /tmp/EUS/apt_option ]]; then IFS=" " read -r -a apt_options <<< "$(tr '\r\n' ' ' < /tmp/EUS/apt_option)"; rm --force /tmp/EUS/apt_option &> /dev/null; fi
  fi
  if [[ "$("$(which dpkg)" -l apt | grep ^"ii" | awk '{print $2,$3}' | awk '{print $2}' | cut -d'.' -f1)" -gt "1" ]] || [[ "$("$(which dpkg)" -l apt | grep ^"ii" | awk '{print $2,$3}' | awk '{print $2}' | cut -d'.' -f1)" == "1" && "$("$(which dpkg)" -l apt | grep ^"ii" | awk '{print $2,$3}' | awk '{print $2}' | cut -d'.' -f2)" -ge "2" ]]; then if ! grep -q "allow-downgrades" /tmp/EUS/apt_downgrade_option &> /dev/null; then echo "--allow-downgrades" &>> /tmp/EUS/apt_downgrade_option; fi; fi
  if [[ -f /tmp/EUS/apt_downgrade_option && -s /tmp/EUS/apt_downgrade_option ]]; then IFS=" " read -r -a apt_downgrade_option <<< "$(tr '\r\n' ' ' < /tmp/EUS/apt_downgrade_option)"; rm --force /tmp/EUS/apt_downgrade_option &> /dev/null; fi
  unset get_apt_option_arguments
  unset remove_apt_options
  unset add_apt_option_no_install_recommends
}
get_apt_options

network_install_dummy_packages_check() {
  # Remove dummy unifi-beta, unifi-rapid and unifi-alpha packages
  unifi_dummy_packages=("unifi-beta" "unifi-rapid" "unifi-alpha")
  for unifi_dummy_package in "${unifi_dummy_packages[@]}"; do
    if "$(which dpkg)" -l | awk '{print $2}' | grep -wq "${unifi_dummy_package}"; then
      if [[ "${unifi_dummy_header_message}" != 'true' ]]; then header; unifi_dummy_header_message="true"; fi
      echo -e "${GRAY_R}#${RESET} Removing dummy package ${unifi_dummy_package}..."
      if DEBIAN_FRONTEND='noninteractive' "$(which dpkg)" --remove --force-remove-reinstreq "${unifi_dummy_package}" &>> "${eus_dir}/logs/unifi-legacy-dummy-packages.log"; then
        echo -e "${GREEN}#${RESET} Successfully removed dummy package ${unifi_dummy_package}! \\n"
      else
        echo -e "${RED}#${RESET} Failed to remove dummy package ${unifi_dummy_package}... \\n"
      fi
    fi
  done
}

is_systemd_unit_present() {
  local unit="$1"
  [[ "$(systemctl show -p LoadState --value "$unit" 2>/dev/null)" == "loaded" ]]
}

already_installed_check() {
  local product_name="$1"         # e.g., "UniFi Network Application" or "UniFi OS Server"
  local check_command="$2"        # command to detect installation
  local grep_pattern="$3"         # optional grep pattern for dpkg-based check
  if eval "${check_command}" >/dev/null 2>&1; then
    if [[ -n "${grep_pattern}" ]] && ! eval "${check_command}" | grep -E "${grep_pattern}" | grep -qE "^ii|^hi"; then return; fi
    header
    echo -e "${GRAY_R}#${RESET} ${product_name} is already installed on your system!${RESET}"
    echo -e "${GRAY_R}#${RESET} You can use my Easy Update Script to update your ${product_name}.${RESET}\n\n"
    read -rp $'\033[39m#\033[0m Would you like to download and run my Easy Update Script? (Y/n) ' yes_no
    case "$yes_no" in
        [Nn]*) check_apt_listbugs; exit 0;;
        *)
          check_apt_listbugs
          rm --force "${script_location}" 2>/dev/null
          curl "${curl_argument[@]}" --remote-name https://get.glennr.nl/unifi/update/unifi-update.sh && bash unifi-update.sh
          exit 0;;
    esac
  fi
}

# Run dpkg lock check
check_dpkg_lock

armhf_recommendation() {
  print_architecture=$("$(which dpkg)" --print-architecture)
  if [[ "${print_architecture}" == 'armhf' ]] && uname -a | grep -ioq aarch64; then
    header_red
    echo -e "${GRAY_R}#${RESET} You appear to have a 64-bit capable device, please use a 64-bit based OS and re-run the script.\\n"
    exit 1
  elif [[ "${print_architecture}" == 'armhf' && "${is_cloudkey}" == "false" ]]; then
    header_red
    echo -e "${GRAY_R}#${RESET} Your installation might fail, please consider getting a Cloud Key Gen2 or go with a VPS at OVH/DO/AWS."
    if [[ "${os_codename}" =~ (precise|trusty|utopic|vivid|wily|yakkety|zesty|artful|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing|resolute) ]]; then
      echo -e "${GRAY_R}#${RESET} You could try using Debian Bullseye before going with a UCK G2 ( PLUS ) or VPS"
    fi
    echo -e "\\n${GRAY_R}#${RESET} UniFi Cloud Key Gen2       | https://store.ui.com/products/unifi-cloud-key-gen2"
    echo -e "${GRAY_R}#${RESET} UniFi Cloud Key Gen2 Plus  | https://store.ui.com/products/unifi-cloudkey-gen2-plus\\n\\n"
    sleep 20
  fi
}
armhf_recommendation

old_systemd_version_check() {
  if [[ "${first_digit_unifi}" == '6' && "${second_digit_unifi}" -ge '4' ]] || [[ "${first_digit_unifi}" -ge '7' ]]; then old_systemd_unifi_check_passed="true"; fi
  if [[ "$(dpkg-query --showformat='${version}' --show systemd 2> /dev/null | awk -F '[.-]' '{print $1}')" -lt "231" && "${old_systemd_unifi_check_passed}" == 'true' ]]; then
    old_systemd_version="true"
    if ! [[ -d "/etc/systemd/system/unifi.service.d/" ]]; then eus_directory_location="/etc/systemd/system"; eus_create_directories "unifi.service.d"; fi
    unifi_helpers="$(grep -s "unifi-network-service-helper" /lib/systemd/system/unifi.service | grep "=+" | while read -r helper; do echo "${helper//+/}"; done)"
    if echo -e "[Service]\nPermissionsStartOnly=true\nExecStartPre=/usr/sbin/unifi-network-service-helper create-dirs\n${unifi_helpers}" &> /etc/systemd/system/unifi.service.d/override.conf; then
      daemon_reexec
      systemctl daemon-reload &>> "${eus_dir}/logs/old-systemd.log"
      systemctl reset-failed unifi.service &>> "${eus_dir}/logs/old-systemd.log"
    fi
    if [[ "${limited_functionality}" == 'true' ]]; then
      if service unifi restart &>> "${eus_dir}/logs/old-systemd.log"; then old_systemd_version_check_unifi_restart="true"; fi
    else
      if systemctl restart unifi &>> "${eus_dir}/logs/old-systemd.log"; then old_systemd_version_check_unifi_restart="true"; fi
    fi
  elif [[ "$(dpkg-query --showformat='${version}' --show systemd 2> /dev/null | awk -F '[.-]' '{print $1}')" -lt "238" && "$(dpkg-query --showformat='${version}' --show systemd 2> /dev/null | awk -F '[.-]' '{print $1}')" -gt "231" && "${old_systemd_unifi_check_passed}" == 'true' ]]; then
    old_systemd_version="true"
    if ! [[ -d "/etc/systemd/system/unifi.service.d/" ]]; then eus_directory_location="/etc/systemd/system"; eus_create_directories "unifi.service.d"; fi
    if echo -e "[Service]\nPermissionsStartOnly=true\nExecStartPre=/usr/sbin/unifi-network-service-helper create-dirs" &> /etc/systemd/system/unifi.service.d/override.conf; then
      daemon_reexec
      systemctl daemon-reload &>> "${eus_dir}/logs/old-systemd.log"
      systemctl reset-failed unifi.service &>> "${eus_dir}/logs/old-systemd.log"
    fi
    if [[ "${limited_functionality}" == 'true' ]]; then
      if service unifi restart &>> "${eus_dir}/logs/old-systemd.log"; then old_systemd_version_check_unifi_restart="true"; fi
    else
      if systemctl restart unifi &>> "${eus_dir}/logs/old-systemd.log"; then old_systemd_version_check_unifi_restart="true"; fi
    fi
  fi
}

check_service_overrides() {
  if [[ "${limited_functionality}" != 'true' ]]; then
    if [[ -e "/etc/systemd/system/unifi.service" ]] || [[ -e "/etc/systemd/system/unifi.service.d/" ]]; then
      echo -e "${GRAY_R}#${RESET} UniFi Network Application service overrides detected... Removing them..."
      unifi_override_version="$("$(which dpkg)" -l unifi | tail -n1 |  awk '{print $3}' | cut -d'-' -f1)"
      eus_create_directories "unifi-service-overrides"
      if [[ -d "${eus_dir}/unifi-service-overrides/${unifi_override_version}/" ]]; then
        if [[ -e "/etc/systemd/system/unifi.service" ]]; then
          mv "/etc/systemd/system/unifi.service" "${eus_dir}/unifi-service-overrides/${unifi_override_version}/unifi.service" &>> "${eus_dir}/logs/service-override.log"
        fi
        if [[ -e "/etc/systemd/system/unifi.service.d/" ]]; then
          while read -r override_file; do
            override_file_name="$(basename "${override_file}")"
            if mv "${override_file}" "${eus_dir}/unifi-service-overrides/${unifi_override_version}/${override_file_name}" &>> "${eus_dir}/logs/service-override.log"; then moved_service_override_files="true"; fi
          done < <(find /etc/systemd/system/unifi.service.d/ -type f 2> /dev/null)
        fi
      fi
      if [[ "$(dpkg-query --showformat='${version}' --show systemd 2> /dev/null | awk -F '[.-]' '{print $1}')" -ge "230" ]]; then
        if systemctl revert unifi &>> "${eus_dir}/logs/service-override.log"; then
          echo -e "${GREEN}#${RESET} Successfully reverted the UniFi Network Application service overrides! \\n"
          check_service_overrides_reverted="true"
        else
          echo -e "${RED}#${RESET} Failed to revert the UniFi Network Application service overrides...\\n"
        fi
      else
        if [[ "${moved_service_override_files}" == "true" ]]; then
          if [[ -e /etc/systemd/system/unifi.service.d/override.conf ]]; then
            if rm --force /etc/systemd/system/unifi.service.d/override.conf &>> "${eus_dir}/logs/service-override.log"; then
              echo -e "${GREEN}#${RESET} Successfully reverted the UniFi Network Application service overrides! \\n"
              check_service_overrides_reverted="true"
            else
              echo -e "${RED}#${RESET} Failed to revert the UniFi Network Application service overrides...\\n"
            fi
          fi
        else
          echo -e "${GREEN}#${RESET} Successfully reverted the UniFi Network Application service overrides! \\n"
          check_service_overrides_reverted="true"
        fi
      fi
      if [[ "${check_service_overrides_reverted}" == 'true' ]]; then systemctl daemon-reload &>> "${eus_dir}/logs/service-override.log"; fi
      sleep 3
    fi
  fi
}

unifi_autobackup_dir_check() {
  unifi_autobackup_dir="$(grep -s "^autobackup.dir" /usr/lib/unifi/data/system.properties 2> /dev/null | sed 's/autobackup.dir=//g')"
  if [[ -z "${unifi_autobackup_dir}" ]]; then unifi_autobackup_dir="/usr/lib/unifi/data/backup/autobackup"; fi
  if ! [[ -d "${unifi_autobackup_dir}" ]]; then install -d -m 0755 -o unifi -g unifi "${unifi_autobackup_dir}" &>> "${eus_dir}/logs/unifi-autbackup-dir-check.log"; fi
}

system_properties_check() {
  if [[ -e "/usr/lib/unifi/data/system.properties" ]]; then
    # Remove any duplicates.
    if grep -qE 'unifi\.x(m[xs]|ss)=[0-9]*+' "/usr/lib/unifi/data/system.properties"; then
      cp /usr/lib/unifi/data/system.properties "/usr/lib/unifi/data/system.properties-eus-recovery-$(date +%Y%m%d_%H%M_%s)" &>> "${eus_dir}/logs/system-properties-update.log"
      if sed -i -e '0,/^unifi\.xms=/!{s/^unifi\.xms=.*//}' -e '0,/^unifi\.xmx=/!{s/^unifi\.xmx=.*//}' -e '0,/^unifi\.xss=/!{s/^unifi\.xss=.*//}' -e '/^$/d' "/usr/lib/unifi/data/system.properties"; then
        echo "Corrected unifi.xmx, unifi.xms, and unifi.xss patterns in system.properties" &>> "${eus_dir}/logs/system-properties-update.log"
        chown -R unifi:unifi /usr/lib/unifi/data/system.properties
      fi
    fi
    # Remove any invalid entries.
    if grep -qE 'unifi\.x(m[xs]|ss)=[0-9]*[A-Za-z]+' "/usr/lib/unifi/data/system.properties"; then
      cp /usr/lib/unifi/data/system.properties "/usr/lib/unifi/data/system.properties-eus-recovery-$(date +%Y%m%d_%H%M_%s)" &>> "${eus_dir}/logs/system-properties-update.log"
      if sed -i 's/\(unifi\.\(xmx\|xms\|xss\)=\)\([0-9]\+\)[A-Za-z]*/\1\3/' "/usr/lib/unifi/data/system.properties"; then
        echo "Corrected unifi.xmx, unifi.xms, and unifi.xss patterns in system.properties" &>> "${eus_dir}/logs/system-properties-update.log"
        chown -R unifi:unifi /usr/lib/unifi/data/system.properties
      fi
    fi
  fi
}

system_properties_free_memory_check() {
  if [[ "$(awk '/MemAvailable/{printf "%d", $2 / 1024 / 1024}' /proc/meminfo)" -le "1" ]]; then
    if [[ -e "/usr/lib/unifi/data/system.properties" ]]; then
	  current_xms="$(awk -F= '/^unifi.xms/{print $2}' "/usr/lib/unifi/data/system.properties")"
      current_xmx="$(awk -F= '/^unifi.xmx/{print $2}' "/usr/lib/unifi/data/system.properties")"
    fi
    if [[ -z "$current_xms" ]]; then
      echo "unifi.xms=256" >> "/usr/lib/unifi/data/system.properties"
    elif [[ "$current_xms" -lt "256" ]]; then
      sed -i "s/^unifi.xms=.*/unifi.xms=256/" "/usr/lib/unifi/data/system.properties"
    fi
    if [[ -z "$current_xmx" ]]; then
      echo "unifi.xmx=512" >> "/usr/lib/unifi/data/system.properties"
    elif [[ "$current_xmx" -lt "512" ]]; then
      sed -i "s/^unifi.xmx=.*/unifi.xmx=512/" "/usr/lib/unifi/data/system.properties"
    fi
    chown unifi:unifi "/usr/lib/unifi/data/system.properties"
  fi
}

unifi_folder_permission_check() {
  if grep -isoq "users=" /etc/systemd/system/unifi.service.d/override.conf; then unifi_systemd_file="/etc/systemd/system/unifi.service.d/override.conf"; else unifi_systemd_file="/lib/systemd/system/unifi.service"; fi
  network_application_user="$(grep -s '^User=' "${unifi_systemd_file}" | awk -F= '{print $2}')"
  if [[ -z "${network_application_user}" ]]; then network_application_user="unifi"; fi
  unifi_folder_permission_check_detected_files=()
  while read -r unifi_directory; do
    while read -r unifi_file_or_directory; do
      if [[ -e "${unifi_file_or_directory}" ]]; then
        if ! stat -c "%U:%G" "${unifi_file_or_directory}" 2> /dev/null | grep -q "${network_application_user}:${network_application_user}"; then
          unifi_folder_permission_check_detected_files+=("${unifi_file_or_directory}")
        fi
      fi
    done < <(find "${unifi_directory}" -type d -print -o -type f -print 2> /dev/null)
  done < <(find /usr/lib/unifi/ -maxdepth 1 -type l -printf '%l\n' 2> /dev/null)
  if [[ "${#unifi_folder_permission_check_detected_files[@]}" -gt 0 ]]; then
    for unifi_folder_permission_check_detected_file in "${unifi_folder_permission_check_detected_files[@]}"; do
      if [[ -e "${unifi_folder_permission_check_detected_file}" ]]; then
        original_user="$(find "${unifi_folder_permission_check_detected_file}" -maxdepth 0 -printf '%u\n')"
        original_group="$(find "${unifi_folder_permission_check_detected_file}" -maxdepth 0 -printf '%g\n')"
        if [[ "${original_user}" == "${network_application_user}" && "${original_group}" == "${network_application_user}" ]]; then
          continue
        else
          if chown -R "${network_application_user}":"${network_application_user}" "${unifi_folder_permission_check_detected_file}" &>> "${eus_dir}/logs/unifi-folder-permission-update.log"; then
            echo -e "$(date +%F-%T.%6N) | Successfully changed the user/group for ${unifi_folder_permission_check_detected_file} from ${original_user}:${original_group} to ${network_application_user}:${network_application_user}" &>> "${eus_dir}/logs/unifi-folder-permission-update.log"
          else
            echo -e "$(date +%F-%T.%6N) | Failed to change the user/group for ${unifi_folder_permission_check_detected_file} from ${original_user}:${original_group} to ${network_application_user}:${network_application_user}" &>> "${eus_dir}/logs/unifi-folder-permission-update.log"
          fi
        fi
      fi
    done
  fi
}

shutdown_mongodb() {
  echo -e "${GRAY_R}#${RESET} Shutting down the UniFi Network Application database..."
  if "$(which mongod)" --dbpath "${unifi_database_location}" --port 27117 --shutdown --verbose &> "${eus_dir}/logs/run-mongod-shutdown.log"; then
    echo -e "${GREEN}#${RESET} Successfully shutdown the UniFi Network Application database! \\n"
  else
    echo -e "${RED}#${RESET} Failed to shutdown the UniFi Network Application database... Trying to kill it...\\n"
    if ps -p "${eus_mongodb_process}" > /dev/null; then
      if kill -9 "${eus_mongodb_process}" &> "${eus_dir}/logs/run-mongod-pid-kill.log"; then
        echo -e "${GREEN}#${RESET} Successfully killed PID ${eus_mongodb_process}! \\n"
      else
        abort_reason="Failed to kill PID ${eus_mongodb_process}."
        abort
      fi
    else
      echo -e "${RED}#${RESET} PID ${eus_mongodb_process} does not exist...\\n"
    fi
  fi
}

start_unifi_database() {
  current_unifi_database_pid="$(pgrep -f "mongo.pid|mongod.pid")"
  current_unifi_database_pid_stop_attempt="0"
  current_unifi_database_pid_stop_attempt_round="0"
  if [[ -n "${current_unifi_database_pid}" ]]; then
    while [[ -n "$(ps -p "${current_unifi_database_pid}" -o pid=)" ]]; do
      if [[ "${current_unifi_database_pid_message}" != 'true' ]]; then current_unifi_database_pid_message="true"; echo -e "${YELLOW}#${RESET} Another process is already using the UniFi Network Application database...\\n${YELLOW}#${RESET} Attempting to stop the other process..."; fi
      if [[ "${current_unifi_database_pid_stop_attempt}" == "0" ]]; then systemctl stop unifi &>> "${eus_dir}/logs/shutting-down-unifi-database.log"; sleep 10; fi
      if [[ "${current_unifi_database_pid_stop_attempt}" == "1" ]]; then "$(which mongod)" --dbpath "${unifi_database_location}" --port 27117 --shutdown &>> "${eus_dir}/logs/shutting-down-unifi-database.log"; sleep 10; fi
      ((current_unifi_database_pid_stop_attempt=current_unifi_database_pid_stop_attempt+1))
      ((current_unifi_database_pid_stop_attempt_round=current_unifi_database_pid_stop_attempt_round+1))
      if [[ "${current_unifi_database_pid_stop_attempt}" == "1" ]]; then current_unifi_database_pid_stop_attempt="0"; fi
      if [[ "${current_unifi_database_pid_stop_attempt_round}" -ge "10" ]]; then abort_reason="Unable to shutdown the UniFi Network database used by another process... Please reach out to Glenn R."; abort; fi
    done
    echo -e "${GREEN}#${RESET} Successfully stopped the process that was using the UniFi Network Application database! \\n"
    unset current_unifi_database_pid
    unset current_unifi_database_pid_message
  fi
  start_unifi_database_attempts="0"
  if [[ "${start_unifi_database_attempts}" -ge '1' ]]; then
    echo -e "${GRAY_R}#${RESET} Attempting to start the UniFi Network Application database..."
  else
    echo -e "${GRAY_R}#${RESET} Starting the UniFi Network Application database..."
  fi
  if [[ -e "/tmp/mongodb-27117.sock" ]]; then rm --force "/tmp/mongodb-27117.sock" &> /dev/null; fi
  if su -l "${unifi_database_location_user}" -s /bin/bash -c "$(which mongod) --dbpath '${unifi_database_location}' --port 27117 --bind_ip 127.0.0.1 --logpath '${unifi_logs_location}/eus-run-mongod-${start_unifi_database_task}.log' --logappend 2>&1 &" &>> "${eus_dir}/logs/starting-unifi-database.log"; then
  #if sudo -u unifi "$(which mongod)" --dbpath "${unifi_database_location}" --port 27117 --bind_ip 127.0.0.1 --logpath "${unifi_logs_location}/eus-run-mongod-import.log" --logappend & &>/dev/null; then
    sleep 6
    mongo_wait_initilize="0"
    until "${mongocommand}" --port 27117 --eval "print(\"waited for connection\")" &>> "${eus_dir}/logs/mongodb-initialize-waiting.log"; do
      if [[ -e "${unifi_logs_location}/eus-run-mongod-${start_unifi_database_task}.log" ]]; then if tail -n10 "${unifi_logs_location}/eus-run-mongod-${start_unifi_database_task}.log" | grep -ioq "address already in use"; then break; fi; fi
      ((mongo_wait_initilize=mongo_wait_initilize+1))
      echo -ne "\\r${YELLOW}#${RESET} Waiting for MongoDB to initialize... ${mongo_wait_initilize}/20"
      sleep 10
      if [[ "${mongo_wait_initilize}" -ge '20' ]]; then abort_reason="MongoDB did not respond within the set time frame... Please reach out to Glenn R."; if [[ "${start_unifi_database_task}" == 'import' ]]; then shutdown_mongodb; fi; abort; fi
    done
    if [[ "${mongo_wait_initilize}" -gt '0' ]]; then echo -e ""; fi
    echo -e "${GREEN}#${RESET} Successfully started the UniFi Network Application database! \\n"
    sleep 3
    while read -r pid; do
      if ps -fp "${pid}" | grep -iq mongo; then
        eus_mongodb_process="${pid}"
      fi
    done < <(ps aux | awk '{print$1,$2}' | grep -i "${unifi_database_location_user}" | awk '{print$2}')
  else
    echo -e "${RED}#${RESET} Failed to start the UniFi Network Application database... \\n"
  fi
  if [[ -z "${eus_mongodb_process}" ]]; then
    ((start_unifi_database_attempts=start_unifi_database_attempts+1))
    if [[ "${start_unifi_database_attempts}" -ge "2" ]]; then
      abort_reason="variable start_unifi_database_attempts is great than 2 (${start_unifi_database_attempts})"
      abort_function_skip_reason="true"
      abort
    else
      start_unifi_database
    fi
  fi
}

custom_url_question() {
  header
  echo -e "${GRAY_R}#${RESET} Please enter the application download URL below."
  read -rp $'\033[39m#\033[0m ' custom_download_url
  custom_url_download_check
}

custom_url_upgrade_check() {
  echo -e "\\n${GRAY_R}----${RESET}\\n"
  echo -e "${YELLOW}#${RESET} The script will now install application version: ${unifi_clean}!" && sleep 3
  unifi_network_application_downloaded="true"
}

custom_url_download_check() {
  eus_tmp_deb_name="${unifi_deb_file_name}"
  eus_tmp_deb_var="unifi_temp"
  eus_tmp_directory_check
  header
  echo -e "${GRAY_R}#${RESET} Downloading the application release..."
  echo -e "$(date +%F-%T.%6N) | Downloading ${custom_download_url} to ${unifi_temp}" &>> "${eus_dir}/logs/unifi_custom_url_download.log"
  if ! curl "${nos_curl_argument[@]}" --output "$unifi_temp" "${custom_download_url}" &>> "${eus_dir}/logs/unifi_custom_url_download.log"; then
    header_red
    echo -e "${GRAY_R}#${RESET} The URL you provided cannot be downloaded.. Please provide a working URL."
    sleep 3
    custom_url_question
  else
    "$(which dpkg)" -I "${unifi_temp}" | awk '{print tolower($0)}' &> "${unifi_temp}.tmp"
    package_maintainer=$(awk '/maintainer/{print$2}' "${unifi_temp}.tmp")
    unifi_clean=$(awk '/version:/{print$2}' "${unifi_temp}.tmp" | awk -F"-" '{print $1}')
    rm --force "${unifi_temp}.tmp" &> /dev/null
    if [[ "${package_maintainer}" =~ (unifi|ubiquiti) ]]; then
      echo -e "${GREEN}#${RESET} Successfully downloaded the application release!"
      sleep 2
      custom_url_upgrade_check
    else
      header_red
      echo -e "${GRAY_R}#${RESET} You did not provide a UniFi Network Application that is maintained by Ubiquiti ( UniFi )..."
      while true; do
        read -rp $'\033[39m#\033[0m Do you want to provide the script with another URL? (Y/n) ' yes_no
        case "$yes_no" in
            [Yy]*|"") custom_url_question; break;;
            [Nn]*) break;;
            *) echo -e "\\n${RED}#${RESET} Invalid input, please answer Yes or No (y/n)...\\n"; sleep 3;;
        esac
      done
    fi
  fi
}

if [[ "${script_option_custom_url}" == 'true' ]]; then if [[ "${custom_url_down_provided}" == 'true' ]]; then custom_url_download_check; else custom_url_question; fi; fi

free_space_check() {
  if [[ "$(df -B1 / | awk 'NR==2{print $4}')" -le '5368709120' ]]; then
    header_red
    echo -e "${YELLOW}#${RESET} You only have $(df -B1 / | awk 'NR==2{print $4}' | awk '{ split( "B KB MB GB TB PB EB ZB YB" , v ); s=1; while( $1>1024 && s<9 ){ $1/=1024; s++ } printf "%.1f %s", $1, v[s] }') of disk space available on \"/\"... \\n"
    while true; do
      read -rp $'\033[39m#\033[0m Do you want to proceed with running the script? (y/N) ' yes_no
      case "$yes_no" in
         [Nn]*|"")
            free_space_check_response="Cancel script"
            free_space_check_date="$(date +%s)"
            echo -e "${YELLOW}#${RESET} OK... Please free up disk space before running the script again..."
            cancel_script_without_clearing_error="true"
            cancel_script
            break;;
         [Yy]*)
            free_space_check_response="Proceed at own risk"
            free_space_check_date="$(date +%s)"
            echo -e "${YELLOW}#${RESET} OK... Proceeding with the script.. please note that failures may occur due to not enough disk space... \\n"; sleep 10
            break;;
         *) echo -e "\\n${RED}#${RESET} Invalid input, please answer Yes or No (y/n)...\\n"; sleep 3;;
      esac
    done
    if [[ -n "$(command -v jq)" ]]; then
      if [[ "$(dpkg-query --showformat='${version}' --show jq 2> /dev/null | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" && -e "${eus_dir}/db/db.json" ]]; then
        jq '.scripts."'"${script_name}"'" += {"warnings": {"low-free-disk-space": {"response": "'"${free_space_check_response}"'", "detected-date": "'"${free_space_check_date}"'"}}}' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
      else
        jq '.scripts."'"${script_name}"'" = (.scripts."'"${script_name}"'" | . + {"warnings": {"low-free-disk-space": {"response": "'"${free_space_check_response}"'", "detected-date": "'"${free_space_check_date}"'"}}})' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
      fi
      eus_database_move
    fi
  fi
}
free_space_check

free_boot_space_check() {
  free_boot_space="$(df -B1 /boot | awk 'NR==2{print $4}')"
  if "$(which dpkg)" --list | grep -Ei 'linux-image|linux-headers|linux-firmware' | awk '{print $1}' | grep -iq "^iF" && [[ "${free_boot_space}" -le '322122547' && "${script_option_skip}" != 'true' ]]; then
    apt-get -y autoremove &>> "${eus_dir}/logs/boot-apt-cleanup.log"
    apt-get -y autoclean &>> "${eus_dir}/logs/boot-apt-cleanup.log"
    if [[ "$(df -B1 /boot | awk 'NR==2{print $4}')" == "${free_boot_space}" ]]; then
      if [[ "${free_boot_space}" -le '53687091' ]]; then
        header_red
        echo -e "${GRAY_R}#${RESET} You only have $(df -B1 /boot | awk 'NR==2{print $4}' | awk '{ split( "B KB MB GB TB PB EB ZB YB" , v ); s=1; while( $1>1024 && s<9 ){ $1/=1024; s++ } printf "%.1f %s", $1, v[s] }') of disk space available on \"/boot\".. Please expand or clean up old kernel images!"
        while true; do
          read -rp $'\033[39m#\033[0m Do you want to proceed with running the script? (y/N) ' yes_no
          case "$yes_no" in
             [Nn]*|"")
                free_boot_space_check_response="Cancel script"
                free_boot_space_check_date="$(date +%s)"
                echo -e "${YELLOW}#${RESET} OK... Please free up disk space before running the script again..."
                cancel_script_without_clearing_error="true"
                cancel_script
                break;;
             [Yy]*)
                free_boot_space_check_response="Proceed at own risk"
                free_boot_space_check_date="$(date +%s)"
                echo -e "${YELLOW}#${RESET} OK... Proceeding with the script.. please note that failures may occur due to not enough disk space... \\n"; sleep 10; skip_linux_images_recovery="true"
                break;;
             *) echo -e "\\n${RED}#${RESET} Invalid input, please answer Yes or No (y/n)...\\n"; sleep 3;;
          esac
        done
        if [[ -n "$(command -v jq)" ]]; then
          if [[ "$(dpkg-query --showformat='${version}' --show jq 2> /dev/null | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" && -e "${eus_dir}/db/db.json" ]]; then
            jq '.scripts."'"${script_name}"'" += {"warnings": {"low-free-boot-partition-space": {"response": "'"${free_boot_space_check_response}"'", "detected-date": "'"${free_boot_space_check_date}"'"}}}' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
          else
            jq '.scripts."'"${script_name}"'" = (.scripts."'"${script_name}"'" | . + {"warnings": {"low-free-boot-partition-space": {"response": "'"${free_boot_space_check_response}"'", "detected-date": "'"${free_boot_space_check_date}"'"}}})' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
          fi
          eus_database_move
        fi
      fi
    fi
    if [[ "${skip_linux_images_recovery}" != 'true' ]]; then
      while read -r linux_package; do
        if [[ "${free_boot_space_check_header_message}" != 'true' ]]; then header; free_boot_space_check_header_message="true"; fi
        echo -e "${GRAY_R}#${RESET} Trying to install ${linux_package}..."
        if "${EUS_APT_ENV[@]}" env DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_downgrade_option[@]}" "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "${linux_package}" &>> "${eus_dir}/logs/linux-package-install.log"; then
          echo -e "${GREEN}#${RESET} Successfully installed ${linux_package}! \\n"
        else
          check_unmet_dependencies
          broken_packages_check
          attempt_recover_broken_packages
          add_apt_option_no_install_recommends="true"; get_apt_options
          if "${EUS_APT_ENV[@]}" env DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_downgrade_option[@]}" "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "${linux_package}" &>> "${eus_dir}/logs/linux-package-install.log"; then
            echo -e "${GREEN}#${RESET} Successfully installed ${linux_package}! \\n"
          else
            echo -e "${RED}#${RESET} Failed to install ${linux_package}, most likely because the system only has $(df -B1 /boot | awk 'NR==2{print $4}' | awk '{ split( "B KB MB GB TB PB EB ZB YB" , v ); s=1; while( $1>1024 && s<9 ){ $1/=1024; s++ } printf "%.1f %s", $1, v[s] }') on space available on \"/boot\"... \\n"; abort_function_skip_reason="true"; abort_reason="Failed to install ${linux_package} during the boot partition low disk space check."
            abort
          fi
          get_apt_options
        fi
      done < <(dpkg-query -W -f='${db:Status-Abbrev} ${Package}\n' | awk '$1 == "iF" {print $2}' | grep -Ei 'linux-image|linux-headers|linux-firmware')
    fi
  fi
}
free_boot_space_check

free_var_log_space_check() {
  if [[ "$(df --output=source / | tail -1)" != "$(df --output=source /var/log | tail -1)" && "${script_option_skip}" != 'true' ]]; then
    if [[ "$(df -B1 /var/log | awk 'NR==2{print $4}')" -le '26214400' ]]; then
      header_red
      echo -e "${YELLOW}#${RESET} You only have $(df -B1 /var/log | awk 'NR==2{print $4}' | awk '{ split( "B KB MB GB TB PB EB ZB YB" , v ); s=1; while( $1>1024 && s<9 ){ $1/=1024; s++ } printf "%.1f %s", $1, v[s] }') of disk space available on \"/var/log\"..."
      echo -e "${GRAY_R}#${RESET} How would you like to proceed?"
      echo -e "\\n${GRAY_R}---${RESET}\\n"
      echo -e " [   ${WHITE_R}1 ${RESET}   ]  |  Let the script attempt to clean up log files."
      echo -e " [   ${WHITE_R}2 ${RESET}   ]  |  Proceed with a higher failure risk."
      echo -e " [   ${WHITE_R}3 ${RESET}   ]  |  I want to free up disk space before attempting again."
      echo -e "\\n"
      read -rp $'Your choice | \033[39m' choice
      case "$choice" in
         1) echo -e "${GRAY_R}#${RESET} Attempting to clean up log files..."
            if find "/var/log" -name "*.log" -exec truncate -s 1M {} \;;then echo -e "${GREEN}#${RESET} Successfully cleaned up some log files! \\n"; else echo -e "${RED}#${RESET} Failed to clean up log files... \\n"; fi
            sleep 3
            free_var_log_space_check;;
         2) echo -e "${YELLOW}#${RESET} OK... Proceeding with the script.. please note that failures may occur due to not enough disk space... \\n"; sleep 10;;
         3) echo -e "${YELLOW}#${RESET} OK... Please free up disk space before running the script again..."; cancel_script_without_clearing_error="true"; cancel_script;;
	     *) header_red; echo -e "${GRAY_R}#${RESET} Option ${choice} is not a valid..."; sleep 3; free_var_log_space_check;;
      esac
    fi
  fi
}
free_var_log_space_check

free_disk_space_check() {
  local path="${1}"
  local min_gb="${2}"
  # Get available space in GB (integer)
  local free_gb
  free_gb="$(df -BG --output=avail "${path}" | tail -n 1 | sed 's/[[:space:]]//g; s/G//')"
  if (( free_gb < min_gb )); then
    echo -e "$(date +%F-%T.%6N) | ${path} has only $(df -B1 "${path}" | awk 'NR==2{print $4}' | awk '{ split( "B KB MB GB TB PB EB ZB YB" , v ); s=1; while( $1>1024 && s<9 ){ $1/=1024; s++ } printf "%.1f %s", $1, v[s] }') free (needs at least ${min_gb}GB)" &>> "${eus_dir}/logs/free-disk-space-check.log"
    echo -e "${YELLOW}#${RESET} ${path} has only $(df -B1 "${path}" | awk 'NR==2{print $4}' | awk '{ split( "B KB MB GB TB PB EB ZB YB" , v ); s=1; while( $1>1024 && s<9 ){ $1/=1024; s++ } printf "%.1f %s", $1, v[s] }') free (needs at least ${min_gb} GB)"
    cancel_script_without_clearing_error="true"
    cancel_script
  else
    echo -e "$(date +%F-%T.%6N) | ${path} has $(df -B1 "${path}" | awk 'NR==2{print $4}' | awk '{ split( "B KB MB GB TB PB EB ZB YB" , v ); s=1; while( $1>1024 && s<9 ){ $1/=1024; s++ } printf "%.1f %s", $1, v[s] }') free (≥ ${min_gb} GB)" &>> "${eus_dir}/logs/free-disk-space-check.log"
    return 0
  fi
}

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
  echo -e "${GRAY_R}#${RESET} Installing required packages for the script..\\n"
  run_apt_get_update_with_sha1_fallback
  sleep 2
}
apt_get_install_package() {
  if [[ "${old_openjdk_version}" == 'true' ]]; then
    apt_get_install_package_variable="update"; apt_get_install_package_variable_2="updated"
  else
    apt_get_install_package_variable="install"; apt_get_install_package_variable_2="installed"
  fi
  run_apt_get_update_with_sha1_fallback
  check_dpkg_lock
  echo -e "\\n------- ${required_package} installation ------- $(date +%F-%T.%6N) -------\\n" &>> "${eus_dir}/logs/apt.log"
  echo -e "${GRAY_R}#${RESET} Trying to ${apt_get_install_package_variable} ${required_package%%:*}..."
  if "${EUS_APT_ENV[@]}" env DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "${required_package}" 2>&1 | tee -a "${eus_dir}/logs/apt.log" > /tmp/EUS/apt/apt.log; then
    if [[ "${PIPESTATUS[0]}" -eq "0" ]]; then
      echo -e "${GREEN}#${RESET} Successfully ${apt_get_install_package_variable_2} ${required_package%%:*}! \\n"; sleep 2
    else
      echo -e "${RED}#${RESET} Failed to ${apt_get_install_package_variable} ${required_package%%:*}...\\n"
      check_unmet_dependencies
      broken_packages_check
      attempt_recover_broken_packages
      add_apt_option_no_install_recommends="true"; get_apt_options
      echo -e "${GRAY_R}#${RESET} Trying to ${apt_get_install_package_variable} ${required_package%%:*}..."
      if "${EUS_APT_ENV[@]}" env DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" "${apt_downgrade_option[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "${required_package}" 2>&1 | tee -a "${eus_dir}/logs/apt.log" > /tmp/EUS/apt/apt.log; then
        if [[ "${PIPESTATUS[0]}" -eq "0" ]]; then
          echo -e "${GREEN}#${RESET} Successfully ${apt_get_install_package_variable_2} ${required_package%%:*}! \\n"; sleep 2
        else
          if [[ -z "${java_install_attempts}" ]]; then abort_reason="Failed to ${apt_get_install_package_variable} ${required_package%%:*}."; abort; else echo -e "${RED}#${RESET} Failed to ${apt_get_install_package_variable} ${required_package%%:*}...\\n"; fi
        fi
      fi
      get_apt_options
    fi
  fi
  unset required_package
}

if ! "$(which dpkg)" -l curl 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
  if [[ "${installing_required_package}" != 'yes' ]]; then install_required_packages; fi
  check_dpkg_lock
  echo -e "${GRAY_R}#${RESET} Installing curl..."
  if ! "${EUS_APT_ENV[@]}" env DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install curl &>> "${eus_dir}/logs/required.log"; then
    echo -e "${RED}#${RESET} Failed to install curl in the first run...\\n"
    if [[ "${repo_codename}" =~ (precise|trusty|utopic|vivid|wily|yakkety|zesty|artful|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing|resolute) ]]; then
      if [[ "${repo_codename}" =~ (precise|trusty|utopic|vivid|wily|yakkety|zesty|artful|xenial|bionic|cosmic) ]]; then repo_codename_argument="-security"; repo_component="main"; fi
      if [[ "${repo_codename}" =~ (disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing|resolute) ]]; then repo_component="main"; fi
    elif [[ "${repo_codename}" == "jessie" ]]; then
      repo_codename_argument="/updates"
      repo_component="main"
    elif [[ "${repo_codename}" =~ (stretch|buster|bullseye|bookworm|trixie|forky|unstable) ]]; then
      repo_component="main"
    fi
    add_repositories
    required_package="curl"
    apt_get_install_package
  else
    echo -e "${GREEN}#${RESET} Successfully installed curl! \\n" && sleep 2
  fi
  script_version_check
  set_curl_arguments
  get_repo_url
fi
if ! "$(which dpkg)" -l sudo 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
  if [[ "${installing_required_package}" != 'yes' ]]; then install_required_packages; fi
  check_dpkg_lock
  echo -e "${GRAY_R}#${RESET} Installing sudo..."
  if ! "${EUS_APT_ENV[@]}" env DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install sudo &>> "${eus_dir}/logs/required.log"; then
    echo -e "${RED}#${RESET} Failed to install sudo in the first run...\\n"
    repo_component="main"
    add_repositories
    required_package="sudo"
    apt_get_install_package
  else
    echo -e "${GREEN}#${RESET} Successfully installed sudo! \\n" && sleep 2
  fi
fi
if ! "$(which dpkg)" -l jq 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
  if [[ "${installing_required_package}" != 'yes' ]]; then
    install_required_packages
  fi
  check_dpkg_lock
  echo -e "${GRAY_R}#${RESET} Installing jq..."
  if ! "${EUS_APT_ENV[@]}" env DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install jq &>> "${eus_dir}/logs/required.log"; then
    echo -e "${RED}#${RESET} Failed to install jq in the first run...\\n"
    if [[ "${repo_codename}" =~ (precise|trusty|utopic|vivid|wily|yakkety|zesty|artful|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing|resolute) ]]; then
      if [[ "${repo_codename}" =~ (bionic|cosmic|disco|eoan|focal|focal|groovy|hirsute|impish) ]]; then repo_component="main universe"; add_repositories; fi
      if [[ "${repo_codename}" =~ (jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing|resolute) ]]; then repo_component="main"; add_repositories; fi
      repo_codename_argument="-security"; repo_component="main universe"
    elif [[ "${repo_codename}" =~ (wheezy|jessie|stretch|buster|bullseye|bookworm|trixie|forky|unstable) ]]; then
      if [[ "${repo_codename}" =~ (wheezy|jessie|stretch|buster) ]]; then repo_url_arguments="-security/"; repo_codename_argument="/updates"; repo_component="main"; add_repositories; fi
      if [[ "${repo_codename}" =~ (bullseye|bookworm|trixie|forky|unstable) ]]; then repo_url_arguments="-security/"; repo_codename_argument="-security"; repo_component="main"; add_repositories; fi
      repo_component="main"
    fi
    add_repositories
    required_package="jq"
    apt_get_install_package
  else
    echo -e "${GREEN}#${RESET} Successfully installed jq! \\n" && sleep 2
  fi
  set_curl_arguments
  create_eus_database
  if [[ "${eus_database_update_broken_install_check}" == 'true' ]]; then eus_database_update_broken_install; unset eus_database_update_broken_install_check; fi
fi
if ! "$(which dpkg)" -l lsb-release 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
  if [[ "${installing_required_package}" != 'yes' ]]; then install_required_packages; fi
  check_dpkg_lock
  echo -e "${GRAY_R}#${RESET} Installing lsb-release..."
  if ! "${EUS_APT_ENV[@]}" env DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install lsb-release &>> "${eus_dir}/logs/required.log"; then
    echo -e "${RED}#${RESET} Failed to install lsb-release in the first run...\\n"
    if [[ "${repo_codename}" =~ (precise|trusty|utopic|vivid|wily|yakkety|zesty|artful|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing|resolute) ]]; then
      repo_component="main universe"
    elif [[ "${repo_codename}" =~ (wheezy|jessie|stretch|buster|bullseye|bookworm|trixie|forky|unstable) ]]; then
      repo_component="main"
    fi
    add_repositories
    required_package="lsb-release"
    apt_get_install_package
  else
    echo -e "${GREEN}#${RESET} Successfully installed lsb-release! \\n" && sleep 2
  fi
fi
if ! "$(which dpkg)" -l net-tools 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
  if [[ "${installing_required_package}" != 'yes' ]]; then install_required_packages; fi
  check_dpkg_lock
  echo -e "${GRAY_R}#${RESET} Installing net-tools..."
  if ! "${EUS_APT_ENV[@]}" env DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install net-tools &>> "${eus_dir}/logs/required.log"; then
    echo -e "${RED}#${RESET} Failed to install net-tools in the first run...\\n"
    repo_component="main"
    add_repositories
    required_package="net-tools"
    apt_get_install_package
  else
    echo -e "${GREEN}#${RESET} Successfully installed net-tools! \\n" && sleep 2
  fi
fi
if "$(which dpkg)" -l apt 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
  apt_package_version="$(dpkg-query --showformat='${version}' --show apt 2> /dev/null | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)"
  if [[ "${apt_package_version::2}" -le "14" ]]; then 
    if ! "$(which dpkg)" -l apt-transport-https 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
      check_dpkg_lock
      if [[ "${installing_required_package}" != 'yes' ]]; then install_required_packages; fi
      echo -e "${GRAY_R}#${RESET} Installing apt-transport-https..."
      if ! "${EUS_APT_ENV[@]}" env DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install apt-transport-https &>> "${eus_dir}/logs/required.log"; then
        echo -e "${RED}#${RESET} Failed to install apt-transport-https in the first run...\\n"
        if [[ "${repo_codename}" =~ (precise|trusty|utopic|vivid|wily|yakkety|zesty|artful|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing|resolute) ]]; then
          if [[ "${repo_codename}" =~ (precise|trusty|utopic|vivid|wily|yakkety|zesty|artful|xenial) ]]; then repo_codename_argument="-security"; repo_component="main"; fi
          if [[ "${repo_codename}" =~ (bionic|cosmic) ]]; then repo_codename_argument="-security"; repo_component="main universe"; fi
          if [[ "${repo_codename}" =~ (disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing|resolute) ]]; then repo_component="main universe"; fi
        elif [[ "${repo_codename}" == "jessie" ]]; then
          repo_codename_argument="/updates"
          repo_component="main"
        elif [[ "${repo_codename}" =~ (stretch|buster|bullseye|bookworm|trixie|forky|unstable) ]]; then
          repo_component="main"
        fi
        add_repositories
        required_package="apt-transport-https"
        apt_get_install_package
      else
        echo -e "${GREEN}#${RESET} Successfully installed apt-transport-https! \\n" && sleep 2
      fi
      get_repo_url
    fi
  fi
fi
if ! "$(which dpkg)" -l dirmngr 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
  if [[ "${installing_required_package}" != 'yes' ]]; then install_required_packages; fi
  check_dpkg_lock
  echo -e "${GRAY_R}#${RESET} Installing dirmngr..."
  if ! "${EUS_APT_ENV[@]}" env DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install dirmngr &>> "${eus_dir}/logs/required.log"; then
    echo -e "${RED}#${RESET} Failed to install dirmngr in the first run...\\n"
    if [[ "${repo_codename}" =~ (precise|trusty|utopic|vivid|wily|yakkety|zesty|artful|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing|resolute) ]]; then
      repo_component="universe"
      add_repositories
      repo_component="main restricted"
    elif [[ "${repo_codename}" =~ (wheezy|jessie|stretch|buster|bullseye|bookworm|trixie|forky|unstable) ]]; then
      repo_component="main"
    fi
    add_repositories
    required_package="dirmngr"
    apt_get_install_package
  else
    echo -e "${GREEN}#${RESET} Successfully installed dirmngr! \\n" && sleep 2
  fi
fi
if ! "$(which dpkg)" -l netcat netcat-traditional 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
  if [[ "${installing_required_package}" != 'yes' ]]; then install_required_packages; fi
  if apt-cache search -n '^netcat$' | awk '{print$1}' | grep -qi "^netcat$"; then required_package="netcat"; else required_package="netcat-traditional"; fi
  netcat_installed_package_name="${required_package}"
  check_dpkg_lock
  echo -e "${GRAY_R}#${RESET} Installing ${required_package}..."
  if ! "${EUS_APT_ENV[@]}" env DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "${required_package}" &>> "${eus_dir}/logs/required.log"; then
    echo -e "${RED}#${RESET} Failed to install ${required_package} in the first run...\\n"
    if [[ "${repo_codename}" =~ (precise|trusty|utopic|vivid|wily|yakkety|zesty|artful|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing|resolute) ]]; then
      repo_component="main universe"
    elif [[ "${repo_codename}" =~ (wheezy|jessie|stretch|buster|bullseye|bookworm|trixie|forky|unstable) ]]; then
      repo_component="main"
    fi
    add_repositories
    apt_get_install_package
  else
    echo -e "${GREEN}#${RESET} Successfully installed ${required_package}! \\n" && sleep 2
  fi
  netcat_installed="true"
fi
if ! "$(which dpkg)" -l psmisc 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
  if [[ "${installing_required_package}" != 'yes' ]]; then install_required_packages; fi
  check_dpkg_lock
  echo -e "${GRAY_R}#${RESET} Installing psmisc..."
  if ! "${EUS_APT_ENV[@]}" env DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install psmisc &>> "${eus_dir}/logs/required.log"; then
    echo -e "${RED}#${RESET} Failed to install psmisc in the first run...\\n"
    if [[ "${repo_codename}" =~ (precise|trusty|utopic|vivid|wily|yakkety|zesty|artful|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing|resolute) ]]; then
      if [[ "${repo_codename}" =~ (precise) ]]; then repo_codename_argument="-updates"; repo_component="main restricted"; fi
      if [[ "${repo_codename}" =~ (trusty|utopic|vivid|wily|yakkety|zesty|artful|xenial|bionic|cosmicdisco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing|resolute) ]]; then repo_component="universe"; fi
    elif [[ "${repo_codename}" =~ (wheezy|jessie|stretch|buster|bullseye|bookworm|trixie|forky|unstable) ]]; then
      repo_component="main"
    fi
    add_repositories
    required_package="psmisc"
    apt_get_install_package
  else
    echo -e "${GREEN}#${RESET} Successfully installed psmisc! \\n" && sleep 2
  fi
fi
if ! "$(which dpkg)" -l gnupg 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
  if [[ "${installing_required_package}" != 'yes' ]]; then install_required_packages; fi
  check_dpkg_lock
  echo -e "${GRAY_R}#${RESET} Installing gnupg..."
  if ! "${EUS_APT_ENV[@]}" env DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install gnupg &>> "${eus_dir}/logs/required.log"; then
    echo -e "${RED}#${RESET} Failed to install gnupg in the first run...\\n"
    if [[ "${repo_codename}" =~ (precise|trusty|utopic|vivid|wily|yakkety|zesty|artful|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing|resolute) ]]; then
      if [[ "${repo_codename}" =~ (precise|trusty|utopic|vivid|wily|yakkety|zesty|artful|xenial) ]]; then repo_codename_argument="-security"; repo_component="main"; fi
      if [[ "${repo_codename}" =~ (bionic|cosmic) ]]; then repo_codename_argument="-security"; repo_component="main universe"; fi
      if [[ "${repo_codename}" =~ (disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing|resolute) ]]; then repo_component="main universe"; fi
    elif [[ "${repo_codename}" =~ (wheezy|jessie|stretch|buster|bullseye|bookworm|trixie|forky|unstable) ]]; then
      repo_component="main"
    fi
    add_repositories
    required_package="gnupg"
    apt_get_install_package
  else
    echo -e "${GREEN}#${RESET} Successfully installed gnupg! \\n" && sleep 2
  fi
else
  if dmesg 2> /dev/null | grep -i gpg | grep -iq segfault; then
    gnupg_segfault_packages=("gnupg" "gnupg2" "libc6" "libreadline8" "libreadline-dev" "libslang2" "zlib1g" "libbz2-1.0" "libgcrypt20" "libsqlite3-0" "libassuan0" "libgpg-error0" "libm6" "libpthread-stubs0-dev" "libtinfo6")
    reinstall_gnupg_segfault_packages=()
    for gnupg_segfault_package in "${gnupg_segfault_packages[@]}"; do if "$(which dpkg)" -l "${gnupg_segfault_package}" &> /dev/null; then reinstall_gnupg_segfault_packages+=("${gnupg_segfault_package}"); fi; done
    if [[ "${#reinstall_gnupg_segfault_packages[@]}" -gt '0' ]]; then echo -e "\\n------- $(date +%F-%T.%6N) -------\\n" &>> "${eus_dir}/logs/gnupg-segfault-reinstall.log"; "${EUS_APT_ENV[@]}" env DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install --reinstall "${reinstall_gnupg_segfault_packages[@]}" &>> "${eus_dir}/logs/gnupg-segfault-reinstall.log"; fi
  fi
fi
if ! "$(which dpkg)" -l perl 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
  if [[ "${installing_required_package}" != 'yes' ]]; then
    install_required_packages
  fi
  check_dpkg_lock
  echo -e "${GRAY_R}#${RESET} Installing perl..."
  if ! "${EUS_APT_ENV[@]}" env DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install perl &>> "${eus_dir}/logs/required.log"; then
    echo -e "${RED}#${RESET} Failed to install perl in the first run...\\n"
    if [[ "${repo_codename}" =~ (precise|trusty|utopic|vivid|wily|yakkety|zesty|artful|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing|resolute) ]]; then
      if [[ "${repo_codename}" =~ (precise|trusty|utopic|vivid|wily|yakkety|zesty|artful|xenial|bionic|cosmic) ]]; then repo_codename_argument="-security"; repo_component="main"; fi
      if [[ "${repo_codename}" =~ (disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing|resolute) ]]; then repo_component="main"; fi
    elif [[ "${repo_codename}" == "jessie" ]]; then
      repo_codename_argument="/updates"
      repo_component="main"
    elif [[ "${repo_codename}" =~ (stretch|buster|bullseye|bookworm|trixie|forky|unstable) ]]; then
      repo_component="main"
    fi
    add_repositories
    required_package="perl"
    apt_get_install_package
  else
    echo -e "${GREEN}#${RESET} Successfully installed perl! \\n" && sleep 2
  fi
fi
if [[ "${fqdn_specified}" == 'true' ]]; then
  if ! "$(which dpkg)" -l dnsutils 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
    if [[ "${installing_required_package}" != 'yes' ]]; then install_required_packages; fi
  check_dpkg_lock
    echo -e "${GRAY_R}#${RESET} Installing dnsutils..."
    if ! "${EUS_APT_ENV[@]}" env DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install dnsutils &>> "${eus_dir}/logs/required.log"; then
      echo -e "${RED}#${RESET} Failed to install dnsutils in the first run...\\n"
      if [[ "${repo_codename}" =~ (precise|trusty|utopic|vivid|wily|yakkety|zesty|artful|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing|resolute) ]]; then
        if [[ "${repo_codename}" =~ (precise|trusty|utopic|vivid|wily|yakkety|zesty|artful|xenial) ]]; then repo_codename_argument="-security"; repo_component="main"; fi
        if [[ "${repo_codename}" =~ (bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing|resolute) ]]; then repo_component="main"; fi
      elif [[ "${repo_codename}" =~ (wheezy|jessie|stretch|buster|bullseye|bookworm|trixie|forky|unstable) ]]; then
        if [[ "${repo_codename}" =~ (wheezy|jessie|stretch|buster|bullseye|bookworm|trixie|forky|unstable) ]]; then repo_url_arguments="-security/"; repo_codename_argument="/updates"; repo_component="main"; add_repositories; fi
        repo_component="main"
      fi
      add_repositories
      required_package="dnsutils"
      apt_get_install_package
    else
      echo -e "${GREEN}#${RESET} Successfully installed dnsutils! \\n" && sleep 2
    fi
  fi
fi

network_install_required_packages_check() {
  if ! "$(which dpkg)" -l logrotate 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
    if [[ "${installing_required_package}" != 'yes' ]]; then install_required_packages; fi
    check_dpkg_lock
    echo -e "${GRAY_R}#${RESET} Installing logrotate..."
    if ! "${EUS_APT_ENV[@]}" env DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install logrotate &>> "${eus_dir}/logs/required.log"; then
      echo -e "${RED}#${RESET} Failed to install logrotate in the first run...\\n"
      if [[ "${repo_codename}" =~ (precise|trusty|utopic|vivid|wily|yakkety|zesty|artful|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing|resolute) ]]; then
        repo_component="universe"
      elif [[ "${repo_codename}" =~ (wheezy|jessie|stretch|buster|bullseye|bookworm|trixie|forky|unstable) ]]; then
        repo_component="main"
      fi
      add_repositories
      required_package="logrotate"
      apt_get_install_package
    else
      echo -e "${GREEN}#${RESET} Successfully installed logrotate! \\n" && sleep 2
    fi
  fi
  if ! "$(which dpkg)" -l procps 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
    if [[ "${installing_required_package}" != 'yes' ]]; then install_required_packages; fi
    check_dpkg_lock
    echo -e "${GRAY_R}#${RESET} Installing procps..."
    if ! "${EUS_APT_ENV[@]}" env DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install procps &>> "${eus_dir}/logs/required.log"; then
      echo -e "${RED}#${RESET} Failed to install procps in the first run...\\n"
      if [[ "${repo_codename}" =~ (precise|trusty|utopic|vivid|wily|yakkety|zesty|artful|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing|resolute) ]]; then
        if [[ "${repo_codename}" =~ (precise|trusty|utopic|vivid|wily|yakkety|zesty|artful|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing|resolute) ]]; then repo_codename_argument="-security"; repo_component="main"; fi
      elif [[ "${repo_codename}" == "jessie" ]]; then
        repo_codename_argument="/updates"
        repo_component="main"
      elif [[ "${repo_codename}" =~ (stretch|buster|bullseye|bookworm|trixie|forky|unstable) ]]; then
        repo_component="main"
      fi
      add_repositories
      required_package="procps"
      apt_get_install_package
    else
      echo -e "${GREEN}#${RESET} Successfully installed procps! \\n" && sleep 2
    fi
  fi
  if ! "$(which dpkg)" -l adduser 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
    if [[ "${installing_required_package}" != 'yes' ]]; then install_required_packages; fi
    check_dpkg_lock
    echo -e "${GRAY_R}#${RESET} Installing adduser..."
    if ! "${EUS_APT_ENV[@]}" env DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install adduser &>> "${eus_dir}/logs/required.log"; then
      echo -e "${RED}#${RESET} Failed to install adduser in the first run...\\n"
      if [[ "${repo_codename}" =~ (precise|trusty|utopic|vivid|wily|yakkety|zesty|artful|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing|resolute) ]]; then
        repo_component="universe"
      elif [[ "${repo_codename}" =~ (wheezy|jessie|stretch|buster|bullseye|bookworm|trixie|forky|unstable) ]]; then
        repo_component="main"
      fi
      add_repositories
      required_package="adduser"
      apt_get_install_package
    else
      echo -e "${GREEN}#${RESET} Successfully installed adduser! \\n" && sleep 2
    fi
  fi
}

uos_server_install_required_packages_check() {
  if ! "$(which dpkg)" -l podman 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
    if [[ "${installing_required_package}" != 'yes' ]]; then install_required_packages; fi
    check_dpkg_lock
    echo -e "${GRAY_R}#${RESET} Installing podman..."
    if ! "${EUS_APT_ENV[@]}" env DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install podman &>> "${eus_dir}/logs/required.log"; then
      echo -e "${RED}#${RESET} Failed to install podman in the first run...\\n"
      if [[ "${repo_codename}" =~ (noble|oracular|plucky|questing|resolute) ]]; then
        repo_component="main universe"
      elif [[ "${repo_codename}" =~ (bookworm|trixie|forky|unstable) ]]; then
        repo_component="main"
      fi
      add_repositories
      required_package="podman"
      apt_get_install_package
    else
      echo -e "${GREEN}#${RESET} Successfully installed podman! \\n" && sleep 2
    fi
  fi
  podman_version="$(dpkg-query -W -f='${Version}\n' podman 2> /dev/null | sed -E 's/^([0-9]+\.[0-9]+\.[0-9]+).*/\1/')"
  pasta_podman_version_required="4.9.3"
  paste_uos_version_required="5.0.5"
  if ! (version_ge "${podman_version}" "${pasta_podman_version_required}" && version_ge "${uos_version}" "${paste_uos_version_required}"); then
    echo -e "$(date +%F-%T.%6N) | slirp4netns is required (Podman ${podman_version} $(cmp_symbol "${podman_version}" "${pasta_podman_version_required}") ${pasta_podman_version_required} and uos_version ${uos_version} $(cmp_symbol "${uos_version}" "${paste_uos_version_required}") ${paste_uos_version_required})" &>> "${eus_dir}/logs/uos-server-slirp4netns-check.log"
    if ! "$(which dpkg)" -l slirp4netns 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
      if [[ "${installing_required_package}" != 'yes' ]]; then install_required_packages; fi
      check_dpkg_lock
      echo -e "${GRAY_R}#${RESET} Installing slirp4netns..."
      if ! "${EUS_APT_ENV[@]}" env DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install slirp4netns &>> "${eus_dir}/logs/required.log"; then
        echo -e "${RED}#${RESET} Failed to install slirp4netns in the first run...\\n"
        if [[ "${repo_codename}" =~ (noble|oracular|plucky|questing|resolute) ]]; then
          repo_component="universe"
        elif [[ "${repo_codename}" =~ (bookworm|trixie|forky|unstable) ]]; then
          repo_component="main"
        fi
        add_repositories
        required_package="slirp4netns"
        apt_get_install_package
      else
        echo -e "${GREEN}#${RESET} Successfully installed slirp4netns! \\n" && sleep 2
      fi
    fi
  else
    echo -e "$(date +%F-%T.%6N) | Skipping slirp4netns install (Podman ${podman_version} $(cmp_symbol "${podman_version}" "${pasta_podman_version_required}") ${pasta_podman_version_required} and uos_version ${uos_version} $(cmp_symbol "${uos_version}" "${paste_uos_version_required}") ${paste_uos_version_required})" &>> "${eus_dir}/logs/uos-server-slirp4netns-check.log"
  fi
  if ! "$(which dpkg)" -l uidmap 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
    if [[ "${installing_required_package}" != 'yes' ]]; then install_required_packages; fi
    check_dpkg_lock
    echo -e "${GRAY_R}#${RESET} Installing uidmap..."
    if ! "${EUS_APT_ENV[@]}" env DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install uidmap &>> "${eus_dir}/logs/required.log"; then
      echo -e "${RED}#${RESET} Failed to install uidmap in the first run...\\n"
      if [[ "${repo_codename}" =~ (noble|oracular|plucky|questing|resolute) ]]; then
        repo_component="universe"
      elif [[ "${repo_codename}" =~ (bookworm|trixie|forky|unstable) ]]; then
        repo_component="main"
      fi
      add_repositories
      required_package="uidmap"
      apt_get_install_package
    else
      echo -e "${GREEN}#${RESET} Successfully installed uidmap! \\n" && sleep 2
    fi
  fi
  if ! "$(which dpkg)" -l dbus 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
    if [[ "${installing_required_package}" != 'yes' ]]; then install_required_packages; fi
    check_dpkg_lock
    echo -e "${GRAY_R}#${RESET} Installing dbus..."
    if ! "${EUS_APT_ENV[@]}" env DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install dbus &>> "${eus_dir}/logs/required.log"; then
      echo -e "${RED}#${RESET} Failed to install dbus in the first run...\\n"
      if [[ "${repo_codename}" =~ (noble|oracular|plucky|questing|resolute) ]]; then
        repo_component="main"
      elif [[ "${repo_codename}" =~ (bookworm|trixie|forky|unstable) ]]; then
        repo_component="main"
      fi
      add_repositories
      required_package="dbus"
      apt_get_install_package
    else
      echo -e "${GREEN}#${RESET} Successfully installed dbus! \\n" && sleep 2
    fi
  fi
  if ! "$(which dpkg)" -l libpam-systemd 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
    if [[ "${installing_required_package}" != 'yes' ]]; then install_required_packages; fi
    check_dpkg_lock
    echo -e "${GRAY_R}#${RESET} Installing libpam-systemd..."
    if ! "${EUS_APT_ENV[@]}" env DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install libpam-systemd &>> "${eus_dir}/logs/required.log"; then
      echo -e "${RED}#${RESET} Failed to install libpam-systemd in the first run...\\n"
      if [[ "${repo_codename}" =~ (noble|oracular|plucky|questing|resolute) ]]; then
        repo_component="main"
      elif [[ "${repo_codename}" =~ (bookworm|trixie|forky|unstable) ]]; then
        repo_component="main"
      fi
      add_repositories
      required_package="libpam-systemd"
      apt_get_install_package
    else
      echo -e "${GREEN}#${RESET} Successfully installed libpam-systemd! \\n" && sleep 2
    fi
  fi
  if ! "$(which dpkg)" -l dbus-user-session 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
    if [[ "${installing_required_package}" != 'yes' ]]; then install_required_packages; fi
    check_dpkg_lock
    echo -e "${GRAY_R}#${RESET} Installing dbus-user-session..."
    if ! "${EUS_APT_ENV[@]}" env DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install dbus-user-session &>> "${eus_dir}/logs/required.log"; then
      echo -e "${RED}#${RESET} Failed to install dbus-user-session in the first run...\\n"
      if [[ "${repo_codename}" =~ (noble|oracular|plucky|questing|resolute) ]]; then
        repo_component="main"
      elif [[ "${repo_codename}" =~ (bookworm|trixie|forky|unstable) ]]; then
        repo_component="main"
      fi
      add_repositories
      required_package="dbus-user-session"
      apt_get_install_package
    else
      echo -e "${GREEN}#${RESET} Successfully installed dbus-user-session! \\n" && sleep 2
    fi
  fi
}

repackage_deb_file() {
  eus_tmp_directory_check
  repackage_deb_file_required_package
  repackage_deb_file_temp_dir="$(mktemp -d "${repackage_deb_name}_XXXXX" --tmpdir="${eus_tmp_directory_location}")"
  cd "${repackage_deb_file_temp_dir}" || return
  echo -e "${GRAY_R}#${RESET} Downloading ${repackage_deb_name}..."
  if apt-get download "${repackage_deb_name}""${repackage_deb_version}" &>> "${eus_dir}/logs/repackage-deb-files-download.log"; then
    echo -e "${GREEN}#${RESET} Successfully downloaded ${repackage_deb_name}! \\n"
  else
    abort_reason="Failed to download ${repackage_deb_name}."
    abort
  fi
  repackage_deb_file_name="$(find "${repackage_deb_file_temp_dir}" -name "${repackage_deb_name}*" -type f | sed 's/\.deb//g')"
  repackage_deb_file_name_message="$(basename "${repackage_deb_file_name}")"
  echo -e "${GRAY_R}#${RESET} Unpacking ${repackage_deb_file_name_message}.deb..."
  if ar x "${repackage_deb_file_name}.deb" &>> "${eus_dir}/logs/repackage-deb-files.log"; then
    echo -e "${GREEN}#${RESET} Successfully unpacked ${repackage_deb_file_name_message}.deb! \\n"
  else
    abort_reason="Failed to unpack ${repackage_deb_file_name_message}.deb."
    abort
  fi
  while read -r repackage_files; do
    echo -e "${GRAY_R}#${RESET} Decompressing and recompressing $(basename "${repackage_files}")..."
    if zstd -d < "${repackage_files}" | xz > "${repackage_files//zst/xz}"; then
      echo -e "${GREEN}#${RESET} Successfully decompressed $(basename "${repackage_files}") and recompressed it to $(basename "${repackage_files}" | sed 's/zst/xz/g')! \\n"
      rm --force "${repackage_files}" &> /dev/null
    else
      abort_reason="Failed to decompress $(basename "${repackage_files}") and recompress it to $(basename "${repackage_files}" | sed 's/zst/xz/g')."
      abort
    fi
  done < <(find "${repackage_deb_file_temp_dir}" -name "*.zst" -type f)
  echo -e "${GRAY_R}#${RESET} Repacking ${repackage_deb_file_name_message}.deb to ${repackage_deb_file_name_message}_repacked.deb..."
  if ar -m -c -a sdsd "${repackage_deb_file_name}"_repacked.deb "$(find "${repackage_deb_file_temp_dir}" -type f -name "debian-binary")" "$(find "${repackage_deb_file_temp_dir}" -type f -name "control.*")" "$(find "${repackage_deb_file_temp_dir}" -type f -name "data.*")" &>> "${eus_dir}/logs/repackage-deb-files.log"; then
    echo -e "${GREEN}#${RESET} Successfully repackaged ${repackage_deb_file_name_message}.deb to ${repackage_deb_file_name_message}_repacked.deb! \\n"
  else
    abort_reason="Failed to repackage ${repackage_deb_file_name_message}.deb to ${repackage_deb_file_name_message}_repacked.deb."
    abort
  fi
  while read -r cleanup_files; do
    rm --force "${cleanup_files}" &> /dev/null
  done < <(find "${repackage_deb_file_temp_dir}" -not -name "${repackage_deb_file_name_message}_repacked.deb" -type f)
  repackage_deb_file_location="$(find "${repackage_deb_file_temp_dir}" -name "${repackage_deb_file_name_message}_repacked.deb" -type f)"
  unset repackage_deb_name
  unset repackage_deb_version
}

multiple_attempt_to_install_package() {
  check_add_mongodb_repo_variable
  if [[ "${multiple_attempt_to_install_package_task}" == 'install' ]] || [[ -z "${multiple_attempt_to_install_package_task}" ]]; then
    multiple_attempt_to_install_package_message_1="Installing"
    multiple_attempt_to_install_package_message_2="Installed"
    multiple_attempt_to_install_package_message_3="Install"
  elif [[ "${multiple_attempt_to_install_package_task}" == 'downgrade' ]]; then
    multiple_attempt_to_install_package_message_1="Downgrading"
    multiple_attempt_to_install_package_message_2="Downgraded"
    multiple_attempt_to_install_package_message_3="Downgrade"
  fi
  attempt_to_install_package_attempts="0"
  if [[ -z "${multiple_attempt_to_install_package_attempts_max}" ]]; then multiple_attempt_to_install_package_attempts_max="4"; fi
  while [[ "${attempt_to_install_package_attempts}" -le "${multiple_attempt_to_install_package_attempts_max}" ]]; do
    if [[ -n "${original_multiple_attempt_to_install_package_version_with_equal_sign}" ]]; then multiple_attempt_to_install_package_version_with_equal_sign="${original_multiple_attempt_to_install_package_version_with_equal_sign}"; fi
    if [[ "${attempt_to_install_package_attempts}" == '1' ]]; then
      attempt_message="second"
    elif [[ "${attempt_to_install_package_attempts}" == '2' ]]; then
      check_unmet_dependencies
      broken_packages_check
      attempt_recover_broken_packages
      add_apt_option_no_install_recommends="true"; get_apt_options
      attempt_message="third"
    elif [[ "${attempt_to_install_package_attempts}" == '3' ]]; then
      attempt_message="fourth"
    elif [[ "${attempt_to_install_package_attempts}" == '4' ]]; then
      attempt_message="fifth"
    fi
    if [[ "${multiple_attempt_to_install_package_name}" =~ (mongodb-mongosh-shared-openssl11|mongodb-mongosh-shared-openssl3|mongodb-org-shell|mongodb-org-tools) ]]; then
      if [[ "${multiple_attempt_to_install_package_name}" == "mongodb-mongosh-shared-openssl11" ]]; then
        if ! "$(which dpkg)" -l libssl1.1 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui" && "$(which dpkg)" -l libssl3t64 libssl3 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
          multiple_attempt_to_install_package_name="mongodb-mongosh-shared-openssl3"
        fi
      fi
      if [[ "${attempt_to_install_package_attempts}" == '1' ]]; then
        try_different_mongodb_repo="true"
      elif [[ "${attempt_to_install_package_attempts}" == '2' ]]; then
        try_http_mongodb_repo="true"
      fi
      if [[ "${ran_remove_older_mongodb_repositories}" != 'true' ]]; then ran_remove_older_mongodb_repositories="true"; remove_older_mongodb_repositories; fi
      add_mongodb_repo
      mongodb_package_libssl="${multiple_attempt_to_install_package_name}"
      mongodb_package_version_libssl="${multiple_attempt_to_install_package_version_with_equal_sign//=/}"
      libssl_installation_check
      if ! apt-cache policy "${multiple_attempt_to_install_package_name}" | tr '[:upper:]' '[:lower:]' | sed '1,/version table/d' | sed -e 's/500//g' -e 's/100//g' -e '/http/d' -e '/var/d' -e 's/*//g' -e 's/ //g' | grep -ioq "${multiple_attempt_to_install_package_version_with_equal_sign//=/}"; then
        attempt_new_version="$(echo "${multiple_attempt_to_install_package_version_with_equal_sign//=/}" | cut -d'.' -f1,2)"
        located_new_version="$(apt-cache policy "${multiple_attempt_to_install_package_name}" | tr '[:upper:]' '[:lower:]' | sed '1,/version table/d' | sed -e 's/500//g' -e 's/100//g' -e '/http/d' -e '/var/d' -e 's/*//g' -e 's/ //g' | grep -i "${attempt_new_version}" | head -n1)"
        if [[ "${located_new_version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then multiple_attempt_to_install_package_version_with_equal_sign="=${located_new_version}"; else original_multiple_attempt_to_install_package_version_with_equal_sign="${multiple_attempt_to_install_package_version_with_equal_sign}"; unset multiple_attempt_to_install_package_version_with_equal_sign; fi
      fi
    fi
    check_dpkg_lock
    if [[ "${attempt_to_install_package_attempts}" -ge '1' ]]; then
      attempt_message_1="for the ${attempt_message} time"
      attempt_message_2="in the ${attempt_message} run"
      echo -e "${GRAY_R}#${RESET} Attempting to $(echo "${multiple_attempt_to_install_package_message_3}"| tr '[:upper:]' '[:lower:]') ${multiple_attempt_to_install_package_name} ${attempt_message_1}..."
    else
      echo -e "${GRAY_R}#${RESET} ${multiple_attempt_to_install_package_message_1} ${multiple_attempt_to_install_package_name}..."
    fi
    if ! "${EUS_APT_ENV[@]}" env DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_downgrade_option[@]}" "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "${multiple_attempt_to_install_package_name}""${multiple_attempt_to_install_package_version_with_equal_sign}" &>> "${eus_dir}/logs/${multiple_attempt_to_install_package_log}.log"; then
      if tail -n20 "${eus_dir}/logs/${multiple_attempt_to_install_package_log}.log" | grep -iq "uses unknown compression for member .*zst"; then
        if [[ "${attempt_to_install_package_attempts}" -ge '1' ]]; then
          echo -e "${RED}#${RESET} Failed to $(echo "${multiple_attempt_to_install_package_message_3}"| tr '[:upper:]' '[:lower:]') ${multiple_attempt_to_install_package_name} ${attempt_message_2}...\\n"
        else
          echo -e "${RED}#${RESET} Failed to $(echo "${multiple_attempt_to_install_package_message_3}"| tr '[:upper:]' '[:lower:]') ${multiple_attempt_to_install_package_name}...\\n"
        fi
        repackage_deb_name="${multiple_attempt_to_install_package_name}"
        repackage_deb_version="${multiple_attempt_to_install_package_version_with_equal_sign}"
        repackage_deb_file
        check_dpkg_lock
        if [[ "${attempt_to_install_package_attempts}" -ge '1' ]]; then
          echo -e "${GRAY_R}#${RESET} Attempting to $(echo "${multiple_attempt_to_install_package_message_3}"| tr '[:upper:]' '[:lower:]') ${multiple_attempt_to_install_package_name} ${attempt_message_1}..."
        else
          echo -e "${GRAY_R}#${RESET} ${multiple_attempt_to_install_package_message_1} ${multiple_attempt_to_install_package_name}..."
        fi
        if ! "${EUS_APT_ENV[@]}" env DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_downgrade_option[@]}" "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "${repackage_deb_file_location}" &>> "${eus_dir}/logs/${multiple_attempt_to_install_package_log}.log"; then
          if [[ "${attempt_to_install_package_attempts}" -ge '1' ]]; then
            echo -e "${RED}#${RESET} Failed to $(echo "${multiple_attempt_to_install_package_message_3}"| tr '[:upper:]' '[:lower:]') ${multiple_attempt_to_install_package_name} ${attempt_message_2}...\\n"
          else
            echo -e "${RED}#${RESET} Failed to $(echo "${multiple_attempt_to_install_package_message_3}"| tr '[:upper:]' '[:lower:]') ${multiple_attempt_to_install_package_name}...\\n"
          fi
        else
          if [[ "${attempt_to_install_package_attempts}" -ge '1' ]]; then
            echo -e "${GREEN}#${RESET} Successfully $(echo "${multiple_attempt_to_install_package_message_2}"| tr '[:upper:]' '[:lower:]') ${multiple_attempt_to_install_package_name} ${attempt_message_2}! \\n"
          else
            echo -e "${GREEN}#${RESET} Successfully $(echo "${multiple_attempt_to_install_package_message_2}"| tr '[:upper:]' '[:lower:]') ${multiple_attempt_to_install_package_name}! \\n"
          fi
        fi
      else
        if [[ "${attempt_to_install_package_attempts}" -ge '1' ]]; then
          echo -e "${RED}#${RESET} Failed to $(echo "${multiple_attempt_to_install_package_message_3}"| tr '[:upper:]' '[:lower:]') ${multiple_attempt_to_install_package_name} ${attempt_message_2}...\\n"
        else
          echo -e "${RED}#${RESET} Failed to $(echo "${multiple_attempt_to_install_package_message_3}"| tr '[:upper:]' '[:lower:]') ${multiple_attempt_to_install_package_name}...\\n"
        fi
      fi
    else
      if [[ "${attempt_to_install_package_attempts}" -ge '1' ]]; then
        echo -e "${GREEN}#${RESET} Successfully $(echo "${multiple_attempt_to_install_package_message_2}"| tr '[:upper:]' '[:lower:]') ${multiple_attempt_to_install_package_name} ${attempt_message_2}...\\n"
      else
        echo -e "${GREEN}#${RESET} Successfully $(echo "${multiple_attempt_to_install_package_message_2}"| tr '[:upper:]' '[:lower:]') ${multiple_attempt_to_install_package_name}...\\n"
      fi
      break
    fi
    abort_reason="Failed to $(echo "${multiple_attempt_to_install_package_message_3}"| tr '[:upper:]' '[:lower:]') ${multiple_attempt_to_install_package_name} ${attempt_message_2}."
    abort_function_skip_reason="skip"
    if [[ "${attempt_to_install_package_attempts}" -ge "${multiple_attempt_to_install_package_attempts_max}" ]]; then abort; fi
    ((attempt_to_install_package_attempts=attempt_to_install_package_attempts+1))
    sleep 2
  done
  unset multiple_attempt_to_install_package_log
  unset multiple_attempt_to_install_package_task
  unset multiple_attempt_to_install_package_attempts_max
  unset multiple_attempt_to_install_package_name
  unset multiple_attempt_to_install_package_version_with_equal_sign
  unset original_multiple_attempt_to_install_package_version_with_equal_sign
  reverse_check_add_mongodb_repo_variable
  get_apt_options
}

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                            Variables                                                                                            #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################


#
system_memory="$(awk '/MemTotal/ {printf( "%.0f\n", $2 / 1024 / 1024)}' /proc/meminfo)"
system_swap="$(awk '/SwapTotal/ {printf( "%.0f\n", $2 / 1024 / 1024)}' /proc/meminfo)"
system_free_disk_space="$(df -k / | awk '{print $4}' | tail -n1)"
#
abort_function_skip_reason="false"
remove_apt_options="false"
#
server_ip_address="$(ip addr | grep -A8 -m1 MULTICAST | grep -m1 inet | cut -d' ' -f6 | cut -d'/' -f1)"
if [[ -z "${server_ip_address}" ]]; then server_ip_address="$(hostname -I | head -n 1 | awk '{ print $NF; }')"; fi
public_server_address="$(curl "${curl_argument[@]}" https://api.glennr.nl/api/geo 2> /dev/null | jq -r '."address"' 2> /dev/null)"
network_install_broken_override_check() {
  # Override broken_unifi_install_version if script version is newer.
  if [[ -n "${broken_unifi_install_version}" ]]; then
    script_unifi_version="$(grep -i "# Application version" "${script_location}" | head -n 1 | cut -d'|' -f2 | sed 's/ //g' | cut -d'-' -f1)"
    if [[ "$(echo "${script_unifi_version}" | cut -d'.' -f1)" -gt "${broken_unifi_install_version_first_digit}" ]]; then
      override_broken_unifi_version="true"
    elif [[ "$(echo "${script_unifi_version}" | cut -d'.' -f1)" == "${broken_unifi_install_version_first_digit}" && "$(echo "${script_unifi_version}" | cut -d'.' -f2)" -gt "${broken_unifi_install_version_second_digit}" ]]; then
      override_broken_unifi_version="true"
    elif [[ "$(echo "${script_unifi_version}" | cut -d'.' -f1)" == "${broken_unifi_install_version_first_digit}" && "$(echo "${script_unifi_version}" | cut -d'.' -f2)" == "${broken_unifi_install_version_second_digit}" && "$(echo "${script_unifi_version}" | cut -d'.' -f3)" == "${broken_unifi_install_version_third_digit}" ]]; then
      override_broken_unifi_version="true"
    fi
  fi
}
#
network_install_set_unifi_variables() {
  if [[ "${unifi_network_application_downloaded}" == 'true' ]]; then
    if [[ -n "${custom_download_url}" ]]; then
      if [[ -z "${unifi_clean}" ]]; then unifi_clean="$(echo "${custom_download_url}" | grep -io "5.*\\|6.*\\|7.*\\|8.*\\|9.*\\|10.*" | cut -d'-' -f1 | cut -d'/' -f1)"; fi
      #unifi_secret="$(echo "${custom_download_url}" | grep -io "5.*\\|6.*\\|7.*\\|8.*\\|9.*\\|10.*" | cut -d'/' -f1)"
    elif [[ -n "${broken_unifi_install_version}" ]]; then
      unifi_clean="${broken_unifi_install_version}"
    fi
  else
    if [[ -n "${broken_unifi_install_version}" && "${override_broken_unifi_version}" != 'true' ]]; then
      unifi_clean="${broken_unifi_install_version}"
    else
      unifi_clean="$(grep -i "# Application version" "${script_location}" | head -n 1 | cut -d'|' -f2 | sed 's/ //g' | cut -d'-' -f1)"
      #unifi_secret="$(grep -i "# Application version" "${script_location}" | head -n 1 | cut -d'|' -f2 | sed 's/ //g')"
      unifi_repo_version="$(grep -i "# Debian repo version" "${script_location}" | head -n 1 | cut -d'|' -f2 | sed 's/ //g')"
    fi
  fi
}
uos_server_install_get_variables() {
  uos_version="$(grep -i "# UOS Server version" "${script_location}" | head -n 1 | cut -d'|' -f2 | sed 's/ //g' | cut -d'-' -f1)"
}
get_unifi_version() {
  first_digit_unifi="$(echo "${unifi_clean}" | cut -d'.' -f1)"
  second_digit_unifi="$(echo "${unifi_clean}" | cut -d'.' -f2)"
  third_digit_unifi="$(echo "${unifi_clean}" | cut -d'.' -f3)"
}
uos_server_install_set_variables() {
  uos_server_web_port="$(grep -sE '^WEB_PORT=' /var/lib/uosserver/server.conf 2> /dev/null | cut -d= -f2)"
  uos_server_web_port="${uos_server_web_port:-11443}"
  uos_server_https_legacy_port="8443"
  uos_server_http_captive_portal_port="8880"
  uos_server_https_captive_portal_port="8444"
  uos_server_captive_portal_redirector_1_port="8881"
  uos_server_captive_portal_redirector_2_port="8882"
  uos_server_device_inform_port="8080"
  uos_server_remote_logger_port="5514"
  uos_server_stun_port="3478"
  uos_server_mobile_speedtest_port="6789"
  uos_server_discovery_1_port="10003"
  uos_server_discovery_2_port="11002"
  uos_server_rabbitmq_port="5671"
  uos_server_identity_hub_port="9543"
  uos_server_management_wrapper_port="11084"
}
#
update_eus_db_unifi_network_version() {
  if [[ -n "$(command -v jq)" && -e "${eus_dir}/db/db.json" ]]; then
    if [[ "$(dpkg-query --showformat='${version}' --show jq 2> /dev/null | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
      jq '.scripts."'"${script_name}"'" |= if .["install-version"] | index("'"${unifi_clean}"'") | not then .["install-version"] += ["'"${unifi_clean}"'"] else . end' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
    else
      jq --arg script_name "$script_name" --arg unifi_clean "$unifi_clean" '.scripts[$script_name] |= (.["install-version"] as $versions | if ($versions | map(select(. == $unifi_clean)) | length) == 0 then .["install-version"] += [$unifi_clean] else . end)' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
    fi
    eus_database_move
  fi
}
#
network_install_gen1_cloudkey_check() {
  if [[ "${cloudkey_generation}" == "1" ]]; then
    if [[ "${first_digit_unifi}" -gt '7' ]] || [[ "${first_digit_unifi}" == '7' && "${second_digit_unifi}" -ge '3' ]]; then
      header_red
      echo -e "${GRAY_R}#${RESET} UniFi Network Application ${unifi_clean} is not supported on your Gen1 UniFi Cloudkey (UC-CK)."
      echo -e "${GRAY_R}#${RESET} The latest supported version on your Cloudkey is $(curl "${curl_argument[@]}" "https://api.glennr.nl/api/latest-application-release?app=network&version=7.2" 2> /dev/null | jq -r '.latest_version' 2> /dev/null) and older.. \\n\\n"
      echo -e "${GRAY_R}#${RESET} Consider upgrading to a Gen2 Cloudkey:"
      echo -e "${GRAY_R}#${RESET} UniFi Cloud Key Gen2       | https://store.ui.com/products/unifi-cloud-key-gen2"
      echo -e "${GRAY_R}#${RESET} UniFi Cloud Key Gen2 Plus  | https://store.ui.com/products/unifi-cloudkey-gen2-plus\\n\\n"
      author
      exit 0
    fi
  fi
}
#
network_install_32_bit_check() {
  if [[ "${first_digit_unifi}" -gt '7' ]] || [[ "${first_digit_unifi}" == '7' && "${second_digit_unifi}" -ge '5' ]]; then
    if [[ "$(getconf LONG_BIT)" == '32' ]]; then
      header_red
      if [[ "${first_digit_mongodb_version_installed}" -le "2" && "${second_digit_mongodb_version_installed}" -le "5" ]]; then unifi_latest_supported_version="7.3"; else unifi_latest_supported_version="7.4"; fi
      echo -e "${GRAY_R}#${RESET} Your 32-bit system/OS is no longer supported by UniFi Network Application ${unifi_clean}!"
      echo -e "${GRAY_R}#${RESET} The latest supported version on your system/OS is $(curl "${curl_argument[@]}" "https://api.glennr.nl/api/latest-application-release?app=network&version=${unifi_latest_supported_version}" 2> /dev/null | jq -r '.latest_version' 2> /dev/null) and older..."
      echo -e "${GRAY_R}#${RESET} Consider upgrading to a 64-bit system/OS!\\n\\n"
      author
      exit 0
    fi
  fi
}
#
network_install_set_required_package_versions() {
  mongo_version_max="36"
  mongo_version_max_with_dot="3.6"
  unifi_mongo_version_max="36"
  add_mongodb_36_repo="true"
  #mongo_version_not_supported="4.0"
  # MongoDB Version override
  if [[ "${first_digit_unifi}" -le '5' && "${second_digit_unifi}" -le '13' ]]; then
    mongo_version_max="34"
    mongo_version_max_with_dot="3.4"
    unifi_mongo_version_max="34"
    add_mongodb_34_repo="true"
    unset add_mongodb_36_repo
    #mongo_version_not_supported="3.6"
  fi
  if [[ "${first_digit_unifi}" == '5' && "${second_digit_unifi}" == '13' && "${third_digit_unifi}" -gt '10' ]]; then
    mongo_version_max="36"
    mongo_version_max_with_dot="3.6"
    unifi_mongo_version_max="36"
    add_mongodb_36_repo="true"
    #mongo_version_not_supported="4.0"
  fi
  # JAVA/MongoDB Version override
  if [[ "${first_digit_unifi}" -gt '9' ]] || [[ "${first_digit_unifi}" == '9' && "${second_digit_unifi}" -ge "0" ]]; then
    mongo_version_max="80"
    mongo_version_max_with_dot="8.0"
    unifi_mongo_version_max="80"
    add_mongodb_80_repo="true"
    unset add_mongodb_70_repo
    unset add_mongodb_44_repo
    unset add_mongodb_36_repo
    unset add_mongodb_34_repo
    #mongo_version_not_supported="7.1"
  elif [[ "${first_digit_unifi}" -gt '8' ]] || [[ "${first_digit_unifi}" == '8' && "${second_digit_unifi}" -ge "1" ]]; then
    mongo_version_max="70"
    mongo_version_max_with_dot="7.0"
    unifi_mongo_version_max="70"
    add_mongodb_70_repo="true"
    unset add_mongodb_44_repo
    unset add_mongodb_36_repo
    unset add_mongodb_34_repo
    #mongo_version_not_supported="7.1"
  elif [[ "${first_digit_unifi}" -gt '7' ]] || [[ "${first_digit_unifi}" == '7' && "${second_digit_unifi}" -ge "5" ]]; then
    mongo_version_max="44"
    mongo_version_max_with_dot="4.4"
    unifi_mongo_version_max="44"
    add_mongodb_44_repo="true"
    unset add_mongodb_36_repo
    unset add_mongodb_34_repo
    #mongo_version_not_supported="4.5"
  fi
}

java_required_variables() {
  if [[ "${first_digit_unifi}" -gt '10' ]] || [[ "${first_digit_unifi}" == '10' && "${second_digit_unifi}" -ge "1" ]]; then
    required_java_version="openjdk-25"
    required_java_version_short="25"
  elif [[ "${first_digit_unifi}" -gt '9' ]] || [[ "${first_digit_unifi}" == '9' && "${second_digit_unifi}" -ge "0" ]]; then
    if apt-cache search --names-only "openjdk-21-jre-headless|temurin-21-jre" | awk '{print $1}' | grep -ioq "openjdk-21-jre-headless\\|temurin-21-jre"; then
      required_java_version="openjdk-21"
      required_java_version_short="21"
    else
      required_java_version="openjdk-17"
      required_java_version_short="17"
    fi
  elif [[ "${first_digit_unifi}" -gt '7' ]] || [[ "${first_digit_unifi}" == '7' && "${second_digit_unifi}" -ge "5" ]]; then
    required_java_version="openjdk-17"
    required_java_version_short="17"
  elif [[ "${first_digit_unifi}" == '7' && "${second_digit_unifi}" =~ (3|4) ]]; then
    required_java_version="openjdk-11"
    required_java_version_short="11"
  else
    required_java_version="openjdk-8"
    required_java_version_short="8"
  fi
  # Failed to instantiate [ch.qos.logback.classic.LoggerContext] issue with temurin-21-jre 21.0.7.0.0+6-0
  # Could not find or load main class com.ubnt.ace.Launcher issue with openjdk-21-jre-headless 21.0.7
  if [[ "${architecture}" == "arm64" && "${required_java_version_short}" == "21" ]]; then
    cpu_model_name="$(lscpu | tr '[:upper:]' '[:lower:]' | grep -i '^model name' | cut -f 2 -d ":" | awk '{$1=$1}1')"
    if [[ -z "${cpu_model_name}" ]]; then cpu_model_name="$(lscpu | tr '[:upper:]' '[:lower:]' | sed -n 's/^model name:[[:space:]]*//p')"; fi
    if [[ "${cpu_model_name}" =~ (cortex-a53) ]]; then
      if "$(which dpkg)" -l | grep "^ii\\|^hi" | grep -iq "temurin-21-jre"; then
        temurin_21_version="$(dpkg-query --showformat='${version}' --show temurin-21-jre 2> /dev/null | sed -e 's/.*://' -e 's/[^0-9.]//g' -e 's/\.//g')"
      else
        temurin_21_version="$(apt-cache policy temurin-21-jre 2> /dev/null | tr '[:upper:]' '[:lower:]' | grep "candidate:" | cut -d':' -f2 | sed -e 's/ //g' -e 's/.*://' -e 's/[^0-9.]//g' -e 's/\.//g')"
      fi
      temurin_21_candidate_version="$(apt-cache policy temurin-21-jre 2> /dev/null | tr '[:upper:]' '[:lower:]' | grep "candidate:" | cut -d':' -f2 | sed -e 's/ //g' -e 's/.*://' -e 's/[^0-9.]//g' -e 's/\.//g')"
      if "$(which dpkg)" -l | grep "^ii\\|^hi" | grep -iq "openjdk-21-jre-headless"; then
        openjdk_21_version="$(dpkg-query --showformat='${version}' --show openjdk-21-jre-headless 2> /dev/null | sed -e 's/+.*//g' -e 's/.*://' -e 's/[^0-9.]//g' -e 's/\.//g')"
      else
        openjdk_21_version="$(apt-cache policy openjdk-21-jre-headless 2> /dev/null | tr '[:upper:]' '[:lower:]' | grep "candidate:" | cut -d':' -f2 | sed -e 's/ //g' -e 's/+.*//g' -e 's/.*://' -e 's/[^0-9.]//g' -e 's/\.//g')"
      fi
      openjdk_21_candidate_version="$(apt-cache policy openjdk-21-jre-headless 2> /dev/null | tr '[:upper:]' '[:lower:]' | grep "candidate:" | cut -d':' -f2 | sed -e 's/ //g' -e 's/+.*//g' -e 's/.*://' -e 's/[^0-9.]//g' -e 's/\.//g')"
      if [[ "${temurin_21_version}" =~ (21070060) ]] || [[ "${temurin_21_candidate_version}" =~ (21070060) ]] || [[ "${openjdk_21_version}" =~ (2107) ]] || [[ "${openjdk_21_candidate_version}" =~ (2107) ]]; then
        required_java_version="openjdk-17"
        required_java_version_short="17"
      fi
    fi
  fi
}

# Stick to 4.4 if cpu doesn't report avx support.
mongodb_avx_support_check() {
  if [[ "${mongo_version_max}" =~ (44|50|60|70|80) && "${unifi_core_system}" != 'true' ]]; then
    cpu_model_name="$(lscpu | tr '[:upper:]' '[:lower:]' | grep -i '^model name' | cut -f 2 -d ":" | awk '{$1=$1}1')"
    if [[ -z "${cpu_model_name}" ]]; then cpu_model_name="$(lscpu | tr '[:upper:]' '[:lower:]' | sed -n 's/^model name:[[:space:]]*//p')"; fi
    if [[ "${architecture}" == "arm64" && -n "${cpu_model_name}" ]]; then
      if grep -iqs "numa=fake\\|system_heap" /proc/cmdline; then memory_allocation_modifications="true"; fi
      cpu_model_regex="^(cortex-a55|cortex-a65|cortex-a65ae|cortex-a75|cortex-a76|cortex-a77|cortex-a78|cortex-x1|cortex-x2|cortex-x3|cortex-x4|neoverse-n1|neoverse-n2|neoverse-n3|neoverse-e1|neoverse-e2|neoverse-v1|neoverse-v2|neoverse-v3|cortex-a510|cortex-a520|cortex-a715|cortex-a720)$"
      if ! [[ "${cpu_model_name}" =~ ${cpu_model_regex} ]] || [[ "${memory_allocation_modifications}" == 'true' ]]; then
        if [[ "${mongo_version_max}" =~ (50|60|70|80) ]]; then
          while true; do
            if "$(which dpkg)" -l | grep "^ii\\|^hi" | grep -iq "mongod-armv8" || [[ "${script_option_skip}" == 'true' ]] || [[ "${glennr_compiled_mongod}" == 'true' ]]; then
              echo -e "$(date +%F-%T.%6N) | Automatically answered \"YES\" to the Glenn R. MongoDB Compiled question." &>> "${eus_dir}/logs/avx-questionnaire.log"
              mongod_armv8_installed="true"
              yes_no="y"
            else
              echo -e "${GRAY_R}----${RESET}\\n"
              if [[ "${memory_allocation_modifications}" == 'true' ]]; then
                echo -e "${YELLOW}#${RESET} The script detected system modifications that might affect memory allocation, which\\n${YELLOW}#${RESET} could result in issues with the official MongoDB package..."
              else
                echo -e "${YELLOW}#${RESET} Your CPU is no longer officially supported by MongoDB themselves..."
              fi
              read -rp $'\033[39m#\033[0m Would you like to use mongod compiled from MongoDB source code specifically for your CPU by Glenn R.? (Y/n) ' yes_no
            fi
            case "$yes_no" in
                [Yy]*|"")
                   echo -e "$(date +%F-%T.%6N) | Answered \"${yes_no}\" to the Glenn R. MongoDB Compiled question." &>> "${eus_dir}/logs/avx-questionnaire.log"
                   if [[ "${mongo_version_max}" == "80" ]]; then add_mongod_80_repo="true"; elif [[ "${mongo_version_max}" == "70" ]]; then add_mongod_70_repo="true"; elif [[ "${mongo_version_max}" == "60" ]]; then add_mongod_60_repo="true"; elif [[ "${mongo_version_max}" == "50" ]]; then add_mongod_50_repo="true"; fi
                   glennr_compiled_mongod="true"
                   if [[ "${broken_unifi_install}" == 'true' ]]; then broken_glennr_compiled_mongod="true"; fi
                   cleanup_unifi_repos
                   if [[ "${mongod_armv8_installed}" != 'true' ]]; then echo ""; fi
                   break;;
                [Nn]*)
                   echo -e "$(date +%F-%T.%6N) | Answered \"${yes_no}\" to the Glenn R. MongoDB Compiled question." &>> "${eus_dir}/logs/avx-questionnaire.log"
                   unset add_mongodb_50_repo
                   unset add_mongodb_60_repo
                   unset add_mongodb_70_repo
                   unset add_mongodb_80_repo
                   add_mongodb_44_repo="true"
                   mongo_version_max="44"
                   mongo_version_max_with_dot="4.4"
                   mongo_version_locked="4.4.18"
                   echo ""
                   break;;
                *)
                   echo -e "$(date +%F-%T.%6N) | Invalid input \"${yes_no}\", repeating the question..." &>> "${eus_dir}/logs/avx-questionnaire.log"
                   echo -e "\\n${RED}#${RESET} Invalid input, please answer Yes or No (y/n)...\\n"
                   sleep 3;;
            esac
            unset yes_no
          done
        else
          echo -e "$(date +%F-%T.%6N) | Did not ask the Glenn R. MongoDB Compiled question." &>> "${eus_dir}/logs/avx-questionnaire.log"
          unset add_mongodb_50_repo
          unset add_mongodb_60_repo
          unset add_mongodb_70_repo
          unset add_mongodb_80_repo
          add_mongodb_44_repo="true"
          mongo_version_max="44"
          mongo_version_max_with_dot="4.4"
          mongo_version_locked="4.4.18"
        fi
      fi
    else
      if [[ "${mongo_version_max}" =~ (50|60|70|80) && "${glennr_mongod_compatible}" == "true" && "${official_mongodb_compatible}" != 'true' ]]; then
        while true; do
          if "$(which dpkg)" -l | grep "^ii\\|^hi" | grep -iq "mongod-amd64" || [[ "${script_option_skip}" == 'true' ]] || [[ "${glennr_compiled_mongod}" == 'true' ]]; then
            echo -e "$(date +%F-%T.%6N) | Automatically answered \"YES\" to the Glenn R. MongoDB Compiled question." &>> "${eus_dir}/logs/avx-questionnaire.log"
            mongod_amd64_installed="true"
            yes_no="y"
          else
            echo -e "${GRAY_R}----${RESET}\\n"
            echo -e "${YELLOW}#${RESET} Your CPU is no longer officially supported by MongoDB themselves..."
            read -rp $'\033[39m#\033[0m Would you like to use mongod compiled from MongoDB source code specifically for your CPU by Glenn R.? (Y/n) ' yes_no
          fi
          case "$yes_no" in
              [Yy]*|"")
                 echo -e "$(date +%F-%T.%6N) | Answered \"${yes_no}\" to the Glenn R. MongoDB Compiled question." &>> "${eus_dir}/logs/avx-questionnaire.log"
                 if [[ "${mongo_version_max}" == "80" ]]; then add_mongod_80_repo="true"; elif [[ "${mongo_version_max}" == "70" ]]; then add_mongod_70_repo="true"; elif [[ "${mongo_version_max}" == "60" ]]; then add_mongod_60_repo="true"; elif [[ "${mongo_version_max}" == "50" ]]; then add_mongod_50_repo="true"; fi
                 glennr_compiled_mongod="true"
                   if [[ "${broken_unifi_install}" == 'true' ]]; then broken_glennr_compiled_mongod="true"; fi
                 cleanup_unifi_repos
                 if [[ "${mongod_amd64_installed}" != 'true' ]]; then echo ""; fi
                 break;;
              [Nn]*)
                 echo -e "$(date +%F-%T.%6N) | Answered \"${yes_no}\" to the Glenn R. MongoDB Compiled question." &>> "${eus_dir}/logs/avx-questionnaire.log"
                 unset add_mongodb_50_repo
                 unset add_mongodb_60_repo
                 unset add_mongodb_70_repo
                 unset add_mongodb_80_repo
                 add_mongodb_44_repo="true"
                 mongo_version_max="44"
                 mongo_version_max_with_dot="4.4"
                 mongo_version_locked="4.4.18"
                 echo ""
                 break;;
              *)
                 echo -e "$(date +%F-%T.%6N) | Invalid input \"${yes_no}\", repeating the question..." &>> "${eus_dir}/logs/avx-questionnaire.log"
                 echo -e "\\n${RED}#${RESET} Invalid input, please answer Yes or No (y/n)...\\n"
                 sleep 3;;
          esac
          unset yes_no
        done
      else
        echo -e "$(date +%F-%T.%6N) | Did not ask the Glenn R. MongoDB Compiled question." &>> "${eus_dir}/logs/avx-questionnaire.log"
        if [[ "${avx_compatible}" != 'true' ]]; then
          echo -e "$(date +%F-%T.%6N) | System is not AVX compatible." &>> "${eus_dir}/logs/avx-questionnaire.log"
          unset add_mongodb_50_repo
          unset add_mongodb_60_repo
          unset add_mongodb_70_repo
          unset add_mongodb_80_repo
          add_mongodb_44_repo="true"
          mongo_version_max="44"
          mongo_version_max_with_dot="4.4"
          mongo_version_locked="4.4.18"
        fi
      fi
    fi
    if [[ "$(dpkg-query --showformat='${version}' --show jq 2> /dev/null | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
      jq '.scripts["'"$script_name"'"].tasks += {"mongodb-avx-check ('"$(date +%s)"')": [.scripts["'"$script_name"'"].tasks["mongodb-avx-check ('"$(date +%s)"')"][0] + {"architecture":"'"${architecture}"'","CPU":"'"${cpu_model_name}"'","add_mongodb_44_repo":"'"${add_mongodb_44_repo}"'","mongo_version_max":"'"${mongo_version_max}"'","mongo_version_max_with_dot":"'"${mongo_version_max_with_dot}"'","mongo_version_locked":"'"${mongo_version_locked}"'","Official MongoDB Compatible":"'"${official_mongodb_compatible}"'","Glenn R. MongoDB":"'"${glennr_compiled_mongod}"'","Glenn R. MongoDB Compatible":"'"${glennr_mongod_compatible}"'","Memory Allocation Modifications":"'"${memory_allocation_modifications}"'"}]}' "${eus_dir}/db/db.json" > "/tmp/EUS/db-avx-debug.json"
    else
      jq --arg script_name "$script_name" --arg date_key "$(date +%s)" --arg cpu_model_name "$cpu_model_name" --arg architecture "$architecture" --arg add_mongodb_44_repo "$add_mongodb_44_repo" --arg mongo_version_max "$mongo_version_max" --arg mongo_version_max_with_dot "$mongo_version_max_with_dot" --arg mongo_version_locked "$mongo_version_locked" --arg official_mongodb_compatible "$official_mongodb_compatible" --arg glennr_compiled_mongod "$glennr_compiled_mongod" --arg glennr_mongod_compatible "$glennr_mongod_compatible" --arg memory_allocation_modifications "$memory_allocation_modifications" '.scripts[$script_name].tasks += {("mongodb-avx-check (" + $date_key + ")"): ((.scripts[$script_name].tasks["mongodb-avx-check (" + $date_key + ")"] // []) + [{"architecture": $architecture, "CPU": $cpu_model_name, "add_mongodb_44_repo": $add_mongodb_44_repo, "mongo_version_max": $mongo_version_max, "mongo_version_max_with_dot": $mongo_version_max_with_dot, "mongo_version_locked": $mongo_version_locked, "Official MongoDB Compatible": $official_mongodb_compatible, "Glenn R. MongoDB": $glennr_compiled_mongod, "Glenn R. MongoDB Compatible": $glennr_mongod_compatible, "Memory Allocation Modifications": $memory_allocation_modifications}])}' "${eus_dir}/db/db.json" > "/tmp/EUS/db-avx-debug.json"
    fi
  fi
}

mongo_command() {
  mongo_command_server_version="$("$(which dpkg)" -l | grep "^ii\\|^hi" | grep -E "(mongodb-server|mongodb-org-server|mongod-armv8|mongod-amd64)[[:space:]]" | awk '{print $3}' | sed -e 's/.*://' -e 's/-.*//' -e 's/+.*//' -e 's/\.//g')"
  if "$(which dpkg)" -l mongodb-mongosh-shared-openssl3 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui" && [[ "${mongo_command_server_version::2}" -ge "40" ]]; then
    mongocommand="mongosh"
  elif "$(which dpkg)" -l mongodb-mongosh-shared-openssl11 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui" && [[ "${mongo_command_server_version::2}" -ge "40" ]]; then
    mongocommand="mongosh"
  elif "$(which dpkg)" -l mongodb-mongosh 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui" && [[ "${mongo_command_server_version::2}" -ge "40" ]]; then
    mongocommand="mongosh"
  elif "$(which dpkg)" -l mongosh 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui" && [[ "${mongo_command_server_version::2}" -ge "40" ]]; then
    mongocommand="mongosh"
  else
    mongocommand="mongo"
  fi
}

prevent_mongodb_org_server_install() {
  if ! [[ -e "/etc/apt/preferences.d/eus_prevent_install_mongodb-org-server" ]]; then
    tee /etc/apt/preferences.d/eus_prevent_install_mongodb-org-server &>/dev/null << EOF
Package: mongodb-org-server
Pin: release *
Pin-Priority: -1
EOF
  fi
}

remove_older_mongodb_repositories() {
  echo -e "${GRAY_R}#${RESET} Checking for older MongoDB repository entries..."
  local found_entries="false"
  if [[ -e "/etc/apt/sources.list" ]] && grep -q "mongo" /etc/apt/sources.list; then
    if [[ "${remove_older_mongodb_repositories_message_1}" != 'true' ]]; then remove_older_mongodb_repositories_message_1="true"; echo -ne "${GRAY_R}#${RESET} Removing old repository entries for MongoDB..."; fi
    sed -i 's|^\(.*mongo.*\)|# \1|' /etc/apt/sources.list
    found_entries="true"
  fi
  while read -r file; do
    if [[ "${remove_older_mongodb_repositories_message_1}" != 'true' ]]; then remove_older_mongodb_repositories_message_1="true"; echo -ne "${GRAY_R}#${RESET} Removing old repository entries for MongoDB..."; fi
    if [[ "${file##*.}" == "sources" ]]; then
      entry_block_start_line="$(awk '{ lines[NR] = $0 } END { for (i = NR; i >= 1; i--) if (lines[i] ~ /mongo/) { for (j = i - 1; j >= 1; j--) if (lines[j] != "" && lines[j] !~ /^#/) { print j; exit } } }' "${file}")"
      entry_block_end_line="$(awk -v start_line="${entry_block_start_line}" '{ lines[NR] = $0 } END { for (k = start_line + 1; k <= NR; k++) if (lines[k] == "") { print k - 1; exit } print NR }' "${file}")"
      if [[ -z "${entry_block_end_line}" ]]; then entry_block_end_line="${entry_block_start_line}"; fi
      sed -i "${entry_block_start_line},${entry_block_end_line}s/^\([^#]\)/# \1/" "${file}" &>/dev/null
    elif [[ "${file##*.}" == "list" ]]; then
      sed -i 's|^\([^#]*mongo.*\)|# \1|' "${file}" 2> /dev/null
    fi
    if ! grep -qE '^\s*[^#]' "${file}"; then rm -f "${file}"; fi
    found_entries="true"
  done < <(find /etc/apt/sources.list.d/ \( -name "*.list" -o -name "*.sources" \) -exec grep -sril "^[^#]*mongo" {} +)
  if [[ "${found_entries}" == "true" ]]; then
    echo -e "\\r${GREEN}#${RESET} Successfully removed all older MongoDB repository entries! \\n"
  else
    echo -e "\\r${YELLOW}#${RESET} There were no older MongoDB Repository entries... \\n"
  fi
  unset remove_older_mongodb_repositories_message_1
}

remove_older_adoptium_repositories() {
  echo -e "${GRAY_R}#${RESET} Checking for older Adoptium repository entries..."
  local found_entries="false"
  if [[ -e "/etc/apt/sources.list" ]] && grep -q "packages.adoptium.net" /etc/apt/sources.list; then
    if [[ "${remove_older_adoptium_repositories_message_1}" != 'true' ]]; then remove_older_adoptium_repositories_message_1="true"; echo -ne "${GRAY_R}#${RESET} Removing old repository entries for Adoptium..."; fi
    sed -i 's|^\(.*packages.adoptium.net.*\)|# \1|' /etc/apt/sources.list
    found_entries="true"
  fi
  while read -r file; do
    if [[ "${remove_older_adoptium_repositories_message_1}" != 'true' ]]; then remove_older_adoptium_repositories_message_1="true"; echo -ne "${GRAY_R}#${RESET} Removing old repository entries for Adoptium..."; fi
    if [[ "${file##*.}" == "sources" ]]; then
      entry_block_start_line="$(awk '{ lines[NR] = $0 } END { for (i = NR; i >= 1; i--) if (lines[i] ~ /packages.adoptium.net/) { for (j = i - 1; j >= 1; j--) if (lines[j] != "" && lines[j] !~ /^#/) { print j; exit } } }' "${file}")"
      entry_block_end_line="$(awk -v start_line="${entry_block_start_line}" '{ lines[NR] = $0 } END { for (k = start_line + 1; k <= NR; k++) if (lines[k] == "") { print k - 1; exit } print NR }' "${file}")"
      if [[ -z "${entry_block_end_line}" ]]; then entry_block_end_line="${entry_block_start_line}"; fi
      sed -i "${entry_block_start_line},${entry_block_end_line}s/^\([^#]\)/# \1/" "${file}" &>/dev/null
    elif [[ "${file##*.}" == "list" ]]; then
      sed -i 's|^\([^#]*packages.adoptium.net.*\)|# \1|' "${file}" 2> /dev/null
    fi
    if ! grep -qE '^\s*[^#]' "${file}"; then rm -f "${file}"; fi
    found_entries="true"
  done < <(find /etc/apt/sources.list.d/ \( -name "*.list" -o -name "*.sources" \) -exec grep -sril "^[^#]*packages.adoptium.net" {} +)
  if [[ "${found_entries}" == "true" ]]; then
    echo -e "\\r${GREEN}#${RESET} Successfully removed all older Adoptium repository entries! \\n"
  else
    echo -e "\\r${YELLOW}#${RESET} There were no older Adoptium repository entries... \\n"
  fi
}

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                             libssl                                                                                              #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

libssl_installation() {
  echo -e "${GRAY_R}#${RESET} Downloading libssl..."
  while read -r libssl_package; do
    libssl_package_empty="false"
    if ! libssl_temp="$(mktemp --tmpdir=/tmp "libssl${libssl_version}_XXXXX.deb")"; then abort_reason="Failed to create temporarily libssl download file."; abort; fi
    echo -e "$(date +%F-%T.%6N) | Downloading ${libssl_repo_url}/pool/main/o/${libssl_url_arg}/${libssl_package} to ${libssl_temp}" &>> "${eus_dir}/logs/libssl.log"
    if curl "${nos_curl_argument[@]}" --output "$libssl_temp" "${libssl_repo_url}/pool/main/o/${libssl_url_arg}/${libssl_package}" &>> "${eus_dir}/logs/libssl.log"; then
      if command -v dpkg-deb &> /dev/null; then if ! dpkg-deb --info "${libssl_temp}" &> /dev/null; then echo -e "$(date +%F-%T.%6N) | The file downloaded via ${libssl_repo_url}/pool/main/o/${libssl_url_arg}/${libssl_package} was not a debian file format..." &>> "${eus_dir}/logs/libssl.log"; continue; fi; fi
      if [[ "${libssl_download_success_message}" != 'true' ]]; then echo -e "${GREEN}#${RESET} Successfully downloaded libssl! \\n"; libssl_download_success_message="true"; fi
      check_dpkg_lock
      if [[ "${libssl_installing_message}" != 'true' ]]; then echo -e "${GRAY_R}#${RESET} Installing libssl..."; libssl_installing_message="true"; fi
      if "${EUS_APT_ENV[@]}" env DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_downgrade_option[@]}" "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "$libssl_temp" &>> "${eus_dir}/logs/libssl.log"; then
        echo -e "${GREEN}#${RESET} Successfully installed libssl! \\n"
        libssl_install_success="true"
        break
      else
        check_unmet_dependencies
        broken_packages_check
        attempt_recover_broken_packages
        add_apt_option_no_install_recommends="true"; get_apt_options
        check_dpkg_lock
        if "${EUS_APT_ENV[@]}" env DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_downgrade_option[@]}" "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "$libssl_temp" &>> "${eus_dir}/logs/libssl.log"; then
          echo -e "${GREEN}#${RESET} Successfully installed libssl! \\n"
          libssl_install_success="true"
          break
        else
          check_dpkg_lock
          if DEBIAN_FRONTEND='noninteractive' "$(which dpkg)" -i "$libssl_temp" &>> "${eus_dir}/logs/libssl.log"; then
            echo -e "${GREEN}#${RESET} Successfully installed libssl! \\n"
            libssl_install_success="true"
            break
          else
            if [[ "${libssl_install_failed_message}" != 'true' ]]; then echo -e "${RED}#${RESET} Failed to install libssl... trying some different versions... \\n"; echo -e "${GRAY_R}#${RESET} Attempting to install different versions..."; libssl_install_failed_message="true"; fi
            rm --force "$libssl_temp" &> /dev/null
          fi
        fi
        get_apt_options
      fi
    else
      abort_reason="Failed to download libssl."
      abort
    fi
  done < <(curl "${curl_argument[@]}" "${libssl_repo_url}/pool/main/o/${libssl_url_arg}/?C=M;O=D" | grep -Eaio "${libssl_grep_arg}" | cut -d'"' -f1)
  if [[ "${libssl_package_empty}" != 'false' ]]; then
    curl "${curl_argument[@]}" "${libssl_repo_url}/pool/main/o/${libssl_url_arg}/?C=M;O=D" &> /tmp/EUS/libssl.html
    if ! [[ -s "${eus_dir}/logs/libssl-failure-debug-info.json" ]] || ! jq empty "${eus_dir}/logs/libssl-failure-debug-info.json"; then
      libssl_json_time="$(date +%F-%T.%6N)"
      if [[ "$(dpkg-query --showformat='${version}' --show jq 2> /dev/null | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
        jq -n \
          --argjson "libssl failures" "$( 
            jq -n \
              --argjson "${libssl_json_time}" "{ \"version\" : \"$libssl_version\", \"URL Argument\" : \"$libssl_url_arg\", \"Grep Argument\" : \"$libssl_grep_arg\", \"Repository URL\" : \"$libssl_repo_url\", \"Curl Results\" : \"\" }" \
               '$ARGS.named'
          )" \
          '$ARGS.named' &> "${eus_dir}/logs/libssl-failure-debug-info.json"
      else
        jq -n \
          --arg libssl_version "${libssl_version}" \
          --arg libssl_url_arg "${libssl_url_arg}" \
          --arg libssl_grep_arg "${libssl_grep_arg}" \
          --arg libssl_repo_url "${libssl_repo_url}" \
          '{ 
            "libssl failures": {
              "version": $libssl_version,
              "URL Argument": $libssl_url_arg,
              "Grep Argument": $libssl_grep_arg,
              "Repository URL": $libssl_repo_url,
              "Curl Results": ""
            }
          }' &> "${eus_dir}/logs/libssl-failure-debug-info.json"
      fi
      if [[ "$(dpkg-query --showformat='${version}' --show jq 2> /dev/null | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
        jq --arg libssl_json_time "${libssl_json_time}" --arg libssl_curl_results "$(</tmp/EUS/libssl.html)" '."libssl failures"."'"${libssl_json_time}"'"."Curl Results"=$libssl_curl_results' "${eus_dir}/logs/libssl-failure-debug-info.json" > "${eus_dir}/logs/libssl-failure-debug-info.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
      else
        jq --arg libssl_json_time "$libssl_json_time" --arg libssl_curl_results "$(</tmp/EUS/libssl.html)" '.["libssl failures"][$libssl_json_time]["Curl Results"] = $libssl_curl_results' "${eus_dir}/logs/libssl-failure-debug-info.json" > "${eus_dir}/logs/libssl-failure-debug-info.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
      fi
      eus_database_move_file="${eus_dir}/logs/libssl-failure-debug-info.json"; eus_database_move_log_file="${eus_dir}/logs/libssl-failure-debug-info.log"; eus_database_move
    else
      if [[ "$(dpkg-query --showformat='${version}' --show jq 2> /dev/null | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
        jq --arg libssl_repo_url "${libssl_repo_url}" --arg libssl_grep_arg "${libssl_grep_arg}" --arg libssl_url_arg "${libssl_url_arg}" --arg libssl_version "${libssl_version}" --arg version "${version}" --arg libssl_curl_results "$(</tmp/EUS/libssl.html)" '."libssl failures" += {"'"$(date +%F-%T.%6N)"'": {"version": $libssl_version, "URL Argument": $libssl_url_arg, "Grep Argument": $libssl_grep_arg, "Repository URL": $libssl_repo_url, "Curl Results": $libssl_curl_results}}' "${eus_dir}/logs/libssl-failure-debug-info.json" > "${eus_dir}/logs/libssl-failure-debug-info.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
      else
        jq --arg libssl_repo_url "$libssl_repo_url" --arg libssl_grep_arg "$libssl_grep_arg" --arg libssl_url_arg "$libssl_url_arg" --arg libssl_version "$libssl_version" --arg version "$version" --arg libssl_curl_results "$(</tmp/EUS/libssl.html)" --arg current_time "$current_time" '.["libssl failures"][$current_time] = {"version": $libssl_version, "URL Argument": $libssl_url_arg, "Grep Argument": $libssl_grep_arg, "Repository URL": $libssl_repo_url, "Curl Results": $libssl_curl_results}' "${eus_dir}/logs/libssl-failure-debug-info.json" > "${eus_dir}/logs/libssl-failure-debug-info.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
      fi
      eus_database_move_file="${eus_dir}/logs/libssl-failure-debug-info.json"; eus_database_move_log_file="${eus_dir}/logs/libssl-failure-debug-info.log"; eus_database_move
    fi
    rm --force /tmp/EUS/libssl.html &> /dev/null
    abort_reason="Failed to locate any libssl packages for version ${libssl_version}."
    abort
  fi
  if [[ "${libssl_install_success}" != 'true' ]]; then apt-cache policy libc6 libssl3 &>> "${eus_dir}/logs/libssl.log"; abort_reason="Failed to install libssl."; abort; fi
  rm --force "$libssl_temp" 2> /dev/null
}

libssl_installation_check() {
  if [[ -n "${mongodb_package_libssl}" ]]; then
    if apt-cache policy "^${mongodb_package_libssl}$" | grep -ioq "candidate"; then
      if [[ -n "${mongodb_package_version_libssl}" ]]; then
        required_libssl_version="$(apt-cache depends "${mongodb_package_libssl}=${mongodb_package_version_libssl}" | sed -e 's/>//g' -e 's/<//g' | grep -io "libssl1.0.0$\\|libssl1.1$\\|libssl3$")"
      else
        required_libssl_version="$(apt-cache depends "${mongodb_package_libssl}" | sed -e 's/>//g' -e 's/<//g' | grep -io "libssl1.0.0$\\|libssl1.1$\\|libssl3$")"
      fi
      if ! [[ "${required_libssl_version}" =~ (libssl1.0.0|libssl1.1|libssl3) ]]; then echo -e "$(date +%F-%T.%6N) | mongodb_package_libssl was \"${mongodb_package_libssl}\", mongodb_package_version_libssl was \"${mongodb_package_version_libssl}\", required_libssl_version was \"${required_libssl_version}\"..." &>> "${eus_dir}/logs/libssl-dynamic-failure.log"; unset required_libssl_version; fi
      unset mongodb_package_libssl
      unset mongodb_package_version_libssl
    fi
  fi
  if [[ -z "${required_libssl_version}" ]]; then
    if [[ "${mongo_version_max}" == '70' && -n "${mongo_version_max}" ]]; then
      if grep -sioq "jammy" "/etc/apt/sources.list.d/mongodb-org-7.0.list" "/etc/apt/sources.list.d/mongodb-org-7.0.sources"; then
        required_libssl_version="libssl3"
      else
        required_libssl_version="libssl1.1"
      fi
    elif [[ "${mongo_version_max}" -ge '36' && -n "${mongo_version_max}" ]]; then
      required_libssl_version="libssl1.1"
    elif [[ "${mongo_version_max}" -lt '36' && -n "${mongo_version_max}" ]]; then
      required_libssl_version="libssl1.0.0"
    fi
  fi
  unset libssl_install_required
  if [[ "${required_libssl_version}" == 'libssl3' ]]; then
    libssl_version="3.0.0"
    libssl_url_arg="openssl"
    libssl_grep_arg="libssl3_3.0.*${architecture}.deb"
    if ! "$(which dpkg)" -l libssl3 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
      libssl_install_required="true"
      if "$(which dpkg)" -l libssl3t64 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then unset libssl_install_required; fi
    elif [[ "$(dpkg-query --showformat='${Version}' --show libssl3 2> /dev/null | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -lt "${libssl_version//./}" ]]; then
      libssl_install_required="true"
    fi
    if [[ "${os_codename}" =~ (wheezy|jessie|stretch|buster|bullseye|bookworm|trixie|forky|unstable) ]]; then
      libssl_repo_url="${http_or_https}://deb.debian.org/debian"
    else
      if [[ "${architecture}" =~ (amd64|i386) ]]; then
        libssl_repo_url="${http_or_https}://security.ubuntu.com/ubuntu"
      else
        libssl_repo_url="${http_or_https}://ports.ubuntu.com"
      fi
    fi
    if [[ "${libssl_install_required}" == 'true' ]]; then
      if [[ "$(dpkg-query --showformat='${version}' --show libc6 2> /dev/null | sed 's/.*://' | sed 's/-.*//g' | cut -d'.' -f1)" -lt "2" ]] || [[ "$(dpkg-query --showformat='${version}' --show libc6 2> /dev/null | sed 's/.*://' | sed 's/-.*//g' | cut -d'.' -f1)" == "2" && "$(dpkg-query --showformat='${version}' --show libc6 2> /dev/null | sed 's/.*://' | sed 's/-.*//g' | cut -d'.' -f2)" -lt "34" ]]; then
        if [[ "${os_codename}" =~ (trusty|utopic|vivid|wily|yakkety|zesty|artful|qiana|rebecca|rafaela|rosa|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish) ]]; then
          if [[ "${architecture}" =~ (amd64|i386) ]]; then
            get_repo_url_security_url="true"
            get_repo_url
            repo_codename_argument="-security"
            repo_component="main"
          else
            repo_url="${http_or_https}://ports.ubuntu.com"
            repo_codename_argument="-security"
            repo_component="main universe"
          fi
          repo_codename="jammy"
        elif [[ "${os_codename}" =~ (wheezy|jessie|stretch|buster|bullseye) ]]; then
          repo_codename="bookworm"
          get_repo_url
          repo_component="main"
        fi
        add_repositories
        run_apt_get_update_with_sha1_fallback
      fi
    fi
  elif [[ "${required_libssl_version}" == 'libssl1.1' ]]; then
    libssl_version="1.1.0"
    libssl_url_arg="openssl"
    libssl_grep_arg="libssl1.1.*${architecture}.deb"
    if ! "$(which dpkg)" -l libssl1.1 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
      libssl_install_required="true"
    elif [[ "$(dpkg-query --showformat='${Version}' --show libssl1.1 2> /dev/null | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g')" -lt "${libssl_version//./}" ]]; then
      libssl_install_required="true"
    fi
    if [[ "${os_codename}" =~ (wheezy|jessie|stretch|buster|bullseye|bookworm|trixie|forky|unstable) ]]; then
      libssl_repo_url="${http_or_https}://deb.debian.org/debian"
    else
      if [[ "${architecture}" =~ (amd64|i386) ]]; then
        libssl_repo_url="${http_or_https}://security.ubuntu.com/ubuntu"
      else
        libssl_repo_url="${http_or_https}://ports.ubuntu.com"
      fi
    fi
    if [[ "${libssl_install_required}" == 'true' ]]; then
      if [[ "$(dpkg-query --showformat='${version}' --show libc6 2> /dev/null | sed 's/.*://' | sed 's/-.*//g' | cut -d'.' -f1)" -lt "2" ]] || [[ "$(dpkg-query --showformat='${version}' --show libc6 2> /dev/null | sed 's/.*://' | sed 's/-.*//g' | cut -d'.' -f1)" == "2" && "$(dpkg-query --showformat='${version}' --show libc6 2> /dev/null | sed 's/.*://' | sed 's/-.*//g' | cut -d'.' -f2)" -lt "29" ]]; then
        if [[ "${os_codename}" =~ (trusty|utopic|vivid|wily|yakkety|zesty|artful|qiana|rebecca|rafaela|rosa|xenial|bionic|cosmic|disco|eoan) ]]; then
          if [[ "${architecture}" =~ (amd64|i386) ]]; then
            get_repo_url_security_url="true"
            get_repo_url
            repo_codename_argument="-security"
            repo_component="main"
          else
            repo_url="${http_or_https}://ports.ubuntu.com"
            repo_component="main universe"
          fi
          repo_codename="focal"
          get_repo_url
        elif [[ "${os_codename}" =~ (wheezy|jessie|stretch|buster) ]]; then
          repo_codename="bullseye"
          get_repo_url
          repo_component="main"
        fi
        add_repositories
        run_apt_get_update_with_sha1_fallback
      fi
    fi
  elif [[ "${required_libssl_version}" == 'libssl1.0.0' ]]; then
    libssl_version="1.0.2"
    libssl_url_arg="openssl1.0"
    libssl_grep_arg="libssl1.0.*${architecture}.deb"
    if ! "$(which dpkg)" -l libssl1.0.0 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
      libssl_install_required="true"
    elif [[ "$(dpkg-query --showformat='${Version}' --show libssl1.0.0 2> /dev/null | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g')" -lt "${libssl_version//./}" ]]; then
      libssl_install_required="true"
    fi
    if [[ "${architecture}" =~ (amd64|i386) ]]; then
      libssl_repo_url="${http_or_https}://security.ubuntu.com/ubuntu"
    else
      libssl_repo_url="${http_or_https}://ports.ubuntu.com"
    fi
  else
    echo -e "$(date +%F-%T.%6N) | ${mongodb_package_libssl} doesn't appear to required libssl..." &>> "${eus_dir}/logs/libssl-dynamic-failure.log"
  fi
  if [[ "${libssl_install_required}" == 'true' ]]; then libssl_installation; fi
  unset required_libssl_version
}

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                             Checks                                                                                              #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

network_install_mongodb_version_check() {
  # MongoDB version check.
  if [[ "${mongodb_version_installed_no_dots::2}" -gt "${mongo_version_max}" ]]; then
    eus_directory_location="/tmp/EUS"
    eus_create_directories "mongodb"
    apt-cache rdepends mongodb-* | sed "/mongo/d" | sed "/Reverse Depends/d" | awk '!a[$0]++' | sed 's/|//g' | sed 's/ //g' | sed -e 's/unifi-video//g' -e 's/unifi//g' -e 's/libstdc++6//g' -e '/^$/d' &> /tmp/EUS/mongodb/reverse_depends
    if [[ -s "/tmp/EUS/mongodb/reverse_depends" ]]; then mongodb_has_dependencies="true"; fi
    header_red
    while true; do
      echo -e "${GRAY_R}#${RESET} UniFi Network Application ${unifi_clean} does not support MongoDB ${mongodb_version_installed}..."
      if [[ "${mongodb_has_dependencies}" == 'true' ]]; then
        echo -e "${GRAY_R}#${RESET} The following services depend on MongoDB..."
        while read -r service; do echo -e "${RED}-${RESET} ${service}"; done < /tmp/EUS/mongodb/reverse_depends
        echo -e "\\n\\n"
        echo -e "${RED}#${RESET} Uninstalling MongoDB will also get rid of the applications/services listed above..."
      fi
      echo -e "\\n\\n"
      if [[ "${script_option_skip}" != 'true' && "${mongodb_has_dependencies}" != 'true' ]]; then
        read -rp "Do you want to proceed with uninstalling MongoDB? (Y/n)" yes_no
      else
        sleep 5
      fi
      case "$yes_no" in
          [Yy]*|"")
            mongodb_installed="false"
            header
            check_dpkg_lock
            echo -e "${GRAY_R}#${RESET} Preparing unsupported mongodb uninstall... \\n"
            if [[ -n "${previous_mongodb_version}" ]]; then
              if [[ "${mongodb_version_installed_no_dots::2}" == "${previous_mongodb_version::2}" ]]; then
                installed_and_previous_mongodb_match="true"
                mongodb_downgrade_process="true"
              fi
            fi
            if [[ "$(grep -si is_default /usr/lib/unifi/data/system.properties | awk -F= '{print $2}')" != 'true' && "${installed_and_previous_mongodb_match}" == 'true' ]]; then
              if "$(which dpkg)" -l "${gr_mongod_name}" 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then mongodb_org_server_package="${gr_mongod_name}"; else mongodb_org_server_package="mongodb-org-server"; fi
              if "$(which dpkg)" -l "${mongodb_org_server_package}" 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
                mongodb_org_version="$(dpkg-query --showformat='${Version}' --show "${mongodb_org_server_package}" 2> /dev/null | sed 's/.*://' | sed 's/-.*//g')"
                mongodb_org_version_major_minor="${mongodb_org_version%.*}"
                if ! "$(which dpkg)" -l mongodb-org-shell 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
        	      install_mongodb_org_shell="true"
                else
	              install_mongodb_org_shell_version="$(dpkg-query --showformat='${version}' --show mongodb-org-shell 2> /dev/null | sed 's/.*://' | sed 's/-.*//g')"
                  install_mongodb_org_shell_major_minor="${install_mongodb_org_shell_version%.*}"
                  if [[ "${install_mongodb_org_shell_major_minor}" != "${mongodb_org_version_major_minor}" ]]; then install_mongodb_org_shell="true"; fi
                fi
                if [[ "${install_mongodb_org_shell}" == 'true' ]]; then
                  unset install_mongodb_org_shell
                  echo -e "${GRAY_R}----${RESET}\\n"
                  multiple_attempt_to_install_package_log="unifi-install-script-required"
                  multiple_attempt_to_install_package_task="install"
                  multiple_attempt_to_install_package_attempts_max="3"
                  multiple_attempt_to_install_package_name="mongodb-org-shell"
                  multiple_attempt_to_install_package_version_with_equal_sign="=${mongodb_org_version}"
                  multiple_attempt_to_install_package
                  get_apt_options
                fi
              fi
              if "$(which dpkg)" -l "${mongodb_org_server_package}" 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
                mongodb_org_version="$(dpkg-query --showformat='${Version}' --show "${mongodb_org_server_package}" 2> /dev/null | sed 's/.*://' | sed 's/-.*//g')"
                mongodb_org_version_no_dots="${mongodb_org_version//./}"
                if [[ "${mongodb_org_version_no_dots::1}" -ge "5" ]]; then
                  mongodb_mongosh_libssl_version="$(apt-cache depends "${mongodb_org_server_package}"="${mongodb_org_version}" | sed -e 's/>//g' -e 's/<//g' | grep -io "libssl1.1$\\|libssl3$")"
                  if [[ -z "${mongodb_mongosh_libssl_version}" ]]; then
                    mongodb_mongosh_libssl_version="$(apt-cache depends "${mongodb_org_server_package}" | sed -e 's/>//g' -e 's/<//g' | grep -io "libssl1.1$\\|libssl3$")"
                  fi
                  if [[ "${mongodb_mongosh_libssl_version}" == 'libssl3' ]]; then
                    mongodb_mongosh_install_package_name="mongodb-mongosh-shared-openssl3"
                  elif [[ "${mongodb_mongosh_libssl_version}" == 'libssl1.1' ]]; then
                    mongodb_mongosh_install_package_name="mongodb-mongosh-shared-openssl11"
                  elif "$(which dpkg)" -l libssl3t64 libssl3 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
                    mongodb_mongosh_install_package_name="mongodb-mongosh-shared-openssl3"
                  else
                    mongodb_mongosh_install_package_name="mongodb-mongosh-shared-openssl11"
                  fi
                  if ! "$(which dpkg)" -l mongodb-mongosh-shared-openssl11 mongodb-mongosh-shared-openssl3 mongodb-mongosh mongosh 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
                    echo -e "${GRAY_R}----${RESET}\\n"
                    mongodb_package_libssl="${mongodb_mongosh_install_package_name}"
                    libssl_installation_check
                    multiple_attempt_to_install_package_log="unifi-install-script-required"
                    multiple_attempt_to_install_package_task="install"
                    multiple_attempt_to_install_package_attempts_max="3"
                    multiple_attempt_to_install_package_name="${mongodb_mongosh_install_package_name}"
                    multiple_attempt_to_install_package
                    get_apt_options
                  fi
                fi
              fi
              mongo_command
              unifi_database_location="$(readlink -f /usr/lib/unifi/data/db)"
              unifi_database_location_user="$(stat -c "%U" "${unifi_database_location}")"
              unifi_logs_location="$(readlink -f /usr/lib/unifi/logs)"
              start_unifi_database_task="unsupported-mongodb-version"
              start_unifi_database
              FeatureCompatibilityVersion="${mongo_version_max_with_dot}"
              echo -e "${GRAY_R}#${RESET} Setting featureCompatibilityVersion to version ${FeatureCompatibilityVersion}..."
              echo -e "${GRAY_R}#${RESET} This process could take up to 60 seconds before timing out..."
              check_count=0
              while [[ "${check_count}" -lt '60' ]]; do
                if [[ "${mongodb_version_installed_no_dots::2}" -ge "36" ]]; then
                  if grep -sioq "confirm: true" /tmp/EUS/mongodb/setFeatureCompatibilityVersion.log; then
                    "${mongocommand}" --quiet --port 27117 --eval 'db.adminCommand( { setFeatureCompatibilityVersion: "'"${FeatureCompatibilityVersion}"'", confirm: true } )' &> /tmp/EUS/mongodb/setFeatureCompatibilityVersion.log
                  else
                    "${mongocommand}" --quiet --port 27117 --eval 'db.adminCommand( { setFeatureCompatibilityVersion: "'"${FeatureCompatibilityVersion}"'" } )' &> /tmp/EUS/mongodb/setFeatureCompatibilityVersion.log
                 fi
                fi
                if sed -e 's/ //g' -e 's/"//g' /tmp/EUS/mongodb/setFeatureCompatibilityVersion.log | grep -iq "ok:1"; then
                  echo -e "${GREEN}#${RESET} Successfully set featureCompatibilityVersion to ${FeatureCompatibilityVersion}! \\n"
                  success_setfeaturecompatibilityversion="true"
                  break
                else
                  ((check_count=check_count+1))
                  sleep 1
                fi
              done
              if [[ "${success_setfeaturecompatibilityversion}" != 'true' ]]; then
                echo -e "${RED}#${RESET} Failed to set featureCompatibilityVersion to ${FeatureCompatibilityVersion}! \\n${RED}#${RESET} We will keep featureCompatibilityVersion untouched! \\n"
              fi
              shutdown_mongodb
            fi
            if "$(which dpkg)" -l | grep "unifi " | grep -q "^ii\\|^hi"; then
              echo -e "${GRAY_R}#${RESET} Removing the UniFi Network Application so that the files are kept on the system...\\n"
              if "$(which dpkg)" --remove --force-remove-reinstreq unifi &>> "${eus_dir}/logs/unsupported-mongodb-uninstall.log"; then
                echo -e "${GREEN}#${RESET} Successfully removed the UniFi Network Application! \\n"
              else
                abort_reason="Failed to remove the UniFi Network Application."
                abort
              fi
            fi
            if "$(which dpkg)" -l | grep "unifi-video" | grep -q "^ii\\|^hi"; then
              echo -e "${GRAY_R}#${RESET} Removing UniFi Video so that the files are kept on the system...\\n"
              if "$(which dpkg)" --remove --force-remove-reinstreq unifi-video &>> "${eus_dir}/logs/unsupported-mongodb-uninstall.log"; then
                echo -e "${GREEN}#${RESET} Successfully removed UniFi Video! \\n"
              else
                abort_reason="Failed to remove UniFi Video."
                abort
              fi
            fi
            remove_older_mongodb_repositories
            sleep 2
            while read -r mongodb_package_purge; do
              if "$(which dpkg)" -l | awk '{print$2}' | grep -iq "^${mongodb_package_purge}$"; then
                check_dpkg_lock
                echo -e "${GRAY_R}#${RESET} Purging package ${mongodb_package_purge}..."
                if "${EUS_APT_ENV[@]}" env DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' purge "${mongodb_package_purge}" &>> "${eus_dir}/logs/unsupported-mongodb-uninstall.log"; then
                  echo -e "${GREEN}#${RESET} Successfully purged ${mongodb_package_purge}! \\n"
                else
                  echo -e "${RED}#${RESET} Failed to purge ${mongodb_package_purge}... \\n"
                  mongodb_package_purge_failed="true"
                fi
              fi
            done < <("$(which dpkg)" -l | grep "^ii\\|^hi\\|^ri\\|^pi\\|^ui\\|^iU" | grep -i "mongo" | awk '{print $2}')
            if [[ "${mongodb_package_purge_failed}" == 'true' ]]; then
              echo -e "${YELLOW}#${RESET} There was a failure during the purge process...\\n"
              echo -e "${GRAY_R}#${RESET} Uninstalling MongoDB with different actions...\\n"
              while read -r mongodb_package_remove; do
                if "$(which dpkg)" -l | awk '{print$2}' | grep -iq "^${mongodb_package_remove}$"; then
                  check_dpkg_lock
                  echo -e "${GRAY_R}#${RESET} Removing package ${mongodb_package_remove}..."
                  if DEBIAN_FRONTEND='noninteractive' "$(which dpkg)" --remove --force-remove-reinstreq "${mongodb_package_remove}" &>> "${eus_dir}/logs/unsupported-mongodb-uninstall.log"; then
                    echo -e "${GREEN}#${RESET} Successfully removed ${mongodb_package_remove}! \\n"
                  else
                    echo -e "${RED}#${RESET} Failed to remove ${mongodb_package_remove}... \\n"
                  fi
                fi
              done < <("$(which dpkg)" -l | grep "^ii\\|^hi\\|^ri\\|^pi\\|^ui\\|^iU" | grep -i "mongo" | awk '{print $2}')
            fi
            echo -e "${GRAY_R}#${RESET} Running apt-get autoremove..."
            if apt-get -y autoremove &>> "${eus_dir}/logs/apt-cleanup.log"; then echo -e "${GREEN}#${RESET} Successfully ran apt-get autoremove! \\n"; else echo -e "${RED}#${RESET} Failed to run apt-get autoremove"; fi
            echo -e "${GRAY_R}#${RESET} Running apt-get autoclean..."
            if apt-get -y autoclean &>> "${eus_dir}/logs/apt-cleanup.log"; then echo -e "${GREEN}#${RESET} Successfully ran apt-get autoclean! \\n"; else echo -e "${RED}#${RESET} Failed to run apt-get autoclean"; fi
            sleep 3
            mongodb_unsupported_uninstall="true"
            unset mongodb_downgrade_process
            break;;
          [Nn]*)
            cancel_script
            break;;
          *)
            echo -e "\\n${RED}#${RESET} Invalid input, please answer Yes or No (y/n)...\\n"
            sleep 3;;
      esac
    done
  fi
}

swap_file_check() {
  # Memory and Swap file.
  if [[ "${system_swap}" != "0" || "${script_option_skip_swap}" == 'true' || "${unifi_core_system}" == 'true' || "${is_cloudkey}" == 'true' || "${container_system}" == 'true' ]]; then
    return
  fi
  header
  if [[ "${system_memory}" -lt "2" ]]; then 
    echo -e "${YELLOW}#${RESET} System memory is lower than recommended!"
  fi
  echo -e "${GRAY_R}#${RESET} Checking free disk space to create a swap file... \\n"
  sleep 2
  create_swap() {
    local size="${1}"
    local msg="${2}"
    echo -e "${GRAY_R}---${RESET} \\n"
    echo -e "${GRAY_R}#${RESET} ${msg}"
    if dd if=/dev/zero of=/swapfile bs=1M count="${size}" &>/dev/null; then
      echo -e "${GREEN}#${RESET} Successfully created a swap file! \\n"
      chmod 600 /swapfile &>/dev/null
      echo -e "${GRAY_R}#${RESET} Formatting the swap file..."
      if mkswap /swapfile &>/dev/null; then
        echo -e "${GRAY_R}#${RESET} Successfully formatted the swap file! \\n"
        echo -e "${GRAY_R}#${RESET} Enabling the swap file..."
        if swapon /swapfile &>/dev/null; then
          echo -e "${GRAY_R}#${RESET} Successfully enabled the swap file! \\n"
          echo "/swapfile swap swap defaults 0 0" | tee -a /etc/fstab &>/dev/null
        else
          echo -e "${RED}#${RESET} Failed to enable the swap file... \\n"
        fi
      else
        echo -e "${RED}#${RESET} Failed to format the swap file... \\n"
      fi
    else
      echo -e "${RED}#${RESET} Failed to create a swap file... \\n"
    fi
  }
  if [[ "${system_free_disk_space}" -ge "10000000" ]]; then
    create_swap 2048 "You have more than 10GB free. Creating a 2GB swap file!"
  elif [[ "${system_free_disk_space}" -ge "5000000" ]]; then
    create_swap 1024 "You have more than 5GB free. Creating a 1GB swap file."
  elif [[ "${system_free_disk_space}" -ge "4000000" ]]; then
    create_swap 256 "You have more than 4GB free. Creating a 256MB swap file."
  else
    echo -e "${GRAY_R}---${RESET}\n"
    echo -e "${GRAY_R}#${RESET} Your free disk space is extremely low!"
    echo -e "${GRAY_R}#${RESET} Not enough free disk space to create a swap file.  \\n"
    echo -e "${GRAY_R}#${RESET} I recommend upgrading system memory (≥2GB) and expanding disk space!"
    echo -e "${GRAY_R}#${RESET} Continuing script at your own risk... \\n"
    sleep 10
  fi
}

if [[ -d /tmp/EUS/services ]]; then
  if [[ -f /tmp/EUS/services/stopped_list ]]; then cat /tmp/EUS/services/stopped_list &>> /tmp/EUS/services/stopped_services; fi
  find /tmp/EUS/services/ -type f -printf "%f\\n" | sed 's/ //g' | sed '/file_list/d' | sed '/stopped_services/d' &> /tmp/EUS/services/file_list
  while read -r file; do
    rm --force "/tmp/EUS/services/${file}" &> /dev/null
  done < /tmp/EUS/services/file_list
  rm --force /tmp/EUS/services/file_list &> /dev/null
fi

network_install_ports_check() {
  # Check if UniFi Network Application ports are in use.
  if netstat -tuln | grep -qE '(:8443|:8080|:8843|:8880|:6789)\s'; then unifi_ports_in_use="true"; fi
}

uos_server_ports_change_support_check() {
  declare -gA port_variable_install_flag=(
    ["uos_server_web_port"]="--web-port"
  )
  declare -A uos_server_port_change_map
  uos_server_port_change_map["4.3.3"]="uos_server_web_port"
  for version in "${!uos_server_port_change_map[@]}"; do
    if version_ge "${uos_version}" "${version}"; then
      for uos_server_ports_variable in ${uos_server_port_change_map[${version}]}; do
        uos_server_ports_changeable+=("${uos_server_ports_variable}")
      done
    fi
  done
}

uos_server_install_ports_check() {
  # Check if UniFi OS Server ports are in use.
  uos_server_ports_used=("${uos_server_web_port}" "${uos_server_http_captive_portal_port}" "${uos_server_https_captive_portal_port}" "${uos_server_captive_portal_redirector_1_port}" "${uos_server_captive_portal_redirector_2_port}" "${uos_server_device_inform_port}" "${uos_server_remote_logger_port}" "${uos_server_stun_port}" "${uos_server_mobile_speedtest_port}" "${uos_server_discovery_1_port}" "${uos_server_discovery_2_port}" "${uos_server_rabbitmq_port}" "${uos_server_identity_hub_port}" "${uos_server_management_wrapper_port}")
  if ! version_ge "${uos_version}" "5.0.7"; then
    uos_server_ports_used+=("${uos_server_https_legacy_port}")
  fi
  uos_server_ports_changeable=()
  uos_server_install_flags=()
  uos_server_ports_change_support_check
  for uos_server_port in "${!uos_server_ports_used[@]}"; do
    port="${uos_server_ports_used[${uos_server_port}]}"
    process_info="$(ss -ltnp "( sport = :${port} )" 2>/dev/null | awk 'NR>1 {print $6}' | uniq)"
    if [[ -n "${process_info}" ]]; then
      mapfile -t pids < <(echo "${process_info}" | grep -oP 'pid=\K[0-9]+' | sort -u)
      services=()
      for pid in "${pids[@]}"; do
        svc="$(systemctl status "$pid" --no-pager 2>/dev/null | head -n 1 | awk '{print $2}' | sed 's/\.service$//')"
        if [[ -z "${svc}" ]]; then svc="$(ps -p "$pid" -o comm=)"; fi
        services+=("${svc}")
      done
      unique_services=$(printf "%s\n" "${services[@]}" | sort -u | paste -sd, -)
      for var in "${uos_server_ports_changeable[@]}"; do
        if [[ "${!var}" == "${port}" ]]; then
          new_port=$((port+1))
          while [[ -n "$(ss -ltn "( sport = :${new_port} )" | awk 'NR>1')" ]]; do
            new_port=$((new_port+1))
          done
          if [[ "${uos_server_install_ports_check_header_printed}" != 'true' ]]; then header; uos_server_install_ports_check_header_printed="true"; fi
          echo -e "${YELLOW}#${RESET} Port ${port} was in use by ${unique_services}, switching to port ${new_port}..."
          echo -e "$(date +%F-%T.%6N) | Port ${port} in use by ${unique_services}, attempting to change it to port ${new_port}" &>> "${eus_dir}/logs/uos-server-ports-check.log"
          # Update array + actual variable
          uos_server_ports_used["${uos_server_port}"]="${new_port}"
          if printf -v "${var}" '%s' "${new_port}"; then
            echo -e "$(date +%F-%T.%6N) | Successfully updated ${var} to port ${new_port}!" &>> "${eus_dir}/logs/uos-server-ports-check.log"
            echo -e "${GREEN}#${RESET} Successfully updated the variable to port ${new_port}! \\n"
            if [[ -n "${port_variable_install_flag[${var}]}" ]]; then
              uos_server_install_flags+=( "${port_variable_install_flag[$var]}" "${new_port}" )
            fi
            continue 2
          else
            echo -e "$(date +%F-%T.%6N) | Failed to update ${var} to port ${new_port}..." &>> "${eus_dir}/logs/uos-server-ports-check.log"
            echo -e "${RED}#${RESET} Failed to update the variable to port ${new_port}... \\n"
          fi
        fi
      done
      if [[ "${unique_services}" == "unifi" && "${uos_server_overlapping_ports_message_printed}" != 'true' ]]; then
        uos_server_overlapping_ports_message_printed="true"
        header_red
        echo -e "${YELLOW}#${RESET} The UniFi Network Application appears to be running already..."
        echo -e "${YELLOW}#${RESET} The UniFi OS Server software uses overlapping ports, which means that the"
        echo -e "${YELLOW}#${RESET} UniFi Network Application has to be stopped in order to proceed with the install\\n"
        while true; do
          if [[ "${script_option_skip}" != 'true' ]]; then read -rp $'\033[39m#\033[0m Do you want to proceed with the UniFi OS Server install? (y/N) ' yes_no; fi
          case "$yes_no" in
            [Yy]*)
              echo -e "${GREEN}#${RESET} OK! Proceeding with the install of the UniFi OS Server software!\\n"
              sleep 2
              break;;
            [Nn]*|"") cancel_script; break;;
            *) echo -e "\\n${RED}#${RESET} Invalid input, please answer Yes or No (y/n)...\\n"; sleep 3;;
          esac
        done
      fi
      if [[ "${uos_server_install_ports_check_header_printed}" != 'true' ]]; then header; uos_server_install_ports_check_header_printed="true"; fi
      echo -e "${YELLOW}#${RESET} Port ${port} is in use by: ${unique_services} (PIDs: ${pids[*]})..."
      echo -e "$(date +%F-%T.%6N) | Port ${port} is in use by: ${unique_services} (PIDs ${pids[*]})" &>> "${eus_dir}/logs/uos-server-ports-check.log"
      while true; do
        if [[ "${script_option_skip}" != 'true' ]]; then read -rp $'\033[39m#\033[0m Do you want to stop '"${unique_services}"'? (Y/n) ' yes_no; fi
        case "$yes_no" in
          [Yy]*|"")
            for idx in "${!pids[@]}"; do
              pid="${pids[$idx]}"
              svc="${services[$idx]}"
              # Try to detect if PID belongs to a real systemd unit
              unit="$(systemctl status "${pid}" --no-pager 2>/dev/null | awk '/Loaded:/ {print $2}' | sed -n 's/\.service$//p')"
              if [[ -n "${unit}" ]]; then
                echo -e "\\n${WHITE_R}#${RESET} Attempting to stop service unit ${unit}.service..."
                echo -e "$(date +%F-%T.%6N) | Attempting to stop service unit ${unit}.service..." &>> "${eus_dir}/logs/uos-server-ports-check.log"
                if systemctl stop "${unit}.service" &>> "${eus_dir}/logs/uos-server-ports-check.log"; then
                  echo -e "$(date +%F-%T.%6N) | Successfully stopped ${unit}.service!" &>> "${eus_dir}/logs/uos-server-ports-check.log"
                  echo -e "${GREEN}#${RESET} Successfully stopped ${unit}.service!\\n"
                else
                  echo -e "$(date +%F-%T.%6N) | Failed to stop ${unit}.service (PID ${pid})" &>> "${eus_dir}/logs/uos-server-ports-check.log"
                  abort_reason="Failed to stop ${unit}.service (PID ${pid}) during the UniFi OS Server ports check process"
                  abort
                fi
              elif [[ -n "${svc}" ]]; then
                echo -e "\n${WHITE_R}#${RESET} Attempting to stop service ${svc}.service..."
               if systemctl stop "${svc}.service" &>> "${eus_dir}/logs/uos-server-ports-check.log"; then
                  echo -e "${GREEN}#${RESET} Successfully stopped ${svc}.service!\\n"
                else
                  echo -e "\n${WHITE_R}#${RESET} Attempting to kill PID ${pid} (${svc})..."
                  if kill "$pid" &>> "${eus_dir}/logs/uos-server-ports-check.log"; then
                    echo -e "${GREEN}#${RESET} Successfully killed PID ${pid}!\\n"
                  else
                    abort_reason="Failed to kill PID ${pid} (${svc}) during the UniFi OS Server ports check process"
                    abort
                  fi
                fi
              else
                echo -e "$(date +%F-%T.%6N) | Attempting to kill PID ${pid} (${svc})..." &>> "${eus_dir}/logs/uos-server-ports-check.log"
                echo -e "\\n${WHITE_R}#${RESET} Attempting to kill PID ${pid} (${svc})..."
                if kill "$pid" &>> "${eus_dir}/logs/uos-server-ports-check.log"; then
                  echo -e "$(date +%F-%T.%6N) | Successfully killed PID ${pid}!" &>> "${eus_dir}/logs/uos-server-ports-check.log"
                  echo -e "${GREEN}#${RESET} Successfully killed PID ${pid}!\\n"
                else
                  echo -e "$(date +%F-%T.%6N) | Failed to kill PID ${pid} (${svc})..." &>> "${eus_dir}/logs/uos-server-ports-check.log"
                  abort_reason="Failed to kill PID ${pid} (${svc}) during the UniFi OS Server ports check process"
                  abort
                fi
              fi
            done
            break;;
          [Nn]*) abort_reason="Ports required by UniFi OS Server are already in use (services: ${unique_services})."; abort;;
          *) echo -e "\\n${RED}#${RESET} Invalid input, please answer Yes or No (y/n)...\\n"; sleep 3;;
        esac
      done
    else
      echo -e "$(date +%F-%T.%6N) | Port ${port} is free" &>> "${eus_dir}/logs/uos-server-ports-check.log"
    fi
  done
  if [[ "${uos_server_install_ports_check_header_printed}" == 'true' ]]; then sleep 3; fi
}

check_free_ports() {
  local port="${1}"
  free_port=""
  for ((i=1; i<=100; i++)); do
    test_port="$((port + i))"
    netstat -tuln | grep -q ":${test_port} " || {
      free_port="${test_port}"
      break
    }
  done
}

change_default_unifi_ports() {
  unifi_ports=( "8843/tcp/portal.https.port/Hotspot Portal https redirection" "8880/tcp/portal.http.port/Hotspot Portal http redirection" "8443/tcp/unifi.https.port/Dashboard Management" "8080/tcp/unifi.http.port/Device Inform" "6789/tcp/unifi.stun.port/Mobile Speedtest" )
  eus_directory_location="/tmp/EUS"
  eus_create_directories "services" "ports"
  for port in "${unifi_ports[@]}"; do
    port_clean="$(echo "${port}" | cut -d'/' -f1)"
    if netstat -tulpn | grep -q ":${port_clean}\\b"; then
      port_pid="$(netstat -tulpn | grep ":${port_clean}\\b" | awk '{print $7}' | sed 's/[/].*//g' | head -n1)"
      port_service="$(head -n1 "/proc/${port_pid}/comm")"
      if [[ "$(find "/proc/${port_pid}/exe" -maxdepth 0 -printf '%u\n' 2>/dev/null)" != "unifi" ]]; then
        check_free_ports "${port_clean}"
        echo -e "${port_service}" &>> /tmp/EUS/services/list
        echo -e "${port_pid}" &>> /tmp/EUS/services/pid_list
        sed -i "s/^$(echo "${port}" | cut -d'/' -f3 | cut -d'.' -f1)\.$(echo "${port}" | cut -d'/' -f3 | cut -d'.' -f2)\.port/#&/" "/usr/lib/unifi/data/system.properties"
        echo -e "${GRAY_R}#${RESET} Changing the $(echo "${port}" | cut -d'/' -f4) to ${free_port}..."
        if echo -e "$(echo "${port}" | cut -d'/' -f3 | cut -d'.' -f1).$(echo "${port}" | cut -d'/' -f3 | cut -d'.' -f2).port=${free_port}" >> /usr/lib/unifi/data/system.properties 2>> "${eus_dir}/logs/change-default-ports.log"; then
          echo -e "${GREEN}#${RESET} Successfully changed the $(echo "${port}" | cut -d'/' -f4) to ${free_port}! \\n"
          echo -e "${port_clean}/${free_port}/$(echo "${port}" | cut -d'/' -f4)" &>> "/tmp/EUS/ports/new-ports"
        else
          echo -e "${RED}#${RESET} Failed to change the $(echo "${port}" | cut -d'/' -f4) port."
        fi
      fi
    fi
  done
  chown unifi:unifi /usr/lib/unifi/data/system.properties
}

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                  Ask to keep script or delete                                                                                   #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

support_file_requests_opt_in() {
  if [[ "$(jq -r '.database["support-file-upload"]' "${eus_dir}/db/db.json")" != 'true' ]]; then
    opt_in_requests="$(jq -r '.database["opt-in-requests"]' "${eus_dir}/db/db.json")"
    ((opt_in_requests=opt_in_requests+1))
    if [[ "${opt_in_requests}" -ge '3' ]]; then
      opt_in_rotations="$(jq -r '.database["opt-in-rotations"]' "${eus_dir}/db/db.json")"
      ((opt_in_rotations=opt_in_rotations+1))
      if [[ "$(dpkg-query --showformat='${version}' --show jq 2> /dev/null | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
        jq '."database" += {"opt-in-rotations": "'"${opt_in_rotations}"'"}' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
      else
        jq --arg opt_in_rotations "$opt_in_rotations" '.database = (.database + {"opt-in-rotations": $opt_in_rotations})' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
      fi
      eus_database_move
      if [[ "$(dpkg-query --showformat='${version}' --show jq 2> /dev/null | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
        jq --arg opt_in_requests "0" '."database" += {"opt-in-requests": "'"${opt_in_requests}"'"}' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
      else
        jq --arg opt_in_requests "$opt_in_requests" '.database = (.database + {"opt-in-requests": $opt_in_requests})' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
      fi
      eus_database_move
    else
      if [[ "$(dpkg-query --showformat='${version}' --show jq 2> /dev/null | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
        jq '."database" += {"opt-in-requests": "'"${opt_in_requests}"'"}' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
      else
        jq --arg opt_in_requests "$opt_in_requests" '.database = (.database + {"opt-in-requests": $opt_in_requests})' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
      fi
      eus_database_move
    fi
  fi
}

support_file_upload_opt_in() {
  if [[ "$(jq -r '.database["support-file-upload"]' "${eus_dir}/db/db.json")" != 'true' && "$(jq -r '.database["opt-in-requests"]' "${eus_dir}/db/db.json")" == '0' ]]; then
    if [[ "${installing_required_package}" != 'yes' ]]; then
      if [[ "${script_option_skip}" != 'true' ]]; then echo -e "${GREEN}---${RESET}\\n"; fi
    else
      if [[ "${script_option_skip}" != 'true' ]]; then header; fi
    fi
    if [[ "${script_option_skip}" != 'true' ]]; then echo -e "${GRAY_R}#${RESET} The script generates support files when failures are detected, these can help Glenn R. to"; echo -e "${GRAY_R}#${RESET} improve the script quality for the Community and resolve your issues in future versions of the script.\\n"; read -rp $'\033[39m#\033[0m Do you want to automatically upload the support files? (Y/n) ' yes_no; fi
    case "$yes_no" in
        [Nn]*) upload_support_files="false";;
        *) upload_support_files="true";;
    esac
    if [[ "$(dpkg-query --showformat='${version}' --show jq 2> /dev/null | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
      jq '."database" += {"support-file-upload": "'"${upload_support_files}"'"}' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
    else
      jq --arg upload_support_files "$upload_support_files" '.database = (.database + {"support-file-upload": $upload_support_files})' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
    fi
    eus_database_move
  fi
}
support_file_upload_opt_in
support_file_requests_opt_in

script_removal() {
  if [[ "$(jq -r '.database["keep-script-on-system"]' "${eus_dir}/db/db.json")" != 'true' ]]; then
    header
    read -rp $'\033[39m#\033[0m Do you want to keep the script on your system after completion? (Y/n) ' yes_no
    case "$yes_no" in
        [Nn]*) keep_script_on_system="false";;
        *) keep_script_on_system="true";;
    esac
    if [[ "$(dpkg-query --showformat='${version}' --show jq 2> /dev/null | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
      jq '."database" += {"keep-script-on-system": "'"${keep_script_on_system}"'"}' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
    else
      jq --arg keep_script_on_system "$keep_script_on_system" '.database = (.database + {"keep-script-on-system": $keep_script_on_system})' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
    fi
    eus_database_move
  fi
}

if [[ "${script_option_skip}" != 'true' ]]; then
  script_removal
fi

if [[ "$(jq '.database | has("mongodb-key-check-reset")' "${eus_dir}/db/db.json")" == 'true' ]]; then
  jq 'del(.database."mongodb-key-check-reset")' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
  eus_database_move
fi

# Expired MongoDB key check
while read -r mongodb_repo_version; do
  # Update the MongoDB keys if there are multiple in 1 file.
  while read -r mongodb_repository_list; do
    if [[ "$(gpg "$(grep -iE "(signed-by=|Signed-By:|Signed-By )[[:space:]]*[^ ]*" "${mongodb_repository_list}" | sed -E 's/.*(signed-by=|Signed-By:|Signed-By )[[:space:]]*([^ ]*).*/\2/' | head -n 1)" 2>&1 | grep -c "^pub")" -gt "1" ]]; then
      if [[ "${mongodb_repo_version//./}" =~ (30|32|34|36|40|42|44|50|60|70|80) ]]; then
        mongodb_key_update="true"
        mongodb_version_major_minor="${mongodb_repo_version}"
        mongodb_org_v="${mongodb_repo_version//./}"
        add_mongodb_repo
        continue
      fi
    fi
  done < <(grep -sriIl "${mongodb_repo_version} main\\|${mongodb_repo_version} multiverse" /etc/apt/sources.list /etc/apt/sources.list.d/)
  #
  if [[ "$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/mongodb-release?version=${mongodb_repo_version}" 2> /dev/null | jq -r '.updated' 2> /dev/null)" -ge "$(jq -r '.database["mongodb-key-last-check"]' "${eus_dir}/db/db.json")" ]]; then
    if [[ "${expired_header}" != 'true' ]]; then if header; then expired_header="true"; fi; fi
    if [[ "${expired_mongodb_check_message}" != 'true' ]]; then if echo -e "${GRAY_R}#${RESET} Checking for expired MongoDB repository keys..."; then expired_mongodb_check_message="true"; fi; fi
    if [[ "${expired_mongodb_check_message}" == 'true' ]]; then echo -e "${YELLOW}#${RESET} The script detected that the repository key for MongoDB version ${mongodb_repo_version} has been updated by MongoDB... \\n"; fi
    if [[ "${mongodb_repo_version//./}" =~ (30|32|34|36|40|42|44|50|60|70|80) ]]; then
      mongodb_key_update="true"
      mongodb_version_major_minor="${mongodb_repo_version}"
      mongodb_org_v="${mongodb_repo_version//./}"
      add_mongodb_repo
      continue
    fi
  fi
  while read -r repo_file; do
    if ! grep -ioq "trusted=yes" "${repo_file}" && [[ "$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/mongodb-release?version=${mongodb_repo_version}" 2> /dev/null | jq -r '.expired' 2> /dev/null)" == 'true' ]]; then
      if [[ "${expired_header}" != 'true' ]]; then if header; then expired_header="true"; fi; fi
      if [[ "${expired_mongodb_check_message}" != 'true' ]]; then if echo -e "${GRAY_R}#${RESET} Checking for expired MongoDB repository keys..."; then expired_mongodb_check_message="true"; fi; fi
      if [[ "${mongodb_repo_version//./}" =~ (30|32|34|36|40|42|44|50|60|70|80) ]]; then
        if [[ "${expired_mongodb_check_message}" == 'true' ]]; then echo -e "${YELLOW}#${RESET} The script will add a new repository entry for MongoDB version ${mongodb_repo_version}... \\n"; fi
        mongodb_key_update="true"
        mongodb_version_major_minor="${mongodb_repo_version}"
        mongodb_org_v="${mongodb_repo_version//./}"
        add_mongodb_repo
      else
        eus_create_directories "repository/archived"
        if [[ "${expired_mongodb_check_message}" == 'true' ]]; then echo -e "\\n${GRAY_R}#${RESET} The repository for version ${mongodb_repo_version} will be moved to \"${eus_dir}/repository/archived/$(basename -- "${repo_file}")\"..."; fi
        if mv "${repo_file}" "${eus_dir}/repository/archived/$(basename -- "${repo_file}")" &>> "${eus_dir}/logs/repository-archiving.log"; then echo -e "${GREEN}#${RESET} Successfully moved the repository list to \"${eus_dir}/repository/archived/$(basename -- "${repo_file}")\"! \\n"; else echo -e "${RED}#${RESET} Failed to move the repository list to \"${eus_dir}/repository/archived/$(basename -- "${repo_file}")\"... \\n"; fi
        mongodb_expired_archived="true"
      fi
    fi
  done < <(grep -sriIl "${mongodb_repo_version} main\\|${mongodb_repo_version} multiverse" /etc/apt/sources.list /etc/apt/sources.list.d/)
  if [[ "${expired_mongodb_check_message_3}" != 'true' ]]; then if [[ "${expired_mongodb_check_message}" == 'true' && "${mongodb_key_update}" != 'true' && "${mongodb_expired_archived}" != 'true' ]]; then echo -e "${GREEN}#${RESET} The script didn't detect any expired MongoDB repository keys! \\n"; expired_mongodb_check_message_3="true"; sleep 3; fi; fi
done < <(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep mongodb | grep -io "[0-9].[0-9]" | awk '!NF || !seen[$0]++')
if [[ "${mongodb_key_update}" == 'true' ]]; then run_apt_get_update_with_sha1_fallback; unset mongodb_key_update; sleep 3; fi

# Update the MongoDB Check time in the EUS database.
if [[ "$(jq -r '.database["mongodb-key-last-check"]' "${eus_dir}/db/db.json")" == 'null' ]]; then
  mongodb_key_check_time="$(date +%s)"
  if [[ "$(dpkg-query --showformat='${version}' --show jq 2> /dev/null | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
    jq --arg mongodb_key_check_time "${mongodb_key_check_time}" '."database" += {"mongodb-key-last-check": "'"${mongodb_key_check_time}"'"}' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
  else
    jq --arg mongodb_key_check_time "$mongodb_key_check_time" '.database = (.database + {"mongodb-key-last-check": $mongodb_key_check_time})' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
  fi
  eus_database_move
fi

daemon_reexec() {
  if [[ "${limited_functionality}" != 'true' ]]; then
    if ! systemctl daemon-reexec &>> "${eus_dir}/logs/daemon-reexec.log"; then
      echo -e "${RED}#${RESET} Failed to re-execute the systemctl daemon... \\n"
      sleep 3
    fi
  fi
}
daemon_reexec

##########################################################################################################################################################################
#                                                                                                                                                                        #
#                                                                         Java Install functions                                                                         #
#                                                                                                                                                                        #
##########################################################################################################################################################################

adoptium_java() {
  if [[ "${os_codename}" =~ (wheezy|jessie|forky|lunar|impish|eoan|disco|cosmic|mantic) ]]; then
    if ! curl "${curl_argument[@]}" "https://packages.adoptium.net/artifactory/deb/dists/" | sed -e 's/<[^>]*>//g' -e '/^$/d' -e '/\/\//d' -e '/function/d' -e '/location/d' -e '/}/d' -e 's/\///g' -e '/Name/d' -e '/Index/d' -e '/\.\./d' -e '/Artifactory/d' | awk '{print $1}' | grep -iq "${os_codename}"; then
      if [[ "${os_codename}" =~ (jessie) ]]; then
        os_codename="wheezy"
        adoptium_adjusted_os_codename="true"
      elif [[ "${os_codename}" =~ (forky|unstable) ]]; then
        os_codename="bookworm"
        adoptium_adjusted_os_codename="true"
      elif [[ "${os_codename}" =~ (lunar|impish) ]]; then
        os_codename="jammy"
        adoptium_adjusted_os_codename="true"
      elif [[ "${os_codename}" =~ (eoan|disco|cosmic) ]]; then
        os_codename="focal"
        adoptium_adjusted_os_codename="true"
      elif [[ "${os_codename}" =~ (mantic) ]]; then
        os_codename="noble"
        adoptium_adjusted_os_codename="true"
      fi
    fi
  fi
  remove_older_adoptium_repositories
  if curl "${curl_argument[@]}" "https://packages.adoptium.net/artifactory/deb/dists/" | sed -e 's/<[^>]*>//g' -e '/^$/d' -e '/\/\//d' -e '/function/d' -e '/location/d' -e '/}/d' -e 's/\///g' -e '/Name/d' -e '/Index/d' -e '/\.\./d' -e '/Artifactory/d' | awk '{print $1}' | grep -iq "${os_codename}"; then
    echo -e "${GRAY_R}#${RESET} Adding the key for adoptium packages..."
    aptkey_depreciated
    if [[ "${apt_key_deprecated}" == 'true' ]]; then
      echo -e "$(date +%F-%T.%6N) | packages.adoptium.net repository key.\\n" &>> "${eus_dir}/logs/repository-keys.log"
      if curl "${curl_argument[@]}" -fSL "https://packages.adoptium.net/artifactory/api/gpg/key/public" 2>&1 | tee -a "${eus_dir}/logs/repository-keys.log" | gpg -o "/etc/apt/keyrings/packages-adoptium.gpg" --dearmor --yes &> /dev/null; then
        adoptium_curl_exit_status="${PIPESTATUS[0]}"
        adoptium_gpg_exit_status="${PIPESTATUS[2]}"
        if [[ "${adoptium_curl_exit_status}" -eq "0" && "${adoptium_gpg_exit_status}" -eq "0" && -s "/etc/apt/keyrings/packages-adoptium.gpg" ]]; then
          echo -e "${GREEN}#${RESET} Successfully added the key for adoptium packages! \\n"; signed_by_value_adoptium="signed-by=/etc/apt/keyrings/packages-adoptium.gpg"; deb822_signed_by_value="\nSigned-By: /etc/apt/keyrings/packages-adoptium.gpg"
          repository_key_location="/etc/apt/keyrings/packages-adoptium.gpg"; check_repository_key_permissions
        else
          abort_reason="Failed to add the key for adoptium packages."; abort
        fi
      else
        abort_reason="Failed to fetch the key for adoptium packages."
        abort
      fi
    else
      echo -e "$(date +%F-%T.%6N) | packages.adoptium.net repository key.\\n" &>> "${eus_dir}/logs/repository-keys.log"
      if curl "${curl_argument[@]}" -fSL "https://packages.adoptium.net/artifactory/api/gpg/key/public" 2>&1 | tee -a "${eus_dir}/logs/repository-keys.log" | apt-key add - &> /dev/null; then
        adoptium_curl_exit_status="${PIPESTATUS[0]}"
        adoptium_apt_key_exit_status="${PIPESTATUS[2]}"
        if [[ "${adoptium_curl_exit_status}" -eq "0" && "${adoptium_apt_key_exit_status}" -eq "0" ]]; then
          echo -e "${GREEN}#${RESET} Successfully added the key for adoptium packages! \\n"
        else
          abort_reason="Failed to add the key for adoptium packages."; abort
        fi
      else
        abort_reason="Failed to fetch the key for adoptium packages."
        abort
      fi
    fi
    echo -e "${GRAY_R}#${RESET} Adding the adoptium packages repository..."
    if [[ "${use_deb822_format}" == 'true' ]]; then
      # DEB822 format
      adoptium_repo_entry="Types: deb\nURIs: ${http_or_https}://packages.adoptium.net/artifactory/deb\nSuites: ${os_codename}\nComponents: main${deb822_signed_by_value}"
    else
      # Traditional format
      adoptium_repo_entry="deb [ ${signed_by_value_adoptium} ] ${http_or_https}://packages.adoptium.net/artifactory/deb ${os_codename} main"
    fi
    if echo -e "${adoptium_repo_entry}" &> "/etc/apt/sources.list.d/glennr-packages-adoptium.${source_file_format}"; then
      echo -e "${GREEN}#${RESET} Successfully added the adoptium packages repository!\\n" && sleep 2
    else
      abort_reason="Failed to add the adoptium packages repository."
      abort
    fi
    check_default_repositories
    if [[ "${os_codename}" =~ (wheezy|jessie|stretch) ]]; then
      repo_codename="buster"
      repo_component="main"
      get_repo_url
      add_repositories
      get_distro
    fi
    repo_component="main"
    get_repo_url
    add_repositories
    run_apt_get_update_with_sha1_fallback
  else
    { echo "# Could not find \"${os_codename}\" on https://packages.adoptium.net/artifactory/deb/dists/"; echo "# List of what was found:"; curl "${curl_argument[@]}" "https://packages.adoptium.net/artifactory/deb/dists/" | sed -e 's/<[^>]*>//g' -e '/^$/d' -e '/\/\//d' -e '/function/d' -e '/location/d' -e '/}/d' -e 's/\///g' -e '/Name/d' -e '/Index/d' -e '/\.\./d' -e '/Artifactory/d' | awk '{print $1}'; } &>> "${eus_dir}/logs/adoptium.log"
  fi
  if [[ "${adoptium_adjusted_os_codename}" == 'true' ]]; then get_distro; fi
}

openjdk_java() {
  if [[ "${repo_codename}" =~ (precise|trusty|utopic|vivid|wily|yakkety|zesty|artful|xenial|bionic|cosmic) ]]; then
    if [[ "${architecture}" =~ (amd64|i386) ]]; then
      repo_url="http://ppa.launchpad.net/openjdk-r/ppa/ubuntu"
      repo_component="main"
      repo_key="EB9B1D8886F44E2A"
      repo_key_name="openjdk-ppa"
    else
      repo_url="${http_or_https}://ports.ubuntu.com"
      repo_codename_argument="-security"
      repo_component="main universe"
    fi
    add_repositories
  elif [[ "${repo_codename}" =~ (disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing|resolute) ]]; then
    if [[ "${architecture}" =~ (amd64|i386) ]]; then
      get_repo_url_security_url="true"
      get_repo_url
      repo_codename_argument="-security"
      repo_component="main universe"
    else
      repo_url="${http_or_https}://ports.ubuntu.com"
      repo_codename_argument="-security"
      repo_component="main universe"
    fi
    add_repositories
    repo_component="main"
    add_repositories
  elif [[ "${os_codename}" == "jessie" ]]; then
    check_dpkg_lock
    echo -e "${GRAY_R}#${RESET} ${openjdk_variable} ${required_java_version}-jre-headless..."
    if ! "${EUS_APT_ENV[@]}" env DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install -t jessie-backports "${required_java_version}-jre-headless" &>> "${eus_dir}/logs/apt.log" || [[ "${old_openjdk_version}" == 'true' ]]; then
      echo -e "${RED}#${RESET} Failed to ${openjdk_variable_3} ${required_java_version}-jre-headless in the first run...\\n"
      if [[ "$(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -P -c "^deb http[s]*://archive.debian.org/debian jessie-backports main")" -eq "0" ]]; then
        echo "deb ${http_or_https}://archive.debian.org/debian jessie-backports main" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
        locate_http_proxy
        if [[ -n "$http_proxy" ]]; then
          apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --keyserver-options http-proxy="${http_proxy}" --recv-keys 8B48AD6246925553 7638D0442B90D010 || abort
        elif [[ -f /etc/apt/apt.conf ]]; then
          apt_http_proxy="$(grep "http.*Proxy" /etc/apt/apt.conf | awk '{print $2}' | sed 's/[";]//g')"
          if [[ -n "${apt_http_proxy}" ]]; then
            apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --keyserver-options http-proxy="${apt_http_proxy}" --recv-keys 8B48AD6246925553 7638D0442B90D010 || abort
          fi
        else
          apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 8B48AD6246925553 7638D0442B90D010 || abort
        fi
        echo -e "${GRAY_R}#${RESET} Running apt-get update..."
        required_package="${required_java_version}-jre-headless"
        if apt-get update -o Acquire::Check-Valid-Until="false" &> /dev/null; then echo -e "${GREEN}#${RESET} Successfully ran apt-get update! \\n"; else abort_reason="Failed to ran apt-get update."; abort; fi
        echo -e "\\n------- ${required_package} installation ------- $(date +%F-%T.%6N) -------\\n" &>> "${eus_dir}/logs/apt.log"
        if "${EUS_APT_ENV[@]}" env DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install -t jessie-backports "${required_java_version}-jre-headless" &>> "${eus_dir}/logs/apt.log"; then echo -e "${GREEN}#${RESET} Successfully installed ${required_package}! \\n" && sleep 2; else abort_reason="Failed to install ${required_package}."; abort; fi
        sed -i '/jessie-backports/d' /etc/apt/sources.list.d/glennr-install-script.list
        unset required_package
      fi
    fi
  elif [[ "${repo_codename}" =~ (stretch|buster|bullseye|bookworm|trixie|forky|unstable) ]]; then
    if [[ "${required_java_version}" == "openjdk-8" ]]; then
      repo_codename="stretch"
      repo_component="main"
      get_repo_url
      add_repositories
    elif [[ "${required_java_version}" =~ (openjdk-11|openjdk-17) ]]; then
      if [[ "${repo_codename}" =~ (stretch|buster) ]] && [[ "${required_java_version}" =~ (openjdk-11) ]]; then repo_codename="bullseye"; fi
      if [[ "${repo_codename}" =~ (bookworm|trixie|forky|unstable) ]] && [[ "${required_java_version}" =~ (openjdk-11) ]]; then repo_codename="unstable"; fi
      if [[ "${repo_codename}" =~ (trixie|forky|unstable) ]] && [[ "${required_java_version}" =~ (openjdk-17) ]]; then repo_codename="bookworm"; fi
      if [[ "${repo_codename}" =~ (stretch|buster) ]] && [[ "${required_java_version}" =~ (openjdk-17) ]]; then repo_codename="bullseye"; fi
      repo_component="main"
      get_repo_url
      add_repositories
    fi
  fi
}

network_install_dependencies_check() {
  if [[ "${required_java_version}" == "openjdk-8" ]]; then
    unifi_dependencies_list=( "binutils" "ca-certificates-java" "java-common" "jsvc" "libcommons-daemon-java" "libcap2" )
  else
    unifi_dependencies_list=( "binutils" "ca-certificates-java" "java-common" "libcap2" )
  fi
  for unifi_dependency in "${unifi_dependencies_list[@]}"; do
    if ! "$(which dpkg)" -l "${unifi_dependency}" 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
      if [[ "${unifi_dependencies_mesasge}" != 'true' ]]; then header; echo -e "${GRAY_R}#${RESET} Preparing installation of the UniFi Network Application dependencies...\\n"; sleep 2; unifi_dependencies_mesasge="true"; fi
      echo -e "\\n------- UniFi Dependecy \"${unifi_dependency}\" installation ------- $(date +%F-%T.%6N) -------\\n" &>> "${eus_dir}/logs/apt.log"
      if ! apt-cache search --names-only ^"${unifi_dependency}" | awk '{print $1}' | grep -ioq "${unifi_dependency}"; then
        get_repo_url
        if [[ "${repo_codename}" =~ (precise|trusty|utopic|vivid|wily|yakkety|zesty|artful|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing|resolute) ]]; then
          repo_component="main universe"
        elif [[ "${repo_codename}" =~ (wheezy|jessie|stretch|buster|bullseye|bookworm|trixie|forky|unstable) ]]; then
          repo_component="main"
        fi
        add_repositories
      fi
      required_package="${unifi_dependency}"
      apt_get_install_package
    fi
  done
}

available_java_packages_check() {
  if apt-cache search --names-only ^"openjdk-${required_java_version_short}-jre-headless" | grep -ioq "openjdk-${required_java_version_short}-jre-headless"; then openjdk_available="true"; else unset openjdk_available; fi
  if apt-cache search --names-only ^"temurin-${required_java_version_short}-jre|temurin-${required_java_version_short}-jdk" | grep -ioq "temurin-${required_java_version_short}-jre\\|temurin-${required_java_version_short}-jdk"; then temurin_available="true"; else unset temurin_available; fi
}

update_ca_certificates() {
  if [[ "${update_ca_certificates_ran}" != 'true' ]]; then
    echo -e "${GRAY_R}#${RESET} Updating the ca-certificates..."
    rm /etc/ssl/certs/java/cacerts 2> /dev/null
    if update-ca-certificates -f &> /dev/null; then
      echo -e "${GREEN}#${RESET} Successfully updated the ca-certificates\\n" && sleep 3
      if [[ -e "/usr/bin/printf" ]]; then /usr/bin/printf '\xfe\xed\xfe\xed\x00\x00\x00\x02\x00\x00\x00\x00\xe2\x68\x6e\x45\xfb\x43\xdf\xa4\xd9\x92\xdd\x41\xce\xb6\xb2\x1c\x63\x30\xd7\x92' > /etc/ssl/certs/java/cacerts; fi
      if [[ -e "/var/lib/dpkg/info/ca-certificates-java.postinst" ]]; then /var/lib/dpkg/info/ca-certificates-java.postinst configure &> /dev/null; fi
      update_ca_certificates_ran="true"
    else
      echo -e "${RED}#${RESET} Failed to update the ca-certificates...\\n" && sleep 3
    fi
  fi
}

java_home_check() {
  if [[ -z "${required_java_version_short}" ]]; then java_required_variables; fi
  if "$(which dpkg)" -l | grep "^ii\\|^hi" | grep -iq "openjdk-${required_java_version_short}\\|temurin-${required_java_version_short}"; then
    java_readlink="$(readlink -f "$( command -v java )" | sed "s:/bin/.*$::")"
    if ! echo "${java_readlink}" | grep -ioq "${required_java_version_short}"; then java_readlink="$(update-java-alternatives --list | grep "${required_java_version_short}" | awk '{print $3}' | head -n1)"; fi
    java_home_location="JAVA_HOME=${java_readlink}"
    current_java_home="$(grep -si "^JAVA_HOME" /etc/default/unifi)"
    if [[ -n "${java_home_location}" ]]; then
      if [[ "${current_java_home}" != "${java_home_location}" ]]; then
        if [[ -e "/etc/default/unifi" ]]; then sed -i '/JAVA_HOME/d' /etc/default/unifi; fi
        echo "${java_home_location}" >> /etc/default/unifi
      fi
    fi
    current_java_home="$(grep -si "^JAVA_HOME" /etc/environment)"
    if [[ -n "${java_home_location}" ]]; then
      if [[ "${current_java_home}" != "${java_home_location}" ]]; then
        if [[ -e "/etc/default/unifi" ]]; then sed -i 's/^JAVA_HOME/#JAVA_HOME/' /etc/environment; fi
        echo "${java_home_location}" >> /etc/environment
        # shellcheck disable=SC1091
        source /etc/environment
      fi
    fi
  fi
}

java_cleanup_not_required_versions() {
  java_required_variables
  if "$(which dpkg)" -l | grep "^ii\\|^hi" | grep -iq "openjdk-${required_java_version_short}"; then
    required_java_version_installed="true"
  fi
  if "$(which dpkg)" -l | grep "^ii\\|^hi" | grep -i "openjdk-.*-\\|oracle-java.*\\|temurin-.*-" | grep -vq "openjdk-${required_java_version_short}\\|oracle-java${required_java_version_short}\\|openjdk-${required_java_version_short}\\|temurin-${required_java_version_short}"; then
    unsupported_java_version_installed="true"
  fi
  if [[ "${required_java_version_installed}" == 'true' && "${unsupported_java_version_installed}" == 'true' && "${script_option_skip}" != 'true' && "${unifi_core_system}" != 'true' ]]; then
    header_red
    echo -e "${GRAY_R}#${RESET} Unsupported JAVA version(s) are detected, do you want to uninstall them?"
    echo -e "${GRAY_R}#${RESET} This may remove packages that depend on these java versions."
    read -rp $'\033[39m#\033[0m Do you want to proceed with uninstalling the unsupported JAVA version(s)? (y/N) ' yes_no
    case "$yes_no" in
         [Yy]*)
            header
            while read -r java_package; do
              echo -e "${GRAY_R}#${RESET} Removing ${java_package}..."
              if "${EUS_APT_ENV[@]}" env DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' remove "${java_package}" &>> "${eus_dir}/logs/java-uninstall.log"; then
                echo -e "${GREEN}#${RESET} Successfully removed ${java_package}! \\n"
              else
                echo -e "${RED}#${RESET} Successfully removed ${java_package}... \\n"
              fi
            done < <("$(which dpkg)" -l | grep "^ii\\|^hi\\|^ri\\|^pi\\|^ui\\|^iU" | grep -i "openjdk-.*-\\|oracle-java.*\\|temurin-.*-" | grep -v "openjdk-${required_java_version_short}\\|oracle-java${required_java_version_short}\\|openjdk-${required_java_version_short}\\|temurin-${required_java_version_short}" | awk '{print $2}' | sed 's/:.*//')
            sleep 3;;
         *) ;;
    esac
  fi
}

java_configure_default() {
  if "$(which dpkg)" -l | grep "^ii\\|^hi" | grep -iq "openjdk-${required_java_version_short}\\|temurin-${required_java_version_short}"; then
    update_java_alternatives="$(update-java-alternatives --list | grep "^java-1.${required_java_version_short}.*openjdk\\|temurin-${required_java_version_short}" | awk '{print $1}' | head -n1)"
    if [[ -n "${update_java_alternatives}" ]]; then
      update-java-alternatives --set "${update_java_alternatives}" &> /dev/null
    fi
    update_alternatives="$(update-alternatives --list java | grep "java-${required_java_version_short}-openjdk\\|temurin-${required_java_version_short}" | awk '{print $1}' | head -n1)"
    if [[ -n "${update_alternatives}" ]]; then
      update-alternatives --set java "${update_alternatives}" &> /dev/null
    fi
    header
    update_ca_certificates
  fi
}

java_install_check() {
  java_required_variables
  if "$(which dpkg)" -l | grep "^ii\\|^hi" | grep -iq "openjdk-8"; then
    openjdk_version="$("$(which dpkg)" -l | grep "^ii\\|^hi" | grep "openjdk-8" | awk '{print $3}' | grep "^8u" | sed 's/-.*//g' | sed 's/8u//g' | grep -o '[[:digit:]]*' | sort -V | tail -n 1)"
    if [[ "${openjdk_version}" -lt '131' && "${required_java_version}" == "openjdk-8" ]]; then old_openjdk_version="true"; fi
  fi
  if "$(which dpkg)" -l | grep "^ii\\|^hi" | grep -iq "temurin-${required_java_version_short}-jdk"; then
    if ! "$(which dpkg)" -l | grep "^ii\\|^hi" | grep -iq "temurin-${required_java_version_short}-jre"; then
      if apt-cache search --names-only "^temurin-${required_java_version_short}-jre" | grep -ioq "temurin-${required_java_version_short}-jre"; then
        temurin_jdk_to_jre="true"
      fi
    fi
  fi
  if [[ -n "$(dpkg --print-foreign-architectures)" ]]; then if ! dpkg-query --show --showformat='${Package}:${Architecture}\n' | grep -iq "openjdk-${required_java_version_short}.*:${architecture}\\|temurin-${required_java_version_short}.*:${architecture}"; then incorrect_architecture_java="true"; java_architecture_flag=":${architecture}"; fi; fi
  if ! "$(which dpkg)" -l | grep "^ii\\|^hi" | grep -iq "openjdk-${required_java_version_short}\\|temurin-${required_java_version_short}" || [[ "${incorrect_architecture_java}" == 'true' ]] || [[ "${old_openjdk_version}" == 'true' ]] || [[ "${temurin_jdk_to_jre}" == 'true' ]]; then
    if [[ "${old_openjdk_version}" == 'true' ]]; then
      header_red
      echo -e "${RED}#${RESET} OpenJDK ${required_java_version_short} is to old...\\n" && sleep 2
      openjdk_variable="Updating"; openjdk_variable_3="Update"
    else
      header
      echo -e "${GREEN}#${RESET} Preparing OpenJDK/Temurin ${required_java_version_short} installation...\\n" && sleep 2
      openjdk_variable="Installing"; openjdk_variable_3="Install"
    fi
    openjdk_java
    if [[ "${unifi_core_system}" != 'true' ]]; then adoptium_java; fi
    run_apt_get_update_with_sha1_fallback
    available_java_packages_check
    java_install_attempts="$(apt-cache search --names-only ^"openjdk-${required_java_version_short}-jre-headless|temurin-${required_java_version_short}-jre|temurin-${required_java_version_short}-jdk" | awk '{print $1}' | wc -l)"
    until [[ "${java_install_attempts}" == "0" ]]; do
      if [[ "${openjdk_available}" == "true" && "${openjdk_attempted}" != 'true' ]]; then
        required_package="openjdk-${required_java_version_short}-jre-headless${java_architecture_flag}"; apt_get_install_package; openjdk_attempted="true"
        if "$(which dpkg)" -l | grep "^ii\\|^hi" | grep -iq "openjdk-${required_java_version_short}-jre-headless"; then break; fi
      fi
      if [[ "${temurin_available}" == "true" ]]; then
        if apt-cache search --names-only ^"temurin-${required_java_version_short}-jre" | grep -ioq "temurin-${required_java_version_short}-jre" && [[ "${temurin_jre_attempted}" != 'true' ]]; then
          required_package="temurin-${required_java_version_short}-jre${java_architecture_flag}"; apt_get_install_package; temurin_jre_attempted="true"
          if "$(which dpkg)" -l | grep "^ii\\|^hi" | grep -iq "temurin-${required_java_version_short}-jre"; then break; fi
        elif apt-cache search --names-only ^"temurin-${required_java_version_short}-jdk" | grep -ioq "temurin-${required_java_version_short}-jdk" && [[ "${temurin_jdk_attempted}" != 'true' ]]; then
          required_package="temurin-${required_java_version_short}-jdk${java_architecture_flag}"; apt_get_install_package; temurin_jdk_attempted="true"
          if "$(which dpkg)" -l | grep "^ii\\|^hi" | grep -iq "temurin-${required_java_version_short}-jdk"; then break; fi
        fi
      fi
      ((java_install_attempts=java_install_attempts-1))
    done
    if ! "$(which dpkg)" -l | grep "^ii\\|^hi" | grep -iq "openjdk-${required_java_version_short}-jre-headless\\|temurin-${required_java_version_short}-jre\\|temurin-${required_java_version_short}-jdk"; then abort_reason="Failed to install the required java version."; abort; fi
    unset java_install_attempts
    if "$(which dpkg)" -l | grep "^ii\\|^hi" | grep -iq "temurin-${required_java_version_short}-jre" && "$(which dpkg)" -l | grep "^ii\\|^hi" | grep -iq "temurin-${required_java_version_short}-jdk"; then
      echo -e "${GRAY_R}#${RESET} Removing temurin-${required_java_version_short}-jdk..."
      if "${EUS_APT_ENV[@]}" env DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg6::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' remove "temurin-${required_java_version_short}-jdk" &>> "${eus_dir}/logs/temurin-jdk-remove.log"; then
        echo -e "${GREEN}#${RESET} Successfully removed temurin-${required_java_version_short}-jdk! \\n"
      else
        echo -e "${RED}#${RESET} Failed to remove temurin-${required_java_version_short}-jdk... \\n"
      fi
    fi
  else
    header
    echo -e "${GREEN}#${RESET} Preparing OpenJDK/Temurin ${required_java_version_short} installation..."
    echo -e "${GRAY_R}#${RESET} OpenJDK/Temurin ${required_java_version_short} is already installed! \\n"
  fi
  sleep 3
  java_configure_default
  java_home_check
}

##########################################################################################################################################################################
#                                                                                                                                                                        #
#                                                                     UniFi deb Package modification                                                                     #
#                                                                                                                                                                        #
##########################################################################################################################################################################

unifi_deb_package_modification() {
  if "$(which dpkg)" -l | grep "^ii\\|^hi\\|^ri\\|^pi\\|^ui\\|^iU" | grep -iq "temurin-${required_java_version_short}-jdk"; then
    temurin_type="jdk"
    custom_unifi_deb_file_required="true"
  elif "$(which dpkg)" -l | grep "^ii\\|^hi\\|^ri\\|^pi\\|^ui\\|^iU" | grep -iq "temurin-${required_java_version_short}-jre"; then
    temurin_type="jre"
    if [[ "${first_digit_unifi}" -lt '8' ]]; then
      custom_unifi_deb_file_required="true"
    elif [[ "${first_digit_unifi}" -ge '8' ]]; then
      custom_unifi_deb_file_required="false"
    fi
  fi
  if "$(which dpkg)" -l | grep "^ii\\|^hi\\|^ri\\|^pi\\|^ui\\|^iU" | grep -qi "${required_java_version}" | grep -v "openjdk-${required_java_version_short}-jre-headless\\|temurin-${required_java_version_short}-jre\\|temurin-${required_java_version_short}-jdk"; then
    non_default_java_package="$("$(which dpkg)" -l | grep "^ii\\|^hi\\|^ri\\|^pi\\|^ui\\|^iU" | grep -i "${required_java_version}" | grep -v "openjdk-${required_java_version_short}-jre-headless\\|temurin-${required_java_version_short}-jre\\|temurin-${required_java_version_short}-jdk" | awk '{print $2}' | head -n1)"
    if ! "$(which dpkg)" -l | grep "^ii\\|^hi\\|^ri\\|^pi\\|^ui\\|^iU" | grep -ioq "openjdk-${required_java_version_short}-jre-headless\\|temurin-${required_java_version_short}-jre\\|temurin-${required_java_version_short}-jdk" && [[ -z "${non_default_java_package}" ]]; then custom_unifi_deb_file_required="true"; fi
  fi
  if "$(which dpkg)" -l | grep "^ii\\|^hi\\|^ri\\|^pi\\|^ui\\|^iU" | grep -iq "${gr_mongod_name}"; then
    unifi_deb_package_modification_mongodb_package="${gr_mongod_name}"
    custom_unifi_deb_file_required="true"
    prevent_mongodb_org_server_install
  fi
  if [[ "${custom_unifi_deb_file_required}" == 'true' ]]; then
    if [[ "$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/application-release?status" 2> /dev/null | jq -r '.availability' 2> /dev/null)" == "OK" ]]; then download_pre_build_deb_available="true"; fi
    if [[ -n "${unifi_deb_package_modification_mongodb_package}" && -n "${temurin_type}" ]]; then
      unifi_deb_package_modification_message_1="temurin-${required_java_version_short}-${temurin_type} and ${unifi_deb_package_modification_mongodb_package}"
      if [[ "${download_pre_build_deb_available}" == 'true' ]]; then
        pre_build_fw_update_dl_link="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/application-release?mongodb=${unifi_deb_package_modification_mongodb_package}&java=temurin-${required_java_version_short}-${temurin_type}&unifi-version=${first_digit_unifi}.${second_digit_unifi}.${third_digit_unifi}" | jq -r '."download_link"' | sed '/null/d' 2> "${eus_dir}/logs/locate-download.log")"
        pre_build_fw_update_dl_link_sha256sum="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/application-release?mongodb=${unifi_deb_package_modification_mongodb_package}&java=temurin-${required_java_version_short}-${temurin_type}&unifi-version=${first_digit_unifi}.${second_digit_unifi}.${third_digit_unifi}" | jq -r '.sha256sum' | sed '/null/d' 2> "${eus_dir}/logs/locate-download.log")"
      fi
    elif [[ -n "${temurin_type}" ]]; then
      unifi_deb_package_modification_message_1="temurin-${required_java_version_short}-${temurin_type}"
      if [[ "${download_pre_build_deb_available}" == 'true' ]]; then
        pre_build_fw_update_dl_link="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/application-release?java=temurin-${required_java_version_short}-${temurin_type}&unifi-version=${first_digit_unifi}.${second_digit_unifi}.${third_digit_unifi}" | jq -r '."download_link"' | sed '/null/d' 2> "${eus_dir}/logs/locate-download.log")"
        pre_build_fw_update_dl_link_sha256sum="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/application-release?java=temurin-${required_java_version_short}-${temurin_type}&unifi-version=${first_digit_unifi}.${second_digit_unifi}.${third_digit_unifi}" | jq -r '.sha256sum' | sed '/null/d' 2> "${eus_dir}/logs/locate-download.log")"
      fi
    elif [[ -n "${unifi_deb_package_modification_mongodb_package}" ]]; then
      unifi_deb_package_modification_message_1="${unifi_deb_package_modification_mongodb_package}"
      if [[ "${download_pre_build_deb_available}" == 'true' ]]; then
        pre_build_fw_update_dl_link="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/application-release?mongodb=${unifi_deb_package_modification_mongodb_package}&unifi-version=${first_digit_unifi}.${second_digit_unifi}.${third_digit_unifi}" | jq -r '."download_link"' | sed '/null/d' 2> "${eus_dir}/logs/locate-download.log")"
        pre_build_fw_update_dl_link_sha256sum="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/application-release?mongodb=${unifi_deb_package_modification_mongodb_package}&unifi-version=${first_digit_unifi}.${second_digit_unifi}.${third_digit_unifi}" | jq -r '.sha256sum' | sed '/null/d' 2> "${eus_dir}/logs/locate-download.log")"
      fi
    elif [[ -n "${non_default_java_package}" ]]; then
      unifi_deb_package_modification_message_1="${non_default_java_package}"
    fi
    if [[ -n "${pre_build_fw_update_dl_link}" ]]; then
      gr_unifi_temp=""
      eus_tmp_deb_name="${unifi_deb_file_name}_${first_digit_unifi}.${second_digit_unifi}.${third_digit_unifi}"
      eus_tmp_deb_var="gr_unifi_temp"
      eus_tmp_directory_check
      echo -e "$(date +%F-%T.%6N) | Downloading ${pre_build_fw_update_dl_link} to ${gr_unifi_temp}" &>> "${eus_dir}/logs/unifi-download.log"
      echo -e "${GRAY_R}#${RESET} Downloading UniFi Network Application version ${first_digit_unifi}.${second_digit_unifi}.${third_digit_unifi} built for ${unifi_deb_package_modification_message_1}..."
      if curl "${nos_curl_argument[@]}" --output "$gr_unifi_temp" "${pre_build_fw_update_dl_link}" &>> "${eus_dir}/logs/unifi-download.log"; then
        if command -v sha256sum &> /dev/null; then
          if [[ "$(sha256sum "$gr_unifi_temp" | awk '{print $1}')" == "${pre_build_fw_update_dl_link_sha256sum}" ]]; then
            pre_build_download_failure="false"
          else
            if curl "${nos_curl_argument[@]}" --output "$gr_unifi_temp" "${pre_build_fw_update_dl_link}" &>> "${eus_dir}/logs/unifi-download.log"; then
              if [[ "$(sha256sum "$gr_unifi_temp" | awk '{print $1}')" == "${pre_build_fw_update_dl_link_sha256sum}" ]]; then
                pre_build_download_failure="false"
              fi
            fi
          fi
        elif command -v dpkg-deb &> /dev/null; then
          if ! dpkg-deb --info "${gr_unifi_temp}" &> /dev/null; then
            if curl "${nos_curl_argument[@]}" --output "$gr_unifi_temp" "${pre_build_fw_update_dl_link}" &>> "${eus_dir}/logs/unifi-download.log"; then
              if ! dpkg-deb --info "${gr_unifi_temp}" &> /dev/null; then
                echo -e "$(date +%F-%T.%6N) | The file downloaded via ${pre_build_fw_update_dl_link} was not a debian file format..." &>> "${eus_dir}/logs/unifi-download.log"
                pre_build_download_failure="false"
              fi
            fi
          fi
        fi
      fi
    fi
    if [[ "${pre_build_download_failure}" != 'false' ]] || [[ -z "${pre_build_fw_update_dl_link}" ]]; then
      if [[ "${pre_build_download_failure}" != 'false' && -n "${pre_build_fw_update_dl_link}" ]]; then echo -e "${RED}#${RESET} Failed to download UniFi Network Application version ${first_digit_unifi}.${second_digit_unifi}.${third_digit_unifi} built for ${unifi_deb_package_modification_message_1}! \\n${RED}#${RESET} The script will attempt to built it locally... \\n"; fi
      eus_temp_dir="$(mktemp -d --tmpdir="${eus_tmp_directory_location}" unifi.deb.XXX)"
      echo -e "${GRAY_R}#${RESET} This setup is using ${unifi_deb_package_modification_message_1}... Editing the UniFi Network Application dependencies..."
      echo -e "\\n------- $(date +%F-%T.%6N) -------\\n" &>> "${eus_dir}/logs/unifi-custom-deb-file.log"
      if dpkg-deb -x "${unifi_temp}" "${eus_temp_dir}" &>> "${eus_dir}/logs/unifi-custom-deb-file.log"; then
        if dpkg-deb --control "${unifi_temp}" "${eus_temp_dir}/DEBIAN" &>> "${eus_dir}/logs/unifi-custom-deb-file.log"; then
          if [[ -e "${eus_temp_dir}/DEBIAN/control" ]]; then
            current_state_unifi_deb="$(stat -c "%y" "${eus_temp_dir}/DEBIAN/control")"
            if [[ -n "${temurin_type}" ]] && ! grep -iq "temurin-${required_java_version_short}-${temurin_type}" "${eus_temp_dir}/DEBIAN/control"; then if sed -i "s/openjdk-${required_java_version_short}-jre-headless/temurin-${required_java_version_short}-${temurin_type}/g" "${eus_temp_dir}/DEBIAN/control" &>> "${eus_dir}/logs/unifi-custom-deb-file.log"; then unifi_deb_package_modification_control_modified_success="true"; fi; fi
            if [[ -n "${non_default_java_package}" ]]; then if sed -i "s/openjdk-${required_java_version_short}-jre-headless/${non_default_java_package}/g" "${eus_temp_dir}/DEBIAN/control" &>> "${eus_dir}/logs/unifi-custom-deb-file.log"; then unifi_deb_package_modification_control_modified_success="true"; fi; fi
            if [[ -n "${unifi_deb_package_modification_mongodb_package}" ]]; then if sed -i "s/mongodb-org-server/${unifi_deb_package_modification_mongodb_package}/g" "${eus_temp_dir}/DEBIAN/control" &>> "${eus_dir}/logs/unifi-custom-deb-file.log"; then unifi_deb_package_modification_control_modified_success="true"; fi; fi
            if [[ "${unifi_deb_package_modification_control_modified_success}" == 'true' ]]; then
              echo -e "${GREEN}#${RESET} Successfully edited the dependencies of the UniFi Network Application deb file! \\n"
              if [[ "${current_state_unifi_deb}" != "$(stat -c "%y" "${eus_temp_dir}/DEBIAN/control")" ]]; then
                unifi_new_deb="$(basename "${unifi_temp}" .deb).new.deb"
                cat "${eus_temp_dir}/DEBIAN/control" &>> "${eus_dir}/logs/unifi-custom-deb-file.log"
                echo -e "${GRAY_R}#${RESET} Building a new UniFi Network Application deb file... This may take a while..."
                if "$(which dpkg)" -b "${eus_temp_dir}" "${unifi_new_deb}" &>> "${eus_dir}/logs/unifi-custom-deb-file.log"; then
                  unifi_temp="${unifi_new_deb}"
                  echo -e "${GREEN}#${RESET} Successfully built a new UniFi Network Application deb file! \\n"
                else
                  echo -e "${RED}#${RESET} Failed to build a new UniFi Network Application deb file...\\n"
                fi
              else
                echo -e "${RED}#${RESET} Failed to edit the dependencies of the UniFi Network Application deb file...\\n"
              fi
            else
              echo -e "${RED}#${RESET} Failed to edit the dependencies of the UniFi Network Application deb file...\\n"
            fi
          else
            echo -e "${RED}#${RESET} Failed to detect the required files to edit the dependencies of the UniFi Network Application...\\n"
          fi
        else
          echo -e "${RED}#${RESET} Failed to unpack the current UniFi Network Application deb file...\\n"
        fi
      else
        echo -e "${RED}#${RESET} Failed to edit the dependencies of the UniFi Network Application deb file...\\n"
      fi
      rm -rf "${eus_temp_dir}" &> /dev/null
    else
      echo -e "${GREEN}#${RESET} Successfully downloaded UniFi Network Application version ${first_digit_unifi}.${second_digit_unifi}.${third_digit_unifi} built for ${unifi_deb_package_modification_message_1}! \\n"
      unifi_temp="${gr_unifi_temp}"
    fi
  fi
}

##########################################################################################################################################################################
#                                                                                                                                                                        #
#                                                                       UniFi Ignore Dependencies                                                                        #
#                                                                                                                                                                        #
##########################################################################################################################################################################

ignore_unifi_package_dependencies() {
  if [[ -f "/tmp/EUS/ignore-depends" ]]; then rm --force /tmp/EUS/ignore-depends &> /dev/null; fi
  if ! "$(which dpkg)" -l | grep "^ii\\|^hi" | grep -Eiq "(mongodb-server|mongodb-org-server|mongod-armv8|mongod-amd64)[[:space:]]"; then echo -e "mongodb-server" &>> /tmp/EUS/ignore-depends; fi
  if "$(which dpkg)" -l | grep "^ii\\|^hi" | grep -Eiq "(mongodb-server|mongodb-org-server|mongod-armv8|mongod-amd64)[[:space:]]"; then
    ignore_unifi_package_dependencies_mongodb_version="$("$(which dpkg)" -l | grep -E "(mongodb-server|mongodb-org-server|mongod-armv8|mongod-amd64)[[:space:]]" | grep "^ii\\|^hi" | awk '{print $3}' | sed -e 's/.*://' -e 's/-.*//' -e 's/+.*//' -e 's/\.//g')"
    unset minimum_required_mongodb_version
    minimum_required_mongodb_version_check
    if [[ "${ignore_unifi_package_dependencies_mongodb_version::2}" -gt "${unifi_mongo_version_max}" ]]; then
      echo -e "mongodb-server" &>> /tmp/EUS/ignore-depends
    fi
    if [[ -n "${minimum_required_mongodb_version}" ]]; then 
      if [[ "${ignore_unifi_package_dependencies_mongodb_version::2}" -lt "${minimum_required_mongodb_version}" ]]; then
        echo -e "mongodb-server" &>> /tmp/EUS/ignore-depends
      fi
    fi
  fi
  if ! "$(which dpkg)" -l | grep "^ii\\|^hi" | grep -iq "${required_java_version}-jre-headless"; then echo -e "${required_java_version}-jre-headless" &>> /tmp/EUS/ignore-depends; fi
  if [[ -f /tmp/EUS/ignore-depends && -s /tmp/EUS/ignore-depends ]]; then IFS=" " read -r -a ignored_depends <<< "$(tr '\r\n' ',' < /tmp/EUS/ignore-depends | sed 's/.$//')"; rm --force /tmp/EUS/ignore-depends &> /dev/null; dpkg_ignore_depends_flag="--ignore-depends=${ignored_depends[*]}"; fi
}

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                 Installation Script starts here                                                                                 #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

mongodb_upgrade_check() {
  while read -r mongodb_upgrade_check_package; do
    mongodb_upgrade_check_from_version="$(dpkg-query --showformat='${Version}' --show "${mongodb_upgrade_check_package}" | sed 's/.*://' | sed 's/-.*//g' | sed 's/\.//g')"
    mongodb_upgrade_check_to_version="$(apt-cache madison "${mongodb_upgrade_check_package}" 2>/dev/null | awk '{print $3}' | sort -V | tail -n 1 | sed 's/.*://' | sed 's/-.*//g' | sed 's/\.//g')"
    if [[ "${mongodb_upgrade_check_to_version::2}" -gt "${mongodb_upgrade_check_from_version::2}" ]]; then
      check_dpkg_lock
      echo -e "${GRAY_R}#${RESET} Preventing ${mongodb_upgrade_check_package} from upgrading..."
      if echo "${mongodb_upgrade_check_package} hold" | "$(which dpkg)" --set-selections; then
        echo -e "${GREEN}#${RESET} Successfully prevented ${mongodb_upgrade_check_package} from upgrading! \\n"
      else
        echo -e "${RED}#${RESET} Failed to prevent ${mongodb_upgrade_check_package} from upgrading...\\n"
        if [[ "${mongodb_upgrade_check_remove_old_mongo_repo}" != 'true' ]]; then remove_older_mongodb_repositories; mongodb_upgrade_check_remove_old_mongo_repo="true"; run_apt_get_update_with_sha1_fallback; fi
      fi
    fi
  done < <("$(which dpkg)" -l | awk '{print $1,$2}' | awk '/ii.*mongo/ {print $2}' | sed 's/:.*//')
}

system_upgrade() {
  if [[ -f /tmp/EUS/upgrade/upgrade_list && -s /tmp/EUS/upgrade/upgrade_list ]]; then
    while read -r package; do
      check_dpkg_lock
      echo -e "\\n------- updating ${package} ------- $(date +%F-%T.%6N) -------\\n" &>> "${eus_dir}/logs/upgrade.log"
      echo -ne "\\r${GRAY_R}#${RESET} Updating package ${package}..."
      if "${EUS_APT_ENV[@]}" env DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' --only-upgrade install "${package}" 2>&1 | tee -a "${eus_dir}/logs/upgrade.log" > /tmp/EUS/apt/install.log; then
        if [[ "${PIPESTATUS[0]}" -eq "0" ]]; then echo -e "\\r${GREEN}#${RESET} Successfully updated package ${package}!"; fi
      elif tail -n1 /usr/lib/EUS/logs/upgrade.log | grep -ioq "Packages were downgraded and -y was used without --allow-downgrades" "${eus_dir}/logs/upgrade.log"; then
        check_dpkg_lock
        if "${EUS_APT_ENV[@]}" env DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' --only-upgrade --allow-downgrades install "${package}" 2>&1 | tee -a "${eus_dir}/logs/upgrade.log" > /tmp/EUS/apt/install.log; then
          if [[ "${PIPESTATUS[0]}" -eq "0" ]]; then
            echo -e "\\r${GREEN}#${RESET} Successfully updated package ${package}!"
            continue
          else
            echo -e "\\r${RED}#${RESET} Something went wrong during the update of package ${package}... \\n${RED}#${RESET} The script will continue with an apt-get upgrade...\\n"
            break
          fi
        fi
        echo -e "\\r${RED}#${RESET} Something went wrong during the update of package ${package}... \\n${RED}#${RESET} The script will continue with an apt-get upgrade...\\n"
        break
      fi
    done < /tmp/EUS/upgrade/upgrade_list
    echo ""
  fi
  if ls /tmp/EUS/apt/*.log 1> /dev/null 2>&1; then check_package_cache_file_corruption; check_extended_states_corruption; https_died_unexpectedly_check; check_time_date_for_repositories; cleanup_malformed_repositories; cleanup_duplicated_repositories; cleanup_unavailable_repositories; cleanup_conflicting_repositories; if [[ "${repository_changes_applied}" == 'true' ]]; then unset repository_changes_applied; run_apt_get_update_with_sha1_fallback; fi; fi
  check_dpkg_lock
  echo -e "\\n------- apt-get upgrade ------- $(date +%F-%T.%6N) -------\\n" &>> "${eus_dir}/logs/upgrade.log"
  echo -e "${GRAY_R}#${RESET} Running apt-get upgrade..."
  if "${EUS_APT_ENV[@]}" env DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' upgrade 2>&1 | tee -a "${eus_dir}/logs/upgrade.log" > /tmp/EUS/apt/upgrade.log; then if [[ "${PIPESTATUS[0]}" -eq "0" ]]; then echo -e "${GREEN}#${RESET} Successfully ran apt-get upgrade! \\n"; else echo -e "${RED}#${RESET} Failed to run apt-get upgrade... \\n"; fi; fi
  check_dpkg_lock
  echo -e "\\n------- apt-get dist-upgrade ------- $(date +%F-%T.%6N) -------\\n" &>> "${eus_dir}/logs/upgrade.log"
  echo -e "${GRAY_R}#${RESET} Running apt-get dist-upgrade..."
  if "${EUS_APT_ENV[@]}" env DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' dist-upgrade 2>&1 | tee -a "${eus_dir}/logs/upgrade.log" > /tmp/EUS/apt/dist-upgrade.log; then if [[ "${PIPESTATUS[0]}" -eq "0" ]]; then echo -e "${GREEN}#${RESET} Successfully ran apt-get dist-upgrade! \\n"; else echo -e "${RED}#${RESET} Failed to run apt-get dist-upgrade... \\n"; fi; fi
  echo -e "${GRAY_R}#${RESET} Running apt-get autoremove..."
  if apt-get -y autoremove &>> "${eus_dir}/logs/apt-cleanup.log"; then echo -e "${GREEN}#${RESET} Successfully ran apt-get autoremove! \\n"; else echo -e "${RED}#${RESET} Failed to run apt-get autoremove"; fi
  echo -e "${GRAY_R}#${RESET} Running apt-get autoclean..."
  if apt-get -y autoclean &>> "${eus_dir}/logs/apt-cleanup.log"; then echo -e "${GREEN}#${RESET} Successfully ran apt-get autoclean! \\n"; else echo -e "${RED}#${RESET} Failed to run apt-get autoclean"; fi
  sleep 3
  daemon_reexec
}

system_update_check() {
  cleanup_codename_mismatch_repos
  header
  echo -e "${GRAY_R}#${RESET} Checking if your system is up-to-date...\\n" && sleep 1
  run_apt_get_update_with_sha1_fallback
  mongodb_upgrade_check
  echo -e "${GRAY_R}#${RESET} The package(s) below can be upgraded!"
  echo -e "\\n${GRAY_R}----${RESET}\\n"
  rm --force /tmp/EUS/upgrade/upgrade_list &> /dev/null
  { apt-get --just-print upgrade 2>&1 | perl -ne 'if (/Inst\s([\w,\-,\d,\.,~,:,\+]+)\s\[([\w,\-,\d,\.,~,:,\+]+)\]\s\(([\w,\-,\d,\.,~,:,\+]+)\)? /i) {print "$1 ( \e[1;34m$2\e[0m -> \e[1;32m$3\e[0m )\n"}';} | while read -r line; do echo -en "${GRAY_R}-${RESET} ${line}\\n"; echo -en "${line}\\n" | awk '{print $1}' &>> /tmp/EUS/upgrade/upgrade_list; done;
  if [[ -f /tmp/EUS/upgrade/upgrade_list ]]; then number_of_updates=$(wc -l < /tmp/EUS/upgrade/upgrade_list); else number_of_updates='0'; fi
  if [[ "${number_of_updates}" == '0' ]]; then echo -e "${GRAY_R}#${RESET} There are no packages that need an upgrade..."; fi
  echo -e "\\n${GRAY_R}----${RESET}\\n"
  while true; do
    if [[ "${script_option_skip}" != 'true' ]]; then
      read -rp $'\033[39m#\033[0m Do you want to proceed with updating your system? (Y/n) ' yes_no
    else
      echo -e "${GRAY_R}#${RESET} Performing the updates!"
    fi
    case "$yes_no" in
        [Yy]*|"") echo -e "\\n${GRAY_R}----${RESET}\\n"; system_upgrade; check_mongodb_installed; break;;
        [Nn]*) break;;
        *) echo -e "\\n${RED}#${RESET} Invalid input, please answer Yes or No (y/n)...\\n"; sleep 3;;
    esac
  done
  check_dpkg_lock
  while read -r mongo_package; do
    echo "${mongo_package} install" | "$(which dpkg)" --set-selections &> /dev/null
  done < <("$(which dpkg)" -l | awk '{print $1,$2}' | awk '/ii.*mongo/ {print $2}' | sed 's/:.*//')
  rm --force /tmp/EUS/upgrade/upgrade_list &> /dev/null
}

mongo_last_attempt() {
  unset mongo_last_attempt_install_success
  unset mongo_last_attempt_install_failed_message
  unset mongo_last_attempt_download_success_message
  echo -e "${RED}#${RESET} Trying to install ${mongo_last_attempt_name}..."
  if [[ "${manually_setmongo_last_attempt_version}" != 'true' ]]; then
    if [[ "${ignore_mongo_last_attempt_version}" == 'true' ]]; then
      mongo_last_attempt_version=""
    else
      mongo_last_attempt_version="$("$(which dpkg)" -l | grep "mongodb-server" | grep -i "^ii\\|^hi\\|^ri\\|^pi\\|^ui" | awk '{print $3}' | sed 's/.*://' | sed 's/-.*//g' | sed 's/+.*//g' | sort -V | tail -n 1 | cut -d'.' -f1,2)"
    fi
  fi
  if [[ "${mongo_last_attempt_type}" == 'tools' ]]; then
    repo_archive_array=( "${http_or_https}://archive.ubuntu.com/ubuntu/pool/universe/m/mongo-tools/" "${http_or_https}://ports.ubuntu.com/pool/universe/m/mongo-tools/" "${http_or_https}://old-releases.ubuntu.com/ubuntu/pool/universe/m/mongo-tools/" "${http_or_https}://archive.debian.org/debian/pool/main/m/mongo-tools/" )
    mongo_last_attempt_name="mongo-tools"
  elif [[ "${mongo_last_attempt_type}" == 'clients' ]]; then
    repo_archive_array=( "${http_or_https}://archive.ubuntu.com/ubuntu/pool/universe/m/mongodb/" "${http_or_https}://ports.ubuntu.com/pool/universe/m/mongodb/" "${http_or_https}://old-releases.ubuntu.com/ubuntu/pool/universe/m/mongodb/" "${http_or_https}://archive.debian.org/debian/pool/main/m/mongodb/" )
    mongo_last_attempt_name="mongodb-clients"
  elif [[ "${mongo_last_attempt_type}" == 'server' ]]; then
    repo_archive_array=( "${http_or_https}://archive.ubuntu.com/ubuntu/pool/universe/m/mongodb/" "${http_or_https}://ports.ubuntu.com/pool/universe/m/mongodb/" "${http_or_https}://old-releases.ubuntu.com/ubuntu/pool/universe/m/mongodb/" "${http_or_https}://archive.debian.org/debian/pool/main/m/mongodb/" )
    mongo_last_attempt_name="mongodb-server"
  fi
  for repo_archive in "${repo_archive_array[@]}"; do
    while read -r mongo_last_attempt_package; do
      mongo_last_attempt_package_empty="false"
      echo -e "\\n${GRAY_R}#${RESET} Downloading ${mongo_last_attempt_name}..."
      if ! mongo_last_attempt_temp="$(mktemp --tmpdir=/tmp mongo_last_attempt_XXXXX.deb)"; then abort_reason="Failed to create temporarily MongoDB download file."; abort; fi
      echo -e "$(date +%F-%T.%6N) | Downloading ${repo_archive}${mongo_last_attempt_package} to ${mongo_last_attempt_temp}" &>> "${eus_dir}/logs/unifi-database-required.log"
      if curl "${nos_curl_argument[@]}" --output "$mongo_last_attempt_temp" "${repo_archive}${mongo_last_attempt_package}" &>> "${eus_dir}/logs/unifi-database-required.log"; then
        if command -v dpkg-deb &> /dev/null; then if ! dpkg-deb --info "${mongo_last_attempt_temp}" &> /dev/null; then echo -e "$(date +%F-%T.%6N) | The file downloaded via ${repo_archive}${mongo_last_attempt_package} was not a debian file format..." &>> "${eus_dir}/logs/unifi-database-required.log"; continue; fi; fi
        if [[ "${mongo_last_attempt_download_success_message}" != 'true' ]]; then echo -e "${GREEN}#${RESET} Successfully downloaded ${mongo_last_attempt_name}! \\n"; mongo_last_attempt_download_success_message="true"; fi
        echo -e "${GRAY_R}#${RESET} Installing ${mongo_last_attempt_name}..."
        check_dpkg_lock
        if "${EUS_APT_ENV[@]}" env DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "$mongo_last_attempt_temp" &>> "${eus_dir}/logs/unifi-database-required.log"; then
          echo -e "${GREEN}#${RESET} Successfully installed ${mongo_last_attempt_name}! \\n"
          mongo_last_attempt_install_success="true"
          break
        else
          if DEBIAN_FRONTEND='noninteractive' "$(which dpkg)" -i "$mongo_last_attempt_temp" &>> "${eus_dir}/logs/unifi-database-required.log"; then
            echo -e "${GREEN}#${RESET} Successfully installed ${mongo_last_attempt_name}! \\n"
            mongo_last_attempt_install_success="true"
            break
          fi
          if [[ "${mongo_last_attempt_install_failed_message}" != 'true' ]]; then
            echo -e "${RED}#${RESET} Failed to install ${mongo_last_attempt_name}... trying some different versions... \\n"
            echo -e "${GRAY_R}#${RESET} Attempting to install different versions... \\n"
            mongo_last_attempt_install_failed_message="true"
          fi
          rm --force "$mongo_last_attempt_temp" &> /dev/null
        fi
      else
        abort_reason="Failed to download ${mongo_last_attempt_name}."
        abort
      fi
    done < <(curl "${curl_argument[@]}" "${repo_archive}" | grep -io "${mongo_last_attempt_name}.*${mongo_last_attempt_version}.*${architecture}.deb"  | cut -d'"' -f1)
    if [[ "${mongo_last_attempt_package_empty}" != 'false' ]]; then
      echo -e "${RED}#${RESET} Failed to locate any MongoDB packages for version ${mongo_last_attempt_version}...\\n"
      curl "${curl_argument[@]}" "${repo_archive}" &> /tmp/EUS/mongodb.html
      if ! [[ -s "${eus_dir}/logs/mongodb-last-attempt-failure-debug-info.json" ]] || ! jq empty "${eus_dir}/logs/mongodb-last-attempt-failure-debug-info.json"; then
        mongodb_json_time="$(date +%F-%T.%6N)"
        if [[ "$(dpkg-query --showformat='${version}' --show jq 2> /dev/null | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
          jq -n \
            --argjson "MongoDB Last Attempt Failures" "$( 
              jq -n \
                --argjson "${mongodb_json_time}" "{ \"version\" : \"$mongo_last_attempt_version\", \"Repository URL\" : \"$repo_archive\", \"Architecture\" : \"$architecture\", \"Package\" : \"$mongo_last_attempt_package\", \"Curl Results\" : \"\" }" \
                 '$ARGS.named'
            )" \
            '$ARGS.named' &> "${eus_dir}/logs/mongodb-last-attempt-failure-debug-info.json"
        else
          jq -n \
            --arg mongo_last_attempt_version "${mongo_last_attempt_version}" \
            --arg repo_archive "${repo_archive}" \
            --arg architecture "${architecture}" \
            --arg mongo_last_attempt_package "${mongo_last_attempt_package}" \
            '{
              "MongoDB Last Attempt Failures": {
                "version": $mongo_last_attempt_version,
                "Repository URL": $repo_archive,
                "Architecture": $architecture,
                "Package": $mongo_last_attempt_package,
                "Curl Results": ""
              }
            }' &> "${eus_dir}/logs/mongodb-last-attempt-failure-debug-info.json"
        fi
        if [[ "$(dpkg-query --showformat='${version}' --show jq 2> /dev/null | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
          jq --arg mongodb_json_time "${mongodb_json_time}" --arg mongodb_curl_results "$(</tmp/EUS/mongodb.html)" '."MongoDB Last Attempt Failures"."'"${mongodb_json_time}"'"."Curl Results"=$mongodb_curl_results' "${eus_dir}/logs/mongodb-last-attempt-failure-debug-info.json" > "${eus_dir}/logs/mongodb-last-attempt-failure-debug-info.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
        else
          jq --arg mongodb_json_time "$mongodb_json_time" --arg mongodb_curl_results "$(</tmp/EUS/mongodb.html)" '.["MongoDB Last Attempt Failures"][$mongodb_json_time]["Curl Results"] = $mongodb_curl_results' "${eus_dir}/logs/mongodb-last-attempt-failure-debug-info.json" > "${eus_dir}/logs/mongodb-last-attempt-failure-debug-info.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
        fi
        eus_database_move_file="${eus_dir}/logs/mongodb-last-attempt-failure-debug-info.json"; eus_database_move_log_file="${eus_dir}/logs/mongodb-last-attempt-failure-debug-info.log"; eus_database_move
      else
        if [[ "$(dpkg-query --showformat='${version}' --show jq 2> /dev/null | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
          jq --arg mongo_last_attempt_version "${mongo_last_attempt_version}" --arg repo_archive "${repo_archive}" --arg architecture "${architecture}" --arg mongo_last_attempt_package "${mongo_last_attempt_package}" --arg mongodb_curl_results "$(</tmp/EUS/mongodb.html)" '."MongoDB Last Attempt Failures" += {"'"$(date +%F-%T.%6N)"'": {"version": $mongo_last_attempt_version, "Repository URL": $repo_archive, "Architecture": $architecture, "Package": $mongo_last_attempt_package, "Curl Results": $mongodb_curl_results}}' "${eus_dir}/logs/mongodb-last-attempt-failure-debug-info.json" > "${eus_dir}/logs/mongodb-last-attempt-failure-debug-info.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
        else
          jq --arg mongo_last_attempt_version "$mongo_last_attempt_version" --arg repo_archive "$repo_archive" --arg architecture "$architecture" --arg mongo_last_attempt_package "$mongo_last_attempt_package" --arg mongodb_curl_results "$(</tmp/EUS/mongodb.html)" --arg libssl_curl_results "$(</tmp/EUS/libssl.html)" --arg current_time "$current_time" '.["MongoDB Last Attempt Failures"][$current_time] = {"version": $mongo_last_attempt_version, "Repository URL": $repo_archive, "Architecture": $architecture, "Package": $mongo_last_attempt_package, "Curl Results": $mongodb_curl_results}' "${eus_dir}/logs/mongodb-last-attempt-failure-debug-info.json" > "${eus_dir}/logs/mongodb-last-attempt-failure-debug-info.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
        fi
        eus_database_move_file="${eus_dir}/logs/mongodb-last-attempt-failure-debug-info.json"; eus_database_move_log_file="${eus_dir}/logs/mongodb-last-attempt-failure-debug-info.log"; eus_database_move
      fi
    fi
    if [[ "${mongo_last_attempt_install_success}" == 'true' ]]; then break; fi
	rm --force "$mongo_last_attempt_temp" 2> /dev/null
    rm --force /tmp/EUS/mongodb.html &> /dev/null
  done
  if [[ "${mongo_last_attempt_install_success}" != 'true' ]]; then
    echo -e "${RED}#${RESET} Failed to install ${mongo_last_attempt_name}...\\n"
    if [[ "${ignore_mongo_last_attempt_version}" != 'true' ]]; then
      ignore_mongo_last_attempt_version="true"
      echo -e "${RED}#${RESET} Attempting one last try without a version requirement... \\n"
      mongo_last_attempt
      unset ignore_mongo_last_attempt_version
    fi
  fi
}

mongodb_installation() {
  echo -e "\\n------- $(date +%F-%T.%6N) -------\\n" &>> "${eus_dir}/logs/mongodb-org-install.log"
  if [[ "$(dpkg-query --showformat='${version}' --show jq 2> /dev/null | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
    jq '.scripts["'"$script_name"'"].tasks += {"mongodb-install ('"$(date +%s)"')": [.scripts["'"$script_name"'"].tasks["mongodb-install ('"$(date +%s)"')"][0] + {"add-mongodb-repo":"'"${mongodb_add_repo_variables_true_statements[*]}"'","Glenn R. MongoDB":"'"${glennr_compiled_mongod}"'"}]}' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
  else
    jq --arg script_name "$script_name" --arg date_key "$(date +%s)" --arg add_mongodb_repo "${mongodb_add_repo_variables_true_statements[*]}" --arg glennr_compiled_mongod "$glennr_compiled_mongod" '.scripts[$script_name].tasks = (.scripts[$script_name].tasks + {("mongodb-install (" + $date_key + ")"): ((.scripts[$script_name].tasks["mongodb-install (" + $date_key + ")"] // []) + [{"add-mongodb-repo": $add_mongodb_repo, "Glenn R. MongoDB": $glennr_compiled_mongod}] )})' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
  fi
  eus_database_move
  unset mongodb_key_update
  if [[ "${glennr_compiled_mongod}" == 'true' ]]; then
    get_distro
    check_default_repositories
    if [[ "$(find /etc/apt/ -type f \( -name "*.sources" -o -name "*.list" \) -exec grep -lE 'raspbian.|raspberrypi.' {} + | wc -l)" -ge "1" ]]; then
      if [[ "${os_codename}" =~ (wheezy|jessie|stretch|buster|bullseye) ]]; then
        repo_codename="bookworm"
        use_raspberrypi_repo="true"
        get_repo_url
        repo_component="main"
        add_repositories
        run_apt_get_update_with_sha1_fallback
      fi
    fi
    list_of_glennr_mongod_dependencies="$(apt-cache depends "${gr_mongod_name}" | tr '[:upper:]' '[:lower:]' | grep -i depends | awk '!a[$0]++' | sed -e 's/|//g' -e 's/ //g' -e 's/<//g' -e 's/>//g' -e 's/depends://g' | sort -V | awk '!/^gcc/ || !f++')"
    glennr_mongod_dependency_version="$(echo "${list_of_glennr_mongod_dependencies}" | grep -Eio "gcc-[0-9]{1,2}-base" | sed -e 's/gcc-//g' -e 's/-base//g')"
    while read -r glennr_mongod_dependency; do
      if [[ "${glennr_mongod_dependency}" =~ (libssl1.0.0|libssl1.1|libssl3) ]]; then
        mongodb_package_libssl="${gr_mongod_name}"
        mongodb_package_version_libssl="${install_mongod_version}"
        libssl_installation_check
        continue
      fi
      if [[ "${glennr_mongod_dependency}" =~ (libc6) ]]; then
        glennr_mongod_libc6_required_version="$(apt-cache show "${gr_mongod_name}${install_mongod_version_with_equality_sign}" | grep -i "libc6" | grep -oP "libc6 \(>= \K[0-9\.]+")"
        installed_libc_version="$(dpkg-query -W -f='${Version}' libc6 2> /dev/null)"
        if dpkg --compare-versions "${installed_libc_version}" lt "${glennr_mongod_libc6_required_version}"; then
          if [[ "${os_codename}" =~ (trusty|utopic|vivid|wily|yakkety|zesty|artful|qiana|rebecca|rafaela|rosa|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy) ]]; then
            if [[ "${architecture}" =~ (amd64|i386) ]]; then
              repo_url="${http_or_https}://security.ubuntu.com/ubuntu"
              repo_codename_argument="-security"
              repo_component="main"
            else
              repo_url="${http_or_https}://ports.ubuntu.com"
              repo_codename_argument="-security"
              repo_component="main universe"
            fi
            repo_codename="noble"
          elif [[ "${os_codename}" =~ (wheezy|jessie|stretch|buster|bullseye) ]]; then
            repo_codename="bookworm"
            get_repo_url
            repo_component="main"
          fi
          add_repositories
          run_apt_get_update_with_sha1_fallback
        fi
      fi
      if "$(which dpkg)" -l mongodb-mongosh-shared-openssl11 "${glennr_mongod_dependency}" 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
        glennr_mongod_dependency_version_current="$(dpkg-query --showformat='${Version}' --show "${glennr_mongod_dependency}" | awk -F'[-.]' '{print $1}')"
      else
        glennr_mongod_dependency_version_current="0"
      fi
      if [[ "${glennr_mongod_dependency_version_current}" -lt "${glennr_mongod_dependency_version}" ]]; then
        if ! apt-cache policy "${glennr_mongod_dependency}" | tr '[:upper:]' '[:lower:]' | sed '1,/version table/d' | sed -e 's/500//g' -e 's/100//g' -e '/http/d' -e '/var/d' -e 's/*//g' -e 's/ //g' | grep -iq "^${glennr_mongod_dependency_version}"; then
          if [[ "${os_codename}" =~ (precise|trusty|utopic|vivid|wily|yakkety|zesty|artful|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish) ]]; then
            repo_codename="jammy"
            repo_component="main"
            get_repo_url
            add_repositories
            repo_codename="jammy"
            repo_component="universe"
            get_repo_url
          elif [[ "${os_codename}" =~ (wheezy|jessie|stretch|buster|bullseye) ]]; then
            repo_codename="bookworm"
            repo_component="main"
            get_repo_url
          elif [[ "${os_id}" == "ubuntu" ]]; then
            repo_component="main"
            add_repositories
            repo_component="universe"
          else
            repo_component="main"
          fi
          add_repositories
          if [[ "${os_codename}" =~ (precise|trusty|utopic|vivid|wily|yakkety|zesty|artful|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish) ]]; then
            repo_codename="jammy"
            get_repo_url
            repo_component="universe"
          elif [[ "${os_codename}" =~ (wheezy|jessie|stretch|buster|bullseye) ]]; then
            repo_codename="bookworm"
            get_repo_url
            repo_component="main"
            add_repositories
            repo_component="contrib"
          elif [[ "${os_id}" == "ubuntu" ]]; then
            repo_component="main"
            add_repositories
            repo_component="universe"
          else
            repo_component="main"
          fi
          add_repositories
          run_apt_get_update_with_sha1_fallback
        fi
        glennr_mongod_dependency_install_version="$(apt-cache policy "${glennr_mongod_dependency}" | tr '[:upper:]' '[:lower:]' | sed '1,/version table/d' | sed -e 's/500//g' -e 's/100//g' -e '/http/d' -e '/var/d' -e 's/*//g' -e 's/ //g' | grep -i "^${glennr_mongod_dependency_version}" | head -n1)"
        if [[ -z "${glennr_mongod_dependency_install_version}" ]]; then
          echo -e "${RED}#${RESET} Failed to locate required version for ${glennr_mongod_dependency}...\\n"
        fi
        check_dpkg_lock
        echo -e "${GRAY_R}#${RESET} Installing ${glennr_mongod_dependency}..."
        if ! "${EUS_APT_ENV[@]}" env DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "${glennr_mongod_dependency}"="${glennr_mongod_dependency_install_version}" &>> "${eus_dir}/logs/${gr_mongod_name}-dependencies.log"; then
          if ! "${EUS_APT_ENV[@]}" env DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "${glennr_mongod_dependency}" &>> "${eus_dir}/logs/${gr_mongod_name}-dependencies.log"; then
            check_unmet_dependencies
            broken_packages_check
            attempt_recover_broken_packages
            add_apt_option_no_install_recommends="true"; get_apt_options
            check_dpkg_lock
            if ! "${EUS_APT_ENV[@]}" env DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "${glennr_mongod_dependency}" &>> "${eus_dir}/logs/${gr_mongod_name}-dependencies.log"; then
              abort_reason="Failed to install ${glennr_mongod_dependency}."
              abort
            else
              echo -e "${GREEN}#${RESET} Successfully installed ${glennr_mongod_dependency}! \\n" && sleep 2
            fi
            get_apt_options
          else
            echo -e "${GREEN}#${RESET} Successfully installed ${glennr_mongod_dependency}! \\n" && sleep 2
          fi
        else
          echo -e "${GREEN}#${RESET} Successfully installed ${glennr_mongod_dependency}! \\n" && sleep 2
        fi
      fi
    done < <(echo "${list_of_glennr_mongod_dependencies}")
    mongodb_installation_server_package="${gr_mongod_name}${install_mongod_version_with_equality_sign}"
  else
    mongodb_package_libssl="mongodb-org-server"
    mongodb_package_version_libssl="${install_mongodb_version}"
    libssl_installation_check
    mongodb_installation_server_package="mongodb-org-server${install_mongodb_version_with_equality_sign}"
  fi
  te_mongodb_org_server_version="${install_mongodb_version//./}"
  if "$(which dpkg)" -l mongodb-org-database-tools-extra 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui" && [[ "${te_mongodb_org_server_version::2}" -lt "44" ]]; then
    mongodb_tools_extra_dependencies=()
    if "$(which dpkg)" -l | awk '{print $2}' | grep -ioq "mongodb-org-database$"; then mongodb_tools_extra_dependencies+=("mongodb-org-database"); fi
    if "$(which dpkg)" -l | awk '{print $2}' | grep -ioq "mongodb-org-tools$"; then mongodb_tools_extra_dependencies+=("mongodb-org-tools"); fi
    if "$(which dpkg)" -l | awk '{print $2}' | grep -ioq "mongodb-org$"; then mongodb_tools_extra_dependencies+=("mongodb-org"); fi
    if [[ "${#mongodb_tools_extra_dependencies[@]}" -gt 0 ]]; then tools_extra_dependency_extra_packages_message=", $(IFS=,; echo "${mongodb_tools_extra_dependencies[*]}" | sed 's/,/, /g; s/,\([^,]*\)$/ and\1/')"; fi
    check_dpkg_lock
    echo -e "${GRAY_R}#${RESET} Purging package mongodb-org-database-tools-extra${tools_extra_dependency_extra_packages_message}..."
    if "${EUS_APT_ENV[@]}" env DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' purge "mongodb-org-database-tools-extra" "${mongodb_tools_extra_dependencies[@]}" &>> "${eus_dir}/logs/unifi-database-required.log"; then
      echo -e "${GREEN}#${RESET} Successfully purged mongodb-org-database-tools-extra${tools_extra_dependency_extra_packages_message}! \\n"
    else
      echo -e "${RED}#${RESET} Failed to purge mongodb-org-database-tools-extra${tools_extra_dependency_extra_packages_message}...\\n"
      abort_function_skip_reason="true"; abort_reason="Failed to purge mongodb-org-database-tools-extra${tools_extra_dependency_extra_packages_message}."; abort
    fi
  fi
  if "$(which dpkg)" -l mongo-tools 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
    check_dpkg_lock
    echo -e "${GRAY_R}#${RESET} Purging package mongo-tools..."
    if "${EUS_APT_ENV[@]}" env DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' purge "mongo-tools" &>> "${eus_dir}/logs/mongodb-org-install.log"; then
      echo -e "${GREEN}#${RESET} Successfully purged mongo-tools! \\n"
    else
      echo -e "${RED}#${RESET} Failed to purge mongo-tools...\\n"
      if [[ -e "/var/lib/dpkg/info/mongo-tools.prerm" ]]; then eus_create_directories "dpkg"; mv "/var/lib/dpkg/info/mongo-tools.prerm" "${eus_dir}/dpkg/mongo-tools.prerm-$(date +%Y%m%d_%H%M_%s)"; fi
      echo -e "${GRAY_R}#${RESET} Trying another method to get rid of mongo-tools..."
      if DEBIAN_FRONTEND='noninteractive' "$(which dpkg)" --remove --force-remove-reinstreq "mongo-tools" &>> "${eus_dir}/logs/mongodb-org-install.log"; then
        echo -e "${GREEN}#${RESET} Successfully removed mongo-tools! \\n"
      else
        echo -e "${RED}#${RESET} Failed to force remove mongo-tools...\\n"
        abort_function_skip_reason="true"; abort_reason="Failed to purge mongo-tools."; abort
      fi
    fi
  fi
  check_dpkg_lock
  echo -e "${GRAY_R}#${RESET} Installing mongodb-org version ${mongo_version_max_with_dot::3}..."
  if "${EUS_APT_ENV[@]}" env DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_downgrade_option[@]}" "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "${mongodb_installation_server_package}" "mongodb-org-shell${install_mongodb_version_with_equality_sign}" "mongodb-org-tools${install_mongodb_version_with_equality_sign}" &>> "${eus_dir}/logs/mongodb-org-install.log"; then
    echo -e "${GREEN}#${RESET} Successfully installed mongodb-org version ${mongo_version_max_with_dot::3}! \\n"
    mongodb_installed="true"
  else
    echo -e "${RED}#${RESET} Failed to install mongodb-org version ${mongo_version_max_with_dot::3}...\\n"
    try_different_mongodb_repo="true"
    add_mongodb_repo
    mongodb_package_libssl="mongodb-org-server"
    mongodb_package_version_libssl="${install_mongodb_version}"
    libssl_installation_check
    check_dpkg_lock
    echo -e "${GRAY_R}#${RESET} Trying to install mongodb-org version ${mongo_version_max_with_dot::3} in the second run..."
    if "${EUS_APT_ENV[@]}" env DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_downgrade_option[@]}" "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "${mongodb_installation_server_package}" "mongodb-org-shell${install_mongodb_version_with_equality_sign}" "mongodb-org-tools${install_mongodb_version_with_equality_sign}" &>> "${eus_dir}/logs/mongodb-org-install.log"; then
      echo -e "${GREEN}#${RESET} Successfully installed mongodb-org version ${mongo_version_max_with_dot::3} in the second run! \\n"
      mongodb_installed="true"
    else
      echo -e "${RED}#${RESET} Failed to install mongodb-org version ${mongo_version_max_with_dot::3} in the second run...\\n"
      try_different_mongodb_repo="true"
      try_http_mongodb_repo="true"
      add_mongodb_repo
      mongodb_package_libssl="mongodb-org-server"
      mongodb_package_version_libssl="${install_mongodb_version}"
      libssl_installation_check
      check_dpkg_lock
      echo -e "${GRAY_R}#${RESET} Trying to install mongodb-org version ${mongo_version_max_with_dot::3} in the third run..."
      if "${EUS_APT_ENV[@]}" env DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_downgrade_option[@]}" "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "${mongodb_installation_server_package}" "mongodb-org-shell${install_mongodb_version_with_equality_sign}" "mongodb-org-tools${install_mongodb_version_with_equality_sign}" &>> "${eus_dir}/logs/mongodb-org-install.log"; then
        echo -e "${GREEN}#${RESET} Successfully installed mongodb-org version ${mongo_version_max_with_dot::3} in the third run! \\n"
        mongodb_installed="true"
      else
        check_unmet_dependencies
        broken_packages_check
        attempt_recover_broken_packages
        add_apt_option_no_install_recommends="true"; get_apt_options
        if "${EUS_APT_ENV[@]}" env DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_downgrade_option[@]}" "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "${mongodb_installation_server_package}" "mongodb-org-shell${install_mongodb_version_with_equality_sign}" "mongodb-org-tools${install_mongodb_version_with_equality_sign}" &>> "${eus_dir}/logs/mongodb-org-install.log"; then
          echo -e "${GREEN}#${RESET} Successfully installed mongodb-org version ${mongo_version_max_with_dot::3} in the fourth run! \\n"
          mongodb_installed="true"
        else
          abort_reason="Failed to install mongodb-org version ${mongo_version_max_with_dot::3} in the fourth run."
          abort
        fi
        get_apt_options
      fi
    fi
  fi
  if [[ "${install_mongod_version::1}" -ge "5" ]]; then
    if ! "$(which dpkg)" -l mongodb-mongosh-shared-openssl11 mongodb-mongosh-shared-openssl3 mongodb-mongosh mongosh 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
      if "$(which dpkg)" -l | grep "^ii\\|^hi\\|^ri\\|^pi\\|^ui\\|^iU" | grep -iq "${gr_mongod_name}"; then
        mongodb_mongosh_libssl_version="$(apt-cache depends "${gr_mongod_name}${install_mongod_version_with_equality_sign}" | sed -e 's/>//g' -e 's/<//g' | grep -io "libssl1.1$\\|libssl3$")"
        if [[ -z "${mongodb_mongosh_libssl_version}" ]]; then
          mongodb_mongosh_libssl_version="$(apt-cache depends "${gr_mongod_name}" | sed -e 's/>//g' -e 's/<//g' | grep -io "libssl1.1$\\|libssl3$")"
        fi
      else
        mongodb_mongosh_libssl_version="$(apt-cache depends "mongodb-org-server${install_mongodb_version_with_equality_sign}" | sed -e 's/>//g' -e 's/<//g' | grep -io "libssl1.1$\\|libssl3$")"
        if [[ -z "${mongodb_mongosh_libssl_version}" ]]; then
          mongodb_mongosh_libssl_version="$(apt-cache depends "mongodb-org-server" | sed -e 's/>//g' -e 's/<//g' | grep -io "libssl1.1$\\|libssl3$")"
        fi
      fi
      if [[ "${mongodb_mongosh_libssl_version}" == 'libssl3' ]]; then
        mongodb_mongosh_install_package_name="mongodb-mongosh-shared-openssl3"
      elif [[ "${mongodb_mongosh_libssl_version}" == 'libssl1.1' ]]; then
        mongodb_mongosh_install_package_name="mongodb-mongosh-shared-openssl11"
      elif "$(which dpkg)" -l libssl3t64 libssl3 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
        mongodb_mongosh_install_package_name="mongodb-mongosh-shared-openssl3"
      else
        mongodb_mongosh_install_package_name="mongodb-mongosh-shared-openssl11"
      fi
      if [[ "${mongodb_mongosh_install_package_name}" == "mongodb-mongosh-shared-openssl11" ]]; then
        if ! "$(which dpkg)" -l libssl1.1 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui" && "$(which dpkg)" -l libssl3t64 libssl3 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
          mongodb_mongosh_install_package_name="mongodb-mongosh-shared-openssl3"
        fi
      fi
      echo -e "${GRAY_R}#${RESET} Installing ${mongodb_mongosh_install_package_name}..."
      check_dpkg_lock
      if "${EUS_APT_ENV[@]}" env DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_downgrade_option[@]}" "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "${mongodb_mongosh_install_package_name}" &>> "${eus_dir}/logs/mongodb-org-install.log"; then
        echo -e "${GREEN}#${RESET} Successfully installed ${mongodb_mongosh_install_package_name}! \\n"
        if [[ "$(apt-cache policy "${mongodb_mongosh_libssl_version}" | tr '[:upper:]' '[:lower:]' | grep "installed:" | cut -d':' -f2 | sed 's/ //g')" != "$(apt-cache policy "${mongodb_mongosh_libssl_version}" | tr '[:upper:]' '[:lower:]' | grep "candidate:" | cut -d':' -f2 | sed 's/ //g')" ]]; then
          echo -e "${GRAY_R}#${RESET} Updating ${mongodb_mongosh_libssl_version}..."
          check_dpkg_lock
          if "${EUS_APT_ENV[@]}" env DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' --only-upgrade install "${mongodb_mongosh_libssl_version}" &>> "${eus_dir}/logs/libssl.log"; then
            echo -e "${GREEN}#${RESET} Successfully updated ${mongodb_mongosh_libssl_version}! \\n"
          else
            echo -e "${RED}#${RESET} Failed to update ${mongodb_mongosh_libssl_version}...\\n"
          fi
        fi
      else
        check_unmet_dependencies
        broken_packages_check
        attempt_recover_broken_packages
        add_apt_option_no_install_recommends="true"; get_apt_options
        check_dpkg_lock
        if "${EUS_APT_ENV[@]}" env DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_downgrade_option[@]}" "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "${mongodb_mongosh_install_package_name}" &>> "${eus_dir}/logs/mongodb-org-install.log"; then
          echo -e "${GREEN}#${RESET} Successfully installed ${mongodb_mongosh_install_package_name}! \\n"
          if [[ "$(apt-cache policy "${mongodb_mongosh_libssl_version}" | tr '[:upper:]' '[:lower:]' | grep "installed:" | cut -d':' -f2 | sed 's/ //g')" != "$(apt-cache policy "${mongodb_mongosh_libssl_version}" | tr '[:upper:]' '[:lower:]' | grep "candidate:" | cut -d':' -f2 | sed 's/ //g')" ]]; then
            echo -e "${GRAY_R}#${RESET} Updating ${mongodb_mongosh_libssl_version}..."
            check_dpkg_lock
            if "${EUS_APT_ENV[@]}" env DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' --only-upgrade install "${mongodb_mongosh_libssl_version}" &>> "${eus_dir}/logs/libssl.log"; then
              echo -e "${GREEN}#${RESET} Successfully updated ${mongodb_mongosh_libssl_version}! \\n"
            else
              echo -e "${RED}#${RESET} Failed to update ${mongodb_mongosh_libssl_version}...\\n"
            fi
          fi
          get_apt_options
        else
          abort_reason="Failed to install ${mongodb_mongosh_install_package_name}."
          abort
        fi
      fi
    fi
  fi
  if [[ "${architecture}" == "arm64" && "${mongodb_version_major_minor}" == "4.4" ]]; then
    eus_directory_location="/tmp/EUS"
    eus_create_directories "mongodb"
    "$(which dpkg)" -l | grep mongodb-org | grep "^ii\\|^hi\\|^ri\\|^pi\\|^ui\\|^iU" | awk '{print $2}' &> /tmp/EUS/mongodb/packages_list
    check_dpkg_lock
    while read -r mongodb_package; do
      echo -e "${GRAY_R}#${RESET} Preventing ${mongodb_package} from upgrading..."
      if echo "${mongodb_package} hold" | "$(which dpkg)" --set-selections; then
        echo -e "${GREEN}#${RESET} Successfully prevented ${mongodb_package} from upgrading! \\n"
      else
        abort_reason="Failed to prevent ${mongodb_package} from upgrading."
        abort
      fi
    done < /tmp/EUS/mongodb/packages_list
    rm /tmp/EUS/mongodb/packages_list
  fi
}

mongodb_installation_armhf() {
  aptkey_depreciated
  if [[ -z "${raspbian_repo_url}" ]]; then raspbian_repo_url="${http_or_https}://archive.raspbian.org/raspbian"; fi
  if [[ "${apt_key_deprecated}" == 'true' ]]; then
    echo -e "$(date +%F-%T.%6N) | archive.raspbian.org repository key.\\n" &>> "${eus_dir}/logs/repository-keys.log"
    if curl "${curl_argument[@]}" -fSL "${raspbian_repo_url}.public.key" 2>&1 | tee -a "${eus_dir}/logs/repository-keys.log" | gpg -o "/etc/apt/keyrings/raspbian.gpg" --dearmor --yes &> /dev/null; then
      raspbian_curl_exit_status="${PIPESTATUS[0]}"
      raspbian_gpg_exit_status="${PIPESTATUS[2]}"
      if [[ "${raspbian_curl_exit_status}" -eq "0" && "${raspbian_gpg_exit_status}" -eq "0" && -s "/etc/apt/keyrings/raspbian.gpg" ]]; then
        echo -e "${GREEN}#${RESET} Successfully added the key for the raspbian repository! \\n"; signed_by_value_raspbian="[ signed-by=/etc/apt/keyrings/raspbian.gpg ]"
        repository_key_location="/etc/apt/keyrings/raspbian.gpg"; check_repository_key_permissions
      else
        abort_reason="Failed to add the key for the raspbian repository."; abort
      fi
    else
      abort_reason="Failed to fetch the key for the raspbian repository."
      abort
    fi
  else
    echo -e "$(date +%F-%T.%6N) | archive.raspbian.org repository key.\\n" &>> "${eus_dir}/logs/repository-keys.log"
    if curl "${curl_argument[@]}" -fSL "${raspbian_repo_url}.public.key" 2>&1 | tee -a "${eus_dir}/logs/repository-keys.log" | apt-key add - &> /dev/null; then
      raspbian_curl_exit_status="${PIPESTATUS[0]}"
      raspbian_apt_key_exit_status="${PIPESTATUS[2]}"
      if [[ "${raspbian_curl_exit_status}" -eq "0" && "${raspbian_apt_key_exit_status}" -eq "0" ]]; then
        echo -e "${GREEN}#${RESET} Successfully added the key for the raspbian repository! \\n"
      else
        abort_reason="Failed to add the key for the raspbian repository."; abort
      fi
    else
      abort_reason="Failed to fetch the key for the raspbian repository."
      abort
    fi
  fi
  if [[ -f "/etc/apt/sources.list.d/glennr_armhf.list" ]]; then rm --force "/etc/apt/sources.list.d/glennr_armhf.list"; fi
  echo "deb ${signed_by_value_raspbian}${raspbian_repo_url} ${os_codename} main contrib non-free rpi" &> /etc/apt/sources.list.d/glennr-install-script.list
  run_apt_get_update_with_sha1_fallback
  check_dpkg_lock
  if "${EUS_APT_ENV[@]}" env DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_downgrade_option[@]}" "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install mongodb-server mongodb-clients &>> "${eus_dir}/logs/mongodb-armhf-install.log"; then
    echo -e "${GREEN}#${RESET} Successfully installed mongodb-server and mongodb-clients! \\n"
  else
    echo -e "${RED}#${RESET} Failed to install mongodb-server and mongodb-clients in the first run... \\n${RED}#${RESET} Trying to save the installation...\\n"
    echo -e "${GRAY_R}#${RESET} Running \"apt-get install -f\"..."
    if "${EUS_APT_ENV[@]}" env DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_downgrade_option[@]}" "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install -f &>> "${eus_dir}/logs/mongodb-armhf-install.log"; then
      echo -e "${GREEN}#${RESET} Successfully ran \"apt-get install -f\"! \\n"
      check_dpkg_lock
      echo -e "${GRAY_R}#${RESET} Trying to install mongodb-server and mongodb-clients again..."
      if "${EUS_APT_ENV[@]}" env DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_downgrade_option[@]}" "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install mongodb-server mongodb-clients &>> "${eus_dir}/logs/mongodb-armhf-install.log"; then
        echo -e "${GREEN}#${RESET} Successfully installed mongodb-server and mongodb-clients! \\n"
      else
        check_unmet_dependencies
        broken_packages_check
        attempt_recover_broken_packages
        add_apt_option_no_install_recommends="true"; get_apt_options
        if "${EUS_APT_ENV[@]}" env DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_downgrade_option[@]}" "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install mongodb-server mongodb-clients &>> "${eus_dir}/logs/mongodb-armhf-install.log"; then
          echo -e "${GREEN}#${RESET} Successfully installed mongodb-server and mongodb-clients! \\n"
        else
          abort_reason="Failed to install mongodb-server and mongodb-clients... Consider switching to a 64-bit platform and re-run the scripts."
          abort
        fi
        get_apt_options
      fi
    else
      abort_reason="Failed to run apt-get install -f."; abort
    fi
  fi
  sleep 3
}

mongodb_server_clients_installation() {
  check_dpkg_lock
  echo -e "\\n------- $(date +%F-%T.%6N) -------\\n" &>> "${eus_dir}/logs/mongodb-server-client-install.log"
  echo -e "${GRAY_R}#${RESET} Installing mongodb-server and mongodb-clients..."
  if ! "${EUS_APT_ENV[@]}" env DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_downgrade_option[@]}" "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "mongodb-server${mongodb_server_clients_installation_recovery_version}" "mongodb-clients${mongodb_server_clients_installation_recovery_version}" &>> "${eus_dir}/logs/mongodb-server-client-install.log"; then
    echo -e "${RED}#${RESET} Failed to install mongodb-server and mongodb-clients in the first run...\\n"
    if [[ "${os_codename}" =~ (trusty|utopic|vivid|wily|yakkety|zesty|artful|qiana|rebecca|rafaela|rosa|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing|resolute|sarah|serena|sonya|sylvia|tara|tessa|tina|tricia) ]]; then
      repo_component="main universe"
      repo_codename="xenial"
    elif [[ "${os_codename}" =~ (wheezy|jessie|stretch|buster|bullseye|bookworm|trixie|forky|unstable) ]]; then
      repo_component="main"
      repo_codename="stretch"
    fi
    get_repo_url
    add_repositories
    run_apt_get_update_with_sha1_fallback
    check_dpkg_lock
    echo -e "${GRAY_R}#${RESET} Trying to install mongodb-server and mongodb-clients for the second time..."
    if ! "${EUS_APT_ENV[@]}" env DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_downgrade_option[@]}" "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "mongodb-server${mongodb_server_clients_installation_recovery_version}" "mongodb-clients${mongodb_server_clients_installation_recovery_version}" &>> "${eus_dir}/logs/mongodb-server-client-install.log"; then
      echo -e "${RED}#${RESET} Failed to install mongodb-server and mongodb-clients in the second run... \\n${GRAY_R}#${RESET} Trying to save the installation...\\n"
      echo -e "${GRAY_R}#${RESET} Running apt-get install -f..."
      if "${EUS_APT_ENV[@]}" env DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_downgrade_option[@]}" "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install -f &>> "${eus_dir}/logs/mongodb-server-client-install.log"; then
        echo -e "${GREEN}#${RESET} Successfully ran \"apt-get install -f\"! \\n"
      else
        echo -e "${RED}#${RESET} Failed to run \"apt-get install -f\"...\\n"
      fi
      check_dpkg_lock
      check_unmet_dependencies
      broken_packages_check
      attempt_recover_broken_packages
      echo -e "${GRAY_R}#${RESET} Trying to install mongodb-server and mongodb-clients again..."
      if ! "${EUS_APT_ENV[@]}" env DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_downgrade_option[@]}" "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "mongodb-server" "mongodb-clients" &>> "${eus_dir}/logs/mongodb-server-client-install.log"; then
        if [[ "${architecture}" == "armhf" ]]; then
          mongo_last_attempt_type="server"
          mongo_last_attempt
          if [[ "${mongo_last_attempt_install_success}" != 'true' ]]; then
            mongodb_installation_armhf
          else
            mongo_last_attempt_type="clients"
            mongo_last_attempt
            if [[ "${mongo_last_attempt_install_success}" != 'true' ]]; then
              mongodb_installation_armhf
            fi
          fi
        else
          mongo_last_attempt_type="server"
          mongo_last_attempt
          if [[ "${mongo_last_attempt_install_success}" != 'true' ]]; then
            abort_reason="Failed to install mongodb-server and mongodb-clients... Consider switching to a 64-bit platform and re-run the scripts."
            abort
          else
            mongo_last_attempt_type="clients"
            mongo_last_attempt
            if [[ "${mongo_last_attempt_install_success}" != 'true' ]]; then
              abort_reason="Failed to install mongodb-server and mongodb-clients... Consider switching to a 64-bit platform and re-run the scripts."
              abort
            fi
          fi
        fi
      fi
    else
      echo -e "${GREEN}#${RESET} Successfully installed mongodb-server and mongodb-clients! \\n"
    fi
  fi
}

network_install_mongodb_install_process() {
  check_mongodb_installed
  header
  echo -e "${GRAY_R}#${RESET} Preparing for MongoDB installation..."
  sleep 2
  if [[ "${mongodb_installed}" != 'true' ]]; then
    echo ""
    remove_older_mongodb_repositories
    if [[ "${broken_unifi_install}" == 'true' ]]; then
      if [[ -z "${previous_mongodb_version}" && "${mongodb_unsupported_uninstall}" != 'true' ]]; then previous_mongodb_version="$(grep ${grep_matches:+${grep_matches}} -sEio "db version v[0-9].[0-9].[0-9]{1,2}|buildInfo\":{\"version\":\"[0-9].[0-9].[0-9]{1,2}\"" "${unifi_logs_location}/mongod.log" | tail -n1 | sed -e 's/db version v//g' -e 's/buildInfo":{"version":"//g' -e 's/"//g' | sed 's/\.//g')"; fi
      if [[ -n "${previous_mongodb_version}" && "${success_setfeaturecompatibilityversion}" != "true" ]]; then
        unset add_mongodb_30_repo
        unset add_mongodb_32_repo
        unset add_mongodb_34_repo
        unset add_mongodb_36_repo
        unset add_mongodb_40_repo
        unset add_mongodb_42_repo
        unset add_mongodb_44_repo
        unset add_mongodb_50_repo
        unset add_mongodb_60_repo
        unset add_mongodb_70_repo
        unset add_mongodb_80_repo
        unset install_mongodb_version
        unset install_mongodb_version_with_equality_sign
        unset mongo_version_locked
        unset glennr_compiled_mongod
        unset unsupported_database_version_change
        if [[ "${previous_mongodb_version::2}" == '26' ]]; then
          if [[ ! "${architecture}" =~ (amd64|arm64) ]]; then
            eus_directory_location="/tmp/EUS"
            eus_create_directories "mongodb"
            apt-cache policy mongodb-server &> /tmp/EUS/mongodb/apt-cache-policy-mongodb-server
            mongodb_server_installable_versions="$(apt-cache policy mongodb-server | grep -i "\<2\.6\>\|\<3\.0\>" | grep -i Candidate | sed -e 's/1://g' -e 's/ //g' -e 's/*//g' | cut -d':' -f2 | cut -d'-' -f1 | sed -e 's/\.//g' | uniq)"
            if [[ -z "${mongodb_server_installable_versions}" ]]; then mongodb_server_installable_versions="$(apt-cache policy mongodb-server | grep -v " \-1" | grep -i "\<2\.6\>\|\<3\.0\>" | sed -e 's/500//g' -e 's/-1//g' -e 's/100//g' -e 's/ //g' -e '/http/d' -e 's/*//g' -e 's/^[^:]*://' -e 's/^[0-9]*://' | cut -d'-' -f1 | uniq | sed -e 's/\.//g')"; fi
            IFS=' ' read -r -a version_array <<< "$mongodb_server_installable_versions"
            for version in "${version_array[@]}"; do
              if [[ "${version::2}" =~ (26|30) ]]; then
                broken_unifi_install_mongodb_server_clients="true"
                mongodb_server_installable_major_minor_version="${version:0:1}.${version:1:1}"
                mongodb_server_clients_installation_recovery_version="$(apt-cache policy mongodb-server | grep -i "${mongodb_server_installable_major_minor_version}" | grep -v " \-1" | sed -e 's/500//g' -e 's/-1//g' -e 's/100//g' -e 's/ //g' -e '/http/d' -e 's/*//g' -e 's/^[^:]*://' -e 's/^[0-9]*://' | cut -d'-' -f1 | uniq)"
                if [[ -n "${mongodb_server_clients_installation_recovery_version}" ]]; then mongodb_server_clients_installation_recovery_version="=${mongodb_server_clients_installation_recovery_version}"; fi
                mongodb_server_clients_installation
                break
              fi
            done
            if [[ -z "${mongodb_server_installable_versions}" ]]; then
              add_mongodb_30_repo="true"
              #mongo_version_not_supported="4.0"
              mongo_version_max="30"
              mongo_version_max_with_dot="3.0"
            fi
          else
            add_mongodb_30_repo="true"
            #mongo_version_not_supported="4.0"
            mongo_version_max="30"
            mongo_version_max_with_dot="3.0"
          fi
        elif [[ "${previous_mongodb_version::2}" == "30" ]]; then
          add_mongodb_30_repo="true"
          #mongo_version_not_supported="4.0"
          mongo_version_max="30"
          mongo_version_max_with_dot="3.0"
        elif [[ "${previous_mongodb_version::2}" == "32" ]]; then
          add_mongodb_32_repo="true"
          #mongo_version_not_supported="4.0"
          mongo_version_max="32"
          mongo_version_max_with_dot="3.2"
        elif [[ "${previous_mongodb_version::2}" == '34' ]]; then
          add_mongodb_34_repo="true"
          #mongo_version_not_supported="4.0"
          mongo_version_max="34"
          mongo_version_max_with_dot="3.4"
        elif [[ "${previous_mongodb_version::2}" == '36' ]]; then
          add_mongodb_36_repo="true"
          #mongo_version_not_supported="4.0"
          mongo_version_max="36"
          mongo_version_max_with_dot="3.6"
        elif [[ "${previous_mongodb_version::2}" == '40' ]]; then
          add_mongodb_40_repo="true"
          #mongo_version_not_supported="4.5"
          mongo_version_max="40"
          mongo_version_max_with_dot="4.0"
        elif [[ "${previous_mongodb_version::2}" == '42' ]]; then
          add_mongodb_42_repo="true"
          #mongo_version_not_supported="4.5"
          mongo_version_max="42"
          mongo_version_max_with_dot="4.2"
        elif [[ "${previous_mongodb_version::2}" == '44' ]]; then
          add_mongodb_44_repo="true"
          #mongo_version_not_supported="4.5"
          mongo_version_max="44"
          mongo_version_max_with_dot="4.4"
          if [[ "${avx_compatible}" != "true" ]]; then mongo_version_locked="4.4.18"; fi
        elif [[ "${previous_mongodb_version::2}" == '50' ]]; then
          add_mongodb_50_repo="true"
          #mongo_version_not_supported="5.1"
          mongo_version_max="50"
          mongo_version_max_with_dot="5.0"
          if [[ "${broken_glennr_compiled_mongod}" == 'true' ]]; then
            add_mongod_50_repo="true"
            glennr_compiled_mongod="true"
          elif [[ "${glennr_mongod_compatible}" == "true" ]]; then
            add_mongod_50_repo="true"
            glennr_compiled_mongod="true"
          fi
        elif [[ "${previous_mongodb_version::2}" == '60' ]]; then
          add_mongodb_60_repo="true"
          #mongo_version_not_supported="6.1"
          mongo_version_max="60"
          mongo_version_max_with_dot="6.0"
          if [[ "${broken_glennr_compiled_mongod}" == 'true' ]]; then
            add_mongod_60_repo="true"
            glennr_compiled_mongod="true"
          elif [[ "${glennr_mongod_compatible}" == "true" ]]; then
            add_mongod_60_repo="true"
            glennr_compiled_mongod="true"
          fi
        elif [[ "${previous_mongodb_version::2}" == '70' ]]; then
          add_mongodb_70_repo="true"
          #mongo_version_not_supported="7.1"
          mongo_version_max="70"
          mongo_version_max_with_dot="7.0"
          if [[ "${broken_glennr_compiled_mongod}" == 'true' ]]; then
            add_mongod_70_repo="true"
            glennr_compiled_mongod="true"
          elif [[ "${glennr_mongod_compatible}" == "true" ]]; then
            add_mongod_70_repo="true"
            glennr_compiled_mongod="true"
          fi
        elif [[ "${previous_mongodb_version::2}" == '80' ]]; then
          add_mongodb_80_repo="true"
          #mongo_version_not_supported="8.1"
          mongo_version_max="80"
          mongo_version_max_with_dot="8.0"
          if [[ "${broken_glennr_compiled_mongod}" == 'true' ]]; then
            add_mongod_80_repo="true"
            glennr_compiled_mongod="true"
          elif [[ "${glennr_mongod_compatible}" == "true" ]]; then
            add_mongod_80_repo="true"
            glennr_compiled_mongod="true"
          fi
        else
          network_install_set_required_package_versions
        fi
      fi
    fi
    #
    if [[ "${broken_unifi_install_mongodb_server_clients}" != 'true' ]]; then
      if [[ "${os_codename}" =~ (trusty|utopic|vivid|wily|yakkety|zesty|artful|qiana|rebecca|rafaela|rosa|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing|resolute|sarah|serena|sonya|sylvia|tara|tessa|tina|tricia) ]]; then
        if [[ "${architecture}" =~ (amd64|arm64) ]]; then
	      if [[ "${os_codename}" =~ (precise|maya) && "${broken_unifi_install}" != 'true' ]]; then add_mongodb_34_repo="true"; fi
          add_mongodb_repo
          mongodb_installation
        elif [[ ! "${architecture}" =~ (amd64|arm64) ]]; then
          mongodb_server_clients_installation
        fi
      elif [[ "${os_codename}" =~ (wheezy|jessie|stretch|buster|bullseye|bookworm|trixie|forky|unstable) ]]; then
        if [[ "${architecture}" =~ (amd64|arm64) ]]; then
          add_mongodb_repo
          mongodb_installation
        elif [[ ! "${architecture}" =~ (amd64|arm64) ]]; then
          mongodb_server_clients_installation
        fi
      else
        header_red
        echo -e "${RED}#${RESET} The script is unable to grab your OS ( or does not support it )"
        echo "${architecture}"
        echo "${os_codename}"
      fi
    else
      echo -e "${GREEN}#${RESET} MongoDB is already installed! \\n"
    fi
  else
    echo -e "${GREEN}#${RESET} MongoDB is already installed! \\n"
    if "$(which dpkg)" -l mongodb-org-server 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
      mongodb_org_version="$(dpkg-query --showformat='${version}' --show mongodb-org-server 2> /dev/null | sed 's/.*://' | sed 's/-.*//g')"
      mongodb_org_version_no_dots="${mongodb_org_version//./}"
      if [[ "${mongodb_org_version_no_dots::2}" == '44' && "$(dpkg-query --showformat='${version}' --show mongodb-org-server 2> /dev/null | sed -e 's/.*://' -e 's/-.*//g' | awk -F. '{print $3}')" -ge "19" ]]; then if [[ "${glennr_mongod_compatible}" == "true" ]]; then unsupported_database_version_change="true"; fi; fi
      if [[ "${mongodb_org_version_no_dots::2}" -gt '44' ]]; then if [[ "${glennr_mongod_compatible}" == "true" && "${official_mongodb_compatible}" != 'true' ]]; then unsupported_database_version_change="true"; fi; fi
      if [[ -n "${previous_mongodb_version}" ]]; then if [[ "${mongodb_org_version_no_dots::2}" != "${previous_mongodb_version::2}" ]] && [[ "${previous_mongodb_version::2}" != "$((${mongodb_org_version_no_dots::2} - 2))" ]]; then unsupported_database_version_change="true"; fi; fi
      if [[ -n "${dpkg_log_mongodb_server}" ]]; then if [[ "${mongodb_org_version_no_dots::2}" != "${previous_mongodb_version::2}" ]]; then unsupported_database_version_change="true"; fi; fi
    elif "$(which dpkg)" -l mongodb-server 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
      mongodb_version="$(dpkg-query --showformat='${version}' --show mongodb-server 2> /dev/null | sed 's/.*://' | sed 's/-.*//g')"
      mongodb_version_no_dots="${mongodb_version//./}"
      if [[ "${mongodb_version_no_dots::2}" == '44' && "$(dpkg-query --showformat='${version}' --show mongodb-server 2> /dev/null | sed -e 's/.*://' -e 's/-.*//g' | awk -F. '{print $3}')" -ge "19" ]]; then if [[ "${glennr_mongod_compatible}" == "true" ]]; then unsupported_database_version_change="true"; fi; fi
      if [[ "${mongodb_version_no_dots::2}" -gt '44' ]]; then if [[ "${glennr_mongod_compatible}" == "true" && "${official_mongodb_compatible}" != 'true' ]]; then unsupported_database_version_change="true"; fi; fi
      if [[ -n "${previous_mongodb_version}" ]]; then if [[ "${mongodb_version_no_dots::2}" != "${previous_mongodb_version::2}" ]] && [[ "${previous_mongodb_version::2}" != "$((${mongodb_version_no_dots::2} - 2))" ]]; then unsupported_database_version_change="true"; fi; fi
      if [[ -n "${dpkg_log_mongodb_server}" ]]; then if [[ "${mongodb_version_no_dots::2}" != "${previous_mongodb_version::2}" ]]; then unsupported_database_version_change="true"; fi; fi
    fi
    if "$(which dpkg)" -l mongodb-org-server 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui" && [[ "${glennr_compiled_mongod}" == 'true' && "${mongodb_version_installed_no_dots::2}" =~ (50|60|70|80) && "${unsupported_database_version_change}" != 'true' ]]; then
      rm --force /tmp/EUS/mongodb/arm64_mongodb_purge_list &> /dev/null
      if "$(which dpkg)" -l mongodb-org 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then echo "mongodb-org" &>> /tmp/EUS/mongodb/arm64_mongodb_purge_list; fi
      if "$(which dpkg)" -l mongodb-org-database 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then echo "mongodb-org" &>> /tmp/EUS/mongodb/arm64_mongodb_purge_list; fi
      if "$(which dpkg)" -l mongodb-org-server 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then echo "mongodb-org" &>> /tmp/EUS/mongodb/arm64_mongodb_purge_list; fi
      echo -e "${GRAY_R}#${RESET} Purging mongodb-org-server..."
      echo -e "\\n------- $(date +%F-%T.%6N) -------\\n" &>> "${eus_dir}/logs/arm64-purge-mongodb.log"
      while read -r arm64_mongodb_package; do
        check_dpkg_lock
        if "${EUS_APT_ENV[@]}" env DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_downgrade_option[@]}" "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' purge "${arm64_mongodb_package}" &>> "${eus_dir}/logs/arm64-purge-mongodb.log"; then
          echo -e "${GREEN}#${RESET} Successfully purged ${arm64_mongodb_package}! \\n"
        else
          abort_reason="Failed to purge ${arm64_mongodb_package}."
          abort
        fi
      done < /tmp/EUS/mongodb/arm64_mongodb_purge_list
      mongodb_installation
    fi
  fi
  sleep 3
}

compress_and_relocate_database_recovery_logs() {
  local recovery_epoch
  recovery_epoch="$(date +%s)"
  local log_files
  log_files="$(grep -raEl "This version of MongoDB is too recent to start up on the existing data files|This may be due to an unsupported upgrade or downgrade.|UPGRADE PROBLEM|Cannot start server with an unknown storage engine|unsupported WiredTiger file version|DBException in initAndListen, terminating" "/usr/lib/unifi/logs")"
  if [[ -n "${log_files}" ]]; then
    echo -e "${GRAY_R}#${RESET} Compressing the previous MongoDB logs into an archive..."
    if command -v xz &> /dev/null; then
      echo "Starting to compress the mongodb logs into \"${eus_dir}/logs/unifi-database-recovery-${recovery_epoch}.tar.xz\"" &>>"${eus_dir}/logs/database-recovery-log-compression.log"
      if tar -Jcvf "${eus_dir}/logs/unifi-database-recovery-${recovery_epoch}.tar.xz" "${log_files}" &>>"${eus_dir}/logs/database-recovery-log-compression-debug.log"; then compress_success="true"; fi
    elif command -v bzip2 &> /dev/null; then
      echo "Starting to compress the mongodb logs into \"${eus_dir}/logs/unifi-database-recovery-${recovery_epoch}.tar.bz2\"" &>> "${eus_dir}/logs/database-recovery-log-compression.log"
      if tar -jcvf "${eus_dir}/logs/unifi-database-recovery-${recovery_epoch}.tar.bz2" "${log_files}" &>> "${eus_dir}/logs/database-recovery-log-compression-debug.log"; then compress_success="true"; fi
    elif command -v gzip &> /dev/null; then
      echo "Starting to compress the mongodb logs into \"${eus_dir}/logs/unifi-database-recovery-${recovery_epoch}.tar.gz\"" &>> "${eus_dir}/logs/database-recovery-log-compression.log"
      if tar -zcvf "${eus_dir}/logs/unifi-database-recovery-${recovery_epoch}.tar.gz" "${log_files}" &>> "${eus_dir}/logs/database-recovery-log-compression-debug.log"; then compress_success="true"; fi
    elif command -v zip &> /dev/null; then
      echo "Starting to compress the mongodb logs into \"${eus_dir}/logs/unifi-database-recovery-${recovery_epoch}.zip\"" &>> "${eus_dir}/logs/database-recovery-log-compression.log"
      if zip "${eus_dir}/logs/unifi-database-recovery-${recovery_epoch}.zip" "${log_files}" &>> "${eus_dir}/logs/database-recovery-log-compression-debug.log"; then compress_success="true"; fi
    else
      echo -e "${YELLOW}#${RESET} Failed to locate any compression tool... \\n"
    fi
    if [[ "${compress_success}" == 'true' ]]; then
      if command -v truncate &> /dev/null; then
        truncate -s 0 "${log_files}" &>> "${eus_dir}/logs/database-recovery-log-compression-debug.log"
      else
        echo -n | tee "${log_files}" &>> "${eus_dir}/logs/database-recovery-log-compression-debug.log"
      fi
      echo -e "${GREEN}#${RESET} Successfully compressed the previous MongoDB logs into an archive! \\n"
    fi
  fi
}

network_install_unsupported_database_version_change_override() {
  # Override MongoDB version change attempts when the application is up and running.
  if [[ "${unsupported_database_version_change}" == 'true' ]]; then
    if grep -sioq "^unifi.https.port" "/usr/lib/unifi/data/system.properties"; then dmport="$(awk '/^unifi.https.port/' /usr/lib/unifi/data/system.properties | cut -d'=' -f2)"; else dmport="8443"; fi
    if [[ -n "$(command -v jq)" ]]; then
      application_up="$(curl --silent --insecure "https://localhost:${dmport}/status" | jq -r '.meta.up' 2> /dev/null)"
      if [[ -z "${application_up}" ]]; then application_up="$(curl "${noproxy_curl_argument[@]}" --silent --insecure --connect-timeout 1 "https://localhost:${dmport}/status" | jq -r '.meta.up' 2> /dev/null)"; fi
    else
      application_up="$(curl --silent --insecure --connect-timeout 1 "https://localhost:${dmport}/status" | grep -o '"up":[^,]*' | awk -F ':' '{print $2}')"
      if [[ -z "${application_up}" ]]; then application_up="$(curl "${noproxy_curl_argument[@]}" --silent --insecure --connect-timeout 1 "https://localhost:${dmport}/status" | grep -o '"up":[^,]*' | awk -F ':' '{print $2}')"; fi
    fi
    if [[ "${application_up}" == 'true' ]]; then
      echo -e "$(date +%F-%T.%6N) | The Network Application appears to be functioning, cancelling any unsupported MongoDB version change fix attempts..." &>> "${eus_dir}/logs/mongodb-unsupported-version-change-override.log"
      echo -e "$(date +%F-%T.%6N) | previous_mongodb_version: ${previous_mongodb_version}, previous_mongodb_version_with_dot: ${previous_mongodb_version_with_dot}, unsupported_database_version_change: ${unsupported_database_version_change}" &>> "${eus_dir}/logs/mongodb-unsupported-version-change-override.log"
      unset previous_mongodb_version
      unset previous_mongodb_version_with_dot
      unset unsupported_database_version_change
    fi
  fi
}

network_install_unsupported_database_version_change_recovery() {
  if [[ "${mongo_version_locked}" == '4.4.18' ]] || [[ "${unsupported_database_version_change}" == 'true' ]]; then
    if "$(which dpkg)" -l "${gr_mongod_name}" 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
      mongodb_org_version="$(dpkg-query --showformat='${version}' --show "${gr_mongod_name}" 2> /dev/null | sed 's/.*://' | sed 's/-.*//g')"
      mongodb_org_version_no_dots="${mongodb_org_version//./}"
    elif "$(which dpkg)" -l mongodb-org-server 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
      mongodb_org_version="$(dpkg-query --showformat='${version}' --show mongodb-org-server 2> /dev/null | sed 's/.*://' | sed 's/-.*//g')"
      mongodb_org_version_no_dots="${mongodb_org_version//./}"
    elif "$(which dpkg)" -l mongodb-server 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
      mongodb_org_version="$(dpkg-query --showformat='${version}' --show mongodb-server 2> /dev/null | sed 's/.*://' | sed 's/-.*//g')"
      mongodb_org_version_no_dots="${mongodb_org_version//./}"
    fi
    if [[ "${mongodb_org_version_no_dots::2}" == '44' && "$(echo "${mongodb_org_version}" | cut -d'.' -f3)" -gt "18" ]] || [[ "${unsupported_database_version_change}" == 'true' ]]; then
      echo ""
      eus_directory_location="/tmp/EUS"
      eus_create_directories "mongodb"
      if "$(which dpkg)" -l | grep "^ii\\|^hi\\|^ri\\|^pi\\|^ui\\|^iU" | awk '{print$2}' | grep -iq "mongodb-org-server$" && [[ "${previous_mongodb_version::2}" =~ (50|60|70|80) ]]; then
        if [[ "${glennr_mongod_compatible}" == "true" ]]; then
          glennr_compiled_mongod="true"
        fi
      fi
      "$(which dpkg)" -l | grep "mongo-\\|mongodb-\\|mongod-" | grep "^ii\\|^hi\\|^hU\\|^ri\\|^pi\\|^ui\\|^iU" | awk '{print $2}' &> /tmp/EUS/mongodb/packages_list
      check_add_mongodb_repo_variable
      if [[ -n "${previous_mongodb_version}" ]]; then
        if [[ "${previous_mongodb_version::2}" == "26" ]]; then
          original_previous_mongodb_version="26"
          original_previous_mongodb_version_with_dot="3.0"
          previous_mongodb_version="30"
          previous_mongodb_version_with_dot="3.0"
        fi
        mongodb_add_repo_downgrade_variable="add_mongodb_${previous_mongodb_version::2}_repo"
        declare "$mongodb_add_repo_downgrade_variable=true"
        if [[ "${glennr_compiled_mongod}" == 'true' && "${previous_mongodb_version::2}" =~ (50|60|70|80) ]]; then
          mongod_add_repo_downgrade_variable="add_mongod_${previous_mongodb_version::2}_repo"
          declare "$mongod_add_repo_downgrade_variable=true"
        fi
        mongodb_downgrade_process="true"
      else
        add_mongodb_44_repo="true"
      fi
      if [[ -z "${mongo_version_locked}" ]]; then unset_mongo_version_locked="true"; fi
      remove_older_mongodb_repositories
      previous_mongodb_org_v="${mongodb_org_v}"
      unset mongodb_org_v
      skip_mongodb_org_v="true"
      add_mongodb_repo
      mongodb_package_libssl="mongodb-org-server"
      mongodb_package_version_libssl="${install_mongodb_version}"
      libssl_installation_check
      rm --force /tmp/EUS/mongodb/packages_remove_list &> /dev/null
      "$(which dpkg)" -l | grep "^ii\\|^hi\\|^ri\\|^pi\\|^ui\\|^iU" | awk '{print$2}' | grep "^unifi$" | awk '{print $1}' &>> /tmp/EUS/mongodb/packages_remove_list
      cp /tmp/EUS/mongodb/packages_list /tmp/EUS/mongodb/packages_list.tmp &> /dev/null
      recovery_install_mongodb_version="${install_mongodb_version//./}"
      while read -r installed_mongodb_package; do
        if ! apt-cache policy "^${installed_mongodb_package}$" | grep -ioq "${install_mongodb_version}"; then
          if [[ "${installed_mongodb_package}" == "mongodb-server-core" ]] && [[ "${previous_mongodb_version::2}" != "24" ]]; then if sed -i "s/mongodb-server-core$/mongodb-org-server/g" /tmp/EUS/mongodb/packages_list; then echo "mongodb-server-core" &>> /tmp/EUS/mongodb/packages_remove_list; fi; fi
          if [[ "${installed_mongodb_package}" == "mongodb-server" ]] && [[ "${previous_mongodb_version::2}" != "24" ]]; then if sed -i "s/mongodb-server$/mongodb-org-server/g" /tmp/EUS/mongodb/packages_list; then echo "mongodb-server" &>> /tmp/EUS/mongodb/packages_remove_list; fi; fi
          if [[ "${installed_mongodb_package}" == "mongodb-clients" ]] && [[ "${previous_mongodb_version::2}" != "24" ]]; then if sed -i "s/mongodb-clients$/mongodb-org-shell/g" /tmp/EUS/mongodb/packages_list; then echo "mongodb-clients" &>> /tmp/EUS/mongodb/packages_remove_list; fi; fi
          if [[ "${installed_mongodb_package}" == "mongo-tools" ]] && [[ "${previous_mongodb_version::2}" != "24" ]]; then if sed -i "s/mongo-tools$/mongodb-org-tools/g" /tmp/EUS/mongodb/packages_list; then echo "mongo-tools" &>> /tmp/EUS/mongodb/packages_remove_list; fi; fi
          if [[ "${installed_mongodb_package}" == "mongodb-org-database-tools-extra" && "${recovery_install_mongodb_version::2}" -lt "44" ]]; then
            if "$(which dpkg)" -l | grep "^ii\\|^hi\\|^ri\\|^pi\\|^ui\\|^iU" | awk '{print$2}' | grep -iq "mongodb-org-database$"; then echo -e "mongodb-org-database" &>> /tmp/EUS/mongodb/packages_remove_list; fi
            if "$(which dpkg)" -l | grep "^ii\\|^hi\\|^ri\\|^pi\\|^ui\\|^iU" | awk '{print$2}' | grep -iq "mongodb-org-tools$"; then echo -e "mongodb-org-tools" &>> /tmp/EUS/mongodb/packages_remove_list; fi
            echo -e "mongodb-org-database-tools-extra" &>> /tmp/EUS/mongodb/packages_remove_list
          fi
          sed -i "/^${installed_mongodb_package}$/d" /tmp/EUS/mongodb/packages_list
        fi
        if [[ "${installed_mongodb_package}" == 'mongodb-org-server' && "${previous_mongodb_version::2}" =~ (50|60|70|80) && "${glennr_compiled_mongod}" == 'true' ]]; then
          if sed -i "s/mongodb-org-server$/${gr_mongod_name}/g" /tmp/EUS/mongodb/packages_list; then
            echo "mongodb-org-server" &>> /tmp/EUS/mongodb/packages_remove_list
            while read -r mongodb_org_server_dep; do
              if "$(which dpkg)" -l | awk '{print $2}' | grep -ioq "${mongodb_org_server_dep}$" && ! grep -ioq "${mongodb_org_server_dep}" /tmp/EUS/mongodb/packages_remove_list; then echo "${mongodb_org_server_dep}" &>> /tmp/EUS/mongodb/packages_remove_list; fi
            done < <(apt-cache rdepends "mongodb-org-server" 2> /dev/null | awk -v pkg="${package}" '($0 ~ /mongod/ ) && $0 != pkg && !seen[$0]++ {gsub(/ /, "", $0); print}' 2> /dev/null)
          fi
        fi
      done < "/tmp/EUS/mongodb/packages_list.tmp"
      if "$(which dpkg)" -l | grep "^ii\\|^hi\\|^ri\\|^pi\\|^ui\\|^iU" | grep -iq "${gr_mongod_name}" && [[ ! "${recovery_install_mongodb_version::2}" =~ (50|60|70|80) ]]; then if sed -i "s/${gr_mongod_name}/mongodb-org-server/g" /tmp/EUS/mongodb/packages_list; then echo "${gr_mongod_name}" &>> /tmp/EUS/mongodb/packages_remove_list; fi; fi
      rm --force "/tmp/EUS/mongodb/packages_list.tmp" &> /dev/null
      awk '{ if ($0 == "mongodb-server") { server_found = 1; } else if ($0 == "mongodb-server-core") { core_found = 1; } if (!found_both) { original[NR] = $0; } } END { if (server_found && core_found) { found_both = 1; printed_server = 0; printed_core = 0; for (i = 1; i <= NR; i++) { if (original[i] == "mongodb-server" && !printed_server) { printed_server = 1; continue; } else if (original[i] == "mongodb-server-core" && !printed_core) { printed_core = 1; print "mongodb-server"; } print original[i]; } } else { for (i = 1; i <= NR; i++) { print original[i]; } } }' /tmp/EUS/mongodb/packages_remove_list &> /tmp/EUS/mongodb/packages_remove_list.tmp && mv /tmp/EUS/mongodb/packages_remove_list.tmp /tmp/EUS/mongodb/packages_remove_list
      if grep -iq "unifi" /tmp/EUS/mongodb/packages_remove_list; then reinstall_unifi="true"; fi
      while read -r package; do
        mongodb_extra_dependencies=()
        while read -r mongodb_extra_dependency; do
          if "$(which dpkg)" -l | awk '{print $2}' | grep -ioq "${mongodb_extra_dependency}$"; then mongodb_extra_dependencies+=("${mongodb_extra_dependency}"); fi
        done < <(apt-cache rdepends "${package}" 2> /dev/null | awk -v pkg="${package}" '($0 ~ /mongodb-/ || $0 ~ /unifi/) && $0 != pkg && !seen[$0]++ {gsub(/ /, "", $0); print}' 2> /dev/null)
        if [[ "${package}" == "mongodb-org-"* ]] && dpkg -l | grep -i "^ii\\|^hi\\|^ri\\|^pi\\|^ui" | awk '{print $2}' | grep -ioq "mongodb-org$"; then
          for dep in "${mongodb_extra_dependencies[@]}"; do if [[ "${dep}" == "mongodb-org" ]]; then located_mongodb_org_dep="true"; break; fi; done
          if [[ "${located_mongodb_org_dep}" != "true" ]]; then mongodb_extra_dependencies+=("mongodb-org"); fi
        fi
        for dep in "${mongodb_extra_dependencies[@]}"; do
          if [[ "${dep}" == "unifi" && "${reinstall_unifi}" != 'true' ]]; then reinstall_unifi="true"; fi
          if [[ "${dep}" == "mongodb-org"* && "${glennr_compiled_mongod}" == 'true' ]]; then
            if grep -iq "${dep}" /tmp/EUS/mongodb/packages_list; then
              echo -e "$(date +%F-%T.%6N) | Located \"${dep}\" in \"/tmp/EUS/mongodb/packages_list\", removing it..." &>> "${eus_dir}/logs/mongodb-unsupported-version-change-locate.log"
              if sed -i "/^${dep}$/d" /tmp/EUS/mongodb/packages_list; then
                echo -e "$(date +%F-%T.%6N) | Successfully removed \"${dep}\" from \"/tmp/EUS/mongodb/packages_list\"!" &>> "${eus_dir}/logs/mongodb-unsupported-version-change-locate.log"
                echo -e "$(date +%F-%T.%6N) | Packages \"$(awk 'ORS=", " { print $0 }' /tmp/EUS/mongodb/packages_list 2> /dev/null | sed 's/, $//')\" are still in \"/tmp/EUS/mongodb/packages_list\"!" &>> "${eus_dir}/logs/mongodb-unsupported-version-change-locate.log"
              fi
            fi
          fi
        done
        if [[ "${#mongodb_extra_dependencies[@]}" -gt 0 ]]; then mongodb_extra_dependencies_message=", $(IFS=,; echo "${mongodb_extra_dependencies[*]}" | sed 's/,/, /g; s/,\([^,]*\)$/ and\1/')"; fi
        if "$(which dpkg)" -l | awk '{print $2}' | grep -ioq "${package}$"; then
          echo -e "${GRAY_R}#${RESET} Removing ${package}${mongodb_extra_dependencies_message}..."
          check_dpkg_lock
          if "${EUS_APT_ENV[@]}" env DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_downgrade_option[@]}" "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' remove "${package}" "${mongodb_extra_dependencies[@]}" &>> "${eus_dir}/logs/mongodb-unsupported-version-change.log"; then
            echo -e "${GREEN}#${RESET} Successfully removed ${package}${mongodb_extra_dependencies_message}! \\n"
          else
            abort_reason="Failed to remove ${package}${mongodb_extra_dependencies_message} during the downgrade process."
            abort
          fi
        fi
        unset mongodb_extra_dependencies
        unset mongodb_extra_dependencies_message
      done < /tmp/EUS/mongodb/packages_remove_list
      while read -r mongodb_package; do
        if [[ "${previous_mongodb_version::2}" == "24" ]]; then
          if [[ "${mongodb_package}" == "mongodb-server" ]]; then
            manually_setmongo_last_attempt_version="true"
            mongo_last_attempt_version="2.6"
            mongo_last_attempt_type="server"
            mongo_last_attempt
            if [[ "${mongo_last_attempt_install_success}" != 'true' ]]; then abort_reason="Failed to install mongodb-server through mongo_last_attempt function during the MongoDB Downgrade process."; abort_function_skip_reason="true"; abort; fi
          elif [[ "${mongodb_package}" == "mongodb-clients" ]]; then
            manually_setmongo_last_attempt_version="true"
            mongo_last_attempt_version="2.6"
            mongo_last_attempt_type="clients"
            mongo_last_attempt
            if [[ "${mongo_last_attempt_install_success}" != 'true' ]]; then abort_reason="Failed to install mongodb-clients through mongo_last_attempt function during the MongoDB Downgrade process."; abort_function_skip_reason="true"; abort; fi
          fi
        else
          echo -e "${GRAY_R}#${RESET} Downgrading ${mongodb_package}..."
          if [[ "${mongodb_package}" =~ (mongod-armv8|mongod-amd64) ]]; then unset mongodb_version_with_equal; else mongodb_version_with_equal="${install_mongodb_version_with_equality_sign}"; fi
          check_dpkg_lock
          if "${EUS_APT_ENV[@]}" env DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_downgrade_option[@]}" "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "${mongodb_package}${mongodb_version_with_equal}" &>> "${eus_dir}/logs/mongodb-unsupported-version-change.log"; then
            echo -e "${GREEN}#${RESET} Successfully downgraded ${mongodb_package} to version ${install_mongodb_version}! \\n"
          else
            check_unmet_dependencies
            broken_packages_check
            attempt_recover_broken_packages
            add_apt_option_no_install_recommends="true"; get_apt_options
            check_dpkg_lock
            if "${EUS_APT_ENV[@]}" env DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_downgrade_option[@]}" "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "${mongodb_package}${mongodb_version_with_equal}" &>> "${eus_dir}/logs/mongodb-unsupported-version-change.log"; then
              echo -e "${GREEN}#${RESET} Successfully downgraded ${mongodb_package} to version ${install_mongodb_version}! \\n"
            else
              try_different_mongodb_repo="true"
              skip_mongodb_org_v="true"
              add_mongodb_repo
              check_dpkg_lock
              if "${EUS_APT_ENV[@]}" env DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_downgrade_option[@]}" "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "${mongodb_package}${mongodb_version_with_equal}" &>> "${eus_dir}/logs/mongodb-unsupported-version-change.log"; then
                echo -e "${GREEN}#${RESET} Successfully downgraded ${mongodb_package} to version ${install_mongodb_version}! \\n"
              else
                try_http_mongodb_repo="true"
                skip_mongodb_org_v="true"
                add_mongodb_repo
                check_dpkg_lock
                if "${EUS_APT_ENV[@]}" env DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_downgrade_option[@]}" "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "${mongodb_package}${mongodb_version_with_equal}" &>> "${eus_dir}/logs/mongodb-unsupported-version-change.log"; then
                  echo -e "${GREEN}#${RESET} Successfully downgraded ${mongodb_package} to version ${install_mongodb_version}! \\n"
                else
                  abort_reason="Failed to downgrade ${mongodb_package} from version ${mongodb_org_version} to ${install_mongodb_version}."
                  abort
                fi
              fi
            fi
            get_apt_options
          fi
        fi
        echo -e "${GRAY_R}#${RESET} Preventing ${mongodb_package} from upgrading..."
        if echo "${mongodb_package} hold" | "$(which dpkg)" --set-selections &>> "${eus_dir}/logs/package-hold.log"; then
          echo -e "${GREEN}#${RESET} Successfully prevented ${mongodb_package} from upgrading! \\n"
        else
          echo -e "${RED}#${RESET} Failed to prevent ${mongodb_package} from upgrading...\\n"
        fi
      done < /tmp/EUS/mongodb/packages_list
      sleep 2
      rm --force /tmp/EUS/mongodb/packages_list &> /dev/null
      if [[ -n "${mongodb_add_repo_downgrade_variable}" ]]; then
        unset "${mongodb_add_repo_downgrade_variable}"
        unset mongodb_downgrade_process
      else
        unset add_mongodb_44_repo
      fi
      if [[ "${reinstall_unifi}" == 'true' ]]; then
        reinstall_unifi_version="$(head -n1 "${unifi_db_version_path}" | sed 's/[^0-9.]//g' 2> /dev/null)"
        if [[ -z "${reinstall_unifi_version}" ]]; then reinstall_unifi_version="$(dpkg-query --showformat='${version}' --show unifi 2> /dev/null | awk -F '[-]' '{print $1}')"; fi
        if [[ "$(curl "${curl_argument[@]}" https://api.glennr.nl/api/application-release?status 2> /dev/null | jq -r '.[]' 2> /dev/null)" == "OK" ]]; then
          fw_update_dl_link="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/application-release?app=network&version=${reinstall_unifi_version}${unifi_core_glennr_api}" | jq -r '."download_link"' | sed '/null/d' 2> "${eus_dir}/logs/locate-download.log")"
          fw_update_gr_dl_link="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/application-release?app=network&version=${reinstall_unifi_version}&server=archive${unifi_core_glennr_api}" | jq -r '."download_link"' | sed '/null/d' 2> "${eus_dir}/logs/locate-download.log")"
          fw_update_dl_link_sha256sum="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/application-release?app=network&version=${reinstall_unifi_version}${unifi_core_glennr_api}" | jq -r '.sha256sum' | sed '/null/d' 2> "${eus_dir}/logs/locate-download.log")"
        fi
        if [[ -z "${fw_update_dl_link}" ]]; then
          fw_update_dl_link="$(curl "${curl_argument[@]}" --location --request GET "https://fw-update.ui.com/api/firmware-latest?filter=eq~~version_major~~$(awk -F'.' '{print $1}' <<< "${reinstall_unifi_version}")&filter=eq~~version_minor~~$(awk -F'.' '{print $2}' <<< "${reinstall_unifi_version}")&filter=eq~~version_patch~~$(awk -F'.' '{print $3}' <<< "${reinstall_unifi_version}")&filter=eq~~platform~~debian" 2> /dev/null | jq -r "._embedded.firmware[0]._links.data.href" 2> /dev/null | sed '/null/d' 2> "${eus_dir}/logs/locate-download.log")"
          fw_update_dl_link_sha256sum="$(curl "${curl_argument[@]}" --location --request GET "https://fw-update.ui.com/api/firmware-latest?filter=eq~~version_major~~$(awk -F'.' '{print $1}' <<< "${reinstall_unifi_version}")&filter=eq~~version_minor~~$(awk -F'.' '{print $2}' <<< "${reinstall_unifi_version}")&filter=eq~~version_patch~~$(awk -F'.' '{print $3}' <<< "${reinstall_unifi_version}")&filter=eq~~platform~~debian" 2> /dev/null | jq -r "._embedded.firmware[0].sha256_checksum" 2> /dev/null | sed '/null/d' 2> "${eus_dir}/logs/locate-download.log")"
        fi
        if [[ -n "${fw_update_gr_dl_link}" ]]; then
          fw_update_dl_links=("${fw_update_dl_link}" "${fw_update_gr_dl_link}")
        else
          fw_update_dl_links=("${fw_update_dl_link}")
        fi
        for fw_update_dl_link in "${fw_update_dl_links[@]}"; do
          eus_tmp_deb_name="${unifi_deb_file_name}_${reinstall_unifi_version}"
          eus_tmp_deb_var="unifi_temp"
          eus_tmp_directory_check
          echo -e "$(date +%F-%T.%6N) | Downloading ${fw_update_dl_link} to ${unifi_temp}" &>> "${eus_dir}/logs/unifi-download.log"
          if [[ "${net_application_download_message_printed}" != 'true' ]]; then echo -e "${GRAY_R}#${RESET} Downloading UniFi Network Application version ${reinstall_unifi_version}..."; net_application_download_message_printed="true"; fi
          if curl "${nos_curl_argument[@]}" --output "$unifi_temp" "${fw_update_dl_link}" &>> "${eus_dir}/logs/unifi-download.log"; then
            if command -v sha256sum &> /dev/null; then
              if [[ "$(sha256sum "$unifi_temp" | awk '{print $1}')" != "${fw_update_dl_link_sha256sum}" ]]; then
                if curl "${nos_curl_argument[@]}" --output "$unifi_temp" "${fw_update_dl_link}" &>> "${eus_dir}/logs/unifi-download.log"; then
                  if [[ "$(sha256sum "$unifi_temp" | awk '{print $1}')" != "${fw_update_dl_link_sha256sum}" ]]; then
                    continue
                  fi
                fi
              fi
            elif command -v dpkg-deb &> /dev/null; then
              if ! dpkg-deb --info "${unifi_temp}" &> /dev/null; then
                if curl "${nos_curl_argument[@]}" --output "$unifi_temp" "${fw_update_dl_link}" &>> "${eus_dir}/logs/unifi-download.log"; then
                  if ! dpkg-deb --info "${unifi_temp}" &> /dev/null; then
                    echo -e "$(date +%F-%T.%6N) | The file downloaded via ${fw_update_dl_link} was not a debian file format..." &>> "${eus_dir}/logs/unifi-download.log"
                    continue
                  fi
                fi
              fi
            fi
            echo -e "${GREEN}#${RESET} Successfully downloaded UniFi Network Application version ${reinstall_unifi_version}! \\n"; unifi_downloaded="true"; break
          else
            continue
          fi
        done
        if [[ "${unifi_downloaded}" == 'true' ]]; then
          unset unifi_downloaded
          first_digit_unifi="$(echo "${reinstall_unifi_version}" | cut -d'.' -f1)"
          second_digit_unifi="$(echo "${reinstall_unifi_version}" | cut -d'.' -f2)"
          third_digit_unifi="$(echo "${reinstall_unifi_version}" | cut -d'.' -f3)"
          java_install_check
          network_install_required_packages_check
          network_install_dependencies_check
          unifi_deb_package_modification
          unifi_version="${reinstall_unifi_version}"
          network_install_set_required_package_versions
          ignore_unifi_package_dependencies
          echo -e "${GRAY_R}#${RESET} Re-installing UniFi Network Application version ${reinstall_unifi_version}..."
          check_dpkg_lock
          echo "unifi unifi/has_backup boolean true" 2> /dev/null | debconf-set-selections
          # shellcheck disable=SC2086
          if DEBIAN_FRONTEND='noninteractive' "$(which dpkg)" -i ${dpkg_ignore_depends_flag} "${unifi_temp}" &>> "${eus_dir}/logs/mongodb-unsupported-version-change.log"; then
            echo -e "${GREEN}#${RESET} Successfully re-installed UniFi Network Application version ${reinstall_unifi_version}! \\n"
            get_unifi_version
          else
            abort_reason="Failed to reinstall UniFi Network Application ${reinstall_unifi_version} during the MongoDB Downgrade process."
            abort
          fi
        else
          abort_reason="Failed to download UniFi Network Application version ${reinstall_unifi_version} during the MongoDB Downgrade process."
          abort
        fi
      fi
      if grep -sioq "^unifi.https.port" "/usr/lib/unifi/data/system.properties"; then dmport="$(awk '/^unifi.https.port/' /usr/lib/unifi/data/system.properties | cut -d'=' -f2)"; else dmport="8443"; fi
      if [[ -n "$(command -v jq)" ]]; then
        application_up="$(curl --silent --insecure "https://localhost:${dmport}/status" | jq -r '.meta.up' 2> /dev/null)"
        if [[ -z "${application_up}" ]]; then application_up="$(curl "${noproxy_curl_argument[@]}" --silent --insecure --connect-timeout 1 "https://localhost:${dmport}/status" | jq -r '.meta.up' 2> /dev/null)"; fi
      else
        application_up="$(curl --silent --insecure --connect-timeout 1 "https://localhost:${dmport}/status" | grep -o '"up":[^,]*' | awk -F ':' '{print $2}')"
        if [[ -z "${application_up}" ]]; then application_up="$(curl "${noproxy_curl_argument[@]}" --silent --insecure --connect-timeout 1 "https://localhost:${dmport}/status" | grep -o '"up":[^,]*' | awk -F ':' '{print $2}')"; fi
      fi
      if [[ "${application_up}" == 'true' ]]; then compress_and_relocate_database_recovery_logs; fi
      if [[ "${unset_mongo_version_locked}" == 'true' ]]; then unset mongo_version_locked; fi
      if [[ -n "${original_previous_mongodb_version}" ]]; then previous_mongodb_version="${original_previous_mongodb_version}"; fi
      if [[ -n "${original_previous_mongodb_version_with_dot}" ]]; then previous_mongodb_version_with_dot="${original_previous_mongodb_version_with_dot}"; fi
      reverse_check_add_mongodb_repo_variable
      mongodb_org_v="${previous_mongodb_org_v}"
      unset previous_mongodb_org_v
    fi
  fi
}

network_install_minimal_mongodb_version_check() {
  # Check if MongoDB is newer than 2.6 (3.6 for 7.5.x) for UniFi Network application 7.4.x
  if [[ "${first_digit_unifi}" -gt '7' ]] || [[ "${first_digit_unifi}" == '7' && "${second_digit_unifi}" -ge '4' ]] || [[ "${first_digit_unifi}" == '7' && "${second_digit_unifi}" -ge '5' ]]; then
    if [[ "${first_digit_unifi}" -gt '7' ]] || [[ "${first_digit_unifi}" == '7' && "${second_digit_unifi}" -ge '5' ]]; then minimum_required_mongodb_version_dot="3.6"; minimum_required_mongodb_version="36"; unifi_latest_supported_version_number="7.4"; fi
    if [[ "${first_digit_unifi}" == '7' && "${second_digit_unifi}" == '4' ]]; then minimum_required_mongodb_version_dot="2.6"; minimum_required_mongodb_version="26"; unifi_latest_supported_version_number="7.3"; fi
    mongodb_server_version="$("$(which dpkg)" -l | grep "^ii\\|^hi\\|^ri\\|^pi\\|^ui\\|^iU" | grep -E "(mongodb-server|mongodb-org-server|mongod-armv8|mongod-amd64)[[:space:]]" | awk '{print $3}' | sed -e 's/.*://' -e 's/-.*//' -e 's/+.*//' -e 's/\.//g')"
    if [[ -z "${mongodb_server_version}" ]]; then
      if [[ -n "$(command -v mongod)" ]]; then
        if "${mongocommand}" --port 27117 --eval "print(\"waited for connection\")" &> /dev/null; then
          mongodb_server_version="$("$(which mongod)" --quiet --eval "db.version()" | sed 's/\.//g' | sed 's/.*://' | sed 's/-.*//g')"
        else
          mongodb_server_version="$("$(which mongod)" --version --quiet | tr '[:upper:]' '[:lower:]' | sed -e '/db version/d' -e '/mongodb shell/d' -e 's/build info: //g' | jq -r '.version' | sed 's/\.//g')"
        fi
      fi
    fi
    if [[ "${mongodb_server_version::2}" -lt "${minimum_required_mongodb_version}" ]]; then
      header_red
      echo -e "${GRAY_R}#${RESET} UniFi Network Application ${first_digit_unifi}.${second_digit_unifi}.${third_digit_unifi} requires MongoDB ${minimum_required_mongodb_version_dot} or newer."
      echo -e "${GRAY_R}#${RESET} The latest version that you can run with MongoDB version $("$(which dpkg)" -l | grep -E "(mongodb-server|mongodb-org-server|mongod-armv8|mongod-amd64)[[:space:]]" | awk '{print $3}' | sed -e 's/.*://' -e 's/-.*//' -e 's/+.*//') is $(curl "${curl_argument[@]}" "https://api.glennr.nl/api/latest-application-release?app=network&version=${unifi_latest_supported_version_number}" 2> /dev/null | jq -r '.latest_version' 2> /dev/null) and older.. \\n\\n"
      echo -e "${GRAY_R}#${RESET} Upgrade to MongoDB ${minimum_required_mongodb_version_dot} or newer, or perform a fresh install with the latest OS."
      echo -e "${GRAY_R}#${RESET} Installation Script   | https://community.ui.com/questions/ccbc7530-dd61-40a7-82ec-22b17f027776\\n\\n"
      if [[ "$(getconf LONG_BIT)" == '32' ]]; then
        echo -e "${GRAY_R}#${RESET} You're using a 32-bit OS.. please switch over to a 64-bit OS.\\n\\n"
      fi
      author
      exit 0
    fi
  fi
}

network_install_7_2_workaround_check() {
  # Quick workaround for 7.2.91 and older 7.2 versions.
  if [[ "${first_digit_unifi}" == "7" && "${second_digit_unifi}" == "2" && "${third_digit_unifi}" -le "91" ]]; then
    NAME="unifi"
    UNIFI_USER="${UNIFI_USER:-unifi}"
    DATADIR="${UNIFI_DATA_DIR:-/var/lib/$NAME}"
    if ! id "${UNIFI_USER}" >/dev/null 2>&1; then
      adduser --system --home "${DATADIR}" --no-create-home --group --disabled-password --quiet "${UNIFI_USER}"
    fi
    if ! [[ -d "/usr/lib/unifi/" ]]; then mkdir -p /usr/lib/unifi/ && chown -R unifi:unifi /usr/lib/unifi/; fi
    if ! [[ -d "/var/lib/unifi/" ]]; then mkdir -p /var/lib/unifi/ && chown -R unifi:unifi /var/lib/unifi/; fi
  fi
}

network_install_installation_process() {
  header
  echo -e "${GRAY_R}#${RESET} Installing your UniFi Network Application ${GRAY_R}${unifi_clean}${RESET}...\\n"
  sleep 2
  if [[ "${unifi_network_application_downloaded}" != 'true' ]]; then
    unifi_fwupdate="$(curl "${curl_argument[@]}" "https://fw-update.ui.com/api/firmware-latest?filter=eq~~version_major~~${first_digit_unifi}&filter=eq~~version_minor~~${second_digit_unifi}&filter=eq~~version_patch~~${third_digit_unifi}&filter=eq~~platform~~debian" 2> /dev/null | jq -r "._embedded.firmware[]._links.data.href" 2> /dev/null | sed '/null/d' 2> "${eus_dir}/logs/locate-download.log")"
    if [[ -z "${unifi_fwupdate}" ]]; then unifi_fwupdate="$(curl "${curl_argument[@]}" "http://fw-update.ui.com/api/firmware-latest?filter=eq~~version_major~~${first_digit_unifi}&filter=eq~~version_minor~~${second_digit_unifi}&filter=eq~~version_patch~~${third_digit_unifi}&filter=eq~~platform~~debian" 2> /dev/null | jq -r "._embedded.firmware[]._links.data.href" 2> /dev/null | sed '/null/d' 2> "${eus_dir}/logs/locate-download.log")"; fi
    if [[ "$(curl "${curl_argument[@]}" https://api.glennr.nl/api/application-release?status 2> /dev/null | jq -r '.[]' 2> /dev/null)" == "OK" ]]; then
      glennr_unifi_dl="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/application-release?app=network&version=${first_digit_unifi}.${second_digit_unifi}.${third_digit_unifi}${unifi_core_glennr_api}" | jq -r '."download_link"' | sed '/null/d' 2> "${eus_dir}/logs/locate-download.log")"
      glennr_gr_unifi_dl="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/application-release?app=network&version=${first_digit_unifi}.${second_digit_unifi}.${third_digit_unifi}&server=archive${unifi_core_glennr_api}" | jq -r '."download_link"' | sed '/null/d' 2> "${eus_dir}/logs/locate-download.log")"
      unifi_sha256sum="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/application-release?app=network&version=${first_digit_unifi}.${second_digit_unifi}.${third_digit_unifi}${unifi_core_glennr_api}" | jq -r '."sha256sum"' | sed '/null/d' 2> "${eus_dir}/logs/locate-download.log")"
    else
      unifi_sha256sum="$(curl "${curl_argument[@]}" "https://fw-update.ui.com/api/firmware-latest?filter=eq~~version_major~~${first_digit_unifi}&filter=eq~~version_minor~~${second_digit_unifi}&filter=eq~~version_patch~~${third_digit_unifi}&filter=eq~~platform~~debian" 2> /dev/null | jq -r "._embedded.firmware[0].sha256_checksum" 2> /dev/null | sed '/null/d' 2> "${eus_dir}/logs/locate-download.log")"
    fi
    bash_history_unifi_dl="$(timeout 30 find /home /root -type f -name ".bash_history" -exec grep -oP "https?://\S+/${unifi_clean}\S+" {} \; 2> /dev/null | tail -n1)"
    unifi_download_urls=()
    if [[ "$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/geo" 2> /dev/null | jq -r '."continent_code"' 2> /dev/null)" == "EU" ]]; then
      if [[ -n "${glennr_gr_unifi_dl}" ]]; then unifi_download_urls+=("${glennr_gr_unifi_dl}"); fi
      if [[ -n "${glennr_unifi_dl}" ]]; then unifi_download_urls+=("${glennr_unifi_dl}"); fi
    else
      if [[ -n "${glennr_unifi_dl}" ]]; then unifi_download_urls+=("${glennr_unifi_dl}"); fi
      if [[ -n "${glennr_gr_unifi_dl}" ]]; then unifi_download_urls+=("${glennr_gr_unifi_dl}"); fi
    fi
    if [[ -n "${unifi_fwupdate}" ]]; then unifi_download_urls+=("${unifi_fwupdate}"); fi
    if [[ -n "${bash_history_unifi_dl}" ]]; then unifi_download_urls+=("${bash_history_unifi_dl}"); fi
    #if [[ -n "${unifi_secret}" ]]; then unifi_download_urls+=("https://dl.ui.com/unifi/${unifi_secret}/${unifi_deb_file_name}.deb"); fi
    if [[ -n "${unifi_clean}" ]]; then unifi_download_urls+=("https://dl.ui.com/unifi/${unifi_clean}/${unifi_deb_file_name}.deb"); fi
    if [[ -n "${unifi_repo_version}" ]]; then unifi_download_urls+=("https://dl.ui.com/unifi/debian/pool/ubiquiti/u/unifi/unifi_${unifi_repo_version}_all.deb"); fi
    echo -e "${GRAY_R}#${RESET} Downloading the UniFi Network Application..."
    for unifi_download_url in "${unifi_download_urls[@]}"; do
      eus_tmp_deb_name="${unifi_deb_file_name}_${unifi_clean}"
      eus_tmp_deb_var="unifi_temp"
      eus_tmp_directory_check
      echo -e "$(date +%F-%T.%6N) | Downloading ${unifi_download_url} to ${unifi_temp}" &>> "${eus_dir}/logs/unifi-download.log"
      if curl "${nos_curl_argument[@]}" --output "${unifi_temp}" "${unifi_download_url}" &>> "${eus_dir}/logs/unifi-download.log"; then
        if command -v sha256sum &> /dev/null && [[ -n "${unifi_sha256sum}" ]]; then
          if [[ "$(sha256sum "$unifi_temp" | awk '{print $1}')" != "${unifi_sha256sum}" ]]; then echo -e "$(date +%F-%T.%6N) | The file downloaded via ${unifi_download_url} did not have sha256sum \"${unifi_sha256sum}\"..." &>> "${eus_dir}/logs/unifi-download.log"; continue; fi
        else
          if command -v dpkg-deb &> /dev/null; then if ! dpkg-deb --info "${unifi_temp}" &> /dev/null; then echo -e "$(date +%F-%T.%6N) | The file downloaded via ${unifi_download_url} was not a debian file format..." &>> "${eus_dir}/logs/unifi-download.log"; continue; fi; fi
        fi
        echo -e "${GREEN}#${RESET} Successfully downloaded application version ${unifi_clean}! \\n"; unifi_downloaded="true"; break
      elif [[ "${unifi_download_url}" =~ ^https:// ]]; then
        echo -e "$(date +%F-%T.%6N) | Downloading ${unifi_download_url/https:/http:} to ${unifi_temp}" &>> "${eus_dir}/logs/unifi-download.log"
        if curl "${nos_curl_argument[@]}" --output "${unifi_temp}" "${unifi_download_url/https:/http:}" &>> "${eus_dir}/logs/unifi-download.log"; then
          if command -v sha256sum &> /dev/null && [[ -n "${unifi_sha256sum}" ]]; then
            if [[ "$(sha256sum "$unifi_temp" | awk '{print $1}')" != "${unifi_sha256sum}" ]]; then echo -e "$(date +%F-%T.%6N) | The file downloaded via ${unifi_download_url} did not have sha256sum \"${unifi_sha256sum}\"..." &>> "${eus_dir}/logs/unifi-download.log"; continue; fi
          else
            if command -v dpkg-deb &> /dev/null; then if ! dpkg-deb --info "${unifi_temp}" &> /dev/null; then echo -e "$(date +%F-%T.%6N) | The file downloaded via ${unifi_download_url/https:/http:} was not a debian file format..." &>> "${eus_dir}/logs/unifi-download.log"; continue; fi; fi
          fi
          echo -e "${GREEN}#${RESET} Successfully downloaded application version ${unifi_clean} (using HTTP)! \\n"; unifi_downloaded="true"; break
        fi
      fi
    done
    if [[ "${unifi_downloaded}" != "true" ]]; then abort_reason="Failed to download application version ${unifi_clean}."; abort; fi
  else
    echo -e "${GRAY_R}#${RESET} Downloading the UniFi Network Application..."
    echo -e "${GREEN}#${RESET} UniFi Network Application version ${unifi_clean} has already been downloaded! \\n"
  fi
  unifi_deb_package_modification
  unifi_version="${unifi_clean}"
  ignore_unifi_package_dependencies
  check_service_overrides
  network_install_required_packages_check
  system_properties_check
  unifi_folder_permission_check
  echo -e "${GRAY_R}#${RESET} Installing the UniFi Network Application..."
  echo -e "\\n------- $(date +%F-%T.%6N) -------\\n" &>> "${eus_dir}/logs/unifi-install.log"
  echo "unifi unifi/has_backup boolean true" 2> /dev/null | debconf-set-selections
  check_dpkg_lock
  # shellcheck disable=SC2086
  if DEBIAN_FRONTEND=noninteractive "$(which dpkg)" -i ${dpkg_ignore_depends_flag} "${unifi_temp}" &>> "${eus_dir}/logs/unifi-install.log"; then
    echo -e "${GREEN}#${RESET} Successfully installed the UniFi Network Application! \\n"
    if [[ "${unifi_ports_in_use}" == 'true' ]]; then change_default_unifi_ports; fi
  else
    abort_reason="Failed to install the UniFi Network Application."
    abort
  fi
  if journalctl -u unifi 2> /dev/null | grep -qiE "unifi-network-service-helper.*(rm: cannot remove|mv: cannot move)"; then /usr/sbin/unifi-network-service-helper create-dirs &>> "${eus_dir}/logs/unifi-missing-directories.log"; fi
  system_properties_free_memory_check
  unifi_autobackup_dir_check
  unifi_folder_permission_check
  if ! [[ -d "/var/run/unifi" ]]; then install -o unifi -g unifi -m 750 -d /var/run/unifi &>> "${eus_dir}/logs/unifi-var-run-missing.log"; fi
  if ! [[ -d "$(readlink -f /usr/lib/unifi/logs)" ]]; then install -o unifi -g unifi -m 750 -d "$(readlink -f /usr/lib/unifi/logs)" &>> "${eus_dir}/logs/unifi-logs-dir-missing.log"; fi
  if [[ "$(dpkg-query --showformat='${version}' --show jq 2> /dev/null | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
    jq '."scripts"."'"${script_name}"'" += {"install-date": "'"$(date +%s)"'"}' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
  else
    jq --arg script_name "$script_name" --arg install_date "$(date +%s)" '.scripts[$script_name] += {"install-date": $install_date}' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
  fi
  eus_database_move
  rm --force "${unifi_temp}" 2> /dev/null
  if ! systemctl is-active --quiet unifi && [[ "${limited_functionality}" != 'true' ]]; then unifi_service_not_running="true"; elif [[ "$(pgrep -f "/usr/lib/unifi" | grep -cv grep)" -lt "2" ]]; then unifi_service_not_running="true"; fi
  if [[ "${unifi_service_not_running}" == 'true' ]]; then
    if [[ "${limited_functionality}" == 'true' ]]; then
      service unifi stop &>> "${eus_dir}/logs/post-unifi-install-stop.log"
    else
      systemctl stop unifi &>> "${eus_dir}/logs/post-unifi-install-stop.log"
    fi
    echo -e "${GRAY_R}#${RESET} Starting the UniFi Network Application..."
    old_systemd_version_check
    if [[ "${limited_functionality}" == 'true' ]]; then
      if [[ "${old_systemd_version}" == 'true' ]]; then if [[ "${old_systemd_version_check_unifi_restart}" == 'true' ]]; then echo -e "${GREEN}#${RESET} Successfully started the UniFi Network Application! \\n"; else abort_reason="Failed to start the Network Application."; abort; fi; elif ! service unifi start &>> "${eus_dir}/logs/post-unifi-install-start.log"; then abort_reason="Failed to start the Network Application."; abort; else echo -e "${GREEN}#${RESET} Successfully started the UniFi Network Application! \\n"; fi
    else
      if [[ "${old_systemd_version}" == 'true' ]]; then if [[ "${old_systemd_version_check_unifi_restart}" == 'true' ]]; then echo -e "${GREEN}#${RESET} Successfully started the UniFi Network Application! \\n"; else abort_reason="Failed to start the Network Application."; abort; fi; elif ! systemctl start unifi &>> "${eus_dir}/logs/post-unifi-install-start.log"; then abort_reason="Failed to start the Network Application."; abort; else echo -e "${GREEN}#${RESET} Successfully started the UniFi Network Application! \\n"; fi
    fi
  fi
  sleep 3
  # Check if service is enabled
  if ! [[ "${os_codename}" =~ (precise|maya|trusty|utopic|vivid|wily|yakkety|zesty|artful|qiana|rebecca|rafaela|rosa|utopic|vivid|wily|yakkety|zesty|artful) && "${limited_functionality}" != 'true' ]]; then
    if systemctl list-units --full -all | grep -Fioq "unifi.service"; then
      SERVICE_UNIFI=$(systemctl is-enabled unifi)
      if [[ "$SERVICE_UNIFI" = 'disabled' ]]; then
        if ! systemctl enable unifi 2>/dev/null; then
          echo -e "${RED}#${RESET} Failed to enable service | UniFi"
          sleep 3
        fi
      fi
    fi
  fi
}

network_install_repository_unsupported_check() {
  # Check if UniFi Repo is supported.
  if [[ "${architecture}" == "arm64" && "${first_digit_unifi}" -ge "8" && "${glennr_compiled_mongod}" != 'true' ]]; then
    unifi_repo_supported="true"
  elif [[ "${architecture}" == "amd64" ]]; then
    unifi_repo_supported="true"
  else
    unifi_repo_supported="false"
  fi
}

network_install_repository_check() {
  if [[ "${script_option_skip}" != 'true' || "${script_option_add_repository}" == 'true' ]] && [[ "${unifi_repo_supported}" == "true" ]]; then
    if [[ "${script_option_skip}" != 'true' ]]; then
      header
      echo -e "${GRAY_R}#${RESET} Would you like to update the UniFi Network Application via APT?"
      read -rp $'\033[39m#\033[0m Do you want the script to add the source list file? (y/N) ' yes_no
    else
      if [[ "${script_option_add_repository}" == 'true' ]]; then yes_no="y"; fi
    fi
    case "$yes_no" in
        [Yy]*)
          header
          echo -e "${GRAY_R}#${RESET} Adding the UniFi Network Application repository for branch ${first_digit_unifi}.${second_digit_unifi}... \\n"
          sleep 3
          # Handle .list files in Traditional format
          while read -r list_file; do
            sed -Ei "s|^#*(unifi)|#\1|g" "${list_file}"
          done < <(find /etc/apt/ -type f -name "*.list")
          # Handle .sources files if using DEB822 format
          while read -r sources_file; do
            entry_block_start_line="$(awk '!/^#/ && /Types:/ { types_line=NR } /'"unifi"'/ && !/^#/ && !seen[types_line]++ { print types_line }' "${sources_file}" | head -n1)"
            entry_block_end_line="$(awk -v start_line="$entry_block_start_line" 'NR > start_line && NF == 0 { print NR-1; exit } END { if (NR > start_line && NF > 0) print NR }' "${sources_file}")"
            sed -i "${entry_block_start_line},${entry_block_end_line}s/^\([^#]\)/# \1/" "${sources_file}" &>/dev/null
          done < <(find /etc/apt/sources.list.d/ -type f -name "*.sources")
          rm --force /etc/apt/sources.list.d/100-ubnt-unifi.* 2> /dev/null
          echo -e "${GRAY_R}#${RESET} Downloading the UniFi Network Application repository key..."
          if curl "${curl_argument[@]}" -fSL "https://dl.ui.com/unifi/unifi-repo.gpg" | gpg -o "/etc/apt/keyrings/unifi-repo.gpg" --dearmor --yes &> /dev/null; then
            unifi_curl_exit_status="${PIPESTATUS[0]}"
            unifi_gpg_exit_status="${PIPESTATUS[2]}"
            if [[ "${unifi_curl_exit_status}" -eq "0" && "${unifi_gpg_exit_status}" -eq "0" && -s "/etc/apt/keyrings/unifi-repo.gpg" ]]; then
              signed_by_value_unifi="/etc/apt/keyrings/unifi-repo.gpg"
              echo -e "${GREEN}#${RESET} Successfully downloaded the key for the UniFi Network Application repository! \\n"
              echo -e "${GRAY_R}#${RESET} Adding the UniFi Network Application repository..."
              if [[ "${architecture}" == 'arm64' ]]; then arch="arch=arm64"; elif [[ "${architecture}" == 'amd64' ]]; then arch="arch=amd64"; else arch="arch=amd64,arm64"; fi
              if [[ "${use_deb822_format}" == 'true' ]]; then
                # DEB822 format
                unifi_repo_entry="Types: deb\nURIs: ${http_or_https}://www.ui.com/downloads/unifi/debian\nSuites: unifi-${first_digit_unifi}.${second_digit_unifi}\nComponents: ubiquiti\nSigned-By: ${signed_by_value_unifi}\nArchitectures: ${arch//arch=/}"
              else
                # Traditional format
                unifi_repo_entry="deb [ ${arch} signed-by=${signed_by_value_unifi} ] ${http_or_https}://www.ui.com/downloads/unifi/debian unifi-${first_digit_unifi}.${second_digit_unifi} ubiquiti"
              fi
              if echo -e "${unifi_repo_entry}" &> "/etc/apt/sources.list.d/100-ubnt-unifi.${source_file_format}"; then
                echo -e "${GREEN}#${RESET} Successfully added UniFi Network Application source list! \\n"
                run_apt_get_update_with_sha1_fallback
                echo -ne "\\r${GRAY_R}#${RESET} Checking if the added UniFi Network Application repository is valid..." && sleep 1
                if grep -sioq "unifi-${first_digit_unifi}.${second_digit_unifi} Release' does not" /tmp/EUS/apt/apt-update.log; then
                  echo -ne "\\r${RED}#${RESET} The added UniFi Repository is not valid/used, the repository list will be removed! \\n"
                  rm -f "/etc/apt/sources.list.d/100-ubnt-unifi.${source_file_format}" &> /dev/null
                else
                  echo -ne "\\r${GREEN}#${RESET} The added UniFi Network Application Repository is valid! \\n"
                fi
                sleep 3
              else
                echo -e "${RED}#${RESET} Failed to add the UniFi Network Application source list...\\n"
              fi
            else
              echo -e "${RED}#${RESET} Failed to add the UniFi Network Application source list...\\n"
            fi
          else
            echo -e "${RED}#${RESET} Failed to download the key for the UniFi Network Application repository...\\n"
          fi;;
        *) ;;
    esac
    unset yes_no
  fi
}

ufw_ports_check() {
  local app_type="$1"
  if [[ "${app_type}" == "net" ]]; then
    app_type_pretty="UniFi Network Application"
  elif [[ "${app_type}" == "uosserver" ]]; then
    app_type_pretty="UniFi OS Server"
  else
    app_type_pretty="Unknown"
  fi
  if ! dpkg -l ufw 2>/dev/null | grep -q "^ii\|^hi"; then return 1; fi
  # Build port list depending on app type
  case "${app_type}" in
    net)
      if grep -sioq "^unifi.https.port" "/usr/lib/unifi/data/system.properties"; then dmport="$(awk '/^unifi.https.port/' /usr/lib/unifi/data/system.properties | cut -d'=' -f2)"; else dmport="8443"; fi
      if grep -sioq "^unifi.http.port" "/usr/lib/unifi/data/system.properties"; then diport="$(awk '/^unifi.http.port/' /usr/lib/unifi/data/system.properties | cut -d'=' -f2)"; else diport="8080"; fi
      if grep -sioq "^unifi.stun.port" "/usr/lib/unifi/data/system.properties"; then stport="$(awk '/^unifi.stun.port/' /usr/lib/unifi/data/system.properties | cut -d'=' -f2)"; else stport="6789"; fi
      if grep -sioq "^portal.https.port" "/usr/lib/unifi/data/system.properties"; then hpsport="$(awk '/^portal.https.port/' /usr/lib/unifi/data/system.properties | cut -d'=' -f2)"; else hpsport="8843"; fi
      if grep -sioq "^portal.http.port" "/usr/lib/unifi/data/system.properties"; then hphport="$(awk '/^portal.http.port/' /usr/lib/unifi/data/system.properties | cut -d'=' -f2)"; else hphport="8880"; fi
      base_ports=(
        "3478/udp"
        "${diport}/tcp"
        "${dmport}/tcp"
        "${hphport}/tcp"
        "${hpsport}/tcp"
        "${stport}/tcp"
      );;
    uosserver)
      base_ports=(
        "${uos_server_web_port}/tcp"
        "${uos_server_mobile_speedtest_port}/tcp"
        "${uos_server_device_inform_port}/tcp"
        "${uos_server_remote_logger_port}/tcp"
        "${uos_server_rabbitmq_port}/tcp"
        "${uos_server_stun_port}/udp"
      );;
    *)
      echo -e "${RED}#${RESET} Unknown application type: ${app_type}"
      return 1;;
  esac
  # If ufw is active, validate ports
  if ufw status verbose | awk '/^Status:/{print $2}' | grep -xq "active"; then
    if [[ "${app_type}" == "net" ]]; then
      # Ask if discovery port should be included
      if [[ "${script_option_skip}" != 'true' && "${script_option_local_install}" != 'true' ]]; then
        while true; do
          read -rp $'\033[39m#\033[0m Is/will your application only be used locally (regarding device discovery)? (Y/n) ' yes_no
          case "${yes_no}" in
            [Yy]*|"")
              echo -e "${GRAY_R}#${RESET} Adding device discovery port 10001/udp.\\n"
              base_ports+=("10001/udp")
              break;;
            [Nn]*) echo ""; break ;;
            *) echo -e "\\n${RED}#${RESET} Invalid input, please answer Yes or No (y/n)...\\n";;
          esac
        done
      elif [[ "${script_option_local_install}" == 'true' ]]; then
        base_ports+=("10001/udp")
      fi
    fi
    if [[ "${script_option_skip}" != 'true' ]]; then
      while true; do
        read -rp $'\033[39m#\033[0m Do you want the script to add the required ports to UFW for '"${app_type_pretty}"'? (Y/n) ' yes_no
        case "${yes_no}" in
          [Yy]*|"")
            echo -e "${GREEN}#${RESET} OK, Checking required ports for ${app_type_pretty}! \\n"
            if [[ "${ufw_append_ssh_port}" != 'true' ]]; then
              while true; do
                read -rp $'\033[39m#\033[0m Do you want the script to add the SSH port to the Firewall Allow List? (Y/n) ' yes_no
                case "${yes_no}" in
                  [Yy]*|"")
                    echo -e "${GREEN}#${RESET} OK, Appending the SSH port to the ports list!"
                    ufw_append_ssh_port="true"
                    break;;
                  [Nn]*)
                    echo -e "${GREEN}#${RESET} OK, the script won't add the SSH port to the Firewall Allow List..."
                    break;;
                  *) echo -e "\n${RED}#${RESET} Invalid input, please answer Yes or No (y/n)... \\n";;
                esac
              done
            fi
            break;;
          [Nn]*)
            echo -e "${GREEN}#${RESET} OK, the script won't touch your UFW configuration... \\n"
            return 1;;
          *) echo -e "\n${RED}#${RESET} Invalid input, please answer Yes or No (y/n)... \\n";;
        esac
      done
    else
      echo -e "${GRAY_R}#${RESET} Checking if the required ports for ${app_type_pretty} are allowed in the Firewall (UFW)..."
    fi
    # Append ssh port too
    ssh_port="$(awk '/^Port/{print $2}' /etc/ssh/sshd_config | head -n1)"
    ssh_port="${ssh_port:-22}"
    all_ports=("${base_ports[@]}")
    if [[ "${ufw_append_ssh_port}" == "true" ]]; then
      all_ports+=("${ssh_port}/tcp")
    fi
    ufw_list="$(ufw status verbose)"
    missing_ports=()
    for port in "${all_ports[@]}"; do
      port_number_only="${port%%/*}"  # strip protocol if present
      if ! grep -v "(v6)" <<<"${ufw_list}" | grep -Eq "^${port_number_only}\b|^${port}\b.*ALLOW IN"; then
        missing_ports+=("$port")
      fi
    done
    # Apply missing rules if needed
    if ((${#missing_ports[@]})); then
      for port in "${missing_ports[@]}"; do
        if [[ "${ufw_ports_empty_message_printed}" != 'true' ]]; then echo -e ""; ufw_ports_empty_message_printed="true"; fi
        echo -e "${GRAY_R}#${RESET} Port ${port} is missing in the rule set, adding it..."
        if ufw allow "${port}" &>/dev/null; then
          echo -e "${GREEN}#${RESET} Successfully added port ${port} to the Firewall Allow Rules! \\n"
        else
          echo -e "${RED}#${RESET} Failed to add port ${port} to the Firewall Allow Rules... \\n"
        fi
      done
    else
      echo -e "${GREEN}#${RESET} All required ports already exist! \\n"
    fi
  fi
}

public_install_check() {
  local app_type="$1"
  if [[ "${app_type}" == "net" ]]; then
    app_type_pretty="UniFi Network Application"
    web_ui_port="${dmport}"
  elif [[ "${app_type}" == "uosserver" ]]; then
    app_type_pretty="UniFi OS Server"
    web_ui_port="${uos_server_web_port}"
  else
    app_type_pretty="Unknown"
  fi
  if [[ -z "${public_server_address}" ]]; then public_reachable="false"; return 0; fi
  # Check if application is reachable via public IP.
  if timeout 1 nc -zv "${public_server_address}" "${web_ui_port}" &> /dev/null; then public_reachable="true"; fi
  # Check if application is up and running + if it respond on public IP
  if [[ "${public_reachable}" == 'true' ]]; then
    check_count=0
    while [[ "${check_count}" -lt '60' ]]; do
      if [[ "${check_count}" == '3' ]]; then
        header
        echo -e "${GRAY_R}#${RESET} Checking if the ${app_type_pretty} is responding... (this can take up to 60 seconds)"
        unifi_api_message="true"
      fi
      if [[ "${app_type}" == "net" ]]; then get_unifi_application_status "${public_server_address}"; elif [[ "${app_type}" == "uosserver" ]]; then get_uos_server_status "${public_server_address}"; fi
      if [[ "${application_up}" == 'true' ]]; then
        if [[ "${unifi_api_message}" == 'true' ]]; then echo -e "${GREEN}#${RESET} The ${app_type_pretty} is up and running! \\n"; sleep 1; fi
        if [[ "${unifi_api_message}" == 'true' ]]; then echo -e "${GRAY_R}#${RESET} Checking if the ${app_type_pretty} is also responding on it's public IP address..."; fi
        if [[ "${app_type}" == "net" ]]; then get_unifi_application_status "${public_server_address}"; elif [[ "${app_type}" == "uosserver" ]]; then get_uos_server_status "${public_server_address}"; fi
        if [[ "${application_up}" == 'true' ]]; then
          if [[ "${unifi_api_message}" == 'true' ]]; then echo -e "${GREEN}#${RESET} The ${app_type_pretty} is responding on it's public IP address! The script will continue with the SSL setup!"; sleep 3; fi
          public_reachable="true"
        else
          if [[ "${unifi_api_message}" == 'true' ]]; then echo -e "${GREEN}#${RESET} The ${app_type_pretty} does not respond on it's public IP address... \\n"; sleep 3; fi
          public_reachable="false"
        fi
        break
      fi
      ((check_count=check_count+1))
      sleep 1
    done
  fi
  if [[ "${public_reachable}" == 'true' || "${run_easy_encrypt}" == 'true' ]] && [[ "${script_option_skip}" != 'true' || "${fqdn_specified}" == 'true' ]]; then
    echo -e "--install-script" &>> /tmp/EUS/le_script_options
    if [[ -f /tmp/EUS/le_script_options && -s /tmp/EUS/le_script_options ]]; then IFS=" " read -r le_script_options <<< "$(tr '\r\n' ' ' < /tmp/EUS/le_script_options)"; fi
    header
    le_script="true"
    echo -e "${GRAY_R}#${RESET} Your ${app_type_pretty} seems to be exposed to the internet."
    echo -e "${GRAY_R}#${RESET} It's recommend to secure your application with a SSL certficate.\\n"
    echo -e "${GRAY_R}#${RESET} Requirements:"
    echo -e "${GRAY_R}-${RESET} A domain name and A record pointing to the server that runs the ${app_type_pretty}."
    echo -e "${GRAY_R}-${RESET} Port 80 needs to be open ( port forwarded )\\n\\n"
    while true; do
      if [[ "${script_option_skip}" != 'true' ]]; then read -rp $'\033[39m#\033[0m Do you want to download and execute my UniFi Easy Encrypt Script? (Y/n) ' yes_no; fi
      case "$yes_no" in
          [Yy]*|"")
              rm --force unifi-easy-encrypt.sh &> /dev/null
              # shellcheck disable=SC2068
              curl "${curl_argument[@]}" --remote-name https://get.glennr.nl/unifi/extra/unifi-easy-encrypt.sh && bash unifi-easy-encrypt.sh ${le_script_options[@]}
              break;;
          [Nn]*)
              break;;
          *)
             echo -e "\\n${RED}#${RESET} Invalid input, please answer Yes or No (y/n)...\\n"
             sleep 3;;
      esac
    done
  fi
}

netcat_uninstall_check() {
  if [[ "${netcat_installed}" == 'true' ]]; then
    header
    check_dpkg_lock
    echo -e "${GRAY_R}#${RESET} The script installed ${netcat_installed_package_name}, we do not need this anymore.\\n"
    echo -e "${GRAY_R}#${RESET} Purging package ${netcat_installed_package_name}..."
    if "${EUS_APT_ENV[@]}" env DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' purge "${netcat_installed_package_name}" &>> "${eus_dir}/logs/uninstall-${netcat_installed_package_name}.log"; then
      echo -e "${GREEN}#${RESET} Successfully purged ${netcat_installed_package_name}! \\n"
    else
      echo -e "${RED}#${RESET} Failed to purge ${netcat_installed_package_name}... \\n"
    fi
    sleep 2
  fi
}

network_install_installation_check() {
  if "$(which dpkg)" -l | grep "unifi " | grep -q "^ii\\|^hi"; then
    if grep -sioq "^unifi.https.port" "/usr/lib/unifi/data/system.properties"; then dmport="$(awk '/^unifi.https.port/' /usr/lib/unifi/data/system.properties | cut -d'=' -f2)"; else dmport="8443"; fi
    header
    echo -e "${GREEN}#${RESET} UniFi Network Application ${unifi_clean} has been installed successfully"
    if [[ "${public_reachable}" = 'true' ]]; then
     echo -e "${GREEN}#${RESET} Your application address: ${GRAY_R}https://${public_server_address}:${dmport}${RESET}"
      if [[ "${le_script}" == 'true' ]]; then
        if [[ -d /usr/lib/EUS/ ]]; then
          if [[ -f /usr/lib/EUS/server_fqdn_install && -s /usr/lib/EUS/server_fqdn_install ]]; then
            application_fqdn_le="$(tail -n1 /usr/lib/EUS/server_fqdn_install)"
            rm --force /usr/lib/EUS/server_fqdn_install &> /dev/null
          fi
        elif [[ -d /srv/EUS/ ]]; then
          if [[ -f /srv/EUS/server_fqdn_install && -s /srv/EUS/server_fqdn_install ]]; then
            application_fqdn_le="$(tail -n1 /srv/EUS/server_fqdn_install)"
            rm --force /srv/EUS/server_fqdn_install &> /dev/null
          fi
        fi
        if [[ -n "${application_fqdn_le}" ]]; then
          echo -e "${GREEN}#${RESET} Your application FQDN: ${GRAY_R}https://${application_fqdn_le}:${dmport}${RESET}"
        fi
      fi
    else
      echo -e "${GREEN}#${RESET} Your application address: ${GRAY_R}https://${server_ip_address}:${dmport}${RESET}"
    fi
    echo -e "\\n"
    if [[ "${limited_functionality}" == 'true' ]]; then
      if [[ "$(pgrep -f "/usr/lib/unifi" | grep -cv grep)" -ge "2" ]]; then echo -e "${GREEN}#${RESET} UniFi is active ( running )"; else echo -e "${RED}#${RESET} UniFi failed to start... Please contact Glenn R. (AmazedMender16) on the Community Forums!"; fi
    else
      if [[ "${os_codename}" =~ (precise|maya|trusty|utopic|vivid|wily|yakkety|zesty|artful|qiana|rebecca|rafaela|rosa|utopic|vivid|wily|yakkety|zesty|artful) ]]; then
        if systemctl status unifi | grep -iq running; then echo -e "${GREEN}#${RESET} UniFi is active ( running )"; else echo -e "${RED}#${RESET} UniFi failed to start... Please contact Glenn R. (AmazedMender16) on the Community Forums!"; fi
      else
        if systemctl is-active -q unifi; then echo -e "${GREEN}#${RESET} UniFi is active ( running )"; else echo -e "${RED}#${RESET} UniFi failed to start... Please contact Glenn R. (AmazedMender16) on the Community Forums!"; fi
      fi
    fi
    if [[ -s "/tmp/EUS/ports/new-ports" ]]; then
      if [[ "$(wc -l "/tmp/EUS/ports/new-ports" | awk '{print $1}')" -ge "1" ]]; then
        if [[ "$(wc -l "/tmp/EUS/ports/new-ports" | awk '{print $1}')" == "1" ]]; then
          echo -e "\\n\\n${YELLOW}#${RESET} We had to change one of the default UniFi Network Application ports, the port change is listed below."
        else
          echo -e "\\n\\n${YELLOW}#${RESET} We had to change a couple of the default UniFi Network Application ports, the port changes are listed below."
        fi
        while read -r line; do
          echo -e "${YELLOW}-${RESET} The $(echo "${line}" | cut -d'/' -f3) port was changed from $(echo "${line}" | cut -d'/' -f1) was changed to $(echo "${line}" | cut -d'/' -f2)..."
        done < "/tmp/EUS/ports/new-ports"
      fi
    fi
    echo -e "\\n"
    author
    remove_yourself
  else
    header_red
    echo -e "\\n${RED}#${RESET} Failed to successfully install UniFi Network Application ${unifi_clean}"
    echo -e "${RED}#${RESET} Please contact Glenn R. (AmazedMender16) on the Community Forums!${RESET}\\n\\n"
    remove_yourself
  fi
}

uos_server_install_installation_check() {
  header
  echo -e "${GREEN}#${RESET} UniFi OS Server ${uos_version} has been installed successfully"
  if [[ "${public_reachable}" = 'true' ]]; then
   echo -e "${GREEN}#${RESET} Your application address: ${GRAY_R}https://${public_server_address}:${uos_server_web_port}${RESET}"
    if [[ "${le_script}" == 'true' ]]; then
      if [[ -d /usr/lib/EUS/ ]]; then
        if [[ -f /usr/lib/EUS/server_fqdn_install && -s /usr/lib/EUS/server_fqdn_install ]]; then
          application_fqdn_le="$(tail -n1 /usr/lib/EUS/server_fqdn_install)"
          rm --force /usr/lib/EUS/server_fqdn_install &> /dev/null
        fi
      elif [[ -d /srv/EUS/ ]]; then
        if [[ -f /srv/EUS/server_fqdn_install && -s /srv/EUS/server_fqdn_install ]]; then
          application_fqdn_le="$(tail -n1 /srv/EUS/server_fqdn_install)"
          rm --force /srv/EUS/server_fqdn_install &> /dev/null
        fi
      fi
      if [[ -n "${application_fqdn_le}" ]]; then
        echo -e "${GREEN}#${RESET} Your application FQDN: ${GRAY_R}https://${application_fqdn_le}:${uos_server_web_port}${RESET}"
      fi
    fi
  else
    echo -e "${GREEN}#${RESET} Your application address: ${GRAY_R}https://$server_ip_address:${uos_server_web_port}${RESET}"
  fi
  echo -e "\\n"
  if systemctl is-active -q uosserver; then echo -e "${GREEN}#${RESET} UniFi OS Server is active ( running )"; else echo -e "${RED}#${RESET} UniFi OS Server failed to start... Please contact Glenn R. (AmazedMender16) on the Community Forums!"; fi
  echo -e "\\n"
  author
  remove_yourself
}

uos_server_logind_dbus_check() {
  if ! systemctl is-active --quiet dbus; then
    state="$(systemctl is-enabled dbus 2>/dev/null)"
    echo -e "$(date +%F-%T.%6N) | dbus not running (state: ${state}). Attempting recovery..." &>> "${eus_dir}/logs/uos-server-logind-dbus-check.log"
    if [[ "${state}" == "masked" ]]; then
      echo -e "$(date +%F-%T.%6N) | dbus is masked. Attempting to unmask..." &>> "${eus_dir}/logs/uos-server-logind-dbus-check.log"
      if systemctl unmask dbus &>> "${eus_dir}/logs/uos-server-logind-dbus-check.log"; then
        echo -e "$(date +%F-%T.%6N) | Successfully unmasked dbus!" &>> "${eus_dir}/logs/uos-server-logind-dbus-check.log"
      else
        echo -e "$(date +%F-%T.%6N) | Failed to unmask dbus..." &>> "${eus_dir}/logs/uos-server-logind-dbus-check.log"
      fi
    fi
    echo -e "$(date +%F-%T.%6N) | Attempting to enable dbus..." &>> "${eus_dir}/logs/uos-server-logind-dbus-check.log"
    if systemctl enable --now dbus &>> "${eus_dir}/logs/uos-server-logind-dbus-check.log"; then
      echo -e "$(date +%F-%T.%6N) | Successfully enabled dbus!" &>> "${eus_dir}/logs/uos-server-logind-dbus-check.log"
    else
      echo -e "$(date +%F-%T.%6N) | Failed to enable dbus..." &>> "${eus_dir}/logs/uos-server-logind-dbus-check.log"
    fi
    echo -e "$(date +%F-%T.%6N) | Attempting to restart dbus..." &>> "${eus_dir}/logs/uos-server-logind-dbus-check.log"
    if systemctl restart dbus &>> "${eus_dir}/logs/uos-server-logind-dbus-check.log"; then
      echo -e "$(date +%F-%T.%6N) | Successfully restarted dbus!" &>> "${eus_dir}/logs/uos-server-logind-dbus-check.log"
    else
      echo -e "$(date +%F-%T.%6N) | Failed to restart dbus..." &>> "${eus_dir}/logs/uos-server-logind-dbus-check.log"
    fi
    sleep 1
  fi
  if ! systemctl is-active --quiet systemd-logind; then
    state="$(systemctl is-enabled systemd-logind 2>/dev/null)"
    if [[ "${state}" == "masked" ]]; then
      echo -e "$(date +%F-%T.%6N) | systemd-logind is masked. Attempting to unmask..." &>> "${eus_dir}/logs/uos-server-logind-dbus-check.log"
      if systemctl unmask systemd-logind &>> "${eus_dir}/logs/uos-server-logind-dbus-check.log"; then
        echo -e "$(date +%F-%T.%6N) | Successfully unmasked systemd-logind!" &>> "${eus_dir}/logs/uos-server-logind-dbus-check.log"
      else
        echo -e "$(date +%F-%T.%6N) | Failed to unmask systemd-logind..." &>> "${eus_dir}/logs/uos-server-logind-dbus-check.log"
      fi
    fi
    echo -e "$(date +%F-%T.%6N) | Attempting to enable systemd-logind..." &>> "${eus_dir}/logs/uos-server-logind-dbus-check.log"
    if systemctl enable --now systemd-logind &>> "${eus_dir}/logs/uos-server-logind-dbus-check.log"; then
      echo -e "$(date +%F-%T.%6N) | Successfully enabled systemd-logind!" &>> "${eus_dir}/logs/uos-server-logind-dbus-check.log"
    else
      echo -e "$(date +%F-%T.%6N) | Failed to enable systemd-logind..." &>> "${eus_dir}/logs/uos-server-logind-dbus-check.log"
    fi
    echo -e "$(date +%F-%T.%6N) | Attempting to restart systemd-logind..." &>> "${eus_dir}/logs/uos-server-logind-dbus-check.log"
    if systemctl restart systemd-logind &>> "${eus_dir}/logs/uos-server-logind-dbus-check.log"; then
      echo -e "$(date +%F-%T.%6N) | Successfully restarted systemd-logind!" &>> "${eus_dir}/logs/uos-server-logind-dbus-check.log"
    else
      echo -e "$(date +%F-%T.%6N) | Failed to restart systemd-logind..." &>> "${eus_dir}/logs/uos-server-logind-dbus-check.log"
    fi
    sleep 1
  fi
  echo -e "$(date +%F-%T.%6N) | Checking login1 ping..." &>> "${eus_dir}/logs/uos-server-logind-dbus-check.log"
  if busctl --system call org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.DBus.Peer Ping >/dev/null 2>&1; then
    echo -e "$(date +%F-%T.%6N) | login1 responded to Ping" &>> "${eus_dir}/logs/uos-server-logind-dbus-check.log"
  else
    echo -e "$(date +%F-%T.%6N) | login1 not responding, restarting dbus + systemd-logind..." &>> "${eus_dir}/logs/uos-server-logind-dbus-check.log"
    systemctl restart dbus systemd-logind
    sleep 1
    if busctl --system call org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.DBus.Peer Ping >/dev/null 2>&1; then
      echo -e "$(date +%F-%T.%6N) | login1 responsive after restart" &>> "${eus_dir}/logs/uos-server-logind-dbus-check.log"
    else
      echo -e "$(date +%F-%T.%6N) | login1 still not responsive after restart" &>> "${eus_dir}/logs/uos-server-logind-dbus-check.log"
    fi
  fi
}

uos_server_user_group_check() {
  if id -u "uosserver" >/dev/null 2>&1 || getent group "uosserver" >/dev/null 2>&1; then
    if [[ ! -f "/var/lib/uosserver/server.conf" ]]; then
      echo -e "$(date +%F-%T.%6N) | User or group 'uosserver' exists but '/var/lib/uosserver/server.conf' does not..." &>> "${eus_dir}/logs/uos-server-user-group-check.log"
      if [[ "${script_option_skip}" != 'true' ]]; then
        while true; do
          header
          echo -e "${WHITE_R}#${RESET} The uosserver user/group is already present on the system, most likely from a broken installation..."
          echo -e "${WHITE_R}#${RESET} Removing the user/group may cause data loss if this is an existing install \\n"
          read -rp $'\033[39m#\033[0m Do you want to remove the "uosserver" user/group? (y/N) ' confirm
          case "$confirm" in
            [Yy]*)
              echo ""
              break;;
            [Nn]*|"")
              echo -e "$(date +%F-%T.%6N) | Removal canceled by user..." &>> "${eus_dir}/logs/uos-server-user-group-check.log"
              return 0;;
            *)
              echo -e "\\n${RED}#${RESET} Invalid input, please answer Yes or No (y/n)...\\n"
              sleep 3;;
          esac
        done
      fi
      if id -u "uosserver" >/dev/null 2>&1; then
        echo -e "${WHITE_R}#${RESET} Removing user 'uosserver'..."
        echo -e "$(date +%F-%T.%6N) | Removing user 'uosserver'..." &>> "${eus_dir}/logs/uos-server-user-group-check.log"
        if userdel -r "uosserver" &>> "${eus_dir}/logs/uos-server-user-group-check.log"; then
          echo -e "${GREEN}#${RESET} Successfully removed user 'uosserver'...  \\n"
          echo -e "$(date +%F-%T.%6N) | Successfully removed user 'uosserver'!" &>> "${eus_dir}/logs/uos-server-user-group-check.log"
        else
          echo -e "${RED}#${RESET} Failed to remove user 'uosserver'...  \\n"
          echo -e "$(date +%F-%T.%6N) | Failed to remove user 'uosserver'..." &>> "${eus_dir}/logs/uos-server-user-group-check.log"
        fi
      fi
      if getent group "uosserver" >/dev/null 2>&1; then
        echo -e "${WHITE_R}#${RESET} Removing group 'uosserver'..."
        echo -e "$(date +%F-%T.%6N) | Removing group 'uosserver'..." &>> "${eus_dir}/logs/uos-server-user-group-check.log"
        if groupdel "uosserver" &>> "${eus_dir}/logs/uos-server-user-group-check.log"; then
          echo -e "${GREEN}#${RESET} Successfully removed group 'uosserver'! \\n"
          echo -e "$(date +%F-%T.%6N) | Successfully removed group 'uosserver'!" &>> "${eus_dir}/logs/uos-server-user-group-check.log"
        else
          echo -e "${RED}#${RESET} Failed to remove group 'uosserver'...  \\n"
          echo -e "$(date +%F-%T.%6N) | Failed to remove group 'uosserver'..." &>> "${eus_dir}/logs/uos-server-user-group-check.log"
        fi
      fi
    fi
  fi
}

show_spinner() {
  local pid="${1}"
  local spinstr="|/-\\"
  local i="0"
  while ps -p "${pid}" > /dev/null 2>&1; do
    i=$(( (i + 1) % 4 ))
    printf "\r# [%c]" "${spinstr:$i:1}"
    sleep "0.1"
  done
  printf "\r\033[K"
}

uos_server_install_process() {
  tmp_dir_candidates=("/tmp" "/var/tmp")
  uos_server_tmp_dir=""
  for directory in "${tmp_dir_candidates[@]}"; do
    if [[ -d "${directory}" ]]; then
      uos_server_tmp_dir="${directory}"
      break
    fi
  done
  free_disk_space_check "${uos_server_tmp_dir}" "2"
  free_disk_space_check "/var/lib" "1"
  free_disk_space_check "/home" "18"
  if [[ -z "${uos_version}" ]]; then
    if [[ "$(command -v jq)" ]]; then latest_uos_release_api_status="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/uos-server-latest?status" 2> /dev/null | jq -r '.availability' 2> /dev/null)"; else latest_uos_release_api_status="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/uos-server-latest?status" 2> /dev/null | grep -oP '(?<="availability":")[^"]+')"; fi
    if [[ "${latest_uos_release_api_status}" == "OK" ]]; then
      if [[ -n "$(command -v jq)" ]]; then uos_version="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/latest-application-release?app=unifi-os-server&version=latest" 2> /dev/null | jq -r '.latest_release' 2> /dev/null)"; else uos_version="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/latest-application-release?app=unifi-os-server&version=latest" 2> /dev/null | sed -n 's/.*"latest_release":"\([^"]*\)".*/\1/p')"; fi
    else
      abort_function_skip_reason="true"
      abort_reason="Variable uos_version is empty."
      abort
    fi
  fi
  if [[ "${architecture}" == "amd64" ]]; then fwupdate_uos_server_platform="linux-x64"; elif [[ "${architecture}" == "arm64" ]]; then fwupdate_uos_server_platform="linux-arm64"; fi
  if [[ "$(curl "${curl_argument[@]}" https://api.glennr.nl/api/application-release?status 2> /dev/null | jq -r '.[]' 2> /dev/null)" == "OK" ]]; then
    fw_update_dl_link="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/application-release?app=uosserver&version=${uos_version}&architecture=${architecture}" | jq -r '."download_link"' | sed '/null/d' 2> "${eus_dir}/logs/locate-download.log")"
    fw_update_gr_dl_link="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/application-release?app=uosserver&version=${uos_version}&server=archive&architecture=${architecture}" | jq -r '."download_link"' | sed '/null/d' 2> "${eus_dir}/logs/locate-download.log")"
    fw_update_dl_link_sha256sum="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/application-release?app=uosserver&version=${uos_version}&architecture=${architecture}" | jq -r '.sha256sum' | sed '/null/d' 2> "${eus_dir}/logs/locate-download.log")"
  fi
  if [[ -z "${fw_update_dl_link}" ]]; then
    fw_update_dl_link="$(curl "${curl_argument[@]}" --location --request GET "https://fw-update.ui.com/api/firmware-latest?filter=eq~~version_major~~$(awk -F'.' '{print $1}' <<< "${uos_version}")&filter=eq~~version_minor~~$(awk -F'.' '{print $2}' <<< "${uos_version}")&filter=eq~~version_patch~~$(awk -F'.' '{print $3}' <<< "${uos_version}")&filter=eq~~platform~~${fwupdate_uos_server_platform}" 2> "${eus_dir}/logs/locate-download.log" | jq -r "._embedded.firmware[0]._links.data.href" 2> "${eus_dir}/logs/locate-download.log" | sed '/null/d' 2> "${eus_dir}/logs/locate-download.log")"
    fw_update_dl_link_sha256sum="$(curl "${curl_argument[@]}" --location --request GET "https://fw-update.ui.com/api/firmware-latest?filter=eq~~version_major~~$(awk -F'.' '{print $1}' <<< "${uos_version}")&filter=eq~~version_minor~~$(awk -F'.' '{print $2}' <<< "${uos_version}")&filter=eq~~version_patch~~$(awk -F'.' '{print $3}' <<< "${uos_version}")&filter=eq~~platform~~${fwupdate_uos_server_platform}" 2> "${eus_dir}/logs/locate-download.log" | jq -r "._embedded.firmware[0].sha256_checksum" 2> "${eus_dir}/logs/locate-download.log" | sed '/null/d' 2> "${eus_dir}/logs/locate-download.log")"
  fi
  fw_update_dl_links=()
  if [[ "$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/geo" 2> /dev/null | jq -r '."continent_code"' 2> /dev/null)" == "EU" ]]; then
    if [[ -n "${fw_update_gr_dl_link}" ]]; then fw_update_dl_links+=("${fw_update_gr_dl_link}"); fi
    if [[ -n "${fw_update_dl_link}" ]]; then fw_update_dl_links+=("${fw_update_dl_link}"); fi
  else
    if [[ -n "${fw_update_dl_link}" ]]; then fw_update_dl_links+=("${fw_update_dl_link}"); fi
    if [[ -n "${fw_update_gr_dl_link}" ]]; then fw_update_dl_links+=("${fw_update_gr_dl_link}"); fi
  fi
  if version_ge "${uos_version}" "5.0.5"; then
    uos_server_install_flags+=( "--force-install" )
  fi
  header
  for fw_update_dl_link in "${fw_update_dl_links[@]}"; do
    local retry_count="0"
    local max_retries="2"
    while (( retry_count < max_retries )); do
      ((retry_count++))
      eus_tmp_directory_check
      uos_server_file_temp_file="$(mktemp "uos-server-${uos_version}_XXXXX" --tmpdir="${eus_tmp_directory_location}")"
      echo -e "$(date +%F-%T.%6N) | Downloading ${fw_update_dl_link} to ${uos_server_file_temp_file}" &>> "${eus_dir}/logs/uos-server-download.log"
      if [[ "${uos_server_download_message_printed}" != 'true' ]]; then 
        echo -e "${GRAY_R}#${RESET} Downloading UniFi OS Server version ${uos_version}... "
        uos_server_download_message_printed="true"
      fi
      curl "${nos_curl_argument[@]}" --output "${uos_server_file_temp_file}" "${fw_update_dl_link}" &>> "${eus_dir}/logs/uos-server-download.log" &
      curl_pid="$!"
      show_spinner "${curl_pid}"
      wait "${curl_pid}"
      curl_exit_code="$?"
      if [[ "${curl_exit_code}" -eq "0" ]]; then
        if command -v sha256sum &> /dev/null; then
          if [[ "$(sha256sum "${uos_server_file_temp_file}" | awk '{print $1}')" != "${fw_update_dl_link_sha256sum}" ]]; then
            printf "\r%s#%s Checksum mismatch, retrying (%s/%s)...\n" "${YELLOW}" "${RESET}" "${retry_count}" "${max_retries}"
            continue
          fi
        fi
        printf "\r"
        echo -e "${GREEN}#${RESET} Successfully downloaded UniFi OS Server version ${uos_version}! \n"
        uos_server_downloaded="true"
        break 2
      else
        printf "\r%s#%s Download failed, trying next link...\n" "${RED}" "${RESET}"
        break
      fi
    done
    if (( retry_count == max_retries )); then
      printf "%s#%s Max retries reached, trying different download links...\n" "${RED}" "${RESET}"
    fi
  done
  if [[ "${uos_server_downloaded}" == 'true' ]]; then
    unset uos_server_downloaded
    echo -e "${GRAY_R}#${RESET} Installing UniFi OS Server version ${uos_version}..."
    check_dpkg_lock
    if ! chmod +x "${uos_server_file_temp_file}" &>> "${eus_dir}/logs/uos-server-install.log"; then
      abort_reason="Failed to change the permissions on ${uos_server_file_temp_file}."
      abort
    fi
    if "${uos_server_file_temp_file}" --non-interactive "${uos_server_install_flags[@]}" &>> "${eus_dir}/logs/uos-server-install.log"; then
      echo -e "${GREEN}#${RESET} Successfully installed UniFi OS Server version ${uos_version}! \n"
    else
      abort_reason="Failed to install UniFi OS Server ${uos_version}."
      abort
    fi
  else
    abort_reason="Failed to download UniFi OS Server version ${uos_version}."
    abort
  fi
}

support_check_api_payload() {
  check_lxc_setup
  check_docker_setup
  check_wsl_setup
  cpu_model="$(lscpu | awk -F: 'BEGIN{IGNORECASE=1} $1 ~ /^model name$/ {sub(/^[ \t]+/, "", $2); print $2; exit}')"
  if [[ -z "${cpu_model}" ]]; then cpu_model="$(lscpu | sed -n 's/^Model name:[[:space:]]*//Ip' | head -n1)"; fi
  cpu_cores="$(grep -ic '^processor' /proc/cpuinfo)"
  total_mem_mb="$(awk '/MemTotal/ {printf "%.0f\n", $2/1024}' /proc/meminfo)"
  swap_total_mb="$(awk '/SwapTotal/ {printf "%.0f\n", $2/1024}' /proc/meminfo)"
  kernel_version="$(uname -r)"
  server_uuid="$(jq -r '.database.uuid // empty' "${eus_dir}/db/db.json" 2>/dev/null)"
  script_version="$(grep -im1 "# Script Version" "${script_location}" | awk -F'|' '{gsub(/[[:space:]]/, "", $2); print $2}')"
  payload="$(jq -n \
    --arg server_uuid "${server_uuid}" \
    --arg server_os_name "${os_id}" \
    --arg server_os_codename "${os_codename}" \
    --arg server_architecture "${architecture}" \
    --arg server_kernel_version "${kernel_version}" \
    --arg server_cpu_model "${cpu_model}" \
    --argjson server_cpu_cores "${cpu_cores}" \
    --argjson server_total_memory "${total_mem_mb}" \
    --argjson server_total_swap "${swap_total_mb}" \
    --arg script_name "${script_name}" \
    --arg script_version "${script_version}" \
    --argjson lxc "${lxc_setup}" \
    --argjson docker "${docker_setup}" \
    --argjson wsl "${wsl_setup}" \
    --argjson limited_functionality "${limited_functionality:-false}" \
    '{
      server_uuid: $server_uuid,
      server_os_name: $server_os_name,
      server_os_codename: $server_os_codename,
      server_architecture: $server_architecture,
      server_kernel_version: $server_kernel_version,
      server_cpu_model: $server_cpu_model,
      server_cpu_cores: $server_cpu_cores,
      server_total_memory: $server_total_memory,
      server_total_swap: $server_total_swap,
      environment: {
        lxc: $lxc,
        docker: $docker,
        wsl: $wsl,
        limited_functionality: $limited_functionality
      },
      script_name: $script_name,
      script_version: $script_version
    }'
  )"
}

if [[ "$(command -v jq)" ]]; then support_check_status="$(curl "${curl_proxy_arg[@]}" --silent "https://api.glennr.nl/api/support-check?status" 2> /dev/null | jq -r '.status' 2> /dev/null)"; else support_check_status="$(curl "${curl_proxy_arg[@]}" --silent "https://api.glennr.nl/api/support-check?status" 2> /dev/null | grep -oP '(?<="status":")[^"]+')"; fi
if [[ "${support_check_status}" == "OK" ]]; then
  support_check_api_payload
  support_check_api_results="$(curl -sS -X POST "https://api.glennr.nl/api/support-check" -H "Content-Type: application/json" -d "${payload}")"
  unifi_os_server_supported="$(echo "${support_check_api_results}" | jq -r '.supported')"
  if [[ "${unifi_os_server_supported}" != 'true' ]]; then
    unifi_os_server_unsupported_reason="$(echo "${support_check_api_results}" | jq -r '.unsupported_reason')"
    choice="2"
    unifi_os_server_unsupported="true"
    header_red
    echo -e "${YELLOW}#${RESET} ${unifi_os_server_unsupported_reason} \\n\\n"
    echo -e "${YELLOW}#${RESET} Continuing with UniFi Network Application installation..."
    for i in {1..15}; do
      printf "\r${YELLOW}#${RESET} Switching in %2d seconds... [" "$((16-i))"
      for ((j=0; j<i; j++)); do printf "#"; done
      for ((j=i; j<15; j++)); do printf "."; done
      printf "]"
      sleep 1
    done
    header
  fi
else
  # UOS Server only supported on Ubuntu Noble/Debian Bookworm and newer.
  if [[ "${os_id}" == "ubuntu" ]]; then
    if ! [[ "${os_codename}" =~ (noble|oracular|plucky|questing|resolute) ]]; then
      choice="2"
      unifi_os_server_unsupported="true"
    fi
  elif [[ "${os_id}" == "debian" ]]; then
    if ! [[ "${os_codename}" =~ (bookworm|trixie|forky|unstable) ]]; then
      choice="2"
      unifi_os_server_unsupported="true"
    fi
  else
    choice="2"
    unifi_os_server_unsupported="true"
  fi
  # UOS Server not supported on anything other than arm64/amd64.
  if ! [[ "${architecture}" =~ (amd64|arm64) ]]; then
    choice="2"
    unifi_os_server_unsupported="true"
  fi
  if [[ "${limited_functionality}" == 'true' ]]; then
    choice="2"
    unifi_os_server_unsupported="true"
  fi
  # UOS Server not supported within LXC/Docker Container
  if [[ -n "$(command -v jq)" && -e "${eus_dir}/db/db.json" ]]; then
    check_lxc_setup
    check_docker_setup
    check_wsl_setup
    if [[ "$(jq -r '.database["lxc-container"]' "${eus_dir}/db/db.json" | sed '/null/d')" == 'true' ]]; then
      choice="2"
      unifi_os_server_unsupported="true"
    elif [[ "$(jq -r '.database["docker-container"]' "${eus_dir}/db/db.json" | sed '/null/d')" == 'true' ]]; then
      choice="2"
      unifi_os_server_unsupported="true"
    fi
  fi
fi

# Select choices based on script options
if [[ "${script_option_install_uos}" == 'true' && "${unifi_os_server_unsupported}" != 'true' ]]; then
  choice="1"
elif [[ "${script_option_install_net}" == 'true' && "${unifi_os_server_unsupported}" != 'true' ]]; then
  choice="2"
fi

while true; do
  if [[ "${unifi_os_server_unsupported}" != 'true' && "${script_option_skip}" != 'true' ]]; then
    header
    echo -e "Which software do you want to install? \\n"
    echo -e " [   ${GRAY_R}1${RESET}   ]  |  UniFi OS Server"
    echo -e " [   ${GRAY_R}2${RESET}   ]  |  UniFi Network Application \\n"
  fi
  if [[ "${script_option_skip}" != 'true' ]]; then if [[ -z "${choice}" ]]; then read -rp $'Your choice | \033[39m' choice; fi; fi
  case "$choice" in
    1|"")
      header
	  echo -e "${GRAY_R}#${RESET} Preparing to install the UniFi OS Server...\\n"
      sleep 3
      unifi_core_system_check
      uos_server_install_required_packages_check
      if is_systemd_unit_present "uosserver.service"; then already_installed_check "UniFi OS Server" "true"; fi
      uos_server_install_set_variables
      swap_file_check
      uos_server_install_ports_check
      uos_server_install_get_variables
      uos_server_logind_dbus_check
      uos_server_user_group_check
      uos_server_install_process
      ufw_ports_check uosserver
      public_install_check uosserver
      netcat_uninstall_check
      uos_server_install_installation_check
      break
      ;;
    2)
      if [[ "${unifi_os_server_unsupported}" != 'true' ]]; then
        header
	    echo -e "${GRAY_R}#${RESET} Preparing to install the UniFi Network Application...\\n"
        sleep 3
      fi
      unifi_core_system_check
      unifi_native_unsupported_check
      network_install_file_name_check
      network_install_broken_install_check
      network_install_broken_install_recovery
      network_install_dummy_packages_check
      already_installed_check "UniFi Network Application" 'dpkg -l' 'unifi |unifi-native'
      if is_systemd_unit_present "uosserver.service"; then already_installed_check "UniFi OS Server" "true"; fi
      network_install_required_packages_check
      check_mongodb_installed
      network_install_broken_override_check
      network_install_set_unifi_variables
      get_unifi_version
      update_eus_db_unifi_network_version
      network_install_gen1_cloudkey_check
      network_install_32_bit_check
      network_install_set_required_package_versions
      java_required_variables
      mongodb_avx_support_check
      network_install_mongodb_version_check
      swap_file_check
      network_install_ports_check
      system_update_check
      network_install_mongodb_install_process
      network_install_unsupported_database_version_change_override
      network_install_unsupported_database_version_change_recovery
      network_install_minimal_mongodb_version_check
      java_install_check
      java_cleanup_not_required_versions
      network_install_dependencies_check
      network_install_7_2_workaround_check
      network_install_installation_process
      network_install_repository_unsupported_check
      network_install_repository_check
      ufw_ports_check net
      public_install_check net
      netcat_uninstall_check
      network_install_installation_check
      break
      ;;
    *)
      header_red
      echo "Invalid choice."
      sleep 1
      ;;
  esac
done