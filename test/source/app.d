import std.stdio;

import mir.ndslice;
import mir.ndslice.connect.cpython;

import pybuffer : MixinPyBufferWrappers, pybuffer;

extern (C):


// @nogc:
void test_pybuffer(ref Py_buffer pybuf) {
    writeln(pybuf);
    printf("buf: %p\n", pybuf.buf);
    assert(pybuf.buf != null);
    printf("obj: %p\n", pybuf.obj);
    assert(pybuf.obj != null);
    printf("len: %ld\n", pybuf.len);
    assert(pybuf.len == 6 * double.sizeof);
    printf("itemsize: %ld\n", pybuf.itemsize);
    assert(pybuf.itemsize == double.sizeof);

    printf("readonly: %d\n", pybuf.readonly);
    assert(!pybuf.readonly);
    printf("ndim: %d\n", pybuf.ndim);
    assert(pybuf.ndim == 2);
    printf("format: %s\n", pybuf.format);
    assert(pybuf.format[0] == 'd'); // ??

    printf("shape: [%ld, %ld]\n", pybuf.shape[0], pybuf.shape[1]);
    assert(pybuf.shape[0] == 2);
    assert(pybuf.shape[1] == 3);
    printf("strides: [%ld, %ld]\n", pybuf.strides[0], pybuf.strides[1]);
    assert(pybuf.strides[0] == pybuf.shape[1] * double.sizeof);
    assert(pybuf.strides[1] == double.sizeof);

    auto d = cast(double*) pybuf.buf;
    int acc = 0;
    printf("buf: [\n");
    for (int i = 0; i < pybuf.shape[0]; ++i) {
        printf(" [ ");
        for (int j = 0; j < pybuf.shape[1]; ++j) {
            auto idx = (i * pybuf.strides[0] + j * pybuf.strides[1]) / pybuf.itemsize;
            printf("%lf ", d[idx]);
            assert(d[idx] == acc);
            ++acc;
        }
        printf("]\n");
    }
    printf("]\n");

    Slice!(double*, 2) mat = void;
    auto err = fromPythonBuffer(mat, pybuf);
    writeln(err);
    assert(err == PythonBufferErrorCode.success);
    printf("%lf\n", mat[0, 0]);
    printf("%lf\n", mat[1, 0]);
    mat[] = -1;
}

@pybuffer
static void func1(Slice!(double*, 2) mat, Slice!(double*, 1) vec, double a, float f, bool b, long l, string s) {
    mat[0][] += vec;
    vec[] *= 2;
    assert(a == 2.0);
    assert(f == 3.0);
    assert(b);
    assert(l == 5);
    assert(s == "six");
}

@pybuffer
static void func2(Slice!(double*, 2) mat) {
    string s;
    s ~= "hello!";
    writeln(s);

    writeln(mat);
}


mixin MixinPyBufferWrappers;
