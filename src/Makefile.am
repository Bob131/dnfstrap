bin_PROGRAMS = dnfstrap

dnfstrap_SOURCES = dnfstrap.vala
dnfstrap_VALAFLAGS = $(dnfstrap_U_VALAFLAGS)
dnfstrap_CFLAGS = $(dnfstrap_U_CFLAGS)
dnfstrap_LDADD = $(dnfstrap_U_LIBS)

CLEANFILES = \
	$(filter %.c,$(dnfstrap_SOURCES)) \
	*.stamp \
	*.stamp-t

dist-hook:
	cd $(distdir); rm -f $(CLEANFILES)
