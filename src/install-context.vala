const string REPO_DEF = """[fedora-tmp]
name=dnfstrap for Fedora @arch@ - @release@
failovermethod=priority
metalink=https://mirrors.fedoraproject.org/metalink?repo=fedora-@release@&arch=@arch@
enabled=1
metadata_expire=never
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-@release@-@arch@
skip_if_unavailable=False
""";

const string REPO = "/etc/yum.repos.d";
const string LOCK = "/var/run";
const string CACHE = "/var/cache/dnf";

const string RESOLV = "/etc/resolv.conf";
const string BUNDLE = "/etc/pki/tls/certs/ca-bundle.crt";

const string[] LOAD_BEFORE_CHROOT = {
    "libnss_dns.so",
    "libnss_db.so",
    "libnssdbm3.so",
    "libnsssysinit.so",
    "libnsspem.so"
};

delegate bool InstallSuccessTest();

class InstallContext : Object {
    public string arch {construct; get;}
    public string release {construct; get;}
    public string install_root {construct; get;}

    Dnf.Context context;
    string[] native_arches = {"noarch"};

    void init_context(string repo_path, string lock_path, string cache_path,
        string install_path)
    {
        context = new Dnf.Context();
        context.set_repo_dir(repo_path);
        context.set_lock_dir(lock_path);
        context.set_cache_dir(cache_path);
        context.set_solv_dir(cache_path);
        context.set_install_root(install_path);

        // enable the debug spew
        Environment.set_variable("G_MESSAGES_DEBUG", "all", false);
        context.set_rpm_verbosity("debug");

        try {
            context.setup();
        } catch (Error e) {
            stderr.printf("Context init failed: %s\n", e.message);
            Process.exit(1);
        }

        try {
            context.repo_disable("fedora");
            context.repo_disable("updates");
        } catch (Error e) {
            if (!PatternSpec.match_simple("repo * not found", e.message)) {
                stderr.printf("Failed to disable repos: %s", e.message);
                Process.exit(1);
            }
        }

        try {
            context.setup_sack(context.get_state());
            ((!) context.get_sack()).set_arch(native_arches[1]);
        } catch (Error e) {
            stderr.printf("Failed to init sack: %s\n", e.message);
            Process.exit(1);
        }
    }

    void install(string name, InstallSuccessTest succeeded)
        requires (context.get_sack() != null)
    {
        var query = new Hawkey.Query((!) context.get_sack());

        query.filter_latest(true);
        query.filter_in(Hawkey.KeyName.ARCH, Hawkey.ComparisonType.EQ,
            native_arches);
        query.filter(Hawkey.KeyName.REPONAME, Hawkey.ComparisonType.NEQ,
            Hawkey.SYSTEM_REPO_NAME);
        query.filter(Hawkey.KeyName.ARCH, Hawkey.ComparisonType.NEQ, "src");
        query.filter(Hawkey.KeyName.NAME, Hawkey.ComparisonType.EQ, name);

        var results = query.run();
        if (results.length < 1) {
            stderr.printf("Unable to find package '%s'\n", name);
            Process.exit(1);
        }

        if (context.get_goal().install(results[0]) != 0) {
            stderr.printf("Failed to init install for '%s'\n", name);
            Process.exit(1);
        }

        try {
            context.run();
        } catch (Error e) {
            /*
            For cross-arch builds (and probably same-arch builds too), the
            transaction *will* fail. So we have invokers of this function
            provide a closure that tests whether the important files exist
            before declaring outright failure.

            As far as I can tell, failures are caused by rpm post-transaction
            hooks failing, probably because they attempt to invoke binaries for
            a foreign ISA.
            */
            if (!succeeded()) {
                stderr.printf("Install for '%s' failed: %s\n", name, e.message);
                Process.exit(1);
            }
        }
    }

