//
//  DCMShowDetailViewController.m
//  DCM
//
//  Created by Benjamin Ragheb on 5/13/12.
//  Copyright (c) 2012 Upright Citizens Brigade LLC. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "DCMShowDetailViewController.h"
#import "DCMDatabase.h"

@interface DCMShowDetailViewController ()

@end

@implementation DCMShowDetailViewController

@synthesize show;
@synthesize favoriteButton;

+ (CALayer *)vignetteLayerForBounds:(CGRect)imageBounds
{
    // Gradient components: Opaque Black to Transparent Black
    static const CGFloat colorComponents[] = {0, 1, 0, 0};
    
    const CGPoint center = CGPointMake(CGRectGetMidX(imageBounds), CGRectGetMidY(imageBounds));
    const CGSize size = imageBounds.size;
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, colorComponents, NULL, 2);
    CGContextRef context = UIGraphicsGetCurrentContext();
    // Since radial gradients must be circular, we transform the coordinate
    // system so that a unit circle fills the layer rectangle.
    CGContextTranslateCTM(context, center.x, center.y);
    CGContextScaleCTM(context, size.width, size.height);
    CGContextDrawRadialGradient(context, gradient,
                                CGPointZero, 0,
                                CGPointZero, 1,
                                0);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    CALayer *vignetteLayer = [CALayer layer];
    vignetteLayer.bounds = imageBounds;
    vignetteLayer.position = center;
    vignetteLayer.contents = (__bridge id)([image CGImage]);
    UIGraphicsEndImageContext();
    return vignetteLayer;
}

- (void)updateFavoriteButton
{
    NSString *name = self.show.favorite ? @"Heart1" : @"Heart0";
    self.favoriteButton.image = [UIImage imageNamed:name];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    performers = [self.show.performers sortedArrayUsingDescriptors:
                  [NSArray arrayWithObject:
                   [NSSortDescriptor
                    sortDescriptorWithKey:@"name" ascending:YES]]];
    performances = [self.show.performances sortedArrayUsingDescriptors:
                    [NSArray arrayWithObject:
                     [NSSortDescriptor
                      sortDescriptorWithKey:@"startDate" ascending:YES]]];
    self.titleLabel.text = self.show.name;
    self.homeCityLabel.text = self.show.homeCity;
    self.promoBlurbLabel.text = self.show.promoBlurb;
    [self.promoBlurbLabel sizeToFit];
    CGRect bounds = [self.tableView.tableHeaderView bounds];
    bounds.size.height = (CGRectGetHeight(self.imageView.frame) + 8 +
                          CGRectGetHeight(self.promoBlurbLabel.frame) + 8);
    if ([self.show anyShowRequiresTicket]) {
        bounds.size.height += CGRectGetHeight(self.ticketWarningLabel.frame) + 8;
    } else {
        [self.ticketWarningLabel removeFromSuperview];
    }
    [self.tableView.tableHeaderView setBounds:bounds];
    [self updateFavoriteButton];

    CALayer *vignetteLayer = [DCMShowDetailViewController vignetteLayerForBounds:self.imageView.bounds];
    [self.imageView.layer addSublayer:vignetteLayer];
    
    if (self.show.imageURLString) {
        NSString *imageURLString = self.show.imageURLString;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^(void) {
            NSURL *imageURL = [NSURL URLWithString:imageURLString];
            NSMutableURLRequest *imageRequest = [NSMutableURLRequest requestWithURL:imageURL];
            [imageRequest setCachePolicy:NSURLRequestReturnCacheDataElseLoad];
            NSHTTPURLResponse *imageResponse = nil;
            NSError *error = nil;
            NSData *imageData = [NSURLConnection sendSynchronousRequest:imageRequest
                                                      returningResponse:&imageResponse
                                                                  error:&error];
            if (imageData) {
                UIImage *image = [UIImage imageWithData:imageData];
                if (image) {
                    dispatch_async(dispatch_get_main_queue(), ^(void) {
                        self.imageView.image = image;
                    });
                }
            }
        });
    }
}

- (void)viewDidUnload
{
    self.show = nil;
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
        case 0: return [self
                        tableView:tableView
                        cellForPerformanceAtRow:indexPath.row];
        case 1: return [self
                        tableView:tableView
                        cellForPerformerAtRow:indexPath.row];
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    Performance *performance = [performances objectAtIndex:indexPath.row];
    [[UIApplication sharedApplication] openURL:performance.ticketsURL];
}

@end
