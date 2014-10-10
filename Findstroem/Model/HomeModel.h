//
//  HomeModel.h
//  MapsTesting
//
//  Created by Ibrahim Yildirim on 02/10/14.
//  Copyright (c) 2014 Ibrahim Yildirim. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol HomeModalProtocol <NSObject>

-(void)itemsDownloaded:(NSArray *)items;

@end

@interface HomeModel : NSObject <NSURLConnectionDataDelegate>

@property (nonatomic, weak) id<HomeModalProtocol> delegate;

-(void)downloadItems;

@end
