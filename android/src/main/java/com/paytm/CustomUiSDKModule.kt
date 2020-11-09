package com.paytm

import android.app.Activity
import android.app.Application
import android.content.Context
import android.content.Intent
import android.text.TextUtils
import android.util.Log
import com.android.volley.VolleyError
import com.facebook.react.bridge.*
import com.google.gson.Gson
import net.one97.paytm.nativesdk.PaytmSDK
import net.one97.paytm.nativesdk.Utils.Server
import net.one97.paytm.nativesdk.app.PaytmSDKCallbackListener
import net.one97.paytm.nativesdk.common.Constants.SDKConstants
import net.one97.paytm.nativesdk.dataSource.models.*
import net.one97.paytm.nativesdk.instruments.upicollect.models.UpiOptionsModel
import net.one97.paytm.nativesdk.paymethods.datasource.PaymentMethodDataSource
import net.one97.paytm.nativesdk.transcation.model.TransactionInfo
import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject

class CustomUiSDKModule(private var reactContext: ReactApplicationContext) : ReactContextBaseJavaModule(reactContext), PaytmSDKCallbackListener, ActivityEventListener {
    companion object {
        const val ERROR_CODE = "0"
        const val BALANCE_REQUEST_CODE = 102
        const val SET_MPIN_REQUEST_CODE = 101
        const val UPI_PUSH_REQUEST_CODE = 100
        const val TAG = "PaytmCustomuisdk"
    }

    private var paytmSDK: PaytmSDK? = null
    private var transactionPromise: Promise? = null
    private var upiPaymentFlow: String? = null

    init {
        PaytmSDK.init(reactContext.applicationContext as Application)
        reactContext.addActivityEventListener(this)
        Log.d(TAG, "init")
    }

    override fun getName(): String {
        return TAG
    }

    @ReactMethod
    fun fetchAuthCode(clientId: String, mid: String, promise: Promise) {
        try {
            checkNull(clientId, "Client id")

            if (PaytmSDK.getPaymentsUtilRepository().isPaytmAppInstalled(reactContext)) {
                val authCode = PaytmSDK.getPaymentsUtilRepository().fetchAuthCode(reactContext.currentActivity as Context, clientId)
                if (authCode == null) {
                    promise.reject(ERROR_CODE, "Error accessing auth code")
                } else {
                    val result = Arguments.createMap()
                    result.putString("response", authCode)
                    promise.resolve(result as Any)
                }
            } else {
                promise.reject(ERROR_CODE, "App not installed")
            }
        } catch (e: Exception) {
            promise.reject(ERROR_CODE, e.toString())
        }
    }

