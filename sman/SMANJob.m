//
//  SMANJob.m
//  sman
//
//  Created by Roger Chen on 7/3/16.
//  Copyright © 2016 Roger Chen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SMANJob.h"
#import "lib/wildmatch.h"

// See http://stackoverflow.com/questions/938095/#15947190
@implementation NSString (OccurrenceCount)

- (NSUInteger)occurrenceCountOfCharacter:(UniChar)character {
    CFStringRef selfAsCFStr = (__bridge CFStringRef)self;

    CFStringInlineBuffer inlineBuffer;
    CFIndex length = CFStringGetLength(selfAsCFStr);
    CFStringInitInlineBuffer(selfAsCFStr, &inlineBuffer, CFRangeMake(0, length));

    NSUInteger counter = 0;

    for (CFIndex i = 0; i < length; i++) {
        UniChar c = CFStringGetCharacterFromInlineBuffer(&inlineBuffer, i);
        if (c == character) {
            counter += 1;
        }
    }

    return counter;
}

/*!
 * @brief Standardizes a path, but preserves the trailing slash if it's already present
 * @discussion This function is useful for normalizing exclude patterns. A trailing slash in an
 *             exclude pattern should be preserved, because it means "only match directories".
 */
- (NSString *)stringByStandardizingPathPreserveTrailingSlash {
    BOOL endsWithSlash = [self hasSuffix:@"/"];
    NSString *standardizedPath = [self stringByStandardizingPath];
    if (endsWithSlash) {
        standardizedPath = [standardizedPath stringByAppendingString:@"/"];
    }
    return standardizedPath;
}

/*!
 * @brief Standardizes a path, but always adds a trailing slash.
 * @discussion This function is useful for normalizing a source directory.
 */
- (NSString *)stringByStandardizingPathWithTrailingSlash {
    NSString *standardizedPath = [self stringByStandardizingPath];
    return [standardizedPath stringWithTrailingSlash];
}

/*!
 * @brief Adds a trailing slash to a path, if not already present.
 * @discussion This function is useful for making sure the destination path
 *             has a trailing slash.
 */
- (NSString *)stringWithTrailingSlash {
    NSString *path = self;
    if ([path characterAtIndex: [path length] - 1] != '/') {
        path = [path stringByAppendingString:@"/"];
    }
    return path;
}

@end

@interface SMANJob ()

@property BOOL attached;

@property (readwrite) NSString *status;

@property NSTask *syncTask;

@property NSString *outputFirstLine;

@property BOOL syncIsRunning;

@property BOOL shouldSyncAgain;

@property NSString *filePathIfSyncingAgain;

- (void)attachFSEventsListener;

- (void)removeFSEventsListener;

- (BOOL)pathIsExcluded:(NSString *)path isDirectory:(BOOL)pathIsDirectory;

- (void)outputIsReady:(NSNotification *)notification;

- (void)syncDidFinish:(NSNotification *)notification;

- (void)appendToLog:(NSString *)data;

- (NSArray *)rsyncOptions;

- (NSArray *)rsyncOptionsForPath:(NSString *)path;

+ (BOOL)pattern:(NSString *)pattern matches:(NSString *)string;

@end

@implementation SMANJob {
    FSEventStreamRef eventStream;
    CFRunLoopRef eventStreamRunLoop;
}

- (id)init {
    [NSException raise:NSInternalInconsistencyException format:@"Unimplemented"];
    return nil;
}

- (id)initWithSource:(NSString *)source hostname:(NSString *)hostname destination:(NSString *)destination {
    if ([SMANJob problemsWithSource:source] || [SMANJob problemsWithHostname:hostname] || [SMANJob problemsWithDestination:destination]) {
        [NSException raise:NSInternalInconsistencyException format:@"Improper job paramters: %@, %@, %@", source, hostname, destination];
    }

    self = [super init];

    if (self != nil) {
        _source = source;
        _hostname = hostname;
        _destination = destination;
        _log = [NSMutableString new];
        _status = @"Idle";
        _shouldDelete = NO;
        _shouldOptimizeSingleFile = YES;
        _shouldCompareChecksum = YES;
        _attached = NO;
        _syncIsRunning = NO;
        _shouldSyncAgain = NO;
        _filePathIfSyncingAgain = nil;
        eventStream = NULL;
        eventStreamRunLoop = NULL;
    }

    return self;
}

- (void)dealloc {
    [self detatch];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    NSTask *task = self.syncTask;
    if (task != nil) {
        [task interrupt];
    }
}

