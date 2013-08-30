//
//  BNCalendarVC.m
//  BNCalendar1CollectionViewStoryboard
//
//  Created by Alexandr on 01.08.13.
//  Copyright (c) 2013 Alexander Spiridonov. All rights reserved.
//

#import "BNCalendarVC.h"
#import "BNCollectionViewCalendarLayout.h"
#import "BNCalendarItem.h"
// Collection View
#import "BNCalendarCell.h"
#import "BNTimeRowHeaderBackground.h"
#import "BNDayColumnHeaderBackground.h"
#import "BNHorizontalHourGridline.h"
#import "BNHorizontalMinuteGridline.h"
#import "BNVerticalDayGridline.h"
#import "BNDayColumnHeader.h"
#import "BNTimeRowHeader.h"
#import "BNCurrentTimeGridline.h"
#import <QuartzCore/QuartzCore.h>
#import "BNCalendarDraggingView.h"
#import "BNWorkTimeDecorationLayer.h"
#import "BNLunchTimeDecorationLayer.h"
#import "BNCurrentDayDecorationLayer.h"
#import "BNCurrentTimeIndicator.h"
#import "BNMonthCalendarVC.h"

NSString * const BNCalendarCellReuseIdentifier = @"BNCalendarCellReuseIdentifier";
NSString * const BNDayColumnHeaderReuseIdentifier = @"BNDayColumnHeaderReuseIdentifier";
NSString * const BNTimeRowHeaderReuseIdentifier = @"BNTimeRowHeaderReuseIdentifier";
NSString * const BNCurrentTimeIndicatorReuseIdentifier = @"BNCurrentTimeIndicatorReuseIdentifier";

@interface BNCalendarVC ()
{
    BNCalendarCell *orignCell;
    BNCalendarItem *orignItem;
    BNCalendarDraggingView *mockView;
    UIImageView *mockCell;
    CGPoint mockCenter;
}
@property (strong, nonatomic) IBOutlet UICollectionView *collectionView;
@property (strong, nonatomic) IBOutlet BNCollectionViewCalendarLayout *collectionViewLayout;
@property (nonatomic, strong) NSMutableArray *dictSection;
@property (nonatomic, strong) NSMutableArray *dictWorkloadOfDay;
@property (nonatomic, strong) NSMutableDictionary *dict;
@property (nonatomic, strong) NSMutableDictionary *dict2;
@property (nonatomic, assign) CGFloat scrollingSpeed;
@property (nonatomic, assign) CGFloat scrollRateX;
@property (nonatomic, assign) CGFloat scrollRateY;
@property (nonatomic, strong) NSTimer *scrollingTimer;
@property (nonatomic, strong) NSTimer *saveTimer;
@property (nonatomic, strong) BNMonthCalendarVC *monthCalendar;
@property (nonatomic,strong) UIPanGestureRecognizer *pan;
@end

@implementation BNCalendarVC
//@synthesize collectionViewLayout;
//@synthesize collectionView;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void) initUserDefaults{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setInteger:540 forKey:@"strartWorkTime"];
    [prefs setInteger:1080 forKey:@"endWorkTime"];
    
    [prefs setInteger:720 forKey:@"strartLunchTime"];
    [prefs setInteger:780 forKey:@"endLunchTime"];
    [prefs synchronize];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initUserDefaults];
	// Do any additional setup after loading the view.
    self.collectionViewLayout.delegate = self;
    //[self.collectionView setPagingEnabled:YES];
    self.collectionView.backgroundColor = [UIColor whiteColor];
    self.collectionView.dataSource = self;
    [self.collectionView registerClass:BNCalendarCell.class forCellWithReuseIdentifier:BNCalendarCellReuseIdentifier];
    [self.collectionView registerClass:BNDayColumnHeader.class forSupplementaryViewOfKind:BNCollectionElementKindDayColumnHeader withReuseIdentifier:BNDayColumnHeaderReuseIdentifier];
    [self.collectionView registerClass:BNTimeRowHeader.class forSupplementaryViewOfKind:BNCollectionElementKindTimeRowHeader withReuseIdentifier:BNTimeRowHeaderReuseIdentifier];
    [self.collectionView registerClass:BNCurrentTimeIndicator.class forSupplementaryViewOfKind:BNCollectionElementKindCurrentTimeIndicator withReuseIdentifier:BNCurrentTimeIndicatorReuseIdentifier];
    
    // These are optional—if you don't want any of the decoration views, just don't register a class for it
    // [self.collectionViewLayout registerClass:BNCurrentTimeIndicator.class forDecorationViewOfKind:BNCollectionElementKindCurrentTimeIndicator];
    
    [self.collectionViewLayout registerClass:BNCurrentTimeGridline.class forDecorationViewOfKind:BNCollectionElementKindCurrentTimeHorizontalGridline];
    [self.collectionViewLayout registerClass:BNHorizontalHourGridline.class forDecorationViewOfKind:BNCollectionElementKindHorizontalHourGridline];
    [self.collectionViewLayout registerClass:BNHorizontalMinuteGridline.class forDecorationViewOfKind:BNCollectionElementKindHorizontalMinuteGridline];
    [self.collectionViewLayout registerClass:BNVerticalDayGridline.class forDecorationViewOfKind:BNCollectionElementKindVerticalGridline];
    [self.collectionViewLayout registerClass:BNTimeRowHeaderBackground.class forDecorationViewOfKind:BNCollectionElementKindTimeRowHeaderBackground];
    
    //background layers
    [self.collectionViewLayout registerClass:BNWorkTimeDecorationLayer.class forDecorationViewOfKind:BNCollectionElementKindWorkTimeDecorationLayer];
    [self.collectionViewLayout registerClass:BNLunchTimeDecorationLayer.class forDecorationViewOfKind:BNCollectionElementKindLunchTimeDecorationLayer];
    [self.collectionViewLayout registerClass:BNCurrentDayDecorationLayer.class forDecorationViewOfKind:BNCollectionElementKindCurrentDayDecorationLayer];
    
    [self loadData2];
    [self.collectionViewLayout initializeAttributesForAllSections];
    
    UIImage *bgr = [UIImage imageNamed:@"calendar_main_bgr"];
    self.collectionView.backgroundView = [[UIImageView alloc] initWithImage:bgr];
    self.collectionView.backgroundView.contentMode = UIViewContentModeTopLeft;
    
    
    UIStoryboard * mainSB = [UIStoryboard storyboardWithName:MainStoryboard bundle:nil];
    
    
    self.monthCalendar = [mainSB instantiateViewControllerWithIdentifier:@"BNMonthCalendarVC"];
    
    [self.view addSubview:self.monthCalendar.view];
    CGRect monthFrame = self.monthCalendar.view.frame;
    monthFrame.origin.x = 0;
    monthFrame.origin.y = -self.view.frame.size.height;
    self.monthCalendar.view.frame = monthFrame;
    ///перетаскивание с верху
    self.pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
	self.pan.delegate = self;
	[self.collectionView addGestureRecognizer:self.pan];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UICollectionViewDataSource
