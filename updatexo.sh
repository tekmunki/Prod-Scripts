#!/bin/bash
# https://github.com/vatesfr/xen-orchestra :: XO community source github.
# https://github.com/ronivay/XenOrchestraInstallerUpdater :: XO community installer github.
# Script is designed for a Debian 10 install.
# Last Modified 08/06/2020

### This script will update Debian using apt-get, check the git repo for any
### new changes, and finally update and restart XO-Server.  If you're looking to
### install XO from source check out: https://github.com/ronivay/XenOrchestraInstallerUpdater
###

RESET='\033[0m'
#GRAY='\033[0;37m'
#WHITE='\033[1;37m'
GRAY_R='\033[39m'
WHITE_R='\033[39m'
RED='\033[1;31m' # Light Red.
GREEN='\033[1;32m' # Light Green.
#BOLD='\e[1m'

header_red() {
  clear
  clear
  echo -e "${RED}#########################################################################${RESET}\\n"
}

# Check for root (SUDO).
if [[ "$EUID" -ne 0 ]]; then
  header_red
  echo -e "${WHITE_R}#${RESET} The script needs to be run as root...\\n\\n"
  echo -e "${GREEN}#${RESET} Please try again with \"sudo\"\\n"
  exit 1
fi

script_logo() {
  cat << "EOF"

Yb  dP  dP"Yb      88   88 88""Yb 8888b.     db    888888 888888 88""Yb     
 YbdP  dP   Yb     88   88 88__dP  8I  Yb   dPYb     88   88__   88__dP     
 dPYb  Yb   dP     Y8   8P 88"""   8I  dY  dP__Yb    88   88""   88"Yb      
dP  Yb  YbodP      `YbodP' 88     8888Y"  dP""""Yb   88   888888 88  Yb     

EOF
}

# regex used to find the ### comments above and print them out when needed
help_text() {
  sed -rn 's/^### ?//;T;p' "$0"
}


apt_get_update() {
  echo -e "${GREEN}-- Updating apt-get..."${RESET}
  apt-get update 2>&1
}

# Upgrade any outdated packages and clean up any packes no longer in use.
apt_get_upgrade() {
  echo -e "${GREEN}-- Upgrading apt-get..."${RESET}
  apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' upgrade
  apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' dist-upgrade
  echo -e "${GREEN}-- Autoremoving unused packages..."${RESET}
  apt-get -y autoremove
  apt-get -y autoclean
  echo -e "${RED}-- Update & Upgrade completed."${RESET}
}

# Make sure XO installer script is up to date before running.
git_update() {
  cd "/root/xoainstaller"
  echo -e "\\n${GREEN}-- Checking for git repo updates...${RESET}"
  git pull
}

# Update XO from the master branch on github
xo_update() {
  echo -e "\\n${GREEN}-- Updating XO-Server...${RESET}"
  /root/xoainstaller/xo-install.sh --update
}

finalize() {
  cd "/root"
  echo -e "\\n\\n${RED}-- All done, make sure everything works...${RESET}"
}

# This format is not neccisary by any means but it helps keep everything modular.
start_update() {
  clear
  clear
  script_logo
  help_text
  sleep 2
  echo -e "${GREEN}Let's begin...${RESET}"
  apt_get_update
  apt_get_upgrade
  git_update
  xo_update
  finalize
}

# run the main functions with any added requirements
start_update
exit 0