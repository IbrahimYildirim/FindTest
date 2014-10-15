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
#import "UIImageView+WebCache.h"
#import "YIInnerShadowView.h"

@interface MainViewController ()<HomeModalProtocol, MKMapViewDelegate, KPClusteringControllerDelegate, UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate>
{
    NSMutableArray *_btnPositions;
    NSMutableArray *_arrAnnotations;
    NSArray *_arrShopData;
    NSMutableArray *_arrCategories;
    NSMutableArray *_arrSelectedCategories;
    NSMutableArray *_arrVisibleAnnotations;
    CLLocationManager *_locationManager;
    KPAnnotation * _selectedAnnotation;
    Location *_selectedLocation;
    BOOL _showDetailView;
    BOOL _menuHidden;
    BOOL _failedToLoad;
    BOOL _showB2BInfo;
//    CLLocationManager *_locationManager;
}

@property (strong, nonatomic) HomeModel *homeModal;
@property (strong, nonatomic) KPClusteringController *clusteringController;

//View Properties
@property (weak, nonatomic) IBOutlet UIView *selectedMenuView;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
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
@property (weak, nonatomic) IBOutlet UILabel *lblDetailPhone;
@property (weak, nonatomic) IBOutlet UIImageView *imgDetail;
@property (weak, nonatomic) IBOutlet UIButton *btnShowPage;
@property (weak, nonatomic) IBOutlet UITableView *tblFilter;
@property (weak, nonatomic) IBOutlet UISwitch *locationSwitch;
@property (weak, nonatomic) IBOutlet UIView *vwFSMenu;
@property (weak, nonatomic) IBOutlet YIInnerShadowView *vwShadowView;
@property (weak, nonatomic) IBOutlet UILabel *lblInfoContent;
@property (weak, nonatomic) IBOutlet UILabel *lblInfoHeader;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *actvIndicator;

@end

@implementation MainViewController


#pragma mark - Utilities
-(void)dealloc {
    _btnPositions = nil;
    _arrAnnotations = nil;
    _arrShopData = nil;
    _arrCategories = nil;
    _arrSelectedCategories = nil;
    _arrVisibleAnnotations = nil;
}

-(id)init {
    self = [super init];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    _homeModal = [[HomeModel alloc] init];
    _homeModal.delegate = self;
    [_homeModal downloadItems];
    
    _locationManager =  [[CLLocationManager alloc] init];
    
//    NSString *s = @"8.1.2";
//    NSLog(@"%f", [s doubleValue]);
    if ([[[UIDevice currentDevice] systemVersion] doubleValue] >= 8.0)
    {
        NSLog(@"ios 8");
        [_locationManager requestWhenInUseAuthorization];
    }
    
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
    
    [self setupViews];
    
    _showDetailView = NO;
    _menuHidden = YES;
    _showB2BInfo = NO;
    
    [_tblFilter registerNib:[UINib nibWithNibName:[FilterTableViewCell description] bundle:nil] forCellReuseIdentifier:[FilterTableViewCell description]];
    
    self.mapView.parallaxIntensity = 20.0f;
    
    _vwShadowView.shadowRadius = 25;
    _vwShadowView.cornerRadius = 0;
    _vwShadowView.shadowMask = YIInnerShadowMaskAll;
    
}

-(void)viewDidAppear:(BOOL)animated
{
    //Move the "Legal" label in the app so it will still be visible with the parallax effect
    UILabel *attributionLabel = [_mapView.subviews objectAtIndex:1];
    attributionLabel.center = CGPointMake(attributionLabel.center.x + 30.0f, attributionLabel.center.y-20.0f);

}

-(void)viewWillDisappear:(BOOL)animated
{
    if (!_menuHidden) {
        [self controlClicked:self];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)becameActiveAgain
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if ([defaults objectForKey:@"lastUpdate"] || _arrShopData == nil)
    {
        NSDate *lastUpdate = [defaults  objectForKey:@"lastUpdate"];
        
        //Update once per day to get opening hours of the day
        if (![self isSameDayWithDate1:lastUpdate date2:[NSDate date]] || _arrShopData == nil)
        {
            _actvIndicator.hidden = NO;
            [UIView animateWithDuration:0.2f animations:^{
                _actvIndicator.alpha = 1.0f;
            }];
            
            [_homeModal downloadItems];
        }
    }
    
    //TO DO - 
}

