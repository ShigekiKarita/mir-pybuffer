module pyobject;
import core.stdc.config : c_long, c_ulong;

// pragma(mangle, __traits(identifier, PyObject));
extern (C) {
    struct PyTypeObject;
    alias Py_ssize_t = ptrdiff_t;

    struct PyObject
    {
        version (Py_DEBUG) {
            PyObject*_ob_next;
            PyObject*_ob_prev;
        }
        Py_ssize_t ob_refcnt;
        PyTypeObject *ob_type;
    }
}

version (unittest) {} else {
    extern (C) {
        alias PyCFunction = PyObject* function(PyObject*, PyObject*);
        struct PyMethodDef {
            const char  *ml_name;   /* The name of the built-in function/method */
            PyCFunction ml_meth;    /* The C function that implements it */
            int         ml_flags;   /* Combination of METH_xxx flags, which mostly
                                       describe the args expected by the C func */
            const char  *ml_doc;    /* The __doc__ attribute, or NULL */
        };

        // https://docs.python.org/3/c-api/module.html#c.PyModuleDef
        alias inquiry = int function(PyObject*);
        alias visitproc = int function(PyObject*, void*);
        alias traverseproc = int function(PyObject*, visitproc, void*);
        alias freefunc = void function(void*);

        struct PyModuleDef_Base {
            // PyObject_HEAD
            PyObject ob_base;
            PyObject* function() m_init;
            Py_ssize_t m_index;
            PyObject* m_copy;
        }

        struct PyModuleDef_Slot{
            int slot;
            void *value;
        }

        struct PyModuleDef{
            PyModuleDef_Base m_base;
            const char* m_name;
            const char* m_doc;
            Py_ssize_t m_size;
            PyMethodDef *m_methods;
            PyModuleDef_Slot* m_slots;
            traverseproc m_traverse;
            inquiry m_clear;
            freefunc m_free;
        }

        /* The PYTHON_ABI_VERSION is introduced in PEP 384. For the lifetime of
           Python 3, it will stay at the value of 3; changes to the limited API
           must be performed in a strictly backwards-compatible manner. */
        enum PYTHON_ABI_VERSION = 3;

        PyObject* PyModule_Create2(PyModuleDef* def, int apiver);
        PyObject* PyModule_Create(PyModuleDef* def) {
            return PyModule_Create2(def, PYTHON_ABI_VERSION);
        }

        /// for format string, see https://docs.python.org/3/c-api/arg.html#strings-and-buffers
        int PyArg_ParseTuple(PyObject *args, const char *format, ...);

        enum PyModuleDef_Base PyModuleDef_HEAD_INIT = {{1, null}, null, 0, null};

        enum PyMethodDef PyMethodDef_SENTINEL = {null, null, 0, null};

        /* Flag passed to newmethodobject */
        enum : int {
            /* #define METH_OLDARGS  0x0000   -- unsupported now */
            METH_VARARGS = 0x0001,
            METH_KEYWORDS = 0x0002,
            /* METH_NOARGS and METH_O must not be combined with the flags above. */
            METH_NOARGS = 0x0004,
            METH_O = 0x0008,
            /* METH_CLASS and METH_STATIC are a little different; these control
               the construction of methods for a class.  These cannot be used for
               functions in modules. */
            METH_CLASS = 0x0010,
            METH_STATIC = 0x0020
        }

        int Py_AtExit(void function());

        void rtAtExit() {
            import core.runtime : rt_term;
            rt_term();
        }


        /**
           Basic types
        */
        double PyFloat_AsDouble(PyObject* pyfloat);
        c_long PyLong_AsLong(PyObject *obj);
        long PyLong_AsLongLong(PyObject *obj);
        c_ulong PyLong_AsUnsignedLong(PyObject *pylong);
        ulong PyLong_AsUnsignedLongLong(PyObject *pylong);
        Py_ssize_t PyLong_AsSsize_t(PyObject *pylong);
        size_t PyLong_AsSize_t(PyObject *pylong);
        int PyObject_IsTrue(PyObject *o);
        const(char*) PyUnicode_AsUTF8(PyObject *unicode);

        extern __gshared PyObject* Py_True;
        extern __gshared PyObject* Py_False;

        PyObject* PyFloat_FromDouble(double);
        PyObject* PyLong_FromLongLong(long);
        PyObject* PyLong_FromUnsignedLongLong(ulong);
        PyObject* PyLong_FromSize_t(size_t);
        PyObject* PyLong_FromSsize_t(ptrdiff_t);
        PyObject* PyBool_FromLong(long v);
        PyObject* PyUnicode_FromStringAndSize(const(char*) u, Py_ssize_t len);

        /**
           Error handling
        */
        PyObject* PyErr_Occurred();
        void PyErr_SetString(PyObject* type, const char* message);
        // NOTE: c globals need __gshared https://dlang.org/spec/interfaceToC.html#c-globals
        extern __gshared PyObject* PyExc_TypeError;
        extern __gshared PyObject* PyExc_RuntimeError;

        import mir.ndslice.connect.cpython : Py_buffer;
        int PyObject_GetBuffer(PyObject *exporter, Py_buffer *view, int flags);

        extern __gshared PyObject _Py_NoneStruct;
        void Py_IncRef(PyObject*);

        PyObject* newNone() {
            Py_IncRef(&_Py_NoneStruct);
            return &_Py_NoneStruct;
        }

    }
}
