//
//  Performance.h
//  DCM
//
//  Created by Benjamin Ragheb on 5/13/12.
//  Copyright (c) 2012 Heroic Software Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Show;
@class Venue;

@interface Performance : NSManagedObject

@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSDate * startDate;
@property (nonatomic, retain) NSDate * endDate;
@property (nonatomic, retain) NSNumber * minutes;
@property (nonatomic, retain) NSString * ticketsURLString;
@property (nonatomic, retain) Show *show;
@property (nonatomic, retain) Venue *venue;

@end
