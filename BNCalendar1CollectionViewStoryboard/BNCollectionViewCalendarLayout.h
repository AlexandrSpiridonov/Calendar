//
//  BNCollectionViewCalendarLayout.h
//  BNCalendar1CollectionViewStoryboard
//
//  Created by Alexandr on 01.08.13.
//  Copyright (c) 2013 Alexander Spiridonov. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString *const BNCollectionElementKindTimeRowHeader;
extern NSString *const BNCollectionElementKindDayColumnHeader;
extern NSString *const BNCollectionElementKindTimeRowHeaderBackground;
extern NSString *const BNCollectionElementKindDayColumnHeaderBackground;
extern NSString *const BNCollectionElementKindCurrentTimeIndicator;
extern NSString *const BNCollectionElementKindCurrentTimeHorizontalGridline;
extern NSString *const BNCollectionElementKindHorizontalHourGridline;
extern NSString *const BNCollectionElementKindHorizontalMinuteGridline;
extern NSString *const BNCollectionElementKindVerticalGridline;

extern NSString *const BNCollectionElementKindWorkTimeDecorationLayer;
extern NSString *const BNCollectionElementKindLunchTimeDecorationLayer;
extern NSString *const BNCollectionElementKindCurrentDayDecorationLayer;

@class BNCollectionViewCalendarLayout;
@protocol BNCollectionViewDelegateCalendarLayout;


@interface BNCollectionViewCalendarLayout : UICollectionViewLayout

@property (nonatomic, weak) id <BNCollectionViewDelegateCalendarLayout> delegate;

@property (nonatomic, assign) CGFloat sectionWidth;
@property (nonatomic, assign) CGFloat hourHeight;
@property (nonatomic, assign) CGFloat dayColumnHeaderHeight;
@property (nonatomic, assign) CGFloat timeRowHeaderWidth;
@property (nonatomic, assign) CGSize currentTimeIndicatorSize;
@property (nonatomic, assign) CGFloat horizontalHourGridlineHeight;
@property (nonatomic, assign) CGFloat horizontalMinuteGridlineHeight;
@property (nonatomic, assign) CGFloat verticalDayGridlineHeight;
@property (nonatomic, assign) CGFloat currentTimeHorizontalGridlineHeight;
@property (nonatomic, assign) UIEdgeInsets sectionMargin;
@property (nonatomic, assign) UIEdgeInsets contentMargin;
@property (nonatomic, assign) UIEdgeInsets cellMargin;
@property (nonatomic, assign) BOOL displayHeaderBackgroundAtOrigin;

- (NSDate *)dateForTimeRowHeaderAtIndexPath:(NSIndexPath *)indexPath;
- (NSDate *)dateForDayColumnHeaderAtIndexPath:(NSIndexPath *)indexPath;
- (NSDate *)timeDateComponentsFloatX: (CGFloat)itemX FloatY: (CGFloat) itemY;
- (NSInteger)sectionToFloatX: (CGFloat)itemX;
- (NSInteger) toLengthStartFloatY: (CGFloat)startF EndFloatY: (CGFloat) endF;

- (void)scrollCollectionViewToClosetSectionToCurrentTimeAnimated:(BOOL)animated;
// Since a "reloadData" on the UICollectionView doesn't call "prepareForCollectionViewUpdates:", this method must be called first to flush the internal caches
- (void)initializeAttributesForAllSections;// загрузка всех лейаут атрибутов (вычисление и хранение)
- (void)invalidateLayoutCache;
- (void)updateLayoutAttributeItemsInSection: (NSInteger)section;
- (void)deleteLayoutAttributeItemsInSection:(NSInteger )section;
@end



@protocol BNCollectionViewDelegateCalendarLayout <UICollectionViewDelegate>

@required

- (NSDate *)collectionView:(UICollectionView *)collectionView layout:(BNCollectionViewCalendarLayout *)collectionViewLayout dayForSection:(NSInteger)section;
- (NSDate *)collectionView:(UICollectionView *)collectionView layout:(BNCollectionViewCalendarLayout *)collectionViewLayout startTimeForItemAtIndexPath:(NSIndexPath *)indexPath;
- (NSDate *)collectionView:(UICollectionView *)collectionView layout:(BNCollectionViewCalendarLayout *)collectionViewLayout endTimeForItemAtIndexPath:(NSIndexPath *)indexPath;
- (NSDate *)currentTimeComponentsForCollectionView:(UICollectionView *)collectionView layout:(BNCollectionViewCalendarLayout *)collectionViewLayout;
- (NSInteger)currentSection;
@end