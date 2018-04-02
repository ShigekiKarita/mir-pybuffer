# mir-pybuffer [![Build Status](https://travis-ci.org/ShigekiKarita/mir-pybuffer.svg?branch=master)](https://travis-ci.org/ShigekiKarita/mir-pybuffer)


## installation

```
$ pip install pybuffer
$ dub fetch mir-pybuffer
```


## usage

python side. you should wrap numpy contiguous array with `pybuffer.to_bytes`.
also see [mir.ndslice.connect.cpython.PythonBufferErrorCode](http://docs.algorithm.dlang.io/latest/mir_ndslice_connect_cpython.html#.PythonBufferErrorCode) for error handling.

``` python
import ctypes
import numpy
import pybuffer

lib = ctypes.CDLL("./libmir-bp.so") # dynamic library written in d
x = numpy.array([[0, 1, 2], [3, 4, 5]]).astype(numpy.float64)
y = numpy.array([0, 1, 2]).astype(numpy.float64)
err = lib.pybuffer_func1(pybuffer.to_bytes(x),
                         pybuffer.to_bytes(y),
                         ctypes.c_double(1.0))
assert err == 0
```

d side. currently mir-pybuffer only supports ndslice functions that returns void.
see this [dub.json](dub.json) for creating dynamic library for python.

``` d
import mir.ndslice : Slice, Contiguous;
import pybuffer : pybuffer;

@pybuffer
void func1(Slice!(Contiguous, [2LU], double*) mat, Slice!(Contiguous, [1LU], double*) vec, double a) {
  ...
}
```

`@pybuffer` will generate a wrapped function as follows:

``` d
pragma(mangle, __traits(identifier, pybuffer_func1))
extern(C) auto pybuffer_func1( ref Py_buffera0 , ref Py_buffera1 , double a2 ) {
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
