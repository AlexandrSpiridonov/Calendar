//
//  BNMonthCalendarVC.m
//  BNMonthCalendar2CollectionViewCustomLayout
//
//  Created by Alexandr on 12.08.13.
//  Copyright (c) 2013 Alexander Spiridonov. All rights reserved.
//

#import "BNMonthCalendarVC.h"
#import "BNMonthCalendarLayout.h"
#import "BNMonthCalendarDayCell.h"
#import "BNMonthCalendarMonthHeader.h"

NSString * const BNMonthCalendarCellReuseIdentifier = @"BNMonthCalendarCellReuseIdentifier";
NSString * const BNMonthHeaderReuseIdentifier = @"BNMonthHeaderReuseIdentifier";

@interface BNMonthCalendarVC ()

@property (strong, nonatomic) IBOutlet BNMonthCalendarLayout *collectionViewLayout;
@property (strong, nonatomic) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray *arrMonths;
@property (nonatomic, strong) NSMutableDictionary *dictDaysOfMonths;
@property (nonatomic, strong) NSMutableDictionary *dictIndexStartEndMonths;
@property (nonatomic, strong) NSArray *arrWeekDay;

@property (nonatomic, strong) NSCalendar *calendar;
@property (nonatomic, strong) NSDate *fromDate;
@property (nonatomic, strong) NSDate *toDate;
@property (nonatomic,strong) UIPanGestureRecognizer *pan;

@end

@implementation BNMonthCalendarVC

