//
//  DCMFavoritesViewController.m
//  DCM
//
//  Created by Kurt Guenther on 5/19/12.
//  Copyright (c) 2012 Heroic Software Inc. All rights reserved.
//

#import "DCMFavoritesViewController.h"

@interface DCMFavoritesViewController ()

@end

@implementation DCMFavoritesViewController

- (NSPredicate *)predicate
{
    return [NSPredicate predicateWithFormat:@"favorite = TRUE"];
}

@end
