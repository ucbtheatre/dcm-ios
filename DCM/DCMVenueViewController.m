//
//  DCMVenueViewController.m
//  DCM
//
//  Created by Benjamin Ragheb on 6/3/12.
//  Copyright (c) 2012 Upright Citizens Brigade LLC. All rights reserved.
//

#import "DCMVenueViewController.h"
#import "DCMDatabase.h"

static NSString * const DCMVenueViewIsFlipped = @"DCMVenueViewIsFlipped";

@interface DCMVenueViewController ()

@end

@implementation DCMVenueViewController
{
    BOOL isFlipped;
    UIViewController *frontViewController;
    UIViewController *backViewController;
}

@synthesize venue;

- (void)viewDidLoad
{
    isFlipped = [[NSUserDefaults standardUserDefaults]
                 boolForKey:DCMVenueViewIsFlipped];
    [super viewDidLoad];
    self.title = self.venue.shortName;
    frontViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"VenueSchedule"];
    backViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"VenueDetail"];
    UIBarButtonItem *frontButton = frontViewController.navigationItem.rightBarButtonItem;
    [frontButton setTarget:self];
    [frontButton setAction:@selector(flipView:)];
    UIBarButtonItem *backButton = backViewController.navigationItem.rightBarButtonItem;
    [backButton setTarget:self];
    [backButton setAction:@selector(flipView:)];
    UIViewController *initial;
    if (isFlipped) {
        initial = backViewController;
    } else {
        initial = frontViewController;
    }
    [self addChildViewController:initial];
    initial.view.frame = self.view.bounds;
    self.navigationItem.rightBarButtonItem = initial.navigationItem.rightBarButtonItem;
    [self.view addSubview:initial.view];
    [initial didMoveToParentViewController:self];
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
    to.view.frame = self.view.bounds;
    UIBarButtonItem *button = to.navigationItem.rightBarButtonItem;
    [self.navigationItem setRightBarButtonItem:button animated:YES];
    [UIView transitionFromView:from.view toView:to.view
                      duration:0.6 options:options
                    completion:^(BOOL finished) {
                        [to didMoveToParentViewController:self];
                        [from removeFromParentViewController];
                    }];
    isFlipped = !isFlipped;
    [[NSUserDefaults standardUserDefaults]
     setBool:isFlipped forKey:DCMVenueViewIsFlipped];
}

- (void)viewDidUnload
{
    frontViewController = nil;
    backViewController = nil;
    [super viewDidUnload];
}

@end
