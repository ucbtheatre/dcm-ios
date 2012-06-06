//
//  DCMAllShowsViewController.m
//  DCM
//
//  Created by Benjamin Ragheb on 5/12/12.
//  Copyright (c) 2012 Heroic Software Inc. All rights reserved.
//

#import "DCMAllShowsViewController.h"
#import "DCMDatabase.h"
#import "DCMShowDetailViewController.h"

@interface DCMAllShowsViewController ()

@end

@implementation DCMAllShowsViewController

- (void)setUpControllerForDatabase:(DCMDatabase *)database
{
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Show"];
    [request setSortDescriptors:
     [NSArray arrayWithObject:
      [NSSortDescriptor sortDescriptorWithKey:@"sortName" ascending:YES]]];
    showsController = [[NSFetchedResultsController alloc]
                       initWithFetchRequest:request
                       managedObjectContext:database.managedObjectContext
                       sectionNameKeyPath:@"sortSection"
                       cacheName:@"DCMAllShowsViewController"];
    NSError *error = nil;
    if (![showsController performFetch:&error]) {
        NSLog(@"Error: %@", [error localizedDescription]);
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
    showsController = nil;
    if ([self isViewLoaded]) {
        [self.tableView reloadData];
        [self.navigationController popToViewController:self animated:YES];
    }
}

- (void)databaseDidChange:(NSNotification *)notification
{
    [self setUpControllerForDatabase:[notification object]];
    if ([self isViewLoaded]) {
        [self.tableView reloadData];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setUpControllerForDatabase:[DCMDatabase sharedDatabase]];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    showsController = nil;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[showsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> info = [[showsController sections] objectAtIndex:section];
    return [info numberOfObjects];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> info = [[showsController sections] objectAtIndex:section];
    return [info name];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return [showsController sectionIndexTitles];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ShowCell"];
    
    // Configure the cell...
    Show *show = [showsController objectAtIndexPath:indexPath];
    cell.textLabel.text = show.name;
    
    return cell;
}

#pragma mark - Storyboard

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    DCMShowDetailViewController *detailViewController = [segue destinationViewController];
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    detailViewController.show = [showsController objectAtIndexPath:indexPath];
}

@end
