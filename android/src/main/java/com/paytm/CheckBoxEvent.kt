package com.paytm

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.WritableMap
import com.facebook.react.uimanager.events.Event
import com.facebook.react.uimanager.events.RCTEventEmitter

class CheckBoxEvent(var viewId: Int, private var isChecked: Boolean = false) : Event<CheckBoxEvent>(viewId) {

  companion object {
    const val EVENT_NAME = "checkBoxResponse"
  }

  override fun getEventName(): String {
    return EVENT_NAME
  }

  override fun dispatch(rctEventEmitter: RCTEventEmitter?) {
    rctEventEmitter!!.receiveEvent(viewTag, eventName, getData())
  }

  override fun getCoalescingKey(): Short {
    return 0
  }

  private fun getData(): WritableMap? {
    val data = Arguments.createMap()
    data.putInt("target", viewId)
    data.putBoolean("value", isChecked)
    return data
  }
}
