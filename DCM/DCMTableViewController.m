//
//  DCMTableViewController.m
//  DCM
//
//  Created by Benjamin Ragheb on 6/12/12.
//  Copyright (c) 2012 Heroic Software Inc. All rights reserved.
//

#import "DCMTableViewController.h"

@implementation DCMTableViewController

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
        headerView.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:0.8f];
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

@end
