//
//  DCMOffersViewController.m
//  DCM
//
//  Created by Benjamin Ragheb on 6/18/18.
//  Copyright © 2018 Upright Citizens Brigade LLC. All rights reserved.
//

#import "DCMOffersViewController.h"

@implementation DCMOffersViewController

- (void)dealloc
{
    self.webView.delegate = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if (self.webView.request == nil) {
        NSURL *URL = [NSURL URLWithString:@"http://delclosemarathon.com/offersjwdgl0r797"];
        [self.webView loadRequest:[NSURLRequest requestWithURL:URL]];
    }
}

#pragma mark - UIWebViewDelegate

/**
 * If the user tapped on a link, ask the system to open the URL in Safari
 * rather than inside this app.
 */
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
