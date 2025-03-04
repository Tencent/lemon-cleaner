//
//  McCoreFunction.h
//  McCoreFunction
//
//  
//  Copyright (c) 2012 Magican Software Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "McCoreFunctionCommon.h"
#import "QMFullDiskAccessManager.h"

typedef enum: NSUInteger {
    AppBinaryType_None = 0,
    AppBinaryType_X86,
    AppBinaryType_Arm64,
    AppBinaryType_Both,
} AppBinaryType;

@class McFileEvent;
@class McProcessInfo;
@class McFunCleanFile;
@interface McCoreFunction : NSObject
{
    McFileEvent * fileEvent;
    McProcessInfo * processInfo;
    McFunCleanFile * funCleanFile;

}

- (void)cutunlessBinary:(NSString *)path
                 array:(NSArray *)pathArray
             removeType:(AppBinaryType)type;

+ (id)shareCoreFuction;

+ (BOOL)isAppStoreVersion;

// get process info
- (NSArray *)processInfo:(float *)cpuUsage totalMemory:(uint64 *)memory;
- (void)processInfo:(float *)cpuUsage totalMemory:(uint64 *)memory block:(block_v_a)block_a;
// get file event info
- (NSArray *)fileEventInfo;
- (void)fileEventInfoAysnc:(block_v_a)block_a;

- (void)killProcessByID:(int)pid;
- (void)killProcessByID:(int)pid block:(block_v_i)block_i;

// 通过 pid + keyword 杀进程,防止误杀(因为上层调用和Daemon 真正执行有时间窗口).
// keyword 不能为空,key 可以为:进程名或者进程路径.
- (void)killProcessByID:(int)pid ifMatch:(NSString *)keyword;
- (void)killProcessByID:(int)pid ifMatch:(NSString *)keyword block:(block_v_i)block_i;


// 卸载
- (int)unInstallMagican;
- (void)unInstallMagicanAsync:(block_v_i)block_i;

- (int)notiflyClientExit;
- (void)notiflyClientExitAsync:(block_v_i)block_i;

// 更新程序
// fullVersion 可以传 Null,由newAppPath 自动取版本号.
- (int)updateAPP:(NSString *)newAppPath fullVersion:(NSString *)fullVersion;
- (void)updateAPP:(NSString *)newAppPath fullVersion:(NSString *)fullVersion block:(block_v_i)block_i;

// get full disk access for Daemon
- (QMFullDiskAuthorationStatus)getFullDiskAccessForDaemon;

// set fan speed
- (void)setFanMinSpeeds:(int)index minSpeed:(float)speed;
- (void)setFanMinSpeeds:(int)index minSpeed:(float)speed block:(block_v_i)block_i;

- (void)getFanSpeeds:(block_v_a)completion;
- (void)getCPUTemperature:(block_v_a)completion;

// 摄像头或音频接口
- (BOOL)changeOwlDeviceProcInfo:(int)deviceType deviceState:(int)deviceState;
- (void)changeOwlDeviceProcInfo:(int)deviceType deviceState:(int)deviceState block:(block_v_i)block_i;
- (NSArray *)getOwlDeviceProcInfo:(int)deviceType deviceState:(int)deviceState;
- (void)getOwlDeviceProcInfo:(int)deviceType deviceState:(int)deviceState block:(block_v_a)block_a;

// changeNetworkInfo is chmod 644 /dev/bpf* for get network info
- (BOOL)changeNetworkInfo;
- (void)changeNetworkInfoAsync:(block_v_b)block;


// purgeMemory
- (BOOL)purgeMemory;
- (void)purgeMemoryAsync:(block_v_b)block;

// unInstallPlist
- (BOOL)unInstallPlist:(NSString *)plist;
- (void)unInstallPlist:(NSString *)plist block:(block_v_b)block;

- (NSDictionary*)getFileInfo:(NSString *)filePath;
- (void)getFileInfoAsync:(NSString *)filePath block:(block_v_d)block;






