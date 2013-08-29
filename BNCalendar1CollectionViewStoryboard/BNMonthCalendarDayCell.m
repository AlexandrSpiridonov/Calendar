//
//  BNMonthCalendarDayCell.m
//  BNMonthCalendar2CollectionViewCustomLayout
//
//  Created by Alexandr on 12.08.13.
//  Copyright (c) 2013 Alexander Spiridonov. All rights reserved.
//

#import "BNMonthCalendarDayCell.h"
#import <QuartzCore/QuartzCore.h>


@implementation BNMonthCalendarDayCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.dayTextLabel = [UILabel new];
        self.dayTextLabel.backgroundColor = [UIColor clearColor];
        self.dayTextLabel.font = [UIFont systemFontOfSize:((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? 20.0f : 14.0f)];
        self.dayTextLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:self.dayTextLabel];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self.dayTextLabel sizeToFit];
    CGRect titleFrame = self.dayTextLabel.frame;
    titleFrame.origin.x = nearbyintf((CGRectGetWidth(self.frame) / 2.0) - (CGRectGetWidth(titleFrame) / 2.0));
    titleFrame.origin.y = nearbyintf((CGRectGetHeight(self.frame) / 2.0) - (CGRectGetHeight(titleFrame) / 2.0));
    self.dayTextLabel.frame = titleFrame;
    //self.backgroundColor = [UIColor whiteColor];
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
