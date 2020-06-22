#!/usr/bin/env bash

set -eEuo pipefail

MSGID="${1}"
GAMMURC="${GAMMURC:-/etc/gammu-smsdrc}"
DBDIR="$(awk '/^DBDir/ {print $3}' ${GAMMURC})"
SMSDB="${DBDIR}/$(awk '/^Database/ {print $3}' ${GAMMURC})"
LOCDB="${DBDIR}/locations.sqlite"

NUMBER=$(sqlite3 "${SMSDB}" "select sendernumber from inbox where id = ${MSGID};")

LASTKNOWN_LOC=$(sqlite3 "${LOCDB}" "select \"https://www.openstreetmap.org/?mlat=\" || lat ||\"&mlon=\"|| lon || \"&zoom=15\" from locations order by datetime desc limit 1")

echo "${LASTKNOWN_LOC}" | gammu-smsd-inject TEXT "${NUMBER}"

