android-linux3.3:
	./builder.sh -c configure/configure_3.3_android -p android-linux3.3

clean:
	rm -rf system
	cd kernel && make distclean

distclean: clean
	rm -rf arm-none-linux-gnueabi
	rm -rf kernel
