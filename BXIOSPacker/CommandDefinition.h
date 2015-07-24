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


#endif
