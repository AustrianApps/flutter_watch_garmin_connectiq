package com.austrianapps.flutter_watch_garmin_connectiq

import com.garmin.android.connectiq.ConnectIQ
import com.garmin.android.connectiq.IQDevice
import com.garmin.android.connectiq.IQDevice.IQDeviceStatus
import com.shootformance.app.logd
import com.shootformance.app.logw
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding

class ConnectIqHostApiImpl(
    var binding: ActivityPluginBinding
) : ConnectIqHostApi {

    private lateinit var connectIQ: ConnectIQ
    private var sdkReady = false

    override fun initialize(callback: (Result<Boolean>) -> Unit) {
        connectIQ = ConnectIQ.getInstance(
            binding.activity.applicationContext,
            ConnectIQ.IQConnectType.WIRELESS
        )
        connectIQ.initialize(
            binding.activity.applicationContext,
            true,
            object : ConnectIQ.ConnectIQListener {
                override fun onSdkReady() {
                    logd { "Successfully initialized ConnectIQ sdk" }
                    sdkReady = true
                    callback(Result.success(true))
                }

                override fun onInitializeError(status: ConnectIQ.IQSdkErrorStatus?) {
                    logw { "initialize error for ConnectIQ sdk: $status" }
                    sdkReady = false
                    callback(Result.failure(FlutterError("initError", "$status")))
                }

                override fun onSdkShutDown() {
                    logd { "ConnectIQ sdk shutdown" }
                    sdkReady = false
                }

            })
    }

    override fun getKnownDevices(callback: (Result<List<PigeonIqDevice>>) -> Unit) {
        callback(Result.success(connectIQ.knownDevices.map {
            toPigeonIqDevice(it)
                .copy(status = connectIQ.getDeviceStatus(it).toPigeonDeviceStatus())
        }.toList()))
    }

    override fun getConnectedDevices(callback: (Result<List<PigeonIqDevice>>) -> Unit) {
        callback(Result.success(connectIQ.connectedDevices.map(this::toPigeonIqDevice).toList()))
    }

    private fun toPigeonIqDevice(device: IQDevice): PigeonIqDevice {
        return PigeonIqDevice(
            device.deviceIdentifier,
            device.friendlyName,
            device.status.toPigeonDeviceStatus(),
        )
    }
}

fun IQDeviceStatus?.toPigeonDeviceStatus() = when (this) {
    IQDevice.IQDeviceStatus.CONNECTED -> PigeonIqDeviceStatus.CONNECTED
    IQDevice.IQDeviceStatus.NOT_PAIRED -> PigeonIqDeviceStatus.NOTPAIRED
    IQDevice.IQDeviceStatus.NOT_CONNECTED -> PigeonIqDeviceStatus.NOTCONNECTED
    IQDevice.IQDeviceStatus.UNKNOWN, null -> PigeonIqDeviceStatus.UNKNOWN
}
