import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/components/app_header.dart';
import 'package:miniature_paint_finder/controllers/palette_controller.dart';
import 'package:miniature_paint_finder/models/palette.dart';
import 'package:miniature_paint_finder/repositories/palette_repository.dart';
import 'package:miniature_paint_finder/services/paint_service.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';
import 'package:miniature_paint_finder/theme/app_responsive.dart';
import 'package:miniature_paint_finder/screens/palette_detail_screen.dart';
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

  Future<void> _showPaletteDetails(Palette palette) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with palette name and close button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        palette.name,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.black),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),

                // Creation date
                Text(
                  'Created ${_formatDate(palette.createdAt)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),

                const SizedBox(height: 20),

                // Colors section
                const Text(
                  'Colors',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),

                const SizedBox(height: 10),

                // Color grid - large squares in a single row
                if (palette.colors.isNotEmpty)
                  Container(
                    height: 80,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children:
                          palette.colors.map((color) {
                            return Container(
                              width: 48,
                              height: 48,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            );
                          }).toList(),
                    ),
                  ),

                const SizedBox(height: 20),

                // Selected Paints section
                const Text(
                  'Selected Paints',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),

                const SizedBox(height: 10),

                // Paint selections
                if (palette.paintSelections != null &&
                    palette.paintSelections!.isNotEmpty)
                  Column(
                    children:
                        palette.paintSelections!.map((paint) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                // Top part with paint info
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      // Brand avatar (circle with letter)
                                      CircleAvatar(
                                        radius: 25,
                                        backgroundColor: Colors.grey[200],
                                        child: Text(
                                          paint.brandAvatar,
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),

                                      // Paint name and brand
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              paint.paintName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                                color: Colors.black,
                                              ),
                                            ),
                                            Text(
                                              paint.paintBrand,
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Match percentage badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getMatchColor(
                                            paint.matchPercentage,
                                          ).withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: Text(
                                          '${paint.matchPercentage}% match',
                                          style: TextStyle(
                                            color: _getMatchColor(
                                              paint.matchPercentage,
                                            ),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Bottom part with color code and barcode
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(12),
                                      bottomRight: Radius.circular(12),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      // Color code section
                                      Row(
                                        children: [
                                          Container(
                                            width: 24,
                                            height: 24,
                                            decoration: BoxDecoration(
                                              color: paint.paintColor,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Color code:',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              Text(
                                                paint.paintId.split('-').last,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),

                                      const Spacer(),

                                      // Barcode section
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Barcode:',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.qr_code,
                                                size: 16,
                                                color: Colors.black,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '50119${paint.paintId.hashCode.abs() % 10000000}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                  )
                else
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        Icon(
                          Icons.palette_outlined,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No paints selected yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap on a color to find matching paints',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
              ],
            ),
          ),
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

  void _navigateToPaletteDetail(Palette palette) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaletteDetailScreen(palette: palette),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      appBar: const AppHeader(title: 'My Palettes', showBackButton: false),
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

          // Siempre mostrar 2 columnas como estaba originalmente
          final crossAxisCount = 2; // Fijo en 2 columnas

          // Hacer las tarjetas más pequeñas
          final childAspectRatio = 0.85; // Un poco más cuadradas que antes

          // Padding moderado
          final gridPadding = const EdgeInsets.all(16);

          // Espaciado entre tarjetas
          final crossAxisSpacing = 16.0;
          final mainAxisSpacing = 16.0;

          return RefreshIndicator(
            onRefresh: _loadPalettes,
            child: GridView.builder(
              padding: gridPadding,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: crossAxisSpacing,
                mainAxisSpacing: mainAxisSpacing,
                childAspectRatio: childAspectRatio,
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

    // Tamaños fijos más pequeños
    final containerHeight = 100.0; // Reducir altura de la imagen
    final colorSize = 20.0; // Tamaño más pequeño para los círculos de color
    final chipSpacing = 4.0; // Espaciado entre círculos de color

    // Tamaños de texto reducidos
    final titleFontSize = 14.0;
    final subtitleFontSize = 12.0;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: InkWell(
        onTap: () => _navigateToPaletteDetail(palette),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display palette image or placeholder
            Container(
              height: containerHeight,
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
                  child: const Icon(
                    Icons.more_vert,
                    color: Colors.white,
                    size: 20,
                  ),
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
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Edit', style: TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                    ],
              ),
            ),

            // Palette name
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 2),
              child: Text(
                palette.name,
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Creation date
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                _formatDate(palette.createdAt),
                style: TextStyle(
                  fontSize: subtitleFontSize,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ),

            // Color chips at the bottom - with fixed number of elements
            Expanded(
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      ...palette.colors
                          .take(4)
                          .map(
                            (color) => Container(
                              width: colorSize,
                              height: colorSize,
                              margin: const EdgeInsets.only(right: 4),
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
                          ),
                      // Show a +X indicator if there are more colors
                      if (palette.colors.length > 4)
                        Container(
                          width: colorSize,
                          height: colorSize,
                          decoration: BoxDecoration(
                            color:
                                isDarkMode
                                    ? Colors.grey[700]
                                    : Colors.grey[300],
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '+${palette.colors.length - 4}',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color:
                                    isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                    ],
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
