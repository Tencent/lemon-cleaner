#!/bin/sh

#  copyLemonToApplication.sh
#  Lemon
#
#  
#  Copyright © 2018 Tencent. All rights reserved.
rm -rf /Applications/Tencent\ Lemon.app
#path可能会有空格这里"${@:2}"把第二个参数以后的所有参数h合成一个参数
cp -Rf "${@:1}" /Applications
