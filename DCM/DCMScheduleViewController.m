//
//  DCMScheduleViewController.m
//  DCM
//
//  Created by Benjamin Ragheb on 6/3/12.
//  Copyright (c) 2012 Upright Citizens Brigade LLC. All rights reserved.
//

#import "DCMScheduleViewController.h"
#import "DCMDatabase.h"
#import "WallClock.h"
#import "DCMShowDetailViewController.h"

@implementation DCMScheduleViewController
{
    BOOL scrollOnNextAppearance;
}

+ (NSString *)timeStringForPerformance:(Performance *)perf showFavorite:(BOOL)showFav
{
    // Unicode "HEAVY BLACK HEART"
    static NSString * const kHeartPrefix = @"\xE2\x9D\xA4 ";

    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"h:mm a"];
    NSString *timeString = [df stringFromDate:perf.startDate];
    if (showFav && perf.favorite) {
        return [kHeartPrefix stringByAppendingString:timeString];
    } else {
        return timeString;
    }
}

- (void)setUpControllerForDatabase:(DCMDatabase *)database
{
    NSFetchRequest *request = [[NSFetchRequest alloc]
                               initWithEntityName:@"Performance"];
    [request setPredicate:[self predicate]];
    [request setSortDescriptors:
     [NSArray arrayWithObject:
      [NSSortDescriptor sortDescriptorWithKey:@"startDate" ascending:YES]]];
    _performancesController = [[NSFetchedResultsController alloc]
                              initWithFetchRequest:request
                              managedObjectContext:database.managedObjectContext
                              sectionNameKeyPath:@"weekday"
                              cacheName:nil];
    _performancesController.delegate = self;
    NSError *error = nil;
    if (![_performancesController performFetch:&error]) {
        NSLog(@"Error: %@", [error localizedDescription]);
    }
}

- (Performance *)performanceAtIndexPath:(NSIndexPath *)indexPath
{
    return [_performancesController objectAtIndexPath:indexPath];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setUpControllerForDatabase:[DCMDatabase sharedDatabase]];
    scrollOnNextAppearance = YES;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    _performancesController = nil;
}

- (void)scrollToCurrentShowAnimated:(BOOL)animated
{
    NSDate *date = [[WallClock sharedClock] date];
    NSArray *perfArray = [_performancesController fetchedObjects];
    NSUInteger idx = [perfArray
                      indexOfObject:date
                      inSortedRange:NSMakeRange(0, [perfArray count])
                      options:NSBinarySearchingInsertionIndex
                      usingComparator:^NSComparisonResult(id obj1, id obj2) {
                          NSDate *date1;
                          if ([obj1 isKindOfClass:[NSDate class]]) {
                              date1 = obj1;
                          } else {
                              date1 = [obj1 startDate];
                          }
                          NSDate *date2;
                          if ([obj2 isKindOfClass:[NSDate class]]) {
                              date2 = obj2;
                          } else {
                              date2 = [obj2 startDate];
                          }
                          return [date1 compare:date2];
                      }];
    if (idx == 0) return; // don't do anything if first show hasn't happened yet
    NSIndexPath *path;
    if (idx < [perfArray count]) {
        path = [_performancesController indexPathForObject:
                [perfArray objectAtIndex:idx]];
    } else {
        path = [_performancesController indexPathForObject:
                [perfArray lastObject]];
    }
    [self.tableView scrollToRowAtIndexPath:path
                          atScrollPosition:UITableViewScrollPositionMiddle
                                  animated:animated];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (scrollOnNextAppearance) {
        [self scrollToCurrentShowAnimated:NO];
        scrollOnNextAppearance = NO;
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[_performancesController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> info;
    info = [[_performancesController sections] objectAtIndex:section];
    return [info numberOfObjects];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> info;
    info = [[_performancesController sections] objectAtIndex:section];
    return [info name];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PerformanceCell"];
    [self configureCell:cell atIndexPath:indexPath inTableView:tableView];
    return cell;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath inTableView:(UITableView *)tableView
{
    Performance *perf = [_performancesController objectAtIndexPath:indexPath];
    [self configureCell:cell forPerformance:perf];
}

#pragma mark - Storyboard

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    DCMShowDetailViewController *detailViewController = [segue destinationViewController];
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    Performance *perf = [_performancesController objectAtIndexPath:indexPath];
    detailViewController.show = perf.show;
}

@end
