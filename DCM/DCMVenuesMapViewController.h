//
//  DCMVenuesMapViewController.h
//  DCM
//
//  Created by Darren Levy on 5/3/15.
//  Copyright (c) 2015 Heroic Software Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface DCMVenuesMapViewController : UIViewController <MKMapViewDelegate>

@property (strong, nonatomic) IBOutlet MKMapView *mapView;

@end