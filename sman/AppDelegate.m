//
//  AppDelegate.m
//  sman
//
//  Created by Roger Chen on 7/3/16.
//  Copyright © 2016 Roger Chen. All rights reserved.
//

#import "AppDelegate.h"
#import "SMANJob.h"
#import "SMANCreateJobSheetViewController.h"
#import "SMANPreferencesSheetViewController.h"
#import "SMANWindowController.h"

@implementation NSArray (StringArrayCompare)

- (BOOL)isEqualToStringArray:(NSArray *)other {
    if ([self count] != [other count]) {
        return NO;
    }
    for (int i = 0; i < [self count]; i++) {
        if (![self[i] isEqualToString:other[i]]) {
            return NO;
        }
    }
    return YES;
}

@end

@interface AppDelegate ()

- (SMANWindowController *)windowController;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSDictionary *appDefaults = @{
        @"PreferenceRestorePreviousJobsOnLaunch": @1,
        @"DefaultShouldDelete": @0,
        @"DefaultShouldOptimizeSingleFile": @1,
        @"DefaultShouldCompareChecksum": @1,
        @"DefaultExcludedFiles": @[@".DS_Store"],
        @"Jobs": @[],
    };
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults registerDefaults:appDefaults];

    if ([defaults boolForKey:@"PreferenceRestorePreviousJobsOnLaunch"]) {
        [self.roster loadRosterFromPreferences];
    } else {
        [self.roster saveRosterToPreferences];
    }
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application

}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag {
    if (!flag) {
        [self windowController];
    }
    return YES;
}

- (SMANWindowController *)windowController {
    NSWindow *mainWindow = [[NSApplication sharedApplication] mainWindow];
    SMANWindowController *mainWindowController;
    if (mainWindow == nil) {
        NSStoryboard *storyboard = [NSStoryboard storyboardWithName:@"Main" bundle:nil];
        mainWindowController = [storyboard instantiateControllerWithIdentifier:@"MainWindow"];
        mainWindow = mainWindowController.window;
    } else {
        mainWindowController = mainWindow.windowController;
    }
    [mainWindowController showWindow:self];
    [mainWindow makeKeyAndOrderFront:self];
    [NSApp activateIgnoringOtherApps:YES];
    self.mainWindowController = mainWindowController;
    return mainWindowController;
}

- (IBAction)openPreferences:(id)sender {
    SMANWindowController *mainWindowController = [self windowController];
    SMANPreferencesSheetViewController *sheetController = [mainWindowController.storyboard instantiateControllerWithIdentifier:@"PreferencesSheet"];
    [mainWindowController.contentViewController presentViewControllerAsSheet:sheetController];
}

- (IBAction)createJob:(id)sender {
    self.jobToEdit = nil;
    SMANWindowController *mainWindowController = [self windowController];
    SMANCreateJobSheetViewController *sheetController = [mainWindowController.storyboard instantiateControllerWithIdentifier:@"CreateJobSheet"];
    sheetController.delegate = self;
    [mainWindowController.contentViewController presentViewControllerAsSheet:sheetController];
}

- (void)sheetDidCreateJobWithSource:(NSString *)source hostname:(NSString *)hostname destination:(NSString *)destination shouldDelete:(BOOL)shouldDelete shouldOptimizeSingleFile:(BOOL)shouldOptimizeSingleFile shouldCompareChecksum:(BOOL)shouldCompareChecksum excludedFiles:(NSArray *)excludedFiles {
    SMANJob *job = [SMANJob jobWithSource:source hostname:hostname destination:destination];
    job.shouldDelete = shouldDelete;
    job.excludedFiles = excludedFiles;
    [job attach];
    SMANRoster *roster = [self roster];
    [roster addJob:job];
}

- (void)sheetDidEditJob:(SMANJob *)job hostname:(NSString *)hostname destination:(NSString *)destination shouldDelete:(BOOL)shouldDelete shouldOptimizeSingleFile:(BOOL)shouldOptimizeSingleFile shouldCompareChecksum:(BOOL)shouldCompareChecksum excludedFiles:(NSArray *)excludedFiles {
    // Reduce unnecessary UI updates and notifications
    if (![job.hostname isEqualToString:hostname]) {
        job.hostname = hostname;
    }
    if (![job.destination isEqualToString:destination]) {
        job.destination = destination;
    }
    if (job.shouldDelete != shouldDelete) {
        job.shouldDelete = shouldDelete;
    }
    if (job.shouldOptimizeSingleFile != shouldOptimizeSingleFile) {
        job.shouldOptimizeSingleFile = shouldOptimizeSingleFile;
    }
    if (job.shouldCompareChecksum != shouldCompareChecksum) {
        job.shouldCompareChecksum = shouldCompareChecksum;
    }
    if (![job.excludedFiles isEqualToStringArray:excludedFiles]) {
        job.excludedFiles = excludedFiles;
    }
}

@end
