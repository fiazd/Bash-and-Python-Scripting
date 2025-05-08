#!/bin/bash
# script to get the expired system users older than an inputted year
# USAGE: ./find_expired_users.sh <year>
# Get the current year
year=$1
current_year=$(date +%Y)
if [ -z "$1" ]; then
    year=2020
fi
while IFS=: read -r username _ _ _ _ _; do
  if [[ $(id -u "$username") -ge 1000 ]]; then
    account_creation_year=$(chage -l "$username" | grep "Account expires" | awk -F: '{print $2}' | awk '{print $3}')
    if [[ -z "$account_creation_year" ]]; then
      continue
    fi
    if [[ "$account_creation_year" -le $year ]]; then
      echo "$username,$account_creation_year"
    fi
  fi
done < /etc/passwd | sort -t ',' -k2,2 > /tmp/expired_users_"$year"_and_older
