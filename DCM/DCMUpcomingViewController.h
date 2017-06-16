//
//  DCMUpcomingViewController.h
//  DCM
//
//  Created by Benjamin Ragheb on 5/13/12.
//  Copyright (c) 2012 Upright Citizens Brigade LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FluxCapacitorViewController.h"

@interface DCMUpcomingViewController : UITableViewController <FluxCapacitorDelegate>
@property (nonatomic,strong) IBOutlet UILabel *dateLabel;
@property (nonatomic,strong) IBOutlet UIView *countdownView;
@property (nonatomic,strong) IBOutlet UILabel *countdownLabel;
- (IBAction)timeTravel:(id)sender;
@end
