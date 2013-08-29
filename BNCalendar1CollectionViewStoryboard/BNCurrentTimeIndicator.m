//
//  BNCurrentTimeIndicator.m
//  BNCalendar1CollectionViewStoryboard
//
//  Created by Alexandr on 27.08.13.
//  Copyright (c) 2013 Alexander Spiridonov. All rights reserved.
//

#import "BNCurrentTimeIndicator.h"
#import <QuartzCore/QuartzCore.h>

@implementation BNCurrentTimeIndicator

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.layer.borderWidth = 1.0;
        self.layer.cornerRadius = 4.0;
        self.layer.masksToBounds = YES;
        
        self.backgroundColor = [UIColor whiteColor];
        self.timeTitle = [UILabel new];
        self.timeTitle.backgroundColor = [UIColor clearColor];
        self.timeTitle.font = [UIFont fontWithName:@"Trebuchet MS" size:10];
       // self.timeTitle.textColor = [UIColor colorWithRed: 0.4 green: 0.4 blue: 0.6 alpha: 1];
        self.timeTitle.textColor = [UIColor redColor];
        self.timeTitle.shadowColor = [UIColor lightGrayColor];
        self.timeTitle.shadowOffset = CGSizeMake(0.0, 1.0);
        [self addSubview:self.timeTitle];
        self.timeTitle.text = @"##:##";
        //self.backgroundImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"image"]];
        //[self addSubview:self.backgroundImage];
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
    CGRect imageFrame = self.frame;
    /*
    imageFrame.size.height = buttonFrame.size.height-2;
    imageFrame.size.width = buttonFrame.size.width-4;
    imageFrame.origin.x = 2;
    imageFrame.origin.y = 1;
    self.backgroundImage.frame  = imageFrame;
    */
    
    [self.timeTitle sizeToFit];
    CGRect dateFrame = self.timeTitle.frame;
    dateFrame.origin.x = nearbyintf(CGRectGetWidth(imageFrame)/ 2.0 - CGRectGetWidth(dateFrame)/ 2.0);
    dateFrame.origin.y = nearbyintf(CGRectGetHeight(imageFrame)/ 2.0 - CGRectGetHeight(dateFrame) / 2.0);
    self.timeTitle.frame = dateFrame;
}

@end
