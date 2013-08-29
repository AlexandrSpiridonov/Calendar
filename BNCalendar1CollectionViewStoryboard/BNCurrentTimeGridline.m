//
//  BNCurrentTimeGridline.m
//  BNCalendar1CollectionViewStoryboard
//
//  Created by Alexandr on 05.08.13.
//  Copyright (c) 2013 Alexander Spiridonov. All rights reserved.
//

#import "BNCurrentTimeGridline.h"

@implementation BNCurrentTimeGridline

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor redColor];
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
- (void)setFrame:(CGRect)frame
{
    [super setFrame:CGRectInset(frame, -10.0, 0.0)];
}

@end
