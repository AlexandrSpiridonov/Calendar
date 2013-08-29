//
//  BNCalendarCell.m
//  BNCalendar1CollectionViewStoryboard
//
//  Created by Alexandr on 01.08.13.
//  Copyright (c) 2013 Alexander Spiridonov. All rights reserved.
//

#import "BNCalendarCell.h"
#import "BNCalendarItem.h"
#import <QuartzCore/QuartzCore.h>

@interface BNCalendarCell ()

@end

@implementation BNCalendarCell

#pragma mark - UIView
/*
- (id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        [self setFrameColor:[UIColor grayColor]];
        [self setFrameWidth:1.0];
        //[self setCniTopOffset:[NSNumber numberWithFloat:20.0]];
        
        [self setBackgroundColor:[UIColor clearColor]];
        self.contentMode = UIViewContentModeRedraw;
      
        self.message  = [[UILabel alloc] initWithFrame:CGRectMake(7, 20, 131, 115)];
        [self.message  setBackgroundColor:[UIColor clearColor]];
        
  //      [self.message setTextAlignment:UITextAlignmentLeft];
        [self.message setTextColor:[UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:1]];
        //NSDictionary * customFont = [[NSUserDefaults standardUserDefaults] getValueFrom:@"currNotesFont"];
        //[self.lblMessage setFont:[UIFont fontWithName:[customFont objectForKey:@"name"] size:[[NSUserDefaults standardUserDefaults] boolForKey:@"isLargeCalFont"]?15:11]];
        
        [self.message setShadowColor:[UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.5]];
        [self.message setShadowOffset:CGSizeMake(0, 1)];
        [self.message setAdjustsFontSizeToFitWidth:YES];
   //     [self.message setMinimumFontSize:9.0];
        [self.message setContentMode:UIViewContentModeCenter];
  //      [self.message setLineBreakMode:UILineBreakModeCharacterWrap];
        [self.message setNumberOfLines:0];
        [self.message setClipsToBounds:YES];
        [self.message setHidden:YES];
        //[self addSubview:self.message];
        
    }
}
  */

#pragma mark - UICollectionViewCell


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.message = [UILabel new];
        self.message.backgroundColor = [UIColor clearColor];
        self.message.numberOfLines = 1;
        self.message.font = [UIFont fontWithName:@"Trebuchet MS" size:8.0];
        self.message.textColor = [UIColor grayColor];
        [self addSubview:self.message];
        //self.noteType = [NSNumber numberWithInt:0];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    UIEdgeInsets margin = UIEdgeInsetsMake(4.0, 5.0, 4.0, 5.0);
    [self.message sizeToFit];
    CGRect titleFrame = self.message.frame;
    titleFrame.origin.x = margin.left;
    titleFrame.origin.y = nearbyintf((CGRectGetHeight(self.frame) / 2.0) - (CGRectGetHeight(titleFrame) / 2.0));
    titleFrame.size.width = CGRectGetWidth(self.frame)-margin.left-margin.right;
    self.message.frame = titleFrame;

    NSString * imgName = [NSString stringWithFormat:@"cni-note-%@-", self.noteType];
    self.imagesArr = [NSArray arrayWithObjects:
                      [UIImage imageNamed:[imgName stringByAppendingString:@"top"]],
                      [UIImage imageNamed:[imgName stringByAppendingString:@"mid"]],
                      [UIImage imageNamed:[imgName stringByAppendingString:@"bot"]],
                      nil];
    UIImage * top = [self.imagesArr objectAtIndex:0];
    UIImage * mid = [self.imagesArr objectAtIndex:1];
    UIImage * bot = [self.imagesArr objectAtIndex:2];
    CGFloat midHigth = self.bounds.size.height-top.size.height-bot.size.height;
    
    CGSize newSize = CGSizeMake(self.bounds.size.width, top.size.height+midHigth+bot.size.height);
    UIGraphicsBeginImageContext(newSize );
    [top drawInRect:CGRectMake(0, 0, self.bounds.size.width, top.size.height )];
    [mid drawAsPatternInRect:CGRectMake(0, top.size.height ,self.bounds.size.width, midHigth)];
    [bot drawInRect:CGRectMake(0, top.size.height + midHigth, self.bounds.size.width, bot.size.height )];
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    self.backgroundView  = [[UIImageView alloc] initWithImage:newImage];
    self.backgroundView.contentMode = UIViewContentModeRedraw;
}



/*
- (void)setSelected:(BOOL)selected
{
    //if (selected && self.selected != selected) {
        [UIView animateWithDuration:0.1 animations:^{
            self.transform = CGAffineTransformMakeScale(1.05, 1.05);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.1 animations:^{
                self.transform = CGAffineTransformIdentity;
            }];
        }];
    //}
    [super setSelected:selected];
    //self.hidden = YES;
    self.center = CGPointMake(self.center.x+50, self.center.y);
  //  mockCell.center = CGPointMake(location.x, location.y);
   // [self updateColors];
}
*/

/*
- (void)updateColors
{
    self.contentView.backgroundColor = [self cellBackgroundColorSelected:self.selected];
    self.contentView.layer.borderColor = [[self cellBorderColorSelected:self.selected] CGColor];
    
    self.time.textColor = [self cellTextColorSelected:self.selected];
    self.time.shadowColor = [self cellTextShadowColorSelected:self.selected];
    self.time.shadowOffset = [self cellTextShadowOffsetSelected:self.selected];
    
    self.title.textColor = [self cellTextColorSelected:self.selected];
    self.title.shadowColor = [self cellTextShadowColorSelected:self.selected];
    self.title.shadowOffset = [self cellTextShadowOffsetSelected:self.selected];
    
    self.location.textColor = [self cellTextColorSelected:self.selected];
    self.location.shadowColor = [self cellTextShadowColorSelected:self.selected];
    self.location.shadowOffset = [self cellTextShadowOffsetSelected:self.selected];
}

- (UIColor *)cellBackgroundColorSelected:(BOOL)selected
{
    return selected ? [[UIColor colorWithHexString:@"165b9b"] colorWithAlphaComponent:0.8] : [[UIColor colorWithHexString:@"b4d0ea"] colorWithAlphaComponent:0.8];
}

- (UIColor *)cellTextColorSelected:(BOOL)selected
{
    return selected ? [UIColor whiteColor] : [UIColor colorWithHexString:@"2b77ad"];
}

- (UIColor *)cellBorderColorSelected:(BOOL)selected
{
    return selected ? [UIColor colorWithHexString:@"0c2e4d"] : [UIColor colorWithHexString:@"2b77ad"];
}

- (UIColor *)cellTextShadowColorSelected:(BOOL)selected
{
    return selected ? [[UIColor blackColor] colorWithAlphaComponent:0.5] : [[UIColor whiteColor] colorWithAlphaComponent:0.5];
}

- (CGSize)cellTextShadowOffsetSelected:(BOOL)selected
{
    return selected ? CGSizeMake(0.0, -1.0) : CGSizeMake(0.0, 1.0);
}
*/
@end
