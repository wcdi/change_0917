#!/bin/sh
set -eu

# command
sudo=$(command -v diff 2>/dev/null)
diff=$(if ! command -v diff 2>/dev/null ; then print 'cat'; fi)
pkgmgr=""
churl=""
# repo_list
source_file=""
backup_file=""
# tmp
tmp_file=$(mktemp)
trap 'rm -f "$tmp_file"' EXIT

# Abort if not root and sudo is unavailable
if test -z $sudo ; then
  if [ $USER != "root" ] ; then 
    echo "This script must be run as root."
    exit 1
  fi
fi

# Set variables for each Distribution
if [ -f /etc/os-release ]; then
  . /etc/os-release
  case "$ID" in
     ubuntu)
      source_file="/etc/apt/sources.list"
      backup_file="/etc/apt/sources.list.bk"
      pkgmgr="apt-get update"
      churl="debian"

      if $sudo test -e $source_file ; then
        # after 24.04
        source_file="/etc/apt/sources.list.d/ubuntu.sources"
        backup_file="/etc/apt/ubuntu.sources.bk"
      fi
      ;;
    *)
      echo "This distribution is not supported."
      exit 1
      ;;
  esac
fi

# check files
checkfiles

# make backup
$sudo cp $source_file $source_file.bk

# change repository
$churl

# update command
$sudo $pkgmgr

checkfiles() {
  # Detect source_file
  if ! $sudo test -e $source_file ; then
    echo "$source_file is not found"
    exit 1
  fi

  # Detect "mirror.hashy0917.net" domain from $source_file 
  if $sudo grep "mirror.hashy0917.net" $source_file >/dev/null 2>&1 ; then
    echo "Already changed: Detected “mirror.hashy0917.net” domain in $source_file"
    exit 1
  fi

  if $sudo test -e $backup_file ; then
    # backup exists
    echo "Backup failed: $backup_file is already."
    exit 1  
  fi
}

debian() {
  $sudo sed -i 's-ht.*//[A-Za-z0-9.]*/-http://mirror.hashy0917.net/-' $source_file
}