//
//  BNCollectionViewCalendarLayout.m
//  BNCalendar1CollectionViewStoryboard
//
//  Created by Alexandr on 01.08.13.
//  Copyright (c) 2013 Alexander Spiridonov. All rights reserved.
//

#import "BNCollectionViewCalendarLayout.h"


NSString *const BNCollectionElementKindTimeRowHeader = @"BNCollectionElementKindTimeRow";
NSString *const BNCollectionElementKindDayColumnHeader = @"BNCollectionElementKindDayHeader";
NSString *const BNCollectionElementKindCurrentTimeIndicator = @"BNCollectionElementKindCurrentTimeIndicator";
NSString *const BNCollectionElementKindVerticalGridline = @"BNCollectionElementKindVerticalGridline";
NSString *const BNCollectionElementKindHorizontalHourGridline = @"BNCollectionElementKindHorizontalHourGridline";
NSString *const BNCollectionElementKindHorizontalMinuteGridline = @"BNCollectionElementKindHorizontalMinuteGridline";
NSString *const BNCollectionElementKindCurrentTimeHorizontalGridline = @"BNCollectionElementKindCurrentTimeHorizontalGridline";
NSString *const BNCollectionElementKindTimeRowHeaderBackground = @"BNCollectionElementKindTimeRowHeaderBackground";
NSString *const BNCollectionElementKindDayColumnHeaderBackground = @"BNCollectionElementKindDayColumnHeaderBackground";
NSString *const BNCollectionElementKindWorkTimeDecorationLayer = @"BNCollectionElementKindWorkTimeDecorationLayer";
NSString *const BNCollectionElementKindLunchTimeDecorationLayer = @"BNCollectionElementKindLunchTimeDecorationLayer";
NSString *const BNCollectionElementKindCurrentDayDecorationLayer = @"BNCollectionElementKindCurrentDayDecorationLayer";


NSUInteger const BNCollectionMinOverlayZ = 1000.0; // Allows for 900 items in a sectio without z overlap issues
NSUInteger const BNCollectionMinCellZ = 100.0;  // Allows for 100 items in a section's background
NSUInteger const BNCollectionMinBackgroundZ = 0.0;


@interface BNTimerWeakTarget : NSObject
@property (nonatomic, weak) id target;
@property (nonatomic, assign) SEL selector;
- (SEL)fireSelector;
@end

@implementation BNTimerWeakTarget
- (id)initWithTarget:(id)target selector:(SEL)selector
{
    self = [super init];
    if (self) {
        self.target = target;
        self.selector = selector;
    }
    return self;
}
- (void)fire:(NSTimer*)timer
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [self.target performSelector:self.selector withObject:timer];
#pragma clang diagnostic pop
}
- (SEL)fireSelector
{
    return @selector(fire:);
}
@end


@interface BNCollectionViewCalendarLayout()
//===========
// Minute Timer
@property (nonatomic, strong) NSTimer *minuteTimer;

// Minute Height
@property (nonatomic, readonly) CGFloat minuteHeight;


@property (nonatomic, assign) BOOL needsToPopulateAttributesForAllSections;
// Caches
//кэшируются аттрибуты рисования бэкраунда и хедеров и их бэкраундов
@property (nonatomic, assign) CGFloat cachedMaxColumnHeight;
@property (nonatomic, strong) NSMutableDictionary *cachedColumnHeights;
// Registered Decoration Classes
@property (nonatomic, strong) NSMutableDictionary *registeredDecorationClasses;

// Attributes
@property (nonatomic, strong) NSMutableArray *allAttributes;
@property (nonatomic, strong) NSMutableDictionary *itemAttributes;
@property (nonatomic, strong) NSMutableDictionary *dayColumnHeaderAttributes;
@property (nonatomic, strong) NSMutableDictionary *dayColumnHeaderBackgroundAttributes;
@property (nonatomic, strong) NSMutableDictionary *timeRowHeaderAttributes;
@property (nonatomic, strong) NSMutableDictionary *timeRowHeaderBackgroundAttributes;
@property (nonatomic, strong) NSMutableDictionary *horizontalHourGridlineAttributes;
@property (nonatomic, strong) NSMutableDictionary *horizontalMinuteGridlineAttributes;
@property (nonatomic, strong) NSMutableDictionary *verticalGridlineAttributes;
@property (nonatomic, strong) NSMutableDictionary *currentTimeIndicatorAttributes;
@property (nonatomic, strong) NSMutableDictionary *currentTimeHorizontalGridlineAttributes;
@property (nonatomic, strong) NSMutableDictionary *backgroundLayerAttributes;

// arrays to keep track of insert, delete index paths
@property (nonatomic, strong) NSMutableArray *deleteIndexPaths;
@property (nonatomic, strong) NSMutableArray *insertIndexPaths;

- (void)initialize;
// Minute Updates
- (void)minuteTick:(id)sender;
// Layout
- (UICollectionViewLayoutAttributes *)layoutAttributesForDecorationViewAtIndexPath:(NSIndexPath *)indexPath ofKind:(NSString *)kind withItemCache:(NSMutableDictionary *)itemCache;
- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewAtIndexPath:(NSIndexPath *)indexPath ofKind:(NSString *)kind withItemCache:(NSMutableDictionary *)itemCache;
- (UICollectionViewLayoutAttributes *)layoutAttributesForCellAtIndexPath:(NSIndexPath *)indexPath withItemCache:(NSMutableDictionary *)itemCache;
// Scrolling
- (NSInteger)closestSectionToCurrentTime;
// Section Sizing
- (CGRect)rectForSection:(NSInteger)section;
- (CGFloat)maxSectionHeight;
- (CGFloat)stackedSectionHeight;
- (CGFloat)stackedSectionHeightUpToSection:(NSInteger)upToSection;
- (CGFloat)sectionHeight:(NSInteger)section;
- (CGFloat)minuteHeight;
// Z Index
- (CGFloat)zIndexForElementKind:(NSString *)elementKind;
- (CGFloat)zIndexForElementKind:(NSString *)elementKind floating:(BOOL)floating;
// Delegate Wrappers
- (NSDateComponents *)dayForSection:(NSInteger)section;
- (NSDateComponents *)startTimeForIndexPath:(NSIndexPath *)indexPath;
- (NSDateComponents *)endTimeForIndexPath:(NSIndexPath *)indexPath;
- (NSDateComponents *)currentTimeDateComponents;
@end

@implementation BNCollectionViewCalendarLayout

#pragma mark - NSObject
- (void)dealloc
{
    //удаляем таймер
    [self.minuteTimer invalidate];
    self.minuteTimer = nil;
}

- (id)init
{
    self = [super init];
    if (self) {
        [self initialize];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialize];
    }
    return self;
}

#pragma mark - UICollectionViewLayout


//вызов обновления collection view // бесполезный метод
- (void)prepareForCollectionViewUpdates:(NSArray *)updateItems
{
   // [self invalidateLayoutCache];
    // Update the layout with the new items
    [self prepareLayout];
    
    [super prepareForCollectionViewUpdates:updateItems];
}

//по окончанию загрузки collection view
// иногда не рtсуется dicoration view и suplementary view
- (void)finalizeCollectionViewUpdates
{
    // This is a hack to prevent the error detailed in :
    // http://stackoverflow.com/questions/12857301/uicollectionview-decoration-and-supplementary-views-can-not-be-moved
    // If this doesn't happen, whenever the collection view has batch updates performed on it, we get multiple instantiations of decoration classes
    for (UIView *subview in self.collectionView.subviews) {
        for (Class decorationViewClass in self.registeredDecorationClasses.allValues) {
            if ([subview isKindOfClass:decorationViewClass]) {
                [subview removeFromSuperview];
            }
        }
    }
    [self.collectionView reloadData];
}

