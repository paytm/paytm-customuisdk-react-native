#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>
#import <Foundation/Foundation.h>
#import <React/RCTViewManager.h>
#import <React/RCTLinkingManager.h>



@interface RCT_EXTERN_MODULE(PaytmCustomuisdk, RCTLinkingManager)



RCT_EXTERN_METHOD(initPaytmSDK:(NSString *)mid
                  orderId:(NSString *)orderId
                  txnToken:(NSString *)txnToken
                  amount:(NSString *)amount
                  isStaging:(BOOL)isStaging
                  callbackUrl:(NSString *)callbackUrl
                  withResolver:(RCTPromiseResolveBlock)resolve
                  withRejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(goForNewCardTransaction:(NSString *)cardNumber
                  cardExpiry:(NSString *)cardExpiry
                  cardCvv:(NSString *)cardCvv
                  cardType:(NSString *)cardType
                  paymentFlow:(NSString *)paymentFlow
                  channelCode:(NSString *)channelCode
                  issuingBankCode:(NSString *)issuingBankCode
                  emiChannelId:(NSString *)emiChannelId
                  authMode:(NSString *)authMode
                  saveCard:(BOOL)saveCard
                  withResolver:(RCTPromiseResolveBlock)resolve
                  withRejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(goForSavedCardTransaction:(NSString *)cardId
                  cardCvv:(NSString *)cardCvv
                  cardType:(NSString *)cardType
                  paymentFlow:(NSString *)paymentFlow
                  channelCode:(NSString *)channelCode
                  issuingBankCode:(NSString *)issuingBankCode
                  emiChannelId:(NSString *)emiChannelId
                  authMode:(NSString *)authMode
                  withResolver:(RCTPromiseResolveBlock)resolve
                  withRejecter:(RCTPromiseRejectBlock)reject)


RCT_EXTERN_METHOD(getBin:(NSString *)cardSixDigit
                  tokenType:(NSString *)tokenType
                  token:(NSString *)token
                  mid:(NSString *)mid
                  referenceId:(NSString *)referenceId
                  withResolver:(RCTPromiseResolveBlock)resolve
                  withRejecter:(RCTPromiseRejectBlock)reject)


RCT_EXTERN_METHOD(fetchEmiDetails:(NSString *)cardType
                  channelCode:(NSString *)channelCode
                  withResolver:(RCTPromiseResolveBlock)resolve
                  withRejecter:(RCTPromiseRejectBlock)reject)


RCT_EXTERN_METHOD(isPaytmAppInstalled:(RCTPromiseResolveBlock)resolve withRejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(getEnvironment:(RCTPromiseResolveBlock)resolve withRejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(checkHasInstrument:(NSString *)mid
                  withResolver:(RCTPromiseResolveBlock)resolve
                  withRejecter:(RCTPromiseRejectBlock)reject)


RCT_EXTERN_METHOD(setEnvironment:(NSString *)environment
                  withResolver:(RCTPromiseResolveBlock)resolve
                  withRejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(goForWalletTransaction:(NSString *)paymentFlow
                  withResolver:(RCTPromiseResolveBlock)resolve
                  withRejecter:(RCTPromiseRejectBlock)reject)




RCT_EXTERN_METHOD(fetchAuthCode:(NSString *)clientId
                  mid:(NSString *)mid 
                  withResolver:(RCTPromiseResolveBlock)resolve
                  withRejecter:(RCTPromiseRejectBlock)reject)

//UPI
RCT_EXTERN_METHOD(goForUpiCollectTransaction:(NSString *)upiCode
                  paymentFlow:(NSString *)paymentFlow
                  saveVPA:(BOOL)saveVPA
                  withResolver:(RCTPromiseResolveBlock)resolve
                  withRejecter:(RCTPromiseRejectBlock)reject)



RCT_EXTERN_METHOD(goForUpiPushTransaction:(NSString *)paymentFlow
                  bankAccountJson:(NSDictionary *)bankAccountJson
                  vpaName:(NSString *)vpaName
                  merchantDetailsJson:(NSDictionary *)merchantDetailsJson
                  withResolver:(RCTPromiseResolveBlock)resolve
                  withRejecter:(RCTPromiseRejectBlock)reject)


RCT_EXTERN_METHOD(fetchUpiBalance:(NSDictionary *)bankAccountJson
                  vpaName:(NSString *)vpaName
                  withResolver:(RCTPromiseResolveBlock)resolve
                  withRejecter:(RCTPromiseRejectBlock)reject)


RCT_EXTERN_METHOD(setUpiMpin:(NSDictionary *)bankAccountJson
                  vpaName:(NSString *)vpaName
                  withResolver:(RCTPromiseResolveBlock)resolve
                  withRejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(getLastSavedVPA:(RCTPromiseResolveBlock)resolve withRejecter:(RCTPromiseRejectBlock)reject)



//MARK: NET-BANKING

RCT_EXTERN_METHOD(goForNetBankingTransaction:(NSString *)netBankingCode
                  paymentFlow:(NSString *)paymentFlow
                  withResolver:(RCTPromiseResolveBlock)resolve
                  withRejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(fetchNBList:(NSString *)tokenType
                  token:(NSString *)token
                  mid:(NSString *)mid
                  orderId:(NSString *)orderId
                  referenceId:(NSString *)referenceId
                  withResolver:(RCTPromiseResolveBlock)resolve
                  withRejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(getLastNBSavedBank:(RCTPromiseResolveBlock)resolve
                  withRejecter:(RCTPromiseRejectBlock)reject)


//MARK: UPI INTENT
RCT_EXTERN_METHOD(getUpiIntentList:(NSString *)resolve
                  withRejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(goForUpiIntentTransaction:(NSString *)resolve
                  withRejecter:(RCTPromiseRejectBlock)reject)




@end
