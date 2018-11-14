module wrapper;

import pyobject;

auto toPyObject(double x) { return PyFloat_FromDouble(x); }
auto toPyObject(long x) { return PyLong_FromLongLong(x); }
auto toPyObject(ulong x) { return PyLong_FromUnsignedLongLong(x); }
static if (!is(ulong == size_t))
    auto toPyObject(size_t x) { return PyLong_FromSize_t(x); }
static if (!is(long == ptrdiff_t))
    auto toPyObject(ptrdiff_t x) { return PyLong_FromSsize_t(x); }
auto toPyObject(bool b) { return PyBool_FromLong(b ? 1 : 0); }
auto toPyObject(string s) { return PyUnicode_FromStringAndSize(s.ptr, s.length); }
auto toPyObject(PyObject* p) { return p; }

extern(C):

PyObject* toPyFunction(alias dFunction)(PyObject* mod, PyObject* args) {
    import std.traits : Parameters, ReturnType;
    import std.meta : staticMap;
    import std.typecons : Tuple;
    import std.string : toStringz;
    import typeformat; //  : formatTypes;

    alias Ps = Parameters!dFunction;
    Tuple!Ps params;
    alias PointerOf(T) = T*;
    alias Ptrs = staticMap!(PointerOf, Ps);
    Tuple!Ptrs ptrs;
    static foreach (i; 0 .. Ps.length) {
        ptrs[i] = &params[i];
    }
    if (!PyArg_ParseTuple(args, formatTypes!(Ps).toStringz, ptrs.expand)) {
        return null;
    }
    else {
        alias R = ReturnType!dFunction;
        static if (is(R == void)) {
            dFunction(params.expand);
            return newNone(); // TODO support return values
        } else {
            return toPyObject(dFunction(params.expand));
        }
    }
    assert(false);
}

enum def(alias dfunc, string doc = "", string name = __traits(identifier, dfunc))
    = PyMethodDef(name, &toPyFunction!dfunc, METH_VARARGS, doc);

mixin template defModule(string modName, string modDoc, PyMethodDef[] defs) {
    import pyobject;
    import wrapper;
    extern (C):
    static PyModuleDef mod = {PyModuleDef_HEAD_INIT, modName, modDoc, -1};
    static methods = defs ~ [PyMethodDef_SENTINEL];

    mixin(
        "pragma(mangle, __traits(identifier, PyInit_" ~ modName ~ "))" ~
        "auto PyInit_" ~ modName ~ q{
            () {
                import pyobject;
                import core.runtime : rt_init;
                rt_init();
                Py_AtExit(&rtAtExit);
                mod.m_methods = methods.ptr;
                return PyModule_Create(&mod);
            }
        });
}
