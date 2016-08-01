//
//  ViewController.h
//  sman
//
//  Created by Roger Chen on 7/3/16.
//  Copyright © 2016 Roger Chen. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SMANRoster.h"

@interface ViewController : NSViewController <NSMenuDelegate>

@property (weak) IBOutlet NSTableView *rosterTableView;
@property (weak) IBOutlet NSMenu *contextMenu;

@end