- (void)attach {
    if (![NSThread isMainThread]) {
        [NSException raise:NSInternalInconsistencyException format:@"attach() should only be called by the main thread"];
    }
    if (self.attached) {
        [NSException raise:NSInternalInconsistencyException format:@"This task is already attached"];
    }
    self.attached = YES;
    [self attachFSEventsListener];
}

- (void)detatch {
    self.attached = NO;
    [self removeFSEventsListener];
}

- (void)attachFSEventsListener {
    CFRunLoopRef runLoop = CFRunLoopGetCurrent();
    CFRetain(runLoop);
    eventStreamRunLoop = runLoop;
    NSString *path = [self.source stringByStandardizingPath];
    NSArray *paths = @[path];
    CFArrayRef cfPaths = (__bridge CFArrayRef) paths;
    struct FSEventStreamContext eventStreamContext = {
        .version = 0,
        .info = (__bridge void * _Nullable)(self),
        .retain = NULL,
        .release = NULL,
        .copyDescription = NULL,
    };
    eventStream = FSEventStreamCreate(NULL, fsevent_callback, &eventStreamContext, cfPaths, kFSEventStreamEventIdSinceNow, 0.1, kFSEventStreamCreateFlagFileEvents|kFSEventStreamCreateFlagUseCFTypes);
    [self appendToLog:[NSString stringWithFormat:@"Attaching FSEvent stream to path: %@", path]];
    FSEventStreamScheduleWithRunLoop(eventStream, eventStreamRunLoop, kCFRunLoopDefaultMode);
    FSEventStreamStart(eventStream);
}

- (void)removeFSEventsListener {
    if (eventStream != nil) {
        FSEventStreamStop(eventStream);
        FSEventStreamInvalidate(eventStream);
        FSEventStreamRelease(eventStream);
        eventStream = nil;
    }
    if (eventStreamRunLoop != nil) {
        CFRelease(eventStreamRunLoop);
        eventStreamRunLoop = nil;
    }
}

static void fsevent_callback(ConstFSEventStreamRef streamRef, void *clientCallBackInfo, size_t numEvents, void *eventPaths, const FSEventStreamEventFlags eventFlags[], const FSEventStreamEventId eventIds[]) {
    SMANJob *job = (__bridge SMANJob *)clientCallBackInfo;
    CFArrayRef filePaths = eventPaths;
    NSMutableArray *modifiedFiles = [NSMutableArray new];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *jobStandardizedSource = [job.source stringByStandardizingPath];
    for (int i = 0; i < CFArrayGetCount(filePaths); i++) {
        NSString *filePath = (__bridge NSString *)((CFStringRef)CFArrayGetValueAtIndex(filePaths, i));
        if (![filePath isEqualToString:[filePath stringByStandardizingPath]]) {
            [NSException raise:NSInternalInconsistencyException format:@"Path is not standardized: %@", filePath];
        }
        if (![filePath hasPrefix:jobStandardizedSource]) {
            [NSException raise:NSInternalInconsistencyException format:@"%@ is not a prefix of %@", jobStandardizedSource, filePath];
        }
        BOOL pathIsDirectory = NO;
        if (![fileManager fileExistsAtPath:filePath isDirectory:&pathIsDirectory]) {
            // Safer default, I suppose
            pathIsDirectory = NO;
        }
        if (![job pathIsExcluded:filePath isDirectory:pathIsDirectory]) {
            [modifiedFiles addObject:[filePath copy]];
        }
    }

    // Do not perform sync if all paths are unmodified.
    if ([modifiedFiles count] == 0) {
        return;
    }

    do {
        if (!job.shouldOptimizeSingleFile) {
            break;
        }
        if ([modifiedFiles count] != 1) {
            break;
        }
        NSString *filePath = modifiedFiles[0];
        if ([filePath isEqualToString:jobStandardizedSource]) {
            break;
        }
        if ([filePath containsString:@"*"] || [filePath containsString:@"["] || [filePath containsString:@"?"]) {
            break;
        }

        BOOL sourceIsDirectory;
        if (![fileManager fileExistsAtPath:filePath isDirectory:&sourceIsDirectory]) {
            break;
        } else if (sourceIsDirectory) {
            break;
        }

        [job requestSyncForFile:filePath];
        return;
    } while (NO);
    [job requestSync];
}

- (void)requestSync {
    [self requestSyncForFile:nil];
}