    public async void do_install(Cancellable cancel) {
        /*
        Curl and rpmlib don't play well with GMainLoop, so we work in a
        background thread; this allows firing of UNIX signal GSources
        */
        new Thread<void*>("install", () => {
            install("rpm", () => {
                return FileUtils.test(
                    Path.build_filename(install_root, "bin", "rpm"),
                    FileTest.EXISTS);
            });

            /*
            glibc's Name Switching Service and the Network Security Services
            library both make use of modules to extend functionality, loaded at
            runtime by dlopen() and friends. These modules are required for
            name resolution and TLS certificate verification. This won't work
            once we chroot in, so we have to load them now.
            */
            var flags = Dl.Flags.NOW | Dl.Flags.GLOBAL | Dl.Flags.NODELETE;
            foreach (var lib in LOAD_BEFORE_CHROOT)
                if (Dl.open(lib, flags) == null) {
                    stderr.printf("Failed to load %s: %s\n", lib, Dl.error());
                    Process.exit(1);
                }

            var resolv = "nameserver 8.8.8.8\n";
            try {
                FileUtils.get_contents(RESOLV, out resolv);
            } catch (FileError e) {
                warning("Failed to read %s: %s. Using default", RESOLV,
                    e.message);
            }

            /*
            NSS3 looks for the CA bundle used for verifying TLS certificates at
            BUNDLE, but even though the ca-certificates package should be pulled
            by rpm the file never gets installed. We have to set this manually,
            else curl will die with cert verification errors.
            */
            string bundle = "";
            try {
                FileUtils.get_contents(BUNDLE, out bundle);
            } catch (FileError e) {
                stderr.printf("Failed to read %s: %s\n", BUNDLE, e.message);
                Process.exit(1);
            }

            if (Posix.chroot(install_root) == -1 || Posix.chdir("/") == -1) {
                stderr.printf("Failed to chroot: %s\n", strerror(errno));
                Process.exit(1);
            }

            try {
                FileUtils.set_contents(RESOLV, resolv);
            } catch (FileError e) {
                stderr.printf("Failed to write %s: %s\n", RESOLV, e.message);
                Process.exit(1);
            }

            try {
                FileUtils.set_contents(BUNDLE, bundle);
            } catch (FileError e) {
                stderr.printf("Failed to write %s: %s\n", BUNDLE, e.message);
                Process.exit(1);
            }

            /*
            DnfRepoLoader uses GVolumeMonitor to watch for new mounts. Calling
            init_context() again will thus result in the following chain of
            events:

              * Our current DnfContext will have its ref count brought down to
                zero, unreffing the DnfRepoLoader it owns, thereby removing the
                last ref to the global GVolumeMonitor
              * When dnf_context_setup() is called on the new DnfContext, a new
                DnfRepoLoader is initialised which then calls
                g_volume_monitor_get(). Since the old GVolumeMonitor has already
                been freed, it initialises a new one.

            This doesn't work for us for two reasons:

              * We haven't mounted a procfs in the chroot, so GVolumeMonitor
                will be unable to read /proc/mounts
              * This will involve the loading of a GIO module (see above)

            So here we just artificially bump the global monitor's ref count to
            prevent this from being a problem.
            */
            VolumeMonitor.get().ref_count++;

            init_context(REPO, LOCK, CACHE, "/");

            /*
            Actual dnf install. The reason why we go through the trouble of
              (a) installing rpm first, and
              (b) chrooting before we install dnf
            is because installing dnf straight-up causes the test transaction
            to fail due to a conflict between the Python interpreter selected
            by Hawkey and the system's installed interpreter. By installing rpm
            first, we gain a system complete enough to chroot into; doing so
            then prevents librpm from opening the system package DB during the
            test transaction.
            */
            install("dnf", () => {
                return FileUtils.test("/usr/bin/dnf", FileTest.EXISTS);
            });

            Idle.add(do_install.callback);
            return null;
        });

        yield;
    }

    public InstallContext(string arch, string release, string install_root) {
        Object(arch: arch, release: release, install_root: install_root);
    }

    construct {
        /*
        It turns out that there is a difference between a system's "base
        architecture" and the architecture that a package targets. This code is
        copied from the beginning of dnf_context.c (see native-arches.vapi for
        the NA namespace).

        All this does is take an input arch and output a list of acceptable
        package architectures, eg "armhfp" => {"noarch", "armv7hl", "armv7hnl"}
        */
        foreach (var map in NA.arch_map)
            if (map.base == arch) {
                foreach (var native_arch in map.native)
                    native_arches += native_arch;
                break;
            }

        if (native_arches.length <= 1) {
            stderr.printf("Unknown arch '%s'\n", arch);
            Process.exit(1);
        }

        var repo_path = Path.build_filename(install_root, REPO);
        var lock_path = Path.build_filename(install_root, LOCK);
        var cache_path = Path.build_filename(install_root, CACHE);

        foreach (var new_path in new string[]{repo_path, lock_path, cache_path})
            if (DirUtils.create_with_parents(new_path, 0755) == -1) {
                stderr.printf("Failed to create %s: %s\n", new_path,
                    strerror(errno));
                Process.exit(1);
            }

        var tmp_repo =
            REPO_DEF.replace("@arch@", arch).replace("@release@", release);
        var tmp_repo_path = Path.build_filename(repo_path, "fedora-tmp.repo");

        try {
            FileUtils.set_contents(tmp_repo_path, tmp_repo);
        } catch (FileError e) {
            stderr.printf("Failed to write %s: %s\n", tmp_repo_path, e.message);
            Process.exit(1);
        }

        /*
        The libdnf stack will refuse to proceed without the existence of
        /etc/os-release containing a VERSION_ID key.
        */
        try {
            FileUtils.set_contents(
                Path.build_filename(install_root, "etc", "os-release"),
                @"VERSION_ID=$release\n");
        } catch (FileError e) {
            stderr.printf("Failed to write os-release: %s\n", e.message);
            Process.exit(1);
        }

        init_context(repo_path, lock_path, cache_path, install_root);
    }
}
