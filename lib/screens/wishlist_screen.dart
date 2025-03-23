import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/models/paint.dart';
import 'package:miniature_paint_finder/services/paint_service.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';

/// Screen that displays all paints in the user's wishlist
class WishlistScreen extends StatefulWidget {
  /// Constructs the wishlist screen
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final PaintService _paintService = PaintService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _wishlistItems = [];

  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  Future<void> _loadWishlist() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final wishlistItems = await _paintService.getWishlistPaints();

      setState(() {
        _wishlistItems = wishlistItems;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading wishlist: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeFromWishlist(String paintId, String paintName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Removal'),
            content: Text('Remove $paintName from your wishlist?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('REMOVE'),
              ),
            ],
          ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      final result = await _paintService.removeFromWishlist(paintId);

      if (result && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$paintName removed from wishlist'),
            action: SnackBarAction(
              label: 'UNDO',
              onPressed: () async {
                // Find the paint in our list to get the priority status
                final item = _wishlistItems.firstWhere(
                  (item) => (item['paint'] as Paint).id == paintId,
                  orElse: () => {'paint': null, 'isPriority': false},
                );

                if (item['paint'] != null) {
                  await _paintService.addToWishlist(
                    item['paint'] as Paint,
                    item['isPriority'] as bool,
                  );
                  _loadWishlist();
                }
              },
            ),
          ),
        );

        _loadWishlist();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing from wishlist: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _togglePriority(String paintId, bool currentPriority) async {
    try {
      final newPriority = !currentPriority;
      await _paintService.updateWishlistPriority(paintId, newPriority);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newPriority ? 'Marked as priority' : 'Removed from priority',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      _loadWishlist();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating priority: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addToInventory(Paint paint) async {
    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) => _AddToInventoryDialog(paint: paint),
    );

    if (result != null) {
      try {
        await _paintService.addToInventory(
          paint,
          result['quantity'] as int,
          note: result['note'] as String?,
        );

        // Remove from wishlist
        await _paintService.removeFromWishlist(paint.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${paint.name} added to inventory'),
              backgroundColor: Colors.green,
            ),
          );
        }

        _loadWishlist();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error adding to inventory: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Wishlist'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWishlist,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _wishlistItems.isEmpty
              ? _buildEmptyWishlist()
              : _buildWishlistContent(),
    );
  }

  Widget _buildEmptyWishlist() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Your wishlist is empty',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Add paints you want to purchase later',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to Library or Paint Browser
              Navigator.pop(context);
            },
            icon: const Icon(Icons.search),
            label: const Text('Browse Paints'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWishlistContent() {
    return ListView.builder(
      itemCount: _wishlistItems.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final item = _wishlistItems[index];
        final paint = item['paint'] as Paint;
        final isPriority = item['isPriority'] as bool;
        final addedAt = item['addedAt'] as DateTime;

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side:
                isPriority
                    ? BorderSide(color: AppTheme.marineOrange, width: 2)
                    : BorderSide(color: Colors.grey.withOpacity(0.2)),
          ),
          child: InkWell(
            onTap: () {
              _showActionSheet(paint, isPriority);
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Paint color
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Color(
                            int.parse(paint.colorHex.substring(1), radix: 16) +
                                0xFF000000,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.3),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Paint details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Added priority indicator if needed
                            if (isPriority) ...[
                              Row(
                                children: [
                                  Icon(
                                    Icons.star,
                                    size: 16,
                                    color: AppTheme.marineOrange,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'PRIORITY',
                                    style: TextStyle(
                                      color: AppTheme.marineOrange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                            ],

                            Text(
                              paint.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              paint.brand,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryBlue.withOpacity(
                                      0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    paint.category,
                                    style: TextStyle(
                                      color: AppTheme.primaryBlue,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                if (paint.isMetallic ||
                                    paint.isTransparent) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      paint.isMetallic
                                          ? 'Metallic'
                                          : 'Transparent',
                                      style: TextStyle(
                                        color: Colors.amber[800],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Date added
                  Text(
                    'Added on ${_formatDate(addedAt)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Shows a bottom sheet with actions for a paint
  void _showActionSheet(Paint paint, bool isPriority) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Paint info header
                  Row(
                    children: [
                      // Paint color
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Color(
                            int.parse(paint.colorHex.substring(1), radix: 16) +
                                0xFF000000,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.3),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Paint name and brand
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              paint.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              paint.brand,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Action buttons
                  _buildActionButton(
                    icon: isPriority ? Icons.star : Icons.star_border,
                    text: isPriority ? 'Remove priority' : 'Mark as priority',
                    color:
                        isPriority
                            ? Colors.amber
                            : Theme.of(context).colorScheme.primary,
                    onTap: () {
                      Navigator.pop(context);
                      _togglePriority(paint.id, isPriority);
                    },
                  ),

                  _buildActionButton(
                    icon: Icons.add_shopping_cart,
                    text: 'Add to inventory',
                    color: AppTheme.primaryBlue,
                    onTap: () {
                      Navigator.pop(context);
                      _addToInventory(paint);
                    },
                  ),

                  _buildActionButton(
                    icon: Icons.delete_outline,
                    text: 'Remove from wishlist',
                    color: Colors.red,
                    onTap: () {
                      Navigator.pop(context);
                      _removeFromWishlist(paint.id, paint.name);
                    },
                  ),

                  const SizedBox(height: 16),

                  // Cancel button with lighter color and rounded style
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Helper to build action buttons for the bottom sheet
  Widget _buildActionButton({
    required IconData icon,
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 16),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
                const Spacer(),
                Icon(Icons.chevron_right, color: color.withOpacity(0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}

/// Dialog to add a paint to inventory
class _AddToInventoryDialog extends StatefulWidget {
  final Paint paint;

  const _AddToInventoryDialog({required this.paint});

  @override
  State<_AddToInventoryDialog> createState() => _AddToInventoryDialogState();
}

class _AddToInventoryDialogState extends State<_AddToInventoryDialog> {
  int _quantity = 1;
  String? _note;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add ${widget.paint.name} to Inventory'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('How many do you have?'),
          const SizedBox(height: 16),

          // Quantity selector
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed:
                    _quantity > 1
                        ? () {
                          setState(() {
                            _quantity--;
                          });
                        }
                        : null,
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.2),
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _quantity.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () {
                  setState(() {
                    _quantity++;
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Note field
          TextField(
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              hintText: 'E.g.: Almost empty, purchased at...',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
            onChanged: (value) {
              setState(() {
                _note = value.isEmpty ? null : value;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop({'quantity': _quantity, 'note': _note});
          },
          child: const Text('ADD'),
        ),
      ],
    );
  }
}
