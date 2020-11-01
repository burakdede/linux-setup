#!/usr/bin/env bash

./scripts/install.sh
./scripts/git.sh
./scripts/sdk.sh

echo ""
echo "----------COPYING DOTFILES TO HOME DIR----------------------------------"
cp -R dotfiles/. ~
echo "------------------------------------------------------------------------"

echo "DONE!!!"
echo "Note that some of these changes require a logout/restart to take effect..."
