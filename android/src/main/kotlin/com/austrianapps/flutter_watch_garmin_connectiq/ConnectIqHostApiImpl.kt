package com.austrianapps.flutter_watch_garmin_connectiq

class ConnectIqHostApiImpl: ConnectIqHostApi {
    override fun initialize(callback: (Result<Boolean>) -> Unit) {
        callback(Result.success(true))
    }
}
