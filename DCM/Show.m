//
//  Show.m
//  DCM
//
//  Created by Benjamin Ragheb on 5/13/12.
//  Copyright (c) 2012 Heroic Software Inc. All rights reserved.
//

#import "Show.h"
#import "Performance.h"
#import "Performer.h"


@implementation Show

@dynamic name;
@dynamic promoBlurb;
@dynamic homeCity;
@dynamic identifier;
@dynamic performers;
@dynamic performances;
@dynamic sortName;
@dynamic sortSection;


- (BOOL) favorite
{
    return [[self.performances anyObject] favorite];
}

@end
