import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:miniature_paint_finder/components/scan_result_sheet.dart';
import 'package:miniature_paint_finder/data/sample_data.dart';
import 'package:miniature_paint_finder/models/paint.dart';
import 'package:miniature_paint_finder/models/palette.dart';
import 'package:miniature_paint_finder/services/barcode_service.dart';
import 'package:miniature_paint_finder/services/paint_service.dart';
import 'package:miniature_paint_finder/services/palette_service.dart';
import 'package:miniature_paint_finder/services/inventory_service.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:miniature_paint_finder/screens/palette_screen.dart';
import 'package:provider/provider.dart';
import 'package:miniature_paint_finder/services/auth_service.dart';
import 'package:miniature_paint_finder/utils/auth_utils.dart';
import 'package:miniature_paint_finder/widgets/guest_promo_modal.dart';
/// A screen that allows users to scan paint barcodes to find paints
class BarcodeScannerScreen extends StatefulWidget {
  /// Creates a barcode scanner screen
  const BarcodeScannerScreen({
    Key? key,
    this.paletteName,
  }) : super(key: key);

  /// Optional name of the palette being created
  final String? paletteName;

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen>
    with WidgetsBindingObserver {
  MobileScannerController? _scannerController;
  final BarcodeService _barcodeService = BarcodeService();
  final PaintService _paintService = PaintService();
  final PaletteService _paletteService = PaletteService();
  final InventoryService _inventoryService = InventoryService();

  bool _isScanning = true;
  bool _isSearching = false;
  String? _lastScannedCode;
  Paint? _foundPaint;
  String? _errorMessage;
  bool _hasPermission = false;
  bool _isInitialized = false;
  bool _isPermanentlyDenied = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Skip permission checks entirely and directly try to initialize
    Future.delayed(Duration.zero, () {
      print("Directly initializing camera without permission checks");
      _forceInitializeCamera();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print('App resumed, directly trying camera again');
      Future.delayed(const Duration(milliseconds: 500), () {
        _forceInitializeCamera(); // Try direct initialization again
      });
    }
  }

  // Force initialize camera without checking permissions first
  Future<void> _forceInitializeCamera() async {
    // Don't check permissions first - just try to access the camera directly
    print("FORCING camera initialization regardless of permission state");

    try {
      if (_scannerController != null) {
        try {
          await _scannerController!.stop();
          await _scannerController!.dispose();
        } catch (e) {
          print("Error stopping existing controller: $e");
        }
        _scannerController = null;
      }

      setState(() {
        _errorMessage = null;
        _isInitialized = false;
      });

      // Use a more aggressive direct initialization strategy
      print("Creating minimal scanner controller");
      _scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        formats: [BarcodeFormat.ean13],
      );

      print("Starting camera WITHOUT checking permissions first");
      await _scannerController!.start();
      print("SUCCESS! Camera started without permission checks");

      // If we got here, the camera is working
      setState(() {
        _hasPermission = true;
        _isInitialized = true;
        _errorMessage = null;
      });
    } catch (e) {
      print("Direct camera initialization error: $e");

      // Now check if this is a permission issue
      if (e.toString().toLowerCase().contains("permission") ||
          e.toString().toLowerCase().contains("denied")) {
        print("Looks like a permission error - requesting permission");

        // Only now request permission since we know we need it
        final status = await Permission.camera.request();
        print("Permission request result: ${status.toString()}");

        if (status.isGranted) {
          print("Permission granted after request, trying again");
          _forceInitializeCamera(); // Try again with new permission
        } else {
          setState(() {
            _hasPermission = false;
            _isInitialized = false;
            _isPermanentlyDenied = status.isPermanentlyDenied;
            _errorMessage =
                status.isPermanentlyDenied
                    ? 'Camera permission permanently denied. Please enable it in your device settings.'
                    : 'Camera permission required to use scanner.';
          });
        }
      } else {
        // Some other non-permission related error
        setState(() {
          _errorMessage = 'Error initializing camera: $e';
          _isInitialized = false;

          // We'll assume we have permission but hardware issue
          _hasPermission = true;
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_scannerController != null) {
      _scannerController!.stop();
      _scannerController!.dispose();
      _scannerController = null;
    }
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

    final currentUser = FirebaseAuth.instance.currentUser;
    final isGuestUser = currentUser == null || currentUser.isAnonymous;

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
      print('🔍 Searching for paint with barcode: $code');
      final List<Paint>? paints = await _barcodeService.findPaintByBarcode(code, isGuestUser);

      if (mounted) {
        setState(() {
          _isSearching = false;
          _isScanning = false; // Stop scanning after finding paints

          if (paints == null || paints.isEmpty) {
            _errorMessage = 'No paint found for this barcode';
            // Automatically clear error and restart scanning after 3 seconds if no paint found
            Future.delayed(const Duration(seconds: 3), () {
              if (mounted && _errorMessage != null && _foundPaint == null) {
                _resetScanner();
              }
            });
          } else if (paints.length == 1) {
            // Si solo hay una pintura, mostrarla directamente
            _foundPaint = paints[0];
            _showScanResultSheet(_foundPaint!);
          } else {
            // Si hay múltiples pinturas, mostrar diálogo de selección
            _showPaintSelectionDialog(paints);
          }
        });
      }
    } catch (e) {
      print('❌ Error searching for paint: $e');
      if (mounted) {
        setState(() {
          _isSearching = false;
          _errorMessage = 'Error searching for paint: ${e.toString()}';
          // Automatically clear error and restart scanning after 3 seconds
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted && _errorMessage != null) {
              _resetScanner();
            }
          });
        });
      }
    }
  }

  void _showPaintSelectionDialog(List<Paint> paints) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isGuestUser = currentUser == null || currentUser.isAnonymous;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Paint'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: paints.length,
              itemBuilder: (context, index) {
                final paint = paints[index];
                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(int.parse(paint.hex.substring(1), radix: 16) + 0xFF000000),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  title: Text(paint.name),
                  subtitle: Text('${paint.brand} - ${paint.code}'),
                  onTap: () async {
                    if (isGuestUser) {
                      GuestPromoModal.showForRestrictedFeature(
                        context,
                        'Paint Actions',
                      );
                    } else {
                      Navigator.pop(context);
                      _foundPaint = paint;
                      _showScanResultSheet(paint);
                    }
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _resetScanner();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // Show the scan result bottom sheet
  void _showScanResultSheet(Paint paint) {
    // Get the real paint status using the service
    final bool isInInventory = _paintService.isInInventory(paint.id);
    final int? inventoryQuantity = _paintService.getInventoryQuantity(paint.id);
    final bool isInWishlist = _paintService.isInWishlist(paint.id);
    final List<Palette> inPalettes = _paintService.getPalettesContainingPaint(
      paint.id,
    );
    final List<Palette> userPalettes = _paintService.getUserPalettes();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: const BoxDecoration(color: Colors.transparent),
          child: ScanResultSheet(
            paint: paint,
            isInInventory: isInInventory,
            inventoryQuantity: inventoryQuantity,
            isInWishlist: isInWishlist,
            inPalettes: inPalettes,
            userPalettes: userPalettes,
            paletteName: widget.paletteName,
            onAddToInventory: (paint, quantity, note) async {
              try {
                // Use the inventory service to add to inventory
                final success = await _inventoryService.addInventoryRecord(
                  brandId: paint.brandId ?? '',
                  paintId: paint.id,
                  quantity: quantity,
                  notes: note ?? '',
                );
                print('✅ Inventory add result: $success');

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Paint added to inventory!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }

                Navigator.pop(context);
                Navigator.pop(context, paint);
              } catch (e) {
                print('❌ Error adding to inventory: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error adding to inventory: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            onUpdateInventory: (paint, quantity, note) async {
              try {
                // Use the inventory service to update inventory
                final success = await _inventoryService.updateStockFromApi(paint.id, quantity);
                if (note != null) {
                  await _inventoryService.updateNotesFromApi(paint.id, note);
                }
                print('✅ Inventory update result: $success');

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Inventory updated!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }

                Navigator.pop(context);
                Navigator.pop(context, paint);
              } catch (e) {
                print('❌ Error updating inventory: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating inventory: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            onAddToWishlist: (paint, isPriority) async {
              // Use the service to add to wishlist
              await _paintService.addToWishlist(paint, isPriority);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Paint added to wishlist!'),
                    backgroundColor: Colors.amber,
                  ),
                );
              }

              Navigator.pop(context);
              Navigator.pop(context, paint);
            },
            onAddToPalette: (paint, palette) async {
              final user = FirebaseAuth.instance.currentUser;
              final token = await user?.getIdToken();
              final _palette = await _paletteService.createPalette(palette.name, token ?? '');
              final paletteId = _palette['id'];
              await _paletteService.addPaintsToPalette(paletteId, [ { "paint_id": paint.id, "brand_id": paint.brandId } ], token ?? '');

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Paint added to palette ${palette.name}!'),
                    backgroundColor: Colors.purple,
                  ),
                );
              }

              // Navigator.pop(context);
              // Navigator.pop(context, paint);
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const PaletteScreen()),
                (Route<dynamic> route) => false, // elimina todo lo anterior
              );
            },
            onFindEquivalents: (paint) async {
              // Close the modal first
              Navigator.pop(context);

              // Show loading
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Searching for equivalents...'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }

              // Use the service to search for equivalents
              try {
                final equivalents = await _paintService.findEquivalents(paint);

                if (mounted) {
                  // Here we would normally navigate to an equivalents screen
                  // For demo, just show a message with the count
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Found ${equivalents.length} equivalent paints',
                      ),
                      action: SnackBarAction(
                        label: 'View',
                        onPressed: () {
                          // Here we would navigate to the equivalents screen
                        },
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error finding equivalents: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }

              Navigator.pop(context, paint);
            },
            onPurchase: (paint) {
              // Here we would implement navigation to purchase screen
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Checking availability for ${paint.name}...'),
                  duration: const Duration(seconds: 2),
                ),
              );

              Navigator.pop(context);
              Navigator.pop(context, paint);
            },
            onClose: () {
              Navigator.pop(context);
              _resetScanner();
            },
          ),
        );
      },
    ).then((_) {
      // When the bottom sheet is closed, reset the scanner if we're still on this screen
      if (mounted && !_isScanning) {
        _resetScanner();
      }
    });
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
    // Restart the scanner completely
    _forceInitializeCamera();
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
              tooltip: 'Toggle flash',
            ),
          if (_hasPermission && _isInitialized && _scannerController != null)
            IconButton(
              icon: const Icon(Icons.flip_camera_ios),
              onPressed: () => _scannerController!.switchCamera(),
              tooltip: 'Switch camera',
            ),
          // Botón de debug con menú para simular diferentes escenarios
          PopupMenuButton<String>(
            icon: const Icon(Icons.bug_report),
            tooltip: 'Simulate scan',
            onSelected: (String scenario) {
              final paints = SampleData.getPaints();
              Paint selectedPaint;

              switch (scenario) {
                case 'random':
                  final randomIndex =
                      DateTime.now().millisecondsSinceEpoch % paints.length;
                  selectedPaint = paints[randomIndex];
                  break;
                case 'in_inventory':
                  // Simulate a paint that's already in inventory
                  selectedPaint = paints.firstWhere(
                    (p) => _paintService.isInInventory(p.id),
                    orElse: () => paints.first,
                  );
                  break;
                case 'not_in_inventory':
                  // Simulate a paint that exists but is NOT in inventory or wishlist
                  selectedPaint = paints.firstWhere(
                    (p) =>
                        !_paintService.isInInventory(p.id) &&
                        !_paintService.isInWishlist(p.id),
                    orElse: () => paints.first,
                  );
                  break;
                case 'in_wishlist':
                  // Simulate a paint that's already in wishlist
                  selectedPaint = paints.firstWhere(
                    (p) => _paintService.isInWishlist(p.id),
                    orElse: () => paints.first,
                  );
                  break;
                case 'in_palette':
                  // Simulate a paint that's in some palette
                  selectedPaint = paints.firstWhere(
                    (p) =>
                        _paintService
                            .getPalettesContainingPaint(p.id)
                            .isNotEmpty,
                    orElse: () => paints.first,
                  );
                  break;
                case 'metallic':
                  // Simulate a metallic paint
                  selectedPaint = paints.firstWhere(
                    (p) => p.isMetallic,
                    orElse: () => paints.first,
                  );
                  break;
                case 'transparent':
                  // Simulate a transparent paint
                  selectedPaint = paints.firstWhere(
                    (p) => p.isTransparent,
                    orElse: () => paints.first,
                  );
                  break;
                default:
                  selectedPaint = paints.first;
              }

              print(
                'Simulating paint scan: ${selectedPaint.name} (${selectedPaint.brand})',
              );
              _showScanResultSheet(selectedPaint);
            },
            itemBuilder:
                (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'random',
                    child: Text('Random paint'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'in_inventory',
                    child: Text('Paint in inventory'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'not_in_inventory',
                    child: Text('Paint not in inventory'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'in_wishlist',
                    child: Text('Paint in wishlist'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'in_palette',
                    child: Text('Paint in palette'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'metallic',
                    child: Text('Metallic paint'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'transparent',
                    child: Text('Transparent paint'),
                  ),
                ],
          ),
          // Add refresh button to forcibly restart camera permissions and initialization
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              print('Manual camera refresh requested');
              // Force permission refresh
              Permission.camera.shouldShowRequestRationale.then((_) {
                Permission.camera.status.then((status) {
                  print('Manual refresh - Camera status: ${status.toString()}');
                  _forceInitializeCamera();
                });
              });
            },
            tooltip: 'Refresh camera',
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
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            _isPermanentlyDenied
                                ? 'You have permanently denied camera access. Please enable it in your device settings to scan barcodes.'
                                : 'Please allow camera access to scan paint barcodes',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _isPermanentlyDenied
                              ? _openAppSettings
                              : _forceInitializeCamera,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                          ),
                          icon: Icon(
                            _isPermanentlyDenied
                                ? Icons.settings
                                : Icons.camera_alt,
                          ),
                          label: Text(
                            _isPermanentlyDenied
                                ? 'Open Settings'
                                : 'Request Camera Permission',
                          ),
                        ),
                      ],
                    ),
                  ),

                // Scanner not initialized but has permission
                if (!_isInitialized && _hasPermission)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        const Text('Initializing camera...'),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 24),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _restartScanner,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryBlue,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('Back'),
                          ),
                        ],
                      ],
                    ),
                  ),

                // Loading indicator
                if (_isSearching)
                  _buildSearchingOverlay(),

                // Scan guide overlay
                if (_isScanning &&
                    !_isSearching &&
                    _hasPermission &&
                    _isInitialized &&
                    _scannerController != null)
                  _buildScanGuideOverlay(),

                // Error message
                if (_errorMessage != null)
                  _buildErrorOverlay(),
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
                if (_isInitialized && _hasPermission && _isScanning)
                  Expanded(
                    child: Text(
                      'Position barcode in frame to scan',
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ),

                if (!_hasPermission)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                          _isPermanentlyDenied
                              ? _openAppSettings
                              : _forceInitializeCamera,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                      ),
                      icon: Icon(
                        _isPermanentlyDenied
                            ? Icons.settings
                            : Icons.camera_alt,
                      ),
                      label: Text(
                        _isPermanentlyDenied
                            ? 'Open Settings'
                            : 'Request Camera Permission',
                      ),
                    ),
                  ),

                if (_hasPermission && !_isScanning && _foundPaint == null)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _restartScanner,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Restart Scanner'),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.marineOrange, width: 3),
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
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Supported: EAN-13, EAN-8, Code 128, QR',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.marineOrange),
            ),
            const SizedBox(height: 16),
            Text(
              'Searching for paint...',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            if (_lastScannedCode != null) ...[
              const SizedBox(height: 8),
              Text(
                'Code: $_lastScannedCode',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorOverlay() {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              _errorMessage!,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            if (_lastScannedCode != null) ...[
              const SizedBox(height: 8),
              Text(
                'Code: $_lastScannedCode',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaintDetailsView() {
    // This is being replaced by the ScanResultSheet
    // We'll keep this for backward compatibility but it won't be used
    final paint = _foundPaint!;
    final Color paintColor = Color(
      int.parse(paint.hex.substring(1), radix: 16) + 0xFF000000,
    );

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? Colors.grey[800] : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final secondaryTextColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Success icon
            const Icon(Icons.check_circle, color: Colors.green, size: 60),
            const SizedBox(height: 16),
            const Text(
              'Paint Found!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Paint card
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Paint color
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: paintColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.withOpacity(0.3),
                        width: 1,
                      ),
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
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Paint brand & category
                  Text(
                    '${paint.brand} - ${paint.category}',
                    style: TextStyle(color: secondaryTextColor, fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Divider
                  Divider(color: secondaryTextColor?.withOpacity(0.3)),
                  const SizedBox(height: 16),

                  // Paint details
                  _buildDetailRow(
                    icon: Icons.colorize,
                    label: 'Color Code',
                    value: paint.hex,
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    icon: Icons.qr_code,
                    label: 'Barcode',
                    value: _lastScannedCode ?? 'Unknown',
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    icon: Icons.category,
                    label: 'Type',
                    value: [
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
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final secondaryTextColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];

    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryBlue, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: secondaryTextColor),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openAppSettings() async {
    await openAppSettings();
  }
}
