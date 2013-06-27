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
- (void)enableDoubleTapRecognizerOnTableView:(UITableView *)tableView;
@end

@interface DCMTableViewController (Abstract)
- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath inTableView:(UITableView *)tableView;
- (void)tableView:(UITableView *)tableView cellDoubleTappedAtIndexPath:(NSIndexPath *)indexPath;
- (UITableView *)tableViewForFetchedResultsController:(NSFetchedResultsController *)controller;
@end