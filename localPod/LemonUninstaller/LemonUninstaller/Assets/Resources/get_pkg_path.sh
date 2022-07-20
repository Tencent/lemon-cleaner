#!/bin/sh

#  Script.sh
#  LemonUninstaller
#
#  
#  Copyright © 2019 Tencent. All rights reserved.

readonly PKGNAME=$(basename "$1")

vol=$(pkgutil --pkg-info "$PKGNAME" | grep "volume:" | cut -f 2 -d ' ')
loc=$(pkgutil --pkg-info "$PKGNAME" | grep "location:" | cut -f 2 -d ' ')

echo "$vol$loc/" | sed "s|//*|/|g"
