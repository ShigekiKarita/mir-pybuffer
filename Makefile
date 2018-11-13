.PHONY: test test-c test-mir

%.o: %.c
	$(CC) -c -fPIC $< -o $@ -I$(shell echo $(CONDA_PREFIX)/include/python3.*) -std=c99

lib%.so: %.o
	$(CC) -shared -Wl,-soname,$@ -o $@ $<

test-c: libc-bp.so
	python test.py ./$<

test-mir:
	cd test && dub build --force --compiler=$(DC)
	python test.py ./test/libmir-bp-test.so
