//
//  ProcessInfoViewController.m
//  BXIOSPacker
//
//  Created by Leppard on 7/21/15.
//  Copyright (c) 2015 Leppard. All rights reserved.
//

#import "ProcessInfoViewController.h"

@interface ProcessInfoViewController ()
@property (weak) IBOutlet NSTextField *labelProcessTitle;

@end

@implementation ProcessInfoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSTextView *textContent = [self.processInfo documentView];
    
    NSViewController *vc = (NSViewController *)self.delegate;
    //If user push Pack button
    if ([vc.identifier  isEqual: @"PackVC"]) {
        [textContent setString:[self.delegate packArchiveToIpaAndReturnInfo]];
    }
    //If user push Upload button
    else if ([vc.identifier isEqualToString:@"UploadVC"]) {
        [self.delegate postRequestToFirAndUploadThenReturnInfoToField:self.processInfo];
    }
}

@end
