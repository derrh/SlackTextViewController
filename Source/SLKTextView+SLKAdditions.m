//
//  SlackTextViewController
//  https://github.com/slackhq/SlackTextViewController
//
//  Copyright 2014-2016 Slack Technologies, Inc.
//  Licence: MIT-Licence
//

#import "SLKTextView+SLKAdditions.h"

@implementation SLKTextView (SLKAdditions)

- (void)slk_clearText:(BOOL)clearUndo
{
    // Important to call self implementation, as SLKTextView overrides setText: to add additional features.
    [self setText:nil];
    
    if (self.undoManagerEnabled && clearUndo) {
        [self.undoManager removeAllActions];
    }
}

- (void)slk_scrollToCaretPositonAnimated:(BOOL)animated
{
    if (animated) {
        [self scrollRangeToVisible:self.selectedRange];
    }
    else {
        [UIView performWithoutAnimation:^{
            [self scrollRangeToVisible:self.selectedRange];
        }];
    }
}

- (void)slk_scrollToBottomAnimated:(BOOL)animated
{
    CGRect rect = [self caretRectForPosition:self.selectedTextRange.end];
    rect.size.height += self.textContainerInset.bottom;
    
    if (animated) {
        [self scrollRectToVisible:rect animated:animated];
    }
    else {
        [UIView performWithoutAnimation:^{
            [self scrollRectToVisible:rect animated:NO];
        }];
    }
}

- (void)slk_insertNewLineBreak
{
    [self slk_insertTextAtCaretRange:@"\n"];
    
    // if the text view cannot expand anymore, scrolling to bottom are not animated to fix a UITextView issue scrolling twice.
    BOOL animated = !self.isExpanding;
    
    //Detected break. Should scroll to bottom if needed.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.0125 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self slk_scrollToBottomAnimated:animated];
    });
}

- (void)slk_insertTextAtCaretRange:(NSString *)text
{
    NSRange range = [self slk_insertText:text inRange:self.selectedRange];
    self.selectedRange = NSMakeRange(range.location, 0);
}

- (NSRange)slk_insertText:(NSString *)text inRange:(NSRange)range
{
    // Skip if the text is empty
    if (text.length == 0) {
        return NSMakeRange(0, 0);
    }
    
    // Registers for undo management
    [self slk_prepareForUndo:@"Text appending"];
    
    // Append the new string at the caret position
    if (range.length == 0)
    {
        NSString *leftString = [self.text substringToIndex:range.location];
        NSString *rightString = [self.text substringFromIndex: range.location];
        
        self.text = [NSString stringWithFormat:@"%@%@%@", leftString, text, rightString];
        
        range.location += text.length;

        return range;
    }
    // Some text is selected, so we replace it with the new text
    else if (range.location != NSNotFound && range.length > 0)
    {
        self.text = [self.text stringByReplacingCharactersInRange:range withString:text];

        range.location += text.length;
        
        return range;
    }
    
    // No text has been inserted, but still return the caret range
    return self.selectedRange;
}

- (void)slk_prepareForUndo:(NSString *)description
{
    if (!self.undoManagerEnabled) {
        return;
    }
    
    SLKTextView *prepareInvocation = [self.undoManager prepareWithInvocationTarget:self];
    [prepareInvocation setText:self.text];
    [self.undoManager setActionName:description];
}

@end