- (void)requestSyncForFile:(NSString *)path {
    if (![NSThread isMainThread]) {
        [NSException raise:NSInternalInconsistencyException format:@"requestSyncForFile should only be called by the main thread"];
    }

    if (!self.attached) {
        [NSException raise:NSInternalInconsistencyException format:@"This task has not yet been attached"];
    }

    if (self.syncIsRunning) {
        if (self.shouldSyncAgain) {
            if (self.filePathIfSyncingAgain != nil && (path == nil || ![path isEqualToString:self.filePathIfSyncingAgain])) {
                // Broaden the request to sync everything
                self.filePathIfSyncingAgain = nil;
            }
        } else {
            self.shouldSyncAgain = YES;
            self.filePathIfSyncingAgain = path;
        }
        return;
    }

    self.syncIsRunning = YES;
    self.outputFirstLine = nil;
    if (path != nil) {
        NSString *displayPath = path;
        NSString *homeDirectory = NSHomeDirectory();
        if ([displayPath hasPrefix:homeDirectory]) {
            displayPath = [@"~" stringByAppendingString:[displayPath substringFromIndex:[homeDirectory length]]];
        }
        self.status = [NSString stringWithFormat:@"Sync of single file '%@' in progress...", displayPath];
    } else {
        self.status = @"Sync in progress...";
    }

    self.syncTask = [NSTask new];
    NSMutableArray *arguments;
    if (path != nil) {
        arguments = [NSMutableArray arrayWithArray:[self rsyncOptionsForPath:path]];
    } else {
        arguments = [NSMutableArray arrayWithArray:[self rsyncOptions]];
    }

    // Both the source and the destination should have trailing slashes, so rsync treats them as directories.
    [arguments addObject:[self.source stringByStandardizingPathWithTrailingSlash]];
    [arguments addObject:[NSString stringWithFormat:@"%@:%@", self.hostname, [self.destination stringWithTrailingSlash]]];

    self.syncTask.launchPath = @"/usr/bin/rsync";
    self.syncTask.arguments = arguments;

    [self appendToLog:[NSString stringWithFormat:@"Start sync with arguments: %@", self.syncTask.arguments]];
    NSPipe *outputPipe = [NSPipe pipe];
    self.syncTask.standardInput = [NSFileHandle fileHandleWithNullDevice];
    self.syncTask.standardOutput = outputPipe;
    self.syncTask.standardError = outputPipe;

    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(syncDidFinish:) name:NSTaskDidTerminateNotification object:self.syncTask];
    NSFileHandle *outputFileHandle = outputPipe.fileHandleForReading;
    [notificationCenter addObserver:self selector:@selector(outputIsReady:) name:NSFileHandleReadCompletionNotification object:outputFileHandle];
    [outputFileHandle readInBackgroundAndNotify];

    [self.syncTask launch];
}

