import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/models/paint.dart';
import 'package:miniature_paint_finder/models/palette.dart';
import 'package:miniature_paint_finder/services/paint_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PaletteSelectorModal extends StatefulWidget {
  final Paint paint;
  const PaletteSelectorModal({Key? key, required this.paint}) : super(key: key);

  @override
  _PaletteSelectorModalState createState() => _PaletteSelectorModalState();
}

class _PaletteSelectorModalState extends State<PaletteSelectorModal> {
  final List<Palette> _palettes = [];
  final ScrollController _scrollCtrl = ScrollController();

  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoading = false;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _fetchPalettes();
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
            _scrollCtrl.position.maxScrollExtent - 100 &&
        !_isLoadingMore &&
        _currentPage <= _totalPages) {
      _fetchPalettes(loadMore: true);
    }
  }

  Future<void> _fetchPalettes({bool loadMore = false}) async {
    if (_isLoading) return;
    setState(() {
      loadMore ? _isLoadingMore = true : _isLoading = true;
    });

    try {
      final result = await PaintService().getPalettes(
        page: _currentPage,
        limit: 10,
      );

      setState(() {
        _totalPages = result['totalPages'] as int;
        _palettes.addAll(result['palettes'] as List<Palette>);
        _currentPage++;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading pallets: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _addToPalette(String paletteId) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            CircularProgressIndicator(strokeWidth: 2),
            SizedBox(width: 12),
            Text('Adding paint…'),
          ],
        ),
        duration: Duration(minutes: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final token = await user.getIdToken();
      final result = await PaintService().addPaintToPalette(
        widget.paint,
        paletteId,
        token as String,
      );

      messenger.hideCurrentSnackBar();
      if (result['success'] == true) {
        messenger.showSnackBar(
          SnackBar(content: Text('✔️ ${widget.paint.name} added')),
        );
      } else {
        throw Exception(result['message'] ?? 'Unknown error');
      }
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text('❌ $e'), backgroundColor: Colors.red),
      );
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

          if (_isLoading && _palettes.isEmpty)
            const Center(child: CircularProgressIndicator()),

          if (_palettes.isNotEmpty)
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: ListView.builder(
                controller: _scrollCtrl,
                itemCount: _palettes.length + (_isLoadingMore ? 1 : 0),
                itemBuilder: (_, i) {
                  if (i == _palettes.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final p = _palettes[i];
                  return ListTile(
                    title: Text(p.name),
                    subtitle: Text('${p.colors.length} colors'),
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children:
                          p.colors
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
                      _addToPalette(p.id);
                    },
                  );
                },
              ),
            ),

          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              // Aquí tu lógica para crear una paleta nueva
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
    _scrollCtrl.dispose();
    super.dispose();
  }
}
