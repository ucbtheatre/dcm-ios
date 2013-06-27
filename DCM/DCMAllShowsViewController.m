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

- (void)setUpControllerForDatabase:(DCMDatabase *)database
{
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Show"];
    [request setSortDescriptors:
     [NSArray arrayWithObject:
      [NSSortDescriptor sortDescriptorWithKey:@"sortName" ascending:YES]]];
    [request setRelationshipKeyPathsForPrefetching:@[@"performances"]];
    showsController = [[NSFetchedResultsController alloc]
                       initWithFetchRequest:request
                       managedObjectContext:database.managedObjectContext
                       sectionNameKeyPath:@"sortSection"
                       cacheName:nil];
    showsController.delegate = self;
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
    [self enableDoubleTapRecognizer];
    [self setUpControllerForDatabase:[DCMDatabase sharedDatabase]];
    
    //This offsets the scroll so we don't see the Search Bar initially
    if([self.tableView.dataSource tableView:self.tableView numberOfRowsInSection:0] > 0){
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    showsController = nil;
}

- (IBAction)refresh:(id)sender
{
    [[DCMDatabase sharedDatabase] checkForUpdate];
}

- (void)tableCellDoubleTappedAtIndexPath:(NSIndexPath *)indexPath
{
    Show *show = [showsController objectAtIndexPath:indexPath];
    NSError *error = nil;
    if ( ! [show toggleFavoriteAndSave:&error]) {
        UIAlertView *alert = [[UIAlertView alloc] init];
        [alert setTitle:@"Unexpected Error"];
        [alert setMessage:[error debugDescription]];
        [alert addButtonWithTitle:@"Dismiss"];
        [alert show];
    }
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    // Unicode "HEAVY BLACK HEART"
    static NSString * const kHeartSuffix = @" \xE2\x9D\xA4";
    
    Show *show = [showsController objectAtIndexPath:indexPath];
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

// Removed this so we wouldn't show the Indices since we now have search
//- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
//{
//    return [showsController sectionIndexTitles];
//}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ShowCell"];
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

#pragma mark - Storyboard

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar{
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [searchBar setShowsCancelButton:YES animated:YES];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [NSFetchedResultsController deleteCacheWithName:[showsController cacheName]];
    if(searchText != nil && ![searchText isEqual:@""]){
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(name contains[cd] %@) OR (ANY performers.name contains[cd] %@)", searchBar.text, searchBar.text];
        [showsController.fetchRequest setPredicate:predicate];
    }
    else {
        [showsController.fetchRequest setPredicate:nil];
    }

    [showsController performFetch:nil];
    [self.tableView reloadData];

}

- (void) searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [searchBar setShowsCancelButton:NO animated:YES];
    
    [NSFetchedResultsController deleteCacheWithName:[showsController cacheName]];
    [showsController.fetchRequest setPredicate:nil];
    [showsController performFetch:nil];
    [self.tableView reloadData];
    
    [searchBar setText:nil];
    [searchBar resignFirstResponder];
}

- (void) searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

#pragma mark - Storyboard

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    DCMShowDetailViewController *detailViewController = [segue destinationViewController];
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    detailViewController.show = [showsController objectAtIndexPath:indexPath];
}

@end
