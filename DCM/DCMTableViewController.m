//
//  DCMTableViewController.m
//  DCM
//
//  Created by Benjamin Ragheb on 6/12/12.
//  Copyright (c) 2012 Upright Citizens Brigade LLC. All rights reserved.
//

#import "DCMTableViewController.h"

@implementation DCMTableViewController
{
    NSMutableArray *sectionHeaderViews;
}

- (void)enableLongPressRecognizerOnTableView:(UITableView *)tableView
{
    [tableView addGestureRecognizer:[[UILongPressGestureRecognizer alloc]
                                     initWithTarget:self
                                     action:@selector(handleLongPress:)]];
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)pressRecognizer
{
    if (pressRecognizer.state == UIGestureRecognizerStateBegan) {
        UITableView *view = (UITableView *)pressRecognizer.view;
        CGPoint p = [pressRecognizer locationInView:view];
        NSIndexPath *path = [view indexPathForRowAtPoint:p];
        if (path) {
            [self tableView:view cellLongPressedAtIndexPath:path];
        }
    }
}

- (UITableView *)tableViewForFetchedResultsController:(NSFetchedResultsController *)controller
{
    return self.tableView;
}

#pragma mark - Table view delegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSString *title = [tableView.dataSource tableView:tableView titleForHeaderInSection:section];
    if (title == nil) {
        return nil;
    }
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
        if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
            label.shadowColor = [UIColor grayColor];
            label.shadowOffset = CGSizeMake(0, -1);
        }
        label.backgroundColor = [UIColor clearColor];
        label.opaque = NO;
        [headerView addSubview:label];
        [sectionHeaderViews addObject:headerView];
    }
    UILabel *label = [[headerView subviews] lastObject];
    label.text = title;
    return headerView;
}

#pragma mark - NSFetchResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [[self tableViewForFetchedResultsController:controller] beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    UITableView *tableView = [self tableViewForFetchedResultsController:controller];
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                     withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeDelete:
            [tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                     withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableView = [self tableViewForFetchedResultsController:controller];
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
                    atIndexPath:indexPath inTableView:tableView];
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
    [[self tableViewForFetchedResultsController:controller] endUpdates];
}

@end
