# Overview

This simple app for iOS shows the AutoAPI data received and parsed from a connected device.  
Works with *bluetooth* and *telematics*.

# Configuration

Before running the app, make sure to configure the following in `Configuration.swift`:

1. Initialise HMKit with a valid `Device Certiticate` from the Developer Center https://developers.high-mobility.com/
2. Find an `Access Token` in an emulator from https://developers.high-mobility.com/ and paste it in the source code to download `Access Certificates` from the server

# Usage

Basics:
* Run the app on your phone, or the iOS simulator (only telematics).
* Connect to a vehicle, either through bluetooth or telematics.
* First command sent is *Get Vehicle Status* to populate the app with data.
* Refresh button sends *Get Vehicle Status* for a comprehensive update.
* The "catalogue" button shows the list of commands *sent* and *received*.
  
Connections:
- Bluetooth – *states updates* are pushed to the phone automatically and the values update themselves.  
- Telematics – changes are only visible after refreshing.
