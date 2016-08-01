//
//  SMANJobTests.m
//  sman
//
//  Created by Roger Chen on 7/10/16.
//  Copyright © 2016 Roger Chen. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SMANJob.h"

@interface SMANJobTests : XCTestCase

@end

@interface SMANJob ()

- (BOOL)pathIsExcluded:(NSString *)path isDirectory:(BOOL)pathIsDirectory;

@end

@implementation SMANJobTests

- (void)testFilenamePatterns {
    SMANJob *job = [SMANJob jobWithSource:@"/tmp" hostname:@"fakehost" destination:@"tmp/"];
    job.excludedFiles = @[@"FOO", @"bar", @"B.AZ"];

    // Basic patterns
    XCTAssertTrue([job pathIsExcluded:@"/tmp/FOO" isDirectory:NO]);
    XCTAssertTrue([job pathIsExcluded:@"/tmp/bar" isDirectory:NO]);
    XCTAssertTrue([job pathIsExcluded:@"/tmp/B.AZ" isDirectory:NO]);

    // Totally unrelated pattern
    XCTAssertFalse([job pathIsExcluded:@"/tmp/other_file" isDirectory:NO]);

    // Case sensitivity
    XCTAssertFalse([job pathIsExcluded:@"/tmp/BAR" isDirectory:NO]);
    XCTAssertFalse([job pathIsExcluded:@"/tmp/b.Az" isDirectory:NO]);

    // Directory names
    XCTAssertTrue([job pathIsExcluded:@"/tmp/FOO/x" isDirectory:NO]);
    XCTAssertTrue([job pathIsExcluded:@"/tmp/bar/y" isDirectory:NO]);
    XCTAssertTrue([job pathIsExcluded:@"/tmp/B.AZ/z/f/g/s/d/f/a/s/f/a/s" isDirectory:NO]);
}

- (void)testSubdirectoryPatterns {
    SMANJob *job = [SMANJob jobWithSource:@"/tmp" hostname:@"fakehost" destination:@"tmp/"];
    job.excludedFiles = @[@"a/foo", @"b/foo"];
    XCTAssertTrue([job pathIsExcluded:@"/tmp/FOO/a/foo" isDirectory:NO]);
    XCTAssertTrue([job pathIsExcluded:@"/tmp/bar/b/foo" isDirectory:NO]);
    XCTAssertTrue([job pathIsExcluded:@"/tmp/a/foo" isDirectory:NO]);
    XCTAssertTrue([job pathIsExcluded:@"/tmp/a/foo/other_file" isDirectory:NO]);
    XCTAssertFalse([job pathIsExcluded:@"/tmp/a/x/foo" isDirectory:NO]);
}

- (void)testDirectoryPathPatterns {
    SMANJob *job = [SMANJob jobWithSource:@"/tmp" hostname:@"fakehost" destination:@"tmp/"];
    job.excludedFiles = @[@"x/foo/"];
    XCTAssertFalse([job pathIsExcluded:@"/tmp/FOO/x/foo" isDirectory:NO]);
    XCTAssertTrue([job pathIsExcluded:@"/tmp/bar/x/foo" isDirectory:YES]);
    XCTAssertFalse([job pathIsExcluded:@"/tmp/x/foo" isDirectory:NO]);
    XCTAssertTrue([job pathIsExcluded:@"/tmp/x/foo" isDirectory:YES]);
    XCTAssertTrue([job pathIsExcluded:@"/tmp/x/foo/other_file" isDirectory:NO]);
    XCTAssertTrue([job pathIsExcluded:@"/tmp/x/foo/other_directory" isDirectory:YES]);
}

- (void)testStarPatterns {
    SMANJob *job = [SMANJob jobWithSource:@"/tmp" hostname:@"fakehost" destination:@"tmp/"];
    job.excludedFiles = @[@"x/*"];

    // Any file in this directory
    XCTAssertTrue([job pathIsExcluded:@"/tmp/FOO/x/foo" isDirectory:NO]);
    XCTAssertTrue([job pathIsExcluded:@"/tmp/bar/x/foo" isDirectory:YES]);

    // Should also apply to files in subdirectories
    XCTAssertTrue([job pathIsExcluded:@"/tmp/FOO/x/directory/foo" isDirectory:NO]);

    job.excludedFiles = @[@"x/*/bar"];

    // No separating directory
    XCTAssertFalse([job pathIsExcluded:@"/tmp/FOO/x/bar" isDirectory:NO]);

    // Now this should work
    XCTAssertTrue([job pathIsExcluded:@"/tmp/FOO/x/directory/bar" isDirectory:NO]);
    XCTAssertTrue([job pathIsExcluded:@"/tmp/FOO/x/directory/bar" isDirectory:YES]);
    XCTAssertTrue([job pathIsExcluded:@"/tmp/FOO/x/directory/bar/x" isDirectory:NO]);

    // But this shouldn't
    XCTAssertFalse([job pathIsExcluded:@"/tmp/FOO/x/directory/directory/bar" isDirectory:NO]);

    // Starts with the same character
    XCTAssertFalse([job pathIsExcluded:@"/tmp/xxx/xx/xxxxx" isDirectory:NO]);
}

