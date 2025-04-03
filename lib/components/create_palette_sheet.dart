import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/models/paint.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';

class CreatePaletteSheet extends StatefulWidget {
  final ScrollController scrollController;

  const CreatePaletteSheet({Key? key, required this.scrollController})
    : super(key: key);

  @override
  State<CreatePaletteSheet> createState() => _CreatePaletteSheetState();
}

class _CreatePaletteSheetState extends State<CreatePaletteSheet> {
  final TextEditingController _nameController = TextEditingController();
  final ScrollController _paintsScrollController = ScrollController();
  final List<Paint> _selectedPaints = [
    Paint.fromHex(
      id: 'demo-001',
      name: 'Dirty Red',
      brand: 'Scale75',
      hex: '#822A2A',
      set: 'Standard',
      code: '68-06',
      category: '3rd Gen',
      isMetallic: false,
      isTransparent: false,
    ),
    Paint.fromHex(
      id: 'demo-002',
      name: 'Ultramarine Blue',
      brand: 'Citadel',
      hex: '#0D407F',
      set: 'Base',
      code: 'BLU-01',
      category: 'Base Colors',
      isMetallic: false,
      isTransparent: false,
    ),
    Paint.fromHex(
      id: 'demo-003',
      name: 'Shining Silver',
      brand: 'Army Painter',
      hex: '#C8C8CA',
      set: 'Metallics',
      code: 'AP-M01',
      category: 'Metallics',
      isMetallic: true,
      isTransparent: false,
    ),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _paintsScrollController.dispose();
    super.dispose();
  }

