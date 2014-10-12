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
#import "Location.h"
#import "KPAnnotation.h"
#import "NGAParallaxMotion.h"
#import "FilterTableViewCell.h"

@interface MainViewController ()<HomeModalProtocol, MKMapViewDelegate, KPClusteringControllerDelegate, UITableViewDelegate, UITableViewDataSource>
{
    Location *_selectedLocation;
    NSMutableArray *_btnPositions;
    UIView *_selectedMenuView;
    KPAnnotation * _selectedAnnotation;
    BOOL _showDetailView;
    BOOL _menuHidden;
}

@property (strong, nonatomic) HomeModel *homeModal;
@property (weak, nonatomic) NSArray *arrShopData;
@property (strong, nonatomic) KPClusteringController *clusteringController;
@property (weak, nonatomic) NSMutableArray *arrAnnotations;

//View Properties
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UILabel* lblLoadingStatus;
@property (weak, nonatomic) IBOutlet UIView *btnHome;
@property (weak, nonatomic) IBOutlet UIView *vwMenuButtons;
@property (weak, nonatomic) IBOutlet UIImageView *imgFSHome;
@property (weak, nonatomic) IBOutlet UIView *vwSettings;
@property (weak, nonatomic) IBOutlet UIView *vwInfo;
@property (weak, nonatomic) IBOutlet UIView *vwFilter;
@property (weak, nonatomic) IBOutlet UIView *vwDetail;
@property (weak, nonatomic) IBOutlet UILabel *lblDetailName;
@property (weak, nonatomic) IBOutlet UILabel *lblDetailAdress;
@property (weak, nonatomic) IBOutlet UILabel *lblDetailCity;
@property (weak, nonatomic) IBOutlet UILabel *lblDetailHours;
@property (weak, nonatomic) IBOutlet UITableView *tblFilter;

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
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(mapTapped)];
    [self.mapView addGestureRecognizer:tapGestureRecognizer];
    
//    [self setUpFSMenu];
    [self setupViews];
    
    _showDetailView = NO;
    _menuHidden = YES;
    
    [_tblFilter registerNib:[UINib nibWithNibName:[FilterTableViewCell description] bundle:nil] forCellReuseIdentifier:[FilterTableViewCell description]];
}

