class DnfStrap : Application {
    string arch = "x86_64";
    string release_ = "24";

    internal override void open(File[] files, string hint) {
        if (files.length > 1) {
            stderr.printf("Too many arguments\n");
            Process.exit(1);
        }

        var file = files[0];

        if (!file.query_exists()) {
            stderr.printf("Output directory doesn't exist\n");
            Process.exit(1);
        }

        if (file.query_file_type(0) != FileType.DIRECTORY) {
            stderr.printf("Provided path is not a directory\n");
            Process.exit(1);
        }

        var path = file.get_path();
        if (path == null) {
            stderr.printf("Output directory unsupported\n");
            Process.exit(1);
        }

        var context = new InstallContext(arch, release_, (!) path);
        var cancel = new Cancellable();

        Unix.signal_add(ProcessSignal.INT, () => {
            cancel.cancel();
            this.quit();
            return Source.REMOVE;
        });

        this.hold();
        context.do_install.begin(cancel, (obj, res) => {
            context.do_install.end(res);
            this.release();
        });
    }

    internal override void activate() {
        stderr.printf("No output directory specified\n");
        Process.exit(1);
    }

    DnfStrap() {
        Object(flags: ApplicationFlags.HANDLES_OPEN);

        var options = new OptionEntry[3];
        options[0] = {"arch", 'a', 0, OptionArg.STRING, ref arch,
            "Architecture for which to fetch packages", arch};
        options[1] = {"release", 'r', 0, OptionArg.STRING, ref release_,
            "Fedora version", release_};
        options[2] = {(string) null};
        this.add_main_option_entries(options);
    }

    public static int main(string[] args) {
        return new DnfStrap().run(args);
    }
}
