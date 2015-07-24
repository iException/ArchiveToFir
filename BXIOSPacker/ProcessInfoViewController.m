//
//  ProcessInfoViewController.m
//  BXIOSPacker
//
//  Created by Leppard on 7/21/15.
//  Copyright (c) 2015 Leppard. All rights reserved.
//

#import "ProcessInfoViewController.h"

@interface ProcessInfoViewController ()

@end

@implementation ProcessInfoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSTextView *textContent = [self.processInfo documentView];
    [self.delegate passLogInfoToProcessLabel:textContent];
}

@end
