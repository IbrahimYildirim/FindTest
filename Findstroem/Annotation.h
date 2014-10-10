//
//  Annotation.h
//  Findstroem
//
//  Created by Ibrahim Yildirim on 09/10/14.
//  Copyright (c) 2014 Ibrahim Yildirim. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface Annotation : NSObject<MKAnnotation>

@property (nonatomic, assign) CLLocationCoordinate2D coordinate;

@end
