//
//  BNGridline.m
//  BNCalendar1CollectionViewStoryboard
//
//  Created by Alexandr on 05.08.13.
//  Copyright (c) 2013 Alexander Spiridonov. All rights reserved.
//

#import "BNHorizontalHourGridline.h"
#import <QuartzCore/QuartzCore.h>

@implementation BNHorizontalHourGridline

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor colorWithRed:0.4 green:0.4 blue:0.5 alpha:0.5];
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
