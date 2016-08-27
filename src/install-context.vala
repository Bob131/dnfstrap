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

delegate bool InstallSuccessTest(Error e);

class InstallContext : Object {
    public string arch {construct; get;}
    public string release {construct; get;}
    public string install_root {construct; get;}

    const string repo_path = "/etc/yum.repos.d";
    const string lock_path = "/var/run";
    const string cache_path = "/var/cache/dnf";

    Dnf.Context context;
    string[] native_arches = {"noarch"};

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
            if (!succeeded(e)) {
                stderr.printf("Install for '%s' failed: %s\n", name, e.message);
                Process.exit(1);
            }
        }
    }

    public async void do_install(Cancellable cancel) {
        new Thread<void*>("install", () => {
            try {
                context.setup_sack(context.get_state());
                ((!) context.get_sack()).set_arch(native_arches[1]);
            } catch (Error e) {
                stderr.printf("Failed to init sack: %s\n", e.message);
                Process.exit(1);
            }

            Environment.set_variable("G_MESSAGES_DEBUG", "all", false);
            context.set_rpm_verbosity("debug");

            install("dnf", (e) => {
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

        try {
            Dnf.Context.globals_init();
        } catch (Error e) {
            stderr.printf("Failed to init globals: %s\n", e.message);
            Process.exit(1);
        }

        if (Posix.chroot(install_root) == -1) {
            stderr.printf("Failed to chroot: %s\n", strerror(errno));
            Process.exit(1);
        }

        foreach (var new_path in new string[]{repo_path, cache_path, lock_path})
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

        try {
            FileUtils.set_contents("/etc/os-release", @"VERSION_ID=$release\n");
        } catch (FileError e) {
            stderr.printf("Failed to write os-release: %s\n", e.message);
            Process.exit(1);
        }

        context = new Dnf.Context();
        context.set_repo_dir(repo_path);
        context.set_lock_dir(lock_path);
        context.set_cache_dir(cache_path);
        context.set_solv_dir(cache_path);
        context.set_install_root("/");

        try {
            context.setup();
        } catch (Error e) {
            stderr.printf("Context init failed: %s\n", e.message);
            Process.exit(1);
        }
    }
}