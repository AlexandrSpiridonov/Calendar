//
//  BNTimeRowHeader.h
//  BNCalendar1CollectionViewStoryboard
//
//  Created by Alexandr on 01.08.13.
//  Copyright (c) 2013 Alexander Spiridonov. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BNTimeRowHeader : UICollectionReusableView

@property (nonatomic, strong) NSDate *time;
@property (nonatomic, strong) UILabel *title;
@property (nonatomic, strong) UILabel *title15;
@property (nonatomic, strong) UILabel *title30;
@property (nonatomic, strong) UILabel *title45;

@end
