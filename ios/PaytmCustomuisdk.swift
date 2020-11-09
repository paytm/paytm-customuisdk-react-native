import PaytmNativeSDK
import Foundation
import UIKit

class EventEmitter {

    /// Shared Instance.
    public static var sharedInstance = EventEmitter()

    // ReactNativeEventEmitter is instantiated by React Native with the bridge.
    private static var eventEmitter: PaytmCustomuisdk!

    private init() {}

    // When React Native instantiates the emitter it is registered here.
    func registerEventEmitter(eventEmitter: PaytmCustomuisdk) {
        EventEmitter.eventEmitter = eventEmitter
    }

    func dispatch(name: String, body: Any?) {
      EventEmitter.eventEmitter.sendEvent(withName: name, body: body)
    }

    /// All Events which must be support by React Native.
    lazy var allEvents: [String] = {
        var allEventNames: [String] = ["responseIfNotInstalled", "responseIfPaytmInstalled"]

        // Append all events here
        return allEventNames
    }()

}


@objc(PaytmCustomuisdk)
public class PaytmCustomuisdk: RCTEventEmitter {
    
    var resolve: RCTPromiseResolveBlock?
    var reject: RCTPromiseRejectBlock?
    
    var errorCode: String = "0"
    private enum CardType: String {
        case creditCard = "CREDIT_CARD"
        case debitCard = "DEBIT_CARD"
        
        var paymentMode: AINativePaymentModes {
            switch self {
            case .creditCard:
                return .creditCard
            case .debitCard:
                return .debitCard
            }
        }
    }
    
    override init() {
      super.init()
      EventEmitter.sharedInstance.registerEventEmitter(eventEmitter: self)
      NotificationCenter.default.addObserver(self, selector: #selector(getAppInvokeResponse(notification:)), name: NSNotification.Name(rawValue: "appInvokeNotification"), object: nil)

    }

    @objc func getAppInvokeResponse(notification: NSNotification) {
      
      if let userInfo = notification.userInfo {
        let url = userInfo["appInvokeNotificationKey"] as? String
        let response = self.separateDeeplinkParamsIn(url: url, byRemovingParams: nil)
        
//        let alert = UIAlertController(title: "Response", message: response.description, preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
//        self.viewController?.present(alert, animated: true, completion: nil)
//        sendEvent(withName: "responseIfPaytmInstalled", body: response)
        self.resolve?(response)
        
        self.resolve = nil
        self.reject = nil

      }
    }

    /// Base overide for RCTEventEmitter.
    ///
    /// - Returns: all supported events
    @objc open override func supportedEvents() -> [String] {
        return EventEmitter.sharedInstance.allEvents
    }
    
    @objc func separateDeeplinkParamsIn(url: String?, byRemovingParams rparams: [String]?)  -> [String: String] {
        guard let url = url else {
            return [String : String]()
        }

        /// This url gets mutated until the end. The approach is working fine in current scenario. May need a revisit.
        var urlString = stringByRemovingDeeplinkSymbolsIn(url: url)

        var paramList = [String : String]()
        let pList = urlString.components(separatedBy: CharacterSet.init(charactersIn: "&?"))
        for keyvaluePair in pList {
            let info = keyvaluePair.components(separatedBy: CharacterSet.init(charactersIn: "="))
            if let fst = info.first , let lst = info.last, info.count == 2 {
                paramList[fst] = lst.removingPercentEncoding
                if let rparams = rparams, rparams.contains(info.first!) {
                    urlString = urlString.replacingOccurrences(of: keyvaluePair + "&", with: "")
                    //Please dont interchage the order
                    urlString = urlString.replacingOccurrences(of: keyvaluePair, with: "")
                }
            }
        }
        if let trimmedURL = pList.first {
            paramList["trimmedurl"] = trimmedURL
        }

        return paramList
    }

    func  stringByRemovingDeeplinkSymbolsIn(url: String) -> String {
        var urlString = url.replacingOccurrences(of: "$", with: "&")

        /// This may need a revisit. This is doing more than just removing the deeplink symbol.
        if let range = urlString.range(of: "&"), urlString.contains("?") == false{
            urlString = urlString.replacingCharacters(in: range, with: "?")
        }
        return urlString
    }

    
    private enum AuthMode: String {
        case atm
        case otp
        
        var nativeAuthMode: PaytmNativeSDK.AuthMode {
            switch self {
            case .atm:
                return .atm
            case .otp:
                return .otp
            }
        }
    }
    
    private var callbackId = ""
    private var merchantId = ""
    private var orderId = ""
    private var txnToken = ""
    private var amount: Double = 0.0
    private var callbackUrl = ""
    private var aiHandler = PaytmNativeSDK.AIHandler()
    var viewController = UIApplication.shared.windows.first?.rootViewController
    
    
    
    private var redirectionUrl: String {
        switch aiHandler.getEnvironent() {
        case .production:
            return "https://securegw.paytm.in/theia/paytmCallback"
        case .staging:
            return "https://securegw-stage.paytm.in/theia/paytmCallback"
        @unknown default:
            fatalError()
        }
    }
}


public extension PaytmCustomuisdk {
    @objc(initPaytmSDK:orderId:txnToken:amount:isStaging:callbackUrl:withResolver:withRejecter:)
    func initPaytmSDK(_ mid: String, orderId: String, txnToken: String, amount:String, isStaging: Bool, callbackUrl: String, withResolver resolve: @escaping RCTPromiseResolveBlock, withRejecter reject: @escaping RCTPromiseRejectBlock) {
                
        if mid.isEmpty {
            reject(errorCode,"Invalid merchant id", nil)
            return
        }
        if orderId.isEmpty {
            reject(errorCode,"Invalid order id", nil)
            return
        }
        
        if txnToken.isEmpty {
            reject(errorCode,"Invalid transaction token", nil)
            return
        }
        
        if amount.isEmpty {
            reject(errorCode,"Amount is required", nil)
            return
        }
        
        guard let amountDouble = Double(amount) else {
            reject(errorCode,"Invalid amount", nil)
            return
        }
        
        self.merchantId = mid
        self.orderId = orderId
        self.txnToken = txnToken
        self.amount = amountDouble
        self.callbackUrl = callbackUrl
        
        let env: AIEnvironment = (isStaging ? .staging : .production)
        aiHandler.setEnvironment(env)
    }
    