  void _showAddPaintOptionsModal() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor =
        isDarkMode ? AppTheme.marineBlueLight : AppTheme.primaryBlue;
    final secondaryColor =
        isDarkMode ? AppTheme.marineOrange : AppTheme.orangeColor;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                  'Add Paints',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                    shadows: [],
                  ),
                ),
                const SizedBox(height: 24),

                // Opciones para añadir pinturas
                _buildAddPaintOption(
                  icon: Icons.inventory_2_outlined,
                  title: 'From My Library',
                  subtitle: 'Add paints from your inventory',
                  onTap: () {
                    Navigator.pop(context);
                    // Lógica para añadir pinturas desde la biblioteca
                  },
                  color: primaryColor,
                ),
                const SizedBox(height: 12),

                _buildAddPaintOption(
                  icon: Icons.qr_code_scanner,
                  title: 'Scan Barcode',
                  subtitle: 'Add paint by scanning its barcode',
                  onTap: () {
                    Navigator.pop(context);
                    // Lógica para añadir pinturas mediante código de barras
                  },
                  color: primaryColor,
                ),
                const SizedBox(height: 12),

                _buildAddPaintOption(
                  icon: Icons.star_border,
                  title: 'From Wishlist',
                  subtitle: 'Add paints from your wishlist',
                  onTap: () {
                    Navigator.pop(context);
                    // Lógica para añadir pinturas desde la lista de deseos
                  },
                  color: secondaryColor,
                ),
                const SizedBox(height: 12),

                _buildAddPaintOption(
                  icon: Icons.search,
                  title: 'Search Paints',
                  subtitle: 'Search from all available paints',
                  onTap: () {
                    Navigator.pop(context);
                    // Lógica para buscar pinturas
                  },
                  color: primaryColor,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
    );
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
                  shadows: [],
                ),
              ),
            ],
          ),
        ),

        // Contenido principal con estructura fija
        Expanded(
          child: Column(
            children: [
              // Parte superior fija (no scrolleable)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
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

                    // Add paints section header with paint counter
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add Paints',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color:
                                    isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                            Text(
                              '${_selectedPaints.length} paints selected',
                              style: TextStyle(
                                fontSize: 14,
                                color:
                                    isDarkMode
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: _showAddPaintOptionsModal,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Paint'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Área scrolleable solo para las pinturas
              Expanded(
                child:
                    _selectedPaints.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.palette_outlined,
                                size: 48,
                                color: Colors.grey.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No paints added yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.withOpacity(0.8),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add paints to create your palette',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        )
                        : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: ListView.builder(
                            controller: _paintsScrollController,
                            itemCount: _selectedPaints.length,
                            itemBuilder: (context, index) {
                              return _buildSwipeablePaintCard(
                                _selectedPaints[index],
                              );
                            },
                          ),
                        ),
              ),
            ],
          ),
        ),

        // Botón fijo en la parte inferior sin sombra
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF101823) : Colors.white,
            // Sin sombra
          ),
          child: ElevatedButton(
            onPressed:
                _nameController.text.trim().isNotEmpty &&
                        _selectedPaints.isNotEmpty
                    ? () {
                      // TODO: Implementar la creación de paleta
                    }
                    : null,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isDarkMode ? AppTheme.marineOrange : AppTheme.primaryBlue,
              foregroundColor: isDarkMode ? AppTheme.primaryBlue : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Create Palette',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? AppTheme.primaryBlue : Colors.white,
              ),
            ),
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

  // Genera un valor aleatorio para simular si la pintura está en inventario o wishlist
  Map<String, bool> _getPaintStatus(Paint paint) {
    // Simular estados aleatorios para el demo
    // En un caso real, verificarías con tu base de datos/modelo
    final random = paint.id.hashCode % 3;
    return {
      'inInventory': random == 0,
      'inWishlist': random == 1,
      'notInCollection': random == 2,
    };
  }

  // Tarjeta de pintura con gesto de deslizar para eliminar
  Widget _buildSwipeablePaintCard(Paint paint) {
    return Dismissible(
      key: Key(paint.id),
      direction: DismissDirection.endToStart,
      dismissThresholds: const {DismissDirection.endToStart: 0.3},
      background: Card(
        elevation: 0,
        color: Colors.red[400],
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20.0),
          child: const Icon(
            Icons.delete_outline,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
      onDismissed: (direction) {
        setState(() {
          _selectedPaints.remove(paint);
        });
      },
      child: _buildSelectedPaintCard(paint),
    );
  }

  // Tarjeta de pintura sin botón de eliminar (ahora se usa el gesto de swipe)
  Widget _buildSelectedPaintCard(Paint paint) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDarkMode ? const Color(0xFF1A2632) : Colors.grey[100];

    // Convertir el hex a un Color
    final Color paintColor = Color(
      int.parse(paint.hex.substring(1), radix: 16) + 0xFF000000,
    );

    // Obtener el estado simulado de la pintura (inventario/wishlist)
    final paintStatus = _getPaintStatus(paint);
    final bool inInventory = paintStatus['inInventory']!;
    final bool inWishlist = paintStatus['inWishlist']!;
    final bool notInCollection = paintStatus['notInCollection']!;

    return Card(
      elevation: 0,
      color: backgroundColor,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Información principal de la pintura
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Letra inicial en círculo (como en la imagen)
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.grey[200],
                  child: Text(
                    paint.name.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
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
                        paint.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        '${paint.set} (${paint.code})',
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                // Muestra de color como en la imagen
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: paintColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Añadir etiquetas de estado (inventory, wishlist, not in collection)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                // Etiqueta de inventario
                if (inInventory)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(isDarkMode ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: Colors.green.withOpacity(isDarkMode ? 0.3 : 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 14,
                          color: Colors.green,
                        ),
                        SizedBox(width: 4),
                        Text(
                          "In Inventory",
                          style: TextStyle(fontSize: 12, color: Colors.green),
                        ),
                      ],
                    ),
                  ),

                // Etiqueta de wishlist
                if (inWishlist)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(isDarkMode ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: Colors.amber.withOpacity(isDarkMode ? 0.3 : 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.star_outline, size: 14, color: Colors.amber),
                        SizedBox(width: 4),
                        Text(
                          "In Wishlist",
                          style: TextStyle(fontSize: 12, color: Colors.amber),
                        ),
                      ],
                    ),
                  ),

                // Etiqueta de no en colección
                if (notInCollection)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(isDarkMode ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: Colors.grey.withOpacity(isDarkMode ? 0.3 : 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.remove_circle_outline,
                          size: 14,
                          color: Colors.grey,
                        ),
                        SizedBox(width: 4),
                        Text(
                          "Not in Collection",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
