//
//  DCMVenuesMapViewController.m
//  DCM
//
//  Created by Darren Levy on 5/3/15.
//  Copyright (c) 2015 Heroic Software Inc. All rights reserved.
//

#import "DCMVenuesMapViewController.h"
#import "Venue.h"
#import "DCMVenueViewController.h"

@interface DCMVenuesMapViewController ()

@end

@implementation DCMVenuesMapViewController
@synthesize mapView;
@synthesize venues;
Venue *selectedVenue;

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Venue Map";
    self.mapView.delegate = self;
    MKMapRect mapRect = MKMapRectNull;
    for (Venue *venue in venues) {
        MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
        CLLocationDegrees latitude = [venue.latitude doubleValue];
        CLLocationDegrees longitude = [venue.longitude doubleValue];
        [annotation setCoordinate:CLLocationCoordinate2DMake(latitude, longitude)];
        [annotation setTitle:venue.name];
        [self.mapView addAnnotation:annotation];
        MKMapPoint mapPoint = MKMapPointForCoordinate(annotation.coordinate);
        MKMapRect pointRect = MKMapRectMake(mapPoint.x, mapPoint.y, 0, 0);
        mapRect = MKMapRectUnion(mapRect, pointRect);
    }
    [self.mapView setVisibleMapRect:mapRect edgePadding:UIEdgeInsetsMake(100, 100, 100, 100) animated:NO];
}

-(void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    //Figure out which venue was selected
    for (Venue *venue in venues) {
        if ([view.annotation.title isEqualToString:venue.name]) {
            selectedVenue = venue;
            break;
        }
    }
    if (selectedVenue != nil) {
        [self performSegueWithIdentifier:@"mapToVenue" sender:self];
    }
    
}

- (MKAnnotationView *)mapView:(MKMapView *)sender viewForAnnotation:(id < MKAnnotation >)annotation
{
    NSString *annotationId = @"venuePin";
    MKPinAnnotationView *annotationView = (MKPinAnnotationView *)[sender dequeueReusableAnnotationViewWithIdentifier:annotationId];
    if (annotationView == nil) {
        annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:annotationId];
        annotationView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        annotationView.canShowCallout = YES;
    }
    annotationView.annotation = annotation;
    
    return annotationView;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    DCMVenueViewController *viewController = [segue destinationViewController];
    viewController.venue = selectedVenue;
}

@end
