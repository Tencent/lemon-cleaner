//
//  LMPhotoViewItem.m
//  LemonPhotoCleaner
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "LMPhotoViewItem.h"
#import "LMPhotoItem.h"

@interface LMPhotoViewItem ()

@end

@implementation LMPhotoViewItem

- (instancetype)init
{
    self = [super init];
    if (self) {
    }
    [self addGesture];
    return self;
}

-(instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithNibName:NSStringFromClass(self.class) bundle:[NSBundle bundleForClass:self.class]];
    if (self) {
        //myBundle = [NSBundle bundleForClass:[self class]];
    }
    [self addGesture];
    return self;
}
- (void)addGesture {
//    NSClickGestureRecognizer *ges = [[NSClickGestureRecognizer alloc] initWithTarget:self action:@selector(back:)];
//    ges.numberOfClicksRequired = 1;
//    [self.view addGestureRecognizer:ges];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    self.view.wantsLayer = true;
    self.view.layer.backgroundColor = [NSColor.lightGrayColor CGColor];
}


- (LMPhotoItem *) photoItem {
    return (LMPhotoItem *)self.representedObject;
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    NSBundle* bundle = [NSBundle bundleForClass:self.class];
    self.imgThumbnail.image = [bundle imageForResource:@"PreviewPlaceHolder"];
    [self.photoItem requestPreviewImage];
}

- (IBAction)valueChange:(NSButton *)sender{
    
    NSButton *checkBtn = sender;
    BOOL isOn = checkBtn.state;
    NSLog(@"valueChange  %d, item is %@",isOn, self);
    self.photoItem.isSelected = isOn;
    
    NSDictionary *userInfo =@{
                              LM_NOTIFICATION_ITEM_UPDATESELECT_PATH:self.photoItem.path,
                              };
//    double startTime = [[NSDate date] timeIntervalSince1970];
//    NSLog(@"updateCollectionViewByPath click  time:%f",startTime);
    [[NSNotificationCenter defaultCenter] postNotificationName:LM_NOTIFICATION_ITEM_UPDATESELECT object:self userInfo:userInfo];
}

@end
