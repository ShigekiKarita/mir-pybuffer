module pybuffer;

import std.stdio;
import mir.ndslice;


struct pybuffer {}

mixin template MixinPyBufferWrappers(string _mod = __MODULE__) {
    mixin("import mod =  " ~ _mod ~ ";");
    mixin({
            import std.conv : to;
            import std.traits : Parameters, ReturnType;
            string ret;
            foreach (mem; __traits(allMembers, mod)) {
                foreach (attr; __traits(getAttributes, __traits(getMember, mod, mem))) {
                    if (is(attr == pybuffer)) {
                        mixin("alias R = ReturnType!(mod." ~ mem ~ ");");
                        static assert(is(R == void), "@pybuffer function should return void");
                        string args;
                        string rargs;
                        string converts = "  import mir.ndslice.connect.cpython;\n";
                        converts ~= "  import std.stdio : writeln;\n";

                        mixin("alias Ps = Parameters!(mod." ~ mem ~ ");");
                        foreach (i, P; Ps) {
                            enum a = "a" ~ i.to!string;
                            if (isSlice!P) {
                                args ~= " " ~ "ref Py_buffer " ~ a ~ " ,";
                                enum _a = "_a" ~ i.to!string;
                                converts ~= P.stringof ~ " " ~ _a ~ ";\n";
                                converts ~= "  {\n    auto err = fromPythonBuffer( " ~ _a ~ " , " ~ a ~ " );\n";
                                // TODO: enrich error messages
                                converts ~= "    if (err != PythonBufferErrorCode.success) { writeln(err, \"at param " ~ i.to!string ~ "\n\"); return err; }\n  }\n";
                                rargs ~= " " ~ _a ~ " ,";
                            } else {
                                args ~= " " ~ P.stringof ~ " " ~ a ~ " ,";
                                rargs ~= " " ~ a ~ " ,";
                            }
                        }

                        // decleration
                        string newName = "pybuffer_" ~ mem;
                        // workaround to https://issues.dlang.org/show_bug.cgi?id=12575
                        ret ~= "pragma(mangle, __traits(identifier, " ~ newName ~ "))\n";
                        ret ~= "extern(C) auto " ~ newName ~ "(" ~ args[0..$-1] ~ ") {\n";

                        // conversions: pybuf -> ndslice
                        ret ~= converts;

                        // exec function
                        ret ~= "  " ~ mem ~ "(" ~ rargs[0..$-1] ~ ");\n";

                        // return success
                        ret ~= "  return PythonBufferErrorCode.success;\n}\n\n";
                    }
                }
            }
            return ret;
        }()
        );
}
