//
//  DCMPerformerScheduleViewController.m
//  DCM
//
//  Created by Benjamin Ragheb on 6/8/15.
//  Copyright (c) 2015 Upright Citizens Brigade LLC. All rights reserved.
//

#import "DCMPerformerScheduleViewController.h"
#import "DCMDatabase.h"

#define kDateLabelTag 101
#define kVenueLabelTag 102
#define kTitleLabelTag 103

@implementation DCMPerformerScheduleViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self enableLongPressRecognizerOnTableView:self.tableView];
    self.navigationItem.title = [self.performer.attributedFullName string];
}

- (NSPredicate *)predicate
{
    return [NSPredicate predicateWithFormat:@"ANY show.performers = %@", _performer];
}

- (void)configureCell:(UITableViewCell *)cell forPerformance:(Performance *)perf
{
    UILabel *dateLabel = (id)[cell.contentView viewWithTag:kDateLabelTag];
    UILabel *venueLabel = (id)[cell.contentView viewWithTag:kVenueLabelTag];
    UILabel *titleLabel = (id)[cell.contentView viewWithTag:kTitleLabelTag];
    dateLabel.text = [DCMScheduleViewController
                      timeStringForPerformance:perf
                      showFavorite:perf.favorite];
    venueLabel.text = perf.venue.shortName;
    titleLabel.text = perf.show.name;
}

- (void)tableView:(UITableView *)tableView cellLongPressedAtIndexPath:(NSIndexPath *)indexPath
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

@end
