//
//  SMANCreateJobSheetViewControllerDelegate.h
//  sman
//
//  Created by Roger Chen on 7/4/16.
//  Copyright © 2016 Roger Chen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SMANJob.h"

@protocol SMANCreateJobSheetViewControllerDelegate <NSObject>

@optional

- (void)sheetDidCreateJobWithSource:(NSString *)source hostname:(NSString *)hostname destination:(NSString *)destination shouldDelete:(BOOL)shouldDelete shouldOptimizeSingleFile:(BOOL)shouldOptimizeSingleFile shouldCompareChecksum:(BOOL)shouldCompareChecksum excludedFiles:(NSArray *)excludedFiles;

- (SMANJob *)jobToEdit;

- (void)sheetDidEditJob:(SMANJob *)job hostname:(NSString *)hostname destination:(NSString *)destination shouldDelete:(BOOL)shouldDelete shouldOptimizeSingleFile:(BOOL)shouldOptimizeSingleFile shouldCompareChecksum:(BOOL)shouldCompareChecksum excludedFiles:(NSArray *)excludedFiles;

@end
