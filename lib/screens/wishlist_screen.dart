import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/models/paint.dart';
import 'package:miniature_paint_finder/models/palette.dart';
import 'package:miniature_paint_finder/services/paint_service.dart';
import 'package:miniature_paint_finder/services/brand_service.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';
import 'package:miniature_paint_finder/components/app_header.dart';
import 'package:miniature_paint_finder/widgets/app_scaffold.dart';
import 'package:miniature_paint_finder/widgets/shared_drawer.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:miniature_paint_finder/controllers/wishlist_controller.dart';

/// Screen that displays all paints in the user's wishlist
class WishlistScreen extends StatefulWidget {
  /// Constructs the wishlist screen
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final PaintService _paintService = PaintService();
  final BrandService _brandService = BrandService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // Cargar wishlist cuando se inicia el widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WishlistController>().loadWishlist();
      _loadBrandData();
    });
  }

  /// Carga los datos de marcas y logotipos
  Future<void> _loadBrandData() async {
    // Ensure brands are loaded before trying to display logos
    print('🔄 Initializing BrandService...');
    final success = await _brandService.initialize();
    print(
      success
          ? '✅ BrandService initialized successfully'
          : '❌ BrandService initialization failed',
    );
  }

  /// Determinar el brandId correcto de forma segura
  String _getSafeBrandId(Paint paint) {
    try {
      final brandId = _brandService.getBrandId(paint.brand);
      if (brandId != null) {
        return brandId;
      }

      // Si no se encontró, intentar casos especiales
      if ((paint.brand.toLowerCase().contains('army') &&
              paint.brand.toLowerCase().contains('painter')) ||
          paint.brand.toLowerCase().contains('warpaint')) {
        return 'Army_Painter';
      }

      if (paint.brand.toLowerCase().contains('citadel')) {
        return 'Citadel_Colour';
      }

      return paint.brand;
    } catch (e) {
      print('⚠️ Error determinando brandId: $e');
      return paint.brand;
    }
  }

  /// Obtener el nombre oficial de marca de forma segura
  String _getSafeBrandName(String brandId, String fallbackName) {
    try {
      final name = _brandService.getBrandName(brandId);
      return name ?? fallbackName;
    } catch (e) {
      print('⚠️ Error obteniendo nombre de marca: $e');
      return fallbackName;
    }
  }

  /// Construye el logo de la marca para la tarjeta
  Widget _buildBrandLogo(String brandId, String brandName, bool isDarkMode) {
    // Get logo URL from BrandService
    final String? logoUrl = _brandService.getLogoUrl(brandId);

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child:
          logoUrl != null
              ? ClipOval(
                child: Center(
                  child: Image.network(
                    logoUrl,
                    width: 40, // Slightly smaller to ensure it fits
                    height: 40,
                    fit: BoxFit.contain,
                    errorBuilder: (ctx, err, stack) {
                      print('⚠️ Image load error for $brandId: $err');
                      return Text(
                        brandName.isNotEmpty ? brandName[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      );
                    },
                  ),
                ),
              )
              : Center(
                child: Text(
                  brandName.isNotEmpty ? brandName[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
    );
  }

  /// Update the togglePriority method to handle priority levels
  Future<void> _togglePriority(
    String paintId,
    bool currentPriority,
    String _id, [
    int priorityLevel = 0,
  ]) async {
    try {
      // Use the priorityLevel parameter to determine the new priority
      final controller = context.read<WishlistController>();

      // Note: In our API, lower numbers = higher priority (0 is highest)
      // Convert UI priority level to API priority level
      final bool newPriorityFlag = priorityLevel > 0;
      final result = await controller.updatePriority(
        paintId,
        _id,
        newPriorityFlag,
        priorityLevel,
      );

      if (mounted && result) {
        String priorityMessage;
        if (priorityLevel <= 0) {
          priorityMessage = 'Removed from priority';
        } else {
          priorityMessage = 'Priority set to ${5 - priorityLevel} stars';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(priorityMessage),
            duration: const Duration(seconds: 2),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating priority'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
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

    final controller = context.read<WishlistController>();
    final result = await controller.removeFromWishlist(paintId, _id);

    if (result && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$paintName removed from wishlist'),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () async {
              // Find the paint in our list to get the priority status
              final wishlistItems = controller.wishlistItems;
              final item = wishlistItems.firstWhere(
                (item) => (item['paint'] as Paint).id == paintId,
                orElse: () => {'paint': null, 'isPriority': false},
              );

              if (item['paint'] != null) {
                await controller.addToWishlist(
                  item['paint'] as Paint,
                  item['isPriority'] as bool,
                );
              }
            },
          ),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error removing paint from wishlist'),
          backgroundColor: Colors.red,
        ),
      );
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

        // Remove from wishlist
        final controller = context.read<WishlistController>();
        final deleteResult = await controller.removeFromWishlist(paint.id, _id);

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
      selectedIndex: 2, // Uso del índice 2 para Wishlist
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
    return Consumer<WishlistController>(
      builder: (context, controller, child) {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Error loading wishlist',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(controller.errorMessage ?? 'Unknown error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => controller.loadWishlist(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (controller.isEmpty) {
          return _buildEmptyState();
        }

        return _buildWishlistContent(controller.wishlistItems);
      },
    );
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

  Widget _buildWishlistContent(List<Map<String, dynamic>> wishlistItems) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ListView.builder(
      itemCount: wishlistItems.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final item = wishlistItems[index];
        final paint = item['paint'] as Paint;
        final isPriority = item['isPriority'] as bool;
        final _id = item['id'] as String;
        final addedAt = item['addedAt'] as DateTime;

        // Get color from hex or colorHex property
        final String colorCode = paint.hex;
        final Color paintColor = Color(
          int.parse(colorCode.substring(1), radix: 16) + 0xFF000000,
        );

        // Determine correct brand ID and get official brand name
        final String brandId = _getSafeBrandId(paint);
        final String officialBrandName = _getSafeBrandName(
          brandId,
          paint.brand,
        );

        // Get priority level (0-5) where 0 is highest priority
        // Backend uses 0 for high priority, -1 for no priority
        final int priorityLevel = isPriority ? 0 : 5;

        // Get palettes containing this paint
        final palettes = _paintService.getPalettesContainingPaint(paint.id);

        // Card to display
        final card = Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
              width: 1,
            ),
          ),
          color: isDarkMode ? AppTheme.darkSurface : Colors.white,
          child: InkWell(
            onTap: () {
              _showPaintDetails(paint, isPriority, _id, palettes);
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
                        width: 55,
                        height: 55,
                        decoration: BoxDecoration(
                          color: paintColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color:
                                isDarkMode
                                    ? Colors.grey[700]!
                                    : Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Paint details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              paint.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color:
                                    isDarkMode
                                        ? AppTheme.marineOrange
                                        : AppTheme.primaryBlue,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              officialBrandName,
                              style: TextStyle(
                                fontSize: 14,
                                color:
                                    isDarkMode
                                        ? Colors.white70
                                        : Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),

                            // Star rating based on priority
                            Row(
                              children: [
                                ...List.generate(5, (index) {
                                  return Icon(
                                    index < (5 - priorityLevel)
                                        ? Icons.star
                                        : Icons.star_border,
                                    size: 16,
                                    color: AppTheme.marineOrange,
                                  );
                                }),
                                if (isPriority)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4),
                                    child: Text(
                                      'PRIORITY',
                                      style: TextStyle(
                                        color: AppTheme.marineOrange,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            // Category tags and Added date in one row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Category tag
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        isDarkMode
                                            ? AppTheme.primaryBlue.withOpacity(
                                              0.3,
                                            )
                                            : AppTheme.primaryBlue.withOpacity(
                                              0.1,
                                            ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    paint.category,
                                    style: TextStyle(
                                      color:
                                          isDarkMode
                                              ? Colors.lightBlue[100]
                                              : AppTheme.primaryBlue,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),

                                // Special properties tag
                                if (paint.isMetallic || paint.isTransparent)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            isDarkMode
                                                ? Colors.amber.withOpacity(0.3)
                                                : Colors.amber.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        paint.isMetallic
                                            ? 'Metallic'
                                            : 'Transparent',
                                        style: TextStyle(
                                          color:
                                              isDarkMode
                                                  ? Colors.amber[100]
                                                  : Colors.amber[800],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),

                                // Added date
                                const Spacer(),
                                Text(
                                  'Added ${_formatDate(addedAt)}',
                                  style: TextStyle(
                                    color:
                                        isDarkMode
                                            ? Colors.grey[400]
                                            : Colors.grey[600],
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),

                            // Palette tags if any
                            if (palettes.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Used in palettes:',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color:
                                            isDarkMode
                                                ? Colors.grey[300]
                                                : Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    _buildPaletteChips(palettes, isDarkMode),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Brand logo
                      _buildBrandLogo(brandId, officialBrandName, isDarkMode),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );

        // Wrap card with dismissible for swipe-to-delete but use direct deletion without confirmations
        return Dismissible(
          key: Key(_id),
          direction: DismissDirection.endToStart,
          // Properly align the background with the card
          background: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          // Only confirm once with dialog
          confirmDismiss: (direction) async {
            return await showDialog<bool>(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text('Confirm Removal'),
                        content: Text(
                          'Remove ${paint.name} from your wishlist?',
                        ),
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
                ) ??
                false;
          },
          onDismissed: (direction) {
            _removeFromWishlist(paint.id, paint.name, _id);
          },
          child: card,
        );
      },
    );
  }

  /// Build palette chips, limiting to 3 initially with a "View more" option
  Widget _buildPaletteChips(List<Palette> palettes, bool isDarkMode) {
    // State for expanded view
    bool isExpanded = false;

    // Lilac colors for palette chips
    final chipColor =
        isDarkMode
            ? Color(0xFF9370DB).withOpacity(
              0.3,
            ) // Medium purple with opacity for dark mode
            : Color(
              0xFFD8BFD8,
            ).withOpacity(0.6); // Thistle color with opacity for light mode

    final textColor =
        isDarkMode
            ? Color(0xFFE6E6FA) // Lavender for dark mode
            : Color(0xFF7B68EE); // Medium slate blue for light mode

    final borderColor =
        isDarkMode
            ? Color(0xFF9370DB).withOpacity(0.5)
            : Color(0xFF9370DB).withOpacity(0.3);

    return StatefulBuilder(
      builder: (context, setState) {
        // Show all palettes if expanded, otherwise limit to 3
        final displayPalettes =
            isExpanded ? palettes : palettes.take(3).toList();

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
                      color: chipColor,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: borderColor),
                    ),
                    child: Text(
                      palette.name,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }),

                // Show "View more" chip if there are more than 3 palettes and not expanded
                if (palettes.length > 3 && !isExpanded)
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
                        color:
                            isDarkMode
                                ? Colors.grey.withOpacity(0.3)
                                : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '+${palettes.length - 3} more',
                            style: TextStyle(
                              color:
                                  isDarkMode
                                      ? Colors.grey[300]
                                      : Colors.grey[700],
                              fontSize: 11,
                            ),
                          ),
                          Icon(
                            Icons.keyboard_arrow_down,
                            size: 11,
                            color:
                                isDarkMode
                                    ? Colors.grey[300]
                                    : Colors.grey[700],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            // Show collapse option if expanded
            if (isExpanded && palettes.length > 3)
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
                      color: textColor,
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

  /// Shows a bottom sheet with actions for a paint
  void _showPaintDetails(
    Paint paint,
    bool isPriority,
    String _id,
    List<Palette> palettes,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Determine brand ID and name
    final String brandId = _getSafeBrandId(paint);
    final String officialBrandName = _getSafeBrandName(brandId, paint.brand);

    // Current priority level (5 = no priority, 0-4 = priority level)
    int currentPriorityLevel = isPriority ? 0 : 5;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 16,
                  ),
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

                      // Paint info header with brand logo on the right
                      Row(
                        children: [
                          // Paint color
                          Container(
                            width: 55,
                            height: 55,
                            decoration: BoxDecoration(
                              color: Color(
                                int.parse(paint.hex.substring(1), radix: 16) +
                                    0xFF000000,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color:
                                    isDarkMode
                                        ? Colors.grey[700]!
                                        : Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Paint name, brand and additional info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  paint.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color:
                                        isDarkMode
                                            ? AppTheme.marineOrange
                                            : AppTheme.primaryBlue,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  officialBrandName,
                                  style: TextStyle(
                                    color:
                                        isDarkMode
                                            ? Colors.white70
                                            : Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                                // Add color code
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.colorize,
                                      size: 14,
                                      color:
                                          isDarkMode
                                              ? Colors.grey[400]
                                              : Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Code: ${paint.code}',
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
                                // Add barcode/hex
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.qr_code,
                                      size: 14,
                                      color:
                                          isDarkMode
                                              ? Colors.grey[400]
                                              : Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Color: ${paint.hex}',
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
                              ],
                            ),
                          ),

                          // Brand logo
                          _buildBrandLogo(
                            brandId,
                            officialBrandName,
                            isDarkMode,
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Add palette section above priority stars
                      _buildPalettesSection(palettes, isDarkMode),

                      const SizedBox(height: 20),

                      // Interactive star rating with sliding gesture
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Priority:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Star rating with sliding gesture
                          GestureDetector(
                            onHorizontalDragUpdate: (details) {
                              // Calculate star position based on drag position
                              final RenderBox box =
                                  context.findRenderObject() as RenderBox;
                              final double width = box.size.width;
                              final double position = details.localPosition.dx
                                  .clamp(0, width);
                              final double starWidth = width / 5;

                              // Convert position to star count (0-5)
                              int starCount = (position / starWidth).ceil();
                              starCount = starCount.clamp(0, 5);

                              // Update local state for immediate feedback
                              if (5 - starCount != currentPriorityLevel) {
                                setState(() {
                                  currentPriorityLevel = 5 - starCount;
                                });
                              }
                            },
                            onHorizontalDragEnd: (details) {
                              // Save the priority when drag ends
                              Navigator.pop(context);

                              // Convert current priority level to backend format
                              bool isPriority = currentPriorityLevel < 5;
                              _togglePriority(
                                paint.id,
                                !isPriority,
                                _id,
                                5 - currentPriorityLevel,
                              );
                            },
                            child: Container(
                              color:
                                  Colors
                                      .transparent, // Make entire area tappable
                              height: 40,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(5, (index) {
                                  return IconButton(
                                    icon: Icon(
                                      index < (5 - currentPriorityLevel)
                                          ? Icons.star
                                          : Icons.star_border,
                                      size: 28,
                                      color: AppTheme.marineOrange,
                                    ),
                                    onPressed: () {
                                      // Update local state first for immediate feedback
                                      setState(() {
                                        // Toggle between this star level and no priority
                                        if (currentPriorityLevel == index + 1) {
                                          currentPriorityLevel =
                                              5; // No priority
                                        } else {
                                          currentPriorityLevel =
                                              index + 1; // Set to this priority
                                        }
                                      });

                                      // Close modal and update server
                                      Navigator.pop(context);

                                      // Convert current priority level to backend format
                                      bool isPriority =
                                          currentPriorityLevel < 5;
                                      _togglePriority(
                                        paint.id,
                                        !isPriority,
                                        _id,
                                        5 - currentPriorityLevel,
                                      );
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: BoxConstraints(),
                                    splashRadius: 20,
                                  );
                                }),
                              ),
                            ),
                          ),

                          // Added indicator text to show sliding capability
                          Center(
                            child: Text(
                              'Slide to adjust priority',
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    isDarkMode
                                        ? Colors.grey[500]
                                        : Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),

                      // Paint info section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Paint type information
                          Row(
                            children: [
                              Icon(
                                Icons.category,
                                size: 18,
                                color:
                                    isDarkMode
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Type:',
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      isDarkMode
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                paint.isMetallic
                                    ? 'Metallic'
                                    : paint.isTransparent
                                    ? 'Transparent'
                                    : 'Standard',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      isDarkMode
                                          ? Colors.white
                                          : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Add to inventory button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _addToInventory(paint, _id);
                          },
                          icon: Icon(Icons.add_shopping_cart),
                          label: Text('Add to Inventory'),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            backgroundColor:
                                isDarkMode
                                    ? AppTheme.marineOrange
                                    : AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Create a new section for the palettes in the modal
  Widget _buildPalettesSection(List<Palette> palettes, bool isDarkMode) {
    // Demo palettes data if needed
    final demoPalettes = [
      {'name': 'Space Marines', 'color': Color(0xFFD8BFD8)},
      {'name': 'Imperial Guard', 'color': Color(0xFFD8BFD8)},
      {'name': 'Tau Empire', 'color': Color(0xFFD8BFD8)},
      {'name': 'Eldar Craftworlds', 'color': Color(0xFFD8BFD8)},
      {'name': 'Orks', 'color': Color(0xFFD8BFD8)},
      {'name': 'Tyranids', 'color': Color(0xFFD8BFD8)},
      {'name': 'Necrons', 'color': Color(0xFFD8BFD8)},
    ];

    // Use demo data or real data
    final displayPalettes =
        palettes.isNotEmpty
            ? palettes
            : demoPalettes
                .map(
                  (p) => Palette(
                    id: p['name'] as String,
                    name: p['name'] as String,
                    imagePath: '',
                    colors: [p['color'] as Color],
                    createdAt: DateTime.now(),
                  ),
                )
                .toList();

    // If there are no palettes, early return demo UI
    if (displayPalettes.isEmpty) {
      return Container();
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.black12 : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.palette_outlined, size: 18, color: Color(0xFF9370DB)),
              SizedBox(width: 8),
              Text(
                'In Palettes:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.grey[300] : Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Show first two palettes
              ...displayPalettes
                  .take(2)
                  .map(
                    (palette) => _buildPaletteChip(palette.name, isDarkMode),
                  ),

              // Only add "+5 more" button if there are more than 2 palettes
              if (displayPalettes.length > 2)
                _buildMorePalettesChip(
                  '${displayPalettes.length - 2} more',
                  isDarkMode,
                ),
            ],
          ),
        ],
      ),
    );
  }

  // Build an individual palette chip
  Widget _buildPaletteChip(String name, bool isDarkMode) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Color(0xFFD8BFD8), // Light purple background
        borderRadius: BorderRadius.circular(4), // Much less rounded corners
      ),
      child: Text(
        name,
        style: TextStyle(
          color: Color(0xFF673AB7), // Deep purple text
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
    );
  }

  // Build the "more palettes" chip
  Widget _buildMorePalettesChip(String text, bool isDarkMode) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[200], // Light grey background
        borderRadius: BorderRadius.circular(
          4,
        ), // Less rounded, matching other chips
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '+$text',
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey[700]),
        ],
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
