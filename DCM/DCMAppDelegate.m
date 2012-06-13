//
//  DCMAppDelegate.m
//  DCM
//
//  Created by Benjamin Ragheb on 5/12/12.
//  Copyright (c) 2012 Heroic Software Inc. All rights reserved.
//

#import "DCMAppDelegate.h"
#import "DCMDatabase.h"
#import "DCMImportOperation.h"
#import "MBProgressHUD.h"

@implementation DCMAppDelegate

+ (DCMAppDelegate *)sharedDelegate
{
    return [[UIApplication sharedApplication] delegate];
}

+ (NSDate *)currentDate
{
    DCMAppDelegate *ad = [[UIApplication sharedApplication] delegate];
    return [NSDate dateWithTimeIntervalSinceNow:ad.timeShift];
}

@synthesize window = _window;
@synthesize timeShift;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[UINavigationBar appearance] setTintColor:
     [UIColor colorWithRed:1 green:0.2 blue:0.2 alpha:1]];
    // Override point for customization after application launch.
    [[NSNotificationCenter defaultCenter]
     addObserverForName:DCMDatabaseProgressNotification object:nil
     queue:[NSOperationQueue mainQueue]
     usingBlock:^(NSNotification *note) {
         NSError *error = [[note userInfo] objectForKey:DCMDatabaseErrorKey];
         if (error) {
             NSLog(@"Error: %@", [error localizedDescription]);
             [[MBProgressHUD HUDForView:self.window] hide:YES];
             UIAlertView *alert = [[UIAlertView alloc] init];
             alert.title = @"Update Failed";
             alert.message = [error localizedDescription];
             [alert addButtonWithTitle:@"Dismiss"];
             [alert show];
         } else {
             NSDictionary *info = [note userInfo];
             float progress = [[info objectForKey:DCMDatabaseProgressKey] floatValue];
             NSString *activity = [info objectForKey:DCMDatabaseActivityKey];
             // NSLog(@"Progress: %0.4f %@", progress, activity);
             MBProgressHUD *hud = [MBProgressHUD HUDForView:self.window];
             if (hud == nil) {
                 hud = [[MBProgressHUD alloc] initWithWindow:self.window];
                 hud.removeFromSuperViewOnHide = YES;
                 [self.window addSubview:hud];
                 [hud show:YES];
             }
             if (progress == DCMDatabaseProgressIndeterminate) {
                 hud.mode = MBProgressHUDModeIndeterminate;
             } else if (progress < DCMDatabaseProgressComplete) {
                 hud.mode = MBProgressHUDModeDeterminate;
                 hud.progress = progress;
             }
             hud.labelText = activity;
             if (progress == DCMDatabaseProgressComplete) {
                 hud.mode = MBProgressHUDModeText;
                 [hud hide:YES afterDelay:2];
             }
         }
     }];
    [[DCMDatabase sharedDatabase] checkForUpdate];
    return YES;
}

@end