-(void)loadData
{
    
    double mktime0;
    mktime0 = CACurrentMediaTime();
    
    NSArray * notesArr = [NSArray arrayWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"notes" ofType:@"plist"]];
    
    
    NSLog(@"arrayWithContentsOfFile %i rows loaded by %f sec", [notesArr count], CACurrentMediaTime() - mktime0);
    
    mktime0 = CACurrentMediaTime();
    
    
    NSMutableDictionary * notesDict = [NSMutableDictionary dictionary];
    
    self.dict = [NSMutableDictionary dictionary];
    self.dict2 = [NSMutableDictionary dictionary];//<----
    
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString * key2;
    for ( NSDictionary * note in notesArr) {
        
        NSString * key = [note[@"toDate"] substringWithRange:NSMakeRange(0, 10)];
        
        if( !notesDict[key] ) notesDict[key]  = [NSMutableDictionary dictionary];
        
        [notesDict[key] setObject:note forKey:note[@"ID"]];
        
        
        if( !self.dict[key] ) self.dict[key]  = [NSMutableArray array];
        if( !self.dict2[key] ) self.dict2[key]  = [NSMutableArray array];
        
        BNCalendarItem * event  = [BNCalendarItem new];
        event.start = ([dateFormat dateFromString:note[@"toDate"]] == nil)? [NSDate date]: [dateFormat dateFromString:note[@"toDate"]];
        event.end =   [event.start dateByAddingTimeInterval:[note[@"toLength"] intValue]*60  ];
        event.Type = [NSNumber numberWithInt: [note[@"Type"] intValue]];
        event.title = note[@"Message"];
        
        
        [self.dict[key] addObject:event];
        [self.dict2[key] addObject:note];//---------------
        key2 = key;
    }
    self.dictSection = [[notesDict keysSortedByValueUsingComparator:^NSComparisonResult(NSDictionary *note1, NSDictionary *note2) { return [note1[@"toDate"] compare:note2[@"toDate"]]; }] mutableCopy];
    [self saveFile];
}

-(void)saveFile{
    
    NSMutableArray *array = [NSMutableArray new];
    for(int i = 0; i<[self.dictSection count]; i++)
    {
         NSArray * arr = self.dict2[self.dictSection[i]];
        for(int j=0;j<[arr count];j++)
            if(j<5)[array addObject:arr[j]];
            else break;
    }
   // NSString *filePath = [[NSBundle mainBundle] pathForResource:@"notes2" ofType:@"plist"];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *prsPath = [documentsDirectory stringByAppendingPathComponent:@"notes2.plist"];
    [array writeToFile:prsPath atomically:YES];
    NSLog(@"count %d", [array count]);
}

-(void)loadData2
{
    
    double mktime0;
    mktime0 = CACurrentMediaTime();
    
    NSArray * notesArr = [NSArray arrayWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"notes2" ofType:@"plist"]];
    
    
    NSLog(@"arrayWithContentsOfFile %i rows loaded by %f sec", [notesArr count], CACurrentMediaTime() - mktime0);
    
    mktime0 = CACurrentMediaTime();
    
    
    NSMutableDictionary * notesDict = [NSMutableDictionary dictionary];
    
    self.dict = [NSMutableDictionary dictionary];
    
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString * key2;
    for ( NSDictionary * note in notesArr) {
        
        NSString * key = [note[@"toDate"] substringWithRange:NSMakeRange(0, 10)];
        
        if( !notesDict[key] ) notesDict[key]  = [NSMutableDictionary dictionary];
        
        [notesDict[key] setObject:note forKey:note[@"ID"]];
        
        
        if( !self.dict[key] ) self.dict[key]  = [NSMutableArray array];
        
        BNCalendarItem * event  = [BNCalendarItem new];
        event.start = ([dateFormat dateFromString:note[@"toDate"]] == nil)? [NSDate date]: [dateFormat dateFromString:note[@"toDate"]];
        event.end =   [event.start dateByAddingTimeInterval:[note[@"toLength"] intValue]*60  ];
        event.Type = [NSNumber numberWithInt: [note[@"Type"] intValue]];
        event.title = note[@"Message"];
        
        
        [self.dict[key] addObject:event];
        key2 = key;
    }
    self.dictSection = [[notesDict keysSortedByValueUsingComparator:^NSComparisonResult(NSDictionary *note1, NSDictionary *note2) { return [note1[@"toDate"] compare:note2[@"toDate"]]; }] mutableCopy];
    [self initWorkloadOfDay];
}

-(void)initWorkloadOfDay
{
    self.dictWorkloadOfDay = [NSMutableArray new];
    NSMutableArray * temparray = [NSMutableArray array];
    for ( int i = 0 ; i < 48 ; i ++ )
        [temparray addObject:[NSNumber numberWithInt:0]];
     NSInteger hour, minute;
    
    for (int i = 0; i < [self.dictSection count]; i++) {
        [self.dictWorkloadOfDay addObject:[temparray mutableCopy]];
        int n = [(NSArray*)self.dict[self.dictSection[i]] count];
        NSArray * arr = self.dict[self.dictSection[i]];
        for(int j = 0; j < n; j++)
        {
            BNCalendarItem * cVItem = arr[j];
            NSDate * noteDateStart = cVItem.start;
            NSDate * noteDateEnd = cVItem.end;
            NSDateComponents *components = [[NSCalendar currentCalendar] components:(NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:noteDateStart];
            hour = [components hour];
            minute = [components minute];
            if(minute>=30)minute=1; else minute=0;
            int start = hour*2+minute;
            components = [[NSCalendar currentCalendar] components:(NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:noteDateEnd];
            hour = [components hour];
            minute = [components minute];
            if(minute>0 && minute<=30) minute=1;
            else
                if(minute > 30)
                    minute = 2;
            int end = hour*2+minute;
            NSMutableArray * array = (NSMutableArray *)self.dictWorkloadOfDay[i];
            for(int k = start; k<end; k++)
                [array replaceObjectAtIndex:k withObject:[NSNumber numberWithInt:[(NSNumber *)[array objectAtIndex:k] intValue] + 1]];
        }
    }
}

//количество секций
-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    //return self.fetchedResultsController.sections.count;
    return self.dictSection.count;
}


//количество итемов в секции
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{//id <NSFetchedResultsSectionInfo> sectionInfo = self.fetchedResultsController.sections[section];
    //   return [sectionInfo numberOfObjects];
    NSArray * arr = self.dict[self.dictSection[section]];
   /* if( arr.count > 3)
    {
        return 3;
    }
    */
    return arr.count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionV cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    BNCalendarCell* cell = [collectionV dequeueReusableCellWithReuseIdentifier:BNCalendarCellReuseIdentifier forIndexPath:indexPath];
    NSArray * arr = self.dict[self.dictSection[indexPath.section]];
    BNCalendarItem * cVItem = arr[indexPath.item];
    cell.message.text = cVItem.title;
    if( [cVItem.Type intValue] == 0 )
        cell.noteType = [NSNumber numberWithInt: 2];
    else
    {
        if([cVItem.start compare:[NSDate date]] == NSOrderedAscending)
        {
            cell.noteType = [NSNumber numberWithInt: 2];
            
        }
        else
            cell.noteType = [NSNumber numberWithInt: 1];
    }
    [cell setNeedsLayout];
    UILongPressGestureRecognizer *longPressGesture =
    [[UILongPressGestureRecognizer alloc]
     initWithTarget:self action:@selector(longPress:)];
    [cell addGestureRecognizer:longPressGesture];
    return cell;
}

-(UICollectionReusableView *)collectionView:(UICollectionView *)collectionV viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionReusableView *view;
    if ([kind isEqualToString:BNCollectionElementKindDayColumnHeader]) {
        BNDayColumnHeader *dayColumnHeader = [collectionV dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:BNDayColumnHeaderReuseIdentifier forIndexPath:indexPath];
        NSString *str = self.dictSection[indexPath.section];
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateFormat:@"yyyy-MM-dd"];
        NSDate * date  = [dateFormat dateFromString:str];
        //dayColumnHeader.day = date;
        dateFormat.dateFormat = @"dd.MM.YYYY";
        dayColumnHeader.dateTitle.text = [dateFormat stringFromDate:date];
        dateFormat.dateFormat = @"cccc";
        dayColumnHeader.weekTitle.text = [dateFormat stringFromDate:date];
        NSArray *arr = self.dictWorkloadOfDay[indexPath.section];
        int max = [[arr valueForKeyPath:@"@max.intValue"] intValue];
        for ( int i = 0 ; i < 48 ; i ++ )
        {
            UIView *view = (UIView *)dayColumnHeader.workload[i];
            if ([arr[i] integerValue] == 0 )view.backgroundColor = [UIColor colorWithRed:1 green:0 blue:0 alpha:0];
            else
                view.backgroundColor = [UIColor colorWithRed:0.5 green:0 blue:1 alpha:[arr[i] floatValue]/max];
        }
        //[dayColumnHeader setNeedsLayout];
        view = dayColumnHeader;
    }
    else if ([kind isEqualToString:BNCollectionElementKindTimeRowHeader]) {
        BNTimeRowHeader *timeRowHeader = [collectionV dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:BNTimeRowHeaderReuseIdentifier forIndexPath:indexPath];
        //timeRowHeader.time = [self.collectionViewLayout dateForTimeRowHeaderAtIndexPath:indexPath];
        if(indexPath.item == 0 )
            timeRowHeader.title45.text = @"";
        else
            timeRowHeader.title45.text = [NSString stringWithFormat:@"%d:45",indexPath.item-1];
       if(indexPath.item == 24 )
       {
           timeRowHeader.title.text = [NSString stringWithFormat:@"0:00"];
           timeRowHeader.title15.text = [NSString stringWithFormat:@""];
           timeRowHeader.title30.text = [NSString stringWithFormat:@""];
       }
        else
        {
            timeRowHeader.title.text = [NSString stringWithFormat:@"%d:00",indexPath.item];
            timeRowHeader.title15.text = [NSString stringWithFormat:@"%d:15",indexPath.item];
            timeRowHeader.title30.text = [NSString stringWithFormat:@"%d:30",indexPath.item];
        }
        [timeRowHeader setNeedsLayout];
        view = timeRowHeader;
    }
    else if ([kind isEqualToString:BNCollectionElementKindCurrentTimeIndicator]) {
        BNCurrentTimeIndicator *currTimeInicator = [collectionV dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:BNCurrentTimeIndicatorReuseIdentifier forIndexPath:indexPath];
        NSDateFormatter *dateFormatter = [NSDateFormatter new];
        dateFormatter.dateFormat = @"HH:mm";
        currTimeInicator.timeTitle.text = [dateFormatter stringFromDate:[NSDate date]];
        view = currTimeInicator;
    }
    
    return view;
}