    @objc(getEnvironment:withRejecter:)
    func getEnvironment(withResolver resolve: @escaping RCTPromiseResolveBlock, withRejecter reject: @escaping RCTPromiseRejectBlock) {
        
        switch aiHandler.getEnvironent() {
        case .production:
            resolve("production".uppercased())
        case .staging:
            resolve("staging".uppercased())
        @unknown default:
            fatalError()
        }
    }
    
    @objc(setEnvironment:withResolver:withRejecter:)
    func setEnvironment(_ environment: String, withResolver resolve: @escaping RCTPromiseResolveBlock, withRejecter reject: @escaping RCTPromiseRejectBlock) {
        
        guard !environment.isEmpty else {
            reject(errorCode,"Environment is required", nil)
            return
        }
        
        switch environment.lowercased() {
        case "production":
            aiHandler.setEnvironment(.production)
            resolve("success")
            
        case "staging":
            aiHandler.setEnvironment(.staging)
            resolve("success")
            
        default:
            reject(errorCode, "Invalid environment", nil)
        }
    }
    
    @objc(checkHasInstrument:withResolver:withRejecter:)
    func checkHasInstrument(_ mid: String, withResolver resolve: @escaping RCTPromiseResolveBlock, withRejecter reject: @escaping RCTPromiseRejectBlock) {
    }
    
    @objc(isPaytmAppInstalled:withRejecter:)
    func isPaytmAppInstalled(withResolver resolve: @escaping RCTPromiseResolveBlock, withRejecter reject: @escaping RCTPromiseRejectBlock) {
        DispatchQueue.main.async {
            resolve(self.aiHandler.isPaytmAppInstall)
        }
    }
    
    
    @objc(fetchAuthCode:mid:withResolver:withRejecter:)
    func fetchAuthCode(_ clientId: String, mid: String, withResolver resolve: @escaping RCTPromiseResolveBlock, withRejecter reject: @escaping RCTPromiseRejectBlock) {
        self.resolve = resolve
        self.reject = reject
        DispatchQueue.main.async {[weak self] in
            guard let weakSelf = self else {
                return
            }
            
            if AINativeConsentManager.shared.getConsentState() {
                
                if clientId.isEmpty {
                    reject(weakSelf.errorCode, "Client id is required", nil)
                }
                
                if mid.isEmpty {
                    reject(weakSelf.errorCode, "Merchant id is required", nil)
                }
                
                DispatchQueue.main.async { [weak self] in
                    
                    guard let weakSelf = self else {
                        return
                    }
                    
                    weakSelf.aiHandler.getAuthToken(clientId: clientId, mid: mid) { status in
                        switch status {
                        
                        case .error:
                            reject(weakSelf.errorCode, "ERROR", nil)
                            
                        case .appNotInstall:
                            reject(weakSelf.errorCode, "APP NOT INSTALLED", nil)
                            //                                weakSelf.openRedirectionFlow(withResolver: resolve, withRejecter: reject)
                            fallthrough
                            
                        case .inProcess:
                            return
                        @unknown default:
                            fatalError()
                        }
                    }
                }
                
            } else {
                reject(weakSelf.errorCode, "APP NOT INSTALLED", nil)
                
            }
            //            }
        }
    }
    
