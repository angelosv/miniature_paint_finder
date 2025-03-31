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
      drawer: _buildDrawer(isDarkMode),
    );
  }

  Widget _buildDrawer(bool isDarkMode) {
    // Create list of drawer items similar to HomeScreen
    final List<Map<String, dynamic>> _drawerItems = [
      {
        'icon': Icons.home_outlined,
        'text': 'Home',
        'index': -1,
        'screen': 'home',
      },
      {
        'icon': Icons.inventory_2_outlined,
        'text': 'My Inventory',
        'index': -1,
        'screen': 'inventory',
      },
      {
        'icon': Icons.favorite_border,
        'text': 'Wishlist',
        'index': -1,
        'screen': 'wishlist',
      },
      {
        'icon': Icons.auto_awesome_mosaic,
        'text': 'Library',
        'index': -1,
        'screen': 'library',
      },
      {
        'icon': Icons.palette_outlined,
        'text': 'My Palettes',
        'index': -1,
        'screen': 'palettes',
      },
    ];

    return Theme(
      data: Theme.of(context).copyWith(
        canvasColor: isDarkMode ? AppTheme.marineBlueDark : Colors.white,
        drawerTheme: DrawerThemeData(
          backgroundColor: isDarkMode ? AppTheme.marineBlueDark : Colors.white,
          scrimColor: Colors.black54,
        ),
      ),
      child: Drawer(
        elevation: 10,
        width: MediaQuery.of(context).size.width * 0.75,
        backgroundColor: isDarkMode ? AppTheme.marineBlueDark : Colors.white,
        child: Container(
          decoration: BoxDecoration(
            color: isDarkMode ? AppTheme.marineBlueDark : Colors.white,
            boxShadow:
                isDarkMode
                    ? [
                      BoxShadow(
                        color: Colors.black26,
                        offset: const Offset(1, 0),
                        blurRadius: 4,
                        spreadRadius: 0,
                      ),
                    ]
                    : [],
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Drawer header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 32,
                    horizontal: 24,
                  ),
                  decoration: BoxDecoration(
                    color: isDarkMode ? AppTheme.marineBlueDark : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color:
                            isDarkMode
                                ? Colors.black.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MiniPaint',
                        style: AppTheme.headingStyle.copyWith(
                          fontSize: 28,
                          color:
                              isDarkMode ? Colors.white : AppTheme.marineBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color:
                              isDarkMode
                                  ? Colors.white.withOpacity(0.1)
                                  : AppTheme.marineBlue.withOpacity(0.05),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.color_lens_outlined,
                              size: 18,
                              color:
                                  isDarkMode
                                      ? AppTheme.marineGold
                                      : AppTheme.marineBlue,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Find your perfect paint',
                              style: AppTheme.buttonStyle.copyWith(
                                fontSize: 14,
                                color:
                                    isDarkMode
                                        ? Colors.white.withOpacity(0.9)
                                        : AppTheme.marineBlue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Menu items
                Expanded(
                  child: ListView.builder(
                    itemCount: _drawerItems.length,
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    itemBuilder: (context, index) {
                      final item = _drawerItems[index];
                      final bool isActive = item['screen'] == 'palettes';

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _navigateToScreen(item['screen']),
                          splashColor: (isDarkMode
                                  ? AppTheme.marineGold
                                  : AppTheme.marineBlue)
                              .withOpacity(0.2),
                          highlightColor: (isDarkMode
                                  ? AppTheme.marineGold
                                  : AppTheme.marineBlue)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color:
                                  isActive
                                      ? isDarkMode
                                          ? AppTheme.marineGold.withOpacity(
                                            0.15,
                                          )
                                          : AppTheme.marineBlue.withOpacity(0.1)
                                      : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  item['icon'],
                                  size: 22,
                                  color:
                                      isActive
                                          ? isDarkMode
                                              ? AppTheme.marineGold
                                              : AppTheme.marineBlue
                                          : isDarkMode
                                          ? Colors.white.withOpacity(0.9)
                                          : Colors.black.withOpacity(0.75),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  item['text'],
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight:
                                        isActive
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                    color:
                                        isActive
                                            ? isDarkMode
                                                ? AppTheme.marineGold
                                                : AppTheme.marineBlue
                                            : isDarkMode
                                            ? Colors.white
                                            : Colors.black.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToScreen(String? screen) {
    Navigator.pop(context); // Close drawer

    if (screen == null) return;

    switch (screen) {
      case 'home':
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 'inventory':
        Navigator.pushNamed(context, '/inventory');
        break;
      case 'wishlist':
        Navigator.pushNamed(context, '/wishlist');
        break;
      case 'library':
        Navigator.pushNamed(context, '/library');
        break;
      case 'palettes':
        // Already on palettes screen
        break;
    }
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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showPaletteDetails(palette),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: Image.network(
                palette.imageUrl,
                fit: BoxFit.cover,
                height: 120,
                width: double.infinity,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    palette.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${palette.colors.length} colors',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPaletteDetails(Palette palette) {
    // Implement the logic to show palette details
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
