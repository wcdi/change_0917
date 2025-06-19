#!/bin/sh
set -eu

sudo="sudo"

# Abort if not root and sudo is unavailable
if ! command -v sudo >/dev/null 2>&1 ; then
  sudo=""
  if [ $USER != "root" ] ; then 
    echo "This script must be run as root."
    exit 1
  fi
fi

# Get distribution
if [ -f /etc/os-release ]; then
  . /etc/os-release
  case "$ID" in
    arch)
      arch
      ;;
    debian)
      case "$NAME" in
        "Parrot Security")
          parrot
          ;;
        *)
          debian
          ;;
      esac
      ;;
    kali)
      kali
      ;;
    openwrt)
      openwrt
      ;;
    ubuntu)
      ubuntu
      ;;
    *)
      echo "This distribution is not supported."
      ;;
  esac
fi


arch(){
  # path
  source_file="/etc/pacman.d/mirrorlist"
  backup_file="$source_file.bk"
  command='echo "Please add -y option when running pacman next time. (for example: pacman -Syu)"'

  # make backup
  if [ -e $backup_file ]; then
    # backup exists
    echo "Backup failed: $backup_file is already."
    exit 1  
  fi
  cp $source_file $source_file.bk

  # change repository
  if [ -f $source_file ]; then
    echo 'Server = https://mirror.hashy0917.net/archlinux/$repo/os/$arch' > $source_file
    cat $backup_file >> $source_file
  fi
}

debian(){
  # path
  source_file="/etc/apt/sources.list"
  backup_file="/etc/apt/sources.list.bk"
  command="apt-get update"
  if [ -e $source_file ]; then
    # after 24.04
    source_file="/etc/apt/sources.list.d/debian.sources"
    backup_file="/etc/apt/debian.sources.bk"
  fi
  
  # make backup
  if [ -e $backup_file ]; then
    # backup exists
    echo "Backup failed: $backup_file is already."
    exit 1  
  fi
  cp $source_file $source_file.bk

  # change repository
  sed -i 's-ht.*//[A-Za-z0-9.]*/-http://mirror.hashy0917.net/-' $source_file

  # update command
  $command
}

kali(){
  # path
  source_file="/etc/apt/sources.list"
  backup_file="/etc/apt/sources.list.bk"
  command="apt-get update"
  if [ -e $source_file ]; then
    # after 24.04
    source_file="/etc/apt/sources.list.d/kali.sources"
    backup_file="/etc/apt/kali.sources.bk"
  fi
  
  # make backup
  if [ -e $backup_file ]; then
    # backup exists
    echo "Backup failed: $backup_file is already."
    exit 1  
  fi
  cp $source_file $source_file.bk

  # change repository
  sed -i 's-ht.*//[A-Za-z0-9.]*/-http://mirror.hashy0917.net/-' $source_file

  # update command
  $command
}

openwrt(){
  # path
  source_file="/etc/opkg/distfeeds.conf"
  backup_file="$source_file.bk"
  command="opkg update"
  if [ -d /etc/apk ]; then
    # Detect apk-based OpenWrt 
    source_file="/etc/apk/repositories.d/distfeeds.list"
    backup_file="$source_file.bk"
    command="apk update"
  fi

  # make backup
  if [ -e $source_file.bk ]; then
    # backup exists
    echo "Backup failed: $backup_file is already."
    exit 1  
  fi
  cp $source_file $source_file.bk

  # change repository
  sed -i 's-ht.*//[A-Za-z0-9.]*/-http://mirror.hashy0917.net/openwrt/-' $source_file
    
  # update command
  $command
}

parrot(){
  # path
  source_file="/etc/apt/sources.list"
  backup_file="/etc/apt/sources.list.bk"
  command="apt-get update"
  
  # make backup
  if [ -e $backup_file ]; then
    # backup exists
    echo "Backup failed: $backup_file is already."
    exit 1  
  fi
  cp $source_file $source_file.bk

  # change repository
  # (Preserve paths that include 'direct'.)
  sed -i 's-ht.*//[A-Za-z0-9.]*/-http://mirror.hashy0917.net/-' $source_file
  sed -i 's-http://mirror.hashy0917.net/direct/parrot-https://deb.parrot.sh/direct/parrot-' $source_file

  # update command
  $command
}

ubuntu(){
  # set path
  source_file="/etc/apt/sources.list"
  backup_file="/etc/apt/sources.list.bk"
  command="apt-get update"
  if $sudo test -e $source_file ; then
    # after 24.04
    source_file="/etc/apt/sources.list.d/ubuntu.sources"
    backup_file="/etc/apt/ubuntu.sources.bk"
  fi

  # Detect "mirror.hashy0917.net" domain from $source_file 
  if $sudo grep "mirror.hashy0917.net" $source_file >/dev/null 2>&1 ; then
    echo "Already changed: Detected “mirror.hashy0917.net” domain in $source_file"
    exit 1
  fi
  
  # make backup
  if $sudo test -e $backup_file ; then
    # backup exists
    echo "Backup failed: $backup_file is already."
    exit 1  
  fi
  $sudo cp $source_file $source_file.bk

  # change repository
  $sudo sed -i 's-ht.*//[A-Za-z0-9.]*/-http://mirror.hashy0917.net/-' $source_file

  # update command
  $sudo $command
}

