module pyobject;
import core.stdc.config : c_long, c_ulong;

// pragma(mangle, __traits(identifier, PyObject));
extern (C):

// struct _typeobject;
// struct PyTypeObject;
// version (Py_DEBUG) struct _object;
alias Py_ssize_t = ptrdiff_t;

struct PyObject;
// {
//     version (PyDEBUG) {
//         _object *_ob_next;
//         _object *_ob_prev;
//     }
//     Py_ssize_t ob_refcnt;
//     // _typeobject
//     PyTypeObject *ob_type;
// }
// extern PyTypeObject PyFloat_Type;
// auto PyTYPE(PyObject* ob) { return ob.ob_type; }
// int PyType_IsSubtype(PyTypeObject *, PyTypeObject *);
// int PyObject_TypeCheck(PyObject* ob, PyObject* tb) { return PyTYPE(ob) == tb || PyType_IsSubtype(ob, tb); }
// int PyFloat_Check(PyObject* pyfloat) { return PyObject_TypeCheck(ob, &PyFloat_Type); }


/**
   Basic types
 */
double PyFloat_AsDouble(PyObject* pyfloat);
PyObject *Py_False;
PyObject *Py_True;
c_long PyLong_AsLong(PyObject *obj);
long PyLong_AsLongLong(PyObject *obj);
c_ulong PyLong_AsUnsignedLong(PyObject *pylong);
ulong PyLong_AsUnsignedLongLong(PyObject *pylong);
Py_ssize_t PyLong_AsSsize_t(PyObject *pylong);
size_t PyLong_AsSize_t(PyObject *pylong);
int PyObject_IsTrue(PyObject *o);
// const(char*) PyString_AsString(PyObject *pystr);
// PyObject* PyUnicode_AsEncodedString(PyObject *unicode, const char *encoding, const char *errors);
const(char*) PyUnicode_AsUTF8(PyObject *unicode);

/**
   Error handling
 */
PyObject* PyErr_Occurred();
void PyErr_SetString(PyObject* type, const char* message);
extern PyObject* PyExc_TypeError;
extern PyObject* PyExc_RuntimeError;

// struct Py_buffer;
import mir.ndslice.connect.cpython;
int PyObject_GetBuffer(PyObject *exporter, Py_buffer *view, int flags);
enum : int {
    PyBUF_SIMPLE   = 0,
        PyBUF_WRITABLE = 0x0001,
        PyBUF_FORMAT   = 0x0004,
        PyBUF_ND       = 0x0008,
        PyBUF_STRIDES  = 0x0010 | PyBUF_ND,

        PyBUF_C_CONTIGUOUS   = 0x0020 | PyBUF_STRIDES,
        PyBUF_F_CONTIGUOUS   = 0x0040 | PyBUF_STRIDES,
        PyBUF_ANY_CONTIGUOUS = 0x0080 | PyBUF_STRIDES,
        PyBUF_INDIRECT       = 0x0100 | PyBUF_STRIDES,

        PyBUF_CONTIG_RO  = PyBUF_ND,
        PyBUF_CONTIG     = PyBUF_ND | PyBUF_WRITABLE,

        PyBUF_STRIDED_RO = PyBUF_STRIDES,
        PyBUF_STRIDED    = PyBUF_STRIDES | PyBUF_WRITABLE,

        PyBUF_RECORDS_RO = PyBUF_STRIDES | PyBUF_FORMAT,
        PyBUF_RECORDS    = PyBUF_STRIDES | PyBUF_FORMAT | PyBUF_WRITABLE,

        PyBUF_FULL_RO = PyBUF_INDIRECT | PyBUF_FORMAT,
        PyBUF_FULL    = PyBUF_INDIRECT | PyBUF_FORMAT | PyBUF_WRITABLE,
        }
