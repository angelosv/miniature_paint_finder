import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/models/paint.dart';

class CreatePaletteSheet extends StatefulWidget {
  final ScrollController scrollController;

  const CreatePaletteSheet({Key? key, required this.scrollController})
    : super(key: key);

  @override
  State<CreatePaletteSheet> createState() => _CreatePaletteSheetState();
}

class _CreatePaletteSheetState extends State<CreatePaletteSheet> {
  final TextEditingController _nameController = TextEditingController();
  final List<Paint> _selectedPaints = [];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addPaintFromLibrary() {
    // TODO: Implement paint selection from library
  }

  void _addPaintFromBarcode() {
    // TODO: Implement barcode scanner
  }

  void _addPaintFromWishlist() {
    // TODO: Implement wishlist selection
  }

  void _searchPaints() {
    // TODO: Implement paint search
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Handle bar and title
        Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF101823) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Create New Palette',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: ListView(
            controller: widget.scrollController,
            padding: const EdgeInsets.all(24),
            children: [
              // Palette name input
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Palette Name',
                  hintText: 'Enter a name for your palette',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Add paints section
              Text(
                'Add Paints',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              // Add paint options
              _buildAddPaintOption(
                icon: Icons.inventory_2_outlined,
                title: 'From My Library',
                subtitle: 'Add paints from your inventory',
                onTap: _addPaintFromLibrary,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 12),

              _buildAddPaintOption(
                icon: Icons.qr_code_scanner,
                title: 'Scan Barcode',
                subtitle: 'Add paint by scanning its barcode',
                onTap: _addPaintFromBarcode,
                color: Colors.blue,
              ),
              const SizedBox(height: 12),

              _buildAddPaintOption(
                icon: Icons.star_border,
                title: 'From Wishlist',
                subtitle: 'Add paints from your wishlist',
                onTap: _addPaintFromWishlist,
                color: Colors.amber,
              ),
              const SizedBox(height: 12),

              _buildAddPaintOption(
                icon: Icons.search,
                title: 'Search Paints',
                subtitle: 'Search from all available paints',
                onTap: _searchPaints,
                color: Colors.purple,
              ),
              const SizedBox(height: 24),

              // Selected paints
              if (_selectedPaints.isNotEmpty) ...[
                Text(
                  'Selected Paints',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                ..._selectedPaints.map((paint) => _buildPaintCard(paint)),
              ],

              const SizedBox(height: 32),

              // Create button
              ElevatedButton(
                onPressed:
                    _selectedPaints.isEmpty
                        ? null
                        : () {
                          // TODO: Implement palette creation
                        },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Create Palette',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddPaintOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 0,
      color: isDarkMode ? const Color(0xFF1A2632) : Colors.grey[100],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.2), width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isDarkMode ? Colors.white54 : Colors.black45,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaintCard(Paint paint) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Paint avatar/initial
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Color(
                  int.parse('FF${paint.hex.substring(1)}', radix: 16),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                paint.name[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Paint info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    paint.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    paint.set,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            // Color code
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.black12 : Colors.grey[100],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                paint.code,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
