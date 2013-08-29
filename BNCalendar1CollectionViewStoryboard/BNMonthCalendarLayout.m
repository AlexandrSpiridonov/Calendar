//
//  BNMonthCalendarLayout.m
//  BNMonthCalendar2CollectionViewCustomLayout
//
//  Created by Alexandr on 12.08.13.
//  Copyright (c) 2013 Alexander Spiridonov. All rights reserved.
//

#import "BNMonthCalendarLayout.h"
#import <QuartzCore/QuartzCore.h>

NSString *const BNCollectionElementKindMonthHeader = @"BNCollectionElementKindMonthHeader";
NSString *const BNCollectionElementKindWeekHeader = @"BNCollectionElementKindWeekHeader";

#define ITEM_SIZE 40

@interface BNMonthCalendarLayout()

@property (nonatomic, assign) CGSize pageSize;
@property (nonatomic, assign) CGSize contentSize;
@property (nonatomic, strong) NSArray *cellCounts;
@property (nonatomic, strong) NSArray *pageRects;
@property (nonatomic, assign) NSInteger pageCount;
@property (nonatomic, strong) NSMutableArray *deleteIndexPaths;
@property (nonatomic, strong) NSMutableArray *insertIndexPaths;
@property (nonatomic, assign) CGFloat dayWidth;
@property (nonatomic, assign) CGFloat dayHeight;
@property (nonatomic, assign) CGFloat monthHeaderHeight;
@property (nonatomic, assign) UIEdgeInsets cellMargin;
- (void)initialize;

@end

@implementation BNMonthCalendarLayout

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

- (void)initialize
{
    self.cellMargin = UIEdgeInsetsMake(0.0, 2.0, 3.0, 0.0);//расстояние между ячейками
    self.monthHeaderHeight = ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? 60.0 : 40.0);
}
-(void)prepareLayout
{
    [super prepareLayout];
    self.pageSize = self.collectionView.bounds.size;
    self.pageCount = [self.collectionView numberOfSections];
    self.dayWidth = (self.pageSize.width)/7- self.cellMargin.left;
    self.dayHeight = (self.pageSize.height)/7- self.cellMargin.bottom;
    self.dayHeight = MIN(self.dayHeight, self.dayWidth);
    //self.dayWidth = MIN(self.dayHeight, self.dayWidth);
    
    NSMutableArray *counts = [NSMutableArray arrayWithCapacity:self.pageCount];
    NSMutableArray *rects = [NSMutableArray arrayWithCapacity:self.pageCount];
    for (int section = 0; section < self.pageCount; section++)
    {
        [counts addObject:@([self.collectionView numberOfItemsInSection:section])];
        [rects addObject:[NSValue valueWithCGRect:(CGRect){{section * self.pageSize.width, 0}, self.pageSize}]];
    }
    self.cellCounts = [NSArray arrayWithArray:counts];
    self.pageRects = [NSArray arrayWithArray:rects];

    
    self.contentSize = CGSizeMake(self.pageSize.width * self.pageCount, self.pageSize.height);
}


-(CGSize)collectionViewContentSize
{
    return self.contentSize;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    return !CGSizeEqualToSize(self.pageSize, newBounds.size);
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)path
{
    UICollectionViewLayoutAttributes* attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:path];
    attributes.size = CGSizeMake(self.dayWidth, self.dayHeight);
    CGRect pageRect = [self.pageRects[path.section] CGRectValue];
    int row = (path.item)/7;
    int col = (path.item)%7;
    attributes.center = CGPointMake(pageRect.origin.x + self.dayWidth/2 + col*(self.dayWidth+self.cellMargin.left), pageRect.origin.y + self.monthHeaderHeight+ 0.5*self.dayHeight + row*(self.dayHeight+2));
    
    return attributes;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:kind withIndexPath:indexPath];
    CGRect pageRect = [self.pageRects[indexPath.section] CGRectValue];
    attributes.size = CGSizeMake(pageRect.size.width, self.monthHeaderHeight);
    attributes.center = CGPointMake(CGRectGetMidX(pageRect), self.monthHeaderHeight/2);
    return attributes;
}

- (int)cellCountForSection:(NSInteger)section
{
    NSNumber *count = self.cellCounts[section];
    return [count intValue];
}

-(NSArray*)layoutAttributesForElementsInRect:(CGRect)rect
{
    int page = 0;
    NSMutableArray* attributes = [NSMutableArray array];
    for (NSValue *pageRect in self.pageRects)
    {
        if (CGRectIntersectsRect(rect, pageRect.CGRectValue))
        {
            int cellCount = [self cellCountForSection:page];
            for (int i = 0; i < cellCount; i++) {
                NSIndexPath* indexPath = [NSIndexPath indexPathForItem:i inSection:page];
                [attributes addObject:[self layoutAttributesForItemAtIndexPath:indexPath]];
            }
            
            // add header
            [attributes addObject:[self layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader atIndexPath:[NSIndexPath indexPathForItem:0 inSection:page]]];
        }
        
        page++;
    }
    
    return attributes;
}

/*
// Not necessary because I just decided to go with UIScrollView.pagingEnabled = YES instead
- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset withScrollingVelocity:(CGPoint)velocity
 {
 int closestPage = roundf(proposedContentOffset.x / self.pageSize.width);
 if (closestPage < 0)
 closestPage = 0;
 if (closestPage >= self.pageCount)
 closestPage = self.pageCount - 1;
 return CGPointMake(closestPage * self.pageSize.width, proposedContentOffset.y);
 }
*/
- (UICollectionViewLayoutAttributes *)initialLayoutAttributesForAppearingItemAtIndexPath:(NSIndexPath *)itemIndexPath
{
    UICollectionViewLayoutAttributes *attributes = [super initialLayoutAttributesForAppearingItemAtIndexPath:itemIndexPath];
    
    if ([self.insertIndexPaths containsObject:itemIndexPath])
    {
        if (!attributes)
            attributes = [self layoutAttributesForItemAtIndexPath:itemIndexPath];
        
        // Configure attributes ...
        attributes.alpha = 0.0;
        CGRect pageRect = [self.pageRects[itemIndexPath.section] CGRectValue];
        attributes.center = CGPointMake(CGRectGetMidX(pageRect), CGRectGetMidY(pageRect));
    }
    
    return attributes;
}

- (UICollectionViewLayoutAttributes *)finalLayoutAttributesForDisappearingItemAtIndexPath:(NSIndexPath *)itemIndexPath
{
    UICollectionViewLayoutAttributes *attributes = [super finalLayoutAttributesForDisappearingItemAtIndexPath:itemIndexPath];
    
    if ([self.deleteIndexPaths containsObject:itemIndexPath])
    {
        if (!attributes)
            attributes = [self layoutAttributesForItemAtIndexPath:itemIndexPath];
        
        // Configure attributes ...
        attributes.alpha = 0.0;
        attributes.center = CGPointMake(attributes.center.x, 0 - ITEM_SIZE);
    }
    
    return attributes;
}


@end