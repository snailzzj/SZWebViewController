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
    [super viewDidLoad];
    
    [self setTitleColor:[UIColor blackColor]];
    [self setBackBtnTintColor:[UIColor blackColor]];
    
    _navButtonArray = [NSMutableArray array];
    _navButtonFuncDict = [NSMutableDictionary dictionary];
    
    __weak typeof(self) ws = self;
    
    [self setJavascriptObjectProperty:@"setTitle" handle:^(id obj) {
        ws.title = obj;
    }];
    
    [self setJavascriptObjectProperty:@"hideNav" handle:^(id obj) {
        [ws.navigationController setNavigationBarHidden:YES animated:YES];
    }];
    
    [self setJavascriptObjectProperty:@"showNav" handle:^(id obj) {
        [ws.navigationController setNavigationBarHidden:NO animated:NO];
    }];
    
    [self setJavascriptObjectProperty:@"testFunc" handle:^(id obj) {
        NSLog(@"a = %@", obj);
        [ws callFunction:obj withArgs:nil];
    }];
    
    [self setJavascriptObjectProperty:@"addNavRightTextButton" handle:^(id obj) {
        
        __strong typeof(ws) ss = ws;
        static NSInteger tagCount = 1;
        
        UIBarButtonItem *btn = [[UIBarButtonItem alloc]initWithTitle:[obj firstObject]  style:UIBarButtonItemStylePlain target:ws action:@selector(onAddNavButton:)];
        btn.tag = tagCount;
        [ss->_navButtonArray addObject:btn];
        ws.navigationItem.rightBarButtonItems = ss->_navButtonArray;
        
        [ss->_navButtonFuncDict setObject:[obj lastObject] forKey:@(btn.tag).stringValue];
        
        tagCount++;
    }];
    
    [self setJavascriptObjectProperty:@"addNavRightImageButton" handle:^(id obj) {
        
        __strong typeof(ws) ss = ws;
        static NSInteger tagCount = 1000;
        
        UIBarButtonItem *btn = [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:[obj firstObject]] style:UIBarButtonItemStylePlain target:ws action:@selector(onAddNavButton:)];
        btn.tag = tagCount;
        [ss->_navButtonArray addObject:btn];
        ws.navigationItem.rightBarButtonItems = ss->_navButtonArray;
        
        [ss->_navButtonFuncDict setObject:[obj lastObject] forKey:@(btn.tag).stringValue];
        
        tagCount++;
    }];
}

#pragma mark - Private


#pragma mark - Event

- (void)onAddNavButton:(UIBarButtonItem *)barBtn
{
    NSString *funcName = [_navButtonFuncDict objectForKey:@(barBtn.tag).stringValue];
    [self callFunction:funcName withArgs:nil];
}

@end
