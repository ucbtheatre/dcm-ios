//
//  DCMAllShowsViewController.m
//  DCM
//
//  Created by Benjamin Ragheb on 5/12/12.
//  Copyright (c) 2012 Upright Citizens Brigade LLC. All rights reserved.
//

#import "DCMAllShowsViewController.h"
#import "DCMDatabase.h"
#import "DCMShowDetailViewController.h"
#import "DCMAppDelegate.h"

@implementation DCMAllShowsViewController
{
    NSFetchedResultsController *showsController;
    NSFetchedResultsController *searchController;
}

- (void)setUpControllerForDatabase:(DCMDatabase *)database
{
    NSError *error = nil;
    NSSortDescriptor *sortDesc = [NSSortDescriptor sortDescriptorWithKey:@"sortName" ascending:YES];
    
    NSFetchRequest *showsRequest = [[NSFetchRequest alloc] initWithEntityName:@"Show"];
    [showsRequest setSortDescriptors:@[sortDesc]];
    showsController = [[NSFetchedResultsController alloc]
                       initWithFetchRequest:showsRequest
                       managedObjectContext:database.managedObjectContext
                       sectionNameKeyPath:@"sortSection"
                       cacheName:nil];
    showsController.delegate = self;
    if (![showsController performFetch:&error]) {
        NSLog(@"Error: %@", [error localizedDescription]);
    }
    
    NSFetchRequest *searchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Show"];
    [searchRequest setSortDescriptors:@[sortDesc]];
    searchController = [[NSFetchedResultsController alloc]
                        initWithFetchRequest:searchRequest
                        managedObjectContext:database.managedObjectContext
                        sectionNameKeyPath:nil
                        cacheName:nil];
    searchController.delegate = self;
    if (![searchController performFetch:&error]) {
        NSLog(@"Error: %@", [error localizedDescription]);
    }
}

- (UITableView *)tableViewForFetchedResultsController:(NSFetchedResultsController *)controller
{
    if (controller == showsController) {
        return self.tableView;
    }
    if (controller == searchController) {
        return self.searchDisplayController.searchResultsTableView;
    }
    NSAssert(NO, @"Unfamiliar Search Controller");
    return nil;
}

- (NSFetchedResultsController *)fetchedResultsControllerForTableView:(UITableView *)tableView
{
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return searchController;
    }
    if (tableView == self.tableView) {
        return showsController;
    }
    NSAssert(NO, @"Unfamiliar Table View");
    return nil;
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
    searchController = nil;
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
    [self enableDoubleTapRecognizerOnTableView:self.tableView];
    [self setUpControllerForDatabase:[DCMDatabase sharedDatabase]];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    showsController = nil;
    searchController = nil;
}

- (IBAction)refresh:(id)sender
{
    [[DCMDatabase sharedDatabase] checkForUpdate];
}

- (void)tableView:(UITableView *)tableView cellDoubleTappedAtIndexPath:(NSIndexPath *)indexPath
{
    NSFetchedResultsController *controller = [self fetchedResultsControllerForTableView:tableView];
    Show *show = [controller objectAtIndexPath:indexPath];
    NSError *error = nil;
    if ( ! [show toggleFavoriteAndSave:&error]) {
        UIAlertView *alert = [[UIAlertView alloc] init];
        [alert setTitle:@"Unexpected Error"];
        [alert setMessage:[error debugDescription]];
        [alert addButtonWithTitle:@"Dismiss"];
        [alert show];
    }
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath inTableView:(UITableView *)tableView
{
    // Unicode "HEAVY BLACK HEART"
    static NSString * const kHeartSuffix = @" \xE2\x9D\xA4";
    
    NSFetchedResultsController *controller = [self fetchedResultsControllerForTableView:tableView];
    Show *show = [controller objectAtIndexPath:indexPath];
    NSString *title;
    if ([show isFavorite]) {
        title = [show.name stringByAppendingString:kHeartSuffix];
    } else {
        title = show.name;
    }
    cell.textLabel.text = title;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSFetchedResultsController *controller = [self fetchedResultsControllerForTableView:tableView];
    return [[controller sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSFetchedResultsController *controller = [self fetchedResultsControllerForTableView:tableView];
    id <NSFetchedResultsSectionInfo> info = [[controller sections] objectAtIndex:section];
    return [info numberOfObjects];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSFetchedResultsController *controller = [self fetchedResultsControllerForTableView:tableView];
    id <NSFetchedResultsSectionInfo> info = [[controller sections] objectAtIndex:section];
    return [info name];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    NSFetchedResultsController *controller = [self fetchedResultsControllerForTableView:tableView];
    return [controller sectionIndexTitles];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ShowCell"];
    [self configureCell:cell atIndexPath:indexPath inTableView:tableView];
    return cell;
}

#pragma mark - Search

- (void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView
{
    UINib *nib = [UINib nibWithNibName:@"DCMSearchResultCell" bundle:nil];
    [tableView registerNib:nib forCellReuseIdentifier:@"ShowCell"];
    [self enableDoubleTapRecognizerOnTableView:tableView];
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    NSPredicate *predicate;
    if ([searchString length] > 0) {
        predicate = [NSPredicate predicateWithFormat:@"(name contains[cd] %@) OR (ANY performers.name contains[cd] %@)", searchString, searchString];
    } else {
        predicate = nil;
    }
    [searchController.fetchRequest setPredicate:predicate];
    NSError *error = nil;
    if (![searchController performFetch:&error]) {
        NSLog(@"Search Error: %@", error);
    }
    return YES;
}

#pragma mark - Storyboard

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        [self performSegueWithIdentifier:@"FromAllShowsToShowDetail" sender:self.searchDisplayController];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    DCMShowDetailViewController *detailViewController = [segue destinationViewController];
    if (sender == self.searchDisplayController) {
        NSIndexPath *indexPath = [self.searchDisplayController.searchResultsTableView indexPathForSelectedRow];
        detailViewController.show = [searchController objectAtIndexPath:indexPath];
    } else {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        detailViewController.show = [showsController objectAtIndexPath:indexPath];
    }
}

@end
