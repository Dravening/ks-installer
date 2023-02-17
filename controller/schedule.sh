#!/usr/bin/env bash

if [[ $1 == "--config" ]] ; then
  cat <<EOF
{
  "configVersion":"v1",
  "schedule": [
    {
      "allowFailure": true,
      "name": "every month",
      "crontab": "0 0 1 * *"
    }
  ]
}
EOF
else
  ansible-playbook /d3os/playbooks/telemetry.yaml -e @/d3os/config/ks-config.json
  if [[ $? -eq 0 ]]; then
    #statements
    str="successsful!"
    echo -e "$str"
  else
    exit
  fi

fi

