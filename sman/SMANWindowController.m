//
//  SMANWindowController.m
//  sman
//
//  Created by Roger Chen on 7/10/16.
//  Copyright © 2016 Roger Chen. All rights reserved.
//

#import "AppDelegate.h"
#import "SMANWindowController.h"
#import "SMANRoster.h"
#import "SMANCreateJobSheetViewController.h"
#import "SMANPreferencesSheetViewController.h"
#import "ViewController.h"

@interface SMANWindowController ()

- (SMANRoster *)roster;

@end

@implementation SMANWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    self.window.titleVisibility = NSWindowTitleHidden;
}

- (IBAction)createJob:(id)sender {
    AppDelegate *appDelegate = [NSApp delegate];
    appDelegate.jobToEdit = nil;
    SMANCreateJobSheetViewController *sheetController = [self.storyboard instantiateControllerWithIdentifier:@"CreateJobSheet"];
    sheetController.delegate = appDelegate;
    [self.window.contentViewController presentViewControllerAsSheet:sheetController];
}

- (IBAction)openPreferences:(id)sender {
    SMANPreferencesSheetViewController *sheetController = [self.storyboard instantiateControllerWithIdentifier:@"PreferencesSheet"];
    [self.window.contentViewController presentViewControllerAsSheet:sheetController];
}

- (SMANRoster *)roster {
    AppDelegate *appDelegate = [NSApp delegate];
    return appDelegate.roster;
}

@end
