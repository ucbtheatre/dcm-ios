//
//  DCMAppDelegate.m
//  DCM
//
//  Created by Benjamin Ragheb on 5/12/12.
//  Copyright (c) 2012 Upright Citizens Brigade LLC. All rights reserved.
//

#import "DCMAppDelegate.h"
#import "DCMDatabase.h"
#import "DCMImportOperation.h"
#import "MBProgressHUD.h"
#import "WallClock.h"

#if TESTFLIGHT_ENABLED

#import "TestFlight.h"

static NSString * const kTestFlightTeamToken = (@"dfa2a4e0ad7cf43"
                                                @"6bd8bf15b156896"
                                                @"b9_OTA5MTkyMDEy"
                                                @"LTA1LTE2IDE3OjA"
                                                @"wOjE4LjcyOTI5MA");

#endif

@implementation DCMAppDelegate

+ (DCMAppDelegate *)sharedDelegate
{
    return [[UIApplication sharedApplication] delegate];
}

@synthesize window = _window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSTimeZone *tz = [NSTimeZone timeZoneWithName:@"America/New_York"];
    if (tz) [NSTimeZone setDefaultTimeZone:tz];
#if TESTFLIGHT_ENABLED
    [TestFlight takeOff:kTestFlightTeamToken];
    [TestFlight setDeviceIdentifier:[[UIDevice currentDevice] uniqueIdentifier]];
#endif
    [[UINavigationBar appearance] setTintColor:
     [UIColor colorWithRed:0.8 green:0.2 blue:0.2 alpha:1]];
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
                 [hud hide:YES afterDelay:1];
             }
         }
     }];
    // Supress error messages unless the database is empty.
    DCMDatabase *db = [DCMDatabase sharedDatabase];
    [db checkForUpdateQuietly:![db isEmpty]];
    [[WallClock sharedClock] start];
    return YES;
}

@end