/*
- (void)prepareForCollectionViewUpdates:(NSArray *)updateItems
{
    NSLog(@"pre");
    
    // Keep track of insert and delete index paths
   
    self.deleteIndexPaths = [NSMutableArray array];
    self.insertIndexPaths = [NSMutableArray array];
    
    for (UICollectionViewUpdateItem *update in updateItems)
    {
        if (update.updateAction == UICollectionUpdateActionDelete)
        {
            [self.deleteIndexPaths addObject:update.indexPathBeforeUpdate];
            
        }
        else if (update.updateAction == UICollectionUpdateActionInsert)
        {
            [self.insertIndexPaths addObject:update.indexPathAfterUpdate];
            UICollectionViewLayoutAttributes *attributes = [self layoutAttributesForCellAtIndexPath:update.indexPathAfterUpdate withItemCache:self.itemAttributes];
        }
    }
    [super prepareForCollectionViewUpdates:updateItems];
}

- (void)finalizeCollectionViewUpdates
{
     NSLog(@"fina");
    //[super finalizeCollectionViewUpdates];
    // This is a hack to prevent the error detailed in :
    // http://stackoverflow.com/questions/12857301/uicollectionview-decoration-and-supplementary-views-can-not-be-moved
    // If this doesn't happen, whenever the collection view has batch updates performed on it, we get multiple instantiations of decoration classes
    for (UIView *subview in self.collectionView.subviews) {
        for (Class decorationViewClass in self.registeredDecorationClasses.allValues) {
            if ([subview isKindOfClass:decorationViewClass]) {
                [subview removeFromSuperview];
            }
        }
    }
    // release the insert and delete index paths
   
    for(NSIndexPath *deleteIndexPath in self.deleteIndexPaths) {
        [self.itemAttributes removeObjectForKey:deleteIndexPath];
    }
    [self.collectionView reloadData];
    self.deleteIndexPaths = nil;
    self.insertIndexPaths = nil;
}

// Note: name of method changed
// Also this gets called for all visible cells (not just the inserted ones) and
// even gets called when deleting cells!
- (UICollectionViewLayoutAttributes *)initialLayoutAttributesForAppearingItemAtIndexPath:(NSIndexPath *)itemIndexPath
{
    // Must call super
    UICollectionViewLayoutAttributes *attributes = [super initialLayoutAttributesForAppearingItemAtIndexPath:itemIndexPath];
    
    if ([self.insertIndexPaths containsObject:itemIndexPath])
    {
        NSLog(@"ins");
        //надо вставить кэш функции создания атрибута
        // only change attributes on inserted cells
        if (!attributes)
            attributes = [self layoutAttributesForItemAtIndexPath:itemIndexPath];
        attributes.alpha = 1.0;
    }
    
    return attributes;
}

// Note: name of method changed
// Also this gets called for all visible cells (not just the deleted ones) and
// even gets called when inserting cells!
- (UICollectionViewLayoutAttributes *)finalLayoutAttributesForDisappearingItemAtIndexPath:(NSIndexPath *)itemIndexPath
{
    // So far, calling super hasn't been strictly necessary here, but leaving it in
    // for good measure
    UICollectionViewLayoutAttributes *attributes = [super finalLayoutAttributesForDisappearingItemAtIndexPath:itemIndexPath];
    
    if ([self.deleteIndexPaths containsObject:itemIndexPath])
    {
        NSLog(@"del");
        // only change attributes on deleted cells
        if (!attributes)
            attributes = [self layoutAttributesForItemAtIndexPath:itemIndexPath];
        attributes.alpha = 0.0;
    }
    
    return attributes;
}
*/

- (void)registerClass:(Class)viewClass forDecorationViewOfKind:(NSString *)decorationViewKind
{
    [super registerClass:viewClass forDecorationViewOfKind:decorationViewKind];
    self.registeredDecorationClasses[decorationViewKind] = viewClass;
}

//загрузка всех layoutAttributes
- (void)initializeAttributesForAllSections
{
    if (self.needsToPopulateAttributesForAllSections) {
        [self prepareSectionLayoutForSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, self.collectionView.numberOfSections)]];
        self.needsToPopulateAttributesForAllSections = NO;
    }
}

//сообщает layout'у чтобы тот обновился
- (void)prepareLayout
{
    [super prepareLayout];
    
    //[self initializeAttributesForAllSections];//временно
}

