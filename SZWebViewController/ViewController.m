//
//  ViewController.m
//  SZWebViewController
//
//  Created by zzj on 2016/12/1.
//  Copyright © 2016年 snailzzj. All rights reserved.
//

#import "ViewController.h"

#import "SZWebViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    [btn setTitle:@"SZWebViewController" forState:UIControlStateNormal];
    [btn setFrame:CGRectMake(10, 100, 300, 30)];
    [btn addTarget:self action:@selector(onClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:btn];
}


- (void)onClicked:(UIButton *)button
{
    SZWebViewController *web = [[SZWebViewController alloc]initWithURL:@"http://www.baidu.com"];
    [self.navigationController pushViewController:web animated:YES];
}


@end
