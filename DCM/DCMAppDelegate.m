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

#import <Fabric/Fabric.h>
#import <Answers/Answers.h>


@implementation DCMAppDelegate

+ (DCMAppDelegate *)sharedDelegate
{
    return (DCMAppDelegate *)[[UIApplication sharedApplication] delegate];
}

@synthesize window = _window;

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [Fabric with:@[[Answers class]]];
    
    NSTimeZone *nyZone = [NSTimeZone timeZoneWithName:@"America/New_York"];
    if (nyZone) {
        [NSTimeZone setDefaultTimeZone:nyZone];
    } else {
        NSLog(@"Time Zone 'America/New_York' not found!");
    }

    return YES;
}

- (BOOL)application:(UIApplication *)application shouldRestoreApplicationState:(NSCoder *)coder
{
    NSString *bundleVersion = [coder decodeObjectForKey:UIApplicationStateRestorationBundleVersionKey];
    NSString *systemVersion = [coder decodeObjectForKey:UIApplicationStateRestorationSystemVersionKey];
    NSDate *timestamp = [coder decodeObjectForKey:UIApplicationStateRestorationTimestampKey];

    NSLog(@"Restoring app state saved by app version %@ under system %@ on %@", bundleVersion, systemVersion, timestamp);

    return YES;
}

- (BOOL)application:(UIApplication *)application shouldSaveApplicationState:(NSCoder *)coder
{
    return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
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
                 if(activity.length){
                     hud.mode = MBProgressHUDModeText;
                     [hud hide:YES afterDelay:1];
                 } else {
                     [hud hide:YES];
                 }
             }
         }
     }];

    // Red #ed4b59
    self.window.tintColor = [UIColor colorWithRed:0.929
                                            green:0.294
                                             blue:0.349
                                            alpha:1.000];

    // Suppress error messages unless the database is empty.
    DCMDatabase *db = [DCMDatabase sharedDatabase];
    [db checkForUpdateQuietly:![db isEmpty]];

    [[WallClock sharedClock] start];

    return YES;
}

@end
