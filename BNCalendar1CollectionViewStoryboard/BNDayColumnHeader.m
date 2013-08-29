//
//  BNDayColumnHeader.m
//  BNCalendar1CollectionViewStoryboard
//
//  Created by Alexandr on 01.08.13.
//  Copyright (c) 2013 Alexander Spiridonov. All rights reserved.
//

#import "BNDayColumnHeader.h"

@implementation BNDayColumnHeader

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.button = [UIButton new];
        [self addSubview: self.button];
        
        self.backgroundColor = [UIColor clearColor];
        self.dateTitle = [UILabel new];
        self.dateTitle.backgroundColor = [UIColor clearColor];
        self.dateTitle.font = [UIFont fontWithName:@"Trebuchet MS" size:12];
        self.dateTitle.textColor = [UIColor colorWithRed: 0.4 green: 0.4 blue: 0.6 alpha: 1];
        self.dateTitle.shadowColor = [UIColor lightGrayColor];
        self.dateTitle.shadowOffset = CGSizeMake(0.0, 1.0);
        [self addSubview:self.dateTitle];

        self.backgroundColor = [UIColor clearColor];
        self.weekTitle = [UILabel new];
        self.weekTitle.backgroundColor = [UIColor clearColor];
        self.weekTitle.font = [UIFont fontWithName:@"Trebuchet MS" size:10];
        self.weekTitle.textColor = [UIColor lightGrayColor];
        self.weekTitle.shadowOffset = CGSizeMake(0.0, 1.0);
        [self addSubview:self.weekTitle];
        [self.button setImage:[UIImage imageNamed: @"bgr-srch.png"] forState:UIControlStateNormal];
        
        self.workload = [NSMutableArray array];
        for ( int i = 0 ; i < 48 ; i ++ )
        {
            UIView *view = [UIView new];
            view.backgroundColor = [UIColor clearColor];
            //view.backgroundColor = [UIColor redColor];
            [self addSubview:view];
            [self.workload addObject:view];
        }
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

-(void)layoutSubviews
{
    [super layoutSubviews];
    CGRect buttonFrame = self.frame;
    buttonFrame.size.height = buttonFrame.size.height-2;
    buttonFrame.size.width = buttonFrame.size.width-4;
    buttonFrame.origin.x = 2;
    buttonFrame.origin.y = 1;
    self.button.frame  = buttonFrame;
    
    [self.dateTitle sizeToFit];
    CGRect dateFrame = self.dateTitle.frame;
    dateFrame.origin.x = 11;
    dateFrame.origin.y = nearbyintf((3*CGRectGetHeight(buttonFrame)/ 2.0 - CGRectGetHeight(dateFrame)) / 2.0)-2.0;
    self.dateTitle.frame = dateFrame;
    
    [self.weekTitle sizeToFit];
    CGRect weekFrame = self.weekTitle.frame;
    weekFrame.origin.x = CGRectGetWidth(buttonFrame) - 8 - CGRectGetWidth(weekFrame);
    weekFrame.origin.y = nearbyintf((3*CGRectGetHeight(buttonFrame)/ 2.0 - CGRectGetHeight(weekFrame)) / 2.0);
    self.weekTitle.frame = weekFrame;
    
    CGRect workloadFrame = self.frame;
    workloadFrame.size.width = workloadFrame.size.width/48;
    workloadFrame.size.height = workloadFrame.size.width;
    workloadFrame.origin.y = self.frame.size.height-workloadFrame.size.height;
    for ( int i = 0 ; i < 48 ; i ++ )
    {
        workloadFrame.origin.x = workloadFrame.size.width*i;
        UIView *view = (UIView *)self.workload[i];
        view.frame = workloadFrame;
    }
}

-(void)setDay:(NSDate *)day
{
    //self.day = day;
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    dateFormatter.dateFormat = @"dd.MM.YYYY";
    self.dateTitle.text = [dateFormatter stringFromDate:day];
    dateFormatter.dateFormat = @"cccc";
    self.weekTitle.text = [dateFormatter stringFromDate:day];
    //[self.button.imageView setImage:[UIImage imageNamed: @"bgr-srch.png"]];
    
    [self setNeedsLayout];
}

@end
