//
//  Show.m
//  DCM
//
//  Created by Benjamin Ragheb on 5/13/12.
//  Copyright (c) 2012 Upright Citizens Brigade LLC. All rights reserved.
//

#import "Show.h"
#import "Performance.h"
#import "Performer.h"
#import "Venue.h"

@implementation Show

@dynamic name;
@dynamic promoBlurb;
@dynamic homeCity;
@dynamic imageURLString;
@dynamic identifier;
@dynamic performers;
@dynamic performances;
@dynamic sortName;
@dynamic sortSection;
@dynamic favoriteChangedDate;

+ (NSArray *)standardSortDescriptors
{
    return @[[NSSortDescriptor
              sortDescriptorWithKey:@"sortName" ascending:YES]];
}

+ (NSDateFormatter *)dateFormatter
{
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"EEEE h:mm a"];
    return df;
}

+ (NSString *)sortNameFromName:(NSString *)name
{
    NSStringCompareOptions options = (NSCaseInsensitiveSearch |
                                      NSDiacriticInsensitiveSearch |
                                      NSWidthInsensitiveSearch);
    NSString *foldedName = [name
                            stringByFoldingWithOptions:options
                            locale:[NSLocale currentLocale]];
    if ([foldedName hasPrefix:@"the "]) {
        return [foldedName substringFromIndex:4];
    }
    NSRange letterRange = [foldedName rangeOfCharacterFromSet:
                           [NSCharacterSet alphanumericCharacterSet]];
    if (letterRange.location == NSNotFound) {
        return foldedName;
    } else {
        return [foldedName substringFromIndex:letterRange.location];
    }
}

+ (NSString *)sortSectionFromSortName:(NSString *)sortName
{
    NSCharacterSet *letterSet = [NSCharacterSet letterCharacterSet];
    if ([letterSet characterIsMember:[sortName characterAtIndex:0]]) {
        return [sortName substringToIndex:1];
    } else {
        return @"#";
    }
}

- (void)setName:(NSString *)name
{
    [self willChangeValueForKey:@"name"];
    [self setPrimitiveValue:name forKey:@"name"];

    self.sortName = [Show sortNameFromName:name];

    self.sortSection = [Show sortSectionFromSortName:self.sortName];

    [self didChangeValueForKey:@"name"];
}

- (BOOL)isFavorite
{
    for (Performance *p in self.performances) {
        if (p.favorite) return YES;
    }
    return NO;
}

- (BOOL)toggleFavoriteAndSave:(NSError **)error
{
    BOOL favored = ! [self isFavorite];
    self.favoriteChangedDate = [NSDate date];
    for (Performance* p in self.performances) {
        p.favorite = favored;
    }
    return [self.managedObjectContext save:error];
}

- (BOOL)anyShowRequiresTicket
{
    for (Performance *perf in self.performances) {
        if (perf.ticketsURL != nil) return YES;
    }
    return NO;
}

- (NSArray *)performancesSortedByDate
{
    return [self.performances sortedArrayUsingDescriptors:
            [NSArray arrayWithObject:
             [NSSortDescriptor
              sortDescriptorWithKey:@"startDate" ascending:YES]]];
}

#pragma mark UIActivityItemSource

- (id)activityViewControllerPlaceholderItem:(UIActivityViewController *)activityViewController
{
    return @"text";
}

- (id)activityViewController:(UIActivityViewController *)activityViewController itemForActivityType:(NSString *)activityType
{
    // Cases:
    // - 1 performance
    // - multiple performances, 1 venue
    // - multiple performances, multiple venues
    NSMutableString *text = [NSMutableString string];

    [text appendString:([self isFavorite] ? @"I’ll be at " : @"Check out ")];
    [text appendString:self.name];
    [text appendString:@" "];

    NSDateFormatter *dateFormatter = [Show dateFormatter];

    NSArray *performances = [self performancesSortedByDate];

    if ([[performances valueForKeyPath:@"@distinctUnionOfObjects.venue"] count] > 1) {
        [performances enumerateObjectsUsingBlock:^(Performance *p, NSUInteger idx, BOOL *stop) {
            if (idx > 0) [text appendString:@", "];
            [text appendFormat:@"%@ at %@",
             [dateFormatter stringFromDate:p.startDate],
             p.venue.name];
        }];
    }
    else {
        [performances enumerateObjectsUsingBlock:^(Performance *p, NSUInteger idx, BOOL *stop) {
            if (idx > 0) [text appendString:@", "];
            [text appendString:[dateFormatter stringFromDate:p.startDate]];
        }];
        [text appendFormat:@" at %@", [[[performances lastObject] venue] name]];
    }
    [text appendString:@" #dcm17"];

    return text;
}

- (NSString *)activityViewController:(UIActivityViewController *)activityViewController subjectForActivityType:(NSString *)activityType
{
    return self.name;
}

@end
