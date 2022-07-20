//
//  LMSpaceView.m
//  LemonSpaceAnalyse
//
//  
//

#import "LMSpaceView.h"
#import "LMItem.h"
#import <Masonry/Masonry.h>
#import <QMCoreFunction/QMEnvironmentInfo.h>
#import "NSColor+Extension.h"
#import <Quartz/Quartz.h>
#import "LMThemeManager.h"
#import "LMImageView.h"
#import "MPScrollingTextField.h"
#import <QMCoreFunction/NSImage+Extension.h>

@interface LMSpaceView ()

@property(nonatomic, strong) LMImageView *iconImageView;
@property(nonatomic, strong) NSTextField *nameLabel;
@property(nonatomic, strong) NSTextField *sizeLabel;

@property (nonatomic, assign) NSRect frameRect;
@property (nonatomic, assign) BOOL beSelected;

@property(nonatomic, retain) NSColor *startingColor;
@property(nonatomic, retain) NSColor *endingColor;

@end

@implementation LMSpaceView

- (id)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        [self setupUI:frameRect];
        _frameRect = frameRect;
        _beSelected = NO;
        
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
   
}

-(void)dealloc {
//    NSLog(@"__%s__",__FUNCTION__);

}

#pragma mark - mouse

- (void)onGoToFinder {
    [[NSWorkspace sharedWorkspace] selectFile:self.item.fullPath
                     inFileViewerRootedAtPath:[self.item.fullPath stringByDeletingLastPathComponent]];
}

