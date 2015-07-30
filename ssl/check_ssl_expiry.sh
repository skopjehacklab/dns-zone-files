#!/bin/bash

WARNDAYS=60

if [ -z $1 ]; then
    echo "Usage: $0 list_of_ssl_enabled_domains.txt"
    exit 1
fi

ispis=""
while read domain
do
    if [[ ! $domain =~ ^# ]]; then
        cert_expires=`echo | openssl s_client -servername $domain -connect $domain:443 2>/dev/null | openssl x509 -noout -dates| grep notAfter|cut -f2 -d=`
        today=`date +%s`
        cert_expires_formated=`date --date="$cert_expires" +%s`
        expires_days=$((($cert_expires_formated - $today)/60/60/24))

        if [[ "$expires_days" -lt "0" ]]; then
            ispis+="$expires_days days ago did the ssl cert for $domain expire.\e[41m(PANIC)\e[49m\n"
        elif [[ "$expires_days" -lt "$WARNDAYS" ]]; then
            ispis+="\e[7m$expires_days\e[27m days until \e[7m$domain\e[27m ssl cert expires (on $cert_expires). \e[7m(WARNING)\e[27m\n"
        else
            ispis+="$expires_days days until $domain ssl cert expires (on $cert_expires).\n"
        fi
    fi

done < $1
echo -e $ispis | sort --reverse --general-numeric-sort --ignore-leading-blanks
