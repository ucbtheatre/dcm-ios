//
//  DCMImportOperation.h
//  DCM
//
//  Created by Benjamin Ragheb on 5/13/12.
//  Copyright (c) 2012 Upright Citizens Brigade LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DCMImportOperation : NSObject
- (id)initWithData:(NSData *)data context:(NSManagedObjectContext *)context;
- (BOOL)performImport;
@end