- (void)testStar2Patterns {
    SMANJob *job = [SMANJob jobWithSource:@"/tmp" hostname:@"fakehost" destination:@"tmp/"];
    job.excludedFiles = @[@"x/**"];

    // Simple files
    XCTAssertTrue([job pathIsExcluded:@"/tmp/FOO/x/foo" isDirectory:NO]);
    XCTAssertTrue([job pathIsExcluded:@"/tmp/bar/x/foo" isDirectory:YES]);

    // Subdirectories
    XCTAssertTrue([job pathIsExcluded:@"/tmp/FOO/x/foo/other_file" isDirectory:NO]);
    XCTAssertTrue([job pathIsExcluded:@"/tmp/bar/x/foo/other_directory" isDirectory:YES]);

    // The directory itself (needs triple slash)
    XCTAssertFalse([job pathIsExcluded:@"/tmp/FOO/x" isDirectory:YES]);

    // Starts with the same character
    XCTAssertFalse([job pathIsExcluded:@"/tmp/xxx/xx/xxxxx" isDirectory:NO]);
}

- (void)testStar3Patterns {
    SMANJob *job = [SMANJob jobWithSource:@"/tmp" hostname:@"fakehost" destination:@"tmp/"];
    job.excludedFiles = @[@"x/***"];

    // Simple files
    XCTAssertTrue([job pathIsExcluded:@"/tmp/FOO/x/foo" isDirectory:NO]);
    XCTAssertTrue([job pathIsExcluded:@"/tmp/bar/x/foo" isDirectory:YES]);

    // Subdirectories
    XCTAssertTrue([job pathIsExcluded:@"/tmp/FOO/x/foo/other_file" isDirectory:NO]);
    XCTAssertTrue([job pathIsExcluded:@"/tmp/bar/x/foo/other_directory" isDirectory:YES]);

    // The directory itself
    XCTAssertTrue([job pathIsExcluded:@"/tmp/FOO/x" isDirectory:YES]);

    // Starts with the same character
    XCTAssertFalse([job pathIsExcluded:@"/tmp/xxx/xx/xxxxx" isDirectory:NO]);
}

- (void)testAnchoredPatterns {
    SMANJob *job = [SMANJob jobWithSource:@"/tmp" hostname:@"fakehost" destination:@"tmp/"];
    job.excludedFiles = @[@"/x/foo.bar"];

    // Simple files
    XCTAssertTrue([job pathIsExcluded:@"/tmp/x/foo.bar" isDirectory:NO]);
    XCTAssertFalse([job pathIsExcluded:@"/tmp/FOO/x/foo.bar" isDirectory:NO]);

    // Starts with same characters
    XCTAssertFalse([job pathIsExcluded:@"/tmp/x/foo.barxxxx" isDirectory:NO]);
    XCTAssertFalse([job pathIsExcluded:@"/tmp/x/foo.barxxxx/baz" isDirectory:NO]);
}

- (void)testUglyPatterns {
    SMANJob *job = [SMANJob jobWithSource:@"/tmp" hostname:@"fakehost" destination:@"tmp/"];
    job.excludedFiles = @[@"**.tmp"];

    // Simple files
    XCTAssertTrue([job pathIsExcluded:@"/tmp/FOO/x/foo.tmp" isDirectory:NO]);
    XCTAssertTrue([job pathIsExcluded:@"/tmp/bar/x/foo.tmp" isDirectory:YES]);

    job.excludedFiles = @[@"*///***//*.tmp"];

    // Simple files
    XCTAssertTrue([job pathIsExcluded:@"/tmp/FOO/x/foo.tmp" isDirectory:NO]);
    XCTAssertTrue([job pathIsExcluded:@"/tmp/bar/x/foo.tmp" isDirectory:YES]);

    // Not in a subdirectory
    XCTAssertFalse([job pathIsExcluded:@"/tmp/baz.tmp" isDirectory:NO]);
}

@end
