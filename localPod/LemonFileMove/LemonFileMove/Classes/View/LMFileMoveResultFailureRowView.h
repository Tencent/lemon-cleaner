//
//  LMFileMoveResultFailureRowView.h
//  LemonFileMove
//
//  
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface LMFileMoveResultFailureRowView : NSTableRowView {
    NSColor * m_selectedColor;
    CGFloat _textWidth;
}

- (void)moveExpandButtonToFront;

@end

NS_ASSUME_NONNULL_END
