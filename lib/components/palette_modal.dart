import 'dart:convert'; // Para la codificación/decodificación JSON
import 'package:http/http.dart' as http; // Para las peticiones HTTP
import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/utils/env.dart';
import '../models/palette.dart';
import 'package:miniature_paint_finder/screens/inventory_screen.dart';
import 'package:miniature_paint_finder/screens/wishlist_screen.dart';
import 'package:miniature_paint_finder/models/paint.dart';
import 'package:miniature_paint_finder/components/add_to_wishlist_modal.dart';
import 'package:miniature_paint_finder/controllers/wishlist_controller.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:miniature_paint_finder/services/paint_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:miniature_paint_finder/screens/palette_screen.dart';
import 'package:miniature_paint_finder/services/image_cache_service.dart';

/// Modal para mostrar los detalles de una paleta de colores
class PaletteModal extends StatefulWidget {
  final String paletteName;
  final List<PaintSelection> paints;
  final String? imagePath;

  const PaletteModal({
    Key? key,
    required this.paletteName,
    required this.paints,
    this.imagePath,
  }) : super(key: key);

  @override
  State<PaletteModal> createState() => _PaletteModalState();
}

class _PaletteModalState extends State<PaletteModal> {
  // Trigger para forzar la reconstrucción
  int _refreshCounter = 0;

  // Precargar imagen al inicializar
  @override
  void initState() {
    super.initState();
    _precacheHeaderImage();
  }

  // Precarga la imagen del encabezado para mejorar la experiencia
  void _precacheHeaderImage() {
    if (widget.imagePath != null && widget.imagePath!.startsWith('http')) {
      final imageCacheService = ImageCacheService();
      imageCacheService.preloadImage(
        widget.imagePath!,
        context,
        cacheKey: 'palette_modal_${widget.paletteName}',
      );
    }
  }

  void _refreshState() {
    setState(() {
      _refreshCounter++;
    });
  }

