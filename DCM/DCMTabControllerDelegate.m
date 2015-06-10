//
//  DCMTabControllerDelegate.m
//  DCM
//
//  Created by Benjamin Ragheb on 6/9/15.
//  Copyright (c) 2015 Upright Citizens Brigade LLC. All rights reserved.
//

#import "DCMTabControllerDelegate.h"

static NSString * const kDCMTabOrderKey = @"DCMTabOrder";

@implementation DCMTabControllerDelegate

- (void)setTabIdentifiers:(NSArray *)array
{
    [[NSUserDefaults standardUserDefaults]
     setObject:array forKey:kDCMTabOrderKey];
}

- (NSArray *)tabIdentifiers
{
    return [[NSUserDefaults standardUserDefaults]
            arrayForKey:kDCMTabOrderKey];
}

- (NSArray *)sortedViewControllers:(NSArray *)viewControllers usingRestorationIdentifiers:(NSArray *)tabIdentifiers
{
    NSComparator cmp = ^NSComparisonResult(id obj1, id obj2) {
        id identifier1 = [obj1 restorationIdentifier];
        id identifier2 = [obj2 restorationIdentifier];

        NSUInteger index1 = [tabIdentifiers indexOfObject:identifier1];
        NSUInteger index2 = [tabIdentifiers indexOfObject:identifier2];

        if (index1 < index2) return NSOrderedAscending;
        if (index1 > index2) return NSOrderedDescending;
        return NSOrderedSame;
    };
    return [viewControllers sortedArrayUsingComparator:cmp];
}

- (void)awakeFromNib
{
    NSArray *tabIdentifiers = [self tabIdentifiers];
    if (tabIdentifiers) {
        UITabBarController *tabBarController = self.tabBarController;
        NSArray *array = tabBarController.viewControllers;

        array = [self sortedViewControllers:array
                usingRestorationIdentifiers:tabIdentifiers];

        tabBarController.viewControllers = array;
    }
}

- (void)tabBarController:(UITabBarController *)tabBarController didEndCustomizingViewControllers:(NSArray *)viewControllers changed:(BOOL)changed
{
    if (changed) {
        NSArray *identifiers = [viewControllers valueForKey:
                                @"restorationIdentifier"];

        [self setTabIdentifiers:identifiers];
    }
}

@end
