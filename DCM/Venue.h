//
//  Venue.h
//  DCM
//
//  Created by Benjamin Ragheb on 5/13/12.
//  Copyright (c) 2012 Upright Citizens Brigade LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Performance;

@interface Venue : NSManagedObject

@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * shortName;
@property (nonatomic, retain) NSString * address;
@property (nonatomic, retain) NSString * directions;
@property (nonatomic, retain) NSString * imageURLString;
@property (nonatomic, retain) NSString * mapURLString;
@property (nonatomic, retain) NSString * homeURLString;
@property (nonatomic, retain) NSSet *performances;
@property (nonatomic, retain) NSNumber *latitude;
@property (nonatomic, retain) NSNumber *longitude;

@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic, readonly) MKMapItem *mapItem;

@end

@interface Venue (CoreDataGeneratedAccessors)

- (void)addPerformancesObject:(Performance *)value;
- (void)removePerformancesObject:(Performance *)value;
- (void)addPerformances:(NSSet *)values;
- (void)removePerformances:(NSSet *)values;

@end
