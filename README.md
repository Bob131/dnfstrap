dnfstrap
========

dnfstrap is a utility for creating a new Fedora chroot, containing only dnf and
its dependencies. You probably shouldn't use it though; the source files within
are woven from the RPM team's nightmares, I'm sure.

So why use it? Well, the minimal Fedora image weighs in at about 400MiB,
decompressing to 2GiB. The problem with this is two-fold:

 * Downloading 400MiB on a 200kbps connection takes a *long* time.
 * For a typical appliance application, 2GiB before you've got any actual
   software on the device is a bit of a stretch.

A dnfstrap chroot, on the other hand, requires about 80MiB of packages (plus the
forty-odd megabytes of repo data) and ends up using about 500MiB of disk space.

### Usage

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
   shenanigans, rpm needs to be able to setuid etc. This makes the hacky nature
   of dnfstrap all the more terrifying, so use it at your own risk.

### Known bugs

 * **Once you run dnfstrap for a target directory, it cannot be run again**:
   This means that if dnfstrap gets interrupted (or dies) during a build, you
   cannot try again with the same directory. Your best bet is to copy `<your
   build dir>/var/cache/dnf` to a new directory and start again. This is because
   the package solver is, for whatever reason, unable to resolve a dependency on
   `ld-linux-<target arch>.so` after it has already been installed.