// 排序方法,不需要异步通信.
- (void)sortProcess:(NSMutableArray *) array
          orderEnum:(ProcessOrderEnum) orderEnum
              isAsc:(BOOL) isAsc;





// remove files
- (BOOL)cleanItemAtPath:(NSString *)path
                  array:(NSArray *)pathArray
             removeType:(McCleanRemoveType)type;

- (void)startCleanWithThread:(NSArray *)removePaths
                   cutBinary:(NSArray *)binaries
                    delegate:(id<McCleanDelegate>)cleanDelegate
                  removeType:(McCleanRemoveType)type;

- (BOOL)moveFileItem:(NSString *)path1 toPath:(NSString *)path2;
- (BOOL)copyFileItem:(NSString *)path1 toPath:(NSString *)path2;



// 以下方法暂未发现调用,不提供异步方法.
- (void)fixPlistFile:(NSString *)file removeKey:(NSString *)key;

// 0 default plist, 1 system plist, 以下方法暂未发现调用,不提供异步方法.
- (BOOL)modifyPlistFileByString:(NSString *)file key:(NSString *)key plistType:(int)type obj:(NSString *)obj;
- (BOOL)modifyPlistFileByNumber:(NSString *)file key:(NSString *)key plistType:(int)type obj:(NSNumber *)obj;
- (BOOL)modifyPlistFileByDic:(NSString *)file key:(NSString *)key plistType:(int)type obj:(NSDictionary *)obj;
- (BOOL)removePlistFileyKey:(NSString *)file key:(NSString *)key plistType:(int)type;

// uninstall Kext
- (BOOL)uninstallKextWithBundleId:(NSString *)kext;
- (void)uninstallKextWithBundleId:(NSString *)kext block:(block_v_b)block;

/*
 卸载 内核拓展(驱动).  unload Kext 并且移除 kext文件,如果可能的话. kext 文件一般存贮在/Library/Extensions
 kext:需要卸载的驱动的bundleId.
 */
- (BOOL)uninstallKextWithPath:(NSString *)kext;
- (void)uninstallKextWithPath:(NSString *)kext block:(block_v_b)block;


- (BOOL)removePkgInfoWithBundleId:(NSString *)bundleId;
- (void)removePkgInfoWithBundleId:(NSString *)bundleId block:(block_v_b)block;

// 废弃 : remove Login Item (by name) .直接使用系统 api 移除. 并且 root 权限下执行 applescript 也是失败的.
- (BOOL)removeLoginItem:(NSString *)loginItem; //不要在主线程调用,内部有 applescript 操作.
- (void)removeLoginItem:(NSString *)loginItem block:(block_v_b)block;

//collect the lemon log info
- (BOOL)collectLemonLogInfo:(NSString *)userName;
- (void)collectLemonLogInfo:(NSString *)userName block:(block_v_b)block;

//pf is control the ipfw(or iptable)
- (BOOL)setLemonFirewallPortPF:(NSString *)strTcpPort udpPort:(NSString *)strUdpPort;
- (void)setLemonFirewallPortPF:(NSString *)strTcpPort udpPort:(NSString *)strUdpPort block:(block_v_b)block;

// stat port using info(through lsof)
- (NSArray *)statPortProcInfo;
- (void)statPortProcInfoAsync:(block_v_a)block_a;

- (BOOL)enableLaunchSystemWithFilePath:(NSString *)path label:(NSString *)label;
- (void)enableLaunchSystemAsyncWithFilePath:(NSString *)path label:(NSString *)label block:(block_v_i)block;

- (BOOL)disableLaunchSystemWithFilePath:(NSString *)path label:(NSString *)label;
- (void)disableLaunchSystemAsyncWithFilePath:(NSString *)path label:(NSString *)label block:(block_v_i)block;

- (BOOL)getLaunchSystemStatusWithlabel:(NSString *)label;

@end
