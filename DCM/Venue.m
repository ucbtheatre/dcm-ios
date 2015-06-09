//
//  Venue.m
//  DCM
//
//  Created by Benjamin Ragheb on 5/13/12.
//  Copyright (c) 2012 Upright Citizens Brigade LLC. All rights reserved.
//

#import "Venue.h"
#import "Performance.h"


@implementation Venue

@dynamic identifier;
@dynamic name;
@dynamic shortName;
@dynamic address;
@dynamic performances;
@dynamic latitude;
@dynamic longitude;

- (CLLocationCoordinate2D)coordinate
{
    if (self.latitude && self.longitude) {
        CLLocationDegrees latitude = [self.latitude doubleValue];
        CLLocationDegrees longitude = [self.longitude doubleValue];
        return CLLocationCoordinate2DMake(latitude, longitude);
    } else {
        return kCLLocationCoordinate2DInvalid;
    }
}

- (NSDictionary *)addressDictionary
{
    if (self.address) {
        return @{(id)kABPersonAddressStreetKey: self.address};
    } else {
        return @{};
    }
}

- (MKPlacemark *)placemark
{
    CLLocationCoordinate2D coord = [self coordinate];
    if (CLLocationCoordinate2DIsValid(coord)) {
        return [[MKPlacemark alloc] initWithCoordinate:coord addressDictionary:self.addressDictionary];
    } else {
        return nil;
    }
}

- (MKMapItem *)mapItem
{
    MKPlacemark *mark = [self placemark];
    if (mark) {
        return [[MKMapItem alloc] initWithPlacemark:mark];
    } else {
        return nil;
    }
}

@end
