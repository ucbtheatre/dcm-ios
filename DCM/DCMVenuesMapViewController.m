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
#import "DCMVenuesListViewController.h"

@implementation DCMVenuesMapViewController
{
    NSDictionary<NSValue *, NSArray<Venue *> *> *venuesForCoordinate;
    MKMapRect defaultMapRect;
}

@synthesize mapView;

/**
 * Finds a common prefix of all given venue names.
 */
+ (NSString *)titleForVenues:(NSArray<Venue *> *)array
{
    NSString *name = [[array firstObject] shortName];
    for (NSUInteger i = 1; i < [array count]; i++) {
        NSString *otherName = [[array objectAtIndex:i] shortName];
        name = [name commonPrefixWithString:otherName
                                    options:NSCaseInsensitiveSearch];
    }

    // The last character is probably a space or a dash; trim it.
    NSCharacterSet *trimSet = [[NSCharacterSet alphanumericCharacterSet] invertedSet];
    name = [name stringByTrimmingCharactersInSet:trimSet];

    if ([name length] > 0) {
        return name;
    } else {
        // If for some reason there is no common prefix, fall back to a count.
        return @"All Stages";
    }
}

- (void)setUpControllerForDatabase:(DCMDatabase *)database
{
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Venue"];
    NSError *error = nil;

    NSArray<Venue *> *allVenues = [[database managedObjectContext]
                                   executeFetchRequest:request
                                   error:&error];
    if (error) {
        NSLog(@"venue fetch error: %@", error);
    }

    // Build a map from coordinates to arrays of venues.

    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:[allVenues count]];

    for (Venue *venue in allVenues) {
        CLLocationCoordinate2D coord = venue.coordinate;
        NSValue *key = [NSValue valueWithMKCoordinate:coord];
        NSArray<Venue *> *array = [dict objectForKey:key];
        if (array) {
            array = [array arrayByAddingObject:venue];
        } else {
            array = [NSArray arrayWithObject:venue];
        }
        [dict setObject:array forKey:key];
    }

    venuesForCoordinate = [dict copy];
}

- (void)awakeFromNib
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];

    [center addObserver:self selector:@selector(databaseWillChange:)
                   name:DCMDatabaseWillChangeNotification object:nil];
    [center addObserver:self selector:@selector(databaseDidChange:)
                   name:DCMDatabaseDidChangeNotification object:nil];

    [super awakeFromNib];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)databaseWillChange:(NSNotification *)notification
{
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

    for (NSValue *key in venuesForCoordinate) {
        NSArray<Venue *> *array = [venuesForCoordinate objectForKey:key];
        
        //if we have locations that don't have a lat/long it screws up our calculation
        if([[array firstObject] latitude] != nil &&
           [[array firstObject] longitude] != nil){
            MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
            [annotation setCoordinate:[key MKCoordinateValue]];
            [annotation setTitle:[DCMVenuesMapViewController titleForVenues:array]];
            [annotation setSubtitle:[[array firstObject] address]];

            [self.mapView addAnnotation:annotation];

            MKMapPoint mapPoint = MKMapPointForCoordinate(annotation.coordinate);
            MKMapRect pointRect = MKMapRectMake(mapPoint.x, mapPoint.y, 0, 0);
            defaultMapRect = MKMapRectUnion(defaultMapRect, pointRect);
        }
    }
}

- (void)showVenues:(NSArray<Venue *> *)venueList
{
    if ([venueList count] == 1) {
        [self performSegueWithIdentifier:@"MapToSchedule" sender:[venueList firstObject]];
        return;
    }

    NSSortDescriptor *byName = [NSSortDescriptor sortDescriptorWithKey:@"shortName" ascending:YES];
    NSArray *sortedVenueList = [venueList sortedArrayUsingDescriptors:@[byName]];

    [self performSegueWithIdentifier:@"MapToVenueList" sender:sortedVenueList];
}

- (void)showListView
{
    NSMutableArray<Venue *> *allVenues = [NSMutableArray array];

    for (NSArray<Venue *> *array in [venuesForCoordinate allValues]) {
        [allVenues addObjectsFromArray:array];
    }

    [self showVenues:allVenues];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.mapView.delegate = self;

    [self setUpControllerForDatabase:[DCMDatabase sharedDatabase]];
    [self annotateMap];
}

- (void)viewDidLayoutSubviews
{
    [self resetMapRect:nil];
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    CLLocationCoordinate2D coordinate = [view.annotation coordinate];
    NSValue *key = [NSValue valueWithMKCoordinate:coordinate];
    NSArray<Venue *> *venueList = [venuesForCoordinate objectForKey:key];

    [self showVenues:venueList];
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
    if ([[segue identifier] isEqualToString:@"MapToSchedule"]) {
        DCMVenueScheduleViewController *viewController = [segue destinationViewController];
        viewController.venue = sender;
    }
    else if ([[segue identifier] isEqualToString:@"MapToVenueList"])
    {
        DCMVenuesListViewController *viewController = [segue destinationViewController];
        viewController.title = [DCMVenuesMapViewController titleForVenues:sender];
        viewController.venueList = sender;
    }
}

@end
