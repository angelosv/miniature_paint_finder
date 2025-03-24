import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/models/palette.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';
import 'package:miniature_paint_finder/components/app_header.dart';
import 'package:miniature_paint_finder/components/palette_paint_card.dart';
import 'package:miniature_paint_finder/components/palette_action_sheet.dart';

/// Pantalla de detalles de una paleta específica
class PaletteDetailScreen extends StatefulWidget {
  /// La paleta que se va a mostrar
  final Palette palette;

  /// Constructor de la pantalla de detalles de paleta
  const PaletteDetailScreen({super.key, required this.palette});

  @override
  State<PaletteDetailScreen> createState() => _PaletteDetailScreenState();
}

class _PaletteDetailScreenState extends State<PaletteDetailScreen> {
  late Palette _palette;

  // Variables de estado para la UI
  bool _isEditMode = false;
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _palette = widget.palette;
    _nameController.text = _palette.name;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // Formatea la fecha para mostrar
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

  // Calcula cuántos colores de la paleta están en el inventario
  int _getColorsInInventory() {
    // Simulando la lógica (esto se conectaría a tu servicio real)
    return _palette.paintSelections?.length ?? 0;
  }

  // Muestra el modal para agregar un nuevo color a la paleta
  void _showAddColorModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Add Color',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildOptionTile(
                  icon: Icons.camera_alt,
                  title: 'Find from Image',
                  subtitle: 'Extract colors from a photo',
                  onTap: () {
                    Navigator.pop(context);
                    // Implementar extracción de color de imagen
                    _showDemoSnackbar('Finding colors from image...');
                  },
                ),
                const SizedBox(height: 10),
                _buildOptionTile(
                  icon: Icons.search,
                  title: 'Search Library',
                  subtitle: 'Find existing paints in the library',
                  onTap: () {
                    Navigator.pop(context);
                    // Implementar búsqueda en librería
                    _showDemoSnackbar('Searching library...');
                  },
                ),
                const SizedBox(height: 10),
                _buildOptionTile(
                  icon: Icons.qr_code_scanner,
                  title: 'Scan Barcode',
                  subtitle: 'Add paint by scanning its barcode',
                  onTap: () {
                    Navigator.pop(context);
                    // Implementar escaneo de código de barras
                    _showDemoSnackbar('Opening barcode scanner...');
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  // Construye un item de opción para el modal
  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.marineBlue.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppTheme.marineBlue),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey[600],
        ),
        onTap: onTap,
      ),
    );
  }

  // Muestra un snackbar para la demostración
  void _showDemoSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Muestra el menú de opciones para un color
  void _showColorOptionsMenu(BuildContext context, PaintSelection paint) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.inventory_2, color: Colors.green),
                  title: const Text('Add to Inventory'),
                  onTap: () {
                    Navigator.pop(context);
                    _showDemoSnackbar('Added to Inventory');
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.favorite,
                    color: AppTheme.marineOrange,
                  ),
                  title: const Text('Add to Wishlist'),
                  onTap: () {
                    Navigator.pop(context);
                    _showDemoSnackbar('Added to Wishlist');
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.compare_arrows,
                    color: AppTheme.marineBlue,
                  ),
                  title: const Text('Find Equivalents'),
                  onTap: () {
                    Navigator.pop(context);
                    _showDemoSnackbar('Finding equivalent paints...');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.swap_horiz, color: Colors.purple),
                  title: const Text('Replace Color'),
                  onTap: () {
                    Navigator.pop(context);
                    _showDemoSnackbar('Replace color...');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('Remove from Palette'),
                  onTap: () {
                    Navigator.pop(context);
                    _showDemoSnackbar('Color removed from palette');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Muestra el menú de opciones globales de la paleta
  void _showPaletteOptionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.edit, color: AppTheme.marineBlue),
                  title: const Text('Edit Palette Name'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _isEditMode = true;
                    });
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                  title: const Text('Export as PDF'),
                  onTap: () {
                    Navigator.pop(context);
                    _showDemoSnackbar('Exporting as PDF...');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.share, color: AppTheme.marineBlue),
                  title: const Text('Share Palette'),
                  onTap: () {
                    Navigator.pop(context);
                    _showDemoSnackbar('Sharing palette...');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.content_copy, color: Colors.green),
                  title: const Text('Duplicate Palette'),
                  onTap: () {
                    Navigator.pop(context);
                    _showDemoSnackbar('Palette duplicated');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Delete Palette'),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteConfirmationDialog();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Muestra un diálogo de confirmación para eliminar la paleta
  Future<void> _showDeleteConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Palette?'),
          content: const Text(
            'This action cannot be undone. Are you sure you want to delete this palette?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _showDemoSnackbar('Palette deleted');
                // Añadir lógica para volver atrás después de eliminar
                Future.delayed(const Duration(milliseconds: 500), () {
                  Navigator.of(context).pop(); // Volver a la pantalla anterior
                });
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorsInInventory = _getColorsInInventory();
    final totalColors = _palette.paintSelections?.length ?? 0;

    return Scaffold(
      appBar: AppHeader(
        title: _isEditMode ? 'Edit Palette' : _palette.name,
        showBackButton: true,
        actions: [
          if (_isEditMode)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () {
                setState(() {
                  // En una implementación real, aquí guardarías los cambios
                  _isEditMode = false;
                });
                _showDemoSnackbar('Changes saved');
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: _showPaletteOptionsMenu,
            ),
        ],
      ),
      body: Column(
        children: [
          // Sección de información de la paleta
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isEditMode)
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Palette Name',
                      border: OutlineInputBorder(),
                    ),
                    autofocus: true,
                  )
                else ...[
                  // Fecha de creación
                  Text(
                    'Created ${_formatDate(_palette.createdAt)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Estado del inventario
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color:
                          totalColors == 0
                              ? Colors.grey[200]
                              : colorsInInventory == totalColors
                              ? Colors.green.withOpacity(0.1)
                              : AppTheme.marineOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          totalColors == 0
                              ? Icons.info_outline
                              : colorsInInventory == totalColors
                              ? Icons.check_circle
                              : Icons.notification_important,
                          size: 18,
                          color:
                              totalColors == 0
                                  ? Colors.grey[600]
                                  : colorsInInventory == totalColors
                                  ? Colors.green
                                  : AppTheme.marineOrange,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          totalColors == 0
                              ? 'No paints selected'
                              : colorsInInventory == totalColors
                              ? 'All paints in inventory!'
                              : 'Missing ${totalColors - colorsInInventory} paints',
                          style: TextStyle(
                            color:
                                totalColors == 0
                                    ? Colors.grey[600]
                                    : colorsInInventory == totalColors
                                    ? Colors.green
                                    : AppTheme.marineOrange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Colores de la paleta
                const Text(
                  'Colors',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 8),

                // Grid de colores
                Container(
                  height: 70,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      ..._palette.colors.map(
                        (color) => Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),

                      // Botón para añadir más colores
                      if (_isEditMode)
                        InkWell(
                          onTap: _showAddColorModal,
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color:
                                  isDarkMode ? Colors.grey[700] : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color:
                                    isDarkMode
                                        ? Colors.grey[600]!
                                        : Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              Icons.add,
                              size: 24,
                              color:
                                  isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Título de la sección de pinturas
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Paint Selection',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (!_isEditMode)
                  TextButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Paint'),
                    onPressed: _showAddColorModal,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Lista de pinturas seleccionadas
          Expanded(
            child:
                _palette.paintSelections == null ||
                        _palette.paintSelections!.isEmpty
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
                            'No paints selected yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color:
                                  isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap on a color to find matching paints',
                            style: TextStyle(
                              fontSize: 14,
                              color:
                                  isDarkMode
                                      ? Colors.grey[600]
                                      : Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Add First Paint'),
                            onPressed: _showAddColorModal,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _palette.paintSelections!.length,
                      itemBuilder: (context, index) {
                        final paint = _palette.paintSelections![index];
                        // Simular estado de inventario/wishlist para demostración
                        final bool isInInventory = index % 3 == 0;
                        final bool isInWishlist = index % 3 == 1;

                        return Dismissible(
                          key: Key(paint.paintId),
                          direction:
                              _isEditMode
                                  ? DismissDirection.endToStart
                                  : DismissDirection.none,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20.0),
                            color: Colors.red,
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          confirmDismiss: (direction) async {
                            if (_isEditMode) {
                              _showDemoSnackbar('Paint removed from palette');
                              return true;
                            }
                            return false;
                          },
                          child: PalettePaintCard(
                            paint: paint,
                            isInInventory: isInInventory,
                            isInWishlist: isInWishlist,
                            isEditMode: _isEditMode,
                            showMatchPercentage: false,
                            onTap:
                                _isEditMode
                                    ? null
                                    : () =>
                                        _showColorOptionsMenu(context, paint),
                            onRemove: () {
                              _showDemoSnackbar('Paint removed from palette');
                            },
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton:
          !_isEditMode &&
                  (_palette.paintSelections == null ||
                      _palette.paintSelections!.isEmpty)
              ? null
              : FloatingActionButton(
                onPressed: () {
                  if (_isEditMode) {
                    setState(() {
                      _isEditMode = false;
                    });
                    _showDemoSnackbar('Changes saved');
                  } else {
                    setState(() {
                      _isEditMode = true;
                    });
                  }
                },
                backgroundColor:
                    _isEditMode ? Colors.green : AppTheme.marineBlue,
                child: Icon(_isEditMode ? Icons.check : Icons.edit),
              ),
    );
  }
}