- (void)updateLayoutAttributeItemsInSection:(NSInteger )section
{
    CGFloat sectionWidth = (self.sectionMargin.left + self.sectionWidth + self.sectionMargin.right);
    CGFloat calendarGridMinX = (self.timeRowHeaderWidth + self.contentMargin.left);
    CGFloat calendarGridMinY = (self.dayColumnHeaderHeight + self.contentMargin.top);
    CGFloat sectionMinX = (calendarGridMinX + self.sectionMargin.left + (sectionWidth * section));
    NSMutableArray *sectionItemAttributes = [NSMutableArray new];

    for (NSInteger item = 0; item < [self.collectionView numberOfItemsInSection: section]; item++) {
        NSIndexPath *itemIndexPath = [NSIndexPath indexPathForItem:item inSection: section];
        UICollectionViewLayoutAttributes *itemAttribute = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:itemIndexPath];
        [self.itemAttributes setObject:itemAttribute forKey:itemIndexPath];
        [sectionItemAttributes addObject:itemAttribute];
        NSDate *date = [self.delegate collectionView:self.collectionView layout:self startTimeForItemAtIndexPath:itemIndexPath];
        NSDateComponents *timeComponents = [[NSCalendar currentCalendar] components:(NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:date];
        CGFloat startHourY = (timeComponents.hour * self.hourHeight);
        CGFloat startMinuteY = (timeComponents.minute * self.minuteHeight);
        
        date = [self.delegate collectionView:self.collectionView layout:self endTimeForItemAtIndexPath:itemIndexPath];
        timeComponents = [[NSCalendar currentCalendar] components:(NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:date];
        CGFloat endHourY;
        endHourY = ((timeComponents.hour) * self.hourHeight);
        CGFloat endMinuteY = (timeComponents.minute * self.minuteHeight);
        CGFloat itemMinY = (startHourY + startMinuteY + calendarGridMinY + self.cellMargin.top);
        CGFloat itemMaxY = (endHourY + endMinuteY + calendarGridMinY - self.cellMargin.bottom);
        CGFloat itemMinX = (sectionMinX + self.cellMargin.left);
        CGFloat itemMaxX = (itemMinX + (self.sectionWidth - self.cellMargin.left - self.cellMargin.right));
        itemAttribute.frame = CGRectMake(itemMinX, itemMinY, (itemMaxX - itemMinX), (itemMaxY - itemMinY));
        itemAttribute.zIndex = [self zIndexForElementKind:nil];
    }
    [self adjustItemsForOverlap:sectionItemAttributes inSection: section sectionMinX:sectionMinX];
    [self invalidateLayout];
}

- (void)deleteLayoutAttributeItemsInSection:(NSInteger )section
{
    for (NSInteger item = 0; item < [self.collectionView numberOfItemsInSection: section]; item++) {
        NSIndexPath *itemIndexPath = [NSIndexPath indexPathForItem:item inSection: section];
        [self.itemAttributes removeObjectForKey:itemIndexPath];
    }
}


- (void)prepareSectionLayoutForSections:(NSIndexSet *)sectionIndexes
{
    //метод значительно изменится в связи с CoreData // так как объекты быдут хранится не дикшионари а сразу в coredate
    
    if (self.collectionView.numberOfSections == 0) {
        return;
    }
    
    BOOL needsToPopulateHorizontalGridlineAttributes = (self.horizontalHourGridlineAttributes.count == 0);
    
    CGFloat sectionWidth = (self.sectionMargin.left + self.sectionWidth + self.sectionMargin.right);
    CGFloat calendarGridMinX = (self.timeRowHeaderWidth + self.contentMargin.left);
    CGFloat calendarGridMinY = (self.dayColumnHeaderHeight + self.contentMargin.top);
    CGFloat calendarGridWidth = (self.collectionViewContentSize.width - self.timeRowHeaderWidth - self.contentMargin.right);
    CGFloat calendarGridHight = (self.collectionViewContentSize.height - self.contentMargin.top);
    // Time Row Header
    CGFloat timeRowHeaderMinX = fmaxf(self.collectionView.contentOffset.x, 0.0);
    BOOL timeRowHeaderFloating = ((timeRowHeaderMinX != 0) || self.displayHeaderBackgroundAtOrigin);
    
    // Time Row Header Background
    NSIndexPath *timeRowHeaderBackgroundIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    UICollectionViewLayoutAttributes *timeRowHeaderBackgroundAttributes = [self layoutAttributesForDecorationViewAtIndexPath:timeRowHeaderBackgroundIndexPath ofKind:BNCollectionElementKindTimeRowHeaderBackground withItemCache:self.timeRowHeaderBackgroundAttributes];
    // Frame
    CGFloat timeRowHeaderBackgroundHeight = fmaxf(self.collectionViewContentSize.height + self.collectionView.frame.size.height, self.collectionView.frame.size.height);
    CGFloat timeRowHeaderBackgroundWidth = fmaxf(self.collectionViewContentSize.width + self.collectionView.frame.size.width, self.collectionView.frame.size.width);
    CGFloat timeRowHeaderBackgroundMinX = (timeRowHeaderMinX - timeRowHeaderBackgroundWidth + self.timeRowHeaderWidth);
    CGFloat timeRowHeaderBackgroundMinY = -nearbyintf(self.collectionView.frame.size.height / 2.0);
    timeRowHeaderBackgroundAttributes.frame = CGRectMake(timeRowHeaderBackgroundMinX, timeRowHeaderBackgroundMinY, timeRowHeaderBackgroundWidth, timeRowHeaderBackgroundHeight);
    // Floating
    timeRowHeaderBackgroundAttributes.hidden = !timeRowHeaderFloating;
    timeRowHeaderBackgroundAttributes.zIndex = [self zIndexForElementKind:BNCollectionElementKindTimeRowHeaderBackground floating:timeRowHeaderFloating];
    
    // Current Time Indicator
    NSIndexPath *currentTimeIndicatorIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    //UICollectionViewLayoutAttributes *currentTimeIndicatorAttributes = [self layoutAttributesForDecorationViewAtIndexPath:currentTimeIndicatorIndexPath ofKind:BNCollectionElementKindCurrentTimeIndicator withItemCache:self.currentTimeIndicatorAttributes];
     UICollectionViewLayoutAttributes *currentTimeIndicatorAttributes = [self layoutAttributesForSupplementaryViewAtIndexPath:currentTimeIndicatorIndexPath ofKind:BNCollectionElementKindCurrentTimeIndicator withItemCache:self.currentTimeIndicatorAttributes];
    
    // Current Time Horizontal Gridline
    NSIndexPath *currentTimeHorizontalGridlineIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    UICollectionViewLayoutAttributes *currentTimeHorizontalGridlineAttributes = [self layoutAttributesForDecorationViewAtIndexPath:currentTimeHorizontalGridlineIndexPath ofKind:BNCollectionElementKindCurrentTimeHorizontalGridline withItemCache:self.currentTimeHorizontalGridlineAttributes];
    
    // The current time is within the day
    NSDateComponents *currentTimeDateComponents = [self currentTimeDateComponents];
    BOOL currentTimeIndicatorVisible = ((currentTimeDateComponents.hour >= 0) && (currentTimeDateComponents.hour < 24));
    
    if (currentTimeIndicatorVisible) {
        // The y value of the current time
        CGFloat timeY = (calendarGridMinY + nearbyintf(((currentTimeDateComponents.hour) * self.hourHeight) + (currentTimeDateComponents.minute * self.minuteHeight)));
        
        CGFloat currentTimeIndicatorMinY = (timeY - nearbyintf(self.currentTimeIndicatorSize.height / 2.0));
        //CGFloat currentTimeIndicatorMinX = (fmaxf(self.collectionView.contentOffset.x, 0.0) + (self.timeRowHeaderWidth - self.currentTimeIndicatorSize.width));
        CGFloat currentTimeIndicatorMinX = fmaxf(self.collectionView.contentOffset.x, 0.0) +self.collectionView.frame.size.width - self.currentTimeIndicatorSize.width;
        currentTimeIndicatorAttributes.frame = (CGRect){{currentTimeIndicatorMinX, currentTimeIndicatorMinY}, self.currentTimeIndicatorSize};
        currentTimeIndicatorAttributes.zIndex = [self zIndexForElementKind:BNCollectionElementKindCurrentTimeIndicator floating:timeRowHeaderFloating];
        
        CGFloat currentTimeHorizontalGridlineMinY = (timeY - nearbyintf(self.currentTimeHorizontalGridlineHeight / 2.0));
        currentTimeHorizontalGridlineAttributes.frame = CGRectMake(calendarGridMinX, currentTimeHorizontalGridlineMinY, calendarGridWidth, self.currentTimeHorizontalGridlineHeight);
        currentTimeHorizontalGridlineAttributes.zIndex = [self zIndexForElementKind:BNCollectionElementKindCurrentTimeHorizontalGridline];
    } else {
        currentTimeIndicatorAttributes.frame = CGRectZero;
        currentTimeHorizontalGridlineAttributes.frame = CGRectZero;
    }
    
    // Day Column Header
    CGFloat dayColumnHeaderMinY = fmaxf(self.collectionView.contentOffset.y, 0.0);
    BOOL dayColumnHeaderFloating = ((dayColumnHeaderMinY != 0) || self.displayHeaderBackgroundAtOrigin);
    
    // Day Column Header Background
    NSIndexPath *dayColumnHeaderBackgroundIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    UICollectionViewLayoutAttributes *dayColumnHeaderBackgroundAttributes = [self layoutAttributesForDecorationViewAtIndexPath:dayColumnHeaderBackgroundIndexPath ofKind:BNCollectionElementKindDayColumnHeaderBackground withItemCache:self.dayColumnHeaderBackgroundAttributes];
    // Frame
    CGFloat dayColumnHeaderBackgroundWidth = fmaxf(self.collectionViewContentSize.width + self.collectionView.frame.size.width, self.collectionView.frame.size.width);
    CGFloat dayColumnHeaderBackgroundHeight = fmaxf(self.collectionViewContentSize.height + self.collectionView.frame.size.height, self.collectionView.frame.size.height);
    CGFloat dayColumnHeaderBackgroundMinX = -nearbyintf(self.collectionView.frame.size.width / 2.0);
    CGFloat dayColumnHeaderBackgroundMinY = (dayColumnHeaderMinY - dayColumnHeaderBackgroundHeight + self.dayColumnHeaderHeight);
    dayColumnHeaderBackgroundAttributes.frame = CGRectMake(dayColumnHeaderBackgroundMinX, dayColumnHeaderBackgroundMinY, dayColumnHeaderBackgroundWidth, dayColumnHeaderBackgroundHeight);
    // Floating
    dayColumnHeaderBackgroundAttributes.hidden = !dayColumnHeaderFloating;
    dayColumnHeaderBackgroundAttributes.zIndex = [self zIndexForElementKind:BNCollectionElementKindDayColumnHeaderBackground floating:dayColumnHeaderFloating];
    
    // Time Row Headers
    NSUInteger timeRowHeaderIndex = 0;
    for (NSInteger hour = 0; hour <= 24; hour++) {
        NSIndexPath *timeRowHeaderIndexPath = [NSIndexPath indexPathForItem:timeRowHeaderIndex inSection:0];
        UICollectionViewLayoutAttributes *timeRowHeaderAttributes = [self layoutAttributesForSupplementaryViewAtIndexPath:timeRowHeaderIndexPath ofKind:BNCollectionElementKindTimeRowHeader withItemCache:self.timeRowHeaderAttributes];
        CGFloat titleRowHeaderMinY = (calendarGridMinY + (self.hourHeight * (hour)) - nearbyintf(self.hourHeight / 2.0));
        timeRowHeaderAttributes.frame = CGRectMake(timeRowHeaderMinX, titleRowHeaderMinY, self.timeRowHeaderWidth, self.hourHeight);
        timeRowHeaderAttributes.zIndex = [self zIndexForElementKind:BNCollectionElementKindTimeRowHeader floating:timeRowHeaderFloating];
        timeRowHeaderIndex++;
    }
    
    //============<<<< измениться
    BOOL needsToPopulateItemAttributes = (self.itemAttributes.count == 0);//уберется вообще так как 
    [sectionIndexes enumerateIndexesUsingBlock:^(NSUInteger section, BOOL *stop) {
        
        CGFloat sectionMinX = (calendarGridMinX + self.sectionMargin.left + (sectionWidth * section));
        // Day Column Header
        UICollectionViewLayoutAttributes *dayColumnHeaderAttributes = [self layoutAttributesForSupplementaryViewAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:section] ofKind:BNCollectionElementKindDayColumnHeader withItemCache:self.dayColumnHeaderAttributes];
        // Frame
        dayColumnHeaderAttributes.frame = CGRectMake(sectionMinX, dayColumnHeaderMinY, self.sectionWidth, self.dayColumnHeaderHeight);
        dayColumnHeaderAttributes.zIndex = [self zIndexForElementKind:BNCollectionElementKindDayColumnHeader floating:dayColumnHeaderFloating];
        
       // }
        
        if (needsToPopulateItemAttributes) {
            //Vertical Gridline
            //if (needsToPopulateHorizontalGridlineAttributes) {
            UICollectionViewLayoutAttributes *verticalGridlineAttributes = [self layoutAttributesForDecorationViewAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:section] ofKind:BNCollectionElementKindVerticalGridline withItemCache:self.verticalGridlineAttributes];
            verticalGridlineAttributes.frame = CGRectMake(sectionMinX, dayColumnHeaderMinY, self.verticalDayGridlineHeight, self.collectionViewContentSize.height);
            
            // Items
            NSMutableArray *sectionItemAttributes = [NSMutableArray new];
            for (NSInteger item = 0; item < [self.collectionView numberOfItemsInSection:section]; item++) {
                
                NSIndexPath *itemIndexPath = [NSIndexPath indexPathForItem:item inSection:section];
                UICollectionViewLayoutAttributes *itemAttributes = [self layoutAttributesForCellAtIndexPath:itemIndexPath withItemCache:self.itemAttributes];
                [sectionItemAttributes addObject:itemAttributes];
                NSDate *date = [self.delegate collectionView:self.collectionView layout:self startTimeForItemAtIndexPath:itemIndexPath];
                NSDateComponents *timeComponents = [[NSCalendar currentCalendar] components:(NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:date];
                CGFloat startHourY = (timeComponents.hour * self.hourHeight);
                CGFloat startMinuteY = (timeComponents.minute * self.minuteHeight);
                
                date = [self.delegate collectionView:self.collectionView layout:self endTimeForItemAtIndexPath:itemIndexPath];
                timeComponents = [[NSCalendar currentCalendar] components:(NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:date];
                CGFloat endHourY;
                    endHourY = ((timeComponents.hour) * self.hourHeight);
                CGFloat endMinuteY = (timeComponents.minute * self.minuteHeight);

                CGFloat itemMinY = (startHourY + startMinuteY + calendarGridMinY + self.cellMargin.top);
                CGFloat itemMaxY = (endHourY + endMinuteY + calendarGridMinY - self.cellMargin.bottom);
                CGFloat itemMinX = (sectionMinX + self.cellMargin.left);
                CGFloat itemMaxX = (itemMinX + (self.sectionWidth - self.cellMargin.left - self.cellMargin.right));
                itemAttributes.frame = CGRectMake(itemMinX, itemMinY, (itemMaxX - itemMinX), (itemMaxY - itemMinY));
                itemAttributes.zIndex = [self zIndexForElementKind:nil];
            }
            [self adjustItemsForOverlap:sectionItemAttributes inSection:section sectionMinX:sectionMinX];
        }
    }];
    
    //============<<<< измениться
    // Horizontal Gridlines
    if (needsToPopulateHorizontalGridlineAttributes) {
        NSUInteger horizontalHourGridlineIndex = 0;
        NSUInteger horizontalMinuteGridlineIndex = 0;
        
        for (NSInteger hour = 0; hour <= 24; hour++) {
            NSIndexPath *horizontalHourGridlineIndexPath = [NSIndexPath indexPathForItem:horizontalHourGridlineIndex inSection:0];
            UICollectionViewLayoutAttributes *horizontalHourGridlineAttributes = [self layoutAttributesForDecorationViewAtIndexPath:horizontalHourGridlineIndexPath ofKind:BNCollectionElementKindHorizontalHourGridline withItemCache:self.horizontalHourGridlineAttributes];
            CGFloat horizontalHourGridlineMinY = (calendarGridMinY + (self.hourHeight * (hour))) - nearbyintf(self.horizontalHourGridlineHeight / 2.0);
            horizontalHourGridlineAttributes.frame = CGRectMake(calendarGridMinX, horizontalHourGridlineMinY, calendarGridWidth, self.horizontalHourGridlineHeight);
            horizontalHourGridlineIndex++;
            
            //minutes grid line
            NSIndexPath *horizontalMinuteGridlineIndexPath15 = [NSIndexPath indexPathForItem:horizontalMinuteGridlineIndex inSection:0];
            UICollectionViewLayoutAttributes *horizontalMinuteGridlineAttributes15 = [self layoutAttributesForDecorationViewAtIndexPath:horizontalMinuteGridlineIndexPath15 ofKind:BNCollectionElementKindHorizontalMinuteGridline withItemCache:self.horizontalMinuteGridlineAttributes];
            CGFloat horizontalMinuteGridlineMinY15 = (calendarGridMinY + (self.hourHeight * (hour)) + self.hourHeight/4) - nearbyintf(self.horizontalMinuteGridlineHeight/ 2.0);
            horizontalMinuteGridlineAttributes15.frame = CGRectMake(calendarGridMinX, horizontalMinuteGridlineMinY15, calendarGridWidth, self.horizontalMinuteGridlineHeight);
            
            horizontalMinuteGridlineIndex++;
            
            NSIndexPath *horizontalMinuteGridlineIndexPath30 = [NSIndexPath indexPathForItem:horizontalMinuteGridlineIndex inSection:0];
            UICollectionViewLayoutAttributes *horizontalMinuteGridlineAttributes30 = [self layoutAttributesForDecorationViewAtIndexPath:horizontalMinuteGridlineIndexPath30 ofKind:BNCollectionElementKindHorizontalMinuteGridline withItemCache:self.horizontalMinuteGridlineAttributes];
            CGFloat horizontalMinuteGridlineMinY30 = (calendarGridMinY + (self.hourHeight * (hour)) + self.hourHeight/2) - nearbyintf(self.horizontalMinuteGridlineHeight/ 2.0);
            horizontalMinuteGridlineAttributes30.frame = CGRectMake(calendarGridMinX, horizontalMinuteGridlineMinY30, calendarGridWidth, self.horizontalMinuteGridlineHeight);
            
            horizontalMinuteGridlineIndex++;
            
            NSIndexPath *horizontalMinuteGridlineIndexPath45 = [NSIndexPath indexPathForItem:horizontalMinuteGridlineIndex inSection:0];
            UICollectionViewLayoutAttributes *horizontalMinuteGridlineAttributes45 = [self layoutAttributesForDecorationViewAtIndexPath:horizontalMinuteGridlineIndexPath45 ofKind:BNCollectionElementKindHorizontalMinuteGridline withItemCache:self.horizontalMinuteGridlineAttributes];
            CGFloat horizontalMinuteGridlineMinY45 = (calendarGridMinY + (self.hourHeight * (hour)) + 3*self.hourHeight/4) - nearbyintf(self.horizontalMinuteGridlineHeight/ 2.0);
            horizontalMinuteGridlineAttributes45.frame = CGRectMake(calendarGridMinX, horizontalMinuteGridlineMinY45, calendarGridWidth, self.horizontalMinuteGridlineHeight);
            
            horizontalMinuteGridlineIndex++;
        }
        
        //backGroundLayers
        //BNCollectionElementKindCurrentDayDecorationLayer
        NSIndexPath * currentDayDecorationLayerIndexPath= [NSIndexPath indexPathForRow:0 inSection:0];//posle
        UICollectionViewLayoutAttributes *currentDayDecorationAttributes = [self layoutAttributesForDecorationViewAtIndexPath:currentDayDecorationLayerIndexPath ofKind:BNCollectionElementKindCurrentDayDecorationLayer withItemCache:self.backgroundLayerAttributes];
        CGFloat  currentDayMinX = (calendarGridMinX + (sectionWidth * [self currentSection]));
        currentDayDecorationAttributes.frame = CGRectMake(currentDayMinX, calendarGridMinY, (self.sectionWidth), calendarGridHight-calendarGridMinY);
        currentDayDecorationAttributes.alpha = 0.1;
        // Floating
        //currentDayDecorationAttributes.zIndex = [self zIndexForElementKind:BNCollectionElementKindCurrentDayDecorationLayer floating:YES];
        
        
        //BNCollectionElementKindWorkTimeDecorationLayer
        NSIndexPath *workTimeDecorationLayerIndexPath = [NSIndexPath indexPathForRow:1 inSection:0];//do
        UICollectionViewLayoutAttributes *workTimeDecorationAttributes = [self layoutAttributesForDecorationViewAtIndexPath:workTimeDecorationLayerIndexPath ofKind:BNCollectionElementKindWorkTimeDecorationLayer withItemCache:self.backgroundLayerAttributes];
        NSInteger minutes = [[NSUserDefaults standardUserDefaults] integerForKey:@"strartWorkTime"];
        CGFloat workTimeStart = (self.minuteHeight * minutes);
        workTimeDecorationAttributes.frame = CGRectMake(calendarGridMinX,calendarGridMinY, calendarGridWidth, workTimeStart);
        workTimeDecorationAttributes.alpha = 0.1;
        workTimeDecorationAttributes.zIndex = [self zIndexForElementKind:BNCollectionElementKindWorkTimeDecorationLayer floating:YES];
        
        workTimeDecorationLayerIndexPath = [NSIndexPath indexPathForRow:2 inSection:0];//posle
        workTimeDecorationAttributes = [self layoutAttributesForDecorationViewAtIndexPath:workTimeDecorationLayerIndexPath ofKind:BNCollectionElementKindWorkTimeDecorationLayer withItemCache:self.backgroundLayerAttributes];
        minutes = [[NSUserDefaults standardUserDefaults] integerForKey:@"endWorkTime"];
        CGFloat workTimeEnd = calendarGridMinY + (self.minuteHeight * minutes);
        workTimeDecorationAttributes.frame = CGRectMake(calendarGridMinX, workTimeEnd, calendarGridWidth, calendarGridHight-workTimeEnd);
        workTimeDecorationAttributes.alpha = 0.1;
        workTimeDecorationAttributes.zIndex = [self zIndexForElementKind:BNCollectionElementKindWorkTimeDecorationLayer floating:YES];
        
        //BNCollectionElementKindLunchTimeDecorationLayer
        NSIndexPath *lunchTimeDecorationLayerIndexPath = [NSIndexPath indexPathForRow:3 inSection:0];//обед
        UICollectionViewLayoutAttributes *lunchTimeDecorationAttributes = [self layoutAttributesForDecorationViewAtIndexPath:lunchTimeDecorationLayerIndexPath ofKind:BNCollectionElementKindLunchTimeDecorationLayer withItemCache:self.backgroundLayerAttributes];
        minutes = [[NSUserDefaults standardUserDefaults] integerForKey:@"strartLunchTime"];
        CGFloat strartLunchTime = calendarGridMinY + (self.minuteHeight * minutes);
        minutes = [[NSUserDefaults standardUserDefaults] integerForKey:@"endLunchTime"];
        CGFloat endLunchTime = calendarGridMinY + (self.minuteHeight * minutes) ;
        lunchTimeDecorationAttributes.frame = CGRectMake(calendarGridMinX, strartLunchTime, calendarGridWidth, endLunchTime-strartLunchTime);
        lunchTimeDecorationAttributes.alpha = 0.1;
        lunchTimeDecorationAttributes.zIndex = [self zIndexForElementKind:BNCollectionElementKindLunchTimeDecorationLayer floating:YES];
    }
}

//метод, который пересчитывает frame в случае наложения объектов
- (void)adjustItemsForOverlap:(NSArray *)sectionItemAttributes inSection:(NSUInteger)section sectionMinX:(CGFloat)sectionMinX
{
    NSMutableSet *adjustedAttributes = [NSMutableSet new];
    NSUInteger sectionZ = BNCollectionMinCellZ;
    
    for (UICollectionViewLayoutAttributes *itemAttributes in sectionItemAttributes) {
        
        // If an item's already been adjusted, move on to the next one
        if ([adjustedAttributes containsObject:itemAttributes]) {
            continue;
        }
        
        // Find the other items that overlap with this item
        NSMutableArray *overlappingItems = [NSMutableArray new];
        CGRect itemFrame = itemAttributes.frame;
        [overlappingItems addObjectsFromArray:[sectionItemAttributes filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(UICollectionViewLayoutAttributes *layoutAttributes, NSDictionary *bindings) {
            if ((layoutAttributes != itemAttributes)) {
                return CGRectIntersectsRect(itemFrame, layoutAttributes.frame);
            } else {
                return NO;
            }
        }]]];
        
        // If there's items overlapping, we need to adjust them
        if (overlappingItems.count) {
            
            // Add the item we're adjusting to the overlap set
            [overlappingItems insertObject:itemAttributes atIndex:0];
            
            // Find the minY and maxY of the set
            CGFloat minY = CGFLOAT_MAX;
            CGFloat maxY = CGFLOAT_MIN;
            for (UICollectionViewLayoutAttributes *overlappingItemAttributes in overlappingItems) {
                if (CGRectGetMinY(overlappingItemAttributes.frame) < minY) {
                    minY = CGRectGetMinY(overlappingItemAttributes.frame);
                }
                if (CGRectGetMaxY(overlappingItemAttributes.frame) > maxY) {
                    maxY = CGRectGetMaxY(overlappingItemAttributes.frame);
                }
            }
            
            // Determine the number of divisions needed (maximum number of currently overlapping items)
            NSInteger divisions = 1;
            for (CGFloat currentY = minY; currentY <= maxY; currentY += 1.0) {
                NSInteger numberItemsForCurrentY = 0;
                for (UICollectionViewLayoutAttributes *overlappingItemAttributes in overlappingItems) {
                    if ((currentY >= CGRectGetMinY(overlappingItemAttributes.frame)) && (currentY < CGRectGetMaxY(overlappingItemAttributes.frame))) {
                        numberItemsForCurrentY++;
                    }
                }
                if (numberItemsForCurrentY > divisions) {
                    divisions = numberItemsForCurrentY;
                }
            }
            
            // Adjust the items to have a width of the section size divided by the number of divisions needed
            CGFloat divisionWidth = nearbyintf(self.sectionWidth / divisions);
            
            NSMutableArray *dividedAttributes = [NSMutableArray array];
            for (UICollectionViewLayoutAttributes *divisionAttributes in overlappingItems) {
                
                CGFloat itemWidth = (divisionWidth - self.cellMargin.left - self.cellMargin.right);
                
                // It it hasn't yet been adjusted, perform adjustment
                if (![adjustedAttributes containsObject:divisionAttributes]) {
                    
                    CGRect divisionAttributesFrame = divisionAttributes.frame;
                    divisionAttributesFrame.origin.x = (sectionMinX + self.cellMargin.left);
                    divisionAttributesFrame.size.width = itemWidth;
                    
                    // Horizontal Layout
                    NSInteger adjustments = 1;
                    for (UICollectionViewLayoutAttributes *dividedItemAttributes in dividedAttributes) {
                        if (CGRectIntersectsRect(dividedItemAttributes.frame, divisionAttributesFrame)) {
                            divisionAttributesFrame.origin.x = sectionMinX + ((divisionWidth * adjustments) + self.cellMargin.left);
                            adjustments++;
                        }
                    }
                    
                    // Stacking (lower items stack above higher items, since the title is at the top)
                    divisionAttributes.zIndex = sectionZ;
                    sectionZ ++;
                    
                    divisionAttributes.frame = divisionAttributesFrame;
                    [dividedAttributes addObject:divisionAttributes];
                    [adjustedAttributes addObject:divisionAttributes];
                }
            }
        }
    }
}

