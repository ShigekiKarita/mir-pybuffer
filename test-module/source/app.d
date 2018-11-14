import mir.ndslice;
import wrapper : def, defModule;

double foo(long x) {
    import std.stdio;
    writeln(x);
    return x * 2;
}

string d2s(double d) {
    import std.conv;
    return d.to!string;
}

double sum(Slice!(double*, 2) x) {
    return 1.0;
}

mixin defModule!(
    "libtest_module",
    "this is D module",
    [def!(foo, "this is foo"),
     def!(d2s, "this is d2s")]);



/* this mixin generates following for example

extern (C):
static PyModuleDef mod = {
    PyModuleDef_HEAD_INIT,
    "mod",                      // module name
    "this is D language mod",   // module doc
    -1,                         // size of per-interpreter state of the module,
                                // or -1 if the module keeps state in global variables.
};

static methods = [
    def!(foo, "this is foo"),
    PyMethodDef_SENTINEL
    ];

auto PyInit_libtest_module() {
    import core.runtime : rt_init;
    rt_init();
    Py_AtExit(&rtAtExit);
    mod.m_methods = methods.ptr;
    return PyModule_Create(&mod);
}

*/
