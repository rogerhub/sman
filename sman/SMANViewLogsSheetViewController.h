//
//  SMANViewLogsSheetViewController.h
//  sman
//
//  Created by Roger Chen on 7/4/16.
//  Copyright © 2016 Roger Chen. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SMANViewLogsSheetViewControllerDelegate.h"

@interface SMANViewLogsSheetViewController : NSViewController

@property (unsafe_unretained) IBOutlet NSTextView *logsTextView;
@property (weak) id <SMANViewLogsSheetViewControllerDelegate> delegate;

@end
