//
//  DCMVenueScheduleViewController.h
//  DCM
//
//  Created by Benjamin Ragheb on 6/3/12.
//  Copyright (c) 2012 Upright Citizens Brigade LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DCMScheduleViewController.h"

@class Venue;

@interface DCMVenueScheduleViewController : DCMScheduleViewController
@property (readonly, nonatomic) Venue *venue;
@end
