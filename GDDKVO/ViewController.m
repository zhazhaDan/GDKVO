//
//  ViewController.m
//  GDDKVO
//
//  Created by 龚丹丹 on 2018/5/29.
//  Copyright © 2018年 龚丹丹. All rights reserved.
//

#import "ViewController.h"
#import "NSObject+GDKVO.h"
//#import <objc/runtime.h>

@interface ViewController ()
    @property (nonatomic, strong)NSString * name;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self buildUI];
//    [self testRuntime];
    // Do any additional setup after loading the view, typically from a nib.
}
    
    @synthesize name = _name;

- (void)setName:(NSString *)name {
    if (_name != name) {
        _name = name;
    }
}
    
- (NSString *)name {
    return _name;
}
    
- (void)buildUI {
    UIButton * button = [[UIButton alloc]initWithFrame:CGRectMake(100, 100, 100, 50)];
    [button setBackgroundColor:UIColor.blueColor];
    [button setTitle:@"增加监听" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(addObserver) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    
    UIButton * button2 = [[UIButton alloc]initWithFrame:CGRectMake(100, 200, 100, 50)];
    [button2 setBackgroundColor:UIColor.blueColor];
    [button2 setTitle:@"移除监听" forState:UIControlStateNormal];
    [button2 addTarget:self action:@selector(removeObserver) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button2];
}

    
- (void)addObserver {
    self.name = @"hello";
    [self GD_addObserver:self forKey:NSStringFromSelector(@selector(name)) withBlock:^(id observedObject, NSString *observedKey, id oldValue, id newValue) {
        if ([observedKey isEqualToString:@"name"]) {
            NSLog(@"oldvalue is %@, new value is %@",oldValue,newValue);
        }
    }];
    self.name = @"world";
}
    
- (void)removeObserver {
    [self GD_removeObserver:self forKey:@"name"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
