import argparse
import ctypes

import numpy

import pybuffer

parser = argparse.ArgumentParser()
parser.add_argument("libpath")
args = parser.parse_args()

lib = pybuffer.CDLL(args.libpath)

print("==== begin generated ====")
lib.print_generated()
print("===== end generated =====")


x = numpy.array([[0, 1, 2], [3, 4, 5]]).astype(numpy.float64)
y = numpy.array([0, 1, 2]).astype(numpy.float64)
# lib.test_pybuffer(x) # pybuffer.to_buffer(x))
# print(x)
# assert numpy.all(x == -1)
x[:] = -1

if "mir" in args.libpath:
    pybuffer.to_buffer(x)
    assert lib.func1(x, y, 2.0, 3.0, True, 5, "six") == 0
    assert numpy.all(x == numpy.array([[-1, 0, 1], [-1, -1, -1]]))
    assert numpy.all(y == numpy.array([0, 2, 4]))
    assert lib.pybuffer_func2(x) == 0
