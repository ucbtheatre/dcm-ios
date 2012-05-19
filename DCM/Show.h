//
//  Show.h
//  DCM
//
//  Created by Benjamin Ragheb on 5/13/12.
//  Copyright (c) 2012 Heroic Software Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Performance, Performer;

@interface Show : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * promoBlurb;
@property (nonatomic, retain) NSString * homeCity;
@property (nonatomic, retain) NSNumber *identifier;

@property (nonatomic, retain) NSSet *performers;
@property (nonatomic, retain) NSSet *performances;

@property (nonatomic, retain) NSString *sortName;
@property (nonatomic, retain) NSString *sortSection;


@property (nonatomic, readonly) BOOL favorite;

@end

@interface Show (CoreDataGeneratedAccessors)

- (void)addPerformersObject:(Performer *)value;
- (void)removePerformersObject:(Performer *)value;
- (void)addPerformers:(NSSet *)values;
- (void)removePerformers:(NSSet *)values;

- (void)addPerformancesObject:(Performance *)value;
- (void)removePerformancesObject:(Performance *)value;
- (void)addPerformances:(NSSet *)values;
- (void)removePerformances:(NSSet *)values;


@end
