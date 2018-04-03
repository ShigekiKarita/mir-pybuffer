import pybuffer
import numpy

lib = pybuffer.CDLL("./libmir-bp-test.so")
lib.print();
a = numpy.array([[1.0, 2.0, 3.0], [3.0, 4.0, 6.0]]).astype(numpy.float64)
lib.func(a) # pybuffer.to_buffer(a))
