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

@synthesize dateButton;

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

- (void)updateDateButton
{
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"EEEE h:mm a"];
    NSString *dateString = [df stringFromDate:lastRefreshDate];
    [self.dateButton setTitle:dateString forState:UIControlStateNormal];
}

- (NSDictionary *)sectionIndexesBySectionName
{
    NSMutableDictionary *indexesByName = [NSMutableDictionary dictionary];
    for (id <NSFetchedResultsSectionInfo> sectionInfo in [performancesController sections]) {
        NSNumber *sectionIndex = [NSNumber numberWithInteger:[indexesByName count]];
        [indexesByName setObject:[sectionInfo name] forKey:sectionIndex];
    }
    return indexesByName;
}

- (NSDictionary *)indexPathsByObjectID
{
    NSMutableDictionary *pathsByID = [NSMutableDictionary dictionary];
    for (Performance *perf in [performancesController fetchedObjects]) {
        NSIndexPath *indexPath = [performancesController indexPathForObject:perf];
        [pathsByID setObject:indexPath forKey:perf.identifier];
    }
    return pathsByID;
}

- (void)refresh
{
    NSError *error = nil;
    NSFetchRequest *request = performancesController.fetchRequest;
    NSDate *nowDate = [NSDate dateWithTimeIntervalSinceNow:timeShift];
    NSDate *hourFromNowDate = [nowDate dateByAddingTimeInterval:3600];
    [request setPredicate:
     [NSPredicate predicateWithFormat:
      @"endDate >= %@ AND startDate <= %@",
      nowDate, hourFromNowDate]];
    NSDictionary *oldSectionIndexes = [self sectionIndexesBySectionName];
    NSDictionary *oldIndexPaths = [self indexPathsByObjectID];
    if (![performancesController performFetch:&error]) {
        NSLog(@"Error: %@", [error localizedDescription]);
    }
    lastRefreshDate = nowDate;
    if (timeShift != 0) {
        timeShift += 300;
    }
    [self updateDateButton];
    // If this is the first fetch, just reload
    if ([oldSectionIndexes count] == 0) {
        [self.tableView reloadData];
        return;
    }
    // Otherwise, do a ton of tedious work to make the changes animate nicely
    NSDictionary *newSectionIndexes = [self sectionIndexesBySectionName];
    if (![newSectionIndexes isEqualToDictionary:oldSectionIndexes]) {
        // If the section layout change, just reload.
        [self.tableView reloadData];
        return;
    }
    NSMutableArray *rowsToDelete = [NSMutableArray array];
    NSMutableArray *rowsToInsert = [NSMutableArray array];
    NSDictionary *newIndexPaths = [self indexPathsByObjectID];
    for (id key in oldIndexPaths) {
        if ([newIndexPaths objectForKey:key] == nil) {
            [rowsToDelete addObject:[oldIndexPaths objectForKey:key]];
        }
    }
    for (id key in newIndexPaths) {
        if ([oldIndexPaths objectForKey:key] == nil) {
            [rowsToInsert addObject:[newIndexPaths objectForKey:key]];
        }
    }
    if ([rowsToDelete count] || [rowsToInsert count]) {
        @try {
            [self.tableView beginUpdates];
            [self.tableView deleteRowsAtIndexPaths:rowsToDelete withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView insertRowsAtIndexPaths:rowsToInsert withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
        }
        @catch (NSException *exception) {
            if ([[exception name] isEqualToString:NSInternalInconsistencyException]) {
                NSLog(@"Animations failed (%@), reloading:\n%@", nowDate, [exception reason]);
                [self.tableView reloadData];
            } else {
                @throw;
            }
        }
    }
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
    [refreshTimer invalidate]; refreshTimer = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [refreshTimer invalidate];
    refreshTimer = [NSTimer
                    scheduledTimerWithTimeInterval:(timeShift == 0) ? 60 : 1
                    target:self selector:@selector(refreshTimerDidFire:)
                    userInfo:nil repeats:YES];
}

- (void)refreshTimerDidFire:(NSTimer *)timer
{
    [self refresh];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [refreshTimer invalidate]; refreshTimer = nil;
}

#pragma mark - Flux capacitor

- (void)fluxCapacitor:(FluxCapacitorViewController *)fluxCap didSelectTimeShift:(NSTimeInterval)shift
{
    timeShift = shift;
    [fluxCap dismissViewControllerAnimated:YES completion:^{
        [self refresh];
        [self.tableView reloadData];
    }];
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


#pragma mark - Storyboard

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"TimeTravel"]) {
        FluxCapacitorViewController *fluxCap = [segue destinationViewController];
        fluxCap.delegate = self;
        fluxCap.initialTimeShift = timeShift;
    } else {
        DCMShowDetailViewController *detailViewController = [segue destinationViewController];
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        Performance *perf = [performancesController objectAtIndexPath:indexPath];
        detailViewController.show = perf.show;
    }
}

@end
