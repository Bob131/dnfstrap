[CCode (cheader_filename = "dlfcn.h", lower_case_cprefix = "dl")]
namespace Dl {
    [Compact]
    [CCode (cname = "void*")]
    public class Handle {}

    [Flags]
    [CCode (cprefix = "RTLD_", cname = "int")]
    public enum Flags {
        LAZY,
        NOW,

        GLOBAL,
        LOCAL,
        NODELETE,
        NOLOAD,
        DEPBIND
    }

    public unowned Handle? open(string filename, Flags flags);
    public unowned string error();
}
