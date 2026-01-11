need a file deployer.js

it should archive any running deployment for the current Google Apps Script project, do new deployment as web app that can be accessed by anyone executed as Me. Get the web-app url. Copy it to sheet config cell (3,2). And show the URL in a popup in a kind of text box to quickly copy to clipboard.






Enable Google Script API

The "Google Apps Script API" needs to be enabled in the Google Cloud Console, not in the Apps Script editor's Services section. Here's how to enable it:

Steps to Enable Apps Script API:
Go to Google Cloud Console

Visit: https://console.cloud.google.com/
Select Your Project

Make sure you're in the correct Google Cloud Project (the one linked to your Apps Script project)
You can find your project number in Apps Script: Project Settings (gear icon) → Google Cloud Platform (GCP) Project
Enable the API

In the Cloud Console, go to APIs & Services → Library
Search for "Apps Script API"
Click on it and press Enable
Alternative Quick Link

Or go directly to: https://console.cloud.google.com/apis/library/script.googleapis.com
Click Enable
Common Confusion:
The Services section in Apps Script editor is for adding Google services (like Gmail, Drive, etc.) to your script
The Apps Script API is a Cloud Platform API that needs to be enabled in the Cloud Console for deployments and external interactions
After enabling the API, wait a minute for it to propagate, then try your operation again.