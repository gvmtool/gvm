#!/bin/bash

echo ""
echo "Updating gvm scripts..."
TMP_ZIP="/tmp/res.zip"
BIN_FOLDER="$HOME/.gvm/bin"

mkdir -p "$HOME/.gvm/groovy"
mkdir -p "$HOME/.gvm/grails"
mkdir -p "$HOME/.gvm/griffon"
mkdir -p "$HOME/.gvm/vert.x"

mkdir -p "$BIN_FOLDER"
curl -s "$GVM_SERVICE/res?platform=$PLATFORM" > "$TMP_ZIP"
unzip -qo "$TMP_ZIP" -d "$BIN_FOLDER"
rm "$TMP_ZIP"

chmod +x "$BIN_FOLDER"/*

echo ""
echo "Successfully upgraded GVM."
echo ""
