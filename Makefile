#
# Makefile for auto nice daemon
#
# 1999-2005 Patrick Schemitz <schemitz@users.sourceforge.net>
# http://and.sourceforge.net/
#


#######################################################################
# Edit here to adapt to your system!                                  #
#######################################################################


#
# Init script.
# (and.init.debian for Debian GNU/Linux or and.init for others;
# leave empty for BSD!)
#
INITSCRIPT=and.init

#
# Target directories. Examples for common configurations are
# given below.
#
PREFIX=/usr/local
INSTALL_ETC=$(PREFIX)/etc
INSTALL_INITD=/etc/init.d
INSTALL_SBIN=$(PREFIX)/sbin
INSTALL_MAN=$(PREFIX)/man
INSTALL_UNITDIR=$(PREFIX)/lib/systemd/system

# typical OpenBSD or FreeBSD configuration
#PREFIX=/usr/local
#INSTALL_ETC=/etc
#INSTALL_INITD=
#INSTALL_SBIN=$(PREFIX)/sbin
#INSTALL_MAN=$(PREFIX)/man

# typical Debian or SuSE 7.x configuration
#PREFIX=/usr
#INSTALL_ETC=/etc
#INSTALL_INITD=/etc/init.d
#INSTALL_SBIN=$(PREFIX)/sbin
#INSTALL_MAN=$(PREFIX)/share/man

# typical SuSE 6.x configuration
#PREFIX=/usr
#INSTALL_ETC=/etc
#INSTALL_INITD=/sbin/init.d
#INSTALL_SBIN=$(PREFIX)/sbin
#INSTALL_MAN=$(PREFIX)/man

# typical Redhat / Mandrake configuration
#PREFIX=/usr
#INSTALL_ETC=/etc
#INSTALL_INITD=/etc/rc.d/init.d
#INSTALL_SBIN=$(PREFIX)/sbin
#INSTALL_MAN=$(PREFIX)/share/man

# typical OSF/1 / Digital UNIX 4 configuration
#PREFIX=/usr/local
#INSTALL_ETC=/etc
#INSTALL_INITD=/sbin/init.d
#INSTALL_SBIN=$(PREFIX)/sbin
#INSTALL_MAN=$(PREFIX)/man

#
# Install program
#
INSTALL=install


#######################################################################
# Stop editing here!                                                  #
#######################################################################

default: and $(INITSCRIPT) doc

#
# Version and date
#
VERSION=1.2.3
DATE="2015-12-06"

#
# Man pages
#
MANPAGES=and.8 and.conf.5 and.priorities.5 and.service

#
# Determine architecture from uname(1)
#
ARCH=$(shell uname)

#
# Architecture-dependent settings: ANSI C compiler and linker
#
ifeq (${ARCH},Linux)
  CC = gcc -pedantic -Wall
  LD = gcc
  LIBS =
else
ifeq (${ARCH},OSF1)
  CC = cc -ansi
  LD = cc
  LIBS =
else
ifeq (${ARCH},OpenBSD)
  CC = gcc
  LD = gcc
  LIBS = -lkvm
else
ifeq (${ARCH},FreeBSD)
  CC = gcc -Wall
  LD = gcc
  LIBS = -lkvm
else
ifeq (${ARCH},SunOS)
  CC = cc -D__SunOS__
  LD = cc
else
ifeq (${ARCH},IRIX)
  CC = cc
  LD = cc
else
ifeq (${ARCH},IRIX64)
  CC = cc
  LD = cc
else
  # unsupported architecture
  CC = false
  LD = false
  LIBS =
endif
endif
endif
endif
endif
endif
endif


#
# Build the auto-nice daemon.
#
and: and.o and-proc.o and-$(ARCH).o
	$(LD) $(CFLAGS) and.o and-proc.o and-$(ARCH).o -o and $(LIBS)


#
# Independent part: configuration management, priority database.
#
and.o: and.c and.h
	$(CC) $(CFLAGS) -DDEFAULT_INTERVAL=60 -DDEFAULT_NICE=0 \
	  -DDEFAULT_CONFIG_FILE=\"$(INSTALL_ETC)/and/and.conf\" \
	  -DDEFAULT_DATABASE_FILE=\"$(INSTALL_ETC)/and/and.priorities\" \
	  -DAND_VERSION=\"$(VERSION)\" -DAND_DATE=\"$(DATE)\" -c and.c


#
# Unix variant specific stuff
#
and-proc.o: and.h and-proc.c
	$(CC) $(CFLAGS) -c and-proc.c

and-Linux.o: and.h and-Linux.c
	$(CC) $(CFLAGS) -c and-Linux.c

and-OpenBSD.o: and.h and-OpenBSD.c
	$(CC) -c and-OpenBSD.c

and-FreeBSD.o: and.h and-OpenBSD.c
	$(CC) -c and-OpenBSD.c -o and-FreeBSD.o

and-OSF1.o: and.h and-OSF1.c
	$(CC) -c and-OSF1.c

