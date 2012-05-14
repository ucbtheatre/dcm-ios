//
//  DCMUpcomingViewController.h
//  DCM
//
//  Created by Benjamin Ragheb on 5/13/12.
//  Copyright (c) 2012 Heroic Software Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FluxCapacitorViewController.h"

@interface DCMUpcomingViewController : UITableViewController <FluxCapacitorDelegate>
{
    NSFetchedResultsController *performancesController;
    NSDate *lastRefreshDate;
    NSTimeInterval timeShift;
    NSTimer *refreshTimer;
}
@end
