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
}
@property (nonatomic,strong) IBOutlet UIButton *dateButton;
@property (nonatomic,strong) IBOutlet UIView *countdownView;
@property (nonatomic,strong) IBOutlet UILabel *countdownLabel;
- (IBAction)dontThink:(id)sender;
@end
