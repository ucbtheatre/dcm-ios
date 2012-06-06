//
//  DCMFavoritesViewController.m
//  DCM
//
//  Created by Kurt Guenther on 5/19/12.
//  Copyright (c) 2012 Heroic Software Inc. All rights reserved.
//

#import "DCMFavoritesViewController.h"
#import "DCMDatabase.h"

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

@end
