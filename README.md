dnfstrap
========

dnfstrap is a utility for creating a new Fedora chroot, containing only dnf and
its dependencies. You probably shouldn't use it though; the source files within
are woven from the RPM team's nightmares, I'm sure.

If you're feeling self-destructive, you'll need libdnf. It should be coming to
the Fedora repos soon, but until then you can use the RPM team's Copr:

```
dnf copr enable rpmsoftwaremanagement/dnf-nightly
dnf install libdnf-devel
```

Compilation and usage is pretty straightforward:

```
./autogen.sh
make
mkdir my-new-chroot
sudo src/dnfstrap --arch armhfp --release 24 my-new-chroot
```

Two things about the above invocation:

 * Yes, cross-architecture will (should) work. This is what I really needed, so
   I've put some effort into this use case. However, the method with which
   dnfstrap wrestles libdnf into compliance is not exactly robust.
 * Sudo really is needed, as both dnfstrap and rpm partake in chroot
   shenanigans and more. This makes the hacky nature of dnfstrap all the more
   terrifying, so use it at your own risk.
