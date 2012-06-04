//
//  DCMVenueDetailViewController.m
//  DCM
//
//  Created by Benjamin Ragheb on 5/13/12.
//  Copyright (c) 2012 Heroic Software Inc. All rights reserved.
//

#import "DCMVenueDetailViewController.h"
#import "DCMShowDetailViewController.h"
#import "DCMDatabase.h"
#import "DCMAppDelegate.h"
#import "DCMVenueViewController.h"

@interface DCMVenueDetailViewController ()

@end

@implementation DCMVenueDetailViewController

@synthesize nameLabel;
@synthesize addressLabel;
@synthesize directionsLabel;
@synthesize websiteButton;
@synthesize mapButton;

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
}

- (void)viewDidUnload
{
    [self setAddressLabel:nil];
    [self setDirectionsLabel:nil];
    [self setWebsiteButton:nil];
    [self setMapButton:nil];
    [self setNameLabel:nil];
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
