//
//  BNMonthCalendarMonthHeader.m
//  BNMonthCalendar2CollectionViewCustomLayout
//
//  Created by Alexandr on 12.08.13.
//  Copyright (c) 2013 Alexander Spiridonov. All rights reserved.
//

#import "BNMonthCalendarMonthHeader.h"

@implementation BNMonthCalendarMonthHeader

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.fontSizeMonth = ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? 24.0f : 18.0f);
        self.fontSizeDays = ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? 20.0f : 14.0f);
        // Initialization code
        self.cellMargin = UIEdgeInsetsMake(0.0, 2.0, 3.0, 0.0);
        self.backgroundColor = [UIColor clearColor];
        self.monthTextLabel = [UILabel new];
		self.monthTextLabel.textAlignment = NSTextAlignmentCenter;
		self.monthTextLabel.font = [UIFont boldSystemFontOfSize:self.fontSizeMonth];
		//self.monthTextLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        self.monthTextLabel.backgroundColor = [UIColor clearColor];
		[self addSubview:self.monthTextLabel];
        
        self.firstDayTextLabel = [UILabel new];
        self.firstDayTextLabel.font = [UIFont systemFontOfSize:self.fontSizeDays];
        self.firstDayTextLabel.backgroundColor = [UIColor clearColor];
        [self addSubview:self.firstDayTextLabel];
        
        self.secondTextLabel = [UILabel new];
        self.secondTextLabel.font = [UIFont systemFontOfSize:self.fontSizeDays];
        self.secondTextLabel.backgroundColor = [UIColor clearColor];
        [self addSubview:self.secondTextLabel];
        
        self.thirdDayTextLabel = [UILabel new];
        self.thirdDayTextLabel.font = [UIFont systemFontOfSize:self.fontSizeDays];
        self.thirdDayTextLabel.backgroundColor = [UIColor clearColor];
        [self addSubview:self.thirdDayTextLabel];
        
        self.fourthDayTextLabel = [UILabel new];
        self.fourthDayTextLabel.font = [UIFont systemFontOfSize:self.fontSizeDays];
        self.fourthDayTextLabel.backgroundColor = [UIColor clearColor];
        [self addSubview:self.fourthDayTextLabel];
        
        self.fifthDayTextLabel = [UILabel new];
        self.fifthDayTextLabel.font = [UIFont systemFontOfSize:self.fontSizeDays];
        self.fifthDayTextLabel.backgroundColor = [UIColor clearColor];
        [self addSubview:self.fifthDayTextLabel];
        
        self.sixthDayTextLabel = [UILabel new];
        self.sixthDayTextLabel.font = [UIFont systemFontOfSize:self.fontSizeDays];
        self.sixthDayTextLabel.backgroundColor = [UIColor clearColor];
        [self addSubview:self.sixthDayTextLabel];
        
        self.seventhDayTextLabel = [UILabel new];
        self.seventhDayTextLabel.font = [UIFont systemFontOfSize:self.fontSizeDays];
        self.seventhDayTextLabel.backgroundColor = [UIColor clearColor];
        [self addSubview:self.seventhDayTextLabel];
    }
    return self;
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    self.dayWidth = (self.frame.size.width)/7- self.cellMargin.left;
    self.dayHeight = (self.frame.size.height)/8- self.cellMargin.bottom;
    self.dayHeight = MIN(self.dayHeight, self.dayWidth);
    
    [self.monthTextLabel sizeToFit];
    [self.firstDayTextLabel sizeToFit];
    CGRect titleFrame = self.monthTextLabel.frame;
    titleFrame.origin.x = nearbyintf((CGRectGetWidth(self.frame) / 2.0) - (CGRectGetWidth(titleFrame) / 2.0));
    titleFrame.origin.y = nearbyintf(((CGRectGetHeight(self.frame)-self.firstDayTextLabel.frame.size.height) / 2.0) - (CGRectGetHeight(titleFrame) / 2.0));
    self.monthTextLabel.frame = titleFrame;
    
    
    self.firstDayTextLabel.center = CGPointMake(self.dayWidth/2 + 0*(self.dayWidth+self.cellMargin.left),
                                                self.frame.size.height - self.firstDayTextLabel.frame.size.height/2);
    [self.secondTextLabel sizeToFit];
    self.secondTextLabel.center = CGPointMake(self.dayWidth/2 + 1*(self.dayWidth+self.cellMargin.left),
                                                self.frame.size.height - self.secondTextLabel.frame.size.height/2);
    
    [self.thirdDayTextLabel sizeToFit];
    self.thirdDayTextLabel.center = CGPointMake(self.dayWidth/2 + 2*(self.dayWidth+self.cellMargin.left),
                                                self.frame.size.height - self.thirdDayTextLabel.frame.size.height/2);
    [self.fourthDayTextLabel sizeToFit];
    self.fourthDayTextLabel.center = CGPointMake(self.dayWidth/2 + 3*(self.dayWidth+self.cellMargin.left),
                                                self.frame.size.height - self.fourthDayTextLabel.frame.size.height/2);
    
    [self.fifthDayTextLabel sizeToFit];
    self.fifthDayTextLabel.center = CGPointMake(self.dayWidth/2 + 4*(self.dayWidth+self.cellMargin.left),
                                                self.frame.size.height - self.fifthDayTextLabel.frame.size.height/2);
    [self.sixthDayTextLabel sizeToFit];
    self.sixthDayTextLabel.center = CGPointMake(self.dayWidth/2 + 5*(self.dayWidth+self.cellMargin.left),
                                                self.frame.size.height - self.sixthDayTextLabel.frame.size.height/2);
    [self.seventhDayTextLabel sizeToFit];
    self.seventhDayTextLabel.center = CGPointMake(self.dayWidth/2 + 6*(self.dayWidth+self.cellMargin.left),
                                                self.frame.size.height - self.seventhDayTextLabel.frame.size.height/2);
   }


@end
