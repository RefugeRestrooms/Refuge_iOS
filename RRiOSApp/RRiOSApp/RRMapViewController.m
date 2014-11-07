//
//  RRMapViewController.m
//  RRiOSApp
//
//  Created by Harlan Kellaway on 10/14/14.
//  Copyright (c) 2014 ___REFUGERESTROOMS___. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

#import "RRMapViewController.h"

#import "AppDelegate.h"
#import "AppState.h"
#import "Constants.h"
#import "MBProgressHUD.h"
#import "Restroom.h"
#import "RestroomManager.h"
#import "RestroomDetailsViewController.h"
#import "RRMapKitAnnotation.h"
#import "RRMapSearchViewController.h"
#import "Reachability.h"

BOOL initialZoomComplete = NO;
BOOL syncComplete = NO;

@interface RRMapViewController ()

@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@end

@implementation RRMapViewController
{
    Reachability *internetReachability;
    CLLocationManager *locationManager;
    MBProgressHUD *hud;
    NSManagedObjectContext *context;
    BOOL internetIsAccessible;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationController.navigationBar.topItem.title = APP_NAME;
    
    if(!initialZoomComplete)
    {
    // set up mapView
    self.mapView.delegate = self;
    self.mapView.mapType = MKMapTypeStandard;
    self.mapView.showsUserLocation = YES;
    
    // set up HUD
    hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDAnimationFade;
    hud.color = [UIColor colorWithRed:RRCOLOR_DARKPURPLE_RED green:RRCOLOR_DARKPURPLE_GREEN blue:RRCOLOR_DARKPURPLE_BLUE alpha:1.0];
    hud.labelText = SYNC_TEXT;
    
    // set up location manager
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    locationManager.distanceFilter = kCLDistanceFilterNone;
    locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
    
    // set RestroomManager delegate
    RestroomManager *restroomManager = (RestroomManager *)[RestroomManager sharedInstance];
    restroomManager.delegate = self;
        
    context = ((AppDelegate *)[UIApplication sharedApplication].delegate).managedObjectContext;
        
    internetIsAccessible = YES;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if(!initialZoomComplete)
    {
    
    // prompt for location allowing
    if ([locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)])
    {
        [locationManager requestWhenInUseAuthorization];
    }
    else
    {
#pragma message "Should provide else case here that can run on iOS 7"
        // TODO: Test on iOS 7 device
    }
    
    [locationManager startUpdatingLocation];
    
    // check for Internet reachability
    internetReachability = [Reachability reachabilityWithHostname:URL_TO_TEST_REACHABILITY];
    
    __weak RRMapViewController *weakSelf = self;
    
    // Internet is reachable
    internetReachability.reachableBlock = ^(Reachability*reach)
    {
        
        dispatch_async
        (
            // update UI on main thread
            dispatch_get_main_queue(), ^
            {
                RRMapViewController *strongSelf = weakSelf;
                
                if(strongSelf)
                {
                    strongSelf->internetIsAccessible = YES;
                    
                    // if not synced yet, fetch restrooms newly created and updated
                    if(!syncComplete)
                    {
                        [[RestroomManager sharedInstance] fetchRestroomsModifiedSince:[AppState sharedInstance].dateLastSynced];
                    }
                    
                    // reset date last synced
                    [AppState sharedInstance].dateLastSynced = [NSDate date];
                    
                    syncComplete = YES;
                }
            }
         );
    };

    // Internet is not reachable
    internetReachability.unreachableBlock = ^(Reachability*reach)
    {
        // Update the UI on the main thread
        dispatch_async
        (
            dispatch_get_main_queue(), ^
            {
                RRMapViewController *strongSelf = weakSelf;
                
                if(strongSelf)
                {
                    strongSelf->internetIsAccessible = NO;
                    
                    strongSelf->hud.mode = MBProgressHUDModeText;
                    strongSelf->hud.labelText = NO_INTERNET_TEXT;
                }
            }
         );
    };
    
    [internetReachability startNotifier];
    }
}

- (void)plotRestrooms:(NSArray *)restrooms
{
    // remove existing annotations
    for (id<MKAnnotation> annotation in self.mapView.annotations)
    {
        [self.mapView removeAnnotation:annotation];
    }
    
    // add all annotations
    for (Restroom *restroom in restrooms)
    {
        CLLocationCoordinate2D coordinate;
        coordinate.latitude = [restroom.latitude doubleValue];
        coordinate.longitude = [restroom.longitude doubleValue];
    
        // create map location object
        RRMapKitAnnotation *mapLocation = [[RRMapKitAnnotation alloc] initWithName:restroom.name address:restroom.street coordinate:coordinate];
        mapLocation.restroom = restroom;
        
        // add annotation
        [self.mapView addAnnotation:mapLocation];
        
        [self mapView:self.mapView viewForAnnotation:mapLocation];
    }
}

#pragma mark - CLLocationManagerDelegate methods

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    [locationManager stopUpdatingLocation];
    
    if(!initialZoomComplete)
    {
        // zoom to initial location
        CLLocation *location = [locationManager location];
        CLLocationCoordinate2D coordinate = [location coordinate];
    
        float longitude = coordinate.longitude;
        float latitude = coordinate.latitude;
    
        CLLocationCoordinate2D zoomLocation;
        zoomLocation.latitude = latitude;
        zoomLocation.longitude= longitude;
        MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(zoomLocation, (0.5 * METERS_PER_MILE), (0.5 * METERS_PER_MILE));
    
        [self.mapView setRegion:viewRegion animated:YES];
    
        [locationManager startUpdatingLocation];
        
        initialZoomComplete = YES;
    }
}

