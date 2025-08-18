import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/models/paint.dart';
import 'package:miniature_paint_finder/models/palette.dart';
import 'package:miniature_paint_finder/services/paint_service.dart';
import 'package:miniature_paint_finder/controllers/palette_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:miniature_paint_finder/services/palette_service.dart';
import 'package:provider/provider.dart';

class PaletteSelectorModal extends StatefulWidget {
  final Paint paint;
  const PaletteSelectorModal({Key? key, required this.paint}) : super(key: key);

  @override
  _PaletteSelectorModalState createState() => _PaletteSelectorModalState();
}

class _PaletteSelectorModalState extends State<PaletteSelectorModal> {
  bool _isLoading = false;
  final TextEditingController _newPaletteNameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPalettes();
  }

  /// Load palettes using PaletteController cache service (cache-first pattern)
  Future<void> _loadPalettes() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final paletteController = Provider.of<PaletteController>(
        context,
        listen: false,
      );

      // Load palettes using cache-first approach (same as wishlist/inventory)
      await paletteController.loadPalettes();

      debugPrint(
        '🎨 Loaded ${paletteController.palettes.length} palettes via cache service',
      );
    } catch (e) {
      debugPrint('❌ Error loading palettes: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading palettes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Create a palette and immediately add the selected paint using cache service
  Future<void> _createPaletteAndAdd(String name) async {
    try {
      final paletteController = Provider.of<PaletteController>(
        context,
        listen: false,
      );

      // Create palette
      final createdPalette = await paletteController.createPalette(
        name: name,
        imagePath: 'assets/images/placeholder.jpeg',
        colors: [],
      );

      if (createdPalette != null) {
        // Add paint to the newly created palette
        final paintHex =
            widget.paint.hex.startsWith('#')
                ? widget.paint.hex
                : '#${widget.paint.hex}';

        final success = await paletteController.addPaintToPalette(
          createdPalette.id,
          widget.paint,
          paintHex,
        );

        if (success) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Created palette "$name" and added ${widget.paint.name}',
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );

          // Refresh palettes list
          await _loadPalettes();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Palette created but failed to add paint'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create palette'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating palette: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Add paint to existing palette using cache service
  Future<void> _addToPalette(String paletteId) async {
    try {
      final paletteController = Provider.of<PaletteController>(
        context,
        listen: false,
      );

      final paintHex =
          widget.paint.hex.startsWith('#')
              ? widget.paint.hex
              : '#${widget.paint.hex}';

      final success = await paletteController.addPaintToPalette(
        paletteId,
        widget.paint,
        paintHex,
      );

      if (success) {
        // Find palette name for success message
        final palette = paletteController.palettes.firstWhere(
          (p) => p.id == paletteId,
          orElse:
              () => Palette(
                id: paletteId,
                name: 'Selected Palette',
                imagePath: '',
                colors: [],
                createdAt: DateTime.now(),
                totalPaints: 0,
              ),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added ${widget.paint.name} to ${palette.name}'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to add paint to palette'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding paint to palette: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Text('Add to Palette', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Select a palette to add ${widget.paint.name}'),
          const SizedBox(height: 16),

          if (_isLoading) const Center(child: CircularProgressIndicator()),

          // Use Consumer to listen to palette controller changes
          Consumer<PaletteController>(
            builder: (context, paletteController, child) {
              if (!_isLoading && paletteController.palettes.isNotEmpty) {
                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
                  ),
                  child: ListView.builder(
                    itemCount: paletteController.palettes.length,
                    itemBuilder: (_, i) {
                      final palette = paletteController.palettes[i];
                      return ListTile(
                        title: Text(palette.name),
                        subtitle: Text('${palette.colors.length} colors'),
                        leading: Row(
                          mainAxisSize: MainAxisSize.min,
                          children:
                              palette.colors
                                  .take(3)
                                  .map(
                                    (c) => Container(
                                      width: 24,
                                      height: 24,
                                      margin: const EdgeInsets.only(right: 4),
                                      decoration: BoxDecoration(
                                        color: c,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _addToPalette(palette.id);
                        },
                      );
                    },
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () async {
              // open dialog to ask for palette name
              final name = await showDialog<String>(
                context: context,
                builder:
                    (ctx) => AlertDialog(
                      title: const Text('New Palette'),
                      content: TextField(
                        controller: _newPaletteNameCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Palette name',
                        ),
                        autofocus: true,
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            final value = _newPaletteNameCtrl.text.trim();
                            Navigator.of(
                              ctx,
                            ).pop(value.isNotEmpty ? value : null);
                          },
                          child: const Text('Create'),
                        ),
                      ],
                    ),
              );

              if (name != null) {
                Navigator.pop(context); // close the selector modal
                await _createPaletteAndAdd(name);
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Create New Palette'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _newPaletteNameCtrl.dispose();
    super.dispose();
  }
}
