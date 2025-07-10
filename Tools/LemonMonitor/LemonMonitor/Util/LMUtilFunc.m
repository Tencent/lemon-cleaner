//
//  LMUtilFunc.m
//  LemonMonitor
//
//  Copyright © 2025 Tencent. All rights reserved.
//

#import "LMUtilFunc.h"
#import <QMCoreFunction/MdlsToolsHelper.h>
#import <QMCoreFunction/LMLoopTrigger.h>

#include <sys/mman.h>
#include <fcntl.h>
#include <unistd.h>

static const unsigned long long kKILOBYTE = 1024;
static const unsigned long long kMEGABYTE = kKILOBYTE * kKILOBYTE;

static NSErrorDomain const kLogFloodErrorDomain = @"kLogFloodErrorDomain";
static const NSInteger kLogFloodErrorCode= -2000;

NSString *monitorLogPath(void) {
    static NSString *logPath;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *logName = [[[NSBundle mainBundle] executablePath] lastPathComponent];
        
        
        //debug 版本路径: app execute path is /Users/anqixu/Library/Developer/Xcode/DerivedData/Lemon-ekrmddyrbgigkhgmnqsyhqbmonfx/Build/Products/Debug/Lemon.app/Contents/MacOS/Lemon
        //release版本路径: app execute path is /Applications/Lemon.app/Contents/MacOS/Lemon
        
        // do not redirect in test mode
        //if ([[[NSBundle mainBundle] executablePath] containsString:@"/Library"])
        //    return;
        
        NSString *rootLogPath = [NSString stringWithFormat:@"/Library/Logs/%@", logName];
        rootLogPath = [rootLogPath stringByAppendingPathExtension:@"log"];
        
        if (getuid() == 0)
        {
            // root
            logPath = rootLogPath;
        }
        else
        {
            // user
            logPath = [NSHomeDirectory() stringByAppendingPathComponent:rootLogPath];
        }
    });
    return logPath;
}

void redirctNSlog(void) {
    NSLog(@"redirctNSlog ...");
    NSString *logPath = monitorLogPath();
    [MdlsToolsHelper redirectLogToFileAtPath:logPath forDays:7 maxSize:100];
}


/// 读取大文件的首尾部分数据
/// - Parameters:
///   - filePath: 文件路径
///   - direction: 读取起始位置
///   - size: 读取的size(字节, 1KB is 1024bytes)
NSData *readDataFromFile(const char *filePath, LMReadDirection direction, size_t size) {
    int fd = open(filePath, O_RDONLY);
    if (fd == -1) {
        return nil;
    }

    off_t fileSize = lseek(fd, 0, SEEK_END);
    if (fileSize == -1) {
        close(fd);
        return nil;
    }

    size_t readSize = (size > fileSize) ? fileSize : size;
    off_t offset = (direction == LMReadFromHead) ? 0 : fileSize - readSize;

    // 使用 mmap 映射文件
    char *mapped = mmap(NULL, fileSize, PROT_READ, MAP_PRIVATE, fd, 0);
    if (mapped == MAP_FAILED) {
        close(fd);
        return nil;
    }

    NSData *data;
    if (direction == LMReadFromHead) {
        data = [NSData dataWithBytes:mapped length:readSize];
    } else {
        data = [NSData dataWithBytes:mapped + offset length:readSize];
    }

    // 解除映射和关闭文件
    munmap(mapped, fileSize);
    close(fd);

    return data;
}

// 辅助方法：提取文本行
NSArray<NSString *> *extractTailLines(NSData *data, NSUInteger maxLines) {
    if (!data || data.length == 0 || maxLines == 0) return @[];

    const uint8_t *bytes = (const uint8_t *)data.bytes;
    NSUInteger length = data.length;

    // 逆向扫描换行符
    NSMutableArray *lineOffsets = [NSMutableArray array];
    NSInteger lineCount = 0;

    for (NSInteger i = length - 1; i >= 0; i--) {
        if (bytes[i] == '\n') {
            [lineOffsets addObject:@(i)];
            lineCount++;
            if (lineCount >= maxLines) break;
        }
    }

    // 构建行数组 (从新到旧)
    NSMutableArray *lines = [NSMutableArray array];
    NSUInteger start = length;

    for (NSNumber *offset in [lineOffsets reverseObjectEnumerator]) {
        NSUInteger end = offset.unsignedIntegerValue;
        if (end < start - 1) {  // 跳过空行
            NSString *line = [[NSString alloc] initWithBytes:bytes + end + 1
                                                      length:start - end - 1
                                                    encoding:NSUTF8StringEncoding];
            if (line) {
                [lines addObject:line];
            }
        }
        start = end;
    }

    // 添加首行
    if (start > 0 && lines.count < maxLines) {
        NSString *firstLine = [[NSString alloc] initWithBytes:bytes
                                                       length:start
                                                     encoding:NSUTF8StringEncoding];
        if (firstLine) {
            [lines addObject:firstLine];
        }
    }

    // 反转行数组以恢复顺序
    return [[lines reverseObjectEnumerator] allObjects];
}

void trackExceptionLogAndCleanIfNeeded(void) {
    __block unsigned long long lastSize = 0;
      [[LMLoopTrigger sharedInstance] runModes:LMLoopTriggerRunModeEveryOneHour key:@"trackExceptionLogKey" callback:^{
          dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
              // 读取日志文件大小
              NSString *logPath = monitorLogPath();
              NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:logPath error:nil];
              if (fileAttributes) {
                  unsigned long long currentSize = [fileAttributes fileSize];
                  if (lastSize != 0) {
                      if (currentSize > 100 * kMEGABYTE) {
                          // 本次日志超过100MB，则重定向（需要删除日志然后重定向）
                          // 处理用户长期未重启LemonMonitor的情况
                          redirctNSlog();
                          // 重新读取文件大小
                          fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:logPath error:nil];
                          currentSize = [fileAttributes fileSize];
                      }
                  }
                  lastSize = currentSize;
              }
          });
      }];
}