- (void) locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    [locationManager stopUpdatingLocation];
    
    if(internetIsAccessible) { hud.labelText = NO_LOCATION_TEXT; }
    [hud hide:YES afterDelay:5];
    
    hud.labelText = SYNC_TEXT;
    [hud hide:NO];
}

#pragma mark - MKMapViewDelegate methods

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    // If it's the user location, just return nil
    if ([annotation isKindOfClass:[MKUserLocation class]])
        return nil;
    
    // Handle any custom annotations.
    if ([annotation isKindOfClass:[RRMapKitAnnotation class]])
    {
        // Try to dequeue an existing annotation view first
        MKAnnotationView *annotationView = (MKAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:REUSABLE_ANNOTATION_VIEW_IDENTIFIER];
        
        if (!annotationView)
        {
            // If an existing pin view was not available, create one.
            annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:REUSABLE_ANNOTATION_VIEW_IDENTIFIER];
            annotationView.canShowCallout = YES;
            
            // re-size pin image
            CGSize newSize = CGSizeMake(31.0f, 39.5f);
            UIGraphicsBeginImageContext(newSize);
            [[UIImage imageNamed:PIN_GRAPHIC] drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
            UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            // set pin image
            annotationView.image = newImage;
            
            // set callout
            UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
            annotationView.rightCalloutAccessoryView = rightButton;
        }
        else
        {
            annotationView.annotation = annotation;
        }
        
        return annotationView;
    }
    
    return nil;
}

-(void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    id <MKAnnotation> annotation = [view annotation];
    
    if ([[view annotation] isKindOfClass:[RRMapKitAnnotation class]])
    {
        // segue to details controller
        [self performSegueWithIdentifier:TRANSITION_NAME_RESTROOM_DETAILS sender:annotation];
        
    }
}

#pragma mark - RestroomManagerDelegate methods

- (void)didReceiveRestrooms:(NSArray *)restrooms
{
    // plot Restrooms on map
    dispatch_async
    (
     // update UI on main thread
     dispatch_get_main_queue(), ^(void)
     {
         [self plotRestrooms:restrooms];
         
         hud.mode = MBProgressHUDModeCustomView;
         hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:COMPLETION_GRAPHIC]];
         hud.labelText = COMPLETION_TEXT;
         [hud hide:YES afterDelay:1];
     }
     );
}

- (void)fetchingRestroomsFailedWithError:(NSError *)error
{;
    // display error
    hud.mode = MBProgressHUDModeText;
    hud.labelText = SYNC_ERROR_TEXT;
    hud.detailsLabelText = [NSString stringWithFormat:@"Code: %li", (long)[error code]];
}

#pragma mark - RRMapSearchDelegate methods

- (void)mapSearchPlacemarkSelected:(CLPlacemark *)placemark
{
    NSLog(@"PLACEMARK SELECTED!");
    
    [self addPlacemarkAnnotationToMap:placemark addressString:placemark.name];
    [self recenterMapToPlacemark:placemark];
}

#pragma mark - Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([[segue identifier] isEqualToString:TRANSITION_NAME_RESTROOM_DETAILS])
    {
        RestroomDetailsViewController *destinationController = [segue destinationViewController];
        
        RRMapKitAnnotation *annotation = (RRMapKitAnnotation *)sender;
        destinationController.restroom = annotation.restroom;
    }
    
    if([[segue identifier] isEqualToString:TRANSITION_NAME_MAP_SEARCH])
    {
        RRMapSearchViewController *destinationController = [segue destinationViewController];
        
        destinationController.delegate = self;
    }
}

# pragma mark - Helper methods

- (void)recenterMapToPlacemark:(CLPlacemark *)placemark
{
    MKCoordinateRegion region;
    MKCoordinateSpan span;

    span.latitudeDelta = 0.02;
    span.longitudeDelta = 0.02;

    region.span = span;
    region.center = placemark.location.coordinate;

    [self.mapView setRegion:region];
}

- (void)addPlacemarkAnnotationToMap:(CLPlacemark *)placemark addressString:(NSString *)address
{
//    [self.mapView removeAnnotation:selectedPlaceAnnotation];

    MKPointAnnotation *selectedPlaceAnnotation = [[MKPointAnnotation alloc] init];
    selectedPlaceAnnotation.coordinate = placemark.location.coordinate;
    selectedPlaceAnnotation.title = address;
    
    [self.mapView addAnnotation:selectedPlaceAnnotation];
}

//- (void)dismissSearchControllerWhileStayingActive
//{
//    // Animate out the table view.
//    NSTimeInterval animationDuration = 0.3;
//    [UIView beginAnimations:nil context:NULL];
//    [UIView setAnimationDuration:animationDuration];
//    self.searchDisplayController.searchResultsTableView.alpha = 0.0;
//    [UIView commitAnimations];
//
//    [self.searchDisplayController.searchBar setShowsCancelButton:NO animated:YES];
//    [self.searchDisplayController.searchBar resignFirstResponder];
//}

@end