    //    @objc(getInstrumentFromLocalVault:)
    //    func getInstrumentFromLocalVault(command: CDVInvokedUrlCommand) {
    //
    //        guard let custId = command.arguments[0] as? String else {
    //            let pluginResult = CDVPluginResult(status: .error, messageAs: "Customer id is required")
    //            commandDelegate!.send(pluginResult, callbackId: command.callbackId)
    //            return
    //        }
    //
    //        guard !custId.isEmpty else {
    //            let pluginResult = CDVPluginResult(status: .error, messageAs: "Invalid customer id")
    //            commandDelegate!.send(pluginResult, callbackId: command.callbackId)
    //            return
    //        }
    //
    //        guard let mid = command.arguments[1] as? String else {
    //            let pluginResult = CDVPluginResult(status: .error, messageAs: "Merchant id is required")
    //            commandDelegate!.send(pluginResult, callbackId: command.callbackId)
    //            return
    //        }
    //
    //        guard !mid.isEmpty else {
    //            let pluginResult = CDVPluginResult(status: .error, messageAs: "Invalid merchant id")
    //            commandDelegate!.send(pluginResult, callbackId: command.callbackId)
    //            return
    //        }
    //
    //        guard let checksum = command.arguments[2] as? String else {
    //            let pluginResult = CDVPluginResult(status: .error, messageAs: "Checksum is required")
    //            commandDelegate!.send(pluginResult, callbackId: command.callbackId)
    //            return
    //        }
    //
    //        guard !checksum.isEmpty else {
    //            let pluginResult = CDVPluginResult(status: .error, messageAs: "Invalid checksum")
    //            commandDelegate!.send(pluginResult, callbackId: command.callbackId)
    //            return
    //        }
    //
    //        let ssoToken: String
    //        if let sToken = command.arguments[3] as? String {
    //            ssoToken = sToken
    //        } else {
    //            ssoToken = ""
    //        }
    //
    //        callbackId = command.callbackId
    //        commandDelegate.run { [weak self] in
    //            DispatchQueue.main.async { [weak self] in
    //                guard let weakSelf = self else {
    //                    return
    //                }
    //                weakSelf.aiHandler.getInstrumentFromLocalVault(custId: custId, mid: mid, ssoToken: ssoToken, checksum: checksum, delegate: weakSelf)
    //            }
    //        }
    //    }
    
    //    @objc(getConsentState:)
    //    func getConsentState(command: CDVInvokedUrlCommand) {
    //        let pluginResult = CDVPluginResult(status: .ok, messageAs: AINativeConsentManager.shared.getConsentState())
    //        commandDelegate!.send(pluginResult, callbackId: command.callbackId)
    //    }
    
    //    @objc(isAuthCodeValid:)
    //    func isAuthCodeValidisAuthCodeValid(command: CDVInvokedUrlCommand) {
    //        let pluginResult = CDVPluginResult(status: .error, messageAs: "Method not implemented")
    //        commandDelegate!.send(pluginResult, callbackId: command.callbackId)
    //    }
    //
    //    @objc(applyOffer:)
    //    func applyOffer(command: CDVInvokedUrlCommand) {
    //        commandDelegate.run { [weak self] in
    //            DispatchQueue.main.async { [weak self] in
    //                guard let weakSelf = self else {
    //                    return
    //                }
    //                weakSelf.aiHandler.applyOffer()
    //            }
    //        }
    //    }
    
    //    @objc(fetchAllOffers:)
    //    func fetchAllOffers(command: CDVInvokedUrlCommand) {
    //
    //        guard let mid = command.arguments[0] as? String else {
    //            let pluginResult = CDVPluginResult(status: .error, messageAs: "Merchant id is required")
    //            commandDelegate!.send(pluginResult, callbackId: command.callbackId)
    //            return
    //        }
    //
    //        guard !mid.isEmpty else {
    //            let pluginResult = CDVPluginResult(status: .error, messageAs: "Invalid merchant id")
    //            commandDelegate!.send(pluginResult, callbackId: command.callbackId)
    //            return
    //        }
    //
    //        callbackId = command.callbackId
    //        commandDelegate.run { [weak self] in
    //            DispatchQueue.main.async { [weak self] in
    //                guard let weakSelf = self else {
    //                    return
    //                }
    //                weakSelf.aiHandler.fetchAllOffers(mid: mid, delegate: weakSelf)
    //            }
    //        }
    //    }
}


// MARK: Wallet related methods
public extension PaytmCustomuisdk {
    
    @objc (goForWalletTransaction:withResolver:withRejecter:)
    func goForWalletTransaction(_ paymentFlow: String, withResolver resolve: @escaping RCTPromiseResolveBlock, withRejecter reject: @escaping RCTPromiseRejectBlock) {
        print(paymentFlow)
        self.reject = reject
        self.resolve = resolve
        guard !paymentFlow.isEmpty else {
            reject(errorCode, "Payment flow is require", nil)
            return
        }
        
        guard let flowType = AINativePaymentFlow(rawValue: paymentFlow) else {
            reject(errorCode, "Invalid payment flow", nil)
            return
        }
        
        let model = AINativeInhouseParameterModel(withTransactionToken: txnToken, orderId: orderId, shouldOpenNativePlusFlow: true, mid: merchantId, flowType: flowType, paymentModes: .wallet, redirectionUrl: redirectionUrl)
        
        DispatchQueue.main.async { [weak self] in
            guard let weakSelf = self else {
                return
            }
            weakSelf.aiHandler.callProcessTransactionAPI(selectedPayModel: model, delegate: weakSelf)
        }
    }
}


// MARK: Credit/Debit card related methods
public extension PaytmCustomuisdk {
    
