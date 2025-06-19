#!/bin/sh
set -eu

chkfs() {
  # Detect source_file
  if ! $sudo test -e $srcpath ; then
    echo "$srcpath is not found"
    exit 1
  fi

  # Detect "mirror.hashy0917.net" domain from $source_file 
  if $sudo grep "mirror.hashy0917.net" $srcpath >/dev/null 2>&1 ; then
    echo "Already changed: Detected “mirror.hashy0917.net” domain in $srcpath"
    exit 1
  fi

  if $sudo test -e $bkpath ; then
    # backup exists
    echo "Backup failed: $bkpath is already."
    exit 1  
  fi
}

debian() {
  cat $srcpath | sed 's-ht.*//[A-Za-z0-9.]*/-http://mirror.hashy0917.net/-' > $tmpfile
}

# command
sudo=$(command -v sudo 2>/dev/null)
diff=$(if ! command -v diff 2>/dev/null ; then print 'cat'; fi)
pkgmgr=""
churl=""
# repo_list
srcpath=""
bkpath=""
# tmp
tmpfile=$(mktemp)
trap 'rm -f "$tmpfile"' EXIT

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
      srcpath="/etc/apt/sources.list"
      bkpath="/etc/apt/sources.list.bk"
      pkgmgr="apt-get update"
      churl="debian"

      if $sudo test -e $srcpath ; then
        # after 24.04
        srcpath="/etc/apt/sources.list.d/ubuntu.sources"
        bkpath="/etc/apt/ubuntu.sources.bk"
      fi
      ;;
    *)
      echo "This distribution is not supported."
      exit 1
      ;;
  esac
fi

# check files
chkfs

# make backup
$sudo cp $srcpath $srcpath.bk

# change repository
$churl

# show diff
$sudo $diff $srcpath $tmpfile
echo 'Apply the changes? [confirm]'
read

# update command
rm $srcpath
cp $tmpfile $srcpath
$sudo $pkgmgr
