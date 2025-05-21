import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/utils/env.dart';
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
import 'package:miniature_paint_finder/screens/add_paint_form_screen.dart';
import 'package:miniature_paint_finder/services/mixpanel_service.dart';
import 'package:http/http.dart' as http; // Para las peticiones HTTP

/// A screen that allows users to scan paint barcodes to find paints
class BarcodeScannerScreen extends StatefulWidget {
  /// Creates a barcode scanner screen
  const BarcodeScannerScreen({Key? key, this.paletteName}) : super(key: key);

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
  final MixpanelService _analytics = MixpanelService.instance;

  bool _isScanning = true;
  bool _isSearching = false;
  String? _lastScannedCode;
  Paint? _foundPaint;
  String? _errorMessage;
  bool _hasPermission = true;
  bool _isInitialized = false;
  bool _isPermanentlyDenied = false;
  bool _hasScanAttempt = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _directCameraInitialization();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print('App resumed, force initializing camera...');
      _directCameraInitialization();
    }
  }

  Future<void> _directCameraInitialization() async {
    setState(() {
      _hasPermission = true;
      _errorMessage = null;
    });

    await _forceInitializeCamera();
  }

  Future<void> _forceInitializeCamera() async {
    print("FORCING camera initialization regardless of permission state");

    // Intentar hasta 3 veces con diferentes configuraciones
    for (int attempt = 1; attempt <= 3; attempt++) {
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
          _hasScanAttempt = false;
        });

        print("Creating scanner controller (intento $attempt)");

        // Probar diferentes configuraciones según el intento
        if (attempt == 1) {
          _scannerController = MobileScannerController(
            detectionSpeed: DetectionSpeed.normal,
            formats: [BarcodeFormat.ean13],
          );
        } else if (attempt == 2) {
          _scannerController = MobileScannerController(
            detectionSpeed: DetectionSpeed.noDuplicates,
            formats: [
              BarcodeFormat.ean13,
              BarcodeFormat.ean8,
              BarcodeFormat.code128,
            ],
          );
        } else {
          // En el último intento, usar configuración mínima
          _scannerController = MobileScannerController(
            facing: CameraFacing.back,
            detectionSpeed: DetectionSpeed.normal,
            torchEnabled: false,
          );
        }

        print("Starting camera (intento $attempt)");
        await _scannerController!.start();
        print("Camera inicializada con éxito en intento $attempt");

        setState(() {
          _hasPermission = true;
          _isInitialized = true;
          _errorMessage = null;
        });

        // Si llegamos aquí, la cámara está funcionando, salir del bucle
        return;
      } catch (e) {
        print("Error en intento $attempt de inicialización: $e");

        // En el último intento, procesar errores de permisos
        if (attempt == 3) {
          if (e.toString().toLowerCase().contains("permission") ||
              e.toString().toLowerCase().contains("denied")) {
            print(
              "Problema persistente de permisos - solicitando explícitamente",
            );
            try {
              final status = await Permission.camera.request();
              print("Resultado solicitud de permisos: ${status.toString()}");

              if (status.isGranted) {
                print(
                  "Permiso finalmente concedido, reiniciando inicialización",
                );
                return _forceInitializeCamera();
              } else if (status.isPermanentlyDenied) {
                setState(() {
                  _hasPermission = false;
                  _isInitialized = false;
                  _isPermanentlyDenied = true;
                  _errorMessage =
                      'Camera permission permanently denied. Please enable it in your device settings.';
                });
              } else {
                setState(() {
                  _hasPermission =
                      true; // Asumir que tenemos permiso de todos modos
                  _isInitialized = false;
                });

                // Esperar un momento e intentar una vez más
                await Future.delayed(Duration(milliseconds: 800));
                return _forceInitializeCamera();
              }
            } catch (permError) {
              print("Error solicitando permisos: $permError");
              // Asumir que tenemos permisos de todos modos
              setState(() {
                _hasPermission = true;
                _isInitialized = false;
              });
            }
          } else {
            // Error de hardware u otro
            setState(() {
              _isInitialized = false;
              _hasPermission = true; // Asumir que tenemos permiso
            });

            // Intentar una vez más después de un corto retraso
            await Future.delayed(Duration(milliseconds: 800));
            return _forceInitializeCamera();
          }
        }

        // Si no es el último intento, esperar un momento antes del siguiente intento
        if (attempt < 3) {
          await Future.delayed(Duration(milliseconds: 500));
        }
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
    if (_isSearching || !_isScanning || !_hasPermission || !_isInitialized)
      return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final Barcode barcode = barcodes.first;
    final String? code = barcode.rawValue;

    print('Barcode detected: $code');

    setState(() {
      _hasScanAttempt = true;
    });

    final scanStartTime = DateTime.now().millisecondsSinceEpoch;

    final currentUser = FirebaseAuth.instance.currentUser;
    final isGuestUser = currentUser == null || currentUser.isAnonymous;
    print("barcode_scanner_screen.dart isGuestUser: $isGuestUser");
    if (code == null || !_barcodeService.isValidBarcode(code)) {
      setState(() {
        _errorMessage = 'Invalid barcode format: ${code ?? "unknown"}';
      });

      _analytics.trackScannerActivity(
        'error',
        barcode: code,
        errorDetails: 'Invalid barcode format',
        scanDurationMs: DateTime.now().millisecondsSinceEpoch - scanStartTime,
      );

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _errorMessage = null;
          });
        }
      });

      return;
    }

    if (code == _lastScannedCode) return;

    setState(() {
      _isSearching = true;
      _lastScannedCode = code;
      _errorMessage = null;
      _foundPaint = null;
    });

    try {
      print('🔍 Searching for paint with barcode: $code');
      final List<Paint>? paints = await _barcodeService.findPaintByBarcode(
        code,
        isGuestUser,
      );

      final scanDurationMs =
          DateTime.now().millisecondsSinceEpoch - scanStartTime;

      if (mounted) {
        setState(() {
          _isSearching = false;
          _isScanning = false;

          if (paints == null || paints.isEmpty) {
            _errorMessage = 'No paint found for this barcode';

            _analytics.trackBarcodeNotFound(
              code,
              contextScreen: 'BarcodeScannerScreen',
              brandGuess: _guessBrandFromBarcode(code),
            );

            _analytics.trackScannerActivity(
              'not_found',
              barcode: code,
              errorDetails: 'No paint found for this barcode',
              scanDurationMs: scanDurationMs,
            );

            setState(() {
              _isScanning = false;
            });
          } else if (paints.length == 1) {
            _analytics.trackScannerActivity(
              'success',
              barcode: code,
              paintId: paints[0].id,
              paintName: paints[0].name,
              scanDurationMs: scanDurationMs,
            );

            _analytics.trackPaintInteraction(
              paints[0].id,
              paints[0].name,
              paints[0].brand,
              'scanned',
              source: 'barcode_scanner',
              additionalData: {
                'barcode': code,
                'scan_duration_ms': scanDurationMs,
              },
            );

            if (isGuestUser) {
              _showPaintSelectionDialog(paints);
            } else {
              _foundPaint = paints[0];
              _showScanResultSheet(_foundPaint!);
            }
          } else {
            _analytics.trackScannerActivity(
              'success_multiple',
              barcode: code,
              scanDurationMs: scanDurationMs,
              errorDetails: 'Multiple paints found for same barcode',
            );

            _showPaintSelectionDialog(paints);
          }
        });
      }
    } catch (e) {
      print('❌ Error searching for paint: $e');

      _analytics.trackScannerActivity(
        'error',
        barcode: code,
        errorDetails: e.toString(),
        scanDurationMs: DateTime.now().millisecondsSinceEpoch - scanStartTime,
      );

      if (mounted) {
        setState(() {
          _isSearching = false;
          _errorMessage = 'Error searching for paint: ${e.toString()}';
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted && _errorMessage != null) {
              _resetScanner();
            }
          });
        });
      }
    }
  }

  String? _guessBrandFromBarcode(String barcode) {
    if (barcode.startsWith('5011921')) return 'Citadel_Colour';
    if (barcode.startsWith('8429551')) return 'Vallejo';
    if (barcode.startsWith('7331545')) return 'Army_Painter';
    if (barcode.startsWith('3760')) return 'Scale75';
    if (barcode.startsWith('639713')) return 'P3';
    if (barcode.startsWith('8436042')) return 'Green_Stuff_World';
    if (barcode.startsWith('4009803')) return 'AK';
    return null;
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
                      color: Color(
                        int.parse(paint.hex.substring(1), radix: 16) +
                            0xFF000000,
                      ),
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

  void _showScanResultSheet(Paint paint) async {
    String inventoryId = "";
    String wishlistId = "";

    bool isInInventory = _paintService.isInInventory(paint.id);
    final int? inventoryQuantity = _paintService.getInventoryQuantity(paint.id);
    bool isInWishlist = _paintService.isInWishlist(paint.id);
    final List<Palette> inPalettes = _paintService.getPalettesContainingPaint(
      paint.id,
    );
    final List<Palette> userPalettes = _paintService.getUserPalettes();

    final Map<String, dynamic> paintStatus = await _getPaintStatus(paint);

    if (paintStatus['data'] != null) {
      final data = paintStatus['data'];
      isInInventory = data['in_inventory'] == true;
      isInWishlist = data['in_whitelist'] == true;
      inventoryId = data['inventory_id'];
      wishlistId = data['wishlist_id'];
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        debugPrint('👨‍💻 paint: $paint');
        print('👨‍💻 isInInventory: $isInInventory');
        print('👨‍💻 isInWishlist: $isInWishlist');

        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: const BoxDecoration(color: Colors.transparent),

          child: ScanResultSheet(
            paint: paint,
            isInInventory: isInInventory,
            isInWishlist: isInWishlist,
            inventoryId: inventoryId,
            wishlistId: wishlistId,
            inventoryQuantity: inventoryQuantity,
            inPalettes: inPalettes,
            userPalettes: userPalettes,
            paletteName: widget.paletteName,
            onAddToInventory: (paint, quantity, note) async {
              try {
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
            onUpdateInventory: (paint, quantity, note, inventoryId) async {
              try {
                final success = await _inventoryService.updateStockFromApi(
                  inventoryId as String,
                  quantity,
                );
                if (note != null) {
                  await _inventoryService.updateNotesFromApi(inventoryId, note);
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
              final firebaseUser = FirebaseAuth.instance.currentUser;
              if (firebaseUser == null) {
                return;
              }

              final userId = firebaseUser.uid;

              await _paintService.addToWishlistDirect(
                paint,
                isPriority ? 3 : 0,
                userId,
              );

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
              final _palette = await _paletteService.createPalette(
                palette.name,
                token ?? '',
              );
              final paletteId = _palette['id'];
              await _paletteService.addPaintsToPalette(paletteId, [
                {"paint_id": paint.id, "brand_id": paint.brandId},
              ], token ?? '');

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Paint added to palette ${palette.name}!'),
                    backgroundColor: Colors.purple,
                  ),
                );
              }

              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const PaletteScreen()),
                (Route<dynamic> route) => false,
              );
            },
            onFindEquivalents: (paint) async {
              Navigator.pop(context);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Searching for equivalents...'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }

              try {
                final equivalents = await _paintService.findEquivalents(paint);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Found ${equivalents.length} equivalent paints',
                      ),
                      action: SnackBarAction(label: 'View', onPressed: () {}),
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
      _hasScanAttempt = false;
    });

    if (_hasPermission && _scannerController != null) {
      _scannerController!.start();
    }
  }

  void _restartScanner() {
    _forceInitializeCamera();
    setState(() {
      _isScanning = true;
      _isSearching = false;
      _lastScannedCode = null;
      _foundPaint = null;
      _errorMessage = null;
      _hasScanAttempt = false;
    });
  }

  static Future<Map<String, dynamic>> fetchPaintInfo({
    required String brand,
    required String paintId,
    required String token,
  }) async {
    final url = Uri.parse('${Env.apiBaseUrl}/paint/paint-info/$brand/$paintId');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return jsonData;
      } else {
        return {
          'executed': false,
          'message': 'Error: Code ${response.statusCode}',
          'data': null,
        };
      }
    } catch (e) {
      print('❌ Exception in fetchPaintInfo: $e');
      return {'executed': false, 'message': 'Exception: $e', 'data': null};
    }
  }

  Future<Map<String, dynamic>> _getPaintStatus(Paint paint) async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    return fetchPaintInfo(
      brand: paint.brandId ?? '',
      paintId: paint.id,
      token: token ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Barcode Scanner'),
        actions: [
          // Botón para forzar la inicialización
          IconButton(
            icon: const Icon(Icons.camera_enhance),
            onPressed: () {
              print('Forcing camera initialization from UI button');
              _directCameraInitialization();
            },
            tooltip: 'Force camera',
          ),
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
                  selectedPaint = paints.firstWhere(
                    (p) => _paintService.isInInventory(p.id),
                    orElse: () => paints.first,
                  );
                  break;
                case 'not_in_inventory':
                  selectedPaint = paints.firstWhere(
                    (p) =>
                        !_paintService.isInInventory(p.id) &&
                        !_paintService.isInWishlist(p.id),
                    orElse: () => paints.first,
                  );
                  break;
                case 'in_wishlist':
                  selectedPaint = paints.firstWhere(
                    (p) => _paintService.isInWishlist(p.id),
                    orElse: () => paints.first,
                  );
                  break;
                case 'in_palette':
                  selectedPaint = paints.firstWhere(
                    (p) =>
                        _paintService
                            .getPalettesContainingPaint(p.id)
                            .isNotEmpty,
                    orElse: () => paints.first,
                  );
                  break;
                case 'metallic':
                  selectedPaint = paints.firstWhere(
                    (p) => p.isMetallic,
                    orElse: () => paints.first,
                  );
                  break;
                case 'transparent':
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
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              print('Manual camera refresh requested');
              // Forzar directamente sin verificar permisos
              _directCameraInitialization();
            },
            tooltip: 'Refresh camera',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  if (_isScanning &&
                      _hasPermission &&
                      _isInitialized &&
                      _scannerController != null)
                    MobileScanner(
                      controller: _scannerController!,
                      onDetect: _onBarcodeDetected,
                    ),

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
                        ],
                      ),
                    ),

                  if (!_isInitialized)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          const Text('Initializing camera...'),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _directCameraInitialization,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryBlue,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Force Camera'),
                          ),
                        ],
                      ),
                    ),

                  if (_isSearching) _buildSearchingOverlay(),

                  if (_isScanning &&
                      !_isSearching &&
                      _hasPermission &&
                      _isInitialized &&
                      _scannerController != null)
                    _buildScanGuideOverlay(),

                  if (_errorMessage != null &&
                      _hasScanAttempt &&
                      _lastScannedCode != null &&
                      !_isSearching)
                    _buildErrorOverlay(),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
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

                  if (_hasPermission && !_isScanning && _foundPaint == null)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _restartScanner,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
    return Container(
      color: Colors.black.withOpacity(0.5),
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 48,
                      color: AppTheme.marineOrange,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage == 'No paint found for this barcode'
                          ? 'No paint found'
                          : 'Error',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage == 'No paint found for this barcode'
                          ? 'This paint is not in our database yet.'
                          : _errorMessage ?? 'An error occurred',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    if (_errorMessage == 'No paint found for this barcode') ...[
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => AddPaintFormScreen(
                                    barcode: _lastScannedCode,
                                  ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: AppTheme.marineOrange,
                        ),
                        child: const Text(
                          'Add',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Your submission will be reviewed and added to our database.',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: _restartScanner,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Restart Scanner'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaintDetailsView() {
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
            const Icon(Icons.check_circle, color: Colors.green, size: 60),
            const SizedBox(height: 16),
            const Text(
              'Paint Found!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

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

                  Text(
                    '${paint.brand} - ${paint.category}',
                    style: TextStyle(color: secondaryTextColor, fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  Divider(color: secondaryTextColor?.withOpacity(0.3)),
                  const SizedBox(height: 16),

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
