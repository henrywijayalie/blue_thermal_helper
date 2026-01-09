package com.rywtech.blue_thermal_helper

import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothSocket
import android.content.Intent
import android.content.pm.PackageManager
import android.Manifest
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.IOException
import java.util.UUID
import kotlin.concurrent.thread
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.math.min
import kotlin.math.pow
import kotlin.math.roundToLong

class BlueThermalHelperPlugin :
  FlutterPlugin,
  MethodChannel.MethodCallHandler,
  EventChannel.StreamHandler,
  ActivityAware {

  // Channels
  private lateinit var methodChannel: MethodChannel
  private lateinit var eventChannel: EventChannel
  private var eventSink: EventChannel.EventSink? = null

  // Android
  private val mainHandler = Handler(Looper.getMainLooper())
  private val bluetoothAdapter: BluetoothAdapter? = BluetoothAdapter.getDefaultAdapter()
  private var socket: BluetoothSocket? = null
  private var activity: Activity? = null

  // reconnect / monitor
  @Volatile private var lastConnectedMac: String? = null
  private val monitorRunning = AtomicBoolean(false)
  private val reconnectRunning = AtomicBoolean(false)

  private val SPP_UUID: UUID =
    UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")

  // =========================
  // FlutterPlugin
  // =========================
  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    methodChannel =
      MethodChannel(binding.binaryMessenger, "blue_thermal_helper/methods")
    eventChannel =
      EventChannel(binding.binaryMessenger, "blue_thermal_helper/events")

    methodChannel.setMethodCallHandler(this)
    eventChannel.setStreamHandler(this)
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    stopConnectionMonitor()
    methodChannel.setMethodCallHandler(null)
    eventChannel.setStreamHandler(null)
    eventSink = null
  }

  // =========================
  // ActivityAware (WAJIB)
  // =========================
  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivity() {
    activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
  }

  // =========================
  // MethodChannel
  // =========================
  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    when (call.method) {

      "scan" -> scanDevices(result)

      "connect" -> connect(call.argument("mac"), result)

      "disconnect" -> {
        disconnect()
        result.success(null)
      }

      "isConnected" ->
        result.success(socket?.isConnected == true)

      "printBytes" ->
        printBytes(call, result)

      "isBluetoothOn" -> {
        result.success(bluetoothAdapter?.isEnabled == true)
      }

      "requestEnableBluetooth" -> {
        val act = activity
        if (act == null) {
          result.error("NO_ACTIVITY", "Activity not attached", null)
          return
        }

        val intent = Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE)
        act.startActivity(intent)
        result.success(null)
      }

      else -> result.notImplemented()
    }
  }

  // =========================
  // Core logic
  // =========================
  @Suppress("MissingPermission")
  private fun scanDevices(result: MethodChannel.Result) {
    // check runtime permission BLUETOOTH_SCAN on Android 12+
    if (!hasPermission(Manifest.permission.BLUETOOTH_SCAN)) {
      result.error("NO_PERMISSION", "BLUETOOTH_SCAN not granted", null)
      return
    }

    val devices = mutableListOf<Map<String, String>>()

    bluetoothAdapter?.bondedDevices?.forEach {
      devices.add(
        mapOf(
          "name" to (it.name ?: "Unknown"),
          "address" to it.address
        )
      )
    }

    result.success(devices)
  }

  @Suppress("MissingPermission")
  private fun connect(mac: String?, result: MethodChannel.Result) {
    if (mac == null) {
      result.error("ARG", "mac null", null)
      return
    }

    // permission check: BLUETOOTH_CONNECT required for many calls on Android 12+/14+
    if (!hasPermission(Manifest.permission.BLUETOOTH_CONNECT)) {
      result.error("NO_PERMISSION", "BLUETOOTH_CONNECT not granted", null)
      return
    }

    val device = bluetoothAdapter?.getRemoteDevice(mac)

    thread {
      try {
        socket?.close()
        socket = device?.createRfcommSocketToServiceRecord(SPP_UUID)

        bluetoothAdapter?.cancelDiscovery()
        socket?.connect()

        lastConnectedMac = mac
        emit(
          mapOf(
            "event" to "connected",
            "mac" to mac
          )
        )

        // start monitor thread to detect broken socket
        startConnectionMonitor()

        mainHandler.post {
          result.success(true)
        }

      } catch (e: Exception) {
        try { socket?.close() } catch (_: Exception) {}
        socket = null

        emit(
          mapOf(
            "event" to "error",
            "message" to (e.localizedMessage ?: "Connect failed")
          )
        )

        mainHandler.post {
          result.error("CONNECT_FAILED", e.localizedMessage, null)
        }
      }
    }
  }

  private fun printBytes(call: MethodCall, result: MethodChannel.Result) {
    val bytes = call.argument<List<Int>>("bytes")
      ?.map { it.toByte() }
      ?.toByteArray()

    if (bytes == null) {
      result.error("ARG", "bytes null", null)
      return
    }

    try {
      socket?.outputStream?.write(bytes)
      socket?.outputStream?.flush()
      result.success(null)
    } catch (e: IOException) {
      // socket likely broken - emit event and try reconnect in background
      emit(mapOf("event" to "error", "message" to "IO:${e.localizedMessage}"))
      startReconnect(lastConnectedMac)
      result.error("IO", e.localizedMessage, null)
    } catch (e: Exception) {
      result.error("IO", e.localizedMessage, null)
    }
  }

  private fun disconnect() {
    stopConnectionMonitor()
    try { socket?.close() } catch (_: Exception) {}
    socket = null
    lastConnectedMac = null

    emit(
      mapOf(
        "event" to "disconnected"
      )
    )
  }

  // =========================
  // Monitor & reconnect
  // =========================
  private fun startConnectionMonitor() {
    if (monitorRunning.getAndSet(true)) return

    thread {
      while (monitorRunning.get()) {
        try {
          // if socket null or !connected -> attempt reconnect
          val s = socket
          if (s == null || !s.isConnected) {
            // not connected - trigger reconnect attempt
            startReconnect(lastConnectedMac)
            Thread.sleep(3000)
            continue
          }

          // try flush to detect broken pipe (will throw IOException if broken)
          try {
            s.outputStream.flush()
          } catch (io: IOException) {
            emit(mapOf("event" to "error", "message" to "Socket flush failed: ${io.localizedMessage}"))
            startReconnect(lastConnectedMac)
          }

          // check every 5 seconds
          Thread.sleep(5000)
        } catch (_: InterruptedException) {
          break
        } catch (t: Throwable) {
          // swallow unexpected exceptions, but keep monitor running
          emit(mapOf("event" to "error", "message" to "Monitor error: ${t.localizedMessage}"))
          Thread.sleep(3000)
        }
      }
    }
  }

  private fun stopConnectionMonitor() {
    monitorRunning.set(false)
  }

  private fun startReconnect(mac: String?) {
    if (mac == null) return
    if (reconnectRunning.getAndSet(true)) return

    thread {
      try {
        emit(mapOf("event" to "reconnecting", "mac" to mac))
        var attempt = 0
        val maxAttempts = 6
        while (reconnectRunning.get() && attempt < maxAttempts) {
          attempt++
          try {
            val device = bluetoothAdapter?.getRemoteDevice(mac)
            val newSocket = device?.createRfcommSocketToServiceRecord(SPP_UUID)
            bluetoothAdapter?.cancelDiscovery()
            newSocket?.connect()

            // success
            socket = newSocket
            lastConnectedMac = mac
            emit(mapOf("event" to "reconnected", "mac" to mac))
            // restart monitor
            startConnectionMonitor()
            reconnectRunning.set(false)
            return@thread
          } catch (e: Exception) {
            // wait with exponential backoff (cap 30s)
            val waitMs = min(30000.0, (1000.0 * 2.0.pow(attempt.toDouble()))).roundToLong()
            emit(mapOf("event" to "reconnect_attempt", "mac" to mac, "attempt" to attempt, "waitMs" to waitMs))
            Thread.sleep(waitMs)
          }
        }
        // failed after attempts
        emit(mapOf("event" to "reconnect_failed", "mac" to mac))
      } finally {
        reconnectRunning.set(false)
      }
    }
  }

  // =========================
  // Permissions helper (minimal - plugin still expects app to request)
  // =========================
  private fun hasPermission(permission: String): Boolean {
    val act = activity
    return if (act == null) {
      // no activity attached – be conservative
      false
    } else {
      act.checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED
    }
  }

  // =========================
  // EventChannel helpers
  // =========================
  private fun emit(event: Map<String, Any>) {
    mainHandler.post {
      eventSink?.success(event)
    }
  }

  override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
    eventSink = events
  }

  override fun onCancel(arguments: Any?) {
    eventSink = null
  }
}
