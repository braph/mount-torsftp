#!/bin/bash -e


Progname=mount.torsftp
SFTP_Url=""
MountPoint=""
MountOptions=""
TorProxy=127.0.0.1:9050
Password=""

# recommended options (via commandline -o OPTION):
#   UserKnownHostsFile=/dev/null
#   StrictHostKeyChecking=no

# example for an autofs entry:
#
# torsftp         -fstype=torsftp,rw,allow_other,nodev,noatime,UserKnownHostsFile=/dev/null,StrictHostKeyChecking=no,pass=sftp,tor_proxy=192.168.1.100:9050 sftp@ldwvpjcrw5mmekvg.onion:/

export tString=hey

has_value() {
  local Var=$1
  local Value=${!Var}

  if (( ${#Value} )) ; then
    return 0
  else
    return 1
  fi
}

get_char() {
  local Var=$1
  local Value=${!Var}

  if (( ${#Value} )) ; then
    echo "${Value:0:1}"
  else
    return 1
  fi
}

del_char() {
  local Var=$1
  local Value=${!Var}

  if (( ${#Value} )) ; then
    declare -g $Var="${Value:1}"
  else
    return 1
  fi
}

while has_value tString ; do
  Char=`get_char tString`
  del_char tString
  echo "$Char"
done

exit 

get_mount_opt() {
  local MountOpts=$1
  local i=0
  local Opt=
  local Char=

  MountOpts='hey,pass=\ here\nand\, there,opt'

  while (( i < ${#MountOpts} )) ; do
    Char="${MountOpts:$i:1}"

    i=$(( $i + 1 ))

    if [[ "$Char" == '\' ]] ; then
      Char="${MountOpts:$i:1}"
      i=$(( $i + 1 ))
    elif [[ "$Char" == ',' ]] ; then
      echo "$Opt"
      Opt=""
      continue
    fi

    Opt+=$Char

  done

  echo "$Opt"
}

exit


### functions
option_isset() {
  echo "$MountOptions" | grep -q "$1=" || return 1
}

option_get() {
  declare -g MountOptions=$MountOptions
  option_isset "$1" || return 1
  echo "$MountOptions" | grep -Eo "$1=[^,]*" | sed "s/$1=//"
}

option_remove() {
  local Option
  local NewMountOptions=$MountOptions

  for Option; do
    option_isset "$Option" || continue

    NewMountOptions=`echo "$NewMountOptions" | sed -r "s/$Option[^,]*//"`
  done

  echo "$NewMountOptions"
}
###############

while (( $# )) ; do
  Arg=$1; shift

  if [[ "$Arg" == "-o" ]] ; then
    if (( $# )) ; then
      MountOptions+="$1,"
      shift
    else
      echo "$Progname: option '-o' needs a parameter"
      exit 1
    fi
  elif [[ -z "$SFTP_Url" ]] ; then
    SFTP_Url=$Arg
  elif [[ -z "$MountPoint" ]] ; then
    MountPoint=$Arg
  else
    echo "$Progname: too many arguments"
    exit 1
  fi
done

if [[ -z "$SFTP_Url" ]] ; then
  echo "$Progname: no sftp url"
  exit 1
elif [[ -z "$MountPoint" ]] ; then
  echo "$Progname: no mount point"
  exit 1
fi

if option_isset pass; then
  Password=`option_get pass`
fi

if option_isset tor_proxy; then
  TorProxy=`option_get tor_proxy`
fi

MountOptions=`option_remove tor_proxy pass`
MountOptions=`echo "$MountOptions" | tr -s ,`
MountOptions=${MountOptions%,}

type sshfs connect >/dev/null

DefaultOptions="password_stdin,proxycommand=connect -S $TorProxy %h %p"
if [[ -z "$MountOptions" ]] ; then
  MountOptions="$DefaultOptions"
else
  MountOptions="$DefaultOptions,$MountOptions"
fi

echo "$Password" | sshfs -o "$MountOptions" "$SFTP_Url" "$MountPoint"

exit 0
