package com.austrianapps.flutter_watch_garmin_connectiq

import android.util.Log

inline fun formatMessage(message: () -> String) =
    "[${Thread.currentThread().name}] ${message()}"

inline fun Any.logd(message: () -> String) {
    Log.d(this::class.java.simpleName, formatMessage(message))
    //println(message())
}

inline fun Any.loge(tr: Throwable? = null, message: () -> String) {
    Log.e(this::class.java.simpleName, formatMessage(message), tr)
    //println(message())
}

inline fun Any.logw(tr: Throwable? = null, message: () -> String) {
    Log.w(this::class.java.simpleName, formatMessage(message), tr)
    //println(message())
}


