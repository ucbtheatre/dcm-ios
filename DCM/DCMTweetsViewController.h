//
//  DCMTweetsViewController.h
//  DCM
//
//  Created by Benjamin Ragheb on 6/16/13.
//  Copyright (c) 2013 Upright Citizens Brigade LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DCMTweetsViewController : UIViewController <UIWebViewDelegate>
@property (nonatomic, strong) IBOutlet UIWebView *webView;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *refreshButton;
- (IBAction)refreshTweets:(id)sender;
@end
