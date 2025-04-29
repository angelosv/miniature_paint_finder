import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:miniature_paint_finder/components/app_header.dart';
import 'package:miniature_paint_finder/components/palette_modal.dart';
import 'package:miniature_paint_finder/components/create_palette_sheet.dart';
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
import 'package:miniature_paint_finder/services/image_upload_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:miniature_paint_finder/services/image_cache_service.dart';

/// Screen that displays all user palettes
class PaletteScreen extends StatefulWidget {
  /// Constructs the palette screen
  const PaletteScreen({super.key});

  @override
  State<PaletteScreen> createState() => _PaletteScreenState();
}

/// Custom cache manager específico para paletas
class PaletteCacheManager extends CacheManager {
  static const key = 'paletteImageCache';

  static final PaletteCacheManager _instance = PaletteCacheManager._();
  factory PaletteCacheManager() {
    return _instance;
  }

  PaletteCacheManager._()
    : super(
        Config(
          key,
          stalePeriod: const Duration(days: 7),
          maxNrOfCacheObjects: 100,
          repo: JsonCacheInfoRepository(databaseName: key),
          fileService: HttpFileService(),
        ),
      );
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

      // Precarga las imágenes para mejorar la experiencia
      _precacheImages();
    });
  }

  /// Precarga las imágenes de paletas para acelerar la renderización
  void _precacheImages() async {
    final palettes = _paletteController.palettes;
    final imageCacheService = ImageCacheService();

    for (final palette in palettes) {
      if (palette.imagePath.startsWith('http')) {
        imageCacheService.preloadImage(
          palette.imagePath,
          context,
          cacheKey: 'palette_${palette.id}_card',
        );
      }
    }
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
                        builder:
                            (context) => BarcodeScannerScreen(
                              paletteName: nameController.text.trim(),
                            ),
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
        'paletteInfo': {
          'isCreatingPalette': true,
          'paletteName': paletteName,
          'source': 'palette_screen',
        },
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
          // Primero subimos la imagen
          final imageUploadService = ImageUploadService();
          final String imageUrl = await imageUploadService.uploadImage(
            File(image.path),
          );

          // Luego creamos la paleta con la URL de la imagen
          final success = await _paletteController.createPalette(
            name: name,
            imagePath: imageUrl,
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor:
                isDarkMode ? const Color(0xFF101823) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Delete Palette',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you sure you want to delete "${palette.name}"?',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This action cannot be undone.',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.red[300] : Colors.red[700],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isDarkMode ? Colors.red[300] : Colors.red[600],
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Delete',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          ),
    );

    if (confirmed == true) {
      final success = await _paletteController.deletePalette(palette.id);

      if (mounted) {
        // Mostrar mensaje de éxito o error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Palette "${palette.name}" deleted'
                  : 'Failed to delete palette',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );

        // Si la eliminación fue exitosa y estamos en la última página con una sola paleta,
        // cargar la página anterior
        if (success &&
            _paletteController.palettes.isEmpty &&
            _paletteController.currentPage > 1) {
          await _paletteController.loadPreviousPage();
        }
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
      selectedIndex: 3, // Índice 3 para My Palettes en el menú inferior
      body: _buildBody(context, isDarkMode),
      drawer: const SharedDrawer(currentScreen: 'palettes'),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePaletteOptions,
        backgroundColor:
            isDarkMode ? AppTheme.marineOrange : Theme.of(context).primaryColor,
        foregroundColor: isDarkMode ? AppTheme.marineBlue : Colors.white,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void _showCreatePaletteModal(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder:
                (_, controller) => Container(
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF101823) : Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: CreatePaletteSheet(scrollController: controller),
                ),
          ),
    );
  }

  Widget _buildBody(BuildContext context, bool isDarkMode) {
    return Column(
      children: [
        Expanded(
          child:
              _paletteController.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _paletteController.error != null
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _paletteController.error!,
                          style: TextStyle(
                            color: isDarkMode ? Colors.red[300] : Colors.red,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _paletteController.loadPalettes(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                  : _paletteController.palettes.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/palette_palceholder.png',
                          width: 200,
                          height: 200,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No palettes yet',
                          style: TextStyle(
                            fontSize: 18,
                            color:
                                isDarkMode ? Colors.white : AppTheme.marineBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create your first palette to get started',
                          style: TextStyle(
                            color:
                                isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
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
                    itemCount: _paletteController.palettes.length,
                    itemBuilder: (context, index) {
                      final palette = _paletteController.palettes[index];
                      return _buildPaletteCard(palette);
                    },
                  ),
        ),
        if (_paletteController.totalPages > 1)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[900] : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed:
                      _paletteController.currentPage > 1
                          ? () => _paletteController.loadPreviousPage()
                          : null,
                ),
                const SizedBox(width: 16),
                Text(
                  'Page ${_paletteController.currentPage} of ${_paletteController.totalPages}',
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed:
                      _paletteController.currentPage <
                              _paletteController.totalPages
                          ? () => _paletteController.loadNextPage()
                          : null,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPaletteCard(Palette palette) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final hasPaletteSwatch = palette.colors.isNotEmpty;
    final hasSelections =
        palette.paintSelections != null && palette.paintSelections!.isNotEmpty;
    final bool hasImage = palette.imagePath.startsWith('http');

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
              imagePath: palette.imagePath,
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: Stack(
                  children: [
                    // Background image or color grid - AQUÍ ES EL PROBLEM PRINCIPAL
                    AspectRatio(
                      aspectRatio: 16 / 9, // Mantener aspect ratio constante
                      child:
                          hasImage
                              ? CachedNetworkImage(
                                cacheManager: PaletteCacheManager(),
                                imageUrl: palette.imagePath,
                                cacheKey: 'palette_${palette.id}_card',
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                fadeInDuration: const Duration(
                                  milliseconds: 200,
                                ),
                                fadeOutDuration: const Duration(
                                  milliseconds: 200,
                                ),
                                placeholder:
                                    (context, url) => Container(
                                      color:
                                          isDarkMode
                                              ? Colors.grey[800]
                                              : Colors.grey[200],
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color:
                                              isDarkMode
                                                  ? Colors.orange
                                                  : Colors.blue,
                                        ),
                                      ),
                                    ),
                                errorWidget: (context, error, stackTrace) {
                                  print(
                                    '❌ Error loading network image: $error',
                                  );
                                  return _buildFallbackContent(
                                    isDarkMode,
                                    hasPaletteSwatch,
                                    palette,
                                  );
                                },
                              )
                              : _buildFallbackContent(
                                isDarkMode,
                                hasPaletteSwatch,
                                palette,
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
                                '${palette.totalPaints} Paints',
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
                        palette.createdAtText ?? _formatDate(palette.createdAt),
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

  Widget _buildFallbackContent(
    bool isDarkMode,
    bool hasPaletteSwatch,
    Palette palette,
  ) {
    if (hasPaletteSwatch) {
      return Container(
        width: 200,
        height: 200,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/images/placeholder.jpeg', fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: palette.colors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
          child: Center(
            child: Icon(
              Icons.palette_outlined,
              size: 40,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  // Método para abrir la búsqueda en la biblioteca de pinturas
  void _openPaintLibrarySearch(String paletteName) {
    Navigator.pushNamed(
      context,
      '/library',
      arguments: {
        'paletteInfo': {'isCreatingPalette': true, 'paletteName': paletteName},
      },
    );
  }
}
