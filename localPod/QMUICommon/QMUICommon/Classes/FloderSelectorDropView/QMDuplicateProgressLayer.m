//
//  QMDuplicateProgressLayer.m
//  QMDuplicateFile
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import "QMDuplicateProgressLayer.h"

@implementation QMDuplicateProgressLayer

- (id)initWithFrame:(NSRect)rect
{
    if (self = [super init])
    {
        [self setFrame:rect];
        _backLayer = [CALayer layer];
        _backLayer.frame = CGRectInset(rect, 1, 1);
        CGColorRef colorRef = CGColorCreateCopyWithAlpha(CGColorGetConstantColor(kCGColorWhite), 0.5);
        _backLayer.backgroundColor = colorRef;
        _backLayer.cornerRadius = _backLayer.frame.size.width / 2;
        CGColorRelease(colorRef);
        
        _value = -1;
        _lastNumber = -1;
        
        _imageLayer = [CALayer layer];
        [_imageLayer setFrame:CGRectMake(0, (rect.size.height - 34) * 0.5, rect.size.width, 34)];
        [_imageLayer setContentsGravity:kCAAlignmentCenter];
        _imageLayer.contentsScale = [[NSScreen mainScreen] backingScaleFactor];
        [_backLayer addSublayer:_imageLayer];
        [self addSublayer:_backLayer];
        
        _loadingLayer = [CALayer layer];
        _loadingLayer.contents = [NSImage imageNamed:@"loading"];
        [_loadingLayer setFrame:rect];
        [self addSublayer:_loadingLayer];
    }
    return self;
}


- (void)setProgressImagePostion:(CGPoint)point
{
    [_imageLayer setPosition:point];
}
- (CGPoint)progressImagePostion
{
    return _imageLayer.position;
}

- (void)startLoadingAnimation
{
    [_loadingLayer removeAllAnimations];
    [_loadingLayer setHidden:NO];
    CABasicAnimation * animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    animation.fromValue = [NSNumber numberWithFloat:2*M_PI];
    animation.toValue = [NSNumber numberWithFloat: 0.0f];
    animation.duration = 2.0f;
    animation.repeatCount = HUGE_VAL;
    animation.removedOnCompletion = NO;
    [_loadingLayer addAnimation:animation forKey:@"loading"];
}
- (void)stopLoadingAnimation
{
    [_loadingLayer removeAllAnimations];
    [_loadingLayer setHidden:YES];
    [_imageLayer setHidden:NO];
}

char *myitoa(int num,char *str,int radix)
{     /* 索引表*/
    char index[]="0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    unsigned unum; /* 中间变量 */
    int i=0,j,k;
    /* 确定unum的值 */
    if(radix==10&&num<0) /* 十进制负数 */
    {
        unum=(unsigned)-num;
        str[i++]='-';
    }
    else unum=(unsigned)num; /* 其他情况 */
    /* 转换 */
    do{
        str[i++]=index[unum%(unsigned)radix];
        unum/=radix;
    }while(unum);
    str[i]='\0';
    /* 逆序 */
    if(str[0]=='-') k=1; /* 十进制负数 */
    else k=0;
    char temp;
    for(j=k;j<=(i-1)/2;j++)
    {
        temp=str[j];
        str[j] = str[i-1+k-j];
        str[i-1+k-j] = temp;
    }
    return str;
}

- (NSImage *)purgeMemoryResult:(int)result unit:(BOOL)GB
{
    if (_lastNumber == result)
        return nil;
    _lastNumber = result;
    int number = result;
    char string[25];
    myitoa(number, string, 10);
    int length = 0;
    for (int i = 0; i < sizeof(string); i++)
    {
        char value = string[i];
        if (value == '\0')
            break;
        length++;
    }
    
    NSImage * image1 = [NSImage imageNamed:@"dv_number_%"];
    
    NSSize size = NSMakeSize(image1.size.width + length * 16 + 4, image1.size.height);
    
    NSImage * _image = [[NSImage alloc] initWithSize:size];
    [_image lockFocus];
    float xoffset = 0;
    for (int i = 0; i < length; i++)
    {
        char value = string[i];
        if (value == '\0')
            break;
        NSImage * numImge = [NSImage imageNamed:[NSString stringWithFormat:@"%c", value]];
        [numImge drawAtPoint:NSMakePoint(xoffset + i * 16, 0)
                    fromRect:NSZeroRect
                   operation:NSCompositeSourceOver
                    fraction:1];
    }
    [image1 drawAtPoint:NSMakePoint(size.width - image1.size.width, 0)
               fromRect:NSZeroRect
              operation:NSCompositeSourceOver
               fraction:1];
    [_image unlockFocus];
    return _image;
}

- (void)showProgressValue:(CGFloat)value
{
    if (_value == value && _imageLayer.contents)
        return;
    _value = value;
    NSImage * image = [self purgeMemoryResult:(int)(value * 100) unit:NO];
    if (!image)
        return;
    _imageLayer.contents = image;
    if (value != 0)
        [self stopLoadingAnimation];
}

@end
