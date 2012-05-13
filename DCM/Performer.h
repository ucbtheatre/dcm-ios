//
//  Performer.h
//  DCM
//
//  Created by Benjamin Ragheb on 5/13/12.
//  Copyright (c) 2012 Heroic Software Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Performer : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *shows;
@end

@interface Performer (CoreDataGeneratedAccessors)

- (void)addShowsObject:(NSManagedObject *)value;
- (void)removeShowsObject:(NSManagedObject *)value;
- (void)addShows:(NSSet *)values;
- (void)removeShows:(NSSet *)values;

@end
