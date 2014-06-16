//
//  DCMDatabase.m
//  DCM
//
//  Created by Benjamin Ragheb on 5/13/12.
//  Copyright (c) 2012 Upright Citizens Brigade LLC. All rights reserved.
//

#include <sys/xattr.h>

#import "DCMDatabase.h"
#import "DCMDownload.h"
#import "DCMImportOperation.h"

NSString * const DCMDatabaseWillChangeNotification = @"DCMDatabaseWillChange";
NSString * const DCMDatabaseDidChangeNotification = @"DCMDatabaseDidChange";
NSString * const DCMDatabaseProgressNotification = @"DCMDatabaseProgress";

NSString * const DCMDatabaseActivityKey = @"DCMDatabaseActivity";
NSString * const DCMDatabaseProgressKey = @"DCMDatabaseProgress";
NSString * const DCMDatabaseErrorKey = @"DCMDatabaseError";

NSString * const DCMDatabaseErrorDomain = @"DCMDatabaseError";

static NSString * const DCMMetadataOriginLastModifiedKey = @"Origin-Last-Modified";
static NSString * const DCMMetadataOriginEntityTagKey = @"Origin-ETag";

@implementation DCMDatabase
{
    NSManagedObjectModel *__managedObjectModel;
    NSDate *__startDate;
    NSOperationQueue *__backgroundQueue;
    BOOL isUpdating;
}

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
@synthesize shouldReportConnectionErrors;

- (id)init
{
    if ((self = [super init])) {
        __backgroundQueue = [[NSOperationQueue alloc] init];
        __backgroundQueue.maxConcurrentOperationCount = 1;
    }
    return self;
}

#pragma mark - URLs

- (NSURL *)favoritesURL
{
    NSURL *documentsURL = [[[NSFileManager defaultManager]
                            URLsForDirectory:NSDocumentDirectory
                            inDomains:NSUserDomainMask] lastObject];
    return [NSURL URLWithString:@"dcm-favorites.plist" relativeToURL:documentsURL];
}

- (NSURL *)storeURL
{
    NSURL *documentsURL = [[[NSFileManager defaultManager]
                            URLsForDirectory:NSDocumentDirectory
                            inDomains:NSUserDomainMask] lastObject];
    return [NSURL URLWithString:@"dcm.sqlite" relativeToURL:documentsURL];
}

- (NSURL *)originURL
{
    return [NSURL URLWithString:@"http://api.production.ucbt.net/dcm"];
}

#pragma mark - Core Data

- (BOOL)isEmpty
{
    NSString *path = [[self storeURL] path];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        return YES;
    }
    NSDictionary *md = [[self persistentStore] metadata];
    return md[DCMMetadataOriginEntityTagKey] == nil && md[DCMMetadataOriginLastModifiedKey] == nil;
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

- (NSPersistentStore *)persistentStore
{
    return [[self persistentStoreCoordinator]
            persistentStoreForURL:[self storeURL]];
}

- (NSManagedObjectContext *)managedObjectContext
{
    if (__managedObjectContext) return __managedObjectContext;
    
    __managedObjectContext = [[NSManagedObjectContext alloc]
                              initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    __managedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator;
    return __managedObjectContext;
}

#pragma mark - Public methods

- (void)checkForUpdate
{
    [self checkForUpdateQuietly:NO];
}

- (void)checkForUpdateQuietly:(BOOL)beQuiet
{
    if (isUpdating) return;
    isUpdating = YES;
    self.shouldReportConnectionErrors = !beQuiet;
    DCMDownload *download = [[DCMDownload alloc] initWithDatabase:self];
    [NSURLConnection connectionWithRequest:[self originURLRequest:NO]
                                  delegate:download];
}

- (void)forceUpdate
{
    if (isUpdating) return;
    isUpdating = YES;
    self.shouldReportConnectionErrors = YES;
    DCMDownload *download = [[DCMDownload alloc] initWithDatabase:self];
    [NSURLConnection connectionWithRequest:[self originURLRequest:YES]
                                  delegate:download];
}

- (void)importData:(NSData *)rawData responseHeaders:(NSDictionary *)headers
{
    [self backupFavorites];
    [self deleteStore];
    NSManagedObjectContext *context = [[NSManagedObjectContext alloc]
                                       initWithConcurrencyType:
                                       NSPrivateQueueConcurrencyType];
    context.parentContext = self.managedObjectContext;
    [context performBlock:^{
        DCMImportOperation *importer = [[DCMImportOperation alloc]
                                        initWithData:rawData context:context];
        if ([importer performImport]) {
            [self restoreFavoritesWithContext:context];
            NSMutableDictionary *md = [[[self persistentStore] metadata] mutableCopy];
            id entityTag = headers[@"ETag"];
            if (entityTag) {
                md[DCMMetadataOriginEntityTagKey] = entityTag;
            } else {
                [md removeObjectForKey:DCMMetadataOriginEntityTagKey];
            }
            id lastModifiedToken = headers[@"Last-Modified"];
            if (lastModifiedToken) {
                md[DCMMetadataOriginLastModifiedKey] = lastModifiedToken;
            } else {
                [md removeObjectForKey:DCMMetadataOriginLastModifiedKey];
            }
            [[self persistentStore] setMetadata:md];
        }
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self.managedObjectContext save:nil];
            [[NSNotificationCenter defaultCenter]
             postNotificationName:DCMDatabaseDidChangeNotification
             object:self];
            [self endUpdate];
        }];
    }];
}

- (void)endUpdate
{
    isUpdating = NO;
}

#pragma mark - Everything else

- (NSURLRequest *)originURLRequest:(BOOL)forceUpdate
{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[self originURL]];
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    [request setHTTPShouldHandleCookies:NO];
    [request setNetworkServiceType:NSURLNetworkServiceTypeBackground];
    if (!forceUpdate) {
        NSDictionary *md = [[self persistentStore] metadata];
        NSString *entityTag = md[DCMMetadataOriginEntityTagKey];
        if (entityTag) {
            [request setValue:entityTag forHTTPHeaderField:@"If-None-Match"];
            // The client is not supposed to send an ETag header, but we need
            // this to work around a quirk in the UCBT's implementation.
            [request setValue:entityTag forHTTPHeaderField:@"ETag"];
        } else {
            NSString *lastModified = md[DCMMetadataOriginLastModifiedKey];
            if (lastModified) {
                [request setValue:lastModified forHTTPHeaderField:@"If-Modified-Since"];
            }
        }
    }
    return request;
}

- (BOOL)addSkipBackupAttributeToItemAtURL:(NSURL *)URL
{
    const char *filePath = [[URL path] fileSystemRepresentation];    
    const char *attrName = "com.apple.MobileBackup";
    u_int8_t attrValue = 1;
    int result = setxattr(filePath, attrName, &attrValue, sizeof(attrValue), 0, 0);
    return result == 0;
}

- (void)deleteStore
{
    [[NSNotificationCenter defaultCenter]
     postNotificationName:DCMDatabaseWillChangeNotification object:self];
    __managedObjectContext = nil;
    __persistentStoreCoordinator = nil;
    __startDate = nil;
    [[NSFileManager defaultManager] removeItemAtURL:[self storeURL] error:nil];
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