- (void)rightMouseDown:(NSEvent *)event {
    
    if ([self.moveDelegate respondsToSelector:@selector(LMSpaceViewInfoClose:)]) {
        [self.moveDelegate LMSpaceViewInfoClose:YES];
    }
    
    NSMenu* rightClickMenu = [[NSMenu alloc] init];
    NSMenuItem *item1 = [[NSMenuItem alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Reveal in Finder", nil, [NSBundle bundleForClass:[self class]], @"") action:@selector(onGoToFinder) keyEquivalent:@""];

    [item1 setTarget:self];
    [rightClickMenu addItem:item1];
    NSMenu* contextMenu = rightClickMenu;
    [NSMenu popUpContextMenu:contextMenu withEvent:event forView:self];
}

- (void)mouseMoved:(NSEvent *)event {
    [super mouseMoved:event];

    NSPoint point =  [self.superview.window.contentView convertPoint:event.locationInWindow toView:self.superview];
    
    if (point.x > self.frameRect.origin.x+2 && point.x < self.frameRect.origin.x + self.frameRect.size.width -2  && point.y > self.frameRect.origin.y+2 && point.y < self.frameRect.origin.y + self.frameRect.size.height-2) {
        
        if ([self.moveDelegate respondsToSelector:@selector(LMSpaceViewInfoPoint:)]) {
            [self.moveDelegate LMSpaceViewInfoPoint:point];
        }
        if ([self.moveDelegate respondsToSelector:@selector(LMSpaceViewmouse:)]) {
            [self.moveDelegate LMSpaceViewmouse:self.item];
        }
        self.beSelected = YES;
        [self setNeedsDisplay:YES];
    }else{
        self.layer.borderColor =  [NSColor clearColor].CGColor;
        self.beSelected = NO;
        [self setNeedsDisplay:YES];
    }
}

- (void)mouseEntered:(NSEvent *)event {
 
}

- (void)mouseExited:(NSEvent *)event {
    self.layer.borderColor = [NSColor clearColor].CGColor;
    self.beSelected = NO;

    [self setNeedsDisplay:YES];
}

-(void)mouseDown:(NSEvent *)event {
    if (self.item.isDirectory == NO) {
        return;
    }
    if ([self.delegate respondsToSelector:@selector(LMSpaceViewmouseDown:)]) {
        [self.delegate LMSpaceViewmouseDown:self];
    }
}

- (void)updateTrackingAreas {
    NSArray *trackingAreas = [self trackingAreas];
    for (NSTrackingArea *area in trackingAreas)
    {
        [self removeTrackingArea:area];
    }

    NSTrackingArea *area = [[NSTrackingArea alloc] initWithRect:self.bounds options:NSTrackingMouseMoved|NSTrackingMouseEnteredAndExited|NSTrackingActiveAlways
                                                          owner:self
                                                       userInfo:nil];
    [self addTrackingArea:area];
}

#pragma mark - private

- (void)setupUI:(NSRect)frameRect {
    self.showsBorderOnlyWhileMouseInside = YES;
    self.wantsLayer = YES;
    self.layer.borderColor = [NSColor greenColor].CGColor;
    self.layer.backgroundColor = [NSColor clearColor].CGColor;
    [self setNeedsDisplay:YES];

    self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawOnSetNeedsDisplay;
    self.title = @"";
    
    self.nameLabel = [[NSTextField alloc] init];
    self.nameLabel.bordered = NO;
    self.nameLabel.alignment = NSTextAlignmentCenter;
    if ([LMThemeManager cureentTheme] == YES) {
        self.nameLabel.textColor = [NSColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:1/1.0];
    }else{
        self.nameLabel.textColor = [NSColor colorWithRed:81/255.0 green:81/255.0 blue:81/255.0 alpha:1/1.0];
    }
    
    self.nameLabel.backgroundColor = [NSColor clearColor];
    self.nameLabel.font = [NSFont systemFontOfSize:12.0];
    self.nameLabel.editable = NO;
    [self addSubview:self.nameLabel];
    [self.nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@17);
        make.leading.equalTo(self.mas_leading).offset(5);
        make.trailing.equalTo(self.mas_trailing).offset(-5);
        make.centerY.equalTo(self.mas_centerY).offset(6.5);
    }];
    
    self.iconImageView = [[LMImageView alloc] init];
    NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
    NSImage *image = [workspace iconForFile:@"/Users"];
    [self.iconImageView setImage:image];
    [self addSubview:self.iconImageView];
    [self.iconImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.width.equalTo(@30);
        make.bottom.equalTo(self.nameLabel.mas_top).offset(-2);
        make.centerX.equalTo(self.mas_centerX);
    }];
    
    self.sizeLabel = [[NSTextField alloc] init];
    self.sizeLabel.bordered = NO;
    self.sizeLabel.editable = NO;
    self.sizeLabel.alignment = NSTextAlignmentCenter;
    self.sizeLabel.backgroundColor = [NSColor clearColor];
    self.sizeLabel.font = [NSFont systemFontOfSize:12.0];
    
    if ([LMThemeManager cureentTheme] == YES) {
        self.sizeLabel.textColor = [NSColor colorWithRed:152/255.0 green:154/255.0 blue:158/255.0 alpha:1/1.0];
    }else{
        self.sizeLabel.textColor = [NSColor colorWithRed:105/255.0 green:105/255.0 blue:105/255.0 alpha:1/1.0];
    }
    
    [self addSubview:self.sizeLabel];
    [self.sizeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@17);
        make.leading.equalTo(self.mas_leading).offset(5);
        make.trailing.equalTo(self.mas_trailing).offset(-5);
        make.top.equalTo(self.nameLabel.mas_bottom).offset(2);
    }];
    
    if (frameRect.size.width < 35) {
        self.sizeLabel.hidden = YES;
        self.nameLabel.hidden = YES;
        self.iconImageView.hidden = YES;
    }

    if (frameRect.size.height < 20) {
        self.sizeLabel.hidden = YES;
        self.nameLabel.hidden = YES;
        self.iconImageView.hidden = YES;
    }else if(frameRect.size.height < 90) {
        self.iconImageView.hidden = YES;
        self.sizeLabel.hidden = YES;
        [self.nameLabel mas_updateConstraints:^(MASConstraintMaker *make) {
            make.height.equalTo(@17);
            make.leading.equalTo(self.mas_leading).offset(5);
            make.trailing.equalTo(self.mas_trailing).offset(-5);
            make.centerY.equalTo(self.mas_centerY);
        }];
    }
}

