//
//  LMProcNetCellView.h
//  LemonNetSpeed
//
//  
//  Copyright © 2019年 tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface LMProcNetCellView : NSTableCellView

@property (nonatomic, strong) IBOutlet NSImageView* iconView;
@property (nonatomic, strong) IBOutlet NSTextField* nameLabel;
@property (nonatomic, strong) IBOutlet NSTextField* downloadLabel;
@property (nonatomic, strong) IBOutlet NSTextField* uploadLabel;

@end