- (void)viewDidLoad
{
     
    [super viewDidLoad];
    [self.collectionView setCollectionViewLayout:[[BNMonthCalendarLayout alloc] init]];
    
	// Do any additional setup after loading the view.
    //self.collectionView.backgroundColor = [UIColor grayColor];
    [self.collectionView setPagingEnabled:YES];
    //регистрация классов
    [self.collectionView registerClass:[BNMonthCalendarDayCell class] forCellWithReuseIdentifier:BNMonthCalendarCellReuseIdentifier];
    [self.collectionView registerClass:[BNMonthCalendarMonthHeader class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier: BNMonthHeaderReuseIdentifier];
    
    //загрузка и инициализация datesource для календаря
   // self.calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    self.calendar = [NSCalendar currentCalendar];
   // [self.calendar setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"ru_RU"]];
    NSDate *now = [self.calendar dateFromComponents:[self.calendar components:(NSYearCalendarUnit|NSMonthCalendarUnit) fromDate:[NSDate date]]];
    NSDateComponents *dateComponents = [self.calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:now];
    NSInteger monthNow = [dateComponents month];
    
    [dateComponents setMonth: (monthNow-6)];
    self.fromDate = [self.calendar dateFromComponents:dateComponents];
    [dateComponents setMonth: (monthNow+6)];
    self.toDate = [self.calendar dateFromComponents:dateComponents];
    [self loadData];
    
    CGRect monthFrame = self.view.frame;
    monthFrame.origin.x = 0;
    monthFrame.origin.y = -self.view.frame.size.height;
    self.view.frame = monthFrame;
    
    ///перетаскивание с верху
    self.pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
	self.pan.delegate = self;
	[self.view addGestureRecognizer:self.pan];
    
    if(self.interfaceOrientation == UIDeviceOrientationLandscapeRight || self.interfaceOrientation == UIDeviceOrientationLandscapeLeft)
    {
        CGRect monthFrame = self.view.frame;
        monthFrame.size.width = 480;
        monthFrame.size.height = 320;
        self.view.frame = monthFrame;
        
    }
    else
    {
        CGRect monthFrame = self.view.frame;
        monthFrame.size.width = 320;
        monthFrame.size.height = 320;
        self.view.frame = monthFrame;
    }

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Month Calendar DataSource

-(void)loadData
{
    // get week day names array
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    self.arrWeekDay = [dateFormatter shortWeekdaySymbols];
    
    // adjust array depending on which weekday should be first
    NSUInteger firstWeekdayIndex = [self.calendar firstWeekday] - 1;
    if (firstWeekdayIndex > 0)
    {
        self.arrWeekDay = [[self.arrWeekDay subarrayWithRange:NSMakeRange(firstWeekdayIndex, 7-firstWeekdayIndex)]
                    arrayByAddingObjectsFromArray:[self.arrWeekDay subarrayWithRange:NSMakeRange(0,firstWeekdayIndex)]];
    }
    self.dictDaysOfMonths = [NSMutableDictionary new];
    self.dictIndexStartEndMonths = [NSMutableDictionary new];
    self.arrMonths = [NSMutableArray new];
    NSInteger numberOfSections = [self.calendar components:NSMonthCalendarUnit fromDate:self.fromDate toDate: self.toDate options:0].month;
    for (int section = 0; section < numberOfSections; section++)
    {
        NSDate *firstDayInMonth = [self dateForFirstDayInSection:section];
        
        NSDateFormatter *dateFormatter = [NSDateFormatter new];
        dateFormatter.dateFormat = @"MMMM YYYY";
        NSString * keyMonth = [dateFormatter stringFromDate:firstDayInMonth];
        [self.arrMonths setObject:keyMonth atIndexedSubscript:section];
        NSInteger numberOfItemsInSection = 7 * [self numberOfWeeksForMonthOfDate:[self dateForFirstDayInSection:section]];
        NSInteger weekdayOfDate = [self.calendar  ordinalityOfUnit:NSWeekdayCalendarUnit inUnit:NSWeekCalendarUnit forDate:firstDayInMonth];
        NSDateComponents *dateComponents = [NSDateComponents new];
        NSMutableArray *arrDay = [NSMutableArray array];
        for (int item = 0; item < numberOfItemsInSection; item++)
        {
            dateComponents.day = item - (weekdayOfDate - 1);
            NSDate *cellDate = [self.calendar dateByAddingComponents:dateComponents toDate:firstDayInMonth options:0];
            NSDateFormatter *dateFormatter = [NSDateFormatter new];
            dateFormatter.dateFormat = @"dd";
            NSString *DayText = [dateFormatter stringFromDate:cellDate];
            [arrDay setObject:DayText atIndexedSubscript:item];
        }
        NSNumber *start = [NSNumber numberWithInt:weekdayOfDate-1];
        NSRange days = [self.calendar rangeOfUnit:NSDayCalendarUnit
                               inUnit:NSMonthCalendarUnit
                              forDate:firstDayInMonth];
        NSNumber *end = [NSNumber numberWithInt:(weekdayOfDate+days.length-2)];
        NSMutableArray *indexStartEnd = [NSMutableArray new];
        [indexStartEnd setObject:start atIndexedSubscript:0];
        [indexStartEnd setObject:end atIndexedSubscript:1];
        [self.dictDaysOfMonths setObject:arrDay forKey:keyMonth];
        [self.dictIndexStartEndMonths setObject:indexStartEnd forKey:keyMonth];
    }
   // NSLog(@"dic %@",self.dictDaysOfMonths);
    
}

- (NSDate *) dateForFirstDayInSection:(NSInteger)section {
    
    NSDateComponents *dateComponents = [NSDateComponents new];
    dateComponents.month = section;
	return [self.calendar dateByAddingComponents: dateComponents toDate:self.fromDate options:0];
}

- (NSDate *) dateForLastDayInSection:(NSInteger)section {
    
    NSDateComponents *dateComponents = [NSDateComponents new];
    dateComponents.month = section;
	NSDate *firstDayInMonth = [self.calendar dateByAddingComponents: dateComponents toDate:self.fromDate options:0];
    NSDate *lastDayInMonth = [self.calendar dateByAddingComponents:((^{
		NSDateComponents *dateComponents = [NSDateComponents new];
		dateComponents.month = 1;
		dateComponents.day = -1;
		return dateComponents;
	})()) toDate:firstDayInMonth options:0];
    return lastDayInMonth;
}

- (NSUInteger) numberOfWeeksForMonthOfDate:(NSDate *)date {
    
	NSDate *firstDayInMonth = [self.calendar dateFromComponents:[self.calendar components:NSYearCalendarUnit|NSMonthCalendarUnit fromDate:date]];
	
	NSDate *lastDayInMonth = [self.calendar dateByAddingComponents:((^{
		NSDateComponents *dateComponents = [NSDateComponents new];
		dateComponents.month = 1;
		dateComponents.day = -1;
		return dateComponents;
	})()) toDate:firstDayInMonth options:0];
	
	NSDate *fromSunday = [self.calendar dateFromComponents:((^{
		NSDateComponents *dateComponents = [self.calendar components:NSWeekOfYearCalendarUnit|NSYearForWeekOfYearCalendarUnit fromDate:firstDayInMonth];
		dateComponents.weekday = 1;
		return dateComponents;
	})())];
	
	NSDate *toSunday = [self.calendar dateFromComponents:((^{
		NSDateComponents *dateComponents = [self.calendar components:NSWeekOfYearCalendarUnit|NSYearForWeekOfYearCalendarUnit fromDate:lastDayInMonth];
		dateComponents.weekday = 1;
		return dateComponents;
	})())];
	
	return 1 + [self.calendar components:NSWeekCalendarUnit fromDate:fromSunday toDate:toSunday options:0].week;
}

#pragma mark - UICollectionViewDataSource
//количество секций
-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return self.arrMonths.count;
}

//количество итемов в секции
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{//id <NSFetchedResultsSectionInfo> sectionInfo = self.fetchedResultsController.sections[section];
    //   return [sectionInfo numberOfObjects];
    NSArray * arr = self.dictDaysOfMonths[self.arrMonths[section]];
    return arr.count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    BNMonthCalendarDayCell * cell = [collectionView dequeueReusableCellWithReuseIdentifier:BNMonthCalendarCellReuseIdentifier forIndexPath:indexPath];
    NSArray * arr = self.dictDaysOfMonths[self.arrMonths[indexPath.section]];
    cell.dayTextLabel.text = arr[indexPath.item];
   /*
    int start = [self.dictIndexStartEndMonths[self.arrMonths[indexPath.section]][0] intValue];
    int end = [self.dictIndexStartEndMonths[self.arrMonths[indexPath.section]][1] intValue];
   
    if (indexPath.item < start || indexPath.item > end)
    {
            cell.backgroundColor = [UIColor grayColor];
    }
    [cell setNeedsLayout];
    */

    return cell;
}

-(UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionReusableView *view;
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        BNMonthCalendarMonthHeader *monthHeader = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:BNMonthHeaderReuseIdentifier forIndexPath:indexPath];
        monthHeader.monthTextLabel.text = self.arrMonths[indexPath.section];
        [monthHeader.monthTextLabel sizeToFit];
        monthHeader.firstDayTextLabel.text = self.arrWeekDay[0];
        monthHeader.secondTextLabel.text = self.arrWeekDay[1];
        monthHeader.thirdDayTextLabel.text = self.arrWeekDay[2];
        monthHeader.fourthDayTextLabel.text = self.arrWeekDay[3];
        monthHeader.fifthDayTextLabel.text = self.arrWeekDay[4];
        monthHeader.sixthDayTextLabel.text = self.arrWeekDay[5];
        monthHeader.seventhDayTextLabel.text = self.arrWeekDay[6];
        view = monthHeader;
    }
    return view;
}

