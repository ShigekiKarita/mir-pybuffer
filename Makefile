.PHONY: test-c test-mir

%.o: %.c
	$(CC) -c -fPIC $< -o $@ -I$(CONDA_PREFIX)/include/python3.6m

lib%.so: %.o
	$(CC) -shared -Wl,-soname,$@ -o $@ $<

test-c: libc-bp.so
	python test.py ./$<

test-mir:
	dub build --compiler=$(DC)
	python test.py ./libmir-pybuffer.so

