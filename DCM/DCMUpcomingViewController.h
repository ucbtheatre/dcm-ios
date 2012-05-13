//
//  DCMUpcomingViewController.h
//  DCM
//
//  Created by Benjamin Ragheb on 5/13/12.
//  Copyright (c) 2012 Heroic Software Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DCMUpcomingViewController : UITableViewController
{
    NSFetchedResultsController *performancesController;
    NSDate *lastRefreshDate;
}
@end
