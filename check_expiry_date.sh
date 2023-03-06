#!/bin/bash
# 2023-3-6

function help() {
echo "check_expiry_date usage"
echo "========="
echo "check_expiry_date [dns/ssl] [fqdn]"

echo -e "\nexample"
echo "--------"
echo "- check_expiry_date.sh dns example.com"
echo "- check_expiry_date.sh ssl www.example.com"

echo -e "\nreturn"
echo "---------"
echo "days to expiry"
}

function debugmsg() {
  [ $debug != "0" ] &&  echo "$1"
}

function calc_expiry() {
expiry_date=$1
date_now=$(date +%s)
debugmsg "expiry:"$expiry_date
debugmsg "now:"$date_now
diff_days=$(( ($expiry_date-$date_now)/86400 ))
echo $diff_days
}

function check_dns() {

var_temp=$(whois ${domainname} |  egrep -i 'Expiration|Expires on' | grep Date | grep -Eo '[0-9]{4}-[0-9]{2}-[0-9]{2}')
dns_expiry="${var_temp:-$(date +"%Y-%m-%d" --date="10 years")}" #dns with auto renew will return nothing, set a temp date after 10 year
debugmsg $dns_expiry

date_dns_expiry=$(date +%s -d ${dns_expiry})  #change format from yyyy-mm-dd to unixtimestamp
calc_expiry ${date_dns_expiry}
}

function check_ssl() {

debugmsg "checkssl domainname:${domainname}"
var_temp=$(curl https://${domainname} -svIk --stderr - | grep "expire date" | grep -Eo ".{3} [ 0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2} [0-9]{4}")

debugmsg "var_temp:${var_temp}"

[ -z "${var_temp}" ] && echo "0" && echo "null" && exit 1

sslcert_expiry="${var_temp:-$(date +%s)}"
debugmsg "ssl_expiry:""${sslcert_expiry}"

date_sslcert_expiry=$(date +%s -d "${sslcert_expiry}")
calc_expiry ${date_sslcert_expiry}
}


#main

debug=0

check_func=$1
domainname=$2
debugmsg "domainname:$domainname"


case "$check_func" in
    "dns") check_dns ${domainname}
        ;;
    "ssl") check_ssl ${domainname}
        ;;
    "") help 
            ;;
    *) help
        ;;
esac
