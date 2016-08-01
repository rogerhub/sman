//
//  SMANMultilineTextFieldDelegate.m
//  sman
//
//  Created by Roger Chen on 7/6/16.
//  Copyright © 2016 Roger Chen. All rights reserved.
//

#import "SMANMultilineTextFieldDelegate.h"

@implementation SMANMultilineTextFieldDelegate

// See https://developer.apple.com/library/mac/qa/qa1454/_index.html
- (BOOL)control:(NSControl*)control textView:(NSTextView*)textView doCommandBySelector:(SEL)commandSelector {
    BOOL result = NO;

    if (commandSelector == @selector(insertNewline:)) {
        // new line action:
        // always insert a line-break character and don’t cause the receiver to end editing
        [textView insertNewlineIgnoringFieldEditor:self];
        result = YES;
    }

    return result;
}

@end
