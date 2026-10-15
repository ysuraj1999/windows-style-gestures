#!/bin/sh
# Builds windows-style-gestures.kwinscript from the package/ folder.
set -e
cd "$(dirname "$0")"
out="$PWD/windows-style-gestures.kwinscript"
rm -f "$out"
(cd package && zip -qr -X "$out" metadata.json contents)
echo "Built $out"
