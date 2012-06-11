//
//  DCMDatabase.m
//  DCM
//
//  Created by Benjamin Ragheb on 5/13/12.
//  Copyright (c) 2012 Heroic Software Inc. All rights reserved.
//

#include <sys/xattr.h>

#import "DCMDatabase.h"

NSString * const DCMDatabaseWillChangeNotification = @"DCMDatabaseWillChange";
NSString * const DCMDatabaseDidChangeNotification = @"DCMDatabaseDidChange";

@implementation DCMDatabase

+ (DCMDatabase *)sharedDatabase
{
    static DCMDatabase *database = nil;
    
    if (database == nil) {
        database = [[DCMDatabase alloc] init];
    }
    return database;
}

@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;
@synthesize managedObjectContext = __managedObjectContext;

- (void)deleteStore
{
    [[NSNotificationCenter defaultCenter]
     postNotificationName:DCMDatabaseWillChangeNotification object:self];
    __managedObjectContext = nil;
    __persistentStoreCoordinator = nil;
    __startDate = nil;
    [[NSFileManager defaultManager] removeItemAtURL:[self storeURL] error:nil];
}

- (NSURL *)favoritesURL
{
    NSURL *documentsURL = [[[NSFileManager defaultManager]
                            URLsForDirectory:NSDocumentDirectory
                            inDomains:NSUserDomainMask] lastObject];
    return [NSURL URLWithString:@"dcm-favorites.plist" relativeToURL:documentsURL];
}

- (void)backupFavorites
{
    [self backupFavoritesWithContext:self.managedObjectContext];
}

- (void)backupFavoritesWithContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Show"];
    [request setResultType:NSDictionaryResultType];
    [request setPropertiesToFetch:[NSArray arrayWithObject:@"identifier"]];
    [request setPredicate:[NSPredicate predicateWithFormat:@"ANY performances.favorite = TRUE"]];
    NSError *error = nil;
    NSArray *results = [context executeFetchRequest:request error:&error];
    if (error) {
        NSLog(@"Warning: Backup Favorites Failed: %@", [error localizedDescription]);
        return;
    }
    [results writeToURL:[self favoritesURL] atomically:YES];
}

- (void)restoreFavoritesWithContext:(NSManagedObjectContext *)context
{
    NSArray *array = [NSArray arrayWithContentsOfURL:[self favoritesURL]];
    NSMutableSet *identifierSet = [[NSMutableSet alloc] initWithCapacity:[array count]];
    for (NSDictionary *props in array) {
        [identifierSet addObject:[props objectForKey:@"identifier"]];
    }
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Show"];
    [request setPredicate:[NSPredicate predicateWithFormat:@"identifier IN %@", identifierSet]];
    NSError *error = nil;
    NSArray *results = [context executeFetchRequest:request error:&error];
    if (error) {
        NSLog(@"Warning: Restore Favorites: %@", [error localizedDescription]);
        return;
    }
    for (Show *show in results) {
        for (Performance *perf in show.performances) {
            perf.favorite = YES;
        }
    }
    [context save:&error];
    if (error) {
        NSLog(@"Warning: Restore Favorites: %@", [error localizedDescription]);
    }
}

- (NSURL *)storeURL
{
    NSURL *documentsURL = [[[NSFileManager defaultManager]
                            URLsForDirectory:NSDocumentDirectory
                            inDomains:NSUserDomainMask] lastObject];
    return [NSURL URLWithString:@"dcm.sqlite" relativeToURL:documentsURL];
}

- (BOOL)addSkipBackupAttributeToItemAtURL:(NSURL *)URL
{
    const char *filePath = [[URL path] fileSystemRepresentation];    
    const char *attrName = "com.apple.MobileBackup";
    u_int8_t attrValue = 1;
    int result = setxattr(filePath, attrName, &attrValue, sizeof(attrValue), 0, 0);
    return result == 0;
}

- (NSManagedObjectModel *)managedObjectModel
{
    if (__managedObjectModel) return __managedObjectModel;

    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"DCM" withExtension:@"momd"];
    __managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return __managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (__persistentStoreCoordinator) return __persistentStoreCoordinator;

    __persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [self storeURL];
    NSError *error;
    [__persistentStoreCoordinator
     addPersistentStoreWithType:NSSQLiteStoreType
     configuration:nil
     URL:storeURL
     options:nil
     error:&error];
    [self addSkipBackupAttributeToItemAtURL:storeURL];
    return __persistentStoreCoordinator;
}

- (NSManagedObjectContext *)managedObjectContext
{
    if (__managedObjectContext) return __managedObjectContext;

    __managedObjectContext = [[NSManagedObjectContext alloc]
                              initWithConcurrencyType:NSMainQueueConcurrencyType];
    __managedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator;
    return __managedObjectContext;
}

- (NSUInteger)numberOfShows
{
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Show"];
    [request setResultType:NSCountResultType];
    NSError *error = nil;
    NSArray *results = [self.managedObjectContext
                        executeFetchRequest:request error:&error];
    if (error) {
        NSLog(@"Warning: %@", [error localizedDescription]);
    }
    return [[results lastObject] unsignedIntegerValue];
}

- (NSDate *)marathonStartDate
{
    if (__startDate != nil) return __startDate;
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Performance"];
    [request setResultType:NSDictionaryResultType];
    [request setPropertiesToFetch:[NSArray arrayWithObject:@"startDate"]];
    [request setSortDescriptors:
     [NSArray arrayWithObject:
      [NSSortDescriptor sortDescriptorWithKey:@"startDate" ascending:YES]]];
    [request setFetchLimit:1];
    NSError *error = nil;
    NSArray *results = [self.managedObjectContext
                        executeFetchRequest:request error:&error];
    if (error) {
        NSLog(@"Warning: %@", [error localizedDescription]);
    }
    __startDate = [[results lastObject] objectForKey:@"startDate"];
    return __startDate;
}

@end
