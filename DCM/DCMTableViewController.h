//
//  DCMTableViewController.h
//  DCM
//
//  Created by Benjamin Ragheb on 6/12/12.
//  Copyright (c) 2012 Upright Citizens Brigade LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DCMTableViewController : UITableViewController <NSFetchedResultsControllerDelegate>
{
    NSMutableArray *sectionHeaderViews;
}
- (void)enableDoubleTapRecognizer;
@end

@interface DCMTableViewController (Abstract)
- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
- (void)tableCellDoubleTappedAtIndexPath:(NSIndexPath *)indexPath;
@end