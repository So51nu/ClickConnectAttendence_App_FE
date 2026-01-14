import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class AdminQrViewScreen extends StatelessWidget {
  final String officeName;
  final String qrToken;

  const AdminQrViewScreen({
    super.key,
    required this.officeName,
    required this.qrToken,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("QR • $officeName")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            QrImageView(
              data: qrToken,
              size: 280,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SelectableText(
                qrToken,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            const Text("इस QR को print करके office में लगाओ."),
          ],
        ),
      ),
    );
  }
}