  /// Llama al endpoint de la API para obtener la información de la pintura.
  /// El endpoint es: ${Env.apiBaseUrl}/api/paint/paint-info/{brand}/{paintId}
  /// Se requieren [brand], [paintId] y un [token] válido.
  static Future<Map<String, dynamic>> fetchPaintInfo({
    required String brand,
    required String paintId,
    required String token,
  }) async {
    final url = Uri.parse(
      '${Env.apiBaseUrl}/api/paint/paint-info/$brand/$paintId',
    );
    print('📤 Requesting paint info from: $url');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📥 Received response: ${response.statusCode}');
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

  /// Obtiene el estado de la pintura de la respuesta de la API.
  /// Retorna "In Inventory" si está en inventario, "In Wishlist" si está en wishlist
  /// o "Not in Collection" si no se encuentra.
  String getStatusFromPaintInfo(Map<String, dynamic> responseJson) {
    if (responseJson.containsKey('data') && responseJson['data'] != null) {
      final data = responseJson['data'];
      if (data['in_inventory'] == true) {
        return "In Inventory";
      } else if (data['in_whitelist'] == true) {
        return "In Wishlist";
      }
    }
    return "Not in Collection";
  }

  String getInventoryIdFromPaintInfo(Map<String, dynamic> responseJson) {
    if (responseJson.containsKey('data') && responseJson['data'] != null) {
      final data = responseJson['data'];
      if (data['inventory_id'] != null &&
          data['inventory_id'].toString().trim().isNotEmpty) {
        return data['inventory_id'];
      }
      return "";
    }
    return "";
  }

  String getWishlistIdFromPaintInfo(Map<String, dynamic> responseJson) {
    if (responseJson.containsKey('data') && responseJson['data'] != null) {
      final data = responseJson['data'];
      if (data['wishlist_id'] != null &&
          data['wishlist_id'].toString().trim().isNotEmpty) {
        return data['wishlist_id'];
      }
      return "";
    }
    return "";
  }

  /// Helper para obtener el estado dinámico de la pintura consultado a la API.
  Future<Map<String, dynamic>> _getPaintStatus(PaintSelection paint) async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    return fetchPaintInfo(
      brand: paint.paintBrandId ?? '',
      paintId: paint.paintId,
      token: token ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF101823) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              if (widget.imagePath != null &&
                  widget.imagePath!.startsWith('http'))
                CachedNetworkImage(
                  cacheManager: PaletteCacheManager(),
                  imageUrl: widget.imagePath!,
                  width: double.infinity,
                  height: 150,
                  fit: BoxFit.cover,
                  fadeInDuration: const Duration(milliseconds: 200),
                  cacheKey: 'palette_modal_${widget.paletteName}',
                  placeholder:
                      (context, loadingProgress) => Container(
                        width: double.infinity,
                        height: 150,
                        color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                        child: Center(
                          child: CircularProgressIndicator(
                            color: isDarkMode ? Colors.orange : Colors.blue,
                          ),
                        ),
                      ),
                  errorWidget: (context, error, stackTrace) {
                    print('❌ Error loading network image: $error');
                    return Image.asset(
                      'assets/images/placeholder.jpeg',
                      width: double.infinity,
                      height: 150,
                      fit: BoxFit.cover,
                    );
                  },
                )
              else
                Image.asset(
                  widget.imagePath ?? 'assets/images/placeholder.jpeg',
                  width: double.infinity,
                  height: 150,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: double.infinity,
                      height: 150,
                      color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                      child: Center(
                        child: Icon(
                          Icons.image_not_supported,
                          size: 50,
                          color:
                              isDarkMode ? Colors.grey[600] : Colors.grey[400],
                        ),
                      ),
                    );
                  },
                ),
              Container(
                width: double.infinity,
                height: 150,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.4),
                      Colors.black.withOpacity(0.6),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                left: 24,
                right: 24,
                child: Text(
                  widget.paletteName,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [],
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child:
                widget.paints.isEmpty
                    ? Center(
                      child: Text(
                        'No paints in this palette',
                        style: TextStyle(
                          color: isDarkMode ? Colors.grey : Colors.grey[600],
                        ),
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      itemCount: widget.paints.length,
                      itemBuilder: (context, index) {
                        final paint = widget.paints[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color:
                                isDarkMode
                                    ? const Color(0xFF1a2530)
                                    : Colors.grey[100],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Fila principal con información de la pintura
                              InkWell(
                                onTap:
                                    () async => await _showPaintOptionsModal(
                                      context,
                                      paint,
                                    ),
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8.0,
                                  ),
                                  child: Row(
                                    children: [
                                      // Brand avatar
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFEDEDED),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            paint.brandAvatar,
                                            style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      // Paint info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              paint.paintName,
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    isDarkMode
                                                        ? Colors.white
                                                        : Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              paint.paintBrand,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color:
                                                    isDarkMode
                                                        ? Colors.grey
                                                        : Colors.grey[700],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Color preview
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: _getColorFromHex(
                                            paint.paintColorHex,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color:
                                                isDarkMode
                                                    ? Colors.grey.withOpacity(
                                                      0.2,
                                                    )
                                                    : Colors.grey.withOpacity(
                                                      0.3,
                                                    ),
                                            width: 1,
                                          ),
                                        ),
                                      ),

                                      // Chevron icon to indicate tap options
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.chevron_right,
                                        color:
                                            isDarkMode
                                                ? Colors.grey[400]
                                                : Colors.grey[600],
                                        size: 24,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Divider(
                                color:
                                    isDarkMode
                                        ? const Color(0xFF2a3540)
                                        : Colors.grey[300],
                                height: 1,
                              ),
                              const SizedBox(height: 12),
                              // Additional info row
                              Row(
                                children: [
                                  // Color code
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Color code:",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color:
                                              isDarkMode
                                                  ? Colors.grey
                                                  : Colors.grey[700],
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              isDarkMode
                                                  ? const Color(0xFF0d151e)
                                                  : Colors.grey[200],
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          paint.paintCode ?? '',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color:
                                                isDarkMode
                                                    ? Colors.white
                                                    : Colors.black87,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  // Barcode
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        "Barcode:",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color:
                                              isDarkMode
                                                  ? Colors.grey
                                                  : Colors.grey[700],
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.qr_code,
                                            size: 16,
                                            color:
                                                isDarkMode
                                                    ? Colors.white70
                                                    : Colors.black54,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            paint.paintBarcode ?? '',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color:
                                                  isDarkMode
                                                      ? Colors.white70
                                                      : Colors.black54,
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Indicadores de estado dinámicos
                              FutureBuilder<Map<String, dynamic>>(
                                future: _getPaintStatus(paint),
                                builder: (context, snapshot) {
                                  bool isInInventory = false;
                                  bool isInWishlist = false;
                                  if (snapshot.hasData &&
                                      snapshot.data?['data'] != null) {
                                    final data = snapshot.data!['data'];
                                    isInInventory =
                                        data['in_inventory'] == true;
                                    isInWishlist = data['in_whitelist'] == true;
                                  }
                                  return Row(
                                    children: [
                                      if (isInInventory)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withOpacity(
                                              isDarkMode ? 0.2 : 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            border: Border.all(
                                              color: Colors.green.withOpacity(
                                                isDarkMode ? 0.3 : 0.2,
                                              ),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: const [
                                              Icon(
                                                Icons.inventory_2_outlined,
                                                size: 14,
                                                color: Colors.green,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                "In Inventory",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.green,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      if (isInWishlist)
                                        Container(
                                          margin: const EdgeInsets.only(
                                            left: 8,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.amber.withOpacity(
                                              isDarkMode ? 0.2 : 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            border: Border.all(
                                              color: Colors.amber.withOpacity(
                                                isDarkMode ? 0.3 : 0.2,
                                              ),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: const [
                                              Icon(
                                                Icons.star_outline,
                                                size: 14,
                                                color: Colors.amber,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                "In Wishlist",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.amber,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      if (!isInInventory && !isInWishlist)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.withOpacity(
                                              isDarkMode ? 0.2 : 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            border: Border.all(
                                              color: Colors.grey.withOpacity(
                                                isDarkMode ? 0.3 : 0.2,
                                              ),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: const [
                                              Icon(
                                                Icons.remove_circle_outline,
                                                size: 14,
                                                color: Colors.grey,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                "Not in Collection",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  // Mostrar modal de opciones para la pintura
  Future<void> _showPaintOptionsModal(
    BuildContext context,
    PaintSelection paint,
  ) async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    final paintInfo = await fetchPaintInfo(
      brand: paint.paintBrandId ?? '',
      paintId: paint.paintId,
      token: token ?? '',
    );
    final String inventory_id = getInventoryIdFromPaintInfo(paintInfo);
    final String wishlist_id = getWishlistIdFromPaintInfo(paintInfo);
    final dynamicStatus = getStatusFromPaintInfo(paintInfo);
    final bool isInInventory = dynamicStatus == "In Inventory";
    final bool isInWishlist = dynamicStatus == "In Wishlist";
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF101823) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: _getColorFromHex(paint.paintColorHex),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            isDarkMode
                                ? Colors.grey.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          paint.paintName,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          paint.paintBrand,
                          style: TextStyle(
                            fontSize: 16,
                            color: isDarkMode ? Colors.grey : Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(
                                  isDarkMode ? 0.2 : 0.1,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                "${paint.matchPercentage}% Match",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Divider(color: isDarkMode ? Colors.grey[800] : Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                "Quick Actions",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              // Botones para actualizar inventario o añadir a wishlist
              Row(
                children: [
                  // Actualizar o añadir a inventario
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showInventoryUpdateDialog(
                          context,
                          paint,
                          isInInventory,
                          inventory_id,
                        );
                      },
                      icon: const Icon(Icons.inventory_2_outlined),
                      label: Text(
                        isInInventory ? "Update Inventory" : "Add to Inventory",
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            isDarkMode ? Colors.orange : Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Actualizar o añadir a wishlist
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showWishlistDialog(
                          context,
                          paint,
                          isInWishlist,
                          wishlist_id,
                        );
                      },
                      icon: const Icon(Icons.favorite_border),
                      label: Text(
                        isInWishlist ? "Update Wishlist" : "Add to Wishlist",
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.pink,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Botón para ver el inventario
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                isInInventory
                                    ? const InventoryScreen()
                                    : const WishlistScreen(),
                      ),
                    ).then((_) {
                      _refreshState();
                    });
                  },
                  icon: Icon(
                    isInInventory ? Icons.inventory_2 : Icons.favorite_border,
                  ),
                  label: Text(
                    isInInventory ? "View in Inventory" : "View in Wishlist",
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkMode ? Colors.orange : Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showInventoryUpdateDialog(
    BuildContext context,
    PaintSelection paint,
    bool isInInventory,
    String inventoryId,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    int quantity = 1;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                isInInventory ? 'Update Inventory' : 'Add to Inventory',
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _getColorFromHex(paint.paintColorHex),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              paint.paintName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              paint.paintBrand,
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    isDarkMode
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed:
                            quantity > 1
                                ? () {
                                  setState(() {
                                    quantity--;
                                  });
                                }
                                : null,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isDarkMode ? Colors.grey[800] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '$quantity',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () {
                          setState(() {
                            quantity++;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    final paintService = PaintService();

                    final String hexColor =
                        paint.paintColorHex.startsWith('#')
                            ? paint.paintColorHex.substring(1)
                            : paint.paintColorHex;
                    final r = int.parse(hexColor.substring(0, 2), radix: 16);
                    final g = int.parse(hexColor.substring(2, 4), radix: 16);
                    final b = int.parse(hexColor.substring(4, 6), radix: 16);

                    final Paint paintObj = Paint(
                      id: paint.paintId,
                      name: paint.paintName,
                      brand: paint.paintBrand,
                      hex: paint.paintColorHex,
                      set: "Palette Paint",
                      code: paint.paintId,
                      r: r,
                      g: g,
                      b: b,
                      category: "Palette",
                      isMetallic: false,
                      isTransparent: false,
                    );

                    scaffoldMessenger.showSnackBar(
                      const SnackBar(
                        content: Row(
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                              strokeWidth: 2,
                            ),
                            SizedBox(width: 16),
                            Text('Saving inventory...'),
                          ],
                        ),
                        duration: Duration(seconds: 10),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );

                    try {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) {
                        scaffoldMessenger.hideCurrentSnackBar();
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(
                            content: Text('You need to be logged in'),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }

                      bool result = false;

                      if (isInInventory && inventoryId.isNotEmpty) {
                        result = await paintService.updateInventory(
                          paintObj,
                          quantity,
                          inventoryId: inventoryId,
                        );
                      } else {
                        result = await paintService.addToInventory(
                          paintObj,
                          quantity,
                        );
                      }

                      scaffoldMessenger.hideCurrentSnackBar();

                      if (result) {
                        _refreshState();
                        final action = isInInventory ? 'Updated' : 'Added';
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              '$action ${paint.paintName} quantity to $quantity',
                            ),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                            action: SnackBarAction(
                              label: 'VIEW',
                              textColor: Colors.white,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => const InventoryScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      } else {
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text('Error saving inventory'),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } catch (e) {
                      scaffoldMessenger.hideCurrentSnackBar();
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  child: Text(isInInventory ? 'Update' : 'Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Método para mostrar el diálogo de wishlist
  void _showWishlistDialog(
    BuildContext context,
    PaintSelection paint,
    bool isInWishlist,
    String wishlist_id,
  ) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final paintService = PaintService();

    final String hexColor =
        paint.paintColorHex.startsWith('#')
            ? paint.paintColorHex.substring(1)
            : paint.paintColorHex;

    final r = int.parse(hexColor.substring(0, 2), radix: 16);
    final g = int.parse(hexColor.substring(2, 4), radix: 16);
    final b = int.parse(hexColor.substring(4, 6), radix: 16);

    final Paint paintObj = Paint(
      id: paint.paintId,
      name: paint.paintName,
      brand: paint.paintBrand,
      hex: paint.paintColorHex,
      set: "Palette Paint",
      code: paint.paintId,
      r: r,
      g: g,
      b: b,
      category: "Palette",
      isMetallic: false,
      isTransparent: false,
    );

    AddToWishlistModal.show(
      context: context,
      paint: paintObj,
      isUpdate: isInWishlist,
      onAddToWishlist: (paint, priority, _) async {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
                SizedBox(width: 16),
                Text('Saving to wishlist...'),
              ],
            ),
            duration: Duration(seconds: 10),
            behavior: SnackBarBehavior.floating,
          ),
        );

        try {
          final firebaseUser = FirebaseAuth.instance.currentUser;
          if (firebaseUser == null) {
            scaffoldMessenger.hideCurrentSnackBar();
            scaffoldMessenger.showSnackBar(
              const SnackBar(
                content: Text(
                  'You need to be logged in to manage your wishlist',
                ),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }

          final userId = firebaseUser.uid;
          print('🔑 User ID detected: $userId');
          print(
            '📤 Sending paint ${paint.id} with priority $priority and userId $userId',
          );
          print('📤 Paint details: ${paint.toJson()}');
          // 👉 Lógica diferenciada entre add y update
          Map<String, dynamic> result = {};

          if (isInWishlist) {
            // Suponiendo que tienes una forma de recuperar el wishlistId:
            final wishlistId = wishlist_id; // <--- ajusta esto según tu modelo
            final bool isPriority = priority > 0;
            final token = await FirebaseAuth.instance.currentUser?.getIdToken();
            final success = await paintService.updateWishlistPriority(
              paint.id,
              wishlistId,
              isPriority,
              token as String,
              priority,
            );

            result = {
              'success': success,
              'updated': true,
              'priority': priority,
              'alreadyExists': true,
            };
          } else {
            result = await paintService.addToWishlistDirect(
              paint,
              priority,
              userId,
            );
          }

          scaffoldMessenger.hideCurrentSnackBar();
          print('✅ Complete API Wishlist result: $result');

          if (result['success'] == true) {
            final priorityText = _getPriorityText(priority);
            final message =
                result['alreadyExists'] == true
                    ? 'Updated ${paint.name} priority to $priorityText'
                    : 'Added ${paint.name} to wishlist with $priorityText priority';

            _refreshState();

            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text(message),
                duration: const Duration(seconds: 3),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                action: SnackBarAction(
                  label: 'VIEW',
                  textColor: Colors.white,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WishlistScreen(),
                      ),
                    );
                  },
                ),
              ),
            );
          } else {
            print(
              '❌ Error details: ${result['raw_response'] ?? result['message']}',
            );
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text('Error: ${result['message']}'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'Details',
                  textColor: Colors.white,
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: const Text('Error Details'),
                            content: SingleChildScrollView(
                              child: Text(result.toString()),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Close'),
                              ),
                            ],
                          ),
                    );
                  },
                ),
              ),
            );
          }
        } catch (e, stackTrace) {
          print('❌ Exception adding or updating to wishlist: $e');
          print('❌ Stack trace: $stackTrace');
          scaffoldMessenger.hideCurrentSnackBar();
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      },
    );
  }

  /// Devuelve una descripción del nivel de prioridad.
  String _getPriorityText(int priority) {
    switch (priority) {
      case 1:
        return 'low';
      case 2:
        return 'somewhat important';
      case 3:
        return 'important';
      case 4:
        return 'very important';
      case 5:
        return 'highest';
      default:
        return '';
    }
  }

  /// Convierte un string hexadecimal en un objeto Color.
  Color _getColorFromHex(String hexColor) {
    try {
      hexColor = hexColor.replaceAll('#', '');
      if (hexColor.length == 6) {
        return Color(int.parse('FF$hexColor', radix: 16));
      }
      return Colors.red;
    } catch (e) {
      return Colors.red;
    }
  }
}

/// Función helper para mostrar el modal de la paleta.
void showPaletteModal(
  BuildContext context,
  String paletteName,
  List<PaintSelection> paints, {
  String? imagePath,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder:
        (context) => DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder:
              (_, controller) => PaletteModal(
                paletteName: paletteName,
                paints: paints,
                imagePath: imagePath,
              ),
        ),
  );
}
