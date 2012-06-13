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
#import "DCMAppDelegate.h"

@interface DCMUpcomingViewController ()

@end

@implementation DCMUpcomingViewController

@synthesize dateButton;
@synthesize countdownView;
@synthesize countdownLabel;

- (void)setUpControllerForDatabase:(DCMDatabase *)database
{
    NSFetchRequest *request = [[NSFetchRequest alloc]
                               initWithEntityName:@"Performance"];
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
}

- (void)loadCountdownView
{
    [[UINib nibWithNibName:@"CountdownView" bundle:nil]
     instantiateWithOwner:self options:nil];
    self.countdownView.frame = self.view.bounds;
    [self.view addSubview:self.countdownView];
    [self.tableView setScrollEnabled:NO];
}

- (void)refreshCountdownViewWithDate:(NSDate *)nowDate
{
    NSDate *startDate = [[DCMDatabase sharedDatabase] marathonStartDate];
    NSDateComponents *dc = [[NSCalendar currentCalendar]
                            components:(NSDayCalendarUnit |
                                        NSHourCalendarUnit |
                                        NSMinuteCalendarUnit)
                            fromDate:nowDate
                            toDate:startDate
                            options:0];
    if (! self.countdownView) {
        [self loadCountdownView];
    }
    self.countdownLabel.text = [NSString stringWithFormat:
                                @"%d days %d hours %d minutes",
                                dc.day, dc.hour, dc.minute];
}

- (void)unloadCountdownView
{
    if (self.countdownView) {
        [UIView transitionWithView:self.view duration:1
                           options:UIViewAnimationOptionTransitionCurlUp
                        animations:^{
                            [self.countdownView removeFromSuperview];
                            self.countdownView = nil;
                            self.countdownLabel = nil;
                        } completion:^(BOOL finished) {
                            [self.tableView setScrollEnabled:YES];
                        }];
    }
}

- (void)awakeFromNib
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(databaseWillChange:)
                   name:DCMDatabaseWillChangeNotification object:nil];
    [center addObserver:self selector:@selector(databaseDidChange:)
                   name:DCMDatabaseDidChangeNotification object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)databaseWillChange:(NSNotification *)notification
{
    performancesController = nil;
    if ([self isViewLoaded]) {
        [self.tableView reloadData];
        [self.navigationController popToViewController:self animated:YES];
    }
}

- (void)databaseDidChange:(NSNotification *)notification
{
    [self setUpControllerForDatabase:[notification object]];
    if ([self isViewLoaded]) {
        [self refresh];
    }
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
    DCMAppDelegate *ad = [DCMAppDelegate sharedDelegate];
    NSError *error = nil;
    NSDate *nowDate = [NSDate dateWithTimeIntervalSinceNow:ad.timeShift];
    NSDate *hourFromNowDate = [nowDate dateByAddingTimeInterval:3600];
    NSDate *startDate = [[DCMDatabase sharedDatabase] marathonStartDate];
    if ([startDate timeIntervalSinceDate:hourFromNowDate] > 0) {
        [self refreshCountdownViewWithDate:nowDate];
    } else {
        [self unloadCountdownView];
    }
    NSFetchRequest *request = performancesController.fetchRequest;
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
    if (ad.timeShift != 0) {
        ad.timeShift += 300;
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
    [self setUpControllerForDatabase:[DCMDatabase sharedDatabase]];
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
    DCMAppDelegate *ad = [DCMAppDelegate sharedDelegate];
    [super viewWillAppear:animated];
    [refreshTimer invalidate];
    refreshTimer = [NSTimer
                    scheduledTimerWithTimeInterval:(ad.timeShift == 0) ? 60 : 1
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
    DCMAppDelegate *ad = [DCMAppDelegate sharedDelegate];
    ad.timeShift = shift;
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
        DCMAppDelegate *ad = [DCMAppDelegate sharedDelegate];
        FluxCapacitorViewController *fluxCap = [segue destinationViewController];
        fluxCap.delegate = self;
        fluxCap.initialTimeShift = ad.timeShift;
    } else {
        DCMShowDetailViewController *detailViewController = [segue destinationViewController];
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        Performance *perf = [performancesController objectAtIndexPath:indexPath];
        detailViewController.show = perf.show;
    }
}

@end