- (void)pan:(UIPanGestureRecognizer *)gesture {
    if (gesture.numberOfTouches > 0) {
        CGPoint location  = [gesture locationInView:self.view.superview ];
        NSLog(@"pan inside Y = %f", location.y);
        //перетягиваем нажатием
        CGRect monthFrame = self.view.frame;
        monthFrame.origin.x = 0;
        monthFrame.origin.y = location.y - self.view.frame.size.height;
        self.view.frame = monthFrame;
    }
    else
    {
        CGRect monthFrame = self.view.frame;
        if (monthFrame.origin.y< - self.view.frame.size.height +self.view.frame.size.height/2 )
        {
            monthFrame.origin.y = -self.view.frame.size.height;
            [UIView animateWithDuration:0.3 animations:^{
                self.view.frame = monthFrame;
            }];
        }
        else
        {
            monthFrame.origin.y = 0;
            [UIView animateWithDuration:0.3 animations:^{
                self.view.frame = monthFrame;
            }];
        }
        
        
        
        
    }
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch{
    
    if([touch locationInView:self.view].y > self.view.frame.size.height-50)
        return YES;
	return NO;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    // Then your code...
    
    if(self.interfaceOrientation == UIDeviceOrientationLandscapeRight || self.interfaceOrientation == UIDeviceOrientationLandscapeLeft)
    {
        CGRect monthFrame = self.view.frame;
        monthFrame.size.width = 480;
        monthFrame.size.height = 320;
         self.view.frame = monthFrame;
        
    }
    else
    {
        CGRect monthFrame = self.view.frame;
        monthFrame.size.width = 320;
        monthFrame.size.height = 320;
         self.view.frame = monthFrame;
    }

}

@end
