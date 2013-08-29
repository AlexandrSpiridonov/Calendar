//
//  BNWorkTimeDecorationLayer.m
//  BNCalendar1CollectionViewStoryboard
//
//  Created by Alexandr on 20.08.13.
//  Copyright (c) 2013 Alexander Spiridonov. All rights reserved.
//

#import "BNWorkTimeDecorationLayer.h"

@implementation BNWorkTimeDecorationLayer

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor blackColor];
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
