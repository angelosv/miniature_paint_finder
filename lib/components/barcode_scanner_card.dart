import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/models/paint.dart';
import 'package:miniature_paint_finder/screens/barcode_scanner_screen.dart';
import 'package:miniature_paint_finder/theme/app_dimensions.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';
import 'package:permission_handler/permission_handler.dart';

/// A card component that allows users to access the barcode scanner
class BarcodeScannerCard extends StatefulWidget {
  /// Optional callback for when a paint is found
  final Function(Paint)? onPaintFound;

  /// Creates a barcode scanner card
  const BarcodeScannerCard({Key? key, this.onPaintFound}) : super(key: key);

  @override
  State<BarcodeScannerCard> createState() => _BarcodeScannerCardState();
}

class _BarcodeScannerCardState extends State<BarcodeScannerCard> {
  bool _isCameraPermissionChecking = false;
  DateTime? _lastScanAttempt;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openBarcodeScanner,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppDimensions.paddingXL),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.marineOrange, AppTheme.marineGold],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          boxShadow: [
            BoxShadow(
              color: AppTheme.marineOrange.withOpacity(0.3),
              blurRadius: AppDimensions.elevationL,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                  child: Icon(
                    Icons.qr_code_scanner,
                    color: Colors.white,
                    size: AppDimensions.iconXL,
                  ),
                ),
                const SizedBox(width: AppDimensions.marginL),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Barcode Scanner',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: AppDimensions.marginXS),
                      Text(
                        'Find paints by scanning their barcodes',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.marginXL),
            Container(
              padding: const EdgeInsets.symmetric(
                vertical: AppDimensions.paddingM,
                horizontal: AppDimensions.paddingXL,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Scan Barcode',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.marineOrange,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.marginS),
                  Icon(Icons.arrow_forward, color: AppTheme.marineOrange),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openBarcodeScanner() async {
    // Evitar múltiples toques
    if (_isCameraPermissionChecking) return;

    // Prevenir múltiples aperturas rápidas que podrían confundir a la cámara
    final now = DateTime.now();
    if (_lastScanAttempt != null &&
        now.difference(_lastScanAttempt!).inSeconds < 2) {
      return;
    }

    _lastScanAttempt = now;

    setState(() {
      _isCameraPermissionChecking = true;
    });

    try {
      // Skip directly to scanner screen - it will handle permissions internally
      final Paint? scannedPaint = await Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
      );

      if (scannedPaint != null && mounted) {
        // Notificar al callback si existe
        if (widget.onPaintFound != null) {
          widget.onPaintFound!(scannedPaint);
        }

        // Mostrar notificación de éxito
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //     content: Text(
        //       'Found paint: ${scannedPaint.name} (${scannedPaint.brand})',
        //     ),
        //     duration: const Duration(seconds: 2),
        //   ),
        // );
      }
    } catch (e) {
      // Manejar cualquier error inesperado
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCameraPermissionChecking = false;
        });
      }
    }
  }
}
