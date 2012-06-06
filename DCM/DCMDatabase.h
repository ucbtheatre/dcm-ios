//
//  DCMDatabase.h
//  DCM
//
//  Created by Benjamin Ragheb on 5/13/12.
//  Copyright (c) 2012 Heroic Software Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Show.h"
#import "Venue.h"
#import "Performer.h"
#import "Performance.h"

extern NSString * const DCMDatabaseWillChangeNotification;
extern NSString * const DCMDatabaseDidChangeNotification;

@interface DCMDatabase : NSObject
{
    NSManagedObjectModel *managedObjectModel;
}
+ (DCMDatabase *)sharedDatabase;
@property (nonatomic,readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic,readonly) NSManagedObjectContext *managedObjectContext;
- (void)deleteStore;
- (NSUInteger)numberOfShows;
@end
