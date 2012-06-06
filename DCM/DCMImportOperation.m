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

NSString * const DCMImportProgressNotification = @"DCMImportProgress";
NSString * const DCMImportProgressKey = @"DCMImportProgress";
NSString * const DCMImportErrorKey = @"DCMImportError";
NSString * const DCMImportErrorDomain = @"DCMImportError";

@implementation DCMImportOperation

- (id)initWithDatabase:(DCMDatabase *)db
{
    if ((self = [super init])) {
        database = db;
        persistentStoreCoordinator = db.persistentStoreCoordinator;
        sourceURL = [[NSBundle mainBundle]
                     URLForResource:@"dcm13data" withExtension:@"json"];
    }
    return self;
}

- (void)postNotificationOfProgress:(float)progress
{
    [[NSNotificationCenter defaultCenter]
     postNotificationName:DCMImportProgressNotification
     object:self
     userInfo:[NSDictionary
               dictionaryWithObject:[NSNumber numberWithFloat:progress]
               forKey:DCMImportProgressKey]];
    lastProgressNotificationDate = [[NSDate alloc] init];
}

- (void)didImportObject
{
    numberOfObjectsImported += 1;
    if ([lastProgressNotificationDate timeIntervalSinceNow] < -0.2) {
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

- (id)objectFromIdentifier:(id)identifier entity:(NSEntityDescription *)entity
{
    id key = [NSString stringWithFormat:@"%@:%@", entity.name, identifier];
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
    [self didImportObject];
}

- (Performer *)performerFromName:(NSString *)name
{
    if ([name length] < 1) return nil;
    id key = [@"Performer:" stringByAppendingString:name];
    Performer *perf = [objectCache objectForKey:key];
    if (perf) return perf;
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"Performer"
                                   inManagedObjectContext:managedObjectContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entity];
    [request setFetchLimit:1];
    [request setPredicate:[NSPredicate predicateWithFormat:@"name = %@", name]];
    NSError *error = nil;
    NSArray *results = [managedObjectContext
                        executeFetchRequest:request
                        error:&error];
    if (error) {
        @throw [NSException exceptionWithName:NSGenericException
                                       reason:[error localizedDescription]
                                     userInfo:nil];
    }
    if ([results count] > 0) {
        perf = [results objectAtIndex:0];
    } else {
        perf = [[Performer alloc]
                initWithEntity:entity
                insertIntoManagedObjectContext:managedObjectContext];
        perf.name = name;
    }
    [objectCache setObject:perf forKey:key];
    return perf;
}

- (NSString *)sortNameFromName:(NSString *)name
{
    NSString *upName = [name uppercaseString];
    if ([upName hasPrefix:@"THE "]) {
        return [upName substringFromIndex:4];
    }
    NSRange letterRange = [upName rangeOfCharacterFromSet:[NSCharacterSet alphanumericCharacterSet]];
    return [upName substringFromIndex:letterRange.location];
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

- (void)performImport
{
    NSInputStream *stream = [NSInputStream inputStreamWithURL:sourceURL];
    [stream open];
    NSError *error = nil;
    NSDictionary *data = [NSJSONSerialization JSONObjectWithStream:stream options:0 error:&error];
    if (data == nil) {
        [[NSNotificationCenter defaultCenter]
         postNotificationName:DCMImportProgressNotification
         object:self userInfo:[NSDictionary dictionaryWithObject:error forKey:DCMImportErrorKey]];
        return;
    }
    NSArray *venueDataArray = [data objectForKey:@"Venues"];
    NSArray *showDataArray = [data objectForKey:@"Shows"];
    NSArray *scheduleDataArray = [data objectForKey:@"Schedules"];
    // Compute the number of objects to import
    numberOfObjectsToImport = ([venueDataArray count] +
                               [showDataArray count] +
                               [scheduleDataArray count]);
    managedObjectContext = [[NSManagedObjectContext alloc]
                            initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator;
    objectCache = [[NSCache alloc] init];
    for (NSDictionary *info in venueDataArray) {
        [self importVenue:[info objectForKey:@"Venue"]];
    }
    [self saveContext];
    for (NSDictionary *info in showDataArray) {
        @autoreleasepool {
            [self importShow:[info objectForKey:@"Show"]];
        }
    }
    [self saveContext];
    for (NSDictionary *info in scheduleDataArray) {
        @autoreleasepool {
            [self importSchedule:[info objectForKey:@"Schedule"]];
        }
    }
    [self saveContext];
    objectCache = nil;
}

- (void)main
{
    @try {
        [self postNotificationOfProgress:0];
        [self performImport];
        [self postNotificationOfProgress:1];
    }
    @catch (NSException *exception) {
        NSError *error = [NSError
                          errorWithDomain:DCMImportErrorDomain
                          code:DCMImportErrorCodeUnhandledException
                          userInfo:[NSDictionary
                                    dictionaryWithObject:[exception reason]
                                    forKey:NSLocalizedDescriptionKey]];
        [[NSNotificationCenter defaultCenter]
         postNotificationName:DCMImportProgressNotification
         object:self
         userInfo:[NSDictionary
                   dictionaryWithObject:error
                   forKey:DCMImportErrorKey]];
    }
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [[NSNotificationCenter defaultCenter]
         postNotificationName:DCMDatabaseDidChangeNotification
         object:database];
    }];
}

@end
