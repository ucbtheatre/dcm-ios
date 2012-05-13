//
//  DCMUpcomingViewController.m
//  DCM
//
//  Created by Benjamin Ragheb on 5/13/12.
//  Copyright (c) 2012 Heroic Software Inc. All rights reserved.
//

#import "DCMUpcomingViewController.h"
#import "DCMDatabase.h"
#import "DCMShowDetailViewController.h"

@interface DCMUpcomingViewController ()

@end

@implementation DCMUpcomingViewController

- (void)awakeFromNib
{
    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(databaseDidChange:)
     name:DCMDatabaseDidChangeNotification object:nil];
}

- (void)databaseDidChange:(NSNotification *)note
{
    [self refresh];
}

- (void)refresh
{
    NSError *error = nil;
    NSFetchRequest *request = performancesController.fetchRequest;
    NSDate *nowDate = [NSDate date];
    NSDate *hourFromNowDate = [nowDate dateByAddingTimeInterval:3600];
    [request setPredicate:
     [NSPredicate predicateWithFormat:
      @"endDate BETWEEN {%@,%@} OR startDate BETWEEN {%@,%@}",
      nowDate, hourFromNowDate, nowDate, hourFromNowDate]];
    if (![performancesController performFetch:&error]) {
        NSLog(@"Error: %@", [error localizedDescription]);
    }
    [self.tableView reloadData];
    lastRefreshDate = nowDate;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    DCMDatabase *database = [DCMDatabase sharedDatabase];
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Performance"];
    [request setSortDescriptors:
     [NSArray arrayWithObjects:
      [NSSortDescriptor sortDescriptorWithKey:@"venue.name" ascending:YES],
      [NSSortDescriptor sortDescriptorWithKey:@"startDate" ascending:YES],
      nil]];
    performancesController = [[NSFetchedResultsController alloc]
                              initWithFetchRequest:request
                              managedObjectContext:database.managedObjectContext
                              sectionNameKeyPath:@"venue.name"
                              cacheName:nil];
    [self refresh];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    performancesController = nil;
}

- (Performance *)performanceAtIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *path = [NSIndexPath indexPathForRow:indexPath.row
                                           inSection:(indexPath.section - 1)];
    return [performancesController objectAtIndexPath:path];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1 + [[performancesController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) return 1;
    id <NSFetchedResultsSectionInfo> info;
    info = [[performancesController sections] objectAtIndex:(section - 1)];
    return [info numberOfObjects];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0) return nil;
    id <NSFetchedResultsSectionInfo> info;
    info = [[performancesController sections] objectAtIndex:(section - 1)];
    return [info name];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TimeCell"];
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        [df setDateStyle:NSDateFormatterShortStyle];
        [df setTimeStyle:NSDateFormatterShortStyle];
        cell.textLabel.text = [df stringFromDate:lastRefreshDate];
        return cell;
    } else {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PerformanceCell"];
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"h:mma"];
        Performance *perf = [self performanceAtIndexPath:indexPath];
        cell.textLabel.text = [df stringFromDate:perf.startDate];    
        cell.detailTextLabel.text = perf.show.name;
        return cell;
    }
}

#pragma mark - Table view delegate

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    DCMShowDetailViewController *detailViewController = [segue destinationViewController];
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    Performance *perf = [self performanceAtIndexPath:indexPath];
    detailViewController.show = perf.show;
}

@end