    @objc(goForNewCardTransaction:cardExpiry:cardCvv:cardType:paymentFlow:channelCode:issuingBankCode:emiChannelId:authMode:saveCard:withResolver:withRejecter:)
    func goForNewCardTransaction(_ cardNumber: String, cardExpiry: String, cardCvv: String, cardType:String, paymentFlow: String, channelCode: String, issuingBankCode: String, emiChannelId: String, authMode: String, saveCard: Bool, withResolver resolve: @escaping RCTPromiseResolveBlock, withRejecter reject: @escaping RCTPromiseRejectBlock) {
        self.reject = reject
        self.resolve = resolve
        
        if cardNumber.isEmpty {
            reject(self.errorCode, "Invalid card number", nil)
            return
        }
        
        if cardExpiry.isEmpty {
            reject(self.errorCode,  "Card expiry is required", nil)
            return
        }
        
        let component = cardExpiry.split(separator: "/")
        var cardExp = ""
        
        if (component.count == 2), let expMonth = component.first, let yearMonth = component.last {
            cardExp = "\(expMonth)20\(yearMonth)"
        } else {
            reject(self.errorCode, "Invalid card expiry", nil)
            return
        }
        
        
        if cardCvv.isEmpty {
            reject(self.errorCode, "Card cvv is required", nil)
            return
        }
        
        if cardType.isEmpty {
            reject(self.errorCode, "Card cvv is required", nil)
            return
        }
        
        guard let cardType = CardType(rawValue: cardType) else {
            reject(self.errorCode,  "Invalid card type", nil)
            return
        }
        
        if paymentFlow.isEmpty {
            reject(self.errorCode, "Payment flow is required", nil)
            return
        }
        
        guard let paymentFlow = AINativePaymentFlow(rawValue: paymentFlow) else {
            reject(self.errorCode,  "Invalid payment flow", nil)
            return
        }
        
        if channelCode.isEmpty {
            reject(self.errorCode, "Channel code is required", nil)
            return
        }
        
        if issuingBankCode.isEmpty {
            reject(self.errorCode, "Issuing bank code is required", nil)
            return
        }
        
        
        /*
         guard let emiChannelId = command.arguments[7] as? String else {
         let pluginResult = CDVPluginResult(status: .error, messageAs: "Emi channel id is required")
         commandDelegate!.send(pluginResult, callbackId: command.callbackId)
         return
         }
         
         guard !emiChannelId.isEmpty else {
         let pluginResult = CDVPluginResult(status: .error, messageAs: "Invalid emi channel id")
         commandDelegate!.send(pluginResult, callbackId: command.callbackId)
         return
         }
         */
        
        if authMode.isEmpty {
            reject(self.errorCode, "Auth mode is required", nil)
            return
        }
        
        let authanticationMode: PaytmNativeSDK.AuthMode
        if let aMode = AuthMode(rawValue: authMode) {
            authanticationMode = aMode.nativeAuthMode
        } else {
            authanticationMode = .none
        }
        
        
        
        
        //        guard let saveCard = command.arguments[9] as? Bool else {
        //            let pluginResult = CDVPluginResult(status: .error, messageAs: "Should save card is required")
        //            commandDelegate!.send(pluginResult, callbackId: command.callbackId)
        //            return
        //        }
        
        
        let shouldSaveCard = (saveCard ? "1" : "0")
        
        let model = AINativeSavedCardParameterModel(withTransactionToken: txnToken, tokenType: .txntoken, orderId: orderId, shouldOpenNativePlusFlow: true, mid: merchantId, flowType: paymentFlow, paymentModes: cardType.paymentMode, authMode: authanticationMode, cardId: nil, cardNumber: cardNumber, cvv: cardCvv, expiryDate: cardExp, newCard: true, saveInstrument: shouldSaveCard, redirectionUrl: redirectionUrl)
        
        DispatchQueue.main.async { [weak self] in
            guard let weakSelf = self else {
                return
            }
            weakSelf.aiHandler.callProcessTransactionAPI(selectedPayModel: model, delegate: weakSelf)
        }
    }
    @objc(goForSavedCardTransaction:cardCvv:cardType:paymentFlow:channelCode:issuingBankCode:emiChannelId:authMode:withResolver:withRejecter:)
    func goForSavedCardTransaction(_ cardId: String, cardCvv: String, cardType:String, paymentFlow: String, channelCode: String, issuingBankCode: String, emiChannelId: String, authMode: String, withResolver resolve: @escaping RCTPromiseResolveBlock, withRejecter reject: @escaping RCTPromiseRejectBlock) {
        self.reject = reject
        self.resolve = resolve
        
        if cardId.isEmpty {
            reject(self.errorCode,"Card id is required", nil)
            return
        }
        
        
        
        if cardCvv.isEmpty {
            reject(self.errorCode, "Card cvv is required", nil)
            return
        }
        
        if cardType.isEmpty {
            reject(self.errorCode, "Card cvv is required", nil)
            return
        }
        
        guard let cardType = CardType(rawValue: cardType) else {
            reject(self.errorCode,  "Invalid card type", nil)
            return
        }
        
        if paymentFlow.isEmpty {
            reject(self.errorCode, "Payment flow is required", nil)
            return
        }
        
        guard let flowType = AINativePaymentFlow(rawValue: paymentFlow) else {
            reject(self.errorCode,  "Invalid payment flow", nil)
            return
        }
        
        if channelCode.isEmpty {
            reject(self.errorCode, "Channel code is required", nil)
            return
        }
        
        if issuingBankCode.isEmpty {
            reject(self.errorCode, "Issuing bank code is required", nil)
            return
        }
        
        /*
         guard let emiChannelId = command.arguments[7] as? String else {
         let pluginResult = CDVPluginResult(status: .error, messageAs: "Emi channel id is required")
         commandDelegate!.send(pluginResult, callbackId: command.callbackId)
         return
         }
         
         guard !emiChannelId.isEmpty else {
         let pluginResult = CDVPluginResult(status: .error, messageAs: "Invalid emi channel id")
         commandDelegate!.send(pluginResult, callbackId: command.callbackId)
         return
         }
         */
        
        if authMode.isEmpty {
            reject(self.errorCode, "Auth mode is required", nil)
            return
        }
        
        let authanticationMode: PaytmNativeSDK.AuthMode
        if let aMode = AuthMode(rawValue: authMode) {
            authanticationMode = aMode.nativeAuthMode
        } else {
            authanticationMode = .none
        }
        
        let model = AINativeSavedCardParameterModel(withTransactionToken: txnToken, tokenType: .txntoken, orderId: orderId, shouldOpenNativePlusFlow: true, mid: merchantId, flowType: flowType, paymentModes: cardType.paymentMode, authMode: authanticationMode, cardId: cardId, cardNumber: nil, cvv: cardCvv, expiryDate: nil, newCard: false, saveInstrument: "0", redirectionUrl: redirectionUrl)
        
        DispatchQueue.main.async { [weak self] in
            guard let weakSelf = self else {
                return
            }
            weakSelf.aiHandler.callProcessTransactionAPI(selectedPayModel: model, delegate: weakSelf)
        }
    }
    
