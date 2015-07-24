//
//  HomePageViewController.h
//  BXIOSPacker
//
//  Created by Leppard on 7/21/15.
//  Copyright (c) 2015 Leppard. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ProcessInfoViewController.h"

@interface HomePageViewController : NSViewController<LogInfoTransitionDelegate>

@property (weak) IBOutlet NSTextField *filePath;

- (IBAction)filePathSelectBtnPressed:(id)sender;
- (IBAction)packProjectBtnPressed:(id)sender;
- (IBAction)uploadProjectBtnPressed:(id)sender;

@end
