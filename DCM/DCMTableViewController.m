//
//  DCMTableViewController.m
//  DCM
//
//  Created by Benjamin Ragheb on 6/12/12.
//  Copyright (c) 2012 Upright Citizens Brigade LLC. All rights reserved.
//

#import "DCMTableViewController.h"

@implementation DCMTableViewController

- (void)enableDoubleTapRecognizer
{
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    tapRecognizer.numberOfTapsRequired = 2;
    tapRecognizer.numberOfTouchesRequired = 1;
    tapRecognizer.delaysTouchesBegan = YES;
    tapRecognizer.delaysTouchesEnded = YES;
    tapRecognizer.cancelsTouchesInView = YES;
    [self.tableView addGestureRecognizer:tapRecognizer];
}

- (void)handleDoubleTap:(UITapGestureRecognizer *)tapRecognizer
{
    CGPoint p = [tapRecognizer locationInView:self.tableView];
    NSIndexPath *path = [self.tableView indexPathForRowAtPoint:p];
    if (path) {
        [self tableCellDoubleTappedAtIndexPath:path];
    }
}

#pragma mark - Table view delegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *headerView;
    if (sectionHeaderViews == nil) {
        sectionHeaderViews = [[NSMutableArray alloc] initWithCapacity:8];
    } else {
        for (UIView *view in sectionHeaderViews) {
            if ([view superview] == nil) {
                headerView = view;
                break;
            }
        }
    }
    if (headerView == nil) {
        CGRect frame = CGRectMake(0, 0, 320, tableView.sectionHeaderHeight);
        headerView = [[UIView alloc] initWithFrame:frame];
        headerView.backgroundColor = [UIColor colorWithRed:0.8f
                                                     green:0.2f
                                                      blue:0.2f
                                                     alpha:0.8f];
        headerView.opaque = NO;
        headerView.autoresizesSubviews = YES;
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectInset(frame, 10, 0)];
        label.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                  UIViewAutoresizingFlexibleHeight);
        label.font = [UIFont boldSystemFontOfSize:15];
        label.textColor = [UIColor whiteColor];
        label.shadowColor = [UIColor grayColor];
        label.shadowOffset = CGSizeMake(0, -1);
        label.backgroundColor = [UIColor clearColor];
        label.opaque = NO;
        [headerView addSubview:label];
        [sectionHeaderViews addObject:headerView];
    }
    UILabel *label = [[headerView subviews] lastObject];
    label.text = [tableView.dataSource tableView:tableView titleForHeaderInSection:section];
    return headerView;
}

#pragma mark - NSFetchResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                          withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                          withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableView = self.tableView;
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath]
                    atIndexPath:indexPath];
            break;
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}

@end
