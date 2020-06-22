#!/bin/bash

set -eEuo pipefail
tty=${TTY:="/dev/ttyS0"}
DESC=(GNSSrunstatus Fixstatus UTCdatetime latitude longitude altitude speedOTG course fixmode Reserved1 HDOP PDOP VDOP Reserverd2 GNSSsatellitesinview GNSSsatellitesused GLONASSsatellitesused Reserved3 cn0max HPA VPA)

function DecodeLine() {
	local DATA="${1//+CGNSINF: /}"
	DATA=$(echo $DATA | iconv -f UTF-8 -t ASCII)
	local IFS=','
	echo -n '{"date": '$(date +%s)
	a=0
	for i in $DATA; do
	        attr="${DESC[$a]}"
		if [[ "$attr" == "latitude" ]] \
			|| [[ "$attr" == "altitude" ]] \
			|| [[ "$attr" == "GNSSsatellitesinview" ]] \
			|| [[ "$attr" == "longitude" ]]; then
		   printf ',"%s":%s' "$attr" "${i}"
		fi
		a=$((a+1))
	done
	echo -n "}" 

}

function SerialWriteAndRead() {
	exec 4<$tty 5>$tty
        stty -F $tty 115200
	echo "sending $1 .." >&2
	echo "$1" >&5
	while IFS='' read -t 1 -r line || [[ -n "$line"  ]]; do
	    echo "received: $line" >&2
	    if [[ "$line" == +CGNSINF* ]]; then
		echo "received gps info." >&2
	    	DecodeLine "$line"
	    elif [[ "$line" == "OK" ]]; then
		    break
	    fi
	    sleep 1
	done <&4
}

case "$1" in
	towertimesync)
		# Use time from cell tower.
		# You need to physically poweroff and poweron hat after this
		# Without correct time GPS satellites are hard to find
		SerialWriteAndRead "AT+CLTS=1"
		SerialWriteAndRead "AT&W"
		;;
	poweron)
		# Power on GPS
		SerialWriteAndRead "AT+CGNSPWR=1"
		;;
	poweroff)
		# Power off GPS
	        SerialWriteAndRead "AT+CGNSPWR=0"
	        ;;
	loc)
		# Location / postition
		SerialWriteAndRead "AT+CGNSINF"
		;;
	time)
		# Time
		SerialWriteAndRead "AT+CCLK?"
		;;
	decode)
		# Time
		DecodeLine "$2"
		;;
	status)
		# GPS timesync status
		SerialWriteAndRead "AT+CLTS?"
		# Power status
		SerialWriteAndRead "AT+CGNSPWR?"
		# GPS Fix status
		SerialWriteAndRead "AT+CGPSSTATUS?"
		;;
	*)
		echo "Simple GPS-script for Waveshare GSM/GPRS/GNSS/Bluetooth for Raspberry Pi hat"
		echo ""
		echo "$0  {loc|time|status|poweron|poweroff|towertimesync}"
		echo ""
		echo "See more info and AT command: https://www.waveshare.com/wiki/GSM/GPRS/GNSS_HAT"
		exit 1
		;;
esac
exit 0
