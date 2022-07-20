//
//  PkgUninstallProvider.m
//  LemonUninstaller
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//

#import "PkgUninstallProvider.h"
#import "PkgUninstallManager.h"
#import <QMCoreFunction/QMShellExcuteHelper.h>
#import <QMCoreFunction/NSString+PathExtension.h>
#import <QMCoreFunction/McCoreFunction.h>

#define kProtectPathArray @[ @"/", @"/Library",@"/Library/Filesystems",@"/Library/Extensions",@"/System", @"/Applications", @"/bin", @"/cores", @"/sbin", @"/usr",@"/Library/PreferencePanes",@"/Library/LaunchAgents",@"/Library/LaunchDaemons",[@"~/Library/LaunchAgents" stringByExpandingTildeInPathIgnoreSandbox],[@"~/Library/" stringByExpandingTildeInPathIgnoreSandbox],[@"~/.Trash" stringByExpandingTildeInPathIgnoreSandbox],[@"~/Library/PreferencePanes" stringByExpandingTildeInPathIgnoreSandbox] ]

typedef enum {
    BundlePkgCategory = 0,
    SupportPKGCategory,
    PreferencePanePKGCategory,
    FileSystemPKGCategory,
    PlistPkgCategory,
    KextPkgCategory,
    OtherPkgCategory
} PkgCategory;


@implementation PkgUninstallProvider {
    NSFileManager *_fileManager;
    NSString *_pkgBundleId;
    NSString *_keyWord; // for safeDelete
    BOOL useKeyWordForSafeDelete;  //使用 keyword 过滤要删除的文件夹,保证其安全性
    PkgFileNode *_rootNode;
    NSString *_pkgPrefixPath;
    NSMutableArray<NSString *> *_canDeletePaths;
    NSDictionary *_categoryDict;
}

- (id)initWithPkgBundleId:(NSString *)pkgBundleId withKeyWording:(NSString *)keyWord {
    self = [super init];
    if (self) {
        _fileManager = NSFileManager.defaultManager;
        if (!pkgBundleId) {
            return nil;
        }
        _pkgBundleId = pkgBundleId;
        _keyWord = keyWord;
        if (_keyWord) {
            useKeyWordForSafeDelete = YES;
        }

        [self createRootNode];
    }
    return self;
}

- (void)createRootNode {
    _rootNode = [self createDirNode:@"/" isExist:YES];
}


- (BOOL)pkgExistAtThisPC {

    NSArray<NSString *> *pkgList = [PkgUninstallManager pkgList];
    for (NSString *item in pkgList) {
        if ([item isEqualToString:self->_pkgBundleId]) {
            return YES;
        }
    }

    return FALSE;
}




// pkgutil --only-files --files  com.paragon-software.pkg.ntfs
// pkgutil --files 所有文件夹及文件
// pkgutil --only-dirs  --files    List only directories (not files) in --files listing

- (NSArray<NSString *> *)pkgDirs {

    NSString *pkgListCmd = [NSString stringWithFormat:@"pkgutil --only-dirs  --files %@", _pkgBundleId];
    NSString *resultStr = [QMShellExcuteHelper excuteCmd:pkgListCmd];
    NSArray<NSString *> *resultList = [resultStr componentsSeparatedByString:@"\n"];

    NSString *prefixPkgPath = [self pkgPrefixPath];
    if (!prefixPkgPath) {
        NSLog(@"%s un valid pkg prefix path ", __FUNCTION__);
        return nil;
    }

    NSMutableArray *dirs = [NSMutableArray array];
    for (NSString *dirItem in resultList) {
        if (dirItem.length < 1) {continue;}  // split string 会产生空字符串
        NSString *fullPath = [prefixPkgPath stringByAppendingPathComponent:dirItem];
        [dirs addObject:fullPath];
    }
    return [dirs copy];
}


// 不使用 "pkgutil --only-files  --files" 因为这个只返回 普通类型文件,对于 symbolic link 等并不返回.
- (NSArray<NSString *> *)pkgFiles {

    NSString *pkgListCmd = [NSString stringWithFormat:@"pkgutil  --files %@", _pkgBundleId];
    NSString *resultStr = [QMShellExcuteHelper excuteCmd:pkgListCmd];
    NSArray<NSString *> *resultList = [resultStr componentsSeparatedByString:@"\n"];

    NSString *prefixPkgPath = [self pkgPrefixPath];
    if (!prefixPkgPath) {
        NSLog(@"%s un valid pkg prefix path ", __FUNCTION__);
        return nil;
    }

    NSMutableArray *files = [NSMutableArray array];
    for (NSString *dirItem in resultList) {
        if (dirItem.length < 1) {continue;}
        NSString *fullPath = [prefixPkgPath stringByAppendingPathComponent:dirItem];
        [files addObject:fullPath];
    }
    return [files copy];
}

