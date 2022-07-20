//
//  PrivacyData.h
//  FMDBDemo
//
//  
//  Copyright © 2018年 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>


// browser type
typedef NS_ENUM(NSUInteger, PRIVACY_APP_TYPE) {
    PRIVACY_APP_SAFARI = 1,
    PRIVACY_APP_CHROME = 2,
    PRIVACY_APP_FIREFOX = 3,
    PRIVACY_APP_QQ_BROWSER = 4,
    PRIVACY_APP_OPERA = 5,
    PRIVACY_APP_CHROMIUM = 6,
    PRIVACY_APP_MICROSOFT_EDGE_BETA = 7,
    PRIVACY_APP_MICROSOFT_EDGE_DEV = 8,
    PRIVACY_APP_MICROSOFT_EDGE_CANARY = 9,
    PRIVACY_APP_MICROSOFT_EDGE = 10,
    
};


typedef NS_ENUM(NSUInteger, PRIVACY_CATEGORY_TYPE) {
    PRIVACY_CATEGORY_TYPE_COOKIE = 1,
    PRIVACY_CATEGORY_TYPE_BROWSER_HISTORY = 2,
    PRIVACY_CATEGORY_TYPE_DOWNLOAD_HISTORY = 3,
    PRIVACY_CATEGORY_TYPE_SESSION = 4,
    PRIVACY_CATEGORY_TYPE_LOCAL_STORAGE = 5,
    PRIVACY_CATEGORY_TYPE_SAVE_PASSWORD = 6,
    PRIVACY_CATEGORY_TYPE_AUTOFILL = 7,

};

extern NSString *getAppNameByType(PRIVACY_APP_TYPE type);

extern NSString *getDefaultAppNameByType(PRIVACY_APP_TYPE type);

extern NSString *getAppIdentifierByType(PRIVACY_APP_TYPE type);

extern NSString *getCategoryNameByType(PRIVACY_CATEGORY_TYPE type);

extern NSString *getCategoryDescByType(PRIVACY_CATEGORY_TYPE type);

extern NSImage *getCategoryImageByType(PRIVACY_CATEGORY_TYPE type);


@interface BasePrivacyData : NSObject

@property(nonatomic, assign) NSInteger totalSubNum;
@property(nonatomic, assign) NSInteger selectedSubItemNum;
@property(nonatomic, assign) NSControlStateValue state;
@property(nonatomic, retain) NSArray *subItems;

- (void)refreshItemStateValue;   // 根据子 item 的 state 去决定自己的 state
- (NSInteger)resultSelectedCountByRecursive;

- (void)setStateWithSubItemsIfHave:(NSControlStateValue)stateValue;

- (void)calculateSubItemsTotalNum;

@end


@interface PrivacyData : BasePrivacyData


@end


@interface PrivacyAppData : BasePrivacyData

@property(nonatomic, assign) PRIVACY_APP_TYPE appType;
@property(nonatomic, retain) NSString *appName;
@property(nonatomic, retain) NSString *dataPath; //数据来源的路径
@property(nonatomic, retain) NSString *account;
@property(nonatomic, retain) NSString *showAccount; 

@end


@interface PrivacyCategoryData : BasePrivacyData

@property(nonatomic, assign) PRIVACY_CATEGORY_TYPE categoryType;
@property(nonatomic, retain) NSString *categoryName;
@property(nonatomic, retain) NSString *tips;

// 还需要告知如何清理? 还是由各个 app 单独去处理?

@end


@interface PrivacyItemData : BasePrivacyData

//@property(nonatomic, assign) int itemType; //是数据库项还是文件.
@property(nonatomic, retain) NSString *itemName;


@end


@interface PrivacyFileItemData : PrivacyItemData

@property(nonatomic, retain) NSString *path;
@property(nonatomic, assign) BOOL isDirectory;


@end


@interface PrivacyPlistItemData : PrivacyItemData
@property(nonatomic, retain) NSString *path;


@end
