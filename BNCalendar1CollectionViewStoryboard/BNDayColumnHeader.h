//
//  BNDayColumnHeader.h
//  BNCalendar1CollectionViewStoryboard
//
//  Created by Alexandr on 01.08.13.
//  Copyright (c) 2013 Alexander Spiridonov. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BNDayColumnHeader : UICollectionReusableView

@property (nonatomic, strong) UILabel *dateTitle;
@property (nonatomic, strong) UILabel *weekTitle;
@property (nonatomic, strong) UIButton *button;
@property (nonatomic, strong) NSDate *day;
@property (nonatomic, strong) NSMutableArray *workload;

@end
