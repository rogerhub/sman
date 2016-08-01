//
//  AppDelegate.h
//  sman
//
//  Created by Roger Chen on 7/3/16.
//  Copyright © 2016 Roger Chen. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SMANRoster.h"
#import "SMANCreateJobSheetViewControllerDelegate.h"
#import "SMANViewLogsSheetViewControllerDelegate.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, SMANCreateJobSheetViewControllerDelegate, SMANViewLogsSheetViewControllerDelegate>

@property (weak) IBOutlet SMANRoster *roster;

@property NSWindowController *mainWindowController;
@property SMANJob *jobToEdit;
@property SMANJob *jobToViewLogs;

@end