- (PkgFileNode *)buildPkgFileNodes {

    if (![self pkgExistAtThisPC]) {
        return nil;
    }
    NSArray *dirs = [self pkgDirs];
    if (!dirs || dirs.count < 1) {return nil;}
    NSArray *sortDirs = [dirs sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];

    NSMutableArray *allFiles = [[self pkgFiles] mutableCopy];
    if (!allFiles || allFiles.count < 1) {return nil;}
    [allFiles removeObjectsInArray:dirs];
    NSArray *files = [allFiles copy];

    for (NSString *dirItem in sortDirs) {
        BOOL isDir;
        BOOL isExist = [_fileManager fileExistsAtPath:dirItem isDirectory:&isDir];
        if (isDir) {
            // 1.创建 dirNode
            PkgFileNode *dirNode = [self createDirNode:dirItem isExist:isExist];
            // 2.insert node
            [self insertDirNodeToFileTree:dirNode];

        }
    }


    for (NSString *fileItem in files) {
        if([fileItem  isEqualToString:@"/Applications/BeeCut.app/Contents/Frameworks/WXCommonUtils.framework/Versions/A/Resources/UnlimitedWebResource/img/logo@2.png"]){
            NSLog(@"....3123");
        }
        
        BOOL isDir;
        BOOL isExist = [_fileManager fileExistsAtPath:fileItem isDirectory:&isDir];
//        if (!isDir) {
        // 如果symblink对应的是一个文件夹,那么 isDir 为 true.
            // 只处理普通文件/symblink 文件
            BOOL isRegularFileOrSymblink = FALSE;
            NSURL *fileUrl = [NSURL fileURLWithPath:fileItem];
            NSNumber *regularFlag = nil;
            [fileUrl getResourceValue:&regularFlag forKey:NSURLIsRegularFileKey error:NULL];
            if (regularFlag && [regularFlag boolValue]) {
                isRegularFileOrSymblink = TRUE;
            } else {
                NSNumber *symblinkFlag = nil;
                [fileUrl getResourceValue:&symblinkFlag forKey:NSURLIsSymbolicLinkKey error:NULL];
                if (symblinkFlag && [symblinkFlag boolValue]) {
                    isRegularFileOrSymblink = TRUE;
                }
            }

            if (!isRegularFileOrSymblink) {
                NSLog(@"%s %@ not regular file or symblink", __FUNCTION__, fileItem);
                continue;
            }

            // 创建 fileNode 并插入文件树
            PkgFileNode *fileNode = [self createFileNode:fileItem isExist:isExist];
            [self insertDirNodeToFileTree:fileNode];
//        }
    }

    return _rootNode;
}

- (PkgFileNode *)createDirNode:(NSString *)dirItem isExist:(BOOL)isExist {
    PkgFileNode *dirNode = [[PkgFileNode alloc] init];
    dirNode.path = dirItem;
    dirNode.isDir = YES;
    dirNode.isExist = isExist;
    return dirNode;
}

- (PkgFileNode *)createFileNode:(NSString *)fileItem isExist:(BOOL)isExist {
    PkgFileNode *fileNode = [[PkgFileNode alloc] init];
    fileNode.path = fileItem;
    fileNode.isDir = NO;
    fileNode.isExist = isExist;
    return fileNode;
}

- (void)insertDirNodeToFileTree:(PkgFileNode *)node {
    PkgFileNode *superNode = [self findSuperNodeBy:node at:_rootNode];
    if (!superNode) {
        NSLog(@"%s %@ can't find available superNode", __FUNCTION__, node.path);
        return;
    }
    if (!superNode.subNodes) {
        superNode.subNodes = [NSMutableArray array];
    }
    [superNode.subNodes addObject:node];
}

- (PkgFileNode *)findSuperNodeBy:(PkgFileNode *)node at:(PkgFileNode *)pkgFileNode {

    PkgFileNode *superNode = nil;
    for (PkgFileNode *subNode in pkgFileNode.subNodes) {
        if (!subNode.isDir) {continue;}
        //不能简单的用containsString判断,因为 "img/logo.png" contains "img/logo" 了.但 2 者是同级目录.并不是父子关系.
        NSString *insertNodeParentDir = [node.path stringByDeletingLastPathComponent];
        if ([node.path containsString:subNode.path] && [insertNodeParentDir containsString:subNode.path]) {
            superNode = subNode;
            break;
        }
    }
    if (!superNode) {
        return pkgFileNode;
    } else {
        return [self findSuperNodeBy:node at:superNode];
    }

}

