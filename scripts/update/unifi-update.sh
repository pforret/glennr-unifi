#!/bin/bash

# UniFi Network Application Easy Update Script.
# Script   | UniFi Network Easy Update Script
# Version  | 10.3.5
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
  printf "\n\033[39m#\033[0m The script requires to be ran with bash, run the command printed below...\n"
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
  echo -e "${YELLOW}#${RESET} The script has limited functionality on \"$(ps -p 1 -o comm=)\" systems..."
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

get_unifi_version() {
  unifi="$("$(which dpkg)" -l | awk '$2 == "unifi" {print $3}' | sed 's/-.*//')"
  first_digit_unifi="$(echo "${unifi}" | cut -d'.' -f1)"
  second_digit_unifi="$(echo "${unifi}" | cut -d'.' -f2)"
  third_digit_unifi="$(echo "${unifi}" | cut -d'.' -f3)"
  unifi_release="$("$(which dpkg)" -l | awk '$2 == "unifi" {print $3}' | sed 's/-.*//' | sed 's/\.//g')"
}

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
  eus_directory_location="/tmp/EUS"
  eus_create_directories "mongodb-upgrade-${mongodb_upgrade_date}"
  while read -r target; do
    echo -e "\\nPermissions for target: ${target}" &>> "/tmp/EUS/mongodb-upgrade-${mongodb_upgrade_date}/${check_unifi_folder_permissions_state}-folder-permisisons"
    ls -lL "${target}" &>> "/tmp/EUS/mongodb-upgrade-${mongodb_upgrade_date}/${check_unifi_folder_permissions_state}-folder-permisisons"
    if [[ -d "${target}" ]]; then
      ls -l "${target}"/* &>> "/tmp/EUS/mongodb-upgrade-${mongodb_upgrade_date}/${check_unifi_folder_permissions_state}-folder-permisisons"
    fi
  done < <(find "/usr/lib/unifi" -maxdepth 1)
}

check_docker_setup() {
  if [[ -f /.dockerenv ]] || grep -sq '/docker/' /proc/1/cgroup || { command -v pgrep &>/dev/null && (pgrep -f "^dockerd" &>/dev/null || pgrep -f "^containerd" &>/dev/null); }; then docker_setup="true"; else docker_setup="false"; fi
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
  if grep -sqa "lxc" /proc/1/environ /proc/self/mountinfo /proc/1/environ; then lxc_setup="true"; else lxc_setup="false"; fi
  if [[ -n "$(command -v jq)" && -e "${eus_dir}/db/db.json" ]]; then
    if [[ "$(dpkg-query --showformat='${version}' --show jq 2> /dev/null | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
      jq '."database" += {"lxc-container": "'"${lxc_setup}"'"}' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
    else
      jq --arg lxc_setup "$lxc_setup" '.database = (.database + {"lxc-container": $lxc_setup})' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
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
  journalctl --since yesterday --no-pager &> "/tmp/EUS/support/journal.log"
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
  if [[ "$(command -v netstat)" ]]; then netstat -tulp &> "/tmp/EUS/support/netstat-results"; fi
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
    cpu_cores="$(grep -ic processor /proc/cpuinfo)"
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
  find "${eus_dir}" "${unifi_db_eus_dir}" -type d -print -o -type f -print &> "/tmp/EUS/support/dirs_and_files"
  # Create a copy of the system.properties file and remove any mongodb PII
  while read -r system_properties_files; do
    {
      echo -e "\n-----( ${system_properties_files} )----- \n"
      cat "${system_properties_files}"
    } >> "/tmp/EUS/support/unifi.system.properties"
  done < <(find /usr/lib/unifi/data/ -name "system.properties*" -type f)
  if grep -qE 'mongo\.password|mongo\.uri' "/tmp/EUS/support/unifi.system.properties"; then sed -i -e '/mongo.password/d' -e '/mongo.uri/d' "/tmp/EUS/support/unifi.system.properties"; echo "# Removed mongo.password and mongo.uri for privacy reasons" >> "/tmp/EUS/support/unifi.system.properties"; fi
  #
  if [[ "${unifi_core_system}" != 'true' && -n "$(apt-cache search debsums | awk '/debsums/{print$1}')" ]]; then
    if ! [[ "$(command -v debsums)" ]]; then DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install debsums &>> "${eus_dir}/logs/apt.log"; fi
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
    tar cJvfh "${support_file}" --exclude="${eus_dir}/go.tar.gz" --exclude="${eus_dir}/unifi_db" --exclude="${eus_dir}/tmp" --exclude="/usr/lib/unifi/logs/remote" "/tmp/EUS" "${eus_dir}" "/usr/lib/unifi/logs" "/etc/apt/sources.list" "/etc/apt/sources.list.d/" "/etc/apt/preferences" "/etc/apt/keyrings" "/etc/apt/trusted.gpg.d/" "/etc/apt/preferences.d/" "/etc/default/unifi" "/etc/environment" "/var/log/dpkg.log"* "/etc/systemd/system/unifi.service.d/" "/lib/systemd/system/unifi.service" "/var/lib/apt/" "/usr/lib/unifi/data/db/version" &> /dev/null
  elif "$(which dpkg)" -l zstd 2> /dev/null | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
    support_file="/tmp/eus-support-${support_file_uuid}${support_file_time}.tar.zst"
    support_file_name="$(basename "${support_file}")"
    if [[ "$(dpkg-query --showformat='${version}' --show jq 2> /dev/null | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
      jq '.scripts."'"${script_name}"'" |= . + {"support": (.support + {("'"${support_file_name}"'"): {"abort-reason": "'"${abort_reason}"'","upload-results": ""}})}' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
    else
      jq --arg script_name "$script_name" --arg support_file_name "$support_file_name" --arg abort_reason "$abort_reason" '.scripts[$script_name] |= (. + {support: ((.support // {}) + {($support_file_name): {"abort-reason": $abort_reason,"upload-results": ""}})})' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
    fi
    eus_database_move
    tar --use-compress-program=zstd -cvf "${support_file}" --exclude="${eus_dir}/go.tar.gz" --exclude="${eus_dir}/unifi_db" --exclude="${eus_dir}/tmp" --exclude="/usr/lib/unifi/logs/remote" "/tmp/EUS" "${eus_dir}" "/usr/lib/unifi/logs" "/etc/apt/sources.list" "/etc/apt/sources.list.d/" "/etc/apt/preferences" "/etc/apt/keyrings" "/etc/apt/trusted.gpg.d/" "/etc/apt/preferences.d/" "/etc/default/unifi" "/etc/environment" "/var/log/dpkg.log"* "/etc/systemd/system/unifi.service.d/" "/lib/systemd/system/unifi.service" "/var/lib/apt/" "/usr/lib/unifi/data/db/version" &> /dev/null
  elif "$(which dpkg)" -l tar 2> /dev/null | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
    support_file="/tmp/eus-support-${support_file_uuid}${support_file_time}.tar.gz"
    support_file_name="$(basename "${support_file}")"
    if [[ "$(dpkg-query --showformat='${version}' --show jq 2> /dev/null | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
      jq '.scripts."'"${script_name}"'" |= . + {"support": (.support + {("'"${support_file_name}"'"): {"abort-reason": "'"${abort_reason}"'","upload-results": ""}})}' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
    else
      jq --arg script_name "$script_name" --arg support_file_name "$support_file_name" --arg abort_reason "$abort_reason" '.scripts[$script_name] |= (. + {support: ((.support // {}) + {($support_file_name): {"abort-reason": $abort_reason,"upload-results": ""}})})' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
    fi
    eus_database_move
    tar czvfh "${support_file}" --exclude="${eus_dir}/go.tar.gz" --exclude="${eus_dir}/unifi_db" --exclude="${eus_dir}/tmp" --exclude="/usr/lib/unifi/logs/remote" "/tmp/EUS" "${eus_dir}" "/usr/lib/unifi/logs" "/etc/apt/sources.list" "/etc/apt/sources.list.d/" "/etc/apt/preferences" "/etc/apt/keyrings" "/etc/apt/trusted.gpg.d/" "/etc/apt/preferences.d/" "/etc/default/unifi" "/etc/environment" "/var/log/dpkg.log"* "/etc/systemd/system/unifi.service.d/" "/lib/systemd/system/unifi.service" "/var/lib/apt/" "/usr/lib/unifi/data/db/version" &> /dev/null
  elif "$(which dpkg)" -l zip 2> /dev/null | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
    support_file="/tmp/eus-support-${support_file_uuid}${support_file_time}.zip"
    support_file_name="$(basename "${support_file}")"
    if [[ "$(dpkg-query --showformat='${version}' --show jq 2> /dev/null | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
      jq '.scripts."'"${script_name}"'" |= . + {"support": (.support + {("'"${support_file_name}"'"): {"abort-reason": "'"${abort_reason}"'","upload-results": ""}})}' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
    else
      jq --arg script_name "$script_name" --arg support_file_name "$support_file_name" --arg abort_reason "$abort_reason" '.scripts[$script_name] |= (. + {support: ((.support // {}) + {($support_file_name): {"abort-reason": $abort_reason,"upload-results": ""}})})' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
    fi
    eus_database_move
    zip -r "${support_file}" "/tmp/EUS/" "${eus_dir}/" "/usr/lib/unifi/logs/" "/etc/apt/sources.list" "/etc/apt/sources.list.d/" "/etc/apt/preferences" "/etc/apt/keyrings" "/etc/apt/trusted.gpg.d/" "/etc/apt/preferences.d/" "/etc/default/unifi" "/etc/environment" "/var/log/dpkg.log"* "/etc/systemd/system/unifi.service.d/" "/lib/systemd/system/unifi.service" "/var/lib/apt/" "/usr/lib/unifi/data/db/version" -x "${eus_dir}/go.tar.gz" -x "${eus_dir}/unifi_db/*" -x "${eus_dir}/tmp" -x "/usr/lib/unifi/logs/remote" &> /dev/null
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
      fi
    fi
  fi
  if [[ "${script_option_support_file}" == 'true' ]]; then exit 0; fi
}

abort_mongodb() {
  unset mongodb_org_v
  skip_mongodb_org_v="true"
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
  eus_directory_location="/tmp/EUS"
  eus_create_directories "repositories/${mongodb_upgrade_date}"
  apt-get update &> "/tmp/EUS/repositories/${mongodb_upgrade_date}/apt-get-update"
  abort_mongodb_remove_older_mongodb_repositories="true"
  remove_older_mongodb_repositories
  if [[ "${mongodb_org_upgrade_from_version::2}" == "30" ]]; then
    add_mongodb_30_repo="true"
  elif [[ "${mongodb_org_upgrade_from_version::2}" == "32" ]]; then
    add_mongodb_32_repo="true"
  elif [[ "${mongodb_org_upgrade_from_version::2}" == "34" ]]; then
    add_mongodb_34_repo="true"
  elif [[ "${mongodb_org_upgrade_from_version::2}" == "36" ]]; then
    add_mongodb_36_repo="true"
  elif [[ "${mongodb_org_upgrade_from_version::2}" == "40" ]]; then
    add_mongodb_40_repo="true"
  elif [[ "${mongodb_org_upgrade_from_version::2}" == "42" ]]; then
    add_mongodb_42_repo="true"
  elif [[ "${mongodb_org_upgrade_from_version::2}" == "44" ]]; then
    add_mongodb_44_repo="true"
  elif [[ "${mongodb_org_upgrade_from_version::2}" == "50" ]]; then
    add_mongodb_50_repo="true"
  elif [[ "${mongodb_org_upgrade_from_version::2}" == "60" ]]; then
    add_mongodb_60_repo="true"
  elif [[ "${mongodb_org_upgrade_from_version::2}" == "70" ]]; then
    add_mongodb_70_repo="true"
  elif [[ "${mongodb_org_upgrade_from_version::2}" == "80" ]]; then
    add_mongodb_80_repo="true"
  fi
  add_mongodb_repo
}

abort() {
  if [[ "${mongodb_upgrade_started_success_value}" == 'true' ]] && [[ -n "$(command -v jq)" && -f "${eus_dir}/db/db.json" ]]; then
    if [[ "$(dpkg-query --showformat='${version}' --show jq 2> /dev/null | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
      jq '.scripts["'"$script_name"'"].tasks += {"mongodb-upgrade ('"${mongodb_upgrade_date}"')": [.scripts["'"$script_name"'"].tasks["mongodb-upgrade ('"${mongodb_upgrade_date}"')"][0] + {"status":"failed"}]}' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
    else
      jq --arg script_name "$script_name" --arg mongodb_upgrade_date "$mongodb_upgrade_date" '.scripts[$script_name].tasks += {("mongodb-upgrade (" + $mongodb_upgrade_date + ")"): [.scripts[$script_name].tasks["mongodb-upgrade (" + $mongodb_upgrade_date + ")"][0] + {"status": "failed"}]}' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
    fi
    eus_database_move
    check_unifi_folder_permissions_state="after-abort"
    check_unifi_folder_permissions
  fi
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
  if [[ "${unifi_database_move_sucess}" == 'true' ]]; then
    if [[ "${mongodb_upgrade_pre_import_failure}" == 'true' ]]; then revert_mongodb_upgrade_package_changes="true"
    elif [[ "${mongodb_upgrade_import_failure}" == 'true' ]]; then revert_mongodb_upgrade_package_changes="true"
    fi
    if [[ "${revert_mongodb_upgrade_package_changes}" == 'true' && -n "${mongodb_org_upgrade_from_version_with_dots}" ]]; then
      abort_mongodb
      check_dpkg_lock
      if [[ "${glennr_compiled_mongod_purged_server_import}" == 'true' ]]; then
        echo -e "${GRAY_R}#${RESET} Un-installing ${gr_mongod_name}..."
        if DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_downgrade_option[@]}" "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' purge "${gr_mongod_name}" &>> "${eus_dir}/logs/mongodb_upgrade_${mongodb_upgrade_from_version::2}_to_${mongo_version_max}-downgrade-abort.log"; then
          echo -e "${GREEN}#${RESET} Successfully un-installed ${gr_mongod_name}! \\n"
          echo "mongodb-org-server" &>> /tmp/EUS/mongodb/packages_list
          sed -i "/${gr_mongod_name}/d" /tmp/EUS/mongodb/packages_list
        else
          check_unmet_dependencies
          broken_packages_check
          attempt_recover_broken_packages
          add_apt_option_no_install_recommends="true"; get_apt_options
          if DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_downgrade_option[@]}" "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' purge "${gr_mongod_name}" &>> "${eus_dir}/logs/mongodb_upgrade_${mongodb_upgrade_from_version::2}_to_${mongo_version_max}-downgrade-abort.log"; then
            echo -e "${GREEN}#${RESET} Successfully un-installed ${gr_mongod_name}! \\n"
            echo "mongodb-org-server" &>> /tmp/EUS/mongodb/packages_list
            sed -i "/${gr_mongod_name}/d" /tmp/EUS/mongodb/packages_list
          else
            echo -e "${RED}#${RESET} Failed to un-install ${gr_mongod_name}...\\n"
          fi
          get_apt_options
        fi
        if [[ -e "/etc/apt/preferences.d/eus_mongodb-org-server" ]]; then rm --force "/etc/apt/preferences.d/eus_mongodb-org-server" &> /dev/null; fi
      fi
      while read -r mongodb_package; do
        check_dpkg_lock
        echo -e "${GRAY_R}#${RESET} Downgrading ${mongodb_package} back to version ${mongodb_org_upgrade_from_version_with_dots}..."
        if DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_downgrade_option[@]}" "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "${mongodb_package}=${mongodb_org_upgrade_from_version_with_dots}" &>> "${eus_dir}/logs/mongodb_upgrade_${mongodb_upgrade_from_version::2}_to_${mongo_version_max}-downgrade-abort.log"; then
          echo -e "${GREEN}#${RESET} Successfully downgraded ${mongodb_package}! \\n"
        else
          check_unmet_dependencies
          broken_packages_check
          attempt_recover_broken_packages
          add_apt_option_no_install_recommends="true"; get_apt_options
          if DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_downgrade_option[@]}" "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "${mongodb_package}=${mongodb_org_upgrade_from_version_with_dots}" &>> "${eus_dir}/logs/mongodb_upgrade_${mongodb_upgrade_from_version::2}_to_${mongo_version_max}-downgrade-abort.log"; then
            echo -e "${GREEN}#${RESET} Successfully downgraded ${mongodb_package}! \\n"
          else
            echo -e "${RED}#${RESET} Failed to downgrade ${mongodb_package}...\\n"
          fi
          get_apt_options
        fi
      done < /tmp/EUS/mongodb/packages_list
    elif [[ "${glennr_compiled_mongod_purged_server}" == 'true' ]]; then
      abort_mongodb
      check_dpkg_lock
      echo -e "${GRAY_R}#${RESET} Re-installing mongodb-org-server..."
      if DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_downgrade_option[@]}" "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "mongodb-org-server=${mongodb_org_upgrade_from_version_with_dots}" &>> "${eus_dir}/logs/mongodb_upgrade_${mongodb_upgrade_from_version::2}_to_${mongo_version_max}-downgrade-abort.log"; then
        echo -e "${GREEN}#${RESET} Successfully re-installed mongodb-org-server! \\n"
      else
        check_unmet_dependencies
        broken_packages_check
        attempt_recover_broken_packages
        add_apt_option_no_install_recommends="true"; get_apt_options
        if DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_downgrade_option[@]}" "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "mongodb-org-server=${mongodb_org_upgrade_from_version_with_dots}" &>> "${eus_dir}/logs/mongodb_upgrade_${mongodb_upgrade_from_version::2}_to_${mongo_version_max}-downgrade-abort.log"; then
          echo -e "${GREEN}#${RESET} Successfully re-installed mongodb-org-server! \\n"
        else
          echo -e "${RED}#${RESET} Failed to re-install mongodb-org-server...\\n"
        fi
        get_apt_options
      fi
    fi
    if [[ -d "${unifi_database_location}" ]]; then
      echo -e "${GRAY_R}#${RESET} Moving \"${unifi_database_location}/\" back to \"${unifi_db_eus_dir}/unifi_db/db-backup-${mongodb_upgrade_date}-post-abort\"..."
      if mv "${unifi_database_location}" "${unifi_db_eus_dir}/unifi_db/db-backup-${mongodb_upgrade_date}-post-abort" &>> "${eus_dir}/logs/unifi-database-move-abort-revert.log"; then
        echo -e "${GREEN}#${RESET} Successfully moved \"${unifi_database_location}/\" back to \"${unifi_db_eus_dir}/unifi_db/db-backup-${mongodb_upgrade_date}-post-abort\"! \\n"
      else
        echo -e "${RED}#${RESET} Failed to move \"${unifi_database_location}\" back to \"${unifi_db_eus_dir}/unifi_db/db-backup-${mongodb_upgrade_date}-post-abort\"..."
      fi
    fi
    echo -e "${GRAY_R}#${RESET} Moving \"${unifi_db_eus_dir}/unifi_db/db-backup-${mongodb_upgrade_date}/\" back to \"${unifi_database_location}\"..."
    if mv "${unifi_db_eus_dir}/unifi_db/db-backup-${mongodb_upgrade_date}/" "${unifi_database_location}" &>> "${eus_dir}/logs/unifi-database-move-abort-revert.log"; then
      echo -e "${GREEN}#${RESET} Successfully moved \"${unifi_db_eus_dir}/unifi_db/db-backup-${mongodb_upgrade_date}/\" back to \"${unifi_database_location}\"! \\n"
    else
      echo -e "${RED}#${RESET} Failed to move \"${unifi_db_eus_dir}/unifi_db/db-backup-${mongodb_upgrade_date}/\" back to \"${unifi_database_location}\"..."
    fi
  fi
  if [[ "${mongodb_upgrade_unifi_remove}" == 'true' ]]; then
    unifi_required_packages
    unifi_deb_package_modification
    ignore_unifi_package_dependencies
    check_dpkg_lock
    echo -e "${GRAY_R}#${RESET} Installing UniFi Network Application version ${first_digit_current_unifi}.${second_digit_current_unifi}.${third_digit_current_unifi}..."
    # shellcheck disable=SC2086
    if DEBIAN_FRONTEND='noninteractive' "$(which dpkg)" -i ${dpkg_ignore_depends_flag} "${unifi_temp}" &>> "${eus_dir}/logs/mongodb_upgrade_${mongodb_upgrade_from_version::2}_to_${mongo_version_max}.log"; then
      echo -e "${GREEN}#${RESET} Successfully installed UniFi Network Application version ${first_digit_current_unifi}.${second_digit_current_unifi}.${third_digit_current_unifi}! \\n"
      rm --force "${unifi_temp}" &>> /dev/null
    else
      echo -e "${RED}#${RESET} Failed to install UniFi Network Application version ${first_digit_current_unifi}.${second_digit_current_unifi}.${third_digit_current_unifi}...\\n"
    fi
  fi
  if [[ -f "/tmp/EUS/mongodb/unifi_package_list" ]]; then
    while read -r unifi_package; do
      echo -e "${GRAY_R}#${RESET} Starting service ${unifi_package}..."
      if [[ "${unifi_package}" == "unifi" ]]; then check_service_overrides; old_systemd_version_check; check_service_timeoutsec_increase; fi
      if [[ "${limited_functionality}" == 'true' ]]; then
        if [[ "${old_systemd_version}" == 'true' && "${unifi_package}" == "unifi" ]]; then if [[ "${old_systemd_version_check_unifi_restart}" == 'true' ]]; then echo -e "${GREEN}#${RESET} Successfully started service ${unifi_package}! \\n"; else echo -e "${RED}#${RESET} Failed to start service ${unifi_package}... \\n"; fi; elif ! service "${unifi_package}" start &> /dev/null; then echo -e "${RED}#${RESET} Failed to start service ${unifi_package}... \\n"; else echo -e "${GREEN}#${RESET} Successfully started service ${unifi_package}! \\n"; fi
      else
        if [[ "${old_systemd_version}" == 'true' && "${unifi_package}" == "unifi" ]]; then if [[ "${old_systemd_version_check_unifi_restart}" == 'true' ]]; then echo -e "${GREEN}#${RESET} Successfully started service ${unifi_package}! \\n"; else echo -e "${RED}#${RESET} Failed to start service ${unifi_package}... \\n"; fi; elif ! systemctl start "${unifi_package}" &> /dev/null; then echo -e "${RED}#${RESET} Failed to start service ${unifi_package}... \\n"; else echo -e "${GREEN}#${RESET} Successfully started service ${unifi_package}! \\n"; fi
      fi
    done < /tmp/EUS/mongodb/unifi_package_list
  fi
  if [[ -e "/tmp/EUS/mongodb/unhold" && "${unhold_packages}" == 'true' ]]; then
    check_dpkg_lock
    while read -r mongodb_package; do
      echo "${mongodb_package} hold" | "$(which dpkg)" --set-selections &>> "${eus_dir}/logs/package-hold.log"
    done < "/tmp/EUS/mongodb/unhold"
  fi
  echo -e "\\n\\n${RED}#########################################################################${RESET}\\n"
  if [[ "$(df -B1 / | awk 'NR==2{print $4}')" -le '5368709120' ]]; then echo -e "${YELLOW}#${RESET} You only have $(df -B1 / | awk 'NR==2{print $4}' | awk '{ split( "B KB MB GB TB PB EB ZB YB" , v ); s=1; while( $1>1024 && s<9 ){ $1/=1024; s++ } printf "%.1f %s", $1, v[s] }') of disk space available on \"/\"... \\n"; fi
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
  elif grep -iq "UCKP\\|UCKG2\\|UCK" /usr/lib/version &> /dev/null; then
    eus_dir='/srv/EUS'
  elif "$(which dpkg)" -l unifi-core 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
    eus_dir='/srv/EUS'
  else
    eus_dir='/usr/lib/EUS'
  fi
  if [[ "${eus_dir}" == '/srv/EUS' ]]; then if findmnt -no OPTIONS "$(df --output=target /srv | tail -1)" | grep -ioq "ro"; then eus_dir='/usr/lib/EUS'; fi; fi
  eus_directory_location="${eus_dir}"
  eus_create_directories "db" "logs" "tmp"
  if ! rm -rf /tmp/EUS &> /dev/null; then abort_reason="Failed to remove /tmp/EUS."; header_red; abort; fi
  eus_directory_location="/tmp/EUS"
  eus_create_directories "requirement" "sites" "accounts" "application" "apt" "dpkg" "firmware" "repository" "downloads" "apt" "upgrade" "mongodb"
  grep -riIl "unifi-[0-9].[0-9]" /etc/apt/sources.list* &> /tmp/EUS/repository/unifi-repo-file
  if [[ -f /usr/lib/version ]]; then if grep -iq "UCK.mtk7623" /usr/lib/version &> /dev/null; then cloudkey_generation="1"; fi; fi
  if ! [[ -d "/etc/apt/keyrings" ]]; then if ! install -m "0755" -d "/etc/apt/keyrings" &>> "${eus_dir}/logs/keyrings-directory-creation.log"; then if ! mkdir -p "/etc/apt/keyrings" &>> "${eus_dir}/logs/keyrings-directory-creation.log"; then abort_reason="Failed to create /etc/apt/keyrings."; abort; fi; fi; if ! [[ -s "${eus_dir}/logs/keyrings-directory-creation.log" ]]; then rm --force "${eus_dir}/logs/keyrings-directory-creation.log"; fi; fi
  if [[ "$(command -v stat)" ]]; then tmp_permissions="$(stat -c '%a' /tmp)"; echo -e "$(date +%F-%T.%6N) | \"/tmp\" has permissions \"${tmp_permissions}\"..." &>> "${eus_dir}/logs/update-tmp-permissions.log"; fi
  # shellcheck disable=SC2012
  if [[ "${tmp_permissions}" != '1777' ]]; then if [[ -z "${tmp_permissions}" ]]; then echo -e "$(date +%F-%T.%6N) | \"/tmp\" has permissions \"$(ls -ld /tmp | awk '{print $1}')\"..." &>> "${eus_dir}/logs/update-tmp-permissions.log"; fi; chmod 1777 /tmp &>> "${eus_dir}/logs/update-tmp-permissions.log"; fi
  if [[ -n "$(find /etc/apt/sources.list.d/ -name "*.sources" -print -quit 2>/dev/null)" ]]; then use_deb822_format="true"; fi
  if [[ "${use_deb822_format}" == 'true' ]]; then source_file_format="sources"; else source_file_format="list"; fi
  eus_tmp_directory_check
}

script_logo() {
  cat << "EOF"
  _______________ ___  _________   ____ ___            .___       __          
  \_   _____/    |   \/   _____/  |    |   \______   __| _/____ _/  |_  ____  
   |    __)_|    |   /\_____  \   |    |   /\____ \ / __ |\__  \\   __\/ __ \ 
   |        \    |  / /        \  |    |  / |  |_> > /_/ | / __ \|  | \  ___/ 
  /_______  /______/ /_______  /  |______/  |   __/\____ |(____  /__|  \___  >
          \/                 \/             |__|        \/     \/          \/ 

EOF
}

start_script() {
  script_location="${BASH_SOURCE[0]}"
  script_file_name="$(basename "${BASH_SOURCE[0]}")"
  if ! [[ -f "${script_location}" ]]; then header_red; echo -e "${YELLOW}#${RESET} The script needs to be saved on the disk in order to work properly, please follow the instructions...\\n${YELLOW}#${RESET} Usage: curl -sO https://get.glennr.nl/unifi/update/unifi-update.sh && bash unifi-update.sh\\n\\n"; exit 1; fi
  script_name="$(grep -i "# Script" "${script_location}" | head -n 1 | cut -d'|' -f2 | sed -e 's/^ //g')"
  eus_directories
  header
  script_logo
  echo -e "    UniFi Easy Update Script!"
  echo -e "\\n${GRAY_R}#${RESET} Starting the Easy Update Script.."
  echo -e "${GRAY_R}#${RESET} Thank you for using my Easy Update Script :-)\\n\\n"
  if [[ "${update_at_start_script}" != 'true' ]]; then update_at_start_script="true"; update_eus_db; fi
  if pgrep -f unattended-upgrade &> /dev/null; then if systemctl stop unattended-upgrades &>> "${eus_dir}/logs/unattended-upgrades.log"; then stopped_unattended_upgrade="true"; fi; fi
}
start_script
check_dns
check_apt_listbugs

help_script() {
  check_apt_listbugs
  if [[ "${script_option_help}" == 'true' ]]; then header; script_logo; else echo -e "${GRAY_R}----${RESET}\\n"; fi
  echo -e "    Easy UniFi Network Application Install Script assistance\\n"
  echo -e "
  Script usage:
  bash ${script_file_name} [options]
  
  Script options:
    --skip                      Skip most user interactive questions.
    --unifi-version [argument]  Combine with --skip for non-interactive Network Application upgrades
                                if all requirements are already present. An possible argument could
                                be 8.5.6 or latest for example.
    --archive-alerts            Archive all alerts from the UniFi Network Application.
    --delete-events             Delete all events from the UniFi Network Application.
    --do-not-start-unifi        Automatically stop the UniFi Network Application post updates.
    --check-default-networks    Automatically check and cleanup sites with multiple default LAN networks.
    --exit                      Automatically exit the script after completing --check-default-networks.
    --custom-url [argument]     Manually provide a UniFi Network Application download URL.
                                example:
                                --custom-url https://dl.ui.com/unifi/8.5.6/unifi_sysvinit_all.deb
    --help                      Shows this information :)\\n\\n"
  exit 0
}

rm --force /tmp/EUS/script_options &> /dev/null

while [ -n "$1" ]; do
  case "$1" in
  --skip)
       script_option_skip="true"
       echo "--skip" &>> /tmp/EUS/script_options;;
  --archive-alerts)
       script_option_archive_alerts="true"
       echo "--archive-alerts" &>> /tmp/EUS/script_options;;
  --delete-events)
       script_option_delete_events="true"
       echo "--delete-events" &>> /tmp/EUS/script_options;;
  --do-not-start-unifi)
       script_option_do_not_start_unifi="true"
       echo "--do-not-start-unifi" &>> /tmp/EUS/script_options;;
  --check-default-networks)
       check_multiple_default_lan_networks="true"
       echo -e "$(date +%F-%T.%6N) | Script option --check-default-lans was used, changing variable check_multiple_default_lan_networks to true..." &>> "${eus_dir}/logs/cleanup-multiple-default-lan-networks.log"
       echo "--check-default-networks" &>> /tmp/EUS/script_options;;
  --exit)
       exit_after_check_multiple_default_lan_networks="true"
       echo "--exit" &>> /tmp/EUS/script_options;;
  --custom-url)
       if [[ -n "${2}" ]]; then if echo "${2}" | grep -ioq ".deb"; then custom_url_down_provided="true"; custom_download_url="${2}"; else header_red; echo -e "${RED}#${RESET} Provided URL does not have the 'deb' extension...\\n"; help_script; fi; fi
       script_option_custom_url="true"
       if [[ "${custom_url_down_provided}" == 'true' ]]; then echo "--custom-url ${2}" &>> /tmp/EUS/script_options; else echo "--custom-url" &>> /tmp/EUS/script_options; fi;;
  --unifi-version)
       if [[ -n "${2}" ]]; then if [[ "${2}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then application_version="${2}"; elif [[ "${2}" == "latest" ]]; then application_version="${2}"; else header_red; echo -e "${RED}#${RESET} ${2} is not a valid version...\\n"; help_script; fi; fi
       script_option_unifi_version="true"
       echo "--unifi-version ${2}" &>> /tmp/EUS/script_options;;
  --help)
       script_option_help="true"
       help_script;;
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
            "versions-ran": ["'"$(grep -i "# Version" "${script_location}" | head -n 1 | cut -d'|' -f2 | sed 's/ //g')"'"],
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
          "versions-ran": ["'"$(grep -i "# Version" "${script_location}" | head -n 1 | cut -d'|' -f2 | sed 's/ //g')"'"],
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

start_application_upgrade() {
  header
  echo -e "${GRAY_R}#${RESET} Starting the UniFi Network Application update! \\n\\n"
  sleep 2
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
      os_codename="$(grep -io "wheezy\\|jessie\\|stretch\\|buster\\|bullseye\\|bookworm\\|trixie\\|forky\\|precise\\|trusty\\|xenial\\|bionic\\|cosmic\\|disco\\|eoan\\|focal\\|groovy\\|hirsute\\|impish\\|jammy\\|kinetic\\|lunar\\|mantic\\|noble\\|oracular\\|plucky" /etc/os-release | tr '[:upper:]' '[:lower:]' | awk '!NF || !seen[$0]++' | head -n1)"
    fi
  fi
  if [[ "${unsupported_no_modify}" != 'true' ]]; then
    if [[ ! "${os_id}" =~ (ubuntu|debian) ]] && [[ -e "/etc/os-release" ]]; then os_id="$(grep -io "debian\\|ubuntu" /etc/os-release | tr '[:upper:]' '[:lower:]' | head -n1)"; fi
    if [[ "${os_codename}" =~ ^(precise|maya|luna)$ ]]; then repo_codename="precise"; os_codename="precise"; os_id="ubuntu"
    elif [[ "${os_codename}" =~ ^(trusty|qiana|rebecca|rafaela|rosa|freya)$ ]]; then repo_codename="trusty"; os_codename="trusty"; os_id="ubuntu"
    elif [[ "${os_codename}" =~ ^(xenial|sarah|serena|sonya|sylvia|loki)$ ]]; then repo_codename="xenial"; os_codename="xenial"; os_id="ubuntu"
    elif [[ "${os_codename}" =~ ^(bionic|tara|tessa|tina|tricia|hera|juno)$ ]]; then repo_codename="bionic"; os_codename="bionic"; os_id="ubuntu"
    elif [[ "${os_codename}" =~ ^(focal|ulyana|ulyssa|uma|una|odin|jolnir)$ ]]; then repo_codename="focal"; os_codename="focal"; os_id="ubuntu"
    elif [[ "${os_codename}" =~ ^(jammy|vanessa|vera|victoria|virginia|horus|cade)$ ]]; then repo_codename="jammy"; os_codename="jammy"; os_id="ubuntu"
    elif [[ "${os_codename}" =~ ^(noble|wilma|xia|zara|scootski|circe)$ ]]; then repo_codename="noble"; os_codename="noble"; os_id="ubuntu"
    elif [[ "${os_codename}" =~ ^(oracular)$ ]]; then repo_codename="oracular"; os_codename="oracular"; os_id="ubuntu"
    elif [[ "${os_codename}" =~ ^(plucky)$ ]]; then repo_codename="plucky"; os_codename="plucky"; os_id="ubuntu"
    elif [[ "${os_codename}" =~ ^(questing)$ ]]; then repo_codename="questing"; os_codename="questing"; os_id="ubuntu"
    elif [[ "${os_codename}" =~ ^(jessie|betsy)$ ]]; then repo_codename="jessie"; os_codename="jessie"; os_id="debian"
    elif [[ "${os_codename}" =~ ^(stretch|continuum|helium|cindy|tyche|ascii)$ ]]; then repo_codename="stretch"; os_codename="stretch"; os_id="debian"
    elif [[ "${os_codename}" =~ ^(buster|debbie|parrot|engywuck-backports|engywuck|deepin|lithium|beowulf|po-tolo|nibiru|amber|eagle)$ ]]; then repo_codename="buster"; os_codename="buster"; os_id="debian"
    elif [[ "${os_codename}" =~ ^(bullseye|kali-rolling|elsie|ara|beryllium|chimaera|orion-belt|byzantium)$ ]]; then repo_codename="bullseye"; os_codename="bullseye"; os_id="debian"
    elif [[ "${os_codename}" =~ ^(bookworm|lory|faye|boron|beige|preslee|daedalus|crimson)$ ]]; then repo_codename="bookworm"; os_codename="bookworm"; os_id="debian"
    elif [[ "${os_codename}" =~ ^(trixie|excalibur|the-seven-sisters)$ ]]; then repo_codename="trixie"; os_codename="trixie"; os_id="debian"
    elif [[ "${os_codename}" =~ ^(forky|freia)$ ]]; then repo_codename="forky"; os_codename="forky"; os_id="debian"
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
      if [[ "${os_codename}" =~ (precise|trusty|utopic|vivid|wily|yakkety|zesty|artful|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing) ]]; then
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
          #if curl "${curl_argument[@]}" "${http_or_https}://legacy.raspbian.org/raspbian/dists/" 2> /dev/null | grep -iq "${os_codename}" 2> /dev/null; then archived_raspbian_repo="true"; fi
          #if [[ "${archived_raspbian_repo}" == "true" ]]; then raspbian_repo_url="${http_or_https}://legacy.raspbian.org/raspbian"; else raspbian_repo_url="${http_or_https}://archive.raspbian.org/raspbian"; fi
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
    if [[ "${os_codename}" =~ (precise|trusty|utopic|vivid|wily|yakkety|zesty|artful|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing) ]]; then
      repo_url="${http_or_https}://archive.ubuntu.com/ubuntu"
    elif [[ "${os_codename}" =~ (wheezy|jessie|stretch|buster|bullseye|bookworm|trixie|forky|unstable) ]]; then
      repo_url="${http_or_https}://deb.debian.org/debian"
      #if [[ "${architecture}" == 'armhf' ]]; then
      #  raspbian_repo_url="${http_or_https}://archive.raspbian.org/raspbian"
      #fi
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
  if grep -sq "^deb .*http\?s\?://$(echo "${repo_url}" | sed -e 's/https\:\/\///g' -e 's/http\:\/\///g')${repo_url_arguments}\?/\? ${repo_codename}${repo_codename_argument} ${repo_component}" /etc/apt/sources.list /etc/apt/sources.list.d/*; then
    echo -e "$(date +%F-%T.%6N) | \"${repo_url}${repo_url_arguments} ${repo_codename}${repo_codename_argument} ${repo_component}\" was found, not adding to repository lists. $(grep -srIl "^deb .*http\?s\?://$(echo "${repo_url}" | sed -e 's/https\:\/\///g' -e 's/http\:\/\///g')${repo_url_arguments}\?/\? ${repo_codename}${repo_codename_argument} ${repo_component}" /etc/apt/sources.list /etc/apt/sources.list.d/*)..." &>> "${eus_dir}/logs/already-found-repository.log"
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
  if [[ "$(lsb_release --codename --short | tr '[:upper:]' '[:lower:]')" =~ (wheezy|jessie|stretch|buster|bullseye|bookworm|trixie|forky|unstable) && "$(command -v jq)" ]]; then
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

# Check if system runs Unifi OS
if "$(which dpkg)" -l unifi-core 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
  unifi_core_system="true"
  unifi_core_glennr_api="&host=uos&architecture=$("$(which dpkg)" --print-architecture)"
  if grep -sq unifi-native /mnt/.rofs/var/lib/dpkg/status; then unifi_native_system="true"; unifi_core_glennr_api="&host=uos-native&architecture=$("$(which dpkg)" --print-architecture)"; fi
  if [[ -f /proc/ubnthal/system.info ]]; then if grep -iq "shortname" /proc/ubnthal/system.info; then unifi_core_device="$(grep "shortname" /proc/ubnthal/system.info | sed 's/shortname=//g')"; fi; fi
  if [[ -f /etc/motd && -s /etc/motd && -z "${unifi_core_device}" ]]; then unifi_core_device="$(grep -io "welcome.*" /etc/motd | sed -e 's/Welcome //g' -e 's/to //g' -e 's/the //g' -e 's/!//g')"; fi
  if [[ -f /usr/lib/version && -s /usr/lib/version && -z "${unifi_core_device}" ]]; then unifi_core_device="$(cut -d'.' -f1 /usr/lib/version)"; fi
  if [[ -z "${unifi_core_device}" ]]; then unifi_core_device='Unknown device'; fi
  if [[ "$(curl -s http://localhost:11081/api/cloud/status | jq '.enabled')" == 'true' ]]; then unifi_core_remote_access="true"; fi
fi

get_unifi_application_status() {
  if [[ "${unifi_core_system}" == 'true' ]]; then
    if [[ -n "$(command -v jq)" ]]; then
      application_up="$(curl --silent --insecure "${status_api_protocol}://localhost:${dmport}/status" | jq -r '.meta.server_running' 2> /dev/null)"
      if [[ -z "${application_up}" ]]; then application_up="$(curl "${noproxy_curl_argument[@]}" --silent --insecure --connect-timeout 1 "${status_api_protocol}://localhost:${dmport}/status" | jq -r '.meta.server_running' 2> /dev/null)"; noproxy_curl_argument_used="true"; fi
    else
      application_up="$(curl --silent --insecure --connect-timeout 1 "${status_api_protocol}://localhost:${dmport}/status" | grep -o '"server_running":[^,]*' | awk -F ':' '{print $2}')"
      if [[ -z "${application_up}" ]]; then application_up="$(curl "${noproxy_curl_argument[@]}" --silent --insecure --connect-timeout 1 "${status_api_protocol}://localhost:${dmport}/status" | grep -o '"server_running":[^,]*' | awk -F ':' '{print $2}')"; noproxy_curl_argument_used="true"; fi
    fi
  else
    if [[ -n "$(command -v jq)" ]]; then
      application_up="$(curl --silent --insecure "${status_api_protocol}://localhost:${dmport}/status" | jq -r '.meta.up' 2> /dev/null)"
      if [[ -z "${application_up}" ]]; then application_up="$(curl "${noproxy_curl_argument[@]}" --silent --insecure --connect-timeout 1 "${status_api_protocol}://localhost:${dmport}/status" | jq -r '.meta.up' 2> /dev/null)"; noproxy_curl_argument_used="true"; fi
    else
      application_up="$(curl --silent --insecure --connect-timeout 1 "${status_api_protocol}://localhost:${dmport}/status" | grep -o '"up":[^,]*' | awk -F ':' '{print $2}')"
      if [[ -z "${application_up}" ]]; then application_up="$(curl "${noproxy_curl_argument[@]}" --silent --insecure --connect-timeout 1 "${status_api_protocol}://localhost:${dmport}/status" | grep -o '"up":[^,]*' | awk -F ':' '{print $2}')"; noproxy_curl_argument_used="true"; fi
    fi
  fi
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

if [[ "${unifi_native_system}" != 'true' ]] && "$(which dpkg)" -l unifi-native 2> /dev/null; then
  check_dpkg_lock
  echo -e "${GRAY_R}#${RESET} Removing the UniFi Network Native Application..."
  if DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' purge unifi-native &>> "${eus_dir}/logs/unifi-native-uninstall.log"; then
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

if ! [[ -d /etc/apt/sources.list.d ]]; then
  mkdir -p /etc/apt/sources.list.d
fi

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

# Set options for 32-bit or amrhf systems.
if [[ "$(getconf LONG_BIT)" == '32' ]] || [[ "${architecture}" == 'armhf' ]] || [[ "${limited_functionality}" == 'true' ]] || [[ "$(grep -si "db.mongo.local" /usr/lib/unifi/data/system.properties | awk -F= '{print $2}')" == 'false' ]]; then
  mongodb_upgrade_supported="false"
else
  mongodb_upgrade_supported="true"
fi

update_script() {
  check_apt_listbugs
  header_red
  echo -e "${GRAY_R}#${RESET} You're currently running script version ${local_version} while ${online_version} is the latest!"
  echo -e "${GRAY_R}#${RESET} Downloading and executing version ${online_version} of the script...\\n\\n"
  echo -e "$(date +%F-%T.%6N) | Updating script \"${script_name}\" from version \"${local_version}\" to \"${online_version}\"..." &>> "${eus_dir}/logs/script-update.log"
  sleep 2
  if [[ -n "$(command -v jq)" ]]; then
    online_sha256sum="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/latest-script-version?script=unifi-update&api_version=2" 2> /dev/null | jq -r '.checksums.sha256sum' 2> /dev/null | sed '/null/d')"
  else
    online_sha256sum="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/latest-script-version?script=unifi-update&api_version=2" 2> /dev/null | grep -oP '"sha256sum"\s*:\s*"\K[^"]+')"
  fi
  if curl "${curl_argument[@]}" -o "${script_location}.tmp" https://get.glennr.nl/unifi/update/unifi-update.sh; then
    if [[ -n "${online_sha256sum}" && "$(command -v sha256sum)" ]]; then
      local_checksum="$(sha256sum "${script_location}.tmp" 2> /dev/null | awk '{print $1}')"
      if [[ "${local_checksum}" != "${online_sha256sum}" ]]; then
        for attempt in {1..5}; do
          if [[ -n "$(command -v jq)" ]]; then
            online_sha256sum_latest="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/latest-script-version?script=unifi-update&api_version=2" 2> /dev/null | jq -r '.checksums.sha256sum' 2> /dev/null | sed '/null/d')"
          else
            online_sha256sum_latest="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/latest-script-version?script=unifi-update&api_version=2" 2> /dev/null | grep -oP '"sha256sum"\s*:\s*"\K[^"]+')"
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
            echo -e "$(date +%F-%T.%6N) | Local script file SHA256 is \"${local_checksum}\" while it should be \"${online_sha256sum_latest}\" (attempt ${attempt}/5)..." &>> "${eus_dir}/logs/script-update.log"
            echo -e "${RED}#${RESET} Checksum mismatch (attempt ${attempt}/5), retrying download..."
            sleep 5
            curl "${curl_argument[@]}" -o "${script_location}.tmp" https://get.glennr.nl/unifi/update/unifi-update.sh
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
      rm --force unifi-update.sh 2> /dev/null
      # shellcheck disable=SC2068
      curl "${curl_argument[@]}" --remote-name https://get.glennr.nl/unifi/update/unifi-update.sh && bash unifi-update.sh ${script_options[@]}; exit 0
    fi
  fi
}

script_version_check() {
  local local_version
  local online_version
  local_version="$(grep -i "# Version" "${script_location}" | head -n 1 | cut -d'|' -f2 | sed 's/ //g')"
  if [[ -n "$(command -v jq)" ]]; then
    online_version="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/latest-script-version?script=unifi-update&api_version=2" 2> /dev/null | jq -r '."latest-script-version"' 2> /dev/null)"
  else
    online_version="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/latest-script-version?script=unifi-update&api_version=2" 2> /dev/null | grep -oP '(?<="latest-script-version":")[0-9.]+')"
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

# Check if UniFi is already installed.
if ! "$(which dpkg)" -l unifi 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
  header_red
  echo -e "${GRAY_R}#${RESET} UniFi is not installed on your system or is in a broken state!"
  if [[ "${script_option_skip}" != 'true' ]]; then read -rp $'\033[39m#\033[0m Do you want to run the Easy Installation Script? (Y/n) ' yes_no; fi
  case "$yes_no" in
      [Nn]*) check_apt_listbugs; exit 0;;
      *) check_apt_listbugs; curl "${curl_argument[@]}" --remote-name https://get.glennr.nl/unifi/install/install_latest/unifi-latest.sh && bash unifi-latest.sh --skip; exit 0;;
  esac
fi

# If there a RC?
is_there_a_release_candidate='no'

# UniFi Core Setups if no RC channel is available
if [[ "${unifi_core_system}" == 'true' && "${is_there_a_release_candidate}" == 'yes' ]]; then
  if ! grep -siq release-candidate /etc/apt/sources.list.d/ubiquiti.list; then
    console_has_no_rc="true"
    is_there_a_release_candidate='no'
  fi
fi 

release_wanted () {
  if [[ "${is_there_a_release_candidate}" != 'yes' ]]; then
    header
    if [[ "${console_has_no_rc}" == 'true' ]]; then
      if [[ "${unifi_core_remote_access}" == 'true' ]]; then
        echo -e "${GRAY_R}#${RESET} Your account does not have access to the Release Candidate channel, you can enable access under ui.com/beta..."
        echo -e "${GRAY_R}#${RESET} Release Stage set to | Stable."
      else
        echo -e "${GRAY_R}#${RESET} Remote Access is required to access the Release Candidate channel, please enable it in your UniFi OS Settings..."
        echo -e "${GRAY_R}#${RESET} Release Stage set to | Stable."
      fi
      sleep 4
    else
      echo -e "${GRAY_R}#${RESET} There are currently no Release Candidates."
      echo -e "${GRAY_R}#${RESET} Release Stage set to | Stable."
    fi
    release_stage="S"
    release_stage_friendly="Stable"
    sleep 4
  else
    header
    echo -e "${GRAY_R}#${RESET} What release stage do you want to upgrade to?\\n"
    echo -e " [   ${WHITE_R}1${RESET}   ]  |  Stable ( default )"
    echo -e " [   ${WHITE_R}2${RESET}   ]  |  Release Candidate\\n\\n"
    while true; do
      read -rp $'Your choice | \033[39m' release_stage
      case "$release_stage" in
          1*|"")
            release_stage="S"
            release_stage_friendly="Stable"
            if [[ "${unifi}" == "${latest_release}" ]]; then
              header_red
              echo -e "${GRAY_R}#${RESET} There are currently no newer Stable Releases."
              echo -e "${GRAY_R}#${RESET} Release Stage set to | Release Candidate.\\n\\n"
              release_stage="RC"
              release_stage_friendly="Release Candidate"
              sleep 4
            fi
            break;;
          2*)
            release_stage="RC"
            release_stage_friendly="Release Candidate"
            if [[ "${is_there_a_release_candidate}" == "no" ]]; then
              header_red
              echo -e "${GRAY_R}#${RESET} There are currently no Release Candidates."
              echo -e "${GRAY_R}#${RESET} Release Stage set to | Stable.\\n\\n"
              release_stage="S"
              release_stage_friendly="Stable"
              sleep 4
            fi
            break;;
          *) echo -e "\\n${RED}#${RESET} Invalid input, please answer with a number...\\n"; sleep 3;;
      esac
    done
  fi
  if [[ "${release_stage}" == 'RC' ]]; then rc_version_available="9.3.45"; rc_version_available_secret="9.3.45-9iw96x349g"; fi
}

if [[ "$(command -v jq)" ]]; then latest_release_api_status="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/network-latest?status" 2> /dev/null | jq -r '.availability' 2> /dev/null)"; else latest_release_api_status="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/network-latest?status" 2> /dev/null | grep -oP '(?<="availability":")[^"]+')"; fi
if [[ "${latest_release_api_status}" == "OK" ]]; then
  if [[ -n "$(command -v jq)" ]]; then latest_release="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/network-latest?version=latest" 2> /dev/null | jq -r '.latest_release' 2> /dev/null)"; else latest_release="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/network-latest?version=latest" 2> /dev/null | sed -n 's/.*"latest_release":"\([^"]*\)".*/\1/p')"; fi
else
  latest_release="9.3.45"
fi

broken_packages_check() {
  local broken_packages
  if [[ -d "/tmp/EUS/apt/" ]]; then apt-get check &> /tmp/EUS/apt/apt-check.log; fi
  broken_packages="$(apt-get check 2>&1 | grep -iV "you might" | grep -i "Broken" | awk '{print $2}')"
  if [[ -n "${broken_packages}" ]] || tail -n5 "${eus_dir}/logs/"* | grep -iq "Try 'sudo apt --fix-broken install' with no packages\\|Try 'apt --fix-broken install' with no packages"; then
    echo -e "${GRAY_R}#${RESET} Broken packages found: ${broken_packages}. Attempting to fix..." | tee -a "${eus_dir}/logs/broken-packages.log"
    if DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install --fix-broken &>> "${eus_dir}/logs/broken-packages.log"; then
      echo -e "${GREEN}#${RESET} Successfully fixed the broken packages! \\n" | tee -a "${eus_dir}/logs/broken-packages.log"
    else
      echo -e "${RED}#${RESET} Failed to fix the broken packages! \\n" | tee -a "${eus_dir}/logs/broken-packages.log"
    fi
    while read -r log_file; do
      sed -i 's/--fix-broken install/--fix-broken install (completed)/g' "${log_file}" &> /dev/null
    done < <(find "${eus_dir}/logs/" -maxdepth 1 -type f -exec grep -Eil "Try 'sudo apt --fix-broken install' with no packages|Try 'apt --fix-broken install' with no packages" {} \;)
  fi
}

mongo_command() {
  mongo_command_server_version="$("$(which dpkg)" -l | grep "^ii\\|^hi" | grep -E "(mongodb-server|mongodb-org-server|mongod-armv8|mongod-amd64)[[:space:]]" | awk '{print $3}' | sed -e 's/.*://' -e 's/-.*//' -e 's/+.*//' -e 's/\.//g')"
  if "$(which dpkg)" -l mongodb-mongosh-shared-openssl3 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui" && [[ "${mongo_command_server_version::2}" -ge "40" ]]; then
    mongocommand="mongosh"
    mongoprefix="EJSON.stringify( "
    mongosuffix=".toArray() )"
  elif "$(which dpkg)" -l mongodb-mongosh-shared-openssl11 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui" && [[ "${mongo_command_server_version::2}" -ge "40" ]]; then
    mongocommand="mongosh"
    mongoprefix="EJSON.stringify( "
    mongosuffix=".toArray() )"
  elif "$(which dpkg)" -l mongodb-mongosh 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui" && [[ "${mongo_command_server_version::2}" -ge "40" ]]; then
    mongocommand="mongosh"
    mongoprefix="EJSON.stringify( "
    mongosuffix=".toArray() )"
  elif "$(which dpkg)" -l mongosh 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui" && [[ "${mongo_command_server_version::2}" -ge "40" ]]; then
    mongocommand="mongosh"
    mongoprefix="EJSON.stringify( "
    mongosuffix=".toArray() )"
  else
    mongocommand="mongo"
    mongoprefix="JSON.stringify( "
    #mongosuffix=".forEach(printjson) )"
    mongosuffix=".toArray() )"
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

cleanup_multiple_default_lan_networks_js_script() {
  if [[ "${mongo_command_server_version::2}" -ge "40" ]]; then documents_variable="countDocuments"; else documents_variable="count"; fi
  eus_tmp_directory_check
  tee "${eus_tmp_directory_location}/${mongo_oldIdStr}.js" &>/dev/null <<EOF
// Define the old and new IDs
const oldIdStr = "${mongo_oldIdStr}"; // Old ID to replace
const newIdStr = "${mongo_newIdStr}"; // New ID to use

// Function to update a collection for fields only if they exist with verification
function updateFieldIfExists(collectionName, field, oldValue, newValue) {
    let collection = db.getCollection(collectionName);

    // Check for documents with the old value for the specified field
    let filterCondition = { [field]: oldValue };

    print(\`Checking for documents in \${collectionName} matching: \${JSON.stringify(filterCondition)}\`);

    // Perform the update for the specified field only if it exists
    let result = collection.updateMany(
        filterCondition,
        { \$set: { [field]: newValue } }
    );

    // Print the result of the update operation
    print(\`Updated \${result.modifiedCount} documents in \${collectionName} for field \${field}.\`);

    // Verify that the old ID has been removed
    let verificationCountOld = collection.${documents_variable}({ [field]: oldValue });
    let verificationCountNew = collection.${documents_variable}({ [field]: newValue });
    print(\`Verification in \${collectionName} for field \${field}: Found \${verificationCountOld} documents with old ID and \${verificationCountNew} documents with new ID.\`);
}

// Function to update nested fields within port_overrides with verification
function updateNestedFieldInPortOverrides(collectionName, field, oldValue, newValue) {
    let collection = db.getCollection(collectionName);

    // Only update if port_overrides exists and the field matches the old ID
    let result = collection.updateMany(
        {
            "port_overrides": { \$exists: true, \$ne: [] },
            [\`port_overrides.\${field}\`]: oldValue
        },
        { \$set: { [\`port_overrides.\$[elem].\${field}\`]: newValue } },
        { arrayFilters: [{ "elem.native_networkconf_id": oldIdStr }] } // Ensure it targets the correct elements
    );

    print(\`Updated \${field} in port_overrides of \${collectionName}: \${result.modifiedCount} documents modified.\`);

    // Verification step
    let verificationCountOld = collection.${documents_variable}({
        "port_overrides": { \$exists: true, \$ne: [] },
        [\`port_overrides.\${field}\`]: oldValue
    });
    let verificationCountNew = collection.${documents_variable}({
        "port_overrides": { \$exists: true, \$ne: [] },
        [\`port_overrides.\${field}\`]: newValue
    });
    print(\`Verification in \${collectionName} for port_overrides.\${field}: Found \${verificationCountOld} documents with old ID and \${verificationCountNew} documents with new ID.\`);
}

// Update the 'portconf' collection for native_networkconf_id
function updatePortconfNativeId() {
    let collection = db.portconf; // Access the 'portconf' collection
    updateFieldIfExists('portconf', 'native_networkconf_id', oldIdStr, newIdStr);
}

// Update portconf
updatePortconfNativeId();

// Update the 'device' collection for specific fields with verification
updateFieldIfExists("device", "last_connection_network_id", oldIdStr, newIdStr);
updateFieldIfExists("device", "mgmt_network_id", oldIdStr, newIdStr); // Ensure mgmt_network_id is updated if it exists

// Update native_networkconf_id within port_overrides in 'device'
updateNestedFieldInPortOverrides("device", "native_networkconf_id", oldIdStr, newIdStr);

// Function to update excluded_networkconf_ids in the specified collection with verification
function updateExcludedIds(collectionName) {
    let collection = db.getCollection(collectionName);

    // First, remove the old ID from excluded_networkconf_ids if it exists
    let pullResult = collection.updateMany(
        { "excluded_networkconf_ids": oldIdStr },
        { \$pull: { excluded_networkconf_ids: oldIdStr } }
    );
    print(\`Removed old network ID from excluded_networkconf_ids in \${collectionName}: \${pullResult.modifiedCount} documents modified.\`);

    // Now, update the old ID to the new ID if it exists
    let updateResult = collection.updateMany(
        { "excluded_networkconf_ids": { \$exists: true, \$ne: [] } },
        { \$set: { "excluded_networkconf_ids.\$[elem]": newIdStr } },
        { arrayFilters: [{ "elem": oldIdStr }] } // Only target elements that are the old ID
    );
    print(\`Updated old network ID to new ID in excluded_networkconf_ids in \${collectionName}: \${updateResult.modifiedCount} documents modified.\`);

    // Verification step
    let verificationCountOld = collection.${documents_variable}({ "excluded_networkconf_ids": oldIdStr });
    let verificationCountNew = collection.${documents_variable}({ "excluded_networkconf_ids": newIdStr });
    print(\`Verification in \${collectionName} for excluded_networkconf_ids: Found \${verificationCountOld} documents with old ID and \${verificationCountNew} documents with new ID.\`);
}

// Update excluded_networkconf_ids in the 'setting' collection
updateExcludedIds("setting");

// Update excluded_networkconf_ids in the 'portconf' collection
updateExcludedIds("portconf");

// Handle excluded_networkconf_ids within port_overrides in the 'device' collection with verification
function updateExcludedIdsInDevice() {
    let collection = db.getCollection("device");

    // Only attempt to remove the old ID if it exists in port_overrides
    let pullResult = collection.updateMany(
        {
            "port_overrides": { \$exists: true, \$ne: [] },
            "port_overrides.excluded_networkconf_ids": oldIdStr
        },
        { \$pull: { "port_overrides.\$[].excluded_networkconf_ids": oldIdStr } }
    );
    print(\`Removed old network ID from port_overrides.excluded_networkconf_ids in device collection: \${pullResult.modifiedCount} documents modified.\`);

    // Check for existence of excluded_networkconf_ids and update if the old ID was removed successfully
    let checkResult = collection.findOne(
        {
            "port_overrides": { \$exists: true, \$ne: [] },
            "port_overrides.excluded_networkconf_ids": { \$exists: true, \$ne: [] }
        }
    );

    if (checkResult) {
        // Now, update the old ID to the new ID in port_overrides if it exists
        let updateResult = collection.updateMany(
            {
                "port_overrides.excluded_networkconf_ids": oldIdStr
            },
            { \$set: { "port_overrides.\$[].excluded_networkconf_ids.\$[elem]": newIdStr } },
            { arrayFilters: [{ "elem": oldIdStr }] } // Only target elements that are the old ID
        );
        print(\`Updated old network ID to new ID in port_overrides.excluded_networkconf_ids in device collection: \${updateResult.modifiedCount} documents modified.\`);

        // Verification step
        let verificationCountOld = collection.${documents_variable}({
            "port_overrides": { \$exists: true, \$ne: [] },
            "port_overrides.excluded_networkconf_ids": oldIdStr
        });
        let verificationCountNew = collection.${documents_variable}({
            "port_overrides": { \$exists: true, \$ne: [] },
            "port_overrides.excluded_networkconf_ids": newIdStr
        });
        print(\`Verification in device collection for port_overrides.excluded_networkconf_ids: Found \${verificationCountOld} documents with old ID and \${verificationCountNew} documents with new ID.\`);
    } else {
        print(\`No documents found with excluded_networkconf_ids in port_overrides for device collection.\`);
    }
}

// Call the function to update excluded_networkconf_ids in the device collection
updateExcludedIdsInDevice();

// Function to remove dns_filters entries for a specific network_id with verification
function removeDnsFiltersByNetworkId() {
    let collection = db.getCollection("setting");

    // Remove entries from dns_filters where network_id matches oldIdStr
    let result = collection.updateMany(
        {},
        { \$pull: { dns_filters: { network_id: oldIdStr } } }
    );

    print(\`Removed dns_filters entries with network_id \${oldIdStr} in setting: \${result.modifiedCount} documents modified.\`);

    // Verification step
    let verificationCount = collection.${documents_variable}({ "dns_filters.network_id": oldIdStr });
    print(\`Verification in setting: Found \${verificationCount} documents still containing the old network_id.\`);
}

// Call the function to remove dns_filters entries
removeDnsFiltersByNetworkId();

// Function to remove newIdStr from excluded_networkconf_ids only if it's also native
function removeNewIdFromExcludedIdsIfNative() {
    let collection = db.getCollection("device");

    // Log documents that currently have newIdStr in excluded_networkconf_ids and matching native_networkconf_id
    let documentsBefore = collection.find({
        "port_overrides": { \$exists: true, \$ne: [] },
        "port_overrides.excluded_networkconf_ids": newIdStr,
        "port_overrides.native_networkconf_id": newIdStr
    }).toArray();

    print(\`Documents before removal containing newIdStr and native: \${documentsBefore.length}\`);
    documentsBefore.forEach(doc => {
        print(\`Document ID: \${doc._id}, Excluded IDs: \${JSON.stringify(doc.port_overrides)}\`);
    });

    // Remove newIdStr from excluded_networkconf_ids where it appears and matches the native_networkconf_id
    let result = collection.updateMany(
        {
            "port_overrides": { \$exists: true, \$ne: [] },
            "port_overrides.excluded_networkconf_ids": newIdStr,
            "port_overrides.native_networkconf_id": newIdStr
        },
        {
            \$pull: { "port_overrides.\$[].excluded_networkconf_ids": newIdStr }
        }
    );

    print(\`Removed new network ID from excluded_networkconf_ids in port_overrides of device collection: \${result.modifiedCount} documents modified.\`);

    // Verification step
    let verificationCountOld = collection.${documents_variable}({
        "port_overrides": { \$exists: true, \$ne: [] },
        "port_overrides.excluded_networkconf_ids": newIdStr,
        "port_overrides.native_networkconf_id": newIdStr
    });

    print(\`Verification in device collection for port_overrides.excluded_networkconf_ids: Found \${verificationCountOld} documents still containing newIdStr with native match.\`);

    // Log remaining documents
    let documentsAfter = collection.find({
        "port_overrides": { \$exists: true, \$ne: [] },
        "port_overrides.excluded_networkconf_ids": newIdStr,
        "port_overrides.native_networkconf_id": newIdStr
    }).toArray();

    print(\`Documents after removal containing newIdStr with native match: \${documentsAfter.length}\`);
    documentsAfter.forEach(doc => {
        print(\`Document ID: \${doc._id}, Excluded IDs: \${JSON.stringify(doc.port_overrides)}\`);
    });
}

// Call the revised function
removeNewIdFromExcludedIdsIfNative();
EOF
}

cleanup_multiple_default_lan_networks() {
  mongo_command
  get_unifi_api_ports
  get_unifi_application_status
  if [[ "${application_up}" != "true" ]]; then return; fi
  remove_duplicated_networkconf_id() { # Log removed network data and remove the ID from the UniFi Network Application database.
    if [[ "${cleanup_multiple_default_lan_networks_site_desc}" != "${previous_cleanup_multiple_default_lan_networks_site_desc}" ]]; then
      echo -e "${GRAY_R}#${RESET} Cleaning up multiple default networks on site ${cleanup_multiple_default_lan_networks_site_desc}..."
      previous_cleanup_multiple_default_lan_networks_site_desc="${cleanup_multiple_default_lan_networks_site_desc}"
      cleanup_multiple_default_lan_networks_site_desc_message_printed="true"
    fi
    removed_networkconf_data="$("${mongocommand}" --quiet --port 27117 ace --eval "${mongoprefix}db.getCollection('networkconf').find({ _id: ObjectId('${networkconf_id_remove}') })${mongosuffix}")"
    removed_networkconf_info="$("${mongocommand}" --quiet --port 27117 ace --eval "db.getCollection('networkconf').deleteMany({ _id: ObjectId('${networkconf_id_remove}') })")"
    echo -e "$(date +%F-%T.%6N) | networkconf data for ${networkconf_id_remove}: ${removed_networkconf_data}" &>> "${eus_dir}/logs/cleanup-multiple-default-lan-networks.log"
    echo -e "$(date +%F-%T.%6N) | networkconf ${networkconf_id_remove} removal results: ${removed_networkconf_info}" &>> "${eus_dir}/logs/cleanup-multiple-default-lan-networks.log"
    if [[ "${cleanup_multiple_default_lan_networks_site_desc_message_printed}" == 'true' ]]; then
      echo -e "${GREEN}#${RESET} Successfully cleaned up multiple default LAN networks for site ${cleanup_multiple_default_lan_networks_site_desc}! \\n"
      unset cleanup_multiple_default_lan_networks_site_desc_message_printed
    fi
  }
  check_fields() { # Check if any ID's match criteria
    local id="$1"
    json_output="$("${mongocommand}" --quiet --port 27117 ace --eval "${mongoprefix}db.getCollection('networkconf').find({'_id': ObjectId('""${id}""')})${mongosuffix}")"
    name="$(echo "${json_output}" | jq -r '.[0].name' | tr '[:upper:]' '[:lower:]')"
    ip_subnet="$(echo "${json_output}" | jq -r '.[0].ip_subnet' | tr '[:upper:]' '[:lower:]')"
    dhcpd_stop="$(echo "${json_output}" | jq -r '.[0].dhcpd_stop' | tr '[:upper:]' '[:lower:]')"
    dhcpd_start="$(echo "${json_output}" | jq -r '.[0].dhcpd_start' | tr '[:upper:]' '[:lower:]')"
    domain_name="$(echo "${json_output}" | jq -r '.[0].domain_name' | tr '[:upper:]' '[:lower:]')"
    if [[ "${name}" == "default" && "${ip_subnet}" == "192.168.1.1/24" && "${dhcpd_stop}" == "192.168.1.254" && "${dhcpd_start}" == "192.168.1.6" && "${domain_name}" == "localdomain" ]]; then
      return 0  # Match found
    else
      return 1  # No match
    fi
  }
  cleanup_epoch="$(date +%s)"
  eus_create_directories "data"
  eus_create_directories "data/multiple-default-lan-networks"
  "${mongocommand}" --quiet --port 27117 ace --eval "${mongoprefix}db.getCollection('networkconf').aggregate([{ \"\$match\": { \"attr_no_delete\": true, \"attr_hidden_id\": \"LAN\" } }, { \"\$group\": { \"_id\": \"\$site_id\", \"count\": { \"\$sum\": 1 }, \"ids\": { \"\$push\": \"\$_id\" } } }, { \"\$match\": { \"count\": { \"\$gte\": 2 } } }, { \"\$project\": { \"_id\": 0, \"site_id\": \"\$_id\", \"count\": 1, \"duplicate_ids\": \"\$ids\" } }])${mongosuffix}" 2> /dev/null | jq 'map({count: .count, site_id: .site_id, duplicate_ids: (.duplicate_ids | map(.["$oid"]))})' &> "${eus_dir}/data/multiple-default-lan-networks/${cleanup_epoch}-data.json"
  affected_sites_count="$(jq 'length' "${eus_dir}/data/multiple-default-lan-networks/${cleanup_epoch}-data.json")"
  if [[ -z "${affected_sites_count}" ]] || [[ "${affected_sites_count}" == 'null' ]]; then
    echo -e "$(date +%F-%T.%6N) | Variable affected_sites_count was \"${affected_sites_count}\", skipping..." &>> "${eus_dir}/logs/cleanup-multiple-default-lan-networks.log"
    return
  fi
  if [[ "${affected_sites_count}" == '0' ]]; then
    rm --force "${eus_dir}/data/multiple-default-lan-networks/${cleanup_epoch}-data.json" &> /dev/null
    if [[ "$(jq -r '.scripts."'"${script_name}"'".tasks | to_entries[]? | select(.key | startswith("cleanup-multiple-default-lan-networks")) | .value[]? | ."check-completed" // empty' "${eus_dir}/db/db.json" 2> /dev/null | tail -n1)" != 'true' ]]; then
      if [[ "$(dpkg-query --showformat='${version}' --show jq 2> /dev/null | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
        jq '.scripts."'"${script_name}"'" |= . + {"tasks": (.tasks + {"cleanup-multiple-default-lan-networks ('"${cleanup_epoch}"')":[{"check-completed":"true", "affected-sites":"'"${affected_sites_count}"'"}]})}' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
      else
        jq '.scripts["'"${script_name}"'"] |= (.tasks += {"cleanup-multiple-default-lan-networks ('"${cleanup_epoch}"')": [{"check-completed":"true", "affected-sites":"'"${affected_sites_count}"'"}]})' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
      fi
      eus_database_move
    fi
    return
  fi
  duplicate_resolve_cycles="0"
  until [[ "${duplicate_resolve_cycles}" == "${affected_sites_count}" ]]; do
    cleanup_multiple_default_lan_networks_site_id="$(jq -r ".[${duplicate_resolve_cycles}].site_id" "${eus_dir}/data/multiple-default-lan-networks/${cleanup_epoch}-data.json" 2> /dev/null)"
    cleanup_multiple_default_lan_networks_site_desc="$("${mongocommand}" --quiet --port 27117 ace --eval "${mongoprefix}db.getCollection('site').find({\"_id\":ObjectId('${cleanup_multiple_default_lan_networks_site_id}')})${mongosuffix}" 2> /dev/null | sed 's/\(ObjectId(\|)\|NumberLong(\)\|ISODate(//g' 2> /dev/null | jq -r '.[].desc' 2> /dev/null)"
    echo -e "${GRAY_R}#${RESET} Checking for multiple default LAN networks for site ${cleanup_multiple_default_lan_networks_site_desc}..."
    declare -A timestamp_map
    while read -r duplicated_id; do
      time_stamp="$("${mongocommand}" --quiet --port 27117 ace --eval 'Math.floor(ObjectId("'"${duplicated_id}"'").getTimestamp().getTime() / 1000)' 2> /dev/null)"
      timestamp_map["$time_stamp"]+="$duplicated_id "
    done < <(jq -r ".[${duplicate_resolve_cycles}].duplicate_ids[]" "${eus_dir}/data/multiple-default-lan-networks/${cleanup_epoch}-data.json")
    max_timestamp=""
    for ts in "${!timestamp_map[@]}"; do
      if [[ -z "$max_timestamp" || "$ts" -gt "$max_timestamp" ]]; then
        max_timestamp="$ts"
      fi
    done
    if [[ -n "${timestamp_map[$max_timestamp]}" ]]; then
      echo -e "${GREEN}#${RESET} Successfully found some duplicated default LAN networks for site ${cleanup_multiple_default_lan_networks_site_desc}! \\n"
      networkconf_ids_with_max_time="${timestamp_map[$max_timestamp]}"
      id_count="$(echo "$networkconf_ids_with_max_time" | wc -w)"
      networkconf_id_removed=()
      if [[ "${id_count}" -gt "1" ]]; then
        echo -e "$(date +%F-%T.%6N) | Multiple networkconf IDs found with the same timestamp (${max_timestamp}): ${networkconf_ids_with_max_time}" &>> "${eus_dir}/logs/cleanup-multiple-default-lan-networks.log"
        matching_ids=()
        any_match="false"
        for networkconf_id in $networkconf_ids_with_max_time; do
          if check_fields "${networkconf_id}"; then
            echo -e "$(date +%F-%T.%6N) | networkconf ID ${networkconf_id} matches the criteria." &>> "${eus_dir}/logs/cleanup-multiple-default-lan-networks.log"
            matching_ids+=("${networkconf_id}")
            any_match="true"
          fi
        done
        if [[ "${any_match}" == "true" ]]; then
          for matching_id in "${matching_ids[@]}"; do
            networkconf_id_remove="${matching_id//[[:space:]]/}"
            echo -e "$(date +%F-%T.%6N) | Processing networkconf ID ${networkconf_id_remove} for removal." &>> "${eus_dir}/logs/cleanup-multiple-default-lan-networks.log"
            remove_duplicated_networkconf_id "${networkconf_id_remove}"
            networkconf_id_removed+=("${networkconf_id_remove}")
          done
        else
          last_id="$(echo "$networkconf_ids_with_max_time" | awk '{print $NF}' | sed 's/[[:space:]]//g')"
          networkconf_id_remove="${last_id}"
          echo -e "$(date +%F-%T.%6N) | No networkconf IDs matched the criteria. Processing networkconf ID ${networkconf_id_remove} for removal." &>> "${eus_dir}/logs/cleanup-multiple-default-lan-networks.log"
          remove_duplicated_networkconf_id "${networkconf_id_remove}"
          networkconf_id_removed+=("${networkconf_id_remove}")
        fi
      else
        networkconf_id_remove="${networkconf_ids_with_max_time//[[:space:]]/}"
        echo -e "$(date +%F-%T.%6N) | Single networkconf ID returned, processing ${networkconf_id_remove} for removal" &>> "${eus_dir}/logs/cleanup-multiple-default-lan-networks.log"
        remove_duplicated_networkconf_id "${networkconf_id_remove}"
        networkconf_id_removed+=("${networkconf_id_remove}")
      fi
    else
      echo -e "${YELLOW}#${RESET} The script didn't detect and duplicated default LAN networks for site ${cleanup_multiple_default_lan_networks_site_desc}! \\n"
    fi
    ((duplicate_resolve_cycles=duplicate_resolve_cycles+1))
  done
  removed_ids="$(printf "%s\n" "${networkconf_id_removed[@]}")"
  all_ids="$(jq -r '.[].duplicate_ids[]' "${eus_dir}/data/multiple-default-lan-networks/${cleanup_epoch}-data.json")"
  left_over_id="$(grep -Fxv -f <(echo "${removed_ids}") <(echo "${all_ids}"))"
  for removed_id in "${networkconf_id_removed[@]}"; do
    echo -e "${GREEN}#${RESET} Updating references of ID ${removed_id} to ID ${left_over_id} on site ${cleanup_multiple_default_lan_networks_site_desc}..."
    mongo_oldIdStr="${removed_id}"
    mongo_newIdStr="${left_over_id}"
    cleanup_multiple_default_lan_networks_js_script
    echo -e "\\n\\n------- $(date +%F-%T.%6N) -------\\n\\n" &>> "${eus_dir}/logs/${mongo_oldIdStr}.js.log"
    if "${mongocommand}" --quiet --port 27117 ace < "${eus_tmp_directory_location}/${mongo_oldIdStr}.js" &>> "${eus_dir}/logs/${mongo_oldIdStr}.js.log"; then
      echo -e "${GREEN}#${RESET} Successfully updated references of ID ${removed_id} to ID ${left_over_id} on site ${cleanup_multiple_default_lan_networks_site_desc}! \\n"
    else
      echo -e "${RED}#${RESET} Failed to update references of ID ${removed_id} to ID ${left_over_id} on site ${cleanup_multiple_default_lan_networks_site_desc}... \\n"
    fi
  done
  echo -e "${GRAY_R}#${RESET} Restarting the UniFi Network Application..."
  if [[ "${limited_functionality}" == 'true' ]]; then
    if service unifi restart &>> "${eus_dir}/logs/cleanup-multiple-default-lan-networks.log"; then echo -e "${GREEN}#${RESET} Successfully restarted the UniFi Network Application! \\n"; else echo -e "${RED}#${RESET} Failed to restart the UniFi Network Application... \\n"; fi
  else
    if systemctl restart unifi &>> "${eus_dir}/logs/cleanup-multiple-default-lan-networks.log"; then echo -e "${GREEN}#${RESET} Successfully restarted the UniFi Network Application! \\n"; else echo -e "${RED}#${RESET} Failed to restart the UniFi Network Application... \\n"; fi
  fi
  if [[ "$(dpkg-query --showformat='${version}' --show jq 2> /dev/null | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
    jq '.scripts."'"${script_name}"'" |= . + {"tasks": (.tasks + {"cleanup-multiple-default-lan-networks ('"${cleanup_epoch}"')":[{"check-completed":"true", "affected-sites":"'"${affected_sites_count}"'"}]})}' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
  else
    jq '.scripts["'"${script_name}"'"] |= (.tasks += {"cleanup-multiple-default-lan-networks ('"${cleanup_epoch}"')": [{"check-completed":"true", "affected-sites":"'"${affected_sites_count}"'"}]})' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
  fi
  eus_database_move
}

# Add default repositories
check_default_repositories() {
  get_repo_url
  if [[ "${repo_codename}" =~ (precise|trusty|utopic|vivid|wily|yakkety|zesty|artful|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing) ]]; then
    if [[ "${repo_codename}" =~ (precise|trusty|utopic|vivid|wily|yakkety|zesty|artful|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish) ]]; then repo_component="main universe multiverse"; add_repositories; fi
    if [[ "${repo_codename}" =~ (jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing) ]]; then repo_component="main universe multiverse"; add_repositories; fi
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
      if DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_downgrade_option[@]}" "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install -f &>> "${eus_dir}/logs/attempt-recover-broken-packages.log"; then
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
          if DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "${dependency_to_install}" &>> "${eus_dir}/logs/unmet-dependency.log"; then
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
              run_apt_get_update
              if DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "${dependency_to_install}" &>> "${eus_dir}/logs/unmet-dependency.log"; then
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

if ! [[ "${os_codename}" =~ (precise|maya|trusty|utopic|vivid|wily|yakkety|zesty|artful|qiana|rebecca|rafaela|rosa|xenial|sarah|serena|sonya|sylvia|bionic|tara|tessa|tina|tricia|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing|wheezy|jessie|stretch|buster|bullseye|bookworm|trixie|forky|unstable) ]]; then
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
          mv "${cleanup_malformed_repositories_file_path}" "{eus_dir}/repository/$(basename "${cleanup_malformed_repositories_file_path}").corrupted" &>> "${eus_dir}/logs/cleanup-malformed-repository-lists.log"
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

run_apt_get_update() {
  eus_directory_location="/tmp/EUS"
  eus_create_directories "apt"
  if [[ "${run_with_apt_fix_missing}" == 'true' ]] || [[ -z "${afm_first_run}" ]]; then apt_fix_missing_option="--fix-missing"; afm_first_run="1"; unset run_with_apt_fix_missing; IFS=' ' read -r -a apt_fix_missing <<< "${apt_fix_missing_option}"; fi
  if [[ "${silent_run_apt_get_update}" != "true" ]]; then echo -e "${GRAY_R}#${RESET} Running apt-get update..."; fi
  echo -e "\\n------- $(date +%F-%T.%6N) -------\\n" &>> "${eus_dir}/logs/apt-update.log"
  if apt-get update "${apt_fix_missing[@]}" 2>&1 | tee -a "${eus_dir}/logs/apt-update.log" > /tmp/EUS/apt/apt-update.log; then
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
    apt-get update &> /tmp/EUS/apt/apt-update.log
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
  if [[ "${repository_changes_applied}" == 'true' ]]; then unset repository_changes_applied; run_apt_get_update; fi
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

get_mongodb_org_v() {
  mongodb_org_v="$("$(which dpkg)" -l | grep -E "(mongodb-server|mongodb-org-server|mongodb-10gen|mongod-armv8|mongod-amd64)[[:space:]]" | grep -i "^ii\\|^hi\\|^ri\\|^pi\\|^ui" | sed '/tool/d' | awk '{print $3}' | sed 's/\.//g' | sed 's/.*://' | sed 's/-.*//g' | sed 's/+.*//g' | sort -V | tail -n 1)"
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
  elif [[ "${os_codename}" =~ (xenial|sarah|serena|sonya|sylvia|loki) ]]; then
    mongod_codename="repo xenial"
  elif [[ "${os_codename}" =~ (bionic|tara|tessa|tina|tricia|hera|juno) ]]; then
    mongod_codename="repo bionic"
  elif [[ "${os_codename}" =~ (focal|groovy|hirsute|impish) ]]; then
    mongod_codename="repo focal"
  elif [[ "${os_codename}" =~ (jammy|kinetic|lunar|mantic) ]]; then
    mongod_codename="repo jammy"
  elif [[ "${os_codename}" =~ (noble|oracular) ]]; then
    mongod_codename="repo noble"
  elif [[ "${os_codename}" =~ (plucky|questing) ]]; then
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
        run_apt_get_update
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
  if [[ "${os_codename}" =~ (precise|trusty|utopic|vivid|wily|yakkety|zesty|artful|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing) ]]; then
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
      elif [[ "${os_codename}" =~ (xenial|sarah|serena|sonya|sylvia|bionic|tara|tessa|tina|tricia|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing|stretch|buster|bullseye|bookworm|trixie|forky|unstable) ]]; then
        mongodb_codename="ubuntu xenial"
        mongodb_repo_type="multiverse"
      elif [[ "${os_codename}" =~ (bionic|tara|tessa|tina|tricia|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing|bullseye|bookworm|trixie|forky|unstable) ]]; then
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
      elif [[ "${os_codename}" =~ (xenial|sarah|serena|sonya|sylvia|bionic|tara|tessa|tina|tricia|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing) ]]; then
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
      elif [[ "${os_codename}" =~ (bionic|tara|tessa|tina|tricia|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing|bullseye|bookworm|trixie|forky|unstable) ]]; then
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
      elif [[ "${os_codename}" =~ (bionic|tara|tessa|tina|tricia|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing) ]]; then
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
      if [[ "${os_codename}" =~ (stretch|buster|bullseye|bookworm|trixie|forky|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing) ]]; then
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
      elif [[ "${os_codename}" =~ (bionic|tara|tessa|tina|tricia|hera|juno|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing) ]]; then
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
      elif [[ "${os_codename}" =~ (buster|bullseye|bookworm|trixie|forky|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing) ]]; then
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
      elif [[ "${os_codename}" =~ (focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing) ]]; then
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
      if [[ "${os_codename}" =~ (stretch|buster|bullseye|bookworm|trixie|forky|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing) ]]; then
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
      elif [[ "${os_codename}" =~ (focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing) ]]; then
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
      if [[ "${os_codename}" =~ (stretch|buster|bullseye|bookworm|trixie|forky|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing) ]]; then
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
      elif [[ "${os_codename}" =~ (jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing) ]]; then
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
      elif [[ "${os_codename}" =~ (bookworm|trixie|forky|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing) ]]; then
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
      elif [[ "${os_codename}" =~ (jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing) ]]; then
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
      elif [[ "${os_codename}" =~ (trixie|forky|noble|oracular|plucky|questing) ]]; then
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
      elif [[ "${os_codename}" =~ (noble|oracular|plucky|questing) ]]; then
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
  if [[ "${try_http_mongodb_repo}" == 'true' ]]; then repo_http_https="http"; try_different_mongodb_repo_test="a HTTP instead of HTTPS"; try_different_mongodb_repo_test_2="HTTP "; else try_different_mongodb_repo_test="the"; try_different_mongodb_repo_test_2=""; fi
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
        run_apt_get_update
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

# Install needed packages if not installed
install_required_packages() {
  sleep 2
  installing_required_package="yes"
  header
  echo -e "${GRAY_R}#${RESET} Installing required packages for the script..\\n"
  run_apt_get_update
  sleep 2
}
apt_get_install_package() {
  if [[ "${old_openjdk_version}" == 'true' ]]; then
    apt_get_install_package_variable="update"; apt_get_install_package_variable_2="updated"
  else
    apt_get_install_package_variable="install"; apt_get_install_package_variable_2="installed"
  fi
  run_apt_get_update
  check_dpkg_lock
  echo -e "\\n------- ${required_package} installation ------- $(date +%F-%T.%6N) -------\\n" &>> "${eus_dir}/logs/apt.log"
  echo -e "${GRAY_R}#${RESET} Trying to ${apt_get_install_package_variable} ${required_package%%:*}..."
  if DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "${required_package}" 2>&1 | tee -a "${eus_dir}/logs/apt.log" > /tmp/EUS/apt/apt.log; then
    if [[ "${PIPESTATUS[0]}" -eq "0" ]]; then
      echo -e "${GREEN}#${RESET} Successfully ${apt_get_install_package_variable_2} ${required_package%%:*}! \\n"; sleep 2
    else
      echo -e "${RED}#${RESET} Failed to ${apt_get_install_package_variable} ${required_package%%:*}...\\n"
      check_unmet_dependencies
      broken_packages_check
      attempt_recover_broken_packages
      add_apt_option_no_install_recommends="true"; get_apt_options
      echo -e "${GRAY_R}#${RESET} Trying to ${apt_get_install_package_variable} ${required_package%%:*}..."
      if DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" "${apt_downgrade_option[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "${required_package}" 2>&1 | tee -a "${eus_dir}/logs/apt.log" > /tmp/EUS/apt/apt.log; then
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

unifi_required_packages() {
  if ! "$(which dpkg)" -l curl 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
    if [[ "${installing_required_package}" != 'yes' && "${mongodb_upgrade_unifi_remove}" != 'true' ]]; then
      install_required_packages
    fi
    check_dpkg_lock
    echo -e "${GRAY_R}#${RESET} Installing curl..."
    if ! DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install curl &>> "${eus_dir}/logs/required.log"; then
      echo -e "${RED}#${RESET} Failed to install curl in the first run...\\n"
      if [[ "${repo_codename}" =~ (precise|trusty|utopic|vivid|wily|yakkety|zesty|artful|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing) ]]; then
        if [[ "${repo_codename}" =~ (precise|trusty|utopic|vivid|wily|yakkety|zesty|artful|xenial|bionic|cosmic) ]]; then repo_codename_argument="-security"; repo_component="main"; fi
        if [[ "${repo_codename}" =~ (disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing) ]]; then repo_component="main"; fi
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
    set_curl_arguments
    get_repo_url
  fi
  if ! "$(which dpkg)" -l logrotate 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
    if [[ "${installing_required_package}" != 'yes' && "${mongodb_upgrade_unifi_remove}" != 'true' ]]; then
      install_required_packages
    fi
    check_dpkg_lock
    echo -e "${GRAY_R}#${RESET} Installing logrotate..."
    if ! DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install logrotate &>> "${eus_dir}/logs/required.log"; then
      echo -e "${RED}#${RESET} Failed to install logrotate in the first run...\\n"
      if [[ "${repo_codename}" =~ (precise|trusty|utopic|vivid|wily|yakkety|zesty|artful|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing) ]]; then
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
}
if ! "$(which dpkg)" -l jq 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
  if [[ "${installing_required_package}" != 'yes' ]]; then
    install_required_packages
  fi
  check_dpkg_lock
  echo -e "${GRAY_R}#${RESET} Installing jq..."
  if ! DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install jq &>> "${eus_dir}/logs/required.log"; then
    echo -e "${RED}#${RESET} Failed to install jq in the first run...\\n"
    if [[ "${repo_codename}" =~ (precise|trusty|utopic|vivid|wily|yakkety|zesty|artful|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing) ]]; then
      if [[ "${repo_codename}" =~ (bionic|cosmic|disco|eoan|focal|focal|groovy|hirsute|impish) ]]; then repo_component="main universe"; add_repositories; fi
      if [[ "${repo_codename}" =~ (jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing) ]]; then repo_component="main"; add_repositories; fi
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
fi
unifi_required_packages
if [[ "${unifi_core_system}" != 'true' ]]; then
  if ! "$(which dpkg)" -l dirmngr 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
    if [[ "${installing_required_package}" != 'yes' ]]; then
      install_required_packages
    fi
    check_dpkg_lock
    echo -e "${GRAY_R}#${RESET} Installing dirmngr..."
    if ! DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install dirmngr &>> "${eus_dir}/logs/required.log"; then
      echo -e "${RED}#${RESET} Failed to install dirmngr in the first run...\\n"
      if [[ "${repo_codename}" =~ (precise|trusty|utopic|vivid|wily|yakkety|zesty|artful|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing) ]]; then
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
fi
if "$(which dpkg)" -l apt 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
  apt_package_version="$(dpkg-query --showformat='${version}' --show apt 2> /dev/null | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)"
  if [[ "${apt_package_version::2}" -le "14" ]]; then 
    if ! "$(which dpkg)" -l apt-transport-https 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
      check_dpkg_lock
      if [[ "${installing_required_package}" != 'yes' ]]; then install_required_packages; fi
      echo -e "${GRAY_R}#${RESET} Installing apt-transport-https..."
      if ! DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install apt-transport-https &>> "${eus_dir}/logs/required.log"; then
        echo -e "${RED}#${RESET} Failed to install apt-transport-https in the first run...\\n"
        if [[ "${repo_codename}" =~ (precise|trusty|utopic|vivid|wily|yakkety|zesty|artful|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing) ]]; then
          if [[ "${repo_codename}" =~ (precise|trusty|utopic|vivid|wily|yakkety|zesty|artful|xenial) ]]; then repo_codename_argument="-security"; repo_component="main"; fi
          if [[ "${repo_codename}" =~ (bionic|cosmic) ]]; then repo_codename_argument="-security"; repo_component="main universe"; fi
          if [[ "${repo_codename}" =~ (disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing) ]]; then repo_component="main universe"; fi
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
if ! "$(which dpkg)" -l psmisc 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
  if [[ "${installing_required_package}" != 'yes' ]]; then
    install_required_packages
  fi
  check_dpkg_lock
  echo -e "${GRAY_R}#${RESET} Installing psmisc..."
  if ! DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install psmisc &>> "${eus_dir}/logs/required.log"; then
    echo -e "${RED}#${RESET} Failed to install psmisc in the first run...\\n"
    if [[ "${repo_codename}" =~ (precise|trusty|utopic|vivid|wily|yakkety|zesty|artful|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing) ]]; then
      if [[ "${repo_codename}" =~ (precise) ]]; then repo_codename_argument="-updates"; repo_component="main restricted"; fi
      if [[ "${repo_codename}" =~ (trusty|utopic|vivid|wily|yakkety|zesty|artful|xenial|bionic|cosmicdisco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing) ]]; then repo_component="universe"; fi
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
if ! "$(which dpkg)" -l lsb-release 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
  if [[ "${installing_required_package}" != 'yes' ]]; then
    install_required_packages
  fi
  check_dpkg_lock
  echo -e "${GRAY_R}#${RESET} Installing lsb-release..."
  if ! DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install lsb-release &>> "${eus_dir}/logs/required.log"; then
    echo -e "${RED}#${RESET} Failed to install lsb-release in the first run...\\n"
    if [[ "${repo_codename}" =~ (precise|trusty|utopic|vivid|wily|yakkety|zesty|artful|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing) ]]; then
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
if ! "$(which dpkg)" -l gnupg 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
  if [[ "${installing_required_package}" != 'yes' ]]; then install_required_packages; fi
  check_dpkg_lock
  echo -e "${GRAY_R}#${RESET} Installing gnupg..."
  if ! DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install gnupg &>> "${eus_dir}/logs/required.log"; then
    echo -e "${RED}#${RESET} Failed to install gnupg in the first run...\\n"
    if [[ "${repo_codename}" =~ (precise|trusty|utopic|vivid|wily|yakkety|zesty|artful|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing) ]]; then
      if [[ "${repo_codename}" =~ (precise|trusty|utopic|vivid|wily|yakkety|zesty|artful|xenial) ]]; then repo_codename_argument="-security"; repo_component="main"; fi
      if [[ "${repo_codename}" =~ (bionic|cosmic) ]]; then repo_codename_argument="-security"; repo_component="main universe"; fi
      if [[ "${repo_codename}" =~ (disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing) ]]; then repo_component="main universe"; fi
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
    if [[ "${#reinstall_gnupg_segfault_packages[@]}" -gt '0' ]]; then echo -e "\\n------- $(date +%F-%T.%6N) -------\\n" &>> "${eus_dir}/logs/gnupg-segfault-reinstall.log"; DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install --reinstall "${reinstall_gnupg_segfault_packages[@]}" &>> "${eus_dir}/logs/gnupg-segfault-reinstall.log"; fi
  fi
fi
if ! "$(which dpkg)" -l perl 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
  if [[ "${installing_required_package}" != 'yes' ]]; then
    install_required_packages
  fi
  check_dpkg_lock
  echo -e "${GRAY_R}#${RESET} Installing perl..."
  if ! DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install perl &>> "${eus_dir}/logs/required.log"; then
    echo -e "${RED}#${RESET} Failed to install perl in the first run...\\n"
    if [[ "${repo_codename}" =~ (precise|trusty|utopic|vivid|wily|yakkety|zesty|artful|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing) ]]; then
      if [[ "${repo_codename}" =~ (precise|trusty|utopic|vivid|wily|yakkety|zesty|artful|xenial|bionic|cosmic) ]]; then repo_codename_argument="-security"; repo_component="main"; fi
      if [[ "${repo_codename}" =~ (disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing) ]]; then repo_component="main"; fi
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
if ! "$(which dpkg)" -l adduser 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
  if [[ "${installing_required_package}" != 'yes' ]]; then
    install_required_packages
  fi
  check_dpkg_lock
  echo -e "${GRAY_R}#${RESET} Installing adduser..."
  if ! DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install adduser &>> "${eus_dir}/logs/required.log"; then
    echo -e "${RED}#${RESET} Failed to install adduser in the first run...\\n"
    if [[ "${repo_codename}" =~ (precise|trusty|utopic|vivid|wily|yakkety|zesty|artful|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing) ]]; then
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
if ! "$(which dpkg)" -l procps 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
  if [[ "${installing_required_package}" != 'yes' ]]; then
    install_required_packages
  fi
  check_dpkg_lock
  echo -e "${GRAY_R}#${RESET} Installing procps..."
  if ! DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install procps &>> "${eus_dir}/logs/required.log"; then
    echo -e "${RED}#${RESET} Failed to install procps in the first run...\\n"
    if [[ "${repo_codename}" =~ (precise|trusty|utopic|vivid|wily|yakkety|zesty|artful|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing) ]]; then
      if [[ "${repo_codename}" =~ (precise|trusty|utopic|vivid|wily|yakkety|zesty|artful|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing) ]]; then repo_codename_argument="-security"; repo_component="main"; fi
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
repackage_deb_file_required_package() {
  if ! "$(which dpkg)" -l zstd 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
    check_dpkg_lock
    echo -e "${GRAY_R}#${RESET} Installing zstd..."
    if ! DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install zstd &>> "${eus_dir}/logs/required.log"; then
      echo -e "${RED}#${RESET} Failed to install zstd in the first run...\\n"
      if [[ "${repo_codename}" =~ (precise|trusty|utopic|vivid|wily|yakkety|zesty|artful|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish) ]]; then
        repo_codename_argument="-security"
        repo_component="main"
      elif [[ "${repo_codename}" =~ (jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing) ]]; then
        repo_component="main"
      elif [[ "${repo_codename}" =~ (wheezy|jessie|stretch|buster|bullseye|bookworm|trixie|forky|unstable) ]]; then
        repo_component="main"
      fi
      add_repositories
      required_package="zstd"
      apt_get_install_package
    else
      echo -e "${GREEN}#${RESET} Successfully installed zstd! \\n" && sleep 2
    fi
  fi
  if ! "$(which dpkg)" -l binutils 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
    check_dpkg_lock
    echo -e "${GRAY_R}#${RESET} Installing binutils..."
    if ! DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install binutils &>> "${eus_dir}/logs/required.log"; then
      echo -e "${RED}#${RESET} Failed to install binutils in the first run...\\n"
      if [[ "${repo_codename}" =~ (precise|trusty|utopic|vivid|wily|yakkety|zesty|artful|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing) ]]; then
        repo_codename_argument="-security"
        repo_component="main"
      elif [[ "${repo_codename}" =~ (wheezy|jessie|stretch|buster|bullseye|bookworm|trixie|forky|unstable) ]]; then
        repo_component="main"
      fi
      add_repositories
      required_package="binutils"
      apt_get_install_package
    else
      echo -e "${GREEN}#${RESET} Successfully installed binutils! \\n" && sleep 2
    fi
  fi
}

remove_older_mongodb_repositories() {
  echo -e "${GRAY_R}#${RESET} Checking for older MongoDB repository entries..."
  local found_entries="false"
  if [[ "${abort_mongodb_remove_older_mongodb_repositories}" == "true" ]]; then cp -r /etc/apt/sources.list* "/tmp/EUS/repositories/${mongodb_upgrade_date}" &> /dev/null; fi
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
    if ! DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_downgrade_option[@]}" "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "${multiple_attempt_to_install_package_name}""${multiple_attempt_to_install_package_version_with_equal_sign}" &>> "${eus_dir}/logs/${multiple_attempt_to_install_package_log}.log"; then
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
        if ! DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_downgrade_option[@]}" "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "${repackage_deb_file_location}" &>> "${eus_dir}/logs/${multiple_attempt_to_install_package_log}.log"; then
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

##########################################################################################################################################################################
#                                                                                                                                                                        #
#                                                                       UniFi Ignore Dependencies                                                                        #
#                                                                                                                                                                        #
##########################################################################################################################################################################

java_required_variables() {
  if [[ "${first_digit_unifi}" -gt '9' ]] || [[ "${first_digit_unifi}" == '9' && "${second_digit_unifi}" -ge "0" ]]; then
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

ignore_unifi_package_dependencies() {
  if [[ -z "${required_java_version}" ]]; then
    if [[ -z "${first_digit_unifi}" && -n "${first_digit_current_unifi}" ]]; then first_digit_unifi="${first_digit_current_unifi}"; unifi_version_modified="true"; fi
    if [[ -z "${second_digit_unifi}" && -n "${second_digit_current_unifi}" ]]; then second_digit_unifi="${second_digit_current_unifi}"; unifi_version_modified="true"; fi
    if [[ -z "${third_digit_unifi}" && -n "${third_digit_current_unifi}" ]]; then third_digit_unifi="${third_digit_current_unifi}"; unifi_version_modified="true"; fi
    java_required_variables
    if [[ "${unifi_version_modified}" == 'true' ]]; then get_unifi_version; fi
  fi
  if [[ -f "/tmp/EUS/ignore-depends" ]]; then rm --force /tmp/EUS/ignore-depends &> /dev/null; fi
  if ! "$(which dpkg)" -l | grep "^ii\\|^hi" | grep -Eiq "(mongodb-server|mongodb-org-server|mongod-armv8|mongod-amd64)[[:space:]]"; then echo -e "mongodb-server" &>> /tmp/EUS/ignore-depends; fi
  if "$(which dpkg)" -l | grep "^ii\\|^hi" | grep -Eiq "(mongodb-server|mongodb-org-server|mongod-armv8|mongod-amd64)[[:space:]]"; then echo -e "mongodb-server" &>> /tmp/EUS/ignore-depends; fi
  if [[ "${first_digit_unifi}" -lt '8' ]]; then
    if ! "$(which dpkg)" -l | grep "^ii\\|^hi" | grep -iq "${required_java_version}-jre-headless"; then echo -e "${required_java_version}-jre-headless" &>> /tmp/EUS/ignore-depends; fi
  fi
  if [[ -f /tmp/EUS/ignore-depends && -s /tmp/EUS/ignore-depends ]]; then IFS=" " read -r -a ignored_depends <<< "$(tr '\r\n' ',' < /tmp/EUS/ignore-depends | sed 's/.$//')"; rm --force /tmp/EUS/ignore-depends &> /dev/null; dpkg_ignore_depends_flag="--ignore-depends=${ignored_depends[*]}"; fi
}

##########################################################################################################################################################################
#                                                                                                                                                                        #
#                                                                     UniFi deb Package modification                                                                     #
#                                                                                                                                                                        #
##########################################################################################################################################################################

unifi_deb_package_modification() {
  if "$(which dpkg)" -l | grep "^ii\\|^hi" | grep -iq "temurin-${required_java_version_short}-jdk"; then
    temurin_type="jdk"
    custom_unifi_deb_file_required="true"
  elif "$(which dpkg)" -l | grep "^ii\\|^hi" | grep -iq "temurin-${required_java_version_short}-jre"; then
    temurin_type="jre"
    if [[ "${first_digit_unifi}" -lt '8' ]]; then
      custom_unifi_deb_file_required="true"
    elif [[ "${first_digit_unifi}" -ge '8' ]]; then
      custom_unifi_deb_file_required="false"
    fi
  fi
  if "$(which dpkg)" -l | grep "^ii\\|^hi" | grep -qi "${required_java_version}" | grep -v "openjdk-${required_java_version_short}-jre-headless\\|temurin-${required_java_version_short}-jre\\|temurin-${required_java_version_short}-jdk"; then
    non_default_java_package="$("$(which dpkg)" -l | grep "^ii\\|^hi" | grep -i "${required_java_version}" | grep -v "openjdk-${required_java_version_short}-jre-headless\\|temurin-${required_java_version_short}-jre\\|temurin-${required_java_version_short}-jdk" | awk '{print $2}' | head -n1)"
    if ! "$(which dpkg)" -l | grep "^ii\\|^hi" | grep -ioq "openjdk-${required_java_version_short}-jre-headless\\|temurin-${required_java_version_short}-jre\\|temurin-${required_java_version_short}-jdk" && [[ -z "${non_default_java_package}" ]]; then custom_unifi_deb_file_required="true"; fi
  fi
  if "$(which dpkg)" -l | grep "^ii\\|^hi" | grep -iq "${gr_mongod_name}"; then
    unifi_deb_package_modification_mongodb_package="${gr_mongod_name}"
    custom_unifi_deb_file_required="true"
    prevent_mongodb_org_server_install
  fi
  if [[ "${custom_unifi_deb_file_required}" == 'true' ]]; then
    if [[ "$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/locate-network-release?status" 2> /dev/null | jq -r '.availability' 2> /dev/null)" == "OK" ]]; then download_pre_build_deb_available="true"; fi
    if [[ -n "${unifi_deb_package_modification_mongodb_package}" && -n "${temurin_type}" ]]; then
      unifi_deb_package_modification_message_1="temurin-${required_java_version_short}-${temurin_type} and ${unifi_deb_package_modification_mongodb_package}"
      if [[ "${download_pre_build_deb_available}" == 'true' ]]; then
        pre_build_fw_update_dl_link="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/locate-network-release?mongodb=${unifi_deb_package_modification_mongodb_package}&java=temurin-${required_java_version_short}-${temurin_type}&unifi-version=${first_digit_unifi}.${second_digit_unifi}.${third_digit_unifi}" | jq -r '."download_link"' | sed '/null/d' 2> "${eus_dir}/logs/locate-download.log")"
        pre_build_fw_update_dl_link_sha256sum="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/locate-network-release?mongodb=${unifi_deb_package_modification_mongodb_package}&java=temurin-${required_java_version_short}-${temurin_type}&unifi-version=${first_digit_unifi}.${second_digit_unifi}.${third_digit_unifi}" | jq -r '.sha256sum' | sed '/null/d' 2> "${eus_dir}/logs/locate-download.log")"
      fi
    elif [[ -n "${temurin_type}" ]]; then
      unifi_deb_package_modification_message_1="temurin-${required_java_version_short}-${temurin_type}"
      if [[ "${download_pre_build_deb_available}" == 'true' ]]; then
        pre_build_fw_update_dl_link="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/locate-network-release?java=temurin-${required_java_version_short}-${temurin_type}&unifi-version=${first_digit_unifi}.${second_digit_unifi}.${third_digit_unifi}" | jq -r '."download_link"' | sed '/null/d' 2> "${eus_dir}/logs/locate-download.log")"
        pre_build_fw_update_dl_link_sha256sum="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/locate-network-release?java=temurin-${required_java_version_short}-${temurin_type}&unifi-version=${first_digit_unifi}.${second_digit_unifi}.${third_digit_unifi}" | jq -r '.sha256sum' | sed '/null/d' 2> "${eus_dir}/logs/locate-download.log")"
      fi
    elif [[ -n "${unifi_deb_package_modification_mongodb_package}" ]]; then
      unifi_deb_package_modification_message_1="${unifi_deb_package_modification_mongodb_package}"
      if [[ "${download_pre_build_deb_available}" == 'true' ]]; then
        pre_build_fw_update_dl_link="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/locate-network-release?mongodb=${unifi_deb_package_modification_mongodb_package}&unifi-version=${first_digit_unifi}.${second_digit_unifi}.${third_digit_unifi}" | jq -r '."download_link"' | sed '/null/d' 2> "${eus_dir}/logs/locate-download.log")"
        pre_build_fw_update_dl_link_sha256sum="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/locate-network-release?mongodb=${unifi_deb_package_modification_mongodb_package}&unifi-version=${first_digit_unifi}.${second_digit_unifi}.${third_digit_unifi}" | jq -r '.sha256sum' | sed '/null/d' 2> "${eus_dir}/logs/locate-download.log")"
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
      if [[ "${pre_build_download_failure}" != 'false' ]]; then echo -e "${RED}#${RESET} Failed to download UniFi Network Application version ${first_digit_unifi}.${second_digit_unifi}.${third_digit_unifi} built for ${unifi_deb_package_modification_message_1}! \\n${RED}#${RESET} The script will attempt to built it locally... \\n"; fi
      eus_temp_dir="$(mktemp -d --tmpdir="${eus_dir}" unifi.deb.XXX)"
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

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                    Network Application Tasks                                                                                    #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

stop_network_application() {
  echo -e "${GRAY_R}#${RESET} Stopping the Network Application..."
  if [[ "${limited_functionality}" == 'true' ]]; then
    if service unifi stop &>> "${eus_dir}/logs/mongodb-repair-task.log"; then echo -e "${GREEN}#${RESET} Successfully stopped the Network Application! \\n"; else echo -e "${RED}#${RESET} Failed to stop the Network Application... \\n"; fi
  else
    if systemctl stop unifi &>> "${eus_dir}/logs/mongodb-repair-task.log"; then echo -e "${GREEN}#${RESET} Successfully stopped the Network Application! \\n"; else echo -e "${RED}#${RESET} Failed to stop the Network Application... \\n"; fi
  fi
  if [[ -n "$(pgrep [m]ongod)" ]]; then
    echo -e "${GREEN}#${RESET} There are still some services using MongoDB...\\n"
    if kill "$(pgrep [m]ongod)" &> "${eus_dir}/logs/mongodb-repair-task.log"; then
      echo -e "${GREEN}#${RESET} Successfully killed the MongoDB process! \\n"
    else
      echo -e "${RED}#${RESET} Failed to kill MongoDB process! \\n"
    fi
  fi
}

start_network_application() {
  echo -e "${GRAY_R}#${RESET} Starting the Network Application..."
  if [[ "${limited_functionality}" == 'true' ]]; then
    if service unifi stop &>> "${eus_dir}/logs/mongodb-repair-task.log"; then echo -e "${GREEN}#${RESET} Successfully started the Network Application! \\n"; else echo -e "${RED}#${RESET} Failed to start the Network Application... \\n"; fi
  else
    if systemctl stop unifi &>> "${eus_dir}/logs/mongodb-repair-task.log"; then echo -e "${GREEN}#${RESET} Successfully started the Network Application! \\n"; else echo -e "${RED}#${RESET} Failed to start the Network Application... \\n"; fi
  fi
}

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                          MongoDB Tasks                                                                                          #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

# Removes unsupported options
mongodb_upgrade_system_propties() {
  unifi_data_directory="$(readlink -f /usr/lib/unifi/data)"
  system_properties="${unifi_data_directory}/system.properties"
  cp "${unifi_data_directory}/system.properties" "${unifi_data_directory}/system.properties.mongodb-upgrade-${mongodb_upgrade_date}" &>> "${eus_dir}/logs/system-properties.log"
  values_to_clear=( "--journalOptions" "--nssize" "--noprealloc" "--quota" "--quotaFiles" "--smallfiles" "--repairpath" "--replIndexPrefetch" )
  while IFS= read -r sp_line; do
    if [[ "${sp_line}" == unifi.db.extraargs=* ]]; then
      sp_args="${sp_line#unifi.db.extraargs=}"
      # shellcheck disable=SC2001
      for value in "${values_to_clear[@]}"; do sp_args="$(echo "${sp_args}" | sed "s/${value}[^ ]*//g")"; done
      # shellcheck disable=SC2001
      sp_args="$(echo "${sp_args}" | sed 's/--[a-zA-Z]*=[^ ]*//g')"
      sp_args="$(echo "${sp_args}" | xargs)"
      if [[ -z "${sp_args}" ]]; then continue; fi
      # shellcheck disable=SC2001
      sp_args="$(echo "${sp_args}" | sed 's/=/\\=/g')"
      sp_line="unifi.db.extraargs=${sp_args}"
    fi
    echo "${sp_line}"
  done < "${system_properties}" > "${system_properties}.tmp"
  mv "${system_properties}.tmp" "${system_properties}" &>> "${eus_dir}/logs/system-properties.log"
  sed -i '/^#.*unifi.db.nojournal/! s/^unifi.db.nojournal/# &/' "${system_properties}" &>> "${eus_dir}/logs/system-properties.log"
  if [[ -e "${unifi_data_directory}/system.properties.mongodb-upgrade-${mongodb_upgrade_date}" ]]; then
    if [[ "$(md5sum "${unifi_data_directory}/system.properties.mongodb-upgrade-${mongodb_upgrade_date}" | awk '{print $1}')" != "$(md5sum "${system_properties}" | awk '{print $1}')" ]]; then
      echo -e "$(date +%F-%T.%6N) | system.properties file was adjusted!" &>> "${eus_dir}/logs/system-properties.log"
      if [[ "$(command -v diff)" ]]; then echo -e "$(date +%F-%T.%6N) | difference between \"${unifi_data_directory}/system.properties.mongodb-upgrade-${mongodb_upgrade_date}\" and \"${system_properties}\"..." &>> "${eus_dir}/logs/system-properties.log"; diff "${unifi_data_directory}/system.properties.mongodb-upgrade-${mongodb_upgrade_date}" "${system_properties}" &>> "${eus_dir}/logs/system-properties.log"; fi
    fi
  fi
  chown -R "${unifi_database_location_user}":"${unifi_database_location_group}" "${system_properties}" "${unifi_data_directory}/system.properties.mongodb-upgrade-${mongodb_upgrade_date}" &>> "${eus_dir}/logs/system-properties.log"
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
      if [[ "${current_unifi_database_pid_stop_attempt_round}" -ge "10" ]]; then ps axjf &> "/tmp/EUS/start-unifi-process-tree"; abort_reason="Unable to shutdown the UniFi Network database used by another process... Please reach out to Glenn R."; abort; fi
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
      if [[ "${mongo_wait_initilize}" -ge '20' ]]; then abort_reason="MongoDB did not respond within the set time frame... Please reach out to Glenn R."; if [[ "${start_unifi_database_task}" == 'import' ]]; then unifi_database_move_sucess="true"; mongodb_upgrade_import_failure="true"; shutdown_mongodb; fi; abort; fi
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

repair_unifi_database() {
  echo -e "${GRAY_R}#${RESET} Attempting to repair the UniFi Network Application database..."
  if [[ "${mongodb_upgrade_started_success_value}" == 'true' ]]; then shutdown_mongodb; else stop_network_application; fi
  repair_unifi_database_journal="$(find "${unifi_database_location}" -name "journal" -type d | head -n1)"
  if [[ -d "${repair_unifi_database_journal}" && -n "${repair_unifi_database_journal}" ]]; then
    echo -e "${GRAY_R}#${RESET} Moving the database journal files to \"${repair_unifi_database_journal}-$(date +%Y%m%d_%H%M_%S%N)\"..."
    if mv -vi "${repair_unifi_database_journal}" "${repair_unifi_database_journal}-$(date +%Y%m%d_%H%M_%S%N)" &>> "${eus_dir}/logs/unifi-database-repair-move.log"; then
      echo -e "${GREEN}#${RESET} Successfully moved the database journal files to \"${repair_unifi_database_journal}-$(date +%Y%m%d_%H%M_%S%N)\"! \\n"
    else
      echo -e "${GREEN}#${RESET} Failed to move the database journal files to \"${repair_unifi_database_journal}-$(date +%Y%m%d_%H%M_%S%N)\"...\\n"
    fi
  fi
  echo -e "${GRAY_R}#${RESET} Repairing the UniFi Network Application database..."
  if "$(which mongod)" --dbpath "${unifi_database_location}" --logpath "${eus_dir}/logs/unifi-database-repair.log" --repair &>> "${eus_dir}/logs/unifi-database-repair-command.log"; then
    echo -e "${GREEN}#${RESET} Successfully repaired the UniFi Network Application database! \\n"
  else
    echo -e "${GREEN}#${RESET} Failed to repair the UniFi Network Application database...\\n"
  fi
  chown -R "${unifi_database_location_user}":"${unifi_database_location_group}" "${unifi_database_location}" &> /dev/null
  chown -R "${unifi_database_location_user}":"${unifi_database_location_group}" "${unifi_logs_location}" &> /dev/null
  sleep 3
  if [[ "${mongodb_upgrade_started_success_value}" == 'true' ]]; then start_unifi_database; else start_network_application; fi
}

mongodb_upgrade_space_check() {
  mongodb_upgrade_method="regular"
  free_space_kilobyte="$(df -k "${eus_dir}/" | awk '{print $4}' | tail -n1)"
  unifi_database_size_kilobyte="$(du -s "${unifi_database_location}" | awk '{print $1}')"
  if [[ "${free_space_kilobyte}" -lt "$((unifi_database_size_kilobyte*10/100 + unifi_database_size_kilobyte + unifi_database_size_kilobyte))" ]]; then
    if [[ "${unifi_database_location}" != "/usr/lib/unifi/data/db" ]] && [[ "${unifi_database_location}" != "/var/lib/unifi/db" ]]; then
      unifi_db_eus_dir="$(dirname "${unifi_database_location}")"
      free_space_kilobyte="$(df -k "${unifi_db_eus_dir}/" | awk '{print $4}' | tail -n1)"
      unifi_database_size_kilobyte="$(du -s "${unifi_database_location}" | awk '{print $1}')"
    fi
    if [[ "${free_space_kilobyte}" -lt "$((unifi_database_size_kilobyte*10/100 + unifi_database_size_kilobyte + unifi_database_size_kilobyte))" ]]; then
      header_red
      echo -e "${GRAY_R}#${RESET} Your UniFi Network Application database is $(du -sh "${unifi_database_location}" | awk '{print $1}') in size and you have $(df -H "${eus_dir}/" | awk '{print $4}' | tail -n1) of available space..."
      echo -e "${GRAY_R}#${RESET} The MongoDB Upgrade might fail due to not having enough space to export/import the database...\\n"
      if [[ "$(find "$(readlink -f /usr/lib/unifi/data/backup/autobackup/)" -maxdepth 1 -type f -name "*.unf" | wc -l)" -gt '5' ]] && [[ "${cleanup_backup_files_during_mongodb_upgrade_complete}" != 'true' ]]; then
        cleanup_backup_files_during_mongodb_upgrade="true"
        cleanup_backup_files_dir="$(readlink -f /usr/lib/unifi/data/backup/autobackup/)"
        cleanup_backup_files
        if [[ "${cleanup_backup_files_during_mongodb_upgrade_complete}" == 'true' ]]; then mongodb_upgrade_space_check; return; fi
      fi
      echo -e "${GRAY_R}#${RESET} How would you like to proceed with the MongoDB upgrade process?\\n"
      echo -e "\\n${GRAY_R}---${RESET}\\n"
      echo -e " [   ${WHITE_R}1 ${RESET}   ]  |  Regular method, with a higher chance of failure due to low disk space."
      echo -e " [   ${WHITE_R}2 ${RESET}   ]  |  No statistics method, with a lower chance of failure."
      echo -e " [   ${WHITE_R}3 ${RESET}   ]  |  I want to free up disk space before attempting again."
      echo -e "\\n"
      read -rp $'Your choice | \033[39m' choice
      case "$choice" in
         1) migrate_unifi_database_without_stats="false";;
         2) migrate_unifi_database_without_stats="true"; mongodb_upgrade_method="no statistics"; migrate_unifi_database_without_stats_message_1=", without statistics";;
         3) echo -e "${YELLOW}#${RESET} OK... Please free up disk space before running the MongoDB Upgrade again..."; cancel_script;;
	     *) header_red; echo -e "${GRAY_R}#${RESET} Option ${choice} is not a valid..."; sleep 3; mongodb_upgrade_space_check;;
      esac
    fi
  fi
  jq '.scripts["'"$script_name"'"].tasks += {"mongodb-upgrade ('"${mongodb_upgrade_date}"')": [.scripts["'"$script_name"'"].tasks["mongodb-upgrade ('"${mongodb_upgrade_date}"')"][0] + {"method":"'"${mongodb_upgrade_method}"'","free disk space":"'"${free_space_kilobyte}"'","database size":"'"${unifi_database_size_kilobyte}"'","unifi_db_eus_dir":"'"${unifi_db_eus_dir}"'"}]}' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
  eus_database_move
}

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                           JAVA Checks                                                                                           #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

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
    run_apt_get_update
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
  elif [[ "${repo_codename}" =~ (disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing) ]]; then
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
    if ! DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install -t jessie-backports "${required_java_version}-jre-headless" &>> "${eus_dir}/logs/apt.log" || [[ "${old_openjdk_version}" == 'true' ]]; then
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
        if DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install -t jessie-backports "${required_java_version}-jre-headless" &>> "${eus_dir}/logs/apt.log"; then echo -e "${GREEN}#${RESET} Successfully installed ${required_package}! \\n" && sleep 2; else abort_reason="Failed to install ${required_package}."; abort; fi
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

unifi_dependencies_check() {
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
        if [[ "${repo_codename}" =~ (precise|trusty|utopic|vivid|wily|yakkety|zesty|artful|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing) ]]; then
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
  get_unifi_version
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
              if DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' remove "${java_package}" &>> "${eus_dir}/logs/java-uninstall.log"; then
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
    run_apt_get_update
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
      if DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg6::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' remove "temurin-${required_java_version_short}-jdk" &>> "${eus_dir}/logs/temurin-jdk-remove.log"; then
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
      if DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_downgrade_option[@]}" "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "$libssl_temp" &>> "${eus_dir}/logs/libssl.log"; then
        echo -e "${GREEN}#${RESET} Successfully installed libssl! \\n"
        libssl_install_success="true"
        break
      else
        check_unmet_dependencies
        broken_packages_check
        attempt_recover_broken_packages
        add_apt_option_no_install_recommends="true"; get_apt_options
        check_dpkg_lock
        if DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_downgrade_option[@]}" "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "$libssl_temp" &>> "${eus_dir}/logs/libssl.log"; then
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
    if [[ "${mongodb_org_upgrade_from_version::2}" -ge "36" && "${mongodb_package_requirement_check}" == 'true' ]]; then
      required_libssl_version="libssl1.1"
      unset mongodb_package_requirement_check
    elif [[ "${mongo_version_max}" =~ (70|80) && -n "${mongo_version_max}" ]]; then
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
            repo_url="${http_or_https}://security.ubuntu.com/ubuntu"
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
        run_apt_get_update
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
        run_apt_get_update
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

required_mongo_packages_missing() {
  echo -e "\\n${RED}----${RESET}\\n"
  echo -e "${GRAY_R}#${RESET} Required MongoDB packages failed to install... multiple script options will fail to run..."
  while true; do
    if [[ "${script_option_skip}" != 'true' ]]; then read -rp $'\033[39m#\033[0m Do you want to continue the script? (y/N) ' yes_no; fi
    case "$yes_no" in
        [Yy]*) break;;
        [Nn]*|"") abort_reason="Required MongoDB Packages failed to install, does not want to continue with script."; abort_function_skip_reason="true"; abort; break;;
        *) echo -e "\\n${RED}#${RESET} Invalid input, please answer Yes or No (y/n)...\\n"; sleep 3;;
    esac
  done
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
        if DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "$mongo_last_attempt_temp" &>> "${eus_dir}/logs/unifi-database-required.log"; then
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
    multiple_attempt_to_install_package_log="unifi-easy-update-script-required"
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
    if [[ -z "$(mongosh --version 2> /dev/null)" ]]; then
      while read -r mongosh_package; do
        echo -e "\\n------- $(date +%F-%T.%6N) -------\\n" &>> "${eus_dir}/logs/mongosh-corruption.log"
        check_dpkg_lock
        echo -e "${GRAY_R}#${RESET} ${mongosh_package} appears to be corrupted, purging the package..."
        if DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' purge "${mongosh_package}" &>> "${eus_dir}/logs/mongosh-corruption.log"; then
          echo -e "${GREEN}#${RESET} Successfully purged ${mongosh_package}! \\n"
        else
          echo -e "${RED}#${RESET} Failed to purge ${mongosh_package}...\\n"
          echo -e "${GRAY_R}#${RESET} Trying another method to get rid of ${mongosh_package}..."
          check_dpkg_lock
          if DEBIAN_FRONTEND='noninteractive' "$(which dpkg)" --remove --force-remove-reinstreq "${mongosh_package}" &>> "${eus_dir}/logs/mongosh-corruption.log"; then
            echo -e "${GREEN}#${RESET} Successfully removed ${mongosh_package}! \\n"
          else
            echo -e "${RED}#${RESET} Failed to force remove ${mongosh_package}...\\n"
            abort_reason="Failed to purge ${mongosh_package}."; abort
          fi
        fi
      done < <("$(which dpkg)" -l | awk '$1 ~ /^(ii|hi)$/ {print $2}' | grep -E "^mongodb-mongosh-shared-openssl3$|^mongodb-mongosh-shared-openssl11$|^mongodb-mongosh$|^mongosh$")
    fi
    if ! apt-cache depends "${mongodb_org_server_package}" &> /dev/null; then silent_run_apt_get_update="true"; run_apt_get_update; fi
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
      multiple_attempt_to_install_package_log="unifi-easy-update-script-required"
      multiple_attempt_to_install_package_task="install"
      multiple_attempt_to_install_package_attempts_max="3"
      multiple_attempt_to_install_package_name="${mongodb_mongosh_install_package_name}"
      multiple_attempt_to_install_package
      get_apt_options
    fi
  fi
fi
if "$(which dpkg)" -l mongodb-server 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
  if ! "$(which dpkg)" -l mongodb-clients 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
    check_dpkg_lock
    echo -e "${GRAY_R}----${RESET}\\n"
    echo -e "${GRAY_R}#${RESET} Installing required package mongodb-clients..."
    if ! DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install mongodb-clients &>> "${eus_dir}/logs/unifi-easy-update-script-required.log"; then
      echo -e "${RED}#${RESET} Failed to install mongodb-clients...\\n"
      if [[ "${os_codename}" =~ (trusty|utopic|vivid|wily|yakkety|zesty|artful|qiana|rebecca|rafaela|rosa|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing|sarah|serena|sonya|sylvia|tara|tessa|tina|tricia) ]]; then
        repo_component="main universe"
        repo_codename="xenial"
        get_repo_url
        add_repositories
        run_apt_get_update
      elif [[ "${os_codename}" =~ (wheezy|jessie|stretch|buster|bullseye|bookworm|trixie|forky|unstable) ]]; then
        repo_component="main"
        repo_codename="stretch"
        get_repo_url
        add_repositories
        run_apt_get_update
      fi
      check_dpkg_lock
      echo -e "${GRAY_R}#${RESET} Trying to install mongodb-clients for the second time..."
      if ! DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install mongodb-clients &>> "${eus_dir}/logs/unifi-easy-update-script-required.log"; then
        echo -e "${RED}#${RESET} Failed to install mongodb-clients for the second time...\\n"
        echo -e "${GRAY_R}#${RESET} Trying to install mongodb-clients for the thurd time..."
        mongo_last_attempt_type="clients"
        mongo_last_attempt
        if [[ "${mongo_last_attempt_install_success}" != 'true' ]]; then required_mongo_packages_missing; fi
	  else
        echo -e "${GREEN}#${RESET} Successfully installed mongodb-clients! \\n" && sleep 2
      fi
	else
      echo -e "${GREEN}#${RESET} Successfully installed mongodb-clients! \\n" && sleep 2
    fi
  fi
fi

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

# Check if user performed an incorrect MongoDB upgrade.
if [[ -d "/usr/lib/unifi/logs/" ]]; then unifi_logs_location="$(readlink -f /usr/lib/unifi/logs)"; else unifi_logs_location="/var/log/unifi"; fi
if [[ -d "${unifi_logs_location}/" ]]; then
  if [[ "$(command -v zgrep)" ]]; then grep_command="zgrep"; else grep_command="grep"; fi
  get_unifi_api_ports
  get_unifi_application_status
  if [[ "${application_up}" == 'true' ]]; then
    if [[ "$(du -b "${unifi_logs_location}/mongod.log" 2> /dev/null | awk '{print$1}')" -gt "5368709120 " ]]; then grep_matches="-m 2"; fi
  else
    if [[ "$(du -b "${unifi_logs_location}/mongod.log" 2> /dev/null | awk '{print$1}')" -gt "5368709120 " ]]; then grep_matches="-m 10"; fi
  fi
  while read -r found_mongodb_version; do
    found_mongodb_version_fd="$(echo "${found_mongodb_version}" | cut -d'.' -f1)"
    found_mongodb_version_sd="$(echo "${found_mongodb_version}" | cut -d'.' -f2)"
    found_mongodb_version_td="$(echo "${found_mongodb_version}" | cut -d'.' -f3)"
    while read -r file; do
      if ! "${grep_command}" ${grep_matches:+${grep_matches}} -A100 -aE "${found_mongodb_version_fd}\.${found_mongodb_version_sd}\.${found_mongodb_version_td}" "${file}" | sed -n "/${found_mongodb_version_fd}\.${found_mongodb_version_sd}\.${found_mongodb_version_td}/,/SERVER RESTARTED/p" | sed -e "1s/^.*${found_mongodb_version_fd}\.${found_mongodb_version_sd}\.${found_mongodb_version_td} //; /^SERVER RESTARTED/d" | grep -sqiaE "This version of MongoDB is too recent to start up on the existing data files|This may be due to an unsupported upgrade or downgrade.|UPGRADE PROBLEM|Cannot start server with an unknown storage engine|unsupported WiredTiger file version|DBException in initAndListen, terminating"; then
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
  if [[ -z "${last_known_good_mongodb_version}" ]]; then
    if [[ -e "${eus_dir}/logs/mongodb-unsupported-version-change-locate.log" ]]; then
      mapfile -t eus_marked_bad_versions < <("${grep_command}" -E '"[0-9]+\.[0-9]+\.[0-9]+" .* bad' "${eus_dir}/logs/mongodb-unsupported-version-change-locate.log" | sed -E 's/.*"([0-9]+\.[0-9]+\.[0-9]+)".*/\1/' | sort -rV | uniq)
      mapfile -t dpkg_log_mongodb_server_versions < <(find /var/log/ --maxdepth 1 -type f -name "dpkg*" -print0 | xargs -0 "${grep_command}" ${grep_matches:+${grep_matches}} -sEia "upgrade mongodb-org-server|upgrade mongodb-server|upgrade mongod-armv8|upgrade mongod-amd64" | awk '{for(i=1;i<NF;i++) if ($i == "upgrade") {print $(i+2); break}}' | cut -d':' -f2 | sed -E 's/-.*//' | sort -rV | uniq)
      for version in "${dpkg_log_mongodb_server_versions[@]}"; do
        if [[ ! " ${eus_marked_bad_versions[*]} " =~ ${version} ]]; then
          dpkg_log_mongodb_server="${version}"
          break
        fi
      done
    fi
  fi
  if [[ -n "${last_known_good_mongodb_version}" ]]; then
    echo -e "$(date +%F-%T.%6N) | Using last known good MongoDB version \"${last_known_good_mongodb_version}\" from the MongoDB logs!" &>> "${eus_dir}/logs/mongodb-unsupported-version-change-locate.log"
    previous_mongodb_version="${last_known_good_mongodb_version//./}"
    previous_mongodb_version_with_dot="${last_known_good_mongodb_version}"
  elif [[ -n "${dpkg_log_mongodb_server}" ]]; then
    echo -e "$(date +%F-%T.%6N) | Using last known good MongoDB version \"${dpkg_log_mongodb_server}\" from the dpkg logs!" &>> "${eus_dir}/logs/mongodb-unsupported-version-change-locate.log"
    previous_mongodb_version="${dpkg_log_mongodb_server//./}"
    previous_mongodb_version_with_dot="${dpkg_log_mongodb_server}"
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

# downgrade arm64 to 4.4.18 if 4.4 MongoDB is installed.
if "$(which dpkg)" -l mongodb-org-server 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
  installed_mongodb_org_version_check="$(dpkg-query --showformat='${version}' --show mongodb-org-server 2> /dev/null | sed -e 's/.*://' -e 's/-.*//g' -e 's/\.//g')"
  if [[ "${installed_mongodb_org_version_check::2}" == '44' && "$(dpkg-query --showformat='${version}' --show mongodb-org-server 2> /dev/null | sed -e 's/.*://' -e 's/-.*//g' | awk -F. '{print $3}')" -ge "19" ]]; then if [[ "${glennr_mongod_compatible}" == "true" ]]; then unsupported_database_version_change="true"; fi; fi
  if [[ "${installed_mongodb_org_version_check::2}" -gt '44' ]]; then if [[ "${glennr_mongod_compatible}" == "true" && "${official_mongodb_compatible}" != 'true' ]]; then unsupported_database_version_change="true"; fi; fi
  if [[ -n "${previous_mongodb_version}" ]]; then if [[ "${installed_mongodb_org_version_check::2}" != "${previous_mongodb_version::2}" ]] && [[ "${previous_mongodb_version::2}" != "$((${installed_mongodb_org_version_check::2} - 2))" ]]; then unsupported_database_version_change="true"; fi; fi
  if [[ -n "${dpkg_log_mongodb_server}" ]]; then if [[ "${installed_mongodb_org_version_check::2}" != "${previous_mongodb_version::2}" ]]; then unsupported_database_version_change="true"; fi; fi
elif "$(which dpkg)" -l mongodb-server 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
  installed_mongodb_version_check="$(dpkg-query --showformat='${version}' --show mongodb-server 2> /dev/null | sed -e 's/.*://' -e 's/-.*//g' -e 's/\.//g')"
  if [[ "${installed_mongodb_version_check::2}" == '44' && "$(dpkg-query --showformat='${version}' --show mongodb-server 2> /dev/null | sed -e 's/.*://' -e 's/-.*//g' | awk -F. '{print $3}')" -ge "19" ]]; then if [[ "${glennr_mongod_compatible}" == "true" ]]; then unsupported_database_version_change="true"; fi; fi
  if [[ "${installed_mongodb_version_check::2}" -gt '44' ]]; then if [[ "${glennr_mongod_compatible}" == "true" && "${official_mongodb_compatible}" != 'true' ]]; then unsupported_database_version_change="true"; fi; fi
  if [[ -n "${previous_mongodb_version}" ]]; then if [[ "${installed_mongodb_version_check::2}" != "${previous_mongodb_version::2}" ]] && [[ "${previous_mongodb_version::2}" != "$((${installed_mongodb_version_check::2} - 2))" ]]; then unsupported_database_version_change="true"; fi; fi
  if [[ -n "${dpkg_log_mongodb_server}" ]]; then if [[ "${installed_mongodb_version_check::2}" != "${previous_mongodb_version::2}" ]]; then unsupported_database_version_change="true"; fi; fi
fi

# Override MongoDB version change attempts when the application is up and running.
if [[ "${unsupported_database_version_change}" == 'true' ]]; then
  get_unifi_api_ports
  get_unifi_application_status
  if [[ "${application_up}" == 'true' ]]; then
    echo -e "$(date +%F-%T.%6N) | The Network Application appears to be functioning, cancelling any unsupported MongoDB version change fix attempts..." &>> "${eus_dir}/logs/mongodb-unsupported-version-change-override.log"
    echo -e "$(date +%F-%T.%6N) | previous_mongodb_version: ${previous_mongodb_version}, previous_mongodb_version_with_dot: ${previous_mongodb_version_with_dot}, unsupported_database_version_change: ${unsupported_database_version_change}" &>> "${eus_dir}/logs/mongodb-unsupported-version-change-override.log"
    unset previous_mongodb_version
    unset previous_mongodb_version_with_dot
    unset unsupported_database_version_change
  fi
fi

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
    if [[ -n "${mongodb_org_v}" ]]; then unset_mongodb_org_v="true"; unset mongodb_org_v; fi
    remove_older_mongodb_repositories
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
        if DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_downgrade_option[@]}" "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' remove "${package}" "${mongodb_extra_dependencies[@]}" &>> "${eus_dir}/logs/mongodb-unsupported-version-change.log"; then
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
        if DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_downgrade_option[@]}" "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "${mongodb_package}${mongodb_version_with_equal}" &>> "${eus_dir}/logs/mongodb-unsupported-version-change.log"; then
          echo -e "${GREEN}#${RESET} Successfully downgraded ${mongodb_package} to version ${install_mongodb_version}! \\n"
        else
          check_unmet_dependencies
          broken_packages_check
          attempt_recover_broken_packages
          add_apt_option_no_install_recommends="true"; get_apt_options
          check_dpkg_lock
          if DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_downgrade_option[@]}" "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "${mongodb_package}${mongodb_version_with_equal}" &>> "${eus_dir}/logs/mongodb-unsupported-version-change.log"; then
            echo -e "${GREEN}#${RESET} Successfully downgraded ${mongodb_package} to version ${install_mongodb_version}! \\n"
          else
            try_different_mongodb_repo="true"
            skip_mongodb_org_v="true"
            add_mongodb_repo
            check_dpkg_lock
            if DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_downgrade_option[@]}" "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "${mongodb_package}${mongodb_version_with_equal}" &>> "${eus_dir}/logs/mongodb-unsupported-version-change.log"; then
              echo -e "${GREEN}#${RESET} Successfully downgraded ${mongodb_package} to version ${install_mongodb_version}! \\n"
            else
              try_http_mongodb_repo="true"
              skip_mongodb_org_v="true"
              add_mongodb_repo
              check_dpkg_lock
              if DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_downgrade_option[@]}" "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "${mongodb_package}${mongodb_version_with_equal}" &>> "${eus_dir}/logs/mongodb-unsupported-version-change.log"; then
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
      reinstall_unifi_version="$(head -n1 /usr/lib/unifi/data/db/version | sed 's/[^0-9.]//g' 2> /dev/null)"
      if [[ -z "${reinstall_unifi_version}" ]]; then reinstall_unifi_version="$(dpkg-query --showformat='${version}' --show unifi 2> /dev/null | awk -F '[-]' '{print $1}')"; fi
      if [[ "$(curl "${curl_argument[@]}" https://api.glennr.nl/api/network-release?status 2> /dev/null | jq -r '.[]' 2> /dev/null)" == "OK" ]]; then
        fw_update_dl_link="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/network-release?version=${reinstall_unifi_version}${unifi_core_glennr_api}" | jq -r '."download_link"' | sed '/null/d' 2> "${eus_dir}/logs/locate-download.log")"
        fw_update_gr_dl_link="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/network-release?version=${reinstall_unifi_version}&server=archive${unifi_core_glennr_api}" | jq -r '."download_link"' | sed '/null/d' 2> "${eus_dir}/logs/locate-download.log")"
        fw_update_dl_link_sha256sum="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/network-release?version=${reinstall_unifi_version}${unifi_core_glennr_api}" | jq -r '.sha256sum' | sed '/null/d' 2> "${eus_dir}/logs/locate-download.log")"
      fi
      if [[ -z "${fw_update_dl_link}" ]]; then
        fw_update_dl_link="$(curl "${curl_argument[@]}" --location --request GET "https://fw-update.ui.com/api/firmware-latest?filter=eq~~version_major~~$(awk -F'.' '{print $1}' <<< "${reinstall_unifi_version}")&filter=eq~~version_minor~~$(awk -F'.' '{print $2}' <<< "${reinstall_unifi_version}")&filter=eq~~version_patch~~$(awk -F'.' '{print $3}' <<< "${reinstall_unifi_version}")&filter=eq~~platform~~debian" 2> "${eus_dir}/logs/locate-download.log" | jq -r "._embedded.firmware[0]._links.data.href" 2> "${eus_dir}/logs/locate-download.log" | sed '/null/d' 2> "${eus_dir}/logs/locate-download.log")"
        fw_update_dl_link_sha256sum="$(curl "${curl_argument[@]}" --location --request GET "https://fw-update.ui.com/api/firmware-latest?filter=eq~~version_major~~$(awk -F'.' '{print $1}' <<< "${reinstall_unifi_version}")&filter=eq~~version_minor~~$(awk -F'.' '{print $2}' <<< "${reinstall_unifi_version}")&filter=eq~~version_patch~~$(awk -F'.' '{print $3}' <<< "${reinstall_unifi_version}")&filter=eq~~platform~~debian" 2> "${eus_dir}/logs/locate-download.log" | jq -r "._embedded.firmware[0].sha256_checksum" 2> "${eus_dir}/logs/locate-download.log" | sed '/null/d' 2> "${eus_dir}/logs/locate-download.log")"
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
        echo -e "${GRAY_R}#${RESET} Downloading UniFi Network Application version ${reinstall_unifi_version}..."
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
        unifi_dependencies_check
        unifi_deb_package_modification
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
    get_unifi_api_ports
    get_unifi_application_status
    if [[ "${application_up}" == 'true' ]]; then compress_and_relocate_database_recovery_logs; fi
    if [[ "${unset_mongo_version_locked}" == 'true' ]]; then unset mongo_version_locked; fi
    if [[ -n "${original_previous_mongodb_version}" ]]; then previous_mongodb_version="${original_previous_mongodb_version}"; fi
    if [[ -n "${original_previous_mongodb_version_with_dot}" ]]; then previous_mongodb_version_with_dot="${original_previous_mongodb_version_with_dot}"; fi
    if [[ "${unset_mongodb_org_v}" == 'true' ]]; then get_mongodb_org_v; fi
    reverse_check_add_mongodb_repo_variable
    if "$(which dpkg)" -l unifi 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
      echo -e "${GRAY_R}#${RESET} Restarting the UniFi Network Application..."
      if [[ "${limited_functionality}" == 'true' ]]; then
        if service unifi restart &>> "${eus_dir}/logs/mongodb-unsupported-version-change.log"; then echo -e "${GREEN}#${RESET} Successfully restarted the UniFi Network Application! \\n"; else echo -e "${RED}#${RESET} Failed to restart the UniFi Network Application... \\n"; fi
      else
        if systemctl restart unifi &>> "${eus_dir}/logs/mongodb-unsupported-version-change.log"; then echo -e "${GREEN}#${RESET} Successfully restarted the UniFi Network Application! \\n"; else echo -e "${RED}#${RESET} Failed to restart the UniFi Network Application... \\n"; fi
      fi
    fi
  fi
fi

script_cleanup() {
  rm --force "${unifi_api_cookie}" &> /dev/null
  rm -rf /tmp/EUS &> /dev/null
}

prevent_unifi_upgrade() {
  if [[ "${prevented_unifi}" != 'true' ]]; then
    header
    echo -e "${GRAY_R}#${RESET} Preventing Ubiquiti/UniFi package(s) from upgrading!"
    echo -e "${GRAY_R}#${RESET} These changes will be reverted when the script finishes. \\n"
    while read -r service; do
      check_dpkg_lock
      echo -e "${GRAY_R}#${RESET} Preventing ${service} from upgrading..."
      if echo "${service} hold" | "$(which dpkg)" --set-selections &>> "${eus_dir}/logs/package-hold.log"; then echo -e "${GREEN}#${RESET} Successfully prevented ${service} from upgrading! \\n"; prevented_unifi="true"; else echo -e "${RED}#${RESET} Failed to prevented ${service} from upgrading...\\n"; fi
    done < <("$(which dpkg)" -l | awk '/unifi/ {print $2}' | awk -F '[:]' '{print $1}')
    sleep 3
    return
  fi
  if [[ "${prevented_unifi}" == 'true' ]]; then
    while read -r service; do
      check_dpkg_lock
      echo "${service} install" | "$(which dpkg)" --set-selections 2> /dev/null
    done < <("$(which dpkg)" -l | awk '/unifi/ {print $2}' | awk -F '[:]' '{print $1}')
    unset prevented_unifi
  fi
}

if "$(which dpkg)" -l | grep "^ii\\|^hi\\|^ri\\|^pi\\|^ui\\|^iU" | grep -iq "${gr_mongod_name}"; then
  prevent_mongodb_org_server_install
else
  if [[ -e "/etc/apt/preferences.d/eus_prevent_install_mongodb-org-server" ]]; then rm --force "/etc/apt/preferences.d/eus_prevent_install_mongodb-org-server"; fi
fi

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                            Variables                                                                                            #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

get_unifi_version
get_mongodb_org_v

# Supported MongoDB Version
get_mongo_version_max() {
  mongo_version_max="36"
  mongo_version_max_with_dot="3.6"
  if [[ "${first_digit_unifi}" -le '5' && "${second_digit_unifi}" -le '13' ]]; then
    mongo_version_max="34"
    mongo_version_max_with_dot="3.4"
  fi
  if [[ "${first_digit_unifi}" == '5' && "${second_digit_unifi}" == '13' && "${third_digit_unifi}" -gt '10' ]]; then
    mongo_version_max="36"
    mongo_version_max_with_dot="3.6"
  fi
  if [[ "${first_digit_unifi}" -gt '7' ]] || [[ "${first_digit_unifi}" == '7' && "${second_digit_unifi}" -ge "5" ]]; then
    mongo_version_max="44"
    mongo_version_max_with_dot="4.4"
  fi
  if [[ "${first_digit_unifi}" -gt '8' ]] || [[ "${first_digit_unifi}" == '8' && "${second_digit_unifi}" -ge "1" ]]; then
    mongo_version_max="70"
    mongo_version_max_with_dot="7.0"
  fi
  if [[ "${first_digit_unifi}" -gt '9' ]] || [[ "${first_digit_unifi}" == '9' && "${second_digit_unifi}" -ge "0" ]]; then
    mongo_version_max="80"
    mongo_version_max_with_dot="8.0"
  fi
}
get_mongo_version_max

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
mongodb_avx_support_check
mongo_command

unifi_version=''

glennr_unifi_backup=''
executed_unifi_credentials=''
backup_location=''
unifi_write_permission=''

ubic_2fa_token=''
two_factor=''
unifi_backup_cancel=''
application_login=''
run_unifi_firmware_check='yes'

uap_custom=''
usw_custom=''
ugw_custom=''
uap_upgrade_done='no'
usw_upgrade_done='no'
ugw_upgrade_done='no'
uap_upgrade_schedule_done='no'
usw_upgrade_schedule_done='no'
ugw_upgrade_schedule_done='no'
uap_custom_upgrade_message=''
uap_upgrade_message=''
usw_custom_upgrade_message=''
usw_upgrade_message=''
ugw_custom_upgrade_message=''

# UniFi API Variables
if [[ -f "/usr/lib/unifi/data/system.properties" ]]; then
  unifi_https_port=$(grep "^unifi.https.port=" /usr/lib/unifi/data/system.properties | sed 's/unifi.https.port//g' | tr -d '="')
fi
if [[ -z "${unifi_https_port}" ]]; then
  unifi_port_https="8443"
else
  unifi_port_https="${unifi_https_port}"
fi
if "$(which dpkg)" -l unifi-core 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
  unifi_os_or_network="UniFi OS"
  unifi_api_baseurl="https://localhost/proxy/network"
else
  unifi_os_or_network="UniFi Network Application"
  unifi_api_baseurl="https://localhost:${unifi_port_https}"
fi
unifi_api_cookie=$(mktemp --tmpdir=/tmp/EUS unifi_api_cookie_XXXXX)
unifi_api_curl_cmd="curl --tlsv1 --silent --cookie ${unifi_api_cookie} --cookie-jar ${unifi_api_cookie} --insecure "

# UniFi Devices ( 3.7.58 )
UGW3=(UGW3) #USG3
UGW4=(UGW4) #USGP4
US24P250=(USW US8 US8P60 US8P150 US16P150 US24 US24P250 US24P500 US48 US48P500 US48P750) #USW
U7PG2=(U7LT U7LR U7PG2 U7EDU U7MSH U7MP U7IW U7IWP) #UAP-AC-Lite/LR/Pro/EDU/M/M-PRO/IW/IW-Pro
BZ2=(BZ2 BZ2LR U2O U5O) #UAP, UAP-LR, UAP-OD, UAP-OD5
U2Sv2=(U2Sv2 U2Lv2) #UAP-v2, UAP-LR-v2
U2IW=(U2IW) #UAP IW
U7P=(U7P) #UAP PRO
U2HSR=(U2HSR) #UAP OD+
U7HD=(U7HD) #UAP HD
USXG=(USXG) #USW 16 XG
U7E=(U7E U7Ev2 U7O) #UAP AC, UAP AC v2, UAP AC OD

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                                                                                                                                 #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

migration_check() {
  header
  echo -e "${GRAY_R}#${RESET} Checking Database migration process."
  echo -e "${GRAY_R}#${RESET} This can take up to 10 minutes before timing out! \\n\\n"
  read -rt 600 < <(tail -n 0 -f /usr/lib/unifi/logs/server.log | grep --line-buffered "DB migration to version (.*) is complete\\|*** Factory Default ***") && unifi_update="true" || TIMED_OUT="true"
  if [[ "${unifi_update}" == 'true' ]]; then
    unset UNIFI
    unifi=$("$(which dpkg)" -l | awk '$2 == "unifi" {print $3}' | sed 's/-.*//')
    header
    echo -e "${GRAY_R}#${RESET} UniFi Network Application DB migration was successful"
    echo -e "${GRAY_R}#${RESET} Currently your UniFi Network Application is on version ${GRAY_R}$unifi${RESET}\\n\\n"
    echo -e "${GRAY_R}#${RESET} Continuing the UniFi Network Application update! \\n\\n"
    unset unifi_update
    unset TIMED_OUT
    sleep 3
  elif [[ "${TIMED_OUT}" == 'true' ]]; then
    header_red
    echo -e "${RED}#${RESET} DB migration check timed out!"
    echo -e "${RED}#${RESET} Please contact Glenn R. (AmazedMender16) on the Community Forums! \\n\\n"
    exit 1
  fi
  echo -e "\\n"
}

remove_yourself() {
  script_cleanup
  if [[ "${set_lc_all}" == 'true' ]]; then if [[ -n "${original_lang}" ]]; then export LANG="${original_lang}"; else unset LANG; fi; if [[ -n "${original_lcall}" ]]; then export LC_ALL="${original_lcall}"; else unset LC_ALL; fi; fi
  if [[ "${stopped_unattended_upgrade}" == 'true' ]]; then systemctl start unattended-upgrades &>> "${eus_dir}/logs/unattended-upgrades.log"; unset stopped_unattended_upgrade; fi
  if [[ "${delete_script}" == 'true' ]]; then if [[ -e "${script_location}" ]]; then rm --force "${script_location}" 2> /dev/null; fi; fi
}

unifi_update_start() {
  header
  echo -e "${GRAY_R}#${RESET} Starting the UniFi Network Application update! \\n\\n"
  sleep 2
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
  eus_tmp_directory_cleanup="true"; eus_tmp_directory_check
  check_apt_listbugs
  update_eus_db
  cleanup_codename_mismatch_repos
  if [[ "${perform_application_upgrade}" == 'true' ]]; then prevent_unifi_upgrade; fi
  christmass_new_year
  if [[ "${new_year_message}" == 'true' || "${christmas_message}" == 'true' || "${script_option_archive_alerts}" == 'true' || "${script_option_delete_events}" == 'true' ]]; then echo -e "\\n${GRAY_R}----${RESET}\\n"; fi
  if [[ "${archived_repo}" == 'true' && "${unifi_core_system}" != 'true' ]]; then echo -e "\\n${WHITE_R}----${RESET}\\n\\n${RED}# ${RESET}System Notice: ${WHITE_R}Unsupported OS Version Detected${RESET}! \\n${RED}# ${RESET}Your operating system release (${WHITE_R}${os_codename}${RESET}) has reached End of Life (EOL) and is no longer supported by its creators.\\n${RED}# ${RESET}To ensure security and compatibility, please update to a more current release...\\n"; fi
  if [[ "${archived_repo}" == 'true' && "${unifi_core_system}" == 'true' && "${unifi_core_upgrade_message}" != 'true' ]]; then echo -e "\\n${GRAY_R}----${RESET}\\n\\n${RED}# ${RESET}Please update to the latest UniFi OS Release!\\n"; fi
  if [[ "${stopped_unattended_upgrade}" == 'true' ]]; then systemctl start unattended-upgrades &>> "${eus_dir}/logs/unattended-upgrades.log"; unset stopped_unattended_upgrade; fi
  echo -e "${GRAY_R}#${RESET} ${GRAY_R}Author   |  ${WHITE_R}Glenn R.${RESET}"
  echo -e "${GRAY_R}#${RESET} ${GRAY_R}Email    |  ${WHITE_R}glennrietveld8@hotmail.nl${RESET}"
  echo -e "${GRAY_R}#${RESET} ${GRAY_R}Website  |  ${WHITE_R}https://GlennR.nl${RESET}\\n\\n"
}

backup_save_location() {
  if [[ "${backup_location}" == "custom" ]]; then
    if echo "${auto_dir}" | grep -q '/$'; then
      echo -e "${GRAY_R}#${RESET} Your UniFi Network Application backup is saved here: ${GRAY_R}${auto_dir}glennr-unifi-backups/${RESET} \\n"
    else
      echo -e "${GRAY_R}#${RESET} Your UniFi Network Application backup is saved here: ${GRAY_R}${auto_dir}/glennr-unifi-backups/${RESET} \\n"
    fi
  elif [[ "${backup_location}" == "sd_card" ]]; then
    echo -e "${GRAY_R}#${RESET} Your UniFi Network Application backup is saved here: ${GRAY_R}/data/glennr-unifi-backups/${RESET} \\n"
  elif [[ "${backup_location}" == "sd_card_unifi_os" ]]; then
    echo -e "${GRAY_R}#${RESET} Your UniFi Network Application backup is saved here: ${GRAY_R}/sdcard/glennr-unifi-backups/${RESET} \\n"
  elif [[ "${backup_location}" == "unifi_dir" ]]; then
    echo -e "${GRAY_R}#${RESET} Your UniFi Network Application backup is saved here: ${GRAY_R}/usr/lib/unifi/data/backup/glennr-unifi-backups/${RESET} \\n"
  fi
}

auto_backup_write_warning() {
  if [[ "${application_login}" == 'success' ]]; then
    autobackup_status="$("${mongocommand}" --quiet --port 27117 ace --eval "${mongoprefix}db.getCollection('setting').find({key:'super_mgmt'})${mongosuffix}" | sed 's/\(ObjectId(\|)\|NumberLong(\)//g' 2> /dev/null | jq -r '.[]."autobackup_enabled"' 2> /dev/null)"
    if [[ "${autobackup_status}" == 'true' && "${unifi_write_permission}" == "false" ]]; then
      echo -e "${RED}#${RESET} Your autobackups path is set to '${GRAY_R}${auto_dir}${RESET}', user UniFi is not able to backup to that location.."
      echo -e "${RED}#${RESET} I recommend checking the path and make sure the user UniFi has permissions to that directory.. or use the default location. \\n"
    elif [[ "${autobackup_status}" == 'false' ]]; then
      echo -e "${RED}#${RESET} You currently don't have autobackups turned on.."
      echo -e "${RED}#${RESET} I highly recommend turning that on, let it run daily settings only backups... \\n"
    fi
  fi
}

override_inform_host() {
  header
  echo -e "${GRAY_R}#${RESET} Checking if the Hostname/IP override is turned on.."
  if [[ "$("${mongocommand}" --quiet --port 27117 ace --eval "${mongoprefix}db.getCollection('setting').find({key:'super_mgmt'})${mongosuffix}" | sed 's/\(ObjectId(\|)\|NumberLong(\)//g' 2> /dev/null | jq -r '.[]."override_inform_host"' 2> /dev/null)" != 'true' ]]; then
    header_red
    echo -e "${RED}#${RESET} Override Inform Host is currently disabled, I recommend turning this on when doing a mass upgrade."
    echo -e "${RED}#${RESET} The Hostname/IP needs to be accessible for all adopted devices."
    echo -e "\\n${RED}#${RESET} UniFi Network Application Settings"
    echo -e "${RED}#${RESET} Settings > System > Other Configuration > Override Inform Host"
    echo -e "\\n${RED}#${RESET} You can this turn this on right now, or continue without turning it on.\\n\\n"
    read -rp $'\033[39m#\033[0m Can we continue with the device upgrade? (Y/n) ' yes_no
    case "$yes_no" in
        [Nn]*) cancel_script;;
        *) ;;
    esac
  else
    echo -e "${GREEN}#${RESET} Hostname/IP is enabled!" && sleep 2
  fi
}

mail_server_recommendation() {
  net_check_remote_access() {
    net_remote_access_status="$("${mongocommand}" --quiet --port 27117 ace --eval "${mongoprefix}db.getCollection('setting').find({key:'super_cloudaccess'})${mongosuffix}" | sed 's/\(ObjectId(\|)\|NumberLong(\)//g' 2> /dev/null | jq -r '.[]."enabled"' 2> /dev/null)"
  }
  net_enable_cloud_mail() {
    echo -e "${GRAY_R}#${RESET} Enabling UI Cloud Email..."
    # shellcheck disable=SC2016
    net_enable_cloud_mail_status="$("${mongocommand}" --quiet --port 27117 ace --eval ''"${mongoprefix}"'db.getCollection("setting").updateOne({key: "super_mail"}, {"$set": {provider: "cloud"}}) )' 2> /dev/null | jq -r '."modifiedCount"' 2> /dev/null)"
    if [[ "${net_enable_cloud_mail_status}" == '1' ]]; then
      echo -e "${GREEN}#${RESET} Successfully enabled UI Cloud Email! \\n"
    else
      echo -e "${RED}#${RESET} Failed to enable UI Cloud Email, please enable it yourself..."
      echo -e "${RED}#${RESET} Settings > System > Advanced > Email Services \\n"
    fi
  }
  net_mail_server_recommendation() {
    net_check_remote_access
    if [[ "${net_remote_access_status}" == 'true' ]]; then
      echo -e "${YELLOW}#${RESET} You do not have an Email Server configurated for your Network Application..."
      while true; do
        read -rp $'\033[39m#\033[0m Would you like to enable UI Cloud Email for email notifications? (Y/n) ' yes_no
        case "$yes_no" in
            [Yy]*|"")
              net_enable_cloud_mail
              break;;
            [Nn]*)
              echo -e "${YELLOW}#${RESET} Alright... not touching your Email Server Configuration... Please configure one yourself... \\n"
              echo -e "${YELLOW}#${RESET} UniFi Network Application Settings"
              echo -e "${YELLOW}#${RESET} Settings > System > Advanced > Email Services \\n"
              break;;
            *) echo -e "\\n${RED}#${RESET} Invalid input, please answer Yes or No (y/n)...\\n"; sleep 3;;
        esac
      done
    else
      echo -e "${YELLOW}#${RESET} You do not have an Email Server configurated... this is recommended! \\n"
      echo -e "${YELLOW}#${RESET} UniFi Network Application Settings"
      echo -e "${YELLOW}#${RESET} Settings > System > Advanced > Email Services \\n"
    fi
  }
  net_mail_provider_setting="$("${mongocommand}" --quiet --port 27117 ace --eval "${mongoprefix}db.getCollection('setting').find({key:'super_mail'})${mongosuffix}" | sed 's/\(ObjectId(\|)\|NumberLong(\)//g' 2> /dev/null | jq -r '.[]."provider"' 2> /dev/null)"
  if [[ "${net_mail_provider_setting}" == "disabled" ]]; then
    net_mail_server_recommendation
  elif [[ "${net_mail_provider_setting}" == "smtp" && "$("${mongocommand}" --quiet --port 27117 ace --eval "${mongoprefix}db.getCollection('setting').find({key:'super_smtp'})${mongosuffix}" | sed 's/\(ObjectId(\|)\|NumberLong(\)//g' 2> /dev/null | jq -r '.[]."enabled"' 2> /dev/null)" != 'true' ]]; then
    net_mail_server_recommendation
  fi
}

check_mongodb_connection() {
  mongo_wait_initialize="0"
  mongo_max_wait_time="30"
  mongo_wait_interval="5"
  mongo_total_checks="$((mongo_max_wait_time / mongo_wait_interval))"
  until "${mongocommand}" --port 27117 --eval "print(\"waited for connection\")" &> /dev/null; do
    ((mongo_wait_initialize++))
    sleep "${mongo_wait_interval}"
    if [[ "${mongo_wait_initialize}" -ge "${mongo_total_checks}" ]]; then break; fi
  done
  if [[ "${mongo_wait_initialize}" -lt "${mongo_total_checks}" ]]; then
    mongodb_connected="true"
  fi
}

unifi_update_finish() {
  if [[ "${application_login}" == 'success' ]]; then
    application_login_attempt
  fi
  login_cleanup
  header
  echo -e "${GRAY_R}#${RESET} Your UniFi Network Application has been successfully updated to $(dpkg-query --showformat='${version}' --show unifi 2> /dev/null | awk -F '[-]' '{print $1}')"
  if [[ "${script_option_do_not_start_unifi}" == 'true' ]]; then
    echo -e "${GRAY_R}#${RESET} You've used the script option \"Do Not Start UniFi\"... Stopping the service..."
    echo -e "$(date +%F-%T.%6N) | Script option \"Do Not Start UniFi\" was used... Stopping the UniFi Network Application..." &>> "${eus_dir}/logs/script-option-do-not-start-unifi.log"
    if [[ "${limited_functionality}" == 'true' ]]; then
      if service unifi stop &>> "${eus_dir}/logs/script-option-do-not-start-unifi.log"; then echo -e "${GREEN}#${RESET} Successfully stopped service unifi! \\n"; else echo -e "${RED}#${RESET} Failed to stop service unifi..."; fi
    else
      if systemctl stop unifi &>> "${eus_dir}/logs/script-option-do-not-start-unifi.log"; then echo -e "${GREEN}#${RESET} Successfully stopped service unifi! \\n"; else echo -e "${RED}#${RESET} Failed to stop service unifi..."; fi
    fi
  fi
  backup_save_location
  check_mongodb_connection
  if [[ "${mongodb_connected}" == 'true' ]]; then
    auto_backup_write_warning
    if [[ "${first_digit_unifi}" -ge '6' ]] || [[ "${first_digit_unifi}" -ge '5' && "${second_digit_unifi}" -ge '12' ]]; then mail_server_recommendation; fi
  fi
  if [[ "${keystore_alias_checked}" == "true" ]]; then
    echo -e "\\n${GRAY_R}#${RESET} The script has detected a invalid keystore and removed it..."
  fi
  echo -e "\\n"
  author
  remove_yourself
  exit 0
}

unifi_update_latest() {
  login_cleanup
  header
  if [[ "${release_stage}" == 'RC' ]]; then
    echo -e "${GRAY_R}#${RESET} Your UniFi Network Application is already on the latest release candidate! ( ${GRAY_R}$unifi${RESET} )"
  else
    echo -e "${GRAY_R}#${RESET} Your UniFi Network Application is already on the latest stable release! ( ${GRAY_R}$unifi${RESET} )"
  fi
  backup_save_location
  check_mongodb_connection
  if [[ "${mongodb_connected}" == 'true' ]]; then
    auto_backup_write_warning
    if [[ "${first_digit_unifi}" -ge '6' ]] || [[ "${first_digit_unifi}" -ge '5' && "${second_digit_unifi}" -ge '12' ]]; then mail_server_recommendation; fi
  fi
  echo -e "\\n"
  author
  remove_yourself
  exit 0
}

os_update_finish() {
  header
  echo -e "${GRAY_R}#${RESET} The latest patches have been successfully installed on your system! \\n\\n"
  author
  remove_yourself
  exit 0
}

event_alert_archive_delete_finish() {
  header
  echo -e "${GRAY_R}#${RESET} All Alerts and Events have been successfully archived/deleted! \\n\\n"
  author
  remove_yourself
  exit 0
}

devices_update_finish() {
  header
  if [[ "${uap_upgrade_done}" == 'no' ]] && [[ "${uap_upgrade_schedule_done}" == 'no' ]] && [[ "${usw_upgrade_done}" == 'no' ]] && [[ "${usw_upgrade_schedule_done}" == 'no' ]] && [[ "${ugw_upgrade_done}" == 'no' ]] && [[ "${ugw_upgrade_schedule_done}" == 'no' ]]; then
    echo -e "${GRAY_R}#${RESET} There were 0 devices to ${unifi_upgrade_devices_var_2}.. sorry :)"
  else
    if [[ "${uap_upgrade_schedule_done}" == 'yes' || "${usw_upgrade_schedule_done}" == 'yes' || "${ugw_upgrade_schedule_done}" == 'yes' ]]; then
      echo -e "${GRAY_R}#${RESET} Your UniFi devices have been scheduled to ${unifi_upgrade_devices_var_2}!"
    else
      echo -e "${GRAY_R}#${RESET} Your UniFi devices have been successfully ${unifi_upgrade_devices_var_2}d!"
    fi
  fi
  check_mongodb_connection
  if [[ "${mongodb_connected}" == 'true' ]]; then
    if [[ "${first_digit_unifi}" -ge '6' ]] || [[ "${first_digit_unifi}" -ge '5' && "${second_digit_unifi}" -ge '12' ]]; then mail_server_recommendation; fi
  fi
  echo -e "\\n"
  author
  remove_yourself
  exit 0
}

cancel_script() {
  if [[ "${set_lc_all}" == 'true' ]]; then if [[ -n "${original_lang}" ]]; then export LANG="${original_lang}"; else unset LANG; fi; if [[ -n "${original_lcall}" ]]; then export LC_ALL="${original_lcall}"; else unset LC_ALL; fi; fi
  if [[ "${stopped_unattended_upgrade}" == 'true' ]]; then systemctl start unattended-upgrades &>> "${eus_dir}/logs/unattended-upgrades.log"; unset stopped_unattended_upgrade; fi
  if [[ "${script_option_skip}" == 'true' ]]; then
    echo -e "\\n${GRAY_R}#########################################################################${RESET}\\n"
  else
    header
  fi
  if [[ "${exit_after_check_multiple_default_lan_networks}" == "true" ]]; then script_cancel_message_1="Exiting"; else script_cancel_message_1="Cancelling"; fi
  echo -e "${GRAY_R}#${RESET} ${script_cancel_message_1} the script!\\n\\n"
  author
  update_eus_db
  cleanup_codename_mismatch_repos
  remove_yourself
  exit 0
}

application_startup_message() {
  header
  echo -e "${GRAY_R}#${RESET} UniFi Network Application is starting up..."
  echo -e "${GRAY_R}#${RESET} Please wait a moment.\\n\\n"
}

not_supported_version() {
  debug_check_no_upgrade
  login_cleanup
  script_cleanup
  header
  echo -e "${GRAY_R}#${RESET} Your UniFi Network Application is on a release that is not ( yet ) supported in this script."
  echo -e "${GRAY_R}#${RESET} Feel free to contact Glenn R. (AmazedMender16) on the Community Forums if you need help upgrading your UniFi Network Application.\\n"
  echo -e "${GRAY_R}#${RESET} Current version of your UniFi Network Application | ${GRAY_R}$unifi${RESET}"
  backup_save_location
  echo -e "\\n"
  exit 1
}

get_sysinfo() {
  if [[ "${application_login}" == 'success' ]]; then
    if ! [[ -f /tmp/EUS/application/sysinfo ]]; then
      ${unifi_api_curl_cmd} "$unifi_api_baseurl/api/s/default/stat/sysinfo" &>> /tmp/EUS/application/sysinfo_tmp
      tr -d '[:space:]' < /tmp/EUS/application/sysinfo_tmp > /tmp/EUS/application/sysinfo
      sysinfo_version=$(grep -io '"version":".*"' /tmp/EUS/application/sysinfo | cut -d':' -f2 | cut -d'}' -f1 | tr -d '"' | cut -d'.' -f1-2 | tr -d '.')
    fi
   else
    sysinfo_version=$("$(which dpkg)" -l | awk '$2 == "unifi" {print $3}' | sed 's/-.*//' | cut -d'.' -f1-2 | tr -d '.')
  fi
}

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

check_service_timeoutsec_increase() {
  current_timeoutsec_value="$(grep -si "TimeoutSec" /etc/systemd/system/unifi.service.d/override.conf /lib/systemd/system/unifi.service 2> /dev/null | sed 's/ *TimeoutSec *= *\([0-9]*\)min/\1/g' | awk -F: '{print $2}' | sort -n | tail -n 1)"
  if [[ -z "${current_timeoutsec_value}" ]]; then current_timeoutsec_value="15"; fi
  if [[ "${limited_functionality}" != 'true' ]]; then
    if [[ "${mongodb_upgrade_started_success_value}" != 'true' ]]; then unifi_data_size="$("${mongocommand}" --quiet --port 27117 ace --eval "var stats = db.stats(); print(Math.floor(stats.dataSize / (1024 * 1024 * 1024)))" 2> /dev/null)"; fi
    if ! [[ "${unifi_data_size}" =~ ^[0-9]+$ ]]; then unifi_data_size="$(du -s /usr/lib/unifi/data/db | awk '{print int($1 / (1024 * 1024))}')"; fi
    if [[ "${unifi_data_size}" -ge "5" ]]; then
      timeoutsec_value="$((unifi_data_size * 2 + 5))"
      if [[ "${timeoutsec_value}" -gt "15" && "${current_timeoutsec_value}" != "${timeoutsec_value}" ]]; then
        current_timeoutsec_value="${timeoutsec_value}"
        echo -e "$(date +%F-%T.%6N:%S) | MongoDB dataSize is ${unifi_data_size}, increasing TimeoutSec to ${timeoutsec_value}" &>> "${eus_dir}/logs/unifi-service-timeoutsec-increase.log"
        if ! [[ -d "/etc/systemd/system/unifi.service.d/" ]]; then eus_directory_location="/etc/systemd/system"; eus_create_directories "unifi.service.d"; fi
        if grep -siq "^\[Service\]" /etc/systemd/system/unifi.service.d/override.conf; then
          if grep -siq "^TimeoutSec" /etc/systemd/system/unifi.service.d/override.conf; then
            sed -i "s/^TimeoutSec=.*/TimeoutSec=${timeoutsec_value}min/" /etc/systemd/system/unifi.service.d/override.conf
          else
            sed -i "/^\[Service\]/a TimeoutSec=${timeoutsec_value}min" /etc/systemd/system/unifi.service.d/override.conf
          fi
        else
          echo -e "[Service]\nTimeoutSec=${timeoutsec_value}min" | tee /etc/systemd/system/unifi.service.d/override.conf &> /dev/null
        fi
        systemctl daemon-reload &> /dev/null
        systemctl reset-failed unifi.service &> /dev/null
      fi
    fi
  fi
  if [[ "${current_timeoutsec_value}" -gt "60" ]]; then
    unifi_upgrade_estimate_duration_hours="$((current_timeoutsec_value / 60))"
    if [[ "${unifi_upgrade_estimate_duration_hours}" -gt "1" ]]; then unifi_upgrade_estimate_duration_hours_variable="hours"; else unifi_upgrade_estimate_duration_hours_variable="hour"; fi
    unifi_upgrade_estimate_duration_minutes="$((current_timeoutsec_value % 60))"
    if [[ "${unifi_upgrade_estimate_duration_minutes}" -gt "1" ]]; then unifi_upgrade_estimate_duration_minutes_variable="minutes"; else unifi_upgrade_estimate_duration_minutes_variable="minute"; fi
    if [[ "${unifi_upgrade_estimate_duration_minutes}" -gt "0" ]]; then
      unifi_upgrade_estimate_duration="${unifi_upgrade_estimate_duration_hours} ${unifi_upgrade_estimate_duration_hours_variable} and ${unifi_upgrade_estimate_duration_minutes} ${unifi_upgrade_estimate_duration_minutes_variable}"
    else
      unifi_upgrade_estimate_duration="${unifi_upgrade_estimate_duration_hours} ${unifi_upgrade_estimate_duration_minutes_variable}"
    fi
  else
    unifi_upgrade_estimate_duration="${current_timeoutsec_value} minutes"
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

db_version_check() {
  if [[ -z "$(cat "$(readlink -f /usr/lib/unifi/data/db/version)")" ]]; then
    "$(which dpkg)" -l unifi | tail -n1 |  awk '{print $3}' | cut -d'-' -f1 &> "$(readlink -f /usr/lib/unifi/data/db/version)"
  fi
}

keystore_alias_check() {
  if [[ -n "$(command -v keytool)" ]]; then
    if keytool -v -list -keystore /usr/lib/unifi/data/keystore -deststorepass aircontrolenterprise -alias unifi 2> /dev/null | grep -ioq "alias.*unifi.*does not exist"; then
      mv /usr/lib/unifi/data/keystore "/usr/lib/unifi/data/keystore.EUS_detected_invalid_$(date +%Y%m%d_%H%M_%S%N)"
      echo -e "$(date +%F-%T.%6N:%S) | Invalid keystore detected... unifi alias missing!" &>> "${eus_dir}/logs/keystore-alias-check.log"
      keystore_alias_checked="true"
    fi
  fi
}

unifi_autobackup_dir_check() {
  unifi_autobackup_dir="$(grep "^autobackup.dir" /usr/lib/unifi/data/system.properties 2> /dev/null | sed 's/autobackup.dir=//g')"
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

cleanup_backup_files() {
  if [[ "$(find "${cleanup_backup_files_dir}" -maxdepth 1 -type f -name "*.unf" | wc -l)" -gt '5' ]]; then
    unifi_script_backup_free_up="0"
    while read -r unifi_script_backup_oldest_file; do
      unifi_script_backup_oldest_file_size="$(stat -c %s "${unifi_script_backup_oldest_file}")"
      unifi_script_backup_free_up="$((unifi_script_backup_free_up + unifi_script_backup_oldest_file_size))"
    done < <(find "${cleanup_backup_files_dir}" -maxdepth 1 -type f -name "*.unf" -exec stat -c '%X %n' {} \; | sort -nr | awk 'NR>5 {print $2}')
    unifi_script_backup_amount_oldest_files="$(find "${cleanup_backup_files_dir}" -maxdepth 1 -type f -name "*.unf" -exec stat -c '%X %n' {} \; | sort -nr | awk 'NR>5 {print $2}' | wc -l)"
    if [[ "${unifi_script_backup_amount_oldest_files}" -gt '1' ]]; then unifi_script_backup_text_1="s"; unifi_script_backup_text_2="these"; else unifi_script_backup_text_2="this"; fi
    if [[ "${cleanup_backup_files_during_mongodb_upgrade}" != 'true' ]]; then header; else echo ""; fi
    echo -e "${GRAY_R}#${RESET} The script has detected ${unifi_script_backup_amount_oldest_files} old backup file${unifi_script_backup_text_1}, erasing ${unifi_script_backup_text_2} older backup${unifi_script_backup_text_1} will free up $(echo "${unifi_script_backup_free_up}" | awk '{ split( "B KB MB GB TB PB EB ZB YB" , v ); s=1; while( $1>1024 && s<9 ){ $1/=1024; s++ } printf "%.1f %s", $1, v[s] }') on your disk."
    while true; do
      read -rp $'\033[39m#\033[0m The script will keep the latest 5 backup files, do you want to free up the disk space? (y/N) ' yes_no
      case "$yes_no" in
          [Yy]*)
            if [[ "${cleanup_backup_files_during_mongodb_upgrade}" != 'true' ]]; then header; else echo ""; fi
            echo -e "${GRAY_R}#${RESET} Erasing ${unifi_script_backup_amount_oldest_files} backup file${unifi_script_backup_text_1}..."
            if find "${cleanup_backup_files_dir}" -type f -name "*.unf" -exec stat -c '%X %n' {} \; | sort -nr | awk 'NR>5 {print $2}' | xargs rm --force; then
              echo -e "${GREEN}#${RESET} Successfully deleted the old backup file${unifi_script_backup_text_1}! \\n"
            else
              echo -e "${RED}#${RESET} Failed to delete the old backup file${unifi_script_backup_text_1}... \\n"
            fi
            sleep 2
            if [[ "${cleanup_backup_files_during_mongodb_upgrade}" == 'true' ]]; then cleanup_backup_files_during_mongodb_upgrade_complete="true"; fi
            break;;
          [Nn]*|"")
            echo -e "\\n${GRAY_R}#${RESET} Alright! the script will keep the backups on your system! \\n\\n"
            sleep 2
            break;;
          *) echo -e "\\n${RED}#${RESET} Invalid input, please answer Yes or No (y/n)...\\n"; sleep 3;;
      esac
    done
  fi
}

monitor_update_progress_pid() {
  get_unifi_api_ports
  while kill -0 "${1}" 2>/dev/null; do
    monitor_update_progress_pid_database_status="$(curl --silent --insecure --connect-timeout 1 "${status_api_protocol}://localhost:${dmport}/status" | jq -r '.meta."db_migrating"' 2> /dev/null | sed '/null/d')"
    if [[ -z "${monitor_update_progress_pid_database_status}" ]]; then monitor_update_progress_pid_database_status="$(curl "${noproxy_curl_argument[@]}" --silent --insecure --connect-timeout 1 "${status_api_protocol}://localhost:${dmport}/status" | jq -r '.meta."db_migrating"' 2> /dev/null | sed '/null/d')"; fi
    if [[ "${monitor_update_progress_pid_database_status}" == 'true' ]]; then
      unifi_update_process="$(curl --silent --insecure --connect-timeout 1 "${status_api_protocol}://localhost:${dmport}/status" | jq -r '.meta."app_context_message"' 2> /dev/null | sed '/null/d')"
      if [[ -z "${unifi_update_process}" ]]; then unifi_update_process="$(curl "${noproxy_curl_argument[@]}" --silent --insecure --connect-timeout 1 "${status_api_protocol}://localhost:${dmport}/status" | jq -r '.meta."app_context_message"' 2> /dev/null | sed '/null/d')"; fi
      if [[ -n "${unifi_update_process}" ]]; then
        if [[ "${database_migration_message}" != 'true' ]]; then echo -e "\\n${GRAY_R}#${RESET} Database Migration in progress..."; database_migration_message="true"; fi
        echo -ne "\033[K${GRAY_R}#${RESET} ${unifi_update_process}...\\r"
      fi
    fi
    sleep 3
  done
  echo ""
}

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                          Script options                                                                                         #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

only_archive_or_delete() {
  mongodb_server_version=$("$(which dpkg)" -l | grep "^ii\\|^hi\\|^ri\\|^pi\\|^ui\\|^iU" | grep -E "(mongodb-server|mongodb-org-server|mongod-armv8|mongod-amd64)[[:space:]]" | awk '{print $3}' | sed -e 's/.*://' -e 's/-.*//' -e 's/+.*//' -e 's/\.//g')
  header
  if [[ "${script_option_archive_alerts}" == 'true' ]]; then
    echo -e "${GRAY_R}#${RESET} Archiving the Alerts..."
    if [[ "${mongodb_server_version::2}" -gt "30" ]]; then
      # shellcheck disable=SC2016
      modified_count="$("${mongocommand}" --quiet --port 27117 ace --eval ''"${mongoprefix}"'db.alarm.updateMany({},{"$set": {"archived": true}}) )' | jq '."modifiedCount"')"
      echo -e "${GREEN}#${RESET} Successfully archived ${modified_count} Alerts..."
    else
      # shellcheck disable=SC2016
      "${mongocommand}" --quiet --port 27117 ace --eval 'db.alarm.update({},{$set: {"archived": true}},{multi: true})' | awk '{ nModified=$10 ; print "\033[1;32m#\033[0m Successfully archived " nModified " Alerts" }' # nModified
    fi
    echo -e "\\n"
  fi
  if [[ "${script_option_delete_events}" == 'true' ]]; then
    echo -e "${GRAY_R}#${RESET} Deleting all Alerts..."
    if [[ "${mongodb_server_version::2}" -gt "30" ]]; then
      deleted_count="$("${mongocommand}" --quiet --port 27117 ace --eval "${mongoprefix}db.alarm.deleteMany({}) )" | jq '."deletedCount"')"
      echo -e "${GREEN}#${RESET} Successfully deleted ${deleted_count} Alerts..."
    else
      # shellcheck disable=SC2016
      "${mongocommand}" --quiet --port 27117 ace --eval 'db.alarm.remove({},{multi: true})' | awk '{ nRemoved=$4 ; print "\033[1;32m#\033[0m Successfully deleted " nRemoved " Alerts" }' # nRemoved
    fi
    echo -e "\\n"
  fi
  author
  remove_yourself
  exit 0
}

if [[ "${script_option_archive_alerts}" == 'true' || "${script_option_delete_events}" == 'true' ]]; then only_archive_or_delete; fi

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                  UniFi API Login/Logout/Cleanup                                                                                 #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

username_text() {
  header
  if [[ "${unifi_core_system}" == 'true' ]]; then
    echo -e "${YELLOW}#${RESET} Please use the Owner or any other Super Administrator account."
  else
    echo -e "${YELLOW}#${RESET} Please use your Super Administrator credentials."
  fi
  echo -e "${YELLOW}#${RESET} The credentials will only be used to login to your application installation ( api ), the credentials will not be saved."
  echo -e "\\n${GRAY_R}---${RESET}\\n"
  if [[ "${unifi_core_system}" == 'true' ]]; then
    echo -e "${GRAY_R}#${RESET} What is your UniFi OS Username?\\n\\n"
  else
    echo -e "${GRAY_R}#${RESET} What is your UniFi Network Application Username?\\n\\n"
  fi
}

password_text() {
  header
  if [[ "${unifi_core_system}" == 'true' ]]; then
    echo -e "${GRAY_R}#${RESET} What is your UniFi OS Password?\\n\\n"
  else
    echo -e "${GRAY_R}#${RESET} What is your UniFi Network Application Password?\\n\\n"
  fi
}

two_factor_request() {
  echo -e "${GRAY_R}#${RESET} Insert your 2FA token ( 6 Digits Token )\\n\\n"
  read -rp $' 2FA Token:\033[39m ' ubic_2fa_token
  if [[ -z "$ubic_2fa_token" ]]; then
    header_red
    echo -e "${GRAY_R}#${RESET} 2FA Token can't be blank...\\n\\n"
    sleep 3
    unset ubic_2fa_token
    read -rp $' 2FA Token:\033[39m ' ubic_2fa_token
  fi
}

unifi_credentials() {
  username_text
  read -rp $' Username:\033[39m ' username
  if [[ -z "$username" ]]; then
    header_red
    echo -e "${GRAY_R}#${RESET} Username can't be blank...\\n\\n"
    sleep 3
    unset username
    username_text
    read -rp $' Username:\033[39m ' username
  fi
  password_text
  read -srp " Password: " password
  if [[ -z "$password" ]]; then
    header_red
    echo -e "${GRAY_R}#${RESET} Password can't be blank...\\n\\n"
    sleep 3
    unset password
    password_text
    read -srp " Password: " password
  fi
  header
  echo -e "${GRAY_R}#${RESET} Attempting to login..."
}

username_case_sensitive_check() {
  backup_username="${username}"
  username="$("${mongocommand}" --quiet --port 27117 ace --eval "${mongoprefix}db.getCollection('admin').find({})${mongosuffix}" | sed 's/\(ObjectId(\|)\|NumberLong(\)//g' | jq -r '.[] | .name, .email' | grep -ix "\\b${username}\\b")"
  if [[ -z "${username}" ]]; then username="${backup_username}"; unset backup_username; fi
}

unifi_login() {
  if [[ "${executed_unifi_login}" != 'true' ]]; then
    username_case_sensitive_check
    if "$(which dpkg)" -l unifi-core 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
      if [[ "${two_factor}" == 'enabled' ]]; then
        jq -n --arg username "$username" --arg password "$password" --arg ubic_2fa_token "$ubic_2fa_token" '{username: $username, password: $password, token: $ubic_2fa_token}' | ${unifi_api_curl_cmd} -d@- --header "Content-Type: application/json" "https://localhost/api/auth/login" &>> /tmp/EUS/application/login
      else
        jq -n --arg username "$username" --arg password "$password" '{username: $username, password: $password}' | ${unifi_api_curl_cmd} -d@- --header "Content-Type: application/json" "https://localhost/api/auth/login" &>> /tmp/EUS/application/login
      fi
    else
      if [[ "${two_factor}" == 'enabled' ]]; then
        jq -n --arg username "$username" --arg password "$password" --arg ubic_2fa_token "$ubic_2fa_token" '{username: $username, password: $password, ubic_2fa_token: $ubic_2fa_token}' | ${unifi_api_curl_cmd} -d@- "$unifi_api_baseurl/api/login" >> /tmp/EUS/application/login
      else
        jq -n --arg username "$username" --arg password "$password" '{username: $username, password: $password}' | ${unifi_api_curl_cmd} -d@- "$unifi_api_baseurl/api/login" >> /tmp/EUS/application/login
      fi
    fi
    unifi_login_check
    super_user_check
    executed_unifi_login="true"
  fi
}

unifi_logout() {
  ${unifi_api_curl_cmd} "$unifi_api_baseurl/logout"
  executed_unifi_login="false"
}

super_user_check() {
  if "$(which dpkg)" -l unifi-core 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
    jq --raw-output '.permissions["network.management"] | .[]' /tmp/EUS/application/login &> /tmp/EUS/accounts/network_permissions
    jq --raw-output '.isSuperAdmin' /tmp/EUS/application/login &> /tmp/EUS/accounts/super_admin
    #if grep -iq 'true' /tmp/EUS/accounts/super_admin; then user_is_super="true"; fi
    if grep -iq 'admin' /tmp/EUS/accounts/network_permissions; then user_is_admin="true"; fi
    if grep -iq 'readonly' /tmp/EUS/accounts/network_permissions; then user_is_readonly="true"; fi
    if [[ "${user_is_readonly}" == 'true' && "${user_is_admin}" == 'true' ]]; then
      header_red
      echo -e "${GRAY_R}#${RESET} The user is an Administrator and Read Only user!"
      echo -e "${GRAY_R}#${RESET} Please remove the read only permission or login with administrator account! \\n\\n"
      while true; do
        read -rp $'\033[39m#\033[0m Would you like to try another account? (Y/n) ' yes_no
        case "$yes_no" in
            [Yy]*|"")
              unifi_login_cleanup
              login_cleanup
              unifi_logout
              unifi_credentials
              unifi_login
              break;;
            [Nn]*) unifi_backup_cancel="true"; break;;
            *) echo -e "\\n${RED}#${RESET} Invalid input, please answer Yes or No (y/n)...\\n"; sleep 3;;
        esac
      done
    fi
  else
    net_super_site_id="$("${mongocommand}" --quiet --port 27117 ace --eval "${mongoprefix}db.getCollection('site').find({key:'super'})${mongosuffix}" | sed 's/\(ObjectId(\|)\|NumberLong(\)//g' | jq -r '.[]._id[]')"
    if [[ -z "${net_super_site_id}" ]]; then net_super_site_id="$("${mongocommand}" --quiet --port 27117 ace --eval "db.getCollection('site').find({key:'super'}).toArray()" | sed 's/\(ObjectId(\|)\|NumberLong(\)//g' | jq -r '.[]._id')"; fi
    script_admin_id="$("${mongocommand}" --quiet --port 27117 ace --eval "${mongoprefix}db.getCollection('admin').find({name:'${username}'})${mongosuffix}" | sed 's/\(ObjectId(\|)\|NumberLong(\)//g' | jq -r '.[]._id[]' | head -n1)"
    if [[ -z "${script_admin_id}" ]]; then script_admin_id="$("${mongocommand}" --quiet --port 27117 ace --eval "db.getCollection('admin').find({name:'${username}'}).toArray()" | sed 's/\(ObjectId(\|)\|NumberLong(\)//g' | jq -r '.[]._id' | head -n1)"; fi
    if [[ -z "${script_admin_id}" ]]; then
      script_admin_id="$("${mongocommand}" --quiet --port 27117 ace --eval "${mongoprefix}db.getCollection('admin').find({email:'${username}'})${mongosuffix}" | sed 's/\(ObjectId(\|)\|NumberLong(\)//g' | jq -r '.[]._id[]' | head -n1)"
      if [[ -z "${script_admin_id}" ]]; then script_admin_id="$("${mongocommand}" --quiet --port 27117 ace --eval "db.getCollection('admin').find({email:'${username}'}).toArray()" | sed 's/\(ObjectId(\|)\|NumberLong(\)//g' | jq -r '.[]._id' | head -n1)"; fi
    fi
    if ! [[ "${script_admin_id}" =~ ^($("${mongocommand}" --quiet --port 27117 ace --eval "${mongoprefix}db.getCollection('privilege').find({site_id:'${net_super_site_id}', role:'admin'})${mongosuffix}" | sed 's/\(ObjectId(\|)\|NumberLong(\)//g' | jq -r '.[].admin_id' | tr "\n" "|" | sed 's/|$//'))$ ]]; then
      header_red
      echo -e "${GRAY_R}#${RESET} Account/User ${GRAY_R}${username}${RESET} is not a Super Administrator.."
      echo -e "${GRAY_R}#${RESET} Please use the Super Administrator credentials! \\n\\n"
      while true; do
        read -rp $'\033[39m#\033[0m Would you like to try another account? (Y/n) ' yes_no
        case "$yes_no" in
            [Yy]*|"")
              unifi_login_cleanup
              login_cleanup
              unifi_logout
              unifi_credentials
              unifi_login
              break;;
            [Nn]*) unifi_backup_cancel="true"; break;;
            *) echo -e "\\n${RED}#${RESET} Invalid input, please answer Yes or No (y/n)...\\n"; sleep 3;;
        esac
      done
    fi
  fi
}

unifi_login_check() {
  net_admin="$("${mongocommand}" --quiet --port 27117 ace --eval "${mongoprefix}db.getCollection('admin').find({name:'${username}'})${mongosuffix}" | sed 's/\(ObjectId(\|)\|NumberLong(\)//g' | jq -r '.[]._id[]')"
  if [[ -z "${net_admin}" ]]; then net_admin="$("${mongocommand}" --quiet --port 27117 ace --eval "db.getCollection('admin').find({name:'${username}'}).toArray()" | sed 's/\(ObjectId(\|)\|NumberLong(\)//g' | jq -r '.[]._id')"; fi
  if [[ -z "${net_admin}" ]]; then
    net_admin="$("${mongocommand}" --quiet --port 27117 ace --eval "${mongoprefix}db.getCollection('admin').find({email:'${username}'})${mongosuffix}" | sed 's/\(ObjectId(\|)\|NumberLong(\)//g' | jq -r '.[]._id[]')"
    if [[ -z "${net_admin}" ]]; then net_admin="$("${mongocommand}" --quiet --port 27117 ace --eval "db.getCollection('admin').find({email:'${username}'}).toArray()" | sed 's/\(ObjectId(\|)\|NumberLong(\)//g' | jq -r '.[]._id')"; fi
  fi
  if [[ ( -z "${net_admin}" && "${unifi_core_system}" != 'true' ) ]]; then
    header_red
    echo -e "${GRAY_R}#${RESET} Account/User ${GRAY_R}${username}${RESET} does not exist in the database\\n\\n"
    while true; do
      read -rp $'\033[39m#\033[0m Would you like to try another account? (Y/n) ' yes_no
      case "$yes_no" in
          [Yy]*|"")
            unifi_login_cleanup
            login_cleanup
            unifi_credentials
            unifi_login
            break;;
          [Nn]*) 
            unifi_backup_cancel="true"
            unifi_login_cleanup
            break;;
          *) echo -e "\\n${RED}#${RESET} Invalid input, please answer Yes or No (y/n)...\\n"; sleep 3;;
      esac
    done
  elif grep -iq "Ubic2faToken.*Required\\|2fa.*required" /tmp/EUS/application/login; then
    unifi_login_cleanup
    header
    #echo -e "${GRAY_R}#${RESET} You seem to have 2FA enabled on your UBNT account.."
    two_factor=enabled
    two_factor_request
    unifi_login
  elif grep -iq "Invalid2FAToken" /tmp/EUS/application/login; then
    unifi_login_cleanup
    header_red
    echo -e "${GRAY_R}#${RESET} Login error... Invalid 2FA Token"
    two_factor=enabled
    two_factor_request
    unifi_login
  elif grep -iq "Invalid.*username.*password" /tmp/EUS/application/login; then
    unifi_login_cleanup
    header_red
    echo -e "${GRAY_R}#${RESET} Invalid username or password..."
    while true; do
      read -rp $'\033[39m#\033[0m Would you like to try again? (Y/n) ' yes_no
      case "$yes_no" in
          [Yy]*|"")
            unifi_login_cleanup
            unifi_credentials
            unifi_login
            break;;
          [Nn]*)
            unifi_backup_cancel="true"
            unifi_login_cleanup
            break;;
          *) echo -e "\\n${RED}#${RESET} Invalid input, please answer Yes or No (y/n)...\\n"; sleep 3;;
      esac
    done
  elif grep -iq "error\\|Invalid.*username.*password" /tmp/EUS/application/login; then
    header_red
    echo -e "${GRAY_R}#${RESET} ${unifi_os_or_network} credentials are incorrect, login failed.."
    while true; do
      read -rp $'\033[39m#\033[0m Would you like to try again? (Y/n) ' yes_no
      case "$yes_no" in
          [Yy]*|"")
            unifi_login_cleanup
            unifi_credentials
            unifi_login
            break;;
          [Nn]*)
            unifi_backup_cancel="true"
            unifi_login_cleanup
            break;;
          *) echo -e "\\n${RED}#${RESET} Invalid input, please answer Yes or No (y/n)...\\n"; sleep 3;;
      esac
    done
  elif grep -iq "ok\\|id" /tmp/EUS/application/login; then
    application_login="success"
    unifi_login_cleanup
    header
    echo -e "${GRAY_R}#${RESET} Login success! \\n"
  fi
}

login_cleanup() {
  unset username
  unset password
  unset ubic_2fa_token
  unset user_name
  unset user_email
  unset user_name_exist
  unset user_email_exist
  unifi_login_cleanup
}

unifi_login_cleanup() {
  if ! "$(which dpkg)" -l unifi-core 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then rm --force /tmp/EUS/application/login 2> /dev/null; fi
  if [[ "${application_login}" != 'success' ]]; then rm --force /tmp/EUS/application/login 2> /dev/null; fi
}

application_login_attempt() {
  unifi_login
  while grep -q "error" /tmp/EUS/application/login &> /dev/null; do
    unifi_login
    unifi_login_cleanup
    application_startup_message
    sleep 5
  done;
  unifi_logout
}

debug_check () {
  if [[ -z "${site}" ]]; then executed_unifi_list_sites="false"; unifi_list_sites; fi
  get_sysinfo
  if [[ -f /tmp/EUS/application/sysinfo ]]; then
    if grep -iq '"debug_mgmt":"warn"' /tmp/EUS/application/sysinfo || grep -iq '"debug_system":"warn"' /tmp/EUS/application/sysinfo; then
      header
      if [[ "${sysinfo_version}" -ge '511' ]]; then log_level_setting='Verbose'; else log_level_setting='More'; fi
      echo -e "${GRAY_R}#${RESET} Settings log level for management and system to ${log_level_setting}, this is required for the script to get the needed information."
      debug_warn_info="true"
      ${unifi_api_curl_cmd} --data "{\"cmd\":\"set-param\", \"key\":\"debug.mgmt\", \"value\":\"info\"}" "$unifi_api_baseurl/api/s/${site}/cmd/system" &>> /tmp/EUS/application/log_levels
      ${unifi_api_curl_cmd} --data "{\"cmd\":\"set-param\", \"key\":\"debug.system\", \"value\":\"info\"}" "$unifi_api_baseurl/api/s/${site}/cmd/system" &>> /tmp/EUS/application/log_levels
      sleep 3
      if ! grep "ok" /tmp/EUS/application/log_levels; then
        echo -e "${RED}#${RESET} Failed to set log level to ${log_level_setting}, please login to your UniFi Network Application and set the MGMT log level to ${log_level_setting}."
        echo -e "\\n${RED}#${RESET} UniFi Network Application Settings"
        echo -e "${RED}#${RESET} Settings > System > System Logging > Logging Levels"
        echo -e "\\n\\n${RED}#${RESET} Run the script again once you completed the step above."
        exit 1
      fi
    fi
  fi
}

debug_check_no_upgrade() {
  if [[ "${debug_warn_info}" == 'true' ]]; then
    header
    echo -e "${GRAY_R}#${RESET} Setting log level for management and system back to normal.\\n\\n"
    sleep 3
    ${unifi_api_curl_cmd} --data "{\"cmd\":\"set-param\", \"key\":\"debug.mgmt\", \"value\":\"warn\"}" "$unifi_api_baseurl/api/s/${site}/cmd/system" &>> /tmp/EUS/application/log_levels
    ${unifi_api_curl_cmd} --data "{\"cmd\":\"set-param\", \"key\":\"debug.system\", \"value\":\"info\"}" "$unifi_api_baseurl/api/s/${site}/cmd/system" &>> /tmp/EUS/application/log_levels
    if ! grep -iq "ok" /tmp/EUS/application/log_levels; then
      echo -e "${RED}#${RESET} Failed to set log level back to normal."
    fi
  fi
}

alert_event_cleanup() {
  #alert_find_m=$("${mongocommand}" --port 27117 ace --eval 'db.alarm.find({"ip":{ $regex: "127.0.0.1|0:0:0:0:0:0:0:1"}})' | grep -c "log.* 127.0.0.1\|log.* 0:0:0:0:0:0:0:1")
  #event_find_m=$("${mongocommand}" --port 27117 ace --eval 'db.event.find({"ip":{ $regex: "127.0.0.1|0:0:0:0:0:0:0:1"}})' | grep -c "log.* 127.0.0.1\|log.* 0:0:0:0:0:0:0:1")
  if [[ "${application_login}" == 'success' ]]; then
    mongodb_server_version=$("$(which dpkg)" -l | grep "^ii\\|^hi\\|^ri\\|^pi\\|^ui\\|^iU" | grep -E "(mongodb-server|mongodb-org-server|mongod-armv8|mongod-amd64)[[:space:]]" | awk '{print $3}' | sed -e 's/.*://' -e 's/-.*//' -e 's/+.*//' -e 's/\.//g')
    header
    echo -e "${GRAY_R}#${RESET} What would you like to do with the script login events?"
    echo -e "${GRAY_R}#${RESET} Deleting/Archiving can take a while on big setups.\\n"
    echo -e " [   ${WHITE_R}1${RESET}   ]  |  Delete the Events/Alerts ( default )"
    echo -e " [   ${WHITE_R}2${RESET}   ]  |  Archive the Alerts ( keeps the Alerts and deletes the Events )"
    echo -e " [   ${WHITE_R}3${RESET}   ]  |  Skip ( keep the Events/Alerts )\\n\\n\\n"
    read -rp $'Your choice | \033[39m' alert_event_cleanup_question
    case "$alert_event_cleanup_question" in
        1*|"")
          header
          echo -e "${GRAY_R}#${RESET} Deleting the Alerts/Events...\\n"
          sleep 2
          if [[ "${mongodb_server_version::2}" -gt "30" ]]; then
            # shellcheck disable=SC2154,SC2016
            deleted_count="$("${mongocommand}" --quiet --port 27117 ace --eval "${mongoprefix}db.alarm.deleteMany({'ip':{ '$regex': '127.0.0.1|0:0:0:0:0:0:0:1'}}) )" | jq '."deletedCount"')"
            echo -e "${GREEN}#${RESET} Successfully deleted ${deleted_count} Alerts..."
            # shellcheck disable=SC2154,SC2016
            deleted_count="$("${mongocommand}" --quiet --port 27117 ace --eval "${mongoprefix}db.event.deleteMany({'ip':{ '$regex': '127.0.0.1|0:0:0:0:0:0:0:1'}}) )" | jq '."deletedCount"')"
            echo -e "${GREEN}#${RESET} Successfully deleted ${deleted_count} Events..."
          else
            # shellcheck disable=SC2154,SC2016
            "${mongocommand}" --quiet --port 27117 ace --eval 'db.alarm.remove({"ip":{ $regex: "127.0.0.1|0:0:0:0:0:0:0:1"}},{multi: true})' | awk '{ nRemoved=$4 ; print "\033[1;32m#\033[0m Successfully deleted " nRemoved " Alerts" }' # nRemoved
            # shellcheck disable=SC2154,SC2016
            "${mongocommand}" --quiet --port 27117 ace --eval 'db.event.remove({"ip":{ $regex: "127.0.0.1|0:0:0:0:0:0:0:1"}},{multi: true})' | awk '{ nRemoved=$4 ; print "\033[1;32m#\033[0m Successfully deleted " nRemoved " Events" }' # nRemoved
          fi
          echo -e "\\n"
          sleep 2;;
        2*)
          header
          echo -e "${GRAY_R}#${RESET} Archiving the Alerts...\\n"
          if [[ "${mongodb_server_version::2}" -gt "30" ]]; then
            # shellcheck disable=SC2016,SC2154
            modified_count="$("${mongocommand}" --quiet --port 27117 ace --eval ''"${mongoprefix}"'db.alarm.updateMany({"ip":{ "$regex": "127.0.0.1|0:0:0:0:0:0:0:1"}},{"$set": {"archived": true}}) )' | jq '."modifiedCount"')"
            echo -e "${GREEN}#${RESET} Successfully archived ${modified_count} Alerts..."
            # shellcheck disable=SC2154,SC2016
            deleted_count="$("${mongocommand}" --quiet --port 27117 ace --eval "${mongoprefix}db.event.deleteMany({'ip':{ '$regex': '127.0.0.1|0:0:0:0:0:0:0:1'}}) )" | jq '."deletedCount"')"
            echo -e "${GREEN}#${RESET} Successfully deleted ${deleted_count} Events..."
          else
            # shellcheck disable=SC2016,SC2154
            "${mongocommand}" --quiet --port 27117 ace --eval 'db.alarm.update({"ip":{ $regex: "127.0.0.1|0:0:0:0:0:0:0:1"}},{$set: {"archived": true}},{multi: true})' | awk '{ nModified=$10 ; print "\033[1;32m#\033[0m Archived " nModified " Alerts" }' # nModified
            # shellcheck disable=SC2154,SC2016
            "${mongocommand}" --quiet --port 27117 ace --eval 'db.event.remove({"ip":{ $regex: "127.0.0.1|0:0:0:0:0:0:0:1"}},{multi: true})' | awk '{ nRemoved=$4 ; print "\033[1;32m#\033[0m Successfully deleted " nRemoved " Alerts" }' # nRemoved
          fi
          echo -e "\\n"
          sleep 2;;
        3*) ;;
    esac
  fi
}
###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                      UniFi Firmware Cache                                                                                       #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

unifi_firmware_check() {
  header
  echo -e "${GRAY_R}#${RESET} Checking for Firmware Updates..."
  ${unifi_api_curl_cmd} --data "{\"cmd\":\"check-firmware-update\"}" "$unifi_api_baseurl/api/s/${site}/cmd/system" &> /tmp/EUS/firmware/check
  if grep -iq 'ok' /tmp/EUS/firmware/check; then echo -e "${GREEN}#${RESET} Successfully checked for firmware updates"; fi
  rm --force /tmp/EUS/firmware/check 2> /dev/null
  sleep 3
}

unifi_cache_models() {
  header
  echo -e "${GRAY_R}#${RESET} Catching all the device models on your UniFi Network Application.."
  "${mongocommand}" --quiet --port 27117 ace --eval "${mongoprefix}db.getCollection('device').find({})${mongosuffix}" | jq -r '.[].model' | awk '!a[$0]++' &> /tmp/EUS/firmware/device_models
  if [[ -f /tmp/EUS/firmware/device_models && -s /tmp/EUS/firmware/device_models ]]; then echo -e "${GREEN}#${RESET} Successfully found all device models on your UniFi Network Application."; sleep 3; fi
  if grep -iq "UP1" /tmp/EUS/firmware/device_models; then echo "UP1" &>> /tmp/EUS/firmware/special_devices; fi
  if grep -iq "UP6" /tmp/EUS/firmware/device_models; then echo "UP6" &>> /tmp/EUS/firmware/special_devices; fi
  if grep -iq "USMINI" /tmp/EUS/firmware/device_models; then echo "USMINI" &>> /tmp/EUS/firmware/special_devices; fi
  sed -i -e '/UP1/d' -e '/UP6/d' -e '/USMINI/d' -e '/UDM/d' /tmp/EUS/firmware/device_models
}

unifi_cache_remove() {
  unifi_get_site_variable
  header
  ${unifi_api_curl_cmd} --data "{\"cmd\":\"list-cached\"}" "$unifi_api_baseurl/api/s/${site}/cmd/firmware" >> /tmp/EUS/firmware/cached
  while read -r device_model; do
    # shellcheck disable=SC2086
    fw_versions=$(jq -r '.data[] | select(.device == "'${device_model}'") | .version' /tmp/EUS/firmware/cached)
    for fw_version in "${fw_versions[@]}"; do
      echo -ne "\\r${GRAY_R}#${RESET} Removing firmware version ${fw_version} for ${device_model}..."
      ${unifi_api_curl_cmd} --data "{\"cmd\":\"remove\", \"device\":\"$device_model\", \"version\":\"$fw_version\"}" "$unifi_api_baseurl/api/s/${site}/cmd/firmware" >> /tmp/EUS/firmware/removed
      if grep -iq 'result.*true' /tmp/EUS/firmware/removed; then echo -e "\\r${GREEN}#${RESET} Successfully removed cached firmware version ${fw_version} for ${device_model}!"; fi
      if grep -iq 'result.*false' /tmp/EUS/firmware/removed; then echo -e "\\r${RED}#${RESET} Failed to remove cached firmware version ${fw_version} for ${device_model}..."; fi
      rm --force /tmp/EUS/firmware/removed 2> /dev/null
    done
  done < /tmp/EUS/firmware/base_models
  sleep 3
}

unifi_cache_download() {
  header
  echo -e "${GREEN}#${RESET} Downloading/Caching firmware versions for all device models on the UniFi Network Application..."
  echo -e "${GREEN}#${RESET} The duration of the download(s) depends on the internet connection.\\n\\n"
  ${unifi_api_curl_cmd} --data "{\"cmd\":\"list-cached\"}" "$unifi_api_baseurl/api/s/${site}/cmd/firmware" >> /tmp/EUS/firmware/currently_cached
  ${unifi_api_curl_cmd} --data "{\"cmd\":\"list-available\"}" "$unifi_api_baseurl/api/s/${site}/cmd/firmware" >> /tmp/EUS/firmware/available
  while read -r device_model; do
    # shellcheck disable=SC2086
    jq -r '.data[] | select(.device == "'${device_model}'") | .base_model' /tmp/EUS/firmware/available &>> /tmp/EUS/firmware/base_models_tmp
    # shellcheck disable=SC2086
    jq -r '.data[] | select(.device == "'${device_model}'") | .path' /tmp/EUS/firmware/currently_cached | cut -d'/' -f1 | awk '!a[$0]++' &>> /tmp/EUS/firmware/base_models_tmp
  done < /tmp/EUS/firmware/device_models
  if [[ -f /tmp/EUS/firmware/base_models_tmp ]]; then
    awk '!a[$0]++' /tmp/EUS/firmware/base_models_tmp &>> /tmp/EUS/firmware/base_models
    rm --force /tmp/EUS/firmware/base_models_tmp
  fi
  while read -r device_model; do
    # shellcheck disable=SC2086
    fw_version=$(jq -r '.data[] | select(.device == "'${device_model}'") | .version' /tmp/EUS/firmware/available | head -n1)
    # shellcheck disable=SC2086
    cached_fw_version=$(jq -r '.data[] | select(.device == "'${device_model}'") | .version' /tmp/EUS/firmware/currently_cached &> /tmp/EUS/firmware/all_currently_cached && head -n1 /tmp/EUS/firmware/all_currently_cached )
    cp /tmp/EUS/firmware/all_currently_cached /tmp/EUS/firmware/old_cached_firmware 2> /dev/null
    older_cached_fw=$(cat /tmp/EUS/firmware/old_cached_firmware && sed -i "/${cached_fw_version}/d" /tmp/EUS/firmware/old_cached_firmware)
    # shellcheck disable=SC2086
    if ! jq -r '.data[] | select(.device == "'${device_model}'")' /tmp/EUS/firmware/available | grep -iq "${device_model}"; then
      # shellcheck disable=SC2086
      if jq -r '.data[] | select(.device == "'${device_model}'")' /tmp/EUS/firmware/currently_cached | grep -iq "${device_model}"; then
        echo -e "${YELLOW}#${RESET} Firmware version ${cached_fw_version} for ${device_model} is already cached!" && sleep 1
      fi
    elif [[ "${cached_fw_version}" != "${fw_version}" ]]; then
      if [[ -n "${cached_fw_version}" ]]; then
        echo -ne "${GRAY_R}#${RESET} Removing cached firmware version ${version} for ${device_model}..."
        ${unifi_api_curl_cmd} --data "{\"cmd\":\"remove\", \"device\":\"$device_model\", \"version\":\"$cached_fw_version\"}" "$unifi_api_baseurl/api/s/${site}/cmd/firmware" >> /tmp/EUS/firmware/removed
        if grep -iq 'result.*true' /tmp/EUS/firmware/removed; then echo -e "\\r${GREEN}#${RESET} Successfully removed cached firmware version ${cached_fw_version} for ${device_model}!"; fi
        if grep -iq 'result.*false' /tmp/EUS/firmware/removed; then echo -e "\\r${RED}#${RESET} Failed to remove cached firmware version ${cached_fw_version} for ${device_model}..." && cache_download_failed="yes"; fi
        rm --force /tmp/EUS/firmware/removed 2> /dev/null
        removed_cached_fw="true"
      fi
    fi
    if [[ -n "${older_cached_fw}" ]]; then
      while read -r version; do
        echo -ne "\\r${GRAY_R}#${RESET} Removing older cached firmware version ${version} for ${device_model}..."
        ${unifi_api_curl_cmd} --data "{\"cmd\":\"remove\", \"device\":\"$device_model\", \"version\":\"$version\"}" "$unifi_api_baseurl/api/s/${site}/cmd/firmware" >> /tmp/EUS/firmware/removed
        if grep -iq 'result.*true' /tmp/EUS/firmware/removed; then echo -e "\\r${GREEN}#${RESET} Successfully removed older cached firmware version ${version} for ${device_model}!"; fi
        if grep -iq 'result.*false' /tmp/EUS/firmware/removed; then echo -e "\\r${RED}#${RESET} Failed to remove cached firmware version ${version} for ${device_model}..." && cache_download_failed="yes"; fi
        rm --force /tmp/EUS/firmware/removed 2> /dev/null
        removed_cached_fw="true"
      done < /tmp/EUS/firmware/old_cached_firmware
    fi
    # shellcheck disable=SC2086
    if [[ "${removed_cached_fw}" == 'true' ]] || jq -r '.data[] | select(.device == "'${device_model}'")' /tmp/EUS/firmware/available | grep -iq "${device_model}" &> /dev/null; then
      echo -ne "\\r${GRAY_R}#${RESET} Downloading firmware version ${fw_version} for ${device_model}..."
      ${unifi_api_curl_cmd} --data "{\"cmd\":\"download\", \"device\":\"$device_model\", \"version\":\"$fw_version\"}" "$unifi_api_baseurl/api/s/${site}/cmd/firmware" >> /tmp/EUS/firmware/download
      if grep -iq 'result.*true' /tmp/EUS/firmware/download; then echo -e "\\r${GREEN}#${RESET} Successfully downloaded firmware version ${fw_version} for ${device_model}!"; fi
      if grep -iq 'result.*false' /tmp/EUS/firmware/download; then echo -e "\\r${RED}#${RESET} Failed to downloaded firmware version ${fw_version} for ${device_model}..." && cache_download_failed="yes"; fi
      rm --force /tmp/EUS/firmware/download 2> /dev/null
    fi
    unset removed_cached_fw
  done < /tmp/EUS/firmware/base_models
  if [[ -f /tmp/EUS/firmware/special_devices && -s /tmp/EUS/firmware/special_devices ]]; then
    while read -r device_model; do
      # shellcheck disable=SC2086
      cached_fw_version=$(jq -r '.data[] | select(.device == "'${device_model}'") | .version' /tmp/EUS/firmware/currently_cached &> /tmp/EUS/firmware/all_currently_cached && head -n1 /tmp/EUS/firmware/all_currently_cached )
      if [[ -n "${cached_fw_version}" ]]; then 
        echo -ne "\\r${GRAY_R}#${RESET} Removing cached firmware version ${cached_fw_version} for ${device_model}..."
        ${unifi_api_curl_cmd} --data "{\"cmd\":\"remove\", \"device\":\"$device_model\", \"version\":\"$cached_fw_version\"}" "$unifi_api_baseurl/api/s/${site}/cmd/firmware" >> /tmp/EUS/firmware/removed
        if grep -iq 'result.*true' /tmp/EUS/firmware/removed; then echo -e "\\r${GREEN}#${RESET} Successfully removed cached firmware version ${cached_fw_version} for ${device_model}!"; fi
        if grep -iq 'result.*false' /tmp/EUS/firmware/removed; then echo -e "\\r${RED}#${RESET} Failed to removed cached firmware version ${cached_fw_version} for ${device_model}..."; fi
        rm --force /tmp/EUS/firmware/removed 2> /dev/null
      fi
    done < /tmp/EUS/firmware/special_devices
  fi
  rm --force /tmp/EUS/firmware/special_devices &> /dev/null
  sleep 3
  ${unifi_api_curl_cmd} --data "{\"cmd\":\"list-cached\"}" "$unifi_api_baseurl/api/s/${site}/cmd/firmware" >> /tmp/EUS/firmware/cached_firmware
  if [[ "${cache_download_failed}" != 'yes' ]]; then
    firmware_cached="yes"
  else
    firmware_cached="no"
  fi
  rm --force /tmp/EUS/firmware/old_cached_firmware 2> /dev/null
}

firmware_cache_question() {
  header
  echo -e "${GRAY_R}#${RESET} I highly recommand caching the firmware on the UniFi Network Application prior to the device upgrades."
  while true; do
    read -rp $'\033[39m#\033[0m Can we proceed with the firmware download/caching? (Y/n) ' yes_no
    case "$yes_no" in
        [Yy]*|"")
           unifi_cache_models
           unifi_firmware_check
           firmware_cache_directory=$(df -k /usr/lib/unifi/data/ | awk '{print $4}' | tail -n1)
           if [[ "${firmware_cache_directory}" -ge '1000000' ]]; then
             unifi_cache_download
             firmware_cached="yes"
           else
             header_red
             echo -e "${RED}#${RESET} There is not enough disk space to download the firmware..\\n\\n"
             sleep 3
           fi
           break;;
        [Nn]*) unifi_firmware_check; break;;
        *) echo -e "\\n${RED}#${RESET} Invalid input, please answer Yes or No (y/n)...\\n"; sleep 3;;
    esac
  done
}

firmware_cache_remove_question() {
  if [[ "${firmware_cached}" == 'yes' ]]; then
    fw_dir_size=$(du -sch /usr/lib/unifi/data/firmware | grep "total$" | awk '{print $1}')
    header
    if [[ "${uap_upgrade_done}" == 'no' ]] && [[ "${uap_upgrade_schedule_done}" == 'no' ]] && [[ "${usw_upgrade_done}" == 'no' ]] && [[ "${usw_upgrade_schedule_done}" == 'no' ]] && [[ "${ugw_upgrade_done}" == 'no' ]] && [[ "${ugw_upgrade_schedule_done}" == 'no' ]]; then
      echo -e "${GRAY_R}#${RESET} There were 0 devices that required an upgrade, therefore we don't need the cached firmware anymore.."
      echo -e "${GRAY_R}#${RESET} Removing cached firmware will free up ${fw_dir_size} on your disk..\\n"
      echo -e "${GRAY_R}#${RESET} What would you like to do with the cached firmware?\\n\\n"
      echo -e " [   ${WHITE_R}1${RESET}   ]  |  Continue and keep the cached firmware. ( default )"
      echo -e " [   ${WHITE_R}2${RESET}   ]  |  Remove the cached firmware.\\n\\n"
      read -rp $'Your choice | \033[39m' firmware_choice
      case "$firmware_choice" in
          1) ;;
          2) unifi_cache_remove;;
          *) ;;
      esac
    elif [[ "${uap_upgrade_schedule_done}" == 'yes' || "${usw_upgrade_schedule_done}" == 'yes' || "${ugw_upgrade_schedule_done}" == 'yes' ]]; then
      if [[ "${two_factor}" != 'enabled' ]]; then
        echo -e "${GRAY_R}#${RESET} Information: Your UniFi Network Application login credentials will be used/copied to that script."
        while true; do
          read -rp $'\033[39m#\033[0m Do you want to schedule a script to remove the cached firmware after the device upgrade schedule (24 hours/1 day later)? (Y/n) ' yes_no
          case "${yes_no}" in
              [Yy]*|"")
                 cron_day="$(date -d "+1 day" +"%a" | tr '[:upper:]' '[:lower:]')"
                 mkdir -p /root/EUS/
                 if [[ -f /root/EUS/remove_firmware_cache.sh && -s /root/EUS/remove_firmware_cache.sh ]] && [[ -f /etc/cron.d/eus_firmware_removal_script && -s /etc/cron.d/eus_firmware_removal_script ]]; then
                   header
                   scheduled_time_hour=$(grep /root/EUS/remove_firmware_cache.sh /etc/cron.d/eus_firmware_removal_script | awk '{print $2}')
                   scheduled_day=$(grep /root/EUS/remove_firmware_cache.sh /etc/cron.d/eus_firmware_removal_script | awk '{print $5}')
                   if [[ "${scheduled_time_hour}" =~ (^0$|^1$|^2$|^3$|^4$|^5$|^6$|^7$|^8$|^9$) ]]; then scheduled_time_hour="0${scheduled_time_hour}"; fi
                   echo -e "${GRAY_R}#${RESET} The script already seems to be scheduled for: '${scheduled_day} ${scheduled_time_hour}:00'.."
                   sleep 6
                 else
                   if curl "${curl_argument[@]}" --output "/root/EUS/remove_firmware_cache.sh" 'https://get.glennr.nl/unifi/extra/remove_firmware_cache.sh'; then
                     sed -i "s/change_username/${username}/g" /root/EUS/remove_firmware_cache.sh
                     sed -i "s/change_password/${password}/g" /root/EUS/remove_firmware_cache.sh
                     chmod +x /root/EUS/remove_firmware_cache.sh
                     sed -i 's/\r//' /root/EUS/remove_firmware_cache.sh
                     tee /etc/cron.d/eus_firmware_removal_script &>/dev/null << EOF
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
${cron_expr} * * ${cron_day} root /bin/bash /root/EUS/remove_firmware_cache.sh
EOF
                   fi
                 fi
                 break;;
              [Nn]*) break;;
              *) echo -e "\\n${RED}#${RESET} Invalid input, please answer Yes or No (y/n)...\\n"; sleep 3;;
          esac
        done
      fi
    else
      echo -e "${GRAY_R}#${RESET} Devices are currently using the cached firmware to upgrade... we have a few options."
      echo -e "${GRAY_R}#${RESET} Removing cached firmware will free up ${fw_dir_size} on your disk..\\n"
      if [[ "${two_factor}" != 'enabled' ]]; then
        echo -e " [   ${WHITE_R}1${RESET}   ]  |  Continue and keep the cached firmware. ( default )"
        echo -e " [   ${WHITE_R}2${RESET}   ]  |  Continue and schedule a script to remove the cached firmware after 1 hour."
        echo -e " [   ${WHITE_R}3${RESET}   ]  |  Wait 10 minutes, remove the cached firmware and then continue the script."
      else
        echo -e " [   ${WHITE_R}1${RESET}   ]  |  Continue and keep the cached firmware. ( default )"
        echo -e " [   ${WHITE_R}2${RESET}   ]  |  Wait 10 minutes, remove the cached firmware and then continue the script."
      fi
      echo -e "\\n"
      read -rp $'Your choice | \033[39m' firmware_choice
      if [[ "${two_factor}" != 'enabled' ]]; then
        case "$firmware_choice" in
            1|"") ;;
            2)
              header
              echo -e "${GRAY_R}#${RESET} Your UniFi Network Application login credentials will be used/copied to that script."
              echo -e "${GRAY_R}#${RESET} The script will run after 1 hour and will be deleted/erased.\\n\\n"
              read -rp $'\033[39m#\033[0m Do you want to schedule the script? (y/N) ' yes_no
              case "$yes_no" in
                  [Yy]*)
                     header
                     echo -e "${GRAY_R}#${RESET} Scheduling the script..\\n\\n" && sleep 2
                       mkdir -p /root/EUS/
                       if [[ -f /root/EUS/remove_firmware_cache.sh && -s /root/EUS/remove_firmware_cache.sh ]] && [[ -f /etc/cron.d/eus_firmware_removal_script && -s /etc/cron.d/eus_firmware_removal_script ]]; then
                         header
                         scheduled_time_minute=$(grep /root/EUS/remove_firmware_cache.sh /etc/cron.d/eus_firmware_removal_script | awk '{print $1}')
                         scheduled_time_hour=$(grep /root/EUS/remove_firmware_cache.sh /etc/cron.d/eus_firmware_removal_script | awk '{print $2}')
                         if [[ "${scheduled_time_hour}" =~ (^0$|^1$|^2$|^3$|^4$|^5$|^6$|^7$|^8$|^9$) ]]; then scheduled_time_hour="0${scheduled_time_hour}"; fi
                         if [[ "${scheduled_time_minute}" =~ (^0$|^1$|^2$|^3$|^4$|^5$|^6$|^7$|^8$|^9$) ]]; then scheduled_time_minute="0${scheduled_time_minute}"; fi
                         echo -e "${GRAY_R}#${RESET} The script seems to be scheduled already at '${scheduled_time_hour}:${scheduled_time_minute}'.."
                         sleep 6
                       else
                         if curl "${curl_argument[@]}" --output "/root/EUS/remove_firmware_cache.sh" 'https://get.glennr.nl/unifi/extra/remove_firmware_cache.sh'; then
                           sed -i "s/change_username/${username}/g" /root/EUS/remove_firmware_cache.sh
                           sed -i "s/change_password/${password}/g" /root/EUS/remove_firmware_cache.sh
                           chmod +x /root/EUS/remove_firmware_cache.sh
                           sed -i 's/\r//' /root/EUS/remove_firmware_cache.sh
                           time_minute=$(date '+%M' | sed 's/^0*//')
                           time_hour=$(date '+%H' | sed 's/^0*//')
                           cron_time_hour=$((time_hour + 1))
                           if [[ "${cron_time_hour}" == '24' ]]; then cron_time_hour=0; fi
                           if [[ -z "${time_minute}" ]]; then time_minute=0; fi
                           tee /etc/cron.d/eus_firmware_removal_script &>/dev/null << EOF
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
${time_minute} ${cron_time_hour} * * * root /bin/bash /root/EUS/remove_firmware_cache.sh
EOF
                         fi
                       fi;;
                  [Nn]*|"") ;;
              esac;;
            3)
              sleep 600
              unifi_cache_remove;;
            *) ;;
        esac
      else
        case "$firmware_choice" in
            1|"") ;;
            2)
              sleep 600
              unifi_cache_remove;;
            *) ;;
        esac
      fi
    fi
  fi
}

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                      UniFi Devices Upgrade                                                                                      #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

unifi_get_site_variable() {
  if grep -iq "default" /tmp/EUS/unifi_sites; then
    site='default'
  else
    site=$(awk 'NR==1{print $1}' /tmp/EUS/unifi_sites)
  fi
}

unifi_list_sites() {
  if [[ "${executed_unifi_list_sites}" != 'true' ]]; then
    header
    echo -e "${GRAY_R}#${RESET} Catching all the site names! \\n\\n"
    sleep 2
    eus_directory_location="/tmp/EUS"
    eus_create_directories "sites"
    ${unifi_api_curl_cmd} "$unifi_api_baseurl/api/self/sites" | jq -r '.data[] .name' &> /tmp/EUS/unifi_sites # /api/stat/sites
    while read -r site; do
      eus_directory_location="/tmp/EUS"
      eus_create_directories "sites/${site}/upgrade"
      # shellcheck disable=SC2086
      ${unifi_api_curl_cmd} "$unifi_api_baseurl/api/self/sites" | jq -r '.data[] | select(.name == "'${site}'") | .desc' >> "/tmp/EUS/sites/${site}/site_desc" # /api/stat/sites
      ${unifi_api_curl_cmd} "$unifi_api_baseurl/api/s/${site}/stat/sysinfo" | jq -r '.data[] | .timezone' >> "/tmp/EUS/sites/${site}/site_timezone"
      echo -e "${GREEN}#${RESET} Successfully found site with ID ${site}"
    done < /tmp/EUS/unifi_sites
    sleep 2
    unifi_get_site_variable
    executed_unifi_list_sites="true"
  fi
}

get_site_desc() {
  site_desc=$(cat "/tmp/EUS/sites/${site}/site_desc")
}

uap_upgrading() {
  echo -e "\\n${GREEN}---${RESET}\\n"
  echo -e "${GRAY_R}#${RESET} The UniFi Access Points are currently ${unifi_upgrade_devices_var_1}..."
  echo -e "${GRAY_R}#${RESET} Waiting 20 seconds before updating the UniFi Switches."
  echo -e "\\n${GREEN}---${RESET}\\n"
  sleep 20
}

usw_upgrading() {
  echo -e "\\n${GREEN}---${RESET}\\n"
  echo -e "${GRAY_R}#${RESET} The UniFi Switches are currently ${unifi_upgrade_devices_var_1}..."
  echo -e "${GRAY_R}#${RESET} Waiting 20 seconds before updating the UniFi Gateways."
  echo -e "\\n${GREEN}---${RESET}\\n"
  sleep 20
}

cached_firmware_url() {
  if [[ "${firmware_cached}" == 'yes' ]]; then
    # shellcheck disable=SC2086
    cached_fw_path="$(jq -r '.data[] | select(.device == "'$model'") | .path' /tmp/EUS/firmware/cached_firmware)"
    if [[ -z "${application_inform_address}" ]]; then
      if [[ "$("${mongocommand}" --quiet --port 27117 ace --eval "${mongoprefix}db.getCollection('setting').find({key:'super_mgmt'})${mongosuffix}" | jq -r '.[].override_inform_host')" == 'true' ]]; then
        application_inform_address="$("${mongocommand}" --quiet --port 27117 ace --eval "${mongoprefix}db.getCollection('setting').find({key:'super_identity'})${mongosuffix}" | jq -r '.[].hostname')"
      else
        application_inform_address="$(${unifi_api_curl_cmd} "$unifi_api_baseurl/api/s/${site}/stat/device" | jq -r '.data[] | select(.uptime >= 0) | .inform_ip' | tail -n1)"
      fi
    fi
    if [[ -z "${http_unifi_port}" ]] || [[ -z "${cache_fw_port}" ]]; then
      if [[ -f "/usr/lib/unifi/data/system.properties" ]]; then
        http_unifi_port="$(grep "^unifi.http.port=" /usr/lib/unifi/data/system.properties | sed 's/unifi.http.port//g' | tr -d '="')"
      fi
      if [[ -z "${http_unifi_port}" ]]; then
        cache_fw_port="8080"
      else
        cache_fw_port="${http_unifi_port}"
      fi
    fi
  fi
}

uap_custom_upgrade_commands() {
  get_site_desc
  ${unifi_api_curl_cmd}  --data "{\"url\":\"${firmware_url}\", \"mac\":\"${uap_mac}\"}" "$unifi_api_baseurl/api/s/${site}/cmd/devmgr/upgrade-external" >> "/tmp/EUS/sites/${site}/upgrade/uap_custom_upgrade_output"
  if grep -iq 'ok' "/tmp/EUS/sites/${site}/upgrade/uap_custom_upgrade_output"; then echo -e "${GREEN}#${RESET} UAP with MAC address '${uap_mac}' from site '${site_desc}' is now upgrading.."; fi
  if grep -iq 'UpgradeInProgress' "/tmp/EUS/sites/${site}/upgrade/uap_custom_upgrade_output"; then echo -e "${YELLOW}#${RESET} UAP with MAC address '${uap_mac}' from site '${site_desc}' is already upgrading.."; fi
  rm --force "/tmp/EUS/sites/${site}/upgrade/uap_custom_upgrade_output"
}

uap_upgrade() {
  while read -r site; do
    if [[ "${option_upgrade}" == 'true' ]]; then
      ${unifi_api_curl_cmd} "$unifi_api_baseurl/api/s/${site}/stat/device" | jq -r '.data[] | select((.type == "uap") and (.version > "3.8") and (.upgradable == true) and (.version | split (".")[-1] | tonumber) < (.upgrade_to_firmware | split (".")[-1] | tonumber) and (.adopted == true) and (.uptime >= 0)) | .mac' &>> "/tmp/EUS/sites/${site}/upgrade/uap_mac" #/tmp/EUS/uaps_upgraded > /dev/null ( tee -a )
      ${unifi_api_curl_cmd} "$unifi_api_baseurl/api/s/${site}/stat/device" | jq -r '.data[] | select((.type == "uap") and (.model == "UP1", .model == "UP6") and (.upgradable == true) and (.version | split (".")[-1] | tonumber) < (.upgrade_to_firmware | split (".")[-1] | tonumber) and (.adopted == true) and (.uptime >= 0)) | .mac' &>> "/tmp/EUS/sites/${site}/upgrade/uap_mac"
    else
      ${unifi_api_curl_cmd} "$unifi_api_baseurl/api/s/${site}/stat/device" | jq -r '.data[] | select((.type == "uap") and (.version > "3.8") and (.upgradable == true) and (.version | split (".")[-1] | tonumber) > (.upgrade_to_firmware | split (".")[-1] | tonumber) and (.adopted == true) and (.uptime >= 0)) | .mac' &>> "/tmp/EUS/sites/${site}/upgrade/uap_mac" #/tmp/EUS/uaps_upgraded > /dev/null ( tee -a )
      ${unifi_api_curl_cmd} "$unifi_api_baseurl/api/s/${site}/stat/device" | jq -r '.data[] | select((.type == "uap") and (.model == "UP1", .model == "UP6") and (.upgradable == true) and (.version | split (".")[-1] | tonumber) > (.upgrade_to_firmware | split (".")[-1] | tonumber) and (.adopted == true) and (.uptime >= 0)) | .mac' &>> "/tmp/EUS/sites/${site}/upgrade/uap_mac"
    fi
    ${unifi_api_curl_cmd} "$unifi_api_baseurl/api/s/${site}/stat/device" | jq -r '.data[] | select((.type == "uap") and (.model == "UAP6MP", .model == "U6M") and (.version <= "5.66.0") and (.adopted == true) and (.uptime >= 0)) | .mac' &>> "/tmp/EUS/sites/${site}/upgrade/uap_mac_u6qca_special"
    if ! [[ -s "/tmp/EUS/sites/${site}/upgrade/uap_mac_u6qca_special" ]]; then rm --force "/tmp/EUS/sites/${site}/upgrade/uap_mac_u6qca_special" &> /dev/null; else while read -r mac_u6qca_special; do sed -i "/${mac_u6qca_special}/d" "/tmp/EUS/sites/${site}/upgrade/uap_mac" &> /dev/null; done < "/tmp/EUS/sites/${site}/upgrade/uap_mac_u6qca_special"; fi
    if ! [[ -s "/tmp/EUS/sites/${site}/upgrade/uap_mac" ]]; then rm --force "/tmp/EUS/sites/${site}/upgrade/uap_mac"; fi
    if [[ -f "/tmp/EUS/sites/${site}/upgrade/uap_mac" ]] && [[ -s "/tmp/EUS/sites/${site}/upgrade/uap_mac" ]]; then
      uap_upgrade_done="yes"
      if [[ "${uap_upgrade_message}" != "true" ]]; then echo -e "${GRAY_R}#${RESET} ${unifi_upgrade_devices_var_1} UniFi Access Points.\\n"; uap_upgrade_message="true"; fi
      get_site_desc
      while read -r uap_mac; do
        ${unifi_api_curl_cmd} --data "{\"mac\":\"${uap_mac}\"}" "$unifi_api_baseurl/api/s/${site}/cmd/devmgr/upgrade" >> "/tmp/EUS/sites/${site}/upgrade/uap_upgrade_output"
        if grep -iq 'ok' "/tmp/EUS/sites/${site}/upgrade/uap_upgrade_output"; then echo -e "${GREEN}#${RESET} UAP with MAC address '${uap_mac}' from site '${site_desc}' is now ${unifi_upgrade_devices_var_1}.."; fi
        if grep -iq 'UpgradeInProgress' "/tmp/EUS/sites/${site}/upgrade/uap_upgrade_output"; then echo -e "${YELLOW}#${RESET} UAP with MAC address '${uap_mac}' from site '${site_desc}' is already ${unifi_upgrade_devices_var_1}.."; fi
        rm --force "/tmp/EUS/sites/${site}/upgrade/uap_upgrade_output"
      done < "/tmp/EUS/sites/${site}/upgrade/uap_mac"
    fi
    ${unifi_api_curl_cmd} "$unifi_api_baseurl/api/s/${site}/stat/device" | jq -r '.data[] | select((.type == "uap") and (.version < "3.8")) | .model' | sed '/UP1/d' >> /tmp/EUS/uap_models
    if [[ -s /tmp/EUS/uap_models ]]; then
      uap_custom="yes"
      uap_upgrade_done="yes"
    else
      rm --force /tmp/EUS/uap_models
    fi
    if [[ "${uap_custom}" == 'yes' ]]; then
      while read -r model; do
        # shellcheck disable=SC2086
        ${unifi_api_curl_cmd} "$unifi_api_baseurl/api/s/${site}/stat/device" | jq -r '.data[] | select((.type == "uap") and (.version < "3.8") and (.model == "'${model}'") and (.adopted == true) and (.uptime >= 0)) | .mac' &>> "/tmp/EUS/sites/${site}/upgrade/${model}_mac" #/tmp/EUS/uaps_upgraded > /dev/null ( tee -a )
        cached_firmware_url
        if [[ "${uap_custom_upgrade_message}" != "true" ]]; then
          echo -e "${GRAY_R}#${RESET} Custom upgrading UniFi Access Points! \\n"
          uap_custom_upgrade_message="true"
        fi
        if [[ ${U7PG2[*]} =~ ${model} ]]; then # -- UAP-AC-Lite/LR/Pro/EDU/M/M-PRO/IW/IW-Pro
          if [[ "${firmware_cached}" == 'yes' ]]; then
            firmware_url="http://${application_inform_address}:${cache_fw_port}/dl/firmware-cached/${cached_fw_path}"
          else
            firmware_url=$(curl -s "http://fw-update.ui.com/api/firmware-latest?filter=eq~~platform~~U7PG2&filter=eq~~channel~~release" 2> /dev/null | jq -r '._embedded.firmware[]._links.data.href' 2> /dev/null | sed 's/https/http/g')
            if [[ -z "${firmware_url}" ]]; then firmware_url="http://dl.ui.com/unifi/firmware/U7PG2/4.0.80.10875/BZ.qca956x.v4.0.80.10875.200111.2335.bin"; fi
          fi
          while read -r uap_mac; do
            uap_custom_upgrade_commands
          done < "/tmp/EUS/sites/${site}/upgrade/${model}_mac"
        elif [[ ${BZ2[*]} =~ ${model} ]]; then # -- UAP, UAP-LR, UAP-OD, UAP-OD5
          if [[ "${firmware_cached}" == 'yes' ]]; then
            firmware_url="http://${application_inform_address}:${cache_fw_port}/dl/firmware-cached/${cached_fw_path}"
          else
            firmware_url="http://dl.ui.com/unifi/firmware/BZ2/4.0.10.9653/BZ.ar7240.v4.0.10.9653.181205.1311.bin"
          fi
          while read -r uap_mac; do
            uap_custom_upgrade_commands
          done < "/tmp/EUS/sites/${site}/upgrade/${model}_mac"
        elif [[ ${U2Sv2[*]} =~ ${model} ]]; then # -- UAP-v2, UAP-LR-v2
          if [[ "${firmware_cached}" == 'yes' ]]; then
            firmware_url="http://${application_inform_address}:${cache_fw_port}/dl/firmware-cached/${cached_fw_path}"
          else
            firmware_url="http://dl.ui.com/unifi/firmware/U2Sv2/4.0.10.9653/BZ.qca9342.v4.0.10.9653.181205.1310.bin"
          fi
          while read -r uap_mac; do
            uap_custom_upgrade_commands
          done < "/tmp/EUS/sites/${site}/upgrade/${model}_mac"
        elif [[ ${U2IW[*]} =~ ${model} ]]; then # -- UAP-IW
          if [[ "${firmware_cached}" == 'yes' ]]; then
            firmware_url="http://${application_inform_address}:${cache_fw_port}/dl/firmware-cached/${cached_fw_path}"
          else
            firmware_url="http://dl.ui.com/unifi/firmware/U2IW/4.0.10.9653/BZ.qca933x.v4.0.10.9653.181205.1310.bin"
          fi
          while read -r uap_mac; do
            uap_custom_upgrade_commands
          done < "/tmp/EUS/sites/${site}/upgrade/${model}_mac"
        elif [[ ${U7P[*]} =~ ${model} ]]; then # -- UAP-PRO
          if [[ "${firmware_cached}" == 'yes' ]]; then
            firmware_url="http://${application_inform_address}:${cache_fw_port}/dl/firmware-cached/${cached_fw_path}"
          else
            firmware_url="http://dl.ui.com/unifi/firmware/U7P/4.0.10.9653/BZ.ar934x.v4.0.10.9653.181205.1310.bin"
          fi
          while read -r uap_mac; do
            uap_custom_upgrade_commands
          done < "/tmp/EUS/sites/${site}/upgrade/${model}_mac"
        elif [[ ${U2HSR[*]} =~ ${model} ]]; then # -- UAP-OD+
          if [[ "${firmware_cached}" == 'yes' ]]; then
            firmware_url="http://${application_inform_address}:${cache_fw_port}/dl/firmware-cached/${cached_fw_path}"
          else
            firmware_url="http://dl.ui.com/unifi/firmware/U2HSR/4.0.10.9653/BZ.ar7240.v4.0.10.9653.181205.1311.bin"
          fi
          while read -r uap_mac; do
            uap_custom_upgrade_commands
          done < "/tmp/EUS/sites/${site}/upgrade/${model}_mac"
        elif [[ ${U7HD[*]} =~ ${model} ]]; then # -- UAP-HD/SHD/XG/BaseStationXG
          if [[ "${firmware_cached}" == 'yes' ]]; then
            firmware_url="http://${application_inform_address}:${cache_fw_port}/dl/firmware-cached/${cached_fw_path}"
          else
            firmware_url=$(curl -s "http://fw-update.ui.com/api/firmware-latest?filter=eq~~platform~~U7HD&filter=eq~~channel~~release" 2> /dev/null | jq -r '._embedded.firmware[]._links.data.href' 2> /dev/null | sed 's/https/http/g')
            if [[ -z "${firmware_url}" ]]; then firmware_url="http://dl.ui.com/unifi/firmware/U7HD/4.0.80.10875/BZ.ipq806x.v4.0.80.10875.200111.1635.bin"; fi
          fi
          while read -r uap_mac; do
            uap_custom_upgrade_commands
          done < "/tmp/EUS/sites/${site}/upgrade/${model}_mac"
        elif [[ ${U7E[*]} =~ ${model} ]]; then # -- UAP-AC, UAP-AC v2, UAP-AC-OD
          if [[ "${firmware_cached}" == 'yes' ]]; then
            firmware_url="http://${application_inform_address}:${cache_fw_port}/dl/firmware-cached/${cached_fw_path}"
          else
            firmware_url="http://dl.ui.com/unifi/firmware/U7E/3.8.17.6789/BZ.bcm4706.v3.8.17.6789.190110.0913.bin"
          fi
          while read -r uap_mac; do
            uap_custom_upgrade_commands
          done < "/tmp/EUS/sites/${site}/upgrade/${model}_mac"
        fi
      done < /tmp/EUS/uap_models
    fi
    if [[ -f "/tmp/EUS/sites/${site}/upgrade/uap_mac_u6qca_special" && -s "/tmp/EUS/sites/${site}/upgrade/uap_mac_u6qca_special" ]]; then uap_u6qca_special_custom="yes"; uap_upgrade_done="yes"; else rm --force "/tmp/EUS/sites/${site}/upgrade/uap_mac_u6qca_special"; fi
    if [[ "${uap_u6qca_special_custom}" == 'yes' ]]; then
      if [[ "${uap_custom_upgrade_message_u6qca}" != "true" ]]; then echo -e "${GRAY_R}#${RESET} Custom upgrading U6-Pro/U6-Mesh UniFi Access Points! \\n"; uap_custom_upgrade_message_u6qca="true"; fi
      if [[ -f "/tmp/EUS/sites/${site}/upgrade/uap_mac_u6qca_special" && -s "/tmp/EUS/sites/${site}/upgrade/uap_mac_u6qca_special" ]]; then
        firmware_url="https://dl.ui.com/unifi/firmware/UAP6MP/5.67.0.13114/BZ.ipq50xx_5.67.0+13114.210608.1558.bin"
        while read -r uap_mac; do
          uap_custom_upgrade_commands
        done < "/tmp/EUS/sites/${site}/upgrade/uap_mac_u6qca_special"
      fi
    fi
  done < /tmp/EUS/unifi_sites
}

usw_custom_upgrade_commands() {
  get_site_desc
  ${unifi_api_curl_cmd}  --data "{\"url\":\"${firmware_url}\", \"mac\":\"${usw_mac}\"}" "$unifi_api_baseurl/api/s/${site}/cmd/devmgr/upgrade-external" >> "/tmp/EUS/sites/${site}/upgrade/usw_custom_upgrade_output"
  if grep -iq 'ok' "/tmp/EUS/sites/${site}/upgrade/usw_custom_upgrade_output"; then echo -e "${GREEN}#${RESET} USW with MAC address '${usw_mac}' from site '${site_desc}' is now upgrading.."; fi
  if grep -iq 'UpgradeInProgress' "/tmp/EUS/sites/${site}/upgrade/usw_custom_upgrade_output"; then echo -e "${YELLOW}#${RESET} USW with MAC address '${usw_mac}' from site '${site_desc}' is already upgrading.."; fi
  rm --force "/tmp/EUS/sites/${site}/upgrade/usw_custom_upgrade_output"
}

usw_upgrade() {
  while read -r site; do
    if [[ "${option_upgrade}" == 'true' ]]; then
      ${unifi_api_curl_cmd} "$unifi_api_baseurl/api/s/${site}/stat/device" | jq -r '.data[] | select((.type == "usw") and (.version > "3.8") and (.upgradable == true) and (.version | split (".")[-1] | tonumber) < (.upgrade_to_firmware | split (".")[-1] | tonumber) and (.adopted == true) and (.uptime >= 0)) | .mac' &>> "/tmp/EUS/sites/${site}/upgrade/usw_mac"
      ${unifi_api_curl_cmd} "$unifi_api_baseurl/api/s/${site}/stat/device" | jq -r '.data[] | select((.type == "usw") and (.model == "USMINI") and (.upgradable == true) and (.version | split (".")[-1] | tonumber) < (.upgrade_to_firmware | split (".")[-1] | tonumber) and (.adopted == true) and (.uptime >= 0)) | .mac' &>> "/tmp/EUS/sites/${site}/upgrade/usw_mac"
    else
      ${unifi_api_curl_cmd} "$unifi_api_baseurl/api/s/${site}/stat/device" | jq -r '.data[] | select((.type == "usw") and (.version > "3.8") and (.upgradable == true) and (.version | split (".")[-1] | tonumber) > (.upgrade_to_firmware | split (".")[-1] | tonumber) and (.adopted == true) and (.uptime >= 0)) | .mac' &>> "/tmp/EUS/sites/${site}/upgrade/usw_mac"
      ${unifi_api_curl_cmd} "$unifi_api_baseurl/api/s/${site}/stat/device" | jq -r '.data[] | select((.type == "usw") and (.model == "USMINI") and (.upgradable == true) and (.version | split (".")[-1] | tonumber) > (.upgrade_to_firmware | split (".")[-1] | tonumber) and (.adopted == true) and (.uptime >= 0)) | .mac' &>> "/tmp/EUS/sites/${site}/upgrade/usw_mac"
    fi
    ${unifi_api_curl_cmd} "$unifi_api_baseurl/api/s/${site}/stat/device" | jq -r '.data[] | select((.type == "usw") and (.model == "USL16P", .model == "USL24P") and (.version <= "4.0.50") and (.adopted == true) and (.uptime >= 0)) | .mac' &>> "/tmp/EUS/sites/${site}/upgrade/usw_mac_gen2_special" #/tmp/EUS/usws_upgraded > /dev/null ( tee -a )
    if ! [[ -s "/tmp/EUS/sites/${site}/upgrade/usw_mac_gen2_special" ]]; then rm --force "/tmp/EUS/sites/${site}/upgrade/usw_mac_gen2_special" &> /dev/null; else while read -r mac_gen2_special; do sed -i "/${mac_gen2_special}/d" "/tmp/EUS/sites/${site}/upgrade/usw_mac" &> /dev/null; done < "/tmp/EUS/sites/${site}/upgrade/usw_mac_gen2_special"; fi
    if ! [[ -s "/tmp/EUS/sites/${site}/upgrade/usw_mac" ]]; then rm --force "/tmp/EUS/sites/${site}/upgrade/usw_mac" &> /dev/null; fi
    if [[ -f "/tmp/EUS/sites/${site}/upgrade/usw_mac" && -s "/tmp/EUS/sites/${site}/upgrade/usw_mac" ]]; then
      usw_upgrade_done="yes"
      if [[ "${check_uap_upgrade}" != 'yes' ]]; then check_uap_upgrades; fi
      if [[ "${usw_upgrade_message}" != "true" ]]; then echo -e "${GRAY_R}#${RESET} ${unifi_upgrade_devices_var_1} UniFi Switches.\\n"; usw_upgrade_message="true"; fi
      get_site_desc
      while read -r usw_mac; do
        ${unifi_api_curl_cmd} --data "{\"mac\":\"${usw_mac}\"}" "$unifi_api_baseurl/api/s/${site}/cmd/devmgr/upgrade" >> "/tmp/EUS/sites/${site}/upgrade/usw_upgrade_output"
        if grep -iq 'ok' "/tmp/EUS/sites/${site}/upgrade/usw_upgrade_output"; then echo -e "${GREEN}#${RESET} USW with MAC address '${usw_mac}' from site '${site_desc}' is now ${unifi_upgrade_devices_var_1}.."; fi
        if grep -iq 'UpgradeInProgress' "/tmp/EUS/sites/${site}/upgrade/usw_upgrade_output"; then echo -e "${YELLOW}#${RESET} USW with MAC address '${usw_mac}' from site '${site_desc}' is already ${unifi_upgrade_devices_var_1}.."; fi
        rm --force "/tmp/EUS/sites/${site}/upgrade/usw_upgrade_output"
      done < "/tmp/EUS/sites/${site}/upgrade/usw_mac"
    fi
    ${unifi_api_curl_cmd} "$unifi_api_baseurl/api/s/${site}/stat/device" | jq -r '.data[] | select((.type == "usw") and (.version < "3.8")) | .model' | sed '/USMINI/d' >> /tmp/EUS/usw_models
    if [[ -s /tmp/EUS/usw_models ]]; then
      usw_custom="yes"
      usw_upgrade_done="yes"
    else
      rm --force /tmp/EUS/usw_models
    fi
    if [[ "${usw_custom}" == 'yes' ]]; then
      while read -r model; do
        # shellcheck disable=SC2086
        ${unifi_api_curl_cmd} "$unifi_api_baseurl/api/s/${site}/stat/device" | jq -r '.data[] | select((.type == "usw") and (.version < "3.8") and (.model == "'${model}'") and (.adopted == true) and (.uptime >= 0)) | .mac' &>> "/tmp/EUS/sites/${site}/upgrade/${model}_mac" #/tmp/EUS/usws_upgraded > /dev/null ( tee -a )
        cached_firmware_url
        if [[ "${check_uap_upgrade}" != 'yes' ]]; then
          check_uap_upgrades
        fi
        if [[ "${usw_custom_upgrade_message}" != "true" ]]; then
          echo -e "${GRAY_R}#${RESET} Custom ${unifi_upgrade_devices_var_1} UniFi Switches! \\n"
          usw_custom_upgrade_message="true"
        fi
        if [[ ${USXG[*]} =~ ${model} ]]; then # -- US-16-XG
          if [[ "${firmware_cached}" == 'yes' ]]; then
            firmware_url="http://${application_inform_address}:${cache_fw_port}/dl/firmware-cached/${cached_fw_path}"
          else
            firmware_url=$(curl -s "http://fw-update.ui.com/api/firmware-latest?filter=eq~~platform~~USXG&filter=eq~~channel~~release" 2> /dev/null | jq -r '._embedded.firmware[]._links.data.href' 2> /dev/null | sed 's/https/http/g')
            if [[ -z "${firmware_url}" ]]; then firmware_url="http://dl.ui.com/unifi/firmware/USXG/4.0.80.10875/US.bcm5341x.v4.0.80.10875.200111.1635.bin"; fi
          fi
          while read -r usw_mac; do
            usw_custom_upgrade_commands
          done < "/tmp/EUS/sites/${site}/upgrade/${model}_mac"
        elif [[ ${US24P250[*]} =~ ${model} ]]; then # -- US/US-POE
          if [[ "${firmware_cached}" == 'yes' ]]; then
            firmware_url="http://${application_inform_address}:${cache_fw_port}/dl/firmware-cached/${cached_fw_path}"
          else
            firmware_url=$(curl -s "http://fw-update.ui.com/api/firmware-latest?filter=eq~~platform~~US24P250&filter=eq~~channel~~release" 2> /dev/null | jq -r '._embedded.firmware[]._links.data.href' 2> /dev/null | sed 's/https/http/g')
            if [[ -z "${firmware_url}" ]]; then firmware_url="http://dl.ui.com/unifi/firmware/US24P250/4.0.80.10875/US.bcm5334x.v4.0.80.10875.200111.2335.bin"; fi
          fi
          while read -r usw_mac; do
            usw_custom_upgrade_commands
          done < "/tmp/EUS/sites/${site}/upgrade/${model}_mac"
        fi
      done < /tmp/EUS/usw_models
    fi
    if [[ -f "/tmp/EUS/sites/${site}/upgrade/usw_mac_gen2_special" && -s "/tmp/EUS/sites/${site}/upgrade/usw_mac_gen2_special" ]]; then usw_gen2_special_custom="yes"; usw_upgrade_done="yes"; else rm --force "/tmp/EUS/sites/${site}/upgrade/usw_mac_gen2_special"; fi
    if [[ "${usw_gen2_special_custom}" == 'yes' ]]; then
      if [[ "${check_uap_upgrade}" != 'yes' ]]; then check_uap_upgrades; fi
      if [[ "${usw_custom_upgrade_message_gen2}" != "true" ]]; then echo -e "${GRAY_R}#${RESET} Custom upgrading Gen2 UniFi Switches! \\n"; usw_custom_upgrade_message_gen2="true"; fi
      if [[ -f "/tmp/EUS/sites/${site}/upgrade/usw_mac_gen2_special" && -s "/tmp/EUS/sites/${site}/upgrade/usw_mac_gen2_special" ]]; then
        firmware_url="https://dl.ui.com/unifi/firmware/USL16P/4.0.49.10569/US.rtl838x.v4.0.49.10569.190708.1559.bin"
        while read -r usw_mac; do
          usw_custom_upgrade_commands
        done < "/tmp/EUS/sites/${site}/upgrade/usw_mac_gen2_special"
      fi
    fi
  done < /tmp/EUS/unifi_sites
}

ugw_custom_upgrade_commands() {
  get_site_desc
  ${unifi_api_curl_cmd}  --data "{\"url\":\"${firmware_url}\", \"mac\":\"${ugw_mac}\"}" "$unifi_api_baseurl/api/s/${site}/cmd/devmgr/upgrade-external" >> "/tmp/EUS/sites/${site}/upgrade/ugw_custom_upgrade_output"
  if grep -iq 'ok' "/tmp/EUS/sites/${site}/upgrade/ugw_custom_upgrade_output"; then echo -e "${GREEN}#${RESET} UGW with MAC address '${ugw_mac}' from site '${site_desc}' is now upgrading.."; fi
  if grep -iq 'UpgradeInProgress' "/tmp/EUS/sites/${site}/upgrade/ugw_custom_upgrade_output"; then echo -e "${YELLOW}#${RESET} UGW with MAC address '${ugw_mac}' from site '${site_desc}' is already upgrading.."; fi
  rm --force "/tmp/EUS/sites/${site}/upgrade/ugw_custom_upgrade_output"
}

ugw_upgrade() {
  while read -r site; do
    if [[ "${option_upgrade}" == 'true' ]]; then
      ${unifi_api_curl_cmd} "$unifi_api_baseurl/api/s/${site}/stat/device" | jq -r '.data[] | select((.type == "ugw") and (.version > "4.4.20") and (.upgradable == true) and (.version | split (".")[-1] | tonumber) < (.upgrade_to_firmware | split (".")[-1] | tonumber) and (.adopted == true) and (.uptime >= 0)) | .mac' &>> "/tmp/EUS/sites/${site}/upgrade/ugw_mac" #/tmp/EUS/ugws_upgraded > /dev/null ( tee -a )
      ${unifi_api_curl_cmd} "$unifi_api_baseurl/api/s/${site}/stat/device" | jq -r '.data[] | select((.type == "uxg") and (.version > "0.1.0") and (.upgradable == true) and (.version | split (".")[-1] | tonumber) < (.upgrade_to_firmware | split (".")[-1] | tonumber) and (.adopted == true) and (.uptime >= 0)) | .mac' &>> "/tmp/EUS/sites/${site}/upgrade/uxg_mac"
    else
      ${unifi_api_curl_cmd} "$unifi_api_baseurl/api/s/${site}/stat/device" | jq -r '.data[] | select((.type == "ugw") and (.version > "4.4.20") and (.upgradable == true) and (.version | split (".")[-1] | tonumber) > (.upgrade_to_firmware | split (".")[-1] | tonumber) and (.adopted == true) and (.uptime >= 0)) | .mac' &>> "/tmp/EUS/sites/${site}/upgrade/ugw_mac" #/tmp/EUS/ugws_upgraded > /dev/null ( tee -a )
      ${unifi_api_curl_cmd} "$unifi_api_baseurl/api/s/${site}/stat/device" | jq -r '.data[] | select((.type == "uxg") and (.version > "0.1.0") and (.upgradable == true) and (.version | split (".")[-1] | tonumber) > (.upgrade_to_firmware | split (".")[-1] | tonumber) and (.adopted == true) and (.uptime >= 0)) | .mac' &>> "/tmp/EUS/sites/${site}/upgrade/uxg_mac"
    fi
    if ! [[ -s "/tmp/EUS/sites/${site}/upgrade/uxg_mac" ]]; then rm --force "/tmp/EUS/sites/${site}/upgrade/uxg_mac"; fi
    if ! [[ -s "/tmp/EUS/sites/${site}/upgrade/ugw_mac" ]]; then rm --force "/tmp/EUS/sites/${site}/upgrade/ugw_mac"; fi
    if [[ -f "/tmp/EUS/sites/${site}/upgrade/uxg_mac" ]] && [[ -s "/tmp/EUS/sites/${site}/upgrade/uxg_mac" ]]; then
      ugw_upgrade_done="yes"
      if [[ "${check_usw_upgrade}" != 'yes' ]]; then check_usw_upgrades; elif [[ "${check_uap_upgrade}" != 'yes' ]]; then check_uap_upgrades; fi
      if [[ "${uxg_upgrade_message}" != "true" ]]; then echo -e "${GRAY_R}#${RESET} ${unifi_upgrade_devices_var_1} UniFi NeXt-Gen Gateways.\\n"; uxg_upgrade_message="true"; fi
      get_site_desc
      while read -r uxg_mac; do
        ${unifi_api_curl_cmd} --data "{\"mac\":\"${uxg_mac}\"}" "$unifi_api_baseurl/api/s/${site}/cmd/devmgr/upgrade" >> "/tmp/EUS/sites/${site}/upgrade/uxg_upgrade_output"
        if grep -iq 'ok' "/tmp/EUS/sites/${site}/upgrade/uxg_upgrade_output"; then echo -e "${GREEN}#${RESET} UXG with MAC address '${uxg_mac}' from site '${site_desc}' is now ${unifi_upgrade_devices_var_1}.."; fi
        if grep -iq 'UpgradeInProgress' "/tmp/EUS/sites/${site}/upgrade/uxg_upgrade_output"; then echo -e "${YELLOW}#${RESET} UXG with MAC address '${uxg_mac}' from site '${site_desc}' is already ${unifi_upgrade_devices_var_1}.."; fi
        rm --force "/tmp/EUS/sites/${site}/upgrade/uxg_upgrade_output"
      done < "/tmp/EUS/sites/${site}/upgrade/uxg_mac"
    fi
    if [[ -f "/tmp/EUS/sites/${site}/upgrade/ugw_mac" ]] && [[ -s "/tmp/EUS/sites/${site}/upgrade/ugw_mac" ]]; then
      ugw_upgrade_done="yes"
      if [[ "${check_usw_upgrade}" != 'yes' ]]; then check_usw_upgrades; elif [[ "${check_uap_upgrade}" != 'yes' ]]; then check_uap_upgrades; fi
      if [[ "${ugw_upgrade_message}" != "true" ]]; then echo -e "${GRAY_R}#${RESET} ${unifi_upgrade_devices_var_1} UniFi Security Gateways.\\n"; ugw_upgrade_message="true"; fi
      get_site_desc
      while read -r ugw_mac; do
        ${unifi_api_curl_cmd} --data "{\"mac\":\"${ugw_mac}\"}" "$unifi_api_baseurl/api/s/${site}/cmd/devmgr/upgrade" >> "/tmp/EUS/sites/${site}/upgrade/ugw_upgrade_output"
        if grep -iq 'ok' "/tmp/EUS/sites/${site}/upgrade/ugw_upgrade_output"; then echo -e "${GREEN}#${RESET} UGW with MAC address '${ugw_mac}' from site '${site_desc}' is now ${unifi_upgrade_devices_var_1}.."; fi
        if grep -iq 'UpgradeInProgress' "/tmp/EUS/sites/${site}/upgrade/ugw_upgrade_output"; then echo -e "${YELLOW}#${RESET} UGW with MAC address '${ugw_mac}' from site '${site_desc}' is already ${unifi_upgrade_devices_var_1}.."; fi
        rm --force "/tmp/EUS/sites/${site}/upgrade/ugw_upgrade_output"
      done < "/tmp/EUS/sites/${site}/upgrade/ugw_mac"
    fi
    ${unifi_api_curl_cmd} "$unifi_api_baseurl/api/s/${site}/stat/device" | jq -r '.data[] | select((.type == "ugw") and (.version < "4.4.20")) | .model' >> /tmp/EUS/ugw_models
    if [[ -s /tmp/EUS/ugw_models ]]; then
      ugw_custom="yes"
      ugw_upgrade_done="yes"
    else
      rm --force /tmp/EUS/ugw_models
    fi
    if [[ "${ugw_custom}" == 'yes' ]]; then
      while read -r model; do
        # shellcheck disable=SC2086
        ${unifi_api_curl_cmd} "$unifi_api_baseurl/api/s/${site}/stat/device" | jq -r '.data[] | select((.type == "ugw") and (.version < "4.4.20") and (.model == "'${model}'") and (.adopted == true) and (.uptime >= 0)) | .mac' &>> "/tmp/EUS/sites/${site}/upgrade/${model}_mac" #/tmp/EUS/ugws_upgraded > /dev/null ( tee -a )
        cached_firmware_url
        if [[ "${ugw_custom_upgrade_message}" != "true" ]]; then
          if [[ "${check_usw_upgrade}" != 'yes' ]]; then
            check_usw_upgrades
          elif [[ "${check_uap_upgrade}" != 'yes' ]]; then
            check_uap_upgrades
          fi
          echo -e "${GRAY_R}#${RESET} Custom upgrading UniFi Security Gateways! \\n"
          ugw_custom_upgrade_message="true"
        fi
        if [[ ${UGW3[*]} =~ ${model} ]]; then # -- USG3
          if [[ "${firmware_cached}" == 'yes' ]]; then
            firmware_url="http://${application_inform_address}:${cache_fw_port}/dl/firmware-cached/${cached_fw_path}"
          else
            firmware_url=$(curl -s "http://fw-update.ui.com/api/firmware-latest?filter=eq~~platform~~UGW3&filter=eq~~channel~~release" 2> /dev/null | jq -r '._embedded.firmware[]._links.data.href' 2> /dev/null | sed 's/https/http/g')
            if [[ -z "${firmware_url}" ]]; then firmware_url="http://dl.ui.com/unifi/firmware/UGW3/4.4.51.5287926/UGW3.v4.4.51.5287926.tar"; fi
          fi
          while read -r ugw_mac; do
            ugw_custom_upgrade_commands
          done < "/tmp/EUS/sites/${site}/upgrade/${model}_mac"
        elif [[ ${UGW4[*]} =~ ${model} ]]; then # -- USG-PRO-4
          if [[ "${firmware_cached}" == 'yes' ]]; then
            firmware_url="http://${application_inform_address}:${cache_fw_port}/dl/firmware-cached/${cached_fw_path}"
          else
            firmware_url=$(curl -s "http://fw-update.ui.com/api/firmware-latest?filter=eq~~platform~~UGW4&filter=eq~~channel~~release" 2> /dev/null | jq -r '._embedded.firmware[]._links.data.href' 2> /dev/null | sed 's/https/http/g')
            if [[ -z "${firmware_url}" ]]; then firmware_url="http://dl.ui.com/unifi/firmware/UGW4/4.4.51.5287926/UGW4.v4.4.51.5287926.tar"; fi
          fi
          while read -r ugw_mac; do
            ugw_custom_upgrade_commands
          done < "/tmp/EUS/sites/${site}/upgrade/${model}_mac"
        fi
      done < /tmp/EUS/ugw_models
    fi
  done < /tmp/EUS/unifi_sites
}

check_uap_upgrades() {
  if [[ "${uap_upgrade_done}" == 'yes' ]]; then
    uap_upgrading
    check_uap_upgrade="yes"
  fi
}

check_usw_upgrades() {
  if [[ "${usw_upgrade_done}" == 'yes' ]]; then
    usw_upgrading
    check_usw_upgrade="yes"
  fi
}

check_uap_upgraded() {
  if [[ "${uap_upgrade_done}" == 'no' ]]; then echo -e "\\n${GREEN}#${RESET} There were 0 UAP(s) that needed a firmware ${unifi_upgrade_devices_var_2}.."; fi
}

check_usw_upgraded() {
  if [[ "${usw_upgrade_done}" == 'no' ]]; then echo -e "\\n${GREEN}#${RESET} There were 0 USW(s) that needed a firmware ${unifi_upgrade_devices_var_2}.."; fi
}

check_uxg_upgraded() {
  if [[ "${ugw_upgrade_done}" == 'no' ]]; then echo -e "\\n${GREEN}#${RESET} There were 0 UXG(s) that needed a firmware ${unifi_upgrade_devices_var_2}.."; fi
}

check_ugw_upgraded() {
  if [[ "${ugw_upgrade_done}" == 'no' ]]; then echo -e "\\n${GREEN}#${RESET} There were 0 UGW(s) that needed a firmware ${unifi_upgrade_devices_var_2}.."; fi
}

unifi_upgrade_devices() {
  header
  echo -e "\\n${GRAY_R}#${RESET} Starting the device ${unifi_upgrade_devices_var_2}!"
  echo -e "\\n${GREEN}---${RESET}\\n"
  uap_upgrade
  check_uap_upgraded
  usw_upgrade
  check_usw_upgraded
  ugw_upgrade
  check_uxg_upgraded
  check_ugw_upgraded
  sleep 3
}

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                 UniFi Devices Update Scheduling                                                                                 #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

check_uap_scheduled() {
  if [[ "${uap_upgrade_schedule_done}" == 'no' ]] && [[ "${uap_upgrade_schedule_done_message}" != 'yes' ]]; then
    echo -e "\\n${GREEN}#${RESET} There were 0 UAP(s) that needed a firmware ${unifi_upgrade_devices_var_2}, script didn't schedule any UAPs."
    uap_upgrade_schedule_done_message="yes"
  fi
}

check_usw_scheduled() {
  if [[ "${usw_upgrade_schedule_done}" == 'no' ]] && [[ "${usw_upgrade_schedule_done_message}" != 'yes' ]]; then
    echo -e "\\n${GREEN}#${RESET} There were 0 USW(s) that needed a firmware ${unifi_upgrade_devices_var_2}, script didn't schedule any USWs."
    usw_upgrade_schedule_done_message="yes"
  fi
}

check_uxg_scheduled() {
  if [[ "${uxg_upgrade_schedule_done}" == 'no' ]] && [[ "${ugw_upgrade_schedule_done_message}" != 'yes' ]]; then
    echo -e "\\n${GREEN}#${RESET} There were 0 UXG(s) that needed a firmware ${unifi_upgrade_devices_var_2}, script didn't schedule any UXGs."
    ugw_upgrade_schedule_done_message="yes"
  fi
}

check_ugw_scheduled() {
  if [[ "${ugw_upgrade_schedule_done}" == 'no' ]] && [[ "${ugw_upgrade_schedule_done_message}" != 'yes' ]]; then
    echo -e "\\n${GREEN}#${RESET} There were 0 UGW(s) that needed a firmware ${unifi_upgrade_devices_var_2}, script didn't schedule any UGWs."
    ugw_upgrade_schedule_done_message="yes"
  fi
}

schedule_time_question() {
  header
  echo -e "${GRAY_R}#${RESET} Information: The device ${unifi_upgrade_devices_var_2} will be exectured at the choosen time at the sites timezone."
  echo -e "${GRAY_R}#${RESET} At what time do you want to schedule your devices to update?"
  echo -e "\\n${GRAY_R}---${RESET}\\n"
  echo -e " [   ${WHITE_R}1 ${RESET}   ]  |  1 AM          ${GREEN}|${RESET}          [   ${WHITE_R}13${RESET}   ]  |  1 PM"
  echo -e " [   ${WHITE_R}2 ${RESET}   ]  |  2 AM          ${GREEN}|${RESET}          [   ${WHITE_R}14${RESET}   ]  |  2 PM"
  echo -e " [   ${WHITE_R}3 ${RESET}   ]  |  3 AM          ${GREEN}|${RESET}          [   ${WHITE_R}15${RESET}   ]  |  3 PM"
  echo -e " [   ${WHITE_R}4 ${RESET}   ]  |  4 AM          ${GREEN}|${RESET}          [   ${WHITE_R}16${RESET}   ]  |  4 PM"
  echo -e " [   ${WHITE_R}5 ${RESET}   ]  |  5 AM          ${GREEN}|${RESET}          [   ${WHITE_R}17${RESET}   ]  |  5 PM"
  echo -e " [   ${WHITE_R}6 ${RESET}   ]  |  6 AM          ${GREEN}|${RESET}          [   ${WHITE_R}18${RESET}   ]  |  6 PM"
  echo -e " [   ${WHITE_R}7 ${RESET}   ]  |  7 AM          ${GREEN}|${RESET}          [   ${WHITE_R}19${RESET}   ]  |  7 PM"
  echo -e " [   ${WHITE_R}8 ${RESET}   ]  |  8 AM          ${GREEN}|${RESET}          [   ${WHITE_R}20${RESET}   ]  |  8 PM"
  echo -e " [   ${WHITE_R}9 ${RESET}   ]  |  9 AM          ${GREEN}|${RESET}          [   ${WHITE_R}21${RESET}   ]  |  9 PM"
  echo -e " [   ${WHITE_R}10${RESET}   ]  |  10 AM         ${GREEN}|${RESET}          [   ${WHITE_R}22${RESET}   ]  |  10 PM"
  echo -e " [   ${WHITE_R}11${RESET}   ]  |  11 AM         ${GREEN}|${RESET}          [   ${WHITE_R}23${RESET}   ]  |  11 PM"
  echo -e " [   ${WHITE_R}12${RESET}   ]  |  12 PM         ${GREEN}|${RESET}          [   ${WHITE_R}24${RESET}   ]  |  12 AM"
  echo -e "\\n"
  read -rp $'Your choice | \033[39m' choice
  case "$choice" in
     1) cron_expr='0 1'; cron_expr_human='1 AM';;
     2) cron_expr='0 2'; cron_expr_human='2 AM';;
     3) cron_expr='0 3'; cron_expr_human='3 AM';;
     4) cron_expr='0 4'; cron_expr_human='4 AM';;
     5) cron_expr='0 5'; cron_expr_human='5 AM';;
     6) cron_expr='0 6'; cron_expr_human='6 AM';;
     7) cron_expr='0 7'; cron_expr_human='7 AM';;
     8) cron_expr='0 8'; cron_expr_human='8 AM';;
     9) cron_expr='0 9'; cron_expr_human='9 AM';;
     10) cron_expr='0 10'; cron_expr_human='10 AM';;
     11) cron_expr='0 11'; cron_expr_human='11 AM';;
     12) cron_expr='0 12'; cron_expr_human='12 PM';;
     13) cron_expr='0 13'; cron_expr_human='1 PM';;
     14) cron_expr='0 14'; cron_expr_human='2 PM';;
     15) cron_expr='0 15'; cron_expr_human='3 PM';;
     16) cron_expr='0 16'; cron_expr_human='4 PM';;
     17) cron_expr='0 17'; cron_expr_human='5 PM';;
     18) cron_expr='0 18'; cron_expr_human='6 PM';;
     19) cron_expr='0 19'; cron_expr_human='7 PM';;
     20) cron_expr='0 20'; cron_expr_human='8 PM';;
     21) cron_expr='0 21'; cron_expr_human='9 PM';;
     22) cron_expr='0 22'; cron_expr_human='10 PM';;
     23) cron_expr='0 23'; cron_expr_human='11 PM';;
     24) cron_expr='0 0'; cron_expr_human='12 AM';;
	 *) 
        header_red
        echo -e "${GRAY_R}#${RESET} '${choice}' is not a valid option..." && sleep 2
        schedule_time_question;;
  esac
}

device_upgrade_schedule() {
  echo -e "uap\\nusw\\nuxg\\nugw" &> /tmp/EUS/device_types
  while read -r device_type; do
    while read -r site; do
      ${unifi_api_curl_cmd} "$unifi_api_baseurl/api/s/${site}/rest/scheduletask" | jq -r '.data[] | select(.execute_only_once == true) | .upgrade_targets | .[] | .mac' &> "/tmp/EUS/sites/${site}/scheduletask"
      if ! [[ -s "/tmp/EUS/sites/${site}/scheduletask" ]]; then rm --force "/tmp/EUS/sites/${site}/scheduletask" &> /dev/null; fi
      get_site_desc
      site_timezone=$(tail -n1 "/tmp/EUS/sites/${site}/site_timezone")
      type_2=$(echo "${device_type}" | tr '[:lower:]' '[:upper:]')
      if [[ "${device_type}" == 'uap' ]]; then type_long="UniFi Access Points"; elif [[ "${device_type}" == 'usw' ]]; then type_long="UniFi Switches"; elif [[ "${device_type}" == 'uxg' ]]; then type_long="UniFi NeXt-Gen Gateways"; elif [[ "${device_type}" == 'ugw' ]]; then type_long="UniFi Security Gateways"; fi
      # shellcheck disable=SC2086
      if [[ "${option_upgrade}" == 'true' ]]; then
        ${unifi_api_curl_cmd} "$unifi_api_baseurl/api/s/${site}/stat/device" | jq -r '.data[] | select((.type == "'${device_type}'") and (.upgradable == true) and (.version | split (".")[-1] | tonumber) < (.upgrade_to_firmware | split (".")[-1] | tonumber) and (.adopted == true)) | .mac' &>> "/tmp/EUS/sites/${site}/${device_type}_mac"
      else
        ${unifi_api_curl_cmd} "$unifi_api_baseurl/api/s/${site}/stat/device" | jq -r '.data[] | select((.type == "'${device_type}'") and (.upgradable == true) and (.version | split (".")[-1] | tonumber) > (.upgrade_to_firmware | split (".")[-1] | tonumber) and (.adopted == true)) | .mac' &>> "/tmp/EUS/sites/${site}/${device_type}_mac"
      fi
      if ! [[ -s "/tmp/EUS/sites/${site}/${device_type}_mac" ]]; then rm --force "/tmp/EUS/sites/${site}/${device_type}_mac" &> /dev/null; fi
      if [[ -f "/tmp/EUS/sites/${site}/${device_type}_mac" ]] && [[ -s "/tmp/EUS/sites/${site}/${device_type}_mac" ]]; then
        if [[ "${device_type}" == 'uap' ]]; then uap_upgrade_schedule_done="yes"; elif [[ "${device_type}" == 'usw' ]]; then usw_upgrade_schedule_done="yes"; elif [[ "${device_type}" == 'uxg' ]]; then uxg_upgrade_schedule_done="yes"; elif [[ "${device_type}" == 'ugw' ]]; then ugw_upgrade_schedule_done="yes"; fi
        if ! [[ -f "/tmp/EUS/${device_type}_schedule_message" ]]; then
          echo -e "${GRAY_R}#${RESET} Scheduling updates for the ${type_long}.\\n"
          touch "/tmp/EUS/${device_type}_schedule_message"
        fi
        while read -r mac; do
          if grep -iq "${mac}" "/tmp/EUS/sites/${site}/scheduletask" &> /dev/null; then
            echo -e "${YELLOW}#${RESET} ${type_2} with MAC address '${mac}' from site '${site_desc}' is already scheduled.."
          else
            schedule_name="EUS ${type_2} Upgrade | ${mac}"
            ${unifi_api_curl_cmd}  --data "{\"cron_expr\":\"${cron_expr} * * *\",\"name\":\"${schedule_name}\",\"execute_only_once\":true,\"action\":\"upgrade\",\"upgrade_targets\":[{\"mac\":\"${mac}\"}]}" "$unifi_api_baseurl/api/s/${site}/rest/scheduletask" >> "/tmp/EUS/sites/${site}/${device_type}_upgrade_schedule_output"
            if grep -iq 'ok' "/tmp/EUS/sites/${site}/${device_type}_upgrade_schedule_output"; then echo -e "${GREEN}#${RESET} ${type_2} with MAC address '${mac}' from site '${site_desc}' is scheduled to ${unifi_upgrade_devices_var_2} at ${cron_expr_human} ${site_timezone}."; fi
            rm --force "/tmp/EUS/sites/${site}/${device_type}_upgrade_schedule_output" 2> /dev/null
          fi
        done < "/tmp/EUS/sites/${site}/${device_type}_mac"
      fi
    done < /tmp/EUS/unifi_sites
    rm --force "/tmp/EUS/${device_type}_schedule_message" &> /dev/null
    if [[ "${device_type}" == 'uap' ]]; then check_uap_scheduled; elif [[ "${device_type}" == 'usw' ]]; then check_usw_scheduled; elif [[ "${device_type}" == 'uxg' ]]; then check_uxg_scheduled; elif [[ "${device_type}" == 'ugw' ]]; then check_ugw_scheduled; fi
  done < /tmp/EUS/device_types
  rm --force /tmp/EUS/device_types &> /dev/null
}

unifi_upgrade_scheduler() {
  schedule_time_question
  header
  echo -e "\\n${GRAY_R}#${RESET} Starting the device ${unifi_upgrade_devices_var_2} scheduler!"
  echo -e "\\n${GREEN}---${RESET}\\n"
  device_upgrade_schedule
  sleep 3
}

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                          UniFi Backup                                                                                           #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

unifi_backup () {
  backup_time=$(date +%Y%m%d_%H%M_%S%N)
  header
  echo -e "${GRAY_R}#${RESET} Creating the backup!"
  echo -e "${GRAY_R}#${RESET} This can take a while for big setups! \\n\\n"
  sleep 2
  auto_dir=$(grep ^autobackup.dir /var/lib/unifi/system.properties 2> /dev/null | sed 's/autobackup.dir=//g')
  if grep -q "^unifi:" /etc/group && grep -q "^unifi:" /etc/passwd; then
    if sudo -u unifi [ -w "${auto_dir}" ]; then touch /tmp/EUS/application/dir_writable; fi
    if [[ -f /tmp/EUS/application/dir_writable ]]; then
      unifi_write_permission="true"
      rm --force /tmp/EUS/application/dir_writable 2> /dev/null
    else
      unifi_write_permission="false"
    fi
  fi
  if ! [[ "${unifi}" =~ ^(5.6.0|5.6.1|5.6.2|5.6.3)$ || "${unifi_release::3}" -lt "56" ]]; then
    unifi_write_permission=pass
  fi
  # shellcheck disable=SC2012
  if [[ -n "$auto_dir" && "${unifi_write_permission}" =~ (true|pass) || $(ls -ld "${auto_dir}" 2> /dev/null | awk '{print $3":"$4}') == "unifi:unifi" ]]; then
    backup_location=custom
    if echo "${auto_dir}" | grep -q '/$'; then
      if ! [[ -d "${auto_dir}glennr-unifi-backups/" ]]; then mkdir "${auto_dir}glennr-unifi-backups/"; fi
      output="${auto_dir}glennr-unifi-backups/unifi_backup_${unifi}_${backup_time}.unf"
    else
      if ! [[ -d "${auto_dir}/glennr-unifi-backups/" ]]; then mkdir "${auto_dir}/glennr-unifi-backups/"; fi
      output="${auto_dir}/glennr-unifi-backups/unifi_backup_${unifi}_${backup_time}.unf"
	fi
  elif [[ -d /data/autobackup/ ]]; then
    if ! [[ -d /data/glennr-unifi-backups/ ]]; then mkdir /data/glennr-unifi-backups/; fi
    backup_location="sd_card"
    output="/data/glennr-unifi-backups/unifi_backup_${unifi}_${backup_time}.unf"
  elif [[ -d /sdcard/ ]] && [[ "${eus_dir}" == '/srv/EUS' ]]; then
    if ! [[ -d /sdcard/glennr-unifi-backups/ ]]; then mkdir /sdcard/glennr-unifi-backups/; fi
    backup_location="sd_card_unifi_os"
    output="/sdcard/glennr-unifi-backups/unifi_backup_${unifi}_${backup_time}.unf"
  else
    if ! [[ -d /usr/lib/unifi/data/backup/glennr-unifi-backups/ ]]; then mkdir /usr/lib/unifi/data/backup/glennr-unifi-backups/; fi
    backup_location="unifi_dir"
    output="/usr/lib/unifi/data/backup/glennr-unifi-backups/unifi_backup_${unifi}_${backup_time}.unf"
  fi
  if [[ "${unifi}" =~ ^(5.4.0|5.4.1)$ || "${unifi_release::3}" -lt "54" ]]; then
    path=$($unifi_api_curl_cmd --data "{\"cmd\":\"backup\",\"days\":\"0\"}" "$unifi_api_baseurl/api/s/${site}/cmd/system" | sed -n 's/.*\(\/dl.*unf\).*/\1/p')
  else
    path=$($unifi_api_curl_cmd --data "{\"cmd\":\"backup\",\"days\":\"0\"}" "$unifi_api_baseurl/api/s/${site}/cmd/backup" | sed -n 's/.*\(\/dl.*unf\).*/\1/p')
  fi
  ${unifi_api_curl_cmd} "$unifi_api_baseurl$path" -o "$output" --create-dirs
}

unifi_backup_check() {
  if [[ -f "${output}" && -s "${output}" ]]; then
    while true; do
      header
      echo -e "${GRAY_R}#${RESET} Checking if the backup got created!"
      echo -e "${GRAY_R}#${RESET} Backup Location: ${output}"
      for (( ; ; )); do
        stat_1=$(stat -c%s "${output}")
        sleep 10
        stat_2=$(stat -c%s "${output}")
        if [[ "${stat_1}" -eq "${stat_2}" ]]; then
          header
          echo -e "${GREEN}#${RESET} UniFi Network Application backup was successful!"
          sleep 2
          glennr_unifi_backup="success"
          break
        fi
        header_red
        echo -e "${RED}#${RESET} UniFi Network Application backup didn't finish yet!"
      done
      if [[ -f "${output}" && -s "${output}" ]]; then break; fi
    done
    if [[ "${glennr_unifi_backup}" == 'success' ]]; then
      echo -e "${GREEN}#${RESET} Changing backup file permissions to unifi:unifi!"
      if [[ "${backup_location}" == 'custom' ]]; then
        if ! [[ "${unifi}" =~ ^(5.6.0|5.6.1|5.6.2|5.6.3)$ || "${unifi_release::3}" -lt "56" ]]; then
          if echo "$auto_dir" | grep -q '/$'; then
            chown -R unifi:unifi "${auto_dir}glennr-unifi-backups/"
          else
            chown -R unifi:unifi "${auto_dir}/glennr-unifi-backups/"
          fi
        fi
      elif [[ "${backup_location}" == 'sd_card' ]]; then
        if ! [[ "${unifi}" =~ ^(5.6.0|5.6.1|5.6.2|5.6.3)$ || "${unifi_release::3}" -lt "56" ]]; then
          chown -R unifi:unifi /data/glennr-unifi-backups/
        fi
      elif [[ "${backup_location}" == 'sd_card_unifi_os' ]]; then
        if ! [[ "${unifi}" =~ ^(5.6.0|5.6.1|5.6.2|5.6.3)$ || "${unifi_release::3}" -lt "56" ]]; then
          chown -R unifi:unifi /sdcard/glennr-unifi-backups/
        fi
      elif [[ "${backup_location}" == 'unifi_dir' ]]; then
        if ! [[ "${unifi}" =~ ^(5.6.0|5.6.1|5.6.2|5.6.3)$ || "${unifi_release::3}" -lt "56" ]]; then
          chown -R unifi:unifi /usr/lib/unifi/data/backup/glennr-unifi-backups/
        fi
      fi
      sleep 3
    fi
  else
    header_red
    echo -e "${RED}#${RESET} UniFi Network Application backup seems to have failed.."
    while true; do
      read -rp $'\033[39m#\033[0m Do you want to try to perform another backup? (Y/n) ' yes_no
      case "${yes_no}" in
         [Yy]*|"")
            unifi_backup
            unifi_backup_check
            break;;
         [Nn]*)
            header
            echo -e "${GRAY_R}#${RESET} Skipping the UniFi Network Application backup.."; sleep 3
            break;;
         *) echo -e "\\n${RED}#${RESET} Invalid input, please answer Yes or No (y/n)...\\n"; sleep 3;;
      esac
    done
  fi
}

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                     Ask For Device Upgrade                                                                                      #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

schedule_or_upgrade_now() {
  header
  echo -e "${GRAY_R}#${RESET} Please choice your device upgrade/downgrade option below."
  echo -e "\\n${GRAY_R}---${RESET}\\n"
  echo -e " [   ${WHITE_R}1${RESET}   ]  |  Upgrade all devices."
  echo -e " [   ${WHITE_R}2${RESET}   ]  |  Downgrade all devices."
  echo -e " [   ${WHITE_R}3${RESET}   ]  |  Schedule upgrades for all devices."
  echo -e " [   ${WHITE_R}4${RESET}   ]  |  Schedule downgrades for all devices."
  echo -e " [   ${WHITE_R}5${RESET}   ]  |  Cancel Script.\\n\\n"
  read -rp $'Your choice | \033[39m' choice
  case "$choice" in
     1)
        option_upgrade="true"
        unifi_upgrade_devices_var_1='upgrading'
        unifi_upgrade_devices_var_2='upgrade'
        unifi_upgrade_devices;;
     2)
        option_upgrade="false"
        unifi_upgrade_devices_var_1='downgrading'
        unifi_upgrade_devices_var_2='downgrade'
        unifi_upgrade_devices;;
     3)
        option_upgrade="true"
        unifi_upgrade_devices_var_1='upgrading'
        unifi_upgrade_devices_var_2='upgrade'
        unifi_upgrade_scheduler;;
     4)
        option_upgrade="false"
        unifi_upgrade_devices_var_1='downgrading'
        unifi_upgrade_devices_var_2='downgrade'
        unifi_upgrade_scheduler;;
     5) cancel_script;;
	 *) 
        header_red
        echo -e "${GRAY_R}#${RESET} '${choice}' is not a valid option..." && sleep 2
        schedule_or_upgrade_now;;
  esac
}

run_unifi_devices_upgrade() {
  if [[ "${executed_unifi_credentials}" != 'true' ]]; then
    unifi_credentials
    executed_unifi_credentials="true"
  fi
  unifi_login
  unifi_list_sites
  override_inform_host
  firmware_cache_question
  schedule_or_upgrade_now
  firmware_cache_remove_question
}

only_run_unifi_devices_upgrade() {
  unifi_credentials
  unifi_login
  unifi_list_sites
  override_inform_host
  firmware_cache_question
  schedule_or_upgrade_now
  firmware_cache_remove_question
  unifi_logout
  alert_event_cleanup
  devices_update_finish
}

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                   5.10.x Upgrades ( 5.6.42 )                                                                                    #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

unifi_firmware_requirement() {
  eus_directory_location="/tmp/EUS"
  eus_create_directories "requirement"
  header
  echo -e "${GRAY_R}#${RESET} Checking if all devices pass the minimum required firmware check..." # Gen1 Switches, Gen1/Gen2/Gen3 Access Points and all USG models.
  "${mongocommand}" --quiet --port 27117 ace --eval "${mongoprefix}db.getCollection('device').find({model: {\$in: ['UGWXG', 'UGW4', 'UGW3', 'US48P750', 'S248750', 'US48P500', 'S248500', 'US48', 'US48PL2', 'US24P500', 'S224500', 'US24P250', 'S224250', 'US24', 'US24PL2', 'US16P150', 'S216150', 'USXG', 'US8P150', 'S28150', 'US8P60', 'US8', 'USC8', 'USC8P450', 'US6XG150', 'U7HD', 'U7SHD', 'UCXG', 'UXSDM', 'UXBSDM', 'U7PG2', 'U7LT', 'U7LR', 'U7IW', 'U7MSH', 'U7MP', 'U7EDU', 'U7IWP', 'BZ2', 'BZ2LR', 'U2Sv2', 'U2SV2', 'U2Lv2', 'U2LV2', 'U2O', 'U5O', 'U2HSR', 'U2IW', 'U7P', 'U7E', 'U7Ev2', 'U7EV2', 'U7O']}})${mongosuffix}" | sed 's/\(ObjectId(\|)\|NumberLong(\)\|ISODate(//g' | jq '.[] | {type: .type, model: .model, version: .version, build_id: (.version | split(".") | .[3]), connected_at: .connected_at}' > /tmp/EUS/requirement/device_type_model_version
  sed -i 's/"connected_at": null/"connected_at": 0/g' /tmp/EUS/requirement/device_type_model_version
  while read -r build_id; do
    if [[ "${required_upgrade}" == 'true' ]]; then break; fi
    if [[ "${build_id}" -lt "9636" ]]; then required_upgrade="true"; fi
  done < <(jq -r '. | select((.type == "uap" or .type == "usw") and (.connected_at > 0)) | .build_id' /tmp/EUS/requirement/device_type_model_version | awk '!NF || !seen[$0]++')
  while read -r build_id; do
    if [[ "${required_upgrade}" == 'true' ]]; then break; fi
    if [[ "${build_id}" -lt "12088" ]]; then required_upgrade="true"; fi
  done < <(jq -r '. | select((.type == "uap" or .type == "usw")) | select(.model|test("^UA","^US6")) | select(.connected_at > 0) | .build_id' /tmp/EUS/requirement/device_type_model_version | awk '!NF || !seen[$0]++')
  while read -r build_id; do
    if [[ "${required_upgrade}" == 'true' ]]; then break; fi
    if [[ "${build_id}" -lt "5140624" ]]; then required_upgrade="true"; fi
  done < <(jq -r '. | select((.type == "ugw") and (.connected_at > 0)) | .build_id' /tmp/EUS/requirement/device_type_model_version | awk '!NF || !seen[$0]++')
  if [[ "${required_upgrade}" == 'true' ]]; then
    echo -e "${YELLOW}#${RESET} There are devices that require to be updated in order to manage them..."
  else
    echo -e "${GREEN}#${RESET} None of the devices need to be upgraded! You're all good!"
  fi
  sleep 3
  if [[ "${required_upgrade}" == 'true' && "${executed_unifi_credentials}" != 'true' ]]; then
    executed_unifi_credentials="true"
    header
    echo -e "${GRAY_R}#${RESET} Your devices need a firmware upgrade in order to continue to manage them."
    while true; do
      read -rp $'\033[39m#\033[0m Do you want to use the script to upgrade all your devices? (Y/n) ' yes_no
      case "$yes_no" in
          [Yy]*|"")
             unifi_credentials
             unifi_login
             break;;
          [Nn]*)
             echo -e "\\n${RED}---${RESET}\\n"
             echo -e "${GRAY_R}#${RESET} Taking the risk of not upgrading your devices..."
             run_unifi_firmware_check="no"
             break;;
          *) echo -e "\\n${RED}#${RESET} Invalid input, please answer Yes or No (y/n)...\\n"; sleep 3;;
      esac
    done
  fi
  if [[ "${required_upgrade}" == 'true' && "${run_unifi_firmware_check}" != 'no' ]]; then
    while true; do
      header
      echo -e "${GRAY_R}#${RESET} Your devices need to be updated in order to work with the newer UniFi Network Application releease..."
      echo -e "${GRAY_R}#${RESET} What would you like to do? \\n"
      echo -e " [   ${WHITE_R}1${RESET}   ]  |  Update all devices via the script ( default )"
      echo -e " [   ${WHITE_R}2${RESET}   ]  |  Don't upgrade the devices"
      echo -e " [   ${WHITE_R}3${RESET}   ]  |  cancel\\n\\n\\n"
      read -rp $'Your choice | \033[39m' required_upgrade_question
      case "$required_upgrade_question" in
          1*|"") run_unifi_devices_upgrade; break;;
          2*) break;;
          3*) cancel_script; break;;
          *) echo -e "\\n${RED}#${RESET} Invalid input, please answer with 1, 2 or 3...\\n"; sleep 3;;
      esac
    done
  fi
}

usg_unsupported_notice() {
  eus_directory_location="/tmp/EUS"
  eus_create_directories "requirement"
  header
  echo -e "${GRAY_R}#${RESET} Checking if your setup contains any UniFi Security Gateway models..."
  "${mongocommand}" --quiet --port 27117 ace --eval "${mongoprefix}db.getCollection('device').find({model: {\$in: ['UGWXG', 'UGW4', 'UGW3']}})${mongosuffix}" | sed 's/\(ObjectId(\|)\|NumberLong(\)\|ISODate(//g' | jq 'map(select(.type != null) | {type: .type, model: .model, version: .version, build_id: (.version | split(".") | .[3] // "unknown"), connected_at: .connected_at, site_id: .site_id, mac: .mac})' > /tmp/EUS/requirement/usg_unsupported_notice
  sed -i 's/"connected_at": null/"connected_at": 0/g' /tmp/EUS/requirement/usg_unsupported_notice
  usg_unsupported_site_count="$(jq 'length' /tmp/EUS/requirement/usg_unsupported_notice 2> /dev/null)"
  if [[ "${usg_unsupported_site_count}" -gt "5" ]]; then usg_unsupported_site_count_max="8"; else usg_unsupported_site_count_max="${usg_unsupported_site_count}"; fi
  if [[ "${usg_unsupported_site_count}" -ge "1" ]]; then
    usg_unsupported_site_number="0"
    sed -i 's/UGW3/USG3/g' /tmp/EUS/requirement/usg_unsupported_notice
    sed -i 's/UGW4/USG-Pro-4/g' /tmp/EUS/requirement/usg_unsupported_notice
    sed -i 's/UGWXG/USG-XG-8/g' /tmp/EUS/requirement/usg_unsupported_notice
    until [[ "${usg_unsupported_site_number}" == "${usg_unsupported_site_count_max}" ]]; do
      usg_unsupported_model="$(jq -r ".[${usg_unsupported_site_number}].model" /tmp/EUS/requirement/usg_unsupported_notice 2> /dev/null)"
      usg_unsupported_mac="$(jq -r ".[${usg_unsupported_site_number}].mac" /tmp/EUS/requirement/usg_unsupported_notice 2> /dev/null)"
      usg_unsupported_site_object_id="$(jq -r ".[${usg_unsupported_site_number}].site_id" /tmp/EUS/requirement/usg_unsupported_notice 2> /dev/null)"
      usg_unsupported_site_desc="$("${mongocommand}" --quiet --port 27117 ace --eval "${mongoprefix}db.getCollection('site').find({\"_id\":ObjectId('${usg_unsupported_site_object_id}')})${mongosuffix}" 2> /dev/null | sed 's/\(ObjectId(\|)\|NumberLong(\)\|ISODate(//g' 2> /dev/null | jq -r '.[].desc' 2> /dev/null)"
      if [[ "$(jq -r ".[${usg_unsupported_site_number}].connected_at" /tmp/EUS/requirement/usg_unsupported_notice 2> /dev/null)" -ge "1" ]]; then usg_unsupported_device_status="Online (connected)"; else usg_unsupported_device_status="Offline (disconnected)"; fi
      if [[ "${usg_unsupported_site_number}" == "0" ]]; then echo -e "${GRAY_R}#${RESET} The script detected the following UniFi Security Gateways on your setup: \\n"; fi
      echo -e "${GRAY_R}#${RESET} ${usg_unsupported_model} (${usg_unsupported_mac}) was detected on ${usg_unsupported_site_desc}, and it's currently ${usg_unsupported_device_status}..."
      ((usg_unsupported_site_number=usg_unsupported_site_number+1))
      if [[ "${usg_unsupported_site_number}" == "${usg_unsupported_site_count_max}" && "$((usg_unsupported_site_count - usg_unsupported_site_count_max))" != "0" ]]; then echo -e "\\n${GRAY_R}#${RESET} Along with $((usg_unsupported_site_count - usg_unsupported_site_count_max)) other sites that contain UniFi Security Gateway models..."; fi
    done
    echo -e "\\n${GRAY_R}#${RESET} Please note that the UniFi Security Gateways are no longer officially supported. If you proceed with the"
    echo -e "${GRAY_R}#${RESET} upgrade, you'll no longer be able to make any further configuration changes involving these gateways. \\n"
    while true; do
      read -rp $'\033[39m#\033[0m Do you want to proceed with the upgrade and lose configuration control for these devices? (y/N) ' yes_no
      case "$yes_no" in
          [Yy]*)
             if [[ "$(dpkg-query --showformat='${version}' --show jq 2> /dev/null | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
               jq '.scripts."'"${script_name}"'" |= . + {"tasks": (.tasks + {"usg-unsupported-notice ('"$(date +%Y%m%d_%H%M_%s)"')":[{"user-warned":"true"}]})}' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
             else
               jq '.scripts["'"${script_name}"'"] |= (.tasks += {"usg-unsupported-notice ('"$(date +%Y%m%d_%H%M_%s)"')": [{"user-warned":"true"}]})' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
             fi
             eus_database_move
             break;;
          [Nn]*|"")
             if [[ "$(dpkg-query --showformat='${version}' --show jq 2> /dev/null | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
               jq '.scripts."'"${script_name}"'" |= . + {"tasks": (.tasks + {"usg-unsupported-notice ('"$(date +%Y%m%d_%H%M_%s)"')":[{"user-cancelled":"true"}]})}' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
             else
               jq '.scripts["'"${script_name}"'"] |= (.tasks += {"usg-unsupported-notice ('"$(date +%Y%m%d_%H%M_%s)"')": [{"user-cancelled":"true"}]})' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
             fi
             eus_database_move
             cancel_script
             break;;
          *) echo -e "\\n${RED}#${RESET} Invalid input, please answer Yes or No (y/n)...\\n"; sleep 3;;
      esac
    done
  else
    echo -e "${GREEN}#${RESET} Your setup doesn't appear to have any USG models, we're good! \\n"; sleep 3
  fi
}

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                            OS Update                                                                                            #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

mongodb_upgrade_check() {
  while read -r mongodb_upgrade_check_package; do
    # shellcheck disable=SC2016
    mongodb_upgrade_check_from_version="$("$(which dpkg)"-query --showformat='${Version}' --show "${mongodb_upgrade_check_package}" | sed "s/.*://" | sed "s/-.*//g" | sed "s/\.//g")"
    mongodb_upgrade_check_to_version="$(apt-cache madison "${mongodb_upgrade_check_package}" 2>/dev/null | awk '{print $3}' | sort -V | tail -n 1 | sed 's/.*://' | sed 's/-.*//g' | sed 's/\.//g')"
    if [[ "${mongodb_upgrade_check_to_version::2}" -gt "${mongodb_upgrade_check_from_version::2}" ]]; then
      check_dpkg_lock
      echo -e "${GRAY_R}#${RESET} Preventing ${mongodb_upgrade_check_package} from upgrading..."
      if echo "${mongodb_upgrade_check_package} hold" | "$(which dpkg)" --set-selections &>> "${eus_dir}/logs/package-hold.log"; then
        echo -e "${GREEN}#${RESET} Successfully prevented ${mongodb_upgrade_check_package} from upgrading! \\n"
      else
        echo -e "${RED}#${RESET} Failed to prevent ${mongodb_upgrade_check_package} from upgrading...\\n"
        if [[ "${mongodb_upgrade_check_remove_old_mongo_repo}" != 'true' ]]; then remove_older_mongodb_repositories; mongodb_upgrade_check_remove_old_mongo_repo="true"; run_apt_get_update; fi
      fi
    fi
  done < <("$(which dpkg)" -l | awk '{print $1,$2}' | awk '/ii.*mongo/ {print $2}' | sed 's/:.*//')
}

os_upgrade () {
  cleanup_codename_mismatch_repos
  remove_apt_options="true"
  get_apt_options
  rm --force /tmp/EUS/dpkg/unifi_list &> /dev/null
  rm --force /tmp/EUS/dpkg/mongodb_list &> /dev/null
  rm --force /tmp/EUS/upgrade/upgrade_list &> /dev/null
  header
  echo -e "${GRAY_R}#${RESET} You're about to upgrade/update the OS with all it's packages, I recommend"
  echo -e "${GRAY_R}#${RESET} creating a backup/snapshot of the current state of the machine/VM.\\n"
  echo -e " [   ${WHITE_R}1${RESET}   ]  |  Continue with the upgrade/update"
  echo -e " [   ${WHITE_R}2${RESET}   ]  |  Create a UniFi Network Application backup before the upgrade/update"
  echo -e " [   ${WHITE_R}3${RESET}   ]  |  Cancel\\n\\n"
  read -rp $'Your choice | \033[39m' OS_EASY_UPDATE
  case "$OS_EASY_UPDATE" in
      1*) ;;
      2*)
        header
        echo -e "${GRAY_R}#${RESET} Starting the UniFi Network Application backup.\\n\\n"
        unifi_credentials
        unifi_login
        if [[ "${unifi_backup_cancel}" != 'true' ]]; then
          debug_check
          unifi_list_sites
          unifi_backup
          unifi_backup_check
        fi
        unifi_logout
        login_cleanup;;
       3|*) cancel_script;;
  esac
  header
  echo -e "${GRAY_R}#${RESET} Starting the OS update/upgrade.\\n"
  sleep 2
  while read -r service; do
    check_dpkg_lock
    echo -e "${GRAY_R}#${RESET} Preventing ${service} from upgrading..."
    if echo "${service} hold" | "$(which dpkg)" --set-selections &>> "${eus_dir}/logs/package-hold.log"; then echo -e "${GREEN}#${RESET} Successfully prevented ${service} from upgrading! \\n"; else abort_reason="Failed to prevent ${service} from upgrading."; abort; fi
  done < <("$(which dpkg)" -l | awk '/unifi/ {print $2}' | awk -F '[:]' '{print $1}')
  run_apt_get_update
  mongodb_upgrade_check
  sleep 5 && header
  echo -e "${GRAY_R}#${RESET} Upgrading the packages on your machine...\\n${GRAY_R}#${RESET} Below you will see a few of the packages that will upgrade...\\n"
  rm --force /tmp/EUS/upgrade/upgrade_list &> /dev/null
  { apt-get --just-print upgrade 2>&1 | perl -ne 'if (/Inst\s([\w,\-,\d,\.,~,:,\+]+)\s\[([\w,\-,\d,\.,~,:,\+]+)\]\s\(([\w,\-,\d,\.,~,:,\+]+)\)? /i) {print "$1 ( \e[1;34m$2\e[0m -> \e[1;32m$3\e[0m )\n"}';} | while read -r line; do echo -en "${GRAY_R}-${RESET} ${line}\\n"; echo -en "${line}\\n" | awk '{print $1}' &>> /tmp/EUS/upgrade/upgrade_list; done;
  if [[ -f /tmp/EUS/upgrade/upgrade_list ]]; then number_of_updates=$(wc -l < /tmp/EUS/upgrade/upgrade_list); else number_of_updates='0'; fi
  if [[ "${number_of_updates}" == '0' ]]; then echo -e "${GRAY_R}#${RESET} There are no packages that need an upgrade..."; fi
  sleep 3
  echo -e "\\n${GRAY_R}----${RESET}\\n"
  if [[ -f /tmp/EUS/upgrade/upgrade_list && -s /tmp/EUS/upgrade/upgrade_list ]]; then
    while read -r package; do
      check_dpkg_lock
      echo -e "\\n------- updating ${package} ------- $(date +%F-%T.%6N) -------\\n" &>> "${eus_dir}/logs/upgrade.log"
      echo -ne "\\r${GRAY_R}#${RESET} Updating package ${package}..."
      if DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' --only-upgrade install "${package}" 2>&1 | tee -a "${eus_dir}/logs/upgrade.log" > /tmp/EUS/apt/install.log; then
        if [[ "${PIPESTATUS[0]}" -eq "0" ]]; then echo -e "\\r${GREEN}#${RESET} Successfully updated package ${package}!"; fi
      elif tail -n1 /usr/lib/EUS/logs/upgrade.log | grep -ioq "Packages were downgraded and -y was used without --allow-downgrades" "${eus_dir}/logs/upgrade.log"; then
        check_dpkg_lock
        if DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' --only-upgrade --allow-downgrades install "${package}" 2>&1 | tee -a "${eus_dir}/logs/upgrade.log" > /tmp/EUS/apt/install.log; then
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
  if ls /tmp/EUS/apt/*.log 1> /dev/null 2>&1; then check_package_cache_file_corruption; check_extended_states_corruption; https_died_unexpectedly_check; check_time_date_for_repositories; cleanup_malformed_repositories; cleanup_duplicated_repositories; cleanup_unavailable_repositories; cleanup_conflicting_repositories; if [[ "${repository_changes_applied}" == 'true' ]]; then unset repository_changes_applied; run_apt_get_update; fi; fi
  check_dpkg_lock
  echo -e "\\n------- apt-get upgrade ------- $(date +%F-%T.%6N) -------\\n" &>> "${eus_dir}/logs/upgrade.log"
  echo -e "${GRAY_R}#${RESET} Running apt-get upgrade..."
  if DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' upgrade 2>&1 | tee -a "${eus_dir}/logs/upgrade.log" > /tmp/EUS/apt/upgrade.log; then if [[ "${PIPESTATUS[0]}" -eq "0" ]]; then echo -e "${GREEN}#${RESET} Successfully ran apt-get upgrade! \\n"; else echo -e "${RED}#${RESET} Failed to run apt-get upgrade... \\n"; fi; fi
  check_dpkg_lock
  echo -e "\\n------- apt-get dist-upgrade ------- $(date +%F-%T.%6N) -------\\n" &>> "${eus_dir}/logs/upgrade.log"
  echo -e "${GRAY_R}#${RESET} Running apt-get dist-upgrade..."
  if DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' dist-upgrade 2>&1 | tee -a "${eus_dir}/logs/upgrade.log" > /tmp/EUS/apt/dist-upgrade.log; then if [[ "${PIPESTATUS[0]}" -eq "0" ]]; then echo -e "${GREEN}#${RESET} Successfully ran apt-get dist-upgrade! \\n"; else echo -e "${RED}#${RESET} Failed to run apt-get dist-upgrade... \\n"; fi; fi
  echo -e "${GRAY_R}#${RESET} Running apt-get autoremove..."
  if apt-get -y autoremove &>> "${eus_dir}/logs/apt-cleanup.log"; then echo -e "${GREEN}#${RESET} Successfully ran apt-get autoremove! \\n"; else echo -e "${RED}#${RESET} Failed to run apt-get autoremove"; fi
  echo -e "${GRAY_R}#${RESET} Running apt-get autoclean..."
  if apt-get -y autoclean &>> "${eus_dir}/logs/apt-cleanup.log"; then echo -e "${GREEN}#${RESET} Successfully ran apt-get autoclean! \\n"; else echo -e "${RED}#${RESET} Failed to run apt-get autoclean"; fi
  check_dpkg_lock
  if [[ -f /tmp/EUS/dpkg/unifi_list && -s /tmp/EUS/dpkg/unifi_list ]]; then
    while read -r service; do
      echo "${service} install" | "$(which dpkg)" --set-selections 2> /dev/null
    done < /tmp/EUS/dpkg/unifi_list
  fi
  if [[ -f /tmp/EUS/dpkg/mongodb_list && -s /tmp/EUS/dpkg/mongodb_list ]]; then
    while read -r service; do
      echo "${service} install" | "$(which dpkg)" --set-selections 2> /dev/null
    done < /tmp/EUS/dpkg/mongodb_list
  fi
  rm --force /tmp/EUS/dpkg/unifi_list &> /dev/null
  rm --force /tmp/EUS/dpkg/mongodb_list &> /dev/null
  rm --force /tmp/EUS/upgrade/upgrade_list &> /dev/null
  sleep 5
  daemon_reexec
  os_update_finish
}

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                Alerts and Events Archive/Delete                                                                                 #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

are_you_sure() {
  header_red
  read -rp $'\033[39m#\033[0m Do you you want to proceed with '"${are_you_sure_var}"'? (y/N) ' yes_no
  case "$yes_no" in
     [Nn]*|"") are_you_sure_proceed="no";;
     [Yy]*) are_you_sure_proceed="yes";;
	 *)
       header_red
       echo -e "${RED}#${RESET} Invalid input, please answer Yes or No (y/n)...\\n" && sleep 3
       are_you_sure;;
  esac
  if [[ "${are_you_sure_proceed}" == 'no' ]]; then
    header_red
    echo -e "${GRAY_R}#${RESET} Cancelling operation: ${are_you_sure_var}"
    exit 1
  fi
}

alert_event_option() {
  header
  echo -e "${GRAY_R}#${RESET} Please take an option below."
  echo -e "${GRAY_R}#${RESET} Note: Archiving/Deleting events, alarms and alerts can take a long time on big setups.\\n"
  echo -e " [   ${WHITE_R}1${RESET}   ]  |  Archive all Alarms"
  echo -e " [   ${WHITE_R}2${RESET}   ]  |  Delete all Events"
  echo -e " [   ${WHITE_R}3${RESET}   ]  |  Delete all Alarms"
  echo -e " [   ${WHITE_R}4${RESET}   ]  |  Delete all Alerts"
  echo -e " [   ${WHITE_R}5${RESET}   ]  |  Delete all Events, Alarms and Alerts"
  echo -e " [   ${WHITE_R}6${RESET}   ]  |  Cancel Script\\n\\n"
  read -rp $'Your choice | \033[39m' alert_event_option_var
  case "$alert_event_option_var" in
      1*)
        are_you_sure_var="archiving all alarms"
        are_you_sure
        if [[ "${are_you_sure_proceed}" == 'yes' ]]; then
          header
          echo -e "${GRAY_R}#${RESET} Archiving the alarms..."
          alarm_collection_available="$("${mongocommand}" --quiet --port 27117 --eval "use('ace'); db.getCollectionNames().indexOf('alarm') !== -1" 2> /dev/null)"
          if [[ "${mongodb_server_version::2}" -gt "30" ]]; then
            if [[ "${alarm_collection_available}" == 'true' ]]; then
              # shellcheck disable=SC2016
              modified_count="$("${mongocommand}" --quiet --port 27117 ace --eval ''"${mongoprefix}"'db.alarm.updateMany({},{"$set": {"archived": true}}) )' | jq '."modifiedCount"')"
              echo -e "${GREEN}#${RESET} Successfully archived ${modified_count} alarms..."
            else
              echo -e "${YELLOW}#${RESET} The alert collection couldn't be found in the database, skipping..."
            fi
          else
            if [[ "${alarm_collection_available}" == 'true' ]]; then
              # shellcheck disable=SC2016
              "${mongocommand}" --quiet --port 27117 ace --eval 'db.alarm.update({},{$set: {"archived": true}},{multi: true})' | awk '{ nModified=$10 ; print "\033[1;32m#\033[0m Successfully archived " nModified " alarms" }' # nModified
            else
              echo -e "${YELLOW}#${RESET} The alert collection couldn't be found in the database, skipping..."
            fi
          fi
          echo -e "\\n"
          sleep 5
        fi;;
      2*)
        are_you_sure_var="deleting all events"
        are_you_sure
        if [[ "${are_you_sure_proceed}" == 'yes' ]]; then
          header
          echo -e "${GRAY_R}#${RESET} Deleting all events...\\n"
          event_collection_available="$("${mongocommand}" --quiet --port 27117 --eval "use('ace'); db.getCollectionNames().indexOf('event') !== -1" 2> /dev/null)"
          if [[ "${mongodb_server_version::2}" -gt "30" ]]; then
            if [[ "${event_collection_available}" == 'true' ]]; then
              deleted_count="$("${mongocommand}" --quiet --port 27117 ace --eval "${mongoprefix}db.event.deleteMany({}) )" | jq '."deletedCount"')"
              echo -e "${GREEN}#${RESET} Successfully deleted ${deleted_count} events..."
            else
              echo -e "${YELLOW}#${RESET} The event collection couldn't be found in the database, skipping..."
            fi
          else
            if [[ "${event_collection_available}" == 'true' ]]; then
              # shellcheck disable=SC2016
              "${mongocommand}" --quiet --port 27117 ace --eval 'db.event.remove({},{multi: true})' | awk '{ nRemoved=$4 ; print "\033[1;32m#\033[0m Successfully deleted " nRemoved " events" }' # nRemoved
            else
              echo -e "${YELLOW}#${RESET} The event collection couldn't be found in the database, skipping..."
            fi
          fi
          echo -e "\\n"
          sleep 5
        fi;;
      3*)
        are_you_sure_var="deleting all alarms"
        are_you_sure
        if [[ "${are_you_sure_proceed}" == 'yes' ]]; then
          header
          echo -e "${GRAY_R}#${RESET} Deleting all alarms...\\n"
          alarm_collection_available="$("${mongocommand}" --quiet --port 27117 --eval "use('ace'); db.getCollectionNames().indexOf('alarm') !== -1" 2> /dev/null)"
          if [[ "${mongodb_server_version::2}" -gt "30" ]]; then
            if [[ "${alarm_collection_available}" == 'true' ]]; then
              deleted_count="$("${mongocommand}" --quiet --port 27117 ace --eval "${mongoprefix}db.alarm.deleteMany({}) )" | jq '."deletedCount"')"
              echo -e "${GREEN}#${RESET} Successfully deleted ${deleted_count} alarms..."
            else
              echo -e "${YELLOW}#${RESET} The alarm collection couldn't be found in the database, skipping..."
            fi
          else
            if [[ "${alarm_collection_available}" == 'true' ]]; then
              # shellcheck disable=SC2016
              "${mongocommand}" --quiet --port 27117 ace --eval 'db.alarm.remove({},{multi: true})' | awk '{ nRemoved=$4 ; print "\033[1;32m#\033[0m Successfully deleted " nRemoved " alarms" }' # nRemoved
            else
              echo -e "${YELLOW}#${RESET} The alarm collection couldn't be found in the database, skipping..."
            fi
          fi
          echo -e "\\n"
          sleep 5
        fi;;
      4*)
        are_you_sure_var="deleting all alerts"
        are_you_sure
        if [[ "${are_you_sure_proceed}" == 'yes' ]]; then
          header
          echo -e "${GRAY_R}#${RESET} Deleting all alerts..."
          alert_collection_available="$("${mongocommand}" --quiet --port 27117 --eval "use('ace'); db.getCollectionNames().indexOf('alert') !== -1" 2> /dev/null)"
          if [[ "${mongodb_server_version::2}" -gt "30" ]]; then
            if [[ "${alert_collection_available}" == 'true' ]]; then
              deleted_count="$("${mongocommand}" --quiet --port 27117 ace --eval "${mongoprefix}db.alert.deleteMany({}) )" | jq '."deletedCount"')"
              echo -e "${GREEN}#${RESET} Successfully deleted ${deleted_count} alerts..."
            else
              echo -e "${YELLOW}#${RESET} The alert collection couldn't be found in the database, skipping..."
            fi
          else
            if [[ "${alert_collection_available}" == 'true' ]]; then
              # shellcheck disable=SC2016
              "${mongocommand}" --quiet --port 27117 ace --eval 'db.alert.remove({},{multi: true})' | awk '{ nRemoved=$4 ; print "\033[1;32m#\033[0m Successfully deleted " nRemoved " alerts" }' # nRemoved
            else
              echo -e "${YELLOW}#${RESET} The alert collection couldn't be found in the database, skipping..."
            fi
          fi
          echo -e "\\n"
          sleep 5
        fi;;
      5*)
        are_you_sure_var="deleting all events, alarms and alerts"
        are_you_sure
        if [[ "${are_you_sure_proceed}" == 'yes' ]]; then
          header
          echo -e "${GRAY_R}#${RESET} Deleting all events, alarms and alerts..."
          event_collection_available="$("${mongocommand}" --quiet --port 27117 --eval "use('ace'); db.getCollectionNames().indexOf('event') !== -1" 2> /dev/null)"
          alarm_collection_available="$("${mongocommand}" --quiet --port 27117 --eval "use('ace'); db.getCollectionNames().indexOf('alarm') !== -1" 2> /dev/null)"
          alert_collection_available="$("${mongocommand}" --quiet --port 27117 --eval "use('ace'); db.getCollectionNames().indexOf('alert') !== -1" 2> /dev/null)"
          if [[ "${mongodb_server_version::2}" -gt "30" ]]; then
            if [[ "${event_collection_available}" == 'true' ]]; then
              deleted_count="$("${mongocommand}" --quiet --port 27117 ace --eval "${mongoprefix}db.event.deleteMany({}) )" | jq '."deletedCount"')"
              echo -e "${GREEN}#${RESET} Successfully deleted ${deleted_count} events..."
            else
              echo -e "${YELLOW}#${RESET} The event collection couldn't be found in the database, skipping..."
            fi
            if [[ "${alarm_collection_available}" == 'true' ]]; then
              deleted_count="$("${mongocommand}" --quiet --port 27117 ace --eval "${mongoprefix}db.alarm.deleteMany({}) )" | jq '."deletedCount"')"
              echo -e "${GREEN}#${RESET} Successfully deleted ${deleted_count} alarms..."
            else
              echo -e "${YELLOW}#${RESET} The alarm collection couldn't be found in the database, skipping..."
            fi
            if [[ "${alert_collection_available}" == 'true' ]]; then
              deleted_count="$("${mongocommand}" --quiet --port 27117 ace --eval "${mongoprefix}db.alert.deleteMany({}) )" | jq '."deletedCount"')"
              echo -e "${GREEN}#${RESET} Successfully deleted ${deleted_count} alerts..."
            else
              echo -e "${YELLOW}#${RESET} The alert collection couldn't be found in the database, skipping..."
            fi
          else
            if [[ "${event_collection_available}" == 'true' ]]; then
              # shellcheck disable=SC2016
              "${mongocommand}" --quiet --port 27117 ace --eval 'db.event.remove({},{multi: true})' | awk '{ nRemoved=$4 ; print "\033[1;32m#\033[0m Successfully deleted " nRemoved " events" }' # nRemoved
            else
              echo -e "${YELLOW}#${RESET} The event collection couldn't be found in the database, skipping..."
            fi
            if [[ "${alarm_collection_available}" == 'true' ]]; then
              # shellcheck disable=SC2016
              "${mongocommand}" --quiet --port 27117 ace --eval 'db.alarm.remove({},{multi: true})' | awk '{ nRemoved=$4 ; print "\033[1;32m#\033[0m Successfully deleted " nRemoved " alarms" }' # nRemoved
            else
              echo -e "${YELLOW}#${RESET} The alarm collection couldn't be found in the database, skipping..."
            fi
            if [[ "${alert_collection_available}" == 'true' ]]; then
              # shellcheck disable=SC2016
              "${mongocommand}" --quiet --port 27117 ace --eval 'db.alert.remove({},{multi: true})' | awk '{ nRemoved=$4 ; print "\033[1;32m#\033[0m Successfully deleted " nRemoved " alerts" }' # nRemoved
            else
              echo -e "${YELLOW}#${RESET} The alert collection couldn't be found in the database, skipping..."
            fi
          fi
          echo -e "\\n"
          sleep 5
        fi;;
      6*) cancel_script;;
	  *)
        header_red
        echo -e "${GRAY_R}#${RESET} '${alert_event_option_var}' is not a valid option..." && sleep 2
        alert_event_option;;
  esac
  sleep 3
  event_alert_archive_delete_finish
}

##########################################################################################################################################################################
#                                                                                                                                                                        #
#                                                               Custom UniFi Network Application Download                                                                #
#                                                                                                                                                                        #
##########################################################################################################################################################################

custom_url_question() {
  if [[ "${unifi_deb_dl_failed}" != 'true' ]]; then header; fi
  if [[ "${unifi_database_version_newer}" == 'true' ]]; then 
    echo -e "${YELLOW}#${RESET} Your UniFi Network Application database is already migrated to version ${unifi_database_version}...\\n${GRAY_R}#${RESET} Please enter a UniFi Network Application version ${unifi_database_version} or newer download URL below."
  else
    echo -e "${GRAY_R}#${RESET} Please enter the UniFi Network Application download URL below."
  fi
  read -rp $'\033[39m#\033[0m ' custom_download_url
  if [[ "${unifi_deb_dl_failed}" != 'true' ]]; then custom_url_download_check; elif [[ "${unifi_deb_dl_failed}" == 'true' ]]; then mongodb_upgrade_custom_unifi_download_url_check; fi
}

mongodb_upgrade_custom_unifi_download_url_check() {
  eus_tmp_deb_name="unifi_mongodb_upgrade_${mongodb_upgrade_from_version::2}_to_${mongo_version_max}"
  eus_tmp_deb_var="unifi_temp"
  eus_tmp_directory_check
  echo -e "\\n${GRAY_R}#${RESET} Checking if you provided a correct download link for UniFi Network Application version ${first_digit_unifi}.${second_digit_unifi}.${third_digit_unifi}..."
  echo -e "$(date +%F-%T.%6N) | Downloading ${custom_download_url} to ${unifi_temp}" &>> "${eus_dir}/logs/unifi_mongodb_upgrade_${mongodb_upgrade_from_version::2}_to_${mongo_version_max}_download.log"
  if ! curl "${nos_curl_argument[@]}" --output "$unifi_temp" "${custom_download_url}" &>> "${eus_dir}/logs/unifi_mongodb_upgrade_${mongodb_upgrade_from_version::2}_to_${mongo_version_max}_download.log"; then
    echo -e "${RED}#${RESET} Unable to download UniFi Network Application version ${first_digit_unifi}.${second_digit_unifi}.${third_digit_unifi} from the URL you specified... \\n"
    sleep 3
    custom_url_question
  else
    "$(which dpkg)" -I "${unifi_temp}" | awk '{print tolower($0)}' &> "${unifi_temp}.tmp"
    package_details=$(awk '/package:/{print$2}' "${unifi_temp}.tmp")
    package_maintainer=$(awk '/maintainer/{print$2}' "${unifi_temp}.tmp")
    custom_application_version=$(awk '/version:/{print$2}' "${unifi_temp}.tmp" | awk -F"-" '{print $1}')
    if awk '/description:/{print}' "${unifi_temp}.tmp" | cut -d":" -f2 | grep -siq "unifi os network"; then
      unifi_os_package="true"
    elif [[ "${unifi_core_system}" == 'true' ]] && [[ "${package_details}" != 'unifi-native' ]]; then
      if [[ "${custom_application_version_first_digit}" -lt '7' ]] || [[ "${custom_application_version_first_digit}" == '7' ]] && [[ "${custom_application_version_second_digit}" -lt "6" ]]; then
        unifi_os_package="true"
      fi
    fi
    rm --force "${unifi_temp}.tmp" &> /dev/null
	if [[ "${package_maintainer}" =~ (unifi|ubiquiti) ]] && [[ "${unifi_os_package}" != 'true' ]] && [[ "${package_details}" != 'unifi-native' ]] && [[ "${custom_application_version}" == "${first_digit_unifi}.${second_digit_unifi}.${third_digit_unifi}" ]]; then
      unifi_deb_dl="${custom_download_url}"
      unifi_deb_md5="$(md5sum "$unifi_temp" | awk '{print $1}')"
    else
      if ! [[ "${package_maintainer}" =~ (unifi|ubiquiti) ]]; then
        echo -e "${RED}#${RESET} You did not provide a UniFi Network Application that is maintained by Ubiquiti ( UniFi )... \\n"
      elif [[ "${custom_application_version}" != "${first_digit_unifi}.${second_digit_unifi}.${third_digit_unifi}" ]]; then
        echo -e "${RED}#${RESET} You did not provide a UniFi Network Application version ${first_digit_unifi}.${second_digit_unifi}.${third_digit_unifi}... \\n"
      else
        echo -e "${RED}#${RESET} You did not provide the correct UniFi Network Application for your system... \\n"
      fi
      while true; do
        read -rp $'\033[39m#\033[0m Would you like to provide another download link? (Y/n) ' yes_no
        case "$yes_no" in
            [Yy]*|"") unset unifi_os_package; custom_url_question; break;;
            [Nn]*) break;;
            *) echo -e "\\n${RED}#${RESET} Invalid input, please answer Yes or No (y/n)...\\n"; sleep 3;;
        esac
      done
    fi
  fi
}

custom_url_upgrade_check() {
  if [[ -z "${custom_application_version}" ]]; then custom_application_version="$(echo "${custom_download_url}" | grep -io "5.*\\|6.*\\|7.*\\|8.*\\|9.*\\|10.*" | sed 's/-.*//g' | sed 's/\/.*//g')"; fi
  current_application_version="$("$(which dpkg)" -l | awk '$2 == "unifi" {print $3}' | sed 's/-.*//g')"
  if [[ -e "/usr/lib/unifi/data/db/version" ]]; then
    unifi_database_version="$(grep -E '^[0-9.]+$' "/usr/lib/unifi/data/db/version")"
    if [[ "${current_application_version}" != "${unifi_database_version}" ]]; then
      if [[ "$(echo "${unifi_database_version}" | awk -F. '{print $1$2}')" -ge "$(echo "${custom_application_version}" | awk -F. '{print $1$2}')" ]] && [[ "$(echo "${unifi_database_version}" | awk -F. '{print $3}')" -gt "$(echo "${custom_application_version}" | awk -F. '{print $3}')" ]]; then
        unifi_database_version_newer="true"
        custom_url_question
        return
      fi
    fi
  fi
  custom_application_digit_1="$(echo "${custom_application_version}" | cut -d'.' -f1)"
  custom_application_digit_2="$(echo "${custom_application_version}" | cut -d'.' -f2)"
  custom_application_digit_3="$(echo "${custom_application_version}" | cut -d'.' -f3)"
  current_application_digit_1="$(echo "${current_application_version}" | cut -d'.' -f1)"
  current_application_digit_2="$(echo "${current_application_version}" | cut -d'.' -f2)"
  current_application_digit_3="$(echo "${current_application_version}" | cut -d'.' -f3)"
  if [[ "${custom_application_digit_1}" -gt "${current_application_digit_1}" ]]; then application_upgrade="yes"; fi
  if [[ "${custom_application_digit_1}" == "${current_application_digit_1}" && "${custom_application_digit_2}" -gt "${current_application_digit_2}" ]]; then application_upgrade="yes"; fi
  if [[ "${custom_application_digit_1}" == "${current_application_digit_1}" && "${custom_application_digit_2}" == "${current_application_digit_2}" && "${custom_application_digit_3}" -gt "${current_application_digit_3}" ]]; then application_upgrade="yes"; fi
  if [[ "${custom_application_digit_1}.${custom_application_digit_2}.${custom_application_digit_3}" == "${current_application_digit_1}.${current_application_digit_2}.${current_application_digit_3}" ]]; then application_upgrade="match"; fi
  if [[ "${application_upgrade}" == 'yes' ]]; then
    first_digit_unifi="${custom_application_digit_1}"
    second_digit_unifi="${custom_application_digit_2}"
    third_digit_unifi="${custom_application_digit_3}"
    if [[ "${cloudkey_generation}" == "1" ]]; then
      if [[ "${first_digit_unifi}" -gt '7' ]] || [[ "${first_digit_unifi}" == '7' && "${second_digit_unifi}" -ge '3' ]]; then
        header_red
        echo -e "${GRAY_R}#${RESET} UniFi Network Application ${custom_application_digit_1}.${custom_application_digit_2}.${custom_application_digit_3} is not supported on your Gen1 UniFi Cloudkey (UC-CK)."
        echo -e "${GRAY_R}#${RESET} The latest supported version on your Cloudkey is $(curl "${curl_argument[@]}" "https://api.glennr.nl/api/network-latest?version=7.2" 2> /dev/null | jq -r '.latest_version' 2> /dev/null) and older.. \\n\\n"
        echo -e "${GRAY_R}#${RESET} Consider upgrading to a Gen2 Cloudkey:"
        echo -e "${GRAY_R}#${RESET} UniFi Cloud Key Gen2       | https://store.ui.com/products/unifi-cloud-key-gen2"
        echo -e "${GRAY_R}#${RESET} UniFi Cloud Key Gen2 Plus  | https://store.ui.com/products/unifi-cloudkey-gen2-plus\\n\\n"
        author
        exit 0
      fi
    fi
    if [[ "${first_digit_unifi}" -gt '7' ]] || [[ "${first_digit_unifi}" == '7' && "${second_digit_unifi}" -ge '5' ]]; then
      if [[ "$(getconf LONG_BIT)" == '32' ]]; then
        header_red
        mongodb_server_version="$("$(which dpkg)" -l | grep "^ii\\|^hi\\|^ri\\|^pi\\|^ui\\|^iU" | grep -E "(mongodb-server|mongodb-org-server|mongod-armv8|mongod-amd64)[[:space:]]" | awk '{print $3}' | sed -e 's/.*://' -e 's/-.*//' -e 's/+.*//' -e 's/\.//g')"
        if [[ "${mongodb_server_version::2}" -le "25" ]]; then unifi_latest_supported_version="7.3"; else unifi_latest_supported_version="7.4"; fi
        echo -e "${GRAY_R}#${RESET} Your 32-bit system/OS is no longer supported by UniFi Network Application ${custom_application_version}!"
        echo -e "${GRAY_R}#${RESET} The latest supported version on your system/OS is $(curl "${curl_argument[@]}" "https://api.glennr.nl/api/network-latest?version=${unifi_latest_supported_version}" 2> /dev/null | jq -r '.latest_version' 2> /dev/null) and older..."
        echo -e "${GRAY_R}#${RESET} Consider upgrading to a 64-bit system/OS!\\n\\n"
        author
        exit 0
      fi
    fi
    if [[ "${unifi_core_system}" != 'true' ]]; then
      if [[ "${first_digit_unifi}" -gt '7' ]] || [[ "${first_digit_unifi}" == '7' && "${second_digit_unifi}" -ge '4' ]] || [[ "${first_digit_unifi}" == '7' && "${second_digit_unifi}" -ge '5' ]]; then
        if [[ "${first_digit_unifi}" -gt '7' ]] || [[ "${first_digit_unifi}" == '7' && "${second_digit_unifi}" -ge '5' ]]; then
          minimum_required_mongodb_version_dot="3.6"
          minimum_required_mongodb_version="36"
          unifi_latest_supported_version_number="7.4"
        elif [[ "${first_digit_unifi}" == '7' && "${second_digit_unifi}" -ge '4' ]]; then
          minimum_required_mongodb_version_dot="2.6"
          minimum_required_mongodb_version="26"
          unifi_latest_supported_version_number="7.3"
        fi
        mongodb_server_version="$("$(which dpkg)" -l | grep "^ii\\|^hi\\|^ri\\|^pi\\|^ui\\|^iU" | grep -E "(mongodb-server|mongodb-org-server|mongod-armv8|mongod-amd64)[[:space:]]" | awk '{print $3}' | sed -e 's/.*://' -e 's/-.*//' -e 's/+.*//' -e 's/\.//g')"
        if [[ "${mongodb_server_version::2}" -lt "${minimum_required_mongodb_version}" ]]; then
          if [[ "${unifi_core_system}" == 'true' ]]; then
            if [[ "${os_codename}" == 'stretch' ]]; then
              header_red
              echo -e "${GRAY_R}#${RESET} UniFi Network Application ${first_digit_unifi}.${second_digit_unifi}.${third_digit_unifi} requires a newer version of UniFi OS."
              echo -e "${GRAY_R}#${RESET} The latest version that you can run with UniFi OS version $(cut -d'.' -f3,4,5 /usr/lib/version | sed 's/v//g') is $(curl "${curl_argument[@]}" "https://api.glennr.nl/api/network-latest?version=${unifi_latest_supported_version_number}" 2> /dev/null | jq -r '.latest_version' 2> /dev/null) and older.. \\n\\n"
              unifi_core_upgrade_message="true"
            else
              unifi_core_mongodb_upgrade_bypass="true"
            fi
          else
            header_red
            echo -e "${GRAY_R}#${RESET} UniFi Network Application ${first_digit_unifi}.${second_digit_unifi}.${third_digit_unifi} requires MongoDB ${minimum_required_mongodb_version_dot} or newer."
            echo -e "${GRAY_R}#${RESET} The latest version that you can run with MongoDB version $("$(which dpkg)" -l | grep -E "(mongodb-server|mongodb-org-server|mongod-armv8|mongod-amd64)[[:space:]]" | awk '{print $3}' | sed -e 's/.*://' -e 's/-.*//' -e 's/+.*//') is $(curl "${curl_argument[@]}" "https://api.glennr.nl/api/network-latest?version=${unifi_latest_supported_version_number}" 2> /dev/null | jq -r '.latest_version' 2> /dev/null) and older.. \\n\\n"
            if [[ "${mongodb_org_v::2}" =~ (24|26|30|32|34) && "${mongo_version_max}" == "36" && "${mongodb_upgrade_supported}" == 'true' ]] || [[ "${mongodb_org_v::2}" =~ (24|26|30|32|34|36|40|42) && "${mongo_version_max}" == "44" && "${mongodb_upgrade_supported}" == 'true' ]]; then
              while true; do
                read -rp $'\033[39m#\033[0m Would you like to run the option to upgrade to MongoDB '"${mongo_version_max_with_dot}"'? (Y/n) ' yes_no
                case "$yes_no" in
                     [Yy]*|"")
                        unifi_update_mongodb_upgrade_process="true"
                        echo -e "${GRAY_R}#${RESET} OK... Starting the MongoDB Upgrade process..."
                        sleep 5
                        mongodb_upgrade
                        break;;
                     [Nn]*)
                        echo -e "${YELLOW}#${RESET} OK... Please re-execute the script when you feel ready!"
                        break;;
                     *) echo -e "\\n${RED}#${RESET} Invalid input, please answer Yes or No (y/n)...\\n"; sleep 3;;
                esac
              done
            else
              echo -e "${GRAY_R}#${RESET} The script will first update the UniFi Network Application to version $(curl "${curl_argument[@]}" "https://api.glennr.nl/api/network-latest?version=${unifi_latest_supported_version_number}" 2> /dev/null | jq -r '.latest_version' 2> /dev/null) before updating to version ${first_digit_unifi}.${second_digit_unifi}.${third_digit_unifi}... \\n"
	          sleep 5
              original_application_version="${custom_application_version}"
              application_version="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/network-latest?version=${unifi_latest_supported_version_number}" 2> /dev/null | jq -r '.latest_version' 2> /dev/null)"
              application_upgrade_releases
              get_mongo_version_max
              application_version="${original_application_version}"
              application_upgrade_releases
              return 0
            fi
          fi
          if [[ "$(getconf LONG_BIT)" == '32' ]]; then
            echo -e "${GRAY_R}#${RESET} You're using a 32-bit OS.. please switch over to a 64-bit OS.\\n\\n"
          fi
          if [[ "${unifi_update_mongodb_upgrade_process_success}" != 'true' && "${unifi_core_mongodb_upgrade_bypass}" != 'true' ]]; then
            author
            exit 0
          fi
        fi
      fi
    fi
    if [[ "$(command -v jq)" ]]; then net_update_supported_api_status="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/network-supported-upgrade?status" 2> /dev/null | jq -r '.availability' 2> /dev/null)"; else net_update_supported_api_status="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/network-supported-upgrade?status" 2> /dev/null | grep -oP '(?<="availability":")[^"]+')"; fi
    if [[ "${net_update_supported_api_status}" == "OK" ]]; then
      if [[ "$(command -v jq)" ]]; then net_update_supported="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/network-supported-upgrade?current_version=${current_application_version}&new_version=${custom_application_version}" 2> /dev/null | jq -r '.supported' 2> /dev/null | sed '/null/d' 2> "${eus_dir}/logs/glennr-api.log")"; else net_update_supported="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/network-supported-upgrade?current_version=${current_application_version}&new_version=${custom_application_version}" 2> /dev/null | grep -oP '(?<="supported":")[^"]+')"; fi
      if [[ "${net_update_supported}" == 'true' ]]; then
        custom_url_install
      elif [[ "${net_update_supported}" == 'false' ]]; then
        echo -e "\\n${GRAY_R}----${RESET}\\n"
        echo -e "${GRAY_R}#${RESET} You're about to perform a unsupported UniFi Network Application update from \"${current_application_version}\" to \"${custom_application_version}\"..."
        echo -e "${GRAY_R}#${RESET} Canceling the script..."; cancel_script
      fi
    else
      echo -e "\\n${GRAY_R}----${RESET}\\n"
      echo -e "${GRAY_R}#${RESET} You're about to upgrade your UniFi Network Application from \"${current_application_version}\" to \"${custom_application_version}\"."
      while true; do
        read -rp $'\033[39m#\033[0m Did you confirm that this upgrade is supported? (y/N) ' yes_no
        case "$yes_no" in
            [Yy]*) custom_url_install; break;;
            [Nn]*|"") echo -e "${GRAY_R}#${RESET} Canceling the script.."; cancel_script; break;;
            *) echo -e "\\n${RED}#${RESET} Invalid input, please answer Yes or No (y/n)...\\n"; sleep 3;;
        esac
      done
    fi
  elif [[ "${application_upgrade}" == 'match' ]]; then
    header
	echo -e "${GRAY_R}#${RESET} Your UniFi Network Application is already running \"${current_application_version}\"...\\n\\n"
    author
    exit 0
  elif [[ "${application_upgrade}" != 'yes' ]]; then
    header_red
	echo -e "${GRAY_R}#${RESET} You were about to downgrade your UniFi Network Application from \"${current_application_version}\" to \"${custom_application_version}\".. Cancelling this upgrade..\\n\\n"
    author
    exit 0
  fi
}

custom_url_download_check() {
  eus_tmp_deb_name="${unifi_deb_file_name}"
  eus_tmp_deb_var="unifi_temp"
  eus_tmp_directory_check
  header
  echo -e "${GRAY_R}#${RESET} Downloading the UniFi Network Application release..."
  echo -e "$(date +%F-%T.%6N) | Downloading ${custom_download_url} to ${unifi_temp}" &>> "${eus_dir}/logs/unifi_custom_url_download.log"
  if ! curl "${nos_curl_argument[@]}" --output "$unifi_temp" "${custom_download_url}" &>> "${eus_dir}/logs/unifi_custom_url_download.log"; then
    header_red
    echo -e "${GRAY_R}#${RESET} The URL you provided cannot be downloaded.. Please provide a working URL."
    sleep 3
    custom_url_question
  else
    "$(which dpkg)" -I "${unifi_temp}" | awk '{print tolower($0)}' &> "${unifi_temp}.tmp"
    package_details="$(awk '/package:/{print$2}' "${unifi_temp}.tmp")"
    package_maintainer="$(awk '/maintainer/{print$2}' "${unifi_temp}.tmp")"
    custom_application_version="$(awk '/version:/{print$2}' "${unifi_temp}.tmp" | awk -F"-" '{print $1}')"
    custom_application_version_first_digit="$(echo "${custom_application_version}" | cut -d'.' -f1)"
    custom_application_version_second_digit="$(echo "${custom_application_version}" | cut -d'.' -f2)"
    #custom_application_version_third_digit="$(echo "${custom_application_version}" | cut -d'.' -f3)"
    if awk '/description:/{print}' "${unifi_temp}.tmp" | cut -d":" -f2 | grep -siq "unifi os network"; then
      unifi_os_package="true"
    elif [[ "${unifi_core_system}" == 'true' ]] && [[ "${package_details}" != 'unifi-native' ]]; then
      if [[ "${custom_application_version_first_digit}" -lt '7' ]] || [[ "${custom_application_version_first_digit}" == '7' ]] && [[ "${custom_application_version_second_digit}" -lt "6" ]]; then
        unifi_os_package="true"
      fi
    fi
    rm --force "${unifi_temp}.tmp" &> /dev/null
    if [[ "${package_details}" == 'unifi-native' ]] && [[ "${unifi_native_system}" == 'true' ]] && [[ "${package_maintainer}" =~ (unifi|ubiquiti) ]]; then
      echo -e "${GREEN}#${RESET} Successfully downloaded the UniFi Native Network Application release!"
      sleep 2
      custom_url_upgrade_check
    elif [[ "${unifi_os_package}" == 'true' ]] && [[ "${unifi_core_system}" == 'true' ]] && [[ "${unifi_native_system}" != 'true' ]] && [[ "${package_maintainer}" =~ (unifi|ubiquiti) ]]; then
      echo -e "${GREEN}#${RESET} Successfully downloaded the UniFi OS Network Application release!"
      sleep 2
      custom_url_upgrade_check
    elif [[ "${package_maintainer}" =~ (unifi|ubiquiti) ]] && [[ "${unifi_os_package}" != 'true' ]] && [[ "${package_details}" != 'unifi-native' ]] && [[ "${unifi_core_system}" != 'true' ]]; then
      echo -e "${GREEN}#${RESET} Successfully downloaded the UniFi Network Application release!"
      sleep 2
      custom_url_upgrade_check
    else
      header_red
      if [[ "${unifi_native_system}" == 'true' ]] && [[ "${package_details}" != 'unifi-native' ]]; then
        echo -e "${GRAY_R}#${RESET} You did not provide a UniFi Native Network Application..."
      elif [[ "${unifi_core_system}" == 'true' ]] && [[ "${unifi_native_system}" != 'true' ]] && [[ "${unifi_os_package}" != 'true' ]]; then
        echo -e "${GRAY_R}#${RESET} You did not provide a UniFi OS Network Application..."
      elif [[ "${package_maintainer}" =~ (unifi|ubiquiti) ]]; then
        echo -e "${GRAY_R}#${RESET} You did not provide a UniFi Network Application that is maintained by Ubiquiti ( UniFi )..."
      else
        echo -e "${GRAY_R}#${RESET} You did not provide the correct UniFi Network Application for your system..."
      fi
      while true; do
        read -rp $'\033[39m#\033[0m Do you want to provide the script with anothe URL? (Y/n) ' yes_no
        case "$yes_no" in
            [Yy]*|"") custom_url_question; break;;
            [Nn]*) break;;
            *) echo -e "\\n${RED}#${RESET} Invalid input, please answer Yes or No (y/n)...\\n"; sleep 3;;
        esac
      done
    fi
  fi
}

custom_url_install() {
  db_version_check
  system_properties_check
  unifi_autobackup_dir_check
  keystore_alias_check
  #if [[ "${current_application_digit_1}" -lt "9" && "${custom_application_digit_1}" -ge "9" ]]; then usg_unsupported_notice; fi
  if [[ -s "/tmp/EUS/repository/unifi-repo-file" && "${release_stage}" == "S" ]]; then
    while read -r unifi_repo_file; do
      unifi_repo_file_version_current=$(grep -io "unifi-[0-9].[0-9]" "${unifi_repo_file}")
      unifi_repo_file_version_new="unifi-${custom_application_digit_1}.${custom_application_digit_2}"
      sed -i "s/${unifi_repo_file_version_current}/${unifi_repo_file_version_new}/g" "${unifi_repo_file}" &>> "${eus_dir}/logs/unifi_repo_file_update.log"
    done < /tmp/EUS/repository/unifi-repo-file
  fi
  java_install_check
  header
  check_service_overrides
  old_systemd_version_check
  check_service_timeoutsec_increase
  unifi_deb_package_modification
  ignore_unifi_package_dependencies
  if [[ "${current_application_digit_1}${current_application_digit_2}" -le "80" && "${custom_application_digit_1}${custom_application_digit_2}" -ge "81" ]]; then
    echo -e "${GRAY_R}#${RESET} Upgrading your UniFi Network Application from \"${current_application_version}\" to \"${custom_application_version}\" could take up to ${unifi_upgrade_estimate_duration}"
    echo -e "${GRAY_R}#${RESET} because it needs to migrate $("${mongocommand}" --quiet --port 27117 ace_stat --eval "${mongoprefix}db.dpi.stats() )" 2> /dev/null | jq '.count' 2> /dev/null) Traffic Identification records..."
  else
    echo -e "${GRAY_R}#${RESET} Upgrading your UniFi Network Application from \"${current_application_version}\" to \"${custom_application_version}\"..."
    echo -e "${GRAY_R}#${RESET} This process could take up to ${unifi_upgrade_estimate_duration}..."
  fi
  if [[ "$(dpkg-query --showformat='${version}' --show jq 2> /dev/null | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
    jq '.scripts."'"${script_name}"'" |= if .["upgrade-path"] | index("'"${current_application_digit_1}.${current_application_digit_2}.${current_application_digit_3} > ${custom_application_digit_1}.${custom_application_digit_2}.${custom_application_digit_3}"'") | not then .["upgrade-path"] += ["'"${current_application_digit_1}.${current_application_digit_2}.${current_application_digit_3} > ${custom_application_digit_1}.${custom_application_digit_2}.${custom_application_digit_3}"'"] else . end' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
  else
    jq --arg script_name "$script_name" --arg current_app "$current_application_digit_1.$current_application_digit_2.$current_application_digit_3" --arg custom_app "$custom_application_digit_1.$custom_application_digit_2.$custom_application_digit_3" '.scripts[$script_name] |= (if .["upgrade-path"] | type == "array" | not then.["upgrade-path"] = []| .["upgrade-path"] += [$current_app + " > " + $custom_app]else.["upgrade-path"] |= (if map(select(. == ($current_app + " > " + $custom_app))) | length == 0 then. + [$current_app + " > " + $custom_app] else . end ) end )' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
  fi
  eus_database_move
  echo -e "\\n------- $(date +%F-%T.%6N) -------\\n" &>> "${eus_dir}/logs/unifi-update.log"
  check_dpkg_lock
  if [[ "${unifi_core_system}" != 'true' ]]; then
    echo "unifi unifi/has_backup boolean true" 2> /dev/null | debconf-set-selections
    # shellcheck disable=SC2086
    DEBIAN_FRONTEND='noninteractive' "$(which dpkg)" -i ${dpkg_ignore_depends_flag} "${unifi_temp}" &>> "${eus_dir}/logs/unifi-update.log" 2>&1 &
    update_progress_pid="$!"
    monitor_update_progress_pid "${update_progress_pid}"
    wait "${update_progress_pid}"
    update_progress_exit_code="$?"
  else
    DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "${unifi_temp}" &>> "${eus_dir}/logs/unifi-update.log" 2>&1 &
    update_progress_pid="$!"
    monitor_update_progress_pid "${update_progress_pid}"
    wait "${update_progress_pid}"
    update_progress_exit_code="$?"
  fi
  if [[ "${update_progress_exit_code}" -eq "0" ]]; then
    echo -e "${GREEN}#${RESET} Successfully updated UniFi Network version from ${current_application_version} to ${custom_application_version}! \\n"
  else
    abort_reason="Failed to update the UniFi Network version from ${current_application_version} to ${custom_application_version}."
    abort
  fi
  sleep 3
  java_cleanup_not_required_versions
  rm --force "$unifi_temp" 2> /dev/null
  unifi_update_finish
}

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                     MongoDB Upgrade Process                                                                                     #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

mongodb_upgrade() {
  mongodb_upgrade_started_success_value="true"
  get_unifi_api_ports
  get_unifi_application_status
  if [[ "${application_up}" != "true" ]]; then
    header_red
    echo -e "${YELLOW}#${RESET} The UniFi Network Application is not up and running yet...\\n"
    echo -e "${GRAY_R}#${RESET} $(curl -sk --connect-timeout 1 "${status_api_protocol}://localhost:${dmport}/status" | jq -r '.meta."app_context_status"' 2> /dev/null | sed '/null/d')"
    if [[ "${noproxy_curl_argument_used}" == 'true' ]]; then
      until [[ "$(curl "${noproxy_curl_argument[@]}" --silent --insecure --connect-timeout 1 "${status_api_protocol}://localhost:${dmport}/status" | jq '.meta.up' 2> /dev/null)" == "true" ]]; do
        if [[ "${net_not_started_message}" != 'true' ]]; then echo -e "\\n${GRAY_R}#${RESET} It's performing the following actions..."; net_not_started_message="true"; fi
        echo -ne "\033[K${GRAY_R}#${RESET} $(curl "${noproxy_curl_argument[@]}" --silent --insecure --connect-timeout 1 "${status_api_protocol}://localhost:${dmport}/status" | jq -r '.meta."app_context_message"' 2> /dev/null | sed '/null/d')...\\r"
        sleep 5
      done
    else
      until [[ "$(curl --silent --insecure --connect-timeout 1 "${status_api_protocol}://localhost:${dmport}/status" | jq '.meta.up' 2> /dev/null)" == "true" ]]; do
        if [[ "${net_not_started_message}" != 'true' ]]; then echo -e "\\n${GRAY_R}#${RESET} It's performing the following actions..."; net_not_started_message="true"; fi
        echo -ne "\033[K${GRAY_R}#${RESET} $(curl --silent --insecure --connect-timeout 1 "${status_api_protocol}://localhost:${dmport}/status" | jq -r '.meta."app_context_message"' 2> /dev/null | sed '/null/d')...\\r"
        sleep 5
      done
    fi
  fi
  unifi_database_location="$(readlink -f /usr/lib/unifi/data/db)"
  unifi_database_location_user="$(stat -c "%U" "${unifi_database_location}")"
  unifi_database_location_group="$(stat -c "%G" "${unifi_database_location}")"
  unifi_logs_location="$(readlink -f /usr/lib/unifi/logs)"
  if [[ -z "${unifi_database_location}" ]]; then unifi_database_location="/usr/lib/unifi/data/db"; fi
  unifi_db_eus_dir="${eus_dir}"
  mongodb_upgrade_date="$(date +%Y%m%d_%H%M_%s)"
  mongodb_upgrade_from_version_with_dots="$("$(which dpkg)" -l | grep -E "(mongodb-server|mongodb-org-server|mongodb-10gen|mongod-armv8|mongod-amd64)[[:space:]]" | grep -i "^ii\\|^hi\\|^ri\\|^pi\\|^ui" | awk '{print $3}' | sed 's/.*://' | sed 's/-.*//g' | sed 's/+.*//g' | sort -V | tail -n 1)"
  mongodb_upgrade_from_version="$("$(which dpkg)" -l | grep -E "(mongodb-server|mongodb-org-server|mongodb-10gen|mongod-armv8|mongod-amd64)[[:space:]]" | grep -i "^ii\\|^hi\\|^ri\\|^pi\\|^ui" | awk '{print $3}' | sed 's/\.//g' | sed 's/.*://' | sed 's/-.*//g' | sed 's/+.*//g' | sort -V | tail -n 1)"
  mongodb_org_upgrade_from_version_with_dots="$("$(which dpkg)" -l | grep -E "(mongodb-org-server|mongod-armv8|mongod-amd64)[[:space:]]" | grep -i "^ii\\|^hi\\|^ri\\|^pi\\|^ui" | awk '{print $3}' | sed 's/.*://' | sed 's/-.*//g' | sed 's/+.*//g' | sort -V | tail -n 1)"
  mongodb_org_upgrade_from_version="$("$(which dpkg)" -l | grep -E "(mongodb-org-server|mongod-armv8|mongod-amd64)[[:space:]]" | grep -i "^ii\\|^hi\\|^ri\\|^pi\\|^ui" | awk '{print $3}' | sed 's/\.//g' | sed 's/.*://' | sed 's/-.*//g' | sed 's/+.*//g' | sort -V | tail -n 1)"
  mongodb_upgrade_mongodb_org_message="Updating"
  mongodb_upgrade_mongodb_org_message_2="updated"
  mongodb_upgrade_mongodb_org_message_3="update"
  if [[ "${mongodb_org_upgrade_from_version::2}" == "34" && "${mongo_version_max}" == '36' ]]; then
    mongodb_upgrade_without_export_import="true"
  elif [[ "${mongodb_org_upgrade_from_version::2}" == "42" && "${mongo_version_max}" == '44' ]]; then
    mongodb_upgrade_without_export_import="true"
  elif [[ "${mongodb_org_upgrade_from_version::2}" == "60" && "${mongo_version_max}" == '70' ]]; then
    mongodb_upgrade_without_export_import="true"
  elif [[ "${mongodb_org_upgrade_from_version::2}" == "70" && "${mongo_version_max}" == '80' ]]; then
    mongodb_upgrade_without_export_import="true"
  fi
  check_unifi_folder_permissions_state="before"
  check_unifi_folder_permissions
  if [[ "${glennr_compiled_mongod}" == 'true' ]]; then unset mongodb_upgrade_without_export_import; fi
  if [[ "$(dpkg-query --showformat='${version}' --show jq 2> /dev/null | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
    jq '.scripts."'"${script_name}"'" |= . + {"tasks": (.tasks + {"mongodb-upgrade ('"${mongodb_upgrade_date}"')":[{"distribution":"'"${os_codename}"'","from":"'"${mongodb_upgrade_from_version_with_dots}"'","to":"'"${mongo_version_max_with_dot}"'","unifi-version":"'"${unifi}"'","Glenn R. MongoDB":"'"${glennr_compiled_mongod}"'"}]})}' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
  else
    jq '.scripts["'"${script_name}"'"] |= (.tasks += {"mongodb-upgrade ('"${mongodb_upgrade_date}"')": [{"distribution": "'"${os_codename}"'", "from": "'"${mongodb_upgrade_from_version_with_dots}"'", "to": "'"${mongo_version_max_with_dot}"'", "unifi-version": "'"${unifi}"'", "Glenn R. MongoDB": "'"${glennr_compiled_mongod}"'"}]})' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
  fi
  eus_database_move
  unifi_video="$("$(which dpkg)" -l | awk '$2 == "unifi-video" {print $3}' | sed 's/-.*//')"
  if "$(which dpkg)" -l | grep "unifi-video" | grep "^ii\\|^hi\\|^ri\\|^pi\\|^ui\\|^iU"; then
    if [[ "${mongo_version_max}" == '36' ]]; then
      first_digit_unifi_video="$(echo "${unifi_video}" | cut -d'.' -f1)"
      second_digit_unifi_video="$(echo "${unifi_video}" | cut -d'.' -f2)"
      if ! [[ "${first_digit_unifi_video}" -ge '3' && "${second_digit_unifi_video}" -ge '10' ]]; then
        check_apt_listbugs
        header_red
        echo -e "${RED}#${RESET} You need to upgrade UniFi-Video to 3.10.x or newer.."
        echo -e "${RED}#${RESET} Always backups prior to upgrading anything! \\n\\n"
        exit 0
      fi
    else
      check_apt_listbugs
      header_red
      echo -e "${RED}#${RESET} You should run UniFi Video elsewhere.. or migrate to UniFi Protect..."
      echo -e "${RED}#${RESET} Exiting the script...\\n\\n"
      exit 0
    fi
  fi
  if [[ "${mongodb_upgrade_without_export_import}" != 'true' ]]; then mongodb_upgrade_space_check; fi
  header
  echo -e "${GRAY_R}#${RESET} Checking if you already created a UniFi Network Application backup..."
  if [[ "${glennr_unifi_backup}" != 'success' ]]; then
    echo -e "${YELLOW}#${RESET} You didn't take a backup using the UniFi Easy Update Script..."
    while true; do
      read -rp $'\033[39m#\033[0m Do you want to take a UniFi Network Application backup using the script? (Y/n) ' yes_no
      case "$yes_no" in
         [Yy]*|"")
            header
            echo -e "${GRAY_R}#${RESET} Starting the UniFi Network Application backup.\\n\\n"
            unifi_credentials
            unifi_login
            if [[ "${unifi_backup_cancel}" != 'true' ]]; then
              debug_check
              unifi_list_sites
              unifi_backup
              unifi_backup_check
            fi
            unifi_logout
            login_cleanup
            break;;
         [Nn]*)
            while true; do
              read -rp $'\033[39m#\033[0m Did you take a UniFi Network Application backup outside of the script? (y/N) ' yes_no
              case "$yes_no" in
                 [Yy]*)
                    header
                    echo -e "${GREEN}#${RESET} Alright, then we're good to go! \\n"
                    break;;
                 [Nn]*|"")
                    header_red
                    echo -e "${RED}#${RESET} Please take a backup of your UniFi Network Application and then run the script again. \\n"
                    exit 1
                    break;;
                 *) echo -e "\\n${RED}#${RESET} Invalid input, please answer Yes or No (y/n)...\\n"; sleep 3;;
              esac
            done
            break;;
         *) echo -e "\\n${RED}#${RESET} Invalid input, please answer Yes or No (y/n)...\\n"; sleep 3;;
      esac
    done
  else
    echo -e "${GREEN}#${RESET} You've already created a backup using the script! \\n"
  fi
  header
  if "$(which dpkg)" -l mongodb-org-server 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
    mongodb_org_version="$(dpkg-query --showformat='${version}' --show mongodb-org-server 2> /dev/null | sed 's/.*://' | sed 's/-.*//g')"
    mongodb_package_requirement_check="true"
    mongodb_package_libssl="mongodb-org-tools"
    mongodb_package_version_libssl="${mongodb_org_version}"
    libssl_installation_check
    if ! apt-cache policy mongodb-org-tools | grep -ioq "${mongodb_org_version}"; then remove_older_mongodb_repositories; add_mongodb_repo; fi
    if ! "$(which dpkg)" -l mongodb-org-tools 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
	  install_mongodb_org_tools="true"
      multiple_attempt_to_install_package_task="install"
	else
	  mongodb_org_tools_version="$(dpkg-query --showformat='${version}' --show mongodb-org-tools 2> /dev/null | sed 's/.*://' | sed 's/-.*//g' | sed 's/\.//g')"
      if [[ "${mongodb_org_tools_version}" != "${mongodb_org_version//./}" ]]; then install_mongodb_org_tools="true"; fi
      multiple_attempt_to_install_package_task="downgrade"
    fi
    if [[ "${install_mongodb_org_tools}" == 'true' ]]; then
      if "$(which dpkg)" -l mongo-tools 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
        check_dpkg_lock
        echo -e "${GRAY_R}#${RESET} Purging package mongo-tools..."
        if DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' purge "mongo-tools" &>> "${eus_dir}/logs/unifi-database-required.log"; then
          echo -e "${GREEN}#${RESET} Successfully purged mongo-tools! \\n"
        else
          echo -e "${RED}#${RESET} Failed to purge mongo-tools...\\n"
          if [[ -e "/var/lib/dpkg/info/mongo-tools.prerm" ]]; then eus_create_directories "dpkg"; mv "/var/lib/dpkg/info/mongo-tools.prerm" "${eus_dir}/dpkg/mongo-tools.prerm-${mongodb_upgrade_date}"; fi
          echo -e "${GRAY_R}#${RESET} Trying another method to get rid of mongo-tools..."
          if DEBIAN_FRONTEND='noninteractive' "$(which dpkg)" --remove --force-remove-reinstreq "mongo-tools" &>> "${eus_dir}/logs/unifi-database-required.log"; then
            echo -e "${GREEN}#${RESET} Successfully removed mongo-tools! \\n"
            mongodb_upgrade_unifi_remove="true"
          else
            echo -e "${RED}#${RESET} Failed to force remove mongo-tools...\\n"
            abort_function_skip_reason="true"; abort_reason="Failed to purge mongo-tools."; abort
          fi
        fi
      fi
      te_mongodb_org_server_version="${mongodb_org_version//./}"
      if "$(which dpkg)" -l mongodb-org-database-tools-extra 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui" && [[ "${te_mongodb_org_server_version::2}" -lt "44" ]]; then
        mongodb_tools_extra_dependencies=()
        if "$(which dpkg)" -l | awk '{print $2}' | grep -ioq "mongodb-org-database$"; then mongodb_tools_extra_dependencies+=("mongodb-org-database"); fi
        if "$(which dpkg)" -l | awk '{print $2}' | grep -ioq "mongodb-org-tools$"; then mongodb_tools_extra_dependencies+=("mongodb-org-tools"); fi
        if "$(which dpkg)" -l | awk '{print $2}' | grep -ioq "mongodb-org$"; then mongodb_tools_extra_dependencies+=("mongodb-org"); fi
        if [[ "${#mongodb_tools_extra_dependencies[@]}" -gt 0 ]]; then tools_extra_dependency_extra_packages_message=", $(IFS=,; echo "${mongodb_tools_extra_dependencies[*]}" | sed 's/,/, /g; s/,\([^,]*\)$/ and\1/')"; fi
        check_dpkg_lock
        echo -e "${GRAY_R}#${RESET} Purging package mongodb-org-database-tools-extra${tools_extra_dependency_extra_packages_message}..."
        if DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' purge "mongodb-org-database-tools-extra" "${mongodb_tools_extra_dependencies[@]}" &>> "${eus_dir}/logs/unifi-database-required.log"; then
          echo -e "${GREEN}#${RESET} Successfully purged mongodb-org-database-tools-extra${tools_extra_dependency_extra_packages_message}! \\n"
        else
          echo -e "${RED}#${RESET} Failed to purge mongodb-org-database-tools-extra${tools_extra_dependency_extra_packages_message}...\\n"
          abort_function_skip_reason="true"; abort_reason="Failed to purge mongodb-org-database-tools-extra${tools_extra_dependency_extra_packages_message}."; abort
        fi
      fi
      multiple_attempt_to_install_package_log="unifi-database-required"
      multiple_attempt_to_install_package_attempts_max="3"
      multiple_attempt_to_install_package_name="mongodb-org-tools"
      multiple_attempt_to_install_package_version_with_equal_sign="=${mongodb_org_version}"
      multiple_attempt_to_install_package
      get_apt_options
    fi
    if ! apt-cache policy mongodb-org-shell | grep -ioq "${mongodb_org_version}"; then remove_older_mongodb_repositories; add_mongodb_repo; fi
    if ! "$(which dpkg)" -l mongodb-org-shell 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
	  install_mongodb_org_shell="true"
      multiple_attempt_to_install_package_task="install"
	else
	  install_mongodb_org_shell="$(dpkg-query --showformat='${version}' --show mongodb-org-shell 2> /dev/null | sed 's/.*://' | sed 's/-.*//g' | sed 's/\.//g')"
      if [[ "${install_mongodb_org_shell}" != "${mongodb_org_version//./}" ]]; then install_mongodb_org_shell="true"; fi
      multiple_attempt_to_install_package_task="downgrade"
    fi
    if [[ "${install_mongodb_org_shell}" == 'true' ]]; then
      multiple_attempt_to_install_package_log="unifi-database-required"
      multiple_attempt_to_install_package_attempts_max="1"
      multiple_attempt_to_install_package_name="mongodb-org-shell"
      multiple_attempt_to_install_package_version_with_equal_sign="=${mongodb_org_version}"
      multiple_attempt_to_install_package
      get_apt_options
    fi
  fi
  if "$(which dpkg)" -l mongodb-server 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
    mongodb_server_ver="$("$(which dpkg)" -l | grep "mongodb-server" | grep -i "^ii\\|^hi\\|^ri\\|^pi\\|^ui" | awk '{print $3}' | sed 's/\.//g' | sed 's/.*://' | sed 's/-.*//g' | sed 's/+.*//g' | sort -V | tail -n 1)"
    if ! [[ "${mongodb_server_ver::2}" =~ (26|24) ]]; then
      if ! "$(which dpkg)" -l mongo-tools 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
        if "$(which dpkg)" -l mongodb-database-tools 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
          check_dpkg_lock
          echo -e "${GRAY_R}#${RESET} Purging package mongodb-database-tools..."
          if DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' purge "mongodb-database-tools" &>> "${eus_dir}/logs/unifi-database-required.log"; then
            echo -e "${GREEN}#${RESET} Successfully purged mongodb-database-tools! \\n"
          else
            echo -e "${RED}#${RESET} Failed to purge mongodb-database-tools... \\n"
            check_dpkg_lock
            echo -e "${GRAY_R}#${RESET} Trying another method to get rid of mongodb-database-tools..."
            if DEBIAN_FRONTEND='noninteractive' "$(which dpkg)" --remove --force-remove-reinstreq "mongodb-database-tools" &>> "${eus_dir}/logs/unifi-database-required.log"; then
              echo -e "${GREEN}#${RESET} Successfully removed mongodb-database-tools! \\n"
            else
              echo -e "${RED}#${RESET} Failed to force remove mongodb-database-tools...\\n"
              abort_function_skip_reason="true"; abort_reason="Failed to purge mongodb-database-tools while attempting to install mongo-tools."; abort
            fi
          fi
        fi
        check_dpkg_lock
        echo -e "${GRAY_R}#${RESET} Installing mongo-tools..."
        if ! DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install mongo-tools &>> "${eus_dir}/logs/unifi-database-required.log"; then
          echo -e "${RED}#${RESET} Failed to install mongo-tools...\\n"
          if [[ "${os_codename}" =~ (trusty|utopic|vivid|wily|yakkety|zesty|artful|qiana|rebecca|rafaela|rosa|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing|sarah|serena|sonya|sylvia|tara|tessa|tina|tricia) ]]; then
            repo_component="main universe"
            repo_codename="xenial"
            get_repo_url
            add_repositories
            run_apt_get_update
          elif [[ "${os_codename}" =~ (wheezy|jessie|stretch|buster|bullseye|bookworm|trixie|forky|unstable) ]]; then
            repo_component="main"
            repo_codename="stretch"
            get_repo_url
            add_repositories
            run_apt_get_update
          fi
          check_dpkg_lock
          check_unmet_dependencies
          echo -e "${GRAY_R}#${RESET} Trying to install mongo-tools for the second time..."
          if ! DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install mongo-tools &>> "${eus_dir}/logs/unifi-database-required.log"; then
            echo -e "${RED}#${RESET} Failed to install mongo-tools in the second run...\\n"
            if [[ "${os_codename}" =~ (noble|oracular|plucky|questing) ]]; then
              repo_component="main"
              repo_codename="jammy"
              get_repo_url
              add_repositories
              run_apt_get_update
            fi
            echo -e "${GRAY_R}#${RESET} Trying to install mongo-tools for the third time..."
            mongo_last_attempt_type="tools"
            mongo_last_attempt
            if [[ "${mongo_last_attempt_install_success}" != 'true' ]]; then abort_reason="Failed to install mongo-tools through mongo_last_attempt function during the MongoDB Upgrade process."; abort_function_skip_reason="true"; abort; fi
          else
            echo -e "${GREEN}#${RESET} Successfully installed mongo-tools! \\n" && sleep 2
          fi
        else
          echo -e "${GREEN}#${RESET} Successfully installed mongo-tools! \\n" && sleep 2
        fi
      fi
    fi
    if ! "$(which dpkg)" -l mongodb-clients 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
      check_dpkg_lock
      echo -e "${GRAY_R}#${RESET} Installing mongodb-clients..."
      if ! DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install mongodb-clients &>> "${eus_dir}/logs/unifi-database-required.log"; then
        echo -e "${RED}#${RESET} Failed to install mongodb-clients...\\n"
          if [[ "${os_codename}" =~ (trusty|utopic|vivid|wily|yakkety|zesty|artful|qiana|rebecca|rafaela|rosa|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|plucky|questing|sarah|serena|sonya|sylvia|tara|tessa|tina|tricia) ]]; then
            repo_component="main universe"
            repo_codename="xenial"
            get_repo_url
            add_repositories
            run_apt_get_update
          elif [[ "${os_codename}" =~ (wheezy|jessie|stretch|buster|bullseye|bookworm|trixie|forky|unstable) ]]; then
            repo_component="main"
            repo_codename="stretch"
            get_repo_url
            add_repositories
            run_apt_get_update
          fi
        check_dpkg_lock
        check_unmet_dependencies
        echo -e "${GRAY_R}#${RESET} Trying to install mongodb-clients for the second time..."
        if ! DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install mongodb-clients &>> "${eus_dir}/logs/unifi-database-required.log"; then
          echo -e "${RED}#${RESET} Failed to install mongodb-clients in the second run...\\n"
          echo -e "${GRAY_R}#${RESET} Trying to install mongodb-clients for the third time..."
          mongo_last_attempt_type="clients"
          mongo_last_attempt
          if [[ "${mongo_last_attempt_install_success}" != 'true' ]]; then abort_reason="Failed to install mongodb-clients through mongo_last_attempt function during the MongoDB Upgrade process."; abort_function_skip_reason="true"; abort; fi
        else
          echo -e "${GREEN}#${RESET} Successfully installed mongodb-clients! \\n" && sleep 2
        fi
      else
        echo -e "${GREEN}#${RESET} Successfully installed mongodb-clients! \\n" && sleep 2
      fi
    fi
  fi
  if [[ "${mongodb_upgrade_from_version::2}" -ge "32" ]]; then gzip_mongodb_option="--gzip"; fi
  if mongodump --help | grep -ioq "numParallelCollections"; then
    if [[ "$(awk '/MemFree/ { printf "%.0f \n", $2/1024/1024 }' /proc/meminfo)" -le "2" ]]; then
      numparallelcollections_mongodb_option="--numParallelCollections=1"
    else
      numparallelcollections_mongodb_option="--numParallelCollections=4"
    fi
  fi
  jq '.scripts["'"$script_name"'"].tasks += {"mongodb-upgrade ('"${mongodb_upgrade_date}"')": [.scripts["'"$script_name"'"].tasks["mongodb-upgrade ('"${mongodb_upgrade_date}"')"][0] + {"parameters":["'"${numparallelcollections_mongodb_option}"'","'"${gzip_mongodb_option}"'"]}]}' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
  eus_database_move
  echo -e "${GRAY_R}#${RESET} Checking what packages depend on MongoDB..."
  if [[ -e "/tmp/EUS/mongodb/reverse_depends" ]]; then rm --force "/tmp/EUS/mongodb/reverse_depends" &> /dev/null; fi
  if [[ -e "/tmp/EUS/mongodb/reverse_depends_no_check" ]]; then rm --force "/tmp/EUS/mongodb/reverse_depends_no_check" &> /dev/null; fi
  while read -r mongodb_package_depends; do
    apt-cache rdepends "${mongodb_package_depends}" | sed "/mongo/d" | sed "/Reverse Depends/d" | awk '!a[$0]++' | sed 's/|//g' | sed 's/ //g' | sed -e 's/unifi-video//g' -e 's/unifi//g' -e 's/libstdc++6//g' -e 's/golang-github-juju-testing-dev//g' -e '/^$/d' &>> /tmp/EUS/mongodb/reverse_depends_no_check
  done < <("$(which dpkg)" -l | grep "mongodb" | grep "^ii\\|^hi\\|^ri\\|^pi\\|^ui\\|^iU" | awk '{print $2}')
  while read -r depends_mongodb_package; do
    if "$(which dpkg)" -l "${depends_mongodb_package}" 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then echo -e "${depends_mongodb_package}" &>> /tmp/EUS/mongodb/reverse_depends; fi
  done < /tmp/EUS/mongodb/reverse_depends_no_check
  if [[ -s /tmp/EUS/mongodb/reverse_depends ]]; then
    echo -e "${RED}#${RESET} The following services depend on MongoDB...\\n"
    while read -r service; do echo -e "${RED}-${RESET} ${service}"; done < /tmp/EUS/mongodb/reverse_depends
    echo -e "\\n${GRAY_R}#${RESET} NOTE: The packages/services listed above will also be removed if you proceed..."
    while true; do
      read -rp $'\033[39m#\033[0m Would you like to continue with the MongoDB upgrade? (y/N) ' yes_no
      case "$yes_no" in
         [Nn]*|"")
            echo -e "${YELLOW}#${RESET} Alrighty... cancelling the MongoDB Upgrade...\\n"
            sleep 3
            cancel_script
            break;;
         [Yy]*)
            echo -e "${GREEN}#${RESET} Alrighty... continuing the MongoDB Upgrade...\\n"
            sleep 3
            while read -r reverse_depends_package; do
              check_dpkg_lock
              echo -e "${GRAY_R}#${RESET} Removing package ${reverse_depends_package}..."
              if DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' remove "${reverse_depends_package}" &>> "${eus_dir}/logs/mongodb_upgrade_${mongodb_upgrade_from_version::2}_to_${mongo_version_max}.log"; then
                echo -e "${GREEN}#${RESET} Successfully removed ${reverse_depends_package}! \\n"
              else
                echo -e "${RED}#${RESET} Failed to remove ${reverse_depends_package}...\\n"
                check_dpkg_lock
                echo -e "${GRAY_R}#${RESET} Trying another method to get rid of ${reverse_depends_package}..."
                if DEBIAN_FRONTEND='noninteractive' "$(which dpkg)" --remove --force-remove-reinstreq "${reverse_depends_package}" &>> "${eus_dir}/logs/mongodb_upgrade_${mongodb_upgrade_from_version::2}_to_${mongo_version_max}.log"; then
                  echo -e "${GREEN}#${RESET} Successfully removed ${reverse_depends_package}! \\n"
                else
                  echo -e "${RED}#${RESET} Failed to force remove ${reverse_depends_package}...\\n"
                  abort_function_skip_reason="true"; abort_reason="Failed to remove ${reverse_depends_package}."; abort
                fi
              fi
            done < /tmp/EUS/mongodb/reverse_depends
            break;;
         *) echo -e "\\n${RED}#${RESET} Invalid input, please answer Yes or No (y/n)...\\n"; sleep 3;;
      esac
    done
  else
    echo -e "${GREEN}#${RESET} Only UniFi Depends on MongoDB, we are good to go! \\n"
  fi
  # Add default repositories to the system.
  check_default_repositories
  #
  remove_older_mongodb_repositories
  if [[ "${glennr_compiled_mongod}" == 'true' && "${mongo_version_max}" == '80' ]]; then
    unset add_mongod_70_repo
    unset add_mongodb_70_repo
    add_mongod_80_repo="true"
    add_mongodb_80_repo="true"
    add_mongodb_repo
  elif [[ "${glennr_compiled_mongod}" == 'true' && "${mongo_version_max}" == '70' ]]; then
    unset add_mongod_80_repo
    unset add_mongodb_80_repo
    add_mongod_70_repo="true"
    add_mongodb_70_repo="true"
    add_mongodb_repo
  else
    libssl_installation_check
    if [[ "${mongo_version_max}" == '80' ]]; then
      unset add_mongodb_30_repo
      unset add_mongodb_32_repo
      unset add_mongodb_34_repo
      unset add_mongodb_36_repo
      unset add_mongodb_44_repo
      unset add_mongodb_50_repo
      unset add_mongodb_60_repo
      unset add_mongodb_70_repo
      add_mongodb_80_repo="true"
      add_mongodb_repo
    elif [[ "${mongo_version_max}" == '70' ]]; then
      unset add_mongodb_30_repo
      unset add_mongodb_32_repo
      unset add_mongodb_34_repo
      unset add_mongodb_36_repo
      unset add_mongodb_44_repo
      unset add_mongodb_50_repo
      unset add_mongodb_60_repo
      add_mongodb_70_repo="true"
      add_mongodb_repo
    elif [[ "${mongo_version_max}" == '44' ]]; then
      unset add_mongodb_30_repo
      unset add_mongodb_32_repo
      unset add_mongodb_34_repo
      unset add_mongodb_36_repo
      add_mongodb_44_repo="true"
      add_mongodb_repo
    elif [[ "${mongo_version_max}" == '36' ]]; then
      unset add_mongodb_30_repo
      unset add_mongodb_32_repo
      unset add_mongodb_34_repo
      unset add_mongodb_44_repo
      add_mongodb_36_repo="true"
      add_mongodb_repo
    fi
  fi
  jq '.scripts["'"$script_name"'"].tasks += {"mongodb-upgrade ('"${mongodb_upgrade_date}"')": [.scripts["'"$script_name"'"].tasks["mongodb-upgrade ('"${mongodb_upgrade_date}"')"][0] + {"add-mongodb-repo":"'"${mongodb_add_repo_variables_true_statements[*]}"'"}]}' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
  eus_database_move
  #
  "$(which dpkg)" -l | grep "^ii\\|^hi\\|^ri\\|^pi\\|^ui\\|^iU" | awk '{print$2}' | grep "^unifi" | awk '{print $1}' &> /tmp/EUS/mongodb/unifi_package_list
  token="$("${mongocommand}" --quiet --port 27117 ace --eval 'db.setting.find({"key": "super_fwupdate"}).forEach(function(document){ print(document.x_sso_token) })' | grep -Eio "[0-9,a-z]{8}-[0-9,a-z]{4}-[0-9,a-z]{4}-[0-9,a-z]{4}-[0-9,a-z]{12}")"
  unifi_data_size="$("${mongocommand}" --quiet --port 27117 ace --eval "var stats = db.stats(); print(Math.floor(stats.dataSize / (1024 * 1024 * 1024)))" 2> /dev/null)"
  while read -r unifi_package; do
    echo -e "${GRAY_R}#${RESET} Stopping service ${unifi_package}..."
    if systemctl stop "${unifi_package}" &>> "${eus_dir}/logs/mongodb_upgrade_${mongodb_upgrade_from_version::2}_to_${mongo_version_max}_systemctl.log"; then echo -e "${GREEN}#${RESET} Successfully stopped service ${unifi_package}! \\n"; else abort_reason="Failed to stop service ${unifi_package}."; abort; fi
  done < /tmp/EUS/mongodb/unifi_package_list
  # DB Dumping
  if [[ "${mongodb_upgrade_without_export_import}" != 'true' ]]; then
    start_unifi_database_task="export"
    start_unifi_database
    echo -e "${GRAY_R}#${RESET} Exporting the UniFi Network Application database to \"${unifi_db_eus_dir}/unifi_db/unifi-database-${mongodb_upgrade_date}\"..."
    echo -e "\\n------- Dumping MongoDB in the ${mongodb_upgrade_from_version_with_dots} to ${mongo_version_max_with_dot} Upgrade Process ------- $(date +%F-%T.%6N) -------\\n" &>> "${eus_dir}/logs/unifi-database-dump.log"
    eus_create_directories "unifi_db"
    # shellcheck disable=SC2086
    if mongodump --port 27117 ${gzip_mongodb_option} ${numparallelcollections_mongodb_option} --out "${unifi_db_eus_dir}/unifi_db/unifi-database-${mongodb_upgrade_date}" &>> "${eus_dir}/logs/unifi-database-dump.log"; then
      echo -e "${GREEN}#${RESET} Successfully exported the UniFi Network Application database to \"${unifi_db_eus_dir}/unifi_db/unifi-database-${mongodb_upgrade_date}\"! \\n"
      shutdown_mongodb
    else
      dump_attempts="0"
      while [[ "${dump_attempts}" -le '3' ]]; do
        header_red
        echo -e "${RED}#${RESET} Failed to export the UniFi Network Application database... \\n"
        if [[ "${dump_attempts}" == '0' ]]; then
          attempt_message="second"
          short_attempt_message="2nd"
        elif [[ "${dump_attempts}" == '1' ]]; then
          attempt_message="third"
          short_attempt_message="3rd"
        elif [[ "${dump_attempts}" == '2' ]]; then
          attempt_message="fourth"
          short_attempt_message="4th"
        elif [[ "${dump_attempts}" == '3' ]]; then
          attempt_message="fifth"
          short_attempt_message="5th"
        fi
        mongo_wait_initilize="0"
        until "${mongocommand}" --port 27117 --eval "print(\"waited for connection\")" &>> "${eus_dir}/logs/mongodb-initialize-waiting.log"; do
          ((mongo_wait_initilize=mongo_wait_initilize+1))
          echo -ne "\\r${YELLOW}#${RESET} Waiting for MongoDB to initialize before starting the ${attempt_message} attempt... ${mongo_wait_initilize}/5"
          sleep 60
          if [[ "${mongo_wait_initilize}" -ge '5' ]]; then echo -e "${RED}#${RESET} MongoDB did not respond within the set time frame... Please reach out to Glenn R. \\n"; if [[ "${dump_attempts}" -ge '3' ]]; then abort_reason="MongoDB did not respond within the set time frame, and the variable dump_attempts is greater than 3 (${dump_attempts})"; abort_function_skip_reason="true"; abort; else echo ""; break; fi; fi
        done
        if [[ "${dump_attempts}" -ge '1' && "${repair_unifi_database_attempted}" != 'true' ]]; then repair_unifi_database; repair_unifi_database_attempted='true'; fi
        if [[ "${dump_attempts}" -ge '2' && "${migrate_unifi_database_without_stats_attempted}" != 'true' ]]; then
          migrate_unifi_database_without_stats_attempted='true'
          while true; do
            read -rp $'\033[39m#\033[0m Do you want to attempt to upgrade with only your Network Application Settings (all statistics data will be removed)? (y/N) ' yes_no
            case "$yes_no" in
               [Nn]*|"")
                  echo -e "${YELLOW}#${RESET} Alrighty... Proceeding with the regular attempt...\\n"
                  sleep 2
                  break;;
               [Yy]*)
                  echo -e "${YELLOW}#${RESET} Cool, attempting the migration without your Network Application statistics...\\n"
                  migrate_unifi_database_without_stats="true"
                  migrate_unifi_database_without_stats_message_1=", without statistics"
                  break;;
               *) echo -e "\\n${RED}#${RESET} Invalid input, please answer Yes or No (y/n)...\\n"; sleep 3;;
            esac
          done
        fi
        echo -e "${GRAY_R}#${RESET} Trying to export the UniFi Network Application database to \"${unifi_db_eus_dir}/unifi_db/unifi-database-${mongodb_upgrade_date}\" for the ${attempt_message} time..."
        echo -e "\\n------- Dumping MongoDB in the ${mongodb_upgrade_from_version_with_dots} to ${mongo_version_max_with_dot} Upgrade Process (${short_attempt_message} run${migrate_unifi_database_without_stats_message_1}) ------- $(date +%F-%T.%6N) -------\\n" &>> "${eus_dir}/logs/unifi-database-dump.log"
        sleep 2
        # shellcheck disable=SC2086
        if [[ "${migrate_unifi_database_without_stats}" == 'true' ]]; then
          while read -r migrate_unifi_database_without_stats_database; do
            if [[ "${migrate_unifi_database_without_stats_database}" == 'ace_stat' ]]; then continue; fi
            if mongodump --port 27117 ${gzip_mongodb_option} ${numparallelcollections_mongodb_option} --db "${migrate_unifi_database_without_stats_database}" --out "${unifi_db_eus_dir}/unifi_db/unifi-database-${mongodb_upgrade_date}" &>> "${eus_dir}/logs/unifi-database-dump.log"; then
              echo -e "${GREEN}#${RESET} Successfully exported database ${migrate_unifi_database_without_stats_database} from the UniFi Network Application database to \"${unifi_db_eus_dir}/unifi_db/unifi-database-${mongodb_upgrade_date}\" in the ${attempt_message} run! \\n"
            else
              echo -e "${RED}#${RESET} Failed to export database ${migrate_unifi_database_without_stats_database} from the UniFi Network Application database in the ${attempt_message} run... \\n"
              migrate_unifi_database_without_stats_failure="true"
            fi
            sleep 2
          done < <("${mongocommand}" --quiet --port 27117 ace --eval "${mongoprefix}db.adminCommand('listDatabases'))" | jq -r '.databases[].name')
          if [[ "${migrate_unifi_database_without_stats_failure}" != 'true' ]]; then
            shutdown_mongodb
            break
          fi
        else
          if mongodump --port 27117 ${gzip_mongodb_option} ${numparallelcollections_mongodb_option} --out "${unifi_db_eus_dir}/unifi_db/unifi-database-${mongodb_upgrade_date}" &>> "${eus_dir}/logs/unifi-database-dump.log"; then
            echo -e "${GREEN}#${RESET} Successfully exported the UniFi Network Application database to \"${unifi_db_eus_dir}/unifi_db/unifi-database-${mongodb_upgrade_date}\" in the ${attempt_message} run! \\n"
            shutdown_mongodb
            break
          else
            echo -e "${RED}#${RESET} Failed to export the UniFi Network Application database in the ${attempt_message} run... \\n"
            sleep 5
          fi
        fi
        if [[ "${dump_attempts}" -ge '3' ]]; then shutdown_mongodb; abort_reason="Failed to export the MongoDB, and variable dump_attempts is great than 3 (${dump_attempts})"; abort_function_skip_reason="true"; abort; fi
        ((dump_attempts=dump_attempts+1))
      done
    fi
  fi
  # Moving old DB to different place
  if [[ "${mongodb_upgrade_without_export_import}" != 'true' ]]; then
    echo -e "${GRAY_R}#${RESET} Moving \"${unifi_database_location}/\" to \"${unifi_db_eus_dir}/unifi_db/db-backup-${mongodb_upgrade_date}\"..."
    if mv "${unifi_database_location}/" "${unifi_db_eus_dir}/unifi_db/db-backup-${mongodb_upgrade_date}" &>> "${eus_dir}/logs/unifi-database-move.log"; then
      echo -e "${GREEN}#${RESET} Successfully moved \"${unifi_database_location}/\" to \"${unifi_db_eus_dir}/unifi_db/db-backup-${mongodb_upgrade_date}\"! \\n"
      unifi_database_move_sucess="true"
    else
      echo -e "${RED}#${RESET} Failed to move \"${unifi_database_location}/\" to \"${unifi_db_eus_dir}/unifi_db/db-backup-${mongodb_upgrade_date}\"..."; abort_reason="Failed to move ${unifi_database_location} to ${unifi_db_eus_dir}/unifi_db/db-backup-${mongodb_upgrade_date}."; abort_function_skip_reason="true"; abort
    fi
  fi
  # Selecting MongoDB Packages to install/upgrade/purge
  if [[ -s "/tmp/EUS/mongodb/purge_packages_list" ]]; then rm --force /tmp/EUS/mongodb/purge_packages_list &> /dev/null; fi
  "$(which dpkg)" -l | grep "mongodb-org\\|mongodb-server\\|mongodb-clients\\|mongo-tools\\|mongodb-mongosh\\|mongosh\\|mongodb-10gen\\|mongod-armv8\\|mongod-amd64" | grep "^ii\\|^hi\\|^ri\\|^pi\\|^ui\\|^iU" | awk '{print $2}' &> /tmp/EUS/mongodb/packages_list
  cp /tmp/EUS/mongodb/packages_list /tmp/EUS/mongodb/original_packages_list &> /dev/null
  if grep -siq "mongodb-org$" /tmp/EUS/mongodb/packages_list; then sed -i '/mongodb-org$/d' /tmp/EUS/mongodb/packages_list; echo "mongodb-org" &>> /tmp/EUS/mongodb/purge_packages_list; fi
  if grep -siq "mongodb-server-core" /tmp/EUS/mongodb/packages_list; then sed -i 's/mongodb-server-core$/mongodb-org-server/g' /tmp/EUS/mongodb/packages_list; echo "mongodb-server-core" &>> /tmp/EUS/mongodb/purge_packages_list; fi
  if grep -siq "mongodb-server" /tmp/EUS/mongodb/packages_list; then if ! grep -siq "mongodb-org-server" /tmp/EUS/mongodb/packages_list; then sed -i 's/mongodb-server/mongodb-org-server/g' /tmp/EUS/mongodb/packages_list; else sed -i '/mongodb-server/d' /tmp/EUS/mongodb/packages_list; fi; echo "mongodb-server" &>> /tmp/EUS/mongodb/purge_packages_list; fi
  if grep -siq "mongodb-clients" /tmp/EUS/mongodb/packages_list; then sed -i 's/mongodb-clients$/mongodb-org-shell/g' /tmp/EUS/mongodb/packages_list; echo "mongodb-clients" &>> /tmp/EUS/mongodb/purge_packages_list; fi
  if grep -siq "mongo-tools" /tmp/EUS/mongodb/packages_list; then sed -i 's/mongo-tools$/mongodb-org-tools/g' /tmp/EUS/mongodb/packages_list; echo "mongo-tools" &>> /tmp/EUS/mongodb/purge_packages_list; fi
  if grep -siq "mongodb-10gen" /tmp/EUS/mongodb/packages_list; then sed -i 's/mongodb-10gen$/mongodb-org-server/g' /tmp/EUS/mongodb/packages_list; echo "mongodb-10gen" &>> /tmp/EUS/mongodb/purge_packages_list; fi
  if grep -siq "mongodb-mongosh$" /tmp/EUS/mongodb/packages_list; then echo "mongodb-mongosh" &>> /tmp/EUS/mongodb/purge_packages_list; fi
  if grep -siq "^mongosh$" /tmp/EUS/mongodb/packages_list; then echo "mongosh" &>> /tmp/EUS/mongodb/purge_packages_list; fi
  if ! grep -siq "mongodb-org-tools" /tmp/EUS/mongodb/packages_list; then echo "mongodb-org-tools" &>> /tmp/EUS/mongodb/packages_list; fi
  if ! grep -siq "mongodb-org-shell" /tmp/EUS/mongodb/packages_list; then echo "mongodb-org-shell" &>> /tmp/EUS/mongodb/packages_list; fi
  cp /tmp/EUS/mongodb/packages_list /tmp/EUS/mongodb/packages_list.tmp &> /dev/null
  while read -r installed_mongodb_package; do
    if ! apt-cache policy "^${installed_mongodb_package}$" | grep -ioq "${install_mongodb_version}"; then
      echo "${installed_mongodb_package}" &>> /tmp/EUS/mongodb/purge_packages_list
      sed -i "/^${installed_mongodb_package}$/d" /tmp/EUS/mongodb/packages_list
    fi
  done < "/tmp/EUS/mongodb/packages_list.tmp"
  rm --force "/tmp/EUS/mongodb/packages_list.tmp" &> /dev/null
  if [[ "${glennr_compiled_mongod}" == 'true' ]]; then
    cp /tmp/EUS/mongodb/packages_list /tmp/EUS/mongodb/before_glennr_compiled_mongod_packages_list &> /dev/null
    if grep -siq "mongodb-org-server" /tmp/EUS/mongodb/packages_list; then sed -i "s/mongodb-org-server/${gr_mongod_name}/g" /tmp/EUS/mongodb/packages_list; echo "mongodb-org-server" &>> /tmp/EUS/mongodb/purge_packages_list; else echo "${gr_mongod_name}" &>> /tmp/EUS/mongodb/packages_list; fi
  else
    if grep -siq "${gr_mongod_name}" /tmp/EUS/mongodb/packages_list; then sed -i "s/${gr_mongod_name}/mongodb-org-server/g" /tmp/EUS/mongodb/packages_list; echo "${gr_mongod_name}" &>> /tmp/EUS/mongodb/purge_packages_list; else echo "mongodb-org-server" &>> /tmp/EUS/mongodb/packages_list; fi
  fi
  check_dpkg_lock
  if [[ -e "/tmp/EUS/mongodb/unhold" ]]; then rm --force "/tmp/EUS/mongodb/unhold"; fi
  while read -r mongodb_package; do
    if apt-mark unhold "${mongodb_package}" &>> "${eus_dir}/logs/package-unhold.log"; then unhold_packages="true"; echo "${mongodb_package}" &>> /tmp/EUS/mongodb/unhold; fi
  done < <(dpkg --get-selections | grep hold | grep -i "mongo" | awk '{print $1}')
  # re-order mongodb-server and mongodb-server-core.
  awk '{ if ($0 == "mongodb-server") { server_found = 1; } else if ($0 == "mongodb-server-core") { core_found = 1; } if (!found_both) { original[NR] = $0; } } END { if (server_found && core_found) { found_both = 1; printed_server = 0; printed_core = 0; for (i = 1; i <= NR; i++) { if (original[i] == "mongodb-server" && !printed_server) { printed_server = 1; continue; } else if (original[i] == "mongodb-server-core" && !printed_core) { printed_core = 1; print "mongodb-server"; } print original[i]; } } else { for (i = 1; i <= NR; i++) { print original[i]; } } }' /tmp/EUS/mongodb/purge_packages_list &> /tmp/EUS/mongodb/purge_packages_list.tmp && mv /tmp/EUS/mongodb/purge_packages_list.tmp /tmp/EUS/mongodb/purge_packages_list
  #
  if [[ -s "/tmp/EUS/mongodb/purge_packages_list" ]]; then
    mongodb_upgrade_mongodb_org_message="Installing"
    mongodb_upgrade_mongodb_org_message_2="installed"
    mongodb_upgrade_mongodb_org_message_3="install"
    first_digit_current_unifi="$(echo "${unifi}" | cut -d'.' -f1)"
    second_digit_current_unifi="$(echo "${unifi}" | cut -d'.' -f2)"
    third_digit_current_unifi="$(echo "${unifi}" | cut -d'.' -f3)"
    echo -e "${GRAY_R}#${RESET} Locating a download URL for UniFi Network Application version ${first_digit_current_unifi}.${second_digit_current_unifi}.${third_digit_current_unifi}..."
    if [[ -n "${token}" ]]; then
	  unifi_deb_dl="$(curl "${curl_argument[@]}" --location --request GET "https://fw-update.ui.com/api/firmware-latest?filter=eq~~version_major~~${first_digit_current_unifi}&filter=eq~~version_minor~~${second_digit_current_unifi}&filter=eq~~version_patch~~${third_digit_current_unifi}&filter=eq~~platform~~debian" --header 'Authorization: Bearer token:'"${token}"'' 2> "${eus_dir}/logs/locate-download.log" | jq -r "._embedded.firmware[0]._links.data.href" 2> "${eus_dir}/logs/locate-download.log" | sed '/null/d' 2> "${eus_dir}/logs/locate-download.log")"
      if [[ -z "${unifi_deb_dl}" ]]; then unifi_deb_dl="$(curl "${curl_argument[@]}" --location --request GET "http://fw-update.ui.com/api/firmware-latest?filter=eq~~version_major~~${first_digit_current_unifi}&filter=eq~~version_minor~~${second_digit_current_unifi}&filter=eq~~version_patch~~${third_digit_current_unifi}&filter=eq~~platform~~debian" --header 'Authorization: Bearer token:'"${token}"'' 2> "${eus_dir}/logs/locate-download.log" | jq -r "._embedded.firmware[0]._links.data.href" 2> "${eus_dir}/logs/locate-download.log" | sed '/null/d' 2> "${eus_dir}/logs/locate-download.log")"; fi
	  unifi_deb_md5="$(curl "${curl_argument[@]}" --location --request GET "https://fw-update.ui.com/api/firmware-latest?filter=eq~~version_major~~${first_digit_current_unifi}&filter=eq~~version_minor~~${second_digit_current_unifi}&filter=eq~~version_patch~~${third_digit_current_unifi}&filter=eq~~platform~~debian" --header 'Authorization: Bearer token:'"${token}"'' 2> "${eus_dir}/logs/locate-download.log" | jq -r "._embedded.firmware[0].md5" 2> "${eus_dir}/logs/locate-download.log" | sed '/null/d' 2> "${eus_dir}/logs/locate-download.log")"
	  if [[ -z "${unifi_deb_md5}" ]]; then unifi_deb_md5="$(curl "${curl_argument[@]}" --location --request GET "http://fw-update.ui.com/api/firmware-latest?filter=eq~~version_major~~${first_digit_current_unifi}&filter=eq~~version_minor~~${second_digit_current_unifi}&filter=eq~~version_patch~~${third_digit_current_unifi}&filter=eq~~platform~~debian" --header 'Authorization: Bearer token:'"${token}"'' 2> "${eus_dir}/logs/locate-download.log" | jq -r "._embedded.firmware[0].md5" 2> "${eus_dir}/logs/locate-download.log" | sed '/null/d' 2> "${eus_dir}/logs/locate-download.log")"; fi
    else
      unifi_deb_dl="$(curl "${curl_argument[@]}" --location --request GET "https://fw-update.ui.com/api/firmware-latest?filter=eq~~version_major~~${first_digit_current_unifi}&filter=eq~~version_minor~~${second_digit_current_unifi}&filter=eq~~version_patch~~${third_digit_current_unifi}&filter=eq~~platform~~debian" 2> "${eus_dir}/logs/locate-download.log" | jq -r "._embedded.firmware[0]._links.data.href" 2> "${eus_dir}/logs/locate-download.log" | sed '/null/d' 2> "${eus_dir}/logs/locate-download.log")"
      if [[ -z "${unifi_deb_dl}" ]]; then unifi_deb_dl="$(curl "${curl_argument[@]}" --location --request GET "http://fw-update.ui.com/api/firmware-latest?filter=eq~~version_major~~${first_digit_current_unifi}&filter=eq~~version_minor~~${second_digit_current_unifi}&filter=eq~~version_patch~~${third_digit_current_unifi}&filter=eq~~platform~~debian" 2> "${eus_dir}/logs/locate-download.log" | jq -r "._embedded.firmware[0]._links.data.href" 2> "${eus_dir}/logs/locate-download.log" | sed '/null/d' 2> "${eus_dir}/logs/locate-download.log")"; fi
      unifi_deb_md5="$(curl "${curl_argument[@]}" --location --request GET "https://fw-update.ui.com/api/firmware-latest?filter=eq~~version_major~~${first_digit_current_unifi}&filter=eq~~version_minor~~${second_digit_current_unifi}&filter=eq~~version_patch~~${third_digit_current_unifi}&filter=eq~~platform~~debian" 2> "${eus_dir}/logs/locate-download.log" | jq -r "._embedded.firmware[0].md5" 2> "${eus_dir}/logs/locate-download.log" | sed '/null/d' 2> "${eus_dir}/logs/locate-download.log")"
      if [[ -z "${unifi_deb_md5}" ]]; then unifi_deb_md5="$(curl "${curl_argument[@]}" --location --request GET "http://fw-update.ui.com/api/firmware-latest?filter=eq~~version_major~~${first_digit_current_unifi}&filter=eq~~version_minor~~${second_digit_current_unifi}&filter=eq~~version_patch~~${third_digit_current_unifi}&filter=eq~~platform~~debian" 2> "${eus_dir}/logs/locate-download.log" | jq -r "._embedded.firmware[0].md5" 2> "${eus_dir}/logs/locate-download.log" | sed '/null/d' 2> "${eus_dir}/logs/locate-download.log")"; fi
    fi
    if [[ "$(curl "${curl_argument[@]}" https://api.glennr.nl/api/network-release?status 2> /dev/null | jq -r '.[]' 2> /dev/null)" == "OK" ]]; then
      if [[ -z "${unifi_deb_dl}" ]]; then
        unifi_deb_dl="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/network-release?version=${first_digit_current_unifi}.${second_digit_current_unifi}.${third_digit_current_unifi}${unifi_core_glennr_api}" | jq -r '.download_link' | sed '/null/d' 2> "${eus_dir}/logs/locate-download.log")"
        unifi_deb_md5="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/network-release?version=${first_digit_current_unifi}.${second_digit_current_unifi}.${third_digit_current_unifi}${unifi_core_glennr_api}" | jq -r '.md5sum' | sed '/null/d' 2> "${eus_dir}/logs/locate-download.log")"
      fi
      unifi_deb_gr_dl="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/network-release?version=${first_digit_current_unifi}.${second_digit_current_unifi}.${third_digit_current_unifi}&server=archive${unifi_core_glennr_api}" | jq -r '.download_link' | sed '/null/d' 2> "${eus_dir}/logs/locate-download.log")"
    fi
    if [[ -z "${unifi_deb_dl}" ]]; then
      unifi_deb_dl_failed="true"
      echo -e "${RED}#${RESET} Failed to locate a download URL for UniFi Network Application version ${first_digit_current_unifi}.${second_digit_current_unifi}.${third_digit_current_unifi}... \\n"
      while true; do
        read -rp $'\033[39m#\033[0m Would you like to provide a link to download UniFi Network Application version '"${first_digit_current_unifi}"'.'"${second_digit_current_unifi}"'.'"${third_digit_current_unifi}"'? (Y/n) ' yes_no
        case "$yes_no" in
           [Nn]*)
              abort_reason="Failed to locate a download URL for UniFi Network Application version ${first_digit_current_unifi}.${second_digit_current_unifi}.${third_digit_current_unifi}."; abort_function_skip_reason="true"; abort
              break;;
           [Yy]*|"")
              custom_url_question
              if [[ -n "${unifi_deb_dl}" ]]; then echo -e "${GREEN}#${RESET} Awesome! We can download UniFi Network Application version ${first_digit_current_unifi}.${second_digit_current_unifi}.${third_digit_current_unifi} from the URL you specified! \\n"; fi
              break;;
           *) echo -e "\\n${RED}#${RESET} Invalid input, please answer Yes or No (y/n)...\\n"; sleep 3;;
        esac
      done
    else
      echo -e "${GREEN}#${RESET} Successfully located a download URL for UniFi Network Application version ${first_digit_current_unifi}.${second_digit_current_unifi}.${third_digit_current_unifi}! \\n"
    fi
    echo -e "${GRAY_R}#${RESET} Downloading UniFi Network Application version ${first_digit_current_unifi}.${second_digit_current_unifi}.${third_digit_current_unifi}..."
    if [[ -n "${unifi_deb_gr_dl}" ]]; then unifi_deb_dl_urls=("${unifi_deb_dl}" "${unifi_deb_gr_dl}"); else unifi_deb_dl_urls=("${unifi_deb_dl}"); fi
    for unifi_deb_dl in "${unifi_deb_dl_urls[@]}"; do
      eus_tmp_deb_name="unifi_mongodb_upgrade_${mongodb_upgrade_from_version::2}_to_${mongo_version_max}"
      eus_tmp_deb_var="unifi_temp"
      eus_tmp_directory_check
      echo -e "$(date +%F-%T.%6N) | Downloading ${unifi_deb_dl} to ${unifi_temp}" &>> "${eus_dir}/logs/unifi_mongodb_upgrade_${mongodb_upgrade_from_version::2}_to_${mongo_version_max}_download.log"
      if curl "${nos_curl_argument[@]}" --output "$unifi_temp" "${unifi_deb_dl}" &>> "${eus_dir}/logs/unifi_mongodb_upgrade_${mongodb_upgrade_from_version::2}_to_${mongo_version_max}_download.log"; then
        if [[ "$(md5sum "${unifi_temp}" | awk '{print $1}')" == "${unifi_deb_md5}" ]]; then
          echo -e "${GREEN}#${RESET} Successfully downloaded UniFi Network Application version ${first_digit_current_unifi}.${second_digit_current_unifi}.${third_digit_current_unifi}! \\n"; unifi_downloaded="true"; break
        else
          continue
        fi
      fi
    done
    if [[ "${unifi_downloaded}" == "true" ]]; then
      unset unifi_downloaded
      check_dpkg_lock
      echo -e "${GRAY_R}#${RESET} Removing the UniFi Network Application..."
      if DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' remove unifi &>> "${eus_dir}/logs/mongodb_upgrade_${mongodb_upgrade_from_version::2}_to_${mongo_version_max}.log"; then
        echo -e "${GREEN}#${RESET} Successfully removed the UniFi Network Application! \\n"
        mongodb_upgrade_unifi_remove="true"
      else
        if "$(which dpkg)" --remove --force-remove-reinstreq unifi &>> "${eus_dir}/logs/mongodb_upgrade_${mongodb_upgrade_from_version::2}_to_${mongo_version_max}.log"; then
          echo -e "${GREEN}#${RESET} Successfully removed the UniFi Network Application! \\n"
          mongodb_upgrade_unifi_remove="true"
        else
          abort_reason="Failed to remove the UniFi Network Application."
          abort
        fi
      fi
    else
      abort_reason="Failed to download UniFi Network Application version ${first_digit_current_unifi}.${second_digit_current_unifi}.${third_digit_current_unifi}."
      abort
    fi
    while read -r mongodb_package_to_upgrade; do
      check_dpkg_lock
      echo -e "${GRAY_R}#${RESET} Purging package ${mongodb_package_to_upgrade}..."
      if DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' purge "${mongodb_package_to_upgrade}" &>> "${eus_dir}/logs/mongodb_upgrade_${mongodb_upgrade_from_version::2}_to_${mongo_version_max}.log"; then
        echo -e "${GREEN}#${RESET} Successfully purged ${mongodb_package_to_upgrade}! \\n"
        if [[ "${glennr_compiled_mongod}" == 'true' && "${mongodb_package_to_upgrade}" == 'mongodb-org-server' ]]; then glennr_compiled_mongod_purged_server="true"; glennr_compiled_mongod_purged_server_import="true"; fi
      else
        echo -e "${RED}#${RESET} Failed to purge ${mongodb_package_to_upgrade}... \\n"
        if [[ -e "/var/lib/dpkg/info/${mongodb_package_to_upgrade}.prerm" ]]; then eus_create_directories "dpkg"; mv "/var/lib/dpkg/info/${mongodb_package_to_upgrade}.prerm" "${eus_dir}/dpkg/${mongodb_package_to_upgrade}.prerm-${mongodb_upgrade_date}"; fi
        check_dpkg_lock
        echo -e "${GRAY_R}#${RESET} Trying another method to get rid of ${mongodb_package_to_upgrade}..."
        if DEBIAN_FRONTEND='noninteractive' "$(which dpkg)" --remove --force-remove-reinstreq "${mongodb_package_to_upgrade}" &>> "${eus_dir}/logs/mongodb_upgrade_${mongodb_upgrade_from_version::2}_to_${mongo_version_max}.log"; then
          echo -e "${GREEN}#${RESET} Successfully removed ${mongodb_package_to_upgrade}! \\n"
          mongodb_upgrade_unifi_remove="true"
        else
          echo -e "${RED}#${RESET} Failed to force remove ${mongodb_package_to_upgrade}...\\n"
          abort_function_skip_reason="true"; abort_reason="Failed to purge ${mongodb_package_to_upgrade}."; abort
        fi
      fi
    done < /tmp/EUS/mongodb/purge_packages_list
  fi
  # Purge MongoDB packages if needed
  if "$(which dpkg)" -l mongodb-org 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then echo "mongodb-org" &>> /tmp/EUS/mongodb/purge_packages_list_2; fi
  if [[ "${mongodb_upgrade_without_export_import}" == 'true' ]]; then if "$(which dpkg)" -l mongodb-org-tools 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then echo "mongodb-org-tools" &>> /tmp/EUS/mongodb/purge_packages_list_2; fi; fi
  if [[ -s "/tmp/EUS/mongodb/purge_packages_list_2" ]]; then
    while read -r mongodb_package_to_upgrade; do
      check_dpkg_lock
      echo -e "${GRAY_R}#${RESET} Purging package ${mongodb_package_to_upgrade}..."
      if DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' purge "${mongodb_package_to_upgrade}" &>> "${eus_dir}/logs/mongodb_upgrade_${mongodb_upgrade_from_version::2}_to_${mongo_version_max}.log"; then
        echo -e "${GREEN}#${RESET} Successfully purged ${mongodb_package_to_upgrade}! \\n"
      else
        echo -e "${RED}#${RESET} Failed to purge ${mongodb_package_to_upgrade}...\\n"
        if [[ -e "/var/lib/dpkg/info/${mongodb_package_to_upgrade}.prerm" ]]; then eus_create_directories "dpkg"; mv "/var/lib/dpkg/info/${mongodb_package_to_upgrade}.prerm" "${eus_dir}/dpkg/${mongodb_package_to_upgrade}.prerm-${mongodb_upgrade_date}"; fi
        check_dpkg_lock
        echo -e "${GRAY_R}#${RESET} Trying another method to get rid of ${mongodb_package_to_upgrade}..."
        if DEBIAN_FRONTEND='noninteractive' "$(which dpkg)" --remove --force-remove-reinstreq "${mongodb_package_to_upgrade}" &>> "${eus_dir}/logs/mongodb_upgrade_${mongodb_upgrade_from_version::2}_to_${mongo_version_max}.log"; then
          echo -e "${GREEN}#${RESET} Successfully removed ${mongodb_package_to_upgrade}! \\n"
          mongodb_upgrade_unifi_remove="true"
        else
          echo -e "${RED}#${RESET} Failed to force remove ${mongodb_package_to_upgrade}...\\n"
          abort_function_skip_reason="true"; abort_reason="Failed to purge ${mongodb_package_to_upgrade}."; abort
        fi
      fi
    done < /tmp/EUS/mongodb/purge_packages_list_2
  fi
  # Remove old MongoDB Packages cache
  while read -r apt_cache; do
    if [[ "${apt_cache_archive_message}" != 'true' ]]; then echo -e "${GRAY_R}#${RESET} Removing apt cache archives..."; apt_cache_archive_message="true"; fi
    if rm --force "${apt_cache}" &> /dev/null; then if [[ "${apt_cache_archive_success_message}" != 'true' ]]; then echo -e "${GREEN}#${RESET} Successfully removed apt cache archives! \\n"; apt_cache_archive_success_message="true"; fi; fi
  done < <(find /var/cache/apt/archives/ -name "*mongo*" -type f)
  check_unmet_dependencies
  # Install Glenn R. mongod dependencies
  if grep -siq "${gr_mongod_name}" /tmp/EUS/mongodb/packages_list; then
    check_default_repositories
    if [[ "$(find /etc/apt/ -type f \( -name "*.sources" -o -name "*.list" \) -exec grep -lE 'raspbian.|raspberrypi.' {} + | wc -l)" -ge "1" ]]; then
      if [[ "${os_codename}" =~ (wheezy|jessie|stretch|buster|bullseye) ]]; then
        repo_codename="bookworm"
        use_raspberrypi_repo="true"
        get_repo_url
        repo_component="main"
        add_repositories
        run_apt_get_update
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
          run_apt_get_update
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
          run_apt_get_update
        fi
        glennr_mongod_dependency_install_version="$(apt-cache policy "${glennr_mongod_dependency}" | tr '[:upper:]' '[:lower:]' | sed '1,/version table/d' | sed -e 's/500//g' -e 's/100//g' -e '/http/d' -e '/var/d' -e 's/*//g' -e 's/ //g' | grep -i "^${glennr_mongod_dependency_version}" | head -n1)"
        if [[ -z "${glennr_mongod_dependency_install_version}" ]]; then
          echo -e "${RED}#${RESET} Failed to locate required version for ${glennr_mongod_dependency}...\\n"
        fi
        check_dpkg_lock
        echo -e "${GRAY_R}#${RESET} Installing ${glennr_mongod_dependency}..."
        if ! DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "${glennr_mongod_dependency}"="${glennr_mongod_dependency_install_version}" &>> "${eus_dir}/logs/${gr_mongod_name}-dependencies.log"; then
          check_dpkg_lock
          if ! DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "${glennr_mongod_dependency}" &>> "${eus_dir}/logs/${gr_mongod_name}-dependencies.log"; then
            check_unmet_dependencies
            broken_packages_check
            attempt_recover_broken_packages
            add_apt_option_no_install_recommends="true"; get_apt_options
            check_dpkg_lock
            if ! DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "${glennr_mongod_dependency}" &>> "${eus_dir}/logs/${gr_mongod_name}-dependencies.log"; then
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
  fi
  # Install/Upgrade MongoDB
  while read -r mongodb_package; do
    echo -e "${GRAY_R}#${RESET} ${mongodb_upgrade_mongodb_org_message} ${mongodb_package}..."
    if [[ "${mongodb_package}" == "${gr_mongod_name}" ]]; then install_mongodb_version_with_equality_sign_tmp="${install_mongodb_version_with_equality_sign}"; install_mongodb_version_with_equality_sign="${install_mongod_version_with_equality_sign}"; elif [[ -n "${install_mongodb_version_with_equality_sign_tmp}" ]]; then install_mongodb_version_with_equality_sign="${install_mongodb_version_with_equality_sign_tmp}"; fi
    mongodb_package_libssl="${mongodb_package}"
    mongodb_package_version_libssl="${install_mongodb_version}"
    libssl_installation_check
    check_dpkg_lock
    if DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_downgrade_option[@]}" "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "${mongodb_package}${install_mongodb_version_with_equality_sign}" &>> "${eus_dir}/logs/mongodb_upgrade_${mongodb_upgrade_from_version::2}_to_${mongo_version_max}.log"; then
      echo -e "${GREEN}#${RESET} Successfully ${mongodb_upgrade_mongodb_org_message_2} ${mongodb_package}! \\n"
    else
      if tail -n20 "${eus_dir}/logs/mongodb_upgrade_${mongodb_upgrade_from_version::2}_to_${mongo_version_max}.log" | grep -iq "uses unknown compression for member .*zst"; then
        echo -e "${RED}#${RESET} Failed to ${mongodb_upgrade_mongodb_org_message_3} ${mongodb_package}...\\n"
        repackage_deb_name="${mongodb_package}"
        repackage_deb_version="${install_mongodb_version_with_equality_sign}"
        repackage_deb_file
        check_dpkg_lock
        echo -e "${GRAY_R}#${RESET} ${mongodb_upgrade_mongodb_org_message} ${mongodb_package}..."
        if DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_downgrade_option[@]}" "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "${repackage_deb_file_location}" &>> "${eus_dir}/logs/mongodb_upgrade_${mongodb_upgrade_from_version::2}_to_${mongo_version_max}.log"; then
          echo -e "${GREEN}#${RESET} Successfully ${mongodb_upgrade_mongodb_org_message_2} ${mongodb_package}! \\n"
        else
          abort_reason="Failed to ${mongodb_upgrade_mongodb_org_message_3} ${mongodb_package}."
          mongodb_upgrade_pre_import_failure="true"; abort
        fi
      elif tail -n20 "${eus_dir}/logs/mongodb_upgrade_${mongodb_upgrade_from_version::2}_to_${mongo_version_max}.log" | grep -iq "pre-removal script"; then
        echo -e "${RED}#${RESET} Failed to ${mongodb_upgrade_mongodb_org_message_3} ${mongodb_package}...\\n"
        if [[ -e "/var/lib/dpkg/info/${mongodb_package}.prerm" ]]; then eus_create_directories "dpkg"; mv "/var/lib/dpkg/info/${mongodb_package}.prerm" "${eus_dir}/dpkg/${mongodb_package}.prerm-${mongodb_upgrade_date}"; fi
        check_dpkg_lock
        echo -e "${GRAY_R}#${RESET} ${mongodb_upgrade_mongodb_org_message} ${mongodb_package}..."
        if DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_downgrade_option[@]}" "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "${mongodb_package}${install_mongodb_version_with_equality_sign}" &>> "${eus_dir}/logs/mongodb_upgrade_${mongodb_upgrade_from_version::2}_to_${mongo_version_max}.log"; then
          echo -e "${GREEN}#${RESET} Successfully ${mongodb_upgrade_mongodb_org_message_2} ${mongodb_package}! \\n"
        else
          abort_reason="Failed to ${mongodb_upgrade_mongodb_org_message_3} ${mongodb_package}."
          mongodb_upgrade_pre_import_failure="true"; abort
        fi
      else
        check_unmet_dependencies
        broken_packages_check
        attempt_recover_broken_packages
        add_apt_option_no_install_recommends="true"; get_apt_options
        check_dpkg_lock
        if DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_downgrade_option[@]}" "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "${mongodb_package}${install_mongodb_version_with_equality_sign}" &>> "${eus_dir}/logs/mongodb_upgrade_${mongodb_upgrade_from_version::2}_to_${mongo_version_max}.log"; then
          echo -e "${GREEN}#${RESET} Successfully ${mongodb_upgrade_mongodb_org_message_2} ${mongodb_package}! \\n"
        else
          abort_reason="Failed to ${mongodb_upgrade_mongodb_org_message_3} ${mongodb_package}."
          mongodb_upgrade_pre_import_failure="true"; abort
        fi
        get_apt_options
      fi
    fi
    if [[ "${mongo_version_locked}" == "4.4.18" ]]; then
      check_dpkg_lock
      echo -e "${GRAY_R}#${RESET} Preventing ${mongodb_package} from upgrading..."
      if echo "${mongodb_package} hold" | "$(which dpkg)" --set-selections &>> "${eus_dir}/logs/package-hold.log"; then
        echo -e "${GREEN}#${RESET} Successfully prevented ${mongodb_package} from upgrading! \\n"
      else
        echo -e "${RED}#${RESET} Failed to prevent ${mongodb_package} from upgrading...\\n"
      fi
    fi
  done < /tmp/EUS/mongodb/packages_list
  if "$(which dpkg)" -l | grep "^ii\\|^hi\\|^ri\\|^pi\\|^ui\\|^iU" | grep -iq "${gr_mongod_name}"; then prevent_mongodb_org_server_install; fi
  if [[ "${mongo_version_max}" -ge '70' ]]; then
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
      check_dpkg_lock
      echo -e "${GRAY_R}#${RESET} Installing ${mongodb_mongosh_install_package_name}..."
      if DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_downgrade_option[@]}" "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "${mongodb_mongosh_install_package_name}" &>> "${eus_dir}/logs/mongodb_upgrade_${mongodb_upgrade_from_version::2}_to_${mongo_version_max}.log"; then
        echo -e "${GREEN}#${RESET} Successfully installed ${mongodb_mongosh_install_package_name}! \\n"
        if [[ "$(apt-cache policy "${mongodb_mongosh_libssl_version}" | tr '[:upper:]' '[:lower:]' | grep "installed:" | cut -d':' -f2 | sed 's/ //g')" != "$(apt-cache policy "${mongodb_mongosh_libssl_version}" | tr '[:upper:]' '[:lower:]' | grep "candidate:" | cut -d':' -f2 | sed 's/ //g')" ]]; then
          echo -e "${GRAY_R}#${RESET} Updating ${mongodb_mongosh_libssl_version}..."
          check_dpkg_lock
          if DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' --only-upgrade install "${mongodb_mongosh_libssl_version}" &>> "${eus_dir}/logs/libssl.log"; then
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
        if DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_downgrade_option[@]}" "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "${mongodb_mongosh_install_package_name}" &>> "${eus_dir}/logs/mongodb_upgrade_${mongodb_upgrade_from_version::2}_to_${mongo_version_max}.log"; then
          echo -e "${GREEN}#${RESET} Successfully installed ${mongodb_mongosh_install_package_name}! \\n"
          if [[ "$(apt-cache policy "${mongodb_mongosh_libssl_version}" | tr '[:upper:]' '[:lower:]' | grep "installed:" | cut -d':' -f2 | sed 's/ //g')" != "$(apt-cache policy "${mongodb_mongosh_libssl_version}" | tr '[:upper:]' '[:lower:]' | grep "candidate:" | cut -d':' -f2 | sed 's/ //g')" ]]; then
            echo -e "${GRAY_R}#${RESET} Updating ${mongodb_mongosh_libssl_version}..."
            check_dpkg_lock
            if DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' --only-upgrade install "${mongodb_mongosh_libssl_version}" &>> "${eus_dir}/logs/libssl.log"; then
              echo -e "${GREEN}#${RESET} Successfully updated ${mongodb_mongosh_libssl_version}! \\n"
            else
              echo -e "${RED}#${RESET} Failed to update ${mongodb_mongosh_libssl_version}...\\n"
            fi
          fi
          get_apt_options
        else
          abort_reason="Failed to install ${mongodb_mongosh_install_package_name}."
          unifi_database_move_sucess="true"; mongodb_upgrade_pre_import_failure="true"
          abort
        fi
      fi
    fi
  fi
  unset unifi_database_move_sucess
  if ! [[ -d "${unifi_database_location}" ]]; then if mkdir -p "${unifi_database_location}" &> /dev/null; then chown -R unifi:unifi "${unifi_database_location}"; else header_red; abort_reason="Failed to create required UniFi DB directory."; abort; fi; fi
  if [[ "${mongodb_upgrade_unifi_remove}" == 'true' ]]; then
    unifi_required_packages
    java_required_variables
    unifi_deb_package_modification
    ignore_unifi_package_dependencies
    java_home_check
    check_dpkg_lock
    echo -e "${GRAY_R}#${RESET} Installing UniFi Network Application version ${first_digit_current_unifi}.${second_digit_current_unifi}.${third_digit_current_unifi}..."
    # shellcheck disable=SC2086
    if DEBIAN_FRONTEND='noninteractive' "$(which dpkg)" -i ${dpkg_ignore_depends_flag} "${unifi_temp}" &>> "${eus_dir}/logs/mongodb_upgrade_${mongodb_upgrade_from_version::2}_to_${mongo_version_max}.log"; then
      echo -e "${GREEN}#${RESET} Successfully installed UniFi Network Application version ${first_digit_current_unifi}.${second_digit_current_unifi}.${third_digit_current_unifi}! \\n"
      rm --force "${unifi_temp}" &>> /dev/null
      unset mongodb_upgrade_unifi_remove
    else
      abort_reason="Failed to install UniFi Network Application version ${first_digit_current_unifi}.${second_digit_current_unifi}.${third_digit_current_unifi}."
      unifi_database_move_sucess="true"; mongodb_upgrade_pre_import_failure="true"
      abort
    fi
    if [[ "${mongodb_upgrade_without_export_import}" != 'true' ]]; then
      while read -r unifi_package; do
        echo -e "${GRAY_R}#${RESET} Stopping service ${unifi_package}..."
        if systemctl stop "${unifi_package}" &>> "${eus_dir}/logs/mongodb_upgrade_${mongodb_upgrade_from_version::2}_to_${mongo_version_max}_systemctl.log"; then echo -e "${GREEN}#${RESET} Successfully stopped service ${unifi_package}! \\n"; else abort_reason="Failed to stop service ${unifi_package}."; abort; fi
      done < /tmp/EUS/mongodb/unifi_package_list
      if [[ -d "${unifi_database_location}" ]]; then
        echo -e "${GRAY_R}#${RESET} Moving \"${unifi_database_location}/\" to \"${unifi_db_eus_dir}/unifi_db/db-backup-${mongodb_upgrade_date}-post-reinstall\"..."
        eus_create_directories "unifi_db"
        if mv "${unifi_database_location}/" "${unifi_db_eus_dir}/unifi_db/db-backup-${mongodb_upgrade_date}-post-reinstall" &>> "${eus_dir}/logs/unifi-database-move.log"; then
          echo -e "${GREEN}#${RESET} Successfully moved \"${unifi_database_location}/\" to \"${unifi_db_eus_dir}/unifi_db/db-backup-${mongodb_upgrade_date}-post-reinstall\"! \\n"
        else
          echo -e "${RED}#${RESET} Failed to move \"${unifi_database_location}/\" to \"${unifi_db_eus_dir}/unifi_db/db-backup-${mongodb_upgrade_date}-post-reinstall\"..."; abort_reason="Failed to move ${unifi_database_location}/ to ${unifi_db_eus_dir}/unifi_db/db-backup-${mongodb_upgrade_date}-post-reinstall."; abort_function_skip_reason="true"; abort
        fi
      fi
    fi
  fi
  mongo_command
  if ! [[ -d "${unifi_database_location}" ]]; then
    if ! install -d -m 0755 -o "${unifi_database_location_user}" -g "${unifi_database_location_group}" "${unifi_database_location}"; then
      if ! (mkdir -p "${unifi_database_location}" && chown -R "${unifi_database_location_user}":"${unifi_database_location_group}" "${unifi_database_location}"); then
        abort_reason="Failed to create the missing UniFi Database directory."; abort
      fi
    fi
  fi
  # Restore UniFi Network Application database
  if [[ "${mongodb_upgrade_without_export_import}" != 'true' ]]; then
    start_unifi_database_task="import"
    start_unifi_database
    echo -e "${GRAY_R}#${RESET} Importing \"${unifi_db_eus_dir}/unifi_db/unifi-database-${mongodb_upgrade_date}\" into the UniFi Network Application database..."
    echo -e "\\n------- Restoring MongoDB in the ${mongodb_upgrade_from_version_with_dots} to ${mongo_version_max_with_dot} Upgrade Process ------- $(date +%F-%T.%6N) -------\\n" &>> "${eus_dir}/logs/unifi-database-import.log"
    # shellcheck disable=SC2086
    if mongorestore --port 27117 ${gzip_mongodb_option} ${numparallelcollections_mongodb_option} --drop "${unifi_db_eus_dir}/unifi_db/unifi-database-${mongodb_upgrade_date}" &>> "${eus_dir}/logs/unifi-database-import.log"; then
      echo -e "${GREEN}#${RESET} Successfully imported \"${unifi_db_eus_dir}/unifi_db/unifi-database-${mongodb_upgrade_date}\" into the UniFi Network Application database! \\n"
      shutdown_mongodb
    else
      restore_attempts="0"
      while [[ "${restore_attempts}" -le '3' ]]; do
        header_red
        echo -e "${RED}#${RESET} Failed to import data to the UniFi Network Application database... \\n"
        if [[ "${restore_attempts}" == '0' ]]; then
          attempt_message="second"
          short_attempt_message="2nd"
        elif [[ "${restore_attempts}" == '1' ]]; then
          attempt_message="third"
          short_attempt_message="3rd"
        elif [[ "${restore_attempts}" == '2' ]]; then
          attempt_message="fourth"
          short_attempt_message="4th"
        elif [[ "${restore_attempts}" == '3' ]]; then
          attempt_message="fifth"
          short_attempt_message="5th"
        fi
        mongo_wait_initilize="0"
        until "${mongocommand}" --port 27117 --eval "print(\"waited for connection\")" &>> "${eus_dir}/logs/mongodb-initialize-waiting.log"; do
          ((mongo_wait_initilize=mongo_wait_initilize+1))
          echo -ne "\\r${YELLOW}#${RESET} Waiting for MongoDB to initialize before starting the ${attempt_message} attempt... ${mongo_wait_initilize}/5"
          sleep 60
          if [[ "${mongo_wait_initilize}" -gt '5' ]]; then abort_reason="MongoDB did not respond within the set time frame... Please reach out to Glenn R."; abort; fi
        done
        if [[ "${mongo_wait_initilize}" -gt '0' ]]; then echo -e ""; fi
        echo -e "${GRAY_R}#${RESET} Trying to import \"${unifi_db_eus_dir}/unifi_db/unifi-database-${mongodb_upgrade_date}\" into the UniFi Network Application database for the ${attempt_message} time..."
        echo -e "\\n------- Restoring MongoDB in the ${mongodb_upgrade_from_version_with_dots} to ${mongo_version_max_with_dot} Upgrade Process (${short_attempt_message} run) ------- $(date +%F-%T.%6N) -------\\n" &>> "${eus_dir}/logs/unifi-database-import.log"
        sleep 2
        # shellcheck disable=SC2086
        if mongorestore --port 27117 ${gzip_mongodb_option} ${numparallelcollections_mongodb_option} --drop "${unifi_db_eus_dir}/unifi_db/unifi-database-${mongodb_upgrade_date}" &>> "${eus_dir}/logs/unifi-database-import.log"; then
          echo -e "${GREEN}#${RESET} Successfully imported \"${unifi_db_eus_dir}/unifi_db/unifi-database-${mongodb_upgrade_date}\" into the UniFi Network Application database in the ${attempt_message} run! \\n"
          shutdown_mongodb
          break
        else
          echo -e "${RED}#${RESET} Failed to import data to the UniFi Network Application database in the ${attempt_message} run... \\n"
        fi
        if [[ "${restore_attempts}" -ge '3' ]]; then shutdown_mongodb; unifi_database_move_sucess="true"; mongodb_upgrade_import_failure="true"; abort_reason="Failed to import the data into the UniFi Network Application database, variable restore_attempts is great than 3 (${restore_attempts})"; abort_function_skip_reason="true"; abort; fi
        ((restore_attempts=restore_attempts+1))
      done
    fi
  fi
  chown -R "${unifi_database_location_user}":"${unifi_database_location_group}" "${unifi_database_location}" &> /dev/null
  if ! [[ -d "/var/run/unifi" ]]; then /usr/sbin/unifi-network-service-helper create-dirs &>> "${eus_dir}/logs/unifi-var-run-missing.log"; fi
  #
  mongodb_org_v="$("$(which dpkg)" -l | grep -E "(mongodb-org-server|mongod-armv8|mongod-amd64)[[:space:]]" | grep -i "^ii\\|^hi\\|^ri\\|^pi\\|^ui" | awk '{print $3}' | sed 's/\.//g' | sed 's/.*://' | sed 's/-.*//g' | sed 's/+.*//g' | sort -V | tail -n 1)"
  mongodb_org_v_with_dot="$("$(which dpkg)" -l | grep -E "(mongodb-org-server|mongod-armv8|mongod-amd64)[[:space:]]" | grep -i "^ii\\|^hi\\|^ri\\|^pi\\|^ui" | awk '{print $3}' | sed 's/.*://' | sed 's/-.*//g' | sed 's/+.*//g' | sort -V | tail -n 1)"
  if [[ "${mongo_version_max}" =~ (44|70|80) ]] || [[ "${mongodb_org_v::2}" =~ (44|70|80) ]]; then mongodb_upgrade_system_propties; fi
  while read -r unifi_package; do
    echo -e "${GRAY_R}#${RESET} Starting service ${unifi_package}..."
    if systemctl start "${unifi_package}" &>> "${eus_dir}/logs/mongodb_upgrade_${mongodb_upgrade_from_version::2}_to_${mongo_version_max}_systemctl.log"; then
      echo -e "${GREEN}#${RESET} Successfully started service ${unifi_package}! \\n"
    else
      if [[ "${unifi_package}" == "unifi" ]]; then old_systemd_version_check; check_service_timeoutsec_increase; fi
      if [[ "${old_systemd_version}" == 'true' && "${unifi_package}" == "unifi" ]]; then
        if [[ "${old_systemd_version_check_unifi_restart}" == 'true'  ]]; then
          echo -e "${GREEN}#${RESET} Successfully started service ${unifi_package}! \\n"
        else
          abort_reason="Failed to start service ${unifi_package}."; abort
        fi
      else
        abort_reason="Failed to start service ${unifi_package}."; abort
      fi
    fi
  done < /tmp/EUS/mongodb/unifi_package_list
  if [[ "${mongodb_org_v::2}" =~ (36|44|70|80) ]]; then
    FeatureCompatibilityVersion="${mongodb_org_v_with_dot::3}"
    echo -e "${GRAY_R}#${RESET} Setting featureCompatibilityVersion to the new version..."
    check_count=0
    while [[ "${check_count}" -lt '60' ]]; do
      if [[ "${check_count}" == '3' ]]; then
        header
        echo -e "${GRAY_R}#${RESET} Checking if the MongoDB is responding to continue with setting featureCompatibilityVersion to ${FeatureCompatibilityVersion}... (this can take up to 60 seconds)"
        mongo_setfeaturecompatibilityversion_message="true"
      fi
      if [[ "${mongodb_org_v::2}" =~ (36|44|70|80) ]]; then
        if grep -sioq "confirm: true" /tmp/EUS/mongodb/setFeatureCompatibilityVersion.log; then
          "${mongocommand}" --quiet --port 27117 --eval 'db.adminCommand( { setFeatureCompatibilityVersion: "'"${FeatureCompatibilityVersion}"'", confirm: true } )' &> /tmp/EUS/mongodb/setFeatureCompatibilityVersion.log
        else
          "${mongocommand}" --quiet --port 27117 --eval 'db.adminCommand( { setFeatureCompatibilityVersion: "'"${FeatureCompatibilityVersion}"'" } )' &> /tmp/EUS/mongodb/setFeatureCompatibilityVersion.log
        fi
      fi
      if sed -e 's/ //g' -e 's/"//g' /tmp/EUS/mongodb/setFeatureCompatibilityVersion.log | grep -iq "ok:1"; then
        if [[ "${mongo_setfeaturecompatibilityversion_message}" == 'true' ]]; then
          echo -e "${YELLOW}#${RESET} MongoDB responded! The script will now continue with setting the featureCompatibilityVersion to ${FeatureCompatibilityVersion}! \\n"
          sleep 2
        fi
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
  fi
  while read -r unifi_package; do
    echo -e "${GRAY_R}#${RESET} Restarting service ${unifi_package}..."
    if systemctl restart "${unifi_package}" &>> "${eus_dir}/logs/mongodb_upgrade_${mongodb_upgrade_from_version::2}_to_${mongo_version_max}_systemctl.log"; then echo -e "${GREEN}#${RESET} Successfully restarted service ${unifi_package}! \\n"; else abort_reason="Failed to restart service ${unifi_package}."; abort; fi
  done < /tmp/EUS/mongodb/unifi_package_list
  rm --force /tmp/EUS/mongodb/unifi_package_list &> /dev/null
  sleep 6
  if [[ "${mongodb_upgrade_without_export_import}" != 'true' ]]; then
    header
    echo -e "${GRAY_R}#${RESET} The script created a few files during the database migration, this consumes $(du -sch "${unifi_db_eus_dir}/unifi_db/" 2> /dev/null | grep total$ | awk '{print $1}') on your system..."
    echo -e "${YELLOW}#${RESET} Please note: If you proceed, then there is no going back!... \\n\\n"
    while true; do
      read -rp $'\033[39m#\033[0m Would you like to delete the files created during the database migration? (y/N) ' yes_no
      case "$yes_no" in
         [Nn]*|"")
            echo -e "\\n${GREEN}#${RESET} Alrighty, will keep the files on your system!"
            sleep 3
		    break;;
         [Yy]*)
            while true; do
              read -rp $'\033[39m#\033[0m Are you able to log into the UniFi Network Application? (y/N) ' yes_no
              case "$yes_no" in
                 [Yy]*)
                    echo -e "\\n${GRAY_R}#${RESET} Alrighty, cleaning up the files for you..."
                    if rm -r "${unifi_db_eus_dir}/unifi_db/" &>> "${eus_dir}/logs/unifi_database_migration_cleanup.log"; then echo -e "${GREEN}#${RESET} Successfully removed the old UniFi Network Application database files!\\n"; else echo -e "${RED}#${RESET} Failed to remove the old UniFi Network Application database files..."; fi
                    break;;
                 [Nn]*|"")
                    echo -e "${YELLOW}#${RESET} Keeping the files.. since you mentioned that you cannot log in into the UniFi Network Application... \\n\\n"
                    break;;
                 *) echo -e "\\n${RED}#${RESET} Invalid input, please answer Yes or No (y/n)...\\n"; sleep 3;;
              esac
            done
		    sleep 3
		    break;;
         *) echo -e "\\n${RED}#${RESET} Invalid input, please answer Yes or No (y/n)...\\n"; sleep 3;;
      esac
    done
  fi
  mv "${unifi_logs_location}/eus-run-mongod-import.log" "${eus_dir}/logs/eus-run-mongod-import.log" &> /dev/null
  mv "${unifi_logs_location}/eus-run-mongod-export.log" "${eus_dir}/logs/eus-run-mongod-export.log" &> /dev/null
  header
  echo -e "${GREEN}#${RESET} Successfully finished the MongoDB update! \\n\\n"
  jq '.scripts["'"$script_name"'"].tasks += {"mongodb-upgrade ('"${mongodb_upgrade_date}"')": [.scripts["'"$script_name"'"].tasks["mongodb-upgrade ('"${mongodb_upgrade_date}"')"][0] + {"status":"success"}]}' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
  eus_database_move
  check_unifi_folder_permissions_state="after"
  check_unifi_folder_permissions
  unset mongodb_upgrade_started_success_value
  if [[ "${unifi_update_mongodb_upgrade_process}" == 'true' ]]; then sleep 3; unifi_update_mongodb_upgrade_process_success="true"; else author; exit 0; fi
}

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                              UniFi Network Application Statistics                                                                               #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

unifi_site_stats() {
  header
  while read -r site; do
    if [[ "${unifi_site_stats_first}" == '1' ]]; then echo -e "\\n${GRAY_R}----${RESET}\\n"; else unifi_site_stats_first="1"; fi
    echo -e "${GREEN}#${RESET} Statistics for site: \"$(cat "/tmp/EUS/sites/${site}/site_desc")\"\\n"
    ${unifi_api_curl_cmd} "$unifi_api_baseurl/api/s/${site}/stat/health" | jq -r '.data[] | select(.subsystem|test("^wlan","^lan","^wan")) | {site_placeholder: {(.subsystem): {users: .num_user, guests: .num_guest, iot: .num_iot, adopted: .num_adopted, disconnected: .num_disconnected, disabled: .num_disabled, pending: .num_pending}}}' | sed '/null/d' | sed "s/site_placeholder/${site}/g" &> "/tmp/EUS/stats/site_${site}_stats.json"
    # shellcheck disable=SC2086
    adopted_devices_wlan=$(jq -r '.["'${site}'"].wlan.adopted | select (.!=null)' "/tmp/EUS/stats/site_${site}_stats.json")
    # shellcheck disable=SC2086
    adopted_devices_lan=$(jq -r '.["'${site}'"].lan.adopted | select (.!=null)' "/tmp/EUS/stats/site_${site}_stats.json")
    # shellcheck disable=SC2086
    adopted_devices_wan=$(jq -r '.["'${site}'"].wan.adopted | select (.!=null)' "/tmp/EUS/stats/site_${site}_stats.json")
	adopted_devices_total=$(("${adopted_devices_wlan}" + "${adopted_devices_lan}" + "${adopted_devices_wan}"))
    echo -e "${GRAY_R}#${RESET} Total adopted devices: ${GREEN}${adopted_devices_total}${RESET}"
    echo -e "${GRAY_R}#${RESET} WLAN: ${adopted_devices_wlan}"
    echo -e "${GRAY_R}#${RESET} LAN: ${adopted_devices_lan}"
    echo -e "${GRAY_R}#${RESET} Gateway: ${adopted_devices_wan}"
  done < /tmp/EUS/unifi_sites
}

application_statistics() {
  if [[ "${executed_unifi_credentials}" != 'true' ]]; then
    unifi_credentials
    executed_unifi_credentials="true"
  fi
  unifi_login
  unifi_list_sites
  eus_directory_location="/tmp/EUS"
  eus_create_directories "stats"
  total_adopted="$("${mongocommand}" --quiet --port 27117 ace --eval "${mongoprefix}db.device.stats() )" | jq '.count')"
  # shellcheck disable=SC2016
  jq -n --arg total "${total_adopted}" '{"total_adopted":$total}' > "/tmp/EUS/stats/total_adopted.json"
  unifi_site_stats
  jq -s '.' "/tmp/EUS/stats/total_adopted.json" /tmp/EUS/stats/site_*_stats.json > "/tmp/EUS/stats/complete_stats.json"
  json_time="$(date "+%Y%m%d_%H%M")"
  eus_create_directories "stats"
  mv "/tmp/EUS/stats/complete_stats.json" "${eus_dir}/stats/complete_stats_${json_time}.json"
  mv "/tmp/EUS/stats/total_adopted.json" "${eus_dir}/stats/total_adopted_${json_time}.json"
  # shellcheck disable=SC2012
  ls -t "${eus_dir}/stats/complete_stats_*" 2> /dev/null | awk 'NR>10' | xargs rm -f 2> /dev/null
  # shellcheck disable=SC2012
  ls -t "${eus_dir}/stats/total_adopted_*" 2> /dev/null | awk 'NR>10' | xargs rm -f 2> /dev/null
  echo -e "\\n\\n${GREEN}#########################################################################${RESET}\\n"
  echo -e "${GRAY_R}#${RESET} Total adopted devices on this UniFi Network Application: ${GREEN}${total_adopted}${RESET}\\n"
  echo -e "${GRAY_R}#${RESET} Statistics json file is saved on the locations below: \\n${GRAY_R}-${RESET} \"${eus_dir}/stats/complete_stats_${json_time}.json\" \\n${GRAY_R}-${RESET} \"${eus_dir}/stats/total_adopted_${json_time}.json\"\\n\\n"
  author
  exit 0
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
  if [[ "${installing_required_package}" != 'yes' ]]; then
    echo -e "${GREEN}---${RESET}\\n"
  else
    header
  fi
  if [[ "${script_option_skip}" != 'true' ]]; then read -rp $'\033[39m#\033[0m Do you want to keep the script on your system after completion? (Y/n) ' yes_no; fi
  case "$yes_no" in
      [Nn]*) delete_script="true";;
      *) ;;
  esac
}
script_removal

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
        if DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_downgrade_option[@]}" "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "${linux_package}" &>> "${eus_dir}/logs/linux-package-install.log"; then
          echo -e "${GREEN}#${RESET} Successfully installed ${linux_package}! \\n"
        else
          check_unmet_dependencies
          broken_packages_check
          attempt_recover_broken_packages
          add_apt_option_no_install_recommends="true"; get_apt_options
          if DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_downgrade_option[@]}" "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "${linux_package}" &>> "${eus_dir}/logs/linux-package-install.log"; then
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
         3) echo -e "${YELLOW}#${RESET} OK... Please free up disk space before running the script again..."; cancel_script;;
	     *) header_red; echo -e "${GRAY_R}#${RESET} Option ${choice} is not a valid..."; sleep 3; free_var_log_space_check;;
      esac
    fi
  fi
}
free_var_log_space_check

not_running_proceed() {
  echo -e "${RED}#${RESET} The UniFi Network Application is still not running.. you may experience login issues..."
  while true; do
    read -rp $'\033[39m#\033[0m Do you want to proceed anyway? (Y/n) ' yes_no
    case "$yes_no" in
        [Yy]*|"") break;;
        [Nn]*) cancel_script; break;;
        *) echo -e "\\n${RED}#${RESET} Invalid input, please answer Yes or No (y/n)...\\n"; sleep 3;;
    esac
  done
}

not_running_dir_check() {
  if ! [[ -d "/var/run/unifi" ]]; then install -o unifi -g unifi -m 750 -d /var/run/unifi &>> "${eus_dir}/logs/unifi-var-run-missing.log"; fi
  if ! [[ -d "$(readlink -f /usr/lib/unifi/logs)" ]]; then install -o unifi -g unifi -m 750 -d "$(readlink -f /usr/lib/unifi/logs)" &>> "${eus_dir}/logs/unifi-logs-dir-missing.log"; fi
}

not_running_java_21_check() {
  # Failed to instantiate [ch.qos.logback.classic.LoggerContext] issue with temurin-21-jre 21.0.7.0.0+6-0
  # Could not find or load main class com.ubnt.ace.Launcher issue with openjdk-21-jre-headless 21.0.7
  if [[ "${architecture}" == "arm64" ]]; then
    cpu_model_name="$(lscpu | tr '[:upper:]' '[:lower:]' | grep -i '^model name' | cut -f 2 -d ":" | awk '{$1=$1}1')"
    if [[ -z "${cpu_model_name}" ]]; then cpu_model_name="$(lscpu | tr '[:upper:]' '[:lower:]' | sed -n 's/^model name:[[:space:]]*//p')"; fi
    if [[ "${cpu_model_name}" =~ (cortex-a53) ]]; then
      java_install_check
    fi
  fi
}

if [[ "${limited_functionality}" == 'true' ]]; then
  if ! [[ "$(pgrep -f "/usr/lib/unifi" | grep -cv grep)" -ge "2" ]]; then
    if [[ "${installing_required_package}" != 'yes' ]]; then echo -e "\\n${GREEN}---${RESET}\\n"; else header; fi
    not_running_dir_check
    not_running_java_21_check
    echo -e "${GRAY_R}#${RESET} The UniFi Network Application does not appear to be running... Trying to start it..."
    if service unifi start &> /dev/null; then echo -e "${GREEN}#${RESET} The UniFi Network Application started successfully!"; sleep 3; fi
    if ! [[ "$(pgrep -f "/usr/lib/unifi" | grep -cv grep)" -ge "2" ]]; then
      not_running_proceed
    fi
  fi
else
  if [[ "${os_codename}" =~ (precise|maya|trusty|utopic|vivid|wily|yakkety|zesty|artful|qiana|rebecca|rafaela|rosa|utopic|vivid|wily|yakkety|zesty|artful) ]]; then
    if ! systemctl status unifi | grep -iq running; then
      if [[ "${installing_required_package}" != 'yes' ]]; then echo -e "\\n${GREEN}---${RESET}\\n"; else header; fi
      not_running_dir_check
      not_running_java_21_check
      echo -e "${GRAY_R}#${RESET} The UniFi Network Application does not appear to be running... Trying to start it..."
      if systemctl start unifi &> /dev/null; then echo -e "${GREEN}#${RESET} The UniFi Network Application started successfully!"; sleep 3; fi
      if ! systemctl status unifi | grep -iq running; then
        not_running_proceed
      fi
    fi
  else
    if ! systemctl is-active -q unifi; then
      if [[ "${installing_required_package}" != 'yes' ]]; then echo -e "\\n${GREEN}---${RESET}\\n"; else header; fi
      not_running_dir_check
      not_running_java_21_check
      echo -e "${GRAY_R}#${RESET} The UniFi Network Application does not appear to be running... Trying to start it..."
      if systemctl start unifi &> /dev/null; then echo -e "${GREEN}#${RESET} The UniFi Network Application started successfully!"; sleep 3; fi
      if ! systemctl is-active -q unifi; then
        not_running_proceed
      fi
    fi
  fi
fi

mongodb_repair_required_check() {
  last_match_line="$(grep -n 'SERVER RESTARTED' /usr/lib/unifi/logs/mongod.log 2> /dev/null | tail -n 1 | cut -d: -f1)"
  if [[ -n "${last_match_line}" ]]; then
    if tail -n +$((last_match_line + 1)) /usr/lib/unifi/logs/mongod.log | grep -iaEq "WT_NOTFOUND: item not found, terminating|__wt_panic|An incomplete repair has been detected!"; then
      database_repair_required="true"
    fi
  fi
  if [[ "${database_repair_required}" == 'true' ]]; then
    unifi_database_location="$(readlink -f /usr/lib/unifi/data/db)"
    unifi_database_location_user="$(stat -c "%U" "${unifi_database_location}")"
    unifi_database_location_group="$(stat -c "%G" "${unifi_database_location}")"
    repair_unifi_database
  fi
}
mongodb_repair_required_check

while read -r mongodb_upgrade_log_file; do
  mongodb_upgrade_log_file_epoch_time="$( (stat "${mongodb_upgrade_log_file}" | awk '/Birth:/{print $2, $3}' || find "$(dirname "${mongodb_upgrade_log_file}")" -maxdepth 1 -name "$(basename "${mongodb_upgrade_log_file}")" -printf '%TY-%Tm-%Td %TH:%TM:%TS\n') | xargs -I{} date --date="{}" +"%s" )"
  if [[ "${mongodb_upgrade_log_file_epoch_time}" -lt "1705096140" ]]; then # Check if file is before 12 Jan 2024.
    echo -e "$(date +%F-%T.%6N) | Log file \"${mongodb_upgrade_log_file}\" epoch time is ${mongodb_upgrade_log_file_epoch_time}, changing variable check_multiple_default_lan_networks to true..." &>> "${eus_dir}/logs/cleanup-multiple-default-lan-networks.log"
    check_multiple_default_lan_networks="true"
  fi
done < <(find "${eus_dir}/logs/" -type f -name "mongodb_upgrade*")
if [[ "${check_multiple_default_lan_networks}" == 'true' ]]; then cleanup_multiple_default_lan_networks; if [[ "${exit_after_check_multiple_default_lan_networks}" == 'true' ]]; then cancel_script; else sleep 3; fi; fi

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
    if [[ "${expired_mongodb_check_message}" != 'true' ]]; then if echo -e "${GRAY_R}#${RESET} Checking for expired MongoDB repository keys... \\n"; then expired_mongodb_check_message="true"; fi; fi
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
      if [[ "${expired_mongodb_check_message}" != 'true' ]]; then if echo -e "${GRAY_R}#${RESET} Checking for expired MongoDB repository keys... \\n"; then expired_mongodb_check_message="true"; fi; fi
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
if [[ "${mongodb_key_update}" == 'true' ]]; then run_apt_get_update; unset mongodb_key_update; get_mongodb_org_v; sleep 3; fi

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

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                       What Should we run?                                                                                       #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

script_option_run_question() {
  header
  if [[ "${script_option_skip}" == 'true' && "${script_option_unifi_version}" == 'true' ]]; then
    non_interactive_application_upgrade="true"
  else
    echo -e "  What would you like to perform?\\n\\n"
    if [[ "${unifi_core_system}" == 'true' ]]; then
      echo -e " [   ${WHITE_R}1${RESET}   ]  |  Update the UniFi Network Application"
      echo -e " [   ${WHITE_R}2${RESET}   ]  |  Update UniFi Devices"
      echo -e " [   ${WHITE_R}3${RESET}   ]  |  Update the UniFi Network Application and UniFi Devices"
      echo -e " [   ${WHITE_R}4${RESET}   ]  |  Archive/Delete UniFi Network Application events, alarms and alerts"
      echo -e " [   ${WHITE_R}5${RESET}   ]  |  Get UniFi Network Application Statistics"
      echo -e " [   ${WHITE_R}6${RESET}   ]  |  Cancel Script\\n\\n"
    else
      echo -e " [   ${WHITE_R}1${RESET}   ]  |  Update the UniFi Network Application"
      echo -e " [   ${WHITE_R}2${RESET}   ]  |  Update UniFi Devices"
      echo -e " [   ${WHITE_R}3${RESET}   ]  |  Update the Operating System"
      echo -e " [   ${WHITE_R}4${RESET}   ]  |  Update the UniFi Network Application and UniFi Devices"
      echo -e " [   ${WHITE_R}5${RESET}   ]  |  Archive/Delete UniFi Network Application events, alarms and alerts"
      echo -e " [   ${WHITE_R}6${RESET}   ]  |  Get UniFi Network Application Statistics"
      if [[ "${mongo_version_max}" == '34' ]]; then
        echo -e " [   ${WHITE_R}7${RESET}   ]  |  Cancel Script\\n\\n"
      else
        if [[ "${mongodb_org_v::2}" =~ (24|26|30|32|34) && "${mongo_version_max}" == "36" && "${mongodb_upgrade_supported}" == 'true' ]] || [[ "${mongodb_org_v::2}" =~ (24|26|30|32|34|36|40|42) && "${mongo_version_max}" == "44" && "${mongodb_upgrade_supported}" == 'true' ]] || [[ "${mongodb_org_v::2}" =~ (24|26|30|32|34|36|40|42|44|50|60) && "${mongo_version_max}" == "70" && "${mongodb_upgrade_supported}" == 'true' ]] || [[ "${mongodb_org_v::2}" =~ (24|26|30|32|34|36|40|42|44|50|60|70) && "${mongo_version_max}" == "80" && "${mongodb_upgrade_supported}" == 'true' ]]; then
          echo -e " [   ${WHITE_R}7${RESET}   ]  |  MongoDB upgrade to ${mongo_version_max_with_dot}"
          echo -e " [   ${WHITE_R}8${RESET}   ]  |  Cancel Script\\n\\n"
        else
          echo -e " [   ${WHITE_R}7${RESET}   ]  |  Cancel Script\\n\\n"
        fi
      fi
    fi
    read -rp $'Your choice | \033[39m' unifi_easy_update
    if [[ "${unifi_core_system}" == 'true' ]]; then
      case "$unifi_easy_update" in
          1) perform_application_upgrade="true";;
          2) only_run_unifi_devices_upgrade;;
          3) perform_application_upgrade="true"; run_unifi_devices_upgrade;;
          4) alert_event_option;;
          5) application_statistics;;
          6) cancel_script;;
          *) echo -e "\\n${RED}#${RESET} Invalid input, please answer with a number...\\n"; sleep 3; script_option_run_question;;
      esac
    else
      if [[ "${mongo_version_max}" == '34' ]]; then
        case "$unifi_easy_update" in
            1) perform_application_upgrade="true";;
            2) only_run_unifi_devices_upgrade;;
            3) os_upgrade;;
            4) perform_application_upgrade="true"; run_unifi_devices_upgrade;;
            5) alert_event_option;;
            6) application_statistics;;
            7) cancel_script;;
            *) echo -e "\\n${RED}#${RESET} Invalid input, please answer with a number...\\n"; sleep 3; script_option_run_question;;
        esac
      else
        if [[ "${mongodb_org_v::2}" =~ (24|26|30|32|34) && "${mongo_version_max}" == "36" && "${mongodb_upgrade_supported}" == 'true' ]] || [[ "${mongodb_org_v::2}" =~ (24|26|30|32|34|36|40|42) && "${mongo_version_max}" == "44" && "${mongodb_upgrade_supported}" == 'true' ]] || [[ "${mongodb_org_v::2}" =~ (24|26|30|32|34|36|40|42|44|50|60) && "${mongo_version_max}" == "70" && "${mongodb_upgrade_supported}" == 'true' ]] || [[ "${mongodb_org_v::2}" =~ (24|26|30|32|34|36|40|42|44|50|60|70) && "${mongo_version_max}" == "80" && "${mongodb_upgrade_supported}" == 'true' ]]; then
          case "$unifi_easy_update" in
              1) perform_application_upgrade="true";;
              2) only_run_unifi_devices_upgrade;;
              3) os_upgrade;;
              4) perform_application_upgrade="true"; run_unifi_devices_upgrade;;
              5) alert_event_option;;
              6) application_statistics;;
              7) mongodb_upgrade;;
              8) cancel_script;;
              *) echo -e "\\n${RED}#${RESET} Invalid input, please answer with a number...\\n"; sleep 3; script_option_run_question;;
          esac
        else
          case "$unifi_easy_update" in
              1) perform_application_upgrade="true";;
              2) only_run_unifi_devices_upgrade;;
              3) os_upgrade;;
              4) perform_application_upgrade="true"; run_unifi_devices_upgrade;;
              5) alert_event_option;;
              6) application_statistics;;
              7) cancel_script;;
              *) echo -e "\\n${RED}#${RESET} Invalid input, please answer with a number...\\n"; sleep 3; script_option_run_question;;
          esac
        fi
      fi
    fi
  fi
}
script_option_run_question

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                         Ask For Backup                                                                                          #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

header
if [[ "${non_interactive_application_upgrade}" != 'true' ]]; then
  echo -e "${GRAY_R}#${RESET} Would you like to create a backup of your UniFi Network Application?"
  echo -e "${GRAY_R}#${RESET} I highly recommend creating a UniFi Network Application backup!${RESET}\\n\\n"
  while true; do
    read -rp $'\033[39m#\033[0m Do you want to proceed with creating a backup? (Y/n) ' yes_no
    case "$yes_no" in
        [Yy]*|"")
          header
          echo -e "${GRAY_R}#${RESET} Starting the UniFi Network Application backup! \\n\\n"
          sleep 3
          if [[ "${executed_unifi_credentials}" != 'true' ]]; then
            unifi_credentials
            executed_unifi_credentials="true"
          fi
          unifi_login
          if [[ "${unifi_backup_cancel}" != 'true' ]]; then
            debug_check
            unifi_list_sites
            unifi_backup
            unifi_backup_check
          fi
          break;;
        [Nn]*)
          header_red
          echo -e "${GRAY_R}#${RESET} You choose not to create a backup! \\n\\n"
          sleep 2
          break;;
        *) echo -e "\\n${RED}#${RESET} Invalid input, please answer Yes or No (y/n)...\\n"; sleep 3;;
    esac
  done
else
  echo -e "${YELLOW}#${RESET} Skipping the backup option because script in running in non-interactive mode. \\n"
  sleep 3
fi

if [[ "${non_interactive_application_upgrade}" != 'true' ]]; then
  if [[ "${glennr_unifi_backup}" != 'success' ]]; then
    header_red
    echo -e "${GRAY_R}#${RESET} You didn't create a backup of your UniFi Network Application! \\n\\n"
    while true; do
      read -rp $'\033[39m#\033[0m Do you want to proceed with updating your UniFi Network Application? (Y/n) ' yes_no
      case "$yes_no" in
          [Yy]*|"") break;;
          [Nn]*)
            header_red
            echo -e "${RED}#${RESET} You didn't download a backup!"
            echo -e "${RED}#${RESET} Please download a backup and rerun the script..\\n"
            echo -e "${RED}#${RESET} Cancelling the script!"
            exit 1
            break;;
          *) echo -e "\\n${RED}#${RESET} Invalid input, please answer Yes or No (y/n)...\\n"; sleep 3;;
      esac
    done
  fi
fi

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                             Checks                                                                                              #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

if [[ "${perform_application_upgrade}" == 'true' ]]; then prevent_unifi_upgrade; fi
alert_event_cleanup

if [[ "${backup_location}" == "custom" ]]; then
  if echo "$auto_dir" | grep -q '/$'; then
    cleanup_backup_files_dir="${auto_dir}glennr-unifi-backups/"
  else
    cleanup_backup_files_dir="$auto_dir/glennr-unifi-backups/"
  fi
elif [[ "${backup_location}" == "sd_card" ]]; then
  cleanup_backup_files_dir="/data/glennr-unifi-backups/glennr-unifi-backups/"
elif [[ "${backup_location}" == "sd_card_unifi_os" ]]; then
  cleanup_backup_files_dir="/sdcard/glennr-unifi-backups/glennr-unifi-backups/"
elif [[ "${backup_location}" == "unifi_dir" ]]; then
  cleanup_backup_files_dir="/usr/lib/unifi/data/backup/glennr-unifi-backups/"
fi

if [[ -n "${cleanup_backup_files_dir}" ]]; then cleanup_backup_files; fi

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                              JAVA                                                                                               #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

java_install_check

##########################################################################################################################################################################
#                                                                                                                                                                        #
#                                                               Custom UniFi Network Application Download                                                                #
#                                                                                                                                                                        #
##########################################################################################################################################################################

if [[ "${script_option_custom_url}" == 'true' && "${perform_application_upgrade}" == 'true' ]]; then if [[ "${custom_url_down_provided}" == 'true' ]]; then custom_url_download_check; else custom_url_question; fi; fi

##########################################################################################################################################################################
#                                                                                                                                                                        #
#                                                           UniFi Network Application download and installation                                                          #
#                                                                                                                                                                        #
##########################################################################################################################################################################

application_upgrade_releases() {
  db_version_check
  system_properties_check
  unifi_autobackup_dir_check
  keystore_alias_check
  unifi_current="$("$(which dpkg)" -l unifi | tail -n1 |  awk '{print $3}' | cut -d'-' -f1)"
  application_version_release="$(echo "${application_version}" | cut -d'-' -f1)"
  if [[ -e "/usr/lib/unifi/data/db/version" ]]; then
    unifi_database_version="$(grep -E '^[0-9.]+$' "/usr/lib/unifi/data/db/version")"
    if [[ "${unifi_current}" != "${unifi_database_version}" ]]; then
      if [[ "$(echo "${unifi_database_version}" | awk -F. '{print $1$2}')" -ge "$(echo "${application_version_release}" | awk -F. '{print $1$2}')" ]] && [[ "$(echo "${unifi_database_version}" | awk -F. '{print $3}')" -gt "$(echo "${application_version_release}" | awk -F. '{print $3}')" ]]; then
	    echo -e "${YELLOW}#${RESET} Your UniFi Network Application database is already migrated to version ${unifi_database_version}, the script will upgrade to that version instead."
        application_version_release="${unifi_database_version}"
      fi
    fi
  fi
  application_version_release_digit_1="$(echo "${application_version_release}" | cut -d'.' -f1)"
  application_version_release_digit_2="$(echo "${application_version_release}" | cut -d'.' -f2)"
  application_version_release_digit_3="$(echo "${application_version_release}" | cut -d'.' -f3)"
  application_current_digit_1="$(echo "${unifi_current}" | cut -d'.' -f1)"
  application_current_digit_2="$(echo "${unifi_current}" | cut -d'.' -f2)"
  application_current_digit_3="$(echo "${unifi_current}" | cut -d'.' -f3)"
  if [[ "${application_version_release_digit_1}" -gt "${application_current_digit_1}" ]]; then application_upgrade="yes"; fi
  if [[ "${application_version_release_digit_1}" == "${application_current_digit_1}" && "${application_version_release_digit_2}" -gt "${application_current_digit_2}" ]]; then application_upgrade="yes"; fi
  if [[ "${application_version_release_digit_1}" == "${application_current_digit_1}" && "${application_version_release_digit_2}" == "${application_current_digit_2}" && "${application_version_release_digit_3}" -gt "${application_current_digit_3}" ]]; then application_upgrade="yes"; fi
  if [[ "${application_current_digit_1}.${application_current_digit_2}.${application_current_digit_3}" == "${application_version_release_digit_1}.${application_version_release_digit_2}.${application_version_release_digit_3}" ]]; then application_upgrade="match"; fi
  if [[ "${application_upgrade}" == 'match' ]]; then
    header
	echo -e "${GRAY_R}#${RESET} Your UniFi Network Application is already running \"${unifi_current}\"...\\n\\n"
    author
    exit 0
  elif [[ "${application_upgrade}" != 'yes' ]]; then
    header_red
	echo -e "${GRAY_R}#${RESET} You were about to downgrade your UniFi Network Application from \"${unifi_current}\" to \"${application_version_release}\".. Cancelling this upgrade..\\n\\n"
    author
    exit 0
  fi
  first_digit_unifi="${application_version_release_digit_1}"
  second_digit_unifi="${application_version_release_digit_2}"
  third_digit_unifi="${application_version_release_digit_3}"
  if [[ "${cloudkey_generation}" == "1" ]]; then
    if [[ "${first_digit_unifi}" -gt '7' ]] || [[ "${first_digit_unifi}" == '7' && "${second_digit_unifi}" -ge '3' ]]; then
      header_red
      echo -e "${GRAY_R}#${RESET} UniFi Network Application ${application_version_release_digit_1}.${application_version_release_digit_2}.${application_version_release_digit_3} is not supported on your Gen1 UniFi Cloudkey (UC-CK)."
      echo -e "${GRAY_R}#${RESET} The latest supported version on your Cloudkey is $(curl "${curl_argument[@]}" "https://api.glennr.nl/api/network-latest?version=7.2" 2> /dev/null | jq -r '.latest_version' 2> /dev/null) and older.. \\n\\n"
      echo -e "${GRAY_R}#${RESET} Consider upgrading to a Gen2 Cloudkey:"
      echo -e "${GRAY_R}#${RESET} UniFi Cloud Key Gen2       | https://store.ui.com/products/unifi-cloud-key-gen2"
      echo -e "${GRAY_R}#${RESET} UniFi Cloud Key Gen2 Plus  | https://store.ui.com/products/unifi-cloudkey-gen2-plus\\n\\n"
      author
      exit 0
    fi
  fi
  if [[ "${first_digit_unifi}" -gt '7' ]] || [[ "${first_digit_unifi}" == '7' && "${second_digit_unifi}" -ge '5' ]]; then
    if [[ "$(getconf LONG_BIT)" == '32' ]]; then
      header_red
      mongodb_server_version="$("$(which dpkg)" -l | grep "^ii\\|^hi\\|^ri\\|^pi\\|^ui\\|^iU" | grep -E "(mongodb-server|mongodb-org-server|mongod-armv8|mongod-amd64)[[:space:]]" | awk '{print $3}' | sed -e 's/.*://' -e 's/-.*//' -e 's/+.*//' -e 's/\.//g')"
      if [[ "${mongodb_server_version::2}" -le "25" ]]; then unifi_latest_supported_version="7.3"; else unifi_latest_supported_version="7.4"; fi
      echo -e "${GRAY_R}#${RESET} Your 32-bit system/OS is no longer supported by UniFi Network Application ${application_version_release}!"
      echo -e "${GRAY_R}#${RESET} The latest supported version on your system/OS is $(curl "${curl_argument[@]}" "https://api.glennr.nl/api/network-latest?version=${unifi_latest_supported_version}" 2> /dev/null | jq -r '.latest_version' 2> /dev/null) and older..."
      echo -e "${GRAY_R}#${RESET} Consider upgrading to a 64-bit system/OS!\\n\\n"
      author
      exit 0
    fi
  fi
  if [[ "${first_digit_unifi}" -gt '7' ]] || [[ "${first_digit_unifi}" == '7' && "${second_digit_unifi}" == '4' ]] || [[ "${first_digit_unifi}" == '7' && "${second_digit_unifi}" -ge '5' ]]; then
    if [[ "${first_digit_unifi}" -gt '7' ]] || [[ "${first_digit_unifi}" == '7' && "${second_digit_unifi}" -ge '5' ]]; then
      minimum_required_mongodb_version_dot="3.6"
      minimum_required_mongodb_version="36"
      unifi_latest_supported_version_number="7.4"
    elif [[ "${first_digit_unifi}" == '7' && "${second_digit_unifi}" == '4' ]]; then
      minimum_required_mongodb_version_dot="2.6"
      minimum_required_mongodb_version="26"
      unifi_latest_supported_version_number="7.3"
    fi
    mongodb_server_version="$("$(which dpkg)" -l | grep "^ii\\|^hi\\|^ri\\|^pi\\|^ui\\|^iU" | grep -E "(mongodb-server|mongodb-org-server|mongod-armv8|mongod-amd64)[[:space:]]" | awk '{print $3}' | sed -e 's/.*://' -e 's/-.*//' -e 's/+.*//' -e 's/\.//g')"
    if [[ "${mongodb_server_version::2}" -lt "${minimum_required_mongodb_version}" ]]; then
      if [[ "${unifi_core_system}" == 'true' ]]; then
        if [[ "${os_codename}" == 'stretch' ]]; then
          header_red
          echo -e "${GRAY_R}#${RESET} UniFi Network Application ${first_digit_unifi}.${second_digit_unifi}.${third_digit_unifi} requires a newer version of UniFi OS."
          echo -e "${GRAY_R}#${RESET} The latest version that you can run with UniFi OS version $(cut -d'.' -f3,4,5 /usr/lib/version | sed 's/v//g') is $(curl "${curl_argument[@]}" "https://api.glennr.nl/api/network-latest?version=${unifi_latest_supported_version_number}" 2> /dev/null | jq -r '.latest_version' 2> /dev/null) and older.. \\n\\n"
          unifi_core_upgrade_message="true"
        else
          unifi_core_mongodb_upgrade_bypass="true"
        fi
      else
        header_red
        echo -e "${GRAY_R}#${RESET} UniFi Network Application ${first_digit_unifi}.${second_digit_unifi}.${third_digit_unifi} requires MongoDB ${minimum_required_mongodb_version_dot} or newer."
        echo -e "${GRAY_R}#${RESET} The latest version that you can run with MongoDB version $("$(which dpkg)" -l | grep -E "(mongodb-server|mongodb-org-server|mongod-armv8|mongod-amd64)[[:space:]]" | awk '{print $3}' | sed -e 's/.*://' -e 's/-.*//' -e 's/+.*//') is $(curl "${curl_argument[@]}" "https://api.glennr.nl/api/network-latest?version=${unifi_latest_supported_version_number}" 2> /dev/null | jq -r '.latest_version' 2> /dev/null) and older.. \\n\\n"
        if [[ "${mongodb_org_v::2}" =~ (24|26|30|32|34) && "${mongo_version_max}" == "36" && "${mongodb_upgrade_supported}" == 'true' ]] || [[ "${mongodb_org_v::2}" =~ (24|26|30|32|34|36|40|42) && "${mongo_version_max}" == "44" && "${mongodb_upgrade_supported}" == 'true' ]] || [[ "${mongodb_org_v::2}" =~ (24|26|30|32|34|36|40|42|44|50|60) && "${mongo_version_max}" == "70" && "${mongodb_upgrade_supported}" == 'true' ]] || [[ "${mongodb_org_v::2}" =~ (24|26|30|32|34|36|40|42|44|50|60|70) && "${mongo_version_max}" == "80" && "${mongodb_upgrade_supported}" == 'true' ]]; then
          while true; do
            read -rp $'\033[39m#\033[0m Would you like to run the option to upgrade to MongoDB '"${mongo_version_max_with_dot}"'? (Y/n) ' yes_no
            case "$yes_no" in
                 [Yy]*|"")
                    unifi_update_mongodb_upgrade_process="true"
                    echo -e "${GRAY_R}#${RESET} OK... Starting the MongoDB Upgrade process..."
                    sleep 5
                    mongodb_upgrade
                    break;;
                 [Nn]*)
                    echo -e "${YELLOW}#${RESET} OK... Please re-execute the script when you feel ready!"
                    break;;
                 *) echo -e "\\n${RED}#${RESET} Invalid input, please answer Yes or No (y/n)...\\n"; sleep 3;;
            esac
          done
        else
          echo -e "${GRAY_R}#${RESET} The script will first update the UniFi Network Application to version $(curl "${curl_argument[@]}" "https://api.glennr.nl/api/network-latest?version=${unifi_latest_supported_version_number}" 2> /dev/null | jq -r '.latest_version' 2> /dev/null) before updating to version ${first_digit_unifi}.${second_digit_unifi}.${third_digit_unifi}... \\n"
	      sleep 5
          original_application_version="${application_version}"
          application_version="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/network-latest?version=${unifi_latest_supported_version_number}" 2> /dev/null | jq -r '.latest_version' 2> /dev/null)"
          application_upgrade_releases
          get_mongo_version_max
          application_version="${original_application_version}"
          application_upgrade_releases
          return 0
        fi
      fi
      if [[ "$(getconf LONG_BIT)" == '32' ]]; then
        echo -e "${GRAY_R}#${RESET} You're using a 32-bit OS.. please switch over to a 64-bit OS.\\n\\n"
      fi
      if [[ "${unifi_update_mongodb_upgrade_process_success}" != 'true' && "${unifi_core_mongodb_upgrade_bypass}" != 'true' ]]; then
        author
        exit 0
      fi
    fi
  fi
  #if [[ "${application_current_digit_1}" -lt "9" && "${application_version_release_digit_1}" -ge "9" ]]; then usg_unsupported_notice; fi
  if [[ -s "/tmp/EUS/repository/unifi-repo-file" && "${release_stage}" == "S" ]]; then
    while read -r unifi_repo_file; do
      unifi_repo_file_version_current="$(grep -io "unifi-[0-9].[0-9]" "${unifi_repo_file}")"
      unifi_repo_file_version_new="unifi-${application_version_release_digit_1}.${application_version_release_digit_2}"
      sed -i "s/${unifi_repo_file_version_current}/${unifi_repo_file_version_new}/g" "${unifi_repo_file}" &>> "${eus_dir}/logs/unifi_repo_file_update.log"
    done < /tmp/EUS/repository/unifi-repo-file
  fi
  java_install_check
  header
  check_service_overrides
  old_systemd_version_check
  check_service_timeoutsec_increase
  echo -e "${GRAY_R}#${RESET} Updating your UniFi Network Application version from ${unifi_current} to ${application_version_release}! \\n"
  echo -e "${GRAY_R}#${RESET} Downloading UniFi Network Application version ${application_version_release}..."
  if [[ "$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/locate-network-release?status" 2> "${eus_dir}/logs/locate-download.log" | jq -r '.availability' 2> "${eus_dir}/logs/locate-download.log")" == "OK" ]]; then
    fw_update_dl_link="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/network-release?version=${application_version_release}${unifi_core_glennr_api}" | jq -r '.download_link' | sed '/null/d' 2> "${eus_dir}/logs/locate-download.log")"
    fw_update_gr_dl_link="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/network-release?version=${application_version_release}&server=archive${unifi_core_glennr_api}" | jq -r '.download_link' | sed '/null/d' 2> "${eus_dir}/logs/locate-download.log")"
  else
    fw_update_dl_link="$(curl "${curl_argument[@]}" "https://fw-update.ui.com/api/firmware-latest?filter=eq~~version_major~~${application_version_release_digit_1}&filter=eq~~version_minor~~${application_version_release_digit_2}&filter=eq~~version_patch~~${application_version_release_digit_3}&filter=eq~~platform~~debian" 2> "${eus_dir}/logs/locate-download.log" | jq -r "._embedded.firmware[]._links.data.href" 2> "${eus_dir}/logs/locate-download.log" | sed '/null/d' 2> "${eus_dir}/logs/locate-download.log")"
  fi
  if [[ "${unifi_deb_file_name}" == "unifi_sysvinit_all" ]]; then
    if [[ "$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/locate-network-release?status" 2> "${eus_dir}/logs/locate-download.log" | jq -r '.availability' 2> "${eus_dir}/logs/locate-download.log")" == "OK" ]]; then
      unifi_sha256sum="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/network-release?version=${first_digit_unifi}.${second_digit_unifi}.${third_digit_unifi}${unifi_core_glennr_api}" | jq -r '."sha256sum"' | sed '/null/d' 2> "${eus_dir}/logs/locate-download.log")"
    else
      unifi_sha256sum="$(curl "${curl_argument[@]}" "https://fw-update.ui.com/api/firmware-latest?filter=eq~~version_major~~${application_version_release_digit_1}&filter=eq~~version_minor~~${application_version_release_digit_2}&filter=eq~~version_patch~~${application_version_release_digit_3}&filter=eq~~platform~~debian" 2> "${eus_dir}/logs/locate-download.log" | jq -r "._embedded.firmware[].sha256_checksum" 2> "${eus_dir}/logs/locate-download.log" | sed '/null/d' 2> "${eus_dir}/logs/locate-download.log")"
    fi
  fi
  unifi_download_urls=()
  if [[ "$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/geo" 2> /dev/null | jq -r '."continent_code"' 2> /dev/null)" == "EU" ]]; then
    if [[ -n "${fw_update_gr_dl_link}" ]]; then unifi_download_urls+=("${fw_update_gr_dl_link}"); fi
    if [[ -n "${fw_update_dl_link}" ]]; then unifi_download_urls+=("${fw_update_dl_link}"); fi
  else
    if [[ -n "${fw_update_dl_link}" ]]; then unifi_download_urls+=("${fw_update_dl_link}"); fi
    if [[ -n "${fw_update_gr_dl_link}" ]]; then unifi_download_urls+=("${fw_update_gr_dl_link}"); fi
  fi
  if [[ -n "${application_version}" ]]; then unifi_download_urls+=("https://dl.ui.com/unifi/${application_version}/${unifi_deb_file_name}.deb"); fi
  if [[ -n "${application_version_release}" ]]; then unifi_download_urls+=("https://dl.ui.com/unifi/${application_version_release}/${unifi_deb_file_name}.deb"); fi
  for unifi_download_url in "${unifi_download_urls[@]}"; do
    eus_tmp_deb_name="${unifi_deb_file_name}_${application_version_release}"
    eus_tmp_deb_var="unifi_temp"
    eus_tmp_directory_check
    echo -e "$(date +%F-%T.%6N) | Downloading ${unifi_download_url} to ${unifi_temp}" &>> "${eus_dir}/logs/unifi-download.log"
    if curl "${nos_curl_argument[@]}" --output "${unifi_temp}" "${unifi_download_url}" &>> "${eus_dir}/logs/unifi-download.log"; then
      if command -v sha256sum &> /dev/null && [[ -n "${unifi_sha256sum}" ]]; then
        if [[ "$(sha256sum "$unifi_temp" | awk '{print $1}')" != "${unifi_sha256sum}" ]]; then echo -e "$(date +%F-%T.%6N) | The file downloaded via ${unifi_download_url} did not have sha256sum \"${unifi_sha256sum}\"..." &>> "${eus_dir}/logs/unifi-download.log"; continue; fi
      else
        if command -v dpkg-deb &> /dev/null; then if ! dpkg-deb --info "${unifi_temp}" &> /dev/null; then echo -e "$(date +%F-%T.%6N) | The file downloaded via ${unifi_download_url} was not a debian file format..." &>> "${eus_dir}/logs/unifi-download.log"; continue; fi; fi
      fi
      echo -e "${GREEN}#${RESET} Successfully downloaded UniFi Network version ${application_version_release}! \\n"; unifi_downloaded="true"; break
    elif [[ "${unifi_download_url}" =~ ^https:// ]]; then
      echo -e "$(date +%F-%T.%6N) | Downloading ${unifi_download_url/https:/http} to ${unifi_temp}" &>> "${eus_dir}/logs/unifi-download.log"
      if curl "${nos_curl_argument[@]}" --output "${unifi_temp}" "${unifi_download_url/https:/http:}" &>> "${eus_dir}/logs/unifi-download.log"; then
        if command -v sha256sum &> /dev/null && [[ -n "${unifi_sha256sum}" ]]; then
          if [[ "$(sha256sum "$unifi_temp" | awk '{print $1}')" != "${unifi_sha256sum}" ]]; then echo -e "$(date +%F-%T.%6N) | The file downloaded via ${unifi_download_url} did not have sha256sum \"${unifi_sha256sum}\"..." &>> "${eus_dir}/logs/unifi-download.log"; continue; fi
        else
          if command -v dpkg-deb &> /dev/null; then if ! dpkg-deb --info "${unifi_temp}" &> /dev/null; then echo -e "$(date +%F-%T.%6N) | The file downloaded via ${unifi_download_url/https:/http:} was not a debian file format..." &>> "${eus_dir}/logs/unifi-download.log"; continue; fi; fi
        fi
        echo -e "${GREEN}#${RESET} Successfully downloaded UniFi Network version ${application_version_release} (using HTTP)! \\n"; unifi_downloaded="true"; break
      fi
    fi
  done
  if [[ "${unifi_downloaded}" != 'true' ]]; then abort_reason="Failed to download UniFi Network version ${application_version_release}."; abort; else unset unifi_downloaded; fi
  first_digit_unifi="${application_version_release_digit_1}"
  second_digit_unifi="${application_version_release_digit_2}"
  third_digit_unifi="${application_version_release_digit_3}"
  unifi_deb_package_modification
  ignore_unifi_package_dependencies
  if [[ "${application_current_digit_1}${application_current_digit_2}" -le "80" && "${application_version_release_digit_1}${application_version_release_digit_2}" -ge "81" ]]; then
    echo -e "${GRAY_R}#${RESET} Upgrading your UniFi Network Application from \"${unifi_current}\" to \"${application_version_release}\" could take up to ${unifi_upgrade_estimate_duration}"
    echo -e "${GRAY_R}#${RESET} because it needs to migrate $("${mongocommand}" --quiet --port 27117 ace_stat --eval "${mongoprefix}db.dpi.stats() )" 2> /dev/null | jq '.count' 2> /dev/null) Traffic Identification records..."
  else
    echo -e "${GRAY_R}#${RESET} Upgrading your UniFi Network Application from \"${unifi_current}\" to \"${application_version_release}\"..."
    echo -e "${GRAY_R}#${RESET} This process could take up to ${unifi_upgrade_estimate_duration}..."
  fi
  if [[ "$(dpkg-query --showformat='${version}' --show jq 2> /dev/null | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
    jq '.scripts."'"${script_name}"'" |= if .["upgrade-path"] | index("'"${application_current_digit_1}.${application_current_digit_2}.${application_current_digit_3} > ${application_version_release_digit_1}.${application_version_release_digit_2}.${application_version_release_digit_3}"'") | not then .["upgrade-path"] += ["'"${application_current_digit_1}.${application_current_digit_2}.${application_current_digit_3} > ${application_version_release_digit_1}.${application_version_release_digit_2}.${application_version_release_digit_3}"'"] else . end' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
  else
    jq --arg script_name "$script_name" --arg current_app "$application_current_digit_1.$application_current_digit_2.$application_current_digit_3" --arg new_app "$application_version_release_digit_1.$application_version_release_digit_2.$application_version_release_digit_3" '.scripts[$script_name] |= (if (.["upgrade-path"] | type == "array") then if (.["upgrade-path"] | map(select(. == ($current_app + " > " + $new_app))) | length == 0) then .["upgrade-path"] += [$current_app + " > " + $new_app] else . end else .["upgrade-path"] = [$current_app + " > " + $new_app] end )' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
  fi
  eus_database_move
  echo -e "\\n------- $(date +%F-%T.%6N) -------\\n" &>> "${eus_dir}/logs/unifi-update.log"
  check_dpkg_lock
  if [[ "${unifi_core_system}" != 'true' ]]; then
    echo "unifi unifi/has_backup boolean true" 2> /dev/null | debconf-set-selections
    # shellcheck disable=SC2086
    DEBIAN_FRONTEND='noninteractive' "$(which dpkg)" -i ${dpkg_ignore_depends_flag} "${unifi_temp}" &>> "${eus_dir}/logs/unifi-update.log" 2>&1 &
    update_progress_pid="$!"
    monitor_update_progress_pid "${update_progress_pid}"
    wait "${update_progress_pid}"
    update_progress_exit_code="$?"
  else
    DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "${unifi_temp}" &>> "${eus_dir}/logs/unifi-update.log" 2>&1 &
    update_progress_pid="$!"
    monitor_update_progress_pid "${update_progress_pid}"
    wait "${update_progress_pid}"
    update_progress_exit_code="$?"
  fi
  if [[ "${update_progress_exit_code}" -eq "0" ]]; then
    echo -e "${GREEN}#${RESET} Successfully updated UniFi Network version from ${unifi_current} to ${application_version_release}! \\n"
  else
    abort_reason="Failed to update the UniFi Network version from ${unifi_current} to ${application_version_release}."
    abort
  fi
  rm --force "${unifi_temp}" &> /dev/null
  sleep 3
  java_cleanup_not_required_versions
}

##########################################################################################################################################################################
#                                                                                                                                                                        #
#                                                             5.0.x | 5.1.x | 5.2.x | 5.3.x | 5.4.x | 5.5.x                                                              #
#                                                                                                                                                                        #
##########################################################################################################################################################################

start_application_upgrade
if [[ "${non_interactive_application_upgrade}" == 'true' ]]; then
  unifi_update_start
  if [[ "${application_version}" == "latest" ]]; then application_version="${latest_release}"; fi
  application_upgrade_releases
  unifi_update_finish
fi

if [[ "${first_digit_unifi}" == '5' && "${second_digit_unifi}" =~ ^(0|1|2|3|4|5)$ ]]; then
  release_wanted
  header
  echo "  To what UniFi Network Application version would you like to update?"
  echo -e "  Currently your UniFi Network Application is on version ${GRAY_R}$unifi${RESET}"
  echo -e "\\n  Release stage is set to | ${GRAY_R}${release_stage_friendly}${RESET}\\n\\n"
  echo -e " [   ${WHITE_R}1${RESET}   ]  |  5.6.40 ( UAP-AC, UAP-AC v2, UAP-AC-OD, PicoM2 )"
  echo -e " [   ${WHITE_R}2${RESET}   ]  |  5.6.42 ( UAP-AC, UAP-AC v2, UAP-AC-OD )"
  echo -e " [   ${WHITE_R}3${RESET}   ]  |  6.5.55"
  echo -e " [   ${WHITE_R}4${RESET}   ]  |  7.0.25"
  echo -e " [   ${WHITE_R}5${RESET}   ]  |  7.1.68"
  echo -e " [   ${WHITE_R}6${RESET}   ]  |  7.2.97"
  echo -e " [   ${WHITE_R}7${RESET}   ]  |  7.3.83"
  echo -e " [   ${WHITE_R}8${RESET}   ]  |  7.4.162"
  echo -e " [   ${WHITE_R}9${RESET}   ]  |  7.5.187"
  echo -e " [   ${WHITE_R}10${RESET}  ]  |  8.0.28"
  echo -e " [   ${WHITE_R}11${RESET}  ]  |  8.1.127"
  echo -e " [   ${WHITE_R}12${RESET}  ]  |  8.2.93"
  echo -e " [   ${WHITE_R}13${RESET}  ]  |  8.3.32"
  echo -e " [   ${WHITE_R}14${RESET}  ]  |  8.4.62"
  echo -e " [   ${WHITE_R}15${RESET}  ]  |  8.5.6"
  echo -e " [   ${WHITE_R}16${RESET}  ]  |  8.6.9"
  echo -e " [   ${WHITE_R}17${RESET}  ]  |  9.0.114"
  echo -e " [   ${WHITE_R}18${RESET}  ]  |  9.1.120"
  echo -e " [   ${WHITE_R}19${RESET}  ]  |  9.2.87"
  echo -e " [   ${WHITE_R}20${RESET}  ]  |  9.3.45"
  if [[ "${release_stage}" == 'RC' ]]; then
    echo -e " [   ${WHITE_R}21${RESET}  ]  |  ${rc_version_available}"
    echo -e " [   ${WHITE_R}22${RESET}  ]  |  Cancel\\n\\n"
  else
    echo -e " [   ${WHITE_R}21${RESET}  ]  |  Cancel\\n\\n"
  fi

  read -rp $'Your choice | \033[39m' UPGRADE_VERSION
  case "$UPGRADE_VERSION" in
      1)
        unifi_update_start
        unifi_firmware_requirement
        application_version="5.6.40"
        application_upgrade_releases
        unifi_update_finish;;
      2)
        unifi_update_start
        unifi_firmware_requirement
        application_version="5.6.42"
        application_upgrade_releases
        unifi_update_finish;;
      3)
        unifi_update_start
        unifi_firmware_requirement
        application_version="6.5.55"
        application_upgrade_releases
        unifi_update_finish;;
      4)
        unifi_update_start
        unifi_firmware_requirement
        application_version="7.0.25"
        application_upgrade_releases
        unifi_update_finish;;
      5)
        unifi_update_start
        unifi_firmware_requirement
        application_version="7.1.68-124045abd4"
        application_upgrade_releases
        unifi_update_finish;;
      6)
        unifi_update_start
        unifi_firmware_requirement
        application_version="7.2.97-fa3c0ace6e"
        application_upgrade_releases
        unifi_update_finish;;
      7)
        unifi_update_start
        unifi_firmware_requirement
        application_version="7.3.83-4501ffd244"
        application_upgrade_releases
        unifi_update_finish;;
      8)
        unifi_update_start
        unifi_firmware_requirement
        application_version="7.4.162-3116043f9f"
        application_upgrade_releases
        unifi_update_finish;;
      9)
        unifi_update_start
        unifi_firmware_requirement
        application_version="7.5.187-f57f5bf7ab"
        application_upgrade_releases
        unifi_update_finish;;
      10)
        unifi_update_start
        unifi_firmware_requirement
        application_version="8.0.28-66495b8e3a"
        application_upgrade_releases
        unifi_update_finish;;
      11)
        unifi_update_start
        unifi_firmware_requirement
        application_version="8.1.127-810cd1e59a"
        application_upgrade_releases
        unifi_update_finish;;
      12)
        unifi_update_start
        unifi_firmware_requirement
        application_version="8.2.93-1c329ecd26"
        application_upgrade_releases
        unifi_update_finish;;
      13)
        unifi_update_start
        unifi_firmware_requirement
        application_version="8.3.32-896f48ed11"
        application_upgrade_releases
        unifi_update_finish;;
      14)
        unifi_update_start
        unifi_firmware_requirement
        application_version="8.4.62-i3q2j125cz"
        application_upgrade_releases
        unifi_update_finish;;
      15)
        unifi_update_start
        unifi_firmware_requirement
        application_version="8.5.6-1x29lm155t"
        application_upgrade_releases
        unifi_update_finish;;
      16)
        unifi_update_start
        unifi_firmware_requirement
        application_version="8.6.9-0f45j609pu"
        application_upgrade_releases
        unifi_update_finish;;
      17)
        unifi_update_start
        unifi_firmware_requirement
        application_version="9.0.114-k5dy363g65"
        application_upgrade_releases
        unifi_update_finish;;
      18)
        unifi_update_start
        unifi_firmware_requirement
        application_version="9.1.120-e1aep1zs38"
        application_upgrade_releases
        unifi_update_finish;;
      19)
        unifi_update_start
        unifi_firmware_requirement
        application_version="9.2.87-uf39xch68k"
        application_upgrade_releases
        unifi_update_finish;;
      20)
        unifi_update_start
        unifi_firmware_requirement
        application_version="9.3.45-9iw96x349g"
        application_upgrade_releases
        unifi_update_finish;;
      21)
        if [[ "${release_stage}" == 'RC' ]]; then
          unifi_update_start
          unifi_firmware_requirement
          application_version="${rc_version_available_secret}"
          application_upgrade_releases
          unifi_update_finish
        else
          cancel_script
        fi;;
      22|*) cancel_script;;
  esac

##########################################################################################################################################################################
#                                                                                                                                                                        #
#                                                                                       5.6.x                                                                            #
#                                                                                                                                                                        #
##########################################################################################################################################################################

elif [[ "${first_digit_unifi}" == '5' && "${second_digit_unifi}" == '6' ]]; then
  release_wanted
  header
  echo "  To what UniFi Network Application version would you like to update?"
  echo -e "  Currently your UniFi Network Application is on version ${GRAY_R}$unifi${RESET}"
  echo -e "\\n  Release stage is set to | ${GRAY_R}${release_stage_friendly}${RESET}\\n\\n"
  if [[ "${unifi}" == "5.6.40" || "${unifi}" == "5.6.41" ]]; then
    unifi_version='5.6.40'
    echo -e " [   ${WHITE_R}1${RESET}   ]  |  5.6.42 ( UAP-AC, UAP-AC v2, UAP-AC-OD )"
    echo -e " [   ${WHITE_R}2${RESET}   ]  |  6.5.55"
    echo -e " [   ${WHITE_R}3${RESET}   ]  |  7.0.25"
    echo -e " [   ${WHITE_R}4${RESET}   ]  |  7.1.68"
    echo -e " [   ${WHITE_R}5${RESET}   ]  |  7.2.97"
    echo -e " [   ${WHITE_R}6${RESET}   ]  |  7.3.83"
    echo -e " [   ${WHITE_R}7${RESET}   ]  |  7.4.162"
    echo -e " [   ${WHITE_R}8${RESET}   ]  |  7.5.187"
    echo -e " [   ${WHITE_R}9${RESET}   ]  |  8.0.28"
    echo -e " [   ${WHITE_R}10${RESET}  ]  |  8.1.127"
    echo -e " [   ${WHITE_R}11${RESET}  ]  |  8.2.93"
    echo -e " [   ${WHITE_R}12${RESET}  ]  |  8.3.32"
    echo -e " [   ${WHITE_R}13${RESET}  ]  |  8.4.62"
    echo -e " [   ${WHITE_R}14${RESET}  ]  |  8.5.6"
    echo -e " [   ${WHITE_R}15${RESET}  ]  |  8.6.9"
    echo -e " [   ${WHITE_R}16${RESET}  ]  |  9.0.114"
    echo -e " [   ${WHITE_R}17${RESET}  ]  |  9.1.120"
    echo -e " [   ${WHITE_R}18${RESET}  ]  |  9.2.87"
    echo -e " [   ${WHITE_R}19${RESET}  ]  |  9.3.45"
    if [[ "${release_stage}" == 'RC' ]]; then
      echo -e " [   ${WHITE_R}20${RESET}  ]  |  ${rc_version_available}"
      echo -e " [   ${WHITE_R}21${RESET}  ]  |  Cancel\\n\\n"
    else
      echo -e " [   ${WHITE_R}20${RESET}  ]  |  Cancel\\n\\n"
    fi
  elif [[ "${unifi}" == "5.6.42" ]]; then
    unifi_version='5.6.42'
    echo -e " [   ${WHITE_R}1${RESET}   ]  |  6.5.55"
    echo -e " [   ${WHITE_R}2${RESET}   ]  |  7.0.25"
    echo -e " [   ${WHITE_R}3${RESET}   ]  |  7.1.68"
    echo -e " [   ${WHITE_R}4${RESET}   ]  |  7.2.97"
    echo -e " [   ${WHITE_R}5${RESET}   ]  |  7.3.83"
    echo -e " [   ${WHITE_R}6${RESET}   ]  |  7.4.162"
    echo -e " [   ${WHITE_R}7${RESET}   ]  |  7.5.187"
    echo -e " [   ${WHITE_R}8${RESET}   ]  |  8.0.28"
    echo -e " [   ${WHITE_R}9${RESET}   ]  |  8.1.127"
    echo -e " [   ${WHITE_R}10${RESET}  ]  |  8.2.93"
    echo -e " [   ${WHITE_R}11${RESET}  ]  |  8.3.32"
    echo -e " [   ${WHITE_R}12${RESET}  ]  |  8.4.62"
    echo -e " [   ${WHITE_R}13${RESET}  ]  |  8.5.6"
    echo -e " [   ${WHITE_R}14${RESET}  ]  |  8.6.9"
    echo -e " [   ${WHITE_R}15${RESET}  ]  |  9.0.114"
    echo -e " [   ${WHITE_R}16${RESET}  ]  |  9.1.120"
    echo -e " [   ${WHITE_R}17${RESET}  ]  |  9.2.87"
    echo -e " [   ${WHITE_R}18${RESET}  ]  |  9.3.45"
    if [[ "${release_stage}" == 'RC' ]]; then
      echo -e " [   ${WHITE_R}19${RESET}  ]  |  ${rc_version_available}"
      echo -e " [   ${WHITE_R}20${RESET}  ]  |  Cancel\\n\\n"
    else
      echo -e " [   ${WHITE_R}19${RESET}  ]  |  Cancel\\n\\n"
    fi
  else
    echo -e " [   ${WHITE_R}1${RESET}   ]  |  5.6.40 ( UAP-AC, UAP-AC v2, UAP-AC-OD, PicoM2 )"
    echo -e " [   ${WHITE_R}2${RESET}   ]  |  5.6.42 ( UAP-AC, UAP-AC v2, UAP-AC-OD )"
    echo -e " [   ${WHITE_R}3${RESET}   ]  |  6.5.55"
    echo -e " [   ${WHITE_R}4${RESET}   ]  |  7.0.25"
    echo -e " [   ${WHITE_R}5${RESET}   ]  |  7.1.68"
    echo -e " [   ${WHITE_R}6${RESET}   ]  |  7.2.97"
    echo -e " [   ${WHITE_R}7${RESET}   ]  |  7.3.83"
    echo -e " [   ${WHITE_R}8${RESET}   ]  |  7.4.162"
    echo -e " [   ${WHITE_R}9${RESET}   ]  |  7.5.187"
    echo -e " [   ${WHITE_R}10${RESET}  ]  |  8.0.28"
    echo -e " [   ${WHITE_R}11${RESET}  ]  |  8.1.127"
    echo -e " [   ${WHITE_R}12${RESET}  ]  |  8.2.93"
    echo -e " [   ${WHITE_R}13${RESET}  ]  |  8.3.32"
    echo -e " [   ${WHITE_R}14${RESET}  ]  |  8.4.62"
    echo -e " [   ${WHITE_R}15${RESET}  ]  |  8.5.6"
    echo -e " [   ${WHITE_R}16${RESET}  ]  |  8.6.9"
    echo -e " [   ${WHITE_R}17${RESET}  ]  |  9.0.114"
    echo -e " [   ${WHITE_R}18${RESET}  ]  |  9.1.120"
    echo -e " [   ${WHITE_R}19${RESET}  ]  |  9.2.87"
    echo -e " [   ${WHITE_R}20${RESET}  ]  |  9.3.45"
    if [[ "${release_stage}" == 'RC' ]]; then
      echo -e " [   ${WHITE_R}21${RESET}  ]  |  ${rc_version_available}"
      echo -e " [   ${WHITE_R}22${RESET}  ]  |  Cancel\\n\\n"
    else
      echo -e " [   ${WHITE_R}21${RESET}  ]  |  Cancel\\n\\n"
    fi
  fi

  if [[ "${unifi_version}" == "5.6.40" ]]; then
    read -rp $'Your choice | \033[39m' UPGRADE_VERSION
    case "$UPGRADE_VERSION" in
        1)
          unifi_update_start
          unifi_firmware_requirement
          application_version="5.6.42"
          application_upgrade_releases
          migration_check
          application_version="6.5.55"
          application_upgrade_releases
          unifi_update_finish;;
        2)
          unifi_update_start
          unifi_firmware_requirement
          application_version="5.6.42"
          application_upgrade_releases
          migration_check
          application_version="7.0.25"
          application_upgrade_releases
          unifi_update_finish;;
        3)
          unifi_update_start
          unifi_firmware_requirement
          application_version="5.6.42"
          application_upgrade_releases
          migration_check
          application_version="7.1.68-124045abd4"
          application_upgrade_releases
          unifi_update_finish;;
        4)
          unifi_update_start
          unifi_firmware_requirement
          application_version="5.6.42"
          application_upgrade_releases
          migration_check
          application_version="7.2.97-fa3c0ace6e"
          application_upgrade_releases
          unifi_update_finish;;
        5)
          unifi_update_start
          unifi_firmware_requirement
          application_version="5.6.42"
          application_upgrade_releases
          migration_check
          application_version="7.3.83-4501ffd244"
          application_upgrade_releases
          unifi_update_finish;;
        6)
          unifi_update_start
          unifi_firmware_requirement
          application_version="5.6.42"
          application_upgrade_releases
          migration_check
          application_version="7.4.162-3116043f9f"
          application_upgrade_releases
          unifi_update_finish;;
        7)
          unifi_update_start
          unifi_firmware_requirement
          application_version="5.6.42"
          application_upgrade_releases
          migration_check
          application_version="7.5.187-f57f5bf7ab"
          application_upgrade_releases
          unifi_update_finish;;
        8)
          unifi_update_start
          unifi_firmware_requirement
          application_version="5.6.42"
          application_upgrade_releases
          migration_check
          application_version="8.0.28-66495b8e3a"
          application_upgrade_releases
          unifi_update_finish;;
        10)
          unifi_update_start
          unifi_firmware_requirement
          application_version="5.6.42"
          application_upgrade_releases
          migration_check
          application_version="8.1.127-810cd1e59a"
          application_upgrade_releases
          unifi_update_finish;;
        11)
          unifi_update_start
          unifi_firmware_requirement
          application_version="5.6.42"
          application_upgrade_releases
          migration_check
          application_version="8.2.93-1c329ecd26"
          application_upgrade_releases
          unifi_update_finish;;
        12)
          unifi_update_start
          unifi_firmware_requirement
          application_version="5.6.42"
          application_upgrade_releases
          migration_check
          application_version="8.3.32-896f48ed11"
          application_upgrade_releases
          unifi_update_finish;;
        13)
          unifi_update_start
          unifi_firmware_requirement
          application_version="5.6.42"
          application_upgrade_releases
          migration_check
          application_version="8.4.62-i3q2j125cz"
          application_upgrade_releases
          unifi_update_finish;;
        14)
          unifi_update_start
          unifi_firmware_requirement
          application_version="5.6.42"
          application_upgrade_releases
          migration_check
          application_version="8.5.6-1x29lm155t"
          application_upgrade_releases
          unifi_update_finish;;
        15)
          unifi_update_start
          unifi_firmware_requirement
          application_version="5.6.42"
          application_upgrade_releases
          migration_check
          application_version="8.6.9-0f45j609pu"
          application_upgrade_releases
          unifi_update_finish;;
        16)
          unifi_update_start
          unifi_firmware_requirement
          application_version="5.6.42"
          application_upgrade_releases
          migration_check
          application_version="9.0.114-k5dy363g65"
          application_upgrade_releases
          unifi_update_finish;;
        17)
          unifi_update_start
          unifi_firmware_requirement
          application_version="5.6.42"
          application_upgrade_releases
          migration_check
          application_version="9.1.120-e1aep1zs38"
          application_upgrade_releases
          unifi_update_finish;;
        18)
          unifi_update_start
          unifi_firmware_requirement
          application_version="5.6.42"
          application_upgrade_releases
          migration_check
          application_version="9.2.87-uf39xch68k"
          application_upgrade_releases
          unifi_update_finish;;
        19)
          unifi_update_start
          unifi_firmware_requirement
          application_version="5.6.42"
          application_upgrade_releases
          migration_check
          application_version="9.3.45-9iw96x349g"
          application_upgrade_releases
          unifi_update_finish;;
        20)
          if [[ "${release_stage}" == 'RC' ]]; then
            unifi_update_start
            unifi_firmware_requirement
            application_version="5.6.42"
            application_upgrade_releases
            migration_check
            application_version="${rc_version_available_secret}"
            application_upgrade_releases
            unifi_update_finish
          else
            cancel_script
          fi;;
        21|*) cancel_script;;
    esac
  elif [[ "${unifi_version}" == "5.6.42" ]]; then
    read -rp $'Your choice | \033[39m' UPGRADE_VERSION
    case "$UPGRADE_VERSION" in
        1)
          unifi_update_start
          unifi_firmware_requirement
          application_version="6.5.55"
          application_upgrade_releases
          unifi_update_finish;;
        2)
          unifi_update_start
          unifi_firmware_requirement
          application_version="7.0.25"
          application_upgrade_releases
          unifi_update_finish;;
        3)
          unifi_update_start
          unifi_firmware_requirement
          application_version="7.1.68-124045abd4"
          application_upgrade_releases
          unifi_update_finish;;
        4)
          unifi_update_start
          unifi_firmware_requirement
          application_version="7.2.97-fa3c0ace6e"
          application_upgrade_releases
          unifi_update_finish;;
        5)
          unifi_update_start
          unifi_firmware_requirement
          application_version="7.3.83-4501ffd244"
          application_upgrade_releases
          unifi_update_finish;;
        6)
          unifi_update_start
          unifi_firmware_requirement
          application_version="7.4.162-3116043f9f"
          application_upgrade_releases
          unifi_update_finish;;
        7)
          unifi_update_start
          unifi_firmware_requirement
          application_version="7.5.187-f57f5bf7ab"
          application_upgrade_releases
          unifi_update_finish;;
        8)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.0.28-66495b8e3a"
          application_upgrade_releases
          unifi_update_finish;;
        9)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.1.127-810cd1e59a"
          application_upgrade_releases
          unifi_update_finish;;
        10)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.2.93-1c329ecd26"
          application_upgrade_releases
          unifi_update_finish;;
        11)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.3.32-896f48ed11"
          application_upgrade_releases
          unifi_update_finish;;
        12)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.4.62-i3q2j125cz"
          application_upgrade_releases
          unifi_update_finish;;
        13)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.5.6-1x29lm155t"
          application_upgrade_releases
          unifi_update_finish;;
        14)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.6.9-0f45j609pu"
          application_upgrade_releases
          unifi_update_finish;;
        15)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.0.114-k5dy363g65"
          application_upgrade_releases
          unifi_update_finish;;
        16)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.1.120-e1aep1zs38"
          application_upgrade_releases
          unifi_update_finish;;
        17)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.2.87-uf39xch68k"
          application_upgrade_releases
          unifi_update_finish;;
        18)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.3.45-9iw96x349g"
          application_upgrade_releases
          unifi_update_finish;;
        19)
          if [[ "${release_stage}" == 'RC' ]]; then
            unifi_update_start
            application_version="${rc_version_available_secret}"
            application_upgrade_releases
            unifi_update_finish
          else
            cancel_script
          fi;;
        20|*) cancel_script;;
    esac
  else
    read -rp $'Your choice | \033[39m' UPGRADE_VERSION
    case "$UPGRADE_VERSION" in
        1)
          unifi_update_start
          unifi_firmware_requirement
          application_version="5.6.40"
          application_upgrade_releases
          unifi_update_finish;;
        2)
          unifi_update_start
          unifi_firmware_requirement
          application_version="5.6.42"
          application_upgrade_releases
          unifi_update_finish;;
        3)
          unifi_update_start
          unifi_firmware_requirement
          application_version="6.5.55"
          application_upgrade_releases
          unifi_update_finish;;
        4)
          unifi_update_start
          unifi_firmware_requirement
          application_version="7.0.25"
          application_upgrade_releases
          unifi_update_finish;;
        5)
          unifi_update_start
          unifi_firmware_requirement
          application_version="7.1.68-124045abd4"
          application_upgrade_releases
          unifi_update_finish;;
        6)
          unifi_update_start
          unifi_firmware_requirement
          application_version="7.2.97-fa3c0ace6e"
          application_upgrade_releases
          unifi_update_finish;;
        7)
          unifi_update_start
          unifi_firmware_requirement
          application_version="7.3.83-4501ffd244"
          application_upgrade_releases
          unifi_update_finish;;
        8)
          unifi_update_start
          unifi_firmware_requirement
          application_version="7.4.162-3116043f9f"
          application_upgrade_releases
          unifi_update_finish;;
        9)
          unifi_update_start
          unifi_firmware_requirement
          application_version="7.5.187-f57f5bf7ab"
          application_upgrade_releases
          unifi_update_finish;;
        10)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.0.28-66495b8e3a"
          application_upgrade_releases
          unifi_update_finish;;
        11)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.1.127-810cd1e59a"
          application_upgrade_releases
          unifi_update_finish;;
        12)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.2.93-1c329ecd26"
          application_upgrade_releases
          unifi_update_finish;;
        13)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.3.32-896f48ed11"
          application_upgrade_releases
          unifi_update_finish;;
        14)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.4.62-i3q2j125cz"
          application_upgrade_releases
          unifi_update_finish;;
        15)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.5.6-1x29lm155t"
          application_upgrade_releases
          unifi_update_finish;;
        16)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.6.9-0f45j609pu"
          application_upgrade_releases
          unifi_update_finish;;
        17)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.0.114-k5dy363g65"
          application_upgrade_releases
          unifi_update_finish;;
        18)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.1.120-e1aep1zs38"
          application_upgrade_releases
          unifi_update_finish;;
        19)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.2.87-uf39xch68k"
          application_upgrade_releases
          unifi_update_finish;;
        20)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.3.45-9iw96x349g"
          application_upgrade_releases
          unifi_update_finish;;
        21)
          if [[ "${release_stage}" == 'RC' ]]; then
            unifi_update_start
            unifi_firmware_requirement
            application_version="${rc_version_available_secret}"
            application_upgrade_releases
            unifi_update_finish
          else
            cancel_script
          fi;;
        22|*) cancel_script;;
    esac
  fi

##########################################################################################################################################################################
#                                                                                                                                                                        #
#                                                     5.7.x | 5.8.x | 5.9.x | 6.0.x | 6.1.x | 6.2.x | 6.3.x | 6.4.x                                                      #
#                                                                                                                                                                        #
##########################################################################################################################################################################

elif [[ "${first_digit_unifi}" == '5' && "${second_digit_unifi}" =~ ^(7|8|9|10|11|12|13|14)$ ]] || [[ "${first_digit_unifi}" == '6' && "${second_digit_unifi}" =~ ^(0|1|2|3|4)$ ]]; then
  release_wanted
  header
  echo "  To what UniFi Network Application version would you like to update?"
  echo -e "  Currently your UniFi Network Application is on version ${GRAY_R}$unifi${RESET}"
  echo -e "\\n  Release stage is set to | ${GRAY_R}${release_stage_friendly}${RESET}\\n\\n"
  echo -e " [   ${WHITE_R}1${RESET}   ]  |  6.5.55"
  echo -e " [   ${WHITE_R}2${RESET}   ]  |  7.0.25"
  echo -e " [   ${WHITE_R}3${RESET}   ]  |  7.1.68"
  echo -e " [   ${WHITE_R}4${RESET}   ]  |  7.2.97"
  echo -e " [   ${WHITE_R}5${RESET}   ]  |  7.3.83"
  echo -e " [   ${WHITE_R}6${RESET}   ]  |  7.4.162"
  echo -e " [   ${WHITE_R}7${RESET}   ]  |  7.5.187"
  echo -e " [   ${WHITE_R}8${RESET}   ]  |  8.0.28"
  echo -e " [   ${WHITE_R}9${RESET}   ]  |  8.1.127"
  echo -e " [   ${WHITE_R}10${RESET}  ]  |  8.2.93"
  echo -e " [   ${WHITE_R}11${RESET}  ]  |  8.3.32"
  echo -e " [   ${WHITE_R}12${RESET}  ]  |  8.4.62"
  echo -e " [   ${WHITE_R}13${RESET}  ]  |  8.5.6"
  echo -e " [   ${WHITE_R}14${RESET}  ]  |  8.6.9"
  echo -e " [   ${WHITE_R}15${RESET}  ]  |  9.0.114"
  echo -e " [   ${WHITE_R}16${RESET}  ]  |  9.1.120"
  echo -e " [   ${WHITE_R}17${RESET}  ]  |  9.2.87"
  echo -e " [   ${WHITE_R}18${RESET}  ]  |  9.3.45"
  if [[ "${release_stage}" == 'RC' ]]; then
    echo -e " [   ${WHITE_R}19${RESET}  ]  |  ${rc_version_available}"
    echo -e " [   ${WHITE_R}20${RESET}  ]  |  Cancel\\n\\n"
  else
    echo -e " [   ${WHITE_R}19${RESET}  ]  |  Cancel\\n\\n"
  fi

  read -rp $'Your choice | \033[39m' UPGRADE_VERSION
  case "$UPGRADE_VERSION" in
      1)
        unifi_update_start
        unifi_firmware_requirement
        application_version="6.5.55"
        application_upgrade_releases
        unifi_update_finish;;
      2)
        unifi_update_start
        unifi_firmware_requirement
        application_version="7.0.25"
        application_upgrade_releases
        unifi_update_finish;;
      3)
        unifi_update_start
        unifi_firmware_requirement
        application_version="7.1.68-124045abd4"
        application_upgrade_releases
        unifi_update_finish;;
      4)
        unifi_update_start
        unifi_firmware_requirement
        application_version="7.2.97-fa3c0ace6e"
        application_upgrade_releases
        unifi_update_finish;;
      5)
        unifi_update_start
        unifi_firmware_requirement
        application_version="7.3.83-4501ffd244"
        application_upgrade_releases
        unifi_update_finish;;
      6)
        unifi_update_start
        unifi_firmware_requirement
        application_version="7.4.162-3116043f9f"
        application_upgrade_releases
        unifi_update_finish;;
      7)
        unifi_update_start
        unifi_firmware_requirement
        application_version="7.5.187-f57f5bf7ab"
        application_upgrade_releases
        unifi_update_finish;;
      8)
        unifi_update_start
        unifi_firmware_requirement
        application_version="8.0.28-66495b8e3a"
        application_upgrade_releases
        unifi_update_finish;;
      9)
        unifi_update_start
        unifi_firmware_requirement
        application_version="8.1.127-810cd1e59a"
        application_upgrade_releases
        unifi_update_finish;;
      10)
        unifi_update_start
        unifi_firmware_requirement
        application_version="8.2.93-1c329ecd26"
        application_upgrade_releases
        unifi_update_finish;;
      11)
        unifi_update_start
        unifi_firmware_requirement
        application_version="8.2.93-1c329ecd26"
        application_upgrade_releases
        unifi_update_finish;;
      12)
        unifi_update_start
        unifi_firmware_requirement
        application_version="8.4.62-i3q2j125cz"
        application_upgrade_releases
        unifi_update_finish;;
      13)
        unifi_update_start
        unifi_firmware_requirement
        application_version="8.5.6-1x29lm155t"
        application_upgrade_releases
        unifi_update_finish;;
      14)
        unifi_update_start
        unifi_firmware_requirement
        application_version="8.6.9-0f45j609pu"
         application_upgrade_releases
        unifi_update_finish;;
      15)
        unifi_update_start
        unifi_firmware_requirement
        application_version="9.0.114-k5dy363g65"
        application_upgrade_releases
        unifi_update_finish;;
      16)
        unifi_update_start
        unifi_firmware_requirement
        application_version="9.1.120-e1aep1zs38"
        application_upgrade_releases
        unifi_update_finish;;
      17)
        unifi_update_start
        unifi_firmware_requirement
        application_version="9.2.87-uf39xch68k"
        application_upgrade_releases
        unifi_update_finish;;
      18)
        unifi_update_start
        unifi_firmware_requirement
        application_version="9.3.45-9iw96x349g"
        application_upgrade_releases
        unifi_update_finish;;
      19)
        if [[ "${release_stage}" == 'RC' ]]; then
          unifi_update_start
          unifi_firmware_requirement
          application_version="${rc_version_available_secret}"
          application_upgrade_releases
          unifi_update_finish
        else
          cancel_script
        fi;;
      20|*) cancel_script;;
  esac

##########################################################################################################################################################################
#                                                                                                                                                                        #
#                                                                                  6.5.x                                                                                 #
#                                                                                                                                                                        #
##########################################################################################################################################################################

elif [[ "${first_digit_unifi}" == '6' && "${second_digit_unifi}" == '5' ]]; then
  release_wanted
  header
  echo "  To what UniFi Network Application version would you like to update?"
  echo -e "  Currently your UniFi Network Application is on version ${GRAY_R}$unifi${RESET}"
  echo -e "\\n  Release stage is set to | ${GRAY_R}${release_stage_friendly}${RESET}\\n\\n"
  if [[ "${unifi}" == "6.5.55" ]]; then
    unifi_version='6.5.55'
    echo -e " [   ${WHITE_R}1${RESET}   ]  |  7.0.25"
    echo -e " [   ${WHITE_R}2${RESET}   ]  |  7.1.68"
    echo -e " [   ${WHITE_R}3${RESET}   ]  |  7.2.97"
    echo -e " [   ${WHITE_R}4${RESET}   ]  |  7.3.83"
    echo -e " [   ${WHITE_R}5${RESET}   ]  |  7.4.162"
    echo -e " [   ${WHITE_R}6${RESET}   ]  |  7.5.187"
    echo -e " [   ${WHITE_R}7${RESET}   ]  |  8.0.28"
    echo -e " [   ${WHITE_R}8${RESET}   ]  |  8.1.127"
    echo -e " [   ${WHITE_R}9${RESET}   ]  |  8.2.93"
    echo -e " [   ${WHITE_R}10${RESET}  ]  |  8.3.32"
    echo -e " [   ${WHITE_R}11${RESET}  ]  |  8.4.62"
    echo -e " [   ${WHITE_R}12${RESET}  ]  |  8.5.6"
    echo -e " [   ${WHITE_R}13${RESET}  ]  |  8.6.9"
    echo -e " [   ${WHITE_R}14${RESET}  ]  |  9.0.114"
    echo -e " [   ${WHITE_R}15${RESET}  ]  |  9.1.120"
    echo -e " [   ${WHITE_R}16${RESET}  ]  |  9.2.87"
    echo -e " [   ${WHITE_R}17${RESET}  ]  |  9.3.45"
    if [[ "${release_stage}" == 'RC' ]]; then
      echo -e " [   ${WHITE_R}18${RESET}  ]  |  ${rc_version_available}"
      echo -e " [   ${WHITE_R}19${RESET}  ]  |  Cancel\\n\\n"
    else
      echo -e " [   ${WHITE_R}18${RESET}  ]  |  Cancel\\n\\n"
    fi
  else
    echo -e " [   ${WHITE_R}1${RESET}   ]  |  6.5.55"
    echo -e " [   ${WHITE_R}2${RESET}   ]  |  7.0.25"
    echo -e " [   ${WHITE_R}3${RESET}   ]  |  7.1.68"
    echo -e " [   ${WHITE_R}4${RESET}   ]  |  7.2.97"
    echo -e " [   ${WHITE_R}5${RESET}   ]  |  7.3.83"
    echo -e " [   ${WHITE_R}6${RESET}   ]  |  7.4.162"
    echo -e " [   ${WHITE_R}7${RESET}   ]  |  7.5.187"
    echo -e " [   ${WHITE_R}8${RESET}   ]  |  8.0.28"
    echo -e " [   ${WHITE_R}9${RESET}   ]  |  8.1.127"
    echo -e " [   ${WHITE_R}10${RESET}  ]  |  8.2.93"
    echo -e " [   ${WHITE_R}11${RESET}  ]  |  8.3.32"
    echo -e " [   ${WHITE_R}12${RESET}  ]  |  8.4.62"
    echo -e " [   ${WHITE_R}13${RESET}  ]  |  8.5.6"
    echo -e " [   ${WHITE_R}14${RESET}  ]  |  8.6.9"
    echo -e " [   ${WHITE_R}15${RESET}  ]  |  9.0.114"
    echo -e " [   ${WHITE_R}16${RESET}  ]  |  9.1.120"
    echo -e " [   ${WHITE_R}17${RESET}  ]  |  9.2.87"
    echo -e " [   ${WHITE_R}18${RESET}  ]  |  9.3.45"
    if [[ "${release_stage}" == 'RC' ]]; then
      echo -e " [   ${WHITE_R}19${RESET}  ]  |  ${rc_version_available}"
      echo -e " [   ${WHITE_R}20${RESET}  ]  |  Cancel\\n\\n"
    else
      echo -e " [   ${WHITE_R}19${RESET}  ]  |  Cancel\\n\\n"
    fi
  fi

  if [[ "${unifi_version}" == "6.5.55" ]]; then
    read -rp $'Your choice | \033[39m' UPGRADE_VERSION
    case "$UPGRADE_VERSION" in
        1)
          unifi_update_start
          unifi_firmware_requirement
          application_version="7.0.25"
          application_upgrade_releases
          unifi_update_finish;;
        2)
          unifi_update_start
          unifi_firmware_requirement
          application_version="7.1.68-124045abd4"
          application_upgrade_releases
          unifi_update_finish;;
        3)
          unifi_update_start
          unifi_firmware_requirement
          application_version="7.2.97-fa3c0ace6e"
          application_upgrade_releases
          unifi_update_finish;;
        4)
          unifi_update_start
          unifi_firmware_requirement
          application_version="7.3.83-4501ffd244"
          application_upgrade_releases
          unifi_update_finish;;
        5)
          unifi_update_start
          unifi_firmware_requirement
          application_version="7.4.162-3116043f9f"
          application_upgrade_releases
          unifi_update_finish;;
        6)
          unifi_update_start
          unifi_firmware_requirement
          application_version="7.5.187-f57f5bf7ab"
          application_upgrade_releases
          unifi_update_finish;;
        7)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.0.28-66495b8e3a"
          application_upgrade_releases
          unifi_update_finish;;
        8)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.1.127-810cd1e59a"
          application_upgrade_releases
          unifi_update_finish;;
        9)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.2.93-1c329ecd26"
          application_upgrade_releases
          unifi_update_finish;;
        10)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.3.32-896f48ed11"
          application_upgrade_releases
          unifi_update_finish;;
        11)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.4.62-i3q2j125cz"
          application_upgrade_releases
          unifi_update_finish;;
        12)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.5.6-1x29lm155t"
          application_upgrade_releases
          unifi_update_finish;;
        13)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.6.9-0f45j609pu"
          application_upgrade_releases
          unifi_update_finish;;
        14)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.0.114-k5dy363g65"
          application_upgrade_releases
          unifi_update_finish;;
        15)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.1.120-e1aep1zs38"
          application_upgrade_releases
          unifi_update_finish;;
        16)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.2.87-uf39xch68k"
          application_upgrade_releases
          unifi_update_finish;;
        17)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.3.45-9iw96x349g"
          application_upgrade_releases
          unifi_update_finish;;
        18)
          if [[ "${release_stage}" == 'RC' ]]; then
            unifi_update_start
            unifi_firmware_requirement
            application_version="${rc_version_available_secret}"
            application_upgrade_releases
            unifi_update_finish
          else
            cancel_script
          fi;;
        19|*) cancel_script;;
    esac
  else
    read -rp $'Your choice | \033[39m' UPGRADE_VERSION
    case "$UPGRADE_VERSION" in
        1)
          unifi_update_start
          unifi_firmware_requirement
          application_version="6.5.55"
          application_upgrade_releases
          unifi_update_finish;;
        2)
          unifi_update_start
          unifi_firmware_requirement
          application_version="7.0.25"
          application_upgrade_releases
          unifi_update_finish;;
        3)
          unifi_update_start
          unifi_firmware_requirement
          application_version="7.1.68-124045abd4"
          application_upgrade_releases
          unifi_update_finish;;
        4)
          unifi_update_start
          unifi_firmware_requirement
          application_version="7.2.97-fa3c0ace6e"
          application_upgrade_releases
          unifi_update_finish;;
        5)
          unifi_update_start
          unifi_firmware_requirement
          application_version="7.3.83-4501ffd244"
          application_upgrade_releases
          unifi_update_finish;;
        6)
          unifi_update_start
          unifi_firmware_requirement
          application_version="7.4.162-3116043f9f"
          application_upgrade_releases
          unifi_update_finish;;
        7)
          unifi_update_start
          unifi_firmware_requirement
          application_version="7.5.187-f57f5bf7ab"
          application_upgrade_releases
          unifi_update_finish;;
        8)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.0.28-66495b8e3a"
          application_upgrade_releases
          unifi_update_finish;;
        9)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.1.127-810cd1e59a"
          application_upgrade_releases
          unifi_update_finish;;
        10)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.2.93-1c329ecd26"
          application_upgrade_releases
          unifi_update_finish;;
        11)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.3.32-896f48ed11"
          application_upgrade_releases
          unifi_update_finish;;
        12)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.4.62-i3q2j125cz"
          application_upgrade_releases
          unifi_update_finish;;
        13)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.5.6-1x29lm155t"
          application_upgrade_releases
          unifi_update_finish;;
        14)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.6.9-0f45j609pu"
          application_upgrade_releases
          unifi_update_finish;;
        15)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.0.114-k5dy363g65"
          application_upgrade_releases
          unifi_update_finish;;
        16)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.1.120-e1aep1zs38"
          application_upgrade_releases
          unifi_update_finish;;
        17)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.2.87-uf39xch68k"
          application_upgrade_releases
          unifi_update_finish;;
        18)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.3.45-9iw96x349g"
          application_upgrade_releases
          unifi_update_finish;;
        19)
          if [[ "${release_stage}" == 'RC' ]]; then
            unifi_update_start
            unifi_firmware_requirement
            application_version="${rc_version_available_secret}"
            application_upgrade_releases
            unifi_update_finish
          else
            cancel_script
          fi;;
        20|*) cancel_script;;
    esac
  fi

##########################################################################################################################################################################
#                                                                                                                                                                        #
#                                                                                  7.0.x                                                                                 #
#                                                                                                                                                                        #
##########################################################################################################################################################################

elif [[ "${first_digit_unifi}" == '7' && "${second_digit_unifi}" == '0' ]]; then
  release_wanted
  header
  echo "  To what UniFi Network Application version would you like to update?"
  echo -e "  Currently your UniFi Network Application is on version ${GRAY_R}$unifi${RESET}"
  echo -e "\\n  Release stage is set to | ${GRAY_R}${release_stage_friendly}${RESET}\\n\\n"
  if [[ "${unifi}" == "7.0.25" ]]; then
    unifi_version='7.0.25'
    echo -e " [   ${WHITE_R}1${RESET}   ]  |  7.1.68"
    echo -e " [   ${WHITE_R}2${RESET}   ]  |  7.2.97"
    echo -e " [   ${WHITE_R}3${RESET}   ]  |  7.3.83"
    echo -e " [   ${WHITE_R}4${RESET}   ]  |  7.4.162"
    echo -e " [   ${WHITE_R}5${RESET}   ]  |  7.5.187"
    echo -e " [   ${WHITE_R}6${RESET}   ]  |  8.0.28"
    echo -e " [   ${WHITE_R}7${RESET}   ]  |  8.1.127"
    echo -e " [   ${WHITE_R}8${RESET}   ]  |  8.2.93"
    echo -e " [   ${WHITE_R}9${RESET}   ]  |  8.3.32"
    echo -e " [   ${WHITE_R}10${RESET}  ]  |  8.4.62"
    echo -e " [   ${WHITE_R}11${RESET}  ]  |  8.5.6"
    echo -e " [   ${WHITE_R}12${RESET}  ]  |  8.6.9"
    echo -e " [   ${WHITE_R}13${RESET}  ]  |  9.0.114"
    echo -e " [   ${WHITE_R}14${RESET}  ]  |  9.1.120"
    echo -e " [   ${WHITE_R}15${RESET}  ]  |  9.2.87"
    echo -e " [   ${WHITE_R}16${RESET}  ]  |  9.3.45"
    if [[ "${release_stage}" == 'RC' ]]; then
      echo -e " [   ${WHITE_R}16${RESET}  ]  |  ${rc_version_available}"
      echo -e " [   ${WHITE_R}17${RESET}  ]  |  Cancel\\n\\n"
    else
      echo -e " [   ${WHITE_R}16${RESET}  ]  |  Cancel\\n\\n"
    fi
  else
    echo -e " [   ${WHITE_R}1${RESET}   ]  |  7.0.25"
    echo -e " [   ${WHITE_R}2${RESET}   ]  |  7.1.68"
    echo -e " [   ${WHITE_R}3${RESET}   ]  |  7.2.97"
    echo -e " [   ${WHITE_R}4${RESET}   ]  |  7.3.83"
    echo -e " [   ${WHITE_R}5${RESET}   ]  |  7.4.162"
    echo -e " [   ${WHITE_R}6${RESET}   ]  |  7.5.187"
    echo -e " [   ${WHITE_R}7${RESET}   ]  |  8.0.28"
    echo -e " [   ${WHITE_R}8${RESET}   ]  |  8.1.127"
    echo -e " [   ${WHITE_R}9${RESET}   ]  |  8.2.93"
    echo -e " [   ${WHITE_R}10${RESET}  ]  |  8.3.32"
    echo -e " [   ${WHITE_R}11${RESET}  ]  |  8.4.62"
    echo -e " [   ${WHITE_R}12${RESET}  ]  |  8.5.6"
    echo -e " [   ${WHITE_R}13${RESET}  ]  |  8.6.9"
    echo -e " [   ${WHITE_R}14${RESET}  ]  |  9.0.114"
    echo -e " [   ${WHITE_R}15${RESET}  ]  |  9.1.120"
    echo -e " [   ${WHITE_R}16${RESET}  ]  |  9.2.87"
    echo -e " [   ${WHITE_R}17${RESET}  ]  |  9.3.45"
    if [[ "${release_stage}" == 'RC' ]]; then
      echo -e " [   ${WHITE_R}18${RESET}  ]  |  ${rc_version_available}"
      echo -e " [   ${WHITE_R}19${RESET}  ]  |  Cancel\\n\\n"
    else
      echo -e " [   ${WHITE_R}18${RESET}  ]  |  Cancel\\n\\n"
    fi
  fi

  if [[ "${unifi_version}" == "7.0.25" ]]; then
    read -rp $'Your choice | \033[39m' UPGRADE_VERSION
    case "$UPGRADE_VERSION" in
        1)
          unifi_update_start
          unifi_firmware_requirement
          application_version="7.1.68-124045abd4"
          application_upgrade_releases
          unifi_update_finish;;
        2)
          unifi_update_start
          unifi_firmware_requirement
          application_version="7.2.97-fa3c0ace6e"
          application_upgrade_releases
          unifi_update_finish;;
        3)
          unifi_update_start
          unifi_firmware_requirement
          application_version="7.3.83-4501ffd244"
          application_upgrade_releases
          unifi_update_finish;;
        4)
          unifi_update_start
          unifi_firmware_requirement
          application_version="7.4.162-3116043f9f"
          application_upgrade_releases
          unifi_update_finish;;
        5)
          unifi_update_start
          unifi_firmware_requirement
          application_version="7.5.187-f57f5bf7ab"
          application_upgrade_releases
          unifi_update_finish;;
        6)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.0.28-66495b8e3a"
          application_upgrade_releases
          unifi_update_finish;;
        7)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.1.127-810cd1e59a"
          application_upgrade_releases
          unifi_update_finish;;
        8)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.2.93-1c329ecd26"
          application_upgrade_releases
          unifi_update_finish;;
        9)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.3.32-896f48ed11"
          application_upgrade_releases
          unifi_update_finish;;
        10)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.4.62-i3q2j125cz"
          application_upgrade_releases
          unifi_update_finish;;
        11)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.5.6-1x29lm155t"
          application_upgrade_releases
          unifi_update_finish;;
        12)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.6.9-0f45j609pu"
          application_upgrade_releases
          unifi_update_finish;;
        13)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.0.114-k5dy363g65"
          application_upgrade_releases
          unifi_update_finish;;
        14)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.1.120-e1aep1zs38"
          application_upgrade_releases
          unifi_update_finish;;
        15)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.2.87-uf39xch68k"
          application_upgrade_releases
          unifi_update_finish;;
        16)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.3.45-9iw96x349g"
          application_upgrade_releases
          unifi_update_finish;;
        17)
          if [[ "${release_stage}" == 'RC' ]]; then
            unifi_update_start
            unifi_firmware_requirement
            application_version="${rc_version_available_secret}"
            application_upgrade_releases
            unifi_update_finish
          else
            cancel_script
          fi;;
        18|*) cancel_script;;
    esac
  else
    read -rp $'Your choice | \033[39m' UPGRADE_VERSION
    case "$UPGRADE_VERSION" in
        1)
          unifi_update_start
          unifi_firmware_requirement
          application_version="7.0.25"
          application_upgrade_releases
          unifi_update_finish;;
        2)
          unifi_update_start
          unifi_firmware_requirement
          application_version="7.1.68-124045abd4"
          application_upgrade_releases
          unifi_update_finish;;
        3)
          unifi_update_start
          unifi_firmware_requirement
          application_version="7.2.97-fa3c0ace6e"
          application_upgrade_releases
          unifi_update_finish;;
        4)
          unifi_update_start
          unifi_firmware_requirement
          application_version="7.3.83-4501ffd244"
          application_upgrade_releases
          unifi_update_finish;;
        5)
          unifi_update_start
          unifi_firmware_requirement
          application_version="7.4.162-3116043f9f"
          application_upgrade_releases
          unifi_update_finish;;
        6)
          unifi_update_start
          unifi_firmware_requirement
          application_version="7.5.187-f57f5bf7ab"
          application_upgrade_releases
          unifi_update_finish;;
        7)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.0.28-66495b8e3a"
          application_upgrade_releases
          unifi_update_finish;;
        8)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.1.127-810cd1e59a"
          application_upgrade_releases
          unifi_update_finish;;
        9)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.2.93-1c329ecd26"
          application_upgrade_releases
          unifi_update_finish;;
        10)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.3.32-896f48ed11"
          application_upgrade_releases
          unifi_update_finish;;
        11)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.4.62-i3q2j125cz"
          application_upgrade_releases
          unifi_update_finish;;
        12)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.5.6-1x29lm155t"
          application_upgrade_releases
          unifi_update_finish;;
        13)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.6.9-0f45j609pu"
          application_upgrade_releases
          unifi_update_finish;;
        14)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.0.114-k5dy363g65"
          application_upgrade_releases
          unifi_update_finish;;
        15)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.1.120-e1aep1zs38"
          application_upgrade_releases
          unifi_update_finish;;
        16)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.2.87-uf39xch68k"
          application_upgrade_releases
          unifi_update_finish;;
        17)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.3.45-9iw96x349g"
          application_upgrade_releases
          unifi_update_finish;;
        18)
          if [[ "${release_stage}" == 'RC' ]]; then
            unifi_update_start
            unifi_firmware_requirement
            application_version="${rc_version_available_secret}"
            application_upgrade_releases
            unifi_update_finish
          else
            cancel_script
          fi;;
        19|*) cancel_script;;
    esac
  fi

##########################################################################################################################################################################
#                                                                                                                                                                        #
#                                                                                  7.1.x                                                                                 #
#                                                                                                                                                                        #
##########################################################################################################################################################################

elif [[ "${first_digit_unifi}" == '7' && "${second_digit_unifi}" == '1' ]]; then
  release_wanted
  header
  echo "  To what UniFi Network Application version would you like to update?"
  echo -e "  Currently your UniFi Network Application is on version ${GRAY_R}$unifi${RESET}"
  echo -e "\\n  Release stage is set to | ${GRAY_R}${release_stage_friendly}${RESET}\\n\\n"
  if [[ "${unifi}" == "7.1.68" ]]; then
    unifi_version='7.1.68'
    echo -e " [   ${WHITE_R}1${RESET}   ]  |  7.2.97"
    echo -e " [   ${WHITE_R}2${RESET}   ]  |  7.3.83"
    echo -e " [   ${WHITE_R}3${RESET}   ]  |  7.4.162"
    echo -e " [   ${WHITE_R}4${RESET}   ]  |  7.5.187"
    echo -e " [   ${WHITE_R}5${RESET}   ]  |  8.0.28"
    echo -e " [   ${WHITE_R}6${RESET}   ]  |  8.1.127"
    echo -e " [   ${WHITE_R}7${RESET}   ]  |  8.2.93"
    echo -e " [   ${WHITE_R}8${RESET}   ]  |  8.3.32"
    echo -e " [   ${WHITE_R}9${RESET}   ]  |  8.4.62"
    echo -e " [   ${WHITE_R}10${RESET}  ]  |  8.5.6"
    echo -e " [   ${WHITE_R}11${RESET}  ]  |  8.6.9"
    echo -e " [   ${WHITE_R}12${RESET}  ]  |  9.0.114"
    echo -e " [   ${WHITE_R}13${RESET}  ]  |  9.1.120"
    echo -e " [   ${WHITE_R}14${RESET}  ]  |  9.2.87"
    echo -e " [   ${WHITE_R}15${RESET}  ]  |  9.3.45"
    if [[ "${release_stage}" == 'RC' ]]; then
      echo -e " [   ${WHITE_R}16${RESET}  ]  |  ${rc_version_available}"
      echo -e " [   ${WHITE_R}17${RESET}  ]  |  Cancel\\n\\n"
    else
      echo -e " [   ${WHITE_R}16${RESET}  ]  |  Cancel\\n\\n"
    fi
  else
    echo -e " [   ${WHITE_R}1${RESET}   ]  |  7.1.68"
    echo -e " [   ${WHITE_R}2${RESET}   ]  |  7.2.97"
    echo -e " [   ${WHITE_R}3${RESET}   ]  |  7.3.83"
    echo -e " [   ${WHITE_R}4${RESET}   ]  |  7.4.162"
    echo -e " [   ${WHITE_R}5${RESET}   ]  |  7.5.187"
    echo -e " [   ${WHITE_R}6${RESET}   ]  |  8.0.28"
    echo -e " [   ${WHITE_R}7${RESET}   ]  |  8.1.127"
    echo -e " [   ${WHITE_R}8${RESET}   ]  |  8.2.93"
    echo -e " [   ${WHITE_R}9${RESET}   ]  |  8.3.32"
    echo -e " [   ${WHITE_R}10${RESET}  ]  |  8.4.62"
    echo -e " [   ${WHITE_R}11${RESET}  ]  |  8.5.6"
    echo -e " [   ${WHITE_R}12${RESET}  ]  |  8.6.9"
    echo -e " [   ${WHITE_R}13${RESET}  ]  |  9.0.114"
    echo -e " [   ${WHITE_R}14${RESET}  ]  |  9.1.120"
    echo -e " [   ${WHITE_R}15${RESET}  ]  |  9.2.87"
    echo -e " [   ${WHITE_R}16${RESET}  ]  |  9.3.45"
    if [[ "${release_stage}" == 'RC' ]]; then
      echo -e " [   ${WHITE_R}17${RESET}  ]  |  ${rc_version_available}"
      echo -e " [   ${WHITE_R}18${RESET}  ]  |  Cancel\\n\\n"
    else
      echo -e " [   ${WHITE_R}17${RESET}  ]  |  Cancel\\n\\n"
    fi
  fi

  if [[ "${unifi_version}" == "7.1.68" ]]; then
    read -rp $'Your choice | \033[39m' UPGRADE_VERSION
    case "$UPGRADE_VERSION" in
        1)
          unifi_update_start
          unifi_firmware_requirement
          application_version="7.2.97-fa3c0ace6e"
          application_upgrade_releases
          unifi_update_finish;;
        2)
          unifi_update_start
          unifi_firmware_requirement
          application_version="7.3.83-4501ffd244"
          application_upgrade_releases
          unifi_update_finish;;
        3)
          unifi_update_start
          unifi_firmware_requirement
          application_version="7.4.162-3116043f9f"
          application_upgrade_releases
          unifi_update_finish;;
        4)
          unifi_update_start
          unifi_firmware_requirement
          application_version="7.5.187-f57f5bf7ab"
          application_upgrade_releases
          unifi_update_finish;;
        5)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.0.28-66495b8e3a"
          application_upgrade_releases
          unifi_update_finish;;
        6)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.1.127-810cd1e59a"
          application_upgrade_releases
          unifi_update_finish;;
        7)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.2.93-1c329ecd26"
          application_upgrade_releases
          unifi_update_finish;;
        8)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.3.32-896f48ed11"
          application_upgrade_releases
          unifi_update_finish;;
        9)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.4.62-i3q2j125cz"
          application_upgrade_releases
          unifi_update_finish;;
        10)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.5.6-1x29lm155t"
          application_upgrade_releases
          unifi_update_finish;;
        11)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.6.9-0f45j609pu"
          application_upgrade_releases
          unifi_update_finish;;
        12)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.0.114-k5dy363g65"
          application_upgrade_releases
          unifi_update_finish;;
        13)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.1.120-e1aep1zs38"
          application_upgrade_releases
          unifi_update_finish;;
        14)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.2.87-uf39xch68k"
          application_upgrade_releases
          unifi_update_finish;;
        15)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.3.45-9iw96x349g"
          application_upgrade_releases
          unifi_update_finish;;
        16)
          if [[ "${release_stage}" == 'RC' ]]; then
            unifi_update_start
            unifi_firmware_requirement
            application_version="${rc_version_available_secret}"
            application_upgrade_releases
            unifi_update_finish
          else
            cancel_script
          fi;;
        17|*) cancel_script;;
    esac
  else
    read -rp $'Your choice | \033[39m' UPGRADE_VERSION
    case "$UPGRADE_VERSION" in
        1)
          unifi_update_start
          unifi_firmware_requirement
          application_version="7.1.68-124045abd4"
          application_upgrade_releases
          unifi_update_finish;;
        2)
          unifi_update_start
          unifi_firmware_requirement
          application_version="7.2.97-fa3c0ace6e"
          application_upgrade_releases
          unifi_update_finish;;
        3)
          unifi_update_start
          unifi_firmware_requirement
          application_version="7.3.83-4501ffd244"
          application_upgrade_releases
          unifi_update_finish;;
        4)
          unifi_update_start
          unifi_firmware_requirement
          application_version="7.4.162-3116043f9f"
          application_upgrade_releases
          unifi_update_finish;;
        5)
          unifi_update_start
          unifi_firmware_requirement
          application_version="7.5.187-f57f5bf7ab"
          application_upgrade_releases
          unifi_update_finish;;
        6)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.0.28-66495b8e3a"
          application_upgrade_releases
          unifi_update_finish;;
        7)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.1.127-810cd1e59a"
          application_upgrade_releases
          unifi_update_finish;;
        8)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.2.93-1c329ecd26"
          application_upgrade_releases
          unifi_update_finish;;
        9)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.3.32-896f48ed11"
          application_upgrade_releases
          unifi_update_finish;;
        10)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.4.62-i3q2j125cz"
          application_upgrade_releases
          unifi_update_finish;;
        11)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.5.6-1x29lm155t"
          application_upgrade_releases
          unifi_update_finish;;
        12)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.6.9-0f45j609pu"
          application_upgrade_releases
          unifi_update_finish;;
        13)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.0.114-k5dy363g65"
          application_upgrade_releases
          unifi_update_finish;;
        14)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.1.120-e1aep1zs38"
          application_upgrade_releases
          unifi_update_finish;;
        15)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.2.87-uf39xch68k"
          application_upgrade_releases
          unifi_update_finish;;
        16)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.3.45-9iw96x349g"
          application_upgrade_releases
          unifi_update_finish;;
        17)
          if [[ "${release_stage}" == 'RC' ]]; then
            unifi_update_start
            unifi_firmware_requirement
            application_version="${rc_version_available_secret}"
            application_upgrade_releases
            unifi_update_finish
          else
            cancel_script
          fi;;
        18|*) cancel_script;;
    esac
  fi

##########################################################################################################################################################################
#                                                                                                                                                                        #
#                                                                                  7.2.x                                                                                 #
#                                                                                                                                                                        #
##########################################################################################################################################################################

elif [[ "${first_digit_unifi}" == '7' && "${second_digit_unifi}" == '2' ]]; then
  release_wanted
  header
  echo "  To what UniFi Network Application version would you like to update?"
  echo -e "  Currently your UniFi Network Application is on version ${GRAY_R}$unifi${RESET}"
  echo -e "\\n  Release stage is set to | ${GRAY_R}${release_stage_friendly}${RESET}\\n\\n"
  if [[ "${unifi}" == "7.2.97" ]]; then
    unifi_version='7.2.97'
    echo -e " [   ${WHITE_R}1${RESET}   ]  |  7.3.83"
    echo -e " [   ${WHITE_R}2${RESET}   ]  |  7.4.162"
    echo -e " [   ${WHITE_R}3${RESET}   ]  |  7.5.187"
    echo -e " [   ${WHITE_R}4${RESET}   ]  |  8.0.28"
    echo -e " [   ${WHITE_R}5${RESET}   ]  |  8.1.127"
    echo -e " [   ${WHITE_R}6${RESET}   ]  |  8.2.93"
    echo -e " [   ${WHITE_R}7${RESET}   ]  |  8.3.32"
    echo -e " [   ${WHITE_R}8${RESET}   ]  |  8.4.62"
    echo -e " [   ${WHITE_R}9${RESET}   ]  |  8.5.6"
    echo -e " [   ${WHITE_R}10${RESET}  ]  |  8.6.9"
    echo -e " [   ${WHITE_R}11${RESET}  ]  |  9.0.114"
    echo -e " [   ${WHITE_R}12${RESET}  ]  |  9.1.120"
    echo -e " [   ${WHITE_R}13${RESET}  ]  |  9.2.87"
    echo -e " [   ${WHITE_R}14${RESET}  ]  |  9.3.45"
    if [[ "${release_stage}" == 'RC' ]]; then
      echo -e " [   ${WHITE_R}15${RESET}  ]  |  ${rc_version_available}"
      echo -e " [   ${WHITE_R}16${RESET}  ]  |  Cancel\\n\\n"
    else
      echo -e " [   ${WHITE_R}15${RESET}  ]  |  Cancel\\n\\n"
    fi
  else
    echo -e " [   ${WHITE_R}1${RESET}   ]  |  7.2.97"
    echo -e " [   ${WHITE_R}2${RESET}   ]  |  7.3.83"
    echo -e " [   ${WHITE_R}3${RESET}   ]  |  7.4.162"
    echo -e " [   ${WHITE_R}4${RESET}   ]  |  7.5.187"
    echo -e " [   ${WHITE_R}5${RESET}   ]  |  8.0.28"
    echo -e " [   ${WHITE_R}6${RESET}   ]  |  8.1.127"
    echo -e " [   ${WHITE_R}7${RESET}   ]  |  8.2.93"
    echo -e " [   ${WHITE_R}8${RESET}   ]  |  8.3.32"
    echo -e " [   ${WHITE_R}9${RESET}   ]  |  8.4.62"
    echo -e " [   ${WHITE_R}10${RESET}  ]  |  8.5.6"
    echo -e " [   ${WHITE_R}11${RESET}  ]  |  8.6.9"
    echo -e " [   ${WHITE_R}12${RESET}  ]  |  9.0.114"
    echo -e " [   ${WHITE_R}13${RESET}  ]  |  9.1.120"
    echo -e " [   ${WHITE_R}14${RESET}  ]  |  9.2.87"
    echo -e " [   ${WHITE_R}15${RESET}  ]  |  9.3.45"
    if [[ "${release_stage}" == 'RC' ]]; then
      echo -e " [   ${WHITE_R}16${RESET}  ]  |  ${rc_version_available}"
      echo -e " [   ${WHITE_R}17${RESET}  ]  |  Cancel\\n\\n"
    else
      echo -e " [   ${WHITE_R}16${RESET}  ]  |  Cancel\\n\\n"
    fi
  fi

  if [[ "${unifi_version}" == "7.2.97" ]]; then
    read -rp $'Your choice | \033[39m' UPGRADE_VERSION
    case "$UPGRADE_VERSION" in
        1)
          unifi_update_start
          unifi_firmware_requirement
          application_version="7.3.83-4501ffd244"
          application_upgrade_releases
          unifi_update_finish;;
        2)
          unifi_update_start
          unifi_firmware_requirement
          application_version="7.4.162-3116043f9f"
          application_upgrade_releases
          unifi_update_finish;;
        3)
          unifi_update_start
          unifi_firmware_requirement
          application_version="7.5.187-f57f5bf7ab"
          application_upgrade_releases
          unifi_update_finish;;
        4)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.0.28-66495b8e3a"
          application_upgrade_releases
          unifi_update_finish;;
        5)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.1.127-810cd1e59a"
          application_upgrade_releases
          unifi_update_finish;;
        6)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.2.93-1c329ecd26"
          application_upgrade_releases
          unifi_update_finish;;
        7)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.3.32-896f48ed11"
          application_upgrade_releases
          unifi_update_finish;;
        8)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.4.62-i3q2j125cz"
          application_upgrade_releases
          unifi_update_finish;;
        9)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.5.6-1x29lm155t"
          application_upgrade_releases
          unifi_update_finish;;
        10)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.6.9-0f45j609pu"
          application_upgrade_releases
          unifi_update_finish;;
        11)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.0.114-k5dy363g65"
          application_upgrade_releases
          unifi_update_finish;;
        12)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.1.120-e1aep1zs38"
          application_upgrade_releases
          unifi_update_finish;;
        13)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.2.87-uf39xch68k"
          application_upgrade_releases
          unifi_update_finish;;
        14)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.3.45-9iw96x349g"
          application_upgrade_releases
          unifi_update_finish;;
        15)
          if [[ "${release_stage}" == 'RC' ]]; then
            unifi_update_start
            unifi_firmware_requirement
            application_version="${rc_version_available_secret}"
            application_upgrade_releases
            unifi_update_finish
          else
            cancel_script
          fi;;
        16|*) cancel_script;;
    esac
  else
    read -rp $'Your choice | \033[39m' UPGRADE_VERSION
    case "$UPGRADE_VERSION" in
        1)
          unifi_update_start
          unifi_firmware_requirement
          application_version="7.2.97-fa3c0ace6e"
          application_upgrade_releases
          unifi_update_finish;;
        2)
          unifi_update_start
          unifi_firmware_requirement
          application_version="7.3.83-4501ffd244"
          application_upgrade_releases
          unifi_update_finish;;
        3)
          unifi_update_start
          unifi_firmware_requirement
          application_version="7.4.162-3116043f9f"
          application_upgrade_releases
          unifi_update_finish;;
        4)
          unifi_update_start
          unifi_firmware_requirement
          application_version="7.5.187-f57f5bf7ab"
          application_upgrade_releases
          unifi_update_finish;;
        5)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.0.28-66495b8e3a"
          application_upgrade_releases
          unifi_update_finish;;
        6)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.1.127-810cd1e59a"
          application_upgrade_releases
          unifi_update_finish;;
        7)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.2.93-1c329ecd26"
          application_upgrade_releases
          unifi_update_finish;;
        8)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.3.32-896f48ed11"
          application_upgrade_releases
          unifi_update_finish;;
        9)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.4.62-i3q2j125cz"
          application_upgrade_releases
          unifi_update_finish;;
        10)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.5.6-1x29lm155t"
          application_upgrade_releases
          unifi_update_finish;;
        11)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.6.9-0f45j609pu"
          application_upgrade_releases
          unifi_update_finish;;
        12)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.0.114-k5dy363g65"
          application_upgrade_releases
          unifi_update_finish;;
        13)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.1.120-e1aep1zs38"
          application_upgrade_releases
          unifi_update_finish;;
        14)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.2.87-uf39xch68k"
          application_upgrade_releases
          unifi_update_finish;;
        15)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.3.45-9iw96x349g"
          application_upgrade_releases
          unifi_update_finish;;
        16)
          if [[ "${release_stage}" == 'RC' ]]; then
            unifi_update_start
            unifi_firmware_requirement
            application_version="${rc_version_available_secret}"
            application_upgrade_releases
            unifi_update_finish
          else
            cancel_script
          fi;;
        17|*) cancel_script;;
    esac
  fi

##########################################################################################################################################################################
#                                                                                                                                                                        #
#                                                                                  7.3.x                                                                                 #
#                                                                                                                                                                        #
##########################################################################################################################################################################

elif [[ "${first_digit_unifi}" == '7' && "${second_digit_unifi}" == '3' ]]; then
  release_wanted
  header
  echo "  To what UniFi Network Application version would you like to update?"
  echo -e "  Currently your UniFi Network Application is on version ${GRAY_R}$unifi${RESET}"
  echo -e "\\n  Release stage is set to | ${GRAY_R}${release_stage_friendly}${RESET}\\n\\n"
  if [[ "${unifi}" == "7.3.83" ]]; then
    unifi_version='7.3.83'
    echo -e " [   ${WHITE_R}1${RESET}   ]  |  7.4.162"
    echo -e " [   ${WHITE_R}2${RESET}   ]  |  7.5.187"
    echo -e " [   ${WHITE_R}3${RESET}   ]  |  8.0.28"
    echo -e " [   ${WHITE_R}4${RESET}   ]  |  8.1.127"
    echo -e " [   ${WHITE_R}5${RESET}   ]  |  8.2.93"
    echo -e " [   ${WHITE_R}6${RESET}   ]  |  8.3.32"
    echo -e " [   ${WHITE_R}7${RESET}   ]  |  8.4.62"
    echo -e " [   ${WHITE_R}8${RESET}   ]  |  8.5.6"
    echo -e " [   ${WHITE_R}9${RESET}   ]  |  8.6.9"
    echo -e " [   ${WHITE_R}10${RESET}  ]  |  9.0.114"
    echo -e " [   ${WHITE_R}11${RESET}  ]  |  9.1.120"
    echo -e " [   ${WHITE_R}12${RESET}  ]  |  9.2.87"
    echo -e " [   ${WHITE_R}13${RESET}  ]  |  9.3.45"
    if [[ "${release_stage}" == 'RC' ]]; then
      echo -e " [   ${WHITE_R}14${RESET}  ]  |  ${rc_version_available}"
      echo -e " [   ${WHITE_R}15${RESET}  ]  |  Cancel\\n\\n"
    else
      echo -e " [   ${WHITE_R}14${RESET}  ]  |  Cancel\\n\\n"
    fi
  else
    echo -e " [   ${WHITE_R}1${RESET}   ]  |  7.3.83"
    echo -e " [   ${WHITE_R}2${RESET}   ]  |  7.4.162"
    echo -e " [   ${WHITE_R}3${RESET}   ]  |  7.5.187"
    echo -e " [   ${WHITE_R}4${RESET}   ]  |  8.0.28"
    echo -e " [   ${WHITE_R}5${RESET}   ]  |  8.1.127"
    echo -e " [   ${WHITE_R}6${RESET}   ]  |  8.2.93"
    echo -e " [   ${WHITE_R}7${RESET}   ]  |  8.3.32"
    echo -e " [   ${WHITE_R}8${RESET}   ]  |  8.4.62"
    echo -e " [   ${WHITE_R}9${RESET}   ]  |  8.5.6"
    echo -e " [   ${WHITE_R}10${RESET}  ]  |  8.6.9"
    echo -e " [   ${WHITE_R}11${RESET}  ]  |  9.0.114"
    echo -e " [   ${WHITE_R}12${RESET}  ]  |  9.1.120"
    echo -e " [   ${WHITE_R}13${RESET}  ]  |  9.2.87"
    echo -e " [   ${WHITE_R}14${RESET}  ]  |  9.3.45"
    if [[ "${release_stage}" == 'RC' ]]; then
      echo -e " [   ${WHITE_R}15${RESET}  ]  |  ${rc_version_available}"
      echo -e " [   ${WHITE_R}16${RESET}  ]  |  Cancel\\n\\n"
    else
      echo -e " [   ${WHITE_R}15${RESET}  ]  |  Cancel\\n\\n"
    fi
  fi

  if [[ "${unifi_version}" == "7.3.83" ]]; then
    read -rp $'Your choice | \033[39m' UPGRADE_VERSION
    case "$UPGRADE_VERSION" in
        1)
          unifi_update_start
          unifi_firmware_requirement
          application_version="7.4.162-3116043f9f"
          application_upgrade_releases
          unifi_update_finish;;
        2)
          unifi_update_start
          unifi_firmware_requirement
          application_version="7.5.187-f57f5bf7ab"
          application_upgrade_releases
          unifi_update_finish;;
        3)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.0.28-66495b8e3a"
          application_upgrade_releases
          unifi_update_finish;;
        4)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.1.127-810cd1e59a"
          application_upgrade_releases
          unifi_update_finish;;
        5)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.2.93-1c329ecd26"
          application_upgrade_releases
          unifi_update_finish;;
        6)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.3.32-896f48ed11"
          application_upgrade_releases
          unifi_update_finish;;
        7)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.4.62-i3q2j125cz"
          application_upgrade_releases
          unifi_update_finish;;
        8)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.5.6-1x29lm155t"
          application_upgrade_releases
          unifi_update_finish;;
        9)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.6.9-0f45j609pu"
          application_upgrade_releases
          unifi_update_finish;;
        10)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.0.114-k5dy363g65"
          application_upgrade_releases
          unifi_update_finish;;
        11)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.1.120-e1aep1zs38"
          application_upgrade_releases
          unifi_update_finish;;
        12)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.2.87-uf39xch68k"
          application_upgrade_releases
          unifi_update_finish;;
        13)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.3.45-9iw96x349g"
          application_upgrade_releases
          unifi_update_finish;;
        14)
          if [[ "${release_stage}" == 'RC' ]]; then
            unifi_update_start
            unifi_firmware_requirement
            application_version="${rc_version_available_secret}"
            application_upgrade_releases
            unifi_update_finish
          else
            cancel_script
          fi;;
        15|*) cancel_script;;
    esac
  else
    read -rp $'Your choice | \033[39m' UPGRADE_VERSION
    case "$UPGRADE_VERSION" in
        1)
          unifi_update_start
          unifi_firmware_requirement
          application_version="7.3.83-4501ffd244"
          application_upgrade_releases
          unifi_update_finish;;
        2)
          unifi_update_start
          unifi_firmware_requirement
          application_version="7.4.162-3116043f9f"
          application_upgrade_releases
          unifi_update_finish;;
        3)
          unifi_update_start
          unifi_firmware_requirement
          application_version="7.5.187-f57f5bf7ab"
          application_upgrade_releases
          unifi_update_finish;;
        4)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.0.28-66495b8e3a"
          application_upgrade_releases
          unifi_update_finish;;
        5)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.1.127-810cd1e59a"
          application_upgrade_releases
          unifi_update_finish;;
        6)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.2.93-1c329ecd26"
          application_upgrade_releases
          unifi_update_finish;;
        7)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.3.32-896f48ed11"
          application_upgrade_releases
          unifi_update_finish;;
        8)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.4.62-i3q2j125cz"
          application_upgrade_releases
          unifi_update_finish;;
        9)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.5.6-1x29lm155t"
          application_upgrade_releases
          unifi_update_finish;;
        10)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.6.9-0f45j609pu"
          application_upgrade_releases
          unifi_update_finish;;
        11)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.0.114-k5dy363g65"
          application_upgrade_releases
          unifi_update_finish;;
        12)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.1.120-e1aep1zs38"
          application_upgrade_releases
          unifi_update_finish;;
        13)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.2.87-uf39xch68k"
          application_upgrade_releases
          unifi_update_finish;;
        14)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.3.45-9iw96x349g"
          application_upgrade_releases
          unifi_update_finish;;
        15)
          if [[ "${release_stage}" == 'RC' ]]; then
            unifi_update_start
            unifi_firmware_requirement
            application_version="${rc_version_available_secret}"
            application_upgrade_releases
            unifi_update_finish
          else
            cancel_script
          fi;;
        16|*) cancel_script;;
    esac
  fi

##########################################################################################################################################################################
#                                                                                                                                                                        #
#                                                                                  7.4.x                                                                                 #
#                                                                                                                                                                        #
##########################################################################################################################################################################

elif [[ "${first_digit_unifi}" == '7' && "${second_digit_unifi}" == '4' ]]; then
  release_wanted
  header
  echo "  To what UniFi Network Application version would you like to update?"
  echo -e "  Currently your UniFi Network Application is on version ${GRAY_R}$unifi${RESET}"
  echo -e "\\n  Release stage is set to | ${GRAY_R}${release_stage_friendly}${RESET}\\n\\n"
  if [[ "${unifi}" == "7.4.162" ]]; then
    unifi_version='7.4.162'
    echo -e " [   ${WHITE_R}1${RESET}   ]  |  7.5.187"
    echo -e " [   ${WHITE_R}2${RESET}   ]  |  8.0.28"
    echo -e " [   ${WHITE_R}3${RESET}   ]  |  8.1.127"
    echo -e " [   ${WHITE_R}4${RESET}   ]  |  8.2.93"
    echo -e " [   ${WHITE_R}5${RESET}   ]  |  8.3.32"
    echo -e " [   ${WHITE_R}6${RESET}   ]  |  8.4.62"
    echo -e " [   ${WHITE_R}7${RESET}   ]  |  8.5.6"
    echo -e " [   ${WHITE_R}8${RESET}   ]  |  8.6.9"
    echo -e " [   ${WHITE_R}9${RESET}   ]  |  9.0.114"
    echo -e " [   ${WHITE_R}10${RESET}  ]  |  9.1.120"
    echo -e " [   ${WHITE_R}11${RESET}  ]  |  9.2.87"
    echo -e " [   ${WHITE_R}12${RESET}  ]  |  9.3.45"
    if [[ "${release_stage}" == 'RC' ]]; then
      echo -e " [   ${WHITE_R}13${RESET}  ]  |  ${rc_version_available}"
      echo -e " [   ${WHITE_R}14${RESET}  ]  |  Cancel\\n\\n"
    else
      echo -e " [   ${WHITE_R}13${RESET}  ]  |  Cancel\\n\\n"
    fi
  else
    echo -e " [   ${WHITE_R}1${RESET}   ]  |  7.4.162"
    echo -e " [   ${WHITE_R}2${RESET}   ]  |  7.5.187"
    echo -e " [   ${WHITE_R}3${RESET}   ]  |  8.0.28"
    echo -e " [   ${WHITE_R}4${RESET}   ]  |  8.1.127"
    echo -e " [   ${WHITE_R}5${RESET}   ]  |  8.2.93"
    echo -e " [   ${WHITE_R}6${RESET}   ]  |  8.3.32"
    echo -e " [   ${WHITE_R}7${RESET}   ]  |  8.4.62"
    echo -e " [   ${WHITE_R}8${RESET}   ]  |  8.5.6"
    echo -e " [   ${WHITE_R}9${RESET}   ]  |  8.6.9"
    echo -e " [   ${WHITE_R}10${RESET}  ]  |  9.0.114"
    echo -e " [   ${WHITE_R}11${RESET}  ]  |  9.1.120"
    echo -e " [   ${WHITE_R}12${RESET}  ]  |  9.2.87"
    echo -e " [   ${WHITE_R}13${RESET}  ]  |  9.3.45"
    if [[ "${release_stage}" == 'RC' ]]; then
      echo -e " [   ${WHITE_R}14${RESET}  ]  |  ${rc_version_available}"
      echo -e " [   ${WHITE_R}15${RESET}  ]  |  Cancel\\n\\n"
    else
      echo -e " [   ${WHITE_R}14${RESET}  ]  |  Cancel\\n\\n"
    fi
  fi

  if [[ "${unifi_version}" == "7.4.162" ]]; then
    read -rp $'Your choice | \033[39m' UPGRADE_VERSION
    case "$UPGRADE_VERSION" in
        1)
          unifi_update_start
          unifi_firmware_requirement
          application_version="7.5.187-f57f5bf7ab"
          application_upgrade_releases
          unifi_update_finish;;
        2)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.0.28-66495b8e3a"
          application_upgrade_releases
          unifi_update_finish;;
        3)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.1.127-810cd1e59a"
          application_upgrade_releases
          unifi_update_finish;;
        4)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.2.93-1c329ecd26"
          application_upgrade_releases
          unifi_update_finish;;
        5)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.3.32-896f48ed11"
          application_upgrade_releases
          unifi_update_finish;;
        6)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.4.62-i3q2j125cz"
          application_upgrade_releases
          unifi_update_finish;;
        7)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.5.6-1x29lm155t"
          application_upgrade_releases
          unifi_update_finish;;
        8)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.6.9-0f45j609pu"
          application_upgrade_releases
          unifi_update_finish;;
        9)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.0.114-k5dy363g65"
          application_upgrade_releases
          unifi_update_finish;;
        10)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.1.120-e1aep1zs38"
          application_upgrade_releases
          unifi_update_finish;;
        11)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.2.87-uf39xch68k"
          application_upgrade_releases
          unifi_update_finish;;
        12)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.3.45-9iw96x349g"
          application_upgrade_releases
          unifi_update_finish;;
        13)
          if [[ "${release_stage}" == 'RC' ]]; then
            unifi_update_start
            unifi_firmware_requirement
            application_version="${rc_version_available_secret}"
            application_upgrade_releases
            unifi_update_finish
          else
            cancel_script
          fi;;
        14|*) cancel_script;;
    esac
  else
    read -rp $'Your choice | \033[39m' UPGRADE_VERSION
    case "$UPGRADE_VERSION" in
        1)
          unifi_update_start
          unifi_firmware_requirement
          application_version="7.4.162-3116043f9f"
          application_upgrade_releases
          unifi_update_finish;;
        2)
          unifi_update_start
          unifi_firmware_requirement
          application_version="7.5.187-f57f5bf7ab"
          application_upgrade_releases
          unifi_update_finish;;
        3)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.0.28-66495b8e3a"
          application_upgrade_releases
          unifi_update_finish;;
        4)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.1.127-810cd1e59a"
          application_upgrade_releases
          unifi_update_finish;;
        5)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.2.93-1c329ecd26"
          application_upgrade_releases
          unifi_update_finish;;
        6)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.3.32-896f48ed11"
          application_upgrade_releases
          unifi_update_finish;;
        7)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.4.62-i3q2j125cz"
          application_upgrade_releases
          unifi_update_finish;;
        8)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.5.6-1x29lm155t"
          application_upgrade_releases
          unifi_update_finish;;
        9)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.6.9-0f45j609pu"
          application_upgrade_releases
          unifi_update_finish;;
        10)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.0.114-k5dy363g65"
          application_upgrade_releases
          unifi_update_finish;;
        11)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.1.120-e1aep1zs38"
          application_upgrade_releases
          unifi_update_finish;;
        12)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.2.87-uf39xch68k"
          application_upgrade_releases
          unifi_update_finish;;
        13)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.3.45-9iw96x349g"
          application_upgrade_releases
          unifi_update_finish;;
        14)
          if [[ "${release_stage}" == 'RC' ]]; then
            unifi_update_start
            unifi_firmware_requirement
            application_version="${rc_version_available_secret}"
            application_upgrade_releases
            unifi_update_finish
          else
            cancel_script
          fi;;
        15|*) cancel_script;;
    esac
  fi

##########################################################################################################################################################################
#                                                                                                                                                                        #
#                                                                                  7.5.x                                                                                 #
#                                                                                                                                                                        #
##########################################################################################################################################################################

elif [[ "${first_digit_unifi}" == '7' && "${second_digit_unifi}" == '5' ]]; then
  release_wanted
  header
  echo "  To what UniFi Network Application version would you like to update?"
  echo -e "  Currently your UniFi Network Application is on version ${GRAY_R}$unifi${RESET}"
  echo -e "\\n  Release stage is set to | ${GRAY_R}${release_stage_friendly}${RESET}\\n\\n"
  if [[ "${unifi}" == "7.5.187" ]]; then
    unifi_version='7.5.187'
    echo -e " [   ${WHITE_R}1${RESET}   ]  |  8.0.28"
    echo -e " [   ${WHITE_R}2${RESET}   ]  |  8.1.127"
    echo -e " [   ${WHITE_R}3${RESET}   ]  |  8.2.93"
    echo -e " [   ${WHITE_R}4${RESET}   ]  |  8.3.32"
    echo -e " [   ${WHITE_R}5${RESET}   ]  |  8.4.62"
    echo -e " [   ${WHITE_R}6${RESET}   ]  |  8.5.6"
    echo -e " [   ${WHITE_R}7${RESET}   ]  |  8.6.9"
    echo -e " [   ${WHITE_R}8${RESET}   ]  |  9.0.114"
    echo -e " [   ${WHITE_R}9${RESET}   ]  |  9.1.120"
    echo -e " [   ${WHITE_R}10${RESET}  ]  |  9.2.87"
    echo -e " [   ${WHITE_R}11${RESET}  ]  |  9.3.45"
    if [[ "${release_stage}" == 'RC' ]]; then
      echo -e " [   ${WHITE_R}12${RESET}  ]  |  ${rc_version_available}"
      echo -e " [   ${WHITE_R}13${RESET}  ]  |  Cancel\\n\\n"
    else
      echo -e " [   ${WHITE_R}12${RESET}  ]  |  Cancel\\n\\n"
    fi
  else
    echo -e " [   ${WHITE_R}1${RESET}   ]  |  7.5.187"
    echo -e " [   ${WHITE_R}2${RESET}   ]  |  8.0.28"
    echo -e " [   ${WHITE_R}3${RESET}   ]  |  8.1.127"
    echo -e " [   ${WHITE_R}4${RESET}   ]  |  8.2.93"
    echo -e " [   ${WHITE_R}5${RESET}   ]  |  8.3.32"
    echo -e " [   ${WHITE_R}6${RESET}   ]  |  8.4.62"
    echo -e " [   ${WHITE_R}7${RESET}   ]  |  8.5.6"
    echo -e " [   ${WHITE_R}8${RESET}   ]  |  8.6.9"
    echo -e " [   ${WHITE_R}9${RESET}   ]  |  9.0.114"
    echo -e " [   ${WHITE_R}10${RESET}  ]  |  9.1.120"
    echo -e " [   ${WHITE_R}11${RESET}  ]  |  9.2.87"
    echo -e " [   ${WHITE_R}12${RESET}  ]  |  9.3.45"
    if [[ "${release_stage}" == 'RC' ]]; then
      echo -e " [   ${WHITE_R}13${RESET}  ]  |  ${rc_version_available}"
      echo -e " [   ${WHITE_R}14${RESET}  ]  |  Cancel\\n\\n"
    else
      echo -e " [   ${WHITE_R}13${RESET}  ]  |  Cancel\\n\\n"
    fi
  fi

  if [[ "${unifi_version}" == "7.5.187" ]]; then
    read -rp $'Your choice | \033[39m' UPGRADE_VERSION
    case "$UPGRADE_VERSION" in
        1)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.0.28-66495b8e3a"
          application_upgrade_releases
          unifi_update_finish;;
        2)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.1.127-810cd1e59a"
          application_upgrade_releases
          unifi_update_finish;;
        3)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.2.93-1c329ecd26"
          application_upgrade_releases
          unifi_update_finish;;
        4)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.3.32-896f48ed11"
          application_upgrade_releases
          unifi_update_finish;;
        5)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.4.62-i3q2j125cz"
          application_upgrade_releases
          unifi_update_finish;;
        6)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.5.6-1x29lm155t"
          application_upgrade_releases
          unifi_update_finish;;
        7)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.6.9-0f45j609pu"
          application_upgrade_releases
          unifi_update_finish;;
        8)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.0.114-k5dy363g65"
          application_upgrade_releases
          unifi_update_finish;;
        9)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.1.120-e1aep1zs38"
          application_upgrade_releases
          unifi_update_finish;;
        10)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.2.87-uf39xch68k"
          application_upgrade_releases
          unifi_update_finish;;
        11)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.3.45-9iw96x349g"
          application_upgrade_releases
          unifi_update_finish;;
        12)
          if [[ "${release_stage}" == 'RC' ]]; then
            unifi_update_start
            unifi_firmware_requirement
            application_version="${rc_version_available_secret}"
            application_upgrade_releases
            unifi_update_finish
          else
            cancel_script
          fi;;
        13|*) cancel_script;;
    esac
  else
    read -rp $'Your choice | \033[39m' UPGRADE_VERSION
    case "$UPGRADE_VERSION" in
        1)
          unifi_update_start
          unifi_firmware_requirement
          application_version="7.5.187-f57f5bf7ab"
          application_upgrade_releases
          unifi_update_finish;;
        2)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.0.28-66495b8e3a"
          application_upgrade_releases
          unifi_update_finish;;
        3)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.1.127-810cd1e59a"
          application_upgrade_releases
          unifi_update_finish;;
        4)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.2.93-1c329ecd26"
          application_upgrade_releases
          unifi_update_finish;;
        5)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.3.32-896f48ed11"
          application_upgrade_releases
          unifi_update_finish;;
        6)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.4.62-i3q2j125cz"
          application_upgrade_releases
          unifi_update_finish;;
        7)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.5.6-1x29lm155t"
          application_upgrade_releases
          unifi_update_finish;;
        8)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.6.9-0f45j609pu"
          application_upgrade_releases
          unifi_update_finish;;
        9)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.0.114-k5dy363g65"
          application_upgrade_releases
          unifi_update_finish;;
        10)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.1.120-e1aep1zs38"
          application_upgrade_releases
          unifi_update_finish;;
        11)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.2.87-uf39xch68k"
          application_upgrade_releases
          unifi_update_finish;;
        12)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.3.45-9iw96x349g"
          application_upgrade_releases
          unifi_update_finish;;
        13)
          if [[ "${release_stage}" == 'RC' ]]; then
            unifi_update_start
            unifi_firmware_requirement
            application_version="${rc_version_available_secret}"
            application_upgrade_releases
            unifi_update_finish
          else
            cancel_script
          fi;;
        14|*) cancel_script;;
    esac
  fi

##########################################################################################################################################################################
#                                                                                                                                                                        #
#                                                                                  8.0.x                                                                                 #
#                                                                                                                                                                        #
##########################################################################################################################################################################

elif [[ "${first_digit_unifi}" == '8' && "${second_digit_unifi}" == '0' ]]; then
  release_wanted
  header
  echo "  To what UniFi Network Application version would you like to update?"
  echo -e "  Currently your UniFi Network Application is on version ${GRAY_R}$unifi${RESET}"
  echo -e "\\n  Release stage is set to | ${GRAY_R}${release_stage_friendly}${RESET}\\n\\n"
  if [[ "${unifi}" == "8.0.28" ]]; then
    unifi_version='8.0.28'
    echo -e " [   ${WHITE_R}1${RESET}   ]  |  8.1.127"
    echo -e " [   ${WHITE_R}2${RESET}   ]  |  8.2.93"
    echo -e " [   ${WHITE_R}3${RESET}   ]  |  8.3.32"
    echo -e " [   ${WHITE_R}4${RESET}   ]  |  8.4.62"
    echo -e " [   ${WHITE_R}5${RESET}   ]  |  8.5.6"
    echo -e " [   ${WHITE_R}6${RESET}   ]  |  8.6.9"
    echo -e " [   ${WHITE_R}7${RESET}   ]  |  9.0.114"
    echo -e " [   ${WHITE_R}8${RESET}   ]  |  9.1.120"
    echo -e " [   ${WHITE_R}9${RESET}   ]  |  9.2.87"
    echo -e " [   ${WHITE_R}10${RESET}  ]  |  9.3.45"
    if [[ "${release_stage}" == 'RC' ]]; then
      echo -e " [   ${WHITE_R}11${RESET}  ]  |  ${rc_version_available}"
      echo -e " [   ${WHITE_R}12${RESET}  ]  |  Cancel\\n\\n"
    else
      echo -e " [   ${WHITE_R}11${RESET}  ]  |  Cancel\\n\\n"
    fi
  else
    echo -e " [   ${WHITE_R}1${RESET}   ]  |  8.0.28"
    echo -e " [   ${WHITE_R}2${RESET}   ]  |  8.1.127"
    echo -e " [   ${WHITE_R}3${RESET}   ]  |  8.2.93"
    echo -e " [   ${WHITE_R}4${RESET}   ]  |  8.3.32"
    echo -e " [   ${WHITE_R}5${RESET}   ]  |  8.4.62"
    echo -e " [   ${WHITE_R}6${RESET}   ]  |  8.5.6"
    echo -e " [   ${WHITE_R}7${RESET}   ]  |  8.6.9"
    echo -e " [   ${WHITE_R}8${RESET}   ]  |  9.0.114"
    echo -e " [   ${WHITE_R}9${RESET}   ]  |  9.1.120"
    echo -e " [   ${WHITE_R}10${RESET}  ]  |  9.2.87"
    echo -e " [   ${WHITE_R}11${RESET}  ]  |  9.3.45"
    if [[ "${release_stage}" == 'RC' ]]; then
      echo -e " [   ${WHITE_R}12${RESET}  ]  |  ${rc_version_available}"
      echo -e " [   ${WHITE_R}13${RESET}  ]  |  Cancel\\n\\n"
    else
      echo -e " [   ${WHITE_R}12${RESET}  ]  |  Cancel\\n\\n"
    fi
  fi

  if [[ "${unifi_version}" == "8.0.28" ]]; then
    read -rp $'Your choice | \033[39m' UPGRADE_VERSION
    case "$UPGRADE_VERSION" in
        1)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.1.127-810cd1e59a"
          application_upgrade_releases
          unifi_update_finish;;
        2)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.2.93-1c329ecd26"
          application_upgrade_releases
          unifi_update_finish;;
        3)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.3.32-896f48ed11"
          application_upgrade_releases
          unifi_update_finish;;
        4)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.4.62-i3q2j125cz"
          application_upgrade_releases
          unifi_update_finish;;
        5)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.5.6-1x29lm155t"
          application_upgrade_releases
          unifi_update_finish;;
        6)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.6.9-0f45j609pu"
          application_upgrade_releases
          unifi_update_finish;;
        7)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.0.114-k5dy363g65"
          application_upgrade_releases
          unifi_update_finish;;
        8)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.1.120-e1aep1zs38"
          application_upgrade_releases
          unifi_update_finish;;
        9)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.2.87-uf39xch68k"
          application_upgrade_releases
          unifi_update_finish;;
        10)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.3.45-9iw96x349g"
          application_upgrade_releases
          unifi_update_finish;;
        11)
          if [[ "${release_stage}" == 'RC' ]]; then
            unifi_update_start
            unifi_firmware_requirement
            application_version="${rc_version_available_secret}"
            application_upgrade_releases
            unifi_update_finish
          else
            cancel_script
          fi;;
        12|*) cancel_script;;
    esac
  else
    read -rp $'Your choice | \033[39m' UPGRADE_VERSION
    case "$UPGRADE_VERSION" in
        1)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.0.28-66495b8e3a"
          application_upgrade_releases
          unifi_update_finish;;
        2)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.1.127-810cd1e59a"
          application_upgrade_releases
          unifi_update_finish;;
        3)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.2.93-1c329ecd26"
          application_upgrade_releases
          unifi_update_finish;;
        4)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.3.32-896f48ed11"
          application_upgrade_releases
          unifi_update_finish;;
        5)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.4.62-i3q2j125cz"
          application_upgrade_releases
          unifi_update_finish;;
        6)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.5.6-1x29lm155t"
          application_upgrade_releases
          unifi_update_finish;;
        7)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.6.9-0f45j609pu"
          application_upgrade_releases
          unifi_update_finish;;
        8)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.0.114-k5dy363g65"
          application_upgrade_releases
          unifi_update_finish;;
        9)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.1.120-e1aep1zs38"
          application_upgrade_releases
          unifi_update_finish;;
        10)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.2.87-uf39xch68k"
          application_upgrade_releases
          unifi_update_finish;;
        11)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.3.45-9iw96x349g"
          application_upgrade_releases
          unifi_update_finish;;
        12)
          if [[ "${release_stage}" == 'RC' ]]; then
            unifi_update_start
            unifi_firmware_requirement
            application_version="${rc_version_available_secret}"
            application_upgrade_releases
            unifi_update_finish
          else
            cancel_script
          fi;;
        13|*) cancel_script;;
    esac
  fi

##########################################################################################################################################################################
#                                                                                                                                                                        #
#                                                                                  8.1.x                                                                                 #
#                                                                                                                                                                        #
##########################################################################################################################################################################

elif [[ "${first_digit_unifi}" == '8' && "${second_digit_unifi}" == '1' ]]; then
  release_wanted
  header
  echo "  To what UniFi Network Application version would you like to update?"
  echo -e "  Currently your UniFi Network Application is on version ${GRAY_R}$unifi${RESET}"
  echo -e "\\n  Release stage is set to | ${GRAY_R}${release_stage_friendly}${RESET}\\n\\n"
  if [[ "${unifi}" == "8.1.127" ]]; then
    unifi_version='8.1.127'
    echo -e " [   ${WHITE_R}1${RESET}   ]  |  8.2.93"
    echo -e " [   ${WHITE_R}2${RESET}   ]  |  8.3.32"
    echo -e " [   ${WHITE_R}3${RESET}   ]  |  8.4.62"
    echo -e " [   ${WHITE_R}4${RESET}   ]  |  8.5.6"
    echo -e " [   ${WHITE_R}5${RESET}   ]  |  8.6.9"
    echo -e " [   ${WHITE_R}6${RESET}   ]  |  9.0.114"
    echo -e " [   ${WHITE_R}7${RESET}   ]  |  9.1.120"
    echo -e " [   ${WHITE_R}8${RESET}   ]  |  9.2.87"
    echo -e " [   ${WHITE_R}9${RESET}   ]  |  9.3.45"
    if [[ "${release_stage}" == 'RC' ]]; then
      echo -e " [   ${WHITE_R}10${RESET}  ]  |  ${rc_version_available}"
      echo -e " [   ${WHITE_R}11${RESET}  ]  |  Cancel\\n\\n"
    else
      echo -e " [   ${WHITE_R}10${RESET}  ]  |  Cancel\\n\\n"
    fi
  else
    echo -e " [   ${WHITE_R}1${RESET}   ]  |  8.1.127"
    echo -e " [   ${WHITE_R}2${RESET}   ]  |  8.2.93"
    echo -e " [   ${WHITE_R}3${RESET}   ]  |  8.3.32"
    echo -e " [   ${WHITE_R}4${RESET}   ]  |  8.4.62"
    echo -e " [   ${WHITE_R}5${RESET}   ]  |  8.5.6"
    echo -e " [   ${WHITE_R}6${RESET}   ]  |  8.6.9"
    echo -e " [   ${WHITE_R}7${RESET}   ]  |  9.0.114"
    echo -e " [   ${WHITE_R}8${RESET}   ]  |  9.1.120"
    echo -e " [   ${WHITE_R}9${RESET}   ]  |  9.2.87"
    echo -e " [   ${WHITE_R}10${RESET}  ]  |  9.3.45"
    if [[ "${release_stage}" == 'RC' ]]; then
      echo -e " [   ${WHITE_R}11${RESET}  ]  |  ${rc_version_available}"
      echo -e " [   ${WHITE_R}12${RESET}  ]  |  Cancel\\n\\n"
    else
      echo -e " [   ${WHITE_R}11${RESET}  ]  |  Cancel\\n\\n"
    fi
  fi

  if [[ "${unifi_version}" == "8.1.127" ]]; then
    read -rp $'Your choice | \033[39m' UPGRADE_VERSION
    case "$UPGRADE_VERSION" in
        1)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.2.93-1c329ecd26"
          application_upgrade_releases
          unifi_update_finish;;
        2)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.3.32-896f48ed11"
          application_upgrade_releases
          unifi_update_finish;;
        3)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.4.62-i3q2j125cz"
          application_upgrade_releases
          unifi_update_finish;;
        4)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.5.6-1x29lm155t"
          application_upgrade_releases
          unifi_update_finish;;
        5)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.6.9-0f45j609pu"
          application_upgrade_releases
          unifi_update_finish;;
        6)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.0.114-k5dy363g65"
          application_upgrade_releases
          unifi_update_finish;;
        7)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.1.120-e1aep1zs38"
          application_upgrade_releases
          unifi_update_finish;;
        8)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.2.87-uf39xch68k"
          application_upgrade_releases
          unifi_update_finish;;
        9)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.3.45-9iw96x349g"
          application_upgrade_releases
          unifi_update_finish;;
        10)
          if [[ "${release_stage}" == 'RC' ]]; then
            unifi_update_start
            unifi_firmware_requirement
            application_version="${rc_version_available_secret}"
            application_upgrade_releases
            unifi_update_finish
          else
            cancel_script
          fi;;
        11|*) cancel_script;;
    esac
  else
    read -rp $'Your choice | \033[39m' UPGRADE_VERSION
    case "$UPGRADE_VERSION" in
        1)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.1.127-810cd1e59a"
          application_upgrade_releases
          unifi_update_finish;;
        2)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.2.93-1c329ecd26"
          application_upgrade_releases
          unifi_update_finish;;
        3)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.3.32-896f48ed11"
          application_upgrade_releases
          unifi_update_finish;;
        4)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.4.62-i3q2j125cz"
          application_upgrade_releases
          unifi_update_finish;;
        5)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.5.6-1x29lm155t"
          application_upgrade_releases
          unifi_update_finish;;
        6)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.6.9-0f45j609pu"
          application_upgrade_releases
          unifi_update_finish;;
        7)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.0.114-k5dy363g65"
          application_upgrade_releases
          unifi_update_finish;;
        8)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.1.120-e1aep1zs38"
          application_upgrade_releases
          unifi_update_finish;;
        9)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.2.87-uf39xch68k"
          application_upgrade_releases
          unifi_update_finish;;
        10)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.3.45-9iw96x349g"
          application_upgrade_releases
          unifi_update_finish;;
        11)
          if [[ "${release_stage}" == 'RC' ]]; then
            unifi_update_start
            unifi_firmware_requirement
            application_version="${rc_version_available_secret}"
            application_upgrade_releases
            unifi_update_finish
          else
            cancel_script
          fi;;
        12|*) cancel_script;;
    esac
  fi

##########################################################################################################################################################################
#                                                                                                                                                                        #
#                                                                                  8.2.x                                                                                 #
#                                                                                                                                                                        #
##########################################################################################################################################################################

elif [[ "${first_digit_unifi}" == '8' && "${second_digit_unifi}" == '2' ]]; then
  release_wanted
  header
  echo "  To what UniFi Network Application version would you like to update?"
  echo -e "  Currently your UniFi Network Application is on version ${GRAY_R}$unifi${RESET}"
  echo -e "\\n  Release stage is set to | ${GRAY_R}${release_stage_friendly}${RESET}\\n\\n"
  if [[ "${unifi}" == "8.2.93" ]]; then
    unifi_version='8.2.93'
    echo -e " [   ${WHITE_R}1${RESET}   ]  |  8.3.32"
    echo -e " [   ${WHITE_R}2${RESET}   ]  |  8.4.62"
    echo -e " [   ${WHITE_R}3${RESET}   ]  |  8.5.6"
    echo -e " [   ${WHITE_R}4${RESET}   ]  |  8.6.9"
    echo -e " [   ${WHITE_R}5${RESET}   ]  |  9.0.114"
    echo -e " [   ${WHITE_R}6${RESET}   ]  |  9.1.120"
    echo -e " [   ${WHITE_R}7${RESET}   ]  |  9.2.87"
    echo -e " [   ${WHITE_R}8${RESET}   ]  |  9.3.45"
    if [[ "${release_stage}" == 'RC' ]]; then
      echo -e " [   ${WHITE_R}9${RESET}   ]  |  ${rc_version_available}"
      echo -e " [   ${WHITE_R}10${RESET}  ]  |  Cancel\\n\\n"
    else
      echo -e " [   ${WHITE_R}9${RESET}   ]  |  Cancel\\n\\n"
    fi
  else
    echo -e " [   ${WHITE_R}1${RESET}   ]  |  8.2.93"
    echo -e " [   ${WHITE_R}2${RESET}   ]  |  8.3.32"
    echo -e " [   ${WHITE_R}3${RESET}   ]  |  8.4.62"
    echo -e " [   ${WHITE_R}4${RESET}   ]  |  8.5.6"
    echo -e " [   ${WHITE_R}5${RESET}   ]  |  8.6.9"
    echo -e " [   ${WHITE_R}6${RESET}   ]  |  9.0.114"
    echo -e " [   ${WHITE_R}7${RESET}   ]  |  9.1.120"
    echo -e " [   ${WHITE_R}8${RESET}   ]  |  9.2.87"
    echo -e " [   ${WHITE_R}9${RESET}   ]  |  9.3.45"
    if [[ "${release_stage}" == 'RC' ]]; then
      echo -e " [   ${WHITE_R}10${RESET}  ]  |  ${rc_version_available}"
      echo -e " [   ${WHITE_R}11${RESET}  ]  |  Cancel\\n\\n"
    else
      echo -e " [   ${WHITE_R}10${RESET}  ]  |  Cancel\\n\\n"
    fi
  fi

  if [[ "${unifi_version}" == "8.2.93" ]]; then
    read -rp $'Your choice | \033[39m' UPGRADE_VERSION
    case "$UPGRADE_VERSION" in
        1)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.3.32-896f48ed11"
          application_upgrade_releases
          unifi_update_finish;;
        2)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.4.62-i3q2j125cz"
          application_upgrade_releases
          unifi_update_finish;;
        3)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.5.6-1x29lm155t"
          application_upgrade_releases
          unifi_update_finish;;
        4)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.6.9-0f45j609pu"
          application_upgrade_releases
          unifi_update_finish;;
        5)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.0.114-k5dy363g65"
          application_upgrade_releases
          unifi_update_finish;;
        6)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.1.120-e1aep1zs38"
          application_upgrade_releases
          unifi_update_finish;;
        7)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.2.87-uf39xch68k"
          application_upgrade_releases
          unifi_update_finish;;
        8)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.3.45-9iw96x349g"
          application_upgrade_releases
          unifi_update_finish;;
        9)
          if [[ "${release_stage}" == 'RC' ]]; then
            unifi_update_start
            unifi_firmware_requirement
            application_version="${rc_version_available_secret}"
            application_upgrade_releases
            unifi_update_finish
          else
            cancel_script
          fi;;
        10|*) cancel_script;;
    esac
  else
    read -rp $'Your choice | \033[39m' UPGRADE_VERSION
    case "$UPGRADE_VERSION" in
        1)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.2.93-1c329ecd26"
          application_upgrade_releases
          unifi_update_finish;;
        2)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.3.32-896f48ed11"
          application_upgrade_releases
          unifi_update_finish;;
        3)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.4.62-i3q2j125cz"
          application_upgrade_releases
          unifi_update_finish;;
        4)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.5.6-1x29lm155t"
          application_upgrade_releases
          unifi_update_finish;;
        5)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.6.9-0f45j609pu"
          application_upgrade_releases
          unifi_update_finish;;
        6)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.0.114-k5dy363g65"
          application_upgrade_releases
          unifi_update_finish;;
        7)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.1.120-e1aep1zs38"
          application_upgrade_releases
          unifi_update_finish;;
        8)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.2.87-uf39xch68k"
          application_upgrade_releases
          unifi_update_finish;;
        9)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.3.45-9iw96x349g"
          application_upgrade_releases
          unifi_update_finish;;
        10)
          if [[ "${release_stage}" == 'RC' ]]; then
            unifi_update_start
            unifi_firmware_requirement
            application_version="${rc_version_available_secret}"
            application_upgrade_releases
            unifi_update_finish
          else
            cancel_script
          fi;;
        11|*) cancel_script;;
    esac
  fi

##########################################################################################################################################################################
#                                                                                                                                                                        #
#                                                                                  8.3.x                                                                                 #
#                                                                                                                                                                        #
##########################################################################################################################################################################

elif [[ "${first_digit_unifi}" == '8' && "${second_digit_unifi}" == '3' ]]; then
  release_wanted
  header
  echo "  To what UniFi Network Application version would you like to update?"
  echo -e "  Currently your UniFi Network Application is on version ${GRAY_R}$unifi${RESET}"
  echo -e "\\n  Release stage is set to | ${GRAY_R}${release_stage_friendly}${RESET}\\n\\n"
  if [[ "${unifi}" == "8.3.32" ]]; then
    unifi_version='8.3.32'
    echo -e " [   ${WHITE_R}1${RESET}   ]  |  8.4.62"
    echo -e " [   ${WHITE_R}2${RESET}   ]  |  8.5.6"
    echo -e " [   ${WHITE_R}3${RESET}   ]  |  8.6.9"
    echo -e " [   ${WHITE_R}4${RESET}   ]  |  9.0.114"
    echo -e " [   ${WHITE_R}5${RESET}   ]  |  9.1.120"
    echo -e " [   ${WHITE_R}6${RESET}   ]  |  9.2.87"
    echo -e " [   ${WHITE_R}7${RESET}   ]  |  9.3.45"
    if [[ "${release_stage}" == 'RC' ]]; then
      echo -e " [   ${WHITE_R}8${RESET}   ]  |  ${rc_version_available}"
      echo -e " [   ${WHITE_R}9${RESET}   ]  |  Cancel\\n\\n"
    else
      echo -e " [   ${WHITE_R}8${RESET}   ]  |  Cancel\\n\\n"
    fi
  else
    echo -e " [   ${WHITE_R}1${RESET}   ]  |  8.3.32"
    echo -e " [   ${WHITE_R}2${RESET}   ]  |  8.4.62"
    echo -e " [   ${WHITE_R}3${RESET}   ]  |  8.5.6"
    echo -e " [   ${WHITE_R}4${RESET}   ]  |  8.6.9"
    echo -e " [   ${WHITE_R}5${RESET}   ]  |  9.0.114"
    echo -e " [   ${WHITE_R}6${RESET}   ]  |  9.1.120"
    echo -e " [   ${WHITE_R}7${RESET}   ]  |  9.2.87"
    echo -e " [   ${WHITE_R}8${RESET}   ]  |  9.3.45"
    if [[ "${release_stage}" == 'RC' ]]; then
      echo -e " [   ${WHITE_R}9${RESET}   ]  |  ${rc_version_available}"
      echo -e " [   ${WHITE_R}10${RESET}  ]  |  Cancel\\n\\n"
    else
      echo -e " [   ${WHITE_R}9${RESET}   ]  |  Cancel\\n\\n"
    fi
  fi

  if [[ "${unifi_version}" == "8.3.32" ]]; then
    read -rp $'Your choice | \033[39m' UPGRADE_VERSION
    case "$UPGRADE_VERSION" in
        1)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.4.62-i3q2j125cz"
          application_upgrade_releases
          unifi_update_finish;;
        2)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.5.6-1x29lm155t"
          application_upgrade_releases
          unifi_update_finish;;
        3)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.6.9-0f45j609pu"
          application_upgrade_releases
          unifi_update_finish;;
        4)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.0.114-k5dy363g65"
          application_upgrade_releases
          unifi_update_finish;;
        5)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.1.120-e1aep1zs38"
          application_upgrade_releases
          unifi_update_finish;;
        6)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.2.87-uf39xch68k"
          application_upgrade_releases
          unifi_update_finish;;
        7)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.3.45-9iw96x349g"
          application_upgrade_releases
          unifi_update_finish;;
        8)
          if [[ "${release_stage}" == 'RC' ]]; then
            unifi_update_start
            unifi_firmware_requirement
            application_version="${rc_version_available_secret}"
            application_upgrade_releases
            unifi_update_finish
          else
            cancel_script
          fi;;
        9|*) cancel_script;;
    esac
  else
    read -rp $'Your choice | \033[39m' UPGRADE_VERSION
    case "$UPGRADE_VERSION" in
        1)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.3.32-896f48ed11"
          application_upgrade_releases
          unifi_update_finish;;
        2)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.4.62-i3q2j125cz"
          application_upgrade_releases
          unifi_update_finish;;
        3)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.5.6-1x29lm155t"
          application_upgrade_releases
          unifi_update_finish;;
        4)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.6.9-0f45j609pu"
          application_upgrade_releases
          unifi_update_finish;;
        5)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.0.114-k5dy363g65"
          application_upgrade_releases
          unifi_update_finish;;
        6)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.1.120-e1aep1zs38"
          application_upgrade_releases
          unifi_update_finish;;
        7)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.2.87-uf39xch68k"
          application_upgrade_releases
          unifi_update_finish;;
        8)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.3.45-9iw96x349g"
          application_upgrade_releases
          unifi_update_finish;;
        9)
          if [[ "${release_stage}" == 'RC' ]]; then
            unifi_update_start
            unifi_firmware_requirement
            application_version="${rc_version_available_secret}"
            application_upgrade_releases
            unifi_update_finish
          else
            cancel_script
          fi;;
        10|*) cancel_script;;
    esac
  fi

##########################################################################################################################################################################
#                                                                                                                                                                        #
#                                                                                  8.4.x                                                                                 #
#                                                                                                                                                                        #
##########################################################################################################################################################################

elif [[ "${first_digit_unifi}" == '8' && "${second_digit_unifi}" == '4' ]]; then
  release_wanted
  header
  echo "  To what UniFi Network Application version would you like to update?"
  echo -e "  Currently your UniFi Network Application is on version ${GRAY_R}$unifi${RESET}"
  echo -e "\\n  Release stage is set to | ${GRAY_R}${release_stage_friendly}${RESET}\\n\\n"
  if [[ "${unifi}" == "8.4.62" ]]; then
    unifi_version='8.4.62'
    echo -e " [   ${WHITE_R}1${RESET}   ]  |  8.5.6"
    echo -e " [   ${WHITE_R}2${RESET}   ]  |  8.6.9"
    echo -e " [   ${WHITE_R}3${RESET}   ]  |  9.0.114"
    echo -e " [   ${WHITE_R}4${RESET}   ]  |  9.1.120"
    echo -e " [   ${WHITE_R}5${RESET}   ]  |  9.2.87"
    echo -e " [   ${WHITE_R}6${RESET}   ]  |  9.3.45"
    if [[ "${release_stage}" == 'RC' ]]; then
      echo -e " [   ${WHITE_R}7${RESET}   ]  |  ${rc_version_available}"
      echo -e " [   ${WHITE_R}8${RESET}   ]  |  Cancel\\n\\n"
    else
      echo -e " [   ${WHITE_R}7${RESET}   ]  |  Cancel\\n\\n"
    fi
  else
    echo -e " [   ${WHITE_R}1${RESET}   ]  |  8.4.62"
    echo -e " [   ${WHITE_R}2${RESET}   ]  |  8.5.6"
    echo -e " [   ${WHITE_R}3${RESET}   ]  |  8.6.9"
    echo -e " [   ${WHITE_R}4${RESET}   ]  |  9.0.114"
    echo -e " [   ${WHITE_R}5${RESET}   ]  |  9.1.120"
    echo -e " [   ${WHITE_R}6${RESET}   ]  |  9.2.87"
    echo -e " [   ${WHITE_R}7${RESET}   ]  |  9.3.45"
    if [[ "${release_stage}" == 'RC' ]]; then
      echo -e " [   ${WHITE_R}8${RESET}   ]  |  ${rc_version_available}"
      echo -e " [   ${WHITE_R}9${RESET}   ]  |  Cancel\\n\\n"
    else
      echo -e " [   ${WHITE_R}8${RESET}   ]  |  Cancel\\n\\n"
    fi
  fi

  if [[ "${unifi_version}" == "8.4.62" ]]; then
    read -rp $'Your choice | \033[39m' UPGRADE_VERSION
    case "$UPGRADE_VERSION" in
        1)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.5.6-1x29lm155t"
          application_upgrade_releases
          unifi_update_finish;;
        2)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.6.9-0f45j609pu"
          application_upgrade_releases
          unifi_update_finish;;
        3)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.0.114-k5dy363g65"
          application_upgrade_releases
          unifi_update_finish;;
        4)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.1.120-e1aep1zs38"
          application_upgrade_releases
          unifi_update_finish;;
        5)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.2.87-uf39xch68k"
          application_upgrade_releases
          unifi_update_finish;;
        6)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.3.45-9iw96x349g"
          application_upgrade_releases
          unifi_update_finish;;
        7)
          if [[ "${release_stage}" == 'RC' ]]; then
            unifi_update_start
            unifi_firmware_requirement
            application_version="${rc_version_available_secret}"
            application_upgrade_releases
            unifi_update_finish
          else
            cancel_script
          fi;;
        8|*) cancel_script;;
    esac
  else
    read -rp $'Your choice | \033[39m' UPGRADE_VERSION
    case "$UPGRADE_VERSION" in
        1)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.4.62-i3q2j125cz"
          application_upgrade_releases
          unifi_update_finish;;
        2)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.5.6-1x29lm155t"
          application_upgrade_releases
          unifi_update_finish;;
        3)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.6.9-0f45j609pu"
          application_upgrade_releases
          unifi_update_finish;;
        4)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.0.114-k5dy363g65"
          application_upgrade_releases
          unifi_update_finish;;
        5)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.1.120-e1aep1zs38"
          application_upgrade_releases
          unifi_update_finish;;
        6)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.2.87-uf39xch68k"
          application_upgrade_releases
          unifi_update_finish;;
        7)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.3.45-9iw96x349g"
          application_upgrade_releases
          unifi_update_finish;;
        8)
          if [[ "${release_stage}" == 'RC' ]]; then
            unifi_update_start
            unifi_firmware_requirement
            application_version="${rc_version_available_secret}"
            application_upgrade_releases
            unifi_update_finish
          else
            cancel_script
          fi;;
        9|*) cancel_script;;
    esac
  fi

##########################################################################################################################################################################
#                                                                                                                                                                        #
#                                                                                  8.5.x                                                                                 #
#                                                                                                                                                                        #
##########################################################################################################################################################################

elif [[ "${first_digit_unifi}" == '8' && "${second_digit_unifi}" == '5' ]]; then
  release_wanted
  header
  echo "  To what UniFi Network Application version would you like to update?"
  echo -e "  Currently your UniFi Network Application is on version ${GRAY_R}$unifi${RESET}"
  echo -e "\\n  Release stage is set to | ${GRAY_R}${release_stage_friendly}${RESET}\\n\\n"
  if [[ "${unifi}" == "8.5.6" ]]; then
    unifi_version='8.5.6'
    echo -e " [   ${WHITE_R}1${RESET}   ]  |  8.6.9"
    echo -e " [   ${WHITE_R}2${RESET}   ]  |  9.0.114"
    echo -e " [   ${WHITE_R}3${RESET}   ]  |  9.1.120"
    echo -e " [   ${WHITE_R}4${RESET}   ]  |  9.2.87"
    echo -e " [   ${WHITE_R}5${RESET}   ]  |  9.3.45"
    if [[ "${release_stage}" == 'RC' ]]; then
      echo -e " [   ${WHITE_R}6${RESET}   ]  |  ${rc_version_available}"
      echo -e " [   ${WHITE_R}7${RESET}   ]  |  Cancel\\n\\n"
    else
      echo -e " [   ${WHITE_R}6${RESET}   ]  |  Cancel\\n\\n"
    fi
  else
    echo -e " [   ${WHITE_R}1${RESET}   ]  |  8.5.6"
    echo -e " [   ${WHITE_R}2${RESET}   ]  |  8.6.9"
    echo -e " [   ${WHITE_R}3${RESET}   ]  |  9.0.114"
    echo -e " [   ${WHITE_R}4${RESET}   ]  |  9.1.120"
    echo -e " [   ${WHITE_R}5${RESET}   ]  |  9.2.87"
    echo -e " [   ${WHITE_R}6${RESET}   ]  |  9.3.45"
    if [[ "${release_stage}" == 'RC' ]]; then
      echo -e " [   ${WHITE_R}7${RESET}   ]  |  ${rc_version_available}"
      echo -e " [   ${WHITE_R}8${RESET}   ]  |  Cancel\\n\\n"
    else
      echo -e " [   ${WHITE_R}7${RESET}   ]  |  Cancel\\n\\n"
    fi
  fi

  if [[ "${unifi_version}" == "8.5.6" ]]; then
    read -rp $'Your choice | \033[39m' UPGRADE_VERSION
    case "$UPGRADE_VERSION" in
        1)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.6.9-0f45j609pu"
          application_upgrade_releases
          unifi_update_finish;;
        2)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.0.114-k5dy363g65"
          application_upgrade_releases
          unifi_update_finish;;
        3)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.1.120-e1aep1zs38"
          application_upgrade_releases
          unifi_update_finish;;
        4)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.2.87-uf39xch68k"
          application_upgrade_releases
          unifi_update_finish;;
        5)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.3.45-9iw96x349g"
          application_upgrade_releases
          unifi_update_finish;;
        6)
          if [[ "${release_stage}" == 'RC' ]]; then
            unifi_update_start
            unifi_firmware_requirement
            application_version="${rc_version_available_secret}"
            application_upgrade_releases
            unifi_update_finish
          else
            cancel_script
          fi;;
        7|*) cancel_script;;
    esac
  else
    read -rp $'Your choice | \033[39m' UPGRADE_VERSION
    case "$UPGRADE_VERSION" in
        1)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.5.6-1x29lm155t"
          application_upgrade_releases
          unifi_update_finish;;
        2)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.6.9-0f45j609pu"
          application_upgrade_releases
          unifi_update_finish;;
        3)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.0.114-k5dy363g65"
          application_upgrade_releases
          unifi_update_finish;;
        4)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.1.120-e1aep1zs38"
          application_upgrade_releases
          unifi_update_finish;;
        5)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.2.87-uf39xch68k"
          application_upgrade_releases
          unifi_update_finish;;
        6)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.3.45-9iw96x349g"
          application_upgrade_releases
          unifi_update_finish;;
        7)
          if [[ "${release_stage}" == 'RC' ]]; then
            unifi_update_start
            unifi_firmware_requirement
            application_version="${rc_version_available_secret}"
            application_upgrade_releases
            unifi_update_finish
          else
            cancel_script
          fi;;
        8|*) cancel_script;;
    esac
  fi

##########################################################################################################################################################################
#                                                                                                                                                                        #
#                                                                                  8.6.x                                                                                 #
#                                                                                                                                                                        #
##########################################################################################################################################################################

elif [[ "${first_digit_unifi}" == '8' && "${second_digit_unifi}" == '6' ]]; then
  release_wanted
  header
  echo "  To what UniFi Network Application version would you like to update?"
  echo -e "  Currently your UniFi Network Application is on version ${GRAY_R}$unifi${RESET}"
  echo -e "\\n  Release stage is set to | ${GRAY_R}${release_stage_friendly}${RESET}\\n\\n"
  if [[ "${unifi}" == "8.6.9" ]]; then
    unifi_version='8.6.9'
    echo -e " [   ${WHITE_R}1${RESET}   ]  |  9.0.114"
    echo -e " [   ${WHITE_R}2${RESET}   ]  |  9.1.120"
    echo -e " [   ${WHITE_R}3${RESET}   ]  |  9.2.87"
    echo -e " [   ${WHITE_R}4${RESET}   ]  |  9.3.45"
    if [[ "${release_stage}" == 'RC' ]]; then
      echo -e " [   ${WHITE_R}5${RESET}   ]  |  ${rc_version_available}"
      echo -e " [   ${WHITE_R}6${RESET}   ]  |  Cancel\\n\\n"
    else
      echo -e " [   ${WHITE_R}5${RESET}   ]  |  Cancel\\n\\n"
    fi
  else
    echo -e " [   ${WHITE_R}1${RESET}   ]  |  8.6.9"
    echo -e " [   ${WHITE_R}2${RESET}   ]  |  9.0.114"
    echo -e " [   ${WHITE_R}3${RESET}   ]  |  9.1.120"
    echo -e " [   ${WHITE_R}4${RESET}   ]  |  9.2.87"
    echo -e " [   ${WHITE_R}5${RESET}   ]  |  9.3.45"
    if [[ "${release_stage}" == 'RC' ]]; then
      echo -e " [   ${WHITE_R}6${RESET}   ]  |  ${rc_version_available}"
      echo -e " [   ${WHITE_R}7${RESET}   ]  |  Cancel\\n\\n"
    else
      echo -e " [   ${WHITE_R}6${RESET}   ]  |  Cancel\\n\\n"
    fi
  fi

  if [[ "${unifi_version}" == "8.6.9" ]]; then
    read -rp $'Your choice | \033[39m' UPGRADE_VERSION
    case "$UPGRADE_VERSION" in
        1)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.0.114-k5dy363g65"
          application_upgrade_releases
          unifi_update_finish;;
        2)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.1.120-e1aep1zs38"
          application_upgrade_releases
          unifi_update_finish;;
        3)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.2.87-uf39xch68k"
          application_upgrade_releases
          unifi_update_finish;;
        4)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.3.45-9iw96x349g"
          application_upgrade_releases
          unifi_update_finish;;
        5)
          if [[ "${release_stage}" == 'RC' ]]; then
            unifi_update_start
            unifi_firmware_requirement
            application_version="${rc_version_available_secret}"
            application_upgrade_releases
            unifi_update_finish
          else
            cancel_script
          fi;;
        6|*) cancel_script;;
    esac
  else
    read -rp $'Your choice | \033[39m' UPGRADE_VERSION
    case "$UPGRADE_VERSION" in
        1)
          unifi_update_start
          unifi_firmware_requirement
          application_version="8.6.9-0f45j609pu"
          application_upgrade_releases
          unifi_update_finish;;
        2)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.0.114-k5dy363g65"
          application_upgrade_releases
          unifi_update_finish;;
        3)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.1.120-e1aep1zs38"
          application_upgrade_releases
          unifi_update_finish;;
        4)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.2.87-uf39xch68k"
          application_upgrade_releases
          unifi_update_finish;;
        5)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.3.45-9iw96x349g"
          application_upgrade_releases
          unifi_update_finish;;
        6)
          if [[ "${release_stage}" == 'RC' ]]; then
            unifi_update_start
            unifi_firmware_requirement
            application_version="${rc_version_available_secret}"
            application_upgrade_releases
            unifi_update_finish
          else
            cancel_script
          fi;;
        7|*) cancel_script;;
    esac
  fi

##########################################################################################################################################################################
#                                                                                                                                                                        #
#                                                                                  9.0.x                                                                                 #
#                                                                                                                                                                        #
##########################################################################################################################################################################

elif [[ "${first_digit_unifi}" == '9' && "${second_digit_unifi}" == '0' ]]; then
  release_wanted
  header
  echo "  To what UniFi Network Application version would you like to update?"
  echo -e "  Currently your UniFi Network Application is on version ${GRAY_R}$unifi${RESET}"
  echo -e "\\n  Release stage is set to | ${GRAY_R}${release_stage_friendly}${RESET}\\n\\n"
  if [[ "${unifi}" == "9.0.114" ]]; then
    unifi_version='9.0.114'
    echo -e " [   ${WHITE_R}1${RESET}   ]  |  9.1.120"
    echo -e " [   ${WHITE_R}2${RESET}   ]  |  9.2.87"
    echo -e " [   ${WHITE_R}3${RESET}   ]  |  9.3.45"
    if [[ "${release_stage}" == 'RC' ]]; then
      echo -e " [   ${WHITE_R}4${RESET}   ]  |  ${rc_version_available}"
      echo -e " [   ${WHITE_R}5${RESET}   ]  |  Cancel\\n\\n"
    else
      echo -e " [   ${WHITE_R}4${RESET}   ]  |  Cancel\\n\\n"
    fi
  else
    echo -e " [   ${WHITE_R}1${RESET}   ]  |  9.0.114"
    echo -e " [   ${WHITE_R}2${RESET}   ]  |  9.1.120"
    echo -e " [   ${WHITE_R}3${RESET}   ]  |  9.2.87"
    echo -e " [   ${WHITE_R}4${RESET}   ]  |  9.3.45"
    if [[ "${release_stage}" == 'RC' ]]; then
      echo -e " [   ${WHITE_R}5${RESET}   ]  |  ${rc_version_available}"
      echo -e " [   ${WHITE_R}6${RESET}   ]  |  Cancel\\n\\n"
    else
      echo -e " [   ${WHITE_R}5${RESET}   ]  |  Cancel\\n\\n"
    fi
  fi

  if [[ "${unifi_version}" == "9.0.114" ]]; then
    read -rp $'Your choice | \033[39m' UPGRADE_VERSION
    case "$UPGRADE_VERSION" in
        1)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.1.120-e1aep1zs38"
          application_upgrade_releases
          unifi_update_finish;;
        2)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.2.87-uf39xch68k"
          application_upgrade_releases
          unifi_update_finish;;
        3)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.3.45-9iw96x349g"
          application_upgrade_releases
          unifi_update_finish;;
        4)
          if [[ "${release_stage}" == 'RC' ]]; then
            unifi_update_start
            unifi_firmware_requirement
            application_version="${rc_version_available_secret}"
            application_upgrade_releases
            unifi_update_finish
          else
            cancel_script
          fi;;
        5|*) cancel_script;;
    esac
  else
    read -rp $'Your choice | \033[39m' UPGRADE_VERSION
    case "$UPGRADE_VERSION" in
        1)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.0.114-k5dy363g65"
          application_upgrade_releases
          unifi_update_finish;;
        2)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.1.120-e1aep1zs38"
          application_upgrade_releases
          unifi_update_finish;;
        3)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.2.87-uf39xch68k"
          application_upgrade_releases
          unifi_update_finish;;
        4)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.3.45-9iw96x349g"
          application_upgrade_releases
          unifi_update_finish;;
        5)
          if [[ "${release_stage}" == 'RC' ]]; then
            unifi_update_start
            unifi_firmware_requirement
            application_version="${rc_version_available_secret}"
            application_upgrade_releases
            unifi_update_finish
          else
            cancel_script
          fi;;
        6|*) cancel_script;;
    esac
  fi

##########################################################################################################################################################################
#                                                                                                                                                                        #
#                                                                                  9.1.x                                                                                 #
#                                                                                                                                                                        #
##########################################################################################################################################################################

elif [[ "${first_digit_unifi}" == '9' && "${second_digit_unifi}" == '1' ]]; then
  release_wanted
  header
  echo "  To what UniFi Network Application version would you like to update?"
  echo -e "  Currently your UniFi Network Application is on version ${GRAY_R}$unifi${RESET}"
  echo -e "\\n  Release stage is set to | ${GRAY_R}${release_stage_friendly}${RESET}\\n\\n"
  if [[ "${unifi}" == "9.1.120" ]]; then
    unifi_version='9.1.120'
    echo -e " [   ${WHITE_R}1${RESET}   ]  |  9.2.87"
    echo -e " [   ${WHITE_R}2${RESET}   ]  |  9.3.45"
    if [[ "${release_stage}" == 'RC' ]]; then
      echo -e " [   ${WHITE_R}3${RESET}   ]  |  ${rc_version_available}"
      echo -e " [   ${WHITE_R}4${RESET}   ]  |  Cancel\\n\\n"
    else
      echo -e " [   ${WHITE_R}3${RESET}   ]  |  Cancel\\n\\n"
    fi
  else
    echo -e " [   ${WHITE_R}1${RESET}   ]  |  9.1.120"
    echo -e " [   ${WHITE_R}2${RESET}   ]  |  9.2.87"
    echo -e " [   ${WHITE_R}3${RESET}   ]  |  9.3.45"
    if [[ "${release_stage}" == 'RC' ]]; then
      echo -e " [   ${WHITE_R}4${RESET}   ]  |  ${rc_version_available}"
      echo -e " [   ${WHITE_R}5${RESET}   ]  |  Cancel\\n\\n"
    else
      echo -e " [   ${WHITE_R}4${RESET}   ]  |  Cancel\\n\\n"
    fi
  fi

  if [[ "${unifi_version}" == "9.1.120" ]]; then
    read -rp $'Your choice | \033[39m' UPGRADE_VERSION
    case "$UPGRADE_VERSION" in
        1)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.2.87-uf39xch68k"
          application_upgrade_releases
          unifi_update_finish;;
        2)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.3.45-9iw96x349g"
          application_upgrade_releases
          unifi_update_finish;;
        3)
          if [[ "${release_stage}" == 'RC' ]]; then
            unifi_update_start
            unifi_firmware_requirement
            application_version="${rc_version_available_secret}"
            application_upgrade_releases
            unifi_update_finish
          else
            cancel_script
          fi;;
        4|*) cancel_script;;
    esac
  else
    read -rp $'Your choice | \033[39m' UPGRADE_VERSION
    case "$UPGRADE_VERSION" in
        1)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.1.120-e1aep1zs38"
          application_upgrade_releases
          unifi_update_finish;;
        2)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.2.87-uf39xch68k"
          application_upgrade_releases
          unifi_update_finish;;
        3)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.3.45-9iw96x349g"
          application_upgrade_releases
          unifi_update_finish;;
        4)
          if [[ "${release_stage}" == 'RC' ]]; then
            unifi_update_start
            unifi_firmware_requirement
            application_version="${rc_version_available_secret}"
            application_upgrade_releases
            unifi_update_finish
          else
            cancel_script
          fi;;
        5|*) cancel_script;;
    esac
  fi

##########################################################################################################################################################################
#                                                                                                                                                                        #
#                                                                                  9.2.x                                                                                 #
#                                                                                                                                                                        #
##########################################################################################################################################################################

elif [[ "${first_digit_unifi}" == '9' && "${second_digit_unifi}" == '2' ]]; then
  release_wanted
  if [[ "${release_stage}" == 'S' ]]; then if [[ "${unifi}" == "${latest_release}" ]]; then debug_check_no_upgrade; unifi_update_latest; fi; fi
  header
  echo "  To what UniFi Network Application version would you like to update?"
  echo -e "  Currently your UniFi Network Application is on version ${GRAY_R}$unifi${RESET}"
  echo -e "\\n  Release stage is set to | ${GRAY_R}${release_stage_friendly}${RESET}\\n\\n"
  if [[ "${unifi}" == "9.2.87" ]]; then
    unifi_version='9.2.87'
    echo -e " [   ${WHITE_R}1${RESET}   ]  |  9.3.45"
    if [[ "${release_stage}" == 'RC' ]]; then
      echo -e " [   ${WHITE_R}2${RESET}   ]  |  ${rc_version_available}"
      echo -e " [   ${WHITE_R}3${RESET}   ]  |  Cancel\\n\\n"
    else
      echo -e " [   ${WHITE_R}2${RESET}   ]  |  Cancel\\n\\n"
    fi
  else
    echo -e " [   ${WHITE_R}1${RESET}   ]  |  9.2.87"
    echo -e " [   ${WHITE_R}2${RESET}   ]  |  9.3.45"
    if [[ "${release_stage}" == 'RC' ]]; then
      echo -e " [   ${WHITE_R}3${RESET}   ]  |  ${rc_version_available}"
      echo -e " [   ${WHITE_R}4${RESET}   ]  |  Cancel\\n\\n"
    else
      echo -e " [   ${WHITE_R}3${RESET}   ]  |  Cancel\\n\\n"
    fi
  fi

  if [[ "${unifi_version}" == "9.2.87" ]]; then
    read -rp $'Your choice | \033[39m' UPGRADE_VERSION
    case "$UPGRADE_VERSION" in
        1)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.3.45-9iw96x349g"
          application_upgrade_releases
          unifi_update_finish;;
        2)
          if [[ "${release_stage}" == 'RC' ]]; then
            unifi_update_start
            unifi_firmware_requirement
            application_version="${rc_version_available_secret}"
            application_upgrade_releases
            unifi_update_finish
          else
            cancel_script
          fi;;
        3|*) cancel_script;;
    esac
  else
    read -rp $'Your choice | \033[39m' UPGRADE_VERSION
    case "$UPGRADE_VERSION" in
        1)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.2.87-uf39xch68k"
          application_upgrade_releases
          unifi_update_finish;;
        2)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.3.45-9iw96x349g"
          application_upgrade_releases
          unifi_update_finish;;
        3)
          if [[ "${release_stage}" == 'RC' ]]; then
            unifi_update_start
            unifi_firmware_requirement
            application_version="${rc_version_available_secret}"
            application_upgrade_releases
            unifi_update_finish
          else
            cancel_script
          fi;;
        4|*) cancel_script;;
    esac
  fi

##########################################################################################################################################################################
#                                                                                                                                                                        #
#                                                                                  9.3.x                                                                                 #
#                                                                                                                                                                        #
##########################################################################################################################################################################

elif [[ "${first_digit_unifi}" == '9' && "${second_digit_unifi}" == '3' ]]; then
  if [[ "${third_digit_unifi}" -gt '45' ]]; then not_supported_version; fi
  release_wanted
  if [[ "${release_stage}" == 'RC' ]]; then if [[ "${unifi}" == "${rc_version_available}" ]]; then debug_check_no_upgrade; unifi_update_latest; fi; fi
  header
  echo "  To what UniFi Network Application version would you like to update?"
  echo -e "  Currently your UniFi Network Application is on version ${GRAY_R}$unifi${RESET}"
  echo -e "\\n  Release stage is set to | ${GRAY_R}${release_stage_friendly}${RESET}\\n\\n"
  if [[ "${unifi}" == "9.3.45" ]]; then
    unifi_version='9.3.45'
    #echo -e " [   ${WHITE_R}1${RESET}   ]  |  9.3.45"
    if [[ "${release_stage}" == 'RC' ]]; then
      echo -e " [   ${WHITE_R}1${RESET}   ]  |  ${rc_version_available}"
      echo -e " [   ${WHITE_R}2${RESET}   ]  |  Cancel\\n\\n"
    else
      echo -e " [   ${WHITE_R}1${RESET}   ]  |  Cancel\\n\\n"
    fi
  else
    echo -e " [   ${WHITE_R}1${RESET}   ]  |  9.3.45"
    if [[ "${release_stage}" == 'RC' ]]; then
      echo -e " [   ${WHITE_R}2${RESET}   ]  |  ${rc_version_available}"
      echo -e " [   ${WHITE_R}3${RESET}   ]  |  Cancel\\n\\n"
    else
      echo -e " [   ${WHITE_R}2${RESET}   ]  |  Cancel\\n\\n"
    fi
  fi

  if [[ "${unifi_version}" == "9.3.45" ]]; then
    read -rp $'Your choice | \033[39m' UPGRADE_VERSION
    case "$UPGRADE_VERSION" in
        1)
          if [[ "${release_stage}" == 'RC' ]]; then
            unifi_update_start
            unifi_firmware_requirement
            application_version="${rc_version_available_secret}"
            application_upgrade_releases
            unifi_update_finish
          else
            cancel_script
          fi;;
        2|*) cancel_script;;
    esac
  else
    read -rp $'Your choice | \033[39m' UPGRADE_VERSION
    case "$UPGRADE_VERSION" in
        1)
          unifi_update_start
          unifi_firmware_requirement
          application_version="9.3.45-9iw96x349g"
          application_upgrade_releases
          unifi_update_finish;;
        2)
          if [[ "${release_stage}" == 'RC' ]]; then
            unifi_update_start
            unifi_firmware_requirement
            application_version="${rc_version_available_secret}"
            application_upgrade_releases
            unifi_update_finish
          else
            cancel_script
          fi;;
        3|*) cancel_script;;
    esac
  fi
else
  not_supported_version
fi