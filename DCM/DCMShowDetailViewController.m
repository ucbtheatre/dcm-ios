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
            self.imageView.image = image;
            if(!image){
                CGRect r = self.tableView.tableHeaderView.frame;
                r.size.height = 75;
                self.tableView.tableHeaderView.frame = r ;
                [self.tableView setTableHeaderView:self.tableView.tableHeaderView];
            }
        });
    } else {
        CGRect r = self.tableView.tableHeaderView.frame;
        r.size.height = 75;
        self.tableView.tableHeaderView.frame = r ;
        [self.tableView setTableHeaderView:self.tableView.tableHeaderView];
    }
}


- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
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
    return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case 0: return nil; // Blurb has no header
        case 1: return @"Showtimes";
        case 2: return @"Cast";
    }
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0: return 2;
        case 1: return [performances count];
        case 2: return [performers count];
    }
    return 0;
}

- (NSAttributedString *)promoBlurbString
{
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] init];
    UIFont *font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
    NSMutableParagraphStyle *paraStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paraStyle.paragraphSpacing = 0.5 * [font lineHeight];

    if ([self.show.promoBlurb length] > 0) {
        [string appendAttributedString:[[NSAttributedString alloc]
                                        initWithString:self.show.promoBlurb
                                        attributes:@{NSFontAttributeName: font,
                                                     NSForegroundColorAttributeName: [UIColor blackColor],
                                                     NSParagraphStyleAttributeName: paraStyle}]];
    } else {
        [string appendAttributedString:[[NSAttributedString alloc]
                                        initWithString:@"No Description"
                                        attributes:@{NSFontAttributeName: font,
                                                     NSForegroundColorAttributeName: [UIColor grayColor],
                                                     NSParagraphStyleAttributeName: paraStyle}]];
    }

    if ([self.show anyShowRequiresTicket]) {
        UIFont *italicFont = [UIFont italicSystemFontOfSize:[UIFont systemFontSize]];
        [string appendAttributedString:[[NSAttributedString alloc]
                                        initWithString:@"\nTickets for this show are sold separately."
                                        attributes:@{NSFontAttributeName: italicFont,
                                                     NSForegroundColorAttributeName: [UIColor grayColor],
                                                     NSParagraphStyleAttributeName: paraStyle}]];
    }

    return string;
}

- (UITableViewCell *)promoBlurbCellForTableView:(UITableView *)tableView
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PromoBlurbCell"];
    cell.textLabel.attributedText = [self promoBlurbString];
    return cell;
}

- (UITableViewCell *)voteCellForTableView:(UITableView *)tableView
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"VoteCell"];
    UIButton* button = [cell viewWithTag:1];
    button.layer.borderWidth = 1.f;
    button.layer.cornerRadius = 5.f;
    button.layer.borderColor = [UIColor blueColor].CGColor;
    return cell;
}

- (CGFloat)heightForPromoBlurbCell
{
    CGRect bounds = [[self promoBlurbString]
                     boundingRectWithSize:CGSizeMake(320-40, CGFLOAT_MAX)
                     options:(NSStringDrawingUsesLineFragmentOrigin |
                              NSStringDrawingUsesFontLeading)
                     context:nil];
    return ceil(bounds.size.height) + 16;
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
        case 0:
            if(indexPath.row == 0){
                return [self promoBlurbCellForTableView:tableView];
            } else {
                return [self voteCellForTableView:tableView];
            }
        case 1: return [self
                        tableView:tableView
                        cellForPerformanceAtRow:indexPath.row];
        case 2: return [self
                        tableView:tableView
                        cellForPerformerAtRow:indexPath.row];
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0:
            if(indexPath.row == 0) {
                return [self heightForPromoBlurbCell];
            } else {
                return tableView.rowHeight;
            }
            
        default: return tableView.rowHeight;
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
