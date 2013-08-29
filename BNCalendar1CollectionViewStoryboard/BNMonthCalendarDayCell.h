//
//  BNMonthCalendarDayCell.h
//  BNMonthCalendar2CollectionViewCustomLayout
//
//  Created by Alexandr on 12.08.13.
//  Copyright (c) 2013 Alexander Spiridonov. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BNMonthCalendarDayCell : UICollectionViewCell

@property (nonatomic, strong) UILabel *dayTextLabel;
@property (nonatomic, strong) NSDate * day;
@property (nonatomic, assign) CGFloat dayWidth;
@property (nonatomic, assign) CGFloat dayHeight;
@property (nonatomic, assign) UIEdgeInsets cellMargin;

@end
