#!/bin/sh

#  copyLemonToApplication.sh
#  Lemon
#
#  
#  Copyright © 2018 Tencent. All rights reserved.
#rename
name="${@:1}"
path="/Applications/"${name}
echo $name
echo $path
if [ "${name}" != "Tencent Lemon.app" ]
then
echo "move"
mv "${path}" /Applications/Tencent\ Lemon.app
fi
