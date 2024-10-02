#!/bin/bash

# UniFi Easy Encrypt script.
# Script   | UniFi Network Easy Encrypt Script
# Version  | 3.1.7
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
  echo -e "${WHITE_R}#${RESET} The script need to be run as root...\\n\\n"
  echo -e "${WHITE_R}#${RESET} For Ubuntu based systems run the command below to login as root"
  echo -e "${GREEN}#${RESET} sudo -i\\n"
  echo -e "${WHITE_R}#${RESET} For Debian based systems run the command below to login as root"
  echo -e "${GREEN}#${RESET} su\\n\\n"
  exit 1
fi

# Unset environment variables.
if [[ -n "${PAGER}" ]]; then unset PAGER; fi
if [[ -n "${LESS}" ]]; then unset LESS; fi

if ! grep -siq "udm" /usr/lib/version &> /dev/null; then
  if ! env | grep "LC_ALL\\|LANG" | grep -iq "en_US\\|C.UTF-8\\|en_GB.UTF-8"; then
    header
    echo -e "${WHITE_R}#${RESET} Your language is not set to English ( en_US ), the script will temporarily set the language to English."
    echo -e "${WHITE_R}#${RESET} Information: This is done to prevent issues in the script.."
    original_lang="$LANG"
    original_lcall="$LC_ALL"
    if [[ -e "/etc/locale.gen" ]]; then
      sed -i '/^#.*en_US.UTF-8 UTF-8/ s/^#.*\(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen 2> /dev/null
      if ! grep -q '^en_US.UTF-8 UTF-8' /etc/locale.gen; then echo 'en_US.UTF-8 UTF-8' &>> /etc/locale.gen; fi
    fi
    if ! locale -a 2> /dev/null | grep -iq "C.UTF-8\\|en_US.UTF-8"; then locale-gen en_US.UTF-8 &> /dev/null; fi
    if locale -a 2> /dev/null | grep -iq "^C.UTF-8$"; then eus_lts="C.UTF-8"; elif locale -a 2> /dev/null | grep -iq "^en_US.UTF-8$"; then eus_lts="en_US.UTF-8"; else  eus_lts="en_US.UTF-8"; fi
    export LANG="${eus_lts}" &> /dev/null
    export LC_ALL=C &> /dev/null
    set_lc_all="true"
    sleep 3
  fi
fi

retry_script_option() {
  if [[ -f "/root/EUS/eus-le-retry.sh" ]]; then
    number_of_aborts="$(head -n1 "${eus_dir}/retries_aborts")"
    echo "$((number_of_aborts+1))" &> "${eus_dir}/retries_aborts"
  fi
  if [[ "${script_option_retry}" == 'true' && "${script_option_fqdn}" == 'true' ]]; then
    echo -e "${WHITE_R}----${RESET}\\n"
    echo -e "${WHITE_R}#${RESET} Scheduling retry scripts!\\n"
    mkdir -p /root/EUS
    cp "${0}" /root/EUS/unifi-easy-encrypt.sh
    echo "0" &> "${eus_dir}/retries_aborts"
    curl "${curl_argument[@]}" --output "/root/EUS/script-retry.sh" https://get.glennr.nl/unifi/extra/easy-encrypt-addon-scripts/script-retry.sh
    sed -i "s|__template_eus_dir|${eus_dir}|g" "/root/EUS/script-retry.sh"
    {
      echo -e "SHELL=/bin/sh"
      echo -e "PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin"
      echo -e "*/15 * * * * root $(command -v bash) /root/EUS/script-retry.sh"
    } > /etc/cron.d/eus_lets_encrypt_retry
  fi
}

check_docker_setup() {
  if [[ -f /.dockerenv ]] || grep -sq '/docker/' /proc/1/cgroup || { command -v pgrep &>/dev/null && (pgrep -f "^dockerd" &>/dev/null || pgrep -f "^containerd" &>/dev/null); }; then docker_setup="true"; else docker_setup="false"; fi
  if [[ -n "$(command -v jq)" && -e "${eus_dir}/db/db.json" ]]; then
    if [[ "$(dpkg-query --showformat='${Version}' --show jq | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
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
    if [[ "$(dpkg-query --showformat='${Version}' --show jq | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
      jq '."database" += {"lxc-container": "'"${lxc_setup}"'"}' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
    else
      jq --arg lxc_setup "$lxc_setup" '.database = (.database + {"lxc-container": $lxc_setup})' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
    fi
    eus_database_move
  fi
}

locate_http_proxy() {
  env_proxies="$(grep -E "^[^#]*http_proxy|^[^#]*https_proxy" "/etc/environment" | awk -F '=' '{print $2}' | tr -d '"')"
  profile_proxies="$(find /etc/profile.d/ -type f -exec sh -c 'grep -E "^[^#]*http_proxy|^[^#]*https_proxy" "$1" | awk -F "=" "{print \$2}" | tr -d "\"" ' _ {} \;)"
  # Combine, normalize (remove trailing slashes), and sort unique proxies
  all_proxies="$(echo -e "$env_proxies\n$profile_proxies" | sed 's:/*$::' | sort -u | grep -v '^$')"
  http_proxy="$(echo "$all_proxies" | tail -n1)"
  if [[ -n "$(command -v jq)" && -e "${eus_dir}/db/db.json" ]]; then
    if [[ "$(dpkg-query --showformat='${Version}' --show jq | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
      json_proxies="$(echo "$all_proxies" | jq -R -s 'split("\n") | map(select(length > 0))')"
      jq --argjson proxies "$json_proxies" '.database."http-proxy" = $proxies' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
    else
      json_proxies="$(echo "$all_proxies" | awk 'NF' | awk '{ printf "%s\n", $0 }' | sed 's/^/"/;s/$/"/' | paste -sd, - | sed 's/^/[/;s/$/]/')"
      jq '.database["http-proxy"] = '"$json_proxies"'' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
    fi
    eus_database_move
  fi
}

update_eus_db() {
  if [[ -n "$(command -v jq)" && -e "${eus_dir}/db/db.json" ]]; then
    if [[ -n "${script_local_version_dots}" ]]; then
      if [[ "$(dpkg-query --showformat='${Version}' --show jq | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
        jq '.scripts."'"${script_name}"'" |= if .["versions-ran"] | index("'"${script_local_version_dots}"'") | not then .["versions-ran"] += ["'"${script_local_version_dots}"'"] else . end' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
      else
        jq --arg script_name "$script_name" --arg script_local_version_dots "$script_local_version_dots" '.scripts[$script_name] |= (if (.["versions-ran"] | map(select(. == $script_local_version_dots)) | length == 0) then .["versions-ran"] += [$script_local_version_dots] else . end)' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
      fi
      eus_database_move
    fi
    if [[ -z "${abort_reason}" ]]; then
      if [[ "$(dpkg-query --showformat='${Version}' --show jq | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
        script_success="$(jq -r '.scripts."'"${script_name}"'".success' "${eus_dir}/db/db.json")"
      else
        script_success="$(jq --arg script_name "$script_name"  -r '.scripts[$script_name]["success"]' "${eus_dir}/db/db.json")"
      fi
      ((script_success=script_success+1))
      if [[ "$(dpkg-query --showformat='${Version}' --show jq | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
        jq --arg script_success "${script_success}" '."scripts"."'"${script_name}"'" += {"success": "'"${script_success}"'"}' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
      else
        jq --arg script_name "$script_name" --arg script_success "$script_success" '.scripts[$script_name] += {"success": $script_success}' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
      fi
      eus_database_move
    fi
    if [[ "${update_at_support_file}" != 'true' ]]; then
      if [[ "$(dpkg-query --showformat='${Version}' --show jq | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
        script_total_runs="$(jq -r '.scripts."'"${script_name}"'"."total-runs"' "${eus_dir}/db/db.json")"
      else
        script_total_runs="$(jq --arg script_name "$script_name"  -r '.scripts[$script_name]["total-runs"]' "${eus_dir}/db/db.json")"
      fi
      ((script_total_runs=script_total_runs+1))
      if [[ "$(dpkg-query --showformat='${Version}' --show jq | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
        jq --arg script_total_runs "${script_total_runs}" '."scripts"."'"${script_name}"'" += {"total-runs": "'"${script_total_runs}"'"}' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
      else
        jq --arg script_name "$script_name" --arg script_total_runs "$script_total_runs" '.scripts[$script_name] |= (. + {"total-runs": $script_total_runs})' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
      fi
      eus_database_move
    fi
    if [[ "${update_at_start_script}" == 'true' ]]; then
      if [[ "$(dpkg-query --showformat='${Version}' --show jq | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
        jq '."scripts"."'"${script_name}"'" += {"last-run": "'"$(date +%s)"'"}' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
      else
        jq --arg script_name "$script_name" --arg last_run "$(date +%s)" '.scripts[$script_name] |= (. + {"last-run": $last_run})' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
      fi
      eus_database_move
      unset update_at_start_script
    fi
    json_system_dns_servers="$(echo "$system_dns_servers" | sed 's/[()]//g' | tr ' ' '\n' | jq -R . | jq -s . | jq -c .)"
    if [[ "$(dpkg-query --showformat='${Version}' --show jq | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
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
      echo -e "$(date +%F-%R) | \"${eus_database_move_file}.tmp\" is empty." >> "${eus_database_move_log_file}"
    else
      echo -e "$(date +%F-%R) | \"${eus_database_move_file}.tmp\" does not contain valid JSON. Contents:" >> "${eus_database_move_log_file}"
      cat "${eus_database_move_file}.tmp" >> "${eus_database_move_log_file}"
    fi
  fi
  unset eus_database_move_file
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
  echo -e "${WHITE_R}#${RESET} Creating support file..."
  eus_directory_location="/tmp/EUS"
  eus_create_directories "support"
  if "$(which dpkg)" -l lsb-release 2> /dev/null | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then lsb_release -a &> "/tmp/EUS/support/lsb-release"; else cat /etc/os-release &> "/tmp/EUS/support/os-release"; fi
  if [[ -n "$(command -v jq)" && "$(dpkg-query --showformat='${Version}' --show jq | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
    df -hP | awk 'BEGIN {print"{\"disk-usage\":["}{if($1=="Filesystem")next;if(a)print",";print"{\"mount\":\""$6"\",\"size\":\""$2"\",\"used\":\""$3"\",\"avail\":\""$4"\",\"use%\":\""$5"\"}";a++;}END{print"]}";}' | jq &> "/tmp/EUS/support/disk-usage.json"
  else
    df -h &> "/tmp/EUS/support/df"
  fi
  if [[ "${unifi_core_system}" != 'true' && -n "$(apt-cache search debsums | awk '/debsums/{print$1}')" ]]; then
    if ! [[ "$(command -v debsums)" ]]; then DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install debsums &>> "${eus_dir}/logs/apt.log"; fi
    if [[ "$(command -v debsums)" ]]; then debsums -c &> "/tmp/EUS/support/debsums-check-results"; fi
  fi
  uname -a &> "/tmp/EUS/support/uname-results"
  lscpu &> "/tmp/EUS/support/lscpu-results"
  dmesg &> "/tmp/EUS/support/dmesg-results"
  locale &> "/tmp/EUS/support/locale-results"
  {
    echo -e "-----( --get-selections )----- \n"; update-alternatives --get-selections 2> /dev/null
    echo -e "-----( --display java )----- \n"; update-alternatives --display java 2> /dev/null
    echo -e "-----( JAVA_HOME results )----- \n"; grep -r 'JAVA_HOME' /etc/ 2> /dev/null
    echo -e "-----( readlink java )----- \n"; readlink -f /usr/bin/java 2> /dev/null
  } >> "/tmp/EUS/support/java-details.log"
  grep -is '^unifi:' /etc/passwd /etc/group &> "/tmp/EUS/support/unifi-user-group-results"
  find /usr/sbin -name "unifi*" -type f -print0 | xargs -0 -I {} sh -c 'echo -e "\n------[ {} ]------\n"; cat "{}"; echo;' &> "/tmp/EUS/support/unifi-helper-results"
  ps -p $$ -o command= &> "/tmp/EUS/support/script-usage"
  echo "$PATH" &> "/tmp/EUS/support/PATH"
  cp "${script_location}" "/tmp/EUS/support/${script_file_name}" &> /dev/null
  "$(which dpkg)" -l | grep "mongo\\|oracle\\|openjdk\\|unifi\\|temurin" &> "/tmp/EUS/support/unifi-packages-list"
  "$(which dpkg)" -l &> "/tmp/EUS/support/dpkg-packages-list"
  journalctl -u unifi -p debug --since "1 week ago" --no-pager &> "/tmp/EUS/support/ujournal.log"
  journalctl --since yesterday --no-pager &> "/tmp/EUS/support/journal.log"
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
    if [[ "$(dpkg-query --showformat='${Version}' --show jq | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
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
  # shellcheck disable=SC2129
  sed -n '3p' "${script_location}" &>> "/tmp/EUS/support/script"
  grep "# Version" "${script_location}" | head -n1 &>> "/tmp/EUS/support/script"
  #
  echo "${server_fqdn}" &>> "/tmp/EUS/support/fqdn"
  echo "${server_ip}" &>> "/tmp/EUS/support/ip"
  #
  support_file_time="$(date +%Y%m%d-%H%M-%S%N)"
  if [[ -n "$(command -v jq)" && -f "${eus_dir}/db/db.json" ]]; then support_file_uuid="$(jq -r '.database.uuid' "${eus_dir}/db/db.json")-"; fi
  if "$(which dpkg)" -l xz-utils 2> /dev/null | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
    support_file="/tmp/eus-support-${support_file_uuid}${support_file_time}.tar.xz"
    support_file_name="$(basename "${support_file}")"
    if [[ "$(dpkg-query --showformat='${Version}' --show jq | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
      jq '.scripts."'"${script_name}"'" |= . + {"support": (.support + {("'"${support_file_name}"'"): {"abort-reason": "'"${abort_reason}"'","upload-results": ""}})}' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
    else
      jq --arg script_name "$script_name" --arg support_file_name "$support_file_name" --arg abort_reason "$abort_reason" '.scripts[$script_name] |= (. + {support: ((.support // {}) + {($support_file_name): {"abort-reason": $abort_reason,"upload-results": ""}})})' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
    fi
    eus_database_move
    tar cJvfh "${support_file}" --exclude="${eus_dir}/go.tar.gz" --exclude="${eus_dir}/unifi_db" --exclude="/tmp/EUS/downloads" --exclude="/usr/lib/unifi/logs/remote" "/tmp/EUS" "${eus_dir}" "/usr/lib/unifi/logs" "/etc/apt/sources.list" "/etc/apt/sources.list.d/" "/etc/apt/preferences" "/etc/apt/keyrings" "/etc/apt/trusted.gpg.d/" "/etc/apt/preferences.d/" "/etc/default/unifi" "/etc/environment" "/var/log/dpkg.log"* "/etc/systemd/system/unifi.service.d/" "/lib/systemd/system/unifi.service" "/usr/lib/unifi/data/db/version" "/var/lib/apt/" &> /dev/null
  elif "$(which dpkg)" -l zstd 2> /dev/null | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
    support_file="/tmp/eus-support-${support_file_uuid}${support_file_time}.tar.zst"
    support_file_name="$(basename "${support_file}")"
    if [[ "$(dpkg-query --showformat='${Version}' --show jq | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
      jq '.scripts."'"${script_name}"'" |= . + {"support": (.support + {("'"${support_file_name}"'"): {"abort-reason": "'"${abort_reason}"'","upload-results": ""}})}' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
    else
      jq --arg script_name "$script_name" --arg support_file_name "$support_file_name" --arg abort_reason "$abort_reason" '.scripts[$script_name] |= (. + {support: ((.support // {}) + {($support_file_name): {"abort-reason": $abort_reason,"upload-results": ""}})})' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
    fi
    eus_database_move
    tar --use-compress-program=zstd -cvf "${support_file}" --exclude="${eus_dir}/go.tar.gz" --exclude="${eus_dir}/unifi_db" --exclude="/tmp/EUS/downloads" --exclude="/usr/lib/unifi/logs/remote" "/tmp/EUS" "${eus_dir}" "/usr/lib/unifi/logs" "/etc/apt/sources.list" "/etc/apt/sources.list.d/" "/etc/apt/preferences" "/etc/apt/keyrings" "/etc/apt/trusted.gpg.d/" "/etc/apt/preferences.d/" "/etc/default/unifi" "/etc/environment" "/var/log/dpkg.log"* "/etc/systemd/system/unifi.service.d/" "/lib/systemd/system/unifi.service" "/usr/lib/unifi/data/db/version" "/var/lib/apt/" &> /dev/null
  elif "$(which dpkg)" -l tar 2> /dev/null | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
    support_file="/tmp/eus-support-${support_file_uuid}${support_file_time}.tar.gz"
    support_file_name="$(basename "${support_file}")"
    if [[ "$(dpkg-query --showformat='${Version}' --show jq | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
      jq '.scripts."'"${script_name}"'" |= . + {"support": (.support + {("'"${support_file_name}"'"): {"abort-reason": "'"${abort_reason}"'","upload-results": ""}})}' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
    else
      jq --arg script_name "$script_name" --arg support_file_name "$support_file_name" --arg abort_reason "$abort_reason" '.scripts[$script_name] |= (. + {support: ((.support // {}) + {($support_file_name): {"abort-reason": $abort_reason,"upload-results": ""}})})' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
    fi
    eus_database_move
    tar czvfh "${support_file}" --exclude="${eus_dir}/go.tar.gz" --exclude="${eus_dir}/unifi_db" --exclude="/tmp/EUS/downloads" --exclude="/usr/lib/unifi/logs/remote" "/tmp/EUS" "${eus_dir}" "/usr/lib/unifi/logs" "/etc/apt/sources.list" "/etc/apt/sources.list.d/" "/etc/apt/preferences" "/etc/apt/keyrings" "/etc/apt/trusted.gpg.d/" "/etc/apt/preferences.d/" "/etc/default/unifi" "/etc/environment" "/var/log/dpkg.log"* "/etc/systemd/system/unifi.service.d/" "/lib/systemd/system/unifi.service" "/usr/lib/unifi/data/db/version" "/var/lib/apt/" &> /dev/null
  elif "$(which dpkg)" -l zip 2> /dev/null | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
    support_file="/tmp/eus-support-${support_file_uuid}${support_file_time}.zip"
    support_file_name="$(basename "${support_file}")"
    if [[ "$(dpkg-query --showformat='${Version}' --show jq | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
      jq '.scripts."'"${script_name}"'" |= . + {"support": (.support + {("'"${support_file_name}"'"): {"abort-reason": "'"${abort_reason}"'","upload-results": ""}})}' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
    else
      jq --arg script_name "$script_name" --arg support_file_name "$support_file_name" --arg abort_reason "$abort_reason" '.scripts[$script_name] |= (. + {support: ((.support // {}) + {($support_file_name): {"abort-reason": $abort_reason,"upload-results": ""}})})' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
    fi
    eus_database_move
    zip -r "${support_file}" "/tmp/EUS/" "${eus_dir}/" "/usr/lib/unifi/logs/" "/etc/apt/sources.list" "/etc/apt/sources.list.d/" "/etc/apt/preferences" "/etc/apt/keyrings" "/etc/apt/trusted.gpg.d/" "/etc/apt/preferences.d/" "/etc/default/unifi" "/etc/environment" "/var/log/dpkg.log"* "/etc/systemd/system/unifi.service.d/" "/lib/systemd/system/unifi.service" "/usr/lib/unifi/data/db/version" "/var/lib/apt/" -x "${eus_dir}/go.tar.gz" -x "${eus_dir}/unifi_db/*" -x "/tmp/EUS/downloads" -x "/usr/lib/unifi/logs/remote" &> /dev/null
  fi
  if [[ -n "${support_file}" ]]; then
    echo -e "${WHITE_R}#${RESET} Support file has been created here: ${support_file} \\n"
    if [[ -n "$(command -v jq)" && -f "${eus_dir}/db/db.json" && "${abort_skip_support_file_upload}" != 'true' ]]; then
      if [[ "$(jq -r '.database["support-file-upload"]' "${eus_dir}/db/db.json")" != 'true' ]]; then
        read -rp $'\033[39m#\033[0m Do you want to upload the support file so that Glenn R. can review it and improve the script? (Y/n) ' yes_no
        case "$yes_no" in
             [Yy]*|"") eus_support_one_time_upload="true";;
             [Nn]*) ;;
        esac
      fi
      if [[ "$(jq -r '.database["support-file-upload"]' "${eus_dir}/db/db.json")" == 'true' ]] || [[ "${eus_support_one_time_upload}" == 'true' ]]; then
        upload_result="$(curl "${curl_argument[@]}" -X POST -F "file=@${support_file}" "https://api.glennr.nl/api/eus-support" 2> /dev/null | jq -r '.[]' 2> /dev/null)"
        if [[ "$(dpkg-query --showformat='${Version}' --show jq | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
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
  if [[ -n "${abort_reason}" ]]; then echo -e "${RED}#${RESET} ${abort_reason}.. \\n"; fi
  if [[ -n "$(command -v jq)" && -f "${eus_dir}/db/db.json" ]]; then
    if [[ "$(dpkg-query --showformat='${Version}' --show jq | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
      script_aborts="$(jq -r '.scripts."'"${script_name}"'".aborts' "${eus_dir}/db/db.json")"
    else
      script_aborts="$(jq --arg script_name "$script_name" -r '.scripts[$script_name].aborts' "${eus_dir}/db/db.json")"
    fi
    ((script_aborts=script_aborts+1))
    if [[ "$(dpkg-query --showformat='${Version}' --show jq | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
      jq --arg script_aborts "${script_aborts}" '."scripts"."'"${script_name}"'" += {"aborts": "'"${script_aborts}"'"}' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
    else
      jq --arg script_name "$script_name" --arg script_aborts "$script_aborts" '.scripts[$script_name] += {"aborts": $script_aborts}' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
    fi
    eus_database_move
  fi
  if [[ "${set_lc_all}" == 'true' ]]; then if [[ -n "${original_lang}" ]]; then export LANG="${original_lang}"; else unset LANG; fi; if [[ -n "${original_lcall}" ]]; then export LC_ALL="${original_lcall}"; else unset LC_ALL; fi; fi
  if [[ "${stopped_unattended_upgrade}" == 'true' ]]; then systemctl start unattended-upgrades &>> "${eus_dir}/logs/unattended-upgrades.log"; unset stopped_unattended_upgrade; fi
  echo -e "\\n\\n${RED}#########################################################################${RESET}\\n"
  echo -e "${WHITE_R}#${RESET} An error occurred. Aborting script..."
  echo -e "${WHITE_R}#${RESET} Please contact Glenn R. (AmazedMender16) on the Community Forums!\\n"
  retry_script_option
  support_file
  update_eus_db
  cleanup_codename_mismatch_repos
  exit 1
}

cancel_script() {
  if [[ "${set_lc_all}" == 'true' ]]; then if [[ -n "${original_lang}" ]]; then export LANG="${original_lang}"; else unset LANG; fi; if [[ -n "${original_lcall}" ]]; then export LC_ALL="${original_lcall}"; else unset LC_ALL; fi; fi
  if [[ "${stopped_unattended_upgrade}" == 'true' ]]; then systemctl start unattended-upgrades &>> "${eus_dir}/logs/unattended-upgrades.log"; unset stopped_unattended_upgrade; fi
  if [[ "${script_option_skip}" == 'true' ]]; then
    echo -e "\\n${WHITE_R}#########################################################################${RESET}\\n"
  else
    header
  fi
  echo -e "${WHITE_R}#${RESET} Cancelling the script!\\n\\n"
  author
  update_eus_db
  cleanup_codename_mismatch_repos
  exit 0
}

if uname -a | tr '[:upper:]' '[:lower:]' | grep -iq "cloudkey\\|uck\\|ubnt-mtk"; then
  eus_dir='/srv/EUS'
  is_cloudkey=true
  if grep -iq "UCKP" /usr/lib/version; then is_cloudkey_gen2_plus=true; fi
elif grep -iq "UCKP\\|UCKG2\\|UCK" /usr/lib/version &> /dev/null; then
  eus_dir='/srv/EUS'
  is_cloudkey=true
  if grep -iq "UCKP" /usr/lib/version; then is_cloudkey_gen2_plus=true; fi
elif "$(which dpkg)" -l unifi-core 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
  eus_dir='/srv/EUS'
  is_cloudkey=false
  is_cloudkey_gen2_plus=false
else
  eus_dir='/usr/lib/EUS'
  is_cloudkey=false
  is_cloudkey_gen2_plus=false
fi
if [[ "${eus_dir}" == '/srv/EUS' ]]; then if findmnt -no OPTIONS "$(df --output=target /srv | tail -1)" | grep -ioq "ro"; then eus_dir='/usr/lib/EUS'; fi; fi

check_dig_curl() {
  if [[ "${run_ipv6}" == 'true' ]]; then
    dig_option='AAAA'
    curl_option='-6'
  else
    dig_option='A'
    curl_option='-4'
  fi
}

check_dns() {
  system_dns_servers="($(grep -s '^nameserver' /etc/resolv.conf /run/systemd/resolve/resolv.conf | awk '{print $2}'))"
  local domains=("mongodb.com" "repo.mongodb.org" "ubuntu.com" "ui.com" "ubnt.com" "glennr.nl" "raspbian.org" "adoptium.org")
  if command -v host &> /dev/null; then dns_check_command="host"; elif command -v ping &> /dev/null; then dns_check_command="ping -c 1 -W2"; fi
  if [[ -n "${dns_check_command}" ]]; then
    for domain in "${domains[@]}"; do
      if ! ${dns_check_command} "${domain}" &> /dev/null; then
        echo -e "Failed to resolve ${domain}..." &>> "${eus_dir}/logs/dns-check.log"
        local dns_servers=("1.1.1.1" "8.8.8.8")
        for dns_server in "${dns_servers[@]}"; do
          if ! grep -qF "${dns_server}" /etc/resolv.conf; then
            if echo "nameserver ${dns_server}" | tee -a /etc/resolv.conf >/dev/null; then
              echo -e "Added ${dns_server} to /etc/resolv.conf..." &>> "${eus_dir}/logs/dns-check.log"
              if ${dns_check_command} "${domain}" &> /dev/null; then
                echo -e "Successfully resolved ${domain} after adding ${dns_server}." &>> "${eus_dir}/logs/dns-check.log"
                return 0
              fi
            fi
          fi
        done
        return 1
      fi
    done
  fi
  return 1
}

check_repository_key_permissions() {
  if [[ "$(stat -c %a "${repository_key_location}")" != "644" ]]; then
    if chmod 644 "${repository_key_location}" &>> "${eus_dir}/logs/update-repository-key-permissions.log"; then
      echo -e "$(date +%F-%R) | Successfully updated the permissions for ${repository_key_location} to 644!" &>> "${eus_dir}/logs/update-repository-key-permissions.log"
    else
      echo -e "$(date +%F-%R) | Failed to set the permissions for ${repository_key_location} to 644..." &>> "${eus_dir}/logs/update-repository-key-permissions.log"
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

set_curl_arguments() {
  if [[ "$(command -v jq)" ]]; then ssl_check_status="$(curl --silent "https://api.glennr.nl/api/ssl-check" 2> /dev/null | jq -r '.status' 2> /dev/null)"; else ssl_check_status="$(curl --silent "https://api.glennr.nl/api/ssl-check" 2> /dev/null | grep -oP '(?<="status":")[^"]+')"; fi
  if [[ "${ssl_check_status}" != "OK" ]]; then
    if [[ -e "/etc/ssl/certs/" ]]; then
      if [[ "$(command -v jq)" ]]; then ssl_check_status="$(curl --silent --capath /etc/ssl/certs/ "https://api.glennr.nl/api/ssl-check" 2> /dev/null | jq -r '.status' 2> /dev/null)"; else ssl_check_status="$(curl --silent --capath /etc/ssl/certs/ "https://api.glennr.nl/api/ssl-check" 2> /dev/null | grep -oP '(?<="status":")[^"]+')"; fi
      if [[ "${ssl_check_status}" == "OK" ]]; then curl_args="--capath /etc/ssl/certs/"; fi
    fi
    if [[ -z "${curl_args}" && "${ssl_check_status}" != "OK" ]]; then curl_args="--insecure"; fi
  fi
  if [[ -z "${curl_args}" ]]; then curl_args="--silent"; elif [[ "${curl_args}" != *"--silent"* ]]; then curl_args+=" --silent"; fi
  if [[ "${curl_args}" != *"--show-error"* ]]; then curl_args+=" --show-error"; fi
  if [[ "${curl_args}" != *"--retry"* ]]; then curl_args+=" --retry 3"; fi
  IFS=' ' read -r -a curl_argument <<< "${curl_args}"
  trimmed_args="${curl_args//--silent/}"
  trimmed_args="$(echo "$trimmed_args" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
  IFS=' ' read -r -a nos_curl_argument <<< "${trimmed_args}"
}
if [[ "$(command -v curl)" ]]; then set_curl_arguments; fi

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

create_remove_files() {
  script_location="${BASH_SOURCE[0]}"
  if ! [[ -f "${script_location}" ]]; then header_red; echo -e "${YELLOW}#${RESET} The script needs to be saved on the disk in order to work properly, please follow the instructions...\\n${YELLOW}#${RESET} Usage: curl -sO https://get.glennr.nl/unifi/extra/unifi-easy-encrypt.sh && bash unifi-easy-encrypt.sh\\n\\n"; exit 1; fi
  script_file_name="$(basename "${BASH_SOURCE[0]}")"
  script_name="$(grep -i "# Script" "${script_location}" | head -n 1 | cut -d'|' -f2 | sed -e 's/^ //g')"
  rm --force "${eus_dir}/other_domain_records" &> /dev/null
  rm --force "${eus_dir}/le_domain_list" &> /dev/null
  rm --force "${eus_dir}/fqdn_option_domains" &> /dev/null
  eus_directory_location="${eus_dir}"
  eus_create_directories "logs" "checksum"
  if ! [[ -d "/etc/apt/keyrings" ]]; then if ! install -m "0755" -d "/etc/apt/keyrings" &>> "${eus_dir}/logs/keyrings-directory-creation.log"; then if ! mkdir -p "/etc/apt/keyrings" &>> "${eus_dir}/logs/keyrings-directory-creation.log"; then abort_reason="Failed to create /etc/apt/keyrings."; abort; fi; fi; if ! [[ -s "${eus_dir}/logs/keyrings-directory-creation.log" ]]; then rm --force "${eus_dir}/logs/keyrings-directory-creation.log"; fi; fi
  mkdir -p /tmp/EUS/keys &> /dev/null
  if find /etc/apt/sources.list.d/ -name "*.sources" | grep -ioq /etc/apt; then use_deb822_format="true"; fi
  if [[ "${use_deb822_format}" == 'true' ]]; then source_file_format="sources"; else source_file_format="list"; fi
}
create_remove_files

script_logo() {
  cat << "EOF"

  _______________ ___ _________   _____________________
  \_   _____|    |   /   _____/   \_   _____\_   _____/
   |    __)_|    |   \_____  \     |    __)_ |    __)_ 
   |        |    |  //        \    |        \|        \
  /_______  |______//_______  /   /_______  /_______  /
          \/                \/            \/        \/ 

EOF
}

start_script() {
  header
  script_logo
  echo -e "    UniFi Easy Encrypt Script!"
  echo -e "\\n${WHITE_R}#${RESET} Starting the UniFi Easy Encrypt Script..."
  echo -e "${WHITE_R}#${RESET} Thank you for using my UniFi Easy Encrypt Script :-)\\n\\n"
  if [[ "${update_at_start_script}" != 'true' ]]; then update_at_start_script="true"; update_eus_db; fi
  if pgrep -f unattended-upgrade &> /dev/null; then if systemctl stop unattended-upgrades &>> "${eus_dir}/logs/unattended-upgrades.log"; then stopped_unattended_upgrade="true"; fi; fi
}
start_script
check_dns
check_apt_listbugs

help_script() {
  check_apt_listbugs
  if [[ "${script_option_help}" == 'true' ]]; then header; script_logo; else echo -e "${WHITE_R}----${RESET}\\n"; fi
  echo -e "    UniFi Easy Encrypt script assistance\\n"
  echo -e "
  Script usage:
  bash ${script_file_name} [options]
  
  Script options:
    --skip                                  Skip any kind of manual input.
    --skip-network-application              Skip importing certificates into the Network application
                                            on a UniFi OS Console.
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
    --custom-acme-server [argument]         Specify a custom ACME server.
                                            example:
                                            --custom-acme-server https://acme-staging-v02.api.letsencrypt.org/directory
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
                                            Supported providers: cloudflare, digitalocean, dnsimple, gehirn, google, linode, luadns, nsone, ovh, rfc2136, route53, sakuracloud
                                            Other providers (not supported on UniFi Consoles): dnsmadeeasy, akamaiedgedns, alibabaclouddns, allinkl, amazonlightsail, arvancloud, auroradns, autodns, azuredns, bindman, 
                                            bluecat, brandit, bunny, checkdomain, civo, cloudru, clouddns, cloudns, cloudxns, conoha, constellix, derakcloud, desecio, designatednsaasforopenstack, dnshomede, 
                                            domainoffensive, domeneshop, dreamhost, duckdns, dyn, dynu, easydns, efficientip, epik, exoscale, externalprogram, freemyip, gcore, gandi, gandilivedns, glesys, 
                                            godaddy, hetzner, hostingde, hosttech, httprequest, httpnet, hurricaneelectricdns, hyperone, ibmcloud, iijdnsplatformservice, infoblox, infomaniak, internetinitiativejapan, 
                                            internetbs, inwx, ionos, ipv64, iwantmyname joker joohoisacmedns liara liquidweb loopia metaname mydnsjp mythicbeasts namecom namecheap namesilo nearlyfreespeechnet netcup,
                                            netlify, nicmanager, nifcloud, njalla, nodion, opentelekomcloud, oraclecloud, pleskcom, porkbun, powerdns, rackspace, rcodezero, regru, rimuhosting, scaleway,
                                            selectel, servercow, simplycom, sonic, stackpath, tencentclouddns, transip, ukfastsafedns, ultradns, variomedia, vegadns, vercel, versionl, versioeu, versiouk,
                                            vinyldns, vkcloud, vscale, vultr, webnames, websupport, wedos, yandex360, yandexcloud, yandexpdd, zoneee, zonomi,
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
    --prevent-modify-firewall               Dont automatically open/close port 80 on UniFi Gateway Consoles.
    --restore                               Restore previous certificate/config files.
    --help                                  Shows this information :) \\n\\n"
  exit 0
}

rm --force /tmp/EUS/le_script_options &> /dev/null
rm --force /tmp/EUS/script_options &> /dev/null
script_option_list=(-skip --skip --skip-network-application --install-script --v6 --ipv6 --email --mail --fqdn --domain-name --server-ip --server-address --custom-acme-server --retry --external-dns --force-renew --renew --dns --dns-challenge --priv-key --private-key --signed-crt --signed-certificate --chain-crt --chain-certificate --intermediate-crt --intermediate-certificate --own-certificate --restore --prevent-modify-firewall --help --dns-provider-credentials --dns-provider)
dns_provider_list=(cloudflare digitalocean dnsimple gehirn google linode luadns nsone ovh rfc2136 route53 sakuracloud)
dns_multi_provider_list=(dnsmadeeasy akamaiedgedns alibabaclouddns allinkl amazonlightsail arvancloud auroradns autodns azuredns bindman bluecat brandit bunny checkdomain civo cloudru clouddns cloudns cloudxns conoha constellix derakcloud desecio designatednsaasforopenstack dnshomede domainoffensive domeneshop dreamhost duckdns dyn dynu easydns efficientip epik exoscale externalprogram freemyip gcore gandi gandilivedns glesys godaddy hetzner hostingde hosttech httprequest httpnet hurricaneelectricdns hyperone ibmcloud iijdnsplatformservice infoblox infomaniak internetinitiativejapan internetbs inwx ionos ipv64 iwantmyname joker joohoisacmedns liara liquidweb loopia metaname mydnsjp mythicbeasts namecom namecheap namesilo nearlyfreespeechnet netcup netlify nicmanager nifcloud njalla nodion opentelekomcloud oraclecloud pleskcom porkbun powerdns rackspace rcodezero regru rimuhosting scaleway selectel servercow simplycom sonic stackpath tencentclouddns transip ukfastsafedns ultradns variomedia vegadns vercel versionl versioeu versiouk vinyldns vkcloud vscale vultr webnames websupport wedos yandex360 yandexcloud yandexpdd zoneee zonomi)

while [ -n "$1" ]; do
  case "$1" in
  -skip | --skip)
       old_certificates=all
       script_option_skip=true
       echo "--skip" &>> /tmp/EUS/script_options;;
  --skip-network-application)
       if dpkg -l unifi-core 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
         script_option_skip_network_application=true
         echo "--skip-network-application" &>> /tmp/EUS/script_options
       fi;;
  --install-script)
       install_script=true
       echo "--install-script" &>> /tmp/EUS/script_options;;
  --v6 | --ipv6)
       run_ipv6=true
       echo "--v6" &>> /tmp/EUS/script_options;;
  --email | --mail)
       for option in "${script_option_list[@]}"; do
         if [[ "${2}" == "${option}" ]]; then header_red; echo -e "${WHITE_R}#${RESET} Option ${1} requires a command argument... \\n\\n"; help_script; fi
       done
       le_user_mail="$2"
       email_reg='^(([A-Za-z0-9]+((\.|\-|\_|\+)?[A-Za-z0-9]?)*[A-Za-z0-9]+)|[A-Za-z0-9]+)@(([A-Za-z0-9]+)+((\.|\-|\_)?([A-Za-z0-9]+)+)*)+\.([A-Za-z]{2,})+$'
       if ! [[ "${le_user_mail}" =~ ${email_reg} ]]; then email="--register-unsafely-without-email"; else email="--email ${le_user_mail}"; fi
       script_option_email=true
       echo "--email ${2}" &>> /tmp/EUS/script_options
       shift;;
  --fqdn | --domain-name)
       for option in "${script_option_list[@]}"; do
         if [[ "${2}" == "${option}" ]]; then header_red; echo -e "${WHITE_R}#${RESET} Option ${1} requires a command argument... \\n\\n"; help_script; fi
       done
       echo "$2" &> "${eus_dir}/fqdn_option_le.tmp"
       sed $'s/:/\\\n/g' < "${eus_dir}/fqdn_option_le.tmp" &> "${eus_dir}/fqdn_option_le"
       rm --force "${eus_dir}/fqdn_option_le.tmp"
       awk '!a[$0]++' "${eus_dir}/fqdn_option_le" >> "${eus_dir}/fqdn_option_domains" && rm --force "${eus_dir}/fqdn_option_le"
       script_option_fqdn=true
       echo "--fqdn ${2}" &>> /tmp/EUS/script_options
       shift;;
  --server-ip | --server-address)
       for option in "${script_option_list[@]}"; do
         if [[ "${2}" == "${option}" ]]; then header_red; echo -e "${WHITE_R}#${RESET} Option ${1} requires a command argument... \\n\\n"; help_script; fi
       done
       server_ip="$2"
       echo "${server_ip}" &> "${eus_dir}/server_ip"
       manual_server_ip="true"
       echo "--server-ip ${2}" &>> /tmp/EUS/script_options
       shift;;
  --custom-acme-server)
       for option in "${script_option_list[@]}"; do
         if [[ "${2}" == "${option}" ]]; then header_red; echo -e "${WHITE_R}#${RESET} Option ${1} requires a command argument... \\n\\n"; help_script; fi
       done
       custom_acme_server="$2"
       acme_server="--server ${2}"
       echo "${custom_acme_server}" &> "${eus_dir}/custom_acme_server"
       echo "--custom-acme-server ${2}" &>> /tmp/EUS/script_options
       shift;;
  --retry)
       for option in "${script_option_list[@]}"; do
         if [[ "${2}" == "${option}" ]]; then header_red; echo -e "${WHITE_R}#${RESET} Option ${1} requires a command argument... \\n\\n"; help_script; fi
       done
       if ! [[ "${2}" =~ ^[0-9]+$ ]]; then header_red; echo -e "${WHITE_R}#${RESET} '${2}' is not a valid command argument for ${1}... \\n\\n"; help_script; fi
       retries="$2"
       echo "${retries}" &> "${eus_dir}/retries"
       script_option_retry="true"
       echo "--retry ${2}" &>> /tmp/EUS/script_options
       shift;;
  --external-dns)
       if [[ -n "${2}" ]]; then echo -ne "\\r${WHITE_R}#${RESET} Checking if ${2} is a valid DNS server...\\n"; if [[ "${2}" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then if [[ "$(echo "${2}" | cut -d'.' -f1)" -le '255' && "$(echo "${2}" | cut -d'.' -f2)" -le '255' && "$(echo "${2}" | cut -d'.' -f3)" -le '255' && "$(echo "${2}" | cut -d'.' -f4)" -le '255' ]]; then ip_valid=true; elif [[ "${run_ipv6}" == 'true' ]]; then external_dns_server='@2606:4700:4700::1111'; else external_dns_server='@1.1.1.1'; fi; fi; fi
       if [[ "${ip_valid}" == 'true' ]]; then if ping -c 1 "${2}" > /dev/null; then ping_ok=true; external_dns_server="@${2}"; elif [[ "${run_ipv6}" == 'true' ]]; then external_dns_server='@2606:4700:4700::1111'; else external_dns_server='@1.1.1.1'; fi; fi
       if [[ "${ping_ok}" == 'true' ]]; then check_dig_curl; if dig +short "${dig_option}" google.com "${external_dns_server}" &> /dev/null; then custom_external_dns_server_provided=true; elif [[ "${run_ipv6}" == 'true' ]]; then external_dns_server='@2606:4700:4700::1111'; else external_dns_server='@1.1.1.1'; fi; fi
       if [[ "${custom_external_dns_server_provided}" == 'true' ]]; then echo "--external-dns ${2}" &>> /tmp/EUS/script_options; echo -e "${GREEN}#${RESET} ${2} appears to be a valid DNS server! The script will use ${2} for DNS lookups! \\n"; sleep 2; else echo "--external-dns" &>> /tmp/EUS/script_options; if [[ -n "${2}" ]]; then echo -e "${RED}#${RESET} ${2} does not appear to be a valid DNS server, the script will use 1.1.1.1 for DNS lookups... \\n"; sleep 2; fi; if [[ "${run_ipv6}" == 'true' ]]; then external_dns_server='@2606:4700:4700::1111'; else external_dns_server='@1.1.1.1'; fi; fi;;
  --force-renew | --renew)
       script_option_renew=true
       run_force_renew=true
       echo "--force-renew" &>> /tmp/EUS/script_options;;
  --priv-key | --private-key)
       for option in "${script_option_list[@]}"; do
         if [[ "${2}" == "${option}" ]]; then header_red; echo -e "${WHITE_R}#${RESET} Option ${1} requires a command argument... \\n\\n"; help_script; fi
       done
       if ! [[ -e "${2}" ]]; then header_red; echo -e "${WHITE_R}#${RESET} ${2} couldn't be found on your system... \\n\\n"; fi
       priv_key="$2"
       echo "--private-key ${2}" &>> /tmp/EUS/script_options
       shift;;
  --signed-crt | --signed-certificate)
       for option in "${script_option_list[@]}"; do
         if [[ "${2}" == "${option}" ]]; then header_red; echo -e "${WHITE_R}#${RESET} Option ${1} requires a command argument... \\n\\n"; help_script; fi
       done
       if ! [[ -e "${2}" ]]; then header_red; echo -e "${WHITE_R}#${RESET} ${2} couldn't be found on your system... \\n\\n"; fi
       signed_crt="$2"
       echo "--signed-certificate ${2}" &>> /tmp/EUS/script_options
       shift;;
  --chain-crt | --chain-certificate)
       for option in "${script_option_list[@]}"; do
         if [[ "${2}" == "${option}" ]]; then header_red; echo -e "${WHITE_R}#${RESET} Option ${1} requires a command argument... \\n\\n"; help_script; fi
       done
       if ! [[ -e "${2}" ]]; then header_red; echo -e "${WHITE_R}#${RESET} ${2} couldn't be found on your system... \\n\\n"; fi
       chain_crt="$2"
       echo "--chain-certificate ${2}" &>> /tmp/EUS/script_options
       shift;;
  --intermediate-crt | --intermediate-certificate)
       for option in "${script_option_list[@]}"; do
         if [[ "${2}" == "${option}" ]]; then header_red; echo -e "${WHITE_R}#${RESET} Option ${1} requires a command argument... \\n\\n"; help_script; fi
       done
       if ! [[ -e "${2}" ]]; then header_red; echo -e "${WHITE_R}#${RESET} ${2} couldn't be found on your system... \\n\\n"; fi
       intermediate_crt="$2"
       echo "--intermediate-certificate ${2}" &>> /tmp/EUS/script_options
       shift;;
  --dns | --dns-challenge)
       unset old_certificates
       prefer_dns_challenge=true
       if [[ -z "${dns_manual_flag}" ]]; then dns_manual_flag="--manual"; fi
       echo "--dns" &>> /tmp/EUS/script_options;;
  --dns-provider)
       for option in "${script_option_list[@]}"; do
         if [[ "${2}" == "${option}" ]]; then header_red; echo -e "${WHITE_R}#${RESET} Option ${1} requires a command argument... \\n\\n"; help_script; fi
       done
       for dns_provider_check in "${dns_provider_list[@]}"; do if [[ "${dns_provider_check}" == "$2" ]]; then supported_provider="true"; certbot_native_plugin="true"; break; fi; done
       for dns_provider_check in "${dns_multi_provider_list[@]}"; do if [[ "${dns_provider_check}" == "$2" ]] && ! dpkg -l unifi-core 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then supported_provider="true"; certbot_multi_plugin="true"; break; fi; done
       if [[ "${supported_provider}" != 'true' ]]; then header_red; echo -e "${WHITE_R}#${RESET} DNS Provider ${2} is not supported... \\n\\n"; help_script; fi
       unset old_certificates
       unset dns_manual_flag
       dns_manual_flag="--non-interactive"
       auto_dns_challenge_provider="${2}"
       if [[ "${certbot_native_plugin}" == 'true' ]]; then
         auto_dns_challenge_arguments="--dns-${auto_dns_challenge_provider} --dns-${auto_dns_challenge_provider}-propagation-seconds 60"
       fi
       echo "--dns-provider ${2}" &>> /tmp/EUS/script_options;;
  --dns-provider-credentials)
       for option in "${script_option_list[@]}"; do
         if [[ "${2}" == "${option}" ]]; then header_red; echo -e "${WHITE_R}#${RESET} Option ${1} requires a command argument... \\n\\n"; help_script; fi
       done
       unset old_certificates
       auto_dns_challenge_credentials_file="${2}"
       echo "--dns-provider-credentials ${2}" &>> /tmp/EUS/script_options;;
  --own-certificate)
       own_certificate=true
       echo "--own-certificate" &>> /tmp/EUS/script_options;;
  --prevent-modify-firewall)
       script_option_prevent_modify_firewall=true
       echo "--prevent-modify-firewall" &>> /tmp/EUS/script_options;;
  --restore)
       script_option_skip=false
       echo "--restore" &>> /tmp/EUS/script_options;;
  --help)
       script_option_help=true
       help_script;;
  --debug)
       script_option_debug="true";;
  --support-file)
       script_option_support_file="true"
       support_file;;
  esac
  shift
done

get_script_options() {
  if [[ -f /tmp/EUS/script_options && -s /tmp/EUS/script_options ]]; then IFS=" " read -r script_options <<< "$(tr '\r\n' ' ' < /tmp/EUS/script_options)"; fi
}
get_script_options

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

# Set auto DNS challenge variables.
if [[ -n "${auto_dns_challenge_arguments}" ]] || [[ "${certbot_multi_plugin}" == 'true' ]]; then
  if [[ -n "${auto_dns_challenge_credentials_file}" ]]; then
    chmod 600 "${auto_dns_challenge_credentials_file}" &> /dev/null
    while read -r requirement; do
      if ! grep -ioq "${requirement}" "${auto_dns_challenge_credentials_file}"; then
        header_red
        echo -e "${RED}#${RESET} You appear to be missing the following fields in \"${auto_dns_challenge_credentials_file}\"..."
        echo -e "${RED}#${RESET} The following fields should be within that file: \\n"
        while read -r requirement_missing; do
          echo -e " ${RED}-${RESET} ${requirement_missing}"
        done < <(curl "${curl_argument[@]}" "https://api.glennr.nl/api/multi-dns?provider=${auto_dns_challenge_provider}" 2> /dev/null | jq -r '.required_fields[]' 2> /dev/null)
        abort_skip_support_file_upload="true"
        abort
      fi
    done < <(curl "${curl_argument[@]}" "https://api.glennr.nl/api/multi-dns?provider=${auto_dns_challenge_provider}" 2> /dev/null | jq -r '.required_fields[]' 2> /dev/null)
    if [[ "${certbot_native_plugin}" == 'true' ]]; then
      if [[ "${auto_dns_challenge_provider}" =~ (route53) ]]; then
        # shellcheck disable=SC2269
        auto_dns_challenge_arguments="${auto_dns_challenge_arguments}"
      else
        auto_dns_challenge_arguments="${auto_dns_challenge_arguments} --dns-${auto_dns_challenge_provider}-credentials ${auto_dns_challenge_credentials_file}"
      fi
    elif [[ "${certbot_multi_plugin}" == 'true' ]]; then
      auto_dns_challenge_arguments="-a dns-multi --dns-multi-credentials ${auto_dns_challenge_credentials_file}"
    fi
    if [[ "${prefer_dns_challenge}" != 'true' ]]; then prefer_dns_challenge="true"; echo "--dns" &>> /tmp/EUS/script_options; fi
  else
    header_red; echo -e "${WHITE_R}#${RESET} Option \"--dns-provider-credentials\" doesn't appear to be set... \\n\\n"; help_script
  fi
fi

# Cleanup EUS logs
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

# Cleanup lets encrypt challenge logs ( keep last 5 )
# shellcheck disable=SC2010
ls -t "${eus_dir}/logs/" | grep -i "lets_encrypt_[0-9].*.log" | tail -n+6 &>> /tmp/EUS/challenge_log_cleanup
while read -r log_file; do
  if [[ -f "${eus_dir}/logs/${log_file}" ]]; then
    rm --force "${eus_dir}/logs/${log_file}" &> /dev/null
  fi
done < /tmp/EUS/challenge_log_cleanup
rm --force /tmp/EUS/challenge_log_cleanup &> /dev/null

# Remove obsolete log files
# shellcheck disable=SC2010
if ls "${eus_dir}/logs/" | grep -qi "lets_encrypt_import_[0-9].*.log"; then
  # shellcheck disable=SC2010
  ls -t "${eus_dir}/logs/" | grep -i "lets_encrypt_import_[0-9].*.log" &> /tmp/EUS/obsolete_logs
  while read -r log_file; do
    rm --force "${eus_dir}/logs/${log_file}" &> /dev/null
  done < /tmp/EUS/obsolete_logs
  rm --force /tmp/EUS/obsolete_logs &> /dev/null
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

cleanup_unifi_native_system() {
  if [[ "${openjdk_native_installed}" == 'true' ]]; then
    header
    check_dpkg_lock
    echo -e "${WHITE_R}#${RESET} The script installed ${openjdk_native_installed_package}, we do not need this anymore.\\n"
    echo -e "${WHITE_R}#${RESET} Purging package ${openjdk_native_installed_package}..."
    if DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' purge "${openjdk_native_installed_package}" &>> "${eus_dir}/logs/uninstall-${openjdk_native_installed_package}.log"; then
      echo -e "${GREEN}#${RESET} Successfully purged ${openjdk_native_installed_package}! \\n"
    else
      echo -e "${RED}#${RESET} Failed to purge ${openjdk_native_installed_package}... \\n"
    fi
    sleep 2
  fi
}

author() {
  check_apt_listbugs
  update_eus_db
  cleanup_codename_mismatch_repos
  cleanup_unifi_native_system
  header
  echo -e "${WHITE_R}#${RESET} The script successfully ended, enjoy your secure setup!\\n"
  christmass_new_year
  if [[ "${new_year_message}" == 'true' || "${christmas_message}" == 'true' ]]; then echo -e "\\n${WHITE_R}----${RESET}\\n"; fi
  if [[ "${archived_repo}" == 'true' && "${unifi_core_system}" != 'true' ]]; then echo -e "\\n${WHITE_R}----${RESET}\\n\\n${RED}# Looks like you're using a EOL/unsupported OS Release (${os_codename})\\n${RED}# Please update to a supported release...\\n"; fi
  if [[ "${archived_repo}" == 'true' && "${unifi_core_system}" == 'true' ]]; then echo -e "\\n${WHITE_R}----${RESET}\\n\\n${RED}# Please update to the latest UniFi OS Release!\\n"; fi
  if [[ "${stopped_unattended_upgrade}" == 'true' ]]; then systemctl start unattended-upgrades &>> "${eus_dir}/logs/unattended-upgrades.log"; unset stopped_unattended_upgrade; fi
  echo -e "${WHITE_R}#${RESET} ${GRAY_R}Author   |  ${WHITE_R}Glenn R.${RESET}"
  echo -e "${WHITE_R}#${RESET} ${GRAY_R}Email    |  ${WHITE_R}glennrietveld8@hotmail.nl${RESET}"
  echo -e "${WHITE_R}#${RESET} ${GRAY_R}Website  |  ${WHITE_R}https://GlennR.nl${RESET}\\n\\n"
}

# Set architecture
architecture=$(dpkg --print-architecture)
if [[ "${architecture}" == 'i686' ]]; then architecture="i386"; fi

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
    elif [[ "${os_codename}" =~ ^(noble|wilma|scootski)$ ]]; then repo_codename="noble"; os_codename="noble"; os_id="ubuntu"
    elif [[ "${os_codename}" =~ ^(oracular)$ ]]; then repo_codename="oracular"; os_codename="oracular"; os_id="ubuntu"
    elif [[ "${os_codename}" =~ ^(jessie|betsy)$ ]]; then repo_codename="jessie"; os_codename="jessie"; os_id="debian"
    elif [[ "${os_codename}" =~ ^(stretch|continuum|helium|cindy)$ ]]; then repo_codename="stretch"; os_codename="stretch"; os_id="debian"
    elif [[ "${os_codename}" =~ ^(buster|debbie|parrot|engywuck-backports|engywuck|deepin|lithium)$ ]]; then repo_codename="buster"; os_codename="buster"; os_id="debian"
    elif [[ "${os_codename}" =~ ^(bullseye|kali-rolling|elsie|ara|beryllium)$ ]]; then repo_codename="bullseye"; os_codename="bullseye"; os_id="debian"
    elif [[ "${os_codename}" =~ ^(bookworm|lory|faye|boron|beige|preslee)$ ]]; then repo_codename="bookworm"; os_codename="bookworm"; os_id="debian"
    elif [[ "${os_codename}" =~ ^(unstable|rolling)$ ]]; then repo_codename="unstable"; os_codename="unstable"; os_id="debian"
    else
      repo_codename="${os_codename}"
    fi
    if [[ -n "$(command -v jq)" && "$(jq -r '.database.distribution' "${eus_dir}/db/db.json")" != "${os_codename}" ]]; then
      if [[ "$(dpkg-query --showformat='${Version}' --show jq | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
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
  if "$(which dpkg)" -l apt 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then apt_package_version="$(dpkg-query --showformat='${Version}' --show apt | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)"; fi
  if "$(which dpkg)" -l apt-transport-https 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui" || [[ "${apt_package_version::2}" -ge "15" ]]; then
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
      #if [[ "${use_raspberrypi_repo}" == 'true' ]]; then os_id="raspbian"; if [[ "${architecture}" == 'arm64' ]]; then repo_arch_value="arch=arm64"; fi; unset use_raspberrypi_repo; fi
      distro_api_output="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/distro?distribution=${os_id}&version=${os_codename}&architecture=${architecture}${api_repo_url_procotol}" 2> /dev/null)"
      if [[ "$(command -v jq)" ]]; then archived_repo="$(echo "${distro_api_output}" | jq -r '.codename_eol')"; else archived_repo="$(echo "${distro_api_output}" | grep -oP '"codename_eol":\s*\K[^,}]+')"; fi
      if [[ "${get_repo_url_security_url}" == "true" ]]; then get_repo_url_url_argument="security_repository"; unset get_repo_url_security_url; else get_repo_url_url_argument="repository"; fi
      if [[ "$(command -v jq)" ]]; then repo_url="$(echo "${distro_api_output}" | jq -r ".${get_repo_url_url_argument}")"; else repo_url="$(echo "${distro_api_output}" | grep -oP "\"${get_repo_url_url_argument}\":\s*\"\K[^\"]+")"; fi
      distro_api="true"
    else
      if [[ "${os_codename}" =~ (precise|trusty|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular) ]]; then
        if curl "${curl_argument[@]}" "${http_or_https}://old-releases.ubuntu.com/ubuntu/dists/" 2> /dev/null | grep -iq "${os_codename}" 2> /dev/null; then archived_repo="true"; fi
        if [[ "${architecture}" =~ (amd64|i386) ]]; then
          if [[ "${archived_repo}" == "true" ]]; then repo_url="${http_or_https}://old-releases.ubuntu.com/ubuntu"; else repo_url="http://archive.ubuntu.com/ubuntu"; fi
        else
          if [[ "${archived_repo}" == "true" ]]; then repo_url="${http_or_https}://old-releases.ubuntu.com/ubuntu"; else repo_url="http://ports.ubuntu.com"; fi
        fi
      elif [[ "${os_codename}" =~ (wheezy|jessie|stretch|buster|bullseye|bookworm|trixie|forky) ]]; then
        if curl "${curl_argument[@]}" "${http_or_https}://archive.debian.org/debian/dists/" 2> /dev/null | grep -iq "${os_codename}" 2> /dev/null; then archived_repo="true"; fi
        if [[ "${archived_repo}" == "true" ]]; then repo_url="${http_or_https}://archive.debian.org/debian"; else repo_url="${http_or_https}://deb.debian.org/debian"; fi
      fi
    fi
  else
    if [[ "${os_codename}" =~ (precise|trusty|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular) ]]; then
      repo_url="http://archive.ubuntu.com/ubuntu"
    elif [[ "${os_codename}" =~ (wheezy|jessie|stretch|buster|bullseye|bookworm|trixie|forky) ]]; then
      repo_url="${http_or_https}://deb.debian.org/debian"
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

add_repositories() {
  # Check if repository is already added
  if grep -sq "^deb .*http\?s\?://$(echo "${repo_url}" | sed -e 's/https\:\/\///g' -e 's/http\:\/\///g')${repo_url_arguments}\?/\? ${repo_codename}${repo_codename_argument} ${repo_component}" /etc/apt/sources.list /etc/apt/sources.list.d/*; then
    echo -e "$(date +%F-%R) | \"${repo_url}${repo_url_arguments} ${repo_codename}${repo_codename_argument} ${repo_component}\" was found, not adding to repository lists. $(grep -srIl "^deb .*http\?s\?://$(echo "${repo_url}" | sed -e 's/https\:\/\///g' -e 's/http\:\/\///g')${repo_url_arguments}\?/\? ${repo_codename}${repo_codename_argument} ${repo_component}" /etc/apt/sources.list /etc/apt/sources.list.d/*)..." &>> "${eus_dir}/logs/already-found-repository.log"
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
              echo -e "$(date +%F-%R) | URIs: $section_url Types: $section_types Suites: $section_suites Components: $section_components was found, not adding to repository lists..." &>> "${eus_dir}/logs/already-found-repository.log"
              unset_add_repositories_variables
              unset section
              unset section_types
              unset section_components
              unset section_suites
              unset section_url
              unset section_enabled
              return
            fi
            unset section
            unset section_types
            unset section_components
            unset section_suites
            unset section_url
            unset section_enabled
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
    if gpg --no-default-keyring --keyring "/etc/apt/keyrings/${repo_key_name}.gpg" --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys "${repo_key}" &> /dev/null; then
      signed_by_value_repo_key="signed-by=/etc/apt/keyrings/${repo_key_name}.gpg"
      repository_key_location="/etc/apt/keyrings/${repo_key_name}.gpg"; check_repository_key_permissions
    else
      abort_reason="Failed to add repository key ${repo_key}."
      abort
    fi
  fi
  # Handle Debian versions
  if [[ "${os_codename}" =~ (wheezy|jessie|stretch|buster|bullseye|bookworm|trixie|forky) && "$(command -v jq)" ]]; then
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
    signed_by_value_repo_key_find="$(echo "${repo_url}" | sed -e 's/https\:\/\///g' -e 's/http\:\/\///g' -e 's/\/.*//g' -e 's/\.com//g' -e 's/\./-/g' -e 's/\./-/g' -e 's/deb-debian/archive-debian/g' -e 's/security-ubuntu/archive-ubuntu/g' -e 's/ports-ubuntu/archive-ubuntu/g' | awk -F'-' '{print $2 "-" $1}')"
    if [[ -n "${signed_by_value_repo_key_find}" ]]; then signed_by_value_repo_key="signed-by=$(find /usr/share/keyrings/ /etc/apt/keyrings/ -name "${signed_by_value_repo_key_find}*" | sed '/removed/d' | head -n1)"; fi
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
    echo -e "$(date +%F-%R) | Successfully added \"${repo_entry}\" to ${add_repositories_source_list}!" &>> "${eus_dir}/logs/added-repository.log"
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

check_and_add_to_path() {
  local directory="$1"
  if ! echo "${PATH}" | grep -qE "(^|:)$directory(:|$)"; then
    export PATH="$directory:$PATH"
    echo "Added $directory to PATH" &>> "${eus_dir/logs/path.log}"
  fi
}
check_and_add_to_path "/usr/local/sbin"
check_and_add_to_path "/usr/sbin"
check_and_add_to_path "/sbin"

# Check if --allow-change-held-packages is supported in apt
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
remove_apt_options="false"
get_apt_options

attempt_recover_broken_packages_removal_question() {
  if [[ "${script_option_skip}" != 'true' ]]; then read -rp $'\033[39m#\033[0m Do you allow the script to remove the broken packages? (Y/n) ' yes_no; fi
  case "$yes_no" in
       [Yy]*|"") attempt_recover_broken_packages_remove="true";;
       [Nn]*) attempt_recover_broken_packages_remove="false";;
  esac
}

attempt_recover_broken_packages() {
  while IFS= read -r log_file; do
    while IFS= read -r broken_package; do
      broken_package="$(echo "${broken_package}" | xargs)"
      if ! dpkg -l | awk '{print $2}' | grep -iq "^${broken_package}$"; then continue; fi
      echo -e "\\n------- $(date +%F-%R) -------\\n" &>> "${eus_dir}/logs/attempt-recover-broken-packages.log"
      echo -e "${WHITE_R}#${RESET} Attempting to recover broken packages..."
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
        echo -e "${WHITE_R}#${RESET} Attempting to prevent ${broken_package} from screwing over apt..."
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
        echo -e "\\n${WHITE_R}#${RESET} Removing the ${broken_package} package so that the files are kept on the system..."
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
              run_apt_get_update
              if DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "${dependency_to_install}" &>> "${eus_dir}/logs/unmet-dependency.log"; then
                echo -e "\\nSuccessfully installed ${dependency} after adding the repositories for ${version} \\n" &>> "${eus_dir}/logs/unmet-dependency.log"
                sed -i "s/Depends: ${dependency_no_version}/Depends (completed): ${dependency_no_version}/g" "${log_file}" 2>> "${eus_dir}/logs/unmet-dependency-sed.log"
                rm --force "/etc/apt/sources.list.d/glennr-install-script-unmet.${source_file_format}" &> /dev/null
                break
              fi
            done <<< "${list_of_distro_versions}"
            if [[ -e "/etc/apt/sources.list.d/glennr-install-script-unmet.${source_file_format}" ]]; then rm --force "/etc/apt/sources.list.d/glennr-install-script-unmet.${source_file_format}" &> /dev/null; fi
          fi
        fi
      done < <(grep "Depends:" "${log_file}" | sed 's/.*Depends: //' | sed 's/).*//' | sort | uniq)
      while read -r breaking_package; do
        echo -e "${WHITE_R}#${RESET} Attempting to prevent ${breaking_package} from screwing over apt..."
        if echo "${breaking_package} hold" | "$(which dpkg)" --set-selections &>> "${eus_dir}/logs/unmet-dependency-break.log"; then
          echo -e "${GREEN}#${RESET} Successfully prevented ${breaking_package} from screwing over apt! \\n"
          sed -i "s/Breaks: ${breaking_package}/Breaks (completed): ${breaking_package}/g" "${log_file}" 2>> "${eus_dir}/logs/unmet-dependency-break-sed.log"
        else
          echo -e "${RED}#${RESET} Failed to prevent ${breaking_package} from screwing over apt...\\n"
        fi
      done < <(grep "Breaks:" "${log_file}" | sed -E 's/^(.*) : Breaks: ([^ ]+).*/\1\n\2/' | sed 's/^[ \t]*//' | sort | uniq)
    done < <(grep -slE '^E: Unable to correct problems, you have held broken packages.|^The following packages have unmet dependencies' /tmp/EUS/apt/*.log "${eus_dir}"/logs/*.log | sort -u 2>> /dev/null)
  fi
}

check_dpkg_interrupted() {
  if [[ "${force_dpkg_configure}" == 'true' ]] || [[ -e "/var/lib/dpkg/info/*.status" ]] || tail -n5 "${eus_dir}/logs/"* | grep -iq "you must manually run 'sudo dpkg --configure -a' to correct the problem\\|you must manually run 'dpkg --configure -a' to correct the problem"; then
    echo -e "\\n------- $(date +%F-%R) -------\\n" &>> "${eus_dir}/logs/dpkg-interrupted.log"
    echo -e "${WHITE_R}#${RESET} Looks like dpkg was interrupted... running \"dpkg --configure -a\"..." | tee -a "${eus_dir}/logs/dpkg-interrupted.log"
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
      echo -e "${WHITE_R}#${RESET} $(echo "${lock_file}" | cut -d'/' -f4) is currently locked by process ${lock_owner}... We'll give it 2 minutes to finish." | tee -a "${eus_dir}/logs/dpkg-lock.log"
      local timeout="120"
      local start_time
      start_time="$(date +%s)"
      while true; do
        kill -0 "${lock_owner}" &>/dev/null
        local kill_result="$?"
        if [[ "$kill_result" -eq "0" ]]; then
          local current_time
          current_time="$(date +%s)"
          local elapsed_time="$((current_time - start_time))"
          if [[ "${elapsed_time}" -ge "${timeout}" ]]; then
            process_killed="true"
            echo -e "${YELLOW}#${RESET} Timeout reached. Killing process ${lock_owner} forcefully. \\n" | tee -a "${eus_dir}/logs/dpkg-lock.log"
            kill -9 "${lock_owner}" &>> "${eus_dir}/logs/dpkg-lock.log"
            rm -f "${lock_file}" &>> "${eus_dir}/logs/dpkg-lock.log"
            break
          else
            sleep 1
          fi
        else
          echo -e "${GREEN}#${RESET} $(echo "${lock_file}" | cut -d'/' -f4) is no longer locked! \\n" | tee -a "${eus_dir}/logs/dpkg-lock.log"
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
check_dpkg_lock

script_version_check() {
  local local_version
  local online_version
  local_version="$(grep -i "# Version" "${script_location}" | head -n 1 | cut -d'|' -f2 | sed 's/ //g')"
  if [[ -n "$(command -v jq)" ]]; then
    online_version="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/latest-script-version?script=unifi-easy-encrypt" 2> /dev/null | jq -r '."latest-script-version"' 2> /dev/null)"
  else
    online_version="$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/latest-script-version?script=unifi-easy-encrypt" 2> /dev/null | grep -oP '(?<="latest-script-version":")[0-9.]+')"
  fi
  IFS='.' read -r -a local_parts <<< "${local_version}"
  IFS='.' read -r -a online_parts <<< "${online_version}"
  if [[ "${#local_parts[@]}" -gt "${#online_parts[@]}" ]]; then max_length="${#local_parts[@]}"; else max_length="${#online_parts[@]}"; fi
  local local_adjusted=()
  local online_adjusted=()
  for ((i = 0; i < max_length; i++)) do
    local local_segment="${local_parts[$i]:-0}"
    local online_segment="${online_parts[$i]:-0}"
    local max_segment_length="${#local_segment}"
    [[ "${#online_segment}" -gt "${max_segment_length}" ]] && max_segment_length="${#online_segment}"
    if [[ "${#local_segment}" -lt max_segment_length ]]; then
      local_segment="$(printf "%s%s" "${local_segment}" "$(printf '0%.0s' $(seq $((max_segment_length - ${#local_segment}))) )")"
    fi
    if [[ "${#online_segment}" -lt max_segment_length ]]; then
      online_segment="$(printf "%s%s" "${online_segment}" "$(printf '0%.0s' $(seq $((max_segment_length - ${#online_segment}))) )")"
    fi
    local_adjusted+=("$local_segment")
    online_adjusted+=("$online_segment")
  done
  local local_version_adjusted
  local online_version_adjusted
  local_version_adjusted="$(IFS=; echo "${local_adjusted[*]}")"
  online_version_adjusted="$(IFS=; echo "${online_adjusted[*]}")"
  if [[ "${local_version_adjusted}" -lt "${online_version_adjusted}" ]]; then
    check_apt_listbugs
    header_red
    echo -e "${WHITE_R}#${RESET} You're currently running script version ${local_version} while ${online_version} is the latest!"
    echo -e "${WHITE_R}#${RESET} Downloading and executing version ${online_version} of the script...\\n\\n"
    sleep 3
    rm --force "${script_location}" 2> /dev/null
    rm --force unifi-update.sh 2> /dev/null
    # shellcheck disable=SC2068
    curl "${curl_argument[@]}" --remote-name https://get.glennr.nl/unifi/extra/unifi-easy-encrypt.sh && bash unifi-easy-encrypt.sh ${script_options[@]}; exit 0
  fi
}
if [[ "$(command -v curl)" ]]; then script_version_check; fi

if ! [[ "${os_codename}" =~ (precise|maya|trusty|qiana|rebecca|rafaela|rosa|xenial|sarah|serena|sonya|sylvia|bionic|tara|tessa|tina|tricia|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular|wheezy|jessie|stretch|buster|bullseye|bookworm|trixie|forky) ]]; then
  if [[ -e "/etc/os-release" ]]; then full_os_details="$(sed ':a;N;$!ba;s/\n/\\n/g' /etc/os-release | sed 's/"/\\"/g')"; fi
  if [[ -z "$(which apt)" ]]; then non_apt_based_linux="true"; fi
  unsupported_no_modify="true"
  get_distro
  if [[ "${non_apt_based_linux}" != 'true' ]]; then distro_support_missing_report="$(curl "${curl_argument[@]}" -X POST -H "Content-Type: application/json" -d "{\"distribution\": \"${os_id}\", \"codename\": \"${os_codename}\", \"script-name\": \"${script_name}\", \"full-os-details\": \"${full_os_details}\"}" https://api.glennr.nl/api/missing-distro-support 2> /dev/null | jq -r '.[]' 2> /dev/null)"; fi
  if [[ "${script_option_debug}" != 'true' ]]; then clear; fi
  header_red
  if [[ "${distro_support_missing_report}" == "OK" ]]; then
    echo -e "${WHITE_R}#${RESET} The script does not (yet) support ${os_id} ${os_codename}, and Glenn R. has been informed about it..."
  else
    if [[ "${non_apt_based_linux}" != 'true' ]]; then
      echo -e "${WHITE_R}#${RESET} The script does not yet support ${os_id} ${os_codename}..."
    else
      echo -e "${WHITE_R}#${RESET} It looks like you're a using a linux distribution (${os_id} ${os_codename}) that doesn't use the APT package manager. \\n${WHITE_R}#${RESET} the script is only made for distros based on the APT package manager..."
    fi
  fi
  echo -e "${WHITE_R}#${RESET} Feel free to contact Glenn R. (AmazedMender16) on the UI Community if you need help with installing your UniFi Network Application.\\n\\n"
  author
  exit 1
fi

check_package_cache_file_corruption() {
  if ls /tmp/EUS/apt/*.log 1> /dev/null 2>&1; then
    if grep -ioqE '^E: The package cache file is corrupted' /tmp/EUS/apt/*.log; then
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
      if [[ "${https_died_unexpectedly_check_logged_1}" != 'true' ]] && [[ "${previous_value}" == "0x1" ]]; then echo -e "$(date +%F-%R) | Previous GNUTLS_CPUID_OVERRIDE value is: ${previous_value}" &>> "${eus_dir}/logs/https-died-unexpectedly.log"; https_died_unexpectedly_check_logged_1="true"; fi
      if [[ "${previous_value}" != "0x1" ]]; then
        if sed -i 's/^GNUTLS_CPUID_OVERRIDE=.*/GNUTLS_CPUID_OVERRIDE=0x1/' "/etc/environment" &>> "${eus_dir}/logs/https-died-unexpectedly.log"; then
          echo -e "$(date +%F-%R) | Successfully updated GNUTLS_CPUID_OVERRIDE to 0x1!" &>> "${eus_dir}/logs/https-died-unexpectedly.log"
          # shellcheck disable=SC1091
          source /etc/environment
          repository_changes_applied="true"
        else
          echo -e "$(date +%F-%R) | Failed to update GNUTLS_CPUID_OVERRIDE to 0x1..." &>> "${eus_dir}/logs/https-died-unexpectedly.log"
        fi
      fi
    else
      echo -e "$(date +%F-%R) | Adding \"export GNUTLS_CPUID_OVERRIDE=0x1\" to /etc/environment..." &>> "${eus_dir}/logs/https-died-unexpectedly.log"
      if echo "export GNUTLS_CPUID_OVERRIDE=0x1" &>> /etc/environment; then
        echo -e "$(date +%F-%R) | Successfully added \"export GNUTLS_CPUID_OVERRIDE=0x1\" to /etc/environment..." &>> "${eus_dir}/logs/https-died-unexpectedly.log"
        # shellcheck disable=SC1091
        source /etc/environment
        repository_changes_applied="true"
      else
        echo -e "$(date +%F-%R) | Failed to add \"export GNUTLS_CPUID_OVERRIDE=0x1\" to /etc/environment..." &>> "${eus_dir}/logs/https-died-unexpectedly.log"
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
        echo -e "${WHITE_R}#${RESET} There appear to be malformed repositories..."
        cleanup_malformed_repositories_found_message="true"
      fi
      cleanup_malformed_repositories_file_path="$(echo "${line}" | sed -n 's/.*\(in sources file \|in source file \|in source list \|in list file \)\([^ ]*\).*/\2/p')"
      cleanup_malformed_repositories_line_number="$(echo "${line}" | cut -d':' -f2 | cut -d' ' -f1)"
      if [[ -f "${cleanup_malformed_repositories_file_path}" ]]; then
        if [[ "${cleanup_malformed_repositories_file_path}" == *".sources" ]]; then
          # Handle deb822 format
          entry_block_start_line="$(awk -v cleanup_line="${cleanup_malformed_repositories_line_number}" 'BEGIN { block = 0; in_block = 0; start_line = 0 } /^[^#]/ { if (!in_block) { start_line = NR; in_block = 1; } } /^$/ { if (in_block) { block++; in_block = 0; if (block == cleanup_line) { print start_line; } } } END { if (in_block) { block++; if (block == cleanup_line) { print start_line; } } }' "${cleanup_malformed_repositories_file_path}")"
          entry_block_end_line="$(awk -v start_line="$entry_block_start_line" ' NR > start_line && NF == 0 { print NR-1; found=1; exit } NR > start_line { last_non_blank=NR } END { if (!found) print last_non_blank }' "${cleanup_malformed_repositories_file_path}")"
          sed -i "${entry_block_start_line},${entry_block_end_line}s/^/#/" "${cleanup_malformed_repositories_file_path}" &>/dev/null
        elif [[ "${cleanup_malformed_repositories_file_path}" == *".list" ]]; then
          # Handle regular format
          sed -i "${cleanup_malformed_repositories_line_number}s/^/#/" "${cleanup_malformed_repositories_file_path}" &>/dev/null
        else
          mv "${cleanup_malformed_repositories_file_path}" "{eus_dir}/repository/$(basename "${cleanup_malformed_repositories_file_path}").corrupted" &>/dev/null
        fi
        cleanup_malformed_repositories_changes_made="true"
        echo -e "$(date +%F-%R) | Malformed repository commented out in '${cleanup_malformed_repositories_file_path}' at line $cleanup_malformed_repositories_line_number" &>> "${eus_dir}/logs/cleanup-malformed-repository-lists.log"
      else
        echo -e "$(date +%F-%R) | Warning: Invalid file path '${cleanup_malformed_repositories_file_path}'. Skipping." &>> "${eus_dir}/logs/cleanup-malformed-repository-lists.log"
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
        echo -e "${WHITE_R}#${RESET} There appear to be duplicated repositories..."
        cleanup_duplicated_repositories_found_message="true"
      fi
      cleanup_duplicated_repositories_file_path="$(echo "${line}" | cut -d':' -f1)"
      cleanup_duplicated_repositories_line_number="$(echo "${line}" | cut -d':' -f2 | cut -d' ' -f1)"
      if [[ -f "${cleanup_duplicated_repositories_file_path}" ]]; then
        if [[ "${cleanup_duplicated_repositories_file_path}" == *".sources" ]]; then
          # Handle deb822 format
          entry_block_start_line="$(awk 'BEGIN { block = 0 } { if ($0 ~ /^Types:/) { block++ } if (block == '"$cleanup_duplicated_repositories_line_number"') { print NR; exit } }' "${cleanup_duplicated_repositories_file_path}")"
          entry_block_end_line="$(awk -v start_line="$entry_block_start_line" ' NR > start_line && NF == 0 { print NR-1; found=1; exit } NR > start_line { last_non_blank=NR } END { if (!found) print last_non_blank }' "${cleanup_duplicated_repositories_file_path}")"
          sed -i "${entry_block_start_line},${entry_block_end_line}s/^\([^#]\)/# \1/" "${cleanup_duplicated_repositories_file_path}" &>/dev/null
        elif [[ "${cleanup_duplicated_repositories_file_path}" == *".list" ]]; then
          # Handle regular format
          sed -i "${cleanup_duplicated_repositories_line_number}s/^/#/" "${cleanup_duplicated_repositories_file_path}" &>/dev/null
        fi
        cleanup_duplicated_repositories_changes_made="true"
        echo -e "$(date +%F-%R) | Duplicates commented out in '${cleanup_duplicated_repositories_file_path}' at line $cleanup_duplicated_repositories_line_number" &>> "${eus_dir}/logs/cleanup-duplicate-repository-lists.log"
      else
        echo -e "$(date +%F-%R) | Warning: Invalid file path '${cleanup_duplicated_repositories_file_path}'. Skipping." &>> "${eus_dir}/logs/cleanup-duplicate-repository-lists.log"
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
      if ! grep -sq "^#.*${domain}" /etc/apt/sources.list /etc/apt/sources.list.d/*.list /etc/apt/sources.list.d/*.sources 2> /dev/null; then
        if [[ "${cleanup_unavailable_repositories_found_message}" != 'true' ]]; then
          echo -e "${WHITE_R}#${RESET} There are repositories that are causing issues..."
          cleanup_unavailable_repositories_found_message="true"
        fi
        for file in /etc/apt/sources.list.d/*.sources; do
          if grep -sq "${domain}" "${file}"; then
            entry_block_start_line="$(awk '!/^#/ && /Types:/ { types_line=NR } /'"${domain}"'/ && !/^#/ && !seen[types_line]++ { print types_line }' "${file}" | head -n1)"
            entry_block_end_line="$(awk -v start_line="$entry_block_start_line" 'NR > start_line && NF == 0 { print NR-1; exit } END { if (NR > start_line && NF > 0) print NR }' "${file}")"
            sed -i "${entry_block_start_line},${entry_block_end_line}s/^\([^#]\)/# \1/" "${file}" &>/dev/null
            cleanup_unavailable_repositories_changes_made="true"
            echo -e "$(date +%F-%R) | Unavailable repository with domain ${domain} has been commented out in '${file}'" &>> "${eus_dir}/logs/cleanup-unavailable-repository-lists.log"
          fi
        done
        if sed -i -e "/^[^#].*${domain}/ s|^deb|# deb|g" /etc/apt/sources.list /etc/apt/sources.list.d/*.list &>/dev/null; then
          cleanup_unavailable_repositories_changes_made="true"
          echo -e "$(date +%F-%R) | Unavailable repository with domain ${domain} has been commented out" &>> "${eus_dir}/logs/cleanup-unavailable-repository-lists.log"
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
            echo -e "${WHITE_R}#${RESET} There appear to be repositories with conflicting details..."
            cleanup_conflicting_repositories_found_message_1="true"
          fi
          # Extract the conflicting source URL and remove trailing slash
          source_url="$(echo "${line}" | grep -oP 'source \Khttps?://[^ /]*' | sed 's/ //g')"
          # Extract package name and version from the conflicting source URL
          package_name="$(echo "${line}" | awk -F'/' '{print $(NF-1)}' | sed 's/ //g')"
          version="$(echo "${line}" | awk -F'/' '{print $NF}' | sed 's/ //g')"
          # Loop through each file and awk to comment out the conflicting source
          while read -r file_with_conflict; do
            if [[ "${cleanup_conflicting_repositories_message_1}" != 'true' ]]; then
              echo -e "$(date +%F-%R) | Conflicting Trusted values for ${source_url}" &>> "${eus_dir}/logs/trusted-repository-conflict.log"
              cleanup_conflicting_repositories_message_1="true"
            fi
            if [[ "${file_with_conflict}" == *".sources" ]]; then
              # Handle deb822 format
              entry_block_start_line="$(awk '!/^#/ && /Types:/ { types_line=NR } /'"${source_url}"'/ && !/^#/ && !seen[types_line]++ { print types_line }' "${file_with_conflict}" | head -n1)"
              entry_block_end_line="$(awk -v start_line="$entry_block_start_line" 'NR > start_line && NF == 0 { print NR-1; exit } END { if (NR > start_line && NF > 0) print NR }' "${file_with_conflict}")"
              sed -i "${entry_block_start_line},${entry_block_end_line}s/^\([^#]\)/# \1/" "${file_with_conflict}" &>/dev/null
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
            echo -e "$(date +%F-%R) | awk command executed for ${file_with_conflict}" &>> "${eus_dir}/logs/trusted-repository-conflict.log"
          done < <(grep -sl "^deb.*${source_url}.*${package_name}.*${version}\\|^URIs: *${source_url}" /etc/apt/sources.list /etc/apt/sources.list.d/* /etc/apt/sources.list.d/*.sources | awk '!NF || !seen[$0]++')
          break
        elif [[ ${line} == *"Conflicting values set for option Signed-By regarding source"* ]]; then
          if [[ "${cleanup_conflicting_repositories_found_message_2}" != 'true' ]]; then
            echo -e "${WHITE_R}#${RESET} There appear to be repositories with conflicting details..."
            cleanup_conflicting_repositories_found_message_2="true"
          fi
          # Extract the conflicting source URL and keys
          conflicting_source="$(echo "${line}" | grep -oP 'https?://[^ ]+' | sed 's/\/$//')"  # Remove trailing slash
          key1="$(echo "${line}" | grep -oP '/\S+\.gpg' | head -n 1 | sed 's/ //g')"
          key2="$(echo "${line}" | grep -oP '!= \S+\.gpg' | sed 's/!= //g' | sed 's/ //g')"
          # Loop through each file and awk to comment out the conflicting source
          while read -r file_with_conflict; do
            if [[ "${cleanup_conflicting_repositories_message_2}" != 'true' ]]; then
              echo -e "$(date +%F-%R) | Conflicting Signed-By values for ${conflicting_source}" &>> "${eus_dir}/logs/signed-by-repository-conflict.log"
              echo -e "$(date +%F-%R) | Conflicting keys: ${key1} != ${key2}" &>> "${eus_dir}/logs/signed-by-repository-conflict.log"
              cleanup_conflicting_repositories_message_2="true"
            fi
            if [[ "${file_with_conflict}" == *".sources" ]]; then
              # Handle deb822 format
              entry_block_start_line="$(awk '!/^#/ && /Types:/ { types_line=NR } /'"${source_url}"'/ && !/^#/ && !seen[types_line]++ { print types_line }' "${file_with_conflict}" | head -n1)"
              entry_block_end_line="$(awk -v start_line="$entry_block_start_line" 'NR > start_line && NF == 0 { print NR-1; exit } END { if (NR > start_line && NF > 0) print NR }' "${file_with_conflict}")"
              sed -i "${entry_block_start_line},${entry_block_end_line}s/^\([^#]\)/# \1/" "${file_with_conflict}" &>/dev/null
            elif [[ "${file_with_conflict}" == *".list" ]]; then
              # Handle regular format
              if awk -v source="${conflicting_source}" -v key1="${key1}" -v key2="${key2}" '
                !/^#/ && $0 ~ source && ($0 ~ key1 || $0 ~ key2) {
                  print "#" $0;
                  next
                } 
                1' "${file_with_conflict}" &> tmpfile; then mv tmpfile "${file_with_conflict}" &> /dev/null; cleanup_conflicting_repositories_changes_made="true"; fi
            fi
            echo -e "$(date +%F-%R) | awk command executed for ${file_with_conflict}" &>> "${eus_dir}/logs/signed-by-repository-conflict.log"
          done < <(grep -sl "^deb.*${conflicting_source}\\|^URIs: *${conflicting_source}" /etc/apt/sources.list /etc/apt/sources.list.d/* /etc/apt/sources.list.d/*.sources | awk '!NF || !seen[$0]++')
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
  echo -e "${WHITE_R}#${RESET} Running apt-get update..."
  if apt-get update "${apt_fix_missing[@]}" 2>&1 | tee -a "${eus_dir}/logs/apt-update.log" > /tmp/EUS/apt/apt-update.log; then if [[ "${PIPESTATUS[0]}" -eq "0" ]]; then echo -e "${GREEN}#${RESET} Successfully ran apt-get update! \\n"; else echo -e "${YELLOW}#${RESET} Something went wrong during running apt-get update! \\n"; fi; fi
  if grep -ioq "fix-missing" /tmp/EUS/apt/apt-update.log; then run_with_apt_fix_missing="true"; return; else unset apt_fix_missing; fi
  grep -o 'NO_PUBKEY.*' /tmp/EUS/apt/apt-update.log | sed 's/NO_PUBKEY //g' | tr ' ' '\n' | awk '!a[$0]++' &> /tmp/EUS/apt/missing_keys
  if [[ -s "/tmp/EUS/apt/missing_keys_done" ]]; then
    while read -r key_done; do
      if grep -ioq "${key_done}" /tmp/EUS/apt/missing_keys; then sed -i "/${key_done}/d" /tmp/EUS/apt/missing_keys; fi
    done < <(cat /tmp/EUS/apt/missing_keys_done /tmp/EUS/apt/missing_keys_failed 2> /dev/null)
  fi
  if [[ -s /tmp/EUS/apt/missing_keys ]]; then
    if "$(which dpkg)" -l dirmngr 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
      while read -r key; do
        echo -e "${WHITE_R}#${RESET} Key ${key} is missing.. adding!"
        locate_http_proxy
        if [[ -n "$http_proxy" ]]; then
          if apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --keyserver-options http-proxy="${http_proxy}" --recv-keys "$key" &>> "${eus_dir}/logs/key-recovery.log"; then echo "${key}" &>> /tmp/EUS/apt/missing_keys_done; echo -e "${GREEN}#${RESET} Successfully added key ${key}!\\n"; else fail_key="true"; fi
        elif [[ -f /etc/apt/apt.conf ]]; then
          apt_http_proxy="$(grep "http.*Proxy" /etc/apt/apt.conf | awk '{print $2}' | sed 's/[";]//g')"
          if [[ -n "${apt_http_proxy}" ]]; then
            if apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --keyserver-options http-proxy="${apt_http_proxy}" --recv-keys "$key" &>> "${eus_dir}/logs/key-recovery.log"; then echo "${key}" &>> /tmp/EUS/apt/missing_keys_done; echo -e "${GREEN}#${RESET} Successfully added key ${key}!\\n"; else fail_key="true"; fi
          fi
        else
          if apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv "$key" &>> "${eus_dir}/logs/key-recovery.log"; then echo "${key}" &>> /tmp/EUS/apt/missing_keys_done; echo -e "${GREEN}#${RESET} Successfully added key ${key}!\\n"; else fail_key="true"; fi
        fi
        if [[ "${fail_key}" == 'true' ]]; then
          echo -e "${RED}#${RESET} Failed to add key ${key}... \\n"
          echo -e "${WHITE_R}#${RESET} Trying different method to get key: ${key}"
          gpg -vvv --debug-all --keyserver keyserver.ubuntu.com --recv-keys "${key}" &> /tmp/EUS/apt/failed_key
          debug_key="$(grep "KS_GET" /tmp/EUS/apt/failed_key | grep -io "0x.*")"
          if curl "${curl_argument[@]}" "https://keyserver.ubuntu.com/pks/lookup?op=get&search=${debug_key}" | gpg -o "/tmp/EUS/apt/EUS-${key}.gpg" --dearmor --yes &> /dev/null; then
            if mv "/tmp/EUS/apt/EUS-${key}.gpg" /etc/apt/trusted.gpg.d/; then echo -e "${GREEN}#${RESET} Successfully added key ${key}!\\n"; repository_key_location="/etc/apt/trusted.gpg.d/EUS-${key}.gpg"; check_repository_key_permissions; echo "${key}" &>> /tmp/EUS/apt/missing_keys_done; else echo -e "${RED}#${RESET} Failed to add key ${key}... \\n"; echo "${key}" &>> /tmp/EUS/apt/missing_keys_failed; fi
          else
            echo -e "${RED}#${RESET} Failed to add key ${key}... \\n"
            echo "${key}" &>> /tmp/EUS/apt/missing_keys_failed
          fi
        fi
        sleep 1
      done < /tmp/EUS/apt/missing_keys
    else
      echo -e "${WHITE_R}#${RESET} Keys appear to be missing..." && sleep 1
      echo -e "${YELLOW}#${RESET} Required package dirmngr is missing... cannot recover keys... \\n"
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
}

required_service=no
if [[ "${is_cloudkey}" == 'true' ]]; then required_service=yes; fi
if dpkg -l unifi 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then required_service=yes; fi
if dpkg -l unifi-video 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then required_service=yes; fi
if dpkg -l unifi-talk 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then required_service=yes; fi
if dpkg -l unifi-led 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then required_service=yes; fi
if dpkg -l uas-led 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then required_service=yes; fi
if dpkg -l unifi-core 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then required_service=yes; fi
if dpkg -l | grep -iq "\\bUAS\\b\\|UniFi Application Server"; then required_service=yes; fi
if dpkg -l | awk '{print $2}' | grep -iq "^docker.io\\|^docker-ce"; then if docker ps -a | grep -iq 'ubnt/eot'; then required_service=yes; fi; fi
if [[ "${required_service}" == 'no' ]]; then
  echo -e "${RED}#${RESET} Please install one of the following controllers/applications first, then retry this script again!"
  echo -e "${RED}-${RESET} UniFi Network Application"
  echo -e "${RED}-${RESET} UniFi Video NVR"
  echo -e "${RED}-${RESET} UniFi LED Controller\\n\\n"
  exit 1
fi

# Check if UniFi is already installed.
unifi_status="$(systemctl status unifi | grep -i 'Active:' | awk '{print $2}')"
if dpkg -l unifi 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
  if [[ "${unifi_status}" == 'inactive' ]]; then
    header
    echo -e "${WHITE_R}#${RESET} UniFi is not active ( running ), starting the application now."
    systemctl start unifi
    unifi_status="$(systemctl status unifi | grep -i 'Active:' | awk '{print $2}')"
    if [[ "${unifi_status}" == 'active' ]]; then
      echo -e "${GREEN}#${RESET} Successfully started the UniFi Network Application!"
      sleep 2
    else
      echo -e "${RED}#${RESET} Failed to start the UniFi Network Application!"
      echo -e "${RED}#${RESET} Please check the logs in '/usr/lib/unifi/logs/'"
      sleep 2
    fi
  fi
fi

check_dig_curl

certbot_auto_permission_check() {
  if [[ -f "${eus_dir}/certbot-auto" || -s "${eus_dir}/certbot-auto" ]]; then
    if [[ "$(stat -c "%a" "${eus_dir}/certbot-auto")" != "755" ]]; then
      chmod 0755 "${eus_dir}/certbot-auto"
    fi
    if [[ "$(stat -c "%U" "${eus_dir}/certbot-auto")" != "root" ]] ; then
      chown root "${eus_dir}/certbot-auto"
    fi
  fi
}

download_certbot_auto() {
  if [[ "${use_older_certbot_auto_script}" == 'true' ]]; then
    curl "${curl_argument[@]}" https://raw.githubusercontent.com/certbot/certbot/v1.9.0/certbot-auto --output "${eus_dir}/certbot-auto"
  else
    curl "${curl_argument[@]}" https://raw.githubusercontent.com/certbot/certbot/v1.17.0/certbot-auto --output "${eus_dir}/certbot-auto"
    #curl -s https://dl.eff.org/certbot-auto -o "${eus_dir}/certbot-auto"
  fi
  chown root "${eus_dir}/certbot-auto"
  chmod 0755 "${eus_dir}/certbot-auto"
  downloaded_certbot=true
  certbot_auto_permission_check
  if [[ ! -f "${eus_dir}/certbot-auto" || ! -s "${eus_dir}/certbot-auto" ]]; then abort_reason="Failed to download certbot auto."; abort; fi
}

remove_certbot() {
  if dpkg -l certbot 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
    DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' remove certbot
    apt-get autoremove -y
    apt-get autoclean -y
  fi
}

if [[ "${os_codename}" == "jessie" ]]; then
  if dpkg -l | grep ^"ii" | awk '{print $2}' | grep -q "^certbot\\b"; then
    header_red
    echo -e "${RED}#${RESET} Your certbot version is to old, we will switch to certbot-auto..\\n\\n"
    remove_certbot
  fi
fi

mongo_command() {
  mongo_command_server_version="$("$(which dpkg)" -l | grep "^ii\\|^hi\\|^ri\\|^pi\\|^ui\\|^iU" | grep "mongodb-server\\|mongodb-org-server\\|mongod-armv8" | awk '{print $3}' | sed 's/\.//g' | sed 's/.*://' | sed 's/-.*//g')"
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
mongo_command

# Check openSSL version, if version 3.x.x, use -legacy for pkcs12
openssl_version="$(openssl version | awk '{print $2}' | sed -e 's/[a-zA-Z]//g')"
first_digit_openssl="$(echo "${openssl_version}" | cut -d'.' -f1)"
if [[ "${first_digit_openssl}" -ge "3" ]]; then openssl_legacy_flag="-legacy"; fi

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                        Required Packages                                                                                        #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

# Install needed packages if not installed
install_required_packages() {
  sleep 2
  installing_required_package="yes"
  header
  echo -e "${WHITE_R}#${RESET} Installing required packages for the script..\\n"
  run_apt_get_update
  sleep 2
}
apt_get_install_package() {
  apt_get_install_package_variable="install"; apt_get_install_package_variable_2="installed"
  run_apt_get_update
  check_dpkg_lock
  echo -e "\\n------- ${required_package} installation ------- $(date +%F-%R) -------\\n" &>> "${eus_dir}/logs/apt.log"
  echo -e "${WHITE_R}#${RESET} Trying to ${apt_get_install_package_variable} ${required_package}..."
  if DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "${required_package}" 2>&1 | tee -a "${eus_dir}/logs/apt.log" > /tmp/EUS/apt/apt.log; then
    if [[ "${PIPESTATUS[0]}" -eq "0" ]]; then
      echo -e "${GREEN}#${RESET} Successfully ${apt_get_install_package_variable_2} ${required_package}! \\n"; sleep 2
    else
      echo -e "${RED}#${RESET} Failed to ${apt_get_install_package_variable} ${required_package}...\\n"
      check_unmet_dependencies
      broken_packages_check
      attempt_recover_broken_packages
      add_apt_option_no_install_recommends="true"; get_apt_options
      echo -e "${WHITE_R}#${RESET} Trying to ${apt_get_install_package_variable} ${required_package}..."
      if DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "${required_package}" 2>&1 | tee -a "${eus_dir}/logs/apt.log" > /tmp/EUS/apt/apt.log; then
        if [[ "${PIPESTATUS[0]}" -eq "0" ]]; then
          echo -e "${GREEN}#${RESET} Successfully ${apt_get_install_package_variable_2} ${required_package}! \\n"; sleep 2
        else
          if [[ -z "${java_install_attempts}" ]]; then abort_reason="Failed to ${apt_get_install_package_variable} ${required_package}."; abort; else echo -e "${RED}#${RESET} Failed to ${apt_get_install_package_variable} ${required_package}...\\n"; fi
        fi
      fi
      get_apt_options
    fi
  fi
  unset required_package
}

certbot_install_function() {
  if [[ "${dns_manual_flag}" == '--non-interactive' ]]; then
    try_snapd="false"
    if "$(which dpkg)" -l snapd 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then if snap list certbot 2> /dev/null | grep -ioq certbot 2> /dev/null; then snap remove certbot &>> "${eus_dir}/logs/snapd.log"; fi; fi
  fi
  if [[ "${own_certificate}" != "true" ]]; then
    if [[ "${os_codename}" == "jessie" ]]; then
      if [[ "${os_codename}" == "jessie" ]]; then
        if [[ ! -f "${eus_dir}/certbot-auto" || ! -s "${eus_dir}/certbot-auto" ]]; then download_certbot_auto; fi
      fi
    else
      if ! dpkg -l certbot 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
        if dpkg -l | awk '{print$2}' | grep -iq "^snapd$" && [[ "${try_snapd}" != 'false' ]]; then
          if [[ "${installing_required_package}" != 'yes' ]]; then install_required_packages; fi
          if ! "$(which dpkg)" -l snapd 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
            required_package="snapd"
            apt_get_install_package
          fi
          check_snapd_running
          echo -e "\\n------- update ------- $(date +%F-%R) -------\\n" &>> "${eus_dir}/logs/snapd.log"
          echo -e "${WHITE_R}#${RESET} Updating snapd..."
          if snap install core &>> "${eus_dir}/logs/snapd.log"; snap refresh core &>> "${eus_dir}/logs/snapd.log"; then
            echo -e "${GREEN}#${RESET} Successfully updated snapd! \\n" && sleep 2
            echo -e "\\n------- certbot installation ------- $(date +%F-%R) -------\\n" &>> "${eus_dir}/logs/snapd.log"
            echo -e "${WHITE_R}#${RESET} Installing certbot via snapd..."
            if snap install --classic certbot &>> "${eus_dir}/logs/snapd.log"; then
              echo -e "${GREEN}#${RESET} Successfully installed certbot via snapd! \\n" && sleep 2
              if ! [[ -L "/usr/bin/certbot" ]]; then
                echo -e "${WHITE_R}#${RESET} Creating symlink for certbot..."
                if ln -s /snap/bin/certbot /usr/bin/certbot &>> "${eus_dir}/logs/certbot-symlink.log"; then echo -e "${GREEN}#${RESET} Successfully created symlink for certbot! \\n"; else abort_reason="Failed to create symlink for certbot."; abort; fi
              fi
	        else
              echo -e "${RED}#${RESET} Failed to install certbot via snapd... \\n"
              echo -e "${WHITE_R}#${RESET} Trying to remove cerbot snapd..."
              echo -e "\\n------- certbot removal ------- $(date +%F-%R) -------\\n" &>> "${eus_dir}/logs/snapd.log"
              if snap remove certbot &>> "${eus_dir}/logs/snapd.log"; then
                echo -e "${GREEN}#${RESET} Successfully removed certbot! \\n"
                echo -e "${WHITE_R}#${RESET} Trying the classic way of using certbot..."
                try_snapd=false
                certbot_install_function
              fi
            fi
	      else
            abort_reason="Failed to update snapd."
            abort
          fi
        else
          if [[ "${installing_required_package}" != 'yes' ]]; then install_required_packages; fi
          echo -e "\\n------- certbot installation ------- $(date +%F-%R) -------\\n" &>> "${eus_dir}/logs/required.log"
          echo -e "${WHITE_R}#${RESET} Installing certbot..."
          if DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install certbot &>> "${eus_dir}/logs/required.log"; then
            echo -e "${GREEN}#${RESET} Successfully installed certbot! \\n" && sleep 2
	      else
            echo -e "${RED}#${RESET} Failed to install certbot in the first run... \\n"
            certbot_repositories
          fi
          check_certbot_version
        fi
      else
        check_certbot_version
      fi
    fi
  fi
}

certbot_repositories() {
  if [[ "${repo_codename}" =~ (disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar) ]]; then
    repo_codename="disco"
  else
    repo_component="main"
  fi
  repo_url="http://ppa.launchpad.net/certbot/certbot/ubuntu"
  repo_key="8C47BE8E75BCA694"
  repo_key_name="certbot-ppa"
  add_repositories
  get_distro
  get_repo_url
  run_apt_get_update
  if [[ -n "$(apt-cache policy certbot | grep -i Candidate | sed -e 's/ //g' -e 's/*//g' | cut -d':' -f2)" ]]; then
    required_package="certbot"
    apt_get_install_package
  else
    required_package="snapd"
    apt_get_install_package
    certbot_install_function
  fi
}

check_certbot_version() {
  certbot_version_1="$(dpkg -l | grep ^"ii" | awk '{print $2,$3}' | grep "^certbot\\b" | awk '{print $2}' | cut -d'.' -f1)"
  certbot_version_2="$(dpkg -l | grep ^"ii" | awk '{print $2,$3}' | grep "^certbot\\b" | awk '{print $2}' | cut -d'.' -f2)"
  if [[ -n "${certbot_version_2}" ]] && [[ "${certbot_version_1}" -le '0' ]] && [[ "${certbot_version_2}" -lt '27' ]]; then
    header
    echo -e "${WHITE_R}#${RESET} Making sure your certbot version is on the latest release.\\n\\n"
    certbot_repositories
    certbot_version_1="$(dpkg -l | grep ^"ii" | awk '{print $2,$3}' | grep "^certbot\\b" | awk '{print $2}' | cut -d'.' -f1)"
    certbot_version_2="$(dpkg -l | grep ^"ii" | awk '{print $2,$3}' | grep "^certbot\\b" | awk '{print $2}' | cut -d'.' -f2)"
    if [[ -n "${certbot_version_2}" ]] && [[ "${certbot_version_1}" -le '0' ]] && [[ "${certbot_version_2}" -lt '27' ]]; then
      header_red
      echo -e "${RED}#${RESET} Your certbot version is to old, we will switch to certbot-auto..\\n\\n"
      remove_certbot
      download_certbot_auto
    fi
  fi
}

if ! dpkg -l dnsutils 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
  if [[ "${installing_required_package}" != 'yes' ]]; then
    install_required_packages
  fi
  echo -e "${WHITE_R}#${RESET} Installing dnsutils..."
  if ! DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install dnsutils &>> "${eus_dir}/logs/required.log"; then
    echo -e "${RED}#${RESET} Failed to install dnsutils in the first run...\\n"
    if [[ "${repo_codename}" =~ (precise|trusty|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic) ]]; then
      if [[ "${repo_codename}" =~ (xenial) ]]; then repo_codename_argument="-security"; repo_component="main"; fi
      if [[ "${repo_codename}" =~ (bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar) ]]; then repo_component="main"; fi
    elif [[ "${repo_codename}" =~ (wheezy|jessie|stretch|buster|bullseye|bookworm|trixie|forky) ]]; then
      if [[ "${repo_codename}" =~ (wheezy|jessie|stretch|buster|bullseye|bookworm|trixie|forky) ]]; then repo_url_arguments="-security/"; repo_codename_argument="/updates"; repo_component="main"; add_repositories; fi
      repo_component="main"
    fi
    add_repositories
    required_package="dnsutils"
    apt_get_install_package
  else
    echo -e "${GREEN}#${RESET} Successfully installed dnsutils! \\n" && sleep 2
  fi
  get_repo_url
fi
if ! "$(which dpkg)" -l gnupg 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
  if [[ "${installing_required_package}" != 'yes' ]]; then install_required_packages; fi
  check_dpkg_lock
  echo -e "${WHITE_R}#${RESET} Installing gnupg..."
  if ! DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install gnupg &>> "${eus_dir}/logs/required.log"; then
    echo -e "${RED}#${RESET} Failed to install gnupg in the first run...\\n"
    if [[ "${repo_codename}" =~ (precise|trusty|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular) ]]; then
      if [[ "${repo_codename}" =~ (precise|trusty|xenial) ]]; then repo_codename_argument="-security"; repo_component="main"; fi
      if [[ "${repo_codename}" =~ (bionic|cosmic) ]]; then repo_codename_argument="-security"; repo_component="main universe"; fi
      if [[ "${repo_codename}" =~ (disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular) ]]; then repo_component="main universe"; fi
    elif [[ "${repo_codename}" =~ (wheezy|jessie|stretch|buster|bullseye|bookworm|trixie|forky) ]]; then
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
    if [[ "${#reinstall_gnupg_segfault_packages[@]}" -gt '0' ]]; then echo -e "\\n------- $(date +%F-%R) -------\\n" &>> "${eus_dir}/logs/gnupg-segfault-reinstall.log"; DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install --reinstall "${reinstall_gnupg_segfault_packages[@]}" &>> "${eus_dir}/logs/gnupg-segfault-reinstall.log"; fi
  fi
fi
if ! "$(which dpkg)" -l jq 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then
  if [[ "${installing_required_package}" != 'yes' ]]; then
    install_required_packages
  fi
  check_dpkg_lock
  echo -e "${WHITE_R}#${RESET} Installing jq..."
  if ! DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install jq &>> "${eus_dir}/logs/required.log"; then
    echo -e "${RED}#${RESET} Failed to install jq in the first run...\\n"
    if [[ "${repo_codename}" =~ (precise|trusty|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular) ]]; then
      if [[ "${repo_codename}" =~ (bionic|cosmic|disco|eoan|focal|focal|groovy|hirsute|impish) ]]; then repo_component="main universe"; add_repositories; fi
      if [[ "${repo_codename}" =~ (jammy|kinetic|lunar|mantic|noble|oracular) ]]; then repo_component="main"; add_repositories; fi
      repo_codename_argument="-security"; repo_component="main universe"
    elif [[ "${repo_codename}" =~ (wheezy|jessie|stretch|buster|bullseye|bookworm|trixie|forky) ]]; then
      if [[ "${repo_codename}" =~ (wheezy|jessie|stretch|buster) ]]; then repo_url_arguments="-security/"; repo_codename_argument="/updates"; repo_component="main"; add_repositories; fi
      if [[ "${repo_codename}" =~ (bullseye|bookworm|trixie|forky) ]]; then repo_url_arguments="-security/"; repo_codename_argument="-security"; repo_component="main"; add_repositories; fi
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
if ! dpkg -l net-tools 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
  if [[ "${installing_required_package}" != 'yes' ]]; then
    install_required_packages
  fi
  echo -e "${WHITE_R}#${RESET} Installing net-tools..."
  if ! DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install net-tools &>> "${eus_dir}/logs/required.log"; then
    echo -e "${RED}#${RESET} Failed to install net-tools in the first run...\\n"
    repo_component="main"
    add_repositories
    required_package="net-tools"
    apt_get_install_package
  else
    echo -e "${GREEN}#${RESET} Successfully installed net-tools! \\n" && sleep 2
  fi
  get_repo_url
fi
if ! dpkg -l curl 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
  if [[ "${installing_required_package}" != 'yes' ]]; then
    install_required_packages
  fi
  echo -e "${WHITE_R}#${RESET} Installing curl..."
  if ! DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install curl &>> "${eus_dir}/logs/required.log"; then
    echo -e "${RED}#${RESET} Failed to install curl in the first run...\\n"
    if [[ "${repo_codename}" =~ (precise|trusty|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic) ]]; then
      if [[ "${repo_codename}" =~ (precise|trusty|xenial|bionic|cosmic) ]]; then repo_codename_argument="-security"; repo_component="main"; fi
      if [[ "${repo_codename}" =~ (disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic) ]]; then repo_component="main"; fi
    elif [[ "${repo_codename}" == "jessie" ]]; then
      repo_codename_argument="/updates"
      repo_component="main"
    elif [[ "${repo_codename}" =~ (stretch|buster|bullseye|bookworm|trixie|forky) ]]; then
      repo_component="main"
    fi
    add_repositories
    required_package="curl"
    apt_get_install_package
  else
    echo -e "${GREEN}#${RESET} Successfully installed curl! \\n" && sleep 2
  fi
  set_curl_arguments
  script_version_check
  get_repo_url
fi
if [[ -n "${auto_dns_challenge_provider}" ]]; then
  if [[ "${certbot_native_plugin}" == 'true' ]]; then
    if ! dpkg -l "python3-certbot-dns-${auto_dns_challenge_provider}" 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
      if [[ "${installing_required_package}" != 'yes' ]]; then
        install_required_packages
      fi
      echo -e "${WHITE_R}#${RESET} Installing python3-certbot-dns-${auto_dns_challenge_provider}..."
      if ! DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "python3-certbot-dns-${auto_dns_challenge_provider}" &>> "${eus_dir}/logs/required.log"; then
        echo -e "${RED}#${RESET} Failed to install python3-certbot-dns-${auto_dns_challenge_provider} in the first run...\\n"
        if [[ "${repo_codename}" =~ (precise|trusty|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular) ]]; then
          if [[ "${repo_codename}" =~ (focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular) ]]; then repo_component="main universe"; add_repositories; fi
          repo_codename_argument="-security"
          repo_component="main universe"
        elif [[ "${repo_codename}" =~ (wheezy|jessie|stretch|buster|bullseye|bookworm|trixie|forky) ]]; then
          if [[ "${repo_codename}" =~ (stretch) ]]; then repo_url_arguments="-security/"; repo_codename_argument="/updates"; repo_component="main"; add_repositories; fi
          repo_component="main"
        fi
        add_repositories
        required_package="python3-certbot-dns-${auto_dns_challenge_provider}"
        apt_get_install_package
      else
        echo -e "${GREEN}#${RESET} Successfully installed python3-certbot-dns-${auto_dns_challenge_provider}! \\n" && sleep 2
      fi
    fi
    if [[ -n "$(apt-cache show "python3-certbot-dns-${auto_dns_challenge_provider}" | awk '/Depends/ && /certbot/ {print "certbot"}')" ]]; then certbot_install_function; fi
    if ! dpkg -l python3-certbot 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
      if [[ "${installing_required_package}" != 'yes' ]]; then
        install_required_packages
      fi
      echo -e "${WHITE_R}#${RESET} Installing python3-certbot..."
      if ! DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install python3-certbot &>> "${eus_dir}/logs/required.log"; then
        echo -e "${RED}#${RESET} Failed to install python3-certbot in the first run...\\n"
        if [[ "${repo_codename}" =~ (precise|trusty|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular) ]]; then
          if [[ "${repo_codename}" =~ (focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular) ]]; then repo_component="main universe"; add_repositories; fi
          repo_codename_argument="-security"
          repo_component="main universe"
        elif [[ "${repo_codename}" =~ (wheezy|jessie|stretch|buster|bullseye|bookworm|trixie|forky) ]]; then
          if [[ "${repo_codename}" =~ (stretch) ]]; then repo_url_arguments="-security/"; repo_codename_argument="/updates"; repo_component="main"; add_repositories; fi
          repo_component="main"
        fi
        add_repositories
        required_package="python3-certbot"
        apt_get_install_package
      else
        echo -e "${GREEN}#${RESET} Successfully installed python3-certbot! \\n" && sleep 2
      fi
    fi
  elif [[ "${certbot_multi_plugin}" == 'true' ]]; then
    certbot_required_packages=( "python3" "python3-venv" "libaugeas0" )
    while read -r package; do
      if ! dpkg -l "${package}" 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
        if [[ "${installing_required_package}" != 'yes' ]]; then
          install_required_packages
        fi
        echo -e "${WHITE_R}#${RESET} Installing ${package}..."
        if ! DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "${package}" &>> "${eus_dir}/logs/required.log"; then
          echo -e "${RED}#${RESET} Failed to install ${package} in the first run...\\n"
          if [[ "${repo_codename}" =~ (precise|trusty|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular) ]]; then
            if [[ "${repo_codename}" =~ (focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular) ]]; then repo_component="main universe"; add_repositories; fi
            repo_codename_argument="-security"
            repo_component="main universe"
          elif [[ "${repo_codename}" =~ (wheezy|jessie|stretch|buster|bullseye|bookworm|trixie|forky) ]]; then
            if [[ "${repo_codename}" =~ (stretch) ]]; then repo_url_arguments="-security/"; repo_codename_argument="/updates"; repo_component="main"; add_repositories; fi
            repo_component="main"
          fi
          add_repositories
          required_package="${package}"
          apt_get_install_package
        else
          echo -e "${GREEN}#${RESET} Successfully installed ${package}! \\n" && sleep 2
        fi
      fi
    done < <(printf '%s\n' "${certbot_required_packages[@]}")
    # Setup virtual environment for certbot
    echo -e "${WHITE_R}#${RESET} Installing certbot and it's required packages..."
    if ! python3 -m venv /opt/certbot/ &>> "${eus_dir}/logs/python-certbot.log"; then
      abort_reason="Failed to setup a virtual environment for certbot."; abort
    fi
    if ! /opt/certbot/bin/pip install --upgrade pip &>> "${eus_dir}/logs/python-certbot.log"; then
      abort_reason="Failed to upgrade pip."; abort
    fi
    if ! /opt/certbot/bin/pip install certbot certbot &>> "${eus_dir}/logs/python-certbot.log"; then
      abort_reason="Failed to install certbot."; abort
    fi
    if ! [[ -s /usr/bin/certbot ]]; then 
      if ! ln -s /opt/certbot/bin/certbot /usr/bin/certbot &>> "${eus_dir}/logs/python-certbot.log"; then
        abort_reason="Failed to create a symlink for certbot."; abort
      fi
    fi
    # Install go
    if [[ "${architecture}" =~ (arm64|amd64) ]]; then
      if ! curl --location "${nos_curl_argument[@]}" --output "${eus_dir}/go.tar.gz" "https://go.dev/dl/$(curl --silent "https://go.dev/dl/?mode=json" | jq -r '.[0].files[] | select(.os == "linux" and .arch == "'"${architecture}"'").filename')" &>> "${eus_dir}/logs/go-application.log"; then
        abort_reason="Failed to download go."; abort
      else
        if [[ -e /usr/local/go ]]; then rm -rf /usr/local/go &> /dev/null; fi
        if ! tar -C /usr/local -xzf "${eus_dir}/go.tar.gz" &>> "${eus_dir}/logs/go-application.log"; then
          abort_reason="Failed to extract go."; abort
        else
          export PATH="$PATH:/usr/local/go/bin"
          if [[ -z "$(command -v go)" ]]; then
            abort_reason="Failed to locate the go command."; abort
          fi
        fi
      fi
    else
      echo -e "${RED}#${RESET} Failed to locate go for ${architecture}."; abort
    fi
    if ! /opt/certbot/bin/pip install certbot-dns-multi &>> "${eus_dir}/logs/python-certbot.log"; then
      abort_reason="Failed to install certbot-dns-multi."; abort
    fi
    echo -e "${GREEN}#${RESET} Successfully installed certbot and it's required packages! \\n"
  fi
fi

check_snapd_running() {
  if [[ "${os_codename}" =~ (precise|maya|trusty|qiana|rebecca|rafaela|rosa) ]]; then
    if ! systemctl status snapd | grep -iq running; then
      echo -e "${WHITE_R}#${RESET} snapd doesn't appear to be running... Trying to start it..."
      if systemctl start snapd &> /dev/null; then echo -e "${GREEN}#${RESET} Successfully started snapd!"; sleep 3; fi
      if ! systemctl status snapd | grep -iq running; then
        abort_reason="snapd isn't running"
        abort
      fi
    fi
  else
    if ! systemctl is-active -q snapd; then
      if [[ "${installing_required_package}" != 'yes' ]]; then echo -e "\\n${GREEN}---${RESET}\\n"; else header; fi
      echo -e "${WHITE_R}#${RESET} snapd doesn't appear to be running... Trying to start it..."
      if systemctl start snapd &> /dev/null; then echo -e "${GREEN}#${RESET} Successfully started snapd!"; sleep 3; fi
      if ! systemctl is-active -q snapd; then
        abort_reason="snapd isn't running"
        abort
      fi
    fi
  fi
}

support_file_requests_opt_in() {
  if [[ "$(jq -r '.database["support-file-upload"]' "${eus_dir}/db/db.json")" != 'true' ]]; then
    opt_in_requests="$(jq -r '.database["opt-in-requests"]' "${eus_dir}/db/db.json")"
    ((opt_in_requests=opt_in_requests+1))
    if [[ "${opt_in_requests}" -ge '3' ]]; then
      opt_in_rotations="$(jq -r '.database["opt-in-rotations"]' "${eus_dir}/db/db.json")"
      ((opt_in_rotations=opt_in_rotations+1))
      if [[ "$(dpkg-query --showformat='${Version}' --show jq | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
        jq '."database" += {"opt-in-rotations": "'"${opt_in_rotations}"'"}' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
      else
        jq --arg opt_in_rotations "$opt_in_rotations" '.database = (.database + {"opt-in-rotations": $opt_in_rotations})' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
      fi
      eus_database_move
      if [[ "$(dpkg-query --showformat='${Version}' --show jq | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
        jq --arg opt_in_requests "0" '."database" += {"opt-in-requests": "'"${opt_in_requests}"'"}' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
      else
        jq --arg opt_in_requests "$opt_in_requests" '.database = (.database + {"opt-in-requests": $opt_in_requests})' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
      fi
      eus_database_move
    else
      if [[ "$(dpkg-query --showformat='${Version}' --show jq | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
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
    if [[ "${script_option_skip}" != 'true' ]]; then echo -e "${WHITE_R}#${RESET} The script generates support files when failures are detected, these can help Glenn R. to"; echo -e "${WHITE_R}#${RESET} improve the script quality for the Community and resolve your issues in future versions of the script.\\n"; read -rp $'\033[39m#\033[0m Do you want to automatically upload the support files? (Y/n) ' yes_no; fi
    case "$yes_no" in
        [Yy]*|"") upload_support_files="true";;
        [Nn]*) upload_support_files="false";;
    esac
    if [[ "$(dpkg-query --showformat='${Version}' --show jq | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)" -ge "16" ]]; then
      jq '."database" += {"support-file-upload": "'"${upload_support_files}"'"}' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
    else
      jq --arg upload_support_files "$upload_support_files" '.database = (.database + {"support-file-upload": $upload_support_files})' "${eus_dir}/db/db.json" > "${eus_dir}/db/db.json.tmp" 2>> "${eus_dir}/logs/eus-database-management.log"
    fi
    eus_database_move
  fi
}
support_file_upload_opt_in
support_file_requests_opt_in

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                            Variables                                                                                            #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

certbot_auto_install_run() {
  header
  echo -e "${WHITE_R}#${RESET} Running script in certbot-auto mode, installing more required packages..."
  echo -e "${WHITE_R}#${RESET} This may take a while, depending on the device."
  echo -e "${WHITE_R}#${RESET} certbot-auto verbose log is saved here: ${eus_dir}/logs/certbot_auto_install.log\\n\\n${WHITE_R}----${RESET}\\n"
  sleep 2
  if [[ "${os_codename}" =~ (wheezy|jessie) ]]; then
    if ! dpkg -l | awk '{print$2}' | grep -iq "libssl-dev"; then
      echo deb http://archive.debian.org/debian jessie-backports main >>/etc/apt/sources.list.d/glennr-install-script.list
      echo -e "${WHITE_R}#${RESET} Running apt-get update..."
      if apt-get update -o Acquire::Check-Valid-Until=false &>> "${eus_dir}/logs/required.log"; then echo -e "${GREEN}#${RESET} Successfully ran apt-get update! \\n"; else echo -e "${YELLOW}#${RESET} Something went wrong during apt-get update...\\n"; fi
      echo -e "${WHITE_R}#${RESET} Installing a required package..."
      if DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install -t jessie-backports libssl-dev -y &>> "${eus_dir}/logs/required.log"; then echo -e "${GREEN}#${RESET} Successfully installed the required package! \\n"; else abort_reason="Failed to install required package."; abort; fi
      sed -i '/jessie-backports/d' /etc/apt/sources.list.d/glennr-install-script.list
    fi
  fi
  certbot_auto_permission_check
  if "${eus_dir}/certbot-auto" --non-interactive --install-only --verbose "${certbot_auto_flags}" 2>&1 | tee "${eus_dir}/logs/certbot_auto_install.log"; then
    if grep -ioq "Your system is not supported by certbot-auto anymore" "${eus_dir}/logs/certbot_auto_install.log"; then
      header_red
      echo -e "${YELLOW}#${RESET} certbot-auto no longer supports your system..."
      echo -e "${YELLOW}#${RESET} We will try an older version of the certbot-auto script..."
      sleep 5
      use_older_certbot_auto_script=true
      download_certbot_auto
      certbot_auto_flags="--no-self-upgrade"
      certbot_auto_install_run
      return
    elif grep -ioq "Certbot is installed" "${eus_dir}/logs/certbot_auto_install.log"; then
      return
    else
      abort_reason="Error during certbot_auto_install_run function."
      abort
    fi
  else
    abort_reason="Error during certbot_auto_install_run function."
    abort
  fi
}

if [[ "${os_codename}" =~ (wheezy|jessie) || "${downloaded_certbot}" == 'true' ]]; then
  certbot="${eus_dir}/certbot-auto"
  certbot_auto=true
elif [[ "${certbot_multi_plugin}" == 'true' ]]; then
  if [[ -e "/usr/bin/certbot" ]]; then mv /usr/bin/certbot /usr/bin/certbot.eus_org &>> "${eus_dir}/logs/certbot-multi-dns-symlink.log"; fi
  ln -sf /opt/certbot/bin/certbot /usr/bin/certbot &>> "${eus_dir}/logs/certbot-multi-dns-symlink.log"
  certbot="/opt/certbot/bin/certbot"
else
  certbot="certbot"
fi

manual_fqdn='no'
run_uck_scripts='no'
if [[ "${run_force_renew}" == 'true' ]]; then
  renewal_option="--force-renewal"
else
  renewal_option="--keep-until-expiring"
fi

# Use RSA key for UniFi Core devices
if [[ "${unifi_core_system}" == 'true' ]]; then
  certbot_version="$(certbot --version | awk '{print $2}')"
  if [[ "$(echo "${certbot_version}" | cut -d'.' -f1)" -ge '2' ]]; then
    key_type_option="--key-type rsa"
  fi
fi

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                           Unattended                                                                                            #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

fqdn_option() {
  header
  echo -e "\\n------- $(date +%F-%R) -------\\n" &>> "${eus_dir}/logs/unattended.log"
  server_fqdn="$(head -n1 "${eus_dir}/fqdn_option_domains" | tr '[:upper:]' '[:lower:]')"
  if [[ "${server_ip}" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    if ! [[ "$(echo "${server_ip}" | cut -d'.' -f1)" -le '255' && "$(echo "${server_ip}" | cut -d'.' -f2)" -le '255' && "$(echo "${server_ip}" | cut -d'.' -f3)" -le '255' && "$(echo "${server_ip}" | cut -d'.' -f4)" -le '255' ]]; then
      manual_server_ip="false"
    fi
  fi
  while read -r line; do
    if [[ "${manual_server_ip}" == 'true' ]]; then server_ip="$(head -n1 "${eus_dir}/server_ip")"; else server_ip="$(curl "${curl_argument[@]}" "${curl_option}" https://api.glennr.nl/api/geo 2> /dev/null | jq -r '."address"' 2> /dev/null)"; fi
    echo -e "${WHITE_R}#${RESET} Checking if '${line}' resolves to '${server_ip}'" | tee -a "${eus_dir}/logs/unattended.log"
    domain_record="$(dig +short "${dig_option}" "${line}" "${external_dns_server}" &>> "${eus_dir}/domain_records")"
    if grep -xq "${server_ip}" "${eus_dir}/domain_records"; then domain_record="${server_ip}"; fi
    if grep -xq "connection timed out" "${eus_dir}/domain_records"; then echo -e "${RED}#${RESET} Timed out when reaching DNS server... \\n${RED}#${RESET} Please confirm that the system can reach the specified DNS server. \\n" | tee -a "${eus_dir}/logs/unattended.log"; abort_reason="Timed out when reaching DNS server."; abort; fi
    if [[ -f "${eus_dir}/domain_records" ]]; then resolved_ip="$(grep "..*\\..*\\..*\\..*" "${eus_dir}/domain_records")"; fi
    rm --force "${eus_dir}/domain_records" &> /dev/null
    if [[ "${server_ip}" != "${domain_record}" ]]; then echo -e "${RED}#${RESET} '${line}' does not resolve to '${server_ip}', it resolves to '${resolved_ip}' instead... \\n" | tee -a "${eus_dir}/logs/unattended.log"; if [[ "${server_fqdn}" == "${line}" ]]; then abort_skip_support_file_upload="true"; abort_reason="${line} does not resolve to ${server_ip}, but to ${resolved_ip} instead."; abort; fi; else echo -e "${GREEN}#${RESET} Successfully resolved '${line}' ( '${server_ip}' ) \\n" | tee -a "${eus_dir}/logs/unattended.log"; if [[ "${server_fqdn}" != "${domain_record}" ]]; then echo "${line}" &>> "${eus_dir}/other_domain_records"; fi; fi
    sleep 2
  done < "${eus_dir}/fqdn_option_domains"
  rm --force "${eus_dir}/fqdn_option_domains" &> /dev/null
  if [[ "$(grep -c "" "${eus_dir}/other_domain_records" 2> /dev/null)" -eq "0" ]]; then echo -e "${RED}#${RESET} None of the FQDN's resolved correctly... \\n" | tee -a "${eus_dir}/logs/unattended.log"; abort_skip_support_file_upload="true"; abort_reason="None of the FQDN's resolved correctly."; abort; fi
  if [[ "$(grep -c "" "${eus_dir}/other_domain_records" 2> /dev/null)" -ge "1" ]]; then multiple_fqdn_resolved="true"; fi
  if [[ "${install_script}" == 'true' ]]; then echo "${server_fqdn}" &> "${eus_dir}/server_fqdn_install"; fi
  sleep 2
}

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                             Script                                                                                              #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

delete_certs_question() {
  header
  echo -e "${WHITE_R}#${RESET} What would you like to do with the old certificates?\\n\\n"
  echo -e " [   ${WHITE_R}1${RESET}   ]  |  Keep all certificates. ( default )"
  echo -e " [   ${WHITE_R}2${RESET}   ]  |  Keep last 3 certificates."
  echo -e " [   ${WHITE_R}3${RESET}   ]  |  Cancel script."
  echo -e "\\n"
  read -rp $'Your choice | \033[39m' choice
  case "$choice" in
     1|"") old_certificates=all;;
     2) old_certificates=last_three;;
     3) cancel_script;;
	 *) 
        header_red
        echo -e "${WHITE_R}#${RESET} '${choice}' is not a valid option..." && sleep 2
        delete_certs_question;;
  esac
}

time_date="$(date +%Y%m%d_%H%M)"

timezone() {
  if ! [[ -f "${eus_dir}/timezone_correct" ]]; then
    if [[ -f /etc/timezone && -s /etc/timezone ]]; then
      time_zone="$(awk '{print $1}' /etc/timezone)"
    else
      time_zone="$(timedatectl | grep -i "time zone" | awk '{print $3}')"
    fi
    header
    echo -e "${WHITE_R}#${RESET} Your timezone is set to ${time_zone}."
    read -rp $'\033[39m#\033[0m Is your timezone correct? (Y/n) ' yes_no
    case "${yes_no}" in
       [Yy]*|"") touch "${eus_dir}/timezone_correct";;
       [Nn]*|*)
          header
          echo -e "${WHITE_R}#${RESET} Let's change your timezone!" && sleep 3; mkdir -p /tmp/EUS/
          dpkg-reconfigure tzdata && clear
          if [[ -f /etc/timezone && -s /etc/timezone ]]; then
            time_zone="$(awk '{print $1}' /etc/timezone)"
          else
            time_zone="$(timedatectl | grep -i "time zone" | awk '{print $3}')"
          fi
          rm --force /tmp/EUS/timezone 2> /dev/null
          header
          read -rp $'\033[39m#\033[0m Your timezone is now set to "'"${time_zone}"'", is that correct? (Y/n) ' yes_no
          case "${yes_no}" in
             [Yy]*|"") touch "${eus_dir}/timezone_correct";;
             [Nn]*|*) timezone;;
          esac;;
    esac
  fi
}

domain_name() {
  if [[ "${manual_fqdn}" == 'no' ]]; then
    if dpkg -l unifi 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
      server_fqdn="$("${mongocommand}" --quiet --port 27117 ace --eval "${mongoprefix}db.getCollection('setting').find({key:'super_identity'})${mongosuffix}" | sed 's/\(ObjectId(\|)\|NumberLong(\)//g' | jq -r '.[]."hostname"')"
    else
      if [[ -f "${eus_dir}/server_fqdn" ]]; then
        server_fqdn="$(head -n1 "${eus_dir}/server_fqdn")"
      else
        server_fqdn='unifi.yourdomain.com'
      fi
      no_unifi=yes
    fi
    current_server_fqdn="$server_fqdn"
  fi
  header
  echo -e "${WHITE_R}#${RESET} Your FQDN is set to '${server_fqdn}'"
  read -rp $'\033[39m#\033[0m Is the domain name/FQDN above correct? (Y/n) ' yes_no
  case "${yes_no}" in
     [Yy]*|"") le_resolve;;
     [Nn]*|*) le_manual_fqdn;;
  esac
}

multiple_fqdn_resolve() {
  header
  other_fqdn="$(echo "${other_fqdn}" | tr '[:upper:]' '[:lower:]')"
  echo -e "${WHITE_R}#${RESET} Trying to resolve '${other_fqdn}'"
  other_domain_records="$(dig +short "${dig_option}" "${other_fqdn}" "${external_dns_server}" &>> "${eus_dir}/other_domain_records_tmp")"
  if grep -xq "${server_ip}" "${eus_dir}/other_domain_records_tmp"; then other_domain_records="${server_ip}"; fi
  if grep -xq "connection timed out" "${eus_dir}/other_domain_records_tmp"; then echo -e "${RED}#${RESET} Timed out when reaching DNS server... \\n${RED}#${RESET} Please confirm that the system can reach the specified DNS server. \\n"; abort_reason="Timed out when reaching the DNS server."; abort; fi
  resolved_ip="$(grep "..*\\..*\\..*\\..*" "${eus_dir}/other_domain_records_tmp")"
  rm --force "${eus_dir}/other_domain_records_tmp" &> /dev/null
  sleep 3
  if [[ "${server_ip}" != "${other_domain_records}" ]]; then
    header
    echo -e "${WHITE_R}#${RESET} '${other_fqdn}' does not resolve to '${server_ip}', it resolves to '${resolved_ip}' instead... \\n"
    echo -e "${WHITE_R}#${RESET} Please make an A record pointing to your server's ip."
    echo -e "${WHITE_R}#${RESET} If you are using Cloudflare, please disable the orange cloud.\\n"
    echo -e "${GREEN}---${RESET}\\n"
    echo -e "${WHITE_R}#${RESET} Please take an option below.\\n"
    echo -e " [   ${WHITE_R}1${RESET}   ]  |  Skip and continue script. ( default )"
    echo -e " [   ${WHITE_R}2${RESET}   ]  |  Try a different FQDN."
    echo -e " [   ${WHITE_R}3${RESET}   ]  |  Cancel Script."
    echo -e "\\n\\n"
    read -rp $'Your choice | \033[39m' le_resolve_question
    case "${le_resolve_question}" in
       1*|"") ;;
       2*) multiple_fqdn;;
       3*) cancel_script;;
       *) unknown_option;;
    esac
  elif [[ "${server_fqdn}" == "${other_fqdn}" ]]; then
    header
    echo -e "${WHITE_R}#${RESET} '${other_fqdn}' is the same as '${server_fqdn}' and already entered..."
    read -rp $'\033[39m#\033[0m Do you want to add another FQDN? (Y/n) ' yes_no
    case "$yes_no" in
       [Yy]*|"") multiple_fqdn;;
       [Nn]*) ;;
    esac
  elif grep -ixq "${other_fqdn}" "${eus_dir}/other_domain_records" &> /dev/null; then
    header
    echo -e "${WHITE_R}#${RESET} '${other_fqdn}' was already entered..."
    read -rp $'\033[39m#\033[0m Do you want to add another FQDN? (Y/n) ' yes_no
    case "$yes_no" in
       [Yy]*|"") multiple_fqdn;;
       [Nn]*) ;;
    esac
  else
    multiple_fqdn_resolved=true
    echo "${other_fqdn}" | tr '[:upper:]' '[:lower:]' &>> "${eus_dir}/other_domain_records"
    echo -e "${WHITE_R}#${RESET} '${other_fqdn}' resolved correctly!"
    echo -e "\\n${GREEN}---${RESET}\\n"
    read -rp $'\033[39m#\033[0m Do you want to add more FQDNs? (Y/n) ' yes_no
    case "$yes_no" in
       [Yy]*|"") multiple_fqdn;;
       [Nn]*) ;;
    esac
  fi
}

multiple_fqdn() {
  header
  echo -e "${WHITE_R}#${RESET} Please enter the other FQDN of your setup below."
  read -rp $'\033[39m#\033[0m ' other_fqdn
  multiple_fqdn_resolve
}

le_resolve() {
  header
  server_fqdn="$(echo "${server_fqdn}" | tr '[:upper:]' '[:lower:]')"
  echo -e "${WHITE_R}#${RESET} Trying to resolve '${server_fqdn}'"
  if [[ "${manual_server_ip}" == 'true' ]]; then
    server_ip="$(head -n1 "${eus_dir}/server_ip")"
  else
    server_ip="$(curl "${curl_argument[@]}" "${curl_option}" https://api.glennr.nl/api/geo 2> /dev/null | jq -r '."address"' 2> /dev/null)"
  fi
  domain_record="$(dig +short "${dig_option}" "${server_fqdn}" "${external_dns_server}" &>> "${eus_dir}/domain_records")"
  if grep -xq "${server_ip}" "${eus_dir}/domain_records"; then
    domain_record="${server_ip}"
  fi
  rm --force "${eus_dir}/domain_records" 2> /dev/null
  sleep 3
  if [[ "${server_ip}" != "${domain_record}" ]]; then
    header
    echo -e "${WHITE_R}#${RESET} '${server_fqdn}' does not resolve to '${server_ip}'"
    echo -e "${WHITE_R}#${RESET} Please make an A record pointing to your server's ip."
    echo -e "${WHITE_R}#${RESET} If you are using Cloudflare, please disable the orange cloud."
    echo -e "\\n${GREEN}---${RESET}\\n\\n${WHITE_R}#${RESET} Please take an option below.\\n"
    echo -e " [   ${WHITE_R}1${RESET}   ]  |  Try to resolve your FQDN again. ( default )"
    echo -e " [   ${WHITE_R}2${RESET}   ]  |  Resolve with a external DNS server."
    if [[ "${manual_server_ip}" == 'true' ]]; then
      echo -e " [   ${WHITE_R}3${RESET}   ]  |  Manually set the server IP. ( for users with multiple IP addresses )"
      echo -e " [   ${WHITE_R}4${RESET}   ]  |  Automatically get server IP."
      echo -e " [   ${WHITE_R}5${RESET}   ]  |  Cancel Script."
    else
      echo -e " [   ${WHITE_R}3${RESET}   ]  |  Manually set the server IP. ( for users with multiple IP addresses )"
      echo -e " [   ${WHITE_R}4${RESET}   ]  |  Cancel Script."
    fi
    echo ""
    echo ""
    echo ""
    read -rp $'Your choice | \033[39m' le_resolve_question
    case "${le_resolve_question}" in
       1*|"") le_manual_fqdn;;
       2*) 
          header
          echo -e "${WHITE_R}#${RESET} What external DNS server would you like to use?"
          echo ""
          if [[ "${run_ipv6}" == 'true' ]]; then
            echo -e " [   ${WHITE_R}1${RESET}   ]  |  Google          ( 2001:4860:4860::8888 )"
            echo -e " [   ${WHITE_R}2${RESET}   ]  |  Google          ( 2001:4860:4860::8844 )"
            echo -e " [   ${WHITE_R}3${RESET}   ]  |  Cloudflare      ( 2606:4700:4700::1111 )"
            echo -e " [   ${WHITE_R}4${RESET}   ]  |  Cloudflare      ( 2606:4700:4700::1001 )"
            echo -e " [   ${WHITE_R}5${RESET}   ]  |  Cisco Umbrella  ( 2620:119:35::35 )"
            echo -e " [   ${WHITE_R}6${RESET}   ]  |  Cisco Umbrella  ( 2620:119:53::53 )"
          else
            echo -e " [   ${WHITE_R}1${RESET}   ]  |  Google          ( 8.8.8.8 )"
            echo -e " [   ${WHITE_R}2${RESET}   ]  |  Google          ( 8.8.4.4 )"
            echo -e " [   ${WHITE_R}3${RESET}   ]  |  Cloudflare      ( 1.1.1.1 )"
            echo -e " [   ${WHITE_R}4${RESET}   ]  |  Cloudflare      ( 1.0.0.1 )"
            echo -e " [   ${WHITE_R}5${RESET}   ]  |  Cisco Umbrella  ( 208.67.222.222 )"
            echo -e " [   ${WHITE_R}6${RESET}   ]  |  Cisco Umbrella  ( 208.67.220.220 )"
          fi
          echo -e " [   ${WHITE_R}7${RESET}   ]  |  Don't use external DNS servers."
          echo -e " [   ${WHITE_R}8${RESET}   ]  |  Cancel script"
          echo ""
          echo ""
          echo ""
          read -rp $'Your choice | \033[39m' le_resolve_question
          case "${le_resolve_question}" in
             1*|"") if [[ "${run_ipv6}" == 'true' ]]; then external_dns_server='@2001:4860:4860::8888' && le_resolve; else external_dns_server='@8.8.8.8' && le_resolve; fi;;
             2*) if [[ "${run_ipv6}" == 'true' ]]; then external_dns_server='@2001:4860:4860::8844' && le_resolve; else external_dns_server='@8.8.4.4' && le_resolve; fi;;
             3*) if [[ "${run_ipv6}" == 'true' ]]; then external_dns_server='@2606:4700:4700::1111' && le_resolve; else external_dns_server='@1.1.1.1' && le_resolve; fi;;
             4*) if [[ "${run_ipv6}" == 'true' ]]; then external_dns_server='@2606:4700:4700::1001' && le_resolve; else external_dns_server='@1.0.0.1' && le_resolve; fi;;
             5*) if [[ "${run_ipv6}" == 'true' ]]; then external_dns_server='@2620:119:35::35' && le_resolve; else external_dns_server='@208.67.222.222' && le_resolve; fi;;
             6*) if [[ "${run_ipv6}" == 'true' ]]; then external_dns_server='@2620:119:53::53' && le_resolve; else external_dns_server='@208.67.220.220' && le_resolve; fi;;
             7*) le_resolve;;
             8*) cancel_script;;
             *) unknown_option;;
          esac;;
       3*) le_manual_server_ip;;
       4*) if [[ "${manual_server_ip}" == 'true' ]]; then rm --force "${eus_dir}/server_fqdn" &> /dev/null; manual_server_ip=false; le_resolve; else cancel_script; fi;;
       5*) if [[ "${manual_server_ip}" == 'true' ]]; then cancel_script; else unknown_option; fi;;
       *) unknown_option;;
    esac
  else
    echo -e "${WHITE_R}#${RESET} '${server_fqdn}' resolved correctly!"
    if [[ "${install_script}" == 'true' ]]; then echo "${server_fqdn}" &> "${eus_dir}/server_fqdn_install"; fi
    echo -e "\\n${GREEN}---${RESET}\\n"
    read -rp $'\033[39m#\033[0m Do you want to add more FQDNs? (Y/n) ' yes_no
    case "$yes_no" in
       [Yy]*|"") multiple_fqdn;;
       [Nn]*) ;;
    esac
  fi
}

change_application_hostname() {
  if [[ "${manual_fqdn}" == 'true' && "${run_ipv6}" != 'true' ]] && dpkg -l unifi 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
    header
    echo -e "${WHITE_R}#${RESET} Your current UniFi Network Application FQDN is set to '${current_server_fqdn}' in the settings..."
    echo -e "${WHITE_R}#${RESET} Would you like to change it to '${server_fqdn}'?"
    echo ""
    echo ""
    read -rp $'\033[39m#\033[0m Would you like to apply the change? (Y/n) ' yes_no
    case "$yes_no" in
       [Yy]*|"")
          if [[ "$("${mongocommand}" --quiet --port 27117 ace --eval "${mongoprefix}db.getCollection('setting').find({key:'super_mgmt'})${mongosuffix}" | jq -r '.[].override_inform_host')" != 'true' ]]; then
            if "${mongocommand}" --quiet --port 27117 ace --eval "db.setting.updateOne({\"hostname\":\"${current_server_fqdn}\"}, {\$set: {\"hostname\":\"${server_fqdn}\"}})" | grep -iq "\"nModified\":.*1"; then
              header
              echo -e "${GREEN}#${RESET} Successfully changed the UniFi Network Application Hostname to '${server_fqdn}'"
              sleep 2
            fi
          fi;;
       [Nn]*) ;;
    esac
  fi
}

unknown_option() {
  header_red
  echo -e "${WHITE_R}#${RESET} '${le_resolve_question}' is not a valid option..." && sleep 2
  le_resolve
}

le_manual_server_ip() {
  manual_server_ip=true
  header
  echo -e "${WHITE_R}#${RESET} Please enter your Server/WAN IP below."
  read -rp $'\033[39m#\033[0m ' server_ip
  if [[ -f "${eus_dir}/server_ip" ]]; then rm --force "${eus_dir}/server_ip" &> /dev/null; fi
  echo "$server_ip" >> "${eus_dir}/server_ip"
  le_resolve
}

le_manual_fqdn() {
  manual_fqdn=true
  header
  echo -e "${WHITE_R}#${RESET} Please enter the FQDN of your setup below."
  read -rp $'\033[39m#\033[0m ' server_fqdn
  if [[ "${no_unifi}" == 'yes' ]]; then
    if [[ -f "${eus_dir}/server_fqdn" ]]; then rm --force "${eus_dir}/server_fqdn" &> /dev/null; fi
    echo "$server_fqdn" >> "${eus_dir}/server_fqdn"
  fi
  le_resolve
}

le_email() {
  email_reg='^(([A-Za-z0-9]+((\.|\-|\_|\+)?[A-Za-z0-9]?)*[A-Za-z0-9]+)|[A-Za-z0-9]+)@(([A-Za-z0-9]+)+((\.|\-|\_)?([A-Za-z0-9]+)+)*)+\.([A-Za-z]{2,})+$'
  header
  if [[ "${skip_email_question}" != 'yes' ]]; then
    read -rp $'\033[39m#\033[0m Do you want to setup a email address for renewal notifications? (Y/n) ' yes_no
  fi
  case "$yes_no" in
     [Yy]*|"")
        header
        echo -e "${WHITE_R}#${RESET} Please enter the email address below."
        read -rp $'\033[39m#\033[0m ' le_user_mail
        if ! [[ "${le_user_mail}" =~ ${email_reg} ]]; then
          header_red
          echo -e "${RED}#${RESET} ${le_user_mail} is an invalid email address..."
          read -rp $'\033[39m#\033[0m Do you want to try another email address? (Y/n) ' yes_no
          case "$yes_no" in
             [Yy]*|"")
                skip_email_question=yes
                le_email
                return;;
             [Nn]*|*)
                email="--register-unsafely-without-email";;
          esac
        else
          email="--email ${le_user_mail}"
        fi;;
     [Nn]*|*)
        email="--register-unsafely-without-email";;
  esac
}

le_pre_hook() {
  if ! [[ -d /etc/letsencrypt/renewal-hooks/pre/ ]]; then
    mkdir -p /etc/letsencrypt/renewal-hooks/pre/
  fi
  # shellcheck disable=SC1117
  tee "/etc/letsencrypt/renewal-hooks/pre/EUS_${server_fqdn}.sh" &>/dev/null <<EOF
#!/bin/bash
prevent_modify_firewall="${script_option_prevent_modify_firewall}"
rm --force "${eus_dir}/le_http_service" 2> /dev/null
if [[ -d "${eus_dir}/logs" ]]; then mkdir -p "${eus_dir}/logs"; fi
if [[ -d "${eus_dir}/checksum" ]]; then mkdir -p "${eus_dir}/checksum"; fi
if [[ \${log_date} != 'true' ]]; then
  echo -e "\\n------- \$(date +%F-%R) -------\\n" &>> "${eus_dir}/logs/http_service.log"
  log_date=true
fi
netstat -tulpn | grep ":80 " | awk '{print \$7}' | sed 's/[0-9]*\///' | sed 's/://' &>> "${eus_dir}/le_http_service_temp"
awk '!a[\$0]++' "${eus_dir}/le_http_service_temp" >> "${eus_dir}/le_http_service" && rm --force "${eus_dir}/le_http_service_temp"
if [[ "\${prevent_modify_firewall}" != 'true' ]]; then
  if [[ "\$(curl -s http://localhost:11081/api/system | jq '.features.hasGateway')" == 'true' ]]; then
    if [[ "\$(curl -s http://localhost:8081/v2/api/site/default/settings/mgmt | jq '."direct_connect_supported"')" == 'true' ]]; then
      if iptables -A UBIOS_WAN_LOCAL_USER -p tcp --dport 80 -j RETURN -m comment --comment "Added by EUS"; then
        echo -e " Port 80 is now allowed via iptables" &>> "${eus_dir}/logs/http_service.log"
        touch "${eus_dir}/iptables_allow_80" &> /dev/null
      fi
    fi
  fi 
fi
while read -r service; do
  echo " '\${service}' is running on port 80." &>> "${eus_dir}/logs/http_service.log"
  if systemctl stop "\${service}" 2> /dev/null; then 
    echo " Successfully stopped '\${service}'." &>> "${eus_dir}/logs/http_service.log"
    echo "systemctl:\${service}" &>> "${eus_dir}/le_stopped_http_service"
  else
    echo " Failed to stop '\${service}'." &>> "${eus_dir}/logs/http_service.log"
    if dpkg -l | awk '{print \$2}' | grep -iq "^docker.io\\|^docker-ce"; then
      docker_http=\$(docker ps --filter publish=80 --quiet)
      if [[ -n "\${docker_http}" ]]; then
        if docker stop "\${docker_http}" &> /dev/null; then
          echo " Successfully stopped docker container '\${docker_http}'." &>> "${eus_dir}/logs/http_service.log"
          echo "docker:\${docker_http}" &>> "${eus_dir}/le_stopped_http_service"
        else
          echo " Failed to stop docker container '\${docker_http}'." &>> "${eus_dir}/logs/http_service.log"
        fi
      fi
    fi
    if command -v snap &> /dev/null; then
      pid_http_service=\$(netstat -tulpn | grep ":80 " | awk '{print \$7}' | sed 's/\/.*//g')
        if [[ -n "\${pid_http_service}" ]]; then
        pid_http_service_2=\$(ls -l "/proc/\${pid_http_service}/exe" | grep -io "snap.*/" | cut -d'/' -f1-2)
        if echo \${pid_http_service_2} | grep -iq 'snap'; then
          snap_detail=\$(echo \${pid_http_service_2} | cut -d'/' -f2)
          if snap stop \${snap_detail}; then
            echo " Successfully stopped snap '\${snap_detail}'." &>> "${eus_dir}/logs/http_service.log"
            echo "snap\${snap_detail}" &>> "${eus_dir}/le_stopped_http_service"
          else
            echo " Failed to stop snap '\${snap_detail}'." &>> "${eus_dir}/logs/http_service.log"
          fi
        fi
      fi
    fi
  fi
done < "${eus_dir}/le_http_service"
if dpkg -l | grep -iq "\\bUAS\\b\\|UniFi Application Server"; then
  echo " 'uas' is running on port 80." &>> "${eus_dir}/logs/http_service.log"
  if systemctl stop uas; then echo " Successfully stopped 'uas'." &>> "${eus_dir}/logs/http_service.log"; else echo " Failed to stop 'uas'." &>> "${eus_dir}/logs/http_service.log"; fi
  echo "systemctl:uas" &>> "${eus_dir}/le_stopped_http_service"
fi
if dpkg -l | grep -iq unifi-core; then
  echo " 'unifi-core' is running." &>> "${eus_dir}/logs/http_service.log"
  if systemctl stop unifi-core; then echo " Successfully stopped 'unifi-core'." &>> "${eus_dir}/logs/http_service.log"; else echo " Failed to stop 'unifi-core'." &>> "${eus_dir}/logs/http_service.log"; fi
  echo "systemctl:unifi-core" &>> "${eus_dir}/le_stopped_http_service"
fi
rm --force "${eus_dir}/le_http_service" 2> /dev/null
if dpkg -l ufw 2> /dev/null | grep -q "^ii\\|^hi"; then
  if ufw status verbose | awk '/^Status:/{print \$2}' | grep -xq "active"; then
    if ! ufw status verbose | grep "^80\\b\\|^80/tcp\\b" | grep -iq "ALLOW IN"; then
      ufw allow 80 &> /dev/null && echo -e " Port 80 is now set to 'ALLOW IN'." &>> "${eus_dir}/logs/http_service.log"
      touch "${eus_dir}/ufw_add_http"
    fi
  fi
fi
EOF
  chmod +x "/etc/letsencrypt/renewal-hooks/pre/EUS_${server_fqdn}.sh"
}

le_post_hook() {
  if ! [[ -d /etc/letsencrypt/renewal-hooks/post/ ]]; then
    mkdir -p /etc/letsencrypt/renewal-hooks/post/
  fi
  # shellcheck disable=SC1117
  tee "/etc/letsencrypt/renewal-hooks/post/EUS_${server_fqdn}.sh" &>/dev/null <<EOF
#!/bin/bash
old_certificates="${old_certificates}"
skip_network_application="${script_option_skip_network_application}"
if [[ -f "${eus_dir}/le_stopped_http_service" && -s "${eus_dir}/le_stopped_http_service" ]]; then
  mv "${eus_dir}/le_stopped_http_service" "${eus_dir}/le_stopped_http_service_temp"
  awk '!a[\$0]++' "${eus_dir}/le_stopped_http_service_temp" >> "${eus_dir}/le_stopped_http_service" && rm --force "${eus_dir}/le_stopped_http_service_temp"
  while read -r line; do
    command=\$(echo "\${line}" | cut -d':' -f1)
    id=\$(echo "\${line}" | cut -d':' -f2)
    if "\${command}" start "\${id}" 2> /dev/null; then
      echo " Successfully started \${command} '\${id}'." &>> "${eus_dir}/logs/http_service.log"
      systemctl_status=\$(\${command} status "\${id}" | grep -i 'Active:' | awk '{print \$2}')
      if [[ "\${systemctl_status}" == 'inactive' ]]; then
        echo " '\${id}' is still inactive, attempting to stop/start again." &>> "${eus_dir}/logs/http_service.log"
        if ! "\${command}" stop "\${id}" 2> /dev/null; then
          echo " Failed to stop \${command} '\${id}' (second attempt)." &>> "${eus_dir}/logs/http_service.log"
        fi
        sleep 3
        if "\${command}" start "\${id}" 2> /dev/null; then
          echo " Successfully started \${command} '\${id}' (second attempt)." &>> "${eus_dir}/logs/http_service.log"
        else
          echo " Failed to start \${command} '\${id}' (second attempt)." &>> "${eus_dir}/logs/http_service.log"
        fi
      fi
    else
      echo " Failed to start \${command} '\${id}'." &>> "${eus_dir}/logs/http_service.log"
    fi
  done < "${eus_dir}/le_stopped_http_service"
  rm --force "${eus_dir}/le_stopped_http_service" 2> /dev/null
fi
if [[ -f "${eus_dir}/iptables_allow_80" ]]; then
  if iptables -D UBIOS_WAN_LOCAL_USER -p tcp --dport 80 -j RETURN -m comment --comment "Added by EUS"; then
    echo -e " Port 80 is now closed via iptables" &>> "${eus_dir}/logs/http_service.log"
    rm --force "${eus_dir}/iptables_allow_80" 2> /dev/null
  fi
fi
if [[ -f "${eus_dir}/ufw_add_http" ]]; then
  ufw delete allow 80 &> /dev/null
  rm --force "${eus_dir}/ufw_add_http" 2> /dev/null
fi
# shellcheck disable=SC2034
server_fqdn="${server_fqdn}"
if ls "${eus_dir}/logs/lets_encrypt_[0-9]*.log" &>/dev/null && [[ -d "/etc/letsencrypt/live/${server_fqdn}" ]]; then
  # shellcheck disable=SC2012,SC2010
  last_le_log=\$(ls "${eus_dir}/logs/lets_encrypt_[0-9]*.log" | tail -n1)
  le_var_log=\$(grep -i "/etc/letsencrypt/live/${server_fqdn}" "\${last_le_log}" | awk '{print \$1}' | head -n1 | sed 's/\/etc\/letsencrypt\/live\///g' | grep -io "${server_fqdn}.*" | cut -d'/' -f1 | sed "s/${server_fqdn}//g")
  # shellcheck disable=SC2012,SC2010
  le_var_dir=\$(ls -lc /etc/letsencrypt/live/ | grep -io "${server_fqdn}.*" | tail -n1 | sed "s/${server_fqdn}//g")
  if [[ "\${le_var_log}" != "\${le_var_dir}" ]]; then
    le_var="\${le_var_dir}"
  else
    le_var="\${le_var_log}"
  fi
else
  # shellcheck disable=SC2012,SC2010
  if [[ -d /etc/letsencrypt/live/ ]]; then le_var=\$(ls -lc /etc/letsencrypt/live/ | grep -io "${server_fqdn}.*" | tail -n1 | sed "s/${server_fqdn}//g"); fi
fi
if ! [[ -f "${eus_dir}/checksum/fullchain.sha256sum" && -s "${eus_dir}/checksum/fullchain.sha256sum" && -f "${eus_dir}/checksum/fullchain.md5sum" && -s "${eus_dir}/checksum/fullchain.md5sum" ]]; then
  touch "${eus_dir}/temp_file"
  sha256sum "${eus_dir}/temp_file" 2> /dev/null | awk '{print \$1}' &> "${eus_dir}/checksum/fullchain.sha256sum"
  md5sum "${eus_dir}/temp_file" 2> /dev/null | awk '{print \$1}' &> "${eus_dir}/checksum/fullchain.md5sum"
  rm --force "${eus_dir}/temp_file"
fi
if [[ -f "/etc/letsencrypt/live/${server_fqdn}\${le_var}/privkey.pem" && -f "/etc/letsencrypt/live/${server_fqdn}\${le_var}/fullchain.pem" ]]; then
  current_sha256sum=\$(sha256sum "/etc/letsencrypt/live/${server_fqdn}\${le_var}/fullchain.pem" | awk '{print \$1}')
  current_md5sum=\$(md5sum "/etc/letsencrypt/live/${server_fqdn}\${le_var}/fullchain.pem" 2> /dev/null | awk '{print \$1}')
  if [[ "\${current_sha256sum}" != "\$(cat "${eus_dir}/checksum/fullchain.sha256sum")" && "\${current_md5sum}" != "\$(cat "${eus_dir}/checksum/fullchain.md5sum")" ]]; then
    echo -e "\\n------- \$(date +%F-%R) -------\\n" &>> "${eus_dir}/logs/lets_encrypt_import.log"
    sha256sum "/etc/letsencrypt/live/${server_fqdn}\${le_var}/fullchain.pem" 2> /dev/null | awk '{print \$1}' &> "${eus_dir}/checksum/fullchain.sha256sum" && echo "Successfully updated sha256sum" &>> "${eus_dir}/logs/lets_encrypt_import.log"
    md5sum "/etc/letsencrypt/live/${server_fqdn}\${le_var}/fullchain.pem" 2> /dev/null | awk '{print \$1}' &> "${eus_dir}/checksum/fullchain.md5sum" && echo "Successfully updated md5sum" &>> "${eus_dir}/logs/lets_encrypt_import.log"
    if dpkg -l unifi-core 2> /dev/null | awk '{print \$1}' | grep -iq "^ii\\|^hi"; then
      if grep -sq unifi-native /mnt/.rofs/var/lib/dpkg/status; then unifi_native_system="true"; fi
      if grep -ioq "udm" /usr/lib/version; then udm_device=true; fi
      unifi_core_version="\$(dpkg-query --showformat='\${Version}' --show unifi-core)"
      if [[ -f /usr/lib/version ]]; then unifi_core_device_version=\$(grep -ioE "v[0-9]{1,9}.[0-9]{1,9}.[0-9]{1,9}" /usr/lib/version | sed 's/v//g'); fi
      if [[ "$(echo "\${unifi_core_device_version}" | cut -d'.' -f1)" == "1" ]]; then debbox="false"; else debbox="true"; fi
      if dpkg -l uid-agent 2> /dev/null | grep -iq "^ii\\|^hi"; then uid_agent=\$(curl -s http://localhost:11081/api/controllers | jq '.[] | select(.name == "uid-agent").isConfigured'); fi
      # shellcheck disable=SC2012
      if [[ ! -d /data/eus_certificates/ ]]; then mkdir -p /data/eus_certificates/; fi
      if [[ -f "/etc/letsencrypt/live/${server_fqdn}\${le_var}/fullchain.pem" ]]; then
        cp "/etc/letsencrypt/live/${server_fqdn}\${le_var}/fullchain.pem" /data/eus_certificates/unifi-os.crt
      fi
      if [[ -f "/etc/letsencrypt/live/${server_fqdn}\${le_var}/privkey.pem" ]]; then
        cp "/etc/letsencrypt/live/${server_fqdn}\${le_var}/privkey.pem" /data/eus_certificates/unifi-os.key
      fi
      if [[ "$(echo "\${unifi_core_version}" | cut -d'.' -f1)" == '3' && "$(echo "\${unifi_core_version}" | cut -d'.' -f2)" == '2' && "$(echo "\${unifi_core_version}" | cut -d'.' -f3)" -lt '155' ]]; then unifi_core_certificate_copy="true"; fi
      if [[ "\${unifi_core_certificate_copy}" == 'true' ]]; then
        cp /data/eus_certificates/unifi-os.key /data/unifi-core/config/unifi-core.key
        cp /data/eus_certificates/unifi-os.crt /data/unifi-core/config/unifi-core.crt
      else
        if [[ ! -f "${unifi_core_config_path}" ]]; then
          tee "${unifi_core_config_path}" &>/dev/null << SSL
# File created by EUS ( Easy UniFi Scripts ).
ssl:
  crt: '/data/eus_certificates/unifi-os.crt'
  key: '/data/eus_certificates/unifi-os.key'
SSL
        else
          if ! [[ -d "${eus_dir}/unifi-os/config_backups" ]]; then mkdir -p "${eus_dir}/unifi-os/config_backups"; fi
          cp "${unifi_core_config_path}" "${eus_dir}/unifi-os/config_backups/config.yaml_\$(date +%Y%m%d_%H%M)"
          if ! grep -iq "ssl:" "${unifi_core_config_path}"; then
            tee -a "${unifi_core_config_path}" &>/dev/null << SSL
# File created by EUS ( Easy UniFi Scripts ).
ssl:
  crt: '/data/eus_certificates/unifi-os.crt'
  key: '/data/eus_certificates/unifi-os.key'
SSL
          else
            unifi_os_crt_file=\$(grep -i "crt:" "${unifi_core_config_path}" | awk '{print\$2}' | sed "s/'//g")
            unifi_os_key_file=\$(grep -i "key:" "${unifi_core_config_path}" | awk '{print\$2}' | sed "s/'//g")
            sed -i "s#\${unifi_os_crt_file}#/data/eus_certificates/unifi-os.crt#g" "${unifi_core_config_path}"
            sed -i "s#\${unifi_os_key_file}#/data/eus_certificates/unifi-os.key#g" "${unifi_core_config_path}"
          fi
        fi
      fi
      systemctl restart unifi-core
      time_date=\$(date +%Y%m%d_%H%M)
      if [[ "\${udm_device}" == 'true' && "\${uid_agent}" != 'true' ]]; then
        if [[ "\${debbox}" == 'true' ]]; then
          # shellcheck disable=SC2010
          if [[ -d "/data/udapi-config/raddb/certs/" ]]; then
            if ls -la /data/udapi-config/raddb/certs/ | grep -iq "server.pem\\|server-key.pem" && [[ -f "${eus_dir}/radius/true" ]]; then radius_certs_available=true; fi
          fi
        else
          if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -ql root 127.0.0.1 "ls -la /mnt/data/udapi-config/raddb/certs/" | grep -iq "server.pem\\|server-key.pem" && [[ -f "${eus_dir}/radius/true" ]]; then radius_certs_available=true; fi
        fi
        if [[ "\${radius_certs_available}" == 'true' ]]; then
          if ! [[ -d "/data/eus_certificates/raddb" ]]; then mkdir -p /data/eus_certificates/raddb &> /dev/null; fi
          if [[ "\${debbox}" == 'true' ]]; then
            cp "/data/udapi-config/raddb/certs/server.pem" "/data/eus_certificates/raddb/original_server_\${time_date}.pem" &>> "${eus_dir}/logs/radius.log"
            cp "/data/udapi-config/raddb/certs/server-key.pem" "/data/eus_certificates/raddb/original_server-key_\${time_date}.pem" &>> "${eus_dir}/logs/radius.log"
          else
            ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -ql root 127.0.0.1 "cp /mnt/data/udapi-config/raddb/certs/server.pem /data/eus_certificates/raddb/original_server_\${time_date}.pem" &>> "${eus_dir}/logs/radius.log"
            ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -ql root 127.0.0.1 "cp /mnt/data/udapi-config/raddb/certs/server-key.pem /data/eus_certificates/raddb/original_server-key_\${time_date}.pem" &>> "${eus_dir}/logs/radius.log"
          fi
          if [[ -f "/data/eus_certificates/unifi-os.crt" ]]; then
            raddb_cert_file="/data/eus_certificates/unifi-os.crt"
          else
            cp "/etc/letsencrypt/live/${server_fqdn}\${le_var}/privkey.pem" /data/eus_certificates/raddb-server.pem
            raddb_cert_file="/data/eus_certificates/raddb-server.pem"
          fi
          if [[ "\${debbox}" == 'true' ]]; then
            cp "\${raddb_cert_file}" "/data/udapi-config/raddb/certs/server.pem" &>> "${eus_dir}/logs/radius.log"
          else
            ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -ql root 127.0.0.1 "cp \${raddb_cert_file} /mnt/data/udapi-config/raddb/certs/server.pem" &>> "${eus_dir}/logs/radius.log"
          fi
          if [[ -f "/data/eus_certificates/unifi-os.key" ]]; then
            raddb_key_file="/data/eus_certificates/unifi-os.key"
          else
            cp "/etc/letsencrypt/live/${server_fqdn}\${le_var}/privkey.pem" /data/eus_certificates/raddb-server-key.pem
            raddb_key_file="/data/eus_certificates/raddb-server-key.pem"
          fi
          if [[ "\${debbox}" == 'true' ]]; then
            cp "\${raddb_key_file}" "/data/udapi-config/raddb/certs/server-key.pem" &>> "${eus_dir}/logs/radius.log"
            systemctl restart udapi-server &>> "${eus_dir}/logs/radius.log"
          else
            ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -ql root 127.0.0.1 "cp \${raddb_key_file} /mnt/data/udapi-config/raddb/certs/server-key.pem" &>> "${eus_dir}/logs/radius.log"
            ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -ql root 127.0.0.1 "/etc/init.d/S45ubios-udapi-server restart" &>> "${eus_dir}/logs/radius.log"
          fi
        fi
      fi
    fi
    if dpkg -l unifi 2> /dev/null | awk '{print \$1}' | grep -iq "^ii\\|^hi" && [[ "\${skip_network_application}" != 'true' ]]; then
      if [[ "\${unifi_native_system}" == 'true' ]]; then
        openjdk_native_installed_package="\$(apt-cache search "jre-headless" | grep -Eio "openjdk-[0-9]{1,2}-jre-headless" | sort -V | tail -n1)"
        openjdk_native_installed="true"
        DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "${openjdk_native_installed_package}" 2>&1 | tee -a "${eus_dir}/logs/apt.log"
      fi
      # shellcheck disable=SC2012
      if [[ "\${old_certificates}" == 'last_three' ]]; then ls -t "${eus_dir}/network/keystore_backups/keystore_*" 2> /dev/null | awk 'NR>3' | xargs rm -f 2> /dev/null; fi
      mkdir -p "${eus_dir}/network/keystore_backups" && cp /usr/lib/unifi/data/keystore "${eus_dir}/network/keystore_backups/keystore_\$(date +%Y%m%d_%H%M)"
      # shellcheck disable=SC2129,SC2086
      openssl pkcs12 -export -inkey "/etc/letsencrypt/live/${server_fqdn}\${le_var}/privkey.pem" -in "/etc/letsencrypt/live/${server_fqdn}\${le_var}/fullchain.pem" -out "/etc/letsencrypt/live/${server_fqdn}\${le_var}/fullchain.p12" -name unifi -password pass:aircontrolenterprise ${openssl_legacy_flag} &>> "${eus_dir}/logs/lets_encrypt_import.log"
      keytool -delete -alias unifi -keystore /usr/lib/unifi/data/keystore -deststorepass aircontrolenterprise &>> "${eus_dir}/logs/lets_encrypt_import.log"
      keytool -importkeystore -deststorepass aircontrolenterprise -destkeypass aircontrolenterprise -destkeystore /usr/lib/unifi/data/keystore -srckeystore "/etc/letsencrypt/live/${server_fqdn}\${le_var}/fullchain.p12" -srcstoretype PKCS12 -srcstorepass aircontrolenterprise -alias unifi -noprompt &>> "${eus_dir}/logs/lets_encrypt_import.log"
      chown -R unifi:unifi /usr/lib/unifi/data/keystore &> /dev/null
      # shellcheck disable=SC2086
      if openssl pkcs12 -in "/etc/letsencrypt/live/${server_fqdn}\${le_var}/fullchain.p12" -password pass:aircontrolenterprise -nokeys ${openssl_legacy_flag} | openssl x509 -text -noout | grep -i signature | grep -iq ecdsa &> /dev/null; then
        echo "unifi.https.ciphers=ECDHE-ECDSA-AES256-GCM-SHA384,ECDHE-RSA-AES128-GCM-SHA256" &>> /usr/lib/unifi/data/system.properties
        echo "unifi.https.sslEnabledProtocols=TLSv1.3,TLSv1.2" &>> /usr/lib/unifi/data/system.properties
      fi
      systemctl restart unifi
      if [[ "\${openjdk_native_installed}" == 'true' ]]; then
        DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' purge "${openjdk_native_installed_package}" &>> "${eus_dir}/logs/uninstall-${openjdk_native_installed_package}.log"
      fi
    fi
    if [[ -f "${eus_dir}/cloudkey/cloudkey_management_ui" ]]; then
      mkdir -p "${eus_dir}/cloudkey/certs_backups"
      # shellcheck disable=SC2012
      if [[ \${old_certificates} == 'last_three' ]]; then ls -t "${eus_dir}/cloudkey/certs_backups/cloudkey.key_*" 2> /dev/null | awk 'NR>3' | xargs rm -f 2> /dev/null; fi
      # shellcheck disable=SC2012
      if [[ \${old_certificates} == 'last_three' ]]; then ls -t "${eus_dir}/cloudkey/certs_backups/cloudkey.crt_*" 2> /dev/null | awk 'NR>3' | xargs rm -f 2> /dev/null; fi
      cp /etc/ssl/private/cloudkey.crt "${eus_dir}/cloudkey/certs_backups/cloudkey.crt_\$(date +%Y%m%d_%H%M)"
      cp /etc/ssl/private/cloudkey.key "${eus_dir}/cloudkey/certs_backups/cloudkey.key_\$(date +%Y%m%d_%H%M)"
      if [[ -f "/etc/letsencrypt/live/${server_fqdn}\${le_var}/fullchain.pem" ]]; then
        cp "/etc/letsencrypt/live/${server_fqdn}\${le_var}/fullchain.pem" /etc/ssl/private/cloudkey.crt
      fi
      if [[ -f "/etc/letsencrypt/live/${server_fqdn}\${le_var}/privkey.pem" ]]; then
        cp "/etc/letsencrypt/live/${server_fqdn}\${le_var}/privkey.pem" /etc/ssl/private/cloudkey.key
      fi
      systemctl restart nginx
      if dpkg -l unifi-protect 2> /dev/null | awk '{print \$1}' | grep -iq "^ii\\|^hi"; then
        unifi_protect_status=\$(systemctl status unifi-protect | grep -i 'Active:' | awk '{print \$2}')
        if [[ \${unifi_protect_status} == 'active' ]]; then
          systemctl restart unifi-protect
        fi
      fi
    fi
    if [[ -f "${eus_dir}/cloudkey/cloudkey_unifi_led" ]]; then
      systemctl restart unifi-led
    fi
    if [[ -f "${eus_dir}/cloudkey/cloudkey_unifi_talk" ]]; then
      # shellcheck disable=SC2012
      if [[ \${old_certificates} == 'last_three' ]]; then ls -t "${eus_dir}/talk/certs_backups/server.pem_*" 2> /dev/null | awk 'NR>3' | xargs rm -f 2> /dev/null; fi
      mkdir -p "${eus_dir}/talk/certs_backups" && cp /usr/share/unifi-talk/app/certs/server.pem "${eus_dir}/talk/certs_backups/server.pem_\$(date +%Y%m%d_%H%M)"
      cat "/etc/letsencrypt/live/${server_fqdn}\${le_var}/privkey.pem" "/etc/letsencrypt/live/${server_fqdn}\${le_var}/fullchain.pem" > /usr/share/unifi-talk/app/certs/server.pem
      systemctl restart unifi-talk
    fi
    if [[ -f "${eus_dir}/cloudkey/uas_management_ui" ]]; then
      mkdir -p "${eus_dir}/uas/certs_backups/"
      # shellcheck disable=SC2012
      if [[ \${old_certificates} == 'last_three' ]]; then ls -t "${eus_dir}/uas/certs_backups/uas.crt_*" 2> /dev/null | awk 'NR>3' | xargs rm -f 2> /dev/null; fi
      # shellcheck disable=SC2012
      if [[ \${old_certificates} == 'last_three' ]]; then ls -t "${eus_dir}/uas/certs_backups/uas.key_*" 2> /dev/null | awk 'NR>3' | xargs rm -f 2> /dev/null; fi
      cp /etc/uas/uas.crt "${eus_dir}/uas/certs_backups/uas.crt_\$(date +%Y%m%d_%H%M)"
      cp /etc/uas/uas.key "${eus_dir}/uas/certs_backups/uas.key_\$(date +%Y%m%d_%H%M)"
      systemctl stop uas
      if [[ -f "/etc/letsencrypt/live/${server_fqdn}\${le_var}/fullchain.pem" ]]; then
        cp "/etc/letsencrypt/live/${server_fqdn}\${le_var}/fullchain.pem" /etc/uas/uas.crt
      fi
      if [[ -f "/etc/letsencrypt/live/${server_fqdn}\${le_var}/privkey.pem" ]]; then
        cp "/etc/letsencrypt/live/${server_fqdn}\${le_var}/privkey.pem" /etc/uas/uas.key
      fi
      systemctl start uas
    fi
    if [[ -f "${eus_dir}/eot/uas_unifi_led" ]]; then
      mkdir -p "${eus_dir}/eot/certs_backups"
      # shellcheck disable=SC2012
      if [[ \${old_certificates} == 'last_three' ]]; then ls -t "${eus_dir}/eot/certs_backups/server.pem_*" 2> /dev/null | awk 'NR>3' | xargs rm -f 2> /dev/null; fi
      cat "/etc/letsencrypt/live/${server_fqdn}\${le_var}/privkey.pem" "/etc/letsencrypt/live/${server_fqdn}\${le_var}/fullchain.pem" > "${eus_dir}/eot/eot_docker_container.pem"
      eot_container=\$(docker ps -a | grep -i 'ubnt/eot' | awk '{print \$1}')
      eot_container_name="ueot"
      if [[ -n "\${eot_container}" ]]; then
        docker cp "\${eot_container}:/app/certs/server.pem" "${eus_dir}/eot/certs_backups/server.pem_\$(date +%Y%m%d_%H%M)"
        docker cp "${eus_dir}/eot/eot_docker_container.pem" "\${eot_container}:/app/certs/server.pem"
        docker restart \${eot_container_name}
      fi
    fi
    if [[ -f "${eus_dir}/video/unifi_video" ]]; then
      mkdir -p /usr/lib/unifi-video/data/certificates
      # shellcheck disable=SC2012
      if [[ \${old_certificates} == 'last_three' ]]; then ls -t "${eus_dir}/video/keystore_backups/keystore_*" 2> /dev/null | awk 'NR>3' | xargs rm -f 2> /dev/null; fi
      # shellcheck disable=SC2012
      if [[ \${old_certificates} == 'last_three' ]]; then ls -t "${eus_dir}/video/keystore_backups/ufv-truststore_*" 2> /dev/null | awk 'NR>3' | xargs rm -f 2> /dev/null; fi
      openssl pkcs8 -topk8 -nocrypt -in "/etc/letsencrypt/live/${server_fqdn}\${le_var}/privkey.pem" -outform DER -out /usr/lib/unifi-video/data/certificates/ufv-server.key.der
      openssl x509 -outform der -in "/etc/letsencrypt/live/${server_fqdn}\${le_var}/fullchain.pem" -out /usr/lib/unifi-video/data/certificates/ufv-server.cert.der
      chown -R unifi-video:unifi-video /usr/lib/unifi-video/data/certificates
      systemctl stop unifi-video
      mkdir -p "${eus_dir}/video/keystore_backups"
      mv /usr/lib/unifi-video/data/keystore "${eus_dir}/video/keystore_backups/keystore_\$(date +%Y%m%d_%H%M)"
      mv /usr/lib/unifi-video/data/ufv-truststore "${eus_dir}/video/keystore_backups/ufv-truststore_\$(date +%Y%m%d_%H%M)"
      if ! grep -iq "^ufv.custom.certs.enable=true" /usr/lib/unifi-video/data/system.properties; then
        echo "ufv.custom.certs.enable=true" &>> /usr/lib/unifi-video/data/system.properties
      fi
      systemctl start unifi-video
    fi
  else
    echo -e "\\n------- \$(date +%F-%R) -------\\n" &>> "${eus_dir}/logs/lets_encrypt_import.log"
    echo -e "Checksums are the same.. certificate didn't renew." &>> "${eus_dir}/logs/lets_encrypt_import.log"
    if grep -A40 -i "\$(date '+%d %b %Y %H')" /var/log/letsencrypt/letsencrypt.log | grep -A6 '"error":' | grep -io "detail.*" | grep -iq "firewall"; then
      echo -e "Certificates didn't renew due to a firewall issue ( likely )..." &>> "${eus_dir}/logs/lets_encrypt_import.log"
    fi
  fi
fi
if ! [[ -d "/tmp/EUS" ]]; then mkdir -p /tmp/EUS; fi
ls -t "${eus_dir}/logs/" | grep -i "lets_encrypt_[0-9].*.log" | tail -n+6 &>> /tmp/EUS/challenge_log_cleanup
while read -r log_file; do
  if [[ -f "${eus_dir}/logs/\${log_file}" ]]; then
    rm --force "${eus_dir}/logs/\${log_file}" &> /dev/null
  fi
done < /tmp/EUS/challenge_log_cleanup
rm --force /tmp/EUS/challenge_log_cleanup &> /dev/null
EOF
  chmod +x "/etc/letsencrypt/renewal-hooks/post/EUS_${server_fqdn}.sh"
}

le_import_failed() {
  if [[ "${prefer_dns_challenge}" == 'true' ]]; then header_red; fi
  echo -e "${RED}#${RESET} Failed to imported SSL certificate for '${server_fqdn}'"
  echo -e "${RED}#${RESET} Cleaning up files and restarting the application service(s)...\\n"
  echo -e "${RED}#${RESET} Feel free to reach out to GlennR ( AmazedMender16 ) on the Ubiquiti Community Forums"
  echo -e "${RED}#${RESET} Log file is saved here: ${eus_dir}/logs/lets_encrypt_${time_date}.log"
  if [[ "${unifi_core_system}" == 'true' ]]; then
    if [[ "$(curl -s "http://localhost:8081/v2/api/site/default/settings/mgmt" | jq '."direct_connect_supported"')" == 'true' ]]; then
      if iptables -t nat -nvL UBIOS_PREROUTING_USER_HOOK | grep -ioE "dpt:[0-9]{0,5}" | cut -d':' -f2 | awk '!a[$0]++' | grep "^80$"; then
        echo -e "${RED}#${RESET} Port Forward found from port \"80\" to \"$(iptables -t nat -nvL UBIOS_PREROUTING_USER_HOOK | grep -iE "dpt:80" | grep -io "to:.*" | cut -d':' -f2 | tail -n1)\" port \"$(iptables -t nat -nvL UBIOS_PREROUTING_USER_HOOK | grep -iE "dpt:80" | grep -io "to:.*" | cut -d':' -f3 | tail -n1)\"... Please remove it before re-running the script."
      fi
    fi
  fi
  if [[ -f "${eus_dir}/logs/lets_encrypt_${time_date}.log" ]]; then
    if grep -iq 'timeout during connect' "${eus_dir}/logs/lets_encrypt_${time_date}.log"; then
      script_timeout_http=true
      echo -e "\\n${RED}---${RESET}\\n\\n${RED}#${RESET} Timed out..."
      echo -e "${RED}#${RESET} Your Firewall or ISP does not allow port 80, please verify that your Firewall/Port Fordwarding settings are correct.\\n\\n${RED}---${RESET}"
    fi
    if grep -iq 'timeout after connect' "${eus_dir}/logs/lets_encrypt_${time_date}.log"; then
      script_timeout_http=true
      echo -e "\\n${RED}---${RESET}\\n\\n${RED}#${RESET} Timed out... Your server may be slow or overloaded"
      echo -e "${RED}#${RESET} Please try to run the script again and make sure there is no firewall blocking port 80.\\n\\n${RED}---${RESET}"
    fi
    if grep -iq 'No TXT record found' "${eus_dir}/logs/lets_encrypt_${time_date}.log"; then
      echo -e "\\n${RED}---${RESET}\\n\\n${RED}#${RESET} No TXT records found for \"_acme-challenge.${server_fqdn}\"\\n\\n${RED}---${RESET}"
    fi
    if grep -iq 'too many certificates already issued for exact set of domains' "${eus_dir}/logs/lets_encrypt_${time_date}.log"; then
      echo -e "\\n${RED}---${RESET}\\n\\n${RED}#${RESET} There were too many certificates issued for ${server_fqdn}\\n\\n${RED}---${RESET}"
    fi
    if [[ -f "/var/log/letsencrypt/letsencrypt.log" && "${prefer_dns_challenge}" == 'true' ]] && tail -n80 "/var/log/letsencrypt/letsencrypt.log" | grep -iq 'too many requests'; then
      echo -e "\\n${RED}---${RESET}\\n\\n${RED}#${RESET} There were too many certificates issued for ${server_fqdn}\\n\\n${RED}---${RESET}"
    fi
    if grep -iq 'live directory exists' "${eus_dir}/logs/lets_encrypt_${time_date}.log"; then
      echo -e "\\n${RED}---${RESET}\\n\\n${RED}#${RESET} A live directory exists for ${server_fqdn}\\n\\n${RED}---${RESET}"
    fi
    if grep -iq 'Missing properties in credentials configuration file' "${eus_dir}/logs/lets_encrypt_${time_date}.log"; then
      echo -e "\\n${RED}---${RESET}\\n\\n${RED}#${RESET} Please ensure your ${auto_dns_challenge_credentials_file} contains the right (API) tokens/details...\\n\\n${RED}---${RESET}"
    fi
    if grep -iq 'Problem binding to port 80' "${eus_dir}/logs/lets_encrypt_${time_date}.log"; then
      echo -e "\\n${RED}---${RESET}\\n\\n${RED}#${RESET} Script failed to stop the service running on port 80, please manually stop it and run the script again!\\n\\n${RED}---${RESET}"
    fi
    if grep -iq 'Incorrect TXT record' "${eus_dir}/logs/lets_encrypt_${time_date}.log"; then
      echo ""
      echo -e "${RED}---${RESET}\\n\\n${RED}#${RESET} The TXT record you created was incorrect..\\n\\n${RED}---${RESET}"
    fi
    if grep -iq 'Account creation on ACMEv1 is disabled' "${eus_dir}/logs/lets_encrypt_${time_date}.log"; then
      echo ""
      echo -e "${RED}---${RESET}\\n\\n${RED}#${RESET} Account creation on ACMEv1 is disabled..\\n\\n${RED}---${RESET}"
    fi
    if grep -iq 'Invalid response from' "${eus_dir}/logs/lets_encrypt_${time_date}.log"; then
      header_red
      echo -e "${RED}#${RESET} Invalid response from \"http://${server_fqdn}/.well-known/acme-challenge/xxxxxxxxxxxxxxxxxxx\"..."
      echo -e "${RED}#${RESET} Please make sure that your domain name was entered correctrly and that the DNS A/AAAA record(s) for that domain contain(s) the right IP address..."
      abort_skip_support_file_upload="true"
      abort
    fi
    if [[ -f "${eus_dir}/logs/lets_encrypt_import.log" ]] && grep -iq 'Keystore was tampered with, or password was incorrect' "${eus_dir}/logs/lets_encrypt_import.log"; then
      echo ""
      echo -e "${RED}#${RESET} Please clear your browser cache if you're seeing connection errors.\\n\\n${RED}---${RESET}\\n\\n${RED}#${RESET} Keystore was tampered with, or password was incorrect\\n\\n${RED}---${RESET}"
      if dpkg -l unifi 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
        rm --force /usr/lib/unifi/data/keystore 2> /dev/null && systemctl restart unifi
      fi
    fi
  fi
  rm --force "/etc/letsencrypt/renewal-hooks/pre/EUS_${server_fqdn}.sh" &> /dev/null
  rm --force "/etc/letsencrypt/renewal-hooks/post/EUS_${server_fqdn}.sh" &> /dev/null
  run_uck_scripts=no
  exit 1
}

cloudkey_management_ui() {
  # shellcheck disable=SC2012
  mkdir -p "${eus_dir}/cloudkey/certs_backups" && touch "${eus_dir}/cloudkey/cloudkey_management_ui"
  echo -e "\\n${WHITE_R}#${RESET} Importing the SSL certificates into the Cloudkey User Interface..."
  # shellcheck disable=SC2012
  if [[ "${old_certificates}" == 'last_three' ]]; then ls -t "${eus_dir}/cloudkey/certs_backups/cloudkey.crt_*" 2> /dev/null | awk 'NR>3' | xargs rm -f 2> /dev/null; fi
  # shellcheck disable=SC2012
  if [[ "${old_certificates}" == 'last_three' ]]; then ls -t "${eus_dir}/cloudkey/certs_backups/cloudkey.key_*" 2> /dev/null | awk 'NR>3' | xargs rm -f 2> /dev/null; fi
  cp /etc/ssl/private/cloudkey.crt "${eus_dir}/cloudkey/certs_backups/cloudkey.crt_$(date +%Y%m%d_%H%M)"
  cp /etc/ssl/private/cloudkey.key "${eus_dir}/cloudkey/certs_backups/cloudkey.key_$(date +%Y%m%d_%H%M)"
  if [[ "${paid_cert}" == "true" ]]; then
    if [[ -f "${eus_dir}/paid-certificates/eus_crt_file.crt" ]]; then
      cp "${eus_dir}/paid-certificates/eus_crt_file.crt" /etc/ssl/private/cloudkey.crt
    fi
    if [[ -f "${eus_dir}/paid-certificates/eus_key_file.key" ]]; then
      cp "${eus_dir}/paid-certificates/eus_key_file.key" /etc/ssl/private/cloudkey.key
    fi
  else
    if [[ -f "${fullchain_pem}.pem" ]]; then
      cp "${fullchain_pem}.pem" /etc/ssl/private/cloudkey.crt
    elif [[ -f "/etc/letsencrypt/live/${server_fqdn}${le_var}/fullchain.pem" ]]; then
      cp "/etc/letsencrypt/live/${server_fqdn}${le_var}/fullchain.pem" /etc/ssl/private/cloudkey.crt
    fi
    if [[ -f "${priv_key_pem}.pem" ]]; then
      cp "${priv_key_pem}.pem" /etc/ssl/private/cloudkey.key
    elif [[ -f "/etc/letsencrypt/live/${server_fqdn}${le_var}/privkey.pem" ]]; then
      cp "/etc/letsencrypt/live/${server_fqdn}${le_var}/privkey.pem" /etc/ssl/private/cloudkey.key
    fi
  fi
  if systemctl restart nginx; then echo -e "${GREEN}#${RESET} Successfully imported the SSL certificates into the Cloudkey User Interface!"; else echo -e "${RED}#${RESET} Failed to import the SSL certificates into the Cloudkey User Interface... \\n"; sleep 2; fi
  if dpkg -l unifi-protect 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
    unifi_protect_status=$(systemctl status unifi-protect | grep -i 'Active:' | awk '{print $2}')
    if [[ "${unifi_protect_status}" == 'active' ]]; then
      echo -e "\\n${WHITE_R}#${RESET} Importing the SSL certificates into UniFi-Protect..."
      if systemctl restart unifi-protect; then echo -e "${GREEN}#${RESET} Successfully imported the SSL certificates into UniFi-Protect!"; else echo -e "${RED}#${RESET} Failed to import the SSL certificates into UniFi-Protect... \\n"; sleep 2; fi
    fi
  fi
}

cloudkey_unifi_led() {
  mkdir -p "${eus_dir}/cloudkey/" && touch "${eus_dir}/cloudkey/cloudkey_unifi_led"
  echo -e "\\n${WHITE_R}#${RESET} Importing the SSL certificates into UniFi-LED..."
  if systemctl restart unifi-led; then echo -e "${GREEN}#${RESET} Successfully imported the SSL certificates into UniFi-LED!"; else echo -e "${RED}#${RESET} Failed to import the SSL certificates into UniFi-LED... \\n"; sleep 2; fi
}

cloudkey_unifi_talk() {
  # shellcheck disable=SC2012
  mkdir -p "${eus_dir}/cloudkey/" && touch "${eus_dir}/cloudkey/cloudkey_unifi_talk"
  echo -e "\\n${WHITE_R}#${RESET} Importing the SSL certificates into UniFi-Talk..."
  # shellcheck disable=SC2012
  if [[ "${old_certificates}" == 'last_three' ]]; then ls -t "${eus_dir}/talk/certs_backups/server.pem_*" 2> /dev/null | awk 'NR>3' | xargs rm -f 2> /dev/null; fi
  mkdir -p "${eus_dir}/talk/certs_backups" && cp /usr/share/unifi-talk/app/certs/server.pem "${eus_dir}/talk/certs_backups/server.pem_$(date +%Y%m%d_%H%M)"
  if [[ "${paid_cert}" == "true" ]]; then
    cp "${eus_dir}/paid-certificates/eus_certificates_file.pem" /usr/share/unifi-talk/app/certs/server.pem
  else
    cat "/etc/letsencrypt/live/${server_fqdn}${le_var}/privkey.pem" "/etc/letsencrypt/live/${server_fqdn}${le_var}/fullchain.pem" > /usr/share/unifi-talk/app/certs/server.pem
  fi
  if systemctl restart unifi-talk; then echo -e "${GREEN}#${RESET} Successfully imported the SSL certificates into UniFi-Talk!"; else echo -e "${RED}#${RESET} Failed to import the SSL certificates into UniFi-Talk... \\n"; sleep 2; fi
}

unifi_core() {
  # shellcheck disable=SC2012
  echo -e "\\n${WHITE_R}#${RESET} Importing the SSL certificates into the ${unifi_core_device} running UniFi OS..."
  if [[ ! -d /data/eus_certificates/ ]]; then mkdir -p /data/eus_certificates/; fi
  if [[ "${paid_cert}" == "true" ]]; then
    if [[ -f "${eus_dir}/paid-certificates/eus_crt_file.crt" ]]; then
      cp "${eus_dir}/paid-certificates/eus_crt_file.crt" /data/eus_certificates/unifi-os.crt
    fi
    if [[ -f "${eus_dir}/paid-certificates/eus_key_file.key" ]]; then
      cp "${eus_dir}/paid-certificates/eus_key_file.key" /data/eus_certificates/unifi-os.key
    fi
  else
    if [[ -f "${fullchain_pem}.pem" ]]; then
      cp "${fullchain_pem}.pem" /data/eus_certificates/unifi-os.crt
    elif [[ -f "/etc/letsencrypt/live/${server_fqdn}${le_var}/fullchain.pem" ]]; then
      cp "/etc/letsencrypt/live/${server_fqdn}${le_var}/fullchain.pem" /data/eus_certificates/unifi-os.crt
    fi
    if [[ -f "${priv_key_pem}.pem" ]]; then
      cp "${priv_key_pem}.pem" /data/eus_certificates/unifi-os.key
    elif [[ -f "/etc/letsencrypt/live/${server_fqdn}${le_var}/privkey.pem" ]]; then
      cp "/etc/letsencrypt/live/${server_fqdn}${le_var}/privkey.pem" /data/eus_certificates/unifi-os.key
    fi
  fi
  if [[ "${unifi_core_certificate_copy}" == 'true' ]]; then
    cp /data/eus_certificates/unifi-os.key /data/unifi-core/config/unifi-core.key
    cp /data/eus_certificates/unifi-os.crt /data/unifi-core/config/unifi-core.crt
  else
    if [[ ! -f "${unifi_core_config_path}" ]]; then
      tee "${unifi_core_config_path}" &>/dev/null << SSL
# File created by EUS ( Easy UniFi Scripts ).
ssl:
  crt: '/data/eus_certificates/unifi-os.crt'
  key: '/data/eus_certificates/unifi-os.key'
SSL
    else
      if ! [[ -d "${eus_dir}/unifi-os/config_backups" ]]; then mkdir -p "${eus_dir}/unifi-os/config_backups"; fi
      cp "${unifi_core_config_path}" "${eus_dir}/unifi-os/config_backups/config.yaml_$(date +%Y%m%d_%H%M)"
      if ! grep -iq "ssl:" "${unifi_core_config_path}"; then
        tee -a "${unifi_core_config_path}" &>/dev/null << SSL
# File created by EUS ( Easy UniFi Scripts ).
ssl:
  crt: '/data/eus_certificates/unifi-os.crt'
  key: '/data/eus_certificates/unifi-os.key'
SSL
      else
        unifi_os_crt_file=$(grep -i "crt:" "${unifi_core_config_path}" | awk '{print$2}' | sed "s/'//g")
        unifi_os_key_file=$(grep -i "key:" "${unifi_core_config_path}" | awk '{print$2}' | sed "s/'//g")
        sed -i "s#${unifi_os_crt_file}#/data/eus_certificates/unifi-os.crt#g" "${unifi_core_config_path}"
        sed -i "s#${unifi_os_key_file}#/data/eus_certificates/unifi-os.key#g" "${unifi_core_config_path}"
      fi
    fi
  fi
  if systemctl restart unifi-core; then echo -e "${GREEN}#${RESET} Successfully imported the SSL certificates into UniFi OS running on your ${unifi_core_device}!"; else echo -e "${RED}#${RESET} Failed to import the SSL certificates into UniFi OS running on your ${unifi_core_device}..."; sleep 2; fi
  if dpkg -l unifi 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi" && [[ "${script_option_skip_network_application}" != 'true' ]]; then
    unifi_status=$(systemctl status unifi | grep -i 'Active:' | awk '{print $2}')
    if [[ "${unifi_status}" == 'active' ]]; then
      unifi_network_application
    fi
  fi
  if [[ "${udm_device}" == 'true' && "${uid_agent}" != 'true' ]]; then
    if [[ "${debbox}" == 'true' ]]; then
      # shellcheck disable=SC2010
      if [[ -d "/data/udapi-config/raddb/certs/" ]]; then
        if ls -la /data/udapi-config/raddb/certs/ | grep -iq "server.pem\\|server-key.pem" && [[ "${script_option_skip}" != 'true' ]]; then radius_certs_available=true; fi
      fi
    else
      if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -ql root 127.0.0.1 "ls -la /mnt/data/udapi-config/raddb/certs/" | grep -iq "server.pem\\|server-key.pem" && [[ "${script_option_skip}" != 'true' ]]; then radius_certs_available=true; fi
    fi
    if [[ "${radius_certs_available}" == 'true' ]]; then
      echo -e "\\n${YELLOW}#${RESET} ATTENTION, please backup your system before continuing!!"
      # shellcheck disable=2086
      read -rp $'\033[39m#\033[0m Do you want to apply the same certificates to RADIUS on your "'${unifi_core_device}'"? (y/N) ' yes_no
      case "$yes_no" in
          [Yy]*)
              mkdir -p /data/eus_certificates/raddb
              echo -e "\\n${WHITE_R}#${RESET} Backing up original server.pem certificate..."
              if [[ "${debbox}" == 'true' ]]; then
                if cp "/data/udapi-config/raddb/certs/server.pem" "/data/eus_certificates/raddb/original_server_${time_date}.pem" &>> "${eus_dir}/logs/radius.log"; then echo -e "${GREEN}#${RESET} Successfully backed up server.pem ( RADIUS certificate )! \\n"; else echo -e "${RED}#${RESET} Failed to backup RADIUS certificate... \\n"; sleep 5; return; fi
              else
                if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -ql root 127.0.0.1 "cp /mnt/data/udapi-config/raddb/certs/server.pem /data/eus_certificates/raddb/original_server_${time_date}.pem" &>> "${eus_dir}/logs/radius.log"; then echo -e "${GREEN}#${RESET} Successfully backed up server.pem ( RADIUS certificate )! \\n"; else echo -e "${RED}#${RESET} Failed to backup RADIUS certificate... \\n"; sleep 5; return; fi
              fi
              echo -e "${WHITE_R}#${RESET} Backing up original server-key.pem certificate..."
              if [[ "${debbox}" == 'true' ]]; then
                if cp "/data/udapi-config/raddb/certs/server-key.pem" "/data/eus_certificates/raddb/original_server-key_${time_date}.pem" &>> "${eus_dir}/logs/radius.log"; then echo -e "${GREEN}#${RESET} Successfully backed up server-key.pem ( RADIUS certificate )! \\n"; else echo -e "${RED}#${RESET} Failed to backup RADIUS certificate... \\n"; sleep 5; return; fi
              else
                if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -ql root 127.0.0.1 "cp /mnt/data/udapi-config/raddb/certs/server-key.pem /data/eus_certificates/raddb/original_server-key_${time_date}.pem" &>> "${eus_dir}/logs/radius.log"; then echo -e "${GREEN}#${RESET} Successfully backed up server-key.pem ( RADIUS certificate )! \\n"; else echo -e "${RED}#${RESET} Failed to backup RADIUS certificate... \\n"; sleep 5; return; fi
              fi
              echo -e "${WHITE_R}#${RESET} Applying new server.pem certificate..."
              if [[ -f "/data/eus_certificates/unifi-os.crt" ]]; then
                raddb_cert_file="/data/eus_certificates/unifi-os.crt"
              else
                cp "/etc/letsencrypt/live/${server_fqdn}${le_var}/fullchain.pem" /data/eus_certificates/raddb-server.pem
                raddb_cert_file="/data/eus_certificates/raddb-server.pem"
              fi
              if [[ "${debbox}" == 'true' ]]; then
                if cp "${raddb_cert_file}" "/data/udapi-config/raddb/certs/server.pem" &>> "${eus_dir}/logs/radius.log"; then echo -e "${GREEN}#${RESET} Successfully applied the new server.pem ( RADIUS certificate )! \\n"; else echo -e "${RED}#${RESET} Failed to apply the new RADIUS certificate... \\n"; sleep 5; return; fi
              else
                if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -ql root 127.0.0.1 "cp ${raddb_cert_file} /mnt/data/udapi-config/raddb/certs/server.pem" &>> "${eus_dir}/logs/radius.log"; then echo -e "${GREEN}#${RESET} Successfully applied the new server.pem ( RADIUS certificate )! \\n"; else echo -e "${RED}#${RESET} Failed to apply the new RADIUS certificate... \\n"; sleep 5; return; fi
              fi
              echo -e "${WHITE_R}#${RESET} Applying new server-key.pem certificate..."
              if [[ -f "/data/eus_certificates/unifi-os.key" ]]; then
                raddb_key_file="/data/eus_certificates/unifi-os.key"
              else
                cp "/etc/letsencrypt/live/${server_fqdn}${le_var}/privkey.pem" /data/eus_certificates/raddb-server-key.pem
                raddb_key_file="/data/eus_certificates/raddb-server-key.pem"
              fi
              if [[ "${debbox}" == 'true' ]]; then
                if cp "${raddb_key_file}" "/data/udapi-config/raddb/certs/server-key.pem" &>> "${eus_dir}/logs/radius.log"; then echo -e "${GREEN}#${RESET} Successfully applied the new server-key.pem ( RADIUS certificate )! \\n"; else echo -e "${RED}#${RESET} Failed to apply the new RADIUS certificate... \\n"; sleep 5; return; fi
              else
                if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -ql root 127.0.0.1 "cp ${raddb_key_file} /mnt/data/udapi-config/raddb/certs/server-key.pem" &>> "${eus_dir}/logs/radius.log"; then echo -e "${GREEN}#${RESET} Successfully applied the new server-key.pem ( RADIUS certificate )! \\n"; else echo -e "${RED}#${RESET} Failed to apply the new RADIUS certificate... \\n"; sleep 5; return; fi
              fi
              echo -e "${WHITE_R}#${RESET} Restarting udapi-server..."
              if [[ "${debbox}" == 'true' ]]; then
                if systemctl restart udapi-server &>> "${eus_dir}/logs/radius.log"; then echo -e "${GREEN}#${RESET} Successfully restarted udapi-server! \\n"; else echo -e "${RED}#${RESET} Failed to restart udapi-server... \\n${RED}#${RESET} Please reboot your UDM ASAP!\\n"; abort_reason="Failed to restart udapi-server."; abort; fi
              else
                if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -ql root 127.0.0.1 "/etc/init.d/S45ubios-udapi-server restart" &>> "${eus_dir}/logs/radius.log"; then echo -e "${GREEN}#${RESET} Successfully restarted udapi-server! \\n"; else echo -e "${RED}#${RESET} Failed to restart udapi-server... \\n${RED}#${RESET} Please reboot your UDM ASAP!\\n"; abort_reason="Failed to restart udapi-server."; abort; fi
              fi
              sleep 3;;
          [Nn]*|"") ;;
      esac
    fi
  fi
}

uas_management_ui() {
  # shellcheck disable=SC2012
  mkdir -p "${eus_dir}/uas/certs_backups/" && touch "${eus_dir}/uas/uas_management_ui"
  echo -e "\\n${WHITE_R}#${RESET} Importing the SSL certificates into the UniFi Application Server User Interface..."
  # shellcheck disable=SC2012
  if [[ "${old_certificates}" == 'last_three' ]]; then ls -t "${eus_dir}/uas/certs_backups/uas.crt_*" 2> /dev/null | awk 'NR>3' | xargs rm -f 2> /dev/null; fi
  # shellcheck disable=SC2012
  if [[ "${old_certificates}" == 'last_three' ]]; then ls -t "${eus_dir}/uas/certs_backups/uas.key_*" 2> /dev/null | awk 'NR>3' | xargs rm -f 2> /dev/null; fi
  cp /etc/uas/uas.crt "${eus_dir}/uas/certs_backups/uas.crt_$(date +%Y%m%d_%H%M)"
  cp /etc/uas/uas.key "${eus_dir}/uas/certs_backups/uas.key_$(date +%Y%m%d_%H%M)"
  systemctl stop uas
  if [[ "${paid_cert}" == "true" ]]; then
    if [[ -f "${eus_dir}/paid-certificates/eus_crt_file.crt" ]]; then
      cp "${eus_dir}/paid-certificates/eus_crt_file.crt" /etc/uas/uas.crt
    fi
    if [[ -f "${eus_dir}/paid-certificates/eus_key_file.key" ]]; then
      cp "${eus_dir}/paid-certificates/eus_key_file.key" /etc/uas/uas.key
    fi
  else
    if [[ -f "${fullchain_pem}.pem" ]]; then
      cp "${fullchain_pem}.pem" /etc/uas/uas.crt
    elif [[ -f "/etc/letsencrypt/live/${server_fqdn}${le_var}/fullchain.pem" ]]; then
      cp "/etc/letsencrypt/live/${server_fqdn}${le_var}/fullchain.pem" /etc/uas/uas.crt
    fi
    if [[ -f "${priv_key_pem}.pem" ]]; then
      cp "${priv_key_pem}.pem" /etc/uas/uas.key
    elif [[ -f "/etc/letsencrypt/live/${server_fqdn}${le_var}/privkey.pem" ]]; then
      cp "/etc/letsencrypt/live/${server_fqdn}${le_var}/privkey.pem" /etc/uas/uas.key
    fi
  fi
  if systemctl start uas; then echo -e "${GREEN}#${RESET} Successfully imported the SSL certificates into the UniFi Application Server User Interface!"; else echo -e "${RED}#${RESET} Failed to import the SSL certificates into the UniFi Application Server User Interface..."; sleep 2; fi
}

uas_unifi_led() {
  # shellcheck disable=SC2012
  mkdir -p "${eus_dir}/eot/certs_backups" && touch "${eus_dir}/eot/uas_unifi_led"
  if dpkg -l | grep -iq "\\bUAS\\b\\|UniFi Application Server"; then echo -e "\\n${WHITE_R}#${RESET} Importing the SSL certificates into UniFi-LED on your UniFi Application Server..."; else echo -e "\\n${WHITE_R}#${RESET} Importing the SSL certificates into UniFi-LED..."; fi
  # shellcheck disable=SC2012
  if [[ "${old_certificates}" == 'last_three' ]]; then ls -t "${eus_dir}/eot/certs_backups/server.pem_*" 2> /dev/null | awk 'NR>3' | xargs rm -f 2> /dev/null; fi
  cat "/etc/letsencrypt/live/${server_fqdn}${le_var}/privkey.pem" "/etc/letsencrypt/live/${server_fqdn}${le_var}/fullchain.pem" > "${eus_dir}/eot/eot_docker_container.pem"
  eot_container=$(docker ps -a | grep -i "ubnt/eot" | awk '{print $1}')
  eot_container_name="ueot"
  if [[ -n "${eot_container}" ]]; then
    docker cp "${eot_container}:/app/certs/server.pem" "${eus_dir}/eot/certs_backups/server.pem_$(date +%Y%m%d_%H%M)"
    if [[ "${paid_cert}" == "true" ]]; then
      docker cp "${eus_dir}/paid-certificates/eus_certificates_file.pem" "${eot_container}:/app/certs/server.pem"
    else
      docker cp "${eus_dir}/eot/eot_docker_container.pem" "${eot_container}:/app/certs/server.pem"
    fi
    docker restart "${eot_container_name}" &>> "${eus_dir}/eot/ueot_container_restart" && if dpkg -l | grep -iq "\\bUAS\\b\\|UniFi Application Server"; then echo -e "${GREEN}#${RESET} Successfully imported the SSL certificates into UniFi-LED on your UniFi Application Server..." || echo -e "${RED}#${RESET} Failed to import the SSL certificates into UniFi-LED on your UniFi Application Server... \\n"; else echo -e "${GREEN}#${RESET} Successfully imported the SSL certificates into UniFi-LED!" || echo -e "${RED}#${RESET} Failed to import the SSL certificates into UniFi-LED... \\n"; fi && sleep 2
  else
    rm --force "${eus_dir}/eot/uas_unifi_led" 2> /dev/null
    echo -e "${RED}#${RESET} Couldn't find UniFi LED container..." && sleep 2
  fi
}

unifi_video() {
  # shellcheck disable=SC2012
  mkdir -p "${eus_dir}/video/keystore_backups" && touch "${eus_dir}/video/unifi_video"
  echo -e "\\n${WHITE_R}#${RESET} Importing the SSL certificates into UniFi-Video..."
  mkdir -p /usr/lib/unifi-video/data/certificates
  mkdir -p /var/lib/unifi-video/certificates
  # shellcheck disable=SC2012
  if [[ "${old_certificates}" == 'last_three' ]]; then ls -t "${eus_dir}/video/keystore_backups/keystore_*" 2> /dev/null | awk 'NR>3' | xargs rm -f 2> /dev/null; fi
  # shellcheck disable=SC2012
  if [[ "${old_certificates}" == 'last_three' ]]; then ls -t "${eus_dir}/video/keystore_backups/ufv-truststore_*" 2> /dev/null | awk 'NR>3' | xargs rm -f 2> /dev/null; fi
  mv /usr/lib/unifi-video/data/keystore "${eus_dir}/video/keystore_backups/keystore_$(date +%Y%m%d_%H%M)"
  mv /usr/lib/unifi-video/data/ufv-truststore "${eus_dir}/video/keystore_backups/ufv-truststore_$(date +%Y%m%d_%H%M)"
  if [[ "${paid_cert}" == "true" ]]; then
    cp "${eus_dir}/paid-certificates/ufv-server.key.der" /usr/lib/unifi-video/data/certificates/ufv-server.key.der
    cp "${eus_dir}/paid-certificates/ufv-server.cert.der" /usr/lib/unifi-video/data/certificates/ufv-server.cert.der
  else
    openssl pkcs8 -topk8 -nocrypt -in "/etc/letsencrypt/live/${server_fqdn}${le_var}/privkey.pem" -outform DER -out /usr/lib/unifi-video/data/certificates/ufv-server.key.der
    openssl x509 -outform der -in "/etc/letsencrypt/live/${server_fqdn}${le_var}/fullchain.pem" -out /usr/lib/unifi-video/data/certificates/ufv-server.cert.der
  fi
  chown -R unifi-video:unifi-video /usr/lib/unifi-video/data/certificates
  systemctl stop unifi-video
  if ! grep -iq "^ufv.custom.certs.enable=true" /usr/lib/unifi-video/data/system.properties; then
    echo "ufv.custom.certs.enable=true" &>> /usr/lib/unifi-video/data/system.properties
  fi
  if systemctl start unifi-video; then echo -e "${GREEN}#${RESET} Successfully imported the SSL certificates into UniFi-Video!"; else echo -e "${RED}#${RESET} Failed to import the SSL certificates into UniFi-Video..."; sleep 2; fi
}

unifi_network_application() {
  if [[ "${unifi_native_system}" == 'true' ]]; then
    openjdk_native_installed_package="$(apt-cache search "jre-headless" | grep -Eio "openjdk-[0-9]{1,2}-jre-headless" | sort -V | tail -n1)"
    required_package="${openjdk_native_installed_package}"
    apt_get_install_package
    openjdk_native_installed="true"
  fi
  if [[ "${unifi_core_system}" == 'true' ]]; then echo -e "\\n${WHITE_R}#${RESET} Importing the SSL certificates into the UniFi Network Application running on your ${unifi_core_device}..."; else echo -e "\\n${WHITE_R}#${RESET} Importing the SSL certificates into the UniFi Network Application..."; fi
  echo -e "\\n------- $(date +%F-%R) -------\\n" &>> "${eus_dir}/logs/lets_encrypt_import.log"
  if sha256sum "/etc/letsencrypt/live/${server_fqdn}${le_var}/fullchain.pem" 2> /dev/null | awk '{print $1}' &> "${eus_dir}/checksum/fullchain.sha256sum"; then echo "Successfully updated sha256sum" &>> "${eus_dir}/logs/lets_encrypt_import.log"; fi
  if md5sum "/etc/letsencrypt/live/${server_fqdn}${le_var}/fullchain.pem" 2> /dev/null | awk '{print $1}' &> "${eus_dir}/checksum/fullchain.md5sum"; then echo "Successfully updated md5sum" &>> "${eus_dir}/logs/lets_encrypt_import.log"; fi
  # shellcheck disable=SC2012
  if [[ "${old_certificates}" == 'last_three' ]]; then ls -t "${eus_dir}/network/keystore_backups/keystore_*" 2> /dev/null | awk 'NR>3' | xargs rm -f 2> /dev/null; fi
  mkdir -p "${eus_dir}/network/keystore_backups" && cp /usr/lib/unifi/data/keystore "${eus_dir}/network/keystore_backups/keystore_$(date +%Y%m%d_%H%M)"
  # shellcheck disable=SC2012,SC2129
  if [[ "${paid_cert}" == "true" ]]; then
    keytool -delete -alias unifi -keystore /usr/lib/unifi/data/keystore -deststorepass aircontrolenterprise &>> "${eus_dir}/logs/paid_certificate_import.log"
    keytool -importkeystore -deststorepass aircontrolenterprise -destkeypass aircontrolenterprise -destkeystore /usr/lib/unifi/data/keystore -srckeystore "${eus_dir}/paid-certificates/eus_unifi.p12" -srcstoretype PKCS12 -srcstorepass aircontrolenterprise -alias unifi -noprompt &>> "${eus_dir}/logs/paid_certificate_import.log"
    # shellcheck disable=SC2086
    if openssl pkcs12 -in "${eus_dir}/paid-certificates/eus_unifi.p12" -password pass:aircontrolenterprise -nokeys ${openssl_legacy_flag} | openssl x509 -text -noout | grep -i signature | grep -iq ecdsa &> /dev/null; then
      echo "unifi.https.ciphers=ECDHE-ECDSA-AES256-GCM-SHA384,ECDHE-RSA-AES128-GCM-SHA256" &>> /usr/lib/unifi/data/system.properties
      echo "unifi.https.sslEnabledProtocols=TLSv1.3,TLSv1.2" &>> /usr/lib/unifi/data/system.properties
    fi
  else
    # shellcheck disable=SC2086
    openssl pkcs12 -export -inkey "${priv_key_pem}.pem" -in "${fullchain_pem}.pem" -out "${fullchain_pem}.p12" -name unifi -password pass:aircontrolenterprise ${openssl_legacy_flag} &>> "${eus_dir}/logs/lets_encrypt_import.log"
    keytool -delete -alias unifi -keystore /usr/lib/unifi/data/keystore -deststorepass aircontrolenterprise &>> "${eus_dir}/logs/lets_encrypt_import.log"
    keytool -importkeystore -deststorepass aircontrolenterprise -destkeypass aircontrolenterprise -destkeystore /usr/lib/unifi/data/keystore -srckeystore "${fullchain_pem}.p12" -srcstoretype PKCS12 -srcstorepass aircontrolenterprise -alias unifi -noprompt &>> "${eus_dir}/logs/lets_encrypt_import.log"
    # shellcheck disable=SC2086
    if openssl pkcs12 -in "${fullchain_pem}.p12" -password pass:aircontrolenterprise -nokeys ${openssl_legacy_flag} | openssl x509 -text -noout | grep -i signature | grep -iq ecdsa &> /dev/null; then
      echo "unifi.https.ciphers=ECDHE-ECDSA-AES256-GCM-SHA384,ECDHE-RSA-AES128-GCM-SHA256" &>> /usr/lib/unifi/data/system.properties
      echo "unifi.https.sslEnabledProtocols=TLSv1.3,TLSv1.2" &>> /usr/lib/unifi/data/system.properties
    fi
  fi
  chown -R unifi:unifi /usr/lib/unifi/data/keystore &> /dev/null
  if systemctl restart unifi; then
    if [[ "${unifi_core_system}" == 'true' ]]; then echo -e "${GREEN}#${RESET} Successfully imported the SSL certificates into the UniFi Network Application running on your ${unifi_core_device}!"; else echo -e "${GREEN}#${RESET} Successfully imported the SSL certificates into the UniFi Network Application!"; fi
    sleep 2
  else
    if [[ "${unifi_core_system}" == 'true' ]]; then echo -e "${RED}#${RESET} Failed to import the SSL certificates into the UniFi Network Application running on your ${unifi_core_device}..."; else echo -e "${RED}#${RESET} Failed to import the SSL certificates into the UniFi Network Application..."; fi
    sleep 2
  fi
  if [[ -f "${eus_dir}/logs/lets_encrypt_import.log" ]] && grep -iq 'Keystore was tampered with, or password was incorrect' "${eus_dir}/logs/lets_encrypt_import.log"; then
    if ! [[ -f "${eus_dir}/network/failed" ]]; then
      echo -e "${RED}#${RESET} Importing into the UniFi Network Application failed.. let's clean up some files and try it one more time."
      rm --force /usr/lib/unifi/data/keystore 2> /dev/null && systemctl restart unifi
      rm --force "${eus_dir}/logs/lets_encrypt_import.log" 2> /dev/null
      mkdir -p "${eus_dir}/network/" && touch "${eus_dir}/network/failed"
	  unifi_network_application
    else
      le_import_failed
    fi
  fi
}

import_ssl_certificates() {
  header
  if [[ "${prefer_dns_challenge}" == 'true' ]]; then
    echo -e "${WHITE_R}#${RESET} Performing the DNS challenge!"
    if [[ "${certbot_auto}" == 'true' ]]; then
      if [[ "${dns_manual_flag}" == '--manual' ]]; then
        echo ""
        # shellcheck disable=SC2090,SC2086
        ${certbot} certonly ${dns_manual_flag} --agree-tos --preferred-challenges dns ${auto_dns_challenge_arguments} ${server_fqdn_le} ${email} ${renewal_option} ${acme_server} ${key_type_option} "${certbot_auto_flags}" 2>&1 | tee -a "${eus_dir}/logs/lets_encrypt_${time_date}.log" && dns_manual_certbot_success=true
      else
        if [[ "${certbot_native_plugin}" == 'true' ]]; then
          # shellcheck disable=SC2090,SC2086
          ${certbot} certonly ${dns_manual_flag} --agree-tos --preferred-challenges dns --post-hook "/etc/letsencrypt/renewal-hooks/post/EUS_${server_fqdn}.sh" ${auto_dns_challenge_arguments} ${server_fqdn_le} ${email} ${renewal_option} ${acme_server} ${key_type_option} "${certbot_auto_flags}" &> "${eus_dir}/logs/lets_encrypt_${time_date}.log" && dns_certbot_success=true
        elif [[ "${certbot_multi_plugin}" == 'true' ]]; then
          # shellcheck disable=SC2090,SC2086
          ${certbot} certonly ${auto_dns_challenge_arguments} ${dns_manual_flag} --agree-tos --preferred-challenges dns --post-hook "/etc/letsencrypt/renewal-hooks/post/EUS_${server_fqdn}.sh" ${server_fqdn_le} ${email} ${renewal_option} ${acme_server} ${key_type_option} "${certbot_auto_flags}" &> "${eus_dir}/logs/lets_encrypt_${time_date}.log" && dns_certbot_success=true
        fi
      fi
    else
      if [[ "${dns_manual_flag}" == '--manual' ]]; then
        echo ""
        # shellcheck disable=SC2090,SC2086
        ${certbot} certonly ${dns_manual_flag} --agree-tos --preferred-challenges dns ${auto_dns_challenge_arguments} ${server_fqdn_le} ${email} ${renewal_option} ${acme_server} ${key_type_option} 2>&1 | tee -a "${eus_dir}/logs/lets_encrypt_${time_date}.log" && dns_manual_certbot_success=true
      else
        if [[ "${certbot_native_plugin}" == 'true' ]]; then
          # shellcheck disable=SC2090,SC2086
          ${certbot} certonly ${dns_manual_flag} --agree-tos --preferred-challenges dns --post-hook "/etc/letsencrypt/renewal-hooks/post/EUS_${server_fqdn}.sh" ${auto_dns_challenge_arguments} ${server_fqdn_le} ${email} ${renewal_option} ${acme_server} ${key_type_option} &> "${eus_dir}/logs/lets_encrypt_${time_date}.log" && dns_certbot_success=true
        elif [[ "${certbot_multi_plugin}" == 'true' ]]; then
          # shellcheck disable=SC2090,SC2086
          ${certbot} certonly ${auto_dns_challenge_arguments} ${dns_manual_flag} --agree-tos --preferred-challenges dns --post-hook "/etc/letsencrypt/renewal-hooks/post/EUS_${server_fqdn}.sh" ${server_fqdn_le} ${email} ${renewal_option} ${acme_server} ${key_type_option} &> "${eus_dir}/logs/lets_encrypt_${time_date}.log" && dns_certbot_success=true
        fi
      fi
    fi
  else
    if dpkg -l unifi-core 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
      if [[ "${renewal_option}" == "--force-renewal" ]]; then
        echo -e "${WHITE_R}#${RESET} Force renewing the SSL certificates and importing them into UniFi OS running on your ${unifi_core_device}..."
      else
        echo -e "${WHITE_R}#${RESET} Importing the SSL certificates into UniFi OS running on your ${unifi_core_device}..."
      fi
    elif dpkg -l unifi 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
      if [[ "${renewal_option}" == "--force-renewal" ]]; then
        echo -e "${WHITE_R}#${RESET} Force renewing the SSL certificates and importing them into the UniFi Network Application..."
      else
        echo -e "${WHITE_R}#${RESET} Importing the SSL certificates into the UniFi Network Application..."
      fi
    else
      if [[ "${renewal_option}" == "--force-renewal" ]]; then
        echo -e "${WHITE_R}#${RESET} Force renewing the SSL certificates"
      else
        echo -e "${WHITE_R}#${RESET} Creating the certificates!"
      fi
    fi
    if [[ "${certbot_auto}" == 'true' ]]; then
      # shellcheck disable=2086
      ${certbot} certonly --standalone --agree-tos --preferred-challenges http --pre-hook "/etc/letsencrypt/renewal-hooks/pre/EUS_${server_fqdn}.sh" --post-hook "/etc/letsencrypt/renewal-hooks/post/EUS_${server_fqdn}.sh" ${server_fqdn_le} ${email} ${renewal_option} ${acme_server} ${key_type_option} --non-interactive "${certbot_auto_flags}" &> "${eus_dir}/logs/lets_encrypt_${time_date}.log" && certbot_success=true
    else
      # shellcheck disable=2086
      ${certbot} certonly --standalone --agree-tos --preferred-challenges http --pre-hook "/etc/letsencrypt/renewal-hooks/pre/EUS_${server_fqdn}.sh" --post-hook "/etc/letsencrypt/renewal-hooks/post/EUS_${server_fqdn}.sh" ${server_fqdn_le} ${email} ${renewal_option} ${acme_server} ${key_type_option} --non-interactive &> "${eus_dir}/logs/lets_encrypt_${time_date}.log" && certbot_success=true
    fi
  fi
  if [[ "${certbot_success}" == 'true' ]] || [[ "${dns_certbot_success}" == 'true' ]] || [[ "${dns_manual_certbot_success}" == 'true' ]]; then
    if [[ "${dns_certbot_success}" == 'true' ]] || [[ "${dns_manual_certbot_success}" == 'true' ]]; then dns_certbot_success_check="true"; fi
    if [[ "${dns_certbot_success}" == 'true' ]] || [[ "${certbot_success}" == 'true' ]]; then auto_certbot_success_check="true"; fi
    if [[ "${certbot_success}" == 'true' ]] || [[ "${dns_certbot_success}" == 'true' ]] || [[ "${dns_manual_certbot_success}" == 'true' ]]; then
      if [[ -f "${eus_dir}/logs/lets_encrypt_import.log" ]] && grep -iq 'Keystore was tampered with, or password was incorrect' "${eus_dir}/logs/lets_encrypt_import.log"; then
        mkdir -p "${eus_dir}/network/" && touch "${eus_dir}/network/failed"
        unifi_network_application
      elif [[ -f "${eus_dir}/logs/lets_encrypt_${time_date}.log" ]] && grep -iq 'Incorrect TXT record' "${eus_dir}/logs/lets_encrypt_${time_date}.log"; then
        header_red
        echo -e "${RED}#${RESET} The created TXT record is incorrect..."
        rm --force "${eus_dir}/txt_record" &> /dev/null
        dig +short TXT "_acme-challenge.${server_fqdn}" "${external_dns_server}" &>> "${eus_dir}/txt_record"
        txt_dig=$(head -n1 "${eus_dir}/txt_record")
        echo -e "${RED}#${RESET} TXT record for _acme-challenge.${server_fqdn} is '${txt_dig}'."
        abort_skip_support_file_upload="true"
        abort_reason="TXT record _acme-challenge.${server_fqdn} is ${txt_dig//\"/}."
        abort
      elif [[ -f "${eus_dir}/logs/lets_encrypt_import.log" ]] && grep -iq 'No TXT record found' "${eus_dir}/logs/lets_encrypt_${time_date}.log"; then
        le_import_failed
      elif [[ -f "${eus_dir}/logs/lets_encrypt_${time_date}.log" ]] && grep -iq 'Dns problem' "${eus_dir}/logs/lets_encrypt_${time_date}.log"; then
        header_red
        echo -e "${RED}#${RESET} There is an error looking up DNS record _acme-challenge.${server_fqdn}..."
        abort_skip_support_file_upload="true"
        abort_reason="error looking up DNS record _acme-challenge.${server_fqdn}"
        abort
      elif [[ -f "${eus_dir}/logs/lets_encrypt_${time_date}.log" ]] && grep -iq 'Invalid response from' "${eus_dir}/logs/lets_encrypt_${time_date}.log"; then
        header_red
        echo -e "${RED}#${RESET} Invalid response from \"http://${server_fqdn}/.well-known/acme-challenge/xxxxxxxxxxxxxxxxxxx\"..."
        abort_skip_support_file_upload="true"
        abort_reason="Invalid response from http://${server_fqdn}/.well-known/acme-challenge/xxxxxxxxxxxxxxxxxxx"
        abort
      elif [[ -f "${eus_dir}/logs/lets_encrypt_${time_date}.log" ]] && grep -iq 'too many requests' "${eus_dir}/logs/lets_encrypt_${time_date}.log"; then
        header_red
        echo -e "${RED}#${RESET} There have been to many requests for ${server_fqdn}... \\n${RED}#${RESET} See https://letsencrypt.org/docs/rate-limits/ for more details..."
        abort_skip_support_file_upload="true"
        abort_reason="to many requests for ${server_fqdn}"
        abort
      elif [[ -f "/var/log/letsencrypt/letsencrypt.log" ]] && tail -n80 "/var/log/letsencrypt/letsencrypt.log" | grep -iq 'too many requests' && [[ "${dns_certbot_success_check}" == 'true' ]]; then
        header_red
        echo -e "${RED}#${RESET} There have been to many requests for ${server_fqdn}... \\n${RED}#${RESET} See https://letsencrypt.org/docs/rate-limits/ for more details..."
        abort_skip_support_file_upload="true"
        abort_reason="to many requests for ${server_fqdn}"
        abort
      elif [[ -f "${eus_dir}/logs/lets_encrypt_import.log" ]] && tail -n5 "${eus_dir}/logs/lets_encrypt_import.log" | grep -iq 'Error' && [[ "${auto_certbot_success_check}" == 'true' ]]; then
        header_red
        echo -e "${RED}#${RESET} An unknown error occured..."
        abort_skip_support_file_upload="true"
        abort_reason="Unknown error"
        abort
      else
        if [[ "${auto_certbot_success_check}" == 'true' ]]; then if dpkg -l unifi-core 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then echo -e "${GREEN}#${RESET} Successfully imported the SSL certificates into UniFi OS! \\n"; sleep 5; else echo -e "${GREEN}#${RESET} Successfully imported the SSL certificates into the UniFi Network Application! \\n"; sleep 2; fi; fi
        if [[ "${is_cloudkey}" == 'true' ]]; then run_uck_scripts=true; fi
      fi
      if ls "${eus_dir}/logs/lets_encrypt_[0-9]*.log" &>/dev/null; then
        le_var=$(grep -i "/etc/letsencrypt/live/${server_fqdn}" "${eus_dir}/logs/lets_encrypt_${time_date}.log" | awk '{print $1}' | head -n1 | grep -io "${server_fqdn}.*" | cut -d'/' -f1 | sed "s/${server_fqdn}//g")
      fi
    fi
    if [[ "${dns_manual_certbot_success}" == 'true' ]]; then
      header
      echo -e "${GREEN}#${RESET} Successfully created the SSL Certificates!"
      if [[ "${certbot_auto}" == 'true' ]]; then
        # shellcheck disable=2086
        ${certbot} certificates --domain "${server_fqdn}" "${certbot_auto_flags}" &>> "${eus_dir}/certificates"
      else
        # shellcheck disable=2086
        ${certbot} certificates --domain "${server_fqdn}" &>> "${eus_dir}/certificates"
      fi
      le_fqdn=$(grep -io "${server_fqdn}.*" "${eus_dir}/certificates" | cut -d'/' -f1 | tail -n1)
      fullchain_pem=$(grep -i "Certificate Path" "${eus_dir}/certificates" | grep -i "${le_fqdn}" | awk '{print $3}' | sed 's/.pem//g' | tail -n1)
      priv_key_pem=$(grep -i "Private Key Path" "${eus_dir}/certificates" | grep -i "${le_fqdn}" | awk '{print $4}' | sed 's/.pem//g' | tail -n1)
      if [[ "${unifi_core_system}" == 'true' ]]; then
        echo -e "\\n${WHITE_R}----${RESET}\\n"
        echo -e "${WHITE_R}#${RESET} UniFi OS on your ${unifi_core_device} has been detected!"
        if [[ "${script_option_skip}" != 'true' ]]; then read -rp $'\033[39m#\033[0m Would you like to apply the certificates to UniFi OS? (Y/n) ' yes_no; fi
        case "$yes_no" in
           [Yy]*|"")
              unifi_core
              if [[ "${is_cloudkey}" == 'true' ]]; then run_uck_scripts=true; fi;;
           [Nn]*) ;;
        esac
      elif dpkg -l unifi 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi" && [[ "${unifi_core_system}" != 'true' ]]; then
        echo -e "\\n${WHITE_R}----${RESET}\\n"
        echo -e "${WHITE_R}#${RESET} UniFi Network Application has been detected!"
        if [[ "${script_option_skip}" != 'true' ]]; then read -rp $'\033[39m#\033[0m Would you like to apply the certificates to the UniFi Network Application? (Y/n) ' yes_no; fi
        case "$yes_no" in
           [Yy]*|"")
              unifi_network_application
              if [[ "${is_cloudkey}" == 'true' ]]; then run_uck_scripts=true; fi;;
           [Nn]*) ;;
        esac
      fi
    fi
    if [[ "${is_cloudkey}" == 'true' ]] && [[ "${unifi_core_system}" != 'true' ]]; then
      echo -e "\\n${WHITE_R}----${RESET}\\n"
      echo -e "${WHITE_R}#${RESET} You seem to have a Cloud Key!"
      if [[ "${is_cloudkey_gen2_plus}" == 'true' ]] && dpkg -l unifi-protect 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
        if [[ "${script_option_skip}" != 'true' ]]; then read -rp $'\033[39m#\033[0m Would you like to apply the certificates to the UniFi Cloudkey User Interface and UniFi-Protect? (Y/n) ' yes_no; fi
      else
        if [[ "${script_option_skip}" != 'true' ]]; then read -rp $'\033[39m#\033[0m Would you like to apply the certificates to the UniFi Cloudkey User Interface? (Y/n) ' yes_no; fi
      fi
      case "$yes_no" in
         [Yy]*|"")
            cloudkey_management_ui
            run_uck_scripts=true;;
         [Nn]*) ;;
      esac
      if dpkg -l unifi-led 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi" && [[ "${unifi_core_system}" != 'true' ]]; then
        echo -e "\\n${WHITE_R}----${RESET}\\n"
        echo -e "${WHITE_R}#${RESET} UniFi-LED has been detected!"
        if [[ "${script_option_skip}" != 'true' ]]; then read -rp $'\033[39m#\033[0m Would you like to apply the certificates to UniFi-LED? (Y/n) ' yes_no; fi
        case "$yes_no" in
           [Yy]*|"")
            cloudkey_unifi_led
            run_uck_scripts=true;;
           [Nn]*) ;;
        esac
      fi
      if dpkg -l unifi-talk 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi" && [[ "${unifi_core_system}" != 'true' ]]; then
        echo -e "\\n${WHITE_R}----${RESET}\\n"
        echo -e "${WHITE_R}#${RESET} UniFi-Talk has been detected!"
        if [[ "${script_option_skip}" != 'true' ]]; then read -rp $'\033[39m#\033[0m Would you like to apply the certificates to UniFi-Talk? (Y/n) ' yes_no; fi
        case "$yes_no" in
           [Yy]*|"")
            cloudkey_unifi_talk
            run_uck_scripts=true;;
           [Nn]*) ;;
        esac
      fi
    fi
    if dpkg -l | grep -iq "\\bUAS\\b\\|UniFi Application Server" && [[ "${unifi_core_system}" != 'true' ]]; then
      echo -e "\\n${WHITE_R}----${RESET}\\n"
      echo -e "${WHITE_R}#${RESET} You seem to have a UniFi Application Server!"
      if [[ "${script_option_skip}" != 'true' ]]; then read -rp $'\033[39m#\033[0m Would you like to apply the certificates to the UniFi Application Server User Interface? (Y/n) ' yes_no; fi
      case "$yes_no" in
         [Yy]*|"") uas_management_ui;;
         [Nn]*) ;;
      esac
      if dpkg -l uas-led 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi" && [[ "${unifi_core_system}" != 'true' ]]; then
        if dpkg -l | awk '{print $2}' | grep -iq "^docker.io\\|^docker-ce"; then
          if docker ps -a | grep -iq 'ubnt/eot'; then
            echo -e "\\n${WHITE_R}----${RESET}\\n"
            echo -e "${WHITE_R}#${RESET} UniFi-LED has been detected!"
            if [[ "${script_option_skip}" != 'true' ]]; then read -rp $'\033[39m#\033[0m Would you like to apply the certificates to UniFi-LED? (Y/n) ' yes_no; fi
            case "$yes_no" in
                [Yy]*|"") uas_unifi_led;;
                [Nn]*) ;;
            esac
          fi
        fi
      fi
    fi
    if dpkg -l unifi-video 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi" && [[ "${unifi_core_system}" != 'true' ]]; then
      echo -e "\\n${WHITE_R}----${RESET}\\n"
      echo -e "${WHITE_R}#${RESET} UniFi-Video has been detected!"
      if [[ "${script_option_skip}" != 'true' ]]; then read -rp $'\033[39m#\033[0m Would you like to apply the certificates to UniFi-Video? (Y/n) ' yes_no; fi
      case "$yes_no" in
         [Yy]*|"") unifi_video;;
         [Nn]*) ;;
      esac
    fi
    if dpkg -l | awk '{print $2}' | grep -iq "^docker.io\\|^docker-ce" && [[ "${unifi_core_system}" != 'true' ]]; then
      if docker ps -a | grep -iq 'ubnt/eot'; then
        echo -e "\\n${WHITE_R}----${RESET}\\n"
        echo -e "${WHITE_R}#${RESET} UniFi-LED has been detected!"
        if [[ "${script_option_skip}" != 'true' ]]; then read -rp $'\033[39m#\033[0m Would you like to apply the certificates to UniFi-LED? (Y/n) ' yes_no; fi
        case "$yes_no" in
           [Yy]*|"") uas_unifi_led;;
           [Nn]*) ;;
        esac
      fi
    fi
    if [[ "${dns_manual_certbot_success}" == 'true' ]]; then
      rm --force "${eus_dir}/expire_date" &> /dev/null
      rm --force "/etc/letsencrypt/renewal-hooks/post/EUS_${server_fqdn}.sh" &> /dev/null
      rm --force "/etc/letsencrypt/renewal-hooks/pre/EUS_${server_fqdn}.sh" &> /dev/null
      certbot certificates --domain "${server_fqdn}" &>> "${eus_dir}/expire_date"
      if grep -iq "${server_fqdn}" "${eus_dir}/expire_date"; then
        expire_date=$(grep -i "Expiry Date:" "${eus_dir}/expire_date" | awk '{print $3}')
      fi
      rm --force "${eus_dir}/expire_date" &> /dev/null
      if [[ -n "${expire_date}" ]]; then
         echo -e "\\n${GREEN}---${RESET}\\n"
         echo -e "${WHITE_R}#${RESET} Your SSL certificates will expire at '${expire_date}'"
         echo -e "${WHITE_R}#${RESET} Please run this script again before '${expire_date}' to renew your certificates"
      fi
    fi
  else
    le_import_failed
  fi
}

import_existing_ssl_certificates() {
  case "$yes_no" in
     [Yy]*|"")
        if [[ "${unifi_core_system}" == 'true' ]]; then
          echo -e "\\n${WHITE_R}----${RESET}\\n"
          echo -e "${WHITE_R}#${RESET} UniFi OS on your ${unifi_core_device} has been detected!"
          if [[ "${script_option_skip}" != 'true' ]]; then read -rp $'\033[39m#\033[0m Would you like to apply the certificates to UniFi OS? (Y/n) ' yes_no; fi
          case "$yes_no" in
             [Yy]*|"")
                unifi_core
                if [[ "${is_cloudkey}" == 'true' ]]; then run_uck_scripts=true; fi;;
             [Nn]*) ;;
          esac
        fi
        if dpkg -l unifi 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi" && [[ "${unifi_core_system}" != 'true' ]]; then
          echo -e "\\n${WHITE_R}----${RESET}\\n"
          echo -e "${WHITE_R}#${RESET} UniFi Network Application has been detected!"
          if [[ "${script_option_skip}" != 'true' ]]; then read -rp $'\033[39m#\033[0m Would you like to apply the certificates to the UniFi Network Application? (Y/n) ' yes_no; fi
          case "$yes_no" in
             [Yy]*|"")
                unifi_network_application
                if [[ "${is_cloudkey}" == 'true' ]]; then run_uck_scripts=true; fi;;
             [Nn]*) ;;
          esac
        fi
        if [[ "${is_cloudkey}" == 'true' ]] && [[ "${unifi_core_system}" != 'true' ]]; then
          echo -e "\\n${WHITE_R}----${RESET}\\n"
          echo -e "${WHITE_R}#${RESET} You seem to have a Cloud Key!"
          if [[ "${is_cloudkey_gen2_plus}" == 'true' ]] && dpkg -l unifi-protect 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi" && [[ "${unifi_core_system}" != 'true' ]]; then
            if [[ "${script_option_skip}" != 'true' ]]; then read -rp $'\033[39m#\033[0m Would you like to apply the certificates to the UniFi Cloudkey User Interface and UniFi-Protect? (Y/n) ' yes_no; fi
          else
            if [[ "${script_option_skip}" != 'true' ]]; then read -rp $'\033[39m#\033[0m Would you like to apply the certificates to the UniFi Cloudkey User Interface? (Y/n) ' yes_no; fi
          fi
          case "$yes_no" in
             [Yy]*|"")
                  cloudkey_management_ui
                  run_uck_scripts=true;;
             [Nn]*) ;;
          esac
          if dpkg -l unifi-led 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi" && [[ "${unifi_core_system}" != 'true' ]]; then
            echo -e "\\n${WHITE_R}----${RESET}\\n"
            echo -e "${WHITE_R}#${RESET} UniFi-LED has been detected!"
            if [[ "${script_option_skip}" != 'true' ]]; then read -rp $'\033[39m#\033[0m Would you like to apply the certificates to UniFi-LED? (Y/n) ' yes_no; fi
            case "$yes_no" in
               [Yy]*|"")
                  cloudkey_unifi_led
                  run_uck_scripts=true;;
               [Nn]*) ;;
            esac
          fi
          if dpkg -l unifi-talk 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi" && [[ "${unifi_core_system}" != 'true' ]]; then
            echo -e "\\n${WHITE_R}----${RESET}\\n"
            echo -e "${WHITE_R}#${RESET} UniFi-Talk has been detected!"
            if [[ "${script_option_skip}" != 'true' ]]; then read -rp $'\033[39m#\033[0m Would you like to apply the certificates to UniFi-Talk? (Y/n) ' yes_no; fi
            case "$yes_no" in
               [Yy]*|"")
                  cloudkey_unifi_talk
                  run_uck_scripts=true;;
               [Nn]*) ;;
            esac
          fi
        fi
        if dpkg -l | grep -iq "\\bUAS\\b\\|UniFi Application Server" && [[ "${unifi_core_system}" != 'true' ]]; then
          echo -e "\\n${WHITE_R}----${RESET}\\n"
          echo -e "${WHITE_R}#${RESET} You seem to have a UniFi Application Server!"
          if [[ "${script_option_skip}" != 'true' ]]; then read -rp $'\033[39m#\033[0m Would you like to apply the certificates to the UniFi Application Server User Interface? (Y/n) ' yes_no; fi
          case "$yes_no" in
             [Yy]*|"") uas_management_ui;;
             [Nn]*) ;;
          esac
          if dpkg -l uas-led 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi" && [[ "${unifi_core_system}" != 'true' ]]; then
            if dpkg -l | awk '{print $2}' | grep -iq "^docker.io\\|^docker-ce"; then
              if docker ps -a | grep -iq 'ubnt/eot'; then
                echo -e "\\n${WHITE_R}----${RESET}\\n"
                echo -e "${WHITE_R}#${RESET} UniFi-LED has been detected!"
                if [[ "${script_option_skip}" != 'true' ]]; then read -rp $'\033[39m#\033[0m Would you like to apply the certificates to UniFi-LED? (Y/n) ' yes_no; fi
                case "$yes_no" in
                    [Yy]*|"") uas_unifi_led;;
                    [Nn]*) ;;
                esac
              fi
            fi
          fi
        fi
        if dpkg -l unifi-video 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi" && [[ "${unifi_core_system}" != 'true' ]]; then
          echo -e "\\n${WHITE_R}----${RESET}\\n"
          echo -e "${WHITE_R}#${RESET} UniFi-Video has been detected!"
          if [[ "${script_option_skip}" != 'true' ]]; then read -rp $'\033[39m#\033[0m Would you like to apply the certificates to UniFi-Video? (Y/n) ' yes_no; fi
          case "$yes_no" in
             [Yy]*|"") unifi_video;;
             [Nn]*) ;;
          esac
        fi
        if dpkg -l | awk '{print $2}' | grep -iq "^docker.io\\|^docker-ce" && [[ "${unifi_core_system}" != 'true' ]]; then
          if docker ps -a | grep -iq 'ubnt/eot'; then
            echo -e "\\n${WHITE_R}----${RESET}\\n"
            echo -e "${WHITE_R}#${RESET} UniFi-LED has been detected!"
            if [[ "${script_option_skip}" != 'true' ]]; then read -rp $'\033[39m#\033[0m Would you like to apply the certificates to UniFi-LED? (Y/n) ' yes_no; fi
            case "$yes_no" in
               [Yy]*|"") uas_unifi_led;;
               [Nn]*) ;;
            esac
          fi
        fi;;
     [Nn]*) ;;
  esac
}

restore_previous_certs() {
  case "$yes_no" in
     [Yy]*)
        if [[ "${unifi_core_system}" == 'true' ]]; then
          # shellcheck disable=SC2012
          if [[ -d "${eus_dir}/unifi-os/config_backups/" ]]; then unifi_os_previous_config=$(ls -t "${eus_dir}/unifi-os/config_backups/" | awk '{print$1}' | head -n1); fi
          if [[ -n "${unifi_os_previous_config}" ]]; then
            echo -e "\\n${WHITE_R}----${RESET}\\n"
            echo -e "${WHITE_R}#${RESET} UniFi OS on your ${unifi_core_device} has been detected!"
            if [[ "${restore_original_state}" == 'true' ]]; then
              read -rp $'\033[39m#\033[0m Do you want to restore the certificates to original state? (Y/n) ' yes_no
            else
              read -rp $'\033[39m#\033[0m Do you want to restore the previous certificate configuration? (Y/n) ' yes_no
            fi
            case "$yes_no" in
               [Yy]*|"")
                  restore_done=yes
                  if [[ "${restore_original_state}" == 'true' ]]; then
                    echo -e "\\n${WHITE_R}#${RESET} Restoring UniFi OS certificates to original state..."
                    if [[ "${unifi_core_certificate_copy}" == 'true' ]]; then
                      if rm --force /data/unifi-core/config/unifi-core.key /data/unifi-core/config/unifi-core.crt &> /dev/null; then
                        echo -e "${GREEN}#${RESET} Successfully restored UniFi OS certificates to original state! \\n"
                        echo -e "${WHITE_R}#${RESET} Restarting UniFi OS..."
                        if systemctl restart unifi-core; then
                          echo -e "${GREEN}#${RESET} Successfully restarted UniFi OS! \\n"
                        else
                          abort_reason="Failed to restart UniFi OS."; abort
                        fi
                      fi
                    else
                      if [[ -f "${unifi_core_config_path}" ]]; then
                        if sed -i -e "/File created by EUS/d" -e "/ssl:/d" -e "/crt:/d" -e "/key:/d" "${unifi_core_config_path}" &>> "${eus_dir}/logs/restore.log"; then
                          if ! [[ -s "${unifi_core_config_path}" ]]; then rm --force "${unifi_core_config_path}" &> /dev/null; fi
                          echo -e "${GREEN}#${RESET} Successfully restored UniFi OS certificates to original state! \\n"
                          echo -e "${WHITE_R}#${RESET} Restarting UniFi OS..."
                          if systemctl restart unifi-core; then
                            echo -e "${GREEN}#${RESET} Successfully restarted UniFi OS! \\n"
                          else
                            abort_reason="Failed to restart UniFi OS."; abort
                          fi
                        else
                          abort_reason="Failed to restore UniFi OS certificates to original state."; abort
                        fi
                      else
                        echo -e "${YELLOW}#${RESET} UniFi OS is already in default state..."
                      fi
                    fi
                  else
                    echo -e "\\n${WHITE_R}#${RESET} Restoring \"${eus_dir}/unifi-os/config_backups/${unifi_os_previous_config}\"..."
                    if cp "${eus_dir}/unifi-os/config_backups/${unifi_os_previous_config}" "${unifi_core_config_path}" &>> "${eus_dir}/logs/restore.log"; then
                      echo -e "${GREEN}#${RESET} Successfully restored \"${eus_dir}/unifi-os/config_backups/${unifi_os_previous_config}\"! \\n"
                      echo -e "${WHITE_R}#${RESET} Restarting UniFi OS..."
                      if systemctl restart unifi-core; then
                        echo -e "${GREEN}#${RESET} Successfully restarted UniFi OS! \\n"
                      else
                        abort_reason="Failed to restart UniFi OS."; abort
                      fi
                    else
                      abort_reason="Failed to restore ${eus_dir}/unifi-os/config_backups/${unifi_os_previous_config}."; abort
                    fi
                  fi;;
               [Nn]*) ;;
            esac
          else
            if [[ -f "${unifi_core_config_path}" ]]; then
              echo -e "\\n${WHITE_R}----${RESET}\\n"
              echo -e "${WHITE_R}#${RESET} UniFi OS on your ${unifi_core_device} has been detected!"
              read -rp $'\033[39m#\033[0m Do you want to restore to the default UniFi OS certificates? (Y/n) ' yes_no
              case "$yes_no" in
                 [Yy]*|"")
                    restore_done=yes
                    echo -e "\\n${WHITE_R}#${RESET} Restoring to default UniFi OS certificates..."
                    if [[ "${unifi_core_certificate_copy}" == 'true' ]]; then
                      if rm --force /data/unifi-core/config/unifi-core.key /data/unifi-core/config/unifi-core.crt &> /dev/null; then
                        echo -e "${GREEN}#${RESET} Successfully restored UniFi OS certificates to original state! \\n"
                        echo -e "${WHITE_R}#${RESET} Restarting UniFi OS..."
                        if systemctl restart unifi-core; then
                          echo -e "${GREEN}#${RESET} Successfully restarted UniFi OS! \\n"
                        else
                          abort_reason="Failed to restart UniFi OS."; abort
                        fi
                      fi
                    else
                      if rm --force "${unifi_core_config_path}" &>> "${eus_dir}/logs/restore.log"; then
                        echo -e "${GREEN}#${RESET} Successfully restored default UniFi OS certificates! \\n"
                        echo -e "${WHITE_R}#${RESET} Restarting UniFi OS..."
                        if systemctl restart unifi-core; then
                          echo -e "${GREEN}#${RESET} Successfully restarted UniFi OS! \\n"
                        else
                          abort_reason="Failed to restart UniFi OS."; abort
                        fi
                      else
                        abort_reason="Failed to restore default UniFi OS certificates."; abort
                      fi
                    fi;;
                 [Nn]*) ;;
              esac
            fi
          fi
          # shellcheck disable=SC2012
          if [[ -d "/data/eus_certificates/raddb/" ]]; then radius_previous_crt=$(ls -t /data/eus_certificates/raddb/ | awk '{print$1}' | grep ".*server_.*.pem" | head -n1); radius_previous_key=$(ls -t /data/eus_certificates/raddb/ | awk '{print$1}' | grep ".*server-key_.*.pem" | head -n1); fi
          if [[ -n "${radius_previous_key}" && -n "${radius_previous_crt}" ]]; then
            echo -e "\\n${WHITE_R}----${RESET}\\n"
            echo -e "${WHITE_R}#${RESET} You seem to have replaced the default RADIUS certificates on your ${unifi_core_device}!"
            if [[ "${restore_original_state}" == 'true' ]]; then
              read -rp $'\033[39m#\033[0m Do you want to restore to the default certificates? (Y/n) ' yes_no
            else
              read -rp $'\033[39m#\033[0m Do you want to restore the previous RADIUS certificates? (Y/n) ' yes_no
            fi
            case "$yes_no" in
               [Yy]*|"")
                    restore_done=yes
                    if [[ "${restore_original_state}" == 'true' ]]; then
                      echo -e "\\n${WHITE_R}#${RESET} Restoring to the default RADIUS certificates..."
                      if [[ "${debbox}" == 'true' ]]; then
                        if rm "/data/udapi-config/raddb/certs/server.pem" &>> "${eus_dir}/logs/restore.log" && rm "/data/udapi-config/raddb/certs/server-key.pem" &>> "${eus_dir}/logs/restore.log"; then radius_certs_remove_success=true; fi
                      else
                        if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -ql root 127.0.0.1 "rm /mnt/data/udapi-config/raddb/certs/server.pem" &>> "${eus_dir}/logs/restore.log" && ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -ql root 127.0.0.1 "rm /mnt/data/udapi-config/raddb/certs/server-key.pem" &>> "${eus_dir}/logs/restore.log"; then radius_certs_remove_success=true; fi
                      fi
                      if [[ "${radius_certs_remove_success}" == 'true' ]]; then
                        echo -e "${GREEN}#${RESET} Successfully restored to the default RADIUS certificates! \\n"
                        echo -e "${WHITE_R}#${RESET} Restarting udapi-server..."
                        if [[ "${debbox}" == 'true' ]]; then
                          if systemctl restart udapi-server &>> "${eus_dir}/logs/restore.log"; then udapi_restart_success=true; fi
                        else
                          if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -ql root 127.0.0.1 "/etc/init.d/S45ubios-udapi-server restart" &>> "${eus_dir}/logs/restore.log"; then udapi_restart_success=true; fi
                        fi
                        if [[ "${udapi_restart_success}" == 'true' ]]; then echo -e "${GREEN}#${RESET} Successfully restarted udapi-server! \\n"; else echo -e "${RED}#${RESET} Failed to restart udapi-server... \\n${RED}#${RESET} Please reboot your UDM ASAP!\\n"; abort_reason="Failed to restart udapi-server."; abort; fi
                      else
                        abort_reason="Failed to restore to the default RADIUS certificates."; abort
                      fi
                    else
                      echo -e "\\n${WHITE_R}#${RESET} Restoring \"/data/eus_certificates/raddb/${radius_previous_crt}\" and \"/data/eus_certificates/raddb/${radius_previous_key}\"..."
                      if [[ "${debbox}" == 'true' ]]; then
                        if cp "/data/eus_certificates/raddb/${radius_previous_crt}" "/data/udapi-config/raddb/certs/server.pem" &>> "${eus_dir}/logs/restore.log" && cp "/data/eus_certificates/raddb/${radius_previous_key}" "/mnt/data/udapi-config/raddb/certs/server-key.pem" &>> "${eus_dir}/logs/restore.log"; then radius_certs_restore_success=true; fi
                      else
                        if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -ql root 127.0.0.1 "cp /data/eus_certificates/raddb/${radius_previous_crt} /mnt/data/udapi-config/raddb/certs/server.pem" &>> "${eus_dir}/logs/restore.log" && ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -ql root 127.0.0.1 "cp /data/eus_certificates/raddb/${radius_previous_key} /mnt/data/udapi-config/raddb/certs/server-key.pem" &>> "${eus_dir}/logs/restore.log"; then radius_certs_restore_success=true; fi
                      fi
                      if [[ "${radius_certs_restore_success}" == 'true' ]]; then
                        echo -e "${GREEN}#${RESET} Successfully restored \"/data/eus_certificates/raddb/${radius_previous_crt}\" and \"/data/eus_certificates/raddb/${radius_previous_key}\"! \\n"
                        echo -e "${WHITE_R}#${RESET} Restarting udapi-server..."
                        if [[ "${debbox}" == 'true' ]]; then
                          if systemctl restart udapi-server &>> "${eus_dir}/logs/restore.log"; then udapi_restart_success=true; fi
                        else
                          if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -ql root 127.0.0.1 "/etc/init.d/S45ubios-udapi-server restart" &>> "${eus_dir}/logs/restore.log"; then udapi_restart_success=true; fi
                        fi
                        if [[ "${udapi_restart_success}" == 'true' ]]; then echo -e "${GREEN}#${RESET} Successfully restarted udapi-server! \\n"; else echo -e "${RED}#${RESET} Failed to restart udapi-server... \\n${RED}#${RESET} Please reboot your UDM ASAP!\\n"; abort_reason="Failed to restart udapi-server."; abort; fi
                      else
                        abort_reason="Failed to restore /data/eus_certificates/raddb/${radius_previous_crt} and /data/eus_certificates/raddb/${radius_previous_key}."; abort
                      fi
                    fi;;
               [Nn]*) ;;
            esac
          fi
        fi
        if dpkg -l unifi 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
          # shellcheck disable=SC2012
          if [[ -d "${eus_dir}/network/keystore_backups/" ]]; then unifi_network_previous_keystore=$(ls -t "${eus_dir}/network/keystore_backups/" | awk '{print$1}' | head -n1); fi
          if [[ -n "${unifi_network_previous_keystore}" ]]; then
            echo -e "\\n${WHITE_R}----${RESET}\\n"
            echo -e "${WHITE_R}#${RESET} UniFi Network Application has been detected!"
            if [[ "${restore_original_state}" == 'true' ]]; then
              read -rp $'\033[39m#\033[0m Do you want to restore to default keystore? (Y/n) ' yes_no
            else
              read -rp $'\033[39m#\033[0m Do you want to restore the previous keystore? (Y/n) ' yes_no
            fi
            case "$yes_no" in
               [Yy]*|"")
                  restore_done=yes
                  if [[ "${restore_original_state}" == 'true' ]]; then
                    echo -e "\\n${WHITE_R}#${RESET} Restoring UniFi Network Application to default keystore..."
                    if rm --force /usr/lib/unifi/data/keystore &>> "${eus_dir}/logs/restore.log"; then
                      echo -e "${GREEN}#${RESET} Successfully restored UniFi Network Application to default keystore! \\n"
                      echo -e "${WHITE_R}#${RESET} Restarting the UniFi Network Application..."
                      if systemctl restart unifi &>> "${eus_dir}/logs/easy-encrypt-service-restart.log"; then
                        echo -e "${GREEN}#${RESET} Successfully restarted the UniFi Network Application! \\n"
                      else
                        abort_reason="Failed to restart the UniFi Network Application."; abort
                      fi
                    else
                      abort_reason="Failed to restore UniFi Network Application to default keystore"; abort
                    fi
                  else
                    echo -e "\\n${WHITE_R}#${RESET} Restoring \"${eus_dir}/network/keystore_backups/${unifi_network_previous_keystore}\"..."
                    if cp "${eus_dir}/network/keystore_backups/${unifi_network_previous_keystore}" /usr/lib/unifi/data/keystore &>> "${eus_dir}/logs/restore.log"; then
                      echo -e "${GREEN}#${RESET} Successfully restored \"${eus_dir}/network/keystore_backups/${unifi_network_previous_keystore}\"! \\n"
                      echo -e "${WHITE_R}#${RESET} Restarting the UniFi Network Application..."
                      if systemctl restart unifi &>> "${eus_dir}/logs/easy-encrypt-service-restart.log"; then
                        echo -e "${GREEN}#${RESET} Successfully restarted the UniFi Network Application! \\n"
                      else
                        abort_reason="Failed to restart the UniFi Network Application."; abort
                      fi
                    else
                      abort_reason="Failed to restore ${eus_dir}/network/keystore_backups/${unifi_network_previous_keystore}."; abort
                    fi
                  fi;;
               [Nn]*) ;;
            esac
          fi
        fi
        if [[ "${is_cloudkey}" == 'true' ]] && [[ "${unifi_core_system}" != 'true' ]]; then
          # shellcheck disable=SC2012
          if [[ -d "${eus_dir}/cloudkey/certs_backups/" ]]; then cloudkey_previous_crt=$(ls -t "${eus_dir}/cloudkey/certs_backups/" | awk '{print$1}' | grep "cloudkey.crt" | head -n1); cloudkey_previous_key=$(ls -t "${eus_dir}/cloudkey/certs_backups/" | awk '{print$1}' | grep "cloudkey.key" | head -n1); fi
          if [[ -n "${cloudkey_previous_crt}" && -n "${cloudkey_previous_key}" ]]; then
            echo -e "\\n${WHITE_R}----${RESET}\\n"
            echo -e "${WHITE_R}#${RESET} You seem to have a Cloud Key!"
            if [[ "${restore_original_state}" == 'true' ]]; then
              read -rp $'\033[39m#\033[0m Do you want to restore to the default certificates? (Y/n) ' yes_no
            else
              read -rp $'\033[39m#\033[0m Do you want to restore the previous SSL certificates? (Y/n) ' yes_no
            fi
            case "$yes_no" in
               [Yy]*|"")
                    restore_done=yes
                    if [[ "${restore_original_state}" == 'true' ]]; then
                      echo -e "\\n${WHITE_R}#${RESET} Restoring Cloudkey Web Interface to default certificates..."
                      if rm --force /etc/ssl/private/cloudkey.crt &>> "${eus_dir}/logs/restore.log" && rm --force /etc/ssl/private/cloudkey.key &>> "${eus_dir}/logs/restore.log" && rm --force /etc/ssl/private/unifi.keystore.jks &>> "${eus_dir}/logs/restore.log"; then
                        echo -e "${GREEN}#${RESET} Successfully restored Cloudkey Web Interface to default certificates! \\n"
                        echo -e "${WHITE_R}#${RESET} Restarting the Cloudkey Web Interface..."
                        if systemctl restart ubnt-unifi-setup nginx &>> "${eus_dir}/logs/easy-encrypt-service-restart.log"; then
                          echo -e "${GREEN}#${RESET} Successfully restarted Cloudkey Web Interface! \\n"
                        else
                          abort_reason="Failed to restart the Cloudkey Web Interface."; abort
                        fi
                        if dpkg -l unifi-protect 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
                          unifi_protect_status=$(systemctl status unifi-protect | grep -i 'Active:' | awk '{print $2}')
                          if [[ "${unifi_protect_status}" == 'active' ]]; then
                            echo -e "${WHITE_R}#${RESET} Restarting UniFi Protect..."
                             if systemctl restart unifi-protect &>> "${eus_dir}/logs/easy-encrypt-service-restart.log"; then
                              echo -e "${GREEN}#${RESET} Successfully restarted UniFi Protect! \\n"
                            else
                              abort_reason="Failed to restart UniFi Protect."; abort
                            fi
                          fi
                        fi
                        if dpkg -l unifi-led 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
                          unifi_protect_status=$(systemctl status unifi-led | grep -i 'Active:' | awk '{print $2}')
                          if [[ "${unifi_protect_status}" == 'active' ]]; then
                            echo -e "${WHITE_R}#${RESET} Restarting UniFi LED..."
                            if systemctl restart unifi-led &>> "${eus_dir}/logs/easy-encrypt-service-restart.log"; then
                              echo -e "${GREEN}#${RESET} Successfully restarted UniFi LED! \\n"
                            else
                              abort_reason="Failed to restart UniFi LED."; abort
                            fi
                          fi
                        fi
                      else
                        abort_reason="Failed to restore Cloudkey Web Interface to default certificates."; abort
                      fi
                    else
                      echo -e "\\n${WHITE_R}#${RESET} Restoring \"${eus_dir}/cloudkey/certs_backups/${cloudkey_previous_crt}\" and \"${eus_dir}/cloudkey/certs_backups/${cloudkey_previous_key}\"..."
                      if cp "${eus_dir}/cloudkey/certs_backups/${cloudkey_previous_crt}" /etc/ssl/private/cloudkey.crt &>> "${eus_dir}/logs/restore.log" && cp "${eus_dir}/cloudkey/certs_backups/${cloudkey_previous_key}" /etc/ssl/private/cloudkey.key &>> "${eus_dir}/logs/restore.log"; then
                        echo -e "${GREEN}#${RESET} Successfully restored \"${eus_dir}/cloudkey/certs_backups/${cloudkey_previous_crt}\" and \"${eus_dir}/cloudkey/certs_backups/${cloudkey_previous_key}\"! \\n"
                        echo -e "${WHITE_R}#${RESET} Restarting the Cloudkey Web Interface..."
                        if systemctl restart nginx &>> "${eus_dir}/logs/easy-encrypt-service-restart.log"; then
                          echo -e "${GREEN}#${RESET} Successfully restarted Cloudkey Web Interface! \\n"
                        else
                          abort_reason="Failed to restart the Cloudkey Web Interface."; abort
                        fi
                        if dpkg -l unifi-protect 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
                          unifi_protect_status=$(systemctl status unifi-protect | grep -i 'Active:' | awk '{print $2}')
                          if [[ "${unifi_protect_status}" == 'active' ]]; then
                            echo -e "${WHITE_R}#${RESET} Restarting UniFi Protect..."
                             if systemctl restart unifi-protect &>> "${eus_dir}/logs/easy-encrypt-service-restart.log"; then
                              echo -e "${GREEN}#${RESET} Successfully restarted UniFi Protect! \\n"
                            else
                              abort_reason="Failed to restart UniFi Protect."; abort
                            fi
                          fi
                        fi
                        if dpkg -l unifi-led 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
                          unifi_protect_status=$(systemctl status unifi-led | grep -i 'Active:' | awk '{print $2}')
                          if [[ "${unifi_protect_status}" == 'active' ]]; then
                            echo -e "${WHITE_R}#${RESET} Restarting UniFi LED..."
                            if systemctl restart unifi-led &>> "${eus_dir}/logs/easy-encrypt-service-restart.log"; then
                              echo -e "${GREEN}#${RESET} Successfully restarted UniFi LED! \\n"
                            else
                              abort_reason="Failed to restart UniFi LED."; abort
                            fi
                          fi
                        fi
                      else
                        abort_reason="Failed to restore ${eus_dir}/cloudkey/certs_backups/${cloudkey_previous_crt} and ${eus_dir}/cloudkey/certs_backups/${cloudkey_previous_key}."; abort
                      fi
                    fi;;
               [Nn]*) ;;
            esac
            if dpkg -l unifi-talk 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi" && [[ "${unifi_core_system}" != 'true' && "${restore_original_state}" != 'true' ]]; then
              # shellcheck disable=SC2012
              if [[ -d "${eus_dir}/talk/certs_backups/" ]]; then cloudkey_talk_previous_server_pem=$(ls -t "${eus_dir}/talk/certs_backups/" | awk '{print$1}' | grep "server.pem" | head -n1); fi
              if [[ -n "${cloudkey_talk_previous_server_pem}" ]]; then
                echo -e "\\n${WHITE_R}----${RESET}\\n"
                echo -e "${WHITE_R}#${RESET} UniFi-Talk has been detected!"
                read -rp $'\033[39m#\033[0m Do you want to restore the previous SSL certificate? (Y/n) ' yes_no
                case "$yes_no" in
                   [Yy]*|"")
                      restore_done=yes
                      echo -e "\\n${WHITE_R}#${RESET} Restoring \"${eus_dir}/talk/certs_backups/${cloudkey_talk_previous_server_pem}\"..."
                      if cp "${eus_dir}/talk/certs_backups/${cloudkey_talk_previous_server_pem}" /usr/share/unifi-talk/app/certs/server.pem &>> "${eus_dir}/logs/restore.log"; then
                        echo -e "${GREEN}#${RESET} Successfully restored \"${eus_dir}/talk/certs_backups/${cloudkey_talk_previous_server_pem}\"! \\n"
                        echo -e "${WHITE_R}#${RESET} Restarting UniFi Talk..."
                        if systemctl restart unifi-talk &>> "${eus_dir}/logs/easy-encrypt-service-restart.log"; then
                          echo -e "${GREEN}#${RESET} Successfully restarted UniFi Talk! \\n"
                        else
                          abort_reason="Failed to restart the UniFi service."; abort
                        fi
                      else
                        abort_reason="Failed to restore ${eus_dir}/talk/certs_backups/${cloudkey_talk_previous_server_pem}."; abort
                      fi;;
                   [Nn]*) ;;
                esac
              fi
            fi
          fi
        fi
        if dpkg -l | grep -iq "\\bUAS\\b\\|UniFi Application Server" && [[ "${unifi_core_system}" != 'true' && "${restore_original_state}" != 'true' ]]; then
          # shellcheck disable=SC2012
          if [[ -d "${eus_dir}/uas/certs_backups/" ]]; then uas_previous_crt=$(ls -t "${eus_dir}/uas/certs_backups/" | awk '{print$1}' | grep "uas.crt" | head -n1); uas_previous_key=$(ls -t "${eus_dir}/uas/certs_backups/" | awk '{print$1}' | grep "uas.key" | head -n1); fi
          if [[ -n "${uas_previous_crt}" && -n "${uas_previous_key}" ]]; then
            echo -e "\\n${WHITE_R}----${RESET}\\n"
            echo -e "${WHITE_R}#${RESET} You seem to have a UniFi Application Server!"
            read -rp $'\033[39m#\033[0m Do you want to restore the previous SSL certificates? (Y/n) ' yes_no
            case "$yes_no" in
               [Yy]*|"")
                  restore_done=yes
                  echo -e "\\n${WHITE_R}#${RESET} Restoring \"${eus_dir}/uas/certs_backups/${uas_previous_crt}\" and \"${eus_dir}/uas/certs_backups/${uas_previous_key}\"..."
                  if cp "${eus_dir}/uas/certs_backups/${uas_previous_crt}" /etc/uas/uas.crt &>> "${eus_dir}/logs/restore.log" && cp "${eus_dir}/uas/certs_backups/${uas_previous_key}" /etc/uas/uas.key &>> "${eus_dir}/logs/restore.log"; then
                    echo -e "${GREEN}#${RESET} Successfully restored \"${eus_dir}/uas/certs_backups/${uas_previous_crt}\" and \"${eus_dir}/uas/certs_backups/${uas_previous_key}\"! \\n"
                    echo -e "${WHITE_R}#${RESET} Restarting the UAS Web Interface..."
                    if systemctl restart uas &>> "${eus_dir}/logs/easy-encrypt-service-restart.log"; then
                      echo -e "${GREEN}#${RESET} Successfully restarted UAS Web Interface! \\n"
                    else
                      abort_reason="Failed to restart the UAS Web Interface."; abort
                    fi
                  else
                    abort_reason="Failed to restore ${eus_dir}/uas/certs_backups/${uas_previous_crt} and ${eus_dir}/uas/certs_backups/${uas_previous_key}."; abort
                  fi;;
               [Nn]*) ;;
            esac
            if dpkg -l uas-led 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi" && [[ "${unifi_core_system}" != 'true' ]]; then
              # shellcheck disable=SC2012
              if [[ -d "${eus_dir}/eot/certs_backups/" ]]; then uas_led_previous_server_pem=$(ls -t "${eus_dir}/eot/certs_backups/" | awk '{print$1}' | grep "server.pem" | head -n1); fi
              if [[ -n "${uas_led_previous_server_pem}" ]]; then
                if dpkg -l | awk '{print $2}' | grep -iq "^docker.io\\|^docker-ce"; then
                  if docker ps -a | grep -iq 'ubnt/eot'; then
                    echo -e "\\n${WHITE_R}----${RESET}\\n"
                    echo -e "${WHITE_R}#${RESET} UniFi-LED has been detected!"
                    read -rp $'\033[39m#\033[0m Do you want to restore the previous SSL certificates? (Y/n) ' yes_no
                    case "$yes_no" in
                        [Yy]*|"")
                           restore_done=yes
                           eot_container=$(docker ps -a | grep -i "ubnt/eot" | awk '{print $1}')
                           eot_container_name="ueot"
                           if [[ -n "${eot_container}" ]]; then
                             echo -e "\\n${WHITE_R}#${RESET} Restoring \"${eus_dir}/eot/certs_backups/${uas_led_previous_server_pem}\"..."
                             if docker cp "${eus_dir}/eot/certs_backups/${uas_led_previous_server_pem}" "${eot_container}:/app/certs/server.pem" &>> "${eus_dir}/logs/restore.log"; then
                               echo -e "${GREEN}#${RESET} Successfully restored \"${eus_dir}/eot/certs_backups/${uas_led_previous_server_pem}\"! \\n"
                               echo -e "${WHITE_R}#${RESET} Restarting the UniFi LED container..."
                               if docker restart "${eot_container_name}" &>> "${eus_dir}/eot/ueot_container_restart"; then
                                 echo -e "${GREEN}#${RESET} Successfully restarted the UniFi LED container! \\n"
                               else
                                 abort_reason="Failed to restart the UniFi LED container."; abort
                               fi
                             else
                               abort_reason="Failed to restore ${eus_dir}/eot/certs_backups/${uas_led_previous_server_pem}."; abort
                             fi
                           else
                             abort_reason="Couldn't find UniFi LED container."; abort
                           fi;;
                        [Nn]*) ;;
                    esac
                  fi
                fi
              fi
            fi
          fi
        fi
        if dpkg -l unifi-video 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi" && [[ "${unifi_core_system}" != 'true' ]]; then
          # shellcheck disable=SC2012
          if [[ -d "${eus_dir}/video/keystore_backups/" ]]; then unifi_video_previous_cert=$(ls -t "${eus_dir}/video/keystore_backups/" | awk '{print$1}' | grep "keystore" | head -n1); unifi_video_previous_key=$(ls -t "${eus_dir}/video/keystore_backups/" | awk '{print$1}' | grep "ufv-truststore" | head -n1); fi
          if [[ -n "${unifi_video_previous_cert}" && -n "${unifi_video_previous_key}" && "${restore_original_state}" != 'true' ]]; then
            echo -e "\\n${WHITE_R}----${RESET}\\n"
            echo -e "${WHITE_R}#${RESET} UniFi-Video has been detected!"
            read -rp $'\033[39m#\033[0m Do you want to restore the previous SSL certificates? (Y/n) ' yes_no
            case "$yes_no" in
               [Yy]*|"")
                  restore_done=yes
                  echo -e "\\n${WHITE_R}#${RESET} Restoring \"${eus_dir}/video/keystore_backups/${unifi_video_previous_cert}\" and \"${eus_dir}/video/keystore_backups/${unifi_video_previous_key}\"..."
                  if cp "${eus_dir}/video/keystore_backups/${unifi_video_previous_cert}" /usr/lib/unifi-video/data/certificates/ufv-server.cert.der &>> "${eus_dir}/logs/restore.log" && cp "${eus_dir}/video/keystore_backups/${unifi_video_previous_key}" /usr/lib/unifi-video/data/certificates/ufv-server.key.der &>> "${eus_dir}/logs/restore.log"; then
                    echo -e "${GREEN}#${RESET} Successfully restored \"${eus_dir}/video/keystore_backups/${unifi_video_previous_cert}\" and \"${eus_dir}/video/keystore_backups/${unifi_video_previous_key}\"! \\n"
                    echo -e "${WHITE_R}#${RESET} Restarting UniFi video..."
                    if systemctl restart uas &>> "${eus_dir}/logs/easy-encrypt-service-restart.log"; then
                      echo -e "${GREEN}#${RESET} Successfully restarted UniFi video! \\n"
                    else
                      abort_reason="Failed to restart UniFi video."; abort
                    fi
                  else
                    abort_reason="Failed to restore ${eus_dir}/video/keystore_backups/${unifi_video_previous_cert} and ${eus_dir}/video/keystore_backups/${unifi_video_previous_key}."; abort
                  fi;;
               [Nn]*) ;;
            esac
          else
            if grep -iq "^ufv.custom.certs.enable=true" /usr/lib/unifi-video/data/system.properties; then
              echo -e "\\n${WHITE_R}----${RESET}\\n"
              echo -e "${WHITE_R}#${RESET} UniFi-Video has been detected!"
              read -rp $'\033[39m#\033[0m Do you want to restore to the default SSL certificates? (Y/n) ' yes_no
              case "$yes_no" in
                 [Yy]*|"")
                    restore_done=yes
                    echo -e "\\n${WHITE_R}#${RESET} Restoring to default UniFi Video certificates..."
                    if sed -i "s/ufv.custom.certs.enable=true/ufv.custom.certs.enable=false/g" /usr/lib/unifi-video/data/system.properties &>> "${eus_dir}/logs/restore.log"; then
                      echo -e "${GREEN}#${RESET} Successfully set custom certificates for UniFi Video to false! \\n"
                      echo -e "${WHITE_R}#${RESET} Restarting UniFi Video..."
                      if systemctl restart unifi-video &>> "${eus_dir}/logs/easy-encrypt-service-restart.log"; then
                        echo -e "${GREEN}#${RESET} Successfully restarted UniFi Video! \\n"
                      else
                        abort_reason="Failed to restart UniFi Video."; abort
                      fi
                    else
                      abort_reason="Failed to change custom certificate value for UniFi Video."; abort
                    fi;;
                 [Nn]*) ;;
              esac
            fi
          fi
        fi
        if dpkg -l | awk '{print $2}' | grep -iq "^docker.io\\|^docker-ce" && [[ "${unifi_core_system}" != 'true' && "${restore_original_state}" != 'true' ]]; then
          # shellcheck disable=SC2012
          if [[ -d "${eus_dir}/eot/certs_backups/" ]]; then uas_led_previous_server_pem=$(ls -t "${eus_dir}/eot/certs_backups/" | awk '{print$1}' | grep "server.pem" | head -n1); fi
          if [[ -n "${uas_led_previous_server_pem}" ]]; then
            if dpkg -l | awk '{print $2}' | grep -iq "^docker.io\\|^docker-ce"; then
              if docker ps -a | grep -iq 'ubnt/eot'; then
                echo -e "\\n${WHITE_R}----${RESET}\\n"
                echo -e "${WHITE_R}#${RESET} UniFi-LED has been detected!"
                read -rp $'\033[39m#\033[0m Do you want to restore the previous SSL certificates? (Y/n) ' yes_no
                case "$yes_no" in
                    [Yy]*|"")
                       restore_done=yes
                       eot_container=$(docker ps -a | grep -i "ubnt/eot" | awk '{print $1}')
                       eot_container_name="ueot"
                       if [[ -n "${eot_container}" ]]; then
                         echo -e "\\n${WHITE_R}#${RESET} Restoring \"${eus_dir}/eot/certs_backups/${uas_led_previous_server_pem}\"..."
                         if docker cp "${eus_dir}/eot/certs_backups/${uas_led_previous_server_pem}" "${eot_container}:/app/certs/server.pem" &>> "${eus_dir}/logs/restore.log"; then
                           echo -e "${GREEN}#${RESET} Successfully restored \"${eus_dir}/eot/certs_backups/${uas_led_previous_server_pem}\"! \\n"
                           echo -e "${WHITE_R}#${RESET} Restarting the UniFi LED container..."
                           if docker restart "${eot_container_name}" &>> "${eus_dir}/eot/ueot_container_restart"; then
                             echo -e "${GREEN}#${RESET} Successfully restarted the UniFi LED container! \\n"
                           else
                             abort_reason="Failed to restart the UniFi LED container."; abort
                           fi
                         else
                           abort_reason="Failed to restore ${eus_dir}/eot/certs_backups/${uas_led_previous_server_pem}."; abort
                         fi
                       else
                         abort_reason="Couldn't find UniFi LED container."; abort
                       fi;;
                    [Nn]*) ;;
                esac
              fi
            fi
          fi
        fi;;
     [Nn]*|"")
        header
        echo -e "${WHITE_R}#${RESET} Canceling restore certificates... \\n"
        author
        exit 0;;
  esac
  if [[ "${restore_done}" != 'yes' ]]; then
    header
    echo -e "${YELLOW}#${RESET} Nothing has been restored... \\n"
    author
    exit 0
  else
    header
    echo -e "${GREEN}#${RESET} The script successfully restored your certificates/configs! \\n"
    author
    exit 0
  fi
}

unifi_core_certificate_migration() {
  if [[ "$(echo "${unifi_core_version}" | cut -d'.' -f1)" -lt '3' ]] || [[ "$(echo "${unifi_core_version}" | cut -d'.' -f1)" == '3' && "$(echo "${unifi_core_version}" | cut -d'.' -f2)" == '0' ]]; then
    if [[ -f /data/unifi-core/config.yaml ]]; then
      if ! [[ -d "${eus_dir}/cronjob/" ]]; then mkdir -p "${eus_dir}/cronjob/"; fi
      tee /etc/cron.d/eus_certificate_migration_30 &> /dev/null << EOF
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
@reboot root /bin/bash "${eus_dir}/cronjob/eus_certificate_migration_30.sh"
EOF
      # shellcheck disable=SC1117
      tee "${eus_dir}/cronjob/eus_certificate_migration_30.sh" &> /dev/null << EOF
#!/bin/bash
  unifi_core_version="\$(dpkg-query --showformat='\${Version}' --show unifi-core)"
  if [[ "\$(echo "\${unifi_core_version}" | cut -d'.' -f1)" -gt '3' ]] || [[ "\$(echo "\${unifi_core_version}" | cut -d'.' -f1)" == '3' && "\$(echo "\${unifi_core_version}" | cut -d'.' -f2)" -ge '1' ]]; then
    if ! [[ -d "/data/unifi-core/config/overrides/" ]]; then mkdir -p "/data/unifi-core/config/overrides/" &> /dev/null; fi
    if mv /data/unifi-core/config.yaml /data/unifi-core/config/overrides/local.yml; then
      echo -e "\$(date "+%Y/%m/%d %H:%M") | Successfully migrated the config file!" &>> "${eus_dir}/logs/certificate-migration.log"
      if rm --force "${eus_dir}/cronjob/eus_certificate_migration_30.sh"; then echo -e "\$(date "+%Y/%m/%d %H:%M") | Successfully removed the migration script!" &>> "${eus_dir}/logs/certificate-migration.log"; fi
      if rm --force /etc/cron.d/eus_certificate_migration_30; then echo -e "\$(date "+%Y/%m/%d %H:%M") | Successfully removed the migration script cronjob!" &>> "${eus_dir}/logs/certificate-migration.log"; fi
    else
      echo -e "\$(date "+%Y/%m/%d %H:%M") | Failed to migrate the config file..." &>> "${eus_dir}/logs/certificate-migration.log"
    fi
  fi
EOF
      chmod +x "${eus_dir}/cronjob/eus_certificate_migration_30.sh"
    fi
    migration_script="true"
  fi
  if [[ "$(echo "${unifi_core_version}" | cut -d'.' -f1)" -lt '3' ]] || [[ "$(echo "${unifi_core_version}" | cut -d'.' -f1)" == '3' && "$(echo "${unifi_core_version}" | cut -d'.' -f2)" -le '1' ]]; then
    if ! [[ -d "${eus_dir}/cronjob/" ]]; then mkdir -p "${eus_dir}/cronjob/"; fi
    tee /etc/cron.d/eus_certificate_migration_32 &> /dev/null << EOF
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
@reboot root /bin/bash "${eus_dir}/cronjob/eus_certificate_migration_32.sh"
EOF
    # shellcheck disable=SC1117
    tee "${eus_dir}/cronjob/eus_certificate_migration_32.sh" &> /dev/null << EOF
#!/bin/bash
  unifi_core_version="\$(dpkg-query --showformat='\${Version}' --show unifi-core)"
  if [[ "\$(echo "\${unifi_core_version}" | cut -d'.' -f1)" == '3' && "\$(echo "\${unifi_core_version}" | cut -d'.' -f2)" == '2' ]]; then
    if cp /data/eus_certificates/unifi-os.key /data/unifi-core/config/unifi-core.key; then certficiate_copy_success="true"; else certficiate_copy_success="false"; fi
    if cp /data/eus_certificates/unifi-os.crt /data/unifi-core/config/unifi-core.crt; then certficiate_copy_success="true"; else certficiate_copy_success="false"; fi
    if [[ "\${certficiate_copy_success}" == 'true' ]]; then
      echo -e "\$(date "+%Y/%m/%d %H:%M") | Successfully copied the certificate files!" &>> "${eus_dir}/logs/certificate-migration.log"
      if rm --force "${eus_dir}/cronjob/eus_certificate_migration_32.sh"; then echo -e "\$(date "+%Y/%m/%d %H:%M") | Successfully removed the UniFi OS 3.2 migration script!" &>> "${eus_dir}/logs/certificate-migration.log"; fi
      if rm --force /etc/cron.d/eus_certificate_migration_32; then echo -e "\$(date "+%Y/%m/%d %H:%M") | Successfully removed the UniFi OS 3.2 migration script cronjob!" &>> "${eus_dir}/logs/certificate-migration.log"; fi
    else
      echo -e "\$(date "+%Y/%m/%d %H:%M") | Failed to migrate certificates..." &>> "${eus_dir}/logs/certificate-migration.log"
    fi
  fi
EOF
    chmod +x "${eus_dir}/cronjob/eus_certificate_migration_32.sh"
    migration_script="true"
  fi
  if [[ "$(echo "${unifi_core_version}" | cut -d'.' -f1)" -le '4' ]]; then
    if [[ -f /data/unifi-core/config.yaml ]]; then
      if ! [[ -d "${eus_dir}/cronjob/" ]]; then mkdir -p "${eus_dir}/cronjob/"; fi
      tee /etc/cron.d/eus_certificate_migration_40 &> /dev/null << EOF
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
@reboot root /bin/bash "${eus_dir}/cronjob/eus_certificate_migration_40.sh"
EOF
      # shellcheck disable=SC1117
      tee "${eus_dir}/cronjob/eus_certificate_migration_40.sh" &> /dev/null << EOF
#!/bin/bash
  unifi_core_version="\$(dpkg-query --showformat='\${Version}' --show unifi-core)"
  if [[ "\$(echo "\${unifi_core_version}" | cut -d'.' -f1)" -ge '4' ]]; then
    if ! [[ -d "/data/unifi-core/config/overrides/" ]]; then mkdir -p "/data/unifi-core/config/overrides/" &> /dev/null; fi
    if [[ -e "/data/unifi-core/config.yaml" ]]; then
      if mv /data/unifi-core/config.yaml /data/unifi-core/config/overrides/local.yml; then
        echo -e "\$(date "+%Y/%m/%d %H:%M") | Successfully migrated the config file!" &>> "${eus_dir}/logs/certificate-migration.log"
        if rm --force "${eus_dir}/cronjob/eus_certificate_migration_40.sh"; then echo -e "\$(date "+%Y/%m/%d %H:%M") | Successfully removed the migration script!" &>> "${eus_dir}/logs/certificate-migration.log"; fi
        if rm --force /etc/cron.d/eus_certificate_migration_40; then echo -e "\$(date "+%Y/%m/%d %H:%M") | Successfully removed the migration script cronjob!" &>> "${eus_dir}/logs/certificate-migration.log"; fi
      else
        echo -e "\$(date "+%Y/%m/%d %H:%M") | Failed to migrate the config file..." &>> "${eus_dir}/logs/certificate-migration.log"
      fi
    fi
    if [[ "\$(md5sum /data/unifi-core/config/unifi-core.key | awk '{print\$1}')" == "\$(md5sum /data/eus_certificates/unifi-os.key | awk '{print\$1}')" ]]; then
      if rm --force /data/unifi-core/config/unifi-core.key; then echo -e "\$(date "+%Y/%m/%d %H:%M") | \"/data/unifi-core/config/unifi-core.key\" and \"/data/eus_certificates/unifi-os.key\" are identical, successfully removed \"/data/unifi-core/config/unifi-core.key\"!" &>> "${eus_dir}/logs/certificate-migration.log"; else certificate_removed_failed="true"; fi
    fi
    if [[ "\$(md5sum /data/unifi-core/config/unifi-core.crt | awk '{print\$1}')" == "\$(md5sum /data/eus_certificates/unifi-os.crt | awk '{print\$1}')" ]]; then
      if ! rm --force /data/unifi-core/config/unifi-core.crt; then echo -e "\$(date "+%Y/%m/%d %H:%M") | \"/data/unifi-core/config/unifi-core.crt\" and \"/data/eus_certificates/unifi-os.crt\" are identical, successfully removed \"/data/unifi-core/config/unifi-core.crt\"!" &>> "${eus_dir}/logs/certificate-migration.log"; else certificate_removed_failed="true"; fi
    fi
    if [[ "\${certificate_removed_failed}" != 'true' ]]; then
      if rm --force "${eus_dir}/cronjob/eus_certificate_migration_40.sh"; then echo -e "\$(date "+%Y/%m/%d %H:%M") | Successfully removed the migration script!" &>> "${eus_dir}/logs/certificate-migration.log"; fi
      if rm --force /etc/cron.d/eus_certificate_migration_40; then echo -e "\$(date "+%Y/%m/%d %H:%M") | Successfully removed the migration script cronjob!" &>> "${eus_dir}/logs/certificate-migration.log"; fi
    fi
  fi
EOF
      chmod +x "${eus_dir}/cronjob/eus_certificate_migration_40.sh"
    fi
    migration_script="true"
  fi
  if [[ "${migration_script}" != 'true' ]]; then
    if [[ -f /data/unifi-core/config.yaml ]] && ! [[ -f /data/unifi-core/config/overrides/local.yml ]]; then
      if ! [[ -d "/data/unifi-core/config/overrides/" ]]; then mkdir -p "/data/unifi-core/config/overrides/" &> /dev/null; fi
      if mv /data/unifi-core/config.yaml /data/unifi-core/config/overrides/local.yml; then
        echo -e "$(date "+%Y/%m/%d %H:%M") | Successfully migrated the config file!" &>> "${eus_dir}/logs/certificate-migration.log"
      fi
    elif [[ -f /data/unifi-core/config.yaml ]] && [[ -f /data/unifi-core/config/overrides/local.yml ]]; then
      if rm --force /data/unifi-core/config.yaml &> /dev/null; then
        echo -e "$(date "+%Y/%m/%d %H:%M") | Successfully deleted the old config file!" &>> "${eus_dir}/logs/certificate-migration.log"
      fi
    fi
  fi
}

if dpkg -l unifi-core 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
  if grep -sq unifi-native /mnt/.rofs/var/lib/dpkg/status; then unifi_native_system="true"; fi
  unifi_core_system=true
  if grep -ioq "udm" /usr/lib/version; then udm_device=true; fi
  if dpkg -l uid-agent 2> /dev/null | grep -iq "^ii\\|^hi"; then uid_agent=$(curl -s http://localhost:11081/api/controllers | jq '.[] | select(.name == "uid-agent").isConfigured'); fi
  if [[ -f /usr/lib/version ]]; then unifi_core_device_version=$(grep -ioE "v[0-9]{1,9}.[0-9]{1,9}.[0-9]{1,9}" /usr/lib/version | sed 's/v//g'); fi
  if [[ "$(echo "${unifi_core_device_version}" | cut -d'.' -f1)" == "1" ]]; then debbox="false"; else debbox="true"; fi
  if [[ -f /proc/ubnthal/system.info ]]; then if grep -iq "shortname" /proc/ubnthal/system.info; then unifi_core_device=$(grep "shortname" /proc/ubnthal/system.info | sed 's/shortname=//g'); fi; fi
  if [[ -f /etc/motd && -s /etc/motd && -z "${unifi_core_device}" ]]; then unifi_core_device=$(grep -io "welcome.*" /etc/motd | sed -e 's/Welcome //g' -e 's/to //g' -e 's/the //g' -e 's/!//g'); fi
  if [[ -f /usr/lib/version && -s /usr/lib/version && -z "${unifi_core_device}" ]]; then unifi_core_device=$(cut -d'.' -f1 /usr/lib/version); fi
  if [[ -z "${unifi_core_device}" ]]; then unifi_core_device='Unknown device'; fi
  unifi_core_version="$(dpkg-query --showformat='${Version}' --show unifi-core)"
  if [[ "$(echo "${unifi_core_version}" | cut -d'.' -f1)" -gt '3' ]] || [[ "$(echo "${unifi_core_version}" | cut -d'.' -f1)" == '3' && "$(echo "${unifi_core_version}" | cut -d'.' -f2)" -ge '1' ]]; then unifi_core_config_path="/data/unifi-core/config/overrides/local.yml"; else unifi_core_config_path="/data/unifi-core/config.yaml"; fi
  if [[ "$(echo "${unifi_core_version}" | cut -d'.' -f1)" == '3' && "$(echo "${unifi_core_version}" | cut -d'.' -f2)" == '2' && "$(echo "${unifi_core_version}" | cut -d'.' -f3)" -lt '155' ]]; then unifi_core_certificate_copy="true"; fi
  if ! [[ -d "$(dirname "${unifi_core_config_path}")" ]]; then mkdir -p "$(dirname "${unifi_core_config_path}")" &> /dev/null; fi
  if ! grep -ioq "NODE_CONFIG_DIR" /etc/default/unifi-core; then awk '/NODE_CONFIG_DIR/' /mnt/.rofs/etc/default/unifi-core &>> /etc/default/unifi-core; fi
fi

remove_old_post_pre_hook() {
  if [[ "$(find /etc/letsencrypt/renewal-hooks/post/ /etc/letsencrypt/renewal-hooks/pre/ -printf "%f\\n" | sed -e '/post/d' -e '/pre/d' -e "/EUS_${server_fqdn}.sh/d" | awk '!NF || !seen[$0]++' | grep -ioc "EUS.*.sh")" -ge "1" ]]; then
    if ! [[ -d /tmp/EUS/hook/ ]]; then mkdir -p /tmp/EUS/hook/ &> /dev/null; fi
    find /etc/letsencrypt/renewal-hooks/post/ /etc/letsencrypt/renewal-hooks/pre/ -printf "%f\\n" | sed -e '/post/d' -e '/pre/d' -e "/EUS_${server_fqdn}.sh/d" | awk '!NF || !seen[$0]++' | grep -io "EUS.*.sh" &> /tmp/EUS/hook/list
    header
    echo -e "${WHITE_R}#${RESET} You seem to have multiple post/pre hook scripts for multiple domains."
    echo -e "${WHITE_R}#${RESET} Having multiple post/pre hook scripts can result in older domain/certificates being used. \\n"
    echo -e "${WHITE_R}#${RESET} post/pre scripts:"
    while read -r script_file_name; do echo -e "${WHITE_R}-${RESET} \"${script_file_name}\""; done < /tmp/EUS/hook/list
    echo -e "\\n\\n${WHITE_R}#${RESET} What would you like to do with those scripts?\\n"
    echo -e " [   ${WHITE_R}1${RESET}   ]  |  Remove them"
    echo -e " [   ${WHITE_R}2${RESET}   ]  |  Let me choose which to remove"
    echo -e " [   ${WHITE_R}3${RESET}   ]  |  Do nothing\\n\\n"
    read -rp $'Your choice | \033[39m' choice
    case "$choice" in
        1*|"")
          echo -e "\\n${WHITE_R}----${RESET}\\n\\n${WHITE_R}#${RESET} Removing the post/pre hook scripts... \\n\\n${WHITE_R}----${RESET}\\n"
          while read -r script; do
            if [[ -f "/etc/letsencrypt/renewal-hooks/post/${script}" ]]; then
              echo -e "${WHITE_R}#${RESET} Removing \"/etc/letsencrypt/renewal-hooks/post/${script}\"..."
              if rm --force "/etc/letsencrypt/renewal-hooks/post/${script}"; then echo -e "${GREEN}#${RESET} Successfully removed \"/etc/letsencrypt/renewal-hooks/post/${script}\"! \\n"; else echo -e "${RED}#${RESET} Failed to remove \"/etc/letsencrypt/renewal-hooks/post/${script}\"... \\n"; fi
            elif [[ -f "/etc/letsencrypt/renewal-hooks/pre/${script}" ]]; then
              echo -e "${WHITE_R}#${RESET} Removing \"/etc/letsencrypt/renewal-hooks/pre/${script}\"..."
              if rm --force "/etc/letsencrypt/renewal-hooks/pre/${script}"; then echo -e "${GREEN}#${RESET} Successfully removed \"/etc/letsencrypt/renewal-hooks/pre/${script}\"! \\n"; else echo -e "${RED}#${RESET} Failed to remove \"/etc/letsencrypt/renewal-hooks/pre/${script}\"... \\n"; fi
            fi
          done < /tmp/EUS/hook/list;;
        2*)
          header
          echo -e "${WHITE_R}#${RESET} Please enter the name of the script ( FQDN ) that you want to remove below.\\n${WHITE_R}#${RESET} That is without \"EUS_\" and \".sh\"\\n\\n${WHITE_R}#${RESET} Examples:"
          while read -r script_file_name; do script_file_name=$(echo "${script_file_name}" | sed -e 's/EUS_//g' -e 's/.sh//g'); echo -e "${WHITE_R}-${RESET} \"${script_file_name}\""; done < /tmp/EUS/hook/list
          echo ""
          read -rp $'Script Name | \033[39m' script_file_name_remove
          echo -e "\\n${WHITE_R}----${RESET}\\n"
		  read -rp $'\033[39m#\033[0m You want to remove script: '"EUS_${script_file_name_remove}.sh"', is that correct? (Y/n) ' yes_no
          case "$yes_no" in
             [Yy]*|"") 
                if grep -iq "EUS_${script_file_name_remove}.sh" /tmp/EUS/hook/list; then
                  echo -e "\\n${WHITE_R}----${RESET}\\n\\n${WHITE_R}#${RESET} Removing post/pre hook script \"EUS_${script_file_name_remove}.sh\"... \\n\\n${WHITE_R}----${RESET}\\n"
                  while read -r script; do
                    if [[ -f "/etc/letsencrypt/renewal-hooks/post/EUS_${script_file_name_remove}.sh" ]]; then
                      echo -e "${WHITE_R}#${RESET} Removing \"/etc/letsencrypt/renewal-hooks/post/EUS_${script_file_name_remove}.sh\"..."
                      if rm --force "/etc/letsencrypt/renewal-hooks/post/EUS_${script_file_name_remove}.sh"; then echo -e "${GREEN}#${RESET} Successfully removed \"/etc/letsencrypt/renewal-hooks/post/EUS_${script_file_name_remove}.sh\"! \\n"; else echo -e "${RED}#${RESET} Failed to remove \"/etc/letsencrypt/renewal-hooks/post/EUS_${script_file_name_remove}.sh\"... \\n"; fi
                    elif [[ -f "/etc/letsencrypt/renewal-hooks/pre/EUS_${script_file_name_remove}.sh" ]]; then
                      echo -e "${WHITE_R}#${RESET} Removing \"/etc/letsencrypt/renewal-hooks/pre/EUS_${script_file_name_remove}.sh\"..."
                      if rm --force "/etc/letsencrypt/renewal-hooks/pre/EUS_${script_file_name_remove}.sh"; then echo -e "${GREEN}#${RESET} Successfully removed \"/etc/letsencrypt/renewal-hooks/pre/EUS_${script_file_name_remove}.sh\"! \\n"; else echo -e "${RED}#${RESET} Failed to remove \"/etc/letsencrypt/renewal-hooks/pre/EUS_${script_file_name_remove}.sh\"... \\n"; fi
                    else
                      echo -e "${YELLOW}#${RESET} Script \"EUS_${script_file_name_remove}.sh\" does not exist..."
                    fi
                  done < /tmp/EUS/hook/list
                else
                  echo -e "${YELLOW}#${RESET} \"EUS_${script_file_name_remove}.sh\" is not in the list of post/pre looks that can be removed..."
                fi;;
             [Nn]*) ;;
          esac
          if [[ "$(find /etc/letsencrypt/renewal-hooks/post/ /etc/letsencrypt/renewal-hooks/pre/ -printf "%f\\n" | sed -e '/post/d' -e '/pre/d' -e "/EUS_${server_fqdn}.sh/d" | awk '!NF || !seen[$0]++' | grep -ioc "EUS.*.sh")" -ge "1" ]]; then
            read -rp $'\033[39m#\033[0m Do you want to remove more post/pre hook scripts? (Y/n) ' yes_no
            case "$yes_no" in
               [Yy]*|"") remove_old_post_pre_hook;;
               [Nn]*) ;;
            esac
          fi;;
        3*) return;;
    esac
    sleep 3
  fi
}

lets_encrypt() {
  if [[ "${script_option_skip}" != 'true' ]]; then header; echo -e "${WHITE_R}#${RESET} Heck yeah! I want to secure my setup with a SSL certificate!"; sleep 3; fi
  if [[ "${script_option_fqdn}" == 'true' ]]; then fqdn_option; fi
  # shellcheck disable=SC2012
  ls -t "${eus_dir}/logs/lets_encrypt_*.log" 2> /dev/null | awk 'NR>2' | xargs rm -f &> /dev/null
  if [[ "${os_codename}" =~ (wheezy|jessie) || "${downloaded_certbot}" == 'true' ]]; then certbot_auto_install_run; fi
  if [[ "${script_option_skip}" != 'true' ]]; then timezone; fi
  if [[ "${script_option_skip}" != 'true' ]]; then delete_certs_question; fi
  if [[ "${script_option_fqdn}" != 'true' ]]; then domain_name; fi
  if [[ "${script_option_skip}" != 'true' ]]; then change_application_hostname; fi
  if [[ "${script_option_email}" != 'true' ]]; then if [[ "${script_option_skip}" != 'true' ]]; then le_email; else email="--register-unsafely-without-email"; fi; fi
  if [[ "${udm_device}" == 'true' && "${uid_agent}" != 'true' ]]; then
    if [[ "${debbox}" == 'true' ]]; then
      # shellcheck disable=SC2010
      if [[ -d "/data/udapi-config/raddb/certs/" ]]; then
        if ls -la /data/udapi-config/raddb/certs/ | grep -iq "server.pem\\|server-key.pem" && [[ "${script_option_skip}" != 'true' ]]; then radius_certs_available=true; fi
      fi
    else
      if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -ql root 127.0.0.1 "ls -la /mnt/data/udapi-config/raddb/certs/" | grep -iq "server.pem\\|server-key.pem" && [[ "${script_option_skip}" != 'true' ]]; then radius_certs_available=true; fi
    fi
    if [[ "${radius_certs_available}" == 'true' ]]; then
      header
      echo -e "${YELLOW}#${RESET} ATTENTION, please backup your system before continuing!!"
      # shellcheck disable=2086
      read -rp $'\033[39m#\033[0m Do you want to apply the certificates to RADIUS on your "'${unifi_core_device}'"? (y/N) ' yes_no
      case "$yes_no" in
          [Yy]*) mkdir -p "${eus_dir}/radius/" &> /dev/null && touch "${eus_dir}/radius/true";;
          [Nn]*|"") if [[ -f "${eus_dir}/radius/true" ]]; then rm --force "${eus_dir}/radius/true"; fi;;
      esac
    fi
  fi
  le_post_hook
  le_pre_hook
  header
  echo -e "${WHITE_R}#${RESET} Checking for existing certificates and preparing for the challenge..."
  sleep 3
  echo "-d ${server_fqdn}" &>> "${eus_dir}/le_domain_list"
  if [[ "${multiple_fqdn_resolved}" == 'true' ]]; then while read -r domain; do echo "--domain ${domain}" >> "${eus_dir}/le_domain_list"; done < "${eus_dir}/other_domain_records"; fi
  server_fqdn_le=$(tr '\r\n' ' ' < "${eus_dir}/le_domain_list")
  rm --force "${eus_dir}/certificates" 2> /dev/null
  if ! [[ -s "/etc/letsencrypt/renewal/${server_fqdn}.conf" ]]; then rm --force "/etc/letsencrypt/renewal/${server_fqdn}.conf" &> /dev/null; fi
  if [[ -d "/etc/letsencrypt/live/" ]]; then
    while read -r dir; do
      if ! [[ -f "${dir}/fullchain.pem" ]]; then
        if [[ -f "${dir}/fullchain.p12" ]]; then
          rm --force "${dir}/fullchain.p12" &> /dev/null
        fi
      fi
    done < <(find /etc/letsencrypt/live/ -name "${server_fqdn}" -type d)
  fi
  if [[ "${certbot_auto}" == 'true' ]]; then
    # shellcheck disable=2086
    ${certbot} certificates --domain "${server_fqdn}" "${certbot_auto_flags}" &>> "${eus_dir}/certificates"
  else
    # shellcheck disable=2086
    ${certbot} certificates --domain "${server_fqdn}" &>> "${eus_dir}/certificates"
  fi
  if grep -iq "${server_fqdn}" "${eus_dir}/certificates"; then
    valid_days=$(grep -i "(valid:" "${eus_dir}/certificates" | awk '{print $6}' | sed 's/)//' | grep -o -E '[0-9]+' | tail -n1)
    if [[ -z "${valid_days}" ]]; then
      valid_days=$(grep -i "(valid:" "${eus_dir}/certificates" | awk '{print $6}' | sed 's/)//' | tail -n1)
    fi
    if grep -iq "renewal configuration file .* produced an unexpected error" "${eus_dir}/certificates"; then
      abort_reason="Unexpected error (from Let's Encrypt) regarding configuration files."
      abort
    fi
    le_fqdn=$(grep "${valid_days}" -A2 "${eus_dir}/certificates" | grep -io "${server_fqdn}.*" | cut -d'/' -f1 | tail -n1)
    fullchain_pem=$(grep -i "Certificate Path" "${eus_dir}/certificates" | grep -i "${le_fqdn}" | awk '{print $3}' | sed 's/.pem//g' | tail -n1)
    priv_key_pem=$(grep -i "Private Key Path" "${eus_dir}/certificates" | grep -i "${le_fqdn}" | awk '{print $4}' | sed 's/.pem//g' | tail -n1)
    expire_date=$(grep -i "Expiry Date:" "${eus_dir}/certificates" | grep -i "${le_fqdn}" | awk '{print $3}' | tail -n1)
    if [[ "${run_force_renew}" == 'true' ]] || [[ "${valid_days}" == 'EXPIRED' ]] || [[ "${valid_days}" -lt '30' ]]; then
      echo -e "\\n${GREEN}----${RESET}\\n"
      if [[ "${valid_days}" == 'EXPIRED' ]]; then echo -e "${WHITE_R}#${RESET} Your certificates for '${server_fqdn}' are already EXPIRED!"; else echo -e "${WHITE_R}#${RESET} Your certificates for '${server_fqdn}' expire in ${valid_days} days..."; fi
      if [[ "${script_option_skip}" != 'true' ]]; then read -rp $'\033[39m#\033[0m Do you want to force renew the certficiates? (Y/n) ' yes_no; elif [[ "${script_option_renew}" != 'true' ]]; then echo -e "${WHITE_R}#${RESET} No... I don't want to force renew my certificates"; else echo -e "${WHITE_R}#${RESET} Yes, I want to force renew the certificates!"; fi
      case "$yes_no" in
          [Yy]*|"")
              renewal_option="--force-renewal"
              import_ssl_certificates;;
          [Nn]*)
              read -rp $'\033[39m#\033[0m Would you like to import the existing certificates? (Y/n) ' yes_no
              import_existing_ssl_certificates;;
      esac
    elif [[ "${valid_days}" -ge '30' ]]; then
      echo -e "\\n${GREEN}----${RESET}\\n"
      echo -e "${WHITE_R}#${RESET} You already seem to have certificates for '${server_fqdn}', those expire in ${valid_days} days..."
      if [[ "${script_option_skip}" != 'true' ]]; then read -rp $'\033[39m#\033[0m Would you like to import the existing certificates? (Y/n) ' yes_no; fi
      case "$yes_no" in
           [Yy]*|"")
               import_existing_ssl_certificates;;
           [Nn]*) ;;
      esac
    fi
  else
    import_ssl_certificates
  fi
  if [[ "${certbot_auto}" == 'true' ]]; then
    tee /etc/cron.d/eus_certbot &>/dev/null << EOF
# /etc/cron.d/certbot: crontab entries for the certbot package
#
# Upstream recommends attempting renewal twice a day
#
# Eventually, this will be an opportunity to validate certificates
# haven't been revoked, etc.  Renewal will only occur if expiration
# is within 30 days.
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

0 */12 * * * root ${eus_dir}/certbot-auto -q renew
EOF
  fi
  if [[ "${unifi_core_system}" == 'true' ]] || [[ "${is_cloudkey}" == 'true' ]]; then
    tee /etc/cron.d/eus_script &>/dev/null << EOF
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
@reboot root sleep 300 && /bin/bash /srv/EUS/cronjob/install_certbot.sh
EOF
    # shellcheck disable=SC1117
    tee /srv/EUS/cronjob/install_certbot.sh &>/dev/null << EOF
#!/bin/bash

# Functions
get_distro() {
  if [[ -z "\$(command -v lsb_release)" ]] || [[ "\${skip_use_lsb_release}" == 'true' ]]; then
    if [[ -f "/etc/os-release" ]]; then
      if grep -iq VERSION_CODENAME /etc/os-release; then
        os_codename="\$(grep VERSION_CODENAME /etc/os-release | sed 's/VERSION_CODENAME//g' | tr -d '="' | tr '[:upper:]' '[:lower:]')"
        os_id="\$(grep ^"ID=" /etc/os-release | sed 's/ID//g' | tr -d '="' | tr '[:upper:]' '[:lower:]')"
      elif ! grep -iq VERSION_CODENAME /etc/os-release; then
        os_codename="\$(grep PRETTY_NAME /etc/os-release | sed 's/PRETTY_NAME=//g' | tr -d '="' | awk '{print \$4}' | sed 's/\((\|)\)//g' | sed 's/\/sid//g' | tr '[:upper:]' '[:lower:]')"
        os_id="\$(grep -io "debian\\|ubuntu" /etc/os-release | tr '[:upper:]' '[:lower:]' | head -n1)"
        if [[ -z "\${os_codename}" ]]; then
          os_codename="\$(grep PRETTY_NAME /etc/os-release | sed 's/PRETTY_NAME=//g' | tr -d '="' | awk '{print \$3}' | sed 's/\((\|)\)//g' | sed 's/\/sid//g' | tr '[:upper:]' '[:lower:]')"
        fi
      fi
    fi
  else
    os_codename="\$(lsb_release --codename --short | tr '[:upper:]' '[:lower:]')"
    os_id="\$(lsb_release --id --short | tr '[:upper:]' '[:lower:]')"
    if [[ "\${os_codename}" == 'n/a' ]]; then
      skip_use_lsb_release="true"
      get_distro
      return
    fi
  fi
  if [[ ! "${os_id}" =~ (ubuntu|debian) ]] && [[ -e "/etc/os-release" ]]; then os_id="\$(grep -io "debian\\|ubuntu" /etc/os-release | tr '[:upper:]' '[:lower:]' | head -n1)"; fi
  if [[ "\${os_codename}" =~ ^(precise|maya|luna)$ ]]; then repo_codename="precise"; os_codename="precise"; os_id="ubuntu"
  elif [[ "\${os_codename}" =~ ^(trusty|qiana|rebecca|rafaela|rosa|freya)$ ]]; then repo_codename="trusty"; os_codename="trusty"; os_id="ubuntu"
  elif [[ "\${os_codename}" =~ ^(xenial|sarah|serena|sonya|sylvia|loki)$ ]]; then repo_codename="xenial"; os_codename="xenial"; os_id="ubuntu"
  elif [[ "\${os_codename}" =~ ^(bionic|tara|tessa|tina|tricia|hera|juno)$ ]]; then repo_codename="bionic"; os_codename="bionic"; os_id="ubuntu"
  elif [[ "\${os_codename}" =~ ^(focal|ulyana|ulyssa|uma|una|odin|jolnir)$ ]]; then repo_codename="focal"; os_codename="focal"; os_id="ubuntu"
  elif [[ "\${os_codename}" =~ ^(jammy|vanessa|vera|victoria|virginia|horus)$ ]]; then repo_codename="jammy"; os_codename="jammy"; os_id="ubuntu"
  elif [[ "\${os_codename}" =~ ^(noble|wilma)$ ]]; then repo_codename="noble"; os_codename="noble"; os_id="ubuntu"
  elif [[ "\${os_codename}" =~ ^(oracular)$ ]]; then repo_codename="oracular"; os_codename="oracular"; os_id="ubuntu"
  elif [[ "\${os_codename}" =~ ^(jessie|betsy)$ ]]; then repo_codename="jessie"; os_codename="jessie"; os_id="debian"
  elif [[ "\${os_codename}" =~ ^(stretch|continuum|helium|cindy)$ ]]; then repo_codename="stretch"; os_codename="stretch"; os_id="debian"
  elif [[ "\${os_codename}" =~ ^(buster|debbie|parrot|engywuck-backports|engywuck|deepin|lithium)$ ]]; then repo_codename="buster"; os_codename="buster"; os_id="debian"
  elif [[ "\${os_codename}" =~ ^(bullseye|kali-rolling|elsie|ara|beryllium)$ ]]; then repo_codename="bullseye"; os_codename="bullseye"; os_id="debian"
  elif [[ "\${os_codename}" =~ ^(bookworm|lory|faye|boron|beige)$ ]]; then repo_codename="bookworm"; os_codename="bookworm"; os_id="debian"
  elif [[ "\${os_codename}" =~ ^(unstable|rolling)$ ]]; then repo_codename="unstable"; os_codename="unstable"; os_id="debian"
  else
    repo_codename="\${os_codename}"
  fi
}
get_distro

get_repo_url() {
  unset archived_repo
  if "\$(which dpkg)" -l apt 2> /dev/null | awk '{print \$1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui"; then apt_package_version="\$(dpkg-query --showformat='\${Version}' --show apt | sed -e 's/.*://' -e 's/-.*//g' -e 's/[^0-9.]//g' -e 's/\.//g' | sort -V | tail -n1)"; fi
  if "\$(which dpkg)" -l apt-transport-https 2> /dev/null | awk '{print \$1}' | grep -iq "^ii\\|^hi\\|^ri\\|^pi\\|^ui" || [[ "\${apt_package_version::2}" -ge "15" ]]; then
    http_or_https="https"
    add_repositories_http_or_https="http[s]*"
    if [[ "\${copied_source_files}" == 'true' ]]; then
      while read -r revert_https_repo_needs_http_file; do
        if [[ "\${revert_https_repo_needs_http_file}" == 'source.list' ]]; then
          mv "\${revert_https_repo_needs_http_file}" "/etc/apt/source.list" &>> "\${eus_dir}/logs/revert-https-repo-needs-http.log"
        else
          mv "\${revert_https_repo_needs_http_file}" "/etc/apt/source.list.d/\$(basename "\${revert_https_repo_needs_http_file}")" &>> "\${eus_dir}/logs/revert-https-repo-needs-http.log"
        fi
      done < <(find "\${eus_dir}/repositories" -type f -name "*.list")
    fi
  else
    http_or_https="http"
    add_repositories_http_or_https="http"
  fi
  if dpkg -l curl 2> /dev/null | awk '{print \$1}' | grep -iq "^ii\\|^hi"; then
    if [[ "\${os_codename}" =~ (precise|trusty|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic) ]]; then
      if curl -s http://old-releases.ubuntu.com/ubuntu/dists/ | grep -iq "\${os_codename}" 2> /dev/null; then archived_repo="true"; fi
      if [[ "\${archived_repo}" == "true" ]]; then repo_url="http://old-releases.ubuntu.com/ubuntu"; else repo_url="http://archive.ubuntu.com/ubuntu"; fi
    elif [[ "\${os_codename}" =~ (wheezy|jessie|stretch|buster|bullseye|bookworm|trixie|forky) ]]; then
      if curl -s http://archive.debian.org/debian/dists/ | grep -iq "\${os_codename}" 2> /dev/null; then archived_repo="true"; fi
      if [[ "\${archived_repo}" == "true" ]]; then repo_url="\${http_or_https}://archive.debian.org/debian"; else repo_url="\${http_or_https}://ftp.debian.org/debian"; fi
    fi
  else
    if [[ "\${os_codename}" =~ (precise|trusty|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic) ]]; then
      repo_url="http://archive.ubuntu.com/ubuntu"
    elif [[ "\${os_codename}" =~ (wheezy|jessie|stretch|buster|bullseye|bookworm|trixie|forky) ]]; then
      repo_url="\${http_or_https}://deb.debian.org/debian"
    fi
  fi
}
get_repo_url

add_repositories() {
  # shellcheck disable=SC2154
  if [[ \$(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb \${add_repositories_http_or_https}://\$(echo "\${repo_url}" | sed -e 's/https\:\/\///g' -e 's/http\:\/\///g')\${repo_url_arguments} \${repo_codename}\${repo_codename_argument} \${repo_component}") -eq 0 ]]; then
    if [[ "\${apt_key_deprecated}" == 'true' ]]; then
      if [[ -n "\${repo_key}" && -n "\${repo_key_name}" ]]; then
        if gpg --no-default-keyring --keyring "/etc/apt/keyrings/\${repo_key_name}.gpg" --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys "\${repo_key}" &> /dev/null; then
          signed_by_value_repo_key="[ /etc/apt/keyrings/\${repo_key_name}.gpg ] "
        fi
      fi
    else
      missing_key="\${repo_key}"
      if [[ -n "\${missing_key}" ]]; then
        echo -e "\${missing_key}" &>> /tmp/EUS/keys/missing_keys
      fi
    fi
    if [[ "\${os_codename}" =~ (wheezy|jessie|stretch|buster|bullseye|bookworm|trixie|forky) ]]; then
      os_version_number="\$(lsb_release -rs | tr '[:upper:]' '[:lower:]' | cut -d'.' -f1)"
      check_debian_version="\${os_version_number}"
      if echo "\${repo_url}" | grep -ioq "archive"; then check_debian_version="\${os_version_number}-archive"; fi
      if echo "\${repo_url_arguments}" | grep -ioq "security"; then check_debian_version="\${os_version_number}-security"; fi
      if [[ "\$(curl "${curl_argument[@]}" "https://api.glennr.nl/api/debian-release?version=\${check_debian_version}" 2> /dev/null | jq -r '.expired' 2> /dev/null)" == 'true' ]]; then if [[ -n "\${signed_by_value_repo_key}" ]]; then signed_by_value_repo_key="[ /etc/apt/keyrings/\${repo_key_name}.gpg trusted=yes ] "; else signed_by_value_repo_key="[ trusted=yes ] "; fi; fi
    fi
    echo -e "deb \${signed_by_value_repo_key}\${repo_url}\${repo_url_arguments} \${repo_codename}\${repo_component}" &>> /etc/apt/sources.list.d/glennr-install-script.list
    unset missing_key
    unset repo_key
    unset repo_key_name
    unset repo_url_arguments
    unset signed_by_value_repo_key
  fi
  if [[ "\${add_repositories_http_or_https}" == 'http' ]]; then
    if ! [[ -d "${eus_dir}/repositories" ]]; then mkdir -p "${eus_dir}/repositories"; fi
    while read -r https_repo_needs_http_file; do
      if [[ -d "${eus_dir}/repositories" ]]; then 
        cp "\${https_repo_needs_http_file}" "${eus_dir}/repositories/\$(basename "\${https_repo_needs_http_file}")" &>> "${eus_dir}/logs/https-repo-needs-http.log"
        copied_source_files="true"
      fi
      sed -i '/https/{s/^/#/}' "\${https_repo_needs_http_file}" &>> "${eus_dir}/logs/https-repo-needs-http.log"
      sed -i 's/##/#/g' "\${https_repo_needs_http_file}" &>> "${eus_dir}/logs/https-repo-needs-http.log"
    done < <(grep -sril "^deb https*://\$(echo "\${repo_url}" | sed -e 's/https\:\/\///g' -e 's/http\:\/\///g') \${repo_codename}\${repo_component}" /etc/apt/sources.list /etc/apt/sources.list.d/*)
  fi
  if [[ "\${os_codename_changed}" == 'true' ]]; then unset os_codename_changed; get_distro; get_repo_url; fi
}

while [ -n "\$1" ]; do
  case "\$1" in
  --force-dpkg) script_option_force_dpkg=true;;
  esac
  shift
done
echo -e "\\n------- \$(date +%F-%R) -------\\n" &>>/srv/EUS/logs/cronjob_install.log
mkdir -p /srv/EUS/tmp/
while fuser /var/lib/dpkg/lock /var/lib/apt/lists/lock /var/cache/apt/archives/lock >/dev/null 2>&1; do
  unset dpkg_locked
  if [[ "\${script_option_force_dpkg}" == "true" ]]; then
    current_time=\$(date "+%Y-%m-%d %H:%M")
    echo "Force killing the lock... | \${current_time}" &>> /srv/EUS/logs/cronjob_install.log
    rm --force /srv/EUS/tmp/dpkg_lock &> /dev/null
    pgrep "apt" >> /srv/EUS/tmp/apt
    while read -r glennr_apt; do
      kill -9 "\$glennr_apt" &> /dev/null
    done < /srv/EUS/tmp/apt
    rm --force /srv/EUS/tmp/apt &> /dev/null
    rm --force /var/lib/apt/lists/lock &> /dev/null
    rm --force /var/cache/apt/archives/lock &> /dev/null
    rm --force /var/lib/dpkg/lock* &> /dev/null
    dpkg --configure -a &> /dev/null
    DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install --fix-broken &> /dev/null
  else
    if [[ \$(grep -c "eus_lock_active" /srv/EUS/tmp/dpkg_lock) -ge 60 ]]; then
      echo "dpkg lock still active after 600 seconds..." &>> /srv/EUS/logs/cronjob_install.log
      date_minute=\$(date +%M)
      if ! grep -iq "/srv/EUS/cronjob/install_certbot.sh" /etc/crontab; then
        echo "\${date_minute} * * * * root /bin/bash /srv/EUS/cronjob/install_certbot.sh --force-dpkg" >> /etc/crontab
        if grep -iq "root /bin/bash /srv/EUS/cronjob/install_certbot.sh --force-dpkg" /etc/crontab; then
          echo "Script has been scheduled to run on a later time..." &>> /srv/EUS/logs/cronjob_install.log
          exit 0
        fi
      fi
    fi
  fi
  echo "eus_lock_active" >> /srv/EUS/tmp/dpkg_lock
  sleep 10
done;
rm --force /srv/EUS/tmp/dpkg_lock_test &> /dev/null
rmdir /srv/EUS/tmp/ &> /dev/null
if ! dpkg -l certbot 2> /dev/null | awk '{print \$1}' | grep -iq "^ii\\|^hi"; then
  if [[ -f /srv/EUS/certbot_install_failed ]]; then
    rm --force /srv/EUS/certbot_install_failed
  fi
  if [[ -f /srv/EUS/logs/cronjob_install.log ]]; then
    cronjob_install_log_size=\$(du -sc /srv/EUS/logs/cronjob_install.log | grep total\$ | awk '{print \$1}')
    if [[ \${cronjob_install_log_size} -gt '50' ]]; then
      tail -n100 /srv/EUS/logs/cronjob_install.log &> /srv/EUS/logs/cronjob_install_tmp.log
      cp /srv/EUS/logs/cronjob_install_tmp.log /srv/EUS/logs/cronjob_install.log && rm --force /srv/EUS/logs/cronjob_install_tmp.log
    fi
  fi
  get_distro
  if [[ \$os_codename == "jessie" ]]; then
    if [[ ! -f "${eus_dir}/certbot-auto" && -s "${eus_dir}/certbot-auto" ]]; then
      curl -s https://raw.githubusercontent.com/certbot/certbot/v1.9.0/certbot-auto -o "${eus_dir}/certbot-auto" &>>/srv/EUS/logs/cronjob_install.log
      chown root ${eus_dir}/certbot-auto &>>/srv/EUS/logs/cronjob_install.log
      chmod 0755 ${eus_dir}/certbot-auto &>>/srv/EUS/logs/cronjob_install.log
    else
      echo "certbot-auto is available!" &>>/srv/EUS/logs/cronjob_install.log
    fi
    if ! dpkg -l libssl-dev 2> /dev/null | awk '{print \$1}' | grep -iq "^ii\\|^hi"; then
      if ! apt-get install libssl-dev -y; then
        echo deb http://archive.debian.org/debian jessie-backports main >>/etc/apt/sources.list.d/glennr-install-script.list
        apt-get update -o Acquire::Check-Valid-Until=false &>>/srv/EUS/logs/cronjob_install.log
        apt-get install -t jessie-backports libssl-dev -y &>>/srv/EUS/logs/cronjob_install.log
        sed -i '/jessie-backports/d' /etc/apt/sources.list.d/glennr-install-script.list &>>/srv/EUS/logs/cronjob_install.log
      fi
    else
      echo "libssl-dev is installed!" &>>/srv/EUS/logs/cronjob_install.log
    fi
    if [[ -f "${eus_dir}/certbot-auto" || -s "${eus_dir}/certbot-auto" ]]; then
      if [[ \$(stat -c "%a" "${eus_dir}/certbot-auto") != "755" ]]; then
        chmod 0755 ${eus_dir}/certbot-auto
      fi
      if [[ \$(stat -c "%U" "${eus_dir}/certbot-auto") != "root" ]] ; then
        chown root ${eus_dir}/certbot-auto
      fi
    fi
    ${eus_dir}/certbot-auto --non-interactive --install-only --verbose &>>/srv/EUS/logs/cronjob_install.log
  fi
  if [[ \$os_codename =~ (stretch|bullseye|bookworm|trixie|forky) ]]; then
    repo_component="main"
    add_repositories
    apt-get update &>>/srv/EUS/logs/cronjob_install.log
    apt-get install certbot -y &>>/srv/EUS/logs/cronjob_install.log || touch /srv/EUS/certbot_install_failed
  fi
fi
if [[ -n "\${auto_dns_challenge_provider}" ]]; then
  if dpkg -l certbot 2> /dev/null | awk '{print \$1}' | grep -iq "^ii\\|^hi"; then
    DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' remove certbot &>> "${eus_dir}/logs/remove-certbot.log"
  fi
  if [[ "${certbot_native_plugin}" == 'true' ]]; then
    if ! dpkg -l "python3-certbot-dns-${auto_dns_challenge_provider}" 2> /dev/null | awk '{print \$1}' | grep -iq "^ii\\|^hi"; then
      if ! DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "python3-certbot-dns-${auto_dns_challenge_provider}" &>> "${eus_dir}/logs/required.log"; then
        if [[ "\${repo_codename}" =~ (precise|trusty|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular) ]]; then
          if [[ "\${repo_codename}" =~ (focal|groovy|hirsute|impish) ]]; then repo_component="main universe"; add_repositories; fi
          if [[ "\${repo_codename}" =~ (jammy|kinetic|lunar|mantic|noble|oracular) ]]; then repo_component="main"; add_repositories; fi
          repo_codename_argument="-security"
          repo_component="main universe"
        elif [[ "\${repo_codename}" =~ (wheezy|jessie|stretch|buster|bullseye|bookworm|trixie|forky) ]]; then
          if [[ "\${repo_codename}" =~ (stretch) ]]; then repo_url_arguments="-security/"; repo_codename_argument="/updates"; repo_component="main"; add_repositories; fi
          repo_component="main"
        fi
        add_repositories
        required_package="python3-certbot-dns-${auto_dns_challenge_provider}"
        apt_get_install_package
      fi
    fi
    if ! dpkg -l python3-certbot 2> /dev/null | awk '{print \$1}' | grep -iq "^ii\\|^hi"; then
      if ! DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install python3-certbot &>> "${eus_dir}/logs/required.log"; then
        if [[ "\${repo_codename}" =~ (precise|trusty|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|oracular) ]]; then
          if [[ "\${repo_codename}" =~ (focal|groovy|hirsute|impish) ]]; then repo_component="main universe"; add_repositories; fi
          if [[ "\${repo_codename}" =~ (jammy|kinetic|lunar|mantic|noble|oracular) ]]; then repo_component="main"; add_repositories; fi
          repo_codename_argument="-security"
          repo_component="main universe"
        elif [[ "\${repo_codename}" =~ (wheezy|jessie|stretch|buster|bullseye|bookworm|trixie|forky) ]]; then
          if [[ "\${repo_codename}" =~ (stretch) ]]; then repo_url_arguments="-security/"; repo_codename_argument="/updates"; repo_component="main"; add_repositories; fi
          repo_component="main"
        fi
        add_repositories
        required_package="python3-certbot"
        apt_get_install_package
      fi
    fi
  fi
fi
if [[ "\${script_option_force_dpkg}" == "true" ]]; then sed -i "/install_certbot.sh/d" /etc/crontab &> /dev/null; fi
EOF
    chmod +x /srv/EUS/cronjob/install_certbot.sh
  fi
  if [[ "${run_uck_scripts}" == 'true' ]]; then
    if [[ "${is_cloudkey}" == 'true' ]]; then
      echo -e "\\n${WHITE_R}----${RESET}\\n"
      echo -e "${WHITE_R}#${RESET} Creating required scripts and adding them as cronjobs!"
      mkdir -p /srv/EUS/cronjob
      if dpkg --print-architecture | grep -iq 'armhf'; then
        touch /usr/lib/eus &>/dev/null
        cat /usr/lib/version &> /srv/EUS/cloudkey/version
        tee /etc/cron.d/eus_script_uc_ck &>/dev/null << EOF
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
@reboot root sleep 200 && /bin/bash /srv/EUS/cronjob/eus_uc_ck.sh
EOF
        # shellcheck disable=SC1117
        tee /srv/EUS/cronjob/eus_uc_ck.sh &>/dev/null << EOF
#!/bin/bash
if [[ -f /srv/EUS/cloudkey/version ]]; then
  current_version=\$(cat /usr/lib/version)
  old_version=\$(cat /srv/EUS/cloudkey/version)
  if [[ \${old_version} != \${current_version} ]] || ! [[ -f /usr/lib/eus ]]; then
    touch /usr/lib/eus
    echo "\$(date +%F-%R) | Cloudkey firmware version changed from \${old_version} to \${current_version}" &>> /srv/EUS/logs/uc-ck_firmware_versions.log
  fi
  server_fqdn="${server_fqdn}"
  if ls ${eus_dir}/logs/lets_encrypt_[0-9]*.log &>/dev/null && [[ -d "/etc/letsencrypt/live/${server_fqdn}" ]]; then
    last_le_log=\$(ls ${eus_dir}/logs/lets_encrypt_[0-9]*.log | tail -n1)
    le_var_log=\$(cat \${last_le_log} | grep -i "/etc/letsencrypt/live/${server_fqdn}" | awk '{print \$1}' | head -n1 | sed 's/\/etc\/letsencrypt\/live\///g' | grep -io "${server_fqdn}.*" | cut -d'/' -f1 | sed "s/${server_fqdn}//g")
    le_var_dir=\$(ls -lc /etc/letsencrypt/live/ | grep -io "${server_fqdn}.*" | tail -n1 | sed "s/${server_fqdn}//g")
    if [[ "\${le_var_log}" != "\${le_var_dir}" ]]; then
      le_var="\${le_var_dir}"
    else
      le_var="\${le_var_log}"
    fi
  else
    le_var=\$(ls -lc /etc/letsencrypt/live/ | grep -io "${server_fqdn}.*" | tail -n1 | sed "s/${server_fqdn}//g")
  fi
  if [[ -f /etc/letsencrypt/live/${server_fqdn}\${le_var}/privkey.pem && -f /etc/letsencrypt/live/${server_fqdn}\${le_var}/fullchain.pem ]]; then
    uc_ck_key=\$(cat /etc/ssl/private/cloudkey.key)
    priv_key=\$(cat /etc/letsencrypt/live/${server_fqdn}\${le_var}/privkey.pem)
    if [[ \${uc_ck_key} != \${priv_key} ]]; then
      echo "\$(date +%F-%R) | Certificates were different.. applying the Let's Encrypt ones." &>> /srv/EUS/logs/uc_ck_certificates.log
      cp /etc/ssl/private/cloudkey.crt ${eus_dir}/cloudkey/certs_backups/cloudkey.crt_\$(date +%Y%m%d_%H%M)
      cp /etc/ssl/private/cloudkey.key ${eus_dir}/cloudkey/certs_backups/cloudkey.key_\$(date +%Y%m%d_%H%M)
      if [[ -f /etc/letsencrypt/live/${server_fqdn}\${le_var}/fullchain.pem ]]; then
        cp /etc/letsencrypt/live/${server_fqdn}\${le_var}/fullchain.pem /etc/ssl/private/cloudkey.crt
      fi
      if [[ -f /etc/letsencrypt/live/${server_fqdn}\${le_var}/privkey.pem ]]; then
        cp /etc/letsencrypt/live/${server_fqdn}\${le_var}/privkey.pem /etc/ssl/private/cloudkey.key
      fi
      systemctl restart nginx
      if [[ \$(dpkg-query -W -f='\${Status}' unifi 2>/dev/null | grep -c "ok installed") -eq 1 ]]; then
        echo -e "\\n------- \$(date +%F-%R) -------\\n" &>> ${eus_dir}/logs/uc_ck_unifi_import.log
        if [[ \${old_certificates} == 'last_three' ]]; then ls -t ${eus_dir}/cloudkey/certs_backups/cloudkey.crt_* 2> /dev/null | awk 'NR>3' | xargs rm -f 2> /dev/null; fi
        mkdir -p ${eus_dir}/network/keystore_backups && cp /usr/lib/unifi/data/keystore ${eus_dir}/network/keystore_backups/keystore_\$(date +%Y%m%d_%H%M)
        # shellcheck disable=SC2086
        openssl pkcs12 -export -inkey "/etc/letsencrypt/live/${server_fqdn}\${le_var}/privkey.pem" -in "/etc/letsencrypt/live/${server_fqdn}\${le_var}/fullchain.pem" -out "/etc/letsencrypt/live/${server_fqdn}\${le_var}/fullchain.p12" -name unifi -password pass:aircontrolenterprise ${openssl_legacy_flag} &>> ${eus_dir}/logs/uc_ck_unifi_import.log
        keytool -delete -alias unifi -keystore /usr/lib/unifi/data/keystore -deststorepass aircontrolenterprise &>> ${eus_dir}/logs/uc_ck_unifi_import.log
        keytool -importkeystore -deststorepass aircontrolenterprise -destkeypass aircontrolenterprise -destkeystore /usr/lib/unifi/data/keystore -srckeystore "/etc/letsencrypt/live/${server_fqdn}\${le_var}/fullchain.p12" -srcstoretype PKCS12 -srcstorepass aircontrolenterprise -alias unifi -noprompt &>> ${eus_dir}/logs/uc_ck_unifi_import.log
        # shellcheck disable=SC2086
        if openssl pkcs12 -in "/etc/letsencrypt/live/${server_fqdn}\${le_var}/fullchain.p12" -password pass:aircontrolenterprise -nokeys ${openssl_legacy_flag} | openssl x509 -text -noout | grep -i signature | grep -iq ecdsa &> /dev/null; then
          echo "unifi.https.ciphers=ECDHE-ECDSA-AES256-GCM-SHA384,ECDHE-RSA-AES128-GCM-SHA256" &>> /usr/lib/unifi/data/system.properties
          echo "unifi.https.sslEnabledProtocols=TLSv1.3,TLSv1.2" &>> /usr/lib/unifi/data/system.properties
        fi
        systemctl restart unifi
      fi
    fi
  fi
  if [[ -f /srv/EUS/logs/uc_ck_certificates.log ]]; then
    uc_ck_certificates_log_size=\$(du -sc /srv/EUS/logs/uc_ck_certificates.log | grep total\$ | awk '{print \$1}')
    if [[ \${uc_ck_certificates_log_size} -gt '50' ]]; then
      tail -n5 /srv/EUS/logs/uc_ck_certificates.log &> /srv/EUS/logs/uc_ck_certificates_tmp.log
      cp /srv/EUS/logs/uc_ck_certificates_tmp.log /srv/EUS/logs/uc_ck_certificates.log && rm --force /srv/EUS/logs/uc_ck_certificates_tmp.log
    fi
  fi
  if [[ -f /srv/EUS/logs/uc-ck_firmware_versions.log ]]; then
    firmware_versions_log_size=\$(du -sc /srv/EUS/logs/uc-ck_firmware_versions.log | grep total\$ | awk '{print \$1}')
    if [[ \${firmware_versions_log_size} -gt '50' ]]; then
      tail -n5 /srv/EUS/logs/uc-ck_firmware_versions.log &> /srv/EUS/logs/uc-ck_firmware_versions_tmp.log
      cp /srv/EUS/logs/uc-ck_firmware_versions_tmp.log /srv/EUS/logs/uc-ck_firmware_versions.log && rm --force /srv/EUS/logs/uc-ck_firmware_versions_tmp.log
    fi
  fi
  if [[ -f ${eus_dir}/cloudkey/uc_ck_unifi_import.log ]]; then
    unifi_import_log_size=\$(du -sc ${eus_dir}/logs/uc_ck_unifi_import.log | grep total\$ | awk '{print \$1}')
    if [[ \${unifi_import_log_size} -gt '50' ]]; then
      tail -n100 ${eus_dir}/logs/uc_ck_unifi_import.log &> ${eus_dir}/cloudkey/unifi_import_tmp.log
      cp ${eus_dir}/cloudkey/unifi_import_tmp.log ${eus_dir}/logs/uc_ck_unifi_import.log && rm --force ${eus_dir}/cloudkey/unifi_import_tmp.log
    fi
  fi
fi
EOF
        chmod +x /srv/EUS/cronjob/eus_uc_ck.sh
      fi
    fi
  fi
  echo ""
  echo ""
  if [[ "${script_timeout_http}" == 'true' ]]; then
    echo -e "${WHITE_R}#${RESET} A DNS challenge requires you to add a TXT record to your domain register. ( NO AUTO RENEWING )"
    echo -e "${WHITE_R}#${RESET} The DNS challenge is only recommend for users where the ISP blocks port 80. ( rare occasions )"
    echo ""
    read -rp $'\033[39m#\033[0m Would you like to use the DNS challenge? (Y/n) ' yes_no
    case "$yes_no" in
       [Yy]*|"") 
         check_apt_listbugs
         echo "--dns" &>> /tmp/EUS/script_options
         get_script_options
         # shellcheck disable=SC2068
         bash "${script_location}" ${script_options[@]}; exit 0;;
       [Nn]*) ;;
    esac
  else
    if [[ "${script_option_skip}" != 'true' ]]; then remove_old_post_pre_hook; fi
    author
  fi
  rm --force "${eus_dir}/le_domain_list" &> /dev/null
  rm --force "${eus_dir}/other_domain_records" &> /dev/null
  if [[ "${set_lc_all}" == 'true' ]]; then unset LC_ALL &> /dev/null; fi
  if [[ "${stopped_unattended_upgrade}" == 'true' ]]; then systemctl start unattended-upgrades &>> "${eus_dir}/logs/unattended-upgrades.log"; unset stopped_unattended_upgrade; fi
  if [[ "${unifi_core_system}" == 'true' ]]; then unifi_core_certificate_migration; fi 
}

# shellcheck disable=SC2120
paid_certificate_uc_ck() {
  echo -e "\\n${WHITE_R}----${RESET}\\n"
  echo -e "${WHITE_R}#${RESET} Creating required scripts and adding them as cronjobs!"
  if ! [[ -d "/srv/EUS/cronjob" ]]; then mkdir -p /srv/EUS/cronjob; fi
  if ! [[ -f "/usr/lib/eus" ]]; then touch /usr/lib/eus &>/dev/null; fi
  cat /usr/lib/version &> /srv/EUS/cloudkey/version
  tee /etc/cron.d/eus_script_uc_ck &>/dev/null << EOF
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
@reboot root sleep 200 && /bin/bash /srv/EUS/cronjob/eus_uc_ck.sh
EOF
  # shellcheck disable=SC1117
  tee /srv/EUS/cronjob/eus_uc_ck.sh &>/dev/null << EOF
#!/bin/bash
if [[ -f /srv/EUS/cloudkey/version ]]; then
  current_version=\$(cat /usr/lib/version)
  old_version=\$(cat /srv/EUS/cloudkey/version)
  if [[ "\${old_version}" != "\${current_version}" ]] || ! [[ -f /usr/lib/eus ]]; then
    touch /usr/lib/eus
    echo "\$(date +%F-%R) | Cloudkey firmware version changed from \${old_version} to \${current_version}" &>> /srv/EUS/logs/uc-ck_firmware_versions.log
  fi
  if [[ -f "${eus_dir}/paid-certificates/eus_crt_file.crt" && -f "${eus_dir}/paid-certificates/eus_key_file.key" ]]; then
    uc_ck_key=\$(md5sum /etc/ssl/private/cloudkey.key | awk '{print $1}')
    priv_key=\$(md5sum "${eus_dir}/paid-certificates/eus_key_file.key" | awk '{print $1}')
    if [[ "\${uc_ck_key}" != "\${priv_key}" ]]; then
      echo "\$(date +%F-%R) | Certificates were different.. applying the paid ones." &>> /srv/EUS/logs/uc_ck_certificates.log
      cp "/etc/ssl/private/cloudkey.crt" "${eus_dir}/cloudkey/certs_backups/cloudkey.crt_\$(date +%Y%m%d_%H%M)"
      cp "/etc/ssl/private/cloudkey.key" "${eus_dir}/cloudkey/certs_backups/cloudkey.key_\$(date +%Y%m%d_%H%M)"
      if [[ -f "${eus_dir}/paid-certificates/eus_crt_file.crt" ]]; then
        cp "${eus_dir}/paid-certificates/eus_crt_file.crt" /etc/ssl/private/cloudkey.crt
      fi
      if [[ -f "${eus_dir}/paid-certificates/eus_key_file.key" ]]; then
        cp "${eus_dir}/paid-certificates/eus_key_file.key" /etc/ssl/private/cloudkey.key
      fi
      systemctl restart nginx
      if [[ \$(dpkg-query -W -f='\${Status}' unifi 2>/dev/null | grep -c "ok installed") -eq 1 ]]; then
        echo -e "\\n------- \$(date +%F-%R) -------\\n" &>> "${eus_dir}/logs/uc_ck_unifi_import.log"
        if [[ "\${old_certificates}" == 'last_three' ]]; then ls -t "${eus_dir}/cloudkey/certs_backups/cloudkey.crt_*" 2> /dev/null | awk 'NR>3' | xargs rm -f 2> /dev/null; fi
        mkdir -p "${eus_dir}/network/keystore_backups" && cp /usr/lib/unifi/data/keystore "${eus_dir}/network/keystore_backups/keystore_\$(date +%Y%m%d_%H%M)"
        keytool -delete -alias unifi -keystore /usr/lib/unifi/data/keystore -deststorepass aircontrolenterprise &>> "${eus_dir}/logs/uc_ck_unifi_import.log"
        keytool -importkeystore -deststorepass aircontrolenterprise -destkeypass aircontrolenterprise -destkeystore /usr/lib/unifi/data/keystore -srckeystore "${eus_dir}/paid-certificates/eus_unifi.p12" -srcstoretype PKCS12 -srcstorepass aircontrolenterprise -alias unifi -noprompt &>> "${eus_dir}/logs/uc_ck_unifi_import.log"
        # shellcheck disable=SC2086
        if openssl pkcs12 -in "${eus_dir}/paid-certificates/eus_unifi.p12" -password pass:aircontrolenterprise -nokeys ${openssl_legacy_flag} | openssl x509 -text -noout | grep -i signature | grep -iq ecdsa &> /dev/null; then
          echo "unifi.https.ciphers=ECDHE-ECDSA-AES256-GCM-SHA384,ECDHE-RSA-AES128-GCM-SHA256" &>> /usr/lib/unifi/data/system.properties
          echo "unifi.https.sslEnabledProtocols=TLSv1.3,TLSv1.2" &>> /usr/lib/unifi/data/system.properties
        fi
        systemctl restart unifi
      fi
    fi
  fi
  if [[ -f /srv/EUS/logs/uc_ck_certificates.log ]]; then
    uc_ck_certificates_log_size=\$(du -sc /srv/EUS/logs/uc_ck_certificates.log | grep total\$ | awk '{print \$1}')
    if [[ "\${uc_ck_certificates_log_size}" -gt '50' ]]; then
      tail -n5 /srv/EUS/logs/uc_ck_certificates.log &> /srv/EUS/logs/uc_ck_certificates_tmp.log
      cp /srv/EUS/logs/uc_ck_certificates_tmp.log /srv/EUS/logs/uc_ck_certificates.log && rm --force /srv/EUS/logs/uc_ck_certificates_tmp.log
    fi
  fi
  if [[ -f /srv/EUS/logs/uc-ck_firmware_versions.log ]]; then
    firmware_versions_log_size=\$(du -sc /srv/EUS/logs/uc-ck_firmware_versions.log | grep total\$ | awk '{print \$1}')
    if [[ "\${firmware_versions_log_size}" -gt '50' ]]; then
      tail -n5 /srv/EUS/logs/uc-ck_firmware_versions.log &> /srv/EUS/logs/uc-ck_firmware_versions_tmp.log
      cp /srv/EUS/logs/uc-ck_firmware_versions_tmp.log /srv/EUS/logs/uc-ck_firmware_versions.log && rm --force /srv/EUS/logs/uc-ck_firmware_versions_tmp.log
    fi
  fi
  if [[ -f "${eus_dir}/cloudkey/uc_ck_unifi_import.log" ]]; then
    unifi_import_log_size=\$(du -sc "${eus_dir}/logs/uc_ck_unifi_import.log" | grep total\$ | awk '{print \$1}')
    if [[ "\${unifi_import_log_size}" -gt '50' ]]; then
      tail -n100 "${eus_dir}/logs/uc_ck_unifi_import.log" &> "${eus_dir}/cloudkey/unifi_import_tmp.log"
      cp "${eus_dir}/cloudkey/unifi_import_tmp.log" "${eus_dir}/logs/uc_ck_unifi_import.log" && rm --force "${eus_dir}/cloudkey/unifi_import_tmp.log"
    fi
  fi
fi
EOF
  chmod +x /srv/EUS/cronjob/eus_uc_ck.sh
  if [[ -f "/srv/EUS/cronjob/eus_uc_ck.sh" && -f "/etc/cron.d/eus_script_uc_ck" ]]; then
    echo -e "${GREEN}#${RESET} Successfully created the required scripts and were added as cronjob!"
    sleep 3
  else
    abort_reason="Failed to create the required scripts and were added as cronjob."
    abort
  fi
}

backup_paid_certificate() {
  if [[ "$(find "${eus_dir}/paid-certificates/" -maxdepth 1 -not -type d | wc -l)" -ge '1' ]]; then header; fi
  while read -r cert_file; do
    if ! [[ -d "${eus_dir}/paid-certificates/backup_${time_date}/" ]]; then mkdir -p "${eus_dir}/paid-certificates/backup_${time_date}/"; fi
    echo -e "${WHITE_R}#${RESET} Backing up \"${cert_file}\"..."
    if mv "${cert_file}" "${eus_dir}/paid-certificates/backup_${time_date}/${cert_file##*/}"; then echo -e "${GREEN}#${RESET} Successfully backed up \"${cert_file}\"! \\n"; else abort_reason="Failed to back up ${cert_file}."; abort; fi
  done < <(find "${eus_dir}/paid-certificates/" -maxdepth 1 -type f)
  amount_backup_folders=$(find "${eus_dir}/paid-certificates/" -maxdepth 1 -type d | grep -ci "backup_.*")
  if [[ "${amount_backup_folders}" -gt 10 ]]; then
    echo -e "\\n${WHITE_R}----${RESET}\\n"
    echo -e "${WHITE_R}#${RESET} You seem to have more then 10 paid-certificate backups..."
    echo -e "${WHITE_R}#${RESET} In those backups you can find the certificates that were used on your setup ( imported )."
    if [[ "${script_option_skip}" != 'true' ]]; then read -rp $'\033[39m#\033[0m Do you want to remove older backup folders and keep the last 3? (Y/n) ' yes_no; fi
    case "$yes_no" in
        [Yy]*|"")
           # shellcheck disable=SC2012
           find "${eus_dir}/paid-certificates/" -type d -exec stat -c '%X %n' {} \; | sort -nr | grep -i "${eus_dir}/paid-certificates/backup_.*" | awk 'NR>3 {print $2}' &> "${eus_dir}/paid-certificates/list.tmp"
           while read -r folder; do
             echo -e "${WHITE_R}#${RESET} Removing \"${folder}\"..."
             if rm -r "${folder}" &> /dev/null; then echo -e "${GREEN}#${RESET} Successfully removed \"${folder}\"! \\n"; else abort_reason="Failed to remove ${folder}."; abort; fi
           done < "${eus_dir}/paid-certificates/list.tmp"
           rm --force "${eus_dir}/paid-certificates/list.tmp" &> /dev/null;;
        [Nn]*) ;;
    esac
  fi
}

paid_certificate() {
  if ! [[ -d "${eus_dir}/paid-certificates" ]]; then mkdir -p "${eus_dir}/paid-certificates" &> /dev/null; fi
  if [[ "${is_cloudkey}" == 'true' ]] && [[ "${unifi_core_system}" != 'true' ]] && dpkg -l unifi-talk 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then create_eus_certificates_file=true; fi
  if dpkg -l uas-led 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi" && [[ "${unifi_core_system}" != 'true' ]]; then if dpkg -l | awk '{print $2}' | grep -iq "^docker.io\\|^docker-ce"; then if docker ps -a | grep -iq 'ubnt/eot'; then create_eus_certificates_file=true; fi; fi; fi
  if [[ "${is_cloudkey}" == 'true' ]] && [[ "${unifi_core_system}" != 'true' ]]; then create_eus_crt_file=true; create_eus_key_file=true; fi
  if [[ "${unifi_core_system}" == 'true' ]]; then create_eus_crt_file=true; create_eus_key_file=true; fi
  if dpkg -l | grep -iq "\\bUAS\\b\\|UniFi Application Server" && [[ "${unifi_core_system}" != 'true' ]]; then create_eus_crt_file=true; create_eus_key_file=true; fi
  if dpkg -l unifi-video 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi" && [[ "${unifi_core_system}" != 'true' ]]; then create_ufv_crts=true; fi
  backup_paid_certificate
  header
  paid_cert=true
  if [[ -f "${chain_crt}" ]]; then
    echo -e "\\n------- Creating \"${eus_dir}/paid-certificates/eus_unifi.p12\" ------- $(date +%F-%R) -------\\n" &>> "${eus_dir}/logs/paid_certificate.log"
    echo -e "${WHITE_R}#${RESET} Creating \"${eus_dir}/paid-certificates/eus_unifi.p12\"..."
    # shellcheck disable=SC2086
    if openssl pkcs12 -export -inkey "${priv_key}" -in "${signed_crt}" -in "${chain_crt}" -out "${eus_dir}/paid-certificates/eus_unifi.p12" -name unifi -password pass:aircontrolenterprise ${openssl_legacy_flag} &>> "${eus_dir}/logs/paid_certificate.log"; then echo -e "${GREEN}#${RESET} Successfully created \"${eus_dir}/paid-certificates/eus_unifi.p12\"! \\n"; else abort_reason="Failed to create ${eus_dir}/paid-certificates/eus_unifi.p12."; abort; fi
    if [[ "${create_ufv_crts}" == 'true' ]]; then
      echo -e "\\n------- Creating \"${eus_dir}/paid-certificates/ufv-server.cert.der\" ------- $(date +%F-%R) -------\\n" &>> "${eus_dir}/logs/paid_certificate.log"
      echo -e "${WHITE_R}#${RESET} Creating \"${eus_dir}/paid-certificates/ufv-server.cert.der\"..."
      if openssl x509 -outform der -in "${signed_crt}" -in "${chain_crt}" -out "${eus_dir}/paid-certificates/ufv-server.cert.der" &>> "${eus_dir}/logs/paid_certificate.log"; then echo -e "${GREEN}#${RESET} Successfully created \"${eus_dir}/paid-certificates/ufv-server.cert.der\"!"; else abort_reason="Failed to create ${eus_dir}/paid-certificates/ufv-server.cert.der."; abort; fi
    fi
  elif [[ -f "${intermediate_crt}" ]]; then
    echo -e "\\n------- Creating \"${eus_dir}/paid-certificates/eus_unifi.p12\" ------- $(date +%F-%R) -------\\n" &>> "${eus_dir}/logs/paid_certificate.log"
    echo -e "${WHITE_R}#${RESET} Creating \"${eus_dir}/paid-certificates/eus_unifi.p12\"..."
    # shellcheck disable=SC2086
    if openssl pkcs12 -export -inkey "${priv_key}" -in "${signed_crt}" -certfile "${intermediate_crt}" -out "${eus_dir}/paid-certificates/eus_unifi.p12" -name unifi -password pass:aircontrolenterprise ${openssl_legacy_flag} &>> "${eus_dir}/logs/paid_certificate.log"; then echo -e "${GREEN}#${RESET} Successfully created \"${eus_dir}/paid-certificates/eus_unifi.p12\"!"; else abort_reason="Failed to create ${eus_dir}/paid-certificates/eus_unifi.p12."; abort; fi
    if [[ "${create_ufv_crts}" == 'true' ]]; then
      echo -e "\\n------- Creating \"${eus_dir}/paid-certificates/ufv-server.cert.der\" ------- $(date +%F-%R) -------\\n" &>> "${eus_dir}/logs/paid_certificate.log"
      echo -e "${WHITE_R}#${RESET} Creating \"${eus_dir}/paid-certificates/ufv-server.cert.der\"..."
      if openssl x509 -outform der -in "${signed_crt}" -out "${eus_dir}/paid-certificates/ufv-server.cert.der" &>> "${eus_dir}/logs/paid_certificate.log"; then echo -e "${GREEN}#${RESET} Successfully created \"${eus_dir}/paid-certificates/ufv-server.cert.der\"!"; else abort_reason="Failed to create ${eus_dir}/paid-certificates/ufv-server.cert.der."; abort; fi
    fi
  else
    echo -e "\\n------- Creating \"${eus_dir}/paid-certificates/eus_unifi.p12\" ------- $(date +%F-%R) -------\\n" &>> "${eus_dir}/logs/paid_certificate.log"
    echo -e "${WHITE_R}#${RESET} Creating \"${eus_dir}/paid-certificates/eus_unifi.p12\"..."
    # shellcheck disable=SC2086
    if openssl pkcs12 -export -inkey "${priv_key}" -in "${signed_crt}" -out "${eus_dir}/paid-certificates/eus_unifi.p12" -name unifi -password pass:aircontrolenterprise ${openssl_legacy_flag} &>> "${eus_dir}/logs/paid_certificate.log"; then echo -e "${GREEN}#${RESET} Successfully created \"${eus_dir}/paid-certificates/eus_unifi.p12\"!"; else abort_reason="Failed to create ${eus_dir}/paid-certificates/eus_unifi.p12."; abort; fi
    if [[ "${create_ufv_crts}" == 'true' ]]; then
      echo -e "\\n------- Creating \"${eus_dir}/paid-certificates/ufv-server.cert.der\" ------- $(date +%F-%R) -------\\n" &>> "${eus_dir}/logs/paid_certificate.log"
      echo -e "${WHITE_R}#${RESET} Creating \"${eus_dir}/paid-certificates/ufv-server.cert.der\"..."
      if openssl x509 -outform der -in "${signed_crt}" -out "${eus_dir}/paid-certificates/ufv-server.cert.der" &>> "${eus_dir}/logs/paid_certificate.log"; then echo -e "${GREEN}#${RESET} Successfully created \"${eus_dir}/paid-certificates/ufv-server.cert.der\"!"; else abort_reason="Failed to create ${eus_dir}/paid-certificates/ufv-server.cert.der."; abort; fi
    fi
  fi
  if [[ "${create_ufv_crts}" == 'true' ]]; then
    echo -e "\\n------- Creating \"${eus_dir}/paid-certificates/ufv-server.key.der\" ------- $(date +%F-%R) -------\\n" &>> "${eus_dir}/logs/paid_certificate.log"
    echo -e "${WHITE_R}#${RESET} Creating \"${eus_dir}/paid-certificates/ufv-server.key.der\"..."
    if openssl pkcs8 -topk8 -nocrypt -in "${priv_key}" -outform DER -out "${eus_dir}/paid-certificates/ufv-server.key.der" &>> "${eus_dir}/logs/paid_certificate.log"; then echo -e "${GREEN}#${RESET} Successfully created \"${eus_dir}/paid-certificates/ufv-server.key.der\"!"; else abort_reason="Failed to create ${eus_dir}/paid-certificates/ufv-server.key.der."; abort; fi
  fi
  if [[ "${create_eus_key_file}" == 'true' ]]; then
    echo -e "\\n------- Creating \"${eus_dir}/paid-certificates/eus_key_file.key\" from \"${eus_dir}/paid-certificates/eus_unifi.p12\" ------- $(date +%F-%R) -------\\n" &>> "${eus_dir}/logs/paid_certificate.log"
    echo -e "${WHITE_R}#${RESET} Creating \"${eus_dir}/paid-certificates/eus_key_file.key\" from \"${eus_dir}/paid-certificates/eus_unifi.p12\"..."
    # shellcheck disable=SC2086
    if openssl pkcs12 -in "${eus_dir}/paid-certificates/eus_unifi.p12" -nodes -nocerts -out "${eus_dir}/paid-certificates/eus_key_file.key" -password pass:aircontrolenterprise ${openssl_legacy_flag} &>> "${eus_dir}/logs/paid_certificate.log"; then echo -e "${GREEN}#${RESET} Successfully created \"${eus_dir}/paid-certificates/eus_key_file.key\" from \"${eus_dir}/paid-certificates/eus_unifi.p12\"!"; else abort_reason="Failed to create ${eus_dir}/paid-certificates/eus_key_file.key from ${eus_dir}/paid-certificates/eus_unifi.p12."; abort; fi
  fi
  if [[ "${create_eus_crt_file}" == 'true' ]]; then
    echo -e "\\n------- Creating \"${eus_dir}/paid-certificates/eus_crt_file.crt\" from \"${eus_dir}/paid-certificates/eus_unifi.p12\" ------- $(date +%F-%R) -------\\n" &>> "${eus_dir}/logs/paid_certificate.log"
    echo -e "${WHITE_R}#${RESET} Creating \"${eus_dir}/paid-certificates/eus_crt_file.crt\" from \"${eus_dir}/paid-certificates/eus_unifi.p12\"..."
    # shellcheck disable=SC2086
    if openssl pkcs12 -in "${eus_dir}/paid-certificates/eus_unifi.p12" -clcerts -nokeys -out "${eus_dir}/paid-certificates/eus_crt_file.crt" -password pass:aircontrolenterprise ${openssl_legacy_flag} &>> "${eus_dir}/logs/paid_certificate.log"; then echo -e "${GREEN}#${RESET} Successfully created \"${eus_dir}/paid-certificates/eus_crt_file.crt\" from \"${eus_dir}/paid-certificates/eus_unifi.p12\"!"; else abort_reason="Failed to create ${eus_dir}/paid-certificates/eus_crt_file.crt from ${eus_dir}/paid-certificates/eus_unifi.p12."; abort; fi
  fi
  if [[ "${create_eus_certificates_file}" == 'true' ]]; then
    echo -e "\\n------- Creating \"${eus_dir}/paid-certificates/eus_certificates_file.pem\" from \"${eus_dir}/paid-certificates/eus_unifi.p12\" ------- $(date +%F-%R) -------\\n" &>> "${eus_dir}/logs/paid_certificate.log"
    echo -e "${WHITE_R}#${RESET} Creating \"${eus_dir}/paid-certificates/eus_certificates_file.pem\" from \"${eus_dir}/paid-certificates/eus_unifi.p12\"..."
    # shellcheck disable=SC2086
    if openssl pkcs12 -in "${eus_dir}/paid-certificates/eus_unifi.p12" -nodes -out "${eus_dir}/paid-certificates/eus_certificates_file.pem" -password pass:aircontrolenterprise ${openssl_legacy_flag} &>> "${eus_dir}/logs/paid_certificate.log"; then echo -e "${GREEN}#${RESET} Successfully created \"${eus_dir}/paid-certificates/eus_certificates_file.pem\" from \"${eus_dir}/paid-certificates/eus_unifi.p12\"!"; else abort_reason="Failed to create ${eus_dir}/paid-certificates/eus_certificates_file.pem from ${eus_dir}/paid-certificates/eus_unifi.p12."; abort; fi
  fi
  if [[ "${unifi_core_system}" == 'true' ]]; then
    # shellcheck disable=SC2086
    if openssl pkcs12 -in "${eus_dir}/paid-certificates/eus_unifi.p12" -password pass:aircontrolenterprise -nokeys ${openssl_legacy_flag} | openssl x509 -text -noout | grep -i "signature algorithm" | grep -iq ecdsa &> /dev/null; then
      echo -e "${WHITE_R}#${RESET} UniFi OS doesn't support ECDSA certificates, cancelling script..."
      sleep 6
      cancel_script
    fi
  fi
  import_existing_ssl_certificates
  # shellcheck disable=SC2119
  if [[ "${is_cloudkey}" == 'true' ]] && dpkg --print-architecture | grep -iq 'armhf'; then paid_certificate_uc_ck; fi
  author
  if [[ "${set_lc_all}" == 'true' ]]; then unset LC_ALL &> /dev/null; fi
  if [[ "${stopped_unattended_upgrade}" == 'true' ]]; then systemctl start unattended-upgrades &>> "${eus_dir}/logs/unattended-upgrades.log"; unset stopped_unattended_upgrade; fi
}

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                       What Should we do?                                                                                        #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

if [[ "${script_option_skip}" != 'true' ]]; then
  header
  echo -e "  What do you want to do?\\n\\n"
  echo -e " [   ${WHITE_R}1${RESET}   ]  |  Apply Let's Encrypt Certificates (recommended)"
  echo -e " [   ${WHITE_R}2${RESET}   ]  |  Apply Paid Certificates (advanced)"
  echo -e " [   ${WHITE_R}3${RESET}   ]  |  Restore previous certificates"
  echo -e " [   ${WHITE_R}4${RESET}   ]  |  Restore certificates to original state"
  echo -e " [   ${WHITE_R}5${RESET}   ]  |  Cancel\\n\\n"
  read -rp $'Your choice | \033[39m' unifi_easy_encrypt
  case "$unifi_easy_encrypt" in
      1) certbot_install_function; lets_encrypt;;
      2)
        if [[ ! -f "${priv_key}" ]] || [[ ! -f "${signed_crt}" ]]; then cert_missing=true; fi
        if [[ ! -f "${chain_crt}" ]] && [[ -f "${intermediate_crt}" ]]; then cert_missing=false; fi
        if [[ ! -f "${intermediate_crt}" ]] && [[ -f "${chain_crt}" ]]; then cert_missing=false; fi
        if [[ "${cert_missing}" == 'true' ]]; then
          header_red
          echo -e "${RED}#${RESET} Missing one or more required certificate files..."
          echo -e "${RED}#${RESET} Private Key: \"${priv_key}\""
          echo -e "${RED}#${RESET} Signed Certificate: \"${signed_crt}\""
          if [[ -n "${chain_crt}" ]]; then echo -e "${RED}#${RESET} Chain Certificate file: \"${chain_crt}\""; fi
          if [[ -n "${intermediate_crt}" ]]; then echo -e "${RED}#${RESET} Intermediate Certificate file: \"${intermediate_crt}\""; fi
          echo -e "\\n"
          help_script
        else
          paid_certificate
        fi;;
      3)
        header
        echo -e "${WHITE_R}#${RESET} Restoring certificates may result in browser errors due to invalid certificates."
        read -rp $'\033[39m#\033[0m Do you want to proceed with restoring previous certificates? (y/N) ' yes_no
        restore_previous_certs;;
      4)
        header
        read -rp $'\033[39m#\033[0m Do you want to proceed with restoring to original state? (y/N) ' yes_no
        restore_original_state=true
        restore_previous_certs;;
      5*|"") cancel_script;;
  esac
else
  if [[ "${own_certificate}" == 'true' ]]; then
    if [[ ! -f "${priv_key}" ]] || [[ ! -f "${signed_crt}" ]]; then cert_missing=true; fi
    if [[ ! -f "${chain_crt}" ]] && [[ -f "${intermediate_crt}" ]]; then cert_missing=false; fi
    if [[ ! -f "${intermediate_crt}" ]] && [[ -f "${chain_crt}" ]]; then cert_missing=false; fi
    if [[ "${cert_missing}" == 'true' ]]; then
      header_red
      echo -e "${RED}#${RESET} Missing one or more required certificate files..."
      echo -e "${RED}#${RESET} Private Key: \"${priv_key}\""
      echo -e "${RED}#${RESET} Signed Certificate: \"${signed_crt}\""
      if [[ -n "${chain_crt}" ]]; then echo -e "${RED}#${RESET} Chain Certificate file: \"${chain_crt}\""; fi
      if [[ -n "${intermediate_crt}" ]]; then echo -e "${RED}#${RESET} Intermediate Certificate file: \"${intermediate_crt}\""; fi
      abort_skip_support_file_upload="true"
      abort_reason="Missing one or more required certificate files"
      abort
    else
      paid_certificate
    fi
  else
    certbot_install_function; lets_encrypt
  fi
fi
