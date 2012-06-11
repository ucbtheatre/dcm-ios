//
//  LabelSetView.h
//  DCM
//
//  Created by Benjamin Ragheb on 6/10/12.
//  Copyright (c) 2012 Heroic Software Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

/* A custom view to manage layout of a set of UILabels. */

@interface LabelSetView : UIView
@property (nonatomic) UIEdgeInsets margin;
@property (nonatomic) CGFloat verticalSpacing;
- (void)addLabelWithText:(NSString *)text font:(UIFont *)font;
@end
