//
//  NSDictionary+DCM.m
//  DCM
//
//  Created by Benjamin Ragheb on 5/25/15.
//  Copyright (c) 2015 Upright Citizens Brigade LLC. All rights reserved.
//

#import "NSDictionary+DCM.h"

@implementation NSDictionary (DCM)

- (NSDictionary *)DCM_dictionaryWithNumberKeys
{
    NSMutableDictionary *newDictionary = [NSMutableDictionary dictionaryWithCapacity:[self count]];
    for (id key in self) {
        id object = [self objectForKey:key];

        if ([key isKindOfClass:[NSNumber class]]) {
            [newDictionary setObject:object forKey:key];
        }
        else if ([key respondsToSelector:@selector(integerValue)]) {
            [newDictionary setObject:object forKey:@([key integerValue])];
        }
        else {
            NSLog(@"warning: dropping key '%@', not numberable", key);
        }
    }
    return [newDictionary copy];
}

@end
