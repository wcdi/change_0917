#!/bin/sh
set -eu

# Detect sudo
if test $(id -u) -eq 0 ; then
  mysudo() {
    eval "$@"
  }
else 
  if command -v sudo >/dev/null 2>&1; then
    mysudo() {
      eval "sudo $@"
    }
  else
    echo "This script must be run as root or have sudo available." >&2
    exit 1
  fi
fi


chkfs() {
  # Detect source_file
  if ! mysudo test -e $srcpath ; then
    echo "$srcpath is not found"
    exit 1
  fi

  # Detect $URL domain from $source_file 
  if mysudo grep $URL $srcpath >/dev/null 2>&1 ; then
    echo "Already changed: Detected “$URL” domain in $srcpath"
    exit 1
  fi

  if mysudo test -e $bkpath ; then
    # backup exists
    echo "Backup failed: $bkpath is already."
    exit 1  
  fi
}

simple() {
  sed -i 's-ht.*//[A-Za-z0-9.]*/-http://mirror.hashy0917.net/-' $tmpfile
}

# domain
URL="mirror.hashy0917.net"
# command
diff=$(if ! command -v diff 2>/dev/null ; then print 'cat'; fi)
pkgmgr=""
churl=""
# repo_list
srcpath=""
bkpath=""
# tmp
tmpfile=$(mktemp)
trap 'rm -f "$tmpfile"' EXIT


# Set variables for each Distribution
if [ -f /etc/os-release ]; then
  . /etc/os-release
  case "$ID" in
    debian)
      srcpath="/etc/apt/sources.list.d/debian.sources"
      bkpath="/etc/apt/debian.sources.bk"
      pkgmgr="apt-get update"
      churl="simple"

      if ! mysudo test -e $srcpath ; then
        # before 24.04
        srcpath="/etc/apt/sources.list"
        bkpath="/etc/apt/sources.list.bk"
      fi
      ;;
    ubuntu)
      srcpath="/etc/apt/sources.list.d/ubuntu.sources"
      bkpath="/etc/apt/ubuntu.sources.bk"
      pkgmgr="apt-get update"
      churl="simple"

      if ! mysudo test -e $srcpath ; then
        # before 24.04
        srcpath="/etc/apt/sources.list"
        bkpath="/etc/apt/sources.list.bk"
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

# change repository
mysudo cat $srcpath > $tmpfile
eval "$churl"

# show diff
mysudo $diff $srcpath $tmpfile || true
echo 'Apply the changes? [confirm]'
read i
if test -z $i ; then
  # make backup
  mysudo cp $srcpath $bkpath

  # update command
  mysudo rm $srcpath
  mysudo cp $tmpfile $srcpath
  mysudo $pkgmgr
else 
  echo 'abort.'
fi 