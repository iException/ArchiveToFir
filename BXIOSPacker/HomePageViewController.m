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

@property (nonatomic, strong)NSView *WaitingIndicator;

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
            
            //If and only if you select filepath you can pack your project
            _btnPack.enabled = YES;
        }
    })];
}

- (IBAction)packProjectBtnPressed:(id)sender {
    
//    self.identifier = @"PackVC";
//    ProcessInfoViewController *vc =  [self.storyboard instantiateControllerWithIdentifier:@"ProcessInfoVC"];
//    vc.delegate = self;
    
    // Waiting alert with ProgressIndicator
    NSAlert *alertSheet = [[NSAlert alloc]init];
    [alertSheet setMessageText:@"Please waiting for uploading..."];
    NSView *backView = [[NSView alloc]initWithFrame:NSRectFromCGRect(CGRectMake(0, 0, 150, 100))];
    
    NSProgressIndicator *indicator = [[NSProgressIndicator alloc]initWithFrame:NSRectFromCGRect(CGRectMake(50,0 , 100, 100))];
    indicator.style = NSProgressIndicatorSpinningStyle;
    [backView addSubview:indicator];
    [indicator startAnimation:alertSheet];
    [alertSheet setAccessoryView:backView];
    [alertSheet addButtonWithTitle:@"OK"];
    NSButton *confirm = [alertSheet.buttons objectAtIndex:0];
    confirm.enabled = NO;
    
    [alertSheet beginSheetModalForWindow:self.view.window completionHandler:nil];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        [self packArchiveToIpaAndReturnInfo];
        // Complete then update UI
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [backView removeFromSuperview];
            [alertSheet setInformativeText:@"SUCCEEDED, to find your IPA file on DESKTOP."];
            [alertSheet setMessageText:@"Pack succeeded!"];
            confirm.enabled = YES;
        });
    });
}

- (IBAction)uploadProjectBtnPressed:(id)sender {
    
//    self.identifier = @"UploadVC";
//    ProcessInfoViewController *vc =  [self.storyboard instantiateControllerWithIdentifier:@"ProcessInfoVC"];
//    vc.delegate = self;
//    
//    [self presentViewControllerAsModalWindow:vc];
    
    NSAlert *alertSheet = [[NSAlert alloc]init];
    [alertSheet setMessageText:@"Please waiting for processing..."];
    NSView *backView = [[NSView alloc]initWithFrame:NSRectFromCGRect(CGRectMake(0, 0, 150, 100))];
    
    NSProgressIndicator *indicator = [[NSProgressIndicator alloc]initWithFrame:NSRectFromCGRect(CGRectMake(50,0 , 100, 100))];
    indicator.style = NSProgressIndicatorSpinningStyle;
    [backView addSubview:indicator];
    [indicator startAnimation:alertSheet];
    [alertSheet setAccessoryView:backView];
    [alertSheet addButtonWithTitle:@"OK"];
    NSButton *confirm = [alertSheet.buttons objectAtIndex:0];
    confirm.enabled = NO;
    
    [alertSheet beginSheetModalForWindow:self.view.window completionHandler:nil];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self postRequestToFirAndUploadWhenSuccess: ^{
            // Complete then update UI
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                [backView removeFromSuperview];
                [alertSheet setInformativeText:@"SUCCEEDED, to download your app on Fir.im."];
                [alertSheet setMessageText:@"Upload succeeded!"];
                confirm.enabled = YES;
            });
        
        }];
        // Complete then update UI
    });


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
    
    //Set default ID and Token for user which enterd before
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
    
    //label finished editing
    if ([obj object] == _labelAPPID) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        //store info for user
        [defaults setObject:[_labelAPPID stringValue] forKey:@"APPID"];
  
    }
    
    if ([obj object] == _labelToken) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:[_labelToken stringValue] forKey:@"APPTOKEN"];
        
    }
    //If and only if you enter Token, Vision and Build you can upload
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
    NSString *commandPackProjectWithDate = [NSString stringWithFormat:export_ipa,today, NSHomeDirectory()];
    
    NSString *commandCallAndPack = [[commandCallArchiveWithDate stringByAppendingString:@" && "] stringByAppendingString:commandPackProjectWithDate];
    [self callShellWithCommand:commandCallAndPack];
    
    return _packProcessInfo;
}


- (void)postRequestToFirAndUploadWhenSuccess:(void (^)(void))success {
    
    //Post request to Fir.im and get KEY and TOKEN for upload
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    NSDictionary *parameters = @{@"type":@"ios",
                                 @"bundle_id":@"com.baixing.iosbaixing",
                                 @"api_token":[_labelToken stringValue]};
    
    __block typeof(self) tmpSelf = self;
    [manager POST:[self getCommandForOperationUpdateOrNewApp] parameters:parameters
          success:^(AFHTTPRequestOperation *operation, id resposeobject) {
              NSLog(@"get json: %@", resposeobject);
              [tmpSelf uploadIpaToFirWithJson:resposeobject success:success];
              
//              NSTextView *textContent = [processInfo documentView];
//              [textContent setString:_uploadProcessInfo];
              
          } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              NSLog(@"Error: %@", error);
          }];
}

- (void)uploadIpaToFirWithJson:(id)jsonFile success:(void (^)(void))success {
    
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:jsonFile options:NSJSONWritingPrettyPrinted error:&error];
    //Show json feedback to textfield
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
    
    //Upload ipa file to upload_url
    [manager POST:[binary objectForKey:@"upload_url"] parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        
        [formData appendPartWithFileData:fileData name:@"file" fileName:@"Baixing.ipa" mimeType:@"application/octet-stream"];
        
    }success:^(AFHTTPRequestOperation *operation, id resposeobject) {
        NSLog(@"%@", resposeobject);
        NSError *error = nil;
        NSData *completionData = [NSJSONSerialization dataWithJSONObject:resposeobject options:NSJSONWritingPrettyPrinted error:&error];
        //Update uploadProcessInfo text when finish upload ipa
        _uploadProcessInfo = [_uploadProcessInfo stringByAppendingString:
                                                    [[NSString alloc] initWithData:completionData
                                                                          encoding:NSUTF8StringEncoding]];
        
        success();
//        NSTextView *textContent = [processInfo documentView];
//        [textContent setString:_uploadProcessInfo];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        
        //Error information need to show more in detail
        _uploadProcessInfo = [_uploadProcessInfo stringByAppendingString:@"\nError"];
    }];

}

@end
