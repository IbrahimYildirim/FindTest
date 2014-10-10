//
//  HomeModel.m
//  MapsTesting
//
//  Created by Ibrahim Yildirim on 02/10/14.
//  Copyright (c) 2014 Ibrahim Yildirim. All rights reserved.
//

#import "HomeModel.h"
#import "Location.h"

@interface HomeModel()
{
    NSMutableData *_downloadedData;
}
@end

@implementation HomeModel

-(void)downloadItems
{
    NSURL *jsonFileUrl = [NSURL URLWithString:@"http://findstroem.dk/service.php"];
    
    //Create the request and connection
    NSURLRequest *urlRequest = [[NSURLRequest alloc] initWithURL:jsonFileUrl];
    [NSURLConnection connectionWithRequest:urlRequest delegate:self];
    
}

#pragma mark NSURLConnection Methods
-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    _downloadedData = [[NSMutableData alloc] init];
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [_downloadedData appendData:data];
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(error.description);
    [self downloadItems];
    
}

-(void)connection:(NSURLConnection *)connection didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    NSLog(challenge.description);
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    // Create an array to store the locations
    NSMutableArray *_locations = [[NSMutableArray alloc] init];
    
    // Parse the JSON that came in
    NSError *error;
    NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:_downloadedData options:NSJSONReadingAllowFragments error:&error];
    
    // Loop through Json objects, create question objects and add them to our questions array
    for (int i = 0; i < jsonArray.count; i++)
    {
        NSDictionary *jsonElement = jsonArray[i];
        
        // Create a new location object and set its props to JsonElement properties
        Location *newLocation = [[Location alloc] init];
        newLocation.name = jsonElement[@"Name"];
        newLocation.address = jsonElement[@"Adress"];
        newLocation.latitude = jsonElement[@"Latitude"];
        newLocation.longitude = jsonElement[@"Longtitude"];
        
        // Add this question to the locations array
        [_locations addObject:newLocation];
    }
    
    // Ready to notify delegate that data is ready and pass back items
    if (self.delegate)
    {
        [self.delegate itemsDownloaded:_locations];
    }
}

@end
