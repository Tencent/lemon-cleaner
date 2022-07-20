//
//  TimeUitl.h
//  QMCoreFunction
//
//  
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TimeUitl : NSObject

+(CFTimeInterval) getSystemUptime;  //获取系统开机了多长时间, 同 shell 命令 `uptime` 结果相同.

@end

NS_ASSUME_NONNULL_END
