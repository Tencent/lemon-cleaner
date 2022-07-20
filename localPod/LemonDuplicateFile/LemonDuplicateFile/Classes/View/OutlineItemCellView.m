//
//  OutlineItemCellView.m
//  LemonDuplicateFile
//
//  Created by tencent on 2018/8/19.
//  Copyright © 2018年 tencent. All rights reserved.
//

#import "OutlineItemCellView.h"
#import "Masonry.h"
@interface OutlineItemCellView()

@property (nonatomic, strong) NSTextField *textLabel;

@end
@implementation OutlineItemCellView

//NSTextField *textField;

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

- (instancetype)initWithFrame:(NSRect)frameRect{
    if(self=[super initWithFrame:frameRect]){
        _textLabel = [NSTextField labelWithString:@"qwe"];
        _textLabel.font = [NSFont systemFontOfSize:16];
        [self addSubview:_textLabel];
        [_textLabel mas_makeConstraints:^(MASConstraintMaker *make){
            make.centerX.centerY.equalTo(self);
        }];
        
    }
    return self;
}

//-(void) setTextValue:(NSString*)value{
////    _textField.stringValue = value;
//    _textLabel.stringValue =value;
//
//}
- (void)setTextValue:(NSString *)value{
    _textLabel.stringValue =value;
}
@end
