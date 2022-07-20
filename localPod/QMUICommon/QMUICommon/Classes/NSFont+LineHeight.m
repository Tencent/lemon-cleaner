#import "NSFont+LineHeight.h"

@implementation NSFont (LineHeight)

- (CGFloat)lineHeight {
    return ceilf(self.ascender + ABS(self.descender) + self.leading);
}

@end