#pragma mark - HomeModel Delegate
-(void)itemsDownloaded:(NSArray *)items
{
    [UIView animateWithDuration:0.3f animations:^{
        _actvIndicator.alpha = 0.0;
    } completion:^(BOOL finished) {
        _actvIndicator.hidden = YES;
    }];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:[NSDate date] forKey:@"lastUpdate"];
    _failedToLoad = NO;
    
    if (items.count > 0) {
        _arrShopData = items;
    }
    
    //Update Categories
    [self setUpCategories];

    //Load items to map
    if(_arrShopData != nil)
        [self.clusteringController setAnnotations:_arrVisibleAnnotations];
}
-(void)failedToDownload
{
    [UIView animateWithDuration:0.3f animations:^{
        _actvIndicator.alpha = 0.0;
    } completion:^(BOOL finished) {
        _actvIndicator.hidden = YES;
    }];
    
    if (_arrShopData.count == 0)
    {
        _failedToLoad = YES;
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Fejl ved henting af data"
                                                          message:@"Der opstod desværre en fejl, ved forbindelsen til serveren. Prøv venligst igen."
                                                         delegate:self
                                                cancelButtonTitle:@"OK"
                                                otherButtonTitles:@"Prøv Igen", nil];
        
        [message show];

    }
}

#pragma mark - private methods
-(void)updateViewToCategories
{
    NSMutableArray *tempArray = [NSMutableArray array];
    
    if([_arrSelectedCategories containsObject:@"Alle Kategorier"])
    {
        tempArray = _arrAnnotations;
    }
    else
    {
        for (int i = 0; i < _arrShopData.count; i++)
        {
            Location *l = _arrShopData[i];
            
            if([_arrSelectedCategories containsObject:l.category])
            {
                [tempArray addObject:_arrAnnotations[i]];
            }
        }
        
    }
    _arrVisibleAnnotations = tempArray;
    
    [self.clusteringController setAnnotations:_arrVisibleAnnotations];
    [self.clusteringController refresh:YES];
}

-(void)setUpCategories
{
    //Set the Annotations
    _arrAnnotations = [NSMutableArray array];
    _arrVisibleAnnotations = [NSMutableArray array];
    
    for (int i = 0; i < _arrShopData.count ; i++)
    {
        CLLocationCoordinate2D coordinates;
        coordinates.latitude = [((Location *)_arrShopData[i]).latitude doubleValue];
        coordinates.longitude = [((Location *)_arrShopData[i]).longitude doubleValue];
        
        KPAnnotation *annotion = [[KPAnnotation alloc] init];
        annotion.coordinate = coordinates;
        
        [_arrAnnotations addObject:annotion];
    }
    
    _arrVisibleAnnotations = _arrAnnotations;
    
    //Set the categories
    _arrCategories = [[NSMutableArray alloc] init];
    _arrSelectedCategories = [[NSMutableArray alloc] init];
    [_arrSelectedCategories addObject:@"Alle Kategorier"];
    
    for (Location *l in _arrShopData)
    {
        if(![_arrCategories containsObject:l.category])
        {
            [_arrCategories addObject:l.category];
        }
    }
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    [_arrCategories sortUsingDescriptors:sortDescriptors];
    [_arrCategories insertObject:@"Alle Kategorier" atIndex:0];
    
    if ([_arrCategories containsObject:@"Andet"])
    {
        [_arrCategories removeObject:@"Andet"];
        [_arrCategories addObject:@"Andet"];
    }
    
    [_tblFilter reloadData];
}

-(void)updateDetailView
{
    if (_selectedLocation != nil)
    {
        _lblDetailName.text = _selectedLocation.name;
        _lblDetailAdress.text = _selectedLocation.address;
        _lblDetailCity.text = [NSString stringWithFormat:@"%@ %@", _selectedLocation.zip, _selectedLocation.city];
        _lblDetailPhone.text = _selectedLocation.phone;
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSDate *lastUpdate = [defaults objectForKey:@"lastUpdate"];
        
        if(_selectedLocation.openingHours != nil && [self isSameDayWithDate1:lastUpdate date2:[NSDate date]])
            _lblDetailHours.text = [NSString stringWithFormat:@"Åben idag: %@", _selectedLocation.openingHours];
        
        [_imgDetail sd_setImageWithURL:[NSURL URLWithString:_selectedLocation.imgURL]];
        
        if ([_selectedLocation.web isEqualToString:@""]){
            _btnShowPage.hidden = YES;
        }
        else{
            _btnShowPage.hidden = NO;
        }
    }
}

