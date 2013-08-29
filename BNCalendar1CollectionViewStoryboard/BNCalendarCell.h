//
//  BNCalendarCell.h
//  BNCalendar1CollectionViewStoryboard
//
//  Created by Alexandr on 01.08.13.
//  Copyright (c) 2013 Alexander Spiridonov. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BNCalendarItem;

@interface BNCalendarCell : UICollectionViewCell

@property (nonatomic,weak) BNCalendarItem *calendarItem;

@property (nonatomic, strong) UILabel *time;
@property (nonatomic, strong) UILabel *message;
@property (strong,nonatomic) UIColor  *frameColor;
@property (nonatomic) CGFloat    frameWidth;
@property (strong,nonatomic) NSArray  * imagesArr;

@property (strong) NSNumber * noteType; //{0 - заметка, 2 - в прошлом, 1 - в настоящем}
/*
- (UIColor *)cellBackgroundColorSelected:(BOOL)selected;
- (UIColor *)cellTextColorSelected:(BOOL)selected;
- (UIColor *)cellBorderColorSelected:(BOOL)selected;
- (UIColor *)cellTextShadowColorSelected:(BOOL)selected;
- (CGSize)cellTextShadowOffsetSelected:(BOOL)selected;

- (void)updateColors;
 */

@end
