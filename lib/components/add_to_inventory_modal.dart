import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/models/paint.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';

class AddToInventoryModal extends StatefulWidget {
  final Paint paint;
  final Function(Paint paint, int quantity, String? notes, String? inventoryId)
  onAddToInventory;
  final String? inventoryId;
  final int? initialQuantity;
  final String? initialNotes;

  const AddToInventoryModal({
    super.key,
    required this.paint,
    required this.onAddToInventory,
    this.inventoryId,
    this.initialQuantity = 1,
    this.initialNotes,
  });

  static Future<void> show({
    required BuildContext context,
    required Paint paint,
    String? inventoryId,
    int initialQuantity = 1,
    String? initialNotes,
    required Function(
      Paint paint,
      int quantity,
      String? notes,
      String? inventoryId,
    )
    onAddToInventory,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => AddToInventoryModal(
            paint: paint,
            inventoryId: inventoryId,
            initialQuantity: initialQuantity,
            initialNotes: initialNotes,
            onAddToInventory: onAddToInventory,
          ),
    );
  }

  @override
  State<AddToInventoryModal> createState() => _AddToInventoryModalState();
}

class _AddToInventoryModalState extends State<AddToInventoryModal> {
  late int _quantity;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _quantity = widget.initialQuantity as int;
    _notesController = TextEditingController(text: widget.initialNotes ?? '');
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final paint = widget.paint;
    final paintColor = Color(
      int.parse(paint.hex.substring(1), radix: 16) | 0xFF000000,
    );
    final isUpdate = widget.inventoryId != null;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E2229) : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        16 + MediaQuery.of(context).viewInsets.bottom,
        24,
        16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          Text(
            isUpdate ? 'Update Inventory' : 'Add to Inventory',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
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
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Quantity',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(
                  Icons.remove_circle,
                  color:
                      _quantity > 1
                          ? (isDarkMode
                              ? AppTheme.drawerOrange
                              : AppTheme.primaryBlue)
                          : Colors.grey,
                  size: 36,
                ),
                onPressed:
                    _quantity > 1 ? () => setState(() => _quantity--) : null,
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_quantity',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.add_circle,
                  color:
                      isDarkMode ? AppTheme.drawerOrange : AppTheme.primaryBlue,
                  size: 36,
                ),
                onPressed: () => setState(() => _quantity++),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _notesController,
            decoration: InputDecoration(
              labelText: 'Notes (optional)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              hintText: 'Any notes?',
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
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
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await widget.onAddToInventory(
                      widget.paint,
                      _quantity,
                      _notesController.text.isNotEmpty
                          ? _notesController.text
                          : null,
                      widget.inventoryId,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isUpdate ? AppTheme.drawerOrange : AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isUpdate ? 'Update' : 'Add',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