- (NSString *)pkgPrefixPath {

    if (_pkgPrefixPath) {
        return _pkgPrefixPath;
    }
    NSArray *arguments = @[_pkgBundleId];
    // sh脚本 放在 Resources 目录下,打开 framework 可用看到 其实际目录为 Resources/Resources/get_pkg_path.sh
    NSString *scriptPath = [[NSBundle bundleForClass:self.class] pathForResource:@"Resources/get_pkg_path.sh" ofType:nil];
    NSString *resultPath = [QMShellExcuteHelper executeScript:scriptPath arguments:arguments];

    if (!resultPath || resultPath.length < 1) {  // pkgPath maybe: "/"
        NSLog(@"can't get get_pkg_path.sh  path");
        return nil;
    }

    NSString *pkgPath = nil;
    NSArray<NSString *> *paths = [resultPath componentsSeparatedByString:@"\n"];
    if (paths && paths.count > 0) {
        pkgPath = paths[0];
    }

    BOOL isDir;
    BOOL isExist = [_fileManager fileExistsAtPath:pkgPath isDirectory:&isDir];
    if (isExist && isDir) {
        //valid Path
        _pkgPrefixPath = pkgPath;
    }

    return _pkgPrefixPath;
}

- (NSArray<NSString *> *)getCanDeleteItem {
    //递归遍历文件数, 比对每个文件夹,是否还有其他文件未列出. (有未列出的文件,删除文件夹有风险)
    [self calculateFileNodeIfListAllFiles:_rootNode];
    NSArray<NSString *> *canDeleteArray = [self getHasListAllSubItemNodeAndExist:_rootNode];
    self->_canDeletePaths = [canDeleteArray mutableCopy];

    NSLog(@"%s list all can delete items  start .....", __FUNCTION__);
    for (NSString *item in canDeleteArray) {
        NSLog(@"%@", item);
    }
    NSLog(@"%s list all can delete items  end .....", __FUNCTION__);

    return canDeleteArray;
}

- (void)getArrayByCategory {
    NSMutableDictionary *categoryDict = [NSMutableDictionary dictionary];
    NSArray *app = [self getBundlePath];
    NSArray *support = [self getApplicationSupprotPath];
    NSArray *preferencePanes = [self getPreferencePanes];
    NSArray *kexts = [self getKext];
    NSArray *fileSystem = [self getFileSystem];
    NSArray *daemonPlists = [self getDaemonPlist];
    NSArray *others = [self getOthers];

    categoryDict[@(BundlePkgCategory)] = app;
    categoryDict[@(SupportPKGCategory)] = support;
    categoryDict[@(PreferencePanePKGCategory)] = preferencePanes;
    categoryDict[@(KextPkgCategory)] = kexts;
    categoryDict[@(FileSystemPKGCategory)] = fileSystem;
    categoryDict[@(PlistPkgCategory)] = daemonPlists;
    categoryDict[@(OtherPkgCategory)] = others;

    self->_categoryDict = categoryDict;
}

- (NSArray<NSString *> *)getBundlePath {
    NSString *bundleRegex = @"/Applications/*.app";
    if (useKeyWordForSafeDelete && _keyWord) {
        bundleRegex = [NSString stringWithFormat:@"/Applications/*%@*.app", _keyWord];
    }
    return [self getAndRemovePathBy:bundleRegex];
}

- (NSArray<NSString *> *)getApplicationSupprotPath {
    NSString *systemApplicationSupportRegex = @"/Library/Application Support/*";
    if (useKeyWordForSafeDelete && _keyWord) {
        systemApplicationSupportRegex = [NSString stringWithFormat:@"/Library/Application Support/*%@*", _keyWord];
    }
    NSArray *systemSupports = [self getAndRemovePathBy:systemApplicationSupportRegex];


    NSString *userApplicationSupportRegex = [@"~/Library/Application Support/*" stringByExpandingTildeInPathIgnoreSandbox];
    if (useKeyWordForSafeDelete && _keyWord) {
        NSString *tempStr = [NSString stringWithFormat:@"~/Library/Application Support/*%@*", _keyWord];
        userApplicationSupportRegex = [tempStr stringByExpandingTildeInPathIgnoreSandbox];
    }

    NSArray *userSupports = [self getAndRemovePathBy:userApplicationSupportRegex];

    NSMutableArray *retArr = [NSMutableArray array];
    [retArr addObjectsFromArray:systemSupports];
    [retArr addObjectsFromArray:userSupports];
    return retArr;
}


