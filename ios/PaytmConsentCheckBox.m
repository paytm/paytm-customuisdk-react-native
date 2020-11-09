//
//  CustomConsentCheckBox.m
//  PaytmCustomuisdk
//
//  Created by Nikhil Agarwal on 12/10/20.
//  Copyright © 2020 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <React/RCTViewManager.h>
#import "PaytmNativeSDK.h"
 
@interface RCT_EXTERN_MODULE(PaytmConsentCheckBoxManager, RCTViewManager)
RCT_EXPORT_VIEW_PROPERTY(onCheckChange, RCTBubblingEventBlock)

 
@end
