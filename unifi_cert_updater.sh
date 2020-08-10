#!/bin/bash
# Script to update the java keystore the Unifi Network Controller uses for
# certificate managment enabling use of self signed certs.
# Last Modified 08/10/2020

### 
### This script is designed to take a x.509 certificate and key files
### and convert them to a combined format that the java keystore uses so you
### can use self signed certs with the Unifi Network Controller.
### As long as you have placed both the .crt and .key files inside of:
###     "$HOME/certs/"
### the script should do the rest.  To ensure any existing certs are not
### overwritten you must place your cert files inside the certs directory
### the first time the script is used.

RESET='\033[0m'
GRAY_R='\033[39m'
WHITE_R='\033[39m'
RED='\033[1;31m' # Light Red.
GREEN='\033[1;32m' # Light Green.

user_home=$(eval echo ~${SUDO_USER})
priv_key="$(ls $user_home/certs/*.key)"
priv_cert="$(ls $user_home/certs/*.crt)"
certs_dir="$user_home/certs"
combined_cert="${certs_dir}/combined_cert.p12"
cert_backups_dir="${certs_dir}/backups"

help_text() {
  sed -rn 's/^### ?//;T;p' "$0"
}

header_red() {
  clear
  clear
  echo -e "${RED}#########################################################################${RESET}\\n"
}

# Check for root (SUDO).
if [[ "$EUID" -ne 0 ]]; then
  header_red
  echo -e "${WHITE_R}#${RESET} The script need to be run as root...\\n\\n"
  echo -e "${WHITE_R}#${RESET} Try again as root or with \"sudo\""
  exit 1
fi

# Check for cert backup directory creating it if not found.
if [ ! -d $cert_backups_dir ]; then
  mkdir -p $cert_backups_dir;
fi

# Backup&Combine certs then import them into the java keystore.
import_certs() {
  echo "" && echo -e "${WHITE_R}#${RESET}Backing up old keys"
  cp /usr/lib/unifi/data/keystore "${cert_backups_dir}/keystore_$(date +%Y%m%d_%H%M)"
  echo -e "${GREEN}# Success...Keys backed up inside ${cert_backups_dir}${RESET}" && echo ""
  echo "" && echo -e "${WHITE_R}#${RESET}Combining cert and key..."
  openssl pkcs12 -export -inkey "${priv_key}" -in "${priv_cert}" -out "${combined_cert}" -name unifi -password pass:aircontrolenterprise
  echo -e "${GREEN}# Success...${RESET}"
  keytool -delete -alias unifi -keystore /usr/lib/unifi/data/keystore -deststorepass aircontrolenterprise
  keytool -importkeystore -deststorepass aircontrolenterprise -destkeypass aircontrolenterprise -destkeystore /usr/lib/unifi/data/keystore -srckeystore "${combined_cert}" -srcstoretype PKCS12 -srcstorepass aircontrolenterprise -alias unifi -noprompt
  chown -R unifi:unifi /usr/lib/unifi/data/keystore &> /dev/null
  service unifi restart && echo -e "${GREEN}# Successfully imported the SSL certificates into the UniFi Network Controller!${RESET}" || echo -e "${RED}#${RESET} Failed to import the SSL certificates into the UniFi Network Controller!" && sleep 2
}

# Remove the combined cert to ensure next run is up to date.
cleanup() {
  rm "${combined_cert}"
}

clear
help_text
sleep 2
import_certs
cleanup
exit 0