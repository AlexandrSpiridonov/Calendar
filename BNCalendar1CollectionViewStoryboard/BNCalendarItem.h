//
//  BNCalendarItem.h
//  BNCalendar1CollectionViewStoryboard
//
//  Created by Alexandr on 01.08.13.
//  Copyright (c) 2013 Alexander Spiridonov. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BNCalendarItem : NSObject
@property (nonatomic, strong) NSDate *start;
@property (nonatomic, strong) NSDate *end;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *location;
@property (nonatomic, strong) UICollectionViewLayoutAttributes *itemAttribute;
@property (strong) NSNumber *Type;

- (NSDate *)day;

@end
