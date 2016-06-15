//
//  DCMVenuesListViewController.m
//  DCM
//
//  Created by Benjamin Ragheb on 6/3/15.
//  Copyright (c) 2015 Upright Citizens Brigade LLC. All rights reserved.
//

#import "DCMVenuesListViewController.h"
#import "Venue.h"
#import "DCMVenueScheduleViewController.h"

@interface DCMVenuesListViewController ()

@end

@implementation DCMVenuesListViewController


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.venueList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"VenueCell" forIndexPath:indexPath];

    Venue *venue = [self.venueList objectAtIndex:indexPath.row];
    cell.textLabel.text = venue.name;

    return cell;
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    DCMVenueScheduleViewController *viewController = [segue destinationViewController];
    viewController.venue = [self.venueList objectAtIndex:indexPath.row];
}

@end
