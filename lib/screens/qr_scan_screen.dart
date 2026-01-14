// // import 'package:flutter/material.dart';
// // import 'package:mobile_scanner/mobile_scanner.dart';
// // import 'package:geolocator/geolocator.dart';
// // import '../services/attendance_service.dart';
// //
// // class QrScanScreen extends StatefulWidget {
// //   final String action; // CHECKIN / CHECKOUT
// //   const QrScanScreen({super.key, required this.action});
// //
// //   @override
// //   State<QrScanScreen> createState() => _QrScanScreenState();
// // }
// //
// // class _QrScanScreenState extends State<QrScanScreen> {
// //   final MobileScannerController _controller = MobileScannerController();
// //   bool _processing = false;
// //   bool _cameraAllowed = true;
// //
// //   Future<Position> _getLocation() async {
// //     final enabled = await Geolocator.isLocationServiceEnabled();
// //     if (!enabled) throw Exception("Location services are OFF. Please enable GPS.");
// //
// //     var permission = await Geolocator.checkPermission();
// //     if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
// //     if (permission == LocationPermission.denied) throw Exception("Location permission denied.");
// //     if (permission == LocationPermission.deniedForever) {
// //       throw Exception("Location permission denied forever. Enable from settings.");
// //     }
// //
// //     return Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
// //   }
// //
// //   Future<void> _handleQr(String qrToken) async {
// //     if (_processing) return;
// //     setState(() => _processing = true);
// //
// //     try {
// //       final pos = await _getLocation();
// //
// //       final res = await AttendanceService.mark(
// //         action: widget.action,
// //         qrToken: qrToken,
// //         lat: pos.latitude,
// //         lng: pos.longitude,
// //         accuracyM: pos.accuracy,
// //       );
// //
// //       if (!mounted) return;
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(content: Text("Success: ${res["status"]}"), backgroundColor: Colors.green),
// //       );
// //
// //       await Future.delayed(const Duration(milliseconds: 900));
// //     } catch (e) {
// //       if (!mounted) return;
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(content: Text(e.toString().replaceFirst("Exception: ", "")), backgroundColor: Colors.redAccent),
// //       );
// //     } finally {
// //       if (mounted) setState(() => _processing = false);
// //       _controller.start();
// //     }
// //   }
// //
// //   @override
// //   void dispose() {
// //     _controller.dispose();
// //     super.dispose();
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     final title = widget.action == "CHECKIN" ? "Scan QR (Check-in)" : "Scan QR (Check-out)";
// //
// //     return Scaffold(
// //       appBar: AppBar(title: Text(title)),
// //       body: Stack(
// //         children: [
// //           MobileScanner(
// //             controller: _controller,
// //             onPermissionSet: (ctrl, allowed) {
// //               if (!mounted) return;
// //               setState(() => _cameraAllowed = allowed);
// //               if (!allowed) {
// //                 ScaffoldMessenger.of(context).showSnackBar(
// //                   const SnackBar(content: Text("Camera permission denied."), backgroundColor: Colors.redAccent),
// //                 );
// //               }
// //             },
// //             onDetect: (capture) async {
// //               if (_processing) return;
// //               final barcodes = capture.barcodes;
// //               if (barcodes.isEmpty) return;
// //
// //               final raw = barcodes.first.rawValue;
// //               if (raw == null || raw.trim().isEmpty) return;
// //
// //               _controller.stop();
// //               await _handleQr(raw.trim());
// //             },
// //           ),
// //
// //           if (!_cameraAllowed)
// //             const Center(
// //               child: Padding(
// //                 padding: EdgeInsets.all(16),
// //                 child: Text(
// //                   "Camera permission is required.\nPlease allow camera permission from settings.",
// //                   textAlign: TextAlign.center,
// //                 ),
// //               ),
// //             ),
// //
// //           if (_processing)
// //             Container(
// //               color: Colors.black.withOpacity(0.35),
// //               child: const Center(child: CircularProgressIndicator()),
// //             ),
// //         ],
// //       ),
// //     );
// //   }
// // }
//
// import 'package:flutter/material.dart';
// import 'package:mobile_scanner/mobile_scanner.dart';
// import 'package:geolocator/geolocator.dart';
// import '../services/attendance_service.dart';
//
// class QrScanScreen extends StatefulWidget {
//   final String action; // CHECKIN / CHECKOUT
//   const QrScanScreen({super.key, required this.action});
//
//   @override
//   State<QrScanScreen> createState() => _QrScanScreenState();
// }
//
// class _QrScanScreenState extends State<QrScanScreen> {
//   final MobileScannerController _controller = MobileScannerController();
//   bool _processing = false;
//   bool _cameraAllowed = true;
//   bool _starting = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _startScanner();
//   }
//
//   Future<void> _startScanner() async {
//     if (_starting) return;
//     _starting = true;
//
//     try {
//       await _controller.start();
//       if (!mounted) return;
//       setState(() => _cameraAllowed = true);
//     } on MobileScannerException catch (e) {
//       if (!mounted) return;
//
//       // permissionDenied / controllerAlreadyInitialized / etc.
//       final msg = e.errorCode == MobileScannerErrorCode.permissionDenied
//           ? "Camera permission denied."
//           : "Camera error: ${e.errorCode.name}";
//
//       setState(() => _cameraAllowed = false);
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
//       );
//     } catch (_) {
//       if (!mounted) return;
//       setState(() => _cameraAllowed = false);
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Camera start failed."), backgroundColor: Colors.redAccent),
//       );
//     } finally {
//       _starting = false;
//     }
//   }
//
//   Future<Position> _getLocation() async {
//     final enabled = await Geolocator.isLocationServiceEnabled();
//     if (!enabled) {
//       throw Exception("Location services are OFF. Please enable GPS.");
//     }
//
//     var permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//     }
//     if (permission == LocationPermission.denied) {
//       throw Exception("Location permission denied.");
//     }
//     if (permission == LocationPermission.deniedForever) {
//       throw Exception("Location permission denied forever. Enable from settings.");
//     }
//
//     return Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
//   }
//
//   Future<void> _handleQr(String qrToken) async {
//     if (_processing) return;
//     setState(() => _processing = true);
//
//     try {
//       final pos = await _getLocation();
//
//       final res = await AttendanceService.mark(
//         action: widget.action,
//         qrToken: qrToken,
//         lat: pos.latitude,
//         lng: pos.longitude,
//         accuracyM: pos.accuracy,
//       );
//
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("Success: ${res["status"]}"),
//           backgroundColor: Colors.green,
//         ),
//       );
//
//       await Future.delayed(const Duration(milliseconds: 900));
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(e.toString().replaceFirst("Exception: ", "")),
//           backgroundColor: Colors.redAccent,
//         ),
//       );
//     } finally {
//       if (mounted) setState(() => _processing = false);
//       await _startScanner();
//     }
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final title = widget.action == "CHECKIN" ? "Scan QR (Check-in)" : "Scan QR (Check-out)";
//
//     return Scaffold(
//       appBar: AppBar(title: Text(title)),
//       body: Stack(
//         children: [
//           MobileScanner(
//             controller: _controller,
//             onDetect: (capture) async {
//               if (_processing) return;
//
//               final barcodes = capture.barcodes;
//               if (barcodes.isEmpty) return;
//
//               final raw = barcodes.first.rawValue;
//               if (raw == null || raw.trim().isEmpty) return;
//
//               await _controller.stop();
//               await _handleQr(raw.trim());
//             },
//           ),
//
//           if (!_cameraAllowed)
//             const Center(
//               child: Padding(
//                 padding: EdgeInsets.all(16),
//                 child: Text(
//                   "Camera permission is required.\nPlease allow camera permission from settings.",
//                   textAlign: TextAlign.center,
//                 ),
//               ),
//             ),
//
//           if (_processing)
//             Container(
//               color: Colors.black54,
//               child: const Center(child: CircularProgressIndicator()),
//             ),
//         ],
//       ),
//     );
//   }
// }
//
//
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:geolocator/geolocator.dart';
import '../services/attendance_service.dart';

