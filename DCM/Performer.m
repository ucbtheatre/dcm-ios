//
//  Performer.m
//  DCM
//
//  Created by Benjamin Ragheb on 5/13/12.
//  Copyright (c) 2012 Upright Citizens Brigade LLC. All rights reserved.
//

#import "Performer.h"

@implementation Performer

@dynamic identifier;
@dynamic shows;
@dynamic firstName;
@dynamic lastName;
@dynamic firstInitial;
@dynamic lastInitial;
@dynamic foldedName;

+ (NSArray *)standardSortDescriptors
{
    switch (ABPersonGetSortOrdering()) {
        case kABPersonSortByFirstName:
            return @[
                     [NSSortDescriptor
                      sortDescriptorWithKey:@"firstInitial" ascending:YES],
                     [NSSortDescriptor
                      sortDescriptorWithKey:@"firstName"
                      ascending:YES
                      selector:@selector(localizedCaseInsensitiveCompare:)],
                     [NSSortDescriptor
                      sortDescriptorWithKey:@"lastName"
                      ascending:YES
                      selector:@selector(localizedCaseInsensitiveCompare:)]
                     ];
        case kABPersonSortByLastName:
            return @[
                     [NSSortDescriptor
                      sortDescriptorWithKey:@"lastInitial" ascending:YES],
                     [NSSortDescriptor
                      sortDescriptorWithKey:@"lastName"
                      ascending:YES
                      selector:@selector(localizedCaseInsensitiveCompare:)],
                     [NSSortDescriptor
                      sortDescriptorWithKey:@"firstName"
                      ascending:YES
                      selector:@selector(localizedCaseInsensitiveCompare:)]
                     ];
        default:
            return @[];
    }
}

+ (NSString *)sectionNameKeyPath
{
    switch (ABPersonGetSortOrdering()) {
        case kABPersonSortByFirstName:
            return @"firstInitial";
        case kABPersonSortByLastName:
            return @"lastInitial";
        default:
            return nil;
    }
}

- (void)setFirstName:(NSString *)firstName lastName:(NSString *)lastName
{
    NSCharacterSet *whitespace = [NSCharacterSet whitespaceCharacterSet];

    firstName = [firstName stringByTrimmingCharactersInSet:whitespace];
    lastName = [lastName stringByTrimmingCharactersInSet:whitespace];

    if (firstName == nil) firstName = @"";
    if (lastName == nil) lastName = @"";

    self.firstName = firstName;
    self.lastName = lastName;

    NSStringCompareOptions options = (NSCaseInsensitiveSearch |
                                      NSDiacriticInsensitiveSearch |
                                      NSWidthInsensitiveSearch);
    NSLocale *locale = [NSLocale currentLocale];

    self.foldedName = [[@[firstName, lastName] componentsJoinedByString:@" "]
                       stringByFoldingWithOptions:options locale:locale];

    if ([firstName length] > 0) {
        self.firstInitial = [[[firstName
                               stringByFoldingWithOptions:options
                               locale:locale]
                              substringToIndex:1]
                             uppercaseString];
    } else {
        self.firstInitial = @"";
    }

    if ([lastName length] > 0) {
        self.lastInitial = [[[lastName
                              stringByFoldingWithOptions:options
                              locale:locale]
                             substringToIndex:1]
                            uppercaseString];
    } else {
        self.lastInitial = @"";
    }
}

- (NSAttributedString *)attributedFullName
{
    UIFont *firstFont = [UIFont systemFontOfSize:[UIFont systemFontSize]];
    UIFont *lastFont = [UIFont boldSystemFontOfSize:[UIFont systemFontSize]];

    NSAttributedString *first, *separator, *last;

    first = [[NSAttributedString alloc]
             initWithString:self.firstName
             attributes:@{NSFontAttributeName: firstFont}];

    separator = [[NSAttributedString alloc] initWithString:@" "];

    last = [[NSAttributedString alloc]
            initWithString:self.lastName
            attributes:@{NSFontAttributeName: lastFont}];

    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] init];

    switch (ABPersonGetCompositeNameFormatForRecord(NULL)) {
        case kABPersonCompositeNameFormatFirstNameFirst:
            [string appendAttributedString:first];
            [string appendAttributedString:separator];
            [string appendAttributedString:last];
            break;
        case kABPersonCompositeNameFormatLastNameFirst:
        default:
            [string appendAttributedString:last];
            [string appendAttributedString:separator];
            [string appendAttributedString:first];
            break;
    }

    return string;
}

@end
