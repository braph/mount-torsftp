PREFIX = /usr

build:

install:
	install -m 0755 mount.torsftp $(PREFIX)/bin/mount.torsftp
	install -m 0755 umount.torsftp $(PREFIX)/bin/umount.torsftp
