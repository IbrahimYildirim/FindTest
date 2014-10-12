//
//  FilterTableViewCell.m
//  Findstroem
//
//  Created by Ibrahim Yildirim on 13/10/14.
//  Copyright (c) 2014 Ibrahim Yildirim. All rights reserved.
//

#import "FilterTableViewCell.h"

@implementation FilterTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

-(void)layoutSubviews {
    [super layoutSubviews];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
}

@end
