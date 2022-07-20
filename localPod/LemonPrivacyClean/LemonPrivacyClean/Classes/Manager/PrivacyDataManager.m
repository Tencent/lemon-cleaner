//
//  PrivacyDataManager.m
//  FMDBDemo
//
//  
//  Copyright © 2018年 tencent. All rights reserved.
//

#import "PrivacyDataManager.h"
#import "ChromePrivacyDataManager.h"
#import "SafariPrivacyDataManager.h"
#import "FirefoxPrivacyManager.h"
#import "QQBrowserPrivacyDataManager.h"
#import "OperaPrivacyDataManager.h"
#import "BrowserApp.h"
#import <QMCoreFunction/McCoreFunction.h>
#import "ChromiumPrivacyDataManager.h"
#import "MicrosoftEdgeDevPrivacyDataManager.h"
#import "MicrosoftEdgeBetaPrivacyDataManager.h"
#import "MicrosoftEdgeCanaryPrivacyDataManager.h"
#import "MicrosoftEdgePrivacyDataManager.h"

@implementation PrivacyDataManager



+ (NSImage *)getBrowserIconByType:(PRIVACY_APP_TYPE)type {


    //获取 Application 目录下的所有应用
    //NSArray *urls = [[NSFileManager defaultManager] URLsForDirectory:NSApplicationDirectory inDomains:NSLocalDomainMask];

    NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
    NSString *identifier = getAppIdentifierByType(type);
    NSBundle *bundle = [NSBundle bundleWithIdentifier:identifier];
    NSString *applicationPath = [bundle bundlePath];

    if(!applicationPath){
        NSString *appName = [bundle objectForInfoDictionaryKey:@"CFBundleExecutable"];
        if (!appName) {
            appName = getDefaultAppNameByType(type);
        }
        NSLog(@"AppName: %@",appName);
        
        if (!appName){
            return nil;
        }
        applicationPath = [workspace fullPathForApplication:appName];
        
        NSLog(@"applicationPath: %@",applicationPath);

    }
    

    if (!applicationPath) {
        return nil;
    }
    NSImage *image = [workspace iconForFile:applicationPath];
    return image;
}

// 1. app 是否运行
// 2. 检测系统安装着哪些需要检测的 app.
// 3. 如果 app 在运行,杀死 app.
// -1 代表 找不到这个 app, -2 代表
+ (NSInteger)checkAppIfRunning:(NSString *)identifier {

    // MARK: appName 和是否可以由用户更改. 比如用户安装了2个 chrome 浏览器
    // 修改了 app 的 name 比如 /Application/Google Chrome 改成 /Applications/Google Chrome appName 也改变了.
//    NSWorkspace *workSpace = [NSWorkspace sharedWorkspace];
//    NSString *appPathIs = [workSpace fullPathForApplication:appName];
//    NSString *identifier = [[NSBundle bundleWithPath:appPathIs] bundleIdentifier];;
//    if(!identifier){
//        return -1;
//    }

    NSArray *selectedApps =
            [NSRunningApplication runningApplicationsWithBundleIdentifier:identifier];

    if (!selectedApps || selectedApps.count <= 0) {
        return -2;
    } else {
        return selectedApps.count;
    }
}


+ (NSArray *)getAppRunningArray:(NSString *)identifier {

    NSArray *selectedApps =
            [NSRunningApplication runningApplicationsWithBundleIdentifier:identifier];

    if (!selectedApps || selectedApps.count <= 0) {
        return nil;
    } else {
        return selectedApps;
    }
}