#pragma mark - BNCollectionViewCalendarLayout

- (NSDate *)collectionView:(UICollectionView *)collectionView layout:(BNCollectionViewCalendarLayout *)collectionViewLayout dayForSection:(NSInteger)section
{
    //id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController.sections objectAtIndex:section];
    //MSEvent *event = sectionInfo.objects[0];
    
    //return [event day];
    NSString *str = self.dictSection[section];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd"];
    NSDate * date  = [dateFormat dateFromString:str];
    return date;
}

- (NSDate *)collectionView:(UICollectionView *)collectionView layout:(BNCollectionViewCalendarLayout *)collectionViewLayout startTimeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    //MSEvent *event = [self.fetchedResultsController objectAtIndexPath:indexPath];
    //return event.start;
    //return [NSDate date];
    NSArray * arr = self.dict[self.dictSection[indexPath.section]];
    BNCalendarItem * cVItem = arr[indexPath.item];
    return  cVItem.start;
}

- (NSDate *)collectionView:(UICollectionView *)collectionView layout:(BNCollectionViewCalendarLayout *)collectionViewLayout endTimeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    // MSEvent *event = [self.fetchedResultsController objectAtIndexPath:indexPath];
    //return [NSDate date];
    NSArray * arr = self.dict[self.dictSection[indexPath.section]];
    BNCalendarItem * cVItem = arr[indexPath.item];
    return  cVItem.end;
}

- (NSDate *)currentTimeComponentsForCollectionView:(UICollectionView *)collectionView layout:(BNCollectionViewCalendarLayout *)collectionViewLayout
{
    return [NSDate date];
}

- (NSInteger)currentSection
{
    return 5;
}

- (void)save
{
    [self.saveTimer invalidate];
    self.saveTimer = nil;
    NSDate * start =  [self.collectionViewLayout timeDateComponentsFloatX:(mockView.frame.origin.x+mockView.view.frame.origin.x) FloatY:(mockView.frame.origin.y+mockView.view.frame.origin.y)];
    NSDate * end =  [self.collectionViewLayout timeDateComponentsFloatX:(mockView.frame.origin.x+mockView.view.frame.origin.x) FloatY:(mockView.frame.origin.y+mockView.view.frame.origin.y+mockView.view.frame.size.height)];

    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    NSInteger section = [self.collectionViewLayout sectionToFloatX: mockView.frame.origin.x];
    //NSLog(@"SAVE SECTION %d", section);
    [mockView removeFromSuperview];
    mockView = nil;
    
    dateFormatter.dateFormat = @"YYYY-MM-dd";
    orignItem.start = start;
    orignItem.end = end;
    NSString * key = [dateFormatter stringFromDate:start];
    NSMutableArray * arrNew = [self.dict[key] mutableCopy];
    if(!arrNew) arrNew = [NSMutableArray array];
    [arrNew addObject: orignItem];
    [self.collectionViewLayout deleteLayoutAttributeItemsInSection:section];
    [self.dict setObject: arrNew forKey:key];
    [self.collectionView reloadData];
    [self.collectionViewLayout updateLayoutAttributeItemsInSection:section];
    [self.collectionView reloadData];
    //NSInteger item = [self.collectionView numberOfItemsInSection:section];
   // NSIndexPath * insertIndexPath = [NSIndexPath indexPathForItem:item inSection:section];
    //NSLog(@"ind path save insert %@", insertIndexPath);
   
    /*
    NSLog(@"SAVE SECTION: %d before %d", section, [self.collectionView numberOfItemsInSection:section]);
    [self.collectionView performBatchUpdates:^{
        [self.collectionView insertItemsAtIndexPaths:@[insertIndexPath]];
    }completion:nil];
     NSLog(@"SAVE SECTION: %d after %d", section, [self.collectionView numberOfItemsInSection:section]);
    */
    
    //[self.dict setObject: arrNew forKey:key];
    //[self.collectionView reloadData];
    //[self.collectionViewLayout updateLayoutAttributeItemsInSection:section];
    //[self.collectionView reloadData];
}

