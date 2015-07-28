//
//  ProcessInfoViewController.h
//  BXIOSPacker
//
//  Created by Leppard on 7/21/15.
//  Copyright (c) 2015 Leppard. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol LogInfoTransitionDelegate

-(NSString *)packArchiveToIpaAndReturnInfo;
- (void)postRequestToFirAndUploadThenReturnInfoToField:(NSScrollView *)processInfo;

@end

@interface ProcessInfoViewController : NSViewController

@property (nonatomic) id <LogInfoTransitionDelegate> delegate;

@property (weak) IBOutlet NSScrollView *processInfo;

@end
