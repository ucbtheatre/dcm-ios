//
//  VoteResponse.m
//  DCM
//
//  Created by Kurt Guenther on 6/25/16.
//  Copyright © 2016 Upright Citizens Brigade LLC. All rights reserved.
//

#import "VoteResponse.h"

@implementation VoteResponse

+ (VoteResponse *)randomResponse:(DCMDatabase *)database {
    NSFetchRequest *voteResponseRequest = [NSFetchRequest fetchRequestWithEntityName:@"VoteResponse"];
    
    NSError* err = nil;
    NSArray* results = [database.managedObjectContext executeFetchRequest:voteResponseRequest error:&err];
    
    if(err){
        NSLog(@"Error getting vote response jokes:%@", [err localizedDescription]);
    }
    
    NSUInteger randomIndex = arc4random() % [results count];
    return [results objectAtIndex:randomIndex];
}

@end
