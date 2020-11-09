package com.paytm

import android.util.TypedValue
import android.widget.CompoundButton
import androidx.core.content.ContextCompat
import com.facebook.react.bridge.ReactContext
import com.facebook.react.common.MapBuilder
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.UIManagerModule
import com.paytm.R
import net.one97.paytm.nativesdk.common.widget.PaytmConsentCheckBox

class ConsentCheckBoxManager : SimpleViewManager<PaytmConsentCheckBox>() {

  var listener = CompoundButton.OnCheckedChangeListener { compoundButton, isChecked ->
    val reactContext = compoundButton.context as ReactContext
    reactContext.getNativeModule(UIManagerModule::class.java).eventDispatcher.dispatchEvent(CheckBoxEvent(compoundButton.id, isChecked))
  }

  override fun getName(): String {
    return "PaytmConsentCheckBox"
  }

  override fun createViewInstance(reactContext: ThemedReactContext): PaytmConsentCheckBox {
    val checkBox = PaytmConsentCheckBox(reactContext)
    checkBox.text = reactContext.resources.getString(R.string.consent_checkbox_message)
    checkBox.setTextSize(TypedValue.COMPLEX_UNIT_PX,
            reactContext.resources.getDimension(R.dimen.sp_18))
    return checkBox
  }

  override fun addEventEmitters(reactContext: ThemedReactContext, view: PaytmConsentCheckBox) {
    view.setOnCheckedChangeListener(listener)
  }

  override fun getExportedCustomDirectEventTypeConstants(): MutableMap<String, Any>? {
    return MapBuilder.of(CheckBoxEvent.EVENT_NAME,
      MapBuilder.of("registrationName", "onCheckChange"))
  }

}
