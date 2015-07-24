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
@property (weak) IBOutlet NSButton *btnUpload;

@property (weak) IBOutlet NSTextField *labelAPPID;
@property (weak) IBOutlet NSTextField *labelToken;

@end

@implementation HomePageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [_labelAPPID setDelegate:self];
    [_labelToken setDelegate:self];

    [self checkIdAndTokenStatus];

    if([[_labelToken stringValue] length] != 0) {
        _btnUpload.enabled = YES;
    
    }
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
    
    [self callShellWithCommand:commandCallAndPack];
    
    
    
    [self presentViewControllerAsModalWindow:vc];
}

- (IBAction)uploadProjectBtnPressed:(id)sender {
    
    NSString *commandUpdateToFir = [NSString stringWithFormat:get_upload_info,
                                    [_labelToken stringValue],
                                    [self getCommandForOperationUpdateOrNewApp]];
    [self callShellWithCommand:commandUpdateToFir];
    NSLog(@"%@",_processInfo);
}


#pragma mark - Call Shell Methods

- (void)callShellWithCommand:(NSString *)commandToRun {
    
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/bin/zsh"];
    
    NSMutableArray *commandCollection = [NSMutableArray arrayWithObject:@"-c"];
    [commandCollection addObject:commandToRun];
    
    [task setArguments:commandCollection];
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


#pragma mark - Common Methods

-(void)checkIdAndTokenStatus {
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *appID = [defaults stringForKey:@"APPID"];
    NSString *appToken = [defaults stringForKey:@"APPTOKEN"];
    
    if ([appID length] != 0) {
        [_labelAPPID setStringValue:appID];
    }
    if ([appToken length] != 0) {
        [_labelToken setStringValue:appToken];
    }
    
    return;
}

-(NSString *)getCommandForOperationUpdateOrNewApp {
    
    if ([[_labelAPPID stringValue] length] == 0) {
        return url_new_upload;
    }
    else {
        return [NSString stringWithFormat:url_update,[_labelAPPID stringValue]];
    
    }
}


#pragma mark - Delegate Methods

-(void)controlTextDidEndEditing:(NSNotification *)obj {
    
    if ([obj object] == _labelAPPID) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:[_labelAPPID stringValue] forKey:@"APPID"];
  
    }
    
    if ([obj object] == _labelToken) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:[_labelToken stringValue] forKey:@"APPTOKEN"];

    }

}


- (void)passLogInfoToProcessLabel:(NSTextView *)processInfo {
    [processInfo setString:_processInfo];
    
}
@end