+ (NSArray *)getInstalledAndRunningBrowserApps {

//    NSMutableArray *arr
    NSArray *needCheckAppTypes = [self getNeedCheckAppTypes];

    NSMutableArray *apps = [[NSMutableArray alloc] init];
    for (NSNumber *type in needCheckAppTypes) {
        NSString *identifierByType = getAppIdentifierByType((PRIVACY_APP_TYPE) type.intValue);
        if (!identifierByType) {
            continue;
        }

        BOOL installed = [self checkAppIfInstalled:identifierByType];
        if (installed) {
            BrowserApp *app = [[BrowserApp alloc] init];
            app.appType = (PRIVACY_APP_TYPE) type.intValue;
            app.bundleIdentifier = identifierByType;
            app.appName = getAppNameByType((PRIVACY_APP_TYPE) type.intValue);
            app.isRunning = [self checkAppIfRunning:identifierByType] > 0;
            app.runningApps = [self getAppRunningArray:identifierByType];
            [apps addObject:app];
        }
    }
    return apps;
}

- (void)killAppsAndToScan:(NSArray *)apps needKill:(BOOL)killFlag {
    if (!apps) return;
    if (killFlag) {
        [PrivacyDataManager killBrowserApps:apps];
    }
    [self getBrowserData:apps];
}

+ (BOOL)killBrowserApps:(NSArray *)apps {

    NSInteger flagNum = 0;
    for (BrowserApp *app in apps) {
        if (app.isRunning) {
            BOOL flag = [self killRunningApplicationsAt:app];
            if (flag) {
                flagNum++;
            }
        } else {
            flagNum++;
        }
    }
    return flagNum == apps.count;
}

// 这里如果使用 NSSet 无法保证 app 的顺序
+ (NSArray *)getNeedCheckAppTypes {
    NSMutableArray *apps = [[NSMutableArray alloc] init];
    [apps addObject:@(PRIVACY_APP_CHROME)];
    [apps addObject:@(PRIVACY_APP_CHROMIUM)];
    [apps addObject:@(PRIVACY_APP_FIREFOX)];
    [apps addObject:@(PRIVACY_APP_MICROSOFT_EDGE)];
    [apps addObject:@(PRIVACY_APP_MICROSOFT_EDGE_BETA)];
    [apps addObject:@(PRIVACY_APP_MICROSOFT_EDGE_DEV)];
    [apps addObject:@(PRIVACY_APP_MICROSOFT_EDGE_CANARY)];
    [apps addObject:@(PRIVACY_APP_OPERA)];
    [apps addObject:@(PRIVACY_APP_QQ_BROWSER)];
    [apps addObject:@(PRIVACY_APP_SAFARI)];
    return apps;
}


+ (BOOL)killRunningApplicationsAt:(BrowserApp *)app {
    
    if (!app ) return YES;
    
    //在kill app 的时候真正的获取下 需要杀死的进程 pid,防止真正 kill 的时候pid 不存在或者替换成另外 一个应用.造成的系统崩溃问题.
    app.runningApps = [self getAppRunningArray:app.bundleIdentifier];
    if(!app.runningApps) return YES;
    
    for (id item in app.runningApps) {
        if ([item isKindOfClass:NSRunningApplication.class]) {
            NSRunningApplication *runningItem = item;
            
            int pid = runningItem.processIdentifier;
            NSString *executePath = [runningItem.executableURL path];
            [[McCoreFunction shareCoreFuction] killProcessByID:pid ifMatch:executePath];
        }
    }

    return YES;
}
// MARK: cfString <-> NSString
// CFStringRef aCFString = (CFStringRef)aNSString;
// NSString *aNSString = (NSString *)aCFString;
// The previous syntax was for MRC. If you're using ARC, the new casting syntax is as follows:
// NSString *aNSString = (__bridge NSString *)aCFString; or NSString *happyString = (NSString *)CFBridgingRelease(sadString);
// __bridge transfers a pointer between Objective-C and Core Foundation with no transfer of ownership.
// __bridge_retained or CFBridgingRetain casts an Objective-C pointer to a Core Foundation pointer and also transfers ownership to you. You are responsible for calling CFRelease or a related function to relinquish ownership of the object.
// __bridge_transfer or CFBridgingRelease moves a non-Objective-C pointer to Objective-C and also transfers ownership to ARC. ARC is responsible for relinquishing ownership of the object.

