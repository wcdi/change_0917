#!/bin/sh
set -eu

arch(){
  source="/etc/pacman.d/mirrorlist"
  if [ -f $source ]; then
    cp $source ${source}.bk
    echo 'Server = https://mirror.hashy0917.net/archlinux/$repo/os/$arch' > $source
    cat $source.bk >> $source
  fi
  # pacman -Syyu
}

debian(){
  # APT="/etc/apt"
  # source_file="${APT}/sources.list"
  # if [ -f $source_file ]; then
  #    cp $source_file $source_file.bk
  #    sed -i 's-ht.*//.*/-http://mirror.hashy0917.net/debian/-' $source_file
  #    apt-get update
  # fi
  APT="/etc/apt"
  source_file=""
  # 24.04以降ファイルの位置が変わった
  if [ -f $APT/sources.list.d/debian.sources ]; then
    source_file="${APT}/sources.list.d/debian.sources"
     cp $source_file ${APT}/debian.sources.bk
  else
    source_file="${APT}/sources.list"
     cp $source_file $source_file.bk
  fi
   sed -i 's-ht.*//[A-Za-z0-9.]*/-http://mirror.hashy0917.net/-' $source_file
   apt-get update
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
  source_file="/etc/opkg/distfeeds.conf"
   cp $source_file $source_file.bk
   sed -i 's-ht.*//[A-Za-z0-9.]*/-http://mirror.hashy0917.net/openwrt/-' $source_file
   opkg update
}

ubuntu(){
  APT="/etc/apt"
  source_file=""
  # 24.04以降ファイルの位置が変わった
  if [ -f $APT/sources.list.d/ubuntu.sources ]; then
    source_file="${APT}/sources.list.d/ubuntu.sources"
     cp $source_file ${APT}/ubuntu.sources.bk
  else
    source_file="${APT}/sources.list"
     cp $source_file $source_file.bk
  fi
   sed -i 's-ht.*//[A-Za-z0-9.]*/-http://mirror.hashy0917.net/-' $source_file
   apt-get update
}

# ディストリビューションのバージョン取得
if [ -f /etc/os-release ]; then
  . /etc/os-release #source /etc/os-release
  case "$ID" in
    arch)
      arch
      ;;
    debian)
      debian
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
  esac
fi
