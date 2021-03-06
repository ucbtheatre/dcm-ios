//
//  Performer.h
//  DCM
//
//  Created by Benjamin Ragheb on 5/13/12.
//  Copyright (c) 2012 Upright Citizens Brigade LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface Performer : NSManagedObject

@property (nonatomic, strong) NSNumber *identifier;
@property (nonatomic, strong) NSSet *shows;
@property (nonatomic, strong) NSString *firstInitial;
@property (nonatomic, strong) NSString *firstName;
@property (nonatomic, strong) NSString *lastInitial;
@property (nonatomic, strong) NSString *lastName;
@property (nonatomic, strong) NSString *foldedName;

@property (nonatomic, readonly) NSAttributedString *attributedFullName;

+ (NSArray *)standardSortDescriptors;
+ (NSString *)sectionNameKeyPath;

- (void)setFirstName:(NSString *)firstName lastName:(NSString *)lastName;

@end

@interface Performer (CoreDataGeneratedAccessors)
- (void)addShowsObject:(NSManagedObject *)value;
- (void)removeShowsObject:(NSManagedObject *)value;
- (void)addShows:(NSSet *)values;
- (void)removeShows:(NSSet *)values;
@end