- (BOOL)pathIsExcluded:(NSString *const)path isDirectory:(BOOL)pathIsDirectory {
    if (![path isEqualToString:[path stringByStandardizingPath]]) {
        [NSException raise:NSInternalInconsistencyException format:@"The path is not standardized: %@", path];
    }

    NSString *standardizedSource = [self.source stringByStandardizingPath];
    if (![path hasPrefix:standardizedSource]) {
        [NSException raise:NSInternalInconsistencyException format:@"%@ is not a prefix of %@", standardizedSource, path];
    }

    if ([path isEqualToString:standardizedSource]) {
        return false;
    }

    for (__strong NSString *excludePattern in self.excludedFiles) {
        excludePattern = [excludePattern stringByStandardizingPathPreserveTrailingSlash];

        // Equivalent to MATCHFLG_WILD in rsync
        BOOL patternFlagWild = [excludePattern containsString:@"*"] || [excludePattern containsString:@"["] || [excludePattern containsString:@"?"];

        // Equivalent to MATCHFLG_WILD2 in rsync
        BOOL patternFlagWild2 = [excludePattern containsString:@"**"];

        // Equivalent to MATCHFLG_WILD2_PREFIX in rsync
        BOOL patternFlagWild2Prefix = [excludePattern hasPrefix:@"**"];

        // Equivalent to MATCHFLG_WILD3_SUFFIX in rsync
        BOOL patternFlagWild3Suffix = [excludePattern hasSuffix:@"***"];

        // Equivalent to MATCHFLG_DIRECTORY in rsync
        BOOL patternFlagDirectory = [excludePattern hasSuffix:@"/"];

        // Equivalent to anchored_match
        BOOL patternAnchoredMatch = [excludePattern hasPrefix:@"/"];

        // Equivalent to ex->u.slash_cnt in rsync
        NSUInteger patternSlashCount = [excludePattern occurrenceCountOfCharacter:'/'];

        // Translator's note: This step isn't part of the original rule_matches() function
        // However, this transformation is applied when the pattern is first created.
        if (patternFlagDirectory) {
            excludePattern = [excludePattern substringToIndex:[excludePattern length] - 1];
        }

        if (patternAnchoredMatch) {
            excludePattern = [excludePattern substringFromIndex:1];
        }

        // A path is excluded if any of its ancestors is excluded.
        NSString *ancestorPath = [path substringFromIndex:[self.source stringByStandardizingPathWithTrailingSlash].length];

        while ([ancestorPath length] != 0) {
            if ([ancestorPath isEqualToString:@"/"]) {
                // ancestorPath should be a relative path.
                // If it starts with a slash, then the while loop will never terminate.
                [NSException raise:NSInternalInconsistencyException format:@"The ancestor path %@ should never start with a slash", ancestorPath];
            }
            do {
                // Create another alias to the ancestor path, so we can reassign it, according
                // to the code in rsync's rule_matches().
                // Since NSStrings are immutable, there's no need to worry about accidental mutation.
                NSString *relativePath = ancestorPath;

                // All the logic and comments below were adapted from rsync's rule_matches() function
                if (patternSlashCount == 0 && !patternFlagWild2) {
                    // If the pattern does not have any slashes AND it does
                    // not have a "**" (which could match a slash), then we
                    // just match the name portion of the path.
                    relativePath = [relativePath lastPathComponent];
                } else if (patternFlagWild2Prefix && ![relativePath hasPrefix:@"/"]) {
                    // Allow "**"+"/" to match at the start of the string.
                    relativePath = [@"/" stringByAppendingString:relativePath];
                }

                if (pathIsDirectory) {
                    // Allow a trailing "/"+"***" to match the directory.
                    if (patternFlagWild3Suffix) {
                        relativePath = [relativePath stringByAppendingString:@"/"];
                    }
                } else if (patternFlagDirectory) {
                    // Continue searching ancestor paths
                    break;
                }

                int slashHandling;
                if (!patternAnchoredMatch && patternSlashCount && !patternFlagWild2) {
                    // A non-anchored match with an infix slash and no "**"
                    // needs to match the last slash_cnt+1 name elements.
                    slashHandling = (int)patternSlashCount + 1;
                } else if (!patternAnchoredMatch && !patternFlagWild2Prefix && patternFlagWild2) {
                    // A non-anchored match with an infix or trailing "**" (but not
                    // a prefixed "**") needs to try matching after every slash.
                    slashHandling = -1;
                } else {
                    // The pattern matches only at the start of the path or name.
                    slashHandling = 0;
                }

                const char *relativePathCString = [relativePath cStringUsingEncoding:NSUTF8StringEncoding];
                const char *patternCString = [excludePattern cStringUsingEncoding:NSUTF8StringEncoding];
                const char *const strings[] = {relativePathCString, NULL};
                if (patternFlagWild) {
                    if (wildmatch_array(patternCString, strings, slashHandling)) {
                        return YES;
                    }
                } else if (patternAnchoredMatch) {
                    if (litmatch_array(patternCString, strings, slashHandling)) {
                        return YES;
                    }
                } else {
                    if ([excludePattern length] <= [relativePath length] &&
                        [relativePath hasSuffix:excludePattern] &&
                        ([relativePath length] == [excludePattern length] || [relativePath characterAtIndex:[relativePath length] - ([excludePattern length] + 1)] == '/')) {
                        return YES;
                    }
                }
            } while (NO);

            // Continue checking the parent directory
            ancestorPath = [ancestorPath stringByDeletingLastPathComponent];

            // Any ancestor must be treated as a directory.
            pathIsDirectory = YES;
        }
    }
    return NO;
}

- (void)syncDidFinish:(NSNotification *)notification {
    if (![NSThread isMainThread]) {
        [NSException raise:NSInternalInconsistencyException format:@"syncDidFinish should only be called by the main thread"];
    }

    NSTask *task = notification.object;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSTaskDidTerminateNotification object:task];

    int taskStatus = [task terminationStatus];
    if (taskStatus == 0) {
        [self appendToLog:@"Sync complete"];
        self.status = @"Sync complete";
    } else {
        [self appendToLog:@"Sync failed"];
        self.status = [NSString stringWithFormat:@"E%d: %@", taskStatus, self.outputFirstLine];
    }

    self.syncTask = nil;
    self.syncIsRunning = NO;
    if (self.shouldSyncAgain) {
        self.shouldSyncAgain = NO;
        [self requestSyncForFile:self.filePathIfSyncingAgain];
    }
}

