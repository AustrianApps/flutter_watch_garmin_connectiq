package com.shootformance.app

import android.util.Log

inline fun Any.logd(message: () -> String) {
    Log.d(this::class.java.simpleName, message())
    //println(message())
}

inline fun Any.loge(tr: Throwable? = null, message: () -> String) {
    Log.e(this::class.java.simpleName, message(), tr)
    //println(message())
}

inline fun Any.logw(tr: Throwable? = null, message: () -> String) {
    Log.w(this::class.java.simpleName, message(), tr)
    //println(message())
}


