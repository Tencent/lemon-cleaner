//
//  QMCacheEnumerator.h
//  LemonClener
//

//  Copyright © 2019 Tencent. All rights reserved.
//

/* 非沙盒程序直接将 ~/Library/Caches这个文件夹枚举出来
   沙盒程序直接将  ~/Library/Container/.+/Data/Library/Cache/bundleId所有的全部列列举出来
   将系统temp目录全部列举出来 /var/folders/../C/
 
    好处：
    1、可以加速扫描速度，不需要每次全量枚举 后 过滤
    2、可以通过相互匹配来增加匹配的精准度 防止缓存的误删
    3、可以自由增加缓存维度（缓存文件夹）或者 增加全局过滤策略
*/

#import <Foundation/Foundation.h>
@class QMActionItem;

@interface QMCacheEnumerator : NSObject

+(QMCacheEnumerator *)shareInstance;

//初始化 或者 重新初始化
-(void)initialData;

//获取某个action对应的垃圾
-(NSArray *)getCacheWithActionItem:(QMActionItem *)actionItem;

//获取所有剩余的cache
-(NSArray *)getLeftAppCache;

@end
