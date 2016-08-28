bin_PROGRAMS = dnfstrap

dnfstrap_SOURCES = \
	rpmts-preload.c \
	libdnf.vapi \
	native-arches.vapi \
	dlopen.vapi \
	install-context.vala \
	dnfstrap.vala
dnfstrap_VALAFLAGS = $(dnfstrap_U_VALAFLAGS)
dnfstrap_CFLAGS = $(dnfstrap_U_CFLAGS)
dnfstrap_LDADD = \
	-ldl \
	$(dnfstrap_U_LIBS)

CLEANFILES = \
	install-context.c \
	dnfstrap.c \
	*.stamp \
	*.stamp-t

dist-hook:
	cd $(distdir); rm -f $(CLEANFILES)
