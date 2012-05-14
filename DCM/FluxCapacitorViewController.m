//
//  FluxCapacitorViewController.m
//  DCM
//
//  Created by Benjamin Ragheb on 5/13/12.
//  Copyright (c) 2012 Heroic Software Inc. All rights reserved.
//

#import "FluxCapacitorViewController.h"

@interface FluxCapacitorViewController ()

@end

@implementation FluxCapacitorViewController

@synthesize delegate;
@synthesize initialTimeShift;
@synthesize datePicker;

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.datePicker.date = [NSDate dateWithTimeIntervalSinceNow:self.initialTimeShift];
}

- (void)dcm13:(id)sender
{
    self.datePicker.date = [NSDate dateWithTimeIntervalSince1970:1313181000];
}

- (void)confirm:(id)sender
{
    NSTimeInterval timeShift = [self.datePicker.date timeIntervalSinceNow];
    [self.delegate fluxCapacitor:self
              didSelectTimeShift:timeShift];
}

- (void)reset:(id)sender
{
    [self.delegate fluxCapacitor:self
              didSelectTimeShift:0];
}

@end