-(void)setupViews
{
    _vwDetail.layer.borderColor = [UIColor colorWithRed:(34.0/255.0) green:(154.0/255.0) blue:(38.0/255.0) alpha:1.0f].CGColor;
    _vwDetail.layer.shadowOpacity = 0.5f;
    _vwDetail.layer.shadowOffset = CGSizeMake(1, 1);
    _vwDetail.layer.shadowRadius = 5;
    
}

-(BOOL)locationsEnabled
{
    if ((![CLLocationManager locationServicesEnabled])
        || ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted)
        || ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied))
    {
        return NO;
    }
    else
    {
        return YES;
    }
}

- (BOOL)isSameDayWithDate1:(NSDate*)date1 date2:(NSDate*)date2 {
    NSCalendar* calendar = [NSCalendar currentCalendar];
    
    unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit;
    NSDateComponents* comp1 = [calendar components:unitFlags fromDate:date1];
    NSDateComponents* comp2 = [calendar components:unitFlags fromDate:date2];
    
    return [comp1 day]   == [comp2 day] &&
    [comp1 month] == [comp2 month] &&
    [comp1 year]  == [comp2 year];
}


#pragma mark - Button Events
-(IBAction)zoomOutClicked:(id)sender
{
    MKCoordinateRegion region;
    region.center = CLLocationCoordinate2DMake(56.159687, 10.357533);
    
    MKCoordinateSpan span;
    span.latitudeDelta  = 4.5f;
    span.longitudeDelta = 4.5f;
    region.span = span;
    
    [self.mapView setRegion:region animated:YES];
}

-(IBAction)zoomInClicked:(id)sender
{
    // If Location Services are disabled, restricted or denied.
    if ([self locationsEnabled])
    {
        MKCoordinateRegion region;
        region.center = self.mapView.userLocation.coordinate;
        
        MKCoordinateSpan span;
        span.latitudeDelta  = 0.04f;
        span.longitudeDelta = 0.04f;
        region.span = span;
        
        [self.mapView setRegion:region animated:YES];
    }
    else
    {
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Ups!"
                                                          message:@"For at zoome ind på din lokation skal vi bruge din placering. Gå ind på Indstillinger -> Anonymitet -> Lokalitetstjenester og slå det til."
                                                         delegate:nil
                                                cancelButtonTitle:@"OK"
                                                otherButtonTitles:nil];
        
        [message show];
    }
}

-(IBAction)showWebPage:(id)sender
{
    //If Link is nil, the updateView method hides it
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@",_selectedLocation.web]];
    if (![[UIApplication sharedApplication] openURL:url]) {
        NSLog(@"%@%@",@"Failed to open url:",[url description]);
    }
}

-(IBAction)showDirectionClicked:(id)sender
{
    
    CLLocationCoordinate2D location = CLLocationCoordinate2DMake([_selectedLocation.latitude doubleValue], [_selectedLocation.longitude doubleValue]);// self.mapView.userLocation.coordinate;
    
    MKPlacemark* place = [[MKPlacemark alloc] initWithCoordinate: location addressDictionary: nil];
    MKMapItem* destination = [[MKMapItem alloc] initWithPlacemark: place];
    destination.name = _selectedLocation.name;
    NSArray* items = [[NSArray alloc] initWithObjects: destination, nil];
    NSDictionary* options = [[NSDictionary alloc] initWithObjectsAndKeys:
                             MKLaunchOptionsDirectionsModeWalking,
                             MKLaunchOptionsDirectionsModeKey, nil];
    [MKMapItem openMapsWithItems: items launchOptions: options];
}

