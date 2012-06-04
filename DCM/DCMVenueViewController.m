//
//  DCMVenueViewController.m
//  DCM
//
//  Created by Benjamin Ragheb on 6/3/12.
//  Copyright (c) 2012 Heroic Software Inc. All rights reserved.
//

#import "DCMVenueViewController.h"
#import "DCMDatabase.h"

@interface DCMVenueViewController ()

@end

@implementation DCMVenueViewController

@synthesize venue;

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = self.venue.shortName;
    frontViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"VenueSchedule"];
    backViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"VenueDetail"];
    [self addChildViewController:frontViewController];
    frontViewController.view.frame = self.view.bounds;
    [self.view addSubview:frontViewController.view];
    [frontViewController didMoveToParentViewController:self];
}

- (IBAction)flipView:(id)sender
{
    UIViewController *from, *to;
    UIViewAnimationOptions options;
    if (isFlipped) {
        from = backViewController;
        to = frontViewController;
        options = UIViewAnimationOptionTransitionFlipFromLeft;
    } else {
        from = frontViewController;
        to = backViewController;
        options = UIViewAnimationOptionTransitionFlipFromRight;
    }
    [from willMoveToParentViewController:nil];
    [self addChildViewController:to];
    [UIView transitionFromView:from.view toView:to.view
                      duration:0.4 options:options
                    completion:^(BOOL finished) {
                        [to didMoveToParentViewController:self];
                        [from removeFromParentViewController];
                    }];
    isFlipped = !isFlipped;
}

- (void)viewDidUnload
{
    frontViewController = nil;
    backViewController = nil;
    [super viewDidUnload];
}

@end
