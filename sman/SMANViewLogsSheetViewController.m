//
//  SMANViewLogsSheetViewController.m
//  sman
//
//  Created by Roger Chen on 7/4/16.
//  Copyright © 2016 Roger Chen. All rights reserved.
//

#import "SMANViewLogsSheetViewController.h"

@implementation SMANViewLogsSheetViewController {
    SMANJob *jobToViewLogs;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    jobToViewLogs = nil;
    id delegate = self.delegate;
    if (delegate && [delegate respondsToSelector:@selector(jobToViewLogs)]) {
        jobToViewLogs = [delegate jobToViewLogs];
    }
    if (jobToViewLogs) {
        self.logsTextView.string = jobToViewLogs.log;
        self.logsTextView.textStorage.font = [NSFont fontWithName:@"Menlo" size:11];
    }
}

- (void)cancelOperation:(id)sender {
    [self dismissController:self];
}

@end