+ (BOOL)checkAppIfInstalled:(NSString *)bundleIdentifier {

    BOOL isDriveInstalled = NO;

    // __bridge  CF和OC对象转化时只涉及对象类型不涉及对象所有权的转化
    // __bridge_transfer 常用在CF对象转化成OC对象时，将CF对象的所有权交给OC对象，此时ARC就能自动管理该内存,作用同CFBridgingRelease()
    // __bridge_retained  与__bridge_transfer 相反，常用在将OC对象转化成CF对象，且OC对象的所有权也交给CF对象来管理，即OC对象转化成CF对象时，涉及到对象类型和对象所有权的转化，作用同CFBridgingRetain()

    CFStringRef cfBundleIdentifier = (__bridge CFStringRef) bundleIdentifier;
    CFArrayRef urlArrayRef = LSCopyApplicationURLsForBundleIdentifier(cfBundleIdentifier, NULL);
    if (urlArrayRef != NULL && CFArrayGetCount(urlArrayRef) > 0) {
        isDriveInstalled = YES;
        CFRelease(urlArrayRef);  // CF对象不被 ARC管理, 需要主动调用  CFRelease(object), object不能为null.
    }
    return isDriveInstalled;
}


- (NSArray *)getChromeAppDataWithRunning:(BOOL)running processRate:(double)processRate processStart:(double)startValue {
    
    NSMutableArray *returnArray = [[NSMutableArray alloc] init];
    NSArray *dataPathArray = [ChromePrivacyDataManager getBrowserDataPathArray];
    
    PrivacyAppData *appDataAtDefaultPath;
    for(NSString* pathItem in dataPathArray){
        ChromePrivacyDataManager *browserManager = [ChromePrivacyDataManager sharedManagerWithDataPath:pathItem];
        PrivacyAppData *data = [browserManager getBrowserDataWithManager:self running:running processRate:processRate processStart:startValue];
        NSUInteger totalNum = [self getAppdataSubItemsCount:data];
        if(totalNum > 0){
            [returnArray addObject:data];
        }
        
        if([[browserManager getBrowserDefaultPath] isEqualToString: [ChromePrivacyDataManager getChromeDataDefaultPath]]){
            appDataAtDefaultPath = data;
        }
    }
    
    //当 chrome 没有扫描到任何数据时, 添加 default目录对应的 appData. (防止界面上没有任何数据显示)
    if([returnArray count] <= 0){
         [returnArray addObject:appDataAtDefaultPath];
    }
    
    // reset appData name :Chrome多用户时,获取账户名
    if([returnArray count] >1){
        
        NSUInteger index = 1;
        for(PrivacyAppData *appData in returnArray){
            NSString *accountName = [ChromePrivacyDataManager tryGetAccountNameByPath:appData.dataPath];
            if([appData.dataPath isEqualToString:[ChromePrivacyDataManager getChromeDataDefaultPath]] ){
                 accountName = NSLocalizedStringFromTableInBundle(@"DefaultAccount", nil, [NSBundle bundleForClass:[self class]], @"");
            }
            appData.account = accountName;
            NSString *accoutString = NSLocalizedStringFromTableInBundle(@"Account", nil, [NSBundle bundleForClass:[self class]], @"");
            appData.showAccount = [NSString stringWithFormat:@"%@%lu: %@",accoutString,  (unsigned long)index, accountName];
            index ++;
        }
    }
    
    return returnArray;
}


- (PrivacyAppData *)getDefaultBrowserAppDataWithRunning:(BOOL)running manager:(BaseBrowserPrivacyDataManager*)manager processRate:(double)processRate processStart:(double)startValue {
    PrivacyAppData *data = [manager getBrowserDataWithManager:self running:running processRate:processRate processStart:startValue];
    return data;
}


