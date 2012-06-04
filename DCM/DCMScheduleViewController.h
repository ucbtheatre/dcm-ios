//
//  DCMScheduleViewController.h
//  DCM
//
//  Created by Benjamin Ragheb on 6/3/12.
//  Copyright (c) 2012 Heroic Software Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DCMScheduleViewController : UITableViewController <NSFetchedResultsControllerDelegate>
{
    NSFetchedResultsController *performancesController;
    BOOL scrollOnNextAppearance;
}
@end

@interface DCMScheduleViewController (Abstract)
- (NSPredicate *)predicate;
@end
