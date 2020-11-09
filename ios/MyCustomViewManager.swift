//
//  MyCustomViewManager.swift
//  PaytmCustomuisdk
//
//  Created by Nikhil Agarwal on 12/10/20.
//  Copyright © 2020 Facebook. All rights reserved.
//

import Foundation
import PaytmNativeSDK

@objc (PaytmConsentCheckBoxManager)
class PaytmConsentCheckBoxManager: RCTViewManager {
    

  override static func requiresMainQueueSetup() -> Bool {
    return true
  }

  override func view() -> PaytmConsentCheckBox {
    let consentView = PaytmConsentCheckBox()
    return consentView
  }
    
}
