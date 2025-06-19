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


check() {
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

arch() {
  sed -i '1i server = https://mirror.hashy0917.net/archlinux/$repo/os/$arch' $tmpfile
}

simple() {
  sed -i 's-ht.*//[A-Za-z0-9.]*/-http://mirror.hashy0917.net/-' $tmpfile
}

parrot() {
  sed -i 's-ht.*//[A-Za-z0-9.]*/-http://mirror.hashy0917.net/-' $tmpfile
  # (Preserve paths that include 'direct'.)
  sed -i 's-http://mirror.hashy0917.net/direct/parrot-https://deb.parrot.sh/direct/parrot-' $tmpfile
}

openwrt() {
  sed -i 's-ht.*//[A-Za-z0-9.]*/-http://mirror.hashy0917.net/openwrt/-' $tmpfile
}

# domain
URL="mirror.hashy0917.net"
# command
diff=$(if ! command -v diff 2>/dev/null ; then printf 'cat'; fi)
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
      echo "This distribution is not supported."
      exit 1
      ;;
  esac
fi

# check files
check

# change repository
mysudo cat $srcpath > $tmpfile
eval "$churl"

# show diff
if test $yes -eq 1 ; then
  mysudo $diff $srcpath $tmpfile || true
  echo 'Apply the changes? [confirm]'
  read i
else
  i=""
fi

if test -z $i ; then
  # make backup
  mysudo cp $srcpath $bkpath

  # update command
  mysudo rm $srcpath
  mysudo cp $tmpfile $srcpath
  mysudo $pkgmgr

  echo "The script has finished successfully."
  exit 0
else 
  echo 'abort.'
  exit 1
fi 
