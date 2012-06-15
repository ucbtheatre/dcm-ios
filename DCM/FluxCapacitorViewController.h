//
//  FluxCapacitorViewController.h
//  DCM
//
//  Created by Benjamin Ragheb on 5/13/12.
//  Copyright (c) 2012 Heroic Software Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FluxCapacitorViewController;

@protocol FluxCapacitorDelegate <NSObject>
- (void)fluxCapacitorCompleted:(FluxCapacitorViewController *)fluxCap;
@end

@interface FluxCapacitorViewController : UIViewController
@property (nonatomic,weak) id <FluxCapacitorDelegate> delegate;
@property (nonatomic,strong) IBOutlet UIDatePicker *datePicker;
@property (nonatomic,strong) IBOutlet UISegmentedControl *speedControl;
- (IBAction)confirm:(id)sender;
- (IBAction)reset:(id)sender;
- (IBAction)jumpToMarathonStart:(id)sender;
@end