//подсчет content Size
- (CGSize)collectionViewContentSize
{
    CGFloat width;
    CGFloat height;
    height = [self maxSectionHeight];
    width = (self.timeRowHeaderWidth + self.contentMargin.left + ((self.sectionMargin.left + self.sectionWidth + self.sectionMargin.right) * self.collectionView.numberOfSections) + self.contentMargin.right);
    return CGSizeMake(width, height);
}


//аттрибуты item
- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return self.itemAttributes[indexPath];
}

//аттрибуты  Supplementary
- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if ([kind isEqualToString:BNCollectionElementKindCurrentTimeIndicator]) {
        return self.currentTimeIndicatorAttributes[indexPath];
    }else
    if ([kind isEqualToString:BNCollectionElementKindDayColumnHeader]) {
        return self.dayColumnHeaderAttributes[indexPath];
    }
    else if ([kind isEqualToString:BNCollectionElementKindTimeRowHeader]) {
        return self.timeRowHeaderAttributes[indexPath];
    }
    return nil;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForDecorationViewOfKind:(NSString *)decorationViewKind atIndexPath:(NSIndexPath *)indexPath
{
    if ([decorationViewKind isEqualToString:BNCollectionElementKindCurrentTimeHorizontalGridline]) {
        return self.currentTimeHorizontalGridlineAttributes[indexPath];
    }
    else if ([decorationViewKind isEqualToString:BNCollectionElementKindHorizontalHourGridline]) {
        return self.horizontalHourGridlineAttributes[indexPath];
    }
    else if ([decorationViewKind isEqualToString:BNCollectionElementKindHorizontalMinuteGridline]) {
        return self.horizontalMinuteGridlineAttributes[indexPath];
    }
    else if ([decorationViewKind isEqualToString:BNCollectionElementKindVerticalGridline]) {
        return self.verticalGridlineAttributes[indexPath];
    }
    else if ([decorationViewKind isEqualToString:BNCollectionElementKindTimeRowHeaderBackground]) {
        return self.timeRowHeaderBackgroundAttributes[indexPath];
    }
    else if ([decorationViewKind isEqualToString:BNCollectionElementKindDayColumnHeader]) {
        return self.dayColumnHeaderBackgroundAttributes[indexPath];
    }
    else if ([decorationViewKind isEqualToString:BNCollectionElementKindWorkTimeDecorationLayer]) {
        return self.backgroundLayerAttributes[indexPath];
    }
    else if ([decorationViewKind isEqualToString:BNCollectionElementKindLunchTimeDecorationLayer]) {
        return self.backgroundLayerAttributes[indexPath];
    }
    else if ([decorationViewKind isEqualToString:BNCollectionElementKindCurrentDayDecorationLayer]) {
        return self.backgroundLayerAttributes[indexPath];
    }
    return nil;
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSMutableIndexSet *visibleSections = [NSMutableIndexSet indexSet];
    [[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, self.collectionView.numberOfSections)] enumerateIndexesUsingBlock:^(NSUInteger section, BOOL *stop) {
        CGRect sectionRect = [self rectForSection:section];
        if (CGRectIntersectsRect(sectionRect, rect)) {
            [visibleSections addIndex:section];
        }
    }];
    // Update layout for only the visible sections
    [self prepareSectionLayoutForSections:visibleSections];
    NSMutableArray *visibleAttributes = [NSMutableArray new];
    //[visibleAttributes addObjectsFromArray:[self.dayColumnHeaderBackgroundAttributes allValues]];
    [visibleAttributes addObjectsFromArray:[self.timeRowHeaderAttributes allValues]];
    [visibleAttributes addObjectsFromArray:[self.timeRowHeaderBackgroundAttributes allValues]];
    [visibleAttributes addObjectsFromArray:[self.horizontalHourGridlineAttributes allValues]];
    [visibleAttributes addObjectsFromArray:[self.horizontalMinuteGridlineAttributes allValues]];
    [visibleAttributes addObjectsFromArray:[self.currentTimeHorizontalGridlineAttributes allValues]];
    [visibleAttributes addObjectsFromArray:[self.backgroundLayerAttributes allValues]];
    [visibleAttributes addObjectsFromArray:[self.currentTimeIndicatorAttributes allValues]];
    [visibleSections enumerateIndexesUsingBlock:^(NSUInteger section, BOOL *stop) {
        [visibleAttributes addObject:self.dayColumnHeaderAttributes[[NSIndexPath indexPathForItem:0 inSection:section]]];
        [visibleAttributes addObject:self.verticalGridlineAttributes[[NSIndexPath indexPathForItem:0 inSection:section]]];
        for (NSInteger item = 0; item < [self.collectionView numberOfItemsInSection:section]; item++) {
            NSIndexPath *itemIndexPath = [NSIndexPath indexPathForItem:item inSection:section];
            [visibleAttributes addObject:self.itemAttributes[itemIndexPath]];
        }
    }];
    return [visibleAttributes filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(UICollectionViewLayoutAttributes *layoutAttributes, NSDictionary *bindings) {
        return CGRectIntersectsRect(rect, layoutAttributes.frame);
    }]];
    
}

