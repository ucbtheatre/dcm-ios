//
//  DCMVenueScheduleViewController.m
//  DCM
//
//  Created by Benjamin Ragheb on 6/3/12.
//  Copyright (c) 2012 Upright Citizens Brigade LLC. All rights reserved.
//

#import "DCMVenueScheduleViewController.h"
#import "DCMDatabase.h"
#import "DCMAppDelegate.h"
#import "DCMShowDetailViewController.h"

@interface DCMVenueScheduleViewController ()

@end

@implementation DCMVenueScheduleViewController

@synthesize venue;

- (NSPredicate *)predicate
{
    return [NSPredicate predicateWithFormat:@"venue = %@", self.venue];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self enableDoubleTapRecognizerOnTableView:self.tableView];
    self.navigationItem.title = self.venue.name;
}

- (void)tableView:(UITableView *)tableView cellDoubleTappedAtIndexPath:(NSIndexPath *)indexPath
{
    Performance *perf = [self performanceAtIndexPath:indexPath];
    NSError *error = nil;
    if ( ! [perf.show toggleFavoriteAndSave:&error]) {
        UIAlertView *alert = [[UIAlertView alloc] init];
        [alert setTitle:@"Unexpected Error"];
        [alert setMessage:[error debugDescription]];
        [alert addButtonWithTitle:@"Dismiss"];
        [alert show];
    }
}

- (void)configureCell:(UITableViewCell *)cell forPerformance:(Performance *)perf
{
    cell.textLabel.text = [DCMScheduleViewController
                           timeStringForPerformance:perf showFavorite:YES];
    cell.detailTextLabel.text = perf.show.name;
}

@end
