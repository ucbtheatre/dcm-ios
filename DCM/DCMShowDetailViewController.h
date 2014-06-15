//
//  DCMShowDetailViewController.h
//  DCM
//
//  Created by Benjamin Ragheb on 5/13/12.
//  Copyright (c) 2012 Upright Citizens Brigade LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DCMTableViewController.h"

@class Show;

@interface DCMShowDetailViewController : DCMTableViewController
@property (strong, nonatomic) Show *show;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *favoriteButton;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *homeCityLabel;
@property (weak, nonatomic) IBOutlet UILabel *promoBlurbLabel;
@property (weak, nonatomic) IBOutlet UILabel *ticketWarningLabel;
@property (weak, nonatomic) IBOutlet UIButton *shareButton;
- (IBAction)toggleFavorite:(id)sender;
- (IBAction)shareShow:(id)sender;
- (IBAction)dismiss:(id)sender;
@end
