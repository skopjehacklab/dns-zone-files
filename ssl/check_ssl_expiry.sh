#!/bin/bash

WARNDAYS=20

if [ -z $1 ]; then
    echo "Usage: $0 list_of_ssl_enabled_domains.txt"
    exit 1
fi
DOMAIN_LIST=$1

function PANIC () {
  echo -e "$1 days ago did the ssl cert for $2 expire.\e[41m(PANIC)\e[49m\n"
}
function WARN () {
  echo -e "\e[7m$1\e[27m days until \e[7m$2\e[27m ssl cert expires (on $3). \e[7m(WARNING)\e[27m"
}
function INFO () {
  echo -e "$1 days until $2 ssl cert expires (on $3)."
}

egrep -v '^#' $DOMAIN_LIST | egrep -v '^[[:space:]]*$' |
( while read line
do
    host=${line%:*}
    port=${line#*:}
    cert=`openssl s_client -servername "$host" -connect "$host:$port" </dev/null 2>/dev/null`
    cert_expires=`echo "$cert" | openssl x509 -noout -enddate | cut -f2 -d=`
    issuer=`echo "$cert" | openssl x509 -noout -issuer`
    issuer=${issuer#*/O=}
    issuer=${issuer%%/*}
    today=`date +%s`
    cert_expires_formated=`date --date="$cert_expires" +%s`
    expires_days=$((($cert_expires_formated - $today)/60/60/24))

    if [[ "$expires_days" -lt "0" ]]; then
        PANIC $expires_days "$host" "$issuer"
    elif [[ "$expires_days" -lt "$WARNDAYS" ]]; then
        WARN $expires_days "$host" "$cert_expires" "$issuer"
    else
        INFO $expires_days "$host" "$cert_expires" "$issuer"
    fi
done ) | sort --reverse --general-numeric-sort --ignore-leading-blanks
