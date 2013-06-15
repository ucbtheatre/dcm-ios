//
//  DCMDownload.m
//  DCM
//
//  Created by Benjamin Ragheb on 6/12/12.
//  Copyright (c) 2012 Upright Citizens Brigade LLC. All rights reserved.
//

#import "DCMDownload.h"
#import "DCMDatabase.h"

@implementation DCMDownload

- (id)initWithDatabase:(DCMDatabase *)aDatabase
{
    if ((self = [super init])) {
        database = aDatabase;
    }
    return self;
}

- (void)postNotificationOfProgress:(float)progress activity:(NSString *)activity
{
    [[NSNotificationCenter defaultCenter]
     postNotificationName:DCMDatabaseProgressNotification
     object:database
     userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
               activity,
               DCMDatabaseActivityKey,
               [NSNumber numberWithFloat:progress],
               DCMDatabaseProgressKey,
               nil]];
}

- (void)postNotificationOfProgress:(float)progress
{
    [self postNotificationOfProgress:progress activity:@"Warming Up"];
}

- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    [[challenge sender] performDefaultHandlingForAuthenticationChallenge:challenge];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response
{
    statusCode = [response statusCode];
    expectedLength = [response expectedContentLength];
    responseHeaders = [response allHeaderFields];
    if (expectedLength == NSURLResponseUnknownLength) {
        rawData = [[NSMutableData alloc] init];
        [self postNotificationOfProgress:DCMDatabaseProgressIndeterminate];
    } else {
        rawData = [[NSMutableData alloc] initWithCapacity:expectedLength];
        [self postNotificationOfProgress:DCMDatabaseProgressNone];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [rawData appendData:data];
    if (expectedLength != NSURLResponseUnknownLength) {
        float progress = (float)[rawData length] / (float)expectedLength;
        [self postNotificationOfProgress:progress];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (statusCode == 200) {
        [database importData:rawData responseHeaders:responseHeaders];
    }
    else {
        NSString *msg;
        if (statusCode == 304) {
            msg = @"Up to Date";
        } else {
            msg = [NSHTTPURLResponse localizedStringForStatusCode:statusCode];
        }
        [self postNotificationOfProgress:DCMDatabaseProgressComplete activity:msg];
        [database endUpdate];
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if (database.shouldReportConnectionErrors) {
        [[NSNotificationCenter defaultCenter]
         postNotificationName:DCMDatabaseProgressNotification
         object:database
         userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                   error,
                   DCMDatabaseErrorKey,
                   nil]];
    }
    [database endUpdate];
}

@end
