//
//  FluxCapacitorViewController.m
//  DCM
//
//  Created by Benjamin Ragheb on 5/13/12.
//  Copyright (c) 2012 Heroic Software Inc. All rights reserved.
//

#import "FluxCapacitorViewController.h"
#import "DCMDatabase.h"
#import "WallClock.h"

@interface FluxCapacitorViewController ()

@end

static const NSTimeInterval kSpeedSettings[] = { 0, 300, 1800 };

@implementation FluxCapacitorViewController

@synthesize delegate;
@synthesize datePicker;
@synthesize speedControl;

- (void)viewDidLoad
{
    [super viewDidLoad];
    WallClock *clock = [WallClock sharedClock];
    self.datePicker.date = [NSDate dateWithTimeIntervalSinceNow:clock.timeShift];
    for (NSInteger i = 0; i < [self.speedControl numberOfSegments]; i++) {
        if (clock.speed <= kSpeedSettings[i]) {
            self.speedControl.selectedSegmentIndex = i;
            break;
        }
    }
}

- (void)jumpToMarathonStart:(id)sender
{
    self.datePicker.date = [[DCMDatabase sharedDatabase] marathonStartDate];
}

- (void)confirm:(id)sender
{
    NSTimeInterval newSpeed = kSpeedSettings[self.speedControl.selectedSegmentIndex];
    [[WallClock sharedClock] setSpeed:newSpeed];
    [[WallClock sharedClock] setTimeShift:[self.datePicker.date timeIntervalSinceNow]];
    [self.delegate fluxCapacitorCompleted:self];
}

- (void)reset:(id)sender
{
    [[WallClock sharedClock] setSpeed:0];
    [[WallClock sharedClock] setTimeShift:0];
    [self.delegate fluxCapacitorCompleted:self];
}

@end
