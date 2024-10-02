#!/bin/bash

# Variables (replace these with your actual values)
HUB_ID="b88a673e-cfe7-41bf-ba4d-9f91d311cc70"
DRIVER_ID="8179a4ef-b83f-485a-bb20-0d4b5605b586"
DEVICE_ID="6def03b5-43e4-4e1d-830a-a517ff09de80"
CHANNEL_ID="8d6c0dc5-5a22-4106-9f8d-d8e8f9f028dc"

# Step 1: Package the driver
echo "Packaging the driver..."
smartthings edge:drivers:package

# Step 2: Enroll the driver
echo "Enrolling the driver..."
smartthings edge:channels:enroll $HUB_ID -C $CHANNEL_ID

# Step 3: Assign the driver to a device
echo "Assigning the driver to a device..."
smartthings edge:channels:assign $DRIVER_ID -C $CHANNEL_ID

# Step 4: Start logcat to monitor logs
echo "Starting logcat to monitor logs..."
smartthings edge:drivers:logcat $DRIVER_ID
