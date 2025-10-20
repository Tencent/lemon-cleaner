//
//  LMUninstallerDetector.m
//  LemonUninstaller
//
//  Created by tencent on 2025/9/26.
//

#import "LMUninstallerDetector.h"

@interface LMUninstallerDetector ()

@property (nonatomic, copy) NSArray<NSString *> *uninstallerPatterns;
@property (nonatomic, copy) NSArray<NSString *> *uninstallerKeywords;

@end

@implementation LMUninstallerDetector

+ (instancetype)sharedInstance {
    static LMUninstallerDetector *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupDetector];
    }
    return self;
}

- (void)setupDetector {
    // 卸载程序文件名模式（全部小写）
    self.uninstallerPatterns = @[
        @"uninstall*.app",
        @"*uninstaller.app",
        @"remove*.app",
        @"*remover.app",
        @"*uninstall.app",
        @"uninstall*",
        @"remove*",
        @"*uninstaller*",
        @"*remover*"
    ];
    
    // 卸载程序关键词
    self.uninstallerKeywords = @[
        @"uninstall",
        @"remove",
        @"delete",
        @"uninstaller",
        @"remover"
    ];
}

#pragma mark - Public Methods

- (nullable NSString *)detectUninstallerForApp:(LMLocalApp *)app {
    if (!app || !app.bundlePath) {
        return nil;
    }
    
    NSString *appPath = app.bundlePath;
    NSString *appName = app.showName;  // 使用showname
    
    if (!appName || appName.length == 0) {
        return nil;
    }
    
    NSArray<NSString *> *uninstallerPaths = nil;
    NSString *searchDirectory = nil;
    
    // 检查应用包同级目录
    searchDirectory = [appPath stringByDeletingLastPathComponent];
    // 跳过系统级目录，这些目录下不会有应用专用的卸载程序
    NSArray *systemDirectories = @[
        @"/Applications",
        @"/Applications/Utilities",
        @"/System/Applications",
        @"/System/Library"
    ];
    
    BOOL isSystemDirectory = NO;
    for (NSString *systemDir in systemDirectories) {
        if ([searchDirectory isEqualToString:systemDir]) {
            isSystemDirectory = YES;
            break;
        }
    }
    
    if (!isSystemDirectory) {
        uninstallerPaths = [self findUninstallersInPath:searchDirectory appName:appName];
        // 过滤掉应用本身
        NSMutableArray *filteredPaths = [NSMutableArray array];
        for (NSString *path in uninstallerPaths) {
            if (![path isEqualToString:appPath]) {
                [filteredPaths addObject:path];
            }
        }
        if (filteredPaths.count > 0) {
            return [self processUninstallerPaths:filteredPaths inDirectory:searchDirectory];
        }
    }
    
    // 检查系统常见位置
    searchDirectory = @"/Applications/Utilities";
    uninstallerPaths = [self findUninstallersInPath:searchDirectory appName:appName];
    if (uninstallerPaths.count > 0) {
        return [self processUninstallerPaths:uninstallerPaths inDirectory:searchDirectory];
    }
    
    // 检查应用特定的卸载程序位置
//    NSDictionary *specialLocations = @{
//        @"Adobe": @[@"/Applications/Utilities/Adobe Installers"],
//        @"Parallels": @[@"/Applications/Parallels Desktop.app/Contents/MacOS"],
//        @"Steam": @[[@"~/Library/Application Support/Steam" stringByExpandingTildeInPath]]
//    };
//    
//    NSString *lowercaseAppName = appName.lowercaseString;
//    NSString *lowercaseBundleId = bundleId.lowercaseString;
//    for (NSString *vendor in specialLocations.allKeys) {
//        if ([lowercaseAppName containsString:vendor.lowercaseString] ||
//            [lowercaseBundleId containsString:vendor.lowercaseString]) {
//            
//            NSArray *paths = specialLocations[vendor];
//            for (NSString *path in paths) {
//                uninstallerPaths = [self findUninstallersInPath:path appName:appName];
//                if (uninstallerPaths.count > 0) {
//                    return [self processUninstallerPaths:uninstallerPaths inDirectory:path];
//                }
//            }
//        }
//    }
    
    return nil;
}

/**
 * 处理找到的卸载程序路径数组，根据数量返回不同结果
 * @param uninstallerPaths 找到的卸载程序路径数组
 * @param directory 搜索的目录路径
 * @return 如果只有一个卸载程序，返回卸载程序文件路径；如果有多个，返回目录路径
 */
