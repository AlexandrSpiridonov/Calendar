//
//  BNCalendarDraggingView.m
//  BNCalendar1CollectionViewStoryboard
//
//  Created by Alexandr on 08.08.13.
//  Copyright (c) 2013 Alexander Spiridonov. All rights reserved.
//

#import "BNCalendarDraggingView.h"
#import "BNCalendarItem.h"
#import <QuartzCore/QuartzCore.h>

@implementation BNCalendarDraggingView

#pragma mark - UIView
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.view = [[UIView alloc] initWithFrame:frame];
        //self.view.backgroundColor = [UIColor redColor];
        self.view.backgroundColor = [UIColor clearColor];
        [self addSubview:self.view];
        
        self.margin = UIEdgeInsetsMake(4.0, 5.0, 4.0, 5.0);
        self.bgrImage = [UIImageView new];
        self.bgrImage.contentMode = UIViewContentModeRedraw;
        [self.view addSubview:self.bgrImage];
        //self.backgroundColor = [UIColor redColor];
        
        self.time = [UILabel new];
        self.time.backgroundColor = [UIColor clearColor];
        self.time.numberOfLines = 1;
        self.time.font = [UIFont fontWithName:@"Trebuchet MS" size: 8];
        self.time.textColor = [UIColor colorWithRed:1 green:0.2 blue:0.3 alpha:1];
        [self addSubview:self.time];
        
        
        self.message = [UILabel new];
        self.message.backgroundColor = [UIColor clearColor];
        self.message.numberOfLines = 1;
        self.message.font = [UIFont fontWithName:@"Trebuchet MS" size: 8];
        self.message.textColor = [UIColor grayColor];
        [self addSubview:self.message];
        
        self.toLength = [UILabel new];
        self.toLength.backgroundColor = [UIColor clearColor];
        self.toLength.numberOfLines = 1;
        self.toLength.font = [UIFont fontWithName:@"Trebuchet MS" size: 12];
        self.toLength.textColor = [UIColor colorWithRed:1 green:0.2 blue:0.3 alpha:1];
        [self addSubview:self.toLength];
        
        self.noteType = [NSNumber numberWithInt:0];
        
        self.btnTopResize = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.btnTopResize setImage:[UIImage imageNamed:@"cni_drug_up"] forState:UIControlStateNormal];
        [self addSubview:self.btnTopResize];
        [self.btnTopResize sizeToFit];

        UIPanGestureRecognizer * panToResizeTop = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panToResizeTop:)];
        [self.btnTopResize addGestureRecognizer:panToResizeTop];
        
        self.btnBottomResize = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.btnBottomResize setImage:[UIImage imageNamed:@"cni_drug_dn"] forState:UIControlStateNormal];
        [self addSubview:self.btnBottomResize];
        [self.btnBottomResize sizeToFit];
        UIPanGestureRecognizer * panToResizeBottom = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panToResizeBottom:)];
        [self.btnBottomResize addGestureRecognizer:panToResizeBottom];
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect mainFrame = self.frame;
    mainFrame.size.height = mainFrame.size.height - self.btnTopResize.frame.size.height- self.btnBottomResize.frame.size.height;
    mainFrame.origin.y = self.btnTopResize.frame.size.height;
    mainFrame.origin.x = 0;
    self.view.frame = mainFrame;
    
    [self.time sizeToFit];
    CGRect timeFrame = self.time.frame;
    timeFrame.origin.x = nearbyintf((CGRectGetWidth(mainFrame) / 2.0)-(CGRectGetWidth(timeFrame) / 2.0));
    timeFrame.origin.y = 0;
    self.time.frame = timeFrame;
    
    
    [self.message sizeToFit];
    CGRect titleFrame = self.message.frame;
    titleFrame.origin.x = self.margin.left;
    titleFrame.origin.y = mainFrame.origin.y + nearbyintf((CGRectGetHeight(mainFrame) / 2.0) - (CGRectGetHeight(titleFrame) / 2.0));
    titleFrame.size.width = CGRectGetWidth(mainFrame)-self.margin.left-self.margin.right;
    self.message.frame = titleFrame;
    
    [self.toLength sizeToFit];
    CGRect toLengthFrame = self.toLength.frame;
    toLengthFrame.origin.x =  nearbyintf((CGRectGetWidth(mainFrame) / 2.0)-(CGRectGetWidth(toLengthFrame) / 2.0));
    toLengthFrame.origin.y = mainFrame.origin.y + nearbyintf((CGRectGetHeight(mainFrame) / 2.0) - (CGRectGetHeight(toLengthFrame) / 2.0));
    toLengthFrame.size.width = CGRectGetWidth(mainFrame)-self.margin.left-self.margin.right;
    self.toLength.frame = toLengthFrame;

    //фон view
    NSString * imgName = [NSString stringWithFormat:@"cni-note-%@-", self.noteType];
    self.imagesArr = [NSArray arrayWithObjects:
                      [UIImage imageNamed:[imgName stringByAppendingString:@"top"]],
                      [UIImage imageNamed:[imgName stringByAppendingString:@"mid"]],
                      [UIImage imageNamed:[imgName stringByAppendingString:@"bot"]],
                      nil];
    UIImage * top = [self.imagesArr objectAtIndex:0];
    UIImage * mid = [self.imagesArr objectAtIndex:1];
    UIImage * bot = [self.imagesArr objectAtIndex:2];
    CGFloat midHigth = mainFrame.size.height-top.size.height-bot.size.height;
    
    CGSize newSize = CGSizeMake(self.view.bounds.size.width, top.size.height+midHigth+bot.size.height);
    UIGraphicsBeginImageContext(newSize );
    [top drawInRect:CGRectMake(0, 0, self.view.bounds.size.width, top.size.height )];
    [mid drawAsPatternInRect:CGRectMake(0, top.size.height ,self.view.bounds.size.width, midHigth)];
    [bot drawInRect:CGRectMake(0, top.size.height + midHigth, self.view.bounds.size.width, bot.size.height )];
    
    //оконтовка
    CGRect noteViewFrame = self.view.bounds;
    noteViewFrame.size.width  -=4;
    noteViewFrame.size.height -=4;
    noteViewFrame.origin.x = 2;
    noteViewFrame.origin.y = 2;
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextBeginPath(context);
    CGContextSetLineWidth(context,3.0);
    CGContextSetStrokeColorWithColor(context, [[UIColor colorWithRed:0.7 green:0 blue:0 alpha:1] CGColor]);
    CGContextSetShadow(context, CGSizeMake(2.0, 2.0), 5.0);
    CGContextAddRect(context,noteViewFrame);
    CGContextClosePath(context);
    CGContextDrawPath(context, kCGPathStroke);
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    [self.bgrImage setImage:newImage];
    CGRect imgFrame = mainFrame;
    imgFrame.origin.x = 0;
    imgFrame.origin.y = 0;
    self.bgrImage.frame = imgFrame;
    //NSLog(@"bgr frame %@", NSStringFromCGRect(self.bgrImage.frame));
    
    //жесты
    UIPanGestureRecognizer * panToDragging = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panToDragging:)];
    [self.view addGestureRecognizer:panToDragging];
    
    [self.btnTopResize sizeToFit];
    CGRect btnTopFrame = self.btnTopResize.frame;
    btnTopFrame.origin.x = self.margin.left;
    btnTopFrame.origin.y = mainFrame.origin.y-btnTopFrame.size.height+self.margin.top;
    self.btnTopResize.frame = btnTopFrame;
    
    [self.btnBottomResize sizeToFit];
    CGRect btnBottomFrame = self.btnBottomResize.frame;
    btnBottomFrame.origin.x = mainFrame.size.width - btnBottomFrame.size.width-self.margin.right;
    btnBottomFrame.origin.y = mainFrame.origin.y + mainFrame.size.height-self.margin.bottom;
    self.btnBottomResize.frame = btnBottomFrame;
}
- (void)panToDragging:(UIPanGestureRecognizer *)gesture
{
    [self.delegate panToDragging:gesture];
}
- (void)panToResizeTop:(UIPanGestureRecognizer *)gesture
{
    [self.delegate panToResizeTop:gesture];
}
- (void)panToResizeBottom:(UIPanGestureRecognizer *)gesture
{
    [self.delegate panToResizeBottom:gesture];
}

@end
