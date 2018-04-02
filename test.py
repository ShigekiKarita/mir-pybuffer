import argparse
import ctypes

import numpy

import pybuffer

parser = argparse.ArgumentParser()
parser.add_argument("libpath")
args = parser.parse_args()

lib = ctypes.CDLL(args.libpath)

x = numpy.array([[0, 1, 2], [3, 4, 5]]).astype(numpy.float64)
y = numpy.array([0, 1, 2]).astype(numpy.float64)
lib.test_pybuffer(pybuffer.to_bytes(x))
print(x)
assert numpy.all(x == -1)

# lib.hello()
assert lib.pybuffer_func1(pybuffer.to_bytes(x),
                          pybuffer.to_bytes(y),
                          ctypes.c_double(1.0)) == 0
assert lib.pybuffer_func2(pybuffer.to_bytes(x)) == 0