    @ReactMethod
    fun initPaytmSDK(mid: String, orderId: String, txnToken: String, amount: String, isStaging: Boolean, callbackUrl: String?) {
        try {
            checkNull(mid, "Merchant id")
            checkNull(orderId, "Order id")
            checkNull(txnToken, "Transaction token")
            checkNull(amount, "Amount")

            val builder = PaytmSDK.Builder(
                    reactContext,
                    mid,
                    orderId,
                    txnToken, amount.toDouble(),
                    this
            )
            if (callbackUrl != null && callbackUrl != "null" && callbackUrl.isNotEmpty()) {
                builder.setMerchantCallbackUrl(callbackUrl)
            }
            if (isStaging) {
                PaytmSDK.setServer(Server.STAGING)
            } else {
                PaytmSDK.setServer(Server.PRODUCTION)
            }
            paytmSDK = builder.build()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    @ReactMethod
    fun isPaytmAppInstalled(promise: Promise) {
        try {
            promise.resolve(PaytmSDK.getPaymentsUtilRepository().isPaytmAppInstalled(reactContext))
        } catch (e: Exception) {
            promise.reject(ERROR_CODE, e.toString())
        }
    }

    @ReactMethod
    fun getEnvironment(promise: Promise) {
        try {
            promise.resolve(PaytmSDK.server.toString())
        } catch (e: Exception) {
            promise.reject(ERROR_CODE, e.toString())
        }
    }

    @ReactMethod
    fun setEnvironment(environment: String) {
        try {
            checkNull(environment, "Environment")

            if (environment.equals("STAGING", ignoreCase = true)) {
                PaytmSDK.setServer(Server.STAGING)
            } else if (environment.equals("PRODUCTION", ignoreCase = true)) {
                PaytmSDK.setServer(Server.PRODUCTION)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    @ReactMethod
    fun checkHasInstrument(mid: String, promise: Promise) {
        try {
            checkNull(mid, "Merchant id")

            val hasInstrument = PaytmSDK.getPaymentsUtilRepository().userHasSavedInstruments(reactContext, mid)
            promise.resolve(hasInstrument)
        } catch (e: Exception) {
            promise.reject(ERROR_CODE, e.toString())
        }
    }

    @ReactMethod
    fun goForWalletTransaction(paymentFlow: String, promise: Promise) {
        try {
            checkNull(paymentFlow, "Payment Flow")

            transactionPromise = promise
            val paymentRequestModel = WalletRequestModel(paymentFlow)
            paytmSDK!!.startTransaction(reactContext.currentActivity, paymentRequestModel)
        } catch (e: Exception) {
            promise.reject(ERROR_CODE, e.toString())
        }
    }

    @ReactMethod
    fun fetchEmiDetails(channelCode: String, cardType: String, promise: Promise) {
        try {
            checkNull(channelCode, "Channel code")
            checkNull(cardType, "CardType")

            PaytmSDK.getPaymentsHelper().getEMIDetails(reactContext, channelCode, cardType, object : PaymentMethodDataSource.Callback<JSONObject> {
              override fun onResponse(response: JSONObject?) {
                if (response != null) {
                  promise.resolve(getData(response))
                } else {
                  promise.reject(ERROR_CODE, "null")
                }
              }

              override fun onErrorResponse(error: VolleyError?, errorInfo: JSONObject?) {
                promise.reject(ERROR_CODE, errorInfo.toString())
              }
            })

        } catch (e: Exception) {
            promise.reject(ERROR_CODE, e.toString())
        }
    }

    @ReactMethod
    fun goForNewCardTransaction(cardNumber: String, cardExpiry: String, cardCvv: String, cardType: String, paymentFlow: String, channelCode: String, issuingBankCode: String, emiChannelId: String, authMode: String?, saveCard: Boolean, promise: Promise) {
        try {
            checkNull(cardNumber, "Card Number")
            checkNull(cardExpiry, "Card Expiry")
            checkNull(cardCvv, "Card Cvv")
            checkNull(cardType, "Card Type")
            checkNull(paymentFlow, "Payment Flow")
            checkNull(channelCode, "Channel Code")
            checkNull(issuingBankCode, "Issuing back code")

            transactionPromise = promise
            var authModeFinal = "otp"
            if (authMode != null && authMode != "") {
                authModeFinal = authMode
            }
            val cardRequestModel = CardRequestModel(
                    cardType,
                    paymentFlow,
                    cardNumber,
                    null,
                    cardCvv,
                    cardExpiry,
                    issuingBankCode,
                    channelCode,
                    authModeFinal,
                    emiChannelId,
                    saveCard)
            paytmSDK!!.startTransaction(reactContext.currentActivity, cardRequestModel)
        } catch (e: Exception) {
            promise.reject(ERROR_CODE, e.toString())
        }
    }

    @ReactMethod
    fun goForSavedCardTransaction(cardId: String, cardCvv: String, cardType: String, paymentFlow: String, channelCode: String, issuingBankCode: String, emiChannelId: String, authMode: String?, promise: Promise) {
        try {
            checkNull(cardId, "Card id")
            checkNull(cardCvv, "Card Cvv")
            checkNull(cardType, "Card Type")
            checkNull(paymentFlow, "Payment Flow")
            checkNull(channelCode, "Channel Code")
            checkNull(issuingBankCode, "Issuing back code")

            transactionPromise = promise
            var authModeFinal = "otp"
            if (authMode != null && authMode != "") {
                authModeFinal = authMode
            }
            val cardRequestModel = CardRequestModel(
                    cardType,
                    paymentFlow,
                    null,
                    cardId,
                    cardCvv,
                    null,
                    issuingBankCode,
                    channelCode,
                    authModeFinal,
                    emiChannelId,
                    true)
            paytmSDK!!.startTransaction(reactContext.currentActivity, cardRequestModel)
        } catch (e: Exception) {
            promise.reject(ERROR_CODE, e.toString())
        }
    }

    @ReactMethod
    fun goForNetBankingTransaction(netBankingCode: String, paymentFlow: String, promise: Promise) {
        try {
            checkNull(netBankingCode, "Net banking code")
            checkNull(paymentFlow, "Payment Flow")

            transactionPromise = promise
            val model = NetBankingRequestModel(paymentFlow, netBankingCode)
            paytmSDK!!.startTransaction(reactContext.currentActivity, model)
        } catch (e: Exception) {
            promise.reject(ERROR_CODE, e.toString())
        }
    }

    @ReactMethod
    fun goForUpiCollectTransaction(upiCode: String, paymentFlow: String, saveVPA: Boolean, promise: Promise) {
        try {
            checkNull(upiCode, "UPI code")
            checkNull(paymentFlow, "Payment Flow")

            transactionPromise = promise
            val model = UpiCollectRequestModel(paymentFlow, upiCode, saveVPA)
            upiPaymentFlow = paymentFlow
            paytmSDK!!.startTransaction(reactContext.currentActivity, model)
        } catch (e: Exception) {
            promise.reject(ERROR_CODE, e.toString())
        }
    }

    @ReactMethod
    fun getUpiIntentList(promise: Promise) {
        try {
            val upiIntentList = PaytmSDK.getPaymentsHelper().getUpiAppsInstalled(reactContext)
            val array = Arguments.createArray()
            for (item in upiIntentList) {
                val data = Arguments.createMap()
                data.putString("appName", item.appName)
                array.pushMap(data)
            }
            val finalList = Arguments.createMap()
            finalList.putArray("list", array)
            promise.resolve(finalList)
        } catch (e: Exception) {
            promise.reject(ERROR_CODE, e.toString())
        }
    }

    @ReactMethod
    fun goForUpiIntentTransaction(appName: String, paymentFlow: String, promise: Promise) {
        try {
            checkNull(appName, "App name")
            checkNull(paymentFlow, "Payment Flow")

            transactionPromise = promise
            val upiIntentList = PaytmSDK.getPaymentsHelper().getUpiAppsInstalled(reactContext)
            var model: UpiOptionsModel? = null
            for (item in upiIntentList) {
                if (appName == item.appName) {
                    model = item
                    break
                }
            }
            if (model != null) {
                val upiIntentDataRequestModel = UpiIntentRequestModel(
                        paymentFlow,
                        model.appName,
                        model.resolveInfo.activityInfo
                )
                upiPaymentFlow = paymentFlow
                paytmSDK!!.startTransaction(reactContext.currentActivity, upiIntentDataRequestModel)
            } else {
                promise.reject(ERROR_CODE, "No upi intent of $appName name found")
            }
        } catch (e: Exception) {
            promise.reject(ERROR_CODE, e.toString())
        }
    }

    @ReactMethod
    fun goForUpiPushTransaction(paymentFlow: String, bankAccountJson: ReadableMap, vpaName: String, merchantDetailsJson: ReadableMap, promise: Promise) {
        try {
            checkNull(bankAccountJson, "Bank Account object")
            checkNull(paymentFlow, "Payment Flow")
            checkNull(vpaName, "vpa")
            checkNull(merchantDetailsJson, "Merchant Detail object")

            val bankAccountJsonString = JSONObject(bankAccountJson.toHashMap()).toString()
            val merchantDetailsJsonString = JSONObject(merchantDetailsJson.toHashMap()).toString()

            transactionPromise = promise
            upiPaymentFlow = paymentFlow
            val upiPushRequestModel = UpiPushRequestModel(paymentFlow, vpaName, bankAccountJsonString, merchantDetailsJsonString, UPI_PUSH_REQUEST_CODE)
            paytmSDK!!.startTransaction(reactContext.currentActivity, upiPushRequestModel)
        } catch (e: Exception) {
            promise.reject(ERROR_CODE, e.toString())
        }
    }

    @ReactMethod
    fun fetchUpiBalance(bankAccountJson: ReadableMap, vpaName: String, promise: Promise) {
        try {
            checkNull(bankAccountJson, "Bank Account object")
            checkNull(vpaName, "vpa")

            val bankAccountJsonString = JSONObject(bankAccountJson.toHashMap()).toString()

            transactionPromise = promise
            val requestModel = UpiDataRequestModel(vpaName, bankAccountJsonString, BALANCE_REQUEST_CODE)
            paytmSDK!!.fetchUpiBalance(reactContext.currentActivity, requestModel)
        } catch (e: Exception) {
            promise.reject(ERROR_CODE, e.toString())
        }
    }

    @ReactMethod
    fun setUpiMpin(bankAccountJson: ReadableMap, vpaName: String, promise: Promise) {
        try {
            checkNull(bankAccountJson, "Bank Account object")
            checkNull(vpaName, "vpa")

            val bankAccountJsonString = JSONObject(bankAccountJson.toHashMap()).toString()

            transactionPromise = promise
            val requestModel = UpiDataRequestModel(vpaName, bankAccountJsonString, SET_MPIN_REQUEST_CODE)
            paytmSDK!!.setUpiMpin(reactContext.currentActivity, requestModel)
        } catch (e: Exception) {
            promise.reject(ERROR_CODE, e.toString())
        }
    }

    @ReactMethod
    fun getBin(cardSixDigit: String, tokenType: String, token: String, mid: String, referenceId: String?, promise: Promise) {
        try {
            checkNull(cardSixDigit, "Card digit")
            checkNull(tokenType, "Token type")
            checkNull(token, "Token")
            checkNull(mid, "Merchant id")

            if (tokenType.equals(SDKConstants.ACCESS, ignoreCase = true)) {
                checkNull(referenceId, "Reference id")

                PaytmSDK.getPaymentsHelper().fetchBinDetails(cardSixDigit, token, tokenType, mid, referenceId, object : PaymentMethodDataSource.Callback<JSONObject> {
                  override fun onResponse(response: JSONObject?) {
                    if (response != null) {
                      promise.resolve(getData(response))
                    } else {
                      promise.reject(ERROR_CODE, "null")
                    }
                  }

                  override fun onErrorResponse(error: VolleyError?, errorInfo: JSONObject?) {
                    promise.reject(ERROR_CODE, errorInfo.toString())
                  }
                })
            } else {
                PaytmSDK.getPaymentsHelper().fetchBinDetails(cardSixDigit, token, tokenType, mid, "", object : PaymentMethodDataSource.Callback<JSONObject> {
                  override fun onResponse(response: JSONObject?) {
                    if (response != null) {
                      promise.resolve(getData(response))
                    } else {
                      promise.reject(ERROR_CODE, "null")
                    }
                  }

                  override fun onErrorResponse(error: VolleyError?, errorInfo: JSONObject?) {
                    promise.reject(ERROR_CODE, errorInfo.toString())
                  }
                })
            }
        } catch (e: Exception) {
            promise.reject(ERROR_CODE, e.toString())
        }
    }

    @ReactMethod
    fun fetchNBList(tokenType: String, token: String, mid: String, orderId: String?, referenceId: String?, promise: Promise) {
        try {
            checkNull(tokenType, "Token type")
            checkNull(token, "Token")
            checkNull(mid, "Merchant id")
            if (tokenType == SDKConstants.ACCESS) {
                checkNull(referenceId, "Reference id")
                PaytmSDK.getPaymentsHelper().getNBList(mid, tokenType, token, referenceId, object : PaymentMethodDataSource.Callback<JSONObject> {
                  override fun onResponse(response: JSONObject?) {
                    if (response != null) {
                      promise.resolve(getData(response))
                    } else {
                      promise.reject(ERROR_CODE, "null")
                    }
                  }

                  override fun onErrorResponse(error: VolleyError?, errorInfo: JSONObject?) {
                    promise.reject(ERROR_CODE, errorInfo.toString())
                  }
                })
            } else {
                checkNull(orderId, "Order id")

                PaytmSDK.getPaymentsHelper().getNBList(mid, tokenType, token, orderId, object : PaymentMethodDataSource.Callback<JSONObject> {
                  override fun onResponse(response: JSONObject?) {
                    if (response != null) {
                      promise.resolve(getData(response))
                    } else {
                      promise.reject(ERROR_CODE, "null")
                    }
                  }

                  override fun onErrorResponse(error: VolleyError?, errorInfo: JSONObject?) {
                    promise.reject(ERROR_CODE, errorInfo.toString())
                  }
                })
            }
        } catch (e: Exception) {
            promise.reject(ERROR_CODE, e.toString())
        }
    }

    @ReactMethod
    fun getLastNBSavedBank(promise: Promise) {
        try {
            val bank = PaytmSDK.getPaymentsUtilRepository().getLastNBSavedBank()
            if (bank != null && bank.isNotEmpty()) {
                promise.resolve(bank)
            } else {
                promise.reject(ERROR_CODE, "No Saved Bank Found")
            }
        } catch (e: Exception) {
            promise.reject(ERROR_CODE, e.toString())
        }
    }

    @ReactMethod
    fun getLastSavedVPA(promise: Promise) {
        try {
            val vpa = PaytmSDK.getPaymentsUtilRepository().getLastSavedVPA()
            if (vpa != null && vpa.isNotEmpty()) {
                promise.resolve(vpa)
            } else {
                promise.reject(ERROR_CODE, "No Saved VPA Found")
            }
        } catch (e: Exception) {
            promise.reject(ERROR_CODE, e.toString())
        }
    }

    @ReactMethod
    fun isAuthCodeValid(clientId: String, authCode: String, promise: Promise) {
        try {
            checkNull(clientId, "Client id")
            checkNull(authCode, "AuthCode id")

            val isValid = PaytmSDK.getPaymentsUtilRepository().isValidAuthCode(reactContext, clientId, authCode)
            promise.resolve(isValid)
        } catch (e: Exception) {
            promise.reject(ERROR_CODE, e.toString())
        }
    }

    override fun onTransactionResponse(p0: TransactionInfo?) {
        try {
            if (p0 != null) {
                val s = Gson().toJson(p0.txnInfo)
                if (s != null) {
                    var jsonObject = JSONObject(s)
                    while (jsonObject.has("nameValuePairs")) {
                        jsonObject = jsonObject.getJSONObject("nameValuePairs")
                    }
                    transactionPromise?.resolve(getData(jsonObject))
                } else {
                    transactionPromise?.reject(ERROR_CODE, "null")
                }
            } else {
                transactionPromise?.reject(ERROR_CODE, "null")
            }
        } catch (e: Exception) {
            transactionPromise?.reject(ERROR_CODE, e.message)
        }
        finish()
    }

    override fun networkError() {
        transactionPromise?.reject(ERROR_CODE, "networkError")
        finish()
    }

    override fun onBackPressedCancelTransaction() {
        transactionPromise?.reject(ERROR_CODE, "onBackPressedCancelTransaction")
        finish()
    }

    override fun onGenericError(i: Int, s: String) {
        transactionPromise?.reject(ERROR_CODE, "onGenericError  $i $s")
        finish()
    }

    private fun finish() {
        paytmSDK?.clear()
        paytmSDK = null
        transactionPromise = null
        upiPaymentFlow = null
    }

    override fun onActivityResult(activity: Activity?, requestCode: Int, resultCode: Int, data: Intent?) {
        try {
            if (requestCode == UPI_PUSH_REQUEST_CODE && data != null) {
                val message = data.getStringExtra("nativeSdkForMerchantMessage")
                val response = data.getStringExtra("response")
                if (message != null && message.isNotEmpty()) {
                    transactionPromise?.reject(ERROR_CODE, message)
                } else if (response != null && response.isNotEmpty()) {
                    transactionPromise?.resolve(getData(JSONObject(response)))
                } else {
                    transactionPromise?.reject(ERROR_CODE, "null")
                }
                finish()
            } else if (requestCode == SET_MPIN_REQUEST_CODE && data != null) {
                val response = data.getStringExtra("response")
                if (response != null && response.isNotEmpty()) {
                    transactionPromise?.resolve(getData(JSONObject(response)))
                } else {
                    transactionPromise?.reject(ERROR_CODE, "null")
                }
            } else if (requestCode == BALANCE_REQUEST_CODE && data != null) {
                val response = data.getStringExtra("response")
                if (response != null && response.isNotEmpty()) {
                    transactionPromise?.resolve(getData(JSONObject(response)))
                } else {
                    transactionPromise?.reject(ERROR_CODE, "null")
                }
            } else if (requestCode == SDKConstants.REQUEST_CODE_UPI_APP) {
                if (data != null) {
                    val status = data.getStringExtra("Status")
                    if (status != null && !TextUtils.isEmpty(status) && status.equals("FAILURE", ignoreCase = true)) {
                        transactionPromise?.reject(ERROR_CODE, "Transaction failed")
                        finish()
                    } else {
                        PaytmSDK.getPaymentsHelper().makeUPITransactionStatusRequest(reactContext.currentActivity as Context, upiPaymentFlow
                                ?: "NONE")
                    }
                } else {
                    PaytmSDK.getPaymentsHelper().makeUPITransactionStatusRequest(reactContext.currentActivity as Context, upiPaymentFlow
                            ?: "NONE")
                }
            }
        } catch (e: Exception) {
            transactionPromise?.reject(ERROR_CODE, e.message)
        }
    }

    override fun onNewIntent(intent: Intent?) {
    }

    private fun getData(jsonObject: JSONObject?): WritableMap? {
        var data = Arguments.createMap()
        if (jsonObject != null) {
            data = convertJsonToMap(jsonObject)
        }
        return data
    }

    @Throws(JSONException::class)
    fun convertJsonToMap(jsonObject: JSONObject): WritableMap? {
        val map: WritableMap = WritableNativeMap()
        val iterator = jsonObject.keys()
        while (iterator.hasNext()) {
            val key = iterator.next()
            when (val value = jsonObject[key]) {
              is JSONObject -> {
                map.putMap(key, convertJsonToMap(value))
              }
              is JSONArray -> {
                map.putArray(key, convertJsonToArray(value))
              }
              is Boolean -> {
                map.putBoolean(key, value)
              }
              is Int -> {
                map.putInt(key, value)
              }
              is Double -> {
                map.putDouble(key, value)
              }
              is String -> {
                map.putString(key, value)
              }
                else -> {
                    map.putString(key, value.toString())
                }
            }
        }
        return map
    }

    @Throws(JSONException::class)
    fun convertJsonToArray(jsonArray: JSONArray): WritableArray? {
        val map: WritableArray = WritableNativeArray()
        for (i in 0 until jsonArray.length()) {
            when (val value = jsonArray.get(i)) {
              is JSONObject -> {
                map.pushMap(convertJsonToMap(value))
              }
              is JSONArray -> {
                map.pushArray(convertJsonToArray(value))
              }
              is Boolean -> {
                map.pushBoolean(value)
              }
              is Int -> {
                map.pushInt(value)
              }
              is Double -> {
                map.pushDouble(value)
              }
              is String -> {
                map.pushString(value)
              }
                else -> {
                    map.pushString(value.toString())
                }
            }
        }
        return map
    }

    @Throws(Exception::class)
    private fun checkNull(value: String?, message: String) {
        if (value == null) {
            throw NullPointerException("$message cannot be null")
        } else if (value.trim() == "") {
            throw Exception("$message cannot be empty")
        }
    }

    @Throws(Exception::class)
    private fun checkNull(value: ReadableMap?, message: String) {
        if (value == null) {
            throw NullPointerException("$message cannot be null")
        } else if (!value.keySetIterator().hasNextKey()) {
            throw Exception("$message cannot be empty")
        }
    }
}
