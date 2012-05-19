//
//  DCMShowDetailViewController.m
//  DCM
//
//  Created by Benjamin Ragheb on 5/13/12.
//  Copyright (c) 2012 Heroic Software Inc. All rights reserved.
//

#import "DCMShowDetailViewController.h"
#import "DCMDatabase.h"

@interface DCMShowDetailViewController ()

@end

@implementation DCMShowDetailViewController

@synthesize promoBlurbLabel;
@synthesize show;
@synthesize favoriteButton;

- (void)updateFavoriteButton
{
    NSString *name = self.show.favorite ? @"Heart1" : @"Heart0";
    self.favoriteButton.image = [UIImage imageNamed:name];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = show.name;
    performers = [self.show.performers sortedArrayUsingDescriptors:
                  [NSArray arrayWithObject:
                   [NSSortDescriptor
                    sortDescriptorWithKey:@"name" ascending:YES]]];
    performances = [self.show.performances sortedArrayUsingDescriptors:
                    [NSArray arrayWithObject:
                     [NSSortDescriptor
                      sortDescriptorWithKey:@"startDate" ascending:YES]]];
    self.promoBlurbLabel.text = self.show.promoBlurb;
    [self.promoBlurbLabel sizeToFit];
    CGFloat height = CGRectGetHeight(self.promoBlurbLabel.bounds);
    [[self.promoBlurbLabel superview]
     setBounds:CGRectMake(0, 0, 320, height+16)];
    [self updateFavoriteButton];
}

- (void)viewDidUnload
{
    self.show = nil;
    self.promoBlurbLabel = nil;
    performers = nil;
    performances = nil;
    [super viewDidUnload];
}

- (IBAction)toggleFavorite:(id)sender
{
    //self.show.favorite = !self.show.favorite;
    BOOL fav = self.show.favorite;
    for (Performance* p in self.show.performances) {
        p.favorite = !fav;
    }
    
    NSError *error = nil;
    if ([self.show.managedObjectContext save:&error]) {
        [self updateFavoriteButton];
    } else {
        // TODO: display alert
        NSLog(@"Error: %@", [error localizedDescription]);
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case 0: return @"Showtimes";
        case 1: return @"Cast";
    }
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0: return [performances count];
        case 1: return [performers count];
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForPerformerAtRow:(NSInteger)row
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PerformerCell"];
    Performer *performer = [performers objectAtIndex:row];
    cell.textLabel.text = performer.name;
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForPerformanceAtRow:(NSInteger)row
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PerformanceCell"];
    Performance *performance = [performances objectAtIndex:row];
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"EEEE h:mm a"];
    cell.textLabel.text = [df stringFromDate:performance.startDate];
    cell.detailTextLabel.text = performance.venue.shortName;
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0: return [self
                        tableView:tableView
                        cellForPerformanceAtRow:indexPath.row];
        case 1: return [self
                        tableView:tableView
                        cellForPerformerAtRow:indexPath.row];
    }
    return nil;
}

@end
