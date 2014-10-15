//
//  Location.h
//  MapsTesting
//
//  Created by Ibrahim Yildirim on 02/10/14.
//  Copyright (c) 2014 Ibrahim Yildirim. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Location : NSObject

@property (nonatomic, strong) NSString *latitude;
@property (nonatomic, strong) NSString *longitude;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *address;
@property (nonatomic, strong) NSString *city;
@property (nonatomic, strong) NSString *zip;
@property (nonatomic, strong) NSString *category;
@property (nonatomic, strong) NSString *web;
@property (nonatomic, strong) NSString *phone;
@property (nonatomic, strong) NSString *imgURL;
@property (nonatomic, strong) NSString *openingHours;

@end