//чтобы заголовки дат оставали
- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    // Required for sticky headers
    return YES;
}

#pragma mark - BNCollectionViewCalendarLayout

- (void)initialize
{
    self.needsToPopulateAttributesForAllSections = YES;
    self.cachedMaxColumnHeight = CGFLOAT_MIN;
    self.cachedColumnHeights = [NSMutableDictionary new];
    
    self.registeredDecorationClasses = [NSMutableDictionary new];
    
    self.allAttributes = [NSMutableArray new];
    self.itemAttributes = [NSMutableDictionary new];
    self.dayColumnHeaderAttributes = [NSMutableDictionary new];
    self.dayColumnHeaderBackgroundAttributes = [NSMutableDictionary new];
    self.timeRowHeaderAttributes = [NSMutableDictionary new];
    self.timeRowHeaderBackgroundAttributes = [NSMutableDictionary new];
    self.horizontalHourGridlineAttributes = [NSMutableDictionary new];
    self.horizontalMinuteGridlineAttributes = [NSMutableDictionary new];
    self.verticalGridlineAttributes = [NSMutableDictionary new];
    self.currentTimeIndicatorAttributes = [NSMutableDictionary new];
    self.currentTimeHorizontalGridlineAttributes = [NSMutableDictionary new];
    self.backgroundLayerAttributes = [NSMutableDictionary new];

    self.hourHeight = 95.0;
    self.sectionWidth = 143.0;//2 секции
    //self.sectionWidth = 90.0;//3 секции
    self.dayColumnHeaderHeight = 30.0;
    self.timeRowHeaderWidth = 45.0;
    self.currentTimeIndicatorSize = CGSizeMake(40.0, 20.0);
    self.currentTimeHorizontalGridlineHeight = 2.0;//толщина линии текущего времени
    self.horizontalHourGridlineHeight = 1.0;// толщина линии грид лайн часа
    self.horizontalMinuteGridlineHeight = 1;// толщина линии грид лайн часа
    self.verticalDayGridlineHeight = 1.0;
    self.sectionMargin = UIEdgeInsetsMake(0.0, 0.0, 0.0, 1.0);
    self.cellMargin = UIEdgeInsetsMake(0.0, 1.0, 1.0, 0.0);//расстояние между ячейками
    self.contentMargin = ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? UIEdgeInsetsMake(30.0, 0.0, 30.0, 30.0) : UIEdgeInsetsMake(20.0, 0.0, 20.0, 10.0));

    
    self.displayHeaderBackgroundAtOrigin = YES;
    // Invalidate layout on minute ticks (to update the position of the current time indicator)
    NSDate *oneMinuteInFuture = [[NSDate date] dateByAddingTimeInterval:60];
    NSDateComponents *components = [[NSCalendar currentCalendar] components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:oneMinuteInFuture];
    NSDate *nextMinuteBoundary = [[NSCalendar currentCalendar] dateFromComponents:components];
    
    // This needs to be a weak reference, otherwise we get a retain cycle
    BNTimerWeakTarget *timerWeakTarget = [[BNTimerWeakTarget alloc] initWithTarget:self selector:@selector(minuteTick:)];
    self.minuteTimer = [[NSTimer alloc] initWithFireDate:nextMinuteBoundary interval:60 target:timerWeakTarget selector:timerWeakTarget.fireSelector userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.minuteTimer forMode:NSDefaultRunLoopMode];
}

