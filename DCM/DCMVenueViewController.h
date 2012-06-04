//
//  DCMVenueViewController.h
//  DCM
//
//  Created by Benjamin Ragheb on 6/3/12.
//  Copyright (c) 2012 Heroic Software Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Venue;

@interface DCMVenueViewController : UIViewController
{
    BOOL isFlipped;
    UIViewController *frontViewController;
    UIViewController *backViewController;
}
@property (nonatomic,strong) Venue *venue;
- (IBAction)flipView:(id)sender;
@end
