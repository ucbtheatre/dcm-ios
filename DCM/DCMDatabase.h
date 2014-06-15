//
//  DCMDatabase.h
//  DCM
//
//  Created by Benjamin Ragheb on 5/13/12.
//  Copyright (c) 2012 Upright Citizens Brigade LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Show.h"
#import "Venue.h"
#import "Performer.h"
#import "Performance.h"

extern NSString * const DCMDatabaseWillChangeNotification;
extern NSString * const DCMDatabaseDidChangeNotification;
extern NSString * const DCMDatabaseProgressNotification;

extern NSString * const DCMDatabaseActivityKey;
extern NSString * const DCMDatabaseProgressKey;
extern NSString * const DCMDatabaseErrorKey;

extern NSString * const DCMDatabaseErrorDomain;

static const float DCMDatabaseProgressIndeterminate = -1.0f;
static const float DCMDatabaseProgressNone = 0.0f;
static const float DCMDatabaseProgressComplete = 2.0f;

enum {
    DCMDatabaseErrorCodeNone = 0,
    DCMDatabaseErrorCodeUnhandledException = 1
};

@interface DCMDatabase : NSObject
+ (DCMDatabase *)sharedDatabase;
@property (nonatomic,readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic,readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic) BOOL shouldReportConnectionErrors;
- (BOOL)isEmpty;
- (void)checkForUpdate;
- (void)checkForUpdateQuietly:(BOOL)beQuiet;
- (void)forceUpdate;
- (void)importData:(NSData *)rawData responseHeaders:(NSDictionary *)headers;
- (void)endUpdate;
- (NSDate *)marathonStartDate;
@end
