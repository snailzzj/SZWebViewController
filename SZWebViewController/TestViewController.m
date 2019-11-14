//
//  TestViewController.m
//  SZWebViewController
//
//  Created by zzj on 2017/3/22.
//  Copyright © 2017年 snailzzj. All rights reserved.
//

#import "TestViewController.h"

@interface TestViewController ()

@end

@implementation TestViewController
{
    NSMutableArray *_navButtonArray;
    NSMutableDictionary *_navButtonFuncDict;
}

#pragma mark - VC Life Cycle

- (void)viewDidLoad
{
    [self registMethod:@"push" useCallback:YES handle:^(NSArray *params) {
        NSLog(@"%@", params);
        [self callJavascriptCallbacks:@"push" withParams:@[@"1", @"2", @"3"]];
    }];
    
    [super viewDidLoad];
}

#pragma mark - Private


#pragma mark - Event

- (void)onAddNavButton:(UIBarButtonItem *)barBtn
{
//    NSString *funcName = [_navButtonFuncDict objectForKey:@(barBtn.tag).stringValue];
//    [self callFunction:funcName withArgs:nil];
}

@end
