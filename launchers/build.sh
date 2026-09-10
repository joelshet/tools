#!/bin/sh
# Builds TabGroups.app next to this script. Relaunch the app after rebuilding.
set -eu
cd "$(dirname "$0")"
APP=TabGroups.app
mkdir -p "$APP/Contents/MacOS"
cp Info.plist "$APP/Contents/Info.plist"
swiftc -O TabGroups.swift -o "$APP/Contents/MacOS/TabGroups"
codesign --force -s - "$APP"
echo "built $APP"
