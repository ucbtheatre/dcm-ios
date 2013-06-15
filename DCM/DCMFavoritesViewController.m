//
//  DCMFavoritesViewController.m
//  DCM
//
//  Created by Kurt Guenther on 5/19/12.
//  Copyright (c) 2012 Upright Citizens Brigade LLC. All rights reserved.
//

#import "DCMFavoritesViewController.h"
#import "DCMDatabase.h"

#define kDateLabelTag 101
#define kVenueLabelTag 102
#define kTitleLabelTag 103

@interface DCMFavoritesViewController ()

@end

@implementation DCMFavoritesViewController

- (void)awakeFromNib
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(databaseWillChange:)
                   name:DCMDatabaseWillChangeNotification object:nil];
    [center addObserver:self selector:@selector(databaseDidChange:)
                   name:DCMDatabaseDidChangeNotification object:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
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
        [self.tableView reloadData];
    }
}

- (NSPredicate *)predicate
{
    return [NSPredicate predicateWithFormat:@"favorite = TRUE"];
}

- (void)configureCell:(UITableViewCell *)cell forPerformance:(Performance *)perf
{
    UILabel *dateLabel = (id)[cell.contentView viewWithTag:kDateLabelTag];
    UILabel *venueLabel = (id)[cell.contentView viewWithTag:kVenueLabelTag];
    UILabel *titleLabel = (id)[cell.contentView viewWithTag:kTitleLabelTag];
    dateLabel.text = [DCMScheduleViewController
                      timeStringForPerformance:perf showFavorite:NO];
    venueLabel.text = perf.venue.shortName;
    titleLabel.text = perf.show.name;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return @"Remove";
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        Performance *p = [performancesController objectAtIndexPath:indexPath];
        p.favorite = NO;
        p.show.favoriteChangedDate = [NSDate date];
        [p.managedObjectContext save:nil];
    }
}

@end
