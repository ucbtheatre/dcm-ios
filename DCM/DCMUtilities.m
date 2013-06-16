//
//  DCMUtilities.m
//  DCM
//
//  Created by Benjamin Ragheb on 6/16/13.
//  Copyright (c) 2013 Heroic Software Inc. All rights reserved.
//

#import "DCMUtilities.h"

void DCMLoadImageAsynchronously(NSURL *imageURL, DCMImageHandler imageHandler)
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^(void) {
        NSURLRequest *request = [NSURLRequest requestWithURL:imageURL
                                                 cachePolicy:NSURLRequestReturnCacheDataElseLoad
                                             timeoutInterval:60];
        NSHTTPURLResponse *response = nil;
        NSError *error = nil;
        NSData *imageData = [NSURLConnection sendSynchronousRequest:request
                                                  returningResponse:&response
                                                              error:&error];
        UIImage *image = nil;
        if (imageData != nil && response.statusCode == 200) {
            image = [UIImage imageWithData:imageData];
            if (image == nil) {
                NSString *contentType = response.allHeaderFields[@"Content-Type"];
                NSLog(@"Data from %@ wasn't a recognized image format; server reported Content-Type: %@.", imageURL, contentType);
            }
        } else if (error) {
            NSLog(@"Failed to load data from %@, error: %@", imageURL, error);
        } else {
            NSLog(@"Failed to load data from %@, HTTP %d, headers: %@", imageURL, response.statusCode, response.allHeaderFields);
        }
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            imageHandler(image);
        });
    });
}