- (NSArray<NSString *> *)getPreferencePanes {
    NSString *systemPreferencePanesRegex = @"/Library/PreferencePanes/*";
    if (useKeyWordForSafeDelete && _keyWord) {
        systemPreferencePanesRegex = [NSString stringWithFormat:@"/Library/PreferencePanes/*%@*", _keyWord];
    }
    NSArray *systemPreferencePanes = [self getAndRemovePathBy:systemPreferencePanesRegex];


    NSString *userPreferencePanesRegex = [@"~/Library/PreferencePanes/*" stringByExpandingTildeInPathIgnoreSandbox];
    if (useKeyWordForSafeDelete && _keyWord) {
        NSString *tempStr = [NSString stringWithFormat:@"~/Library/PreferencePanes/*%@*", _keyWord];
        userPreferencePanesRegex = [tempStr stringByExpandingTildeInPathIgnoreSandbox];
    }
    NSArray *userPreferencePanes = [self getAndRemovePathBy:userPreferencePanesRegex];

    NSMutableArray *retArr = [NSMutableArray array];
    [retArr addObjectsFromArray:systemPreferencePanes];
    [retArr addObjectsFromArray:userPreferencePanes];
    return retArr;

}

- (NSArray<NSString *> *)getKext {
    NSString *systemKextRegex = @"/Library/Extensions/*.kext";
    if (useKeyWordForSafeDelete && _keyWord) {
        systemKextRegex = [NSString stringWithFormat:@"/Library/Extensions/*%@*", _keyWord];
    }
    NSArray *kextItems = [self getAndRemovePathBy:systemKextRegex];
    return kextItems;
}

- (NSArray<NSString *> *)getFileSystem {
    NSString *systemFilesystemRegex = @"/Library/Filesystems/*";
    if (useKeyWordForSafeDelete && _keyWord) {
        systemFilesystemRegex = [NSString stringWithFormat:@"/Library/Filesystems/*%@*", _keyWord];
    }
    NSArray *filesystems = [self getAndRemovePathBy:systemFilesystemRegex];
    return filesystems;
}

- (NSArray<NSString *> *)getDaemonPlist {

    NSArray *plistPaths = @[@"/Library/LaunchAgents",
            @"/Library/LaunchDaemons",
            @"/System/Library/LaunchAgents",
            @"/System/Library/LaunchDaemons",
            [@"~/Library/LaunchAgents" stringByExpandingTildeInPathIgnoreSandbox]
    ];

    NSMutableArray<NSString *> *retArr = [NSMutableArray array];
    for (NSString *plistPath in plistPaths) {
        NSString *plistPathRegex = [plistPath stringByAppendingString:@"*.plist"];
        [retArr addObjectsFromArray:[self getAndRemovePathBy:plistPathRegex]];
    }

    return retArr;

}

// 注意:必须最后调用,上面的拿到结果后才能调用.剩余的才属于 other
- (NSArray<NSString *> *)getOthers {

    return _canDeletePaths;
}

- (NSArray<NSString *> *)getAndRemovePathBy:(NSString *)likeStr {
    NSPredicate *likePredicate = [NSPredicate predicateWithFormat:@"SELF LIKE[c] %@", likeStr];

    NSMutableArray *retArr = [NSMutableArray array];
    for (NSString *itemPath in _canDeletePaths) {
        BOOL flag = [likePredicate evaluateWithObject:itemPath];

        if (flag) {
            [retArr addObject:itemPath];
        }
    }

    [_canDeletePaths removeObjectsInArray:retArr];

    return retArr;
}

