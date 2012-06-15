//
//  WallClock.m
//  DCM
//
//  Created by Benjamin Ragheb on 6/14/12.
//  Copyright (c) 2012 Upright Citizens Brigade LLC. All rights reserved.
//

#import "WallClock.h"

NSString * const WallClockMinuteDidChangeNotification = @"WallClockMinuteDidChange";

@implementation WallClock

+ (WallClock *)sharedClock
{
    static WallClock *clock = nil;
    
    if (clock == nil) {
        clock = [[WallClock alloc] init];
    }
    return clock;
}

@synthesize timeShift;

- (NSTimeInterval)speed
{
    return speedRate;
}

- (void)setSpeed:(NSTimeInterval)secondsPerSecond
{
    if (secondsPerSecond) {
        speedOffset = [NSDate timeIntervalSinceReferenceDate];
        speedRate = secondsPerSecond;
        if (isRunning) [self scheduleTimer];
    } else {
        speedOffset = 0;
        speedRate = 0;
    }
}

- (NSDate *)date
{
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:timeShift];
    if (speedRate) {
        NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
        NSTimeInterval speedShift = (now - speedOffset) * speedRate;
        return [date dateByAddingTimeInterval:speedShift];
    } else {
        return date;
    }
}

- (NSTimeInterval)timeIntervalUntilNextMinuteChange
{
    if (speedRate) {
        return 60.0 / speedRate;
    }
    NSDate *now = [self date];
    NSTimeInterval sec;
    NSTimeInterval millis = modf([now timeIntervalSinceReferenceDate], &sec);
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *dc = [calendar components:NSSecondCalendarUnit fromDate:now];
    return 60.001 - millis - dc.second; // add 1 ms for safety
}

- (void)scheduleTimer
{
    [NSTimer
     scheduledTimerWithTimeInterval:[self timeIntervalUntilNextMinuteChange]
     target:self
     selector:@selector(timerDidFire:)
     userInfo:nil
     repeats:NO];
}

- (void)start
{
    isRunning = YES;
    [self scheduleTimer];
}

- (void)stop
{
    isRunning = NO;
}

- (void)timerDidFire:(NSTimer *)timer
{
    if (!isRunning) return;
//    NSLog(@"WallClock Timer Fired (planned %@, off by %f)",
//          [timer fireDate], [[timer fireDate] timeIntervalSinceNow]);
    [[NSNotificationCenter defaultCenter]
     postNotificationName:WallClockMinuteDidChangeNotification object:self];
    [self scheduleTimer];
}

@end
