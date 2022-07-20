//
//  QMDuplicateItem.h
//  QMDuplicateFile
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <QMCoreFunction/QMFileClassification.h>

@interface QMDuplicateFile : NSObject

@property(nonatomic, retain) NSString *filePath;
@property(nonatomic, assign) NSTimeInterval modifyTime;
@property(nonatomic, assign) NSTimeInterval createTime;
@property(nonatomic, assign) uint64 fileSize;
@property(nonatomic, assign) BOOL selected;

@end

@interface QMDuplicateBatch : NSObject

@property(nonatomic, retain) NSString *fileName;
@property(nonatomic, retain) NSImage *iconImage;
@property(nonatomic, assign) UInt64 fileSize;  // 子 item 的大小.
@property(nonatomic, assign) QMFileTypeEnum fileType;
@property(nonatomic, assign) NSControlStateValue selectState; //用于全选,反选逻辑.

// 因为使用的是 LMCheckboxButton, 状态只会从 0(off)转换为1(on),或者1 转换为 0, 而mix(-1)状态只能手动设置,无法通过点击触发.另外button 处于 mix 状态是,再次点击为 off 状态.
// QMDuplicateItem的selectState并不会主动计算,而是由用户点击子 item 或者用户点击 item 时触发状态转变.


- (void)addSubItem:(QMDuplicateFile *)item;

- (NSArray *)subItems;


@end