-(IBAction)b2bClicked:(id)sender
{
    NSString *businessString = @"For 20 år siden kunne ingen forestille sig, at der skulle være Wi-Fi adgang, for spisende gæster på cafeer og restauranter. Men i dag er det en selvfølge, og næsten alle restaurationer tilbyder Wi-Fi. Nutidens digitalisering, samt det stigende behov og brug af mobilen betyder dog også, at mange føler sig isoleret hvis mobilen går ud, og lige så mange bliver forhindret i deres arbejde eller tilbageholdt i andre heensender. – Vi tilbyder Jer den ideelle løsning, for at dække kundernes nye digitale behov, og sammen kan vi give dine nuværende og nye kunder en bedre dag – hvis nu mobilen er ved at løbe tør for strøm igen. \n \nKontakt os på: +45 225 95 225 eller tilbydstrom@findstrom.dk \n\nDu kan også lære mere på www.findstroem.dk/for-virksomheder";
    
    NSString *publicInfoString = @"En smartphone der løber tør for strøm, er et velkendt problem i Danmark og resten af verden. Digitaliseringen, samt det stigende behov og brug af mobilen, betyder også at mange føler sig isoleret når mobilen går ud, og lige så mange bliver forhindret i deres arbejde eller tilbagehold i andre heensender. \n\nFindStrøm, er ChargeSmart.dk’s nye gratis app og social service, som giver et overblik over, hvor smartphones og tablets kan oplades, når man er på farten, ude at shoppe, i byen – eller ganske enkelt igen er ved at løbe tør for strøm og ikke har en ChargeSmart eller oplader med sig.\n\nVi tilbyder vore kunder hos ChargeSmart, uanset hvor de befinder, en sikkerhed for aldrig at løbe tør for strøm, og altid være tilgængelig. Vi har en målsætning om, at kunne tilbyde denne sikkerhed og service, til hele Danmarks befolkning, og samtidig fremme alternativ opladning både i Danmark og resten af verden.\n\n- Derfor startede vi FindStrøm";
    
    if (!_showB2BInfo) {
        _lblInfoContent.text = businessString;
        _lblInfoHeader.text = @"For Virksomheder";
        _showB2BInfo = YES;
    }
    else
    {
        _lblInfoContent.text = publicInfoString;
        _lblInfoHeader.text = @"Om FindStroem";
        _showB2BInfo = NO;
    }
}

-(IBAction)filterClicked:(id)sender
{
    if(_menuHidden)
        return;
    
    if(_selectedMenuView == nil)
    {
        _vwFilter.hidden = NO;
        _vwFilter.alpha = 0.0f;
        [self scaleViewUp:_vwFilter];
        _selectedMenuView = _vwFilter;
    }
    else
    {
        if (_selectedMenuView == _vwFilter)
        {
            [self scaleAndFadeView:_vwFilter downTo:0.5f];
            _selectedMenuView = nil;
        }
        else
        {
            _vwFilter.hidden = NO;
            _vwFilter.alpha = 0.0f;
            [self scaleAndFadeView:_selectedMenuView downTo:0.5];
            [self performSelector:@selector(scaleViewUp:) withObject:_vwFilter afterDelay:0.1f];
            _selectedMenuView = _vwFilter;
        }
    }
}

-(IBAction)infoClicked:(id)sender
{
    if(_menuHidden)
        return;
    
    if(_selectedMenuView == nil)
    {
        if(_showB2BInfo){
            [self b2bClicked:self];
        }
        
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
            if(_showB2BInfo){
                [self b2bClicked:self];
            }
            
            _vwInfo.hidden = NO;
            _vwInfo.alpha = 0.0f;
            [self scaleAndFadeView:_selectedMenuView downTo:0.5];
            [self performSelector:@selector(scaleViewUp:) withObject:_vwInfo afterDelay:0.1f];
            _selectedMenuView = _vwInfo;
        }
    }
}

-(IBAction)settingsClicked:(id)sender
{
    if(_menuHidden)
        return;
    
    if ([self locationsEnabled])
    {
        [_locationSwitch setOn:YES];
    }
    else
    {
        [_locationSwitch setOn:NO];
    }
    
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
            [self performSelector:@selector(scaleViewUp:) withObject:_vwSettings afterDelay:0.1f];
            _selectedMenuView = _vwSettings;
        }
    }
}

