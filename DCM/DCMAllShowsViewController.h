//
//  DCMAllShowsViewController.h
//  DCM
//
//  Created by Benjamin Ragheb on 5/12/12.
//  Copyright (c) 2012 Upright Citizens Brigade LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DCMTableViewController.h"

@interface DCMAllShowsViewController : DCMTableViewController <UISearchBarDelegate, UISearchDisplayDelegate>
- (IBAction)refresh:(id)sender;
@end
