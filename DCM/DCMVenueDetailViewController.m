//
//  DCMVenueDetailViewController.m
//  DCM
//
//  Created by Benjamin Ragheb on 5/13/12.
//  Copyright (c) 2012 Heroic Software Inc. All rights reserved.
//

#import <CommonCrypto/CommonDigest.h>

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
@synthesize loadingIndicator;
@synthesize imageView;

- (Venue *)venue
{
    DCMVenueViewController *parent = (DCMVenueViewController *)self.parentViewController;
    return parent.venue;
}

- (NSString *)cachedImagePath
{
    const char *imgURL = [self.venue.imageURLString UTF8String];
    unsigned char hash[CC_MD5_DIGEST_LENGTH];
    CC_MD5(imgURL, strlen(imgURL), hash);
    NSMutableString *name = [[NSMutableString alloc] initWithCapacity:2*CC_MD5_DIGEST_LENGTH];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [name appendFormat:@"%02x", hash[i]];
    }
    NSURL *cachesURL = [[NSFileManager defaultManager]
                        URLForDirectory:NSCachesDirectory
                        inDomain:NSUserDomainMask
                        appropriateForURL:nil
                        create:YES
                        error:nil];
    return [[NSURL URLWithString:name relativeToURL:cachesURL] path];
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
        NSString *path = [self cachedImagePath];
        UIImage *image = [UIImage imageWithContentsOfFile:path];
        if (image) {
            self.imageView.image = image;
            self.loadingIndicator.hidden = YES;
        } else {
            NSURL *imageURL = [NSURL URLWithString:self.venue.imageURLString];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                NSData *data = [NSData dataWithContentsOfURL:imageURL];
                [data writeToFile:path options:0 error:nil];
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.loadingIndicator.hidden = YES;
                    self.imageView.image = [UIImage imageWithContentsOfFile:path];
                });
            });
        }
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
