all: clean compile

compile: clean
	cp build/autogen.sh .
	./autogen.sh
	rm autogen.sh

clean:
	rm -rf bin
