[CCode (cheader_filename = "native-arches.h", lower_case_cprefix = "", cprefix = "")]
namespace NA {
    [CCode (has_type_id = false)]
    public struct ArchMap {
        string base;
        [CCode (array_length = false, array_null_terminated = true)]
        string[] native;
    }

    [CCode (array_length = false, array_null_terminated = true)]
    public extern const ArchMap[] arch_map;
}
