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

#define call_archive @"xcodebuild clean && xcodebuild archive -workspace Baixing.xcworkspace -scheme Baixing -sdk iphoneos -configuration Release -archivePath ~/Library/Developer/Xcode/Archives/%@/BaixingFromScript.xcarchive"

#define export_ipa @"xcodebuild -exportArchive -archivePath ~/Library/Developer/Xcode/Archives/%@/BaixingFromScript.xcarchive -exportPath %@/Desktop/Baixing -exportFormat ipa"

//# First build the archive
//xcodebuild archive -scheme $SCHEME_NAME -archivePath $ARCHIVE_NAME
//# Then export it to an IPA
//xcodebuild -exportArchive -archivePath $ARCHIVE_NAME.xcarchive -exportPath $ARCHIVE_NAME -exportFormat ipa -exportProvisioningProfile "$PROVISIONING_PROFILE" -exportSigningIdentity "$DEVELOPER_NAME"

//---------------------------------------------------------------------------------

#pragma mark - URL List

#define url_new_upload @"http://api.fir.im/apps"

#define url_update @"http://api.fir.im/apps/%@/releases"

#endif
