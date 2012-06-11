//
//  DCMAppDelegate.h
//  DCM
//
//  Created by Benjamin Ragheb on 5/12/12.
//  Copyright (c) 2012 Heroic Software Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DCMAppDelegate : UIResponder <UIApplicationDelegate>
@property (strong, nonatomic) UIWindow *window;
@property (nonatomic) NSTimeInterval timeShift;
+ (DCMAppDelegate *)sharedDelegate;
+ (NSDate *)currentDate;
- (void)refreshDatabase;
@end