#pragma mark Minute Updates

- (void)minuteTick:(id)sender
{
    [self.collectionView reloadData];
    // Invalidate cached current date componets (since the minute's changed!)
    [self invalidateLayout];
}

#pragma mark - Layout
//получение атрибутов по индексу и кэширование артибутов
- (UICollectionViewLayoutAttributes *)layoutAttributesForDecorationViewAtIndexPath:(NSIndexPath *)indexPath ofKind:(NSString *)kind withItemCache:(NSMutableDictionary *)itemCache
{
    UICollectionViewLayoutAttributes *layoutAttributes;
    if (self.registeredDecorationClasses[kind] && !(layoutAttributes = itemCache[indexPath])) {
        layoutAttributes = [UICollectionViewLayoutAttributes layoutAttributesForDecorationViewOfKind:kind withIndexPath:indexPath];
        itemCache[indexPath] = layoutAttributes;
    }
    return layoutAttributes;
}


- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewAtIndexPath:(NSIndexPath *)indexPath ofKind:(NSString *)kind withItemCache:(NSMutableDictionary *)itemCache
{
    UICollectionViewLayoutAttributes *layoutAttributes;
      if (!(layoutAttributes = itemCache[indexPath])) {
    layoutAttributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:kind withIndexPath:indexPath];
        itemCache[indexPath] = layoutAttributes;
      }
    return layoutAttributes;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForCellAtIndexPath:(NSIndexPath *)indexPath withItemCache:(NSMutableDictionary *)itemCache
{
    UICollectionViewLayoutAttributes *layoutAttributes;
    if (!(layoutAttributes = itemCache[indexPath])) {
        layoutAttributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
        itemCache[indexPath] = layoutAttributes;
    }
    return layoutAttributes;
}

