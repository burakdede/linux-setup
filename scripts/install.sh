#!/usr/bin/env bash
#
echo ""
echo ""
echo "------------UPDATES & UPGRADES FOR LINUX-------------"
echo ">>>>>>>>>>>>>>>>>> apt-get update && apt-get upgrade"
# keep it clean and updated
sudo apt-get update
sudo apt-get upgrade
sudo apt-get autoremove
# copy paste clipboard utility
sudo apt-get install xclip
# tweak some of the gnome defaults
# sudo apt-get install gnome-tweak-tool
# just in case I am running old version of linux https://snapcraft.io/docs/installing-snap-on-ubuntu
sudo apt-get install snapd
# install multimedia stuff
sudo apt-get install ubuntu-restricted-extras
# remove amazon related stuff
sudo apt purge ubuntu-web-launchers
echo ""

echo "----INSTALL APT PACKAGES------"
echo ">>>>>>>>>>>>>>> xargs sudo apt-get -y install < apt-packages.txt"
parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
xargs sudo apt-get -y install < "$parent_path"/apt-packages.txt
echo ""

echo "---------INSTALL SNAP PACKAGES---------"
echo ">>>>>>>>>>>>>>>>>>> snap install packages..."
# unfortunately if one have a confinement of --classic all need to be separate command instead of one
# https://snapcraft.io/docs/snap-confinement
sudo snap install intellij-idea-ultimate --classic
sudo snap install datagrip --classic
sudo snap install rubymine --classic
sudo snap install pycharm-professional --classic
sudo snap install webstorm --classic
sudo snap install --edge node --classic
sudo snap install slack --classic
sudo snap install discord --classic
sudo snap install signal-desktop --classic
sudo snap install vlc --classic
sudo snap install heroku --classic
sudo snap install gimp --classic
sudo snap install spotify --classic
sudo snap install android-studio --classic
sudo snap install vscode --classic
sudo snap install sublime-text --classic
sudo snap install eclipse --classic
echo ""
