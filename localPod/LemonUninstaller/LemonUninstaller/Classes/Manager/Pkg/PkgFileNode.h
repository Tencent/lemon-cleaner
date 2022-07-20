//
//  PkgFileNode.h
//  LemonUninstaller
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PkgFileNode : NSObject

@property NSString *path;
@property BOOL isExist;
@property BOOL isDir;        // 是否是文件夹
// 是否可以安全删除  安全删除有2 种可能.
//  1. 符合特定规则,比如  "/Library/Application Support/"是系统关键目录, 但里面的子目录应该属于某一App, 这些字目录可以安全删除.
//  2. pkgUtil 已经列出了所有的子目录/文件夹, 也就是当删除所有列出的子节点时,文件夹自身变为空.(当前目录下未有没列出的子节点)
@property NSMutableArray<PkgFileNode *> *subNodes;  //当自身为目录时,应该有子节点.

@property NSNumber *subItemTotalListFlag; //使用 NSNumber而不是BOOL的原因是,NSNumber可以表示的多一种状态,nil 代表还未处理,0代表 False,1 代表 True
@property NSArray  *debugForUnListFiles;
@end

NS_ASSUME_NONNULL_END




//  文件的树形结构
//
//[1层]                                               /(根节点)
//[2层]       /usr/local                          /Library/LaunchAgents   /Library/Filesystems  ...
//[3层]    /usr/local/sbin
//[4层]  [...]/fsck_ufsd_NTFS [...]/mount_ufsd_NTFS  ...



// 文件树的排序.
// 分为普通文件和文件夹, 文件肯定挂在文件夹下面.
// 1. 建立根节点"/"
//     文件夹存在包含和互斥的关系. 对于包含关系的文件夹,字符串长度肯定被包含的长. 对于互斥的文件夹,并不在同一枝杈上.
//     文件夹路径越短,说明其越靠近根节点/
//     1.1 对所有的文件夹进行长度排序.
//     1.2 按照排序结果挂载文件夹,如果新增文件夹与树上已存在文件夹存在包含关系,则新增文件夹挂载到被包含的文件夹下.
// 2. 先挂载文件夹
// 3. 挂载文件. (如果文件所处的文件夹不存在,则直接挂载到根节点)

