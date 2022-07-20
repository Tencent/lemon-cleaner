//
//  LMRootCellView.m
//  LemonBigOldFile
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "LMRootCellView.h"
#import "QMLargeOldManager.h"
#import <QMUICommon/NSFontHelper.h>
#import <QMUICommon/LMAppThemeHelper.h>
#import "NSColor+Extension.h"
#import "NSString+Extension.h"
#import "NSFont+Extension.h"

@implementation LMRootCellView

-(void)setCellData:(id)item {
    QMLargeOldResultRoot *rootItem = (QMLargeOldResultRoot*)item;
    NSString * totalFileSizeStr = [NSString stringFromDiskSize:rootItem.totalSize];
    NSString * detail = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"LMRootCellView_setCellData_NSString_1", nil, [NSBundle bundleForClass:[self class]], @""), [[rootItem subItemArray] count], totalFileSizeStr];
    NSAttributedString* selectedDetail;
    UInt64 selectedSize = 0;
    UInt64 selectedCount = 0;
    for(QMLargeOldResultItem *_item in [rootItem subItemArray]) {
        NSLog(@"setCellData ... QMLargeOldResultItem select state is %@, path is %@", _item.isSelected ? @"YES" : @"NO", _item.filePath);
        if(_item.isSelected) {
            
            selectedSize += _item.fileSize;
            selectedCount++;
        }
    }
    NSLog(@"setCellData ..., rootItem is %@,selectedSize is %llu, selectedCount is %llu ",rootItem, rootItem.totalSize, selectedCount);

    if(selectedCount > 0) {
        NSString * selectFileSizeStr = [NSString stringFromDiskSize:selectedSize];
        NSString* preStr = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"LMRootCellView_setCellData_NSString_2", nil, [NSBundle bundleForClass:[self class]], @""), totalFileSizeStr];
        
        NSLog(@"setCellData ... preStr is %@ , selectFileSizeStr is %@", preStr, selectFileSizeStr);
        selectedDetail = [self _selectedString:preStr fontSize:12 selectStr:selectFileSizeStr];
    }
    
    [self.descLabel setFont:[NSFontHelper getLightSystemFont:12]];
    
    self.titleLabel.stringValue = rootItem.typeName;
    [LMAppThemeHelper setTitleColorForTextField:self.titleLabel];
    
    NSLog(@"setCellData ... show str is %@; %@", selectedDetail.string, detail);

    if(selectedCount > 0)
        self.descLabel.attributedStringValue = selectedDetail;
    else
        self.descLabel.stringValue = detail;
}

- (NSAttributedString *)_selectedString:(NSString *)preStr fontSize:(NSInteger)fontSize selectStr:(NSString *)selectStr
{
    NSFont *font = [NSFontHelper getLightSystemFont:fontSize];
    NSMutableAttributedString * attributed = [[NSMutableAttributedString alloc] init];
    [attributed appendAttributedString:[[NSAttributedString alloc] initWithString:preStr attributes:@{NSFontAttributeName: font,
                                                                                                      NSForegroundColorAttributeName:[NSColor colorWithHex:0x94979B]}]];
//    [attributed appendAttributedString:[[NSAttributedString alloc] initWithString:selectStr attributes:@{NSFontAttributeName: font,
//                                                                                                         NSForegroundColorAttributeName:[NSColor colorWithHex:0xFFBE46]}]];
    [attributed appendAttributedString:[[NSAttributedString alloc] initWithString:selectStr attributes:@{NSFontAttributeName: font,
                                                                                                         NSForegroundColorAttributeName:[NSColor colorWithHex:0xffaa09]}]];
    return attributed;
}

@end
