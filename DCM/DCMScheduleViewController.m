//
//  DCMScheduleViewController.m
//  DCM
//
//  Created by Benjamin Ragheb on 6/3/12.
//  Copyright (c) 2012 Heroic Software Inc. All rights reserved.
//

#import "DCMScheduleViewController.h"
#import "DCMDatabase.h"
#import "DCMAppDelegate.h"
#import "DCMShowDetailViewController.h"

@implementation DCMScheduleViewController

- (void)setUpControllerForDatabase:(DCMDatabase *)database
{
    NSFetchRequest *request = [[NSFetchRequest alloc]
                               initWithEntityName:@"Performance"];
    [request setPredicate:[self predicate]];
    [request setSortDescriptors:
     [NSArray arrayWithObject:
      [NSSortDescriptor sortDescriptorWithKey:@"startDate" ascending:YES]]];
    performancesController = [[NSFetchedResultsController alloc]
                              initWithFetchRequest:request
                              managedObjectContext:database.managedObjectContext
                              sectionNameKeyPath:@"weekday"
                              cacheName:nil];
    performancesController.delegate = self;
    NSError *error = nil;
    if (![performancesController performFetch:&error]) {
        NSLog(@"Error: %@", [error localizedDescription]);
    }
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
    performancesController = nil;
}

- (void)scrollToCurrentShowAnimated:(BOOL)animated
{
    NSDate *date = [DCMAppDelegate currentDate];
    NSArray *perfArray = [performancesController fetchedObjects];
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
        path = [performancesController indexPathForObject:
                [perfArray objectAtIndex:idx]];
    } else {
        path = [performancesController indexPathForObject:
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
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (void)configureCell:(UITableViewCell *)cell forPerformance:(Performance *)perf
{
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"h:mm a"];
    cell.textLabel.text = [df stringFromDate:perf.startDate];    
    cell.detailTextLabel.text = perf.show.name;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    Performance *perf = [performancesController objectAtIndexPath:indexPath];
    [self configureCell:cell forPerformance:perf];
}

#pragma mark - Storyboard

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    DCMShowDetailViewController *detailViewController = [segue destinationViewController];
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    Performance *perf = [performancesController objectAtIndexPath:indexPath];
    detailViewController.show = perf.show;
}

#pragma mark - NSFetchResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{    
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                          withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                          withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableView = self.tableView;
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
                    atIndexPath:indexPath];
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
    [self.tableView endUpdates];
}

@end
