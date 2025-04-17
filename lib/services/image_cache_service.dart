import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'dart:developer' as developer;

/// Servicio para gestionar la caché de imágenes de la aplicación
class ImageCacheService {
  /// Singleton instance
  static final ImageCacheService _instance = ImageCacheService._internal();

  /// Factory constructor para obtener la instancia singleton
  factory ImageCacheService() => _instance;

  /// Constructor interno privado
  ImageCacheService._internal();

  /// Clave para almacenar la última limpieza de caché
  static const String _lastCacheClearKey = 'last_image_cache_clear';

  /// Flag para debugging
  static const bool _debugMode = true;

  /// Limpia la caché de imágenes si es necesario
  Future<void> clearCacheIfNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastClearTime = prefs.getInt(_lastCacheClearKey);

      final now = DateTime.now().millisecondsSinceEpoch;
      final clearInterval =
          const Duration(days: 3).inMilliseconds; // Reducido a 3 días

      // Log de memoria inicial
      _logMemoryUsage('Before cache check');

      // Si nunca se ha limpiado o han pasado más de 3 días
      if (lastClearTime == null || (now - lastClearTime) > clearInterval) {
        await clearCache();
        await prefs.setInt(_lastCacheClearKey, now);
        debugPrint('✅ Caché de imágenes limpiada automáticamente');

        // Log de memoria después de limpiar
        _logMemoryUsage('After cache cleaning');
      }
    } catch (e) {
      debugPrint('⚠️ Error al verificar limpieza de caché: $e');
    }
  }

  /// Limpia toda la caché de imágenes
  Future<bool> clearCache() async {
    try {
      debugPrint('🧹 Iniciando limpieza de caché de imágenes...');

      // Limpiar la caché de imágenes en memoria de Flutter
      PaintingBinding.instance.imageCache.clear();

      // También limitar el tamaño después de limpiar
      PaintingBinding.instance.imageCache.maximumSizeBytes =
          20 * 1024 * 1024; // 20 MB
      PaintingBinding.instance.imageCache.maximumSize = 50;

      // Limpiar caché de CachedNetworkImage
      await CachedNetworkImage.evictFromCache(
        '',
        cacheManager: DefaultCacheManager(),
      );

      // Limpiar la caché de imágenes en disco
      await DefaultCacheManager().emptyCache();

      // Intentar forzar la recolección de basura
      debugPrint('🧹 Caché limpiada, pidiendo recolección de basura...');

      debugPrint('✅ Caché de imágenes limpiada completamente');
      return true;
    } catch (e) {
      debugPrint('⚠️ Error al limpiar caché de imágenes: $e');
      return false;
    }
  }

  /// Configura el tamaño máximo de la caché de imágenes en memoria
  /// Esto ayuda a reducir el consumo de memoria sin afectar el aspect ratio
  void configureImageCache({
    int maxSizeBytes = 30 * 1024 * 1024,
    int maxImages = 50,
  }) {
    try {
      // Configurar el tamaño máximo de la caché de imágenes en memoria
      final imageCache = PaintingBinding.instance.imageCache;

      // Obtener tamaño actual para logging
      final currentSize = imageCache.currentSize;
      final currentSizeBytes = imageCache.currentSizeBytes;

      // Aplicar nuevos límites
      imageCache.maximumSizeBytes = maxSizeBytes;
      imageCache.maximumSize = maxImages;

      debugPrint('📊 Estadísticas de caché antes de configuración:');
      debugPrint('- Imágenes en caché: $currentSize');
      debugPrint(
        '- Bytes en caché: ${(currentSizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB',
      );

      debugPrint('✅ Configuración de caché aplicada:');
      debugPrint('- Límite de imágenes: $maxImages');
      debugPrint(
        '- Límite de memoria: ${(maxSizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB',
      );

      // Log de memoria
      _logMemoryUsage('After cache configuration');
    } catch (e) {
      debugPrint('⚠️ Error al configurar caché de imágenes: $e');
    }
  }

  /// Obtiene el tamaño aproximado de la caché
  Future<String> getCacheSize() async {
    try {
      // Obtener información de la caché de imágenes en memoria de Flutter
      final imageCache = PaintingBinding.instance.imageCache;
      final memoryCacheSize = imageCache.currentSizeBytes / (1024 * 1024);

      // Log de memoria
      _logMemoryUsage('When checking cache size');

      return '${memoryCacheSize.toStringAsFixed(2)} MB en memoria';
    } catch (e) {
      debugPrint('⚠️ Error al obtener tamaño de caché: $e');
      return 'Desconocido';
    }
  }

  /// Precarga una imagen para que esté disponible en caché
  Future<void> preloadImage(
    String imageUrl,
    BuildContext context, {
    String? cacheKey,
    int? width,
    int? height,
  }) async {
    try {
      final provider = CachedNetworkImageProvider(
        imageUrl,
        cacheKey: cacheKey ?? imageUrl,
        maxWidth: width,
        maxHeight: height,
      );

      // Usar la función de Flutter para precarga
      await precacheImage(provider, context);
      debugPrint('✅ Imagen precargada: $imageUrl');
    } catch (e) {
      debugPrint('⚠️ Error al precargar imagen: $e');
    }
  }

  /// Registra uso de memoria (solo en modo debug)
  void _logMemoryUsage(String point) {
    if (!_debugMode) return;

    try {
      debugPrint('📊 MEMORY USAGE ($point):');
      // En Flutter web esto mostrará información de memoria. En apps nativas solo para debug
      developer.log('Memory usage at $point', name: 'ImageCacheService');
    } catch (e) {
      debugPrint('⚠️ Error logging memory: $e');
    }
  }
}
