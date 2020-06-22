#!/usr/bin/env bash

set -eEuo pipefail

sudo apt update -y

sudo apt install -y racket git golang-go imagemagick libserialport0 build-essential gammu

# install map stuff
go get github.com/yanndegat/go-staticmaps/create-static-map
go get github.com/yanndegat/mbtileserver
sudo cp ~/go/bin/create-static-map /usr/local/bin
sudo ~/go/bin/mbtileserver /usr/local/bin

# install/setup gpslog
if [[ ! -d ~/gps-sms-tracker ]]; then
    (cd ~ && git clone "https://github.com/yanndegat/gps-sms-tracker")
fi

make -C ~/gps-sms-tracker/gpsloc deps build
sudo make -C ~/gps-sms-tracker/gpsloc install

# setup gammu
sudo make -C ~/gps-sms-tracker/sms install
