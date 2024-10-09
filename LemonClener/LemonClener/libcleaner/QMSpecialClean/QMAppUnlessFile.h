//
//  QMAppUnlessFile.h
//  QMCleanDemo
//

//  Copyright (c) 2013年 tencent. All rights reserved.
//

#import "QMBaseScan.h"
#import "QMActionItem.h"
#import "QMXMLItemDefine.h"

@class QMFilterParse;
@interface QMAppUnlessFile : QMBaseScan
{
    QMFilterParse * m_languageFilter;
    QMFilterParse * m_developerFilter;
    NSMutableArray * m_unlessNibArray;
    
    NSString * _normIdentifier;
}

- (void)scanAppUnlessLanguage:(QMActionItem *)actionItem;

- (void)scanAppUnlessBinary:(QMActionItem *)actionItem;

- (void)scanDeveloperJunck:(QMActionItem *)actionItem;

//找出application路径下所有app中可瘦身的二进制
- (void)scanAppGeneralBinary:(QMActionItem *)actionItem;

//找出download/桌面路径下所有安装包
- (void)scanAppInstallPackage:(QMActionItem *)actionItem;


@end
