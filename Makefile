.PHONY: test test-c test-buffer test-module

%.o: %.c
	$(CC) -c -fPIC $< -o $@ -I$(shell echo $(CONDA_PREFIX)/include/python3.*) -std=c99

lib%.so: %.o
	$(CC) -shared -Wl,-soname,$@ -o $@ $<

test: test-buffer test-module

test-buffer:
	cd test && dub build --force --compiler=$(DC)
	python test.py ./test/libmir-bp-test.so

test-module:
	cd test-module && dub build --force --compiler=$(DC) && python test.py

test-c: libc-bp.so
	python test.py ./$<

