#!/bin/sh
set -eu

# args
yes=1
if test $# -ge 1 ; then
  case "$1" in
    "-y")
      yes=0
    ;;
    *)
      :
    ;;
  esac
fi

# Allow execution from general users in environments where sudo is available.
if test $(id -u) -eq 0 ; then
  mysudo() {
    eval "$@"
  }
else 
  if command -v sudo >/dev/null 2>&1; then
    mysudo() {
      eval "sudo $@"
    }
  elif command -v doas >/dev/null 2>&1; then
    mysudo() {
      eval "doas $@"
    }
  else
    echo "This script must be run as root or have sudo available." >&2
    exit 1
  fi
fi

# File diffs independent of environment
if command -v diff >/dev/null 2>&1; then
  mydiff() {
    eval "diff $srcpath $tmppath" || true
  }
else
  mydiff() {
    echo "<<< old"
    mysudo grep -E 'ht.*//[A-Za-z0-9.]*/' $srcpath || true
    echo ">>> new"
    grep -E 'ht.*//[A-Za-z0-9.]*/' $tmppath || true
  }
fi


check() {
  # Detect source_file
  if ! mysudo test -e $srcpath ; then
    echo "$srcpath is not found"  >&2
    exit 1
  fi

  # Detect $URL domain from $source_file 
  if mysudo grep $URL $srcpath >/dev/null 2>&1 ; then
    echo "Already changed: Detected “$URL” domain in $srcpath"  >&2
    exit 1
  fi

  if mysudo test -e $bkpath ; then
    # backup exists
    echo "Backup failed: $bkpath is already."  >&2
    exit 1  
  fi
}

arch() {
  sed -i '1i server = https://mirror.hashy0917.net/archlinux/$repo/os/$arch' $tmppath
}

simple() {
  sed -i 's-ht.*//[A-Za-z0-9.]*/-http://mirror.hashy0917.net/-' $tmppath
}

parrot() {
  sed -i 's-ht.*//[A-Za-z0-9.]*/-http://mirror.hashy0917.net/-' $tmppath
  # (Preserve paths that include 'direct'.)
  sed -i 's-http://mirror.hashy0917.net/direct/parrot-https://deb.parrot.sh/direct/parrot-' $tmppath
}

openwrt() {
  sed -i 's-ht.*//[A-Za-z0-9.]*/-http://mirror.hashy0917.net/openwrt/-' $tmppath
}

commit() {
  # create backup
  mysudo cp $srcpath $bkpath

  # changing sources files
  mysudo rm $srcpath
  mysudo cp $tmppath $srcpath

  # update package cache
  mysudo $pkgmgr
}

# domain
URL="mirror.hashy0917.net"
# command
pkgmgr=""
churl=""
# repo_list
srcpath=""
bkpath=""
# tmp
tmppath=$(mktemp)
trap 'rm -f "$tmppath"' EXIT


# Set variables for each Distribution
if [ -f /etc/os-release ]; then
  . /etc/os-release
  case "$ID" in
    arch)
      srcpath="/etc/pacman.d/mirrorlist"
      bkpath="$srcpath.bk"
      pkgmgr='echo "Please add -y option when running pacman next time. (for example: pacman -Syu)"'
      churl="arch"
    ;;
    debian)
      pkgmgr="apt-get update"
      case "$NAME" in
        "Parrot Security")
          srcpath="/etc/apt/sources.list.d/parrot.list"
          bkpath="/etc/apt/parrot.list.bk"

          if ! mysudo test -e $srcpath ; then
            # before 24.04
            srcpath="/etc/apt/sources.list"
            bkpath="/etc/apt/sources.list.bk"
          fi
          churl="parrot"
          ;;
        *)
          srcpath="/etc/apt/sources.list.d/debian.sources"
          bkpath="/etc/apt/debian.sources.bk"

          if ! mysudo test -e $srcpath ; then
            # before 24.04
            srcpath="/etc/apt/sources.list"
            bkpath="/etc/apt/sources.list.bk"
          fi
          churl="simple"
          ;;
      esac
      ;;
    kali)
      srcpath="/etc/apt/sources.list.d/kali.sources"
      bkpath="/etc/apt/kali.sources.bk"
      pkgmgr="apt-get update"
      churl="simple"

      if ! mysudo test -e $srcpath ; then
        # before 24.04
        srcpath="/etc/apt/sources.list"
        bkpath="/etc/apt/sources.list.bk"
      fi
      ;;
    openwrt)
      srcpath="/etc/opkg/distfeeds.conf"
      bkpath="$srcpath.bk"
      pkgmgr="opkg update"
      churl="openwrt"

      if [ -d /etc/apk ]; then
        # Detect apk-based OpenWrt 
        srcpath="/etc/apk/repositories.d/distfeeds.list"
        bkpath="$srcpath.bk"
        pkgmgr="apk update"
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
      echo "This distribution is not supported."  >&2
      exit 1
      ;;
  esac
fi

# check files
check

# change repository
mysudo cat $srcpath > $tmppath
eval "$churl"

# show diff
if test $yes -eq 1 ; then
  mydiff
  echo 'Apply the changes? [confirm]'
  read i
else
  i=""
fi

if test -z $i ; then
  commit

  echo "The script has finished successfully."
  exit 0
else 
  echo 'abort.' >&2
  exit 1
fi 