class QrScanScreen extends StatefulWidget {
  final String action; // "CHECKIN" / "CHECKOUT"
  const QrScanScreen({super.key, required this.action});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> with WidgetsBindingObserver {
  late final MobileScannerController _controller;

  bool _processing = false;
  bool _cameraAllowed = true;
  String _errorText = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _controller = MobileScannerController(
      autoStart: false, // lifecycle hum handle karenge
      facing: CameraFacing.back,
      torchEnabled: false,
      detectionSpeed: DetectionSpeed.noDuplicates,
    );

    // IMPORTANT: start after first frame so widget tree has MobileScanner attached
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScanner();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  // App lifecycle handling (recommended by package docs)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;

    if (state == AppLifecycleState.resumed) {
      _startScanner();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _controller.stop();
    }
  }

  Future<void> _startScanner() async {
    try {
      setState(() {
        _cameraAllowed = true;
        _errorText = "";
      });
      await _controller.start();
    } on MobileScannerException catch (e) {
      if (!mounted) return;

      final msg = switch (e.errorCode) {
        MobileScannerErrorCode.permissionDenied =>
        "Camera permission denied. Settings se camera allow karo.",
        MobileScannerErrorCode.unsupported =>
        "Camera unsupported on this device/emulator.",
        MobileScannerErrorCode.controllerUninitialized =>
        "Scanner not ready. Screen ko reload karo.",
        _ => "Camera error: ${e.errorCode.name}",
      };

      setState(() {
        _cameraAllowed = false;
        _errorText = msg;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cameraAllowed = false;
        _errorText = "Camera start failed.";
      });
    }
  }

