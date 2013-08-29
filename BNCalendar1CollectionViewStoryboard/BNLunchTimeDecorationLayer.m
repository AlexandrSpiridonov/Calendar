//
//  BNLunchTimeDecorationLayer.m
//  BNCalendar1CollectionViewStoryboard
//
//  Created by Alexandr on 20.08.13.
//  Copyright (c) 2013 Alexander Spiridonov. All rights reserved.
//

#import "BNLunchTimeDecorationLayer.h"

@implementation BNLunchTimeDecorationLayer

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor greenColor];
        self.alpha = 0.1;
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
