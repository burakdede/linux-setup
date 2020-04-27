#!/usr/bin/env bash
#
echo ""
echo "---------------------------GENERATE SSH KEY FOR GITHUB------------------------------"
ssh-keygen -t rsa -b 4096 -C "burak@burakdede.com"
echo ""

echo ""
echo "---------------------------COPY SSH KEY TO CLIPBOARD------------------------------"
xclip -sel clip < ~/.ssh/id_rsa.pub
echo ""

echo ""
echo "---------------------------START SSH AGENT------------------------------"
eval "$(ssh-agent -s)"
echo ""

echo ""
echo "---------------------------ADD KEY TO SSH-AGENT------------------------------"
ssh-add ~/.ssh/id_rsa
echo ""

echo ""
echo "---------------------------OPEN GITHUB UI & ADD KEY TO SETTINGS------------------------------"
echo "opening github settings to add ssh key."
firefox https://github.com/settings/keys
echo "waiting for 60 seconds to test the new ssh key with github"
sleep 60
echo ""

echo ""
echo ""
echo "---------------------------TEST NEW KEY ADDED AGAINST GITHUB------------------------------"
ssh -T git@github.com -i ~/.ssh/id_rsa
echo ""

echo ""
echo "---------------------------CACHE CREDENTIALS FOR 1HOUR---------------------------"
git config --global credential.helper 'cache --timeout=3600' # setting it to 1 hour now
echo ""
