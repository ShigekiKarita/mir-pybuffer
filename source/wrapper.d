module wrapper;

import pyobject;
import std.string : toStringz;
import std.typecons : isTuple;
import std.conv : to;
import mir.ndslice : isSlice, SliceKind, Slice, Structure;
import mir.ndslice.connect.cpython;

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

enum PyBuf_full = PyBuf_indirect | PyBuf_format | PyBuf_writable;

template toNpyType(T) {
    mixin("enum toNpyType = NpyType.npy_" ~ T.stringof ~ ";");
}

auto toPyObject(T, size_t n, SliceKind k)(Slice!(T*, n, k) x) {
    Py_buffer buf;
    Structure!n str;
    auto err = toPythonBuffer(x, buf, PyBuf_full, str);
    if (err != PythonBufferErrorCode.success) {
        PyErr_SetString(PyExc_RuntimeError,
                        "unable to convert Slice object into Py_buffer");
    }
    return PyMemoryView_FromBuffer(&buf);
    // FIXME use Array API
    // auto p = PyArray_SimpleNew(n, cast(npy_intp*) x.shape.ptr, toNpyType!T);
}

auto toPyObject(T)(T xs) if (isTuple!T) {
    enum N = T.length;
    auto p = PyTuple_New(N);
    if (p == null) {
        PyErr_SetString(PyExc_RuntimeError,
                        ("unable to allocate " ~ N.to!string ~ " tuple elements").toStringz);
    }
    static foreach (i; 0 .. T.length) {{
        auto pi = toPyObject(xs[i]);
        PyTuple_SetItem(p, i, pi);
     }}
    return p;
}

extern(C):

template PointerOf(T) {
    static if (isSlice!T)
        alias PointerOf = PyObject**;
    else
        alias PointerOf = T*;
}


PyObject* toPyFunction(alias dFunction)(PyObject* mod, PyObject* args) {
    import std.stdio;
    import std.conv : to;
    import std.traits : Parameters, ReturnType;
    import std.meta : staticMap;
    import std.typecons : Tuple;
    import std.string : toStringz, replace;
    import typeformat; //  : formatTypes;

    alias Ps = Parameters!dFunction;
    Tuple!Ps params;
    alias Ptrs = staticMap!(PointerOf, Ps);
    Tuple!Ptrs ptrs;
    static foreach (i; 0 .. Ps.length) {
        static if (isSlice!(Ps[i])) {
            mixin(
                q{
                    PyObject* obj$;
                    ptrs[i] = &obj$;
                }.replace("$", i.to!string));

        }
        else {
            ptrs[i] = &params[i];
        }
    }
    if (!PyArg_ParseTuple(args, formatTypes!(Ps).toStringz, ptrs.expand)) {
        return null;
    }
    else {
        static foreach (i; 0 .. Ps.length) {
            static if (isSlice!(Ps[i])) {
                mixin(
                    q{
                        Py_buffer buf$;
                        if (PyObject_CheckReadBuffer(obj$) == -1) {
                            PyErr_SetString(PyExc_RuntimeError,
                                            "invalid array object at param $");
                        }
                        PyObject_GetBuffer(obj$, &buf$, PyBuf_full);
                        {
                            auto err = fromPythonBuffer(params[$], buf$);
                            if (err != PythonBufferErrorCode.success) {
                                PyErr_SetString(PyExc_RuntimeError,
                                                "incompatible array object at param $, expected type: " ~ Ps[i].stringof);
                            }
                        }
                    }.replace("$", i.to!string)
                    );
            }
        }

        alias R = ReturnType!dFunction;
        static if (is(R == void)) {
            dFunction(params.expand);
            return newNone(); // TODO support return values
        } else {
            static foreach (i; 0 .. Ps.length) {
                static if (isSlice!(Ps[i])) {
                    mixin(q{PyBuffer_Release(&buf$);}.replace("$", i.to!string));
                }
            }
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
                import_array();
                return PyModule_Create(&mod);
            }
        });
}
