//
//  DCMImportOperation.m
//  DCM
//
//  Created by Benjamin Ragheb on 5/13/12.
//  Copyright (c) 2012 Upright Citizens Brigade LLC. All rights reserved.
//

#import "DCMImportOperation.h"
#import "DCMDatabase.h"

#import "NSDictionary+DCM.h"

#import "Show.h"
#import "Venue.h"
#import "Performer.h"
#import "Performance.h"

@implementation DCMImportOperation
{
    NSData *rawData;
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

- (id)cacheKeyForIdentifier:(id)identifier entity:(NSEntityDescription *)entity
{
    NSParameterAssert(identifier != nil);
    NSParameterAssert(entity != nil);

    return [NSString stringWithFormat:@"%@:%@", identifier, entity.name];
}

- (void)cacheObject:(NSManagedObject *)object withIdentifier:(id)identifier
{
    id key = [self cacheKeyForIdentifier:identifier entity:object.entity];
    [objectCache setObject:object forKey:key];
}

- (id)objectFromIdentifier:(id)identifier entity:(NSEntityDescription *)entity
{
    id key = [self cacheKeyForIdentifier:identifier entity:entity];
    id object = [objectCache objectForKey:key];
    if (object) return object;

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

- (NSArray *)performersFromIdentifiers:(NSSet *)identifiers
{
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"Performer"
                                   inManagedObjectContext:managedObjectContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entity];
    [request setReturnsObjectsAsFaults:YES];
    [request setPredicate:
     [NSPredicate predicateWithFormat:@"identifier IN %@", identifiers]];
    NSError *error = nil;
    NSArray *results = [managedObjectContext
                        executeFetchRequest:request
                        error:&error];
    if (error) {
        NSLog(@"performer fetch error: %@", error);
    }
    return results;
}

/**
 * Takes a dictionary where each pair is of the form:
 * @{ performer-id: @{ first: String, last: String } }
 * and returns a set of Performer objects.
 */
- (NSSet *)performerSetFromCastInfo:(NSDictionary *)castInfo
{
    NSUInteger count = [castInfo count];

    // Ensure the keys are numbers, not strings.
    castInfo = [castInfo DCM_dictionaryWithNumberKeys];

    // We'll build up a set of performer objects to be returned at the end.
    NSMutableSet *performers = [NSMutableSet setWithCapacity:count];

    // This will be a set of identifiers still to be fetched.
    NSMutableSet *identifiers = [NSMutableSet setWithArray:[castInfo allKeys]];

    assert([performers count] + [identifiers count] == count);

    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"Performer"
                                   inManagedObjectContext:managedObjectContext];

    // First, round up any performers that are in the memory cache.
    for (id key in [identifiers copy]) {
        id cacheKey = [self cacheKeyForIdentifier:key entity:entity];
        Performer *p = [objectCache objectForKey:cacheKey];
        if (p) {
            [performers addObject:p];
            [identifiers removeObject:key];
        }
    }

    assert([performers count] + [identifiers count] == count);

    // Next, fetch any remaining performers from the persistent store.
    NSArray *results = [self performersFromIdentifiers:identifiers];
    for (Performer *p in results) {
        [performers addObject:p];
        [identifiers removeObject:[p identifier]];
    }

    assert([performers count] + [identifiers count] == count);

    // Finally, create any missing performers.
    for (id key in identifiers) {
        NSDictionary *perfInfo = castInfo[key];
        Performer *p = [[Performer alloc]
                        initWithEntity:entity
                        insertIntoManagedObjectContext:managedObjectContext];
        p.identifier = key;
        p.firstName = perfInfo[@"first"];
        p.lastName = perfInfo[@"last"];
        [performers addObject:p];
        [self cacheObject:p withIdentifier:key];
    }

    assert([performers count] == count);

    return performers;
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
/**
The server now sends the cast over in a dictionary instead of an array, where person ID is the key.
We could add cast headshots later with:
http://974d0d3e3fab692e5845-1fa162517f41f1b2710e3fd3bd0f08f4.r84.cf5.rackcdn.com/person_{{ PERSON_ID }}.png
for thumbnail headshots (75pxX75px)
or
http://2292774aeb57f699998f-7c1ee3a3cf06785b3e2b618873b759ef.r47.cf5.rackcdn.com/person_{{ PERSON_ID }}.png
for full size (400pxX400px)
**/
    NSDictionary *castDictionary = info[@"cast"];
    // We check because the cast value may be an empty array (e.g., Indie Team
    // Cage Match Winner).
    if ([castDictionary count] > 0) {
        show.performers = [self performerSetFromCastInfo:castDictionary];
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
    for (NSDictionary *showObject in showArray) {
        @autoreleasepool {
            [self importShow:showObject];
        }
    }
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
