//
//  DCMAllVenuesViewController.m
//  DCM
//
//  Created by Benjamin Ragheb on 5/13/12.
//  Copyright (c) 2012 Heroic Software Inc. All rights reserved.
//

#import "DCMAllVenuesViewController.h"
#import "DCMDatabase.h"
#import "DCMVenueDetailViewController.h"

@interface DCMAllVenuesViewController ()

@end

@implementation DCMAllVenuesViewController

- (void)awakeFromNib
{
    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(databaseDidChange:)
     name:DCMDatabaseDidChangeNotification object:nil];
}

- (void)databaseDidChange:(NSNotification *)note
{
    NSError *error = nil;
    if (![venuesController performFetch:&error]) {
        NSLog(@"Error: %@", [error localizedDescription]);
    }
    if (note) {
        [self.tableView reloadData];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    DCMDatabase *database = [DCMDatabase sharedDatabase];
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Venue"];
    [request setSortDescriptors:
     [NSArray arrayWithObject:
      [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
    venuesController = [[NSFetchedResultsController alloc]
                        initWithFetchRequest:request
                        managedObjectContext:database.managedObjectContext
                        sectionNameKeyPath:nil
                        cacheName:nil];
    [self databaseDidChange:nil];
}

- (void)viewDidUnload
{
    venuesController = nil;
    [super viewDidUnload];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[venuesController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> info = [[venuesController sections] objectAtIndex:section];
    return [info numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"VenueCell"];
    Venue *venue = [venuesController objectAtIndexPath:indexPath];
    cell.textLabel.text = venue.name;
    return cell;
}

#pragma mark - Storyboard

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    DCMVenueDetailViewController *detailViewController = [segue destinationViewController];
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    detailViewController.venue = [venuesController objectAtIndexPath:indexPath];
}

@end
