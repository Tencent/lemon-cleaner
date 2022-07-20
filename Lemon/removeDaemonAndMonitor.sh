#!/bin/sh

#  removeDaemonAndMonitor.sh
#  Lemon
#
#  
#  Copyright © 2018 Tencent. All rights reserved.
#!/bin/sh

#  uninstall.sh
#  LemonInstaller
#
#  
#  Copyright © 2018年 Tencent. All rights reserved.
launchctl unload /Library/LaunchDaemons/com.tencent.Lemon.plist
launchctl unload /Library/LaunchDaemons/com.tencent.Lemon.trash.plist
launchctl unload /Library/LaunchAgents/com.tencent.LemonMonitor.plist

launchctl unload ~/Library/LaunchAgents/com.tencent.Lemon.monitor.trash.plist




rm -rf /Library/Application\ Support/Lemon
rm -f /Library/LaunchDaemons/com.tencent.Lemon.plist
rm -f /Library/LaunchAgents/com.tencent.LemonMonitor.plist
rm -f /Library/LaunchDaemons/com.tencent.Lemon.trash.plist

rm -f ~/Library/LaunchAgents/com.tencent.Lemon.monitor.trash.plist

# 要先删掉文件再kill, unload后立马kill,系统可能还会立马把LemonDaemon重新拉起
# 先把文件删了，系统想拉起也找不到文件了。

pkill -f Lemon\ uninstall-monitor
pkill -f LemonDaemon
pkill -f LemonUpdate
