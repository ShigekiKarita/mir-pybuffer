import libtest_module

assert libtest_module.__doc__ == "this is D module"
assert libtest_module.foo(1) == 2.0
assert libtest_module.d2s(1.5) == "1.5"