-(BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

#pragma mark - Gesture recognizer

- (void)longPress:(UILongPressGestureRecognizer *)gesture
{
    switch (gesture.state)
    {
        case UIGestureRecognizerStateBegan:
        {
            [self.scrollingTimer invalidate];
            self.scrollingTimer = nil;
            self.scrollRateY = 0;
            self.scrollRateX = 0;
            
            if(mockView)
            {
               [self save];
                //[mockView removeFromSuperview];
                //mockView = nil;
            }
            
            //orignCell = (BNCalendarCell *)[gesture view];
            //NSLog(@"orignCell do = %@", orignCell);
            //UICollectionViewCell *cell = (UICollectionViewCell *)[gesture view];
           // NSIndexPath *indexPath = [self.collectionView indexPathForCell:orignCell];
            CGPoint initialPinchPoint = [gesture locationInView:self.collectionView];
            NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:initialPinchPoint];
            //NSLog(@"indexPath = %@", indexPath);
            orignCell = (BNCalendarCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
            //NSLog(@"orignCell = %@", orignCell);
            CGRect tempFrame = orignCell.frame;
            tempFrame.size.width = self.collectionViewLayout.sectionWidth - self.collectionViewLayout.cellMargin.left - self.collectionViewLayout.cellMargin.right;
            
            mockView = [BNCalendarDraggingView new];
            tempFrame.size.height = tempFrame.size.height+mockView.btnTopResize.frame.size.height+mockView.btnBottomResize.frame.size.height;
            tempFrame.origin.y = tempFrame.origin.y - mockView.btnTopResize.frame.size.height;
            mockView.frame = tempFrame;
            
            NSArray * arr = self.dict[self.dictSection[indexPath.section]];
            BNCalendarItem * origItem = arr[indexPath.item];
            
            
            NSDateFormatter *dateFormatter1 = [NSDateFormatter new];
            dateFormatter1.dateFormat = @"YYYY-MM-dd HH:mm";
            NSDateFormatter *dateFormatter2 = [NSDateFormatter new];
            dateFormatter2.dateFormat = @"HH:mm";
            mockView.time.text = [NSString stringWithFormat:@"%@ - %@",[dateFormatter1 stringFromDate:origItem.start], [dateFormatter2 stringFromDate:origItem.end]];
            mockView.message.text = origItem.title;
            mockView.toLength.text = @"";
            
            if( [orignCell.noteType intValue] == 0 )
                mockView.noteType = [NSNumber numberWithInt: 2];
            else
            {
                if([origItem.start compare:[NSDate date]] == NSOrderedAscending)
                {
                    mockView.noteType = [NSNumber numberWithInt: 2];
                    
                }
                else
                    mockView.noteType = [NSNumber numberWithInt: 1];
            }
            mockView.delegate = self;
            [self.collectionView addSubview:mockView];
            [mockView needsUpdateConstraints];

            NSMutableArray * arrLast = [self.dict[self.dictSection[indexPath.section]] mutableCopy];
            if(!arrLast) arrLast = [NSMutableArray array];
            orignItem = arrLast[indexPath.item];
            [arrLast removeObjectAtIndex: indexPath.item];
            [self.collectionViewLayout deleteLayoutAttributeItemsInSection:indexPath.section];
            [self.dict setObject: arrLast forKey:self.dictSection[indexPath.section]];
            [self.collectionView reloadData];
            [self.collectionViewLayout updateLayoutAttributeItemsInSection: indexPath.section];
            [self.collectionView reloadData];
            //NSLog(@"DELETE SECTION %d", indexPath.section);
            /*
            NSLog(@"DELETE SECTION: %d before %d", indexPath.section, [self.collectionView numberOfItemsInSection:indexPath.section]);
            [self.collectionView performBatchUpdates:^{
                [self.collectionView deleteItemsAtIndexPaths:@[indexPath]];
            }completion:nil];
            NSLog(@"DELETE SECTION: %d after %d", indexPath.section, [self.collectionView numberOfItemsInSection:indexPath.section]);
             */
                        
            //self.saveTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(save) userInfo:nil repeats:YES];
            //[[NSRunLoop mainRunLoop] addTimer:self.saveTimer forMode:NSDefaultRunLoopMode];
            // enable scrolling for cell
            
            NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObject:gesture forKey:@"gesture"];
            self.scrollingTimer = [NSTimer timerWithTimeInterval:1/8 target:self selector:@selector(scrollTableWithCell:) userInfo:userInfo repeats:YES];
            [[NSRunLoop mainRunLoop] addTimer:self.scrollingTimer forMode:NSDefaultRunLoopMode];
        } break;
        case UIGestureRecognizerStateChanged:
        {
            [self.saveTimer invalidate];
            CGPoint location = [gesture locationInView:self.collectionView];
            NSDate * start =  [self.collectionViewLayout timeDateComponentsFloatX:(location.x-mockView.frame.size.width/2) FloatY: mockView.frame.origin.y+mockView.view.frame.origin.y];
            NSDate * end =  [self.collectionViewLayout timeDateComponentsFloatX:(location.x-mockView.frame.size.width/2) FloatY:mockView.frame.origin.y+mockView.view.frame.origin.y+mockView.view.frame.size.height];
            NSDateFormatter *dateFormatter1 = [NSDateFormatter new];
            dateFormatter1.dateFormat = @"YYYY-MM-dd HH:mm";
            NSDateFormatter *dateFormatter2 = [NSDateFormatter new];
            dateFormatter2.dateFormat = @"HH:mm";
            mockView.time.text = [NSString stringWithFormat:@"%@ - %@",[dateFormatter1 stringFromDate:start], [dateFormatter2 stringFromDate:end]];
            
            mockView.message.text = orignItem.title;
            mockView.toLength.text = @"";
            [mockView updateConstraintsIfNeeded];
            mockView.center = CGPointMake(location.x, location.y);
            
            //scrolling
            CGRect rect = self.collectionView.bounds;
            // adjust rect for content inset as we will use it below for calculating scroll zones
            rect.size.height -= self.collectionView.contentInset.top;
            rect.size.width -= self.collectionView.contentInset.left;
            
            // tell us if we should scroll and which direction
            CGFloat scrollZoneHeight = rect.size.height / 6;
            CGFloat scrollZoneWidth = rect.size.width / 6;
            CGFloat bottomScrollBeginning = self.collectionView.contentOffset.y + self.collectionView.contentInset.top + rect.size.height - scrollZoneHeight;
            CGFloat topScrollBeginning = self.collectionView.contentOffset.y + self.collectionView.contentInset.top  + scrollZoneHeight;
            CGFloat leftScrollBeginning = self.collectionView.contentOffset.x + self.collectionView.contentInset.left  + scrollZoneWidth;
            CGFloat rightScrollBeginning = self.collectionView.contentOffset.x + self.collectionView.contentInset.left + rect.size.width - scrollZoneWidth;
            
            // we're in the bottom zone
            if (location.y >= bottomScrollBeginning) {
                self.scrollRateY = (location.y - bottomScrollBeginning) / scrollZoneHeight;
            }
            // we're in the top zone
            else if (location.y <= topScrollBeginning) {
                self.scrollRateY = (location.y - topScrollBeginning) / scrollZoneHeight;
            }
            else {
                self.scrollRateY = 0;
            }
            if (location.x >= rightScrollBeginning) {
                self.scrollRateX = (location.x - rightScrollBeginning) / scrollZoneWidth;
            }
            // we're in the left zone
            else if (location.x <= leftScrollBeginning) {
                self.scrollRateX = (location.x - leftScrollBeginning) / scrollZoneWidth;
            }
            else {
                self.scrollRateX = 0;
            }

            
        } break;
        case UIGestureRecognizerStateEnded:
        {
            [self.scrollingTimer invalidate];
            self.scrollingTimer = nil;
            self.scrollRateY = 0;
            self.scrollRateX = 0;
            self.saveTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(save) userInfo:nil repeats:YES];
            [[NSRunLoop mainRunLoop] addTimer:self.saveTimer forMode:NSDefaultRunLoopMode];
        } break;
        default: break;
    }
}