- (void)outputIsReady:(NSNotification *)notification {
    if (![NSThread isMainThread]) {
        [NSException raise:NSInternalInconsistencyException format:@"outputIsReady should only be called by the main thread"];
    }

    NSFileHandle *outputFileHandle = notification.object;
    NSData *readData = notification.userInfo[NSFileHandleNotificationDataItem];

    if ([readData length] == 0) {
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter removeObserver:self name:NSFileHandleReadCompletionNotification object:outputFileHandle];
        return;
    }

    NSString *readDataString = [[NSString alloc] initWithData:readData encoding:NSUTF8StringEncoding];

    if (readDataString == nil) {
        // If UTF-8 is unable to decode the task data, try again with an 8-bit encoding that should
        // handle any byte sequence (latin1 a.k.a ISO-8859-1).
        readDataString = [[NSString alloc] initWithData:readData encoding:NSISOLatin1StringEncoding];
    }
    if (self.outputFirstLine == nil) {
        self.outputFirstLine = [[readDataString componentsSeparatedByString: @"\n"] objectAtIndex:0];
    }
    [self appendToLog:readDataString];
    [outputFileHandle readInBackgroundAndNotify];
}

- (void)appendToLog:(NSString *)data {
    if (![NSThread isMainThread]) {
        [NSException raise:NSInternalInconsistencyException format:@"appendToLog should only be called by the main thread"];
    }
    [self.log appendString:data];
    if (![data hasSuffix:@"\n"]) {
        [self.log appendString:@"\n"];
    }
}

- (NSArray *)rsyncOptions {
    return [self rsyncOptionsForPath:nil];
}

- (NSArray *)rsyncOptionsForPath:(NSString *)path {
    NSMutableArray *options = [NSMutableArray arrayWithObjects:@"--itemize-changes", @"--compress", @"--human-readable", @"--recursive", @"--links", @"--progress", @"--no-times", @"--perms", @"--no-owner", @"--no-group", nil];
    if (self.shouldDelete) {
        [options addObject:@"--delete"];
    }
    if (self.shouldCompareChecksum) {
        [options addObject:@"--checksum"];
    }
    if (path == nil) {
        for (NSString *excludedFile in self.excludedFiles) {
            [options addObject:[NSString stringWithFormat:@"--exclude=%@", excludedFile]];
        }
    } else {
        if (![path isEqualToString:[path stringByStandardizingPath]]) {
            [NSException raise:NSInternalInconsistencyException format:@"Single-file path is not optimized: %@", path];
        }

        NSString *standardizedSource = [self.source stringByStandardizingPath];
        if (![path hasPrefix:standardizedSource]) {
            [NSException raise:NSInternalInconsistencyException format:@"%@ is not a prefix of %@", standardizedSource, path];
        }

        if ([path isEqualToString:standardizedSource]) {
            [NSException raise:NSInternalInconsistencyException format:@"Cannot use single-file optimization to sync directory itself: %@", path];
        }

        if ([path containsString:@"*"] || [path containsString:@"["] || [path containsString:@"?"]) {
            [NSException raise:NSInternalInconsistencyException format:@"Cannot create single-file options for path containing wildcard character: %@", path];
        }

        // Each of the ancestor paths to the file must be included
        NSString *ancestorPath = [path substringFromIndex:[self.source stringByStandardizingPathWithTrailingSlash].length];
        while ([ancestorPath length] != 0) {
            if ([ancestorPath isEqualToString:@"/"]) {
                // ancestorPath should be a relative path.
                // If it starts with a slash, then the while loop will never terminate.
                [NSException raise:NSInternalInconsistencyException format:@"The ancestor path %@ should never start with a slash", ancestorPath];
            }
            [options addObject:[NSString stringWithFormat:@"--include=/%@", ancestorPath]];

            // Continue checking the parent directory
            ancestorPath = [ancestorPath stringByDeletingLastPathComponent];
        }
        [options addObject:@"--exclude=*"];
    }
    return [NSArray arrayWithArray:options];
}

