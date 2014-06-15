//
//  DCMDownload.h
//  DCM
//
//  Created by Benjamin Ragheb on 6/12/12.
//  Copyright (c) 2012 Upright Citizens Brigade LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DCMDatabase;

@interface DCMDownload : NSObject <NSURLConnectionDataDelegate>
- (id)initWithDatabase:(DCMDatabase *)aDatabase;
@end
