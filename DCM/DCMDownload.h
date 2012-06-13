//
//  DCMDownload.h
//  DCM
//
//  Created by Benjamin Ragheb on 6/12/12.
//  Copyright (c) 2012 Heroic Software Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DCMDatabase;

@interface DCMDownload : NSObject <NSURLConnectionDataDelegate>
{
    DCMDatabase *database;
    NSMutableData *rawData;
    NSInteger statusCode;
    NSInteger expectedLength;
    NSString *eTag;
}
- (id)initWithDatabase:(DCMDatabase *)aDatabase;
@end
