.PHONY=clean install build deps

all: build

clean:
	@rm -f gpsloc

./gpsloc.rkt:

./gpsloc: ./gpsloc.rkt
	raco exe gpsloc.rkt

build: ./gpsloc

deps:
	raco pkg install --batch --deps search-auto libserialport

install:
	@cp systemd/gpsloc.timer systemd/gpsloc-power.service systemd/gpsloc.service /etc/systemd/system
	@systemctl enable gpsloc.timer
	@systemctl daemon-reload
	@cp ./gpsloc /usr/local/bin