  Future<Position> _getLocation() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw Exception("Location services OFF. GPS ON karo.");
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw Exception("Location permission denied.");
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception("Location permission denied forever. Settings se allow karo.");
    }

    return Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  Future<void> _handleQr(String qrToken) async {
    if (_processing) return;
    setState(() => _processing = true);

    try {
      final pos = await _getLocation();

      final res = await AttendanceService.mark(
        action: widget.action, // CHECKIN/CHECKOUT
        qrToken: qrToken,
        lat: pos.latitude,
        lng: pos.longitude,
        accuracyM: pos.accuracy,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ ${widget.action}: ${res["status"] ?? "Success"}"),
          backgroundColor: Colors.green,
        ),
      );

      // success ke baad thoda wait, then scan again (ya pop bhi kar sakte ho)
      await Future.delayed(const Duration(milliseconds: 900));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst("Exception: ", "")),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() => _processing = false);
      await _startScanner();
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.action == "CHECKIN" ? "Scan QR (Check-in)" : "Scan QR (Check-out)";

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: "Torch",
            onPressed: () => _controller.toggleTorch(),
            icon: const Icon(Icons.flash_on),
          ),
          IconButton(
            tooltip: "Switch camera",
            onPressed: () => _controller.switchCamera(),
            icon: const Icon(Icons.cameraswitch),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,

            // Best: show meaningful UI on permission/error
            errorBuilder: (context, error, child) {
              final msg = error.errorCode == MobileScannerErrorCode.permissionDenied
                  ? "Camera permission denied. Settings se allow karo."
                  : "Scanner error: ${error.errorCode.name}";

              return _ErrorView(
                title: "Camera Issue",
                message: msg,
                onRetry: _startScanner,
              );
            },

            onDetect: (capture) async {
              if (_processing) return;

              final barcodes = capture.barcodes;
              if (barcodes.isEmpty) return;

              final raw = barcodes.first.rawValue;
              if (raw == null || raw.trim().isEmpty) return;

              await _controller.stop();
              await _handleQr(raw.trim());
            },
          ),

          // custom overlay if permission denied or start failed
          if (!_cameraAllowed)
            _ErrorView(
              title: "Camera Permission Needed",
              message: _errorText.isEmpty
                  ? "Camera permission required."
                  : _errorText,
              onRetry: _startScanner,
            ),

          if (_processing)
            Container(
              color: Colors.black.withOpacity(0.35),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 44),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }
}
