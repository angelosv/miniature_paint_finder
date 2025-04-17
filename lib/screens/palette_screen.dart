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
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Get controller from provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _paletteController = context.read<PaletteController>();
      // Ensure we get a fresh load of palettes when screen initializes
      _paletteController.loadPalettes();

      // Precarga las imágenes para mejorar la experiencia
      _precacheImages();

      // Configurar el controlador de texto para reflejar el estado actual de búsqueda
      _searchController.text = _paletteController.searchQuery;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    return AppScaffold(
      scaffoldKey: _scaffoldKey,
      title: 'My Palettes',
      selectedIndex: 3,
      body: _buildBody(context),
      drawer: const SharedDrawer(currentScreen: 'palette'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreatePaletteOptions,
        backgroundColor:
            isDarkMode ? AppTheme.marineOrange : Theme.of(context).primaryColor,
        foregroundColor: isDarkMode ? AppTheme.marineBlue : Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Palette'),
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

  Widget _buildBody(BuildContext context) {
    return Consumer<PaletteController>(
      builder: (context, controller, child) {
        _paletteController = controller;

        if (controller.isLoading && controller.palettes.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.error != null && controller.palettes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 50, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error loading palettes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(controller.error ?? ''),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => controller.loadPalettes(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (controller.palettes.isEmpty) {
          return _buildEmptyState();
        }

        return Column(
          children: [
            // Barra de búsqueda
            _buildSearchBar(),

            // Barra de filtro y ordenamiento
            _buildFilterAndSortBar(),

            // Lista de paletas
            Expanded(child: _buildPaletteGrid(controller.palettes)),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.palette_outlined,
            size: 70,
            color: isDarkMode ? AppTheme.marineOrange : AppTheme.marineBlue,
          ),
          const SizedBox(height: 24),
          Text(
            'No Palettes Yet',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Create your first palette to organize your paints and match colors.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _showCreatePaletteOptions,
            icon: const Icon(Icons.add),
            label: const Text('Create Palette'),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isDarkMode ? AppTheme.marineOrange : AppTheme.marineBlue,
              foregroundColor: isDarkMode ? AppTheme.marineBlue : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search palettes...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon:
              _paletteController.searchQuery.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _paletteController.setSearchQuery('');
                    },
                  )
                  : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(
              color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(
              color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(
              color: isDarkMode ? AppTheme.marineOrange : AppTheme.marineBlue,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          filled: true,
          fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
        ),
        onChanged: (value) {
          _paletteController.setSearchQuery(value);
        },
      ),
    );
  }

  Widget _buildFilterAndSortBar() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Text(
            'Sort by: ',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
          InkWell(
            onTap: _showSortOptions,
            borderRadius: BorderRadius.circular(30),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getSortByText(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _paletteController.sortAscending
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                    size: 16,
                    color:
                        isDarkMode
                            ? AppTheme.marineOrange
                            : AppTheme.marineBlue,
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          if (_paletteController.searchQuery.isNotEmpty)
            TextButton.icon(
              onPressed: () {
                _searchController.clear();
                _paletteController.clearFilters();
              },
              icon: const Icon(Icons.filter_alt_off),
              label: const Text('Clear'),
              style: TextButton.styleFrom(
                foregroundColor:
                    isDarkMode ? AppTheme.marineOrange : AppTheme.marineBlue,
              ),
            ),
        ],
      ),
    );
  }

  String _getSortByText() {
    switch (_paletteController.sortBy) {
      case 'date':
        return _paletteController.sortAscending ? 'Oldest' : 'Newest';
      case 'name':
        return _paletteController.sortAscending ? 'Name (A-Z)' : 'Name (Z-A)';
      case 'paints':
        return _paletteController.sortAscending
            ? 'Fewest Paints'
            : 'Most Paints';
      default:
        return 'Custom';
    }
  }

  void _showSortOptions() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? const Color(0xFF101823) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Sort Palettes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ),
              const Divider(),
              _buildSortOption(
                title: 'Newest First',
                isSelected:
                    _paletteController.sortBy == 'date' &&
                    !_paletteController.sortAscending,
                onTap: () {
                  _paletteController.setSorting('date', false);
                  Navigator.pop(context);
                },
              ),
              _buildSortOption(
                title: 'Oldest First',
                isSelected:
                    _paletteController.sortBy == 'date' &&
                    _paletteController.sortAscending,
                onTap: () {
                  _paletteController.setSorting('date', true);
                  Navigator.pop(context);
                },
              ),
              _buildSortOption(
                title: 'Name (A-Z)',
                isSelected:
                    _paletteController.sortBy == 'name' &&
                    _paletteController.sortAscending,
                onTap: () {
                  _paletteController.setSorting('name', true);
                  Navigator.pop(context);
                },
              ),
              _buildSortOption(
                title: 'Name (Z-A)',
                isSelected:
                    _paletteController.sortBy == 'name' &&
                    !_paletteController.sortAscending,
                onTap: () {
                  _paletteController.setSorting('name', false);
                  Navigator.pop(context);
                },
              ),
              _buildSortOption(
                title: 'Most Paints',
                isSelected:
                    _paletteController.sortBy == 'paints' &&
                    !_paletteController.sortAscending,
                onTap: () {
                  _paletteController.setSorting('paints', false);
                  Navigator.pop(context);
                },
              ),
              _buildSortOption(
                title: 'Fewest Paints',
                isSelected:
                    _paletteController.sortBy == 'paints' &&
                    _paletteController.sortAscending,
                onTap: () {
                  _paletteController.setSorting('paints', true);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
    );
  }

  Widget _buildSortOption({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.white : Colors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(
                Icons.check,
                color: isDarkMode ? AppTheme.marineOrange : AppTheme.marineBlue,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaletteGrid(List<Palette> palettes) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: palettes.length,
      itemBuilder: (context, index) {
        final palette = palettes[index];
        return _buildPaletteCard(palette);
      },
    );
  }

  Widget _buildPaletteCard(Palette palette) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorIndicatorSize = MediaQuery.of(context).size.width * 0.08;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openPaletteModal(palette),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Imagen principal
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Imagen de paleta o placeholder
                  _buildPaletteImage(palette),

                  // Gradiente oscuro para mejorar legibilidad del texto
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Nombre de la paleta
                  Positioned(
                    bottom: 8,
                    left: 12,
                    right: 12,
                    child: Text(
                      palette.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            offset: Offset(1, 1),
                            blurRadius: 3,
                            color: Colors.black,
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Información y colores
            Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Información de pinturas
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.palette_outlined,
                            size: 16,
                            color:
                                isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${palette.totalPaints} paints',
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
                      Text(
                        palette.createdAtText,
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Muestra de colores
                  SizedBox(
                    height: colorIndicatorSize,
                    child: Row(
                      children: [
                        for (int i = 0; i < palette.colors.length && i < 5; i++)
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                color: palette.colors[i],
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color:
                                      isDarkMode
                                          ? Colors.white24
                                          : Colors.black12,
                                  width: 1,
                                ),
                              ),
                            ),
                          ),
                        if (palette.colors.length > 5)
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                color:
                                    isDarkMode
                                        ? Colors.grey[800]
                                        : Colors.grey[200],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Center(
                                child: Text(
                                  '+${palette.colors.length - 5}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isDarkMode
                                            ? Colors.white70
                                            : Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
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

  Widget _buildPaletteImage(Palette palette) {
    if (palette.imagePath.isEmpty) {
      return Container(
        color: Colors.grey[800],
        child: const Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            color: Colors.white54,
            size: 40,
          ),
        ),
      );
    }

    if (palette.imagePath.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: palette.imagePath,
        fit: BoxFit.cover,
        cacheKey: 'palette_${palette.id}_card',
        cacheManager: PaletteCacheManager(),
        placeholder:
            (context, url) => Container(
              color: Colors.grey[800],
              child: const Center(child: CircularProgressIndicator()),
            ),
        errorWidget:
            (context, url, error) => Container(
              color: Colors.grey[800],
              child: const Center(
                child: Icon(
                  Icons.error_outline,
                  color: Colors.white54,
                  size: 40,
                ),
              ),
            ),
      );
    } else {
      // Imagen local
      return Image.file(
        File(palette.imagePath),
        fit: BoxFit.cover,
        errorBuilder:
            (context, error, stackTrace) => Container(
              color: Colors.grey[800],
              child: const Center(
                child: Icon(
                  Icons.error_outline,
                  color: Colors.white54,
                  size: 40,
                ),
              ),
            ),
      );
    }
  }

  void _openPaletteModal(Palette palette) {
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
                  paletteName: palette.name,
                  paints: palette.paintSelections ?? [],
                  imagePath: palette.imagePath,
                ),
          ),
    );

    // Recargar las paletas cuando se cierre el modal
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _paletteController.loadPalettes();
    });
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
