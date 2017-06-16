//
//  DCMTableSectionHeaderView.m
//  DCM
//
//  Created by Benjamin Ragheb on 6/15/17.
//  Copyright © 2017 Upright Citizens Brigade LLC. All rights reserved.
//

#import "DCMTableSectionHeaderView.h"

@implementation DCMTableSectionHeaderView
{
    UILabel *_label;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {
        self.backgroundColor = [UIColor colorWithRed:0.565
                                               green:0.784
                                                blue:0.749
                                               alpha:1.000];

        self.opaque = YES;
        self.autoresizesSubviews = YES;

        UILabel *label = [[UILabel alloc] initWithFrame:CGRectInset(frame, 10, 0)];
        label.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                  UIViewAutoresizingFlexibleHeight);
        label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle2];
        label.textColor = [UIColor whiteColor];
        label.backgroundColor = self.backgroundColor;
        label.opaque = YES;

        [self addSubview:label];

        _label = label;
    }
    return self;
}

- (NSString *)title
{
    return _label.text;
}

- (void)setTitle:(NSString *)title
{
    _label.text = title;
}

@end