- (void)getBrowserData:(NSArray *)apps {

    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        if (self.delegate) {
            [self.delegate scanStart];
        }

        NSMutableArray *privacyAppDataArray = [[NSMutableArray alloc] init];
        NSInteger totalAppNum = apps.count;
        double appProcess = 1.0 / totalAppNum;
        double processStart = 0.0;


        NSUInteger iteratorIndex = 0;
        NSUInteger countOfFirstAppData = 0;

        for (BrowserApp *app in apps) {

            if (app.appType == PRIVACY_APP_CHROME) {
                NSArray *dataArray = [self getChromeAppDataWithRunning:app.isRunning processRate:appProcess processStart:processStart];
                // TODO chrome 的数据添加
                for(PrivacyAppData *appData in dataArray){
                    [self insertData:appData inArray:privacyAppDataArray firstAppItemNum:&countOfFirstAppData index: iteratorIndex];
                    iteratorIndex ++;
                }
            }else{
                BaseBrowserPrivacyDataManager *manager;
                PrivacyAppData *appData;
                if (app.appType == PRIVACY_APP_SAFARI) {
                    manager = [SafariPrivacyDataManager sharedManager];
                }
                
                if (app.appType == PRIVACY_APP_FIREFOX) {
                    manager = [FirefoxPrivacyManager sharedManager];
                }
                
                if (app.appType == PRIVACY_APP_QQ_BROWSER) {
                    manager = [QQBrowserPrivacyDataManager sharedManager];
                }
                
                if (app.appType == PRIVACY_APP_OPERA) {
                    manager = [OperaPrivacyDataManager sharedManager];
                }
                
                if(app.appType == PRIVACY_APP_CHROMIUM){
                    manager = [ChromiumPrivacyDataManager sharedManager];
                }
                
                if(app.appType == PRIVACY_APP_MICROSOFT_EDGE_BETA){
                    manager = [MicrosoftEdgeBetaPrivacyDataManager sharedManager];
                }
                
                if(app.appType == PRIVACY_APP_MICROSOFT_EDGE_DEV){
                    manager = [MicrosoftEdgeDevPrivacyDataManager sharedManager];
                }
                
                if(app.appType == PRIVACY_APP_MICROSOFT_EDGE_CANARY){
                    manager = [MicrosoftEdgeCanaryPrivacyDataManager sharedManager];
                }
                
                if(app.appType == PRIVACY_APP_MICROSOFT_EDGE){
                    manager = [MicrosoftEdgePrivacyDataManager sharedManager];
                }
                
                appData = [self getDefaultBrowserAppDataWithRunning:app.isRunning manager:manager processRate:appProcess processStart:processStart];
                [self insertData:appData inArray:privacyAppDataArray firstAppItemNum:&countOfFirstAppData index: iteratorIndex];

                iteratorIndex++;
            }

            // for循环中, 每一次去更新一下
            processStart += appProcess;
            if (self.delegate) {
                [self.delegate scanProcess:processStart text:nil];
            }
        }

        PrivacyData *data = [[PrivacyData alloc] init];
        data.subItems = privacyAppDataArray;

        if (self.delegate) {
            [self.delegate scanEnd:data];
        }
    });

}

- (void)insertData:(PrivacyAppData*)appData inArray:(NSMutableArray *)privacyAppDataArray firstAppItemNum:(NSUInteger*)firstAppItemNum  index:(NSUInteger)index {
    if (appData != nil) {
        //没有数据的 app, add 到最后面
        
    
        NSUInteger totalItemNum = [self getAppdataSubItemsCount:appData];
        if (index == 0) {
            *firstAppItemNum = totalItemNum;
        }
        
        // 第一项展示的 app 需要 expand item 后展示 ,所以第一个 app 需要有足够的数据.
        if (*firstAppItemNum < 50 && totalItemNum > *firstAppItemNum) {
            [privacyAppDataArray insertObject:appData atIndex:0];
            *firstAppItemNum = totalItemNum;
        } else {
            [privacyAppDataArray addObject:appData];
        }
    }
}