    @objc(getBin:tokenType:token:mid:referenceId:withResolver:withRejecter:)
    func getBin(_ cardSixDigit: String, tokenType: String, token: String, mid: String, referenceId: String, withResolver resolve: @escaping RCTPromiseResolveBlock, withRejecter reject: @escaping RCTPromiseRejectBlock) {
        self.reject = reject
        self.resolve = resolve
        
        if cardSixDigit.isEmpty {
            reject(self.errorCode, "First six card digits string is required", nil)
            return
        }
        if tokenType.isEmpty {
            reject(self.errorCode, "Token type is required", nil)
            return
        }
        
        guard let tokenType = TokenType(rawValue: tokenType) else {
            reject(self.errorCode, "Invalid token type", nil)
            return
        }
        
        
        if token.isEmpty {
            reject(self.errorCode, "Token is required", nil)
            return
        }
        if mid.isEmpty {
            reject(self.errorCode,  "Merchant id is required", nil)
            return
        }
        
        /*
         guard let refId = command.arguments[4] as? String else {
         let pluginResult = CDVPluginResult(status: .error, messageAs: "Reference id is required")
         commandDelegate!.send(pluginResult, callbackId: command.callbackId)
         return
         }
         
         guard !refId.isEmpty else {
         let pluginResult = CDVPluginResult(status: .error, messageAs: "Invalid reference id")
         commandDelegate!.send(pluginResult, callbackId: command.callbackId)
         return
         }
         */
        
        let model = AINativeSavedCardParameterModel(withTransactionToken: txnToken, tokenType: tokenType, orderId: orderId, shouldOpenNativePlusFlow: true, mid: mid, flowType: .none, paymentModes: .debitCard, authMode: .none, cardId: nil, cardNumber: cardSixDigit, cvv: nil, expiryDate: nil, newCard: false, saveInstrument: "0", redirectionUrl: redirectionUrl)
        
        DispatchQueue.main.async { [weak self] in
            guard let weakSelf = self else {
                return
            }
            weakSelf.aiHandler.fetchBin(selectedPayModel: model, delegate: weakSelf)
        }
    }
    
    
    @objc(fetchEmiDetails:channelCode:withResolver:withRejecter:)
    func fetchEmiDetails(_ cardType: String, channelCode:String, withResolver resolve: @escaping RCTPromiseResolveBlock, withRejecter reject: @escaping RCTPromiseRejectBlock) {
        reject(self.errorCode, "Method not implemented", nil)
        self.reject = reject
        self.resolve = resolve
        
        return
    }
}


// MARK: Net Banking related methods
public extension PaytmCustomuisdk {
    
