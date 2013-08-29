//
//  BNCalendarDraggingView.h
//  BNCalendar1CollectionViewStoryboard
//
//  Created by Alexandr on 08.08.13.
//  Copyright (c) 2013 Alexander Spiridonov. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol BNCollectionViewDelegateGestureRecognizer;
@interface BNCalendarDraggingView : UIView

@property (nonatomic, weak) id <BNCollectionViewDelegateGestureRecognizer> delegate;
@property (nonatomic, strong) UILabel *time;
@property (nonatomic, strong) UIImageView *bgrImage;
@property (nonatomic, strong) UIView *view;
@property (nonatomic, strong) UILabel *toLength;
@property (nonatomic, strong) UILabel *message;
@property (nonatomic, strong) UIButton *btnTopResize;
@property (nonatomic, strong) UIButton *btnBottomResize;
@property (strong,nonatomic) NSArray  * imagesArr;
@property (strong) NSNumber * noteType; //{0 - заметка, 2 - в прошлом, 1 - в настоящем}
@property (assign) UIEdgeInsets margin;

@end

@protocol BNCollectionViewDelegateGestureRecognizer <UIGestureRecognizerDelegate>
@required

- (void)panToResizeTop:(UIPanGestureRecognizer *)gesture;
- (void)panToResizeBottom:(UIPanGestureRecognizer *)gesture;
- (void)panToDragging:(UIPanGestureRecognizer *)gesture;
@end