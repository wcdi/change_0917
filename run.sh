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
  command="opkg update"

  # APK対応
  if [ -d /etc/apk ]; then
    source_file="/etc/apk/repositories.d/distfeeds.list"
    command="apk update"
  fi

  # バックアップが存在する場合はエラーにする
  if [ -f $source_file.bk ]; then
    cp $source_file $source_file.bk
  else 
    echo "Backup failed: $source_file.bk is already."
    exit 1
  fi

  # URLを変更し、ファイルを書き換える
  if awk '{ 
      # URLがある行を変更する
      if ($0~/ht.*\/\/[A-Za-z0-9.]*\//){ 
        # snapshots or releasesでURLを特定する
        if (sub(/ht.*\/\/[A-Za-z0-9.]*\/.*snapshots/, "http://mirror.hashy0917.net/openwrt/snapshots") == 0) {
          sub(/ht.*\/\/[A-Za-z0-9.]*\/.*releases/, "http://mirror.hashy0917.net/openwrt/releases")
        }
        res=1 
      } 
      print $0
    } 
    END {
      # 変更があった場合は1(true)を出力する
      exit res
    }' $source_file > /tmp/changed_$(basename $source_file) ; then
    rm $source_file
    mv /tmp/changed_$(basename $source_file) $source_file
    $command
  else
    echo "Update failed: Already modified."
    exit 1
  fi
}

parrot(){
  APT="/etc/apt"
  source_file="${APT}/sources.list.d/parrot.list"
  # バックアップ作成
  cp $source_file ${APT}/parrot.list.bk
  sed -i 's-ht.*//[A-Za-z0-9.]*/-http://mirror.hashy0917.net/-' $source_file
  # directがついているものだけは元に戻す
  sed -i 's-http://mirror.hashy0917.net/direct/parrot-https://deb.parrot.sh/direct/parrot-' $source_file
  apt-get update
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
      echo "https://mirror.hashy0917.net/"
      ;;
  esac
fi
