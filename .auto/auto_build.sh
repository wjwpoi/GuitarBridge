#!/bin/bash
# GuitarBridge Auto-Iterate Script
# Run by cron

cd /Users/wjwpoi/.openclaw/workspace/GuitarBridge

LOG="/Users/wjwpoi/.openclaw/workspace/GuitarBridge/.auto/auto.log"
echo "=== $(date) ===" >> $LOG

# Try build
xcodebuild -project GuitarBridge.xcodeproj -scheme GuitarBridge -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build >> $LOG 2>&1

if [ $? -eq 0 ]; then
    echo "BUILD SUCCEEDED" >> $LOG
else
    echo "BUILD FAILED - needs fix" >> $LOG
fi
