import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:miniature_paint_finder/models/paint.dart';
import 'package:miniature_paint_finder/services/barcode_service.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';

/// A screen that allows users to scan paint barcodes to find paints
class BarcodeScannerScreen extends StatefulWidget {
  /// Creates a barcode scanner screen
  const BarcodeScannerScreen({Key? key}) : super(key: key);

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  final BarcodeService _barcodeService = BarcodeService();

  bool _isScanning = true;
  bool _isSearching = false;
  String? _lastScannedCode;
  Paint? _foundPaint;
  String? _errorMessage;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onBarcodeDetected(BarcodeCapture capture) async {
    // If already processing a barcode or not scanning, ignore
    if (_isSearching || !_isScanning) return;

    // Get barcode data
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final Barcode barcode = barcodes.first;
    final String? code = barcode.rawValue;

    // Validate code
    if (code == null || !_barcodeService.isValidBarcode(code)) {
      setState(() {
        _errorMessage = 'Invalid barcode format';
      });

      // Clear error after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _errorMessage = null;
          });
        }
      });

      return;
    }

    // Don't process the same code twice in a row
    if (code == _lastScannedCode) return;

    // Update state to show we're searching
    setState(() {
      _isSearching = true;
      _lastScannedCode = code;
      _errorMessage = null;
      _foundPaint = null;
    });

    // Look up the paint by barcode
    try {
      final Paint? paint = await _barcodeService.findPaintByBarcode(code);

      if (mounted) {
        setState(() {
          _isSearching = false;
          _foundPaint = paint;
          _isScanning = false; // Stop scanning after finding a paint

          if (paint == null) {
            _errorMessage = 'No paint found for this barcode';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _errorMessage = 'Error searching for paint: ${e.toString()}';
        });
      }
    }
  }

  void _resetScanner() {
    setState(() {
      _isScanning = true;
      _isSearching = false;
      _lastScannedCode = null;
      _foundPaint = null;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Barcode Scanner'),
        actions: [
          IconButton(
            icon: Icon(_isScanning ? Icons.flash_on : Icons.flash_off),
            onPressed: () => _scannerController.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => _scannerController.switchCamera(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                // Scanner view
                if (_isScanning)
                  MobileScanner(
                    controller: _scannerController,
                    onDetect: _onBarcodeDetected,
                  ),

                // Overlay when not scanning
                if (!_isScanning && _foundPaint != null)
                  _buildPaintDetailsView(),

                // Loading indicator
                if (_isSearching)
                  const Center(child: CircularProgressIndicator()),

                // Scan guide overlay
                if (_isScanning && !_isSearching) _buildScanGuideOverlay(),

                // Error message
                if (_errorMessage != null)
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Bottom controls
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (!_isScanning && _foundPaint != null)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _resetScanner,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Scan Another'),
                    ),
                  ),

                if (!_isScanning && _foundPaint != null)
                  const SizedBox(width: 16),

                if (!_isScanning && _foundPaint != null)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: Add to inventory or navigate to paint details
                        Navigator.of(context).pop(_foundPaint);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.purpleColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Use This Paint'),
                    ),
                  ),

                if (_isScanning)
                  Expanded(
                    child: Text(
                      'Scan a paint barcode',
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanGuideOverlay() {
    return Center(
      child: Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.primaryBlue, width: 3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.qr_code_scanner,
              size: 60,
              color: Colors.white.withOpacity(0.8),
            ),
            const SizedBox(height: 16),
            Text(
              'Position barcode in frame',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaintDetailsView() {
    final paint = _foundPaint!;
    final Color paintColor = Color(
      int.parse(paint.colorHex.substring(1), radix: 16) + 0xFF000000,
    );

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Paint color
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: paintColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Paint name
          Text(
            paint.name,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Paint brand & category
          Text(
            '${paint.brand} - ${paint.category}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Paint details
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[800]
                      : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildDetailRow('Color Code', paint.colorHex),
                const SizedBox(height: 8),
                _buildDetailRow('Barcode', _lastScannedCode ?? 'Unknown'),
                const SizedBox(height: 8),
                _buildDetailRow(
                  'Type',
                  [
                    if (paint.isMetallic) 'Metallic',
                    if (paint.isTransparent) 'Transparent',
                    if (!paint.isMetallic && !paint.isTransparent) 'Standard',
                  ].join(', '),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(value),
      ],
    );
  }
}
