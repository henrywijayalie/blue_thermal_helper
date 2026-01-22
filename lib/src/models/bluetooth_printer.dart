// lib/src/models/bluetooth_printer.dart

/// Represents a Bluetooth printer device.
///
/// This model contains basic information about a discovered or paired
/// Bluetooth printer device.
///
/// Example:
/// ```dart
/// final printer = BluetoothPrinter(
///   name: 'PANDA Printer',
///   address: '00:11:22:33:44:55',
/// );
/// ```
class BluetoothPrinter {
  /// The human-readable name of the Bluetooth device.
  ///
  /// This is typically the device name set by the manufacturer or user.
  /// May be empty if the device name is not available.
  final String name;

  /// The MAC address of the Bluetooth device.
  ///
  /// This is a unique identifier in the format "XX:XX:XX:XX:XX:XX"
  /// where X is a hexadecimal digit.
  ///
  /// Example: "00:11:22:33:44:55"
  final String address;

  /// Creates a new [BluetoothPrinter] instance.
  ///
  /// Both [name] and [address] are required parameters.
  BluetoothPrinter({
    required this.name,
    required this.address,
  });

  /// Creates a [BluetoothPrinter] from platform-specific data.
  ///
  /// This factory constructor is used internally to convert data
  /// received from the native platform (Android/iOS) into a
  /// [BluetoothPrinter] instance.
  ///
  /// Parameters:
  /// - [map]: A map containing 'name' and 'address' keys
  ///
  /// Returns: A new [BluetoothPrinter] instance with data from the map
  factory BluetoothPrinter.fromPlatform(Map<dynamic, dynamic> map) {
    return BluetoothPrinter(
      name: map['name']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
    );
  }

  @override
  String toString() => 'BluetoothPrinter(name: $name, address: $address)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BluetoothPrinter && other.address == address;
  }

  @override
  int get hashCode => address.hashCode;
}
