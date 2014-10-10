//
//  MainViewController.m
//  Findstroem
//
//  Created by Ibrahim Yildirim on 09/10/14.
//  Copyright (c) 2014 Ibrahim Yildirim. All rights reserved.
//

#import "MainViewController.h"
#import "HomeModel.h"
#import <MapKit/MapKit.h>
#import <POP/POP.h>
#import "KPGridClusteringAlgorithm.h"
#import "KPClusteringController.h"
#import "Annotation.h"
#import "Location.h"
#import "KPAnnotation.h"

@interface MainViewController ()<HomeModalProtocol, MKMapViewDelegate, KPClusteringControllerDelegate>
{
    BOOL _showDetailView;
    Location *_selectedLocation;
}

@property (strong, nonatomic) HomeModel *homeModal;
@property (strong, nonatomic) NSArray *arrShopData;
@property (strong, nonatomic) KPClusteringController *clusteringController;
@property (strong, nonatomic) NSMutableArray *arrAnnotations;


@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UILabel* lblLoadingStatus;

//Properties for detail view
@property (weak, nonatomic) IBOutlet UIView *vwDetail;
@property (weak, nonatomic) IBOutlet UILabel *lblDetailName;
@property (weak, nonatomic) IBOutlet UILabel *lblDetailAdress;
@property (weak, nonatomic) IBOutlet UILabel *lblDetailCity;
@property (weak, nonatomic) IBOutlet UILabel *lblDetailHours;

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    _homeModal = [[HomeModel alloc] init];
    _homeModal.delegate = self;
    [_homeModal downloadItems];
    
    self.mapView.delegate = self;
    
    KPGridClusteringAlgorithm *algorithm = [KPGridClusteringAlgorithm new];
    algorithm.annotationSize = CGSizeMake(25, 50);
    algorithm.clusteringStrategy = KPGridClusteringAlgorithmStrategyTwoPhase;
    
    self.clusteringController = [[KPClusteringController alloc] initWithMapView:self.mapView clusteringAlgorithm:algorithm];
    self.clusteringController.delegate = self;
    self.clusteringController.animationOptions = UIViewAnimationOptionCurveEaseOut;
    
    self.mapView.showsUserLocation = YES;
    self.mapView.rotateEnabled = NO;
    
    _showDetailView = NO;
}

