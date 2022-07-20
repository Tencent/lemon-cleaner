//
//  RatingViewController.h
//  Lemon
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface RatingViewController : NSViewController

@property(nonatomic, weak) NSViewController *parentViewController;
- (void)changeToTucaoViewController;
@end



// 类似于 NSAlert,有 title 和两个 button
@interface BaseTitleViewController : NSViewController
@property NSButton*  okButton;
@property NSButton*  cancelButton;
@property NSTextField*  titleLabel;
@end





@interface RatingTitleViewController : BaseTitleViewController



@end




@interface TucaoTitleViewController : BaseTitleViewController

@end

NS_ASSUME_NONNULL_END
