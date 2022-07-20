//
//  QMAppLoginItem.h
//
//  
//  Copyright © 2020 Tencent. All rights reserved.
//

#import "QMBaseLoginItem.h"


NS_ASSUME_NONNULL_BEGIN

/*
 App login item
 */
@interface QMAppLoginItem : QMBaseLoginItem

///App Name for login Item
@property (nonatomic) NSString *loginItemAppName;

///login item path
@property (nonatomic) NSString *loginItemPath;

///bunlde id for login item
@property (nonatomic) NSString *loginItemBundleId;


-(instancetype)initWithAppPath:(NSString *)appPath loginItemPath: (NSString *) loginItempath  loginItemType: (LoginItemType)type;

@end

NS_ASSUME_NONNULL_END
