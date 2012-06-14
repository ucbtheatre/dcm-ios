//
//  DCMImportOperation.h
//  DCM
//
//  Created by Benjamin Ragheb on 5/13/12.
//  Copyright (c) 2012 Heroic Software Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DCMImportOperation : NSObject
{
    NSData *rawData;
    NSMutableDictionary *performerCache;
    NSCache *objectCache;
    NSUInteger numberOfObjectsToImport;
    NSUInteger numberOfObjectsImported;
    NSDate *lastProgressNotificationDate;
    NSManagedObjectContext *managedObjectContext;
}
- (id)initWithData:(NSData *)data context:(NSManagedObjectContext *)context;
- (BOOL)performImport;
@end
