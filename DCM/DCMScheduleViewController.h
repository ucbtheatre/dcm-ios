//
//  DCMScheduleViewController.h
//  DCM
//
//  Created by Benjamin Ragheb on 6/3/12.
//  Copyright (c) 2012 Upright Citizens Brigade LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DCMTableViewController.h"

@class DCMDatabase;
@class Performance;

@interface DCMScheduleViewController : DCMTableViewController <NSFetchedResultsControllerDelegate>
{
    NSFetchedResultsController *performancesController;
    BOOL scrollOnNextAppearance;
}
+ (NSString *)timeStringForPerformance:(Performance *)perf showFavorite:(BOOL)showFav;
- (void)setUpControllerForDatabase:(DCMDatabase *)database;
@end

@interface DCMScheduleViewController (Abstract)
- (NSPredicate *)predicate;
- (void)configureCell:(UITableViewCell *)cell forPerformance:(Performance *)perf;
@end