- (NSString *)processUninstallerPaths:(NSArray<NSString *> *)uninstallerPaths inDirectory:(NSString *)directory {
    if (uninstallerPaths.count == 1) {
        // 只有一个卸载程序，返回具体的卸载程序文件路径
        return uninstallerPaths.firstObject;
    } else if (uninstallerPaths.count > 1) {
        // 有多个卸载程序，返回目录路径，让用户在Finder中选择
        return directory;
    }
    
    return nil;
}

- (NSArray<NSString *> *)findUninstallersInPath:(NSString *)path appName:(NSString *)appName {
    NSMutableArray<NSString *> *uninstallers = [[NSMutableArray alloc] init];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        return uninstallers;
    }
    
    NSError *error;
    NSArray<NSString *> *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:&error];
    if (error) {
        NSLog(@"Error reading directory %@: %@", path, error.localizedDescription);
        return uninstallers;
    }
    
    for (NSString *item in contents) {
        NSString *itemPath = [path stringByAppendingPathComponent:item];
        
        if ([self isUninstallerFile:item appName:appName]) {
            if ([self isValidUninstaller:itemPath]) {
                [uninstallers addObject:itemPath];
            }
        }
    }
    
    // 按相关性排序
    NSString *lowercaseAppName = appName.lowercaseString;
    [uninstallers sortUsingComparator:^NSComparisonResult(NSString *path1, NSString *path2) {
        NSString *name1 = [path1 lastPathComponent];
        NSString *name2 = [path2 lastPathComponent];
        
        // 优先选择包含应用名的卸载程序
        BOOL name1ContainsApp = [name1.lowercaseString containsString:lowercaseAppName];
        BOOL name2ContainsApp = [name2.lowercaseString containsString:lowercaseAppName];
        
        if (name1ContainsApp && !name2ContainsApp) {
            return NSOrderedAscending;
        } else if (!name1ContainsApp && name2ContainsApp) {
            return NSOrderedDescending;
        }
        
        return [name1 compare:name2];
    }];
    
    return [uninstallers copy];
}

- (BOOL)isValidUninstaller:(NSString *)uninstallerPath {
    if (!uninstallerPath) {
        return NO;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // 检查文件是否存在
    if (![fileManager fileExistsAtPath:uninstallerPath]) {
        return NO;
    }
    
    // 检查是否是可执行文件
    if ([uninstallerPath.pathExtension.lowercaseString isEqualToString:@"app"]) {
        // 检查是否是有效的应用包
        NSBundle *bundle = [NSBundle bundleWithPath:uninstallerPath];
        return bundle != nil && bundle.executablePath != nil;
    } else {
        // 检查是否是可执行文件（排除一些明显不是卸载程序的文件类型）
        NSString *extension = uninstallerPath.pathExtension.lowercaseString;
        NSArray *excludedExtensions = @[@"nib", @"xib", @"plist", @"strings", @"txt", @"log"];
        
        if ([excludedExtensions containsObject:extension]) {
            return NO;
        }
        
        return YES;
    }
}





#pragma mark - Private Methods

- (BOOL)isUninstallerFile:(NSString *)fileName appName:(NSString *)appName {
    NSString *lowerFileName = fileName.lowercaseString;
    NSString *lowerAppName = appName.lowercaseString;
    
    // 检查是否包含卸载关键词
    for (NSString *keyword in self.uninstallerKeywords) {
        if ([lowerFileName containsString:keyword]) {
            return YES;
        }
    }
    
    // 检查是否匹配卸载程序模式（使用小写比较）
    for (NSString *pattern in self.uninstallerPatterns) {
        if ([self string:lowerFileName matchesPattern:pattern]) {
            return YES;
        }
    }
    
    // 检查是否是应用名 + 卸载关键词的组合
    if ([lowerFileName containsString:lowerAppName]) {
        for (NSString *keyword in self.uninstallerKeywords) {
            if ([lowerFileName containsString:keyword]) {
                return YES;
            }
        }
    }
    
    return NO;
}

- (BOOL)string:(NSString *)string matchesPattern:(NSString *)pattern {
    NSString *regexPattern = [pattern stringByReplacingOccurrencesOfString:@"*" withString:@".*"];
    regexPattern = [NSString stringWithFormat:@"^%@$", regexPattern];
    
    NSError *error;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexPattern
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error];
    if (error) {
        return NO;
    }
    
    NSRange range = [regex rangeOfFirstMatchInString:string options:0 range:NSMakeRange(0, string.length)];
    return range.location != NSNotFound;
}



@end
