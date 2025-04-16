import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:miniature_paint_finder/services/paint_service.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';
import 'package:provider/provider.dart';

/// A screen for debugging and managing the application's paint cache
class DebugCacheScreen extends StatefulWidget {
  /// Creates a new DebugCacheScreen instance
  const DebugCacheScreen({Key? key}) : super(key: key);

  @override
  State<DebugCacheScreen> createState() => _DebugCacheScreenState();
}

class _DebugCacheScreenState extends State<DebugCacheScreen> {
  bool _isCheckingCache = false;
  bool _isClearingCache = false;
  bool _isLoadingAllPaints = false;
  int _cachedPaintsCount = 0;
  String _lastUpdated = '';
  List<String> _cacheInfo = [];

  @override
  void initState() {
    super.initState();
    _checkCache();
  }

  Future<void> _checkCache() async {
    setState(() {
      _isCheckingCache = true;
      _cacheInfo = [];
    });

    try {
      final paintService = Provider.of<PaintService>(context, listen: false);
      final cacheInfo = await paintService.getCacheInfo();

      setState(() {
        _cachedPaintsCount = cacheInfo['count'] ?? 0;
        _lastUpdated = _formatDateTime(cacheInfo['lastUpdated']);
        _cacheInfo = List<String>.from(cacheInfo['details'] ?? []);
        _isCheckingCache = false;
      });
    } catch (e) {
      setState(() {
        _isCheckingCache = false;
        _cacheInfo = ['Error checking cache: $e'];
      });
    }
  }

  Future<void> _clearCache() async {
    setState(() {
      _isClearingCache = true;
    });

    try {
      final paintService = Provider.of<PaintService>(context, listen: false);
      await paintService.clearCache();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cache cleared successfully')),
      );

      await _checkCache();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error clearing cache: $e')));
    } finally {
      setState(() {
        _isClearingCache = false;
      });
    }
  }

  Future<void> _loadAllPaintsToCache() async {
    setState(() {
      _isLoadingAllPaints = true;
    });

    try {
      final paintService = Provider.of<PaintService>(context, listen: false);
      await paintService.loadAllPaintsToCache();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All paints loaded to cache')),
      );

      await _checkCache();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading paints: $e')));
    } finally {
      setState(() {
        _isLoadingAllPaints = false;
      });
    }
  }

  String _formatDateTime(dynamic dateTime) {
    if (dateTime == null) return 'Never';

    if (dateTime is String) {
      try {
        final DateTime parsed = DateTime.parse(dateTime);
        return DateFormat('MMM d, yyyy HH:mm:ss').format(parsed);
      } catch (e) {
        return dateTime;
      }
    } else if (dateTime is DateTime) {
      return DateFormat('MMM d, yyyy HH:mm:ss').format(dateTime);
    }

    return 'Unknown date format';
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Cache'),
        backgroundColor:
            isDarkMode ? AppTheme.marineBlueDark : AppTheme.marineBlue,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _checkCache,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cache info card
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cache Information',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        'Paints cached:',
                        '$_cachedPaintsCount items',
                      ),
                      _buildInfoRow('Last updated:', _lastUpdated),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    icon: Icons.refresh,
                    label: 'Check Cache',
                    onPressed: _isCheckingCache ? null : _checkCache,
                    isLoading: _isCheckingCache,
                  ),
                  _buildActionButton(
                    icon: Icons.delete_outline,
                    label: 'Clear Cache',
                    onPressed: _isClearingCache ? null : _clearCache,
                    isLoading: _isClearingCache,
                    color: Colors.red,
                  ),
                  _buildActionButton(
                    icon: Icons.download_outlined,
                    label: 'Load All Paints',
                    onPressed:
                        _isLoadingAllPaints ? null : _loadAllPaintsToCache,
                    isLoading: _isLoadingAllPaints,
                    color: Colors.green,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Cache details
              Text(
                'Cache Details',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),

              Expanded(
                child:
                    _isCheckingCache
                        ? const Center(child: CircularProgressIndicator())
                        : _cacheInfo.isEmpty
                        ? const Center(
                          child: Text('No cache details available'),
                        )
                        : ListView.builder(
                          itemCount: _cacheInfo.length,
                          itemBuilder: (context, index) {
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(_cacheInfo[index]),
                              ),
                            );
                          },
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required bool isLoading,
    Color? color,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: color ?? Theme.of(context).primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 12.0),
          ),
          child:
              isLoading
                  ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                  : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 20),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
        ),
      ),
    );
  }
}
