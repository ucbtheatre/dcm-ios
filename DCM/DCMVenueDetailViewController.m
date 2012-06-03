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
#import "DCMAppDelegate.h"

@interface DCMVenueDetailViewController ()

@end

@implementation DCMVenueDetailViewController

@synthesize venue;
@synthesize nameLabel;
@synthesize addressLabel;
@synthesize directionsLabel;
@synthesize websiteButton;
@synthesize mapButton;

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = self.venue.name;
    self.nameLabel.text = self.venue.name;
    self.addressLabel.text = self.venue.address;
    self.directionsLabel.text = self.venue.directions;
    self.websiteButton.enabled = [self.venue.homeURLString length] > 0;
    self.mapButton.enabled = [self.venue.mapURLString length] > 0;
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
    scrollOnNextAppearance = YES;
}

- (void)viewDidUnload
{
    [self setAddressLabel:nil];
    [self setDirectionsLabel:nil];
    [self setWebsiteButton:nil];
    [self setMapButton:nil];
    [self setNameLabel:nil];
    [super viewDidUnload];
    performancesController = nil;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (scrollOnNextAppearance) {
        [self scrollToCurrentShow:nil];
        scrollOnNextAppearance = NO;
    }
}

- (IBAction)scrollToCurrentShow:(id)sender
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
    [UIView animateWithDuration:0.2 animations:^{
        [self.tableView selectRowAtIndexPath:path animated:NO
                              scrollPosition:UITableViewScrollPositionMiddle];
    } completion:^(BOOL finished) {
        [self.tableView deselectRowAtIndexPath:path animated:YES];
    }];
}

- (IBAction)openWebsite:(id)sender
{
    [[UIApplication sharedApplication]
     openURL:[NSURL URLWithString:self.venue.homeURLString]];
}

- (IBAction)openMap:(id)sender
{
    [[UIApplication sharedApplication]
     openURL:[NSURL URLWithString:self.venue.mapURLString]];
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
    DCMShowDetailViewController *detailViewController = [segue destinationViewController];
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    Performance *perf = [performancesController objectAtIndexPath:indexPath];
    detailViewController.show = perf.show;
}

@end
