//
//  DCMVenueDetailViewController.m
//  DCM
//
//  Created by Benjamin Ragheb on 5/13/12.
//  Copyright (c) 2012 Heroic Software Inc. All rights reserved.
//

#import "DCMVenueDetailViewController.h"
#import "DCMShowDetailViewController.h"
#import "DCMDatabase.h"

@interface DCMVenueDetailViewController ()

@end

@implementation DCMVenueDetailViewController

@synthesize venue;

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = self.venue.name;
    DCMDatabase *database = [DCMDatabase sharedDatabase];
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Performance"];
    [request setPredicate:
     [NSPredicate predicateWithFormat:@"venue = %@", self.venue]];
    [request setSortDescriptors:
     [NSArray arrayWithObject:
      [NSSortDescriptor sortDescriptorWithKey:@"startDate" ascending:YES]]];
    performancesController = [[NSFetchedResultsController alloc]
                              initWithFetchRequest:request
                              managedObjectContext:database.managedObjectContext
                              sectionNameKeyPath:@"weekday"
                              cacheName:nil];
    NSError *error = nil;
    if (![performancesController performFetch:&error]) {
        NSLog(@"Error: %@", [error localizedDescription]);
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    performancesController = nil;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[performancesController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> info;
    info = [[performancesController sections] objectAtIndex:section];
    return [info numberOfObjects];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> info;
    info = [[performancesController sections] objectAtIndex:section];
    return [info name];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PerformanceCell"];
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"h:mm a"];
    Performance *perf = [performancesController objectAtIndexPath:indexPath];
    cell.textLabel.text = [df stringFromDate:perf.startDate];    
    cell.detailTextLabel.text = perf.show.name;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Performance *perf = [performancesController objectAtIndexPath:indexPath];
    return 30.0f + ([perf.minutes floatValue] * (5.0f / 15.0f));
}

#pragma mark - Storyboard

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    DCMShowDetailViewController *detailViewController = [segue destinationViewController];
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    Performance *perf = [performancesController objectAtIndexPath:indexPath];
    detailViewController.show = perf.show;
}

@end
