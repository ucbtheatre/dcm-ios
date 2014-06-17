//
//  DCMImportOperation.m
//  DCM
//
//  Created by Benjamin Ragheb on 5/13/12.
//  Copyright (c) 2012 Upright Citizens Brigade LLC. All rights reserved.
//

#import "DCMImportOperation.h"
#import "DCMDatabase.h"

#import "Show.h"
#import "Venue.h"
#import "Performer.h"
#import "Performance.h"

@implementation DCMImportOperation
{
    NSData *rawData;
    NSMutableDictionary *performerCache;
    NSCache *objectCache;
    NSUInteger numberOfObjectsToImport;
    NSUInteger numberOfObjectsImported;
    NSDate *lastProgressNotificationDate;
    NSManagedObjectContext *managedObjectContext;
    NSDictionary *importPropertyMap;
}

- (id)initWithData:(NSData *)data context:(NSManagedObjectContext *)context
{
    if ((self = [super init])) {
        rawData = data;
        managedObjectContext = context;
    }
    return self;
}

- (void)loadImportPropertyMap
{
    NSURL *mapURL = [[NSBundle mainBundle] URLForResource:@"DCMImportMap"
                                            withExtension:@"plist"];
    importPropertyMap = [NSDictionary dictionaryWithContentsOfURL:mapURL];
}

- (void)postNotificationOfProgress:(float)progress
{
    NSString *activity;
    if (progress < 0.1f) {
        activity = @"Opening";
    } else if (progress < 0.4f) {
        activity = @"First Beats";
    } else if (progress < 0.7f) {
        activity = @"Second Beats";
    } else if (progress < DCMDatabaseProgressComplete) {
        activity = @"Third Beats";
    } else {
        activity = @"Blackout";
    }
    [[NSNotificationCenter defaultCenter]
     postNotificationName:DCMDatabaseProgressNotification
     object:nil
     userInfo:@{DCMDatabaseActivityKey: activity,
                DCMDatabaseProgressKey: @(progress)}];
     lastProgressNotificationDate = [[NSDate alloc] init];
}

- (void)postNotificationOfError:(NSError *)error
{
    [[NSNotificationCenter defaultCenter]
     postNotificationName:DCMDatabaseProgressNotification
     object:self
     userInfo:[NSDictionary
               dictionaryWithObject:error
               forKey:DCMDatabaseErrorKey]];
}

- (void)didImportObject
{
    numberOfObjectsImported += 1;
    if ([lastProgressNotificationDate timeIntervalSinceNow] < -0.1) {
        float n = numberOfObjectsImported;
        float d = numberOfObjectsToImport;
        [self postNotificationOfProgress:(n / d)];
    }
}

- (void)cacheObject:(NSManagedObject *)object withIdentifier:(id)identifier
{
    id key = [NSString stringWithFormat:@"%@:%@", identifier, object.entity.name];
    [objectCache setObject:object forKey:key];
}

- (id)objectFromIdentifier:(id)identifier entity:(NSEntityDescription *)entity
{
    id key = [NSString stringWithFormat:@"%@:%@", identifier, entity.name];
    id object = [objectCache objectForKey:key];
    if (object) return object;
    // Because we are no longer using NSCache, the following is never executed.
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entity];
    [request setFetchLimit:1];
    [request setReturnsObjectsAsFaults:YES];
    [request setPredicate:[NSPredicate
                           predicateWithFormat:@"identifier = %d",
                           [identifier intValue]]];
    NSError *error = nil;
    NSArray *results = [managedObjectContext
                        executeFetchRequest:request
                        error:&error];
    if (error) {
        @throw [NSException exceptionWithName:NSGenericException
                                       reason:[error localizedDescription]
                                     userInfo:nil];
    }
    object = [results objectAtIndex:0]; // throws exception if array is empty
    [objectCache setObject:object forKey:key];
    return object;
}

- (Show *)showFromIdentifier:(id)identifier
{
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"Show"
                                   inManagedObjectContext:managedObjectContext];
    return [self objectFromIdentifier:identifier entity:entity];
}

- (Venue *)venueFromIdentifier:(id)identifier
{
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"Venue"
                                   inManagedObjectContext:managedObjectContext];
    return [self objectFromIdentifier:identifier entity:entity];
}

- (Performer *)performerFromName:(NSDictionary *)nameObject
{
    NSString *firstName = nameObject[@"first"];
    NSString *lastName = nameObject[@"last"];
    NSString *fullName = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
    id key = fullName;
    Performer *perf = [performerCache objectForKey:key];
    if (perf) {
        return perf;
    }
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"Performer"
                                   inManagedObjectContext:managedObjectContext];
    perf = [[Performer alloc]
            initWithEntity:entity
            insertIntoManagedObjectContext:managedObjectContext];
    perf.name = fullName;
    [performerCache setObject:perf forKey:key];
    return perf;
}

- (NSString *)sortNameFromName:(NSString *)name
{
    NSString *upName = [name uppercaseString];
    if ([upName hasPrefix:@"THE "]) {
        return [upName substringFromIndex:4];
    }
    NSRange letterRange = [upName rangeOfCharacterFromSet:
                           [NSCharacterSet alphanumericCharacterSet]];
    if (letterRange.location == NSNotFound) {
        return upName;
    } else {
        return [upName substringFromIndex:letterRange.location];
    }
}

