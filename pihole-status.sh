#!/usr/bin/env bash

repo="-p" echo -n "$(pihole -v $repo | sed 's/\ *\([^\ ]*\).*/\1/') ";awk "BEGIN {exit !($(pihole -v $repo -l | sed 's/.* v\([0-9\.]*\)/\1/') > $(pihole -v $repo -c | sed 's/.* v\([0-9\.]*\)/\1/'))}" && echo Update Available || echo Up-to-date
repo="-a" echo -n "$(pihole -v $repo | sed 's/\ *\([^\ ]*\).*/\1/') ";awk "BEGIN {exit !($(pihole -v $repo -l | sed 's/.* v\([0-9\.]*\)/\1/') > $(pihole -v $repo -c | sed 's/.* v\([0-9\.]*\)/\1/'))}" && echo Update Available || echo Up-to-date
repo="-f" echo -n "$(pihole -v $repo | sed 's/\ *\([^\ ]*\).*/\1/') ";awk "BEGIN {exit !($(pihole -v $repo -l | sed 's/.* v\([0-9\.]*\)/\1/') > $(pihole -v $repo -c | sed 's/.* v\([0-9\.]*\)/\1/'))}" && echo Update Available || echo Up-to-date


source /home/pihole/piHoleVersion


GetVersionInformation() {
  # Check if version status has been saved
  if [ -e "piHoleVersion" ]; then # the file exists...
    # the file exits, use it
    # shellcheck disable=SC1091
    source piHoleVersion

    # Today is...
    today=$(date +%Y%m%d)

    # was the last check today?
    # last_check is read from ./piHoleVersion
    # shellcheck disable=SC2154
    if [ "${today}" != "${last_check}" ]; then # no, it wasn't today
      # Remove the Pi-hole version file...
      rm -f piHoleVersion
    fi

  else # the file doesn't exist, create it...
    # Gather core version information...
    read -r -a core_versions <<< "$(pihole -v -p)"
    core_version=$(echo "${core_versions[3]}" | tr -d '\r\n[:alpha:]')
    core_version_latest=${core_versions[5]//)}

    if [[ "${core_version_latest}" == "ERROR" ]]; then
      core_version_heatmap=${yellow_text}
    else
      core_version_latest=$(echo "${core_version_latest}" | tr -d '\r\n[:alpha:]')
      # is core up-to-date?
      if [[ "${core_version}" != "${core_version_latest}" ]]; then
        out_of_date_flag="true"
        core_version_heatmap=${red_text}
      else
        core_version_heatmap=${green_text}
      fi
    fi

    # Gather web version information...
    if [[ "$INSTALL_WEB_INTERFACE" = true ]]; then
      read -r -a web_versions <<< "$(pihole -v -a)"
      web_version=$(echo "${web_versions[3]}" | tr -d '\r\n[:alpha:]')
      web_version_latest=${web_versions[5]//)}
      if [[ "${web_version_latest}" == "ERROR" ]]; then
        web_version_heatmap=${yellow_text}
      else
        web_version_latest=$(echo "${web_version_latest}" | tr -d '\r\n[:alpha:]')
        # is web up-to-date?
        if [[ "${web_version}" != "${web_version_latest}" ]]; then
          out_of_date_flag="true"
          web_version_heatmap=${red_text}
        else
          web_version_heatmap=${green_text}
        fi
      fi
    else
      # Web interface not installed
      web_version_heatmap=${red_text}
      web_version="$(printf '\x08')"  # Hex 0x08 is for backspace, to delete the leading 'v'
      web_version="${web_version}N/A" # N/A = Not Available
    fi

    # Gather FTL version information...
    read -r -a ftl_versions <<< "$(pihole -v -f)"
    ftl_version=$(echo "${ftl_versions[3]}" | tr -d '\r\n[:alpha:]')
    ftl_version_latest=${ftl_versions[5]//)}
    if [[ "${ftl_version_latest}" == "ERROR" ]]; then
      ftl_version_heatmap=${yellow_text}
    else
      ftl_version_latest=$(echo "${ftl_version_latest}" | tr -d '\r\n[:alpha:]')
      # is ftl up-to-date?
      if [[ "${ftl_version}" != "${ftl_version_latest}" ]]; then
        out_of_date_flag="true"
        ftl_version_heatmap=${red_text}
      else
        ftl_version_heatmap=${green_text}
      fi
    fi

    # PADD version information...
    padd_version_latest=$(json_extract tag_name "$(curl -s 'https://api.github.com/repos/pi-hole/PADD/releases/latest' 2> /dev/null)")

    # is PADD up-to-date?
    if [[ "${padd_version_latest}" == "" ]]; then
      padd_version_heatmap=${yellow_text}
    else
      if [[ "${padd_version}" != "${padd_version_latest}" ]]; then
        padd_out_of_date_flag="true"
        padd_version_heatmap=${red_text}
      else
        padd_version_heatmap=${green_text}
      fi
    fi

    # was any portion of Pi-hole out-of-date?
    # yes, pi-hole is out of date
    if [[ "${out_of_date_flag}" == "true" ]]; then
      version_status="Pi-hole is out-of-date!"
      version_heatmap=${red_text}
      version_check_box=${check_box_bad}
      pico_status=${pico_status_update}
      mini_status_=${mini_status_update}
      tiny_status_=${tiny_status_update}
      full_status_=${full_status_update}
      mega_status=${mega_status_update}
    else
      # but is PADD out-of-date?
      if [[ "${padd_out_of_date_flag}" == "true" ]]; then
        version_status="PADD is out-of-date!"
        version_heatmap=${red_text}
        version_check_box=${check_box_bad}
        pico_status=${pico_status_update}
        mini_status_=${mini_status_update}
        tiny_status_=${tiny_status_update}
        full_status_=${full_status_update}
        mega_status=${mega_status_update}
      # else, everything is good!
      else
        version_status="Pi-hole is up-to-date!"
        version_heatmap=${green_text}
        version_check_box=${check_box_good}
        pico_status=${pico_status_ok}
        mini_status_=${mini_status_ok}
        tiny_status_=${tiny_status_ok}
        full_status_=${full_status_ok}
        mega_status=${mega_status_ok}
      fi
    fi

    # write it all to the file
    echo "last_check=${today}" > ./piHoleVersion
    {
      echo "core_version=$core_version"
      echo "core_version_latest=$core_version_latest"
      echo "core_version_heatmap=$core_version_heatmap"

      echo "web_version=$web_version"
      echo "web_version_latest=$web_version_latest"
      echo "web_version_heatmap=$web_version_heatmap"

      echo "ftl_version=$ftl_version"
      echo "ftl_version_latest=$ftl_version_latest"
      echo "ftl_version_heatmap=$ftl_version_heatmap"

      echo "padd_version=$padd_version"
      echo "padd_version_latest=$padd_version_latest"
      echo "padd_version_heatmap=$padd_version_heatmap"

      echo "version_status=\"$version_status\""
      echo "version_heatmap=$version_heatmap"
      echo "version_check_box=\"$version_check_box\""

      echo "pico_status=\"$pico_status\""
      echo "mini_status_=\"$mini_status_\""
      echo "tiny_status_=\"$tiny_status_\""
      echo "full_status_=\"$full_status_\""
      echo "mega_status=\"$mega_status\""
    } >> ./piHoleVersion

    # there's a file now
  fi
}
