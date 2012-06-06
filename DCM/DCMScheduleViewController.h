//
//  DCMScheduleViewController.h
//  DCM
//
//  Created by Benjamin Ragheb on 6/3/12.
//  Copyright (c) 2012 Heroic Software Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DCMDatabase;
@class Performance;

@interface DCMScheduleViewController : UITableViewController <NSFetchedResultsControllerDelegate>
{
    NSFetchedResultsController *performancesController;
    BOOL scrollOnNextAppearance;
}
- (void)setUpControllerForDatabase:(DCMDatabase *)database;
- (void)configureCell:(UITableViewCell *)cell forPerformance:(Performance *)perf;
@end

@interface DCMScheduleViewController (Abstract)
- (NSPredicate *)predicate;
@end
