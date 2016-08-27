bin_PROGRAMS = dnfstrap

dnfstrap_SOURCES = \
	rpmts-preload.h \
	libdnf.vapi \
	native-arches.vapi \
	install-context.vala \
	dnfstrap.vala
dnfstrap_VALAFLAGS = $(dnfstrap_U_VALAFLAGS)
dnfstrap_CFLAGS = $(dnfstrap_U_CFLAGS)
dnfstrap_LDADD = \
	-ldl \
	$(dnfstrap_U_LIBS)

CLEANFILES = \
	$(wildcard *.c) \
	*.stamp \
	*.stamp-t

dist-hook:
	cd $(distdir); rm -f $(CLEANFILES)
