PREFIX = /usr

build:

install:
	install -m 0755 mount.torsftp.py $(PREFIX)/bin/mount.torsftp
	install -m 0755 umount.torsftp.sh $(PREFIX)/bin/umount.torsftp
