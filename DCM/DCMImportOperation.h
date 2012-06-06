//
//  DCMImportOperation.h
//  DCM
//
//  Created by Benjamin Ragheb on 5/13/12.
//  Copyright (c) 2012 Heroic Software Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const DCMImportProgressNotification;
extern NSString * const DCMImportProgressKey;
extern NSString * const DCMImportErrorKey;
extern NSString * const DCMImportErrorDomain;

enum {
    DCMImportErrorCodeNone = 0,
    DCMImportErrorCodeUnhandledException = 1
};

@class DCMDatabase;

@interface DCMImportOperation : NSOperation
{
    DCMDatabase *database;
    NSCache *objectCache;
    NSURL *sourceURL;
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    NSUInteger numberOfObjectsToImport;
    NSUInteger numberOfObjectsImported;
    NSDate *lastProgressNotificationDate;
    NSManagedObjectContext *managedObjectContext;
}
- (id)initWithDatabase:(DCMDatabase *)database;
@end
