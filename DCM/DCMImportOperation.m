//
//  DCMImportOperation.m
//  DCM
//
//  Created by Benjamin Ragheb on 5/13/12.
//  Copyright (c) 2012 Heroic Software Inc. All rights reserved.
//

#import "DCMImportOperation.h"
#import "DCMDatabase.h"

#import "Show.h"
#import "Venue.h"
#import "Performer.h"
#import "Performance.h"

@implementation DCMImportOperation

- (id)initWithData:(NSData *)data context:(NSManagedObjectContext *)context
{
    if ((self = [super init])) {
        rawData = data;
        managedObjectContext = context;
    }
    return self;
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
     userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
               activity,
               DCMDatabaseActivityKey,
               [NSNumber numberWithFloat:progress],
               DCMDatabaseProgressKey,
               nil]];
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

- (NSNumber *)identifierFromInfo:(NSDictionary *)info
{
    id value = [info objectForKey:@"id"];
    return [NSNumber numberWithInt:[value intValue]];
}

- (NSDate *)parseDate:(id)value
{
    return [NSDate dateWithTimeIntervalSince1970:[value doubleValue]];
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

- (void)importVenue:(NSDictionary *)info
{
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"Venue"
                                   inManagedObjectContext:managedObjectContext];
    Venue *venue = [[Venue alloc]
                    initWithEntity:entity
                    insertIntoManagedObjectContext:managedObjectContext];
    venue.identifier = [self identifierFromInfo:info];
    venue.name = [info objectForKey:@"name"];
    venue.shortName = [info objectForKey:@"short_name"];
    venue.address = [info objectForKey:@"address"];
    venue.directions = [info objectForKey:@"directions"];
    venue.imageURLString = [info objectForKey:@"image"];
    venue.mapURLString = [info objectForKey:@"gmaps"];
    venue.homeURLString = [info objectForKey:@"url"];
    [self cacheObject:venue withIdentifier:venue.identifier];
    [self didImportObject];
}

- (Performer *)performerFromName:(NSString *)name
{
    if ([name length] < 1) return nil;
    id key = [name stringByAppendingString:@":Performer"];
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
    perf.name = name;
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
    return [sortName substringToIndex:1];
}

- (void)importShow:(NSDictionary *)info
{
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"Show"
                                   inManagedObjectContext:managedObjectContext];
    Show *show = [[Show alloc]
                  initWithEntity:entity
                  insertIntoManagedObjectContext:managedObjectContext];
    show.identifier = [self identifierFromInfo:info];
    show.name = [info objectForKey:@"show_name"];
    show.sortName = [self sortNameFromName:show.name];
    show.sortSection = [self sortSectionFromSortName:show.sortName];
    show.promoBlurb = [info objectForKey:@"promo_blurb"];
    show.homeCity = [info objectForKey:@"home_city"];
    for (NSString *name in [info objectForKey:@"cast"]) {
        Performer *perf = [self performerFromName:name];
        if (perf) {
            [show addPerformersObject:perf];
        }
    }
    [self cacheObject:show withIdentifier:show.identifier];
    [self didImportObject];
}

- (void)importSchedule:(NSDictionary *)info
{
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"Performance"
                                   inManagedObjectContext:managedObjectContext];
    Performance *perf = [[Performance alloc]
                         initWithEntity:entity
                         insertIntoManagedObjectContext:managedObjectContext];
    perf.identifier = [self identifierFromInfo:info];
    perf.show = [self showFromIdentifier:[info objectForKey:@"show_id"]];
    perf.venue = [self venueFromIdentifier:[info objectForKey:@"venue_id"]];
    perf.startDate = [self parseDate:[info objectForKey:@"starttime"]];
    perf.endDate = [self parseDate:[info objectForKey:@"endtime"]];
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
    NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:rawData
                                                               options:0
                                                                 error:&error];
    if (jsonObject == nil) {
        [self postNotificationOfError:error];
        return;
    }
    NSArray *venueDataArray = [jsonObject objectForKey:@"Venues"];
    NSArray *showDataArray = [jsonObject objectForKey:@"Shows"];
    NSArray *scheduleDataArray = [jsonObject objectForKey:@"Schedules"];
    // Compute the number of objects to import
    numberOfObjectsToImport = ([venueDataArray count] +
                               [showDataArray count] +
                               [scheduleDataArray count]);
    objectCache = [[NSCache alloc] init];
    performerCache = [[NSMutableDictionary alloc]
                      initWithCapacity:(5 * [showDataArray count])];
    for (NSDictionary *info in showDataArray) {
        @autoreleasepool {
            [self importShow:[info objectForKey:@"Show"]];
        }
    }
    performerCache = nil;
    [self saveContext];
    for (NSDictionary *info in venueDataArray) {
        [self importVenue:[info objectForKey:@"Venue"]];
    }
    for (NSDictionary *info in scheduleDataArray) {
        @autoreleasepool {
            [self importSchedule:[info objectForKey:@"Schedule"]];
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