-(NSUInteger)getAppdataSubItemsCount:(PrivacyAppData *)appData{
    NSUInteger totalItemNum = 0;
    if(!appData){
        return 0;
    }
    if (appData.subItems) {
        for (PrivacyCategoryData *categoryData in appData.subItems) {
            if (categoryData.subItems) {
                totalItemNum += categoryData.subItems.count;
            }
        }
    }
    
    return totalItemNum;
}

- (void)killAppAndCleanWithData:(PrivacyData *)privacyData runningApps:(NSArray *)runningApps needKill:(BOOL)killFlag {

    if (killFlag && runningApps) {
        [PrivacyDataManager killBrowserApps:runningApps];
    }

    if (self.delegate) {
        [self.delegate scanStart];
    }

    if (!privacyData || privacyData.selectedSubItemNum == 0) {
        NSLog(@"no data need to clean");
        if (self.delegate) {
            [self.delegate scanEnd:privacyData];
        }
        return;
    }

    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        BOOL chromeFlag = NO;
        BOOL safariFlag = NO;
        BOOL firefoxFlag = NO;
        BOOL qqBrowserFlag = NO;
        BOOL operaFlag = NO;

        NSInteger totalAppNum = privacyData.subItems.count;
        double startProcess = 0.0;
        double itemProcess = 1.0 / totalAppNum;
        for (PrivacyAppData *appData in privacyData.subItems) {
            BaseBrowserPrivacyDataManager *manager;

            switch (appData.appType) {
                case PRIVACY_APP_CHROME:
                    //TODO 分 path 清理
                    manager = [ChromePrivacyDataManager sharedManagerWithDataPath:appData.dataPath];
                    break;
                case PRIVACY_APP_SAFARI:
                    manager = [SafariPrivacyDataManager sharedManager];
                    break;
                case PRIVACY_APP_FIREFOX:
                    manager = [FirefoxPrivacyManager sharedManager];
                    break;
                case PRIVACY_APP_QQ_BROWSER:
                    manager = [QQBrowserPrivacyDataManager sharedManager];
                    break;
                case PRIVACY_APP_OPERA:
                    manager = [OperaPrivacyDataManager sharedManager];
                    break;
                case PRIVACY_APP_CHROMIUM:
                    manager = [ChromiumPrivacyDataManager sharedManager];
                    break;
                case PRIVACY_APP_MICROSOFT_EDGE_CANARY:
                    manager = [MicrosoftEdgeCanaryPrivacyDataManager sharedManager];
                    break;
                case PRIVACY_APP_MICROSOFT_EDGE:
                    manager = [MicrosoftEdgePrivacyDataManager sharedManager];
                    break;
                case PRIVACY_APP_MICROSOFT_EDGE_DEV:
                    manager = [MicrosoftEdgeDevPrivacyDataManager sharedManager];
                    break;
                case PRIVACY_APP_MICROSOFT_EDGE_BETA:
                    manager = [MicrosoftEdgeBetaPrivacyDataManager sharedManager];
                    break;
            }
            
            qqBrowserFlag = [manager cleanBrowserDataWithManger:self data:appData processRate:itemProcess processStart:startProcess];
            startProcess += itemProcess;
        }

        if (chromeFlag && safariFlag && firefoxFlag && qqBrowserFlag) {
            NSLog(@"clean privacy data  success.");
        } else {
            NSLog(@"clean privacy data not success : chrome clean: %@, safari clean: %@,: firefox: %@, qqBrowser:%@ ,Opera:%@",
                    chromeFlag ? @"YES" : @"NO",
                    safariFlag ? @"YES" : @"NO",
                    firefoxFlag ? @"YES" : @"NO",
                    qqBrowserFlag ? @"YES" : @"NO",
                    operaFlag ? @"YES" : @"NO");
        }

        if (self.delegate) {
            [self.delegate scanEnd:privacyData];
        }
    });
}



@end
