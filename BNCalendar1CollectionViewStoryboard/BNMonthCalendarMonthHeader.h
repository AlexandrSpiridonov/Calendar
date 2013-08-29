//
//  BNMonthCalendarMonthHeader.h
//  BNMonthCalendar2CollectionViewCustomLayout
//
//  Created by Alexandr on 12.08.13.
//  Copyright (c) 2013 Alexander Spiridonov. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BNMonthCalendarMonthHeader : UICollectionReusableView

@property (nonatomic, strong) UILabel *monthTextLabel;
@property (nonatomic, strong) UILabel *firstDayTextLabel;
@property (nonatomic, strong) UILabel *secondTextLabel;
@property (nonatomic, strong) UILabel *thirdDayTextLabel;
@property (nonatomic, strong) UILabel *fourthDayTextLabel;
@property (nonatomic, strong) UILabel *fifthDayTextLabel;
@property (nonatomic, strong) UILabel *sixthDayTextLabel;
@property (nonatomic, strong) UILabel *seventhDayTextLabel;
@property (nonatomic, assign) CGFloat dayWidth;
@property (nonatomic, assign) CGFloat dayHeight;
@property (nonatomic, assign) UIEdgeInsets cellMargin;
@property (nonatomic, assign) CGFloat fontSizeMonth;
@property (nonatomic, assign) CGFloat fontSizeDays;

@end
