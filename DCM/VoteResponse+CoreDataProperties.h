//
//  VoteResponse+CoreDataProperties.h
//  DCM
//
//  Created by Kurt Guenther on 6/25/16.
//  Copyright © 2016 Upright Citizens Brigade LLC. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "VoteResponse.h"

NS_ASSUME_NONNULL_BEGIN

@interface VoteResponse (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *message;

@end

NS_ASSUME_NONNULL_END
