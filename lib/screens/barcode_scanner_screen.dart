import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:miniature_paint_finder/models/paint.dart';
import 'package:miniature_paint_finder/services/barcode_service.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';
import 'package:permission_handler/permission_handler.dart';

/// A screen that allows users to scan paint barcodes to find paints
class BarcodeScannerScreen extends StatefulWidget {
  /// Creates a barcode scanner screen
  const BarcodeScannerScreen({Key? key}) : super(key: key);

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen>
    with WidgetsBindingObserver {
  MobileScannerController? _scannerController;
  final BarcodeService _barcodeService = BarcodeService();

  bool _isScanning = true;
  bool _isSearching = false;
  String? _lastScannedCode;
  Paint? _foundPaint;
  String? _errorMessage;
  bool _hasPermission = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Delay para asegurarnos que la UI se haya construido
    Future.delayed(Duration.zero, () {
      _checkPermissionsAndInitialize();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Cuando la app se resume, verificar permisos nuevamente
    if (state == AppLifecycleState.resumed) {
      _checkPermissionsAndInitialize();
    }
  }

  Future<void> _checkPermissionsAndInitialize() async {
    try {
      // Verificar el estado actual del permiso de cámara
      PermissionStatus status = await Permission.camera.status;

      // Si el permiso está denegado, solicitar permiso
      if (status.isDenied) {
        status = await Permission.camera.request();
      }

      // Actualizar estado según el permiso
      if (mounted) {
        setState(() {
          _hasPermission = status.isGranted;

          if (!_hasPermission) {
            _errorMessage =
                'Camera permission denied. Please enable it in settings.';
          } else {
            // Solo inicializar el scanner si tenemos permiso
            _initializeScanner();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error checking permissions: $e';
        });
      }
    }
  }

  Future<void> _initializeScanner() async {
    try {
      // Liberar recursos si ya existía un controlador
      if (_scannerController != null) {
        await _scannerController!.dispose();
      }

      // Crear un nuevo controlador
      _scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
        torchEnabled: false,
        formats: [
          BarcodeFormat.ean8,
          BarcodeFormat.ean13,
          BarcodeFormat.code128,
          BarcodeFormat.qrCode,
        ],
      );

      // Dar un poco de tiempo al sistema para inicializar
      await Future.delayed(const Duration(milliseconds: 500));

      // Iniciar el controlador
      if (_scannerController != null) {
        bool started = false;
        try {
          await _scannerController!.start();
          started = true;
        } catch (e) {
          print('Error starting scanner: $e');
          started = false;
        }

        if (mounted) {
          setState(() {
            _isInitialized = started;
            if (!started) {
              _errorMessage = 'Failed to start camera. Please restart the app.';
            }
          });
        }
      }
    } catch (e) {
      print('Scanner initialization error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Error initializing scanner: $e';
          _isInitialized = false;
        });
      }
    }
  }

  Future<void> _openAppSettings() async {
    await openAppSettings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scannerController?.dispose();
    super.dispose();
  }

  void _onBarcodeDetected(BarcodeCapture capture) async {
    // If already processing a barcode or not scanning, ignore
    if (_isSearching || !_isScanning || !_hasPermission || !_isInitialized)
      return;

    // Get barcode data
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final Barcode barcode = barcodes.first;
    final String? code = barcode.rawValue;

    print('Barcode detected: $code');

    // Validate code
    if (code == null || !_barcodeService.isValidBarcode(code)) {
      setState(() {
        _errorMessage = 'Invalid barcode format: ${code ?? "unknown"}';
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

    // Restart scanner
    if (_hasPermission && _scannerController != null) {
      _scannerController!.start();
    }
  }

  void _restartScanner() {
    // Reiniciar completamente el scanner
    _initializeScanner();
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
          if (_hasPermission && _isInitialized && _scannerController != null)
            IconButton(
              icon: Icon(_isScanning ? Icons.flash_on : Icons.flash_off),
              onPressed: () => _scannerController!.toggleTorch(),
            ),
          if (_hasPermission && _isInitialized && _scannerController != null)
            IconButton(
              icon: const Icon(Icons.flip_camera_ios),
              onPressed: () => _scannerController!.switchCamera(),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                // Scanner view
                if (_isScanning &&
                    _hasPermission &&
                    _isInitialized &&
                    _scannerController != null)
                  MobileScanner(
                    controller: _scannerController!,
                    onDetect: _onBarcodeDetected,
                  ),

                // No permission view
                if (!_hasPermission)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.no_photography,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Camera permission required',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Please allow camera access in your device settings',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _openAppSettings,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Open Settings'),
                        ),
                      ],
                    ),
                  ),

                // Scanner not initialized but has permission
                if (!_isInitialized && _hasPermission)
                  const Center(child: CircularProgressIndicator()),

                // Overlay when not scanning
                if (!_isScanning && _foundPaint != null)
                  _buildPaintDetailsView(),

                // Loading indicator
                if (_isSearching)
                  const Center(child: CircularProgressIndicator()),

                // Scan guide overlay
                if (_isScanning &&
                    !_isSearching &&
                    _hasPermission &&
                    _isInitialized &&
                    _scannerController != null)
                  _buildScanGuideOverlay(),

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

                if (_isInitialized && _hasPermission && _isScanning)
                  Expanded(
                    child: Text(
                      'Scan a paint barcode',
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ),

                if (!_hasPermission)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _checkPermissionsAndInitialize,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Request Camera Permission'),
                    ),
                  ),

                if (_hasPermission && !_isScanning)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _restartScanner,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Restart Scanner'),
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
