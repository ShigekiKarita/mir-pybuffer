module typeformat;

import std.traits;
import std.typecons;
import mir.ndslice : isSlice;
import pyobject; //  : PyObject;

template formatTypes(Ts...) {
    enum formatTypes = {
        string ret;
        static foreach (T; Ts) {
            static if (is(T == string)) {
                ret ~= "s";
            }
            else static if (isBoolean!T) {
                ret ~= "p";
            }
            else static if (isIntegral!T) {
                ret ~= "L"; // long long
            }
            else static if (isFloatingPoint!T) {
                ret ~= "d";
            }
            else static if (is(T == PyObject*)) {
                ret ~= "O";
            }
            else static if (isTuple!T) {
                ret ~= "(";
                ret ~= formatTypes!(T.Types);
                ret ~= ")";
            }
            else static if (isSlice!T) {
                ret ~= "O";
            }
            else {
                static assert(false, "unknown type to format: " ~ T.stringof);
            }
        }
        return ret;
    }();
}

unittest {
    static assert(formatTypes!(string, bool, double, int, PyObject*) == "spdLO");
    static assert(formatTypes!(Tuple!(bool, double).Types) == "pd");
    static assert(formatTypes!(string, Tuple!(bool, Tuple!(double, long)), int, PyObject*)
                  == "s(p(dL))LO");
}
