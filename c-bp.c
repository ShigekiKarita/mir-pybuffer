#include <assert.h>
#include <stdio.h>

// https://docs.python.org/3/c-api/buffer.html#buffer-protocol
#include <Python.h> // Py_buffer is defined inside ./object.h

void test_pybuffer(Py_buffer* pybuf) {
    // pybuf numpy.array([[0, 1, 2], [3, 4, 5]]).astype(numpy.float64)
    printf("buf: %p\n", pybuf->buf);
    assert(pybuf->buf != NULL);
    printf("obj: %p\n", pybuf->obj);
    assert(pybuf->obj != NULL);
    printf("len: %ld\n", pybuf->len);
    assert(pybuf->len == 6 * sizeof(double));
    printf("itemsize: %ld\n", pybuf->itemsize);
    assert(pybuf->itemsize == sizeof(double));

    printf("readonly: %d\n", pybuf->readonly);
    assert(!pybuf->readonly);
    printf("ndim: %d\n", pybuf->ndim);
    assert(pybuf->ndim == 2);
    printf("format: %s\n", pybuf->format);
    assert(pybuf->format[0] == 'd'); // ??

    printf("shape: [%ld, %ld]\n", pybuf->shape[0], pybuf->shape[1]);
    assert(pybuf->shape[0] == 2);
    assert(pybuf->shape[1] == 3);
    printf("strides: [%ld, %ld]\n", pybuf->strides[0], pybuf->strides[1]);
    assert(pybuf->strides[0] == pybuf->shape[1] * sizeof(double));
    assert(pybuf->strides[1] == sizeof(double));

    double* d = pybuf->buf;
    int acc = 0;
    printf("buf: [\n");
    for (int i = 0; i < pybuf->shape[0]; ++i) {
        printf(" [ ");
        for (int j = 0; j < pybuf->shape[1]; ++j) {
            int idx = (i * pybuf->strides[0] + j * pybuf->strides[1]) / pybuf->itemsize;
                printf("%lf ", d[idx]);
                assert(d[idx] == acc);
                d[idx] = -1; // overwrite
                ++acc;
        }
        printf("]\n");
    }
    printf("]\n");
}