- (void)panToDragging:(UIPanGestureRecognizer *)gesture
{
    
    if(gesture.state == UIGestureRecognizerStateBegan)
    {
        [self.scrollingTimer invalidate];
        self.scrollingTimer = nil;
        self.scrollRateY = 0;
        self.scrollRateX = 0;
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObject:gesture forKey:@"gesture"];
        self.scrollingTimer = [NSTimer timerWithTimeInterval:1/8 target:self selector:@selector(scrollTableWithCell:) userInfo:userInfo repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:self.scrollingTimer forMode:NSDefaultRunLoopMode];
    }
    else if ((gesture.state == UIGestureRecognizerStateEnded) ||
        (gesture.state == UIGestureRecognizerStateChanged)) {
        if (gesture.state == UIGestureRecognizerStateChanged)
        {
            [self.saveTimer invalidate];
            
            CGPoint location = [gesture locationInView:self.collectionView];
            //scrolling
            CGRect rect = self.collectionView.bounds;
            // adjust rect for content inset as we will use it below for calculating scroll zones
            rect.size.height -= self.collectionView.contentInset.top;
            rect.size.width -= self.collectionView.contentInset.left;
            
            // tell us if we should scroll and which direction
            CGFloat scrollZoneHeight = rect.size.height / 6;
            CGFloat scrollZoneWidth = rect.size.width / 6;
            CGFloat bottomScrollBeginning = self.collectionView.contentOffset.y + self.collectionView.contentInset.top + rect.size.height - scrollZoneHeight;
            CGFloat topScrollBeginning = self.collectionView.contentOffset.y + self.collectionView.contentInset.top  + scrollZoneHeight;
            CGFloat leftScrollBeginning = self.collectionView.contentOffset.x + self.collectionView.contentInset.left  + scrollZoneWidth;
            CGFloat rightScrollBeginning = self.collectionView.contentOffset.x + self.collectionView.contentInset.left + rect.size.width - scrollZoneWidth;
            
            // we're in the bottom zone
            if (location.y >= bottomScrollBeginning) {
                self.scrollRateY = (location.y - bottomScrollBeginning) / scrollZoneHeight;
            }
            // we're in the top zone
            else if (location.y <= topScrollBeginning) {
                self.scrollRateY = (location.y - topScrollBeginning) / scrollZoneHeight;
            }
            else {
                self.scrollRateY = 0;
            }
            if (location.x >= rightScrollBeginning) {
                self.scrollRateX = (location.x - rightScrollBeginning) / scrollZoneWidth;
            }
            // we're in the left zone
            else if (location.x <= leftScrollBeginning) {
                self.scrollRateX = (location.x - leftScrollBeginning) / scrollZoneWidth;
            }
            else {
                self.scrollRateX = 0;
            }
             
        }
        else
        {
            [self.scrollingTimer invalidate];
            self.scrollingTimer = nil;
            self.scrollRateY = 0;
            self.scrollRateX = 0;
            self.saveTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(save) userInfo:nil repeats:YES];
            [[NSRunLoop mainRunLoop] addTimer:self.saveTimer forMode:NSDefaultRunLoopMode];
        }
        
        
        CGPoint location = [gesture locationInView:self.collectionView];
        NSDate * start =  [self.collectionViewLayout timeDateComponentsFloatX:(location.x-mockView.frame.size.width/2) FloatY: mockView.frame.origin.y+mockView.view.frame.origin.y];
        NSDate * end =  [self.collectionViewLayout timeDateComponentsFloatX:(location.x-mockView.frame.size.width/2) FloatY:mockView.frame.origin.y+mockView.view.frame.origin.y+mockView.view.frame.size.height];
        NSDateFormatter *dateFormatter1 = [NSDateFormatter new];
        dateFormatter1.dateFormat = @"YYYY-MM-dd HH:mm";
        NSDateFormatter *dateFormatter2 = [NSDateFormatter new];
        dateFormatter2.dateFormat = @"HH:mm";
        mockView.time.text = [NSString stringWithFormat:@"%@ - %@",[dateFormatter1 stringFromDate:start], [dateFormatter2 stringFromDate:end]];
        
        mockView.message.text = orignItem.title;
        mockView.toLength.text = @"";
        [mockView updateConstraintsIfNeeded];
        mockView.center = CGPointMake(location.x, location.y);
    }
    
    
    
}

- (void)panToResizeTop:(UIPanGestureRecognizer *)gesture
{
    
    if(gesture.state == UIGestureRecognizerStateBegan)
    {
        [self.scrollingTimer invalidate];
        self.scrollingTimer = nil;
        self.scrollRateY = 0;
        self.scrollRateX = 0;
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObject:gesture forKey:@"gesture"];
        self.scrollingTimer = [NSTimer timerWithTimeInterval:1/8 target:self selector:@selector(scrollTopTableWithCell:) userInfo:userInfo repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:self.scrollingTimer forMode:NSDefaultRunLoopMode];
    }
    else
    if ((gesture.state == UIGestureRecognizerStateEnded) ||
        (gesture.state == UIGestureRecognizerStateChanged)) {
        
        if (gesture.state == UIGestureRecognizerStateChanged)
        {
            mockView.toLength.hidden = NO;
            [self.saveTimer invalidate];
            CGPoint location = [gesture locationInView:self.collectionView];
            //scrolling
            CGRect rect = self.collectionView.bounds;
            // adjust rect for content inset as we will use it below for calculating scroll zones
            rect.size.height -= self.collectionView.contentInset.top;
            rect.size.width -= self.collectionView.contentInset.left;
            
            // tell us if we should scroll and which direction
            CGFloat scrollZoneHeight = rect.size.height / 6;
            CGFloat bottomScrollBeginning = self.collectionView.contentOffset.y + self.collectionView.contentInset.top + rect.size.height - scrollZoneHeight;
            CGFloat topScrollBeginning = self.collectionView.contentOffset.y + self.collectionView.contentInset.top  + scrollZoneHeight;
            
            // we're in the bottom zone
            if (location.y >= bottomScrollBeginning) {
                self.scrollRateY = (location.y - bottomScrollBeginning) / scrollZoneHeight;
            }
            // we're in the top zone
            else if (location.y <= topScrollBeginning) {
                self.scrollRateY = (location.y - topScrollBeginning) / scrollZoneHeight;
            }
            else
            {
                self.scrollRateY = 0;
            }
                self.scrollRateX = 0;
        }
        else
        {
            [self.scrollingTimer invalidate];
            self.scrollingTimer = nil;
            self.scrollRateY = 0;
            self.scrollRateX = 0;
            mockView.toLength.hidden = YES;
            self.saveTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(save) userInfo:nil repeats:YES];
            [[NSRunLoop mainRunLoop] addTimer:self.saveTimer forMode:NSDefaultRunLoopMode];
        }

        CGPoint location = [gesture locationInView:self.collectionView];
        NSDate * start =  [self.collectionViewLayout timeDateComponentsFloatX:mockView.frame.origin.x+(mockView.frame.size.width/2) FloatY: mockView.frame.origin.y+mockView.view.frame.origin.y];
        NSDate * end =  [self.collectionViewLayout timeDateComponentsFloatX:mockView.frame.origin.x+(mockView.frame.size.width/2) FloatY: mockView.frame.origin.y+mockView.view.frame.origin.y+mockView.view.frame.size.height];
        NSDateFormatter *dateFormatter1 = [NSDateFormatter new];
        dateFormatter1.dateFormat = @"YYYY-MM-dd HH:mm";
        NSDateFormatter *dateFormatter2 = [NSDateFormatter new];
        dateFormatter2.dateFormat = @"HH:mm";
        mockView.time.text = [NSString stringWithFormat:@"%@ - %@",[dateFormatter1 stringFromDate:start], [dateFormatter2 stringFromDate:end]];
        mockView.message.text = orignItem.title;
        int ToLength = [self.collectionViewLayout toLengthStartFloatY:mockView.frame.origin.y+mockView.view.frame.origin.y EndFloatY:mockView.frame.origin.y+mockView.view.frame.origin.y+mockView.view.frame.size.height];
        NSString * toTime;
        if ( ToLength < 60)      toTime = [NSString stringWithFormat:@"%d min",ToLength];
        else {
            int Hours = ToLength%60;
            if (Hours != 0 ) toTime = [NSString stringWithFormat:@"%d h %d min",ToLength/60, Hours];
            else             toTime = [NSString stringWithFormat:@"%d h",ToLength/60];
        }
        mockView.toLength.text = toTime;
        CGRect mockFrame = mockView.frame;
        CGFloat addY = location.y-mockFrame.origin.y;
        mockFrame.origin.y = mockFrame.origin.y + addY;
        mockFrame.size.height = mockFrame.size.height - addY;
        mockView.frame = mockFrame;
        [mockView updateConstraintsIfNeeded];
    }
}


