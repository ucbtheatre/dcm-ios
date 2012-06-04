//
//  DCMVenueScheduleViewController.h
//  DCM
//
//  Created by Benjamin Ragheb on 6/3/12.
//  Copyright (c) 2012 Heroic Software Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Venue;

@interface DCMVenueScheduleViewController : UITableViewController
{
    NSFetchedResultsController *performancesController;
    BOOL scrollOnNextAppearance;
}
@property (readonly, nonatomic) Venue *venue;
@end