- (void)setItem:(LMItem *)item {
    
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.lineBreakMode = NSLineBreakByTruncatingTail;
    style.alignment = NSTextAlignmentCenter;
    NSDictionary * dict = @{
                            NSParagraphStyleAttributeName:style,
                            NSFontAttributeName:[NSFont systemFontOfSize:12.0]
                            };
    
    NSAttributedString *nameStr = [[NSAttributedString alloc] initWithString:item.fileName attributes:dict];
    self.nameLabel.attributedStringValue = nameStr;
    
    NSAttributedString *sizeStr = [[NSAttributedString alloc] initWithString:[self changeSizeStr:item.sizeInBytes] attributes:dict];
    self.sizeLabel.attributedStringValue = sizeStr;
    
    NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
    NSImage *image = [workspace iconForFile:item.fullPath];
    self.iconImageView.image = image;
    
    _item = item;
}

-(void)getColor {
    if ([LMThemeManager cureentTheme] == YES) {
        if(self.beSelected){
            [self setEndingColor:[NSColor colorWithRed:36/255.0 green:38/255.0 blue:48/255.0 alpha:1.0]];
            [self setStartingColor:[NSColor colorWithRed:36/255.0 green:38/255.0 blue:48/255.0  alpha:1.0]];
        }else{
            [self setEndingColor:[NSColor colorWithHex:0x292A36 alpha:1]];
            [self setStartingColor:[NSColor colorWithHex:0x383C49 alpha:1]];
        }
    
    }else{
        if(self.beSelected){
            [self setEndingColor:[NSColor whiteColor]];
            [self setStartingColor:[NSColor whiteColor]];
        }else{
            [self setEndingColor:[NSColor colorWithHex:0xF5F8F9 alpha:1]];
            [self setStartingColor:[NSColor colorWithHex:0xffffff alpha:1]];
        }
    }
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];

    [self getColor];
    if(!self.beSelected){
        self.layer.borderColor =  [NSColor clearColor].CGColor;
        self.layer.borderWidth = 3;
        self.layer.cornerRadius = 4;

        NSShadow *shadow = [[NSShadow alloc] init];
        if ([LMThemeManager cureentTheme] == YES) {
            [shadow setShadowColor:[NSColor colorWithHex:0x21222D alpha:0.15]];
        }else{
            [shadow setShadowColor:[NSColor colorWithHex:0x676766 alpha:0.25]];
        }
        [shadow setShadowOffset:NSMakeSize(0,3)];
        shadow.shadowBlurRadius = 3;
        [self setWantsLayer:YES];
        [self setShadow:shadow];
    
    }else{
        self.layer.borderColor =  [NSColor colorWithHex:0xFFA908].CGColor;
        self.layer.borderWidth = 3;
        self.layer.cornerRadius = 4;
        NSShadow *shadow = [[NSShadow alloc] init];
        [shadow setShadowColor:[NSColor colorWithHex:0xd89000 alpha:0.25]];
        [shadow setShadowOffset:NSMakeSize(0,3)];
        shadow.shadowBlurRadius = 3;
        [self setWantsLayer:YES];
        [self setShadow:shadow];
    }
    if ([LMThemeManager cureentTheme] == YES) {
        self.sizeLabel.textColor = [NSColor colorWithRed:152/255.0 green:154/255.0 blue:158/255.0 alpha:1/1.0];
        self.nameLabel.textColor = [NSColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:1/1.0];
    }else{
        self.sizeLabel.textColor = [NSColor colorWithRed:105/255.0 green:105/255.0 blue:105/255.0 alpha:1/1.0];
        self.nameLabel.textColor = [NSColor colorWithRed:81/255.0 green:81/255.0 blue:81/255.0 alpha:1/1.0];
    }
    NSGradient* aGradient = [[NSGradient alloc]
               initWithStartingColor:self.startingColor
               endingColor:self.endingColor];
         [aGradient drawInRect:[self bounds] angle:135];
}

- (NSString *)changeSizeStr:(long long)text {
    float resultSize = 0.0;
    NSString *fileSizeStr;
    if (text < 1000000){
        resultSize = text/1000.0;
        fileSizeStr = [NSString stringWithFormat:@"%0.2fKB",resultSize];
    }else if(text < 1000000000){
        resultSize = text/1000000.0;
        fileSizeStr = [NSString stringWithFormat:@"%0.2fMB",resultSize];
    }else{
        resultSize = text/1000000000.0;
        fileSizeStr = [NSString stringWithFormat:@"%0.2fGB",resultSize];
    }
    return fileSizeStr;
}

@end
