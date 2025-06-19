#!/bin/sh
set -eu

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
  else 
    cp $source_file $source_file.bk
  fi

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
  else 
    cp $source_file $source_file.bk
  fi

  # change repository
  sed -i 's-ht.*//[A-Za-z0-9.]*/-http://mirror.hashy0917.net/-' $source_file

  # update command
  $command
}

kali(){
  APT="/etc/apt"
  source_file=""
  if [ -f $APT/sources.list.d/kali.sources ]; then
    source_file="${APT}/sources.list.d/kali.sources"
     cp $source_file ${APT}/kali.sources.bk
  else
    source_file="${APT}/sources.list"
     cp $source_file $source_file.bk
  fi
   sed -i 's-ht.*//[A-Za-z0-9.]*/-http://mirror.hashy0917.net/-' $source_file
   apt-get update
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
  else 
    cp $source_file $source_file.bk
  fi

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
  else 
    cp $source_file $source_file.bk
  fi

  # change repository
  # (Preserve paths that include 'direct'.)
  sed -i 's-ht.*//[A-Za-z0-9.]*/-http://mirror.hashy0917.net/-' $source_file
  sed -i 's-http://mirror.hashy0917.net/direct/parrot-https://deb.parrot.sh/direct/parrot-' $source_file

  # update command
  $command
}

ubuntu(){
  # path
  source_file="/etc/apt/sources.list"
  backup_file="/etc/apt/sources.list.bk"
  command="apt-get update"
  if [ -e $source_file ]; then
    # after 24.04
    source_file="/etc/apt/sources.list.d/ubuntu.sources"
    backup_file="/etc/apt/ubuntu.sources.bk"
  fi
  
  # make backup
  if [ -e $backup_file ]; then
    # backup exists
    echo "Backup failed: $backup_file is already."
    exit 1  
  else 
    cp $source_file $source_file.bk
  fi

  # change repository
  sed -i 's-ht.*//[A-Za-z0-9.]*/-http://mirror.hashy0917.net/-' $source_file

  # update command
  $command
}

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
