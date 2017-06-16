//
//  DCMUpcomingViewController.m
//  DCM
//
//  Created by Benjamin Ragheb on 5/13/12.
//  Copyright (c) 2012 Upright Citizens Brigade LLC. All rights reserved.
//

#import "DCMUpcomingViewController.h"
#import "DCMDatabase.h"
#import "DCMShowDetailViewController.h"
#import "WallClock.h"
#import "DCMScheduleViewController.h"

@interface DCMUpcomingViewController ()

@end

@implementation DCMUpcomingViewController
{
    NSFetchedResultsController *performancesController;
    NSDate *lastRefreshDate;
}

@synthesize dateLabel;
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
    [self.tableView setScrollEnabled:NO];
    [self.tableView setContentOffset:CGPointZero];
    [self.tableView addSubview:self.countdownView];
}

- (void)viewDidLayoutSubviews
{
    CGRect frame = self.view.bounds;
    if ([self respondsToSelector:@selector(topLayoutGuide)]) {
        frame.origin.y += [[self topLayoutGuide] length];
        frame.size.height -= [[self topLayoutGuide] length];
    }
    if ([self respondsToSelector:@selector(bottomLayoutGuide)]) {
        frame.size.height -= [[self bottomLayoutGuide] length];
    }
    self.countdownView.frame = frame;
}

- (void)refreshCountdownViewWithDate:(NSDate *)nowDate
{
    // Add 60 seconds to the date interval so the countdown appears correctly.
    // (If it is 2:50 and we are counting down to 3:00, we'd expect to see 0:10,
    // but the calendar computation may round away a half-minute remaining. )
    NSDate *startDate = [[DCMDatabase sharedDatabase] marathonStartDate];
    NSDateComponents *dc = [[NSCalendar currentCalendar]
                            components:(NSCalendarUnitDay |
                                        NSCalendarUnitHour |
                                        NSCalendarUnitMinute)
                            fromDate:nowDate
                            toDate:[startDate dateByAddingTimeInterval:60]
                            options:0];
    if (! self.countdownView) {
        [self loadCountdownView];
    }
    self.countdownLabel.text = [NSString stringWithFormat:
                                @"%d days\n%d hours\n%d minutes",
                                (int)dc.day, (int)dc.hour, (int)dc.minute];
}

- (void)unloadCountdownView
{
    [self.tableView setScrollEnabled:YES];
    if (self.countdownView) {
        [UIView transitionWithView:self.view duration:1
                           options:UIViewAnimationOptionTransitionCurlUp
                        animations:^{
                            [self.countdownView removeFromSuperview];
                            self.countdownView = nil;
                            self.countdownLabel = nil;
                        } completion:^(BOOL finished) {
                            [self.tableView reloadData];
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
    [center addObserver:self selector:@selector(timeToRefresh:)
                   name:UIApplicationDidBecomeActiveNotification object:nil];
    [center addObserver:self selector:@selector(timeToRefresh:)
                   name:WallClockMinuteDidChangeNotification object:nil];

    [super awakeFromNib];
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

- (void)timeToRefresh:(NSNotification *)notification
{
    [self refresh];
}

- (void)updateDateButton
{
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"EEEE h:mm a"];
    NSString *dateString = [df stringFromDate:lastRefreshDate];
    self.dateLabel.text = dateString;
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
    NSDate *nowDate = [[WallClock sharedClock] date];
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

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

#pragma mark - Flux capacitor

- (void)fluxCapacitorCompleted:(FluxCapacitorViewController *)fluxCap
{
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
    Performance *perf = [performancesController objectAtIndexPath:indexPath];
    cell.textLabel.text = [DCMScheduleViewController
                           timeStringForPerformance:perf showFavorite:YES];
    cell.detailTextLabel.text = perf.show.name;
    return cell;
}

#pragma mark - Storyboard

- (IBAction)dontThink:(id)sender
{
    //[self performSegueWithIdentifier:@"GiveCredit" sender:sender];
}

- (IBAction)timeTravel:(id)sender
{
    [self performSegueWithIdentifier:@"TimeTravel" sender:sender];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"TimeTravel"]) {
        FluxCapacitorViewController *fluxCap = [segue destinationViewController];
        fluxCap.delegate = self;
    }
    else if ([[segue identifier] isEqualToString:@"ShowDetail"]) {
        DCMShowDetailViewController *detailViewController = [segue destinationViewController];
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        Performance *perf = [performancesController objectAtIndexPath:indexPath];
        detailViewController.show = perf.show;
    }
}

@end
