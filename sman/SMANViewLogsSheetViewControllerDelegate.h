//
//  SMANViewLogsSheetViewControllerDelegate.h
//  sman
//
//  Created by Roger Chen on 7/5/16.
//  Copyright © 2016 Roger Chen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SMANJob.h"

@protocol SMANViewLogsSheetViewControllerDelegate <NSObject>

@optional

- (SMANJob *)jobToViewLogs;

@end
