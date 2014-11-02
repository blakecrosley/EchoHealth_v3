//
//  ECHOHistoryDetailTVC.m
//  EchoHealth
//
//  Created by Blake Crosley on 11/2/14.
//  Copyright (c) 2014 Blake Crosley. All rights reserved.
//

@import CoreMotion;

#import "ECHOHistoryDetailTVC.h"
#import "AAPLMotionActivityQuery.h"
#import "AAPLActivityDataManager.h"

@interface ECHOHistoryDetailTVC ()
- (void)configureView;
@end

@implementation ECHOHistoryDetailTVC
{
    AAPLActivityDataManager *_activityDataManager;
    NSDateFormatter *_dateFormatter;
    NSString *_currentActivity;
    NSInteger _currentSteps;
}
#pragma mark - Managing the detail item

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setDateFormat:[NSDateFormatter dateFormatFromTemplate:@"HH:mm" options:0
                                                                       locale:[NSLocale currentLocale]]];
        _activityDataManager = [[AAPLActivityDataManager alloc] init];
    }
    
    return self;
}

- (void)setDetailItem:(id)newDetailItem
{
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        
        // Update the view.
        [self configureView];
        
        // Load data
        _currentSteps = 0;
        _currentActivity = @"n/a";
        [_activityDataManager stopStepUpdates];
        [_activityDataManager stopMotionUpdates];
        [_activityDataManager queryAsync:(AAPLMotionActivityQuery *)_detailItem withCompletionHandler:^{
            [self.tableView reloadData];
            if ([(AAPLMotionActivityQuery *)_detailItem isToday]) {
                [_activityDataManager startStepUpdates:^(NSNumber *stepCount) {
                    _currentSteps = [stepCount integerValue];
                    NSArray *indexPaths = @[[NSIndexPath indexPathForRow:0 inSection:1]];
                    [self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
                }];
                [_activityDataManager startMotionUpdates:^(AAPLActivityType type) {
                    _currentActivity = [AAPLActivityDataManager activityTypeToString:type];
                    NSArray *indexPaths = @[[NSIndexPath indexPathForRow:4 inSection:0]];
                    [self.tableView reloadRowsAtIndexPaths:indexPaths
                                          withRowAnimation:UITableViewRowAnimationNone];
                }];
            }
        }];
    };
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.sectionHeaderHeight = 60;
    self.tableView.sectionFooterHeight = 60;
    // Do any additional setup after loading the view, typically from a nib.
    [self configureView];
}

- (void)configureView
{
    // Update the user interface for the detail item.
    if (self.detailItem) {
        self.title = [self.detailItem description];
    }
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return [(AAPLMotionActivityQuery *)_detailItem isToday] ? 5 : 4;
    } else if (section == 1) {
        return 1;
    } else if (section == 2){
        return _activityDataManager.significantActivitiesAndSteps.count;
    } else {
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"Walking";
            cell.detailTextLabel.text = [AAPLDetailViewController formatTimeInterval:_activityDataManager.walkingDuration];
        } else if (indexPath.row == 1) {
            cell.textLabel.text = @"Running";
            cell.detailTextLabel.text = [AAPLDetailViewController formatTimeInterval:_activityDataManager.runningDuration];
        } else if (indexPath.row == 2) {
            cell.textLabel.text = @"Driving";
            cell.detailTextLabel.text = [AAPLDetailViewController formatTimeInterval:_activityDataManager.vehicularDuration];
        } else if (indexPath.row == 3) {
            cell.textLabel.text = @"Moving";
            cell.detailTextLabel.text = [AAPLDetailViewController formatTimeInterval:_activityDataManager.movingDuration];
        } else if (indexPath.row == 4) {
            cell.textLabel.text = @"Current activity";
            cell.detailTextLabel.text = _currentActivity;
        }
    } else if (indexPath.section == 1) {
        cell.textLabel.text = [(AAPLMotionActivityQuery *)_detailItem isToday] ? @"Live Step Counts" : @"Step Counts";
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%ld",
                                     [_activityDataManager.stepCounts longValue] + _currentSteps];
    } else if (indexPath.section == 2) {
        
        AAPLSignificantActivity *activity = _activityDataManager.significantActivitiesAndSteps[indexPath.row];
        cell.textLabel.text = [NSString stringWithFormat:@"%@ (%@ - %@)",
                               [AAPLActivityDataManager activityTypeToString:activity.activityType],
                               [_dateFormatter stringFromDate:activity.startDate],
                               [_dateFormatter stringFromDate:activity.endDate]];
        if (activity.activityType == ActivityTypeWalking || activity.activityType == ActivityTypeRunning) {
            cell.detailTextLabel.text = [activity.stepCounts description];
        }
        else {
            cell.detailTextLabel.text = @"n/a";
        }
    }
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return @"Activity";
        case 1:
            return @"Pedometer";
        case 2:
            return @"Filtered History";
    }
    return @"";
}

+ (NSString *)formatTimeInterval:(NSTimeInterval)interval
{
    return [NSString stringWithFormat:@"%2uh %2um",
            (int)(interval / 3600),
            (int)(interval / 60) % 60];
}
@end
