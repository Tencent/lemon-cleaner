//
//  LoginItemManager.h
//
//  
//

#import <Foundation/Foundation.h>

// 系统偏好设置 -> Users And Groups ->点选用户 -> LoginItems
@interface LMLoginItem : NSObject
@property(nonatomic) NSString *displayName;
@property NSString *bundlePath;       // 实际对应的 app 地址
@property NSString *hostBundlePath;   // 实际的 app 对应的宿主app地址
@end


@interface LoginItemManager : NSObject

+ (LMLoginItem *)loginItemAt:(NSString *)bundlePath;

+ (BOOL)removeLoginItemsByName:(NSString *)loginItemDisplayName;

+ (LMLoginItem *)loginItemAt:(NSString *)bundlePath in:(NSArray<LMLoginItem *> *)allLoginItems;

+ (NSArray<LMLoginItem *> *)getAllValidLoginItems;

@end
