//
//  DCMDownload.m
//  DCM
//
//  Created by Benjamin Ragheb on 6/12/12.
//  Copyright (c) 2012 Heroic Software Inc. All rights reserved.
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
    eTag = [[response allHeaderFields] objectForKey:@"ETag"];
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
        [database importData:rawData eTag:eTag];
    }
    else if (statusCode == 304) {
        [self postNotificationOfProgress:DCMDatabaseProgressComplete
                                activity:@"Up to Date"];
    }
    else {
        [self postNotificationOfProgress:DCMDatabaseProgressComplete
                                activity:[NSString stringWithFormat:@"[%d]",
                                          statusCode]];
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [[NSNotificationCenter defaultCenter]
     postNotificationName:DCMDatabaseProgressNotification
     object:database
     userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
               error,
               DCMDatabaseErrorKey,
               nil]];
}

@end
