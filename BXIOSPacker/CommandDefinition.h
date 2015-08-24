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

#define call_archive @"xcodebuild clean && xcodebuild archive -workspace Baixing.xcworkspace -scheme Baixing -sdk iphoneos -configuration Release -archivePath %@/Library/Developer/Xcode/Archives/%@/BaixingFromPacker.xcarchive"

#define export_ipa @"xcodebuild -exportArchive -archivePath %@/Library/Developer/Xcode/Archives/%@/BaixingFromPacker.xcarchive -exportPath %@/Desktop/Baixing.ipa -exportFormat ipa -exportProvisioningProfile \"iosbaixing_inhouse\""

#define pack_to_ipa @"xcrun -sdk iphoneos PackageApplication -v '%@/Library/Developer/Xcode/Archives/%@/BaixingFromPacker.xcarchive/Products/Applications/Baixing.app' -o '%@/Desktop/Baixing.ipa'"

#define call_ruby @"ruby %@"

#define git_stash @"git stash"

#define git_apply @"git stash apply"

#define git_reset @"git reset --hard HEAD"

//---------------------------------------------------------------------------------

#pragma mark - URL List

#define url_new_upload @"http://api.fir.im/apps"

#define url_update @"http://api.fir.im/apps/%@/releases"

#endif
