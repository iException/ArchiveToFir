//
//  HomePageViewController.m
//  BXIOSPacker
//
//  Created by Leppard on 7/21/15.
//  Copyright (c) 2015 Leppard. All rights reserved.
//

#import "HomePageViewController.h"
#import "CommandDefinition.h"

@interface HomePageViewController ()
@property (nonatomic) NSString *fileUrl;
@property (nonatomic) NSString *processInfo;
@property (weak) IBOutlet NSButton *btnPack;

@end

@implementation HomePageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}


#pragma mark - Delegate Implementation

- (void)passLogInfoToProcessLabel:(NSTextView *)processInfo {
    [processInfo setString:_processInfo];
    
}


#pragma mark - Btn Actions

- (IBAction)filePathSelectBtnPressed:(id)sender {
    
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setPrompt:@"Choose"];
    [panel setDirectoryURL:[NSURL fileURLWithPath:@"/Users/"]];
    [panel setCanChooseFiles:YES];
    [panel setCanChooseDirectories:YES];
    [panel beginSheetModalForWindow:self.view.window completionHandler:(^(NSInteger result){
        if(result == NSModalResponseOK){
            
            _fileUrl = [[panel URL] path];
            [self.filePath setStringValue:_fileUrl];
            
            _btnPack.enabled = YES;
        }
    })];
}
- (IBAction)packProjectBtnPressed:(id)sender {

    ProcessInfoViewController *vc =  [self.storyboard instantiateControllerWithIdentifier:@"ProcessInfoVC"];
    vc.delegate = self;
    
    NSDateFormatter *todayFormatter = [[NSDateFormatter alloc]init];
    [todayFormatter setDateFormat:@"YYYY-MM-dd"];
    NSString *today = [todayFormatter stringFromDate:[NSDate date]];
    
    NSString *commandCallArchiveWithDate = [NSString stringWithFormat:call_archive,today];
    //Pack to desktop 
    NSString *commandPackProjectWithDate = [NSString stringWithFormat:pack_to_ipa,NSHomeDirectory(),today,NSHomeDirectory()];

    NSString *commandCallAndPack = [[commandCallArchiveWithDate stringByAppendingString:@" && "] stringByAppendingString:commandPackProjectWithDate];

    NSMutableArray *commandToRun = [NSMutableArray arrayWithObjects:
                                    commandCallAndPack,
                                    nil];
    
    [self callShellWithCommand:commandToRun];
    
    [self presentViewControllerAsModalWindow:vc];
}

- (IBAction)uploadProjectBtnPressed:(id)sender {
    
    
    }


#pragma mark - Call Shell Methods

- (void)callShellWithCommand:(NSMutableArray *)commandToRun {
    
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/bin/zsh"];
    
    [commandToRun insertObject:@"-c" atIndex:0];
    
    [task setArguments:commandToRun];
    [task setCurrentDirectoryPath:_fileUrl];
    NSLog(@"run command:%@", commandToRun);
    
    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput:pipe];
    NSFileHandle *file = [pipe fileHandleForReading];
    
    [task launch];
    
    //Shell command output logs
    NSData *data = [file readDataToEndOfFile];
    _processInfo = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
}
@end
