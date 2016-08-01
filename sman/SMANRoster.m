//
//  SMANRoster.m
//  sman
//
//  Created by Roger Chen on 7/3/16.
//  Copyright © 2016 Roger Chen. All rights reserved.
//

#import "SMANRoster.h"

static const uintptr_t SMANJobUpdated = 1;

@interface SMANRoster ()

@property NSMutableArray *jobsList;

- (void)saveRosterToPreferences;

@end

@implementation SMANRoster

- (id)init {
    self = [super init];

    if (self != nil) {
        _jobsList = [NSMutableArray new];
    }

    return self;
}

- (NSArray *)jobs {
    return [NSArray arrayWithArray:self.jobsList];
}

- (NSInteger)countJobs {
    return [self.jobs count];
}

- (SMANJob *)getJobAtIndex:(NSUInteger)index {
    return [self.jobs objectAtIndex:index];
}

- (void)addJob:(SMANJob *)job {
    [self.jobsList addObject:job];
    [job addObserver:self forKeyPath:@"source" options:NSKeyValueObservingOptionNew context:(void *)SMANJobUpdated];
    [job addObserver:self forKeyPath:@"hostname" options:NSKeyValueObservingOptionNew context:(void *)SMANJobUpdated];
    [job addObserver:self forKeyPath:@"destination" options:NSKeyValueObservingOptionNew context:(void *)SMANJobUpdated];
    [job addObserver:self forKeyPath:@"shouldDelete" options:NSKeyValueObservingOptionNew context:(void *)SMANJobUpdated];
    [job addObserver:self forKeyPath:@"shouldOptimizeSingleFile" options:NSKeyValueObservingOptionNew context:(void *)SMANJobUpdated];
    [job addObserver:self forKeyPath:@"shouldCompareChecksum" options:NSKeyValueObservingOptionNew context:(void *)SMANJobUpdated];
    [job addObserver:self forKeyPath:@"excludedFiles" options:NSKeyValueObservingOptionNew context:(void *)SMANJobUpdated];
    [self saveRosterToPreferences];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"JobAdded" object:self userInfo:@{@"Job": job}];
}

- (void)removeJob:(SMANJob *)job {
    [self.jobsList removeObject:job];
    [job removeObserver:self forKeyPath:@"source" context:(void *)SMANJobUpdated];
    [job removeObserver:self forKeyPath:@"hostname" context:(void *)SMANJobUpdated];
    [job removeObserver:self forKeyPath:@"destination" context:(void *)SMANJobUpdated];
    [job removeObserver:self forKeyPath:@"shouldDelete" context:(void *)SMANJobUpdated];
    [job removeObserver:self forKeyPath:@"shouldOptimizeSingleFile" context:(void *)SMANJobUpdated];
    [job removeObserver:self forKeyPath:@"shouldCompareChecksum" context:(void *)SMANJobUpdated];
    [job removeObserver:self forKeyPath:@"excludedFiles" context:(void *)SMANJobUpdated];
    [self saveRosterToPreferences];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"JobRemoved" object:self userInfo:@{@"Job": job}];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
    return [self countJobs];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if (context == (void *)SMANJobUpdated) {
        [self saveRosterToPreferences];
    }
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    SMANJob *job = [self getJobAtIndex:row];

    if (job == nil) {
        return nil;
    }

    NSString *columnIdentifier = [tableColumn identifier];
    NSString *cellText;

    if ([columnIdentifier isEqualToString:@"SourceCellID"]) {
        cellText = job.source;
        NSString *homeDirectory = NSHomeDirectory();
        if ([cellText hasPrefix:homeDirectory]) {
            cellText = [@"~" stringByAppendingString:[cellText substringFromIndex:[homeDirectory length]]];
        }
    } else if ([columnIdentifier isEqualToString:@"HostnameCellID"]) {
        cellText = job.hostname;
    } else if ([columnIdentifier isEqualToString:@"DestinationCellID"]) {
        cellText = job.destination;
    } else if ([columnIdentifier isEqualToString:@"StatusCellID"]) {
        cellText = job.status;
    } else {
        return nil;
    }

    NSTableCellView *cell = [tableView makeViewWithIdentifier:columnIdentifier owner:self];
    if (cell == nil) {
        return nil;
    }

    cell.textField.stringValue = cellText;
    cell.textField.toolTip = cellText;
    return cell;
}

- (void)saveRosterToPreferences {
    NSMutableArray *jobs = [NSMutableArray new];
    for (SMANJob *job in [self jobs]) {
        [jobs addObject:[job parameters]];
    }
    [[NSUserDefaults standardUserDefaults] setObject:jobs forKey:@"Jobs"];
}

- (void)loadRosterFromPreferences {
    id jobsObject = [[NSUserDefaults standardUserDefaults] objectForKey:@"Jobs"];
    if (jobsObject == nil || ![jobsObject isKindOfClass:[NSArray class]]) {
        return;
    }

    NSDictionary *jobs = [jobsObject copy];
    for (id jobObject in jobs) {
        if ([jobObject isKindOfClass:[NSDictionary class]]) {
            SMANJob *job = [SMANJob jobWithParameters:jobObject];
            if (job != nil) {
                [self addJob:job];
                [job attach];
            }
        }
    }
}

@end
