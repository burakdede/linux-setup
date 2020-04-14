# Linux Machine Setup Guide

> tldr; just run the `run.sh` and it will take care of the rest

1. Install OS
- [TODO] here put the information about how to make live USB for the linux distro

2. Install Updates
- run `install.sh` to get the latest updates with apt
- install some packages necessary for next steps (eg. clipboard copy)
- install apt packages from `apt-packages`
- install snap packages

3. Git & Github
- run `git.sh`
- It will generate new ssh key for github and put into your clipboard
- Launches ssh agent and will ask it to cache the new key
- Opens github settings to enter the new ssh key for the new machine
- Test new ssh key against github
- Sets cache TTL for 1 hour

4. SDKMAN
- run `sdk.sh`
- install sdkman
- install all lang. runtimes and frameworks
