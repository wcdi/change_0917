#!/bin/sh
set -eu

ubuntu(){
  APT="/etc/apt"
  source_file=""
  # 24.04以降ファイルの位置が変わった
  if [ -f $APT/sources.list.d/ubuntu.sources ]; then
    source_file="${APT}/sources.list.d/ubuntu.sources"
    sudo cp $source_file ${APT}/ubuntu.sources.bk
  else
    source_file="${APT}/sources.list"
    sudo cp $source_file $source_file.bk
  fi
  sudo sed -i 's-ht.*//[A-Za-z0-9.]*/-http://mirror.hashy0917.net/-' $source_file
  sudo apt-get update
}

kali(){
  APT="/etc/apt"
  source_file=""
  if [ -f $APT/sources.list.d/kali.sources ]; then
    source_file="${APT}/sources.list.d/kali.sources"
    sudo cp $source_file ${APT}/kali.sources.bk
  else
    source_file="${APT}/sources.list"
    sudo cp $source_file $source_file.bk
  fi
  sudo sed -i 's-ht.*//[A-Za-z0-9.]*/-http://mirror.hashy0917.net/-' $source_file
  sudo apt-get update
}

debian(){
  APT="/etc/apt"
  source_file="${APT}/sources.list"
  if [ -f $source_file ]; then
    sudo cp $source_file $source_file.bk
    sudo sed -i 's-ht.*//.*/-http://mirror.hashy0917.net/debian/-' $source_file
    sudo apt-get update
  fi
}

openwrt(){
  source_file="/etc/opkg/distfeeds.conf"
  sudo cp $source_file $source_file.bk
  sudo sed -i 's-ht.*//[A-Za-z0-9.]*/-http://mirror.hashy0917.net/openwrt/-' $source_file
  sudo opkg update
}

# ディストリビューションのバージョン取得
if [ -f /etc/os-release ]; then
  . /etc/os-release #source /etc/os-release
  case "$ID" in
    ubuntu)
      ubuntu
      ;;
    debian)
      debian
      ;;
    openwrt)
      openwrt
      ;;
    kali)
      kali
      ;;
  esac
fi
