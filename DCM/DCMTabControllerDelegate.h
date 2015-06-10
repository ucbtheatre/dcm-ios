//
//  DCMTabControllerDelegate.h
//  DCM
//
//  Created by Benjamin Ragheb on 6/9/15.
//  Copyright (c) 2015 Upright Citizens Brigade LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DCMTabControllerDelegate : NSObject <UITabBarControllerDelegate>
@property (nonatomic, weak) IBOutlet UITabBarController *tabBarController;
@end
