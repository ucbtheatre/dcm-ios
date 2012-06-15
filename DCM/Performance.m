//
//  Performance.m
//  DCM
//
//  Created by Benjamin Ragheb on 5/13/12.
//  Copyright (c) 2012 Upright Citizens Brigade LLC. All rights reserved.
//

#import "Performance.h"


@implementation Performance

@dynamic favorite;
@dynamic identifier;
@dynamic startDate;
@dynamic endDate;
@dynamic minutes;
@dynamic ticketsURLString;
@dynamic show;
@dynamic venue;

- (NSString *)weekday
{
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"eeee"];
    return [df stringFromDate:self.startDate];
}

- (NSURL *)ticketsURL
{
    if (self.ticketsURLString) {
        return [NSURL URLWithString:self.ticketsURLString];
    } else {
        return nil;
    }
}

@end
