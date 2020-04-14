#!/usr/bin/env bash
#
echo ""
echo "-------------------------------INSTALL SDK MAN ITSELF-----------------------------------"
curl -s "https://get.sdkman.io" | bash
source "$HOME/.sdkman/bin/sdkman-init.sh"
echo ""

echo ""
echo "-------------------------------UPDATE SDKMAN-----------------------------------"
sdk selfupdate
sdk update
echo ""

echo ""
echo "-------------------------------INSTALL LANGUAGE RUNTIME, FRAMEWORKS, LIBRARIES-----------------------------------"
sdk install maven
sdk install gradle
sdk install java
sdk install groovy
sdk install scala
sdk install kotlin
sdk install springboot
sdk install grails
sdk install visualvm
sdk install sbt
echo ""
