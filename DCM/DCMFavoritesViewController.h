//
//  DCMFavoritesViewController.h
//  DCM
//
//  Created by Kurt Guenther on 5/19/12.
//  Copyright (c) 2012 Heroic Software Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DCMFavoritesViewController : UITableViewController <NSFetchedResultsControllerDelegate>
{
    NSFetchedResultsController *performancesController;
}

@end
