import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/models/paint.dart';
import 'package:miniature_paint_finder/models/palette.dart';
import 'package:miniature_paint_finder/services/paint_service.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';
import 'package:miniature_paint_finder/components/app_header.dart';
import 'package:miniature_paint_finder/widgets/app_scaffold.dart';
import 'package:miniature_paint_finder/widgets/shared_drawer.dart';
import 'package:firebase_core/firebase_core.dart';

/// Screen that displays all paints in the user's wishlist
class WishlistScreen extends StatefulWidget {
  /// Constructs the wishlist screen
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final PaintService _paintService = PaintService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _wishlistItems = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  Future<void> _loadWishlist() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String token = "token"; // Fallback token for testing
      bool usingFallbackToken = true;

      // Get Firebase token if available
      try {
        print('🔐 Intentando obtener token de Firebase...');
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          print('👤 Usuario autenticado: ${user.email ?? 'No email'}');
          final idToken = await user.getIdToken();
          if (idToken != null) {
            token = idToken;
            usingFallbackToken = false;
            print('✅ Token de Firebase obtenido correctamente');
          } else {
            print('⚠️ Token de Firebase es null, usando token de respaldo');
          }
        } else {
          print('⚠️ No hay usuario autenticado, usando token de respaldo');
        }
      } catch (e) {
        print('❌ Error al obtener token de Firebase: $e');
        print('⚠️ Usando token de respaldo para continuar');
        // Continue with fallback token
      }

      if (usingFallbackToken) {
        print('⚠️ Usando token de respaldo para la petición de wishlist');
      }

      print('🔄 Obteniendo datos de wishlist...');
      final wishlistItems = await _paintService.getWishlistPaints(token);
      print('✅ Datos de wishlist obtenidos: ${wishlistItems.length} elementos');

      setState(() {
        _wishlistItems = wishlistItems;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error al cargar wishlist: $e');
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading wishlist: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeFromWishlist(
    String paintId,
    String paintName,
    String _id,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Removal'),
            content: Text('Remove $paintName from your wishlist?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('REMOVE'),
              ),
            ],
          ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      String token = "token"; // Fallback token for testing
      bool usingFallbackToken = true;

      // Get Firebase token if available
      try {
        print(
          '🔐 Intentando obtener token de Firebase para eliminar pintura...',
        );
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          print('👤 Usuario autenticado: ${user.email ?? 'No email'}');
          final idToken = await user.getIdToken();
          if (idToken != null) {
            token = idToken;
            usingFallbackToken = false;
            print('✅ Token de Firebase obtenido correctamente');
          } else {
            print('⚠️ Token de Firebase es null, usando token de respaldo');
          }
        } else {
          print('⚠️ No hay usuario autenticado, usando token de respaldo');
        }
      } catch (e) {
        print('❌ Error al obtener token de Firebase: $e');
        print('⚠️ Usando token de respaldo para continuar');
        // Continue with fallback token
      }

      if (usingFallbackToken) {
        print('⚠️ Usando token de respaldo para eliminar de wishlist');
      }

      print('🔄 Eliminando $paintName de wishlist (ID: $_id)...');
      final result = await _paintService.removeFromWishlist(
        paintId,
        _id,
        token,
      );

      if (result && mounted) {
        print('✅ Pintura eliminada de wishlist correctamente');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$paintName removed from wishlist'),
            action: SnackBarAction(
              label: 'UNDO',
              onPressed: () async {
                // Find the paint in our list to get the priority status
                final item = _wishlistItems.firstWhere(
                  (item) => (item['paint'] as Paint).id == paintId,
                  orElse: () => {'paint': null, 'isPriority': false},
                );

                if (item['paint'] != null) {
                  print('🔄 Recuperando $paintName en wishlist...');
                  await _paintService.addToWishlist(
                    item['paint'] as Paint,
                    item['isPriority'] as bool,
                  );
                  print('✅ Pintura recuperada en wishlist correctamente');
                  _loadWishlist();
                }
              },
            ),
          ),
        );

        _loadWishlist();
      } else {
        print('❌ Error al eliminar pintura de wishlist');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error removing paint from wishlist'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Excepción al eliminar de wishlist: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing from wishlist: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _togglePriority(
    String paintId,
    bool currentPriority,
    String _id,
  ) async {
    try {
      final newPriority = !currentPriority;
      String token = "token"; // Fallback token for testing
      bool usingFallbackToken = true;

      // Get Firebase token if available
      try {
        print(
          '🔐 Intentando obtener token de Firebase para actualizar prioridad...',
        );
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          print('👤 Usuario autenticado: ${user.email ?? 'No email'}');
          final idToken = await user.getIdToken();
          if (idToken != null) {
            token = idToken;
            usingFallbackToken = false;
            print('✅ Token de Firebase obtenido correctamente');
          } else {
            print('⚠️ Token de Firebase es null, usando token de respaldo');
          }
        } else {
          print('⚠️ No hay usuario autenticado, usando token de respaldo');
        }
      } catch (e) {
        print('❌ Error al obtener token de Firebase: $e');
        print('⚠️ Usando token de respaldo para continuar');
        // Continue with fallback token
      }

      if (usingFallbackToken) {
        print('⚠️ Usando token de respaldo para actualizar prioridad');
      }

      print(
        '🔄 Actualizando prioridad de pintura (ID: $_id) a: ${newPriority ? 'Prioritaria' : 'Normal'}',
      );
      await _paintService.updateWishlistPriority(
        paintId,
        _id,
        newPriority,
        token,
      );

      if (mounted) {
        print('✅ Prioridad actualizada correctamente');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newPriority ? 'Marked as priority' : 'Removed from priority',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      _loadWishlist();
    } catch (e) {
      print('❌ Excepción al actualizar prioridad: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating priority: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addToInventory(Paint paint, String _id) async {
    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) => _AddToInventoryDialog(paint: paint),
    );

    if (result != null) {
      try {
        print(
          '🔄 Añadiendo ${paint.name} al inventario con cantidad: ${result['quantity']}',
        );
        await _paintService.addToInventory(
          paint,
          result['quantity'] as int,
          note: result['note'] as String?,
        );
        print('✅ Pintura añadida al inventario correctamente');

        String token = "token"; // Fallback token for testing
        bool usingFallbackToken = true;

        // Get Firebase token if available
        try {
          print(
            '🔐 Intentando obtener token de Firebase para eliminar de wishlist...',
          );
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            print('👤 Usuario autenticado: ${user.email ?? 'No email'}');
            final idToken = await user.getIdToken();
            if (idToken != null) {
              token = idToken;
              usingFallbackToken = false;
              print('✅ Token de Firebase obtenido correctamente');
            } else {
              print('⚠️ Token de Firebase es null, usando token de respaldo');
            }
          } else {
            print('⚠️ No hay usuario autenticado, usando token de respaldo');
          }
        } catch (e) {
          print('❌ Error al obtener token de Firebase: $e');
          print('⚠️ Usando token de respaldo para continuar');
          // Continue with fallback token
        }

        if (usingFallbackToken) {
          print(
            '⚠️ Usando token de respaldo para eliminar de wishlist tras añadir al inventario',
          );
        }

        // Remove from wishlist
        print(
          '🔄 Eliminando ${paint.name} de wishlist (ID: $_id) tras añadir al inventario...',
        );
        final deleteResult = await _paintService.removeFromWishlist(
          paint.id,
          _id,
          token,
        );

        if (deleteResult) {
          print('✅ Pintura eliminada de wishlist correctamente');
        } else {
          print(
            '⚠️ No se pudo eliminar la pintura de wishlist tras añadirla al inventario',
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${paint.name} added to inventory'),
              backgroundColor: Colors.green,
            ),
          );
        }

        _loadWishlist();
      } catch (e) {
        print('❌ Error al añadir al inventario: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error adding to inventory: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      print('ℹ️ Usuario canceló la adición al inventario');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      scaffoldKey: _scaffoldKey,
      title: 'Wishlist',
      selectedIndex: -1, // Not a bottom tab item
      body: _buildBody(),
      drawer: const SharedDrawer(currentScreen: 'wishlist'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to Library or Paint Browser
          Navigator.pop(context);
        },
        backgroundColor:
            isDarkMode ? AppTheme.marineOrange : Theme.of(context).primaryColor,
        foregroundColor: isDarkMode ? AppTheme.marineBlue : Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add to Wishlist'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildBody() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _wishlistItems.isEmpty
        ? _buildEmptyState()
        : _buildWishlistContent();
  }

  Widget _buildEmptyState() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/wishlist_palceholder.png',
            width: 200,
            height: 200,
          ),
          const SizedBox(height: 16),
          Text(
            'Your wishlist is empty',
            style: TextStyle(
              fontSize: 18,
              color: isDarkMode ? Colors.white : AppTheme.marineBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add paints you want to purchase later',
            style: TextStyle(
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWishlistContent() {
    return ListView.builder(
      itemCount: _wishlistItems.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final item = _wishlistItems[index];
        final paint = item['paint'] as Paint;
        final isPriority = item['isPriority'] as bool;
        final _id = item['id'] as String;
        final addedAt = item['addedAt'] as DateTime;

        // Get color from hex or colorHex property
        final String colorCode = paint.hex;
        final Color paintColor = Color(
          int.parse(colorCode.substring(1), radix: 16) + 0xFF000000,
        );

        // Simulate paints in palettes - in a real app, this would come from the service
        final palettes = _paintService.getPalettesContainingPaint(paint.id);

        // Simulate a barcode - in a real app, this would come from a barcode service
        final simulatedBarcode =
            "EAN-13: ${paint.id.hashCode.abs() % 10000000000000}";

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side:
                isPriority
                    ? BorderSide(color: AppTheme.marineOrange, width: 2)
                    : BorderSide(color: Colors.grey.withOpacity(0.2)),
          ),
          child: InkWell(
            onTap: () {
              _showActionSheet(paint, isPriority, _id);
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Paint color
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: paintColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.3),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Paint details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Added priority indicator if needed
                            if (isPriority) ...[
                              Row(
                                children: [
                                  Icon(
                                    Icons.star,
                                    size: 16,
                                    color: AppTheme.marineOrange,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'PRIORITY',
                                    style: TextStyle(
                                      color: AppTheme.marineOrange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                            ],

                            Text(
                              paint.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              paint.brand,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryBlue.withOpacity(
                                      0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    paint.category,
                                    style: TextStyle(
                                      color: AppTheme.primaryBlue,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                if (paint.isMetallic ||
                                    paint.isTransparent) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      paint.isMetallic
                                          ? 'Metallic'
                                          : 'Transparent',
                                      style: TextStyle(
                                        color: Colors.amber[800],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Brand avatar and info column on the right
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Brand avatar
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: _getBrandColor(paint.brand),
                            child: Text(
                              paint.brand.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Color code and barcode in small format
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.color_lens,
                                size: 12,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 2),
                              Text(
                                paint.hex,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.qr_code,
                                size: 12,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 2),
                              Text(
                                'EAN-13',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Show palettes if any
                  if (palettes.isNotEmpty) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.palette_outlined,
                          size: 18,
                          color: Colors.purple,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'In Palettes:',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              _buildPaletteChips(palettes),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Date added
                  Text(
                    'Added on ${_formatDate(addedAt)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Build palette chips, limiting to 2 initially with a "View more" option
  Widget _buildPaletteChips(List<Palette> palettes) {
    // State for expanded view
    bool isExpanded = false;

    return StatefulBuilder(
      builder: (context, setState) {
        // Show all palettes if expanded, otherwise limit to 2
        final displayPalettes =
            isExpanded ? palettes : palettes.take(2).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                ...displayPalettes.map((palette) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.purple.withOpacity(0.3)),
                    ),
                    child: Text(
                      palette.name,
                      style: TextStyle(color: Colors.purple[700], fontSize: 11),
                    ),
                  );
                }),

                // Show "View more" chip if there are more than 2 palettes and not expanded
                if (palettes.length > 2 && !isExpanded)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        isExpanded = true;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '+${palettes.length - 2} more',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 11,
                            ),
                          ),
                          Icon(
                            Icons.keyboard_arrow_down,
                            size: 11,
                            color: Colors.grey[700],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            // Show collapse option if expanded
            if (isExpanded && palettes.length > 2)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      isExpanded = false;
                    });
                  },
                  child: Text(
                    'Show less',
                    style: TextStyle(
                      color: Colors.purple[700],
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Helper to build info rows for color code and barcode
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  /// Returns a brand-specific color for avatars
  Color _getBrandColor(String brand) {
    switch (brand.toLowerCase()) {
      case 'citadel':
        return Colors.blue[700]!;
      case 'vallejo':
        return Colors.green[700]!;
      case 'army painter':
        return Colors.red[700]!;
      case 'scale75':
        return Colors.purple[700]!;
      default:
        // Generate a color based on the brand name
        return Color((brand.hashCode & 0xFFFFFF) | 0xFF000000);
    }
  }

  /// Shows a bottom sheet with actions for a paint
  void _showActionSheet(Paint paint, bool isPriority, String _id) {
    // Get palettes containing this paint
    final palettes = _paintService.getPalettesContainingPaint(paint.id);

    // Simulate a barcode - in a real app, this would come from a barcode service
    final simulatedBarcode =
        "EAN-13: ${paint.id.hashCode.abs() % 10000000000000}";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Paint info header with brand avatar on the right
                  Row(
                    children: [
                      // Paint color
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(
                            int.parse(paint.hex.substring(1), radix: 16) +
                                0xFF000000,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.3),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Paint name and brand
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              paint.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              paint.brand,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Brand avatar with info below
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Brand avatar
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: _getBrandColor(paint.brand),
                            child: Text(
                              paint.brand.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Color code and barcode in small format
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.color_lens,
                                size: 12,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 2),
                              Text(
                                paint.hex,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.qr_code,
                                size: 12,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 2),
                              Text(
                                'EAN-13',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),

                  // Paint type information
                  Row(
                    children: [
                      Icon(Icons.category, size: 18, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Type:',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        paint.isMetallic
                            ? 'Metallic'
                            : paint.isTransparent
                            ? 'Transparent'
                            : 'Standard',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  // Palettes info (limit to 2 with View More)
                  if (palettes.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.palette_outlined,
                          size: 18,
                          color: Colors.purple,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'In Palettes:',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              _buildPaletteChips(palettes),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Action buttons
                  _buildActionButton(
                    icon: isPriority ? Icons.star : Icons.star_border,
                    text: isPriority ? 'Remove priority' : 'Mark as priority',
                    color:
                        isPriority
                            ? Colors.amber
                            : Theme.of(context).colorScheme.primary,
                    onTap: () {
                      Navigator.pop(context);
                      _togglePriority(paint.id, isPriority, _id);
                    },
                  ),

                  _buildActionButton(
                    icon: Icons.add_shopping_cart,
                    text: 'Add to inventory',
                    color: AppTheme.primaryBlue,
                    onTap: () {
                      Navigator.pop(context);
                      _addToInventory(paint, _id);
                    },
                  ),

                  _buildActionButton(
                    icon: Icons.delete_outline,
                    text: 'Remove from wishlist',
                    color: Colors.red,
                    onTap: () {
                      Navigator.pop(context);
                      _removeFromWishlist(paint.id, paint.name, _id);
                    },
                  ),

                  const SizedBox(height: 16),

                  // Cancel button with lighter color and rounded style
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Helper to build action buttons for the bottom sheet
  Widget _buildActionButton({
    required IconData icon,
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 16),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
                const Spacer(),
                Icon(Icons.chevron_right, color: color.withOpacity(0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}

/// Dialog to add a paint to inventory
class _AddToInventoryDialog extends StatefulWidget {
  final Paint paint;

  const _AddToInventoryDialog({required this.paint});

  @override
  State<_AddToInventoryDialog> createState() => _AddToInventoryDialogState();
}

class _AddToInventoryDialogState extends State<_AddToInventoryDialog> {
  int _quantity = 1;
  String? _note;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add ${widget.paint.name} to Inventory'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('How many do you have?'),
          const SizedBox(height: 16),

          // Quantity selector
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed:
                    _quantity > 1
                        ? () {
                          setState(() {
                            _quantity--;
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
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.2),
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _quantity.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () {
                  setState(() {
                    _quantity++;
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Note field
          TextField(
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              hintText: 'E.g.: Almost empty, purchased at...',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
            onChanged: (value) {
              setState(() {
                _note = value.isEmpty ? null : value;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop({'quantity': _quantity, 'note': _note});
          },
          child: const Text('ADD'),
        ),
      ],
    );
  }
}
