package com.rywtech.blue_thermal_helper

import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothSocket
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.IOException
import java.util.*
import kotlin.concurrent.thread

class BlueThermalHelperPlugin :
  FlutterPlugin,
  MethodChannel.MethodCallHandler,
  EventChannel.StreamHandler {

  private lateinit var methodChannel: MethodChannel
  private lateinit var eventChannel: EventChannel
  private var eventSink: EventChannel.EventSink? = null

  private val mainHandler = Handler(Looper.getMainLooper())
  private val bluetoothAdapter: BluetoothAdapter? = BluetoothAdapter.getDefaultAdapter()
  private var socket: BluetoothSocket? = null

  private val SPP_UUID: UUID =
    UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    methodChannel = MethodChannel(binding.binaryMessenger, "blue_thermal_helper/methods")
    eventChannel = EventChannel(binding.binaryMessenger, "blue_thermal_helper/events")
    methodChannel.setMethodCallHandler(this)
    eventChannel.setStreamHandler(this)
  }

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    when (call.method) {
      "scan" -> scanDevices(result)
      "connect" -> connect(call.argument("mac"), result)
      "disconnect" -> {
        disconnect()
        result.success(null)
      }
      "isConnected" -> result.success(socket?.isConnected == true)
      "printBytes" -> printBytes(call, result)
      else -> result.notImplemented()
    }
  }

  @SuppressLint("MissingPermission")
  private fun scanDevices(result: MethodChannel.Result) {
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

  @SuppressLint("MissingPermission")
private fun connect(mac: String?, result: MethodChannel.Result) {
  if (mac == null) {
    result.error("ARG", "mac null", null)
    return
  }

  val device = bluetoothAdapter?.getRemoteDevice(mac)

  Thread {
    try {
      socket?.close()
      socket = device?.createRfcommSocketToServiceRecord(SPP_UUID)
      bluetoothAdapter?.cancelDiscovery()
      socket?.connect()

      Handler(Looper.getMainLooper()).post {
        eventSink?.success(
          mapOf(
            "event" to "connected",
            "mac" to mac
          )
        )
        result.success(true)
      }

    } catch (e: Exception) {
      try { socket?.close() } catch (_: Exception) {}

      Handler(Looper.getMainLooper()).post {
        eventSink?.success(
          mapOf(
            "event" to "error",
            "message" to e.localizedMessage
          )
        )
        result.error("CONNECT_FAILED", e.localizedMessage, null)
      }
    }
  }.start()
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
      result.success(null)
    } catch (e: Exception) {
      result.error("IO", e.message, null)
    }
  }

  private fun disconnect() {
    try { socket?.close() } catch (_: Exception) {}
    socket = null
    emit(mapOf("type" to "connection", "state" to "disconnected"))
  }

  // =========================
  // Event helpers
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

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    methodChannel.setMethodCallHandler(null)
    eventChannel.setStreamHandler(null)
    eventSink = null
  }
}
