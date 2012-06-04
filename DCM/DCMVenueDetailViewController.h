//
//  DCMVenueDetailViewController.h
//  DCM
//
//  Created by Benjamin Ragheb on 5/13/12.
//  Copyright (c) 2012 Heroic Software Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Venue;

@interface DCMVenueDetailViewController : UIViewController
@property (readonly, nonatomic) Venue *venue;
@property (strong, nonatomic) IBOutlet UILabel *nameLabel;
@property (strong, nonatomic) IBOutlet UILabel *addressLabel;
@property (strong, nonatomic) IBOutlet UILabel *directionsLabel;
@property (strong, nonatomic) IBOutlet UIButton *websiteButton;
@property (strong, nonatomic) IBOutlet UIButton *mapButton;
- (IBAction)openWebsite:(id)sender;
- (IBAction)openMap:(id)sender;
@end
