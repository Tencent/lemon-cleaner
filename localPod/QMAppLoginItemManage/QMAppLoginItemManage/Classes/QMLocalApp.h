//
//  QMLocalApp.h
//  QMAppLoginItemManage
//
//  
//  Copyright © 2020 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/*
 Local app model
 */
@interface QMLocalApp : NSObject

///bundle Id
@property (nonatomic) NSString *bundleId;

///bundle path
@property (nonatomic) NSString *bundlePath;

///app name
@property (nonatomic) NSString *appName;

///save app info
@property (nonatomic) NSDictionary *infoDict;

- (instancetype)initWithBundlePath:(NSString *)path;

@end

NS_ASSUME_NONNULL_END
