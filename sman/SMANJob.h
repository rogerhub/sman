//
//  SMANJob.h
//  sman
//
//  Created by Roger Chen on 7/3/16.
//  Copyright © 2016 Roger Chen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SMANJob : NSObject

@property (readonly) NSString *source;

@property NSString *hostname;

@property NSString *destination;

@property BOOL shouldDelete;

@property BOOL shouldOptimizeSingleFile;

@property BOOL shouldCompareChecksum;

@property NSArray *excludedFiles;

@property NSMutableString *log;

@property (readonly) NSString *status;

- (id)initWithSource:(NSString *)source hostname: (NSString *)hostname destination:(NSString *)destination;

/*!
 * @brief Attaches this job to the current thread's IO Loop.
 * @discussion This should only be called by the main thread.
 */
- (void)attach;

/*!
 * @brief Un-attaches this job to the current thread's IO Loop.
 */
- (void)detatch;

/*!
 * @brief Requests another sync.
 * @discussion If a sync is currently occurring, then another one will be scheduled after it's finished.
 *             If another sync is already scheduled, then this function has no effect.
 */
- (void)requestSync;

/*!
 * @brief Requests syncing for a single file.
 * @discussion If another sync is already scheduled, but for a different path, then a full sync will be scheduled instead.
 */
- (void)requestSyncForFile:(NSString *)path;

- (void)lockSync;

- (void)unlockSync;

/*!
 * @returns A serialization of the parameters used to construct this job.
 */
- (NSDictionary *)parameters;

+ (NSString *)problemsWithSource:(NSString *)source;

+ (NSString *)problemsWithHostname:(NSString *)hostname;

+ (NSString *)problemsWithDestination:(NSString *)destination;

+ (SMANJob *)jobWithSource:(NSString *)source hostname:(NSString *)hostname destination:(NSString *)destination;

+ (SMANJob *)jobWithParameters:(NSDictionary *)parameters;

@end
