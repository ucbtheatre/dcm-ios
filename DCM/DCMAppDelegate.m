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
    // Override point for customization after application launch.
    [[NSNotificationCenter defaultCenter]
     addObserverForName:DCMImportProgressNotification object:nil
     queue:[NSOperationQueue mainQueue]
     usingBlock:^(NSNotification *note) {
         NSError *error = [[note userInfo] objectForKey:DCMImportErrorKey];
         if (error) {
             [[MBProgressHUD HUDForView:self.window] hide:YES];
             UIAlertView *alert = [[UIAlertView alloc] init];
             alert.title = @"Import Failed";
             alert.message = [error localizedDescription];
             [alert addButtonWithTitle:@"Dismiss"];
             [alert show];
         } else {
             float progress = [[[note userInfo] objectForKey:DCMImportProgressKey] floatValue];
             MBProgressHUD *hud;
             if (progress == 0) {
                 hud = [[MBProgressHUD alloc] initWithWindow:self.window];
                 hud.removeFromSuperViewOnHide = YES;
                 hud.labelText = @"Loading";
                 hud.mode = MBProgressHUDModeDeterminate;
                 [self.window addSubview:hud];
                 [hud show:YES];
             } else {
                 hud = [MBProgressHUD HUDForView:self.window];
             }
             hud.progress = progress;
             if (progress == 1) {
                 [hud hide:YES afterDelay:1];
             }
         }
     }];
    [NSTimer
     scheduledTimerWithTimeInterval:10
     target:self selector:@selector(databaseUpdateTimerDidFire:)
     userInfo:nil repeats:YES];
    return YES;
}

- (void)databaseUpdateTimerDidFire:(NSTimer *)timer
{
    DCMDatabase *database = [DCMDatabase sharedDatabase];
    [database deleteStore];
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue addOperation:[[DCMImportOperation alloc]
                         initWithDatabase:database]];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
