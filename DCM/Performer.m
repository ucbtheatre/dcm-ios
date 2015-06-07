//
//  Performer.m
//  DCM
//
//  Created by Benjamin Ragheb on 5/13/12.
//  Copyright (c) 2012 Upright Citizens Brigade LLC. All rights reserved.
//

#import "Performer.h"

@implementation Performer

@dynamic identifier;
@dynamic firstName;
@dynamic lastName;
@dynamic fullName;
@dynamic shows;

+ (NSArray *)standardSortDescriptors
{
    return @[
             [NSSortDescriptor
              sortDescriptorWithKey:@"firstName" ascending:YES],
             [NSSortDescriptor
              sortDescriptorWithKey:@"lastName" ascending:YES]
             ];
}

- (void)willSave
{
    if (self.fullName == nil) {
        self.fullName = [NSString stringWithFormat:@"%@ %@", self.firstName, self.lastName];
    }
}

@end
