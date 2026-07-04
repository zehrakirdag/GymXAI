import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/services/gym_density_service.dart';

class ClientQrScanScreen extends StatefulWidget {
  final int clientUserId;

  const ClientQrScanScreen({
    super.key,
    required this.clientUserId,
  });

  @override
  State<ClientQrScanScreen> createState() => _ClientQrScanScreenState();
}

class _ClientQrScanScreenState extends State<ClientQrScanScreen> {
  final GymDensityService gymDensityService = GymDensityService();

  final MobileScannerController scannerController =
  MobileScannerController();

  bool isProcessing = false;

  Future<void> handleQr(String qrCode) async {
    if (isProcessing) return;

    setState(() {
      isProcessing = true;
    });

    try {
      final result = await gymDensityService.scanQr(
        userId: widget.clientUserId,
        qrCode: qrCode,
      );

      if (!mounted) return;

      final String type = result["type"] ?? "";

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor:
          type == "ENTRY" ? Colors.green : Colors.orange,
          content: Text(
            type == "ENTRY"
                ? "Salona giriş yapıldı."
                : "Salondan çıkış yapıldı.",
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst("Exception: ", ""),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("QR Giriş / Çıkış"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                MobileScanner(
                  controller: scannerController,
                  onDetect: (capture) {
                    final barcode = capture.barcodes.first;

                    final value = barcode.rawValue;

                    if (value != null &&
                        value.isNotEmpty &&
                        value == "GYM_ACCESS_QR") {
                      handleQr(value);
                    }
                  },
                ),

                Center(
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white,
                        width: 3,
                      ),
                    ),
                  ),
                ),

                if (isProcessing)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.qr_code_scanner_rounded,
                    size: 42,
                    color: AppColors.primary,
                  ),
                  SizedBox(height: 12),
                  Text(
                    "Salon QR Kodunu Okut",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Aynı QR kod hem giriş hem çıkış için kullanılır. Sistem hesabını tanır ve salon yoğunluğunu otomatik günceller.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}