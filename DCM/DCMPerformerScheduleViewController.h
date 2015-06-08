//
//  DCMPerformerScheduleViewController.h
//  DCM
//
//  Created by Benjamin Ragheb on 6/8/15.
//  Copyright (c) 2015 Upright Citizens Brigade LLC. All rights reserved.
//

#import "DCMScheduleViewController.h"

@class Performer;

@interface DCMPerformerScheduleViewController : DCMScheduleViewController
@property (nonatomic, strong) Performer *performer;
@end
