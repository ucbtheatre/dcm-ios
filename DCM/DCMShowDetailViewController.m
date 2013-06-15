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
    NSString *name = [self.show isFavorite] ? @"Heart1" : @"Heart0";
    self.favoriteButton.image = [UIImage imageNamed:name];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self updateFavoriteButton];

    performanceDateFormatter = [[NSDateFormatter alloc] init];
    [performanceDateFormatter setDateFormat:@"EEEE h:mm a"];

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

    CALayer *vignetteLayer = [DCMShowDetailViewController vignetteLayerForBounds:self.imageView.bounds];
    [self.imageView.layer addSublayer:vignetteLayer];

    Class avcClass = NSClassFromString(@"UIActivityViewController");
    self.shareButton.hidden = (avcClass == nil);
    
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

- (void)shareShow:(id)sender
{
    // Cases:
    // - 1 performance
    // - multiple performances, 1 venue
    // - multiple performances, multiple venues
    NSMutableString *text = [NSMutableString string];
    if ([self.show isFavorite]) {
        [text appendString:@"I’ll be at "];
    } else {
        [text appendString:@"Check out "];
    }
    [text appendString:self.show.name];
    [text appendString:@" "];
    if ([[performances valueForKeyPath:@"@distinctUnionOfObjects.venue"] count] > 1) {
        [performances enumerateObjectsUsingBlock:^(Performance *p, NSUInteger idx, BOOL *stop) {
            if (idx > 0) [text appendString:@", "];
            [text appendFormat:@"%@ at %@",
             [performanceDateFormatter stringFromDate:p.startDate],
             p.venue.name];
        }];
    }
    else {
        [performances enumerateObjectsUsingBlock:^(Performance *p, NSUInteger idx, BOOL *stop) {
            if (idx > 0) [text appendString:@", "];
            [text appendString:[performanceDateFormatter stringFromDate:p.startDate]];
        }];
        [text appendFormat:@" at %@", [[[performances lastObject] venue] name]];
    }
    [text appendString:@" #dcm15"];
    NSString *showURLString = [NSString stringWithFormat:@"http://delclosemarathon.com/dcm15/shows/%@", self.show.identifier];
    NSURL *showURL = [NSURL URLWithString:showURLString];
    UIActivityViewController *avc = [[UIActivityViewController alloc]
                                     initWithActivityItems:@[text, showURL]
                                     applicationActivities:nil];
    [self presentViewController:avc animated:YES completion:nil];
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
    cell.textLabel.text = [performanceDateFormatter stringFromDate:performance.startDate];
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
