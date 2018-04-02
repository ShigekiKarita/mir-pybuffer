# mir-pybuffer
[![Build Status](https://travis-ci.org/ShigekiKarita/mir-pybuffer.svg?branch=master)](https://travis-ci.org/ShigekiKarita/mir-pybuffer)
[![pypi](https://img.shields.io/pypi/v/pybuffer.svg)](https://pypi.org/project/pybuffer)
[![dub](https://img.shields.io/dub/v/mir-pybuffer.svg)](https://code.dlang.org/packages/mir-pybuffer)


mir-pybuffer aims to extend python ndarrays (e.g., numpy, PIL) in official [Buffer Protocol](https://docs.python.org/3/c-api/buffer.html#buffer-protocol) with thin wrapper functionality.

## installation

```
$ pip install pybuffer
# for D (mir) extention
$ dub fetch mir-pybuffer
```

for c extention using `#include <Python.h>`, you can see our `test-c` rule in [Makefile](Makefile).

## usage

python side. you should wrap numpy contiguous array with `pybuffer.to_bytes`.
also see [mir.ndslice.connect.cpython.PythonBufferErrorCode](http://docs.algorithm.dlang.io/latest/mir_ndslice_connect_cpython.html#.PythonBufferErrorCode) for error handling.

``` python
import ctypes
import numpy
import pybuffer

x = numpy.array([[0, 1, 2], [3, 4, 5]]).astype(numpy.float64)
y = numpy.array([0, 1, 2]).astype(numpy.float64)
# load dynamic library written in d or c
lib = pybuffer.CDLL("./libyour-dub-lib.so")
err = lib.pybuffer_func1(x, y, ctypes.c_double(2.0))
assert err == 0
```

d side. currently mir-pybuffer only supports ndslice functions that returns void.
see this [dub.json](dub.json) for creating dynamic library for python.

``` d
import mir.ndslice : Slice, Contiguous;
import pybuffer : pybuffer, MixinPyBufferWrappers;

@pybuffer
void func1(Slice!(Contiguous, [2LU], double*) mat, Slice!(Contiguous, [1LU], double*) vec, double a) {
  mat[0][] += vec;
  vec[] *= a;
}

mixin MixinPyBufferWrappers;
```

`@pybuffer` will generate a wrapped function as follows:

``` d
pragma(mangle, __traits(identifier, pybuffer_func1))
extern(C) auto pybuffer_func1( ref Py_buffer a0 , ref Py_buffer a1 , double a2 ) {
  import mir.ndslice.connect.cpython;
  import std.stdio : writeln;
  Slice!(Contiguous, [2LU], double*) _a0;
  {
    auto err = fromPythonBuffer( _a0 , a0 );
    if (err != PythonBufferErrorCode.success) { writeln(err); return err; }
  }
  Slice!(Contiguous, [2LU], double*) _a1;
  {
    auto err = fromPythonBuffer( _a1 , a1 );
    if (err != PythonBufferErrorCode.success) { writeln(err); return err; }
  }
  func1( _a0 , _a1 , a2 );
  return PythonBufferErrorCode.success;
}
```
