//
//  DCMVenueDetailViewController.m
//  DCM
//
//  Created by Benjamin Ragheb on 5/13/12.
//  Copyright (c) 2012 Upright Citizens Brigade LLC. All rights reserved.
//

#import "DCMVenueDetailViewController.h"
#import "DCMShowDetailViewController.h"
#import "DCMDatabase.h"
#import "DCMAppDelegate.h"
#import "DCMVenueViewController.h"
#import "DCMUtilities.h"

@implementation DCMVenueDetailViewController

@synthesize nameLabel;
@synthesize addressLabel;
@synthesize directionsLabel;
@synthesize websiteButton;
@synthesize mapButton;
@synthesize loadingIndicator;
@synthesize imageView;

- (Venue *)venue
{
    DCMVenueViewController *parent = (DCMVenueViewController *)self.parentViewController;
    return parent.venue;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = self.venue.name;
    self.nameLabel.text = self.venue.name;
    self.addressLabel.text = self.venue.address;
    self.directionsLabel.text = self.venue.directions;
    self.websiteButton.enabled = [self.venue.homeURLString length] > 0;
    self.mapButton.enabled = [self.venue.mapURLString length] > 0;
    if ([self.venue.imageURLString length] > 0) {
        NSURL *imageURL = [NSURL URLWithString:self.venue.imageURLString];
        DCMLoadImageAsynchronously(imageURL, ^(UIImage *image) {
            self.loadingIndicator.hidden = YES;
            self.imageView.image = image;
        });
    } else {
        self.imageView.hidden = YES;
        self.loadingIndicator.hidden = YES;
    }
}

- (void)viewDidUnload
{
    [self setAddressLabel:nil];
    [self setDirectionsLabel:nil];
    [self setWebsiteButton:nil];
    [self setMapButton:nil];
    [self setNameLabel:nil];
    [self setImageView:nil];
    [self setLoadingIndicator:nil];
    [super viewDidUnload];
}

- (IBAction)openWebsite:(id)sender
{
    [[UIApplication sharedApplication]
     openURL:[NSURL URLWithString:self.venue.homeURLString]];
}

- (IBAction)openMap:(id)sender
{
    [[UIApplication sharedApplication]
     openURL:[NSURL URLWithString:self.venue.mapURLString]];
}

@end
