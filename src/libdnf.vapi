[CCode (cheader_filename = "libdnf/libdnf.h", lower_case_cprefix = "dnf_")]
namespace Dnf {
    public class Context : GLib.Object {
	public Context ();

	public unowned Hawkey.Goal get_goal();

	public void set_cache_dir (string cache_dir);
	public unowned string get_cache_dir ();

	public void set_install_root (string install_root);
	public unowned string get_install_root ();

	public void set_lock_dir (string lock_dir);
	public unowned string get_lock_dir ();

	public void set_only_trusted (bool only_trusted);
	public bool get_only_trusted ();

	public void set_repo_dir (string repo_dir);
	public unowned string get_repo_dir ();

	public void set_rpm_verbosity (string rpm_verbosity);
	public unowned string get_rpm_verbosity ();

	public void set_solv_dir (string solv_dir);
	public unowned string get_solv_dir ();

	public void repo_disable (string name) throws GLib.Error;
	public void repo_enable (string name) throws GLib.Error;

	public unowned Dnf.State get_state ();

	public static bool globals_init () throws GLib.Error;
	public bool run (GLib.Cancellable? cancellable = null) throws GLib.Error;
	public bool setup (GLib.Cancellable? cancellable = null) throws GLib.Error;

	public bool setup_sack (State state) throws GLib.Error;
	public unowned Sack? get_sack ();
    }

    public class Sack : GLib.Object {
    	public void set_arch (string? value) throws GLib.Error;
    }

    public class Package {}

    public class State : GLib.Object {}
}

[CCode (cprefix = "Hy", lower_case_cprefix = "hy_")]
namespace Hawkey {
    public const string SYSTEM_REPO_NAME;

    [Compact]
    public class Goal {
    	public int install(Dnf.Package new_pkg);
    }

    [Compact]
    public class Query {
    	[CCode (cname = "hy_query_create")]
    	public Query(Dnf.Sack sack);

    	public int filter(KeyName keyname, ComparisonType comptype,
	   string matches);
    	public int filter_in(KeyName keyname, ComparisonType comptype,
	   [CCode (array_length = false)]
	   string[] matches);
    	public void filter_latest(bool val);

    	public GLib.GenericArray<Dnf.Package> run();
    }

    [CCode (cprefix = "HY_PKG_")]
    public enum KeyName {
    	ALL,
    	ARCH,
    	CONFLICTS,
    	DESCRIPTION,
    	EPOCH,
    	EVR,
    	FILE,
    	NAME,
    	NEVRA,
    	OBSOLETES,
    	PROVIDES,
    	RELEASE,
    	REPONAME,
    	REQUIRES,
    	SOURCERPM,
    	SUMMARY,
    	URL,
    	VERSION,
    	LOCATION,
    	ENHANCES,
    	RECOMMENDS,
    	SUGGESTS,
    	SUPPLEMENTS,
    	ADVISORY,
    	ADVISORY_BUG,
    	ADVISORY_CVE,
    	ADVISORY_SEVERITY,
	ADVISORY_TYPE
    }

    [Flags]
    [CCode (cprefix = "HY_")]
    public enum ComparisonType {
    	ICASE,
    	NOT,
    	COMPARISON_FLAG_MASK,
    	EQ,
    	LT,
    	GT,
    	SUBSTR,
    	GLOB,
    	NEQ,
    	NAME_ONLY
    }
}
