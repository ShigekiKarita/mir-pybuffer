import mir.ndslice;
import wrapper : def, defModule;
import std.stdio;

double foo(long x) {
    return x * 2;
}

string baz(double d) {
    import std.conv;
    return d.to!string;
}

auto bar(long i, double d) {
    import std.typecons;
    return tuple(i, tuple(tuple(d, i)));
}

// wip: returning slice is partially supported (as memoryview)
Slice!(double*, 1) sum(Slice!(double*, 2) x, Slice!(double*, 1) y) {
    auto z = y.slice; // copy
    foreach (xi; x) {
        z[] += xi;
    }
    return z;
}

mixin defModule!(
    "libtest_module", // module name
    "this is D module", // module doc
    // register d-func and doc under the module
    [def!(foo, "this is foo"),
     def!(baz, "this is baz"),
     def!(bar, "this is bar"),
     def!(sum, "this is sum")]);



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
