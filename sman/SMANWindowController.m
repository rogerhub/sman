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

@property BOOL syncIsLocked;

- (SMANRoster *)roster;

@end

@implementation SMANWindowController

- (id)init {
    self = [super init];

    if (self != nil) {
        _syncIsLocked = false;
    }

    return self;
}

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

- (IBAction)toggleLock:(id)sender {
    NSButton *button = (NSButton*) sender;
    NSImage *image;
    if (self.syncIsLocked) {
        image = [NSImage imageNamed:NSImageNameLockUnlockedTemplate];
        [[self roster] unlockSync];
    } else {
        image = [NSImage imageNamed:NSImageNameLockLockedTemplate];
        [[self roster] lockSync];
    }
    self.syncIsLocked = !self.syncIsLocked;
    [button setImage: image];
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
