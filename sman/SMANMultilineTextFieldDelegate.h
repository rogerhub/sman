//
//  SMANMultilineTextFieldDelegate.h
//  sman
//
//  Created by Roger Chen on 7/6/16.
//  Copyright © 2016 Roger Chen. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SMANMultilineTextFieldDelegate : NSObject

- (BOOL)control:(NSControl*)control textView:(NSTextView*)textView doCommandBySelector:(SEL)commandSelector;

@end
