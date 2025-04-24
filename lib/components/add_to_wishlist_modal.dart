import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:miniature_paint_finder/models/paint.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';
import 'package:miniature_paint_finder/screens/wishlist_screen.dart';

class AddToWishlistModal extends StatefulWidget {
  final Paint paint;
  final Function(Paint paint, int priority, String? wishlistId) onAddToWishlist;
  final bool isUpdate; // 👈 nuevo campo
  final String? wishlistId;

  const AddToWishlistModal({
    super.key,
    required this.paint,
    required this.onAddToWishlist,
    this.isUpdate = false, // default
    this.wishlistId,
  });

  // Método estático para mostrar el modal
  static Future<void> show({
    required BuildContext context,
    required Paint paint,
    String? wishlistId,
    required Function(Paint paint, int priority, String? wishlistId)
    onAddToWishlist,
    bool isUpdate = false, //
  }) {
    // Crear una nueva instancia del widget cada vez que se muestra el modal
    // para asegurar que tenga un estado fresco
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => AddToWishlistModal(
            key:
                UniqueKey(), // Añadir una key única para forzar la recreación del widget
            paint: paint,
            onAddToWishlist: onAddToWishlist,
            isUpdate: isUpdate, //
            wishlistId: wishlistId,
          ),
    );
  }

  @override
  State<AddToWishlistModal> createState() => _AddToWishlistModalState();
}

class _AddToWishlistModalState extends State<AddToWishlistModal> {
  int _selectedPriority = 3; // Prioridad media por defecto
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Paint paint = widget.paint;
    final bool isUpdate = widget.isUpdate;

    final Color paintColor = Color(
      int.parse(paint.hex.substring(1, 7), radix: 16) + 0xFF000000,
    );

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E2229) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Título del modal
            Text(
              isUpdate ? "Update Wishlist" : "Add to Wishlist",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // Detalles de la pintura
            Row(
              children: [
                // Swatch de color
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: paintColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  ),
                ),
                const SizedBox(width: 16),

                // Nombre y marca
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        paint.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        paint.brand,
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Selector de prioridad con estrellas
            Text(
              'Priority',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPriority = index + 1;
                    });
                  },
                  child: Icon(
                    index < _selectedPriority ? Icons.star : Icons.star_border,
                    color:
                        index < _selectedPriority
                            ? AppTheme.marineOrange
                            : isDarkMode
                            ? Colors.grey[400]
                            : Colors.grey[500],
                    size: 36,
                  ),
                );
              }),
            ),

            // Texto descriptivo de la prioridad
            Text(
              _getPriorityLabel(_selectedPriority),
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),

            const SizedBox(height: 24),

            // Campo de notas opcional
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: 'Add any notes about this paint...',
              ),
              maxLines: 2,
            ),

            const SizedBox(height: 24),

            // Botones de acción
            Row(
              children: [
                // Botón de cancelar
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),

                // Botón de confirmar
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Ahora el componente padre se encargará de hacer la llamada a la API
                      // y mostrar mensajes de éxito o error
                      widget.onAddToWishlist(
                        widget.paint,
                        _selectedPriority,
                        widget.wishlistId,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isDarkMode ? Colors.pinkAccent : Colors.pink,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isUpdate ? "Update Wishlist" : "Add to Wishlist",
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getPriorityLabel(int priority) {
    switch (priority) {
      case 1:
        return "Low priority";
      case 2:
        return "Somewhat important";
      case 3:
        return "Important";
      case 4:
        return "Very important";
      case 5:
        return "Highest priority";
      default:
        return "";
    }
  }
}
