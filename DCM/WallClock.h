//
//  WallClock.h
//  DCM
//
//  Created by Benjamin Ragheb on 6/14/12.
//  Copyright (c) 2012 Upright Citizens Brigade LLC. All rights reserved.
//

/*
 This class serves two purposes:
 
 1. To post a notification whenever the minute (according to a wall clock) changes. This is used to update the UI accordingly.
 
 2. Allow the time, and its rate of passage, to be changed in order to faciliate testing.
 */

#import <Foundation/Foundation.h>

extern NSString * const WallClockMinuteDidChangeNotification;

@interface WallClock : NSObject
+ (WallClock *)sharedClock;
@property (nonatomic) NSTimeInterval timeShift;
@property (nonatomic) NSTimeInterval speed;
- (NSDate *)date;
- (BOOL)isDateInThePast:(NSDate *)date;
- (void)start;
- (void)stop;
@end
