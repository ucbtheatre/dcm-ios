//
//  LabelSetView.m
//  DCM
//
//  Created by Benjamin Ragheb on 6/10/12.
//  Copyright (c) 2012 Upright Citizens Brigade LLC. All rights reserved.
//

#import "LabelSetView.h"

@implementation LabelSetView

@synthesize margin;
@synthesize verticalSpacing;

- (void)addLabelWithText:(NSString *)text font:(UIFont *)font
{
    CGRect frame = UIEdgeInsetsInsetRect(self.bounds, self.margin);
    UILabel *label = [[UILabel alloc] initWithFrame:frame];
    label.text = text;
    label.font = font;
    label.numberOfLines = 0;
    [self addSubview:label];
    [self setNeedsLayout];
}

- (CGSize)sizeThatFits:(CGSize)size
{
    CGFloat height = 0;
    CGSize labelSize = CGSizeMake(size.width -
                                  self.margin.left -
                                  self.margin.right,
                                  size.height);
    for (UILabel *label in self.subviews) {
        CGSize fitSize = [label sizeThatFits:labelSize];
        height += fitSize.height;
    }
    height += (self.margin.top +
               self.verticalSpacing * ([self.subviews count] - 1) +
               self.margin.bottom);
    return CGSizeMake(size.width, height);
}

- (void)layoutSubviews
{
    CGRect labelArea = UIEdgeInsetsInsetRect(self.bounds, self.margin);
    for (UILabel *label in self.subviews) {
        CGSize usedSize = [label sizeThatFits:labelArea.size];
        CGRect labelFrame, remainder;
        CGRectDivide(labelArea, &labelFrame, &remainder,
                     usedSize.height, CGRectMinYEdge);
        label.frame = labelFrame;
        CGRect spacingRect;
        CGRectDivide(remainder, &spacingRect, &labelArea,
                     self.verticalSpacing, CGRectMinYEdge);
    }
}

@end
