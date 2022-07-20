#!/bin/sh

#  killDeamonAndMonitor.sh
#  Lemon
#
#  
#  Copyright © 2018 Tencent. All rights reserved.
launchctl unload /Library/LaunchDaemons/com.tencent.Lemon.plist
launchctl unload /Library/LaunchAgents/com.tencent.LemonMonitor.plist
pkill -f Lemon\ Menu\ bar
pkill -f LemonDaemon
