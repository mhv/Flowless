//
//  ViewController.m
//  FlowlessApp
//
//  Created by Mikhail Vroubel on 22/02/2015.
//  Copyright (c) 2015 my. All rights reserved.
//

#import "ViewController.h"
#import <Flowless/Flowless.h>

@interface ViewController ()
@property UIColor *bgColor;
@property UIColor *fgColor;
@property BOOL visible;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.bgColor = [UIColor yellowColor];
    self.fgColor = [UIColor purpleColor];
    self.visible = YES;
    [self toggleVisible];
    
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)toggleVisible {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.visible = !self.visible;
        [self toggleVisible];
    });
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
