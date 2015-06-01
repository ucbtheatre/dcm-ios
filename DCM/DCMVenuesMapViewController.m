//
//  DCMVenuesMapViewController.m
//  DCM
//
//  Created by Darren Levy on 5/3/15.
//  Copyright (c) 2015 Upright Citizens Brigade LLC. All rights reserved.
//

#import "DCMDatabase.h"
#import "DCMVenuesMapViewController.h"
#import "Venue.h"
#import "DCMVenueScheduleViewController.h"

@implementation DCMVenuesMapViewController
{
    NSArray *allVenues;
    Venue *selectedVenue;
    MKMapRect defaultMapRect;
}

@synthesize mapView;

- (void)setUpControllerForDatabase:(DCMDatabase *)database
{
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Venue"];
    NSError *error = nil;

    allVenues = [[database managedObjectContext]
                 executeFetchRequest:request
                 error:&error];
    if (error) {
        NSLog(@"venue fetch error: %@", error);
    }
}

- (void)awakeFromNib
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(databaseWillChange:)
                   name:DCMDatabaseWillChangeNotification object:nil];
    [center addObserver:self selector:@selector(databaseDidChange:)
                   name:DCMDatabaseDidChangeNotification object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)databaseWillChange:(NSNotification *)notification
{
    allVenues = nil;
    selectedVenue = nil;
    if ([self isViewLoaded]) {
        [self.mapView removeAnnotations:[self.mapView annotations]];
        [self.navigationController popToViewController:self animated:YES];
    }
}

- (void)databaseDidChange:(NSNotification *)notification
{
    [self setUpControllerForDatabase:[notification object]];
    if ([self isViewLoaded]) {
        [self annotateMap];
    }
}

- (void)resetMapRect:(id)sender
{
    [self.mapView setVisibleMapRect:defaultMapRect
                        edgePadding:UIEdgeInsetsMake(100, 100, 100, 100)
                           animated:(sender != nil)];
}

- (void)annotateMap
{
    defaultMapRect = MKMapRectNull;
    for (Venue *venue in allVenues) {
        MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
        [annotation setCoordinate:venue.coordinate];
        [annotation setTitle:venue.name];
        [self.mapView addAnnotation:annotation];
        MKMapPoint mapPoint = MKMapPointForCoordinate(annotation.coordinate);
        MKMapRect pointRect = MKMapRectMake(mapPoint.x, mapPoint.y, 0, 0);
        defaultMapRect = MKMapRectUnion(defaultMapRect, pointRect);
    }
    [self resetMapRect:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.mapView.delegate = self;

    [self setUpControllerForDatabase:[DCMDatabase sharedDatabase]];
    [self annotateMap];
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    // Figure out which venue was selected
    for (Venue *venue in allVenues) {
        if ([view.annotation.title isEqualToString:venue.name]) {
            selectedVenue = venue;
            break;
        }
    }
    if (selectedVenue != nil) {
        [self performSegueWithIdentifier:@"MapToSchedule" sender:self];
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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    DCMVenueScheduleViewController *viewController = [segue destinationViewController];
    viewController.venue = selectedVenue;
}

@end
