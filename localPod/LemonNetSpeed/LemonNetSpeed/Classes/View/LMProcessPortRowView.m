//
//  LMProcessPortRowView.m
//  LemonNetSpeed
//
//  
//  Copyright © 2019年 tencent. All rights reserved.
//

#import "LMProcessPortRowView.h"
#import <QMUICommon/NSFontHelper.h>
#import <QMCoreFunction/NSColor+Extension.h>

@implementation LMProcessPortRowView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}


-(void)awakeFromNib{
    [super awakeFromNib];
    [self.btnKillProcess setTitle:NSLocalizedStringFromTableInBundle(@"LMProcessPortRowView_awakeFromNib_btnKillProcess_1", nil, [NSBundle bundleForClass:[self class]], @"")];
    
    _appName.font = [NSFontHelper getLightSystemFont:12];
    _appName.textColor = [NSColor colorWithHex:0x94979B];
    _protocol.font = [NSFontHelper getLightSystemFont:12];
    _protocol.textColor = [NSColor colorWithHex:0x94979B];
    _socketType.font = [NSFontHelper getLightSystemFont:12];
    _socketType.textColor = [NSColor colorWithHex:0x94979B];
    _srcIpPort.font = [NSFontHelper getLightSystemFont:12];
    _srcIpPort.textColor = [NSColor colorWithHex:0x94979B];
    _destIpPort.font = [NSFontHelper getLightSystemFont:12];
    _destIpPort.textColor = [NSColor colorWithHex:0x94979B];
    _connectState.font = [NSFontHelper getLightSystemFont:12];
    _connectState.textColor = [NSColor colorWithHex:0x94979B];
    
    [_btnKillProcess setBezelStyle:NSTexturedSquareBezelStyle];
    [_btnKillProcess setButtonType:NSButtonTypeMomentaryPushIn];
    _btnKillProcess.bordered = NO;
    _btnKillProcess.focusRingType = NSFocusRingTypeNone;
    _btnKillProcess.appearance = [NSAppearance appearanceNamed:NSAppearanceNameAqua];
    NSFont *font = [NSFontHelper getLightSystemFont:12];
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    _btnKillProcess.alignment = NSTextAlignmentCenter;
    style.alignment = NSTextAlignmentLeft;
    NSDictionary *attributes = @{NSFontAttributeName: font, NSParagraphStyleAttributeName: style, NSForegroundColorAttributeName:[NSColor colorWithHex:0x1E85F7]};
    NSAttributedString *titleString = [[NSMutableAttributedString alloc] initWithString:NSLocalizedStringFromTableInBundle(@"LMProcessPortRowView_awakeFromNib_titleString _2", nil, [NSBundle bundleForClass:[self class]], @"") attributes:attributes];
    _btnKillProcess.attributedTitle = titleString;
}

- (IBAction)clickKillProcess:(id)sender
{
    NSLog(@"clickKillProcess %@", sender);
    if (_actionHandler) _actionHandler(self.portModel);
}

@end
