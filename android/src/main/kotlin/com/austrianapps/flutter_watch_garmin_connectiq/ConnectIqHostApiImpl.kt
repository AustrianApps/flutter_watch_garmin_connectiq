package com.austrianapps.flutter_watch_garmin_connectiq

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import com.garmin.android.connectiq.ConnectIQ
import com.garmin.android.connectiq.ConnectIQ.IQApplicationInfoListener
import com.garmin.android.connectiq.IQApp
import com.garmin.android.connectiq.IQDevice
import com.garmin.android.connectiq.IQDevice.IQDeviceStatus
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.lang.UnsupportedOperationException
import java.util.Date


data class AppCacheKey(val deviceId: String, val applicationId: MyUui)

data class AppCacheValue(
    val app: IQApp,
    val added: Date,
)

class MyUui(uuid: String) {
    private val uuid: String = uuid.uppercase().replace("-", "");

    override fun equals(other: Any?): Boolean {
        if (this === other) return true

        return (other as? MyUui)?.let { uuid == it.uuid } ?: false
    }

    override fun hashCode(): Int {
        return uuid.hashCode()
    }

    override fun toString(): String = uuid
}

class ConnectIqHostApiImpl(
    var binding: ActivityPluginBinding,
    val flutterConnectIqApi: FlutterConnectIqApi,
) : ConnectIqHostApi, ConnectIQ.IQApplicationEventListener, ConnectIQ.IQDeviceEventListener {

    private lateinit var connectIQ: ConnectIQ
    private lateinit var initOptions: InitOptions
    private var sdkReady = false

    private val appCache = mutableMapOf<AppCacheKey, IQApp?>()
    private val knownDevices = mutableMapOf<String, IQDevice>()
    private lateinit var applicationIds: List<String>

    private val scopeIo = CoroutineScope(Dispatchers.IO)

    override fun initialize(initOptions: InitOptions, callback: (Result<InitResult>) -> Unit) {
        this.initOptions = initOptions
        connectIQ = ConnectIQ.getInstance(
            binding.activity.applicationContext,
            when (initOptions.androidOptions.connectType) {
                ConnectType.WIRELESS -> ConnectIQ.IQConnectType.WIRELESS
                ConnectType.ADB -> ConnectIQ.IQConnectType.TETHERED
            }
        )
        applicationIds = initOptions.applicationIds.mapNotNull { it?.applicationId }
        initOptions.androidOptions.adbPort?.let { adbPort ->
            logd { "Setting adbPort to $adbPort" }
            connectIQ.adbPort = adbPort.toInt()
        }
        connectIQ.initialize(
            binding.activity.applicationContext,
            false,
            object : ConnectIQ.ConnectIQListener {
                override fun onSdkReady() {
                    logd { "onSdkReady: Successfully initialized ConnectIQ sdk" }
                    sdkReady = true
                    callback(Result.success(InitResult(InitStatus.SUCCESS)))
                    registerForAllDeviceEvents()
                }

                override fun onInitializeError(status: ConnectIQ.IQSdkErrorStatus) {
                    logw { "initialize error for ConnectIQ sdk: $status" }
                    sdkReady = false
                    val status = when (status) {
                        ConnectIQ.IQSdkErrorStatus.GCM_NOT_INSTALLED -> InitStatus.ERRORGCMNOTINSTALLED
                        ConnectIQ.IQSdkErrorStatus.GCM_UPGRADE_NEEDED -> InitStatus.ERRORGCMUPGRADENEEDED
                        ConnectIQ.IQSdkErrorStatus.SERVICE_ERROR -> InitStatus.ERRORSERVICEERROR
                    }
                    callback(Result.success(InitResult(status)))
                }

                override fun onSdkShutDown() {
                    logd { "ConnectIQ sdk shutdown" }
                    sdkReady = false
                }

            })
//        connectIQ.sendMessage()
    }

    private fun registerForAllDeviceEvents() {
        for (device in connectIQ.knownDevices) {
            logd { "registerForDeviceEvents for ${device.friendlyName} / ${device.status}" }
            val deviceStaus = connectIQ.getDeviceStatus(device)
            connectIQ.registerForDeviceEvents(device, this)
        }
    }

    private fun registerForAllApplicationEventsForDevice(device: IQDevice) {
        logd { "registering for application events for $applicationIds on ${device.friendlyName}" }
        scopeIo.launch {
            for (applicationId in applicationIds) {
                updateApplicationInfoAndRegisterForEvents(device, applicationId) { appResult ->
                    val app = appResult.getOrNull() ?: run {
                        logd { "Unable to register for app events." }
                        return@updateApplicationInfoAndRegisterForEvents
                    }
                    logd { "${device.friendlyName} ${app.displayName}: ${app.status}" }
                }
            }
        }
    }

    private suspend fun updateApplicationInfoAndRegisterForEvents(
        device: IQDevice,
        applicationId: String,
        callback: (appResult: Result<IQApp>) -> Unit
    ) {
        withContext(Dispatchers.IO) {
            try {
                connectIQ.getApplicationInfo(
                    applicationId,
                    device,
                    object : IQApplicationInfoListener {
                        override fun onApplicationInfoReceived(app: IQApp) {
                            logd { "onApplicationInfoReceived: ${app.toDebugString()}" }
                            appCache[AppCacheKey(
                                device.deviceIdentifier.toString(),
                                MyUui(app.applicationId)
                            )] = app
                            callback(Result.success(app))
                            scopeIo.launch {
                                registerForAppEvents(device, app)
                            }
                        }

                        override fun onApplicationNotInstalled(applicationId: String) {
                            onApplicationInfoReceived(
                                IQApp(applicationId, IQApp.IQAppStatus.NOT_INSTALLED, null, -1)
                            )
                        }

                    })
            } catch (e: Throwable) {
                logw(e) { "Unable to get application info for $applicationId" }
                callback(Result.failure(e))
            }
        }
    }

    override fun getKnownDevices(callback: (Result<List<PigeonIqDevice>>) -> Unit) {
        callback(Result.success(connectIQ.knownDevices.map {
            it.toPigeonDevice()
                .copy(status = connectIQ.getDeviceStatus(it).toPigeonDeviceStatus())
        }.toList()))
    }

    override fun getConnectedDevices(callback: (Result<List<PigeonIqDevice>>) -> Unit) {
        callback(Result.success(connectIQ.connectedDevices.map { it.toPigeonDevice() }.toList()))
    }

    private inline fun <T> withDevice(
        deviceId: String,
        callback: (Result<T>) -> Unit,
        body: (device: IQDevice) -> Unit
    ) {
        val device = knownDevices[deviceId] ?: run {
            callback(Result.failure(FlutterError("deviceNotFound")))
            return
        }
        body(device)
    }

    override fun getApplicationInfo(
        deviceId: String,
        applicationId: String,
        callback: (Result<PigeonIqApp>) -> Unit
    ) {
        val cb = CallbackWrapper(callback) { "getApplicationInfo($deviceId, $applicationId)" }
        scopeIo.launch {
            withDevice(deviceId, cb) { device ->
                updateApplicationInfoAndRegisterForEvents(device, applicationId) { appResult ->
                    appResult.fold({ app ->
                        cb(Result.success(app.toPigeonApp()))
                    }, { failure ->
                        cb(Result.failure(failure))
                    })

                }
            }
        }
    }

    private fun <T> withDeviceAndApp(
        deviceId: String,
        applicationId: String,
        callback: (Result<T>) -> Unit,
        body: (device: IQDevice, app: IQApp) -> Unit
    ) {

        val app = appCache[AppCacheKey(deviceId, MyUui(applicationId))]
            ?: if (initOptions.androidOptions.connectType == ConnectType.ADB) {
                // for adb there can only be one app.. and it has no correct id.. so just use it..
                appCache.values.firstOrNull()
            } else {
                null
            }
        if (app == null) {
            callback(Result.failure(FlutterError("unknownApp")))
            return
        }
        withDevice(deviceId, callback) { device ->
            body(device, app)
        }
    }

    override fun openApplication(
        deviceId: String,
        applicationId: String,
        callback: (Result<PigeonIqOpenApplicationResult>) -> Unit
    ) {
        scopeIo.launch {
            withDeviceAndApp(deviceId, applicationId, callback) { device, app ->
                connectIQ.openApplication(device, app) { iqDevice, iqApp, iqOpenApplicationStatus ->
                    logd { "openApplication(${app.applicationId} ${iqApp.toDebugString()}): $iqOpenApplicationStatus (vs: ${app.toDebugString()})" }
                    val response = PigeonIqOpenApplicationResult(
                        status = when (iqOpenApplicationStatus) {
                            ConnectIQ.IQOpenApplicationStatus.PROMPT_SHOWN_ON_DEVICE -> PigeonIqOpenApplicationStatus.PROMPTSHOWNONDEVICE
                            ConnectIQ.IQOpenApplicationStatus.PROMPT_NOT_SHOWN_ON_DEVICE -> PigeonIqOpenApplicationStatus.PROMPTNOTSHOWNONDEVICE
                            ConnectIQ.IQOpenApplicationStatus.APP_IS_NOT_INSTALLED -> PigeonIqOpenApplicationStatus.APPISNOTINSTALLED
                            ConnectIQ.IQOpenApplicationStatus.APP_IS_ALREADY_RUNNING -> PigeonIqOpenApplicationStatus.APPISALREADYRUNNING
                            ConnectIQ.IQOpenApplicationStatus.UNKNOWN_FAILURE, null -> PigeonIqOpenApplicationStatus.UNKNOWNFAILURE
                        }
                    )
                    callback(Result.success(response))
                }
            }
        }
    }

    override fun openStore(deviceId: String, app: AppId, callback: (Result<Boolean>) -> Unit) {
        app.storeId?.let { storeId ->
            val result = connectIQ.openStore(storeId)
            callback(Result.success(result))
        } ?: callback(Result.failure(FlutterError("MissingStoreId")))
    }

    override fun sendMessage(
        deviceId: String,
        applicationId: String,
        message: Map<String, Any>,
        callback: (Result<PigeonIqMessageResult>) -> Unit
    ) {
        scopeIo.launch {
            var submitted = false
            withDeviceAndApp(deviceId, applicationId, callback) { device, app ->
                connectIQ.sendMessage(
                    device,
                    app,
                    message
                ) { iqDevice: IQDevice, iqApp: IQApp, iqMessageStatus: ConnectIQ.IQMessageStatus ->
                    logd { "message status: $iqMessageStatus ($submitted)" }
                    if (submitted) {
                        return@sendMessage
                    }
                    submitted = true
                    val result = PigeonIqMessageResult(
                        status = when (iqMessageStatus) {
                            ConnectIQ.IQMessageStatus.SUCCESS -> PigeonIqMessageStatus.SUCCESS
                            ConnectIQ.IQMessageStatus.FAILURE_UNKNOWN -> PigeonIqMessageStatus.FAILUREUNKNOWN
                            ConnectIQ.IQMessageStatus.FAILURE_INVALID_FORMAT -> PigeonIqMessageStatus.FAILUREINVALIDFORMAT
                            ConnectIQ.IQMessageStatus.FAILURE_MESSAGE_TOO_LARGE -> PigeonIqMessageStatus.FAILUREMESSAGETOOLARGE
                            ConnectIQ.IQMessageStatus.FAILURE_UNSUPPORTED_TYPE -> PigeonIqMessageStatus.FAILUREUNSUPPORTEDTYPE
                            ConnectIQ.IQMessageStatus.FAILURE_DURING_TRANSFER -> PigeonIqMessageStatus.FAILUREDURINGTRANSFER
                            ConnectIQ.IQMessageStatus.FAILURE_INVALID_DEVICE -> PigeonIqMessageStatus.FAILUREINVALIDDEVICE
                            ConnectIQ.IQMessageStatus.FAILURE_DEVICE_NOT_CONNECTED -> PigeonIqMessageStatus.FAILUREDEVICENOTCONNECTED
                        }
                    )
                    callback(Result.success(result))
                }
            }
        }
    }

    override fun openStoreForGcm(callback: (Result<Unit>) -> Unit) {
        try {
            binding.activity.startActivity(
                Intent(
                    "android.intent.action.VIEW",
                    Uri.parse("market://details?id=com.garmin.android.apps.connectmobile")
                )
            )
        } catch (var4: ActivityNotFoundException) {
            binding.activity.startActivity(
                Intent(
                    "android.intent.action.VIEW",
                    Uri.parse("https://play.google.com/store/apps/details?id=com.garmin.android.apps.connectmobile")
                )
            )
        }
        callback(Result.success(Unit))

    }

    override fun iOsShowDeviceSelection(callback: (Result<Unit>) -> Unit) {
        callback(Result.failure(UnsupportedOperationException("Only used on iOS")))
    }

    private suspend fun registerForAppEvents(device: IQDevice, app: IQApp) {
        val self = this
        withContext(Dispatchers.IO) {
            try {
                logd { "Registering for app events of ${app.toDebugString()} for ${device.friendlyName}" }
                if (initOptions.androidOptions.connectType == ConnectType.ADB) {
                    // in adb mode app id is always ""
                    connectIQ.registerForAppEvents(device, IQApp(""), self)
                }
                connectIQ.registerForAppEvents(device, app, self)
            } catch (e: Throwable) {
                loge(e) { "Error while registering for app events." }
            }
        }
    }

    override fun onMessageReceived(
        device: IQDevice,
        app: IQApp,
        msgArray: MutableList<Any>,
        status: ConnectIQ.IQMessageStatus
    ) {
        // for some reason the message is wrapped in a list..
        val msg = msgArray.first()
        logd { "Received message ($status) from app {$app}: $msg" }
        flutterConnectIqApi.onMessageReceived(device.toPigeonDevice(), app.toPigeonApp(), msg) {}
    }

    override fun onDeviceStatusChanged(device: IQDevice, status: IQDeviceStatus) {
        logd { "device $device changed status to: $status (vs ${device.status})" }
        val d = device.copy(newStatus = status)
        knownDevices[device.deviceIdentifier.toString()] = d
        flutterConnectIqApi.onDeviceStatusChanged(d.toPigeonDevice()) {
        }
        if (d.status == IQDeviceStatus.CONNECTED) {
            registerForAllApplicationEventsForDevice(d)
        } else {
            logd { "Device is not connected. not registering for app events." }
        }
    }
}

