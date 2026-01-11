#!/bin/bash
# setup-gcp-oauth.sh

# Variables
PROJECT_ID="purchase-app-12345"  # Change this
PACKAGE_NAME="com.purchase.purchase_app"
SHA1_FINGERPRINT="AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD"  # Get from keytool

# Set the project
gcloud config set project $PROJECT_ID

# Enable required APIs
echo "Enabling APIs..."
gcloud services enable sheets.googleapis.com
gcloud services enable script.googleapis.com
gcloud services enable drive.googleapis.com

# Note: OAuth consent screen and credentials creation still need manual setup
# through the console because they require interactive configuration
echo "APIs enabled!"
echo ""
echo "MANUAL STEPS REQUIRED:"
echo "1. Go to https://console.cloud.google.com/apis/credentials/consent?project=$PROJECT_ID"
echo "2. Configure OAuth consent screen"
echo "3. Go to https://console.cloud.google.com/apis/credentials?project=$PROJECT_ID"
echo "4. Create Android OAuth client with:"
echo "   Package: $PACKAGE_NAME"
echo "   SHA-1: $SHA1_FINGERPRINT"