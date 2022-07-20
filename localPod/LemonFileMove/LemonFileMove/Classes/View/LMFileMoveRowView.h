//
//  LMFileMoveRowView.h
//  LemonFileMove
//
//  
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface LMFileMoveRowView : NSTableRowView
{
    NSColor * m_selectedColor;
    CGFloat _textWidth;
}

- (void)moveExpandButtonToFront;

@end

NS_ASSUME_NONNULL_END