- (NSDictionary *)parameters {
    return @{
        @"Source": self.source,
        @"Hostname": self.hostname,
        @"Destination": self.destination,
        @"ShouldDelete": [NSNumber numberWithBool:self.shouldDelete],
        @"ShouldOptimizeSingleFile": [NSNumber numberWithBool:self.shouldOptimizeSingleFile],
        @"ShouldCompareChecksum": [NSNumber numberWithBool:self.shouldCompareChecksum],
        @"ExcludedFiles": self.excludedFiles,
    };
}

+ (BOOL)pattern:(NSString *)pattern matches:(NSString *)string {
    NSRegularExpression *compiledPattern = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
    return [compiledPattern numberOfMatchesInString:string options:0 range:NSMakeRange(0, [string length])] > 0;
}

+ (NSString *)problemsWithSource:(NSString *)source {
    if ([source isEqualToString:@""]) {
        return @"Please enter a source";
    }
    if (![source hasPrefix:@"/"]) {
        return @"The source must be an absolute path";
    }

    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL sourceIsDirectory;
    if (![fileManager fileExistsAtPath:source isDirectory:&sourceIsDirectory]) {
        return @"The source does not exist";
    } else if (!sourceIsDirectory) {
        return @"The source must be a directory";
    }

    return nil;
}

+ (NSString *)problemsWithHostname:(NSString *)hostname {
    if ([hostname isEqualToString:@""]) {
        return @"Please enter a hostname";
    }
    if (![SMANJob pattern:@"^([a-z0-9_\\-]+@)?([a-zA-Z0-9\\-]+\\.)*[A-Za-z0-9\\-]+$" matches:hostname]) {
        return @"Hostname is invalid";
    }

    return nil;
}

+ (NSString *)problemsWithDestination:(NSString *)destination {
    if ([destination isEqualToString:@""]) {
        return @"Please enter a destination";
    }

    return nil;
}

+ (SMANJob *)jobWithSource:(NSString *)source hostname:(NSString *)hostname destination:(NSString *)destination {
    return [[SMANJob alloc] initWithSource:source hostname:hostname destination:destination];
}

+ (SMANJob *)jobWithParameters:(NSDictionary *)parameters {
    id sourceObject = [parameters objectForKey:@"Source"];
    if (sourceObject == nil || ![sourceObject isKindOfClass:[NSString class]]) {
        return nil;
    }
    id hostnameObject = [parameters objectForKey:@"Hostname"];
    if (hostnameObject == nil || ![hostnameObject isKindOfClass:[NSString class]]) {
        return nil;
    }
    id destinationObject = [parameters objectForKey:@"Destination"];
    if (destinationObject == nil || ![destinationObject isKindOfClass:[NSString class]]) {
        return nil;
    }
    NSString *source = sourceObject;
    NSString *hostname = hostnameObject;
    NSString *destination = destinationObject;
    if ([SMANJob problemsWithSource:source] || [SMANJob problemsWithHostname:hostname] || [SMANJob problemsWithDestination:destination]) {
        return nil;
    }

    SMANJob *job = [SMANJob jobWithSource:source hostname:hostname destination:destination];

    id shouldDeleteObject = [parameters objectForKey:@"ShouldDelete"];
    if (shouldDeleteObject != nil && [shouldDeleteObject isKindOfClass:[NSNumber class]]) {
        job.shouldDelete = [shouldDeleteObject boolValue];
    }
    id shouldOptimizeSingleFileObject = [parameters objectForKey:@"ShouldOptimizeSingleFile"];
    if (shouldOptimizeSingleFileObject != nil && [shouldOptimizeSingleFileObject isKindOfClass:[NSNumber class]]) {
        job.shouldOptimizeSingleFile = [shouldOptimizeSingleFileObject boolValue];
    }
    id shouldCompareChecksumObject = [parameters objectForKey:@"ShouldCompareChecksum"];
    if (shouldCompareChecksumObject != nil && [shouldCompareChecksumObject isKindOfClass:[NSNumber class]]) {
        job.shouldCompareChecksum = [shouldCompareChecksumObject boolValue];
    }
    id excludedFilesObject = [parameters objectForKey:@"ExcludedFiles"];
    if (excludedFilesObject != nil && [excludedFilesObject isKindOfClass:[NSArray class]]) {
        NSMutableArray *excludedFiles = [NSMutableArray new];
        for (__nonnull id excludedFileObject in excludedFilesObject) {
            if ([excludedFileObject isKindOfClass:[NSString class]]) {
                [excludedFiles addObject:excludedFileObject];
            }
        }
        job.excludedFiles = excludedFiles;
    }
    return job;
}

@end
