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

@end
