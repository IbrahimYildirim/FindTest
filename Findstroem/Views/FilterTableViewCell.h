//
//  FilterTableViewCell.h
//  Findstroem
//
//  Created by Ibrahim Yildirim on 13/10/14.
//  Copyright (c) 2014 Ibrahim Yildirim. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FilterTableViewCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *lblTitle;
@property (nonatomic, weak) IBOutlet UILabel *lblSubTitle;
@property (nonatomic, weak) IBOutlet UIImageView *imgvCheck;

@end
