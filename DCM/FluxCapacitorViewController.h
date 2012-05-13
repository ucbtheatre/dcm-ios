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
- (void)fluxCapacitor:(FluxCapacitorViewController *)fluxCap didSelectTimeShift:(NSTimeInterval)shift;
@end

@interface FluxCapacitorViewController : UIViewController
@property (nonatomic,weak) id <FluxCapacitorDelegate> delegate;
@property (nonatomic) NSTimeInterval initialTimeShift;
@property (nonatomic,strong) IBOutlet UIDatePicker *datePicker;
- (IBAction)confirm:(id)sender;
- (IBAction)reset:(id)sender;
@end