// 能删除的文件/文件夹 :
// 1. 文件/文件夹存在,
// 2. 文件夹内容不遗漏:pkgutil 列出的子目录和 fileManager 列出的子目录一样,并且子目录也满足条件
// 3. 不是系统关键目录, 比如 /Library/PreferencePanes是系统目录,如果目录下只有 ParagonNTFS.prefPane, 那么按照前两条规则计算出的是"/Library/PreferencePanes"而不是"/Library/PreferencePanes/ParagonNTFS.prefPane"
- (nullable NSArray<NSString *> *)getHasListAllSubItemNodeAndExist:(PkgFileNode *)superNode {
    if (!superNode.isExist) {
        return nil;
    }
    
    NSArray *protectPaths = kProtectPathArray;
    BOOL isBelongToProtectPath = [protectPaths containsObject:superNode.path ];
//    [kProtectArray containsObject:superNode.path];
    
    if (!isBelongToProtectPath && superNode.subItemTotalListFlag && [superNode.subItemTotalListFlag boolValue]) {
        return @[superNode.path];
    }
    

    NSMutableArray *retArray = [NSMutableArray array];
    for (PkgFileNode *subNode in superNode.subNodes) {
        NSArray<NSString *> *subArray = [self getHasListAllSubItemNodeAndExist:subNode];
        [retArray addObjectsFromArray:subArray];
    }
    return retArray;
}

// 递归, 计算node 是否已经列出了所有的文件.
- (void)calculateFileNodeIfListAllFiles:(PkgFileNode *)superNode {

    NSUInteger hasListTotalCount = 0;
    NSUInteger existSubItemCount = 0;

    for (PkgFileNode *itemNode in superNode.subNodes) {
        if (!itemNode.isExist) {
            continue;
        }
        existSubItemCount++;
        if (!itemNode.isDir) {
            itemNode.subItemTotalListFlag = @(TRUE);
            hasListTotalCount++;
            continue;
        }

        if (!itemNode.subItemTotalListFlag) { //还未计算
            [self calculateFileNodeIfListAllFiles:itemNode];//开始计算
            if (!itemNode.subItemTotalListFlag) {
                NSLog(@"%s,subItem:%@ should be calculate", __FUNCTION__, itemNode.path);
                continue;
            } else if ([itemNode.subItemTotalListFlag boolValue]) {
                hasListTotalCount++;
            } else {
                // 子 item 未有全部选中
            }
        }
    }
    
    if (hasListTotalCount < existSubItemCount) {
        superNode.subItemTotalListFlag = @(FALSE);
    }

    // 比较 fileManager List 的结果和 pkgUtil List 的结果.
    NSError *error = nil;
    NSArray<NSString *> *subFiles = [_fileManager contentsOfDirectoryAtPath:superNode.path error:&error];
    if (error != NULL) {
        superNode.subItemTotalListFlag = @(FALSE);
        NSLog(@"%s node:%@ fileManager list contents occur an error %@ ", __FUNCTION__, superNode.path, error);
        return;
    }
    if (subFiles.count == hasListTotalCount) {
        superNode.subItemTotalListFlag = @(TRUE);
    } else {
        NSMutableArray<NSString *> *mutableSubPaths = [NSMutableArray array];
        for(NSString *lastPathComponent in subFiles){
            [mutableSubPaths addObject:[superNode.path stringByAppendingPathComponent:lastPathComponent]];
        }
        NSArray<NSString *> *listFiles = [superNode.subNodes valueForKeyPath:@"path"];
        [mutableSubPaths removeObjectsInArray:listFiles];
        superNode.debugForUnListFiles = [mutableSubPaths copy];
        superNode.subItemTotalListFlag = @(FALSE);
    }
}


- (void)searchAllItems {

    // 构建文件树
    [self buildPkgFileNodes];
    // 确实删除的文件
    [self getCanDeleteItem];
    // 按照类别寻找文件
    [self getArrayByCategory];
}

- (NSArray *)scanKext {
    return _categoryDict[@(KextPkgCategory)];
}

- (NSArray *)searchFileSystem {
    return _categoryDict[@(FileSystemPKGCategory)];
}

- (NSArray *)searchPreferencePane {
    return _categoryDict[@(PreferencePanePKGCategory)];
}


- (NSArray *)searchBundles {
    return _categoryDict[@(BundlePkgCategory)];
}


- (NSArray *)scanSupports {
    return _categoryDict[@(SupportPKGCategory)];
}


- (NSArray *)scanLaunchDaemons {
    return _categoryDict[@(PlistPkgCategory)];
}


- (NSArray *)scanOthers {
    return _categoryDict[@(OtherPkgCategory)];
}


// sudo pkgutil --forget bundleId  需要 sudo 权限.
- (BOOL) removePkgInfo{
    NSLog(@"%s with pkg bundle id:%@", __FUNCTION__ ,_pkgBundleId);
    return [[McCoreFunction shareCoreFuction] removePkgInfoWithBundleId: _pkgBundleId];
}

@end