-(IBAction)controlClicked:(id)sender
{
    NSArray *buttons = _vwMenuButtons.subviews;
    
    //Calculate center point
    CGPoint controlCenter = CGPointMake(_vwMenuButtons.frame.size.width / 2, _vwMenuButtons.frame.size.height);
    
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
                btn.center = controlCenter;
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

-(IBAction)useLocationSwitchClicked:(id)sender
{
    if (_locationSwitch.isOn) {
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Ups!"
                                                          message:@"Gå ind på Indstillinger -> Anonymitet -> Lokalitetstjenester og slå det til."
                                                         delegate:nil
                                                cancelButtonTitle:@"OK"
                                                otherButtonTitles:nil];
        
        [message show];
        [_locationSwitch setOn:NO animated:YES];
    }
    else
    {
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Ups!"
                                                          message:@"Gå ind på Indstillinger -> Anonymitet -> Lokalitetstjenester for at slå det fra."
                                                         delegate:nil
                                                cancelButtonTitle:@"OK"
                                                otherButtonTitles:nil];
        
        [message show];
        [_locationSwitch setOn:YES animated:YES];
    }
}

-(IBAction)shareClicked:(id)sender
{
    NSString *message = @"Tjek FindStrøm appen fra ChargeSmart ud! http://itunes.apple.com/app/id930100958";
    UIImage *image = [UIImage imageNamed:@"DenmarkIcon"];
    NSArray *arrayOfActivityItems = [NSArray arrayWithObjects:message, image, nil];
    UIActivityViewController *activityVC = [[UIActivityViewController alloc]
                                            initWithActivityItems:arrayOfActivityItems applicationActivities:nil];
    
    [self presentViewController:activityVC animated:YES completion:nil];
}

-(IBAction)reviewClicked:(id)sender
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://itunes.apple.com/app/id930100958"]];
    //Alternative Link to AppStore http://phobos.apple.com/WebObjects/MZStore.woa/wa/viewSoftware?id=301349397&amp;amp;amp;mt=8"]];
}


#pragma mark - Clustering


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
    return _arrCategories.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifer = [FilterTableViewCell description];
    FilterTableViewCell *cell = (FilterTableViewCell *) [tableView dequeueReusableCellWithIdentifier:identifer];
    
    cell.lblTitle.text = [_arrCategories objectAtIndex:indexPath.row];
    
    if([_arrSelectedCategories containsObject:_arrCategories[indexPath.row]])
    {
        [cell.imgvCheck setImage:[UIImage imageNamed:@"filterChecked"]];
    }
    else
    {
        [cell.imgvCheck setImage:[UIImage imageNamed:@"filterUnchecked"]];
    }
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([_arrCategories[indexPath.row] isEqualToString:@"Alle Kategorier"])
    {
        [_arrSelectedCategories removeAllObjects];
        [_arrSelectedCategories addObject:_arrCategories[indexPath.row]];
    }
    else
    {
        [_arrSelectedCategories removeObject:@"Alle Kategorier"];
        
        if([_arrSelectedCategories containsObject:_arrCategories[indexPath.row]])
        {
            [_arrSelectedCategories removeObject:_arrCategories[indexPath.row]];
        }
        else
        {
            [_arrSelectedCategories addObject:_arrCategories[indexPath.row]];
        }
        
        if ([_arrSelectedCategories count] == 0)
        {
            [_arrSelectedCategories addObject:_arrCategories[indexPath.row]];
        }
    }
    
    [self updateViewToCategories];
    [_tblFilter performSelectorInBackground:@selector(reloadData) withObject:nil];
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
    float delay = 0;
    
    for (int i = 0; i < buttons.count; i++)
    {
        UIView *btn = buttons[i];
        
        POPSpringAnimation *positionAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerPosition];
//        positionAnimation.fromValue = [NSValue valueWithCGPoint:controlCenter];
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
    [self.view bringSubviewToFront:_vwFSMenu];
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
    [self.view bringSubviewToFront:_vwFSMenu];
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        if (_failedToLoad) {
            _actvIndicator.hidden = NO;
            [UIView animateWithDuration:0.2f animations:^{
                _actvIndicator.alpha = 1.0f;
            }];
            [_homeModal downloadItems];
        }
    }
}

@end
