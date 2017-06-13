//
//  DCMShowDetailViewController.m
//  DCM
//
//  Created by Benjamin Ragheb on 5/13/12.
//  Copyright (c) 2012 Upright Citizens Brigade LLC. All rights reserved.
//

#import "DCMShowDetailViewController.h"
#import "DCMDatabase.h"
#import "DCMUtilities.h"
#import "VoteResponse.h"

#import <Answers/Answers.h>

enum {
    DCMTableSectionBlurb,
    DCMTableSectionVote,
    DCMTableSectionTicketWarning,
    DCMTableSectionShowtimes,
    DCMTableSectionCast
};

@implementation DCMShowDetailViewController
{
    NSArray *performers;
    NSArray *performances;
}

@synthesize show;
@synthesize favoriteButton;

- (void)updateFavoriteButton
{
    NSString *name = [self.show isFavorite] ? @"LikeFilled" : @"Like";
    self.favoriteButton.image = [UIImage imageNamed:name];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self updateFavoriteButton];

    performers = [self.show.performers sortedArrayUsingDescriptors:
                  [Performer standardSortDescriptors]];

    performances = [self.show performancesSortedByDate];

    self.titleLabel.text = self.show.name;
    self.homeCityLabel.text = self.show.homeCity;

    if (self.show.imageURLString) {
        NSURL *imageURL = [NSURL URLWithString:self.show.imageURLString];
        DCMLoadImageAsynchronously(imageURL, ^(UIImage *image) {
            [self.imageView setImage:image];
        });
    } else {
        [self.imageView setImage:nil];
    }
}

- (void)viewWillLayoutSubviews
{
    UIView *header = self.tableView.tableHeaderView;

    CGSize headerSize = [header systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    CGFloat height = ceil(headerSize.height);

    CGRect bounds = header.bounds;

    if (bounds.size.height != height) {
        bounds.size.height = height;
        header.bounds = bounds;

        self.tableView.tableHeaderView = header;
    }

    [super viewWillLayoutSubviews];
}

- (IBAction)toggleFavorite:(id)sender
{
    NSError *error = nil;
    if ([self.show toggleFavoriteAndSave:&error]) {
        [self updateFavoriteButton];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] init];
        [alert setTitle:@"Unexpected Error"];
        [alert setMessage:[error debugDescription]];
        [alert addButtonWithTitle:@"Dismiss"];
        [alert show];
    }
}

- (IBAction)shareShow:(id)sender
{
    NSURL *link = [NSURL URLWithString:@"http://delclosemarathon.com"];

    UIActivityViewController *avc = [[UIActivityViewController alloc]
                                     initWithActivityItems:@[self.show, link]
                                     applicationActivities:nil];

    [self presentViewController:avc animated:YES completion:nil];
}

- (IBAction)dismiss:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 5;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case DCMTableSectionBlurb:          return nil;
        case DCMTableSectionTicketWarning:  return nil;
        case DCMTableSectionVote:           return nil;
        case DCMTableSectionShowtimes:      return @"Showtimes";
        case DCMTableSectionCast:           return @"Cast";
    }
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case DCMTableSectionBlurb:          return 1;
        case DCMTableSectionTicketWarning:  return [self.show anyShowRequiresTicket] ? 1 : 0;
        case DCMTableSectionVote:           return 1;
        case DCMTableSectionShowtimes:      return [performances count];
        case DCMTableSectionCast:           return [performers count];
    }
    return 0;
}

- (UITableViewCell *)promoBlurbCellForTableView:(UITableView *)tableView
{
    UITableViewCell *cell;

    if ([self.show.promoBlurb length] > 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"PromoBlurbCell"];
        cell.textLabel.text = self.show.promoBlurb;
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"NoPromoBlurbCell"];
    }

    return cell;
}

- (UITableViewCell *)voteCellForTableView:(UITableView *)tableView
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"VoteCell"];
    UIButton* button = [cell viewWithTag:1];
    button.layer.borderWidth = 1.f;
    button.layer.cornerRadius = 5.f;
    button.layer.borderColor = tableView.tintColor.CGColor;
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForPerformerAtRow:(NSInteger)row
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PerformerCell"];
    Performer *performer = [performers objectAtIndex:row];
    cell.textLabel.attributedText = performer.attributedFullName;
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForPerformanceAtRow:(NSInteger)row
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PerformanceCell"];
    Performance *performance = [performances objectAtIndex:row];
    cell.textLabel.text = [[Show dateFormatter] stringFromDate:performance.startDate];
    cell.detailTextLabel.text = performance.venue.shortName;
    NSURL *ticketsURL = performance.ticketsURL;
    if (ticketsURL) {
        cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case DCMTableSectionBlurb:
            return [self promoBlurbCellForTableView:tableView];

        case DCMTableSectionTicketWarning:
            return [tableView dequeueReusableCellWithIdentifier:@"TicketWarningCell"];

        case DCMTableSectionVote:
            return [self voteCellForTableView:tableView];

        case DCMTableSectionShowtimes:
            return [self
                    tableView:tableView
                    cellForPerformanceAtRow:indexPath.row];

        case DCMTableSectionCast:
            return [self
                    tableView:tableView
                    cellForPerformerAtRow:indexPath.row];
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case DCMTableSectionBlurb: {
            // If you call [tableView cellForRowAtIndexPath:] here, you'll enter an infinite loop.

            UITableViewCell *cell = [self tableView:tableView cellForRowAtIndexPath:indexPath];

            CGFloat width = CGRectGetWidth(tableView.bounds);

            CGSize cellSize = [cell sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)];

            return cellSize.height;
        }

        default:
            return tableView.rowHeight;
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    Performance *performance = [performances objectAtIndex:indexPath.row];

    [[UIApplication sharedApplication] openURL:performance.ticketsURL];
}


- (void)vote:(id)sender
{
    [Answers logRating:@(10)
           contentName:self.show.name
           contentType:@"show"
             contentId:[self.show.identifier stringValue]
      customAttributes:nil];
    
    VoteResponse* randomResponse = [VoteResponse randomResponse:[DCMDatabase sharedDatabase]];
    
    UIAlertView* alert = [[UIAlertView alloc]
                          initWithTitle:@"Points Added"
                          message:randomResponse.message
                          delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil];

    [alert show];
}

@end
