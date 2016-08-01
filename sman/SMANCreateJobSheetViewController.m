//
//  SMANCreateJobSheetViewController.m
//  sman
//
//  Created by Roger Chen on 7/3/16.
//  Copyright © 2016 Roger Chen. All rights reserved.
//

#import "SMANJob.h"
#import "SMANCreateJobSheetViewController.h"
#import "SMANArrayToStringValueTransformer.h"

@implementation SMANCreateJobSheetViewController {
    SMANJob *jobToEdit;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    SMANArrayToStringValueTransformer *arrayToStringValueTransformer = [SMANArrayToStringValueTransformer new];
    jobToEdit = nil;
    id delegate = self.delegate;
    if (delegate != nil && [delegate respondsToSelector:@selector(jobToEdit)]) {
        jobToEdit = [delegate jobToEdit];
    }
    if (jobToEdit != nil) {
        self.submitButton.title = @"Update job";
        self.sourceTextField.stringValue = jobToEdit.source;
        self.sourceTextField.enabled = NO;
        self.sourceBrowseButton.enabled = NO;
        self.hostnameTextField.stringValue = jobToEdit.hostname;
        self.destinationTextField.stringValue = jobToEdit.destination;
        self.shouldDeleteButton.state = jobToEdit.shouldDelete ? NSOnState : NSOffState;
        self.shouldOptimizeSingleFileButton.state = jobToEdit.shouldOptimizeSingleFile ? NSOnState : NSOffState;
        self.shouldCompareChecksumButton.state = jobToEdit.shouldCompareChecksum ? NSOnState : NSOffState;
        self.excludedFilesTextField.stringValue = [arrayToStringValueTransformer transformedValue:jobToEdit.excludedFiles];
    } else {
        id preferences = [[NSUserDefaultsController sharedUserDefaultsController] values];
        NSArray *defaultExcludedFiles = [preferences valueForKey:@"DefaultExcludedFiles"];
        self.submitButton.title = @"Create job";
        self.sourceTextField.enabled = YES;
        self.sourceBrowseButton.enabled = YES;
        self.shouldDeleteButton.state = [[preferences valueForKey:@"DefaultShouldDelete"] boolValue] ? NSOnState : NSOffState;
        self.shouldOptimizeSingleFileButton.state = [[preferences valueForKey:@"DefaultShouldOptimizeSingleFile"] boolValue] ? NSOnState : NSOffState;
        self.shouldCompareChecksumButton.state = [[preferences valueForKey:@"DefaultShouldCompareChecksum"] boolValue] ? NSOnState : NSOffState;
        self.excludedFilesTextField.stringValue = [arrayToStringValueTransformer transformedValue:defaultExcludedFiles];
    }
}

- (IBAction)submitJob:(id)sender {
    id delegate = self.delegate;
    NSString *source = [self.sourceTextField stringValue];
    NSString *hostname = [self.hostnameTextField stringValue];
    NSString *destination = [self.destinationTextField stringValue];
    BOOL shouldDelete = [self.shouldDeleteButton state] != NSOffState;
    BOOL shouldOptimizeSingleFile = [self.shouldOptimizeSingleFileButton state] != NSOffState;
    BOOL shouldCompareChecksum = [self.shouldCompareChecksumButton state] != NSOffState;
    SMANArrayToStringValueTransformer *arrayToStringValueTransformer = [SMANArrayToStringValueTransformer new];
    NSArray *excludedFiles = [arrayToStringValueTransformer reverseTransformedValue:[self.excludedFilesTextField stringValue]];

    NSString *errorMessage;
    if ((errorMessage = [SMANJob problemsWithSource:source]) || (errorMessage = [SMANJob problemsWithHostname:hostname]) || (errorMessage = [SMANJob problemsWithDestination:destination])) {
        self.errorLabel.stringValue = errorMessage;
        return;
    }

    if (jobToEdit != nil) {
        if (delegate != nil && [delegate respondsToSelector:@selector(sheetDidEditJob:hostname:destination:shouldDelete:shouldOptimizeSingleFile:shouldCompareChecksum:excludedFiles:)]) {
            [delegate sheetDidEditJob:jobToEdit hostname:hostname destination:destination shouldDelete:shouldDelete shouldOptimizeSingleFile:shouldOptimizeSingleFile shouldCompareChecksum:shouldCompareChecksum excludedFiles:excludedFiles];
        }
    } else {
        if (delegate != nil && [delegate respondsToSelector:@selector(sheetDidCreateJobWithSource:hostname:destination:shouldDelete:shouldOptimizeSingleFile:shouldCompareChecksum:excludedFiles:)]) {
            [delegate sheetDidCreateJobWithSource:source hostname:hostname destination:destination shouldDelete:shouldDelete shouldOptimizeSingleFile:shouldOptimizeSingleFile shouldCompareChecksum:shouldCompareChecksum excludedFiles:excludedFiles];
        }
    }

    [self dismissController:self];
}

- (void)cancelOperation:(id)sender {
    [self dismissController:self];
}

- (void)controlTextDidChange:(NSNotification *)notification {
    NSTextField *textField = [notification object];
    if (textField == self.sourceTextField) {
        NSString *source = [textField stringValue];
        if ([source isEqualToString:@"~/"]) {
            textField.stringValue = [NSString stringWithFormat:@"%@/", NSHomeDirectory()];
        }
    }
}

- (IBAction)browseSource:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setCanChooseFiles:NO];
    [panel setCanChooseDirectories:YES];
    [panel setAllowsMultipleSelection:NO];
    [panel beginWithCompletionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            NSURL *sourcePathUrl = [[panel URLs] objectAtIndex:0];
            if ([sourcePathUrl.scheme isEqualToString:@"file"]) {
                NSString *sourcePath = [sourcePathUrl path];
                self.sourceTextField.stringValue = sourcePath;
            } else {
                // TODO error handling
            }
        }
    }];
}

@end
