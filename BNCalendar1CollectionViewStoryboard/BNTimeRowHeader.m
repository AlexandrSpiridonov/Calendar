//
//  BNTimeRowHeader.m
//  BNCalendar1CollectionViewStoryboard
//
//  Created by Alexandr on 01.08.13.
//  Copyright (c) 2013 Alexander Spiridonov. All rights reserved.
//

#import "BNTimeRowHeader.h"

@implementation BNTimeRowHeader

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor clearColor];
        self.title = [UILabel new];
        self.title.backgroundColor = [UIColor clearColor];
        self.title.font = [UIFont fontWithName:@"Trebuchet MS" size:11.0];
        self.title.textColor = [UIColor colorWithRed:0.4 green:0.4 blue:0.5 alpha:0.7];
        self.title.shadowColor = [UIColor whiteColor];
        self.title.shadowOffset = CGSizeMake(0.0, 1.0);
        
        self.title15 = [UILabel new];
        self.title15.backgroundColor = [UIColor clearColor];
        self.title15.font = [UIFont fontWithName:@"Trebuchet MS" size:10.0];
        self.title15.textColor = [UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:0.6];
        self.title15.shadowColor = [UIColor whiteColor];
        self.title15.shadowOffset = CGSizeMake(0.0, 1.0);
        
        self.title30 = [UILabel new];
        self.title30.backgroundColor = [UIColor clearColor];
        self.title30.font = [UIFont fontWithName:@"Trebuchet MS" size:10.0];
        self.title30.textColor = [UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:0.6];
        self.title30.shadowColor = [UIColor whiteColor];
        self.title30.shadowOffset = CGSizeMake(0.0, 1.0);
        
        self.title45 = [UILabel new];
        self.title45.backgroundColor = [UIColor clearColor];
        self.title45.font = [UIFont fontWithName:@"Trebuchet MS" size:10.0];
        self.title45.textColor = [UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:0.6];
        self.title45.shadowColor = [UIColor whiteColor];
        self.title45.shadowOffset = CGSizeMake(0.0, 1.0);
        
        
        [self addSubview:self.title];
        [self addSubview:self.title15];
        [self addSubview:self.title30];
        [self addSubview:self.title45];
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

- (void)layoutSubviews
{
    [super layoutSubviews];
    UIEdgeInsets margin = UIEdgeInsetsMake(0.0, 0.0, 0.0, 1.0);
    
    [self.title sizeToFit];
    CGRect titleFrame = self.title.frame;
    titleFrame.origin.x = nearbyintf(CGRectGetWidth(self.frame) - CGRectGetWidth(titleFrame)) - margin.right;
    titleFrame.origin.y = nearbyintf((CGRectGetHeight(self.frame) / 2.0) - (CGRectGetHeight(titleFrame) / 2.0));
    self.title.frame = titleFrame;
    
    [self.title15 sizeToFit];
    titleFrame = self.title15.frame;
    titleFrame.origin.x = nearbyintf(CGRectGetWidth(self.frame) - CGRectGetWidth(titleFrame)) - margin.right;
    titleFrame.origin.y = nearbyintf((CGRectGetHeight(self.frame)*3.0 / 4.0) - (CGRectGetHeight(titleFrame)/ 2.0));
    self.title15.frame = titleFrame;
    
    [self.title30 sizeToFit];
    titleFrame = self.title30.frame;
    titleFrame.origin.x = nearbyintf(CGRectGetWidth(self.frame) - CGRectGetWidth(titleFrame)) - margin.right;
    titleFrame.origin.y = nearbyintf(CGRectGetHeight(self.frame) - (CGRectGetHeight(titleFrame)/ 2.0));
    //titleFrame.origin.y = nearbyintf((CGRectGetHeight(self.frame)*4.0 / 4.0) - (CGRectGetHeight(titleFrame)*3.0 / 4.0));
    self.title30.frame = titleFrame;
    
    [self.title45 sizeToFit];
    titleFrame = self.title45.frame;
    titleFrame.origin.x = nearbyintf(CGRectGetWidth(self.frame) - CGRectGetWidth(titleFrame)) - margin.right;
    titleFrame.origin.y = nearbyintf((CGRectGetHeight(self.frame)/ 4.0) - (CGRectGetHeight(titleFrame)/ 2.0));
    //titleFrame.origin.y = nearbyintf((CGRectGetHeight(self.frame)*4.0 / 4.0) - (CGRectGetHeight(titleFrame)*3.0 / 4.0));
    self.title45.frame = titleFrame;
    
    
}

-(void)setTime:(NSDate *)time
{
    //self.time = time;
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    dateFormatter.dateFormat = @"H:mm";
    //NSDateComponents *timeComponents = [[NSCalendar currentCalendar] components:(NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:time];
    self.title45.text = [dateFormatter stringFromDate:[time dateByAddingTimeInterval:-15*60]];
    self.title.text = [dateFormatter stringFromDate:time];
    self.title15.text = [dateFormatter stringFromDate:[time dateByAddingTimeInterval:15*60]];
    self.title30.text = [dateFormatter stringFromDate:[time dateByAddingTimeInterval:30*60]];
    [self setNeedsLayout];
}

@end
