#!/usr/bin/python3

# mount.torsftp - mount sshfs through tor using /etc/fstab
# Copyright (C) 2015 Benjamin Abendroth
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# This script needs the 'connect' program, get it from https://savannah.gnu.org/maintenance/connect.c

# example:
# $TorProxy: "127.0.0.1:9050"
# $SFTPTorServer: ldwvpjcrw5mmekvg.onion
# $SFTPUser: sftp
# $SFTPPass: sftp

# sshfs -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o proxycommand="/usr/local/bin/connect -S $TorProxy %h %p" -o password_stdin $SFTPUser@$SFTPTorServer:/ $MountPoint <<< "$SFTPPass"

import argparse
from subprocess import Popen, PIPE

argp = argparse.ArgumentParser(
    description='mount sshfs through tor using /etc/fstab',
    epilog='You have to specify "password=<pass>" and "tor=<ip:port>" as option in /etc/fstab.'
)
argp.add_argument('--options', '-o', metavar='OPTIONS', help='Specify mount options')
argp.add_argument('source', help='Specify source')
argp.add_argument('mount_point', help='Specify mount point')

def parse_mount_options(options):
    chars = list(options)
    option = ''

    while chars:
        c = chars.pop(0)

        if c == ',':
            yield option
            option = ''

        elif c == '\\':
            try:
                option += chars.pop(0)
            # Backslash without following any char means space
            except IndexError:
                option += " "
		
        else:
            option += c

    if option:
        yield option

args = argp.parse_args()

if args.options:
    options = list(parse_mount_options(args.options))
else:
    options = []

# sshfs requires "-o password_stdin"
options.append('password_stdin')
options.append('UserKnownHostsFile=/dev/null')
options.append('StrictHostKeyChecking=no')

ssh_password = ''
tor_server = '127.0.0.1:9050'
      
for option in options:
  if option[0:9] == "password=":
    ssh_password = option[9:]
    options.remove(option)
  elif option[0:4] == 'tor=':
    tor_server = option[4:]
    options.remove(option)

options.append("proxycommand='connect -S {} %h %p'".format(tor_server))

ssh_execv = ['sshfs', '-o', ','.join(options), args.source, args.mount_point]
ssh_p = Popen(ssh_execv, stdin=PIPE)
ssh_p.communicate(ssh_password.encode('utf-8'))