- (void)panToResizeBottom:(UIPanGestureRecognizer *)gesture
{
    if(gesture.state == UIGestureRecognizerStateBegan)
    {
        [self.scrollingTimer invalidate];
        self.scrollingTimer = nil;
        self.scrollRateY = 0;
        self.scrollRateX = 0;
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObject:gesture forKey:@"gesture"];
        self.scrollingTimer = [NSTimer timerWithTimeInterval:1/8 target:self selector:@selector(scrollBottomTableWithCell:) userInfo:userInfo repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:self.scrollingTimer forMode:NSDefaultRunLoopMode];
    }
    else
    if ((gesture.state == UIGestureRecognizerStateEnded) ||
        (gesture.state == UIGestureRecognizerStateChanged)) {
        
        if (gesture.state == UIGestureRecognizerStateChanged)
        {
            mockView.toLength.hidden = NO;
            [self.saveTimer invalidate];
            CGPoint location = [gesture locationInView:self.collectionView];
            //scrolling
            CGRect rect = self.collectionView.bounds;
            // adjust rect for content inset as we will use it below for calculating scroll zones
            rect.size.height -= self.collectionView.contentInset.top;
            rect.size.width -= self.collectionView.contentInset.left;
            
            // tell us if we should scroll and which direction
            CGFloat scrollZoneHeight = rect.size.height / 6;
            CGFloat bottomScrollBeginning = self.collectionView.contentOffset.y + self.collectionView.contentInset.top + rect.size.height - scrollZoneHeight;
            CGFloat topScrollBeginning = self.collectionView.contentOffset.y + self.collectionView.contentInset.top  + scrollZoneHeight;
            
            // we're in the bottom zone
            if (location.y >= bottomScrollBeginning) {
                self.scrollRateY = (location.y - bottomScrollBeginning) / scrollZoneHeight;
            }
            // we're in the top zone
            else if (location.y <= topScrollBeginning) {
                self.scrollRateY = (location.y - topScrollBeginning) / scrollZoneHeight;
            }
            else
            {
                self.scrollRateY = 0;
            }
            self.scrollRateX = 0;
        }
        else
        {
            [self.scrollingTimer invalidate];
            self.scrollingTimer = nil;
            self.scrollRateY = 0;
            self.scrollRateX = 0;
            mockView.toLength.hidden = YES;
            self.saveTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(save) userInfo:nil repeats:YES];
            [[NSRunLoop mainRunLoop] addTimer:self.saveTimer forMode:NSDefaultRunLoopMode];
        }
        
        CGPoint location = [gesture locationInView:self.collectionView];
        NSDate * start =  [self.collectionViewLayout timeDateComponentsFloatX:mockView.frame.origin.x+(mockView.frame.size.width/2) FloatY: mockView.frame.origin.y+mockView.view.frame.origin.y];
        NSDate * end =  [self.collectionViewLayout timeDateComponentsFloatX:mockView.frame.origin.x+(mockView.frame.size.width/2) FloatY: mockView.frame.origin.y+mockView.view.frame.origin.y+mockView.view.frame.size.height];
        NSDateFormatter *dateFormatter1 = [NSDateFormatter new];
        dateFormatter1.dateFormat = @"YYYY-MM-dd HH:mm";
        NSDateFormatter *dateFormatter2 = [NSDateFormatter new];
        dateFormatter2.dateFormat = @"HH:mm";
        mockView.time.text = [NSString stringWithFormat:@"%@ - %@",[dateFormatter1 stringFromDate:start], [dateFormatter2 stringFromDate:end]];
        mockView.message.text = orignItem.title;
        int ToLength = [self.collectionViewLayout toLengthStartFloatY:mockView.frame.origin.y+mockView.view.frame.origin.y EndFloatY:mockView.frame.origin.y+mockView.view.frame.origin.y+mockView.view.frame.size.height];
        NSString * toTime;
        if ( ToLength < 60)      toTime = [NSString stringWithFormat:@"%d min",ToLength];
        else {
            int Hours = ToLength%60;
            if (Hours != 0 ) toTime = [NSString stringWithFormat:@"%d h %d min",ToLength/60, Hours];
            else             toTime = [NSString stringWithFormat:@"%d h",ToLength/60];
        }
        mockView.toLength.text = toTime;
        CGRect mockFrame = mockView.frame;
        CGFloat addY = location.y-(mockFrame.origin.y+mockFrame.size.height);
        //mockFrame.origin.y = mockFrame.origin.y + addY;
        mockFrame.size.height = mockFrame.size.height + addY;
        mockView.frame = mockFrame;
        [mockView updateConstraintsIfNeeded];
}
    
}




- (void)scrollTableWithCell:(NSTimer *)timer {
    UILongPressGestureRecognizer *gesture = [timer.userInfo objectForKey:@"gesture"];
    CGPoint location  = [gesture locationInView:self.collectionView];
    
    CGPoint currentOffset = self.collectionView.contentOffset;
    CGPoint newOffset = CGPointMake(currentOffset.x + self.scrollRateX, currentOffset.y + self.scrollRateY);
    if (newOffset.y < -self.collectionView.contentInset.top)
    {
        newOffset.y = -self.collectionView.contentInset.top;
    }
    else if (self.collectionView.contentSize.height < self.collectionView.frame.size.height)
    {
        newOffset = currentOffset;
    }
    else if (newOffset.y > self.collectionView.contentSize.height - self.collectionView.frame.size.height)
    {
        newOffset.y = self.collectionView.contentSize.height - self.collectionView.frame.size.height;
    }
    
    if (newOffset.x < -self.collectionView.contentInset.left)
    {
        newOffset.x = -self.collectionView.contentInset.left;
    }
    else if (self.collectionView.contentSize.width < self.collectionView.frame.size.width)
    {
        newOffset = currentOffset;
    }
    else if (newOffset.x > self.collectionView.contentSize.width - self.collectionView.frame.size.width)
    {
        newOffset.x = self.collectionView.contentSize.width - self.collectionView.frame.size.width;
    }
    
    [self.collectionView setContentOffset:newOffset];
    
    if (location.y >= 0 && location.y <= self.collectionView.contentSize.height + 50) {
        mockView.center = CGPointMake(location.x, location.y);
    }
    //[self updateCurrentLocation:gesture];
}

- (void)scrollTopTableWithCell:(NSTimer *)timer {
    UILongPressGestureRecognizer *gesture = [timer.userInfo objectForKey:@"gesture"];
    CGPoint location  = [gesture locationInView:self.collectionView];
    
    CGPoint currentOffset = self.collectionView.contentOffset;
    CGPoint newOffset = CGPointMake(currentOffset.x + self.scrollRateX, currentOffset.y + self.scrollRateY);
    if (newOffset.y < -self.collectionView.contentInset.top)
    {
        newOffset.y = -self.collectionView.contentInset.top;
    }
    else if (self.collectionView.contentSize.height < self.collectionView.frame.size.height)
    {
        newOffset = currentOffset;
    }
    else if (newOffset.y > self.collectionView.contentSize.height - self.collectionView.frame.size.height)
    {
        newOffset.y = self.collectionView.contentSize.height - self.collectionView.frame.size.height;
    }
    
    if (newOffset.x < -self.collectionView.contentInset.left)
    {
        newOffset.x = -self.collectionView.contentInset.left;
    }
    else if (self.collectionView.contentSize.width < self.collectionView.frame.size.width)
    {
        newOffset = currentOffset;
    }
    else if (newOffset.x > self.collectionView.contentSize.width - self.collectionView.frame.size.width)
    {
        newOffset.x = self.collectionView.contentSize.width - self.collectionView.frame.size.width;
    }
    
    [self.collectionView setContentOffset:newOffset];
    
    if (location.y >= 0 && location.y <= self.collectionView.contentSize.height + 50) {
        NSDate * start =  [self.collectionViewLayout timeDateComponentsFloatX:mockView.frame.origin.x+(mockView.frame.size.width/2) FloatY: mockView.frame.origin.y+mockView.view.frame.origin.y];
        NSDate * end =  [self.collectionViewLayout timeDateComponentsFloatX:mockView.frame.origin.x+(mockView.frame.size.width/2) FloatY: mockView.frame.origin.y+mockView.view.frame.origin.y+mockView.view.frame.size.height];
        NSDateFormatter *dateFormatter1 = [NSDateFormatter new];
        dateFormatter1.dateFormat = @"YYYY-MM-dd HH:mm";
        NSDateFormatter *dateFormatter2 = [NSDateFormatter new];
        dateFormatter2.dateFormat = @"HH:mm";
        mockView.time.text = [NSString stringWithFormat:@"%@ - %@",[dateFormatter1 stringFromDate:start], [dateFormatter2 stringFromDate:end]];
        mockView.message.text = orignItem.title;
        int ToLength = [self.collectionViewLayout toLengthStartFloatY:mockView.frame.origin.y+mockView.view.frame.origin.y EndFloatY:mockView.frame.origin.y+mockView.view.frame.origin.y+mockView.view.frame.size.height];
        NSString * toTime;
        if ( ToLength < 60)      toTime = [NSString stringWithFormat:@"%d min",ToLength];
        else {
            int Hours = ToLength%60;
            if (Hours != 0 ) toTime = [NSString stringWithFormat:@"%d h %d min",ToLength/60, Hours];
            else             toTime = [NSString stringWithFormat:@"%d h",ToLength/60];
        }
        mockView.toLength.text = toTime;
        CGRect mockFrame = mockView.frame;
        CGFloat addY = location.y-mockFrame.origin.y;
        mockFrame.origin.y = mockFrame.origin.y + addY;
        mockFrame.size.height = mockFrame.size.height - addY;
        mockView.frame = mockFrame;
        [mockView updateConstraintsIfNeeded];
    }
    //[self updateCurrentLocation:gesture];
}

