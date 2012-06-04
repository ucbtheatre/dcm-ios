//
//  DCMVenueScheduleViewController.m
//  DCM
//
//  Created by Benjamin Ragheb on 6/3/12.
//  Copyright (c) 2012 Heroic Software Inc. All rights reserved.
//

#import "DCMVenueViewController.h"
#import "DCMVenueScheduleViewController.h"
#import "DCMDatabase.h"
#import "DCMAppDelegate.h"
#import "DCMShowDetailViewController.h"

@interface DCMVenueScheduleViewController ()

@end

@implementation DCMVenueScheduleViewController

- (Venue *)venue
{
    DCMVenueViewController *parent = (DCMVenueViewController *)self.parentViewController;
    return parent.venue;
}

- (NSPredicate *)predicate
{
    return [NSPredicate predicateWithFormat:@"venue = %@", self.venue];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = self.venue.name;
}

- (void)configureCell:(UITableViewCell *)cell forPerformance:(Performance *)perf
{
    [super configureCell:cell forPerformance:perf];
    if (perf.favorite) {
        // Unicode "HEAVY BLACK HEART"
        cell.textLabel.text = [@"\xE2\x9D\xA4 " stringByAppendingString:
                               cell.textLabel.text];
    }
}

@end