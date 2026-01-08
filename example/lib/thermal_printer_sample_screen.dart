import 'dart:developer';
import 'package:blue_thermal_helper/blue_thermal_helper.dart';
import 'package:blue_thermal_helper/thermal_receipt.dart';
import 'package:flutter/material.dart';

/// Debug Screen – Thermal Printer Bluetooth
/// Fitur:
/// - Scan device
/// - Connect / Disconnect
/// - Auto-highlight device terakhir dipakai
/// - Print test ESC/POS (bold, align, cut)
/// - Status badge CONNECTED
class ThermalPrinterSampleScreen extends StatefulWidget {
  const ThermalPrinterSampleScreen({
    super.key,
  });

  @override
  State<ThermalPrinterSampleScreen> createState() =>
      _ThermalPrinterSampleScreenState();
}

class _ThermalPrinterSampleScreenState
    extends State<ThermalPrinterSampleScreen> {
  List<BluetoothPrinter> _devices = [];

  String _status = 'Idle';
  String? _connectedMac;
  String? _lastUsedMac;

  final _printer = BlueThermalHelper.instance;

  @override
  void initState() {
    super.initState();

    // _printer.events.listen((event) {
    //   log('EVENT: $event');
    //   if (!mounted) return;

    //   setState(() {
    //     _status = event['event'] ?? _status;

    //     if (event['event'] == 'connected') {
    //       _connectedMac = event['mac'];
    //       _lastUsedMac = event['mac'];
    //     }

    //     if (event['event'] == 'disconnected') {
    //       _connectedMac = null;
    //     }
    //   });
    // });
    _printer.setPaper(
      ThermalPaper.mm58,
    );
    _printer.events.listen(
      (
        event,
      ) {
        log(
          'EVENT: $event',
        );
        if (!mounted) return;

        final type = event['event']?.toString();

        setState(
          () {
            switch (type) {
              case 'connected':
                _connectedMac = event['mac'];
                _status = 'Connected';
                break;

              case 'disconnected':
                _connectedMac = null;
                _status = 'Disconnected';
                break;

              case 'error':
                _status = 'Error: ${event['message']}';
                break;

              default:
                _status = type ?? 'Unknown';
            }
          },
        );
      },
    );
  }

  Future<void> _scan() async {
    setState(
      () {
        _status = 'Scanning...';
        _devices.clear();
      },
    );

    try {
      final res = await _printer.scan(
        timeout: 8,
      );
      if (!mounted) return;

      setState(
        () {
          _devices = res;
          _status = 'Scan finished';
        },
      );
    } catch (e) {
      _show(
        'Scan failed: $e',
      );
    }
  }

  // Future<void> _connect(String mac) async {
  //   if (_connectedMac == mac) {
  //     _showAlreadyConnected();
  //     return;
  //   }

  //   try {
  //     setState(() => _status = 'Connecting...');
  //     await _printer.connect(mac);
  //   } catch (e) {
  //     _show('Connect failed: $e');
  //   }
  // }

  Future<void> _connect(
    String mac,
  ) async {
    if (_connectedMac == mac) {
      _showAlreadyConnected();
      return;
    }

    try {
      setState(
        () {
          _status = 'Connecting...';
          _connectedMac = mac; // <-- PENTING
        },
      );

      await _printer.connect(
        mac,
      );
    } catch (e) {
      setState(
        () {
          _connectedMac = null;
          _status = 'Connect failed';
        },
      );
      _show(
        'Connect failed: $e',
      );
    }
  }

  Future<void> _disconnect() async {
    try {
      await _printer.disconnect();
      setState(
        () {
          _status = 'Disconnected';
          _connectedMac = null;
        },
      );
    } catch (e) {
      _show(
        'Disconnect failed: $e',
      );
    }
  }

  Future<void> _buildReceipt(
    ThermalReceipt r,
  ) async {
    await r.logo(
      'assets/mpos.jpeg',
    ); // optional

    r.text(
      'Iga Bakar Rempah',
      bold: true,
      center: true,
      size: ThermalFontSize.large,
    );

    r.text(
      'Alam Sutera Town Center 10C no 38\nPakulonan, Kec. Serpong Utara\nKota Tangerang Selatan, Banten 15325',
      center: true,
    );

    r.hr();

    r.rowItem(
      qty: 1,
      name: 'Nasi Goreng Ayam',
      price: 35000,
    );
    r.rowItem(
      qty: 2,
      name: 'Teh Tarik',
      price: 15000,
    );
    r.rowItem(
      qty: 1,
      name: 'Iga Bakar Rempah',
      price: 65000,
    );

    r.hr();

    r.rowColumns(
      [
        r.col(
          'TOTAL',
          6,
          bold: true,
        ),
        r.colAuto(
          215000,
          6,
          type: ReceiptTextType.money,
          bold: true,
        ),
      ],
    );

    r.feed(
      2,
    );
    r.text(
      'Terima Kasih',
      center: true,
    );
    r.cut();
  }

  Future<void> _previewAndPrint() async {
    // ambil preview text
    final preview = await _printer.previewReceipt(
      _buildReceipt,
    );

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (
        _,
      ) {
        return AlertDialog(
          title: const Text(
            'Receipt Preview',
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Text(
                preview,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(
                context,
              ),
              child: const Text(
                'CANCEL',
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(
                Icons.print,
              ),
              label: const Text(
                'PRINT',
              ),
              onPressed: () async {
                Navigator.pop(
                  context,
                ); // tutup preview dulu

                if (!await _printer.isConnected()) {
                  _show(
                    'Printer not connected',
                  );
                  return;
                }

                try {
                  await _printer.printReceipt(
                    _buildReceipt,
                  );
                  _show(
                    'Print success',
                  );
                } catch (e) {
                  _show(
                    'Print failed: $e',
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Future<void> _printTest() async {
  //   if (!await _printer.isConnected()) {
  //     _show('Printer not connected');
  //     return;
  //   }

  //   try {
  //     await _printer.printReceipt((r) async {
  //       // optional
  //       // await r.logo('assets/logo.png');

  //       r.text(
  //         'TEST PRINT',
  //         bold: true,
  //         center: true,
  //         size: 2,
  //       );

  //       r.hr();

  //       r.row('Item A', '10.000');
  //       r.row('Item B', '20.000');

  //       r.hr();
  //       r.row('TOTAL', '30.000', bold: true);

  //       r.feed(2);
  //       r.text('Terima kasih', center: true);
  //       r.cut();
  //     });

  //     _show('Print success');
  //   } catch (e) {
  //     _show('Print failed: $e');
  //   }
  // }

  void _showAlreadyConnected() {
    showDialog(
      context: context,
      builder: (
        _,
      ) =>
          AlertDialog(
        title: const Text(
          'Info',
        ),
        content: const Text(
          'Device already connected!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(
              context,
            ),
            child: const Text(
              'OK',
            ),
          ),
        ],
      ),
    );
  }

  void _show(
    String msg,
  ) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content: Text(
          msg,
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Thermal Printer Debug',
        ),
        actions: [
          IconButton(
            onPressed: _scan,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
          if (_connectedMac != null)
            IconButton(
              onPressed: _disconnect,
              icon: const Icon(
                Icons.link_off,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          ListTile(
            title: const Text(
              'Status',
            ),
            subtitle: Text(
              _status,
            ),
            trailing: Icon(
              _connectedMac != null
                  ? Icons.bluetooth_connected
                  : Icons.bluetooth_disabled,
              color: _connectedMac != null ? Colors.green : Colors.red,
            ),
          ),
          const Divider(
            height: 1,
          ),
          Expanded(
            child: _buildDeviceList(),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(
            12,
          ),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              icon: const Icon(
                Icons.preview,
              ),
              label: const Text(
                'PREVIEW & PRINT',
              ),
              onPressed: _previewAndPrint,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceList() {
    if (_devices.isEmpty) {
      return const Center(
        child: Text(
          'No device found',
        ),
      );
    }

    return ListView.separated(
      itemCount: _devices.length,
      separatorBuilder: (_, __) => const Divider(
        height: 1,
      ),
      itemBuilder: (_, i) {
        final d = _devices[i];
        final isConnected = d.address == _connectedMac;
        final isLastUsed = d.address == _lastUsedMac;

        return Container(
          color: isLastUsed ? Colors.green.withValues(alpha: 0.08) : null,
          child: ListTile(
            title: Text(
              d.name.isNotEmpty ? d.name : 'Unknown',
            ),
            subtitle: Text(
              d.address,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isConnected)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(
                        12,
                      ),
                    ),
                    child: const Text(
                      'CONNECTED',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(
                  width: 8,
                ),
                ElevatedButton(
                  onPressed: () => _connect(
                    d.address,
                  ),
                  child: const Text(
                    'CONNECT',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
