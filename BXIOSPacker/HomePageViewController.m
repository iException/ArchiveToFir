//
//  HomePageViewController.m
//  BXIOSPacker
//
//  Created by Leppard on 7/21/15.
//  Copyright (c) 2015 Leppard. All rights reserved.
//

#import "HomePageViewController.h"
#import "CommandDefinition.h"
#import <AFNetworking.h>

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
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    //参数需要改回百姓
    NSDictionary *parameters = @{@"type":@"ios",
                                 @"bundle_id":@"edu.tac.PagedFlowView",
                                 @"api_token":[_labelToken stringValue]};
    
    __block typeof(self) tmpSelf = self;
    [manager POST:[self getCommandForOperationUpdateOrNewApp] parameters:parameters
          success:^(AFHTTPRequestOperation *operation, id resposeobject) {
              NSLog(@"get json: %@", resposeobject);
              [tmpSelf uploadIpaToFir:resposeobject];
          } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              NSLog(@"Error: %@", error);
          }];

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
        return @"http://api.fir.im/apps";
    }
    else {
        return [NSString stringWithFormat:
                @"http://api.fir.im/apps/%@/releases",
                [_labelAPPID stringValue]];
    
    }
}

- (void)uploadIpaToFir:(id)jsonFile {

    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:jsonFile options:NSJSONWritingPrettyPrinted error:&error];
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&error];
    NSDictionary *cert = [dic objectForKey:@"cert"];
    NSDictionary *binary = [cert objectForKey:@"binary"];
    NSURL *filePath = [NSURL URLWithString:[NSString stringWithFormat:
                                       @"%@/Desktop/Baixing.ipa",NSHomeDirectory()]];

    NSData *fileData = [NSData dataWithContentsOfFile:[filePath absoluteString]];
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSDictionary *parameters = @{@"key":[binary objectForKey:@"key"],
                                 @"token":[binary objectForKey:@"token"],
                                 @"x:name":@"百姓网官方版",
                                 @"x:version":@"1.1",
                                 @"x:build":@"1.1.1.1"
                                     };
    [manager POST:[binary objectForKey:@"upload_url"] parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        
        [formData appendPartWithFileData:fileData name:@"file" fileName:@"Baixing.ipa" mimeType:@"application/octet-stream"];
        
    }success:^(AFHTTPRequestOperation *operation, id resposeobject) {
        NSLog(@"%@", resposeobject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];

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
