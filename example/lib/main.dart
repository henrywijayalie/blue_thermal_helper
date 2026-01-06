import 'package:blue_thermal_helper_example/thermal_printer_sample_screen.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Request Bluetooth permissions saat app start
  await _requestBluetoothPermissions();

  runApp(const MyApp());
}

// Fungsi untuk request Bluetooth permissions
Future<void> _requestBluetoothPermissions() async {
  try {
    // Request multiple permissions sekaligus
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location, // Diperlukan untuk Bluetooth scan di Android 10-11
    ].request();

    // Log hasil permission
    statuses.forEach((permission, status) {
      debugPrint('$permission: $status');
    });

    // Cek apakah semua permission granted
    bool allGranted = statuses.values.every((status) => status.isGranted);

    if (allGranted) {
      debugPrint('✅ All Bluetooth permissions granted');
    } else {
      debugPrint('⚠️ Some Bluetooth permissions denied');
    }
  } catch (e) {
    debugPrint('Error requesting Bluetooth permissions: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Thermal Printer App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const BluetoothPermissionChecker(),
    );
  }
}

// Widget untuk cek dan handle Bluetooth permission
class BluetoothPermissionChecker extends StatefulWidget {
  const BluetoothPermissionChecker({super.key});

  @override
  State<BluetoothPermissionChecker> createState() => _BluetoothPermissionCheckerState();
}

class _BluetoothPermissionCheckerState extends State<BluetoothPermissionChecker> with WidgetsBindingObserver {
  bool _hasPermission = false;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Cek ulang permission ketika app kembali dari background
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  // Cek status permission
  Future<void> _checkPermissions() async {
    setState(() => _isChecking = true);

    try {
      final bluetoothScan = await Permission.bluetoothScan.status;
      final bluetoothConnect = await Permission.bluetoothConnect.status;

      final hasPermission = bluetoothScan.isGranted && bluetoothConnect.isGranted;

      setState(() {
        _hasPermission = hasPermission;
        _isChecking = false;
      });
    } catch (e) {
      debugPrint('Error checking permissions: $e');
      setState(() => _isChecking = false);
    }
  }

  // Request permission dengan dialog
  Future<void> _requestPermissions() async {
    // Tampilkan dialog penjelasan
    final shouldRequest = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Izin Bluetooth Diperlukan'),
          content: const Text(
            'Aplikasi memerlukan izin Bluetooth untuk:\n\n'
            '• Mencari printer thermal\n'
            '• Terhubung ke printer\n'
            '• Mencetak struk\n\n'
            'Izinkan akses Bluetooth?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Nanti'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Izinkan'),
            ),
          ],
        );
      },
    );

    if (shouldRequest == true) {
      // Request permissions
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();

      // Cek hasilnya
      final allGranted = statuses.values.every((status) => status.isGranted);

      if (!allGranted) {
        // Jika ada yang ditolak, tanyakan apakah mau ke settings
        if (mounted) {
          final goToSettings = await showDialog<bool>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Izin Ditolak'),
                content: const Text(
                  'Beberapa izin Bluetooth ditolak. '
                  'Aplikasi tidak dapat berfungsi tanpa izin ini.\n\n'
                  'Buka pengaturan untuk memberikan izin?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Batal'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Buka Pengaturan'),
                  ),
                ],
              );
            },
          );

          if (goToSettings == true) {
            await openAppSettings();
          }
        }
      }

      // Cek ulang permission
      await _checkPermissions();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_hasPermission) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.bluetooth_disabled,
                  size: 80,
                  color: Colors.grey,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Izin Bluetooth Diperlukan',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Aplikasi memerlukan izin Bluetooth untuk terhubung ke printer thermal dan mencetak struk.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _requestPermissions,
                  icon: const Icon(Icons.bluetooth),
                  label: const Text('Berikan Izin Bluetooth'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Jika permission sudah granted, tampilkan halaman utama
    // Ganti dengan halaman utama Anda
    return const MainScreen();
  }
}

// Placeholder untuk halaman utama - ganti dengan halaman Anda
class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thermal Printer App'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 80, color: Colors.green),
            const SizedBox(height: 16),
            const Text(
              'Bluetooth Permission Granted!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // Navigate ke Print Screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ThermalPrinterSampleScreen(),
                  ),
                );
              },
              child: const Text('Buka Printer'),
            ),
          ],
        ),
      ),
    );
  }
}
