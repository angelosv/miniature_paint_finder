import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:miniature_paint_finder/components/app_header.dart';
import 'package:miniature_paint_finder/components/palette_modal.dart';
import 'package:miniature_paint_finder/controllers/palette_controller.dart';
import 'package:miniature_paint_finder/models/palette.dart';
import 'package:miniature_paint_finder/models/paint.dart';
import 'package:miniature_paint_finder/providers/theme_provider.dart';
import 'package:miniature_paint_finder/repositories/palette_repository.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';
import 'package:miniature_paint_finder/theme/app_responsive.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:miniature_paint_finder/screens/barcode_scanner_screen.dart';
import 'package:miniature_paint_finder/widgets/app_scaffold.dart';
import 'package:miniature_paint_finder/widgets/shared_drawer.dart';

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
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Get controller from provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Ensure we get a fresh load of palettes when screen initializes
      context.read<PaletteController>().loadPalettes();
    });
  }

  void _showCreatePaletteOptions() {
    // Controlador para el nombre de la paleta
    final TextEditingController nameController = TextEditingController();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDarkMode ? const Color(0xFF101823) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 16,
              left: 24,
              right: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle Bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color:
                          isDarkMode
                              ? Colors.grey.withOpacity(0.3)
                              : Colors.grey.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Title con color naranja y en negrita
                Text(
                  'Create New Palette',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color:
                        isDarkMode
                            ? AppTheme.marineOrange
                            : AppTheme.marineBlue,
                  ),
                ),
                const SizedBox(height: 24),

                // Palette Name Input con estilo según el tema
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Palette Name',
                    hintText: 'Enter a name for your palette',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color:
                            isDarkMode
                                ? Colors.white30
                                : Colors.grey.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color:
                            isDarkMode
                                ? Colors.white30
                                : Colors.grey.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color:
                            isDarkMode
                                ? AppTheme.marineOrange
                                : AppTheme.marineBlue,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor:
                        isDarkMode
                            ? Colors.white.withOpacity(0.05)
                            : Colors.grey.withOpacity(0.05),
                    labelStyle: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                    hintStyle: TextStyle(
                      color:
                          isDarkMode
                              ? Colors.white.withOpacity(0.3)
                              : Colors.black.withOpacity(0.3),
                    ),
                    prefixIcon: Icon(
                      Icons.edit,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  autofocus: true,
                  cursorColor:
                      isDarkMode ? AppTheme.marineOrange : AppTheme.marineBlue,
                ),
                const SizedBox(height: 32),

                // Divider with label
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color:
                            isDarkMode
                                ? Colors.grey.withOpacity(0.3)
                                : Colors.grey.withOpacity(0.3),
                        thickness: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Add Colors By',
                        style: TextStyle(
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color:
                            isDarkMode
                                ? Colors.grey.withOpacity(0.3)
                                : Colors.grey.withOpacity(0.3),
                        thickness: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Options in vertical layout
                // Find color in an image
                _buildOptionButton(
                  context: context,
                  icon: Icons.image_search,
                  label: 'Find colors in image',
                  isDarkMode: isDarkMode,
                  onPressed: () {
                    if (nameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a palette name'),
                        ),
                      );
                      return;
                    }
                    Navigator.pop(context);

                    // Start the image color search flow from PaintListTab
                    _startPaintSearchFlow(nameController.text);
                  },
                ),

                const SizedBox(height: 16),

                // Search the Library
                _buildOptionButton(
                  context: context,
                  icon: Icons.search,
                  label: 'Search the library',
                  isDarkMode: isDarkMode,
                  onPressed: () {
                    if (nameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a palette name'),
                        ),
                      );
                      return;
                    }
                    Navigator.pop(context);
                    // Aquí implementaremos la búsqueda en la biblioteca
                    _openPaintLibrarySearch(nameController.text);
                  },
                ),

                const SizedBox(height: 16),

                // Scan a paint barcode
                _buildOptionButton(
                  context: context,
                  icon: Icons.qr_code_scanner,
                  label: 'Scan paint barcode',
                  isDarkMode: isDarkMode,
                  onPressed: () {
                    if (nameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a palette name'),
                        ),
                      );
                      return;
                    }
                    Navigator.pop(context);
                    // Navegar a la pantalla de escaneo existente
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BarcodeScannerScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
    );
  }

  // Widget helper para crear botones de opciones con estilo consistente
  Widget _buildOptionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isDarkMode,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: isDarkMode ? Colors.white : Colors.black87,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isDarkMode ? AppTheme.marineOrange : AppTheme.marineBlue,
            width: 1.5,
          ),
        ),
        elevation: 0,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isDarkMode ? AppTheme.marineOrange : AppTheme.marineBlue,
            size: 24,
          ),
          const SizedBox(width: 16),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // Método para iniciar el flujo de búsqueda de colores en imagen
  void _startPaintSearchFlow(String paletteName) {
    // Navegar a la pantalla Home y seleccionar el tab Paint Search
    Navigator.pushNamed(
      context,
      '/home',
      arguments: {
        'selectedIndex': 0, // Tab de Paint Search
        'paletteInfo': {'isCreatingPalette': true, 'paletteName': paletteName},
      },
    );
  }

  Future<void> _createPaletteFromImage([String? prefilledName]) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        // Si ya tenemos un nombre prefijado, no mostramos el diálogo
        String? name = prefilledName;

        // Si no hay nombre prefijado, mostramos el diálogo
        if (name == null || name.isEmpty) {
          name = await showDialog<String>(
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
                        final textField =
                            context.findRenderObject() as RenderBox;
                        final name = (textField as dynamic).controller.text;
                        Navigator.pop(context, name);
                      },
                      child: const Text('CREATE'),
                    ),
                  ],
                ),
          );
        }

        if (name != null && name.isNotEmpty) {
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

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);
    _paletteController = Provider.of<PaletteController>(context);

    return AppScaffold(
      scaffoldKey: _scaffoldKey,
      title: 'My Palettes',
      selectedIndex: 1, // Palette tab
      body: _buildBody(context, isDarkMode),
      drawer: const SharedDrawer(currentScreen: 'palettes'),
    );
  }

  Widget _buildBody(BuildContext context, bool isDarkMode) {
    // Use the controller from provider to get data
    final palettes = _paletteController.palettes;
    final isLoading = _paletteController.isLoading;
    final error = _paletteController.error;

    return RefreshIndicator(
      onRefresh: () => _paletteController.loadPalettes(),
      child: Column(
        children: [
          // Error indicator if there's an error
          if (error != null)
            Container(
              color: Colors.red[100],
              padding: const EdgeInsets.all(8),
              width: double.infinity,
              child: Text(
                'Error: $error',
                style: const TextStyle(color: Colors.red),
              ),
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Text(
                  'Your Color Collections',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.sort, size: 18),
                  label: const Text('Sort', style: TextStyle(fontSize: 14)),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Sorting options coming soon'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Loading indicator
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),

          // Palettes grid
          Expanded(
            child:
                palettes.isEmpty && !isLoading
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.palette_outlined,
                            size: 64,
                            color:
                                isDarkMode
                                    ? Colors.grey[700]
                                    : Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No palettes yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color:
                                  isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create your first palette',
                            style: TextStyle(
                              fontSize: 16,
                              color:
                                  isDarkMode
                                      ? Colors.grey[500]
                                      : Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Create Palette'),
                            onPressed: _showCreatePaletteOptions,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                    : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount:
                            MediaQuery.of(context).size.width > 600 ? 3 : 2,
                        childAspectRatio: 0.8,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: palettes.length,
                      itemBuilder: (context, index) {
                        final palette = palettes[index];
                        return _buildPaletteCard(palette);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaletteCard(Palette palette) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final hasPaletteSwatch = palette.colors.isNotEmpty;
    final hasSelections =
        palette.paintSelections != null && palette.paintSelections!.isNotEmpty;
    final bool hasImage =
        palette.imagePath.isNotEmpty &&
        palette.imagePath !=
            'assets/images/placeholder.png'; // Detectar imágenes antiguas

    return Hero(
      tag: 'palette-${palette.id}',
      child: Material(
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: isDarkMode ? Colors.black54 : Colors.black26,
        child: InkWell(
          onTap: () {
            showPaletteModal(
              context,
              palette.name,
              palette.paintSelections ?? [],
              imagePath: 'assets/images/placeholder.jpeg',
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Palette image or color swatch
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: Stack(
                  children: [
                    // Background image or color grid
                    Container(
                      height: 120,
                      width: double.infinity,
                      child:
                          hasImage
                              ? Image.asset(
                                palette.imagePath,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  // Si hay error al cargar, usar placeholder
                                  return Image.asset(
                                    'assets/images/placeholder.jpeg',
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      // Si también falla el placeholder, mostrar grid
                                      return hasPaletteSwatch
                                          ? GridView.count(
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            crossAxisCount: 3,
                                            children:
                                                palette.colors
                                                    .map(
                                                      (color) => Container(
                                                        color: color,
                                                      ),
                                                    )
                                                    .toList(),
                                          )
                                          : Container(
                                            color:
                                                isDarkMode
                                                    ? Colors.grey[800]
                                                    : Colors.grey[200],
                                            child: Center(
                                              child: Icon(
                                                Icons.palette_outlined,
                                                size: 40,
                                                color:
                                                    isDarkMode
                                                        ? Colors.grey[700]
                                                        : Colors.grey[400],
                                              ),
                                            ),
                                          );
                                    },
                                  );
                                },
                              )
                              : hasPaletteSwatch
                              ? Stack(
                                children: [
                                  // Fondo con placeholder
                                  Image.asset(
                                    'assets/images/placeholder.jpeg',
                                    fit: BoxFit.cover,
                                    height: 120,
                                    width: double.infinity,
                                  ),
                                  // Grid de colores con transparencia
                                  GridView.count(
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    crossAxisCount: 3,
                                    children:
                                        palette.colors
                                            .map(
                                              (color) => Container(
                                                color: color.withOpacity(0.6),
                                              ),
                                            )
                                            .toList(),
                                  ),
                                ],
                              )
                              : Container(
                                color:
                                    isDarkMode
                                        ? Colors.grey[800]
                                        : Colors.grey[200],
                                child: Center(
                                  child: Icon(
                                    Icons.palette_outlined,
                                    size: 40,
                                    color:
                                        isDarkMode
                                            ? Colors.grey[700]
                                            : Colors.grey[400],
                                  ),
                                ),
                              ),
                    ),

                    // Badge overlays
                    if (!hasPaletteSwatch)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.color_lens,
                                color: Colors.white,
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Processing',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Paint selections badge
                    if (hasSelections)
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.brush,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${palette.paintSelections!.length} Paints',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Palette info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        palette.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Date created
                      Text(
                        _formatDate(palette.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      const Spacer(),
                      // Color count and delete button
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isDarkMode
                                      ? Colors.grey[800]
                                      : Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.palette,
                                  size: 14,
                                  color:
                                      isDarkMode
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${palette.colors.length}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isDarkMode
                                            ? Colors.grey[400]
                                            : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          InkWell(
                            onTap: () => _deletePalette(palette),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.delete_outline,
                                size: 18,
                                color:
                                    isDarkMode
                                        ? Colors.red[300]
                                        : Colors.red[400],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 1) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    }
  }

  // Método para abrir la búsqueda en la biblioteca de pinturas
  void _openPaintLibrarySearch(String paletteName) {
    // Por ahora, mostramos un diálogo informativo de que esta función está en desarrollo
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Coming Soon'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This feature will allow you to search for paints in the library to add to your palette "$paletteName".',
                ),
                const SizedBox(height: 16),
                const Text(
                  'Available in the next update!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }
}