    @objc(goForNetBankingTransaction:paymentFlow:withResolver:withRejecter:)
    func goForNetBankingTransaction(_ netBankingCode: String, paymentFlow: String,withResolver resolve: @escaping RCTPromiseResolveBlock, withRejecter reject: @escaping RCTPromiseRejectBlock) {
        self.reject = reject
        self.resolve = resolve
        
        if netBankingCode.isEmpty {
            reject(self.errorCode, "Net banking code is required", nil)
            return
        }
        
        if paymentFlow.isEmpty {
            reject(self.errorCode, "Payment flow is required", nil)
            return
        }
        
        
        guard let flowType = AINativePaymentFlow(rawValue: paymentFlow) else {
            reject(self.errorCode,  "Invalid payment flow", nil)
            return
        }
        
        
        aiHandler.saveNetBankingMethod(channelCode: netBankingCode)
        
        let model = AINativeNBParameterModel(withTransactionToken: txnToken, orderId: orderId, shouldOpenNativePlusFlow: true, mid: merchantId, flowType: flowType, paymentModes: .netBanking, channelCode: netBankingCode, redirectionUrl: redirectionUrl)
        
        DispatchQueue.main.async { [weak self] in
            guard let weakSelf = self else {
                return
            }
            weakSelf.aiHandler.callProcessTransactionAPI(selectedPayModel: model, delegate: weakSelf)
        }
    }
    
    @objc(fetchNBList:token:mid:orderId:referenceId:withResolver:withRejecter:)
    func fetchNBList(_ tokenType: String, token: String, mid: String, orderId: String?, referenceId: String?,withResolver resolve: @escaping RCTPromiseResolveBlock, withRejecter reject: @escaping RCTPromiseRejectBlock) {
        self.reject = reject
        self.resolve = resolve
        
        
        if tokenType.isEmpty {
            reject(self.errorCode, "Token is required", nil)
            return
        }
        
        guard let tokenType = TokenType(rawValue: tokenType) else {
            reject(self.errorCode, "Invalid token type", nil)
            return
        }
        
        if tokenType == .acccess {
            guard let referenceId = referenceId else {
                reject(self.errorCode, "Invalid reference id", nil)
                
                return
            }
            
            if referenceId.isEmpty {
                reject(self.errorCode, "Reference id is required", nil)
                return
            }
        }
        
        
        if mid.isEmpty {
            reject(self.errorCode, "Merchant id is required", nil)
            return
        }
        
        guard let orderId = orderId else {
            reject(self.errorCode, "Invalid order id", nil)
            
            return
        }
        
        if orderId.isEmpty {
            reject(self.errorCode, "Order id is required", nil)
            return
        }
        
        
        
        
        let model = AINativeNBParameterModel(withTransactionToken: txnToken, orderId: orderId, shouldOpenNativePlusFlow: true, mid: mid, flowType: .none, paymentModes: .netBanking, channelCode: referenceId ?? "", redirectionUrl: redirectionUrl)
        
        DispatchQueue.main.async { [weak self] in
            guard let weakSelf = self else {
                return
            }
            weakSelf.aiHandler.fetchNetBankingChannels(selectedPayModel: model, delegate: weakSelf)
        }
    }
    
    @objc(getLastNBSavedBank:withRejecter:)
    func getLastNBSavedBank(withResolver resolve: @escaping RCTPromiseResolveBlock, withRejecter reject: @escaping RCTPromiseRejectBlock) {
//        self.reject = reject
//        self.resolve = resolve
//        DispatchQueue.main.async { [weak self] in
//            guard let weakSelf = self else {
//                return
//            }
            if let savedNetBankingMethod = aiHandler.getSavedNetBankingMethod(),
               !savedNetBankingMethod.isEmpty {
                print(savedNetBankingMethod)
                resolve(savedNetBankingMethod)
            } else {
                reject(self.errorCode, "No saved net banking method", nil)
            }
    }
    
}

// MARK: UPI related methods
public extension PaytmCustomuisdk {
    
    @objc(goForUpiCollectTransaction:paymentFlow:saveVPA:withResolver:withRejecter:)
    func goForUpiCollectTransaction(_ upiCode: String, paymentFlow: String, saveVPA: Bool, withResolver resolve: @escaping RCTPromiseResolveBlock, withRejecter reject: @escaping RCTPromiseRejectBlock) {
        self.reject = reject
        self.resolve = resolve
        
        if upiCode.isEmpty {
            reject(self.errorCode, "Upi code is required", nil)
            return
        }
        
        if paymentFlow.isEmpty {
            reject(self.errorCode, "Payment flow is required", nil)
            return
        }
        
        guard let flowType = AINativePaymentFlow(rawValue: paymentFlow) else {
            reject(self.errorCode, "Invalid payment flow", nil)
            return
        }
        
        if saveVPA && upiCode != aiHandler.getSavedVPA() {
            aiHandler.saveVPA(vpa: upiCode)
        }
        
        let model = AINativeNUPIarameterModel(withTransactionToken: txnToken, orderId: orderId, shouldOpenNativePlusFlow: true, mid: merchantId, flowType: flowType, amount: CGFloat(amount), paymentModes: .upi, vpaAddress: upiCode, upiFlowType: .collect, merchantInfo: nil, bankDetail: nil, redirectionUrl: redirectionUrl)
        
        DispatchQueue.main.async { [weak self] in
            guard let weakSelf = self else {
                return
            }
            let upiConfig = UpiCollectConfigurations(shouldAllowCustomPolling: false, isAutoPolling: true)
            weakSelf.aiHandler.callProcessTransitionAPIForCollect(selectedPayModel: model, delegate: weakSelf, upiPollingConfig: upiConfig) {  _ in
                weakSelf.aiHandler.upiCollectPollingCompletion = { (status, model) in
                    switch status {
                    case .none:
                        resolve("Upi collect completed with status - NONE")
                    case .pending:
                        resolve("Upi collect completed with status - PENDING")
                    case .failure:
                        resolve("Upi collect completed with status - FAILURE")
                    case .success:
                        resolve("Upi collect completed with status - SUCCESS")
                    case .timeElapsed:
                        resolve("Upi collect completed with status - TIME ELAPSED")
                    }
                }
            }
        }
    }
    
