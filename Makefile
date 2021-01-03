all: clean compile startup.c

compile: clean
	cp build/autogen.sh .
	./autogen.sh
	rm autogen.sh

startup.c:
	gcc -Wall startup.c -o startup

docker:
	docker build -f Dockerfile -t struharv:rt-muse .

clean:
	rm -rf bin

clean-log:
	rm -rf results
	rm -f *.log
