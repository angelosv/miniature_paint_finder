import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/components/app_header.dart';
import 'package:miniature_paint_finder/controllers/palette_controller.dart';
import 'package:miniature_paint_finder/models/palette.dart';
import 'package:miniature_paint_finder/repositories/palette_repository.dart';
import 'package:miniature_paint_finder/services/paint_service.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

/// Screen that displays all user palettes
class PaletteScreen extends StatefulWidget {
  /// Constructs the palette screen
  const PaletteScreen({super.key});

  @override
  State<PaletteScreen> createState() => _PaletteScreenState();
}

class _PaletteScreenState extends State<PaletteScreen> {
  late PaletteController _paletteController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final PaintService _paintService = PaintService();
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Initialize controller
    _paletteController = PaletteController(context.read<PaletteRepository>());
    _loadPalettes();
  }

  Future<void> _loadPalettes() async {
    await _paletteController.loadPalettes();
  }

  Future<void> _createPaletteFromImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        // Show dialog to get palette name
        final name = await showDialog<String>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Name Your Palette'),
                content: TextField(
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Enter palette name',
                    border: OutlineInputBorder(),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('CANCEL'),
                  ),
                  TextButton(
                    onPressed: () {
                      final textField = context.findRenderObject() as RenderBox;
                      final name = (textField as dynamic).controller.text;
                      Navigator.pop(context, name);
                    },
                    child: const Text('CREATE'),
                  ),
                ],
              ),
        );

        if (name != null && name.isNotEmpty) {
          // TODO: Implement color extraction from image
          // For now, we'll just create a palette with a placeholder image
          final success = await _paletteController.createPalette(
            name: name,
            imagePath: image.path,
            colors: [], // Colors will be extracted from image
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  success != null
                      ? 'Palette "$name" created'
                      : 'Failed to create palette',
                ),
                backgroundColor: success != null ? Colors.green : Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating palette: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createPaletteFromBarcode() async {
    // Navigate to barcode scanner screen
    final result = await Navigator.pushNamed(context, '/barcode-scanner');

    if (result != null && result is Map<String, dynamic>) {
      final paint = result['paint'];
      final name = result['name'] ?? 'New Palette';

      // Create palette with the scanned paint
      final success = await _paletteController.createPalette(
        name: name,
        imagePath: 'assets/images/placeholder_palette.png',
        colors: [
          Color(int.parse(paint.colorHex.substring(1), radix: 16) + 0xFF000000),
        ],
      );

      if (success != null) {
        // Add the paint to the palette
        await _paletteController.addPaintToPalette(
          success.id,
          paint,
          paint.colorHex,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success != null
                  ? 'Palette "$name" created'
                  : 'Failed to create palette',
            ),
            backgroundColor: success != null ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  void _showCreatePaletteOptions() {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.image),
                  title: const Text('Create from Image'),
                  subtitle: const Text('Extract colors from an image'),
                  onTap: () {
                    Navigator.pop(context);
                    _createPaletteFromImage();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.qr_code_scanner),
                  title: const Text('Create from Barcode'),
                  subtitle: const Text('Scan paint barcodes'),
                  onTap: () {
                    Navigator.pop(context);
                    _createPaletteFromBarcode();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.palette),
                  title: const Text('Create Empty Palette'),
                  subtitle: const Text('Start with a blank palette'),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Implement empty palette creation
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Empty palette creation coming soon'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _deletePalette(Palette palette) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Deletion'),
            content: Text(
              'Delete palette "${palette.name}"? This cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('DELETE'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      final success = await _paletteController.deletePalette(palette.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Palette "${palette.name}" deleted'
                  : 'Failed to delete palette',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  void _showPaletteDetails(Palette palette) {
    // We would normally navigate to a detail screen here
    // For now we'll show a simple modal bottom sheet with palette info
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: isDarkMode ? AppTheme.darkSurface : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with palette name and close button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            palette.name,
                            style: Theme.of(context).textTheme.titleLarge,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  // Creation date
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Created ${_formatDate(palette.createdAt)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color:
                            isDarkMode
                                ? AppTheme.darkTextSecondary
                                : AppTheme.textGrey,
                      ),
                    ),
                  ),

                  const Divider(height: 30),

                  // Color chips - updated visualization
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Colors',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Updated color visualization
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      height: 160, // Increased height for the new design
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: palette.colors.length,
                        itemBuilder: (context, index) {
                          final color = palette.colors[index];
                          final isInInventory = _isColorInInventory(color);
                          final isInWishlist = _isColorInWishlist(color);

                          // Get color name or hex code representation
                          final colorHex =
                              '#${color.value.toRadixString(16).toUpperCase().substring(2)}';
                          final luminance = color.computeLuminance();
                          final textColor =
                              luminance > 0.5 ? Colors.black : Colors.white;

                          return Container(
                            width: 110,
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Status indicators
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (isInInventory)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withOpacity(
                                              0.8,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: const Text(
                                            'IN STOCK',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      if (isInWishlist && !isInInventory)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.marineOrange
                                                .withOpacity(0.8),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: const Text(
                                            'WISHLIST',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),

                                // Color info at bottom
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.3),
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(12),
                                      bottomRight: Radius.circular(12),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        colorHex,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      if (palette.paintSelections != null)
                                        ...palette.paintSelections!
                                            .where(
                                              (p) =>
                                                  p.colorHex.toUpperCase() ==
                                                  colorHex,
                                            )
                                            .map(
                                              (p) => Text(
                                                p.paintName,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            )
                                            .toList(),
                                      // Add paint button
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          GestureDetector(
                                            onTap: () {
                                              // Add paint selection functionality here
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Add paint selection coming soon',
                                                  ),
                                                ),
                                              );
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: AppTheme.marineBlue
                                                    .withOpacity(0.8),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.add,
                                                size: 16,
                                                color: Colors.white,
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
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Paint selections
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Selected Paints',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // If no paints are selected yet
                  if (palette.paintSelections == null ||
                      palette.paintSelections!.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      child: Text(
                        'No paints have been selected for this palette yet.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color:
                              isDarkMode
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.textGrey,
                        ),
                      ),
                    ),

                  // Paint selections list
                  if (palette.paintSelections != null &&
                      palette.paintSelections!.isNotEmpty)
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: palette.paintSelections!.length,
                        itemBuilder: (context, index) {
                          final paint = palette.paintSelections![index];
                          final isInInventory = _isPaintInInventory(
                            paint.paintId,
                          );
                          final isInWishlist = _isPaintInWishlist(
                            paint.paintId,
                          );

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 4,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: paint.paintColor,
                                child: Text(
                                  paint.brandAvatar,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(child: Text(paint.paintName)),
                                  if (isInInventory)
                                    Icon(
                                      Icons.inventory_2,
                                      size: 16,
                                      color: Colors.green,
                                    ),
                                  if (isInWishlist && !isInInventory)
                                    Icon(
                                      Icons.favorite,
                                      size: 16,
                                      color: AppTheme.marineOrange,
                                    ),
                                ],
                              ),
                              subtitle: Text(paint.paintBrand),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Match percentage
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getMatchColor(
                                        paint.matchPercentage,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${paint.matchPercentage}%',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _removePaintFromPalette(
                                        palette.id,
                                        paint.paintId,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _removePaintFromPalette(String paletteId, String paintId) async {
    final success = await _paletteController.removePaintFromPalette(
      paletteId,
      paintId,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Paint removed from palette' : 'Failed to remove paint',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Color _getMatchColor(int matchPercentage) {
    if (matchPercentage >= 90) {
      return Colors.green;
    } else if (matchPercentage >= 75) {
      return Colors.amber;
    } else {
      return Colors.orange;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 1) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else {
      return '${(difference.inDays / 365).floor()} years ago';
    }
  }

  bool _isColorInInventory(Color color) {
    // This would normally check the user's inventory
    // For now, we'll just randomly return true or false for demo purposes
    return color.blue > 128; // Just an example condition
  }

  bool _isColorInWishlist(Color color) {
    // This would normally check the user's wishlist
    // For now, we'll just randomly return true or false for demo purposes
    return color.red > 128; // Just an example condition
  }

  bool _isPaintInInventory(String paintId) {
    // This would normally check the user's inventory
    // For now, we'll just randomly return true or false for demo purposes
    // return _paintService.isPaintInInventory(paintId);
    return paintId.length % 2 == 0; // Just a mock implementation
  }

  bool _isPaintInWishlist(String paintId) {
    // This would normally check the user's wishlist
    // For now, we'll just randomly return true or false for demo purposes
    // return _paintService.isPaintInWishlist(paintId);
    return paintId.length % 3 == 0; // Just a mock implementation
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppHeader(
        title: 'My Palettes',
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Palettes help you organize paint schemes'),
                ),
              );
            },
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _paletteController,
        builder: (context, _) {
          if (_paletteController.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_paletteController.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading palettes',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(_paletteController.error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadPalettes,
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            );
          }

          if (_paletteController.palettes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.palette_outlined,
                    size: 64,
                    color:
                        isDarkMode
                            ? AppTheme.marineBlueLight
                            : AppTheme.marineBlue,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Palettes Yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Create a palette to organize colors and matching paints for your projects',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color:
                            isDarkMode
                                ? AppTheme.darkTextSecondary
                                : AppTheme.textGrey,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _showCreatePaletteOptions,
                    icon: const Icon(Icons.add),
                    label: const Text('Create a Palette'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadPalettes,
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: _paletteController.palettes.length,
              itemBuilder: (context, index) {
                final palette = _paletteController.palettes[index];
                return _buildPaletteCard(palette);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePaletteOptions,
        backgroundColor:
            isDarkMode ? AppTheme.marineOrange : AppTheme.marineBlue,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPaletteCard(Palette palette) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _showPaletteDetails(palette),
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? AppTheme.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display palette image or placeholder
            Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                image: DecorationImage(
                  image: AssetImage(palette.imagePath),
                  fit: BoxFit.cover,
                ),
              ),
              alignment: Alignment.topRight,
              child: PopupMenuButton<String>(
                icon: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.more_vert, color: Colors.white),
                ),
                onSelected: (value) {
                  if (value == 'delete') {
                    _deletePalette(palette);
                  }
                },
                itemBuilder:
                    (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
              ),
            ),

            // Palette name
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: Text(
                palette.name,
                style: Theme.of(context).textTheme.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Creation date
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                _formatDate(palette.createdAt),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),

            // Color chips at the bottom
            Expanded(
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children:
                        palette.colors
                            .take(5) // Limit number of colors shown
                            .map(
                              (color) => Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color:
                                        isDarkMode
                                            ? Colors.white12
                                            : Colors.black12,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
