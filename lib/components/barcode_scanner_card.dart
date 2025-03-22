import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/models/paint.dart';
import 'package:miniature_paint_finder/screens/barcode_scanner_screen.dart';
import 'package:miniature_paint_finder/theme/app_dimensions.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';

class BarcodeScannerCard extends StatelessWidget {
  const BarcodeScannerCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final Paint? scannedPaint = await Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
        );

        if (scannedPaint != null) {
          // Handle the scanned paint (e.g., show details or add to inventory)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Found paint: ${scannedPaint.name} (${scannedPaint.brand})',
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
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
}