    @objc(goForUpiPushTransaction:bankAccountJson:vpaName:merchantDetailsJson:withResolver:withRejecter:)
    func goForUpiPushTransaction(_ paymentFlow: String, bankAccountJson: [String:Any], vpaName: String, merchantDetailsJson: [String:Any],withResolver resolve: @escaping RCTPromiseResolveBlock, withRejecter reject: @escaping RCTPromiseRejectBlock) {
        self.reject = reject
        self.resolve = resolve
        
        if paymentFlow.isEmpty {
            reject(self.errorCode, "Payment flow is required", nil)
            return
        }
        
        guard let flowType = AINativePaymentFlow(rawValue: paymentFlow) else {
            reject(self.errorCode, "Invalid payment flow", nil)
            return
        }
        
        
        if bankAccountJson.isEmpty {
            reject(self.errorCode, "Bank details are required", nil)
            return
        }
        
        if vpaName.isEmpty {
            reject(self.errorCode, "Vpa name is required", nil)
            return
        }
        
        
        if merchantDetailsJson.isEmpty {
            reject(self.errorCode, "merchant details are required", nil)
            return
        }
        
        let model = AINativeNUPIarameterModel(withTransactionToken: txnToken, orderId: orderId, shouldOpenNativePlusFlow: true, mid: merchantId, flowType: flowType, amount: CGFloat(amount), paymentModes: .upi, vpaAddress: vpaName, upiFlowType: .push, merchantInfo: merchantDetailsJson, bankDetail: bankAccountJson, redirectionUrl: redirectionUrl)
        
        DispatchQueue.main.async { [weak self] in
            
            guard let weakSelf = self else {
                return
            }
            weakSelf.aiHandler.callProcessTransactionAPIForUPI(selectedPayModel: model) { [weak self] status in
                guard let weakSelf = self else {
                    return
                }
                
                switch status {
                case .appNotInstall:
                    self?.goForUpiCollectTransaction(vpaName, paymentFlow: paymentFlow, saveVPA: false, withResolver: resolve, withRejecter: reject)
                //                        reject(weakSelf.errorCode, "appNotInstall: collect flow will be invoked", nil)
                
                case .error:
                    reject(weakSelf.errorCode, "Upi push completed with status - ERROR", nil)
                case .inProcess:
                    return
                @unknown default:
                    fatalError()
                }
            }
        }
    }
    
    @objc(fetchUpiBalance:vpaName:withResolver:withRejecter:)
    func fetchUpiBalance(_ bankAccountJson: [String:Any], vpaName: String,withResolver resolve: @escaping RCTPromiseResolveBlock, withRejecter reject: @escaping RCTPromiseRejectBlock) {
        self.reject = reject
        self.resolve = resolve
        
        guard !bankAccountJson.isEmpty else {
            reject(self.errorCode, "Invalid bank detail object", nil)
            return
        }
        
        if vpaName.isEmpty {
            reject(self.errorCode, "Vpa name is required", nil)
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            
            guard let weakSelf = self else {
                return
            }
            weakSelf.aiHandler.getUPIBalance(bankDetails: bankAccountJson, mid: weakSelf.merchantId) { [weak self] status in
                guard let weakSelf = self else {
                    return
                }
                
                switch status {
                case .appNotInstall:
                    reject(weakSelf.errorCode, "Paytm is not installed", nil)
                case .error:
                    reject(weakSelf.errorCode, "Something went wrong", nil)
                    
                case .inProcess:
                    return
                @unknown default:
                    fatalError()
                }
            }
        }
    }
    
