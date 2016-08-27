#include <glib.h>

/* data taken from https://github.com/rpm-software-management/dnf/blob/master/dnf/arch.py */
struct {
    const gchar    *base;
    const gchar    *native[12];
} typedef ArchMap;

const ArchMap arch_map[] =  {
    { "aarch64",    { "aarch64", NULL } },
    { "alpha",      { "alpha", "alphaev4", "alphaev45", "alphaev5",
                      "alphaev56", "alphaev6", "alphaev67",
                      "alphaev68", "alphaev7", "alphapca56", NULL } },
    { "arm",        { "armv5tejl", "armv5tel", "armv6l", "armv7l", NULL } },
    { "armhfp",     { "armv7hl", "armv7hnl", NULL } },
    { "i386",       { "i386", "athlon", "geode", "i386",
                      "i486", "i586", "i686", NULL } },
    { "ia64",       { "ia64", NULL } },
    { "noarch",     { "noarch", NULL } },
    { "ppc",        { "ppc", NULL } },
    { "ppc64",      { "ppc64", "ppc64iseries", "ppc64p7",
                      "ppc64pseries", NULL } },
    { "ppc64le",    { "ppc64le", NULL } },
    { "s390",       { "s390", NULL } },
    { "s390x",      { "s390x", NULL } },
    { "sh3",        { "sh3", NULL } },
    { "sh4",        { "sh4", "sh4a", NULL } },
    { "sparc",      { "sparc", "sparc64", "sparc64v", "sparcv8",
                      "sparcv9", "sparcv9v", NULL } },
    { "x86_64",     { "x86_64", "amd64", "ia32e", NULL } },
    { NULL,         { NULL } }
};
