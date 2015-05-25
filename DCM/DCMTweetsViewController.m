//
//  DCMTweetsViewController.m
//  DCM
//
//  Created by Benjamin Ragheb on 6/16/13.
//  Copyright (c) 2013 Upright Citizens Brigade LLC. All rights reserved.
//

#import "DCMTweetsViewController.h"

@implementation DCMTweetsViewController

- (void)viewDidUnload
{
    self.webView.delegate = nil;
    self.webView = nil;
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    if (self.webView.request == nil) {
        NSURL *URL = [[NSBundle mainBundle] URLForResource:@"DCMTweets" withExtension:@"html"];
        [self.webView loadRequest:[NSURLRequest requestWithURL:URL]];
    }
}

- (void)refreshTweets:(id)sender
{
    [self.webView reload];
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
    if ([[URL host] isEqualToString:@"twitter.com"]) {
        NSRange r = [[request.URL path] rangeOfString:@"/intent"];
        if (r.location == 0) {
            NSLog(@"Bouncing request for %@", URL);
            [[UIApplication sharedApplication] openURL:URL];
            return NO;
        }
    }
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    self.refreshButton.enabled = NO;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    self.refreshButton.enabled = YES;
}

@end
