#!/bin/sh
set -eu

# args
confirm=1
pkgupd=1
dryrun=0
force=0
while getopts "ynhdf" opt; do
  case "$opt" in
    "h")
      echo Change the mirror server to mirror.hashy0917.net
      echo
      echo "Usage: $0 [-yn]" >&2
      echo "Options:" >&2
      echo "  -y : Skip confirmation (dockerfile recommended)" >&2
      echo "  -n : Skip package manager updates" >&2
      echo "  -d : Dry run" >&2
      echo "  -f : force"
      exit 1
    ;;
    "y")
      confirm=0
    ;;
    "n")
      pkgupd=0
    ;;
    "d")
      dryrun=1
    ;;
    "f")
      force=1
    ;;
    *)
      :
    ;;
  esac
done
usediff=$confirm

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
    eval "diff $difold $difnew" || true
  }
else
  mydiff() {
    echo "<<< old"
    mysudo grep -E 'ht.*//[A-Za-z0-9.]*/' $difold || true
    echo ">>> new"
    grep -E 'ht.*//[A-Za-z0-9.]*/' $difnew || true
  }
fi

check() {
  newsrcfiles=""
  # Detect source_file
  for srcfile in $srcfiles; do
    srcfulpath="$srcpath/$srcfile"
    if ! mysudo test -e "$srcfulpath" ; then
      if test $force -eq 0 ; then
        echo "$srcfile is not found"  >&2
        exit 1
      fi
    else
      newsrcfiles="$newsrcfiles $srcfile"
    fi
  done
  srcfiles=$newsrcfiles
  echo $srcfiles

  # Detect $URL domain from $source_file 
  # Detect source_file
  for srcfile in $srcfiles; do
    srcfulpath="$srcpath/$srcfile"
    if mysudo grep $URL $srcfulpath >/dev/null 2>&1 ; then
      echo "Already changed: Detected “$URL” domain in $srcfile"  >&2
      exit 1
    fi
  done

  for srcfile in $srcfiles; do
    bkfulpath="$bkpath/$srcfile.bk"
    if mysudo test -e $bkfulpath ; then
      # backup exists
      echo "Backup failed: $bkfulpath is already."  >&2
      exit 1  
    fi
  done
}

transaction() {
  # move srcfile to tmp
  for srcfile in $srcfiles; do
    mkdir -p $(dirname "$tmppath/$srcfile")
    mysudo cat "$srcpath/$srcfile" > "$tmppath/$srcfile"
  done

  # create difold
  if test $usediff -eq 1 ; then
    cd $tmppath
      cat $srcfiles > $difold
    cd - > /dev/null
  fi

  # changes url
  eval "$churl"

  # create difnew
  if test $usediff -eq 1 ; then
    cd $tmppath
      cat $srcfiles > $difnew
    cd - > /dev/null
  fi
}

commit() {
  # create backup
  for srcfile in $srcfiles; do
    tmpfulpath="$tmppath/$srcfile"
    srcfulpath="$srcpath/$srcfile"
    bkfulpath="$bkpath/$srcfile.bk"

    mysudo mkdir -p $(dirname $bkfulpath)
    mysudo cp $srcfulpath $bkfulpath

    # changing sources files
    mysudo rm $srcfulpath
    mysudo cp $tmpfulpath $srcfulpath
  done
}

arch() {
  cd $tmppath
    for srcfile in $srcfiles; do
      sed -i '1i Server = https://mirror.hashy0917.net/archlinux/$repo/os/$arch' $srcfile
    done
  cd - > /dev/null
}

simple() {
  cd $tmppath
    for srcfile in $srcfiles; do
      sed -i 's-ht.*//[A-Za-z0-9.]*/-http://mirror.hashy0917.net/-' $srcfile
    done
  cd - > /dev/null
}

parrot() {
  cd $tmppath
    for srcfile in $srcfiles; do
      sed -i 's-ht.*//[A-Za-z0-9.]*/-http://mirror.hashy0917.net/-' $srcfile
      # (Preserve paths that include 'direct'.)
      sed -i 's-http://mirror.hashy0917.net/direct/parrot-https://deb.parrot.sh/direct/parrot-' $srcfile
    done
  cd - > /dev/null
}

openwrt() {
  if grep -E 'ht.*//[A-Za-z0-9.]*/openwrt/' >/dev/null 2>&1 $tmppath ; then
    sed -i 's-ht.*//[A-Za-z0-9.]*/openwrt/-http://mirror.hashy0917.net/openwrt/-' $tmppath
  else
    sed -i 's-ht.*//[A-Za-z0-9.]*/-http://mirror.hashy0917.net/openwrt/-' $tmppath
  fi
}

#########################################################################

# set default variables.

# domain
URL="mirror.hashy0917.net"
# command
pkgmgr=""
churl=""
# repo_list
srcpath=""
srcfiles=""
bkpath=""
# tmp
tmppath=$(mktemp -d)
difold="$tmppath/old"
difnew="$tmppath/new"
trap 'rm -rf "$tmppath"' EXIT INT TERM


# Set variables for each Distribution
if [ -f /etc/os-release ]; then
  . /etc/os-release
  case "$ID" in
    arch)
      srcpath="/etc/pacman.d"
      srcfiles="mirrorlist"
      bkpath=$srcpath
      pkgmgr='echo "Please add -y option when running pacman next time. (for example: pacman -Syu)"'
      churl="arch"
    ;;
    debian)
      pkgmgr="apt-get update"
      srcpath="/etc/apt"
      bkpath="/etc/apt/backup"
      case "$NAME" in
        "Parrot Security")
          srcfiles="sources.list.d/parrot.list"

          if ! mysudo test -e "$srcpath/$srcfiles" ; then
            # before 24.04
            srcfiles="sources.list"
            bkpath="/etc/apt"
          fi
          churl="parrot"
          ;;
        *)
          srcfiles="sources.list.d/debian.sources"

          if ! mysudo test -e "$srcpath/$srcfiles" ; then
            # before 24.04
            srcfiles="sources.list"
            bkpath="/etc/apt"
          fi
          churl="simple"
          ;;
      esac
      ;;
    kali)
      srcpath="/etc/apt"
      srcfiles="sources.list.d/kali.sources"
      bkpath="/etc/apt/backup"
      pkgmgr="apt-get update"
      churl="simple"

      if ! mysudo test -e "$srcpath/$srcfiles" ; then
        # before 24.04
        srcfiles="sources.list"
        bkpath="/etc/apt"
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
      srcpath="/etc/apt"
      srcfiles="sources.list.d/ubuntu.sources"
      bkpath="/etc/apt/backup"
      pkgmgr="apt-get update"
      churl="simple"

      if ! mysudo test -e "$srcpath/$srcfiles" ; then
        # before 24.04
        srcfiles="sources.list"
        bkpath="/etc/apt"
      fi
      ;;
    *)
      echo "This distribution is not supported."  >&2
      exit 1
      ;;
  esac
else
  echo "This OS is not supported."  >&2
  exit 1
fi

# check files
check

# change repository
transaction

# dry run
if test $dryrun -eq 1 ; then
  mydiff
  exit 0
fi

input=""

# user confirm
if test $confirm -eq 1 ; then
  # show diff
  mydiff
  echo 'Apply the changes? [confirm]'
  read input < /dev/tty
fi

if test -z $input ; then
  # file changed
  commit

  # update package cache
  if test $pkgupd -eq 1 ; then
    mysudo $pkgmgr
  fi

  echo "The script has finished successfully."
  exit 0
else 
  echo 'abort.' >&2
  exit 1
fi 
