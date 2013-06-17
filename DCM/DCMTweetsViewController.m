//
//  DCMTweetsViewController.m
//  DCM
//
//  Created by Benjamin Ragheb on 6/16/13.
//  Copyright (c) 2013 Heroic Software Inc. All rights reserved.
//

#import "DCMTweetsViewController.h"

@implementation DCMTweetsViewController

- (NSURLRequest *)twitterSearchRequest
{
    NSURL *URL = [[NSBundle mainBundle] URLForResource:@"DCMTweets" withExtension:@"html"];
    return [NSURLRequest requestWithURL:URL];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.webView loadRequest:[self twitterSearchRequest]];
}

- (void)viewDidUnload
{
    self.webView.delegate = nil;
    self.webView = nil;
    [super viewDidUnload];
}

- (void)refreshTweets:(id)sender
{
    [self.webView loadRequest:[self twitterSearchRequest]];
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
            [[UIApplication sharedApplication] openURL:request.URL];
            return NO;
        }
    }
    return YES;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    NSLog(@"Load failed: %@", error);
}

@end
