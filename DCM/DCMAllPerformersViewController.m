//
//  DCMAllPerformersViewController.m
//  DCM
//
//  Created by Benjamin Ragheb on 6/7/15.
//  Copyright (c) 2015 Upright Citizens Brigade LLC. All rights reserved.
//

#import "DCMAllPerformersViewController.h"
#import "DCMDatabase.h"
#import "DCMPerformerScheduleViewController.h"

@implementation DCMAllPerformersViewController
{
    NSFetchedResultsController *_performersController;
}

- (void)setUpControllerForDatabase:(DCMDatabase *)database
{
    NSError *error = nil;

    NSFetchRequest *request = [[NSFetchRequest alloc]
                               initWithEntityName:@"Performer"];
    [request setSortDescriptors:[Performer standardSortDescriptors]];
    _performersController = [[NSFetchedResultsController alloc]
                             initWithFetchRequest:request
                             managedObjectContext:database.managedObjectContext
                             sectionNameKeyPath:[Performer sectionNameKeyPath]
                             cacheName:nil];
    _performersController.delegate = self;
    if (![_performersController performFetch:&error]) {
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
    _performersController = nil;
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

#pragma mark - Table view data source

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath inTableView:(UITableView *)tableView
{
    Performer *performer = [_performersController objectAtIndexPath:indexPath];
    cell.textLabel.attributedText = performer.attributedFullName;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[_performersController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)index
{
    NSArray *allSections = [_performersController sections];
    id <NSFetchedResultsSectionInfo> info = allSections[index];
    return [info numberOfObjects];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)index
{
    NSArray *allSections = [_performersController sections];
    id <NSFetchedResultsSectionInfo> info = allSections[index];
    return [info name];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return [_performersController sectionIndexTitles];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PerformerCell"];
    [self configureCell:cell atIndexPath:indexPath inTableView:tableView];
    return cell;
}

#pragma mark - Storyboard

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    DCMPerformerScheduleViewController *viewController = [segue destinationViewController];
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    viewController.performer = [_performersController objectAtIndexPath:indexPath];
}

@end