- (void)invalidateLayoutCache
{
    self.needsToPopulateAttributesForAllSections = YES;
    
    // Invalidate cached Components
    // Invalidate cached interface sizing values
    self.cachedMaxColumnHeight = CGFLOAT_MIN;
    [self.cachedColumnHeights removeAllObjects];
    
    // Invalidate cached item attributes
    [self.itemAttributes removeAllObjects];
    [self.horizontalHourGridlineAttributes removeAllObjects];
    [self.horizontalMinuteGridlineAttributes removeAllObjects];
    [self.verticalGridlineAttributes removeAllObjects];
    [self.dayColumnHeaderAttributes removeAllObjects];
    [self.dayColumnHeaderBackgroundAttributes removeAllObjects];
    [self.timeRowHeaderAttributes removeAllObjects];
    [self.timeRowHeaderBackgroundAttributes removeAllObjects];
    [self.allAttributes removeAllObjects];
    [self.backgroundLayerAttributes removeAllObjects];
}

#pragma mark Dates

- (NSDate *)dateForTimeRowHeaderAtIndexPath:(NSIndexPath *)indexPath
{
    NSDateComponents *dateComponents = [self dayForSection:indexPath.section];
    dateComponents.hour = indexPath.item;
    return [[NSCalendar currentCalendar] dateFromComponents:dateComponents];
}

- (NSDate *)dateForDayColumnHeaderAtIndexPath:(NSIndexPath *)indexPath
{
    NSDate * date = [self.delegate collectionView:self.collectionView layout:self dayForSection:indexPath.section];
    return date;
   // NSCalendar *calendar = [NSCalendar currentCalendar];
   // NSDateComponents *components = [calendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:date];
   // return [calendar dateFromComponents:components];
}

#pragma mark Scrolling
/*
- (void)scrollCollectionViewToClosetSectionToCurrentTimeAnimated:(BOOL)animated
{
    
    if (self.collectionView.numberOfSections != 0) {
        NSInteger closestSectionToCurrentTime = [self closestSectionToCurrentTime];
        CGPoint contentOffset;
        CGRect currentTimeHorizontalGridlineattributesFrame = [self.currentTimeHorizontalGridlineAttributes[[NSIndexPath indexPathForItem:0 inSection:0]] frame];
        CGFloat yOffset;
            if (!CGRectEqualToRect(currentTimeHorizontalGridlineattributesFrame, CGRectZero)) {
                yOffset = nearbyintf(CGRectGetMinY(currentTimeHorizontalGridlineattributesFrame) - (CGRectGetHeight(self.collectionView.frame) / 2.0));
            } else {
                yOffset = 0.0;
            }
            CGFloat xOffset = self.contentMargin.left + ((self.sectionMargin.left + self.sectionWidth + self.sectionMargin.right) * closestSectionToCurrentTime);
            contentOffset = CGPointMake(xOffset, yOffset);
        
        // Prevent the content offset from forcing the scroll view content off its bounds
        if (contentOffset.y > (self.collectionView.contentSize.height - self.collectionView.frame.size.height)) {
            contentOffset.y = (self.collectionView.contentSize.height - self.collectionView.frame.size.height);
        }
        if (contentOffset.y < 0.0) {
            contentOffset.y = 0.0;
        }
        if (contentOffset.x > (self.collectionView.contentSize.width - self.collectionView.frame.size.width)) {
            contentOffset.x = (self.collectionView.contentSize.width - self.collectionView.frame.size.width);
        }
        if (contentOffset.x < 0.0) {
            contentOffset.x = 0.0;
        }
        [self.collectionView setContentOffset:contentOffset animated:animated];
    }
     
}
 */

- (NSInteger)closestSectionToCurrentTime
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *currentDate = [self.delegate currentTimeComponentsForCollectionView:self.collectionView layout:self];
    NSDateComponents *components = [calendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:currentDate];
    currentDate = [calendar dateFromComponents:components];
    NSTimeInterval minTimeInterval = CGFLOAT_MAX;
    NSInteger closestSection = NSIntegerMax;
    for (NSInteger section = 0; section < self.collectionView.numberOfSections; section++) {
        NSDate *sectionDayDate = [self.delegate collectionView:self.collectionView layout:self dayForSection:section];
        NSTimeInterval timeInterval = [currentDate timeIntervalSinceDate:sectionDayDate];
        if ((timeInterval <= 0) && abs(timeInterval) < minTimeInterval) {
            minTimeInterval = abs(timeInterval);
            closestSection = section;
        }
    }
    return ((closestSection != NSIntegerMax) ? closestSection : 0);
}

#pragma mark Section Sizing

- (CGRect)rectForSection:(NSInteger)section
{
    CGRect sectionRect;
    CGFloat calendarGridMinX = (self.timeRowHeaderWidth + self.contentMargin.left);
    CGFloat sectionWidth = (self.sectionMargin.left + self.sectionWidth + self.sectionMargin.right);
    CGFloat sectionMinX = (calendarGridMinX + self.sectionMargin.left + (sectionWidth * section));
    sectionRect = CGRectMake(sectionMinX, 0.0, sectionWidth, self.collectionViewContentSize.height);
    return sectionRect;
}

- (CGFloat)maxSectionHeight
{

    CGFloat maxSectionHeight = (self.hourHeight * 24);
    //CGFloat headerAdjustedMaxColumnHeight = (maxSectionHeight + (self.dayColumnHeaderHeight + self.contentMargin.top + self.contentMargin.bottom));
    CGFloat headerAdjustedMaxColumnHeight = (maxSectionHeight + (self.dayColumnHeaderHeight + self.contentMargin.top + self.contentMargin.bottom));
        return headerAdjustedMaxColumnHeight;

}

