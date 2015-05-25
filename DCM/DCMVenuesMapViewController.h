//
//  DCMVenuesMapViewController.h
//  DCM
//
//  Created by Darren Levy on 5/3/15.
//  Copyright (c) 2015 Upright Citizens Brigade LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface DCMVenuesMapViewController : UIViewController <MKMapViewDelegate>

@property (strong, nonatomic) IBOutlet MKMapView *mapView;

@end