- (void)scrollBottomTableWithCell:(NSTimer *)timer {
    UILongPressGestureRecognizer *gesture = [timer.userInfo objectForKey:@"gesture"];
    CGPoint location  = [gesture locationInView:self.collectionView];
    
    CGPoint currentOffset = self.collectionView.contentOffset;
    CGPoint newOffset = CGPointMake(currentOffset.x + self.scrollRateX, currentOffset.y + self.scrollRateY);
    if (newOffset.y < -self.collectionView.contentInset.top)
    {
        newOffset.y = -self.collectionView.contentInset.top;
    }
    else if (self.collectionView.contentSize.height < self.collectionView.frame.size.height)
    {
        newOffset = currentOffset;
    }
    else if (newOffset.y > self.collectionView.contentSize.height - self.collectionView.frame.size.height)
    {
        newOffset.y = self.collectionView.contentSize.height - self.collectionView.frame.size.height;
    }
    
    if (newOffset.x < -self.collectionView.contentInset.left)
    {
        newOffset.x = -self.collectionView.contentInset.left;
    }
    else if (self.collectionView.contentSize.width < self.collectionView.frame.size.width)
    {
        newOffset = currentOffset;
    }
    else if (newOffset.x > self.collectionView.contentSize.width - self.collectionView.frame.size.width)
    {
        newOffset.x = self.collectionView.contentSize.width - self.collectionView.frame.size.width;
    }
    
    [self.collectionView setContentOffset:newOffset];
    
    if (location.y >= 0 && location.y <= self.collectionView.contentSize.height + 50) {
        NSDate * start =  [self.collectionViewLayout timeDateComponentsFloatX:mockView.frame.origin.x+(mockView.frame.size.width/2) FloatY: mockView.frame.origin.y+mockView.view.frame.origin.y];
        NSDate * end =  [self.collectionViewLayout timeDateComponentsFloatX:mockView.frame.origin.x+(mockView.frame.size.width/2) FloatY: mockView.frame.origin.y+mockView.view.frame.origin.y+mockView.view.frame.size.height];
        NSDateFormatter *dateFormatter1 = [NSDateFormatter new];
        dateFormatter1.dateFormat = @"YYYY-MM-dd HH:mm";
        NSDateFormatter *dateFormatter2 = [NSDateFormatter new];
        dateFormatter2.dateFormat = @"HH:mm";
        mockView.time.text = [NSString stringWithFormat:@"%@ - %@",[dateFormatter1 stringFromDate:start], [dateFormatter2 stringFromDate:end]];
        mockView.message.text = orignItem.title;
        int ToLength = [self.collectionViewLayout toLengthStartFloatY:mockView.frame.origin.y+mockView.view.frame.origin.y EndFloatY:mockView.frame.origin.y+mockView.view.frame.origin.y+mockView.view.frame.size.height];
        NSString * toTime;
        if ( ToLength < 60)      toTime = [NSString stringWithFormat:@"%d min",ToLength];
        else {
            int Hours = ToLength%60;
            if (Hours != 0 ) toTime = [NSString stringWithFormat:@"%d h %d min",ToLength/60, Hours];
            else             toTime = [NSString stringWithFormat:@"%d h",ToLength/60];
        }
        mockView.toLength.text = toTime;
        CGRect mockFrame = mockView.frame;
        CGFloat addY = location.y-(mockFrame.origin.y+mockFrame.size.height);
        //mockFrame.origin.y = mockFrame.origin.y + addY;
        mockFrame.size.height = mockFrame.size.height + addY;
        mockView.frame = mockFrame;
        [mockView updateConstraintsIfNeeded];
    }
    //[self updateCurrentLocation:gesture];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    CGPoint contentOffset = scrollView.contentOffset;
    CGFloat contentOffsetX = contentOffset.x;
    CGFloat sectionWidth = (self.collectionViewLayout.sectionMargin.left + self.collectionViewLayout.sectionWidth + self.collectionViewLayout.sectionMargin.right);
    int section = lrintf(contentOffsetX/sectionWidth);
    contentOffsetX = sectionWidth * section;
    contentOffset.x = contentOffsetX;
    [self.collectionView setContentOffset:contentOffset animated:YES];
}

