package com.austrianapps.flutter_watch_garmin_connectiq

import com.garmin.android.connectiq.ConnectIQ

class ConnectIqHostApiImpl: ConnectIqHostApi {
    override fun initialize(callback: (Result<Boolean>) -> Unit) {
        ConnectIQ.getInstance()
        callback(Result.success(true))
    }
}
