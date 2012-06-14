//
//  DCMShowDetailViewController.h
//  DCM
//
//  Created by Benjamin Ragheb on 5/13/12.
//  Copyright (c) 2012 Heroic Software Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DCMTableViewController.h"

@class Show;

@interface DCMShowDetailViewController : DCMTableViewController
{
    NSArray *performers;
    NSArray *performances;
}
@property (strong, nonatomic) Show *show;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *favoriteButton;
- (IBAction)toggleFavorite:(id)sender;
@end
