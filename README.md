# mir-pybuffer
[![Build Status](https://travis-ci.org/ShigekiKarita/mir-pybuffer.svg?branch=master)](https://travis-ci.org/ShigekiKarita/mir-pybuffer)
[![pypi](https://img.shields.io/pypi/v/pybuffer.svg)](https://pypi.org/project/pybuffer)
[![dub](https://img.shields.io/dub/v/mir-pybuffer.svg)](https://code.dlang.org/packages/mir-pybuffer)


mir-pybuffer provides simpler communication interface between C/D-language and python ndarrays (e.g., numpy, PIL) in [Buffer Protocol](https://docs.python.org/3/c-api/buffer.html#buffer-protocol).

## installation

``` console
$ pip install pybuffer
$ dub fetch mir-pybuffer # for D (mir) extention
```

for C extention, you do not need anything but `Python.h`.
you can see a read/write example in [c-bp.c](c-bp.c) and run it by `$ make test-c`.

## usage

### python side

All you need to do is calling C/D dynamic library with `pybuffer.CDLL`.

``` python
import ctypes
import numpy
import pybuffer

# ndarrays
x = numpy.array([[0, 1, 2], [3, 4, 5]]).astype(numpy.float64)
y = numpy.array([0, 1, 2]).astype(numpy.float64)

# load dynamic library written in d or c
lib = pybuffer.CDLL("./libyour-dub-lib.so")
err = lib.func1(x, y, ctypes.c_double(2.0))
assert err == 0
```

### D side

currently mir-pybuffer only supports ndslice functions that return void.
see this [dub.json](dub.json) for creating dynamic library for python.

``` d
import mir.ndslice : Slice, Contiguous;
// NOTE: DO NOT import pybuffer without ": pybuffer, MixinPyBufferWrappers"
// because it fails to generate wrappers.
import pybuffer : pybuffer, MixinPyBufferWrappers;

@pybuffer
void func1(Slice!(Contiguous, [2LU], double*) mat, Slice!(Contiguous, [1LU], double*) vec, double a) {
  mat[0][] += vec;
  vec[] *= a;
}

mixin MixinPyBufferWrappers;
```

run by `$ make test-mir`.

## detail

`@pybuffer` and `mixin MixinPyBufferWrappers;` will generate wrapper functions as follows:

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

you can see the actual generated codes by `lib.print_generated()` in python.
`pybuffer.CDLL` calls `pybuffer_func1` instead of `func1` with PyBuffer arguments and error code handling.
see [mir.ndslice.connect.cpython.PythonBufferErrorCode](http://docs.algorithm.dlang.io/latest/mir_ndslice_connect_cpython.html#.PythonBufferErrorCode) for error code definitions.


## known issues

- `import pybuffer` without ` : pybuffer, MixinPyBufferWrappers` causes a empty generated string.
