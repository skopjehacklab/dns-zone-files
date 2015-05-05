#!/bin/bash

WARNDAYS=140

if [ -z $1 ]; then
    echo "Usage: $0 list_of_ssl_enabled_domains.txt"
    exit 1
fi

while read domain
do
    if [[ ! $domain =~ ^# ]]; then
        cert_expires=`echo | openssl s_client -servername $domain -connect $domain:443 2>/dev/null | openssl x509 -noout -dates| grep notAfter|cut -f2 -d=`
        today=`date +%s`
        cert_expires_formated=`date --date="$cert_expires" +%s`
        expires_days=$((($cert_expires_formated - $today)/60/60/24))

        if [[ "$expires_days" -lt "0" ]]; then
            echo "PANIC, PANIC, PANIC: SSL for $domain expired $expires_days ago!!!"
        elif [[ "$expires_days" -lt "$WARNDAYS" ]]; then
            echo "WARNING: SSL for $domain will expire in $expires_days days (on $cert_expires)."
        else
            echo "SSL for $domain expires in $expires_days days (on $cert_expires)."
        fi
    fi

done < $1
