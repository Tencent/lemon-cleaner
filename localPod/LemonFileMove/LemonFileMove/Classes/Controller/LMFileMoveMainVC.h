//
//  LMFileMoveMainVC.h
//  LemonFileMove
//
//  
//

#import "LMFileMoveBaseViewController.h"


@interface LMFileMoveMainVC : LMFileMoveBaseViewController

// 展示扫描页
- (void)showStartView;

// 展示列表页
- (void)showSelectView;

// 展示磁盘选择页
- (void)showDiskView;
    
@end