-(void)viewDidAppear:(BOOL)animated
{
    self.mapView.parallaxIntensity = 20.0f;
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

#pragma mark - Button Events
-(IBAction)zoomOutClicked:(id)sender
{
    CLLocationCoordinate2D centerDenmark = CLLocationCoordinate2DMake(56.159687, 10.357533);
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(centerDenmark, 350000.f, 350000.f);
    
    [self.mapView setRegion:viewRegion animated:YES];
}

-(IBAction)showWebPage:(id)sender
{
    NSLog(@"%@", _selectedLocation.web);
}

-(IBAction)filterClicked:(id)sender
{
    NSLog(@"Filter Clicked");
}

-(IBAction)infoClicked:(id)sender
{
        NSLog(@"Info Clicked");
    
    if(_selectedMenuView == nil)
    {
        _vwInfo.hidden = NO;
        _vwInfo.alpha = 0.0f;
        [self scaleViewUp:_vwInfo];
        _selectedMenuView = _vwInfo;
    }
    else
    {
        if(_selectedMenuView == _vwInfo)
        {
            [self scaleAndFadeView:_vwInfo downTo:0.5f];
            _selectedMenuView = nil;
        }
        else
        {
            _vwInfo.hidden = NO;
            _vwInfo.alpha = 0.0f;
            [self scaleAndFadeView:_selectedMenuView downTo:0.5];
            [self performSelector:@selector(scaleViewUp:) withObject:_vwInfo afterDelay:0.2f];
            _selectedMenuView = _vwInfo;
        }
    }
}

-(IBAction)settingsClicked:(id)sender
{
        NSLog(@"Settings Clicked");
    
    if(_selectedMenuView == nil)
    {
        _vwSettings.hidden = NO;
        _vwSettings.alpha = 0.0f;
        [self scaleViewUp:_vwSettings];
        _selectedMenuView = _vwSettings;
    }
    else
    {
        if (_selectedMenuView == _vwSettings)
        {
            [self scaleAndFadeView:_vwSettings downTo:0.5f];
            _selectedMenuView = nil;
        }
        else
        {
            _vwSettings.hidden = NO;
            _vwSettings.alpha = 0.0f;
            [self scaleAndFadeView:_selectedMenuView downTo:0.5];
            [self performSelector:@selector(scaleViewUp:) withObject:_vwSettings afterDelay:0.2f];
            _selectedMenuView = _vwSettings;
        }
    }
}

-(IBAction)controlClicked:(id)sender
{
    NSArray *buttons = _vwMenuButtons.subviews;
    
    //Calculate center point
    
    
    if(_showDetailView){
        if (!_vwDetail.hidden) {
            [self hideDetailView];
            _showDetailView = NO;
        }
    }
    
    if(_menuHidden)
    {
        //The first time: Save the positions of the buttons
        if(_btnPositions == nil)
        {
            _btnPositions = [[NSMutableArray alloc] init];
            for(UIView *btn in buttons)
            {
                [_btnPositions addObject:[NSValue valueWithCGPoint:btn.center]];
            }
        }
        
        //They are hidden in the nib file
        if (_vwMenuButtons.isHidden) {
            _vwMenuButtons.hidden = NO;
        }
        
        [self shootMenuButtonsOut:buttons];
        _menuHidden = NO;
    }
    else
    {
        [self shootMenuButtonsIn:buttons];
        
        if (_selectedMenuView != nil)
        {
            [self scaleAndFadeView:_selectedMenuView downTo:0.5];
            _selectedMenuView = nil;
        }
        
        _menuHidden = YES;
    }
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
        [self scaleViewUp:_vwDetail];
    }
}

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated
{
    if(_showDetailView)
    {
        if (!_vwDetail.hidden)
        {
            [self hideDetailView];
            _showDetailView = NO;
        }
        
        NSArray *selectedAnnotations = mapView.selectedAnnotations;
        for(id annotation in selectedAnnotations) {
            [mapView deselectAnnotation:annotation animated:NO];
        }
    }
    
    if(!_menuHidden)
    {
        [self controlClicked:self];
    }
    
//    NSString * string = [NSString stringWithFormat:@"Latitude: %f Longtitude: %f", self.mapView.region.center.latitude, self.mapView.region.center.longitude];
//    
//    NSLog(string);
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    
    if ([view.annotation isKindOfClass:[KPAnnotation class]]) {
        
        KPAnnotation *cluster = (KPAnnotation *)view.annotation;
        
        if (!_vwDetail.isHidden) {
            return;
        }
        
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
            _selectedAnnotation = cluster;
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

-(void)mapTapped
{
    NSLog(@"Map Tocuhed");
    
    if(_showDetailView)
    {
        [self.mapView setRegion:MKCoordinateRegionMakeWithDistance(_selectedAnnotation.coordinate,5.0f, 5.0f)
                       animated:YES];
    }
}

#pragma mark - UITableView Methods
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 3;//_arrShopData.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifer = [FilterTableViewCell description];
    FilterTableViewCell *cell = (FilterTableViewCell *) [tableView dequeueReusableCellWithIdentifier:identifer];
    
    if (cell == nil)
    {
        NSLog(@"Whzaaa");
    }
    
    return cell;
}

#pragma mark - private methods

-(void)setUpCategories
{
    
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

-(void)setUpFSMenu
{
    NSArray *buttons = _vwMenuButtons.subviews;
    
    for(UIView *btn in buttons)
    {
        btn.alpha = 0.0f;
    }
}

-(void)setupViews
{
    _vwDetail.layer.borderColor = [UIColor colorWithRed:(34.0/255.0) green:(154.0/255.0) blue:(38.0/255.0) alpha:1.0f].CGColor;
    _vwDetail.layer.shadowOpacity = 0.5f;
    _vwDetail.layer.shadowOffset = CGSizeMake(1, 1);
    _vwDetail.layer.shadowRadius = 5;

}


#pragma mark - Animations
-(void)hideDetailView
{
    [UIView animateWithDuration:0.3 animations:^{
        _vwDetail.alpha = 0.0f;
    } completion:^(BOOL finished){
        _vwDetail.hidden = YES;
    }];
}

-(void)scaleAndFadeView:(UIView *)scaleView downTo:(CGFloat)scaleDown
{
    POPSpringAnimation *scaleAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerScaleXY];
    scaleAnimation.fromValue = [NSValue valueWithCGSize:CGSizeMake(1, 1)];
    scaleAnimation.toValue = [NSValue valueWithCGSize:CGSizeMake(scaleDown, scaleDown)];
    scaleAnimation.springBounciness = 12.f;
    [scaleView.layer pop_addAnimation:scaleAnimation forKey:@"scaleAnimation"];
    
    [UIView animateWithDuration:0.2f animations:^{
        scaleView.alpha = 0.0f;
    } completion:^(BOOL finished) {
        scaleView.hidden = YES;
    }];
}

-(void)scaleViewUp:(UIView *)view
{
    //Fade Animation
    POPBasicAnimation *anim = [POPBasicAnimation animationWithPropertyNamed:kPOPViewAlpha];
    anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    anim.fromValue = @(0.5);
    anim.toValue = @(1.0);
    [view pop_addAnimation:anim forKey:@"fade"];
    
    //Scale
    POPSpringAnimation *scaleAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerScaleXY];
    scaleAnimation.fromValue = [NSValue valueWithCGSize:CGSizeMake(0, 0)];
    scaleAnimation.toValue = [NSValue valueWithCGSize:CGSizeMake(1, 1)];
    scaleAnimation.springBounciness = 12.f;
    [view.layer pop_addAnimation:scaleAnimation forKey:@"scaleAnimation"];
}

