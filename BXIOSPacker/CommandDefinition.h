//
//  CommandDefinition.h
//  BXIOSPacker
//
//  Created by baixing on 15/7/22.
//  Copyright (c) 2015年 Leppard. All rights reserved.
//

#ifndef BXIOSPacker_CommandDefinition_h
#define BXIOSPacker_CommandDefinition_h


#pragma mark - Command List

//先把命令写在这里回去改
#define pack_to_ipa @"xcrun -sdk iphoneos PackageApplication -v '%@/Library/Developer/Xcode/Archives/%@/BaixingFromScript.xcarchive/Products/Applications/Baixing.app' -o '%@/Desktop/Baixing.ipa'"

#define call_archive @"xcodebuild clean && xcodebuild archive -workspace Baixing.xcworkspace -scheme Baixing -sdk iphoneos -configuration Release -archivePath ~/Library/Developer/Xcode/Archives/%@/BaixingFromScript.xcarchive"


//之后记得把Bundle_id改成百姓的app，现在是自己测试的appid
#define get_upload_info @"curl -F \"type=ios\" -F \"bundle_id=edu.tac.PagedFlowView\" -F \"api_token=%@\" %@"


#pragma mark - URL List

#define url_new_upload @"http://api.fir.im/apps"

#define url_update @"http://api.fir.im/apps/%@/releases"

#endif