and-IRIX.o: and.h and-OSF1.c
	$(CC) -c and-OSF1.c -o and-IRIX.o

and-IRIX64.o: and.h and-OSF1.c
	$(CC) -c and-OSF1.c -o and-IRIX64.o

and-SunOS.o: and.h and-OSF1.c
	$(CC) -c and-OSF1.c -o and-SunOS.o



#
# Create script for SysV init
#
and.init: and.startup
	sed s:INSTALL_SBIN:$(INSTALL_SBIN):g < and.startup > and.init
	chmod +x and.init


#
# Man pages
#
doc:	$(MANPAGES)

and.8:	and.8.man
	cat $< | \
		sed s/__VERSION__/$(VERSION)/g | \
		sed s/__DATE__/$(DATE)/g > $@

and.conf.5:	and.conf.5.man
	cat $< | \
		sed s/__VERSION__/$(VERSION)/g | \
		sed s/__DATE__/$(DATE)/g > $@

and.priorities.5:	and.priorities.5.man
	cat $< | \
		sed s/__VERSION__/$(VERSION)/g | \
		sed s/__DATE__/$(DATE)/g > $@

and.service:	and.service.man
	cat $< | \
		sed s,EnvironmentFile=,EnvironmentFile=$(PREFIX),g | \
		sed s,ExecStart=/usr,ExecStart=$(PREFIX),g > $@

#
# Install and under $(PREFIX)/bin etc.
#
install: and

#-mkdir $(PREFIX)
	-mkdir -p $(DESTDIR)$(INSTALL_SBIN)
	-mkdir -p $(DESTDIR)$(INSTALL_ETC)/and/
	-mkdir -p $(DESTDIR)$(INSTALL_ETC)/sysconfig
	-mkdir -p $(DESTDIR)$(INSTALL_INITD)
	-mkdir -p $(DESTDIR)$(INSTALL_MAN)/man5
	-mkdir -p $(DESTDIR)$(INSTALL_MAN)/man8
	-mkdir -p $(DESTDIR)$(INSTALL_UNITDIR)
	$(INSTALL) -m 0755 and $(DESTDIR)$(INSTALL_SBIN)
	test -e $(DESTDIR)$(INSTALL_ETC)/and/and.conf || \
	   $(INSTALL) -m 0644 and.conf $(DESTDIR)$(INSTALL_ETC)/and/
	test -e $(DESTDIR)$(INSTALL_ETC)/and/and.priorities || \
	   $(INSTALL) -m 0644 and.priorities $(DESTDIR)$(INSTALL_ETC)/and/
	$(INSTALL) -m 0644 and.8 $(DESTDIR)$(INSTALL_MAN)/man8
	$(INSTALL) -m 0644 and.conf.5 $(DESTDIR)$(INSTALL_MAN)/man5
	$(INSTALL) -m 0644 and.priorities.5 $(DESTDIR)$(INSTALL_MAN)/man5
	$(INSTALL) -m 0644 and.service $(DESTDIR)$(INSTALL_UNITDIR)/
	$(INSTALL) -m 0644 and.sysconf $(DESTDIR)$(INSTALL_ETC)/sysconfig/and

simpleinstall: and and.init
	strip and
	mkdir -p $(DESTDIR)$(INSTALL_SBIN) $(DESTDIR)$(INSTALL_ETC)
	mkdir -p $(DESTDIR)$(INSTALL_INITD)
	mkdir -p $(DESTDIR)$(INSTALL_MAN)/man5 $(DESTDIR)$(INSTALL_MAN)/man8
	cp and $(DESTDIR)$(INSTALL_SBIN)
	test -e $(DESTDIR)$(INSTALL_ETC)/and.conf || \
	   cp and.conf $(DESTDIR)$(INSTALL_ETC)
	test -e $(DESTDIR)$(INSTALL_ETC)/and.priorities || \
	   cp and.priorities $(DESTDIR)$(INSTALL_ETC)
	cp and.8 $(DESTDIR)$(INSTALL_MAN)/man8
	cp and.conf.5 $(DESTDIR)$(INSTALL_MAN)/man5
	cp and.priorities.5 $(DESTDIR)$(INSTALL_MAN)/man5

uninstall:
	rm -f $(DESTDIR)$(INSTALL_SBIN)/and
	rm -f $(DESTDIR)$(INSTALL_INITD)/and
	rm -f $(DESTDIR)$(INSTALL_ETC)/and.conf
	rm -f $(DESTDIR)$(INSTALL_ETC)/and.priorities
	rm -f $(DESTDIR)$(INSTALL_MAN)/man8/and.8
	rm -f $(DESTDIR)$(INSTALL_MAN)/man5/and.conf.5
	rm -f $(DESTDIR)$(INSTALL_MAN)/man5/and.priorities.5


#
# Clean up generated files.
#
clean:
	rm -f *.o and and.init $(MANPAGES)

distclean: clean
	find . -name \*~ -exec rm \{\} \;
