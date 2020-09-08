all: clean compile

compile: clean
	cp build/autogen.sh .
	./autogen.sh
	rm autogen.sh

docker:
	docker build -f Dockerfile -t struharv:rt-muse .

clean:
	rm -rf bin

clean-log:
	rm -rf results
	rm -f *.log
