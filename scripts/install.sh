#!/usr/bin/env bash
#

# keep it clean and updated
echo ""
echo ""
echo "------------UPDATES & UPGRADES FOR LINUX-------------"
echo ">>>>>>>>>>>>>>>>>> running apt-get update && apt-get upgrade"
sudo apt-get update
sudo apt-get upgrade
sudo apt-get autoremove
echo ">>>>>>>>>>>>>>>>>> finished apt-get update && apt-get upgrade"

# copy paste clipboard utility
sudo apt-get install xclip


# install multimedia stuff
sudo apt-get install ubuntu-restricted-extras


# remove amazon related stuff
sudo apt purge ubuntu-web-launchers


echo ""
echo "----INSTALL APT PACKAGES------"


echo ">>>>>>>>>>>>>>> xargs sudo apt-get -y install < apt-packages.txt"
parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
xargs sudo apt-get -y install < "$parent_path"/apt-packages.txt
echo ">>>>>>>>>>>>>>>>>> finished apt installation from apt-packages.txt"
echo ""


echo "----INSTALL NON STANDARD APT PACKAGES---------"


echo ">>>>>>>>>>>>>>>>>>> installing vs code..."
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo apt install ./google-chrome-stable_current_amd64.deb
echo ">>>>>>>>>>>>>>>>>>> installing vs code..."


echo ">>>>>>>>>>>>>>>>>>> installing spotify..."
curl -sS https://download.spotify.com/debian/pubkey_5E3C45D7B312C643.gpg | sudo apt-key add - 
echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list
sudo apt-get update && sudo apt-get install spotify-client
echo ">>>>>>>>>>>>>>>>>>> finished installing spotify..."


# https://www.digitalocean.com/community/tutorials/how-to-install-postgresql-on-ubuntu-20-04-quickstart
echo ">>>>>>>>>>>>>>>>>>> installing PostgreSQL..."
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql.service
echo ">>>>>>>>>>>>>>>>>>> finished installing PostgreSQL..."


# https://www.digitalocean.com/community/tutorials/how-to-install-mysql-on-ubuntu-20-04
echo ">>>>>>>>>>>>>>>>>>> installing MySQL..."
sudo apt install mysql-server
sudo systemctl start mysql.service
echo ">>>>>>>>>>>>>>>>>>> finished installing MySQL..."


# https://code.visualstudio.com/docs/setup/linux
# https://github.com/microsoft/vscode/issues/27970
echo ">>>>>>>>>>>>>>>>>>> installing vs code..."
sudo apt-get install wget gpg
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings
sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
rm -f packages.microsoft.gpg

sudo apt install apt-transport-https
sudo apt update
sudo apt install code
echo ">>>>>>>>>>>>>>>>>>> finished installing vs code..."




echo ""
