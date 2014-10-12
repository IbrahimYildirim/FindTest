//
//  PassThroughView.m
//  Findstroem
//
//  Created by Ibrahim Yildirim on 11/10/14.
//  Copyright (c) 2014 Ibrahim Yildirim. All rights reserved.
//

#import "PassThroughView.h"

@implementation PassThroughView
-(BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    for (UIView *view in self.subviews) {
        if (!view.hidden && view.alpha > 0 && view.userInteractionEnabled && [view pointInside:[self convertPoint:point toView:view] withEvent:event])
            return YES;
    }
    return NO;
}
@end