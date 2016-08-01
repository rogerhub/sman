//
//  ViewController.m
//  sman
//
//  Created by Roger Chen on 7/3/16.
//  Copyright © 2016 Roger Chen. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"
#import "SMANRoster.h"
#import "SMANCreateJobSheetViewController.h"
#import "SMANViewLogsSheetViewController.h"
#import "SMANPreferencesSheetViewController.h"

static const uintptr_t SMANJobStatusUpdated = 1;

@interface ViewController ()

- (SMANRoster *)roster;

- (void)addObserversToJob:(SMANJob *)job;

- (void)removeObserversFromJob:(SMANJob *)job;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    SMANRoster *roster = [self roster];
    [self.rosterTableView setDelegate:roster];
    [self.rosterTableView setDataSource:roster];
    [self.rosterTableView reloadData];

    for (SMANJob *job in roster.jobs) {
        [self addObserversToJob:job];
    }

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rosterDidChange:) name:@"JobAdded" object:roster];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rosterDidChange:) name:@"JobRemoved" object:roster];
}

- (SMANRoster *)roster {
    AppDelegate *appDelegate = [NSApp delegate];
    return appDelegate.roster;
}

- (void)rosterDidChange:(NSNotification *)notification {
    SMANJob *job = notification.userInfo[@"Job"];
    if ([notification.name isEqualToString:@"JobAdded"]) {
        [self addObserversToJob:job];
    } else if ([notification.name isEqualToString:@"JobRemoved"]) {
        [self removeObserversFromJob:job];
    }
    [self.rosterTableView reloadData];
}

- (void)addObserversToJob:(SMANJob *)job {
    [job addObserver:self forKeyPath:@"source" options:NSKeyValueObservingOptionNew context:(void *)SMANJobStatusUpdated];
    [job addObserver:self forKeyPath:@"hostname" options:NSKeyValueObservingOptionNew context:(void *)SMANJobStatusUpdated];
    [job addObserver:self forKeyPath:@"destination" options:NSKeyValueObservingOptionNew context:(void *)SMANJobStatusUpdated];
    [job addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:(void *)SMANJobStatusUpdated];
}

- (void)removeObserversFromJob:(SMANJob *)job {
    [job removeObserver:self forKeyPath:@"source" context:(void *)SMANJobStatusUpdated];
    [job removeObserver:self forKeyPath:@"hostname" context:(void *)SMANJobStatusUpdated];
    [job removeObserver:self forKeyPath:@"destination" context:(void *)SMANJobStatusUpdated];
    [job removeObserver:self forKeyPath:@"status" context:(void *)SMANJobStatusUpdated];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if (context == (void *)SMANJobStatusUpdated) {
        [self.rosterTableView reloadData];
    }
}

- (IBAction)syncJob:(id)sender {
    SMANRoster *roster = [self roster];
    NSInteger clickedRow = [self.rosterTableView clickedRow];
    if (clickedRow > -1 && clickedRow < [roster countJobs]) {
        SMANJob *job = [roster getJobAtIndex:clickedRow];
        [job requestSync];
    }
}

- (IBAction)editJob:(id)sender {
    AppDelegate *appDelegate = [NSApp delegate];
    SMANRoster *roster = [self roster];
    NSInteger clickedRow = [self.rosterTableView clickedRow];
    if (clickedRow > -1 && clickedRow < [roster countJobs]) {
        appDelegate.jobToEdit = [roster getJobAtIndex:clickedRow];
        SMANCreateJobSheetViewController *sheetController = [self.storyboard instantiateControllerWithIdentifier:@"CreateJobSheet"];
        sheetController.delegate = appDelegate;
        [self presentViewControllerAsSheet:sheetController];
    }
}

- (IBAction)createJob:(id)sender {
    AppDelegate *appDelegate = [NSApp delegate];
    appDelegate.jobToEdit = nil;
    SMANCreateJobSheetViewController *sheetController = [self.storyboard instantiateControllerWithIdentifier:@"CreateJobSheet"];
    sheetController.delegate = appDelegate;
    [self presentViewControllerAsSheet:sheetController];
}

- (IBAction)viewLogs:(id)sender {
    AppDelegate *appDelegate = [NSApp delegate];
    SMANRoster *roster = [self roster];
    NSInteger clickedRow = [self.rosterTableView clickedRow];
    if (clickedRow > -1 && clickedRow < [roster countJobs]) {
        appDelegate.jobToViewLogs = [roster getJobAtIndex:clickedRow];
        SMANViewLogsSheetViewController *sheetController = [self.storyboard instantiateControllerWithIdentifier:@"ViewLogsSheet"];
        sheetController.delegate = appDelegate;
        [self presentViewControllerAsSheet:sheetController];
    }
}

- (IBAction)removeJob:(id)sender {
    NSInteger clickedRow = [self.rosterTableView clickedRow];
    SMANRoster *roster = [self roster];
    if (clickedRow > -1 && clickedRow < [roster countJobs]) {
        SMANJob *job = [roster getJobAtIndex:clickedRow];
        [job detatch];
        [roster removeJob:job];
        [self.rosterTableView reloadData];
    }
}

- (void)menuNeedsUpdate:(NSMenu *)menu {
    if (menu == self.contextMenu) {
        NSInteger clickedRow = [self.rosterTableView clickedRow];
        [menu removeAllItems];
        SMANRoster *roster = [self roster];
        if (clickedRow > -1 && clickedRow < [roster countJobs]) {
            NSMenuItem *syncJobMenuItem = [[NSMenuItem alloc] initWithTitle:@"Sync" action:@selector(syncJob:) keyEquivalent:@""];
            [menu addItem:syncJobMenuItem];
            NSMenuItem *editJobMenuItem = [[NSMenuItem alloc] initWithTitle:@"Edit" action:@selector(editJob:) keyEquivalent:@""];
            [menu addItem:editJobMenuItem];
            NSMenuItem *viewLogsMenuItem = [[NSMenuItem alloc] initWithTitle:@"View logs" action:@selector(viewLogs:) keyEquivalent:@""];
            [menu addItem:viewLogsMenuItem];
            NSMenuItem *removeJobMenuItem = [[NSMenuItem alloc] initWithTitle:@"Remove" action:@selector(removeJob:) keyEquivalent:@""];
            [menu addItem:removeJobMenuItem];
            [menu addItem:[NSMenuItem separatorItem]];
        }
        NSMenuItem *createJobMenuItem = [[NSMenuItem alloc] initWithTitle:@"Create job" action:@selector(createJob:) keyEquivalent:@""];
        [menu addItem:createJobMenuItem];
    }
}

@end
