import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:miniature_paint_finder/models/paint.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';

class AddToWishlistModal extends StatefulWidget {
  final Paint paint;
  final Function(Paint paint, int priority) onAddToWishlist;

  const AddToWishlistModal({
    super.key,
    required this.paint,
    required this.onAddToWishlist,
  });

  // Método estático para mostrar el modal
  static Future<void> show({
    required BuildContext context,
    required Paint paint,
    required Function(Paint paint, int priority) onAddToWishlist,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => AddToWishlistModal(
            paint: paint,
            onAddToWishlist: onAddToWishlist,
          ),
    );
  }

  @override
  State<AddToWishlistModal> createState() => _AddToWishlistModalState();
}

class _AddToWishlistModalState extends State<AddToWishlistModal> {
  int _priority = 0; // 0 = no priority, 1-5 = priority level

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final paintColor = Color(
      int.parse(widget.paint.hex.substring(1), radix: 16) + 0xFF000000,
    );

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Row(
                children: [
                  // Miniatura del color de la pintura
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: paintColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Información de la pintura
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.paint.name,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          widget.paint.brand,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color:
                                isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(),

            // Contenido
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add to Wishlist',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Selector de prioridad con estrellas
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Priority:',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Select priority level (5 stars = highest priority)',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          final starValue = index + 1;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (_priority == starValue) {
                                  // Deseleccionar si ya está seleccionada esta estrella
                                  _priority = 0;
                                } else {
                                  _priority = starValue;
                                }
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                              ),
                              child: Icon(
                                _priority >= starValue
                                    ? Icons.star_rounded
                                    : Icons.star_border_rounded,
                                color:
                                    _priority >= starValue
                                        ? AppTheme.marineOrange
                                        : isDarkMode
                                        ? Colors.grey[700]
                                        : Colors.grey[400],
                                size: 40,
                              ),
                            ),
                          );
                        }),
                      ),

                      // Texto de descripción de prioridad
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          _getPriorityDescription(),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color:
                                isDarkMode
                                    ? Colors.grey[300]
                                    : Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Botones de acción
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            widget.onAddToWishlist(widget.paint, _priority);
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isDarkMode
                                    ? AppTheme.marineOrange
                                    : AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            'Add to Wishlist',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
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
      ),
    );
  }

  String _getPriorityDescription() {
    switch (_priority) {
      case 0:
        return 'No priority set';
      case 1:
        return 'Low priority';
      case 2:
        return 'Somewhat important';
      case 3:
        return 'Important';
      case 4:
        return 'Very important';
      case 5:
        return 'Highest priority';
      default:
        return 'No priority set';
    }
  }
}
