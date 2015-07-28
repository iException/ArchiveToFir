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
@property (nonatomic) NSString *packProcessInfo;
@property (nonatomic) NSString *uploadProcessInfo;
@property (weak) IBOutlet NSButton *btnPack;
@property (weak) IBOutlet NSButton *btnUpload;

@property (weak) IBOutlet NSTextField *labelAPPID;
@property (weak) IBOutlet NSTextField *labelToken;
@property (weak) IBOutlet NSTextField *labelVision;
@property (weak) IBOutlet NSTextField *labelBuild;

@end

@implementation HomePageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _uploadProcessInfo = @"Waiting...\n";
    
    //Add label delegate to detect didFinishEditing
    [_labelAPPID setDelegate:self];
    [_labelToken setDelegate:self];
    [_labelVision setDelegate:self];
    [_labelBuild setDelegate:self];
    
    [self checkIdAndTokenStatus];

}


#pragma mark - Btn Actions

- (IBAction)filePathSelectBtnPressed:(id)sender {
    
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setPrompt:@"Choose"];
    //Set default filePath
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
    
    self.identifier = @"PackVC";
    ProcessInfoViewController *vc =  [self.storyboard instantiateControllerWithIdentifier:@"ProcessInfoVC"];
    vc.delegate = self;
    
    [self presentViewControllerAsModalWindow:vc];
}

- (IBAction)uploadProjectBtnPressed:(id)sender {
    
    self.identifier = @"UploadVC";
    ProcessInfoViewController *vc =  [self.storyboard instantiateControllerWithIdentifier:@"ProcessInfoVC"];
    vc.delegate = self;
    
    [self presentViewControllerAsModalWindow:vc];

}




#pragma mark - Call Shell Methods

- (void)callShellWithCommand:(NSString *)commandToRun {
    
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/bin/zsh"];
    
    //Use -c to directly run command
    NSMutableArray *commandCollection = [NSMutableArray arrayWithObject:@"-c"];
    [commandCollection addObject:commandToRun];
    
    [task setArguments:commandCollection];
    
    if(0 == [[self.filePath stringValue] length]) {
        _fileUrl = [NSString stringWithFormat:@"%@/",NSHomeDirectory()];
    }
    
    [task setCurrentDirectoryPath:_fileUrl];
    NSLog(@"run command:%@", commandToRun);
    
    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput:pipe];
    NSFileHandle *file = [pipe fileHandleForReading];
    
    [task launch];
    
    //Shell command output logs
    NSData *data = [file readDataToEndOfFile];
    
    _packProcessInfo = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
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
    
    //User push a new app and does not have a appID
    if ([[_labelAPPID stringValue] length] == 0) {
        return @"http://api.fir.im/apps";
    }
    //User release a new vision
    else {
        return [NSString stringWithFormat:
                @"http://api.fir.im/apps/%@/releases",
                [_labelAPPID stringValue]];
    
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
        if([[_labelToken stringValue] length] != 0) {
            _btnUpload.enabled = YES;
            
        }
    }
    if ([[_labelVision stringValue] length] != 0 &&
        [[_labelBuild stringValue] length] != 0 &&
        [[_labelToken stringValue] length] != 0) {
        
        _btnUpload.enabled = YES;

    }

}


-(NSString *)packArchiveToIpaAndReturnInfo {
    
    NSDateFormatter *todayFormatter = [[NSDateFormatter alloc]init];
    [todayFormatter setDateFormat:@"YYYY-MM-dd"];
    NSString *today = [todayFormatter stringFromDate:[NSDate date]];
    
    //Call the Archive of Baixing.xcodeproj
    NSString *commandCallArchiveWithDate = [NSString stringWithFormat:call_archive,today];
    //Pack to desktop
    NSString *commandPackProjectWithDate = [NSString stringWithFormat:pack_to_ipa,NSHomeDirectory(),today,NSHomeDirectory()];
    
    NSString *commandCallAndPack = [[commandCallArchiveWithDate stringByAppendingString:@" && "] stringByAppendingString:commandPackProjectWithDate];
    [self callShellWithCommand:commandCallAndPack];
    
    return _packProcessInfo;
}


- (void)postRequestToFirAndUploadThenReturnInfoToField:(NSScrollView *)processInfo {
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    NSDictionary *parameters = @{@"type":@"ios",
                                 @"bundle_id":@"com.baixing.iosbaixing",
                                 @"api_token":[_labelToken stringValue]};
    
    __block typeof(self) tmpSelf = self;
    [manager POST:[self getCommandForOperationUpdateOrNewApp] parameters:parameters
          success:^(AFHTTPRequestOperation *operation, id resposeobject) {
              NSLog(@"get json: %@", resposeobject);
              [tmpSelf uploadIpaToFirWithJson:resposeobject andReturnInfo:processInfo];
              
              NSTextView *textContent = [processInfo documentView];
              [textContent setString:_uploadProcessInfo];
              
          } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              NSLog(@"Error: %@", error);
          }];
}

- (void)uploadIpaToFirWithJson:(id)jsonFile andReturnInfo:(NSScrollView *)processInfo {
    
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:jsonFile options:NSJSONWritingPrettyPrinted error:&error];
    _uploadProcessInfo = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    
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
                                 @"x:version":[_labelVision stringValue],
                                 @"x:build":[_labelBuild stringValue]
                                 };
    
    [manager POST:[binary objectForKey:@"upload_url"] parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        
        [formData appendPartWithFileData:fileData name:@"file" fileName:@"Baixing.ipa" mimeType:@"application/octet-stream"];
        
    }success:^(AFHTTPRequestOperation *operation, id resposeobject) {
        NSLog(@"%@", resposeobject);
        NSError *error = nil;
        NSData *completionData = [NSJSONSerialization dataWithJSONObject:resposeobject options:NSJSONWritingPrettyPrinted error:&error];
        _uploadProcessInfo = [_uploadProcessInfo stringByAppendingString:
                                                    [[NSString alloc] initWithData:completionData
                                                                          encoding:NSUTF8StringEncoding]];
        NSTextView *textContent = [processInfo documentView];
        [textContent setString:_uploadProcessInfo];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        
        //具体Error输出需要修改
        _uploadProcessInfo = [_uploadProcessInfo stringByAppendingString:@"\nError"];
    }];

}

@end