-(void)shootMenuButtonsOut:(NSArray *)buttons
{
    CGPoint controlCenter = CGPointMake(_vwMenuButtons.frame.size.width / 2, _vwMenuButtons.frame.size.height);
    float delay = 0;
    
    for (int i = 0; i < buttons.count; i++)
    {
        UIView *btn = buttons[i];
        
        POPSpringAnimation *positionAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerPosition];
        positionAnimation.fromValue = [NSValue valueWithCGPoint:controlCenter];
        positionAnimation.toValue = _btnPositions[i]; //Stored button positions
        positionAnimation.springSpeed = 3.f;
        positionAnimation.springBounciness = 12.f;
        positionAnimation.beginTime = CACurrentMediaTime() + delay;
        [btn.layer pop_addAnimation:positionAnimation forKey:@"positionUpAnimation"];
        
        //Fade Animation
        POPBasicAnimation *anim = [POPBasicAnimation animationWithPropertyNamed:kPOPViewAlpha];
        anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        anim.fromValue = @(0.0);
        anim.toValue = @(1.0);
        [btn pop_addAnimation:anim forKey:@"fade"];
        
        //Fade Animation - Home
        POPBasicAnimation *homeAnim = [POPBasicAnimation animationWithPropertyNamed:kPOPViewAlpha];
        homeAnim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        homeAnim.fromValue = @(0.8);
        homeAnim.toValue = @(1.0);
        [_imgFSHome pop_addAnimation:homeAnim forKey:@"fadeHome"];
        
        
        delay += 0.08f;
    }
}

-(void)shootMenuButtonsIn:(NSArray *)buttons
{
    CGPoint controlCenter = CGPointMake(_vwMenuButtons.frame.size.width / 2, _vwMenuButtons.frame.size.height);
    for (int i = 0; i < buttons.count ; i++)
    {
        UIView *btn = buttons[i];
        POPSpringAnimation *positionAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerPosition];
        positionAnimation.toValue = [NSValue valueWithCGPoint:controlCenter];
        positionAnimation.springSpeed = 2.f;
        [btn.layer pop_addAnimation:positionAnimation forKey:@"positionDownAnimation"];
        
        POPBasicAnimation *anim = [POPBasicAnimation animationWithPropertyNamed:kPOPViewAlpha];
        anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        anim.fromValue = @(1.0);
        anim.toValue = @(0.0);
        [btn pop_addAnimation:anim forKey:@"fade"];
        
        POPBasicAnimation *homeAnim = [POPBasicAnimation animationWithPropertyNamed:kPOPViewAlpha];
        homeAnim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        homeAnim.fromValue = @(1.0);
        homeAnim.toValue = @(0.8);
        [_imgFSHome pop_addAnimation:homeAnim forKey:@"fadeHome"];
        
    }
}

@end
