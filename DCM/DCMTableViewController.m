//
//  DCMTableViewController.m
//  DCM
//
//  Created by Benjamin Ragheb on 6/12/12.
//  Copyright (c) 2012 Upright Citizens Brigade LLC. All rights reserved.
//

#import "DCMTableViewController.h"
#import "DCMTableSectionHeaderView.h"

@implementation DCMTableViewController
{
    NSMutableArray<DCMTableSectionHeaderView *> *sectionHeaderViews;
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

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    NSString *title = [tableView.dataSource tableView:tableView titleForHeaderInSection:section];
    if (title == nil) {
        return 0;
    } else {
        return tableView.sectionHeaderHeight;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSString *title = [tableView.dataSource tableView:tableView titleForHeaderInSection:section];

    if (title == nil) {
        return nil;
    }

    DCMTableSectionHeaderView *headerView;

    if (sectionHeaderViews == nil) {
        sectionHeaderViews = [[NSMutableArray alloc] initWithCapacity:8];
    } else {
        for (DCMTableSectionHeaderView *view in sectionHeaderViews) {
            if ([view superview] == nil) {
                headerView = view;
                break;
            }
        }
    }

    if (headerView == nil) {
        CGRect frame = CGRectMake(0, 0, 320, tableView.sectionHeaderHeight);

        headerView = [[DCMTableSectionHeaderView alloc] initWithFrame:frame];

        [sectionHeaderViews addObject:headerView];
    }

    headerView.title = title;

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
        default:
            NSLog(@"NSFetchedResultsController broke the rules!");
            return;
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
