module pybuffer;
/** CODING GUIDE

D or Python:

When we can implement something both in D or Python, we do everything in D.
D has less overhead than Python (the reason why we use D from Python).

Error Handling:

D function should raise exception for python by PyErr_SetString(PyObject* type, const char* message)
The type can be PyExc_RuntimeError, PyExc_TypeError, etc
see also https://docs.python.org/3/c-api/exceptions.html#standard-exceptions

 */

private import std.stdio;
private import mir.ndslice;

struct pybuffer {}

mixin template MixinPyBufferWrappers(string _Impl = __MODULE__) {
    import pyobject;
    import std.string : toStringz, fromStringz;
    import std.traits : isFloatingPoint, isBoolean, isIntegral;
    import std.conv : to;
    private enum string _generated = {
        // mixin(cpythonHeader);
        mixin("import Impl = " ~ _Impl ~ ";");
        import std.conv : to;
        import std.traits : Parameters, ReturnType;
        string ret;
        foreach (mem; __traits(allMembers, Impl)) {
            foreach (attr; __traits(getAttributes, __traits(getMember, Impl, mem))) {
                if (is(attr == pybuffer)) {
                    mixin("alias R = ReturnType!(" ~ _Impl ~ "." ~ mem ~ ");");
                    static assert(is(R == void), "@pybuffer function should return void");
                    string args;
                    string rargs;
                    string converts = "  import mir.ndslice.connect.cpython;\n";
                    converts ~= "  import std.stdio : writeln;\n";

                    mixin("alias Ps = Parameters!(" ~ _Impl ~ "." ~ mem ~ ");");
                    foreach (i, P; Ps) {
                        enum a = "a" ~ i.to!string;
                        if (isSlice!P) {
                            args ~= " " ~ "ref Py_buffer " ~ a ~ " ,";
                            // args ~= " PyObject* " ~ a ~ " ,";
                            enum _a = "_a" ~ i.to!string;
                            converts ~= "  " ~ P.stringof ~ " " ~ _a ~ ";\n";
                            // converts ~= "  {\n Py_buffer* buf; PyObject_GetBuffer(" ~ a ~ ", buf, PyBUF_FULL); auto err = fromPythonBuffer( " ~ _a ~ " , buf );\n";
                            converts ~= "  {\n auto err = fromPythonBuffer( " ~ _a ~ " , " ~ a ~ " );\n";
                            converts ~= "    if (err != PythonBufferErrorCode.success) { PyErr_SetString(PyExc_RuntimeError, \"invalid array object at param " ~ i.to!string ~ " \".toStringz); }\n  }\n";
                            rargs ~= " " ~ _a ~ " ,";
                        }
                        else if (is(P == string)) {
                            args ~= " PyObject* " ~ a ~ " ,";
                            // TODO error handling
                            enum _a = "_a" ~ i.to!string;
                            converts ~= "  const(char*) " ~ _a ~ " = PyUnicode_AsUTF8(" ~ a ~ ");\n";
                            rargs ~= " " ~ _a ~ ".fromStringz.to!string ,";
                        }
                        else if (isFloatingPoint!P) {
                            args ~= " PyObject* " ~ a ~ " ,";
                            enum _a = "_a" ~ i.to!string;
                            converts ~= "  double " ~ _a ~ " = PyFloat_AsDouble(" ~ a ~ ");\n";
                            rargs ~= " " ~ _a ~ " ,";
                        }
                        else if (is(P == ptrdiff_t)) {
                            args ~= " PyObject* " ~ a ~ " ,";
                            enum _a = "_a" ~ i.to!string;
                            converts ~= "  auto " ~ _a ~ " = PyLong_AsSsize_t(" ~ a ~ ");\n";
                            rargs ~= " " ~ _a ~ " ,";
                        }
                        else if (is(P == size_t)) {
                            args ~= " PyObject* " ~ a ~ " ,";
                            enum _a = "_a" ~ i.to!string;
                            converts ~= "  auto " ~ _a ~ " = PyLong_AsSize_t(" ~ a ~ ");\n";
                            rargs ~= " " ~ _a ~ " ,";
                        }
                        else if (is(P == ulong)) {
                            args ~= " PyObject* " ~ a ~ " ,";
                            enum _a = "_a" ~ i.to!string;
                            converts ~= "  auto " ~ _a ~ " = PyLong_AsUnsignedLongLong(" ~ a ~ ");\n";
                            rargs ~= " " ~ _a ~ " ,";
                        }
                        else if (isIntegral!P) {
                            args ~= " PyObject* " ~ a ~ " ,";
                            enum _a = "_a" ~ i.to!string;
                            converts ~= "  long " ~ _a ~ " = PyLong_AsLongLong(" ~ a ~ ");\n";
                            // converts ~= "  long " ~ _a ~ ";\n";
                            rargs ~= " " ~ _a ~ " ,";
                        }
                        else if (isBoolean!P) {
                            args ~= " PyObject* " ~ a ~ " ,";
                            enum _a = "_a" ~ i.to!string;
                            // https://docs.python.org/3/c-api/object.html#c.PyObject_IsTrue
                            // Returns 1 if the object o is considered to be true, and 0 otherwise
                            converts ~= "  bool " ~ _a ~ " = PyObject_IsTrue(" ~ a ~ ") == 1;\n";
                            rargs ~= " " ~ _a ~ " ,";
                        }
                        else {
                            assert(false, "unknown type to wrap: " ~ P.stringof ~ " at param " ~ i.to!string);
                        }
                        converts ~= "  { PyObject* e; if ((e = PyErr_Occurred()) != null) { PyErr_SetString(e, \"invalid float object at param " ~ i.to!string ~ " \".toStringz); } }\n";
                    }

                    // decleration
                    enum newName = "pybuffer_" ~ mem;
                    // workaround to https://issues.dlang.org/show_bug.cgi?id=12575
                    ret ~= "pragma(mangle, __traits(identifier, " ~ newName ~ "))\n";
                    ret ~= "extern(C) auto " ~ newName ~ "(" ~ args[0..$-1] ~ ") {\n";

                    // conversions: pybuf -> ndslice
                    ret ~= converts;

                    // exec function
                    ret ~= "  " ~ _Impl ~ "." ~ mem ~ "(" ~ rargs[0..$-1] ~ ");\n";

                    // return success
                    ret ~= "  return PythonBufferErrorCode.success;\n}\n\n";
                }
            }
        }
        return ret;
    }();

    pragma(mangle, __traits(identifier, print_generated))
    extern(C) void print_generated() {
        write(_generated);
    }

    mixin(_generated);
}
