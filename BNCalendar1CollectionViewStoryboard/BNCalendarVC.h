//
//  BNCalendarVC.h
//  BNCalendar1CollectionViewStoryboard
//
//  Created by Alexandr on 01.08.13.
//  Copyright (c) 2013 Alexander Spiridonov. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BNCollectionViewCalendarLayout.h"
#import "BNCalendarDraggingView.h"

@interface BNCalendarVC : UIViewController<UICollectionViewDataSource, BNCollectionViewDelegateCalendarLayout,BNCollectionViewDelegateGestureRecognizer>

@end
