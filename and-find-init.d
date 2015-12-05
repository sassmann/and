#!/bin/sh
#
# Figure out where SysV init.d directory is. On BSD, return /tmp.
#
# 2001, Patrick Schemitz <schemitz@users.sourceforge.net>
#

# SuSE 7, Debian
if [ -d /etc/init.d ]; then
	echo /etc/init.d
	exit 0
fi

# SuSE 6, OSF/1
if [ -d /sbin/init.d ]; then
	echo /sbin/init.d
	exit 0
fi

# Redhat 7
if [ -d /etc/rc.d/init.d ]; then
	echo /etc/rc.d/init.d
	exit 0
fi

# Huh? BSD?
echo /tmp
exit 1
