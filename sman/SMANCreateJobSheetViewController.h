//
//  SMANCreateJobSheetViewController.h
//  sman
//
//  Created by Roger Chen on 7/3/16.
//  Copyright © 2016 Roger Chen. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SMANCreateJobSheetViewControllerDelegate.h"

@interface SMANCreateJobSheetViewController : NSViewController

@property (weak) IBOutlet NSTextField *sourceTextField;
@property (weak) IBOutlet NSButton *sourceBrowseButton;
@property (weak) IBOutlet NSTextField *hostnameTextField;
@property (weak) IBOutlet NSTextField *destinationTextField;
@property (weak) IBOutlet NSButton *shouldDeleteButton;
@property (weak) IBOutlet NSButton *shouldOptimizeSingleFileButton;
@property (weak) IBOutlet NSButton *shouldCompareChecksumButton;
@property (weak) IBOutlet NSTextField *excludedFilesTextField;
@property (weak) IBOutlet NSButton *submitButton;
@property (weak) IBOutlet NSTextField *errorLabel;

@property (weak) id <SMANCreateJobSheetViewControllerDelegate> delegate;

@end
