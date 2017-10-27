//
//  SMANRoster.h
//  sman
//
//  Created by Roger Chen on 7/3/16.
//  Copyright © 2016 Roger Chen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SMANJob.h"
@import AppKit;

@interface SMANRoster : NSObject <NSTableViewDataSource, NSTableViewDelegate>

- (NSArray *)jobs;

- (NSInteger)countJobs;

- (SMANJob *)getJobAtIndex:(NSUInteger)index;

- (void)addJob:(SMANJob *)job;

- (void)removeJob:(SMANJob *)job;

- (void)lockSync;

- (void)unlockSync;

- (void)saveRosterToPreferences;

- (void)loadRosterFromPreferences;

@end
