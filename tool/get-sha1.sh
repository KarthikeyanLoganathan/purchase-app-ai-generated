#!/bin/bash
# get-sha1.sh

echo "Debug Keystore SHA-1:"
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android 2>/dev/null | grep "SHA1:" | cut -d' ' -f3

echo ""
echo "Copy this SHA-1 and use it in Google Cloud Console"