# Linux Machine Setup Guide

> tldr; just run the `run.sh` and it will take care of the rest. This is for
> Debian systems (tested on latest Ubuntu LTS)

## Steps

1. Install Chrome (manual)
2. Install Password Manager (manual)
3. Install Git
4. Clone the repo with Git
5. Run `run.sh`

# Run Script Breakdown

1. `install.sh` Install Updates
    - run `install.sh` to get the latest updates with apt
    - install some packages necessary for next steps (eg. clipboard copy cmd)
    - install apt packages from `apt-packages`
    - install snap packages
2. `git.sh` Git & Github
    - run `git.sh`
    - It will generate new ssh key for github and put into your clipboard
    - Launches ssh agent and will ask it to cache the new key
    - Opens github settings to enter the new ssh key for the new machine
    - Test new ssh key against github
    - Sets cache TTL for 1 hour
3. `sdk.sh` SDKMAN
    - run `sdk.sh`
    - install sdkman
    - install all lang. runtimes and frameworks
