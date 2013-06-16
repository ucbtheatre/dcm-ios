//
//  DCMUtilities.h
//  DCM
//
//  Created by Benjamin Ragheb on 6/16/13.
//  Copyright (c) 2013 Heroic Software Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^DCMImageHandler)(UIImage *image);

void DCMLoadImageAsynchronously(NSURL *imageURL, DCMImageHandler imageHandler);
