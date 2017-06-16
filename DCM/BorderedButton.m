//
//  BorderedButton.m
//  DCM
//
//  Created by Benjamin Ragheb on 6/15/17.
//  Copyright © 2017 Upright Citizens Brigade LLC. All rights reserved.
//

#import "BorderedButton.h"

@implementation BorderedButton

- (void)didMoveToSuperview
{
    self.layer.borderWidth = 1.0f;
    self.layer.cornerRadius = 5.0f;
    self.layer.borderColor = [self.tintColor CGColor];
}

- (void)tintColorDidChange
{
    [super tintColorDidChange];

    self.layer.borderColor = [self.tintColor CGColor];
}

@end