- (NSString *)sortSectionFromSortName:(NSString *)sortName
{
    NSCharacterSet *letterSet = [NSCharacterSet letterCharacterSet];
    if ([letterSet characterIsMember:[sortName characterAtIndex:0]]) {
        return [sortName substringToIndex:1];
    } else {
        return @"#";
    }
}

- (id)objectWithEntityName:(NSString *)entityName fromObject:(NSDictionary *)info
{
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:entityName
                                   inManagedObjectContext:managedObjectContext];
    id object = [[NSManagedObject alloc]
                 initWithEntity:entity
                 insertIntoManagedObjectContext:managedObjectContext];
    NSDictionary *map = importPropertyMap[entityName];
    NSDictionary *attributes = [entity attributesByName];
    [map enumerateKeysAndObjectsUsingBlock:^(id localKey, id remoteKey, BOOL *stop) {
        NSAttributeDescription *desc = attributes[localKey];
        assert(desc != nil);
        id remoteValue = info[remoteKey];
        if (remoteValue == [NSNull null]) {
            remoteValue = nil;
        }
        if ([remoteValue isKindOfClass:[NSString class]] && [remoteValue length] == 0) {
            remoteValue = nil;
        }
        id localValue = nil;
        if (remoteValue) {
            switch ([desc attributeType]) {
                case NSDateAttributeType:
                    localValue = [NSDate dateWithTimeIntervalSince1970:[remoteValue doubleValue]];
                    break;
                default:
                    localValue = remoteValue;
            }
        }
        [object setValue:localValue forKey:localKey];
    }];
    return object;
}

- (void)importVenue:(NSDictionary *)info
{
    Venue *venue = [self objectWithEntityName:@"Venue" fromObject:info];
    [self cacheObject:venue withIdentifier:venue.identifier];
    [self didImportObject];
}

- (void)importShow:(NSDictionary *)info
{
    Show *show = [self objectWithEntityName:@"Show" fromObject:info];
    show.sortName = [self sortNameFromName:show.name];
    show.sortSection = [self sortSectionFromSortName:show.sortName];
    NSArray *nameArray = info[@"cast"];
    for (NSDictionary *nameObject in nameArray) {
        Performer *perf = [self performerFromName:nameObject];
        if (perf) {
            [show addPerformersObject:perf];
        }
    }
    [self cacheObject:show withIdentifier:show.identifier];
    [self didImportObject];
}

- (void)importSchedule:(NSDictionary *)info
{
    Performance *perf = [self objectWithEntityName:@"Performance" fromObject:info];
    perf.show = [self showFromIdentifier:[info objectForKey:@"show_id"]];
    perf.venue = [self venueFromIdentifier:[info objectForKey:@"venue_id"]];
    NSTimeInterval interval = [perf.endDate timeIntervalSinceDate:perf.startDate];
    perf.minutes = [NSNumber numberWithDouble:(interval / 60.0)];
    [self didImportObject];
}

- (void)saveContext
{
    NSError *error;
    if (![managedObjectContext save:&error]) {
        @throw [NSException exceptionWithName:NSGenericException
                                       reason:[error localizedDescription]
                                     userInfo:nil];
    }
}

- (void)main
{
    [self postNotificationOfProgress:DCMDatabaseProgressNone];
    NSError *error = nil;
    NSDictionary *rootObject = [NSJSONSerialization JSONObjectWithData:rawData
                                                               options:0
                                                                 error:&error];
    if (rootObject == nil) {
        [self postNotificationOfError:error];
        return;
    }

    /*
     * JSON format synopsis:
     * {
     *   "status": <BOOLEAN>,
     *   "data": {
     *     "Schedules": [ ... ],
     *     "Shows": [ ... ],
     *     "Venues": [ ... ],
     *   }
     * }
     */

    NSDictionary *dataObject = rootObject[@"data"];
    
    if (![dataObject isKindOfClass:[NSDictionary class]]) {
        [self postNotificationOfError:nil];
        return;
    }

    [self loadImportPropertyMap];
    
    NSArray *venueArray = dataObject[@"Venues"];
    NSArray *showArray = dataObject[@"Shows"];
    NSArray *scheduleArray = dataObject[@"Schedules"];

    // Compute the number of objects to import
    numberOfObjectsToImport = ([venueArray count] +
                               [showArray count] +
                               [scheduleArray count]);
    objectCache = [[NSCache alloc] init];
    performerCache = [[NSMutableDictionary alloc] initWithCapacity:(5 * [showArray count])];
    for (NSDictionary *showObject in showArray) {
        @autoreleasepool {
            [self importShow:showObject];
        }
    }
    performerCache = nil;
    [self saveContext];
    for (NSDictionary *venueObject in venueArray) {
        @autoreleasepool {
            [self importVenue:venueObject];
        }
    }
    for (NSDictionary *scheduleObject in scheduleArray) {
        @autoreleasepool {
            [self importSchedule:scheduleObject];
        }
    }
    objectCache = nil;
    [self saveContext];
    [self postNotificationOfProgress:DCMDatabaseProgressComplete];
}

- (BOOL)performImport
{
    @try {
        [self main];
        return YES;
    }
    @catch (NSException *exception) {
        [self postNotificationOfError:
         [NSError
          errorWithDomain:DCMDatabaseErrorDomain
          code:DCMDatabaseErrorCodeUnhandledException
          userInfo:[NSDictionary
                    dictionaryWithObject:[exception reason]
                    forKey:NSLocalizedDescriptionKey]]];
        return NO;
    }
}

@end