-(void)viewDidAppear:(BOOL)animated
{

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - HomeModel Delegate
-(void)itemsDownloaded:(NSArray *)items
{
    _lblLoadingStatus.text = @"Items Loaded!";
    
    _arrShopData = items;
    
    //Load items to map
    if(_arrShopData != nil)
        [self.clusteringController setAnnotations:[self annotations]];
}

#pragma mark - Clustering
-(NSArray *)annotations {
    // build an NYC and SF cluster
    
    _arrAnnotations = [NSMutableArray array];
    
    for (int i = 0; i < _arrShopData.count ; i++)
    {
        CLLocationCoordinate2D coordinates;
        coordinates.latitude = [((Location *)_arrShopData[i]).latitude doubleValue];
        coordinates.longitude = [((Location *)_arrShopData[i]).longitude doubleValue];
        
        KPAnnotation *annotion = [[KPAnnotation alloc] init];
        annotion.coordinate = coordinates;
        
        [_arrAnnotations addObject:annotion];
    }
    
    return _arrAnnotations;
}

- (void)clusteringController:(KPClusteringController *)clusteringController configureAnnotationForDisplay:(KPAnnotation *)annotation
{
    //    annotation.title = [NSString stringWithFormat:@"%lu custom annotations", (unsigned long)annotation.annotations.count];
    //    annotation.subtitle = [NSString stringWithFormat:@"%.0f meters", annotation.radius];
}

- (BOOL)clusteringControllerShouldClusterAnnotations:(KPClusteringController *)clusteringController {
    return YES;
}

- (void)clusteringControllerWillUpdateVisibleAnnotations:(KPClusteringController *)clusteringController {
    //    NSLog(@"Clustering controller %@ will update visible annotations", clusteringController);
}

#pragma mark - <MKMapViewDelegate>

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    [self.clusteringController refresh:YES];
    
    if(_showDetailView)
    {
        [self updateDetailView];
        
        _vwDetail.hidden = NO;
//        _btnControl.hidden = NO;
        
        //Fade Animation
        POPBasicAnimation *anim = [POPBasicAnimation animationWithPropertyNamed:kPOPViewAlpha];
        anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        anim.fromValue = @(0.5);
        anim.toValue = @(1.0);
        [_vwDetail pop_addAnimation:anim forKey:@"fade"];
        
        //Scale
        POPSpringAnimation *scaleAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerScaleXY];
        scaleAnimation.fromValue = [NSValue valueWithCGSize:CGSizeMake(0, 0)];
        scaleAnimation.toValue = [NSValue valueWithCGSize:CGSizeMake(1, 1)];
        scaleAnimation.springBounciness = 12.f;
        [_vwDetail.layer pop_addAnimation:scaleAnimation forKey:@"scaleAnimation"];
        
    }
}

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated
{
    if(_showDetailView)
    {
        if (!_vwDetail.hidden) {
            [self hideDetailView];
            _showDetailView = NO;
        }
        
        NSArray *selectedAnnotations = mapView.selectedAnnotations;
        for(id annotation in selectedAnnotations) {
            [mapView deselectAnnotation:annotation animated:NO];
        }
    }
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    if ([view.annotation isKindOfClass:[KPAnnotation class]]) {
        
        KPAnnotation *cluster = (KPAnnotation *)view.annotation;
        
        if (cluster.annotations.count > 1){
            [self.mapView setRegion:MKCoordinateRegionMakeWithDistance(cluster.coordinate,
                                                                       cluster.radius * 2.5f,
                                                                       cluster.radius * 2.5f)
                           animated:YES];
        }
        else
        {
            
            CLLocationCoordinate2D center = cluster.coordinate;
            
            MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(center, 300.f, 300.f);
            viewRegion.center.latitude += 0.0008f;//viewRegion.span.latitudeDelta * 0.10f;
            
            [self.mapView setRegion:viewRegion animated:YES];
            
            for (int i = 0; i < _arrAnnotations.count ; i++)
            {
                KPAnnotation *a = _arrAnnotations[i];
                if (a.coordinate.latitude == cluster.coordinate.latitude && a.coordinate.longitude == cluster.coordinate.longitude)
                {
                    _selectedLocation = _arrShopData[i];
                    break;
                }
            }
            
            _showDetailView = YES;
            
        }
    }
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[MKUserLocation class]]){
        return nil;
    }
    
    // this part is boilerplate code used to create or reuse a pin annotation
    static NSString *viewId = @"MKAnnotationView";
    MKAnnotationView *annotationView = (MKAnnotationView*)[self.mapView dequeueReusableAnnotationViewWithIdentifier:viewId];
    if (annotationView == nil) {
        annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:viewId];
    }
    // set your custom image
    if ([annotation isKindOfClass:[KPAnnotation class]])
    {
        KPAnnotation *kpAnnotation = (KPAnnotation *) annotation;
        
        if(kpAnnotation.isCluster)
        {
            switch (kpAnnotation.annotations.count) {
                case 2:
                    annotationView.image = [UIImage imageNamed:@"pin2"];
                    break;
                case 3:
                    annotationView.image = [UIImage imageNamed:@"pin3"];
                    break;
                case 4:
                    annotationView.image = [UIImage imageNamed:@"pin4"];
                    break;
                case 5:
                    annotationView.image = [UIImage imageNamed:@"pin5"];
                    break;
                case 6:
                    annotationView.image = [UIImage imageNamed:@"pin6"];
                    break;
                case 7:
                    annotationView.image = [UIImage imageNamed:@"pin7"];
                    break;
                case 8:
                    annotationView.image = [UIImage imageNamed:@"pin8"];
                    break;
                case 9:
                    annotationView.image = [UIImage imageNamed:@"pin9"];
                    break;
                default:
                    annotationView.image = [UIImage imageNamed:@"pin10"];
                    break;
            }
            
            annotationView.centerOffset = CGPointMake(-3, -28);
        }
        else{
            annotationView.image = [UIImage imageNamed:@"pin"];
            annotationView.centerOffset = CGPointMake(-5, -15);
        }
    }
    else
    {
        annotationView.image = [UIImage imageNamed:@"pin"];
        annotationView.centerOffset = CGPointMake(-5, -15);
    }
    
    
    return annotationView;
}

#pragma mark - private methods
-(void)hideDetailView
{
    [UIView animateWithDuration:0.3 animations:^{
        _vwDetail.alpha = 0.0f;
    } completion:^(BOOL finished){
        _vwDetail.hidden = YES;
    }];
}

-(void)updateDetailView
{
    if (_selectedLocation != nil)
    {
        _lblDetailName.text = _selectedLocation.name;
        _lblDetailAdress.text = _selectedLocation.address;
        _lblDetailCity.text = _selectedLocation.city;
    }
}

@end
