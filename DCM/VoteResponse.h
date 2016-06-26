//
//  VoteResponse.h
//  DCM
//
//  Created by Kurt Guenther on 6/25/16.
//  Copyright © 2016 Upright Citizens Brigade LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "DCMDatabase.h"

NS_ASSUME_NONNULL_BEGIN

@interface VoteResponse : NSManagedObject

+ (VoteResponse*) randomResponse:(DCMDatabase*)database;

@end

NS_ASSUME_NONNULL_END

#import "VoteResponse+CoreDataProperties.h"