    @objc(setUpiMpin:vpaName:withResolver:withRejecter:)
    func setUpiMpin(_ bankAccountJson: [String:Any], vpaName: String, withResolver resolve: @escaping RCTPromiseResolveBlock, withRejecter reject: @escaping RCTPromiseRejectBlock) {
        
        self.reject = reject
        self.resolve = resolve
        
        if bankAccountJson.isEmpty {
            reject(self.errorCode, "Invalid bank detail object", nil)
        }
        
        DispatchQueue.main.async { [weak self] in
            
            guard let weakSelf = self else {
                return
            }
            weakSelf.aiHandler.setupUPIPin(bankDetails: bankAccountJson, mid: weakSelf.merchantId) { [weak self] status in
                guard let weakSelf = self else {
                    return
                }
                
                switch status {
                case .appNotInstall:
                    reject(weakSelf.errorCode, "Paytm is not installed", nil)
                case .error:
                    reject(weakSelf.errorCode, "Something went wrong", nil)
                    
                case .inProcess:
                    return
                @unknown default:
                    fatalError()
                }
            }
        }
    }
    
    @objc(getUpiIntentList:withRejecter:)
        func getUpiIntentList(withResolver resolve: @escaping RCTPromiseResolveBlock, withRejecter reject: @escaping RCTPromiseRejectBlock) {
            reject(errorCode, "Method not implemented", nil)

        }
    
    @objc(goForUpiIntentTransaction:withRejecter:)
        func goForUpiIntentTransaction(withResolver resolve: @escaping RCTPromiseResolveBlock, withRejecter reject: @escaping RCTPromiseRejectBlock) {
            reject(errorCode, "Method not implemented", nil)
        }
    
    @objc(getLastSavedVPA:withRejecter:)
    func getLastSavedVPA(withResolver resolve: @escaping RCTPromiseResolveBlock, withRejecter reject: @escaping RCTPromiseRejectBlock) {
        DispatchQueue.main.async { [weak self] in
            guard let weakSelf = self else {
                return
            }
            if let savedVpa = weakSelf.aiHandler.getSavedVPA(),
               !savedVpa.isEmpty {
                reject(weakSelf.errorCode, savedVpa, nil)
            } else {
                reject(weakSelf.errorCode, "No saved vpa", nil)
            }
        }
    }
}

private extension PaytmCustomuisdk {
//    func showConsentView(completion: @escaping (() -> Void)) {
//        let alertController = UIAlertController(title: "Provide Consent", message: nil, preferredStyle: .actionSheet)
//        guard let customView = AINativeConsentView(coder: NSCoder()) else {
//            return
//        }
//        alertController.view.addSubview(customView)
//        customView.translatesAutoresizingMaskIntoConstraints = false
//        customView.topAnchor.constraint(equalTo: alertController.view.topAnchor, constant: 45).isActive = true
//        customView.rightAnchor.constraint(equalTo: alertController.view.rightAnchor, constant: -100).isActive = true
//        customView.leftAnchor.constraint(equalTo: alertController.view.leftAnchor, constant: 100).isActive = true
//        customView.heightAnchor.constraint(equalToConstant: 70).isActive = true
//
//        let width = (UIScreen.main.bounds.width - 17)
//        customView.widthAnchor.constraint(equalToConstant: width).isActive = true
//
//        alertController.view.translatesAutoresizingMaskIntoConstraints = false
//        alertController.view.heightAnchor.constraint(equalToConstant: 180).isActive = true
//
//        let doneAction = UIAlertAction(title: "Done", style: .cancel) { _ in
//            alertController.dismiss(animated: true) {
//                completion()
//            }
//        }
//        alertController.addAction(doneAction)
//        self.viewController?.present(alertController, animated: true, completion: nil)
//    }
    
    func openRedirectionFlow(withResolver resolve: @escaping RCTPromiseResolveBlock, withRejecter reject: @escaping RCTPromiseRejectBlock) {
        
        guard !orderId.isEmpty else {
            reject(errorCode, "Invalid order id", nil)
            return
        }
        
        guard !txnToken.isEmpty else {
            reject(errorCode, "Invalid transaction token", nil)
            return
        }
        
        guard !merchantId.isEmpty else {
            reject(errorCode, "Invalid merchant id", nil)
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let weakSelf = self else {
                return
            }
            
            weakSelf.aiHandler.openRedirectionFlow(orderId: weakSelf.orderId, txnToken: weakSelf.txnToken, mid: weakSelf.merchantId, delegate: weakSelf)
        }
    }
    
    
}

extension PaytmCustomuisdk: AIDelegate {
    
    public func didFinish(with success: Bool, response: [String: Any], error: String?, withUserCancellation hasUserCancelledTransaction: Bool) {
        print(response)
        if hasUserCancelledTransaction {
            self.reject?(errorCode, "Transaxtion Canceled", nil)
        } else if let err = error {
            self.reject?(errorCode, err, nil)
        } else if success {
            self.resolve?(response)
        } else {
            //            self.reject?(errorCode, "Transaxtion Canceled", nil)
            self.resolve?(response)
            
        }
        
        //        commandDelegate!.send(pluginResult, callbackId: callbackId)
        if let presentedViewController = self.viewController?.presentedViewController {
            presentedViewController.dismiss(animated: true, completion: nil)
        }
        self.resolve = nil
        self.reject = nil
    }
    
    public func openPaymentController(_ controller: UIViewController) {
        self.viewController?.present(controller, animated: true, completion: nil)
    }
}
