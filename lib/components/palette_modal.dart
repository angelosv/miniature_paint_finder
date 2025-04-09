import 'package:flutter/material.dart';
import '../models/palette.dart';
import 'package:miniature_paint_finder/screens/inventory_screen.dart';
import 'package:miniature_paint_finder/screens/wishlist_screen.dart';
import 'package:miniature_paint_finder/models/paint.dart';
import 'package:miniature_paint_finder/components/add_to_wishlist_modal.dart';
import 'package:miniature_paint_finder/controllers/wishlist_controller.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:miniature_paint_finder/services/paint_service.dart';

class PaletteModal extends StatelessWidget {
  final String paletteName;
  final List<PaintSelection> paints;
  final String? imagePath;

  const PaletteModal({
    Key? key,
    required this.paletteName,
    required this.paints,
    this.imagePath,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF101823) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header image with overlays
          Stack(
            children: [
              // Image from API or placeholder
              if (imagePath != null && imagePath!.startsWith('http'))
                Image.network(
                  imagePath!,
                  width: double.infinity,
                  height: 150,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: double.infinity,
                      height: 150,
                      color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                      child: Center(
                        child: CircularProgressIndicator(
                          value:
                              loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                          color: isDarkMode ? Colors.orange : Colors.blue,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    print('❌ Error loading network image: $error');
                    return Image.asset(
                      'assets/images/placeholder.jpeg',
                      width: double.infinity,
                      height: 150,
                      fit: BoxFit.cover,
                    );
                  },
                )
              else
                Image.asset(
                  imagePath ?? 'assets/images/placeholder.jpeg',
                  width: double.infinity,
                  height: 150,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: double.infinity,
                      height: 150,
                      color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                      child: Center(
                        child: Icon(
                          Icons.image_not_supported,
                          size: 50,
                          color:
                              isDarkMode ? Colors.grey[600] : Colors.grey[400],
                        ),
                      ),
                    );
                  },
                ),

              // Gradient overlay
              Container(
                width: double.infinity,
                height: 150,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.4),
                      Colors.black.withOpacity(0.6),
                    ],
                  ),
                ),
              ),

              // Handle bar overlay at top
              Positioned(
                top: 12,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),

              // Title at bottom
              Positioned(
                bottom: 16,
                left: 24,
                right: 24,
                child: Text(
                  paletteName,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [],
                  ),
                ),
              ),
            ],
          ),

          // Paint list
          Expanded(
            child:
                paints.isEmpty
                    ? Center(
                      child: Text(
                        'No paints in this palette',
                        style: TextStyle(
                          color: isDarkMode ? Colors.grey : Colors.grey[600],
                        ),
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      itemCount: paints.length,
                      itemBuilder: (context, index) {
                        final paint = paints[index];

                        // Simulate random inventory/wishlist status for demo purposes
                        // In a real app, this would come from your data model
                        final bool isInInventory = index % 3 == 0;
                        final bool isInWishlist = index % 3 == 1;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color:
                                isDarkMode
                                    ? const Color(0xFF1a2530)
                                    : Colors.grey[100],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Main paint info row
                              InkWell(
                                onTap:
                                    () => _showPaintOptionsModal(
                                      context,
                                      paint,
                                      isInInventory,
                                      isInWishlist,
                                    ),
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8.0,
                                  ),
                                  child: Row(
                                    children: [
                                      // Brand avatar
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFEDEDED),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            paint.brandAvatar,
                                            style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      // Paint info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              paint.paintName,
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    isDarkMode
                                                        ? Colors.white
                                                        : Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              paint.paintBrand,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color:
                                                    isDarkMode
                                                        ? Colors.grey
                                                        : Colors.grey[700],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Color preview
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: _getColorFromHex(
                                            paint.paintColorHex,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color:
                                                isDarkMode
                                                    ? Colors.grey.withOpacity(
                                                      0.2,
                                                    )
                                                    : Colors.grey.withOpacity(
                                                      0.3,
                                                    ),
                                            width: 1,
                                          ),
                                        ),
                                      ),

                                      // Chevron icon to indicate tap options
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.chevron_right,
                                        color:
                                            isDarkMode
                                                ? Colors.grey[400]
                                                : Colors.grey[600],
                                        size: 24,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),
                              Divider(
                                color:
                                    isDarkMode
                                        ? const Color(0xFF2a3540)
                                        : Colors.grey[300],
                                height: 1,
                              ),
                              const SizedBox(height: 12),

                              // Additional info row
                              Row(
                                children: [
                                  // Color code
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Color code:",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color:
                                              isDarkMode
                                                  ? Colors.grey
                                                  : Colors.grey[700],
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              isDarkMode
                                                  ? const Color(0xFF0d151e)
                                                  : Colors.grey[200],
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          _generateColorCode(paint.paintName),
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color:
                                                isDarkMode
                                                    ? Colors.white
                                                    : Colors.black87,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const Spacer(),

                                  // Barcode
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        "Barcode:",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color:
                                              isDarkMode
                                                  ? Colors.grey
                                                  : Colors.grey[700],
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.qr_code,
                                            size: 16,
                                            color:
                                                isDarkMode
                                                    ? Colors.white70
                                                    : Colors.black54,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _generateBarcode(paint.paintId),
                                            style: TextStyle(
                                              fontSize: 14,
                                              color:
                                                  isDarkMode
                                                      ? Colors.white70
                                                      : Colors.black54,
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // Status indicators
                              Row(
                                children: [
                                  // Inventory status
                                  if (isInInventory)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(
                                          isDarkMode ? 0.2 : 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: Colors.green.withOpacity(
                                            isDarkMode ? 0.3 : 0.2,
                                          ),
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
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.green,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                  // Wishlist status
                                  if (isInWishlist)
                                    Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withOpacity(
                                          isDarkMode ? 0.2 : 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: Colors.amber.withOpacity(
                                            isDarkMode ? 0.3 : 0.2,
                                          ),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(
                                            Icons.star_outline,
                                            size: 14,
                                            color: Colors.amber,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            "In Wishlist",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.amber,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                  // Not in collection
                                  if (!isInInventory && !isInWishlist)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.withOpacity(
                                          isDarkMode ? 0.2 : 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: Colors.grey.withOpacity(
                                            isDarkMode ? 0.3 : 0.2,
                                          ),
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
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  // Mostrar modal de opciones para la pintura
  void _showPaintOptionsModal(
    BuildContext context,
    PaintSelection paint,
    bool isInInventory,
    bool isInWishlist,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF101823) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Paint info header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Color preview
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: _getColorFromHex(paint.paintColorHex),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            isDarkMode
                                ? Colors.grey.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Paint details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          paint.paintName,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          paint.paintBrand,
                          style: TextStyle(
                            fontSize: 16,
                            color: isDarkMode ? Colors.grey : Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(
                                  isDarkMode ? 0.2 : 0.1,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                "${paint.matchPercentage}% Match",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
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

              const SizedBox(height: 24),

              // Divider
              Divider(color: isDarkMode ? Colors.grey[800] : Colors.grey[300]),

              const SizedBox(height: 16),

              // Opciones rápidas
              Text(
                "Quick Actions",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),

              const SizedBox(height: 16),

              // Botones de acción
              Row(
                children: [
                  // Actualizar inventario
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showInventoryUpdateDialog(context, paint);
                      },
                      icon: const Icon(Icons.inventory_2_outlined),
                      label: Text(
                        isInInventory ? "Update Inventory" : "Add to Inventory",
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            isDarkMode ? Colors.orange : Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Añadir a wishlist
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showWishlistDialog(context, paint);
                      },
                      icon: const Icon(Icons.favorite_border),
                      label: Text(
                        isInWishlist ? "Update Wishlist" : "Add to Wishlist",
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.pink,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Ver en inventario
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const InventoryScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.inventory_2),
                  label: const Text("View in Inventory"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkMode ? Colors.orange : Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Mostrar diálogo para actualizar inventario
  void _showInventoryUpdateDialog(BuildContext context, PaintSelection paint) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    int quantity = 1;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Update Inventory'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${paint.paintName} will be added to your inventory.'),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Quantity: '),
                      SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.remove_circle_outline),
                        onPressed: () {
                          if (quantity > 1) {
                            setState(() {
                              quantity--;
                            });
                          }
                        },
                      ),
                      Text(
                        '$quantity',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: Icon(Icons.add_circle_outline),
                        onPressed: () {
                          setState(() {
                            quantity++;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);

                    // Mostrar confirmación con SnackBar
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Added $quantity ${paint.paintName} to inventory',
                        ),
                        backgroundColor:
                            isDarkMode ? Colors.orange : Colors.blue,
                        action: SnackBarAction(
                          label: 'VIEW',
                          textColor: Colors.white,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const InventoryScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                  child: Text('Confirm'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Mostrar diálogo para añadir a wishlist
  void _showWishlistDialog(BuildContext context, PaintSelection paint) {
    // Store references outside the callback to prevent deactivated widget errors
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Get a global reference to PaintService - don't depend on Provider after widget disposal
    final paintService = PaintService();

    // Convert PaintSelection to Paint for use with AddToWishlistModal with all necessary fields
    // Parse color components to ensure RGB values are provided
    final String hexColor =
        paint.paintColorHex.startsWith('#')
            ? paint.paintColorHex.substring(1)
            : paint.paintColorHex;

    // Parse RGB components
    final r = int.parse(hexColor.substring(0, 2), radix: 16);
    final g = int.parse(hexColor.substring(2, 4), radix: 16);
    final b = int.parse(hexColor.substring(4, 6), radix: 16);

    // Create a more complete Paint object
    final Paint paintObj = Paint(
      id: paint.paintId,
      name: paint.paintName,
      brand: paint.paintBrand,
      hex: paint.paintColorHex,
      // Include these fields with default values to ensure API compatibility
      set: "Palette Paint", // Using a meaningful value instead of empty string
      code: paint.paintId, // Using paintId as code
      r: r,
      g: g,
      b: b,
      category: "Palette", // Using a meaningful category
      isMetallic: false,
      isTransparent: false,
    );

    // Debug print the paint object for debugging
    print('🔍 Adding paint to wishlist: ${paintObj.toJson()}');

    AddToWishlistModal.show(
      context: context,
      paint: paintObj,
      onAddToWishlist: (paint, priority) async {
        // Show loading indicator
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
                SizedBox(width: 16),
                Text('Adding to wishlist...'),
              ],
            ),
            duration: Duration(seconds: 10),
            behavior: SnackBarBehavior.floating,
          ),
        );

        try {
          // Get current Firebase user
          final firebaseUser = FirebaseAuth.instance.currentUser;
          if (firebaseUser == null) {
            // Show error if not logged in
            scaffoldMessenger.hideCurrentSnackBar();
            scaffoldMessenger.showSnackBar(
              const SnackBar(
                content: Text('You need to be logged in to add to wishlist'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }

          final userId = firebaseUser.uid;
          print('🔑 User ID detected: $userId');

          // Call API directly
          print(
            '📤 Sending paint ${paint.id} with priority $priority and userId $userId',
          );
          print('📤 Paint details: ${paint.toJson()}');

          // Include all required data in the API call
          final result = await paintService.addToWishlistDirect(
            paint,
            priority,
            userId,
          );

          scaffoldMessenger.hideCurrentSnackBar();

          // Print complete result
          print('✅ Complete API Wishlist result: $result');

          if (result['success'] == true) {
            // Don't try to update the wishlist directly here
            // Instead, use a notification or refresh when navigating to the WishlistScreen

            // Show success message
            final priorityText = _getPriorityText(priority);
            final String message =
                result['alreadyExists'] == true
                    ? '${paint.name} is already in your wishlist'
                    : 'Added ${paint.name} to wishlist${priority > 0 ? " with $priorityText priority" : ""}';

            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text(message),
                duration: const Duration(seconds: 3),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                action: SnackBarAction(
                  label: 'VIEW',
                  textColor: Colors.white,
                  onPressed: () {
                    // When navigating to WishlistScreen, it will load the data in its initState
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WishlistScreen(),
                      ),
                    );
                  },
                ),
              ),
            );
          } else {
            // Show error with details
            print(
              '❌ Error details: ${result['raw_response'] ?? result['message']}',
            );

            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text('Error: ${result['message']}'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'Details',
                  textColor: Colors.white,
                  onPressed: () {
                    // Show dialog with complete error details
                    showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: const Text('Error Details'),
                            content: SingleChildScrollView(
                              child: Text(result.toString()),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Close'),
                              ),
                            ],
                          ),
                    );
                  },
                ),
              ),
            );
          }
        } catch (e, stackTrace) {
          print('❌ Exception adding to wishlist: $e');
          print('❌ Stack trace: $stackTrace');

          scaffoldMessenger.hideCurrentSnackBar();
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      },
    );
  }

  String _getPriorityText(int priority) {
    switch (priority) {
      case 1:
        return 'low';
      case 2:
        return 'somewhat important';
      case 3:
        return 'important';
      case 4:
        return 'very important';
      case 5:
        return 'highest';
      default:
        return '';
    }
  }

  Color _getColorFromHex(String hexColor) {
    try {
      hexColor = hexColor.replaceAll('#', '');
      if (hexColor.length == 6) {
        return Color(int.parse('FF$hexColor', radix: 16));
      }
      return Colors.red;
    } catch (e) {
      return Colors.red;
    }
  }

  String _generateColorCode(String paintName) {
    final nameBytes = paintName.codeUnits;
    if (nameBytes.isEmpty) return '00-00';

    final firstCode = (nameBytes[0] % 99).toString().padLeft(2, '0');
    final secondCode =
        (nameBytes.length > 1
            ? (nameBytes[1] % 99).toString().padLeft(2, '0')
            : '00');

    return '$firstCode-$secondCode';
  }

  String _generateBarcode(String paintId) {
    final numericPart = paintId.codeUnits
        .map((unit) => unit % 10)
        .join('')
        .padRight(12, '0')
        .substring(0, 12);

    return '5${numericPart}2';
  }
}

// Helper function to show the modal
void showPaletteModal(
  BuildContext context,
  String paletteName,
  List<PaintSelection> paints, {
  String? imagePath,
}) {
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
                paletteName: paletteName,
                paints: paints,
                imagePath: imagePath,
              ),
        ),
  );
}