- (void)pan:(UIPanGestureRecognizer *)gesture {
    if (gesture.numberOfTouches > 0) {
        NSLog(@"pan");
        //перетягиваем нажатием
        CGRect monthFrame = self.monthCalendar.view.frame;
        monthFrame.origin.x = 0;
        monthFrame.origin.y = -self.collectionView.frame.size.height+ [gesture locationOfTouch:0 inView:self.collectionView].y;
        self.monthCalendar.view.frame = monthFrame;
    }
    else
    {
        CGRect monthFrame = self.monthCalendar.view.frame;
        if (monthFrame.origin.y< - self.collectionView.frame.size.height +self.collectionView.frame.size.height/2 )
        {
            monthFrame.origin.y = -self.collectionView.frame.size.height;
            [UIView animateWithDuration:1.0 animations:^{
                self.monthCalendar.view.frame = monthFrame;
            }];
        }
        else
        {
            monthFrame.origin.y = 0;
            [UIView animateWithDuration:1.0 animations:^{
                self.monthCalendar.view.frame = monthFrame;
            }];
        }

        
        

    }
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch{
    
    if([touch locationInView:self.collectionView].y < 50)
        return YES;
	return NO;
}
@end

/*
 - (void)longPress:(UILongPressGestureRecognizer *)gesture
 {
 switch (gesture.state) {
 case UIGestureRecognizerStateBegan:
 {
 if(!mockView)
 {
 [mockView removeFromSuperview];
 mockView = nil;
 }
 // измеение data source (тут надо сделать фетчу в коре дата)
 orignCell = (BNCalendarCell *)[gesture view];
 NSIndexPath *indexPath = [self.collectionView indexPathForCell:orignCell];
 
 CGRect tempFrame = orignCell.frame;
 tempFrame.size.width = self.collectionViewLayout.sectionWidth - self.collectionViewLayout.cellMargin.left - self.collectionViewLayout.cellMargin.right;
 mockView = [[BNCalendarDraggingView alloc] initWithFrame:tempFrame];
 
 
 NSArray * arr = self.dict[self.dictSection[indexPath.section]];
 BNCalendarItem * origItem = arr[indexPath.item];
 
 
 NSDateFormatter *dateFormatter1 = [NSDateFormatter new];
 dateFormatter1.dateFormat = @"YYYY-MM-dd HH:mm";
 NSDateFormatter *dateFormatter2 = [NSDateFormatter new];
 dateFormatter2.dateFormat = @"HH:mm";
 mockView.time.text = [NSString stringWithFormat:@"%@ - %@",[dateFormatter1 stringFromDate:origItem.start], [dateFormatter2 stringFromDate:origItem.end]];
 mockView.message.text = orignCell.message.text;
 
 
 int ToLength = [self.collectionViewLayout toLengthStartFloatY:mockView.frame.origin.y EndFloatY:mockView.frame.origin.y+mockView.frame.size.height];
 NSString * toTime;
 if ( ToLength < 60)      toTime = [NSString stringWithFormat:@"%d min",ToLength];
 else {
 int Hours = ToLength%60;
 if (Hours != 0 ) toTime = [NSString stringWithFormat:@"%d h %d min",ToLength/60, Hours];
 else             toTime = [NSString stringWithFormat:@"%d h",ToLength/60];
 }
 mockView.toLength.text = toTime;
 
 
 [mockView updateConstraintsIfNeeded];
 
 if( [orignCell.noteType intValue] == 0 )
 mockView.noteType = [NSNumber numberWithInt: 2];
 else
 {
 if([item.start compare:[NSDate date]] == NSOrderedAscending)
 {
 mockView.noteType = [NSNumber numberWithInt: 2];
 
 }
 else
 mockView.noteType = [NSNumber numberWithInt: 1];
 }
 // [mockView needsUpdateConstraints];
 
 [self.collectionView addSubview:mockView];
 [UIView
 animateWithDuration:0.3
 animations:^{
 mockView.transform = CGAffineTransformMakeScale(1.1f, 1.1f);
 }
 completion:^(BOOL finished)
 {
 mockView.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
 }];
 NSMutableArray * arrLast = [self.dict[self.dictSection[indexPath.section]] mutableCopy];
 if(!arrLast) arrLast = [NSMutableArray array];
 item = arrLast[indexPath.item];
 [arrLast removeObjectAtIndex: indexPath.item];
 [self.collectionViewLayout deleteLayoutAttributeItemsInSection:indexPath.section];
 [self.dict setObject: arrLast forKey:self.dictSection[indexPath.section]];
 [self.collectionView reloadData];
 [self.collectionViewLayout updateLayoutAttributeItemsInSection: indexPath.section];
 
 
 // enable scrolling for cell
 NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObject:gesture forKey:@"gesture"];
 self.scrollingTimer = [NSTimer timerWithTimeInterval:1/8 target:self selector:@selector(scrollTableWithCell:) userInfo:userInfo repeats:YES];
 [[NSRunLoop mainRunLoop] addTimer:self.scrollingTimer forMode:NSDefaultRunLoopMode];
 
 } break;
 // dragging
 case UIGestureRecognizerStateChanged:{
 CGPoint location = [gesture locationInView:self.collectionView];
 NSDate * start =  [self.collectionViewLayout timeDateComponentsFloatX:(location.x-mockView.frame.size.width/2) FloatY:(location.y-mockView.frame.size.height/2)];
 NSDate * end =  [self.collectionViewLayout timeDateComponentsFloatX:(location.x-mockView.frame.size.width/2) FloatY:(location.y+mockView.frame.size.height/2)];
 NSDateFormatter *dateFormatter1 = [NSDateFormatter new];
 dateFormatter1.dateFormat = @"YYYY-MM-dd HH:mm";
 NSDateFormatter *dateFormatter2 = [NSDateFormatter new];
 dateFormatter2.dateFormat = @"HH:mm";
 mockView.time.text = [NSString stringWithFormat:@"%@ - %@",[dateFormatter1 stringFromDate:start], [dateFormatter2 stringFromDate:end]];
 mockView.message.text = orignCell.message.text;
 int ToLength = [self.collectionViewLayout toLengthStartFloatY:mockView.frame.origin.y EndFloatY:mockView.frame.origin.y+mockView.frame.size.height];
 NSString * toTime;
 if ( ToLength < 60)      toTime = [NSString stringWithFormat:@"%d min",ToLength];
 else {
 int Hours = ToLength%60;
 if (Hours != 0 ) toTime = [NSString stringWithFormat:@"%d h %d min",ToLength/60, Hours];
 else             toTime = [NSString stringWithFormat:@"%d h",ToLength/60];
 }
 mockView.toLength.text = toTime;
 [mockView updateConstraintsIfNeeded];
 mockView.center = CGPointMake(location.x, location.y);
 
 //scrolling
 CGRect rect = self.collectionView.bounds;
 // adjust rect for content inset as we will use it below for calculating scroll zones
 rect.size.height -= self.collectionView.contentInset.top;
 rect.size.width -= self.collectionView.contentInset.left;
 
 // tell us if we should scroll and which direction
 CGFloat scrollZoneHeight = rect.size.height / 6;
 CGFloat scrollZoneWidth = rect.size.width / 6;
 CGFloat bottomScrollBeginning = self.collectionView.contentOffset.y + self.collectionView.contentInset.top + rect.size.height - scrollZoneHeight;
 CGFloat topScrollBeginning = self.collectionView.contentOffset.y + self.collectionView.contentInset.top  + scrollZoneHeight;
 CGFloat leftScrollBeginning = self.collectionView.contentOffset.x + self.collectionView.contentInset.left  + scrollZoneWidth;
 CGFloat rightScrollBeginning = self.collectionView.contentOffset.x + self.collectionView.contentInset.left + rect.size.width - scrollZoneWidth;
 
 // we're in the bottom zone
 if (location.y >= bottomScrollBeginning) {
 self.scrollRateY = (location.y - bottomScrollBeginning) / scrollZoneHeight;
 }
 // we're in the top zone
 else if (location.y <= topScrollBeginning) {
 self.scrollRateY = (location.y - topScrollBeginning) / scrollZoneHeight;
 }
 else {
 self.scrollRateY = 0;
 }
 if (location.x >= rightScrollBeginning) {
 self.scrollRateX = (location.x - rightScrollBeginning) / scrollZoneWidth;
 }
 // we're in the left zone
 else if (location.x <= leftScrollBeginning) {
 self.scrollRateX = (location.x - leftScrollBeginning) / scrollZoneWidth;
 }
 else {
 self.scrollRateX = 0;
 }
 
 } break;
 // dropped
 case UIGestureRecognizerStateEnded:
 {
 [self.scrollingTimer invalidate];
 self.scrollingTimer = nil;
 self.scrollRateY = 0;
 self.scrollRateX = 0;
 
 // NSIndexPath *indexPath = [self.collectionView indexPathForCell:orignCell];
 CGPoint location = [gesture locationInView:self.collectionView];
 NSDate * start =  [self.collectionViewLayout timeDateComponentsFloatX:(location.x-mockView.frame.size.width/2) FloatY:(location.y-mockView.frame.size.height/2)];
 NSDate * end =  [self.collectionViewLayout timeDateComponentsFloatX:(location.x-mockView.frame.size.width/2) FloatY:(location.y+mockView.frame.size.height/2)];
 NSDateFormatter *dateFormatter = [NSDateFormatter new];
 NSInteger section = [self.collectionViewLayout sectionToFloatX:(location.x-mockView.frame.size.width/2)];
 [mockView removeFromSuperview];
 mockView = nil;
 
 
 dateFormatter.dateFormat = @"YYYY-MM-dd";
 item.start = start;
 item.end = end;
 NSString * key = [dateFormatter stringFromDate:start];
 [self.collectionView reloadData];
 NSMutableArray * arrNew = [self.dict[key] mutableCopy];
 if(!arrNew) arrNew = [NSMutableArray array];
 [arrNew addObject: item];
 [self.collectionViewLayout deleteLayoutAttributeItemsInSection:section];
 [self.dict setObject: arrNew forKey:key];
 [self.collectionView reloadData];
 [self.collectionViewLayout updateLayoutAttributeItemsInSection:section];
 
 mockCell = nil;
 item = nil;
 }break;
 default: break;
 }
 
 }
 */