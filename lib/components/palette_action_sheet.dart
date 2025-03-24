import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';

/// Un componente para mostrar acciones relacionadas con paletas
class PaletteActionSheet extends StatelessWidget {
  /// Título de la hoja de acciones
  final String title;

  /// Constructor del componente
  const PaletteActionSheet({super.key, required this.title});

  /// Muestra la hoja de acciones para añadir colores a una paleta
  static Future<void> showAddColorOptions(
    BuildContext context, {
    required VoidCallback onImageSelected,
    required VoidCallback onLibrarySelected,
    required VoidCallback onBarcodeSelected,
  }) {
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
                    onImageSelected();
                  },
                ),
                const SizedBox(height: 10),
                _buildOptionTile(
                  icon: Icons.search,
                  title: 'Search Library',
                  subtitle: 'Find existing paints in the library',
                  onTap: () {
                    Navigator.pop(context);
                    onLibrarySelected();
                  },
                ),
                const SizedBox(height: 10),
                _buildOptionTile(
                  icon: Icons.qr_code_scanner,
                  title: 'Scan Barcode',
                  subtitle: 'Add paint by scanning its barcode',
                  onTap: () {
                    Navigator.pop(context);
                    onBarcodeSelected();
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

  /// Muestra la hoja de acciones para las opciones de un color
  static Future<void> showColorOptions(
    BuildContext context, {
    required VoidCallback onAddToInventory,
    required VoidCallback onAddToWishlist,
    required VoidCallback onFindEquivalents,
    required VoidCallback onReplaceColor,
    required VoidCallback onRemoveColor,
  }) {
    return showModalBottomSheet(
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
                    onAddToInventory();
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
                    onAddToWishlist();
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
                    onFindEquivalents();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.swap_horiz, color: Colors.purple),
                  title: const Text('Replace Color'),
                  onTap: () {
                    Navigator.pop(context);
                    onReplaceColor();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('Remove from Palette'),
                  onTap: () {
                    Navigator.pop(context);
                    onRemoveColor();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Muestra la hoja de acciones para opciones globales de la paleta
  static Future<void> showPaletteOptions(
    BuildContext context, {
    required VoidCallback onEdit,
    required VoidCallback onExport,
    required VoidCallback onShare,
    required VoidCallback onDuplicate,
    required VoidCallback onDelete,
  }) {
    return showModalBottomSheet(
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
                    onEdit();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                  title: const Text('Export as PDF'),
                  onTap: () {
                    Navigator.pop(context);
                    onExport();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.share, color: AppTheme.marineBlue),
                  title: const Text('Share Palette'),
                  onTap: () {
                    Navigator.pop(context);
                    onShare();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.content_copy, color: Colors.green),
                  title: const Text('Duplicate Palette'),
                  onTap: () {
                    Navigator.pop(context);
                    onDuplicate();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Delete Palette'),
                  onTap: () {
                    Navigator.pop(context);
                    onDelete();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Construye un elemento de opción para los menús
  static Widget _buildOptionTile({
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

  @override
  Widget build(BuildContext context) {
    // Este componente no se renderiza directamente,
    // solo proporciona métodos estáticos
    return Container();
  }
}
