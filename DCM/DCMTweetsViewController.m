//
//  DCMTweetsViewController.m
//  DCM
//
//  Created by Benjamin Ragheb on 6/16/13.
//  Copyright (c) 2013 Upright Citizens Brigade LLC. All rights reserved.
//

#import "DCMTweetsViewController.h"

@implementation DCMTweetsViewController

- (void)dealloc
{
    self.webView.delegate = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if (self.webView.request == nil) {
        NSURL *URL = [[NSBundle mainBundle] URLForResource:@"DCMTweets" withExtension:@"html"];
        [self.webView loadRequest:[NSURLRequest requestWithURL:URL]];
    }
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSURL *URL = [request URL];
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        NSLog(@"User clicked %@", URL);
        [[UIApplication sharedApplication] openURL:URL];
        return NO;
    }
    return YES;
}

@end