- (CGFloat)stackedSectionHeight
{
    return [self stackedSectionHeightUpToSection:self.collectionView.numberOfSections];
}
- (CGFloat)stackedSectionHeightUpToSection:(NSInteger)upToSection
{
    if (self.cachedColumnHeights[@(upToSection)]) {
        return [self.cachedColumnHeights[@(upToSection)] integerValue];
    }
    CGFloat stackedSectionHeight = 0.0;
    for (NSInteger section = 0; section < upToSection; section++) {
        CGFloat sectionColumnHeight = [self sectionHeight:section];
        stackedSectionHeight += sectionColumnHeight;
    }
    CGFloat headerAdjustedStackedColumnHeight = (stackedSectionHeight + ((self.dayColumnHeaderHeight + self.contentMargin.top + self.contentMargin.bottom) * upToSection));
    if (stackedSectionHeight != 0.0) {
        self.cachedColumnHeights[@(upToSection)] = @(headerAdjustedStackedColumnHeight);
        return headerAdjustedStackedColumnHeight;
    } else {
        return headerAdjustedStackedColumnHeight;
    }
}

- (CGFloat)sectionHeight:(NSInteger)section
{
        return (self.hourHeight * 24);

}

- (CGFloat)minuteHeight
{
    return (self.hourHeight / 60.0);
}

#pragma mark Z Index

- (CGFloat)zIndexForElementKind:(NSString *)elementKind
{
    return [self zIndexForElementKind:elementKind floating:NO];
}

//
- (CGFloat)zIndexForElementKind:(NSString *)elementKind floating:(BOOL)floating
{
            // Current Time Indicator
            if ([elementKind isEqualToString:BNCollectionElementKindCurrentTimeIndicator]) {
                return (BNCollectionMinOverlayZ + (floating ? 12.0 : 2.0));
            }
            // Time Row Header
            else if ([elementKind isEqualToString:BNCollectionElementKindTimeRowHeader]) {
                return (BNCollectionMinOverlayZ + (floating ? 11.0 : 1.0));
            }
            // Time Row Header Background
            else if ([elementKind isEqualToString:BNCollectionElementKindTimeRowHeaderBackground]) {
                return (BNCollectionMinOverlayZ +(floating ? 10.0 : 0.0));
            }
            // Day Column Header
            else if ([elementKind isEqualToString:BNCollectionElementKindDayColumnHeader]) {
                return (BNCollectionMinOverlayZ + (floating ? 9.0 : 4.0) );
            }
            // Day Column Header Background
            else if ([elementKind isEqualToString:BNCollectionElementKindDayColumnHeaderBackground]) {
                return (BNCollectionMinOverlayZ + (floating ? 8.0 : 3.0));
            }
            // Cell
            else if (elementKind == nil) {
                return BNCollectionMinCellZ;
            }
            // Current Time Horizontal Gridline
            else if ([elementKind isEqualToString:BNCollectionElementKindCurrentTimeHorizontalGridline]) {
                return (BNCollectionMinCellZ + 1.0);
            }
            // Horizontal Gridline
            else if ([elementKind isEqualToString:BNCollectionElementKindHorizontalHourGridline]) {
                return BNCollectionMinBackgroundZ;
            }
            else if ([elementKind isEqualToString:BNCollectionElementKindWorkTimeDecorationLayer]) {
                return (BNCollectionMinBackgroundZ);
            }
            else if ([elementKind isEqualToString:BNCollectionElementKindLunchTimeDecorationLayer]) {
                return (BNCollectionMinBackgroundZ);
            }
    return CGFLOAT_MIN;
}

#pragma mark Delegate Wrappers

- (NSDateComponents *)dayForSection:(NSInteger)section
{
    NSDate *date = [self.delegate collectionView:self.collectionView layout:self dayForSection:section];
    //date = [date beginningOfDay];
    NSDateComponents *dayDateComponents = [[NSCalendar currentCalendar] components:(NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit | NSEraCalendarUnit) fromDate:date];
    return dayDateComponents;
}

- (NSDateComponents *)startTimeForIndexPath:(NSIndexPath *)indexPath
{
    NSDate *date = [self.delegate collectionView:self.collectionView layout:self startTimeForItemAtIndexPath:indexPath];
    NSDateComponents *itemStartTimeDateComponents = [[NSCalendar currentCalendar] components:(NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:date];
    return itemStartTimeDateComponents;
}


- (NSDateComponents *)endTimeForIndexPath:(NSIndexPath *)indexPath
{
    NSDate *date = [self.delegate collectionView:self.collectionView layout:self endTimeForItemAtIndexPath:indexPath];
    NSDateComponents *itemEndTime = [[NSCalendar currentCalendar] components:(NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:date];
    return itemEndTime;
}

- (NSDateComponents *)currentTimeDateComponents
{
    NSDate *date = [self.delegate currentTimeComponentsForCollectionView:self.collectionView layout:self];
    NSDateComponents *currentTime = [[NSCalendar currentCalendar] components:(NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:date];
    return currentTime;
}

- (NSInteger)currentSection
{
    return [self.delegate currentSection];
}


- (NSDate *) timeDateComponentsFloatX: (CGFloat)itemX FloatY: (CGFloat) itemY
{
    CGFloat sectionWidth = (self.sectionMargin.left + self.sectionWidth + self.sectionMargin.right);
    CGFloat calendarGridMinX = (self.timeRowHeaderWidth + self.contentMargin.left);
    CGFloat calendarGridMinY = (self.dayColumnHeaderHeight + self.contentMargin.top);
  //  CGFloat calendarGridWidth = (self.collectionViewContentSize.width - self.timeRowHeaderWidth - self.contentMargin.right);
    CGFloat time = (itemY - calendarGridMinY - (CGFloat)self.cellMargin.top);
    float fmin = (time/self.minuteHeight);
    int min = (int) fmin;
    int hour = (int)min/60;
    min = min%60;
    CGFloat sectionMinX = (itemX - self.cellMargin.left);
    int section = (int)((sectionMinX - calendarGridMinX - self.sectionMargin.left+sectionWidth/2)/sectionWidth);
    NSDate *celldate = [self.delegate collectionView:self.collectionView layout:self dayForSection:section];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit| NSMinuteCalendarUnit fromDate:celldate];
    [components setHour:hour];
    [components setMinute:min];
    return [calendar dateFromComponents:components];
}

-(NSInteger)sectionToFloatX: (CGFloat)itemX
{
    CGFloat sectionWidth = (self.sectionMargin.left + self.sectionWidth + self.sectionMargin.right);
    CGFloat calendarGridMinX = (self.timeRowHeaderWidth + self.contentMargin.left);
    //  CGFloat calendarGridWidth = (self.collectionViewContentSize.width - self.timeRowHeaderWidth - self.contentMargin.right);
    CGFloat sectionMinX = (itemX - self.cellMargin.left);
    return (int)((sectionMinX - calendarGridMinX - self.sectionMargin.left+sectionWidth/2)/sectionWidth);
}
- (NSInteger) toLengthStartFloatY: (CGFloat)startF EndFloatY: (CGFloat) endF
{
    CGFloat calendarGridMinY = (self.dayColumnHeaderHeight + self.contentMargin.top);
    //  CGFloat calendarGridWidth = (self.collectionViewContentSize.width - self.timeRowHeaderWidth - self.contentMargin.right);
    CGFloat timeStart = (startF - calendarGridMinY - (CGFloat)self.cellMargin.top);
    float fmin = (timeStart/self.minuteHeight);
    int startMinutes = (int) fmin;
    CGFloat timeEnd = (endF - calendarGridMinY - (CGFloat)self.cellMargin.top);
    fmin = nearbyintf(timeEnd/self.minuteHeight);
    int EndMinutes = (int) fmin;
    return EndMinutes-startMinutes;
}

@end