fun IQDevice.copy(newStatus: IQDeviceStatus?) =
    IQDevice(deviceIdentifier, friendlyName).also { it.status = newStatus ?: status }

fun IQDevice.toPigeonDevice(newStatus: IQDeviceStatus? = null) = PigeonIqDevice(
    deviceIdentifier.toString(),
    friendlyName,
    (newStatus ?: status).toPigeonDeviceStatus(),
)

fun IQApp.toPigeonApp() = PigeonIqApp(
    applicationId = applicationId,
    status = when (status) {
        IQApp.IQAppStatus.INSTALLED -> PigeonIqAppStatus.INSTALLED
        IQApp.IQAppStatus.UNKNOWN, null -> PigeonIqAppStatus.UNKNOWN
        IQApp.IQAppStatus.NOT_INSTALLED -> PigeonIqAppStatus.NOTINSTALLED
        IQApp.IQAppStatus.NOT_SUPPORTED -> PigeonIqAppStatus.NOTSUPPORTED
    },
    displayName = displayName ?: "",
    version = version().toLong(),
)

fun IQDeviceStatus?.toPigeonDeviceStatus() = when (this) {
    IQDeviceStatus.CONNECTED -> PigeonIqDeviceStatus.CONNECTED
    IQDeviceStatus.NOT_PAIRED -> PigeonIqDeviceStatus.NOTPAIRED
    IQDeviceStatus.NOT_CONNECTED -> PigeonIqDeviceStatus.NOTCONNECTED
    IQDeviceStatus.UNKNOWN, null -> PigeonIqDeviceStatus.UNKNOWN
}

fun IQApp.toDebugString() = "IQApp($applicationId, $displayName, $status)"

class CallbackWrapper<T>(private var callback: ((Result<T>) -> Unit)?, private val debug: () -> String) :
        (Result<T>) -> Unit {
    override fun invoke(result: Result<T>) {
        val cb = callback
        if (cb != null) {
            cb(result)
            callback = null
        } else {
            logd { "WARNING: tried to call callback twice. ${debug()}" }
        }
    }

}