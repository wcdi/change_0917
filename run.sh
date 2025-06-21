#!/bin/sh
set -eu

AUTHER="wcdi"
SCRIPTVERSION="0.0.0"
REPOURL="https://github.com/wcdi/change_0917"

# args
confirm=1
pkgupd=1
dryrun=0
force=1
while getopts "ynhdsv" opt; do
  case "$opt" in
    "h")
      echo Change the mirror server to mirror.hashy0917.net >&2
      echo >&2
      echo "Usage: $0 [-yn]" >&2
      echo "Options:" >&2
      echo "  -y : Skip confirmation (dockerfile recommended)" >&2
      echo "  -n : Skip package manager updates" >&2
      echo "  -d : Dry run" >&2
      echo "  -s : struct mode" >&2
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
    "s")
      force=0
    ;;
    "v")
      echo "version: $SCRIPTVERSION"
      echo "git url: $REPOURL"
      exit 0
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
    # Check if file exists and contains URLs
    if mysudo test -e "$srcfulpath" && mysudo grep 'ht.*//[A-Za-z0-9.]*/' >/dev/null 2>&1 $srcfulpath ; then
      newsrcfiles="$newsrcfiles $srcfile"
    elif test $force -eq 0 ; then
      echo "$srcfile is not found"  >&2
      echo "" >&2
      echo "Please check your package manager's repository source files." >&2
      echo "If any paths have changed, feel free to file an issue." >&2
      echo "" >&2
      echo "Distribution: $PRETTY_NAME" >&2
      echo "Scripts Version: $SCRIPTVERSION" >&2
      echo "url: $REPOURL" >&2
      exit 1
    fi
  done
  # newsrcfiles is empty, exit with error message
  if test -z "$newsrcfiles" ; then
    echo "No change files found." >&2
    echo "" >&2
    echo "Hint: the program looked for the following files: $srcfiles" >&2
    echo "Please check your package manager's repository source files." >&2
    echo "If any paths have changed, feel free to file an issue." >&2
    echo "" >&2
    echo "Distribution: $PRETTY_NAME" >&2
    echo "Scripts Version: $SCRIPTVERSION" >&2
    echo "url: $REPOURL" >&2
    exit 1
  fi
  srcfiles=$newsrcfiles

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
  cd $tmppath
    for srcfile in $srcfiles; do
      if grep -E 'ht.*//[A-Za-z0-9.]*/openwrt/' >/dev/null 2>&1 $srcfile ; then
        sed -i 's-ht.*//[A-Za-z0-9.]*/openwrt/-http://mirror.hashy0917.net/openwrt/-' $srcfile
      else
        sed -i 's-ht.*//[A-Za-z0-9.]*/-http://mirror.hashy0917.net/openwrt/-' $srcfile
      fi
    done
  cd - > /dev/null
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
      force=0
    ;;
    debian)
      pkgmgr="apt-get update"
      srcpath="/etc/apt"
      srcfiles="sources.list"
      bkpath="/etc/apt/backup"
      case "$NAME" in
        "Parrot Security")
          srcfiles="$srcfiles sources.list.d/parrot.list"
          churl="parrot"
          ;;
        *)
          srcfiles="$srcfiles sources.list.d/debian.sources"
          churl="simple"
          ;;
      esac
      ;;
    kali)
      srcpath="/etc/apt"
      srcfiles="sources.list.d/kali.sources sources.list"
      bkpath="/etc/apt/backup"
      pkgmgr="apt-get update"
      churl="simple"
      ;;
    openwrt)
      srcpath="/etc/opkg"
      srcfiles="distfeeds.conf"
      pkgmgr="opkg update"
      if [ -d /etc/apk ]; then
        # Detect apk-based OpenWrt 
        srcpath="/etc/apk/repositories.d"
        srcfiles="distfeeds.list"
        pkgmgr="apk update"
      fi 
      bkpath=$srcpath
      churl="openwrt"
      force=0
      ;;
    ubuntu)
      srcpath="/etc/apt"
      srcfiles="sources.list.d/ubuntu.sources sources.list"
      bkpath="/etc/apt/backup"
      pkgmgr="apt-get update"
      churl="simple"
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
