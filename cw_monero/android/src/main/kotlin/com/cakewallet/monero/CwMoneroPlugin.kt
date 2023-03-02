package com.cakewallet.monero

import android.app.Activity
import android.os.AsyncTask
import android.os.Looper
import android.os.Handler
import android.os.Process

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar
import io.flutter.embedding.engine.plugins.FlutterPlugin

class doAsync(val handler: () -> Unit) : AsyncTask<Void, Void, Void>() {
    override fun doInBackground(vararg params: Void?): Void? {
        Process.setThreadPriority(Process.THREAD_PRIORITY_AUDIO);
        handler()
        return null
    }
}

/**
 * https://api.flutter.dev/javadoc/io/flutter/embedding/engine/plugins/FlutterPlugin.html
 * https://docs.flutter.dev/development/platform-integration/android/plugin-api-migration
 **/
class CwMoneroPlugin : MethodCallHandler, FlutterPlugin {
    companion object {
        //    val moneroApi = MoneroApi()
        val main = Handler(Looper.getMainLooper());

        init {
            System.loadLibrary("cw_monero")
        }

        @JvmStatic
        fun registerWith(registrar: Registrar) {
            val channel = MethodChannel(registrar.messenger(), "cw_monero")
            channel.setMethodCallHandler(CwMoneroPlugin())
        }
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {}

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {}

    override fun onMethodCall(call: MethodCall, result: Result) {
        if (call.method == "setupNode") {
            val uri = call.argument("address") ?: ""
            val login = call.argument("login") ?: ""
            val password = call.argument("password") ?: ""
            val useSSL = false
            val isLightWallet = false
//      doAsync {
//        try {
//          moneroApi.setNodeAddressJNI(uri, login, password, useSSL, isLightWallet)
//          main.post({
//            result.success(true)
//          });
//        } catch(e: Throwable) {
//          main.post({
//            result.error("CONNECTION_ERROR", e.message, null)
//          });
//        }
//      }.execute()
        }
        if (call.method == "startSync") {
//      doAsync {
//        moneroApi.startSyncJNI()
//        main.post({
//          result.success(true)
//        });
//      }.execute()
        }
        if (call.method == "loadWallet") {
            val path = call.argument("path") ?: ""
            val password = call.argument("password") ?: ""
//      moneroApi.loadWalletJNI(path, password)
            result.success(true)
        }
    }
}
