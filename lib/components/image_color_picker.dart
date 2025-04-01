import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;
import 'package:image_picker/image_picker.dart';
import 'package:miniature_paint_finder/services/image_upload_service.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';
import 'package:image/image.dart' as img;
import 'package:miniature_paint_finder/components/color_selection_modal.dart';
import 'package:google_fonts/google_fonts.dart';

// Modelo para representar una marca de pintura
class PaintBrand {
  final String id;
  final String name;
  final String logoUrl;
  bool isSelected;

  PaintBrand({
    required this.id,
    required this.name,
    required this.logoUrl,
    this.isSelected = false,
  });
}

class ImageColorPicker extends StatefulWidget {
  final File? imageFile;
  final Function(List<Map<String, dynamic>>) onColorsSelected;
  final Function(File) onImageSelected;
  final Function(String)? onImageUploaded;

  const ImageColorPicker({
    super.key,
    this.imageFile,
    required this.onColorsSelected,
    required this.onImageSelected,
    this.onImageUploaded,
  });

  @override
  State<ImageColorPicker> createState() => _ImageColorPickerState();
}

class _ImageColorPickerState extends State<ImageColorPicker> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  final ImageUploadService _imageUploadService = ImageUploadService();
  List<_ColorPoint> _selectedColorPoints = [];
  final TransformationController _transformationController =
      TransformationController();
  double _currentScale = 1.0;
  Offset? _doubleTapPosition;

  // Variables para arrastrar los puntos
  int? _draggedPointIndex;

  // Tamaño del contenedor de la imagen
  Size _containerSize = Size.zero;
  // Tamaño de la imagen actual
  Size _imageSize = Size.zero;
  // Rectángulo de la imagen
  Rect _imageRect = Rect.zero;
  // Indicador de si se está cargando la imagen
  bool _isImageLoading = false;

  // Lista de marcas de pinturas disponibles
  final List<PaintBrand> _availableBrands = [
    PaintBrand(
      id: 'citadel',
      name: 'Citadel',
      logoUrl:
          'https://www.games-workshop.com/resources/catalog/product/920x950/99179950001_CitadelColourContrastPaintsAll.jpg',
    ),
    PaintBrand(
      id: 'vallejo',
      name: 'Vallejo',
      logoUrl:
          'https://m.media-amazon.com/images/I/71FQ+grLCFL._AC_UF1000,1000_QL80_.jpg',
    ),
    PaintBrand(
      id: 'armypainter',
      name: 'Army Painter',
      logoUrl:
          'https://i0.wp.com/www.thearmypainter.com/wp-content/uploads/2022/03/TAP_Logo_on-White.png',
    ),
    PaintBrand(
      id: 'scale75',
      name: 'Scale 75',
      logoUrl:
          'https://i0.wp.com/scalemodellingchannel.com/wp-content/uploads/2018/08/scale75-logo-colored.jpg',
    ),
  ];

  // GlobalKey para obtener el tamaño y posición exactos del widget de imagen
  final GlobalKey _imageKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadImageDimensions();

    // Añadir listener para el cambio de transformación (zoom)
    _transformationController.addListener(_handleTransformChange);
  }

  void _handleTransformChange() {
    setState(() {
      _currentScale = _transformationController.value.getMaxScaleOnAxis();
    });

    // Obtener el rectángulo de la imagen después del zoom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateImageRect();
    });
  }

  // Actualizar el rectángulo de la imagen
  void _updateImageRect() {
    if (_imageKey.currentContext != null) {
      final RenderBox box =
          _imageKey.currentContext!.findRenderObject() as RenderBox;
      final Offset position = box.localToGlobal(Offset.zero);
      _imageRect = Rect.fromLTWH(
        position.dx,
        position.dy,
        box.size.width,
        box.size.height,
      );
    }
  }

  // Cargar las dimensiones de la imagen
  Future<void> _loadImageDimensions() async {
    if (widget.imageFile != null && widget.imageFile!.existsSync()) {
      try {
        final bytes = await widget.imageFile!.readAsBytes();
        final image = img.decodeImage(bytes);
        if (image != null) {
          setState(() {
            _imageSize = Size(image.width.toDouble(), image.height.toDouble());
          });
        }
      } catch (e) {
        print('Error loading image dimensions: $e');
      }
    }
  }

  @override
  void didUpdateWidget(ImageColorPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageFile?.path != widget.imageFile?.path) {
      _loadImageDimensions();
      setState(() {
        _selectedColorPoints = [];
      });
      _notifyColorsChanged();
    }
  }

  @override
  void dispose() {
    _transformationController.removeListener(_handleTransformChange);
    _transformationController.dispose();
    super.dispose();
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);

      if (pickedFile != null) {
        final File imageFile = File(pickedFile.path);
        widget.onImageSelected(imageFile);

        // Subir la imagen
        setState(() {
          _isUploading = true;
          _selectedColorPoints = [];
        });

        // Notificar que los colores han cambiado
        _notifyColorsChanged();

        try {
          final String imageUrl = await _imageUploadService.uploadImage(
            imageFile,
          );
          if (widget.onImageUploaded != null) {
            widget.onImageUploaded!(imageUrl);
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error uploading image: $e'),
              backgroundColor: Colors.red,
            ),
          );
        } finally {
          setState(() {
            _isUploading = false;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Convertir las coordenadas visuales a coordenadas de la imagen real
  Offset _getImageCoordinatesFromViewport(Offset viewportPosition) {
    if (_imageKey.currentContext == null) return viewportPosition;

    // Obtener el RenderBox del widget de imagen
    final RenderBox box =
        _imageKey.currentContext!.findRenderObject() as RenderBox;

    // Convertir la posición global a local en el contexto del widget de imagen
    final Offset localPosition = box.globalToLocal(viewportPosition);

    // Calcular la posición relativa en función del tamaño real de la imagen y el estado actual del zoom
    final Matrix4 transform = _transformationController.value;
    final Matrix4 inverseTransform = Matrix4.inverted(transform);
    final Vector3 untransformedPosition = inverseTransform.transform3(
      Vector3(localPosition.dx, localPosition.dy, 0),
    );

    return Offset(untransformedPosition.x, untransformedPosition.y);
  }

  // Obtener color en la posición de la imagen
  Color? _getColorAtPosition(Offset position) {
    if (widget.imageFile == null ||
        !widget.imageFile!.existsSync() ||
        _isImageLoading)
      return null;

    try {
      final image = img.decodeImage(widget.imageFile!.readAsBytesSync());
      if (image == null) return null;

      // Calcular la posición relativa en la imagen
      final double x = position.dx / _containerSize.width;
      final double y = position.dy / _containerSize.height;

      // Convertir a coordenadas de píxel
      final pixelX = (x * image.width).round();
      final pixelY = (y * image.height).round();

      // Verificar que esté dentro de los límites
      if (pixelX >= 0 &&
          pixelX < image.width &&
          pixelY >= 0 &&
          pixelY < image.height) {
        final pixel = image.getPixel(pixelX, pixelY);
        return Color.fromARGB(
          255, // Alpha fijo
          pixel.r.toInt(),
          pixel.g.toInt(),
          pixel.b.toInt(),
        );
      }
    } catch (e) {
      print('Error obteniendo color: $e');
    }

    return null;
  }

  void _handleImageTap(TapDownDetails details) {
    if (widget.imageFile == null || _isImageLoading) return;
    if (_draggedPointIndex != null)
      return; // No seleccionar nuevo color si estamos arrastrando

    // Obtener la posición en coordenadas locales del widget contenedor
    final Offset tapPosition = details.localPosition;

    // Convertir la posición del tap considerando el zoom y transformación
    final Offset imagePosition = _transformPositionToImageCoordinates(
      tapPosition,
    );

    // Asegurarse de que el punto está dentro de los límites del contenedor
    if (imagePosition.dx < 0 ||
        imagePosition.dx > _containerSize.width ||
        imagePosition.dy < 0 ||
        imagePosition.dy > _containerSize.height) {
      return; // El tap está fuera de los límites
    }

    // Obtener el color en la posición seleccionada
    final color = _getColorAtPosition(imagePosition);
    if (color == null) return;

    // Convertir el color a formato hexadecimal
    final hexCode =
        '#${color.value.toRadixString(16).substring(2).toUpperCase()}';

    setState(() {
      // Ya no hay límite de colores seleccionables
      _selectedColorPoints.add(
        _ColorPoint(
          x: imagePosition.dx,
          y: imagePosition.dy,
          color: color,
          hex: hexCode,
        ),
      );

      // Notificar que los colores han cambiado
      _notifyColorsChanged();
    });
  }

  // Convertir las coordenadas del tap en coordenadas de la imagen
  Offset _transformPositionToImageCoordinates(Offset position) {
    // Obtener la matriz de transformación actual
    final Matrix4 transform = _transformationController.value;

    // Invertir la matriz para obtener la posición real en la imagen
    final Matrix4 inverseTransform = Matrix4.inverted(transform);

    // Aplicar la transformación inversa a la posición actual
    final Vector3 untransformedPosition = inverseTransform.transform3(
      Vector3(position.dx, position.dy, 0),
    );

    return Offset(untransformedPosition.x, untransformedPosition.y);
  }

  // Comenzar arrastre del punto seleccionado
  void _handleColorPointDragStart(int index) {
    setState(() {
      _draggedPointIndex = index;
    });
  }

  // Actualizar posición del punto durante el arrastre
  void _handleColorPointDragUpdate(DragUpdateDetails details) {
    if (_draggedPointIndex == null ||
        _draggedPointIndex! >= _selectedColorPoints.length)
      return;

    // Obtener la nueva posición en coordenadas de la imagen
    final Offset newPosition = _transformPositionToImageCoordinates(
      details.localPosition,
    );

    // Comprobar que la nueva posición está dentro de los límites
    if (newPosition.dx < 0 ||
        newPosition.dx > _containerSize.width ||
        newPosition.dy < 0 ||
        newPosition.dy > _containerSize.height) {
      return;
    }

    // Obtener el color en la nueva posición
    final color = _getColorAtPosition(newPosition);
    if (color == null) return;

    // Convertir el color a formato hexadecimal
    final hexCode =
        '#${color.value.toRadixString(16).substring(2).toUpperCase()}';

    setState(() {
      // Actualizar la posición y color del punto arrastrado
      _selectedColorPoints[_draggedPointIndex!] = _ColorPoint(
        x: newPosition.dx,
        y: newPosition.dy,
        color: color,
        hex: hexCode,
      );

      // Notificar que los colores han cambiado
      _notifyColorsChanged();
    });
  }

  // Finalizar arrastre del punto
  void _handleColorPointDragEnd(DragEndDetails details) {
    setState(() {
      _draggedPointIndex = null;
    });
  }

  // Actualizar la lista de colores seleccionados en el formato que espera el padre
  void _notifyColorsChanged() {
    final colors =
        _selectedColorPoints.map((point) {
          return {'color': point.color, 'hexCode': point.hex};
        }).toList();

    widget.onColorsSelected(colors);
  }

  // Manejar el doble tap para zoom
  void _handleDoubleTap() {
    if (_doubleTapPosition == null) return;

    // Realizar zoom in/out dependiendo del nivel actual de zoom
    if (_currentScale > 1.5) {
      // Si ya hay zoom, volver a la escala normal
      _transformationController.value = Matrix4.identity();
      _currentScale = 1.0;
    } else {
      // Hacer zoom en la posición del doble tap
      final Matrix4 newMatrix =
          Matrix4.identity()
            ..translate(
              -_doubleTapPosition!.dx * 2,
              -_doubleTapPosition!.dy * 2,
            )
            ..scale(3.0);

      _transformationController.value = newMatrix;
      _currentScale = 3.0;
    }
  }

  // Remover un punto de color seleccionado
  void _removeColorPoint(int index) {
    setState(() {
      _selectedColorPoints.removeAt(index);
      _notifyColorsChanged();
    });
  }

  // Método para abrir el modal de selección precisa
  void _openPrecisionColorSelector(BuildContext context) {
    if (widget.imageFile == null) return;

    // Convertir los puntos actuales al formato esperado por el modal
    final currentPoints =
        _selectedColorPoints
            .map(
              (point) => ColorPoint(
                x: point.x,
                y: point.y,
                color: point.color,
                hex: point.hex,
              ),
            )
            .toList();

    // Mostrar modal
    ColorSelectionModal.show(
      context: context,
      imageFile: widget.imageFile!,
      selectedPoints: currentPoints,
      onPointsUpdated: (updatedPoints) {
        setState(() {
          // Convertir puntos de regreso al formato utilizado por este widget
          _selectedColorPoints =
              updatedPoints
                  .map(
                    (point) => _ColorPoint(
                      x: point.x,
                      y: point.y,
                      color: point.color,
                      hex: point.hex,
                    ),
                  )
                  .toList();

          // Notificar cambios
          _notifyColorsChanged();
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        if (widget.imageFile != null)
          LayoutBuilder(
            builder: (context, constraints) {
              // Guardar el tamaño del contenedor
              _containerSize = Size(constraints.maxWidth, 250);

              return Stack(
                children: [
                  // Contenedor principal
                  Container(
                    width: constraints.maxWidth,
                    height: 250,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        children: [
                          // Imagen que ocupa todo el espacio disponible
                          Image.file(
                            widget.imageFile!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),

                          // Botón de selección de colores centrado
                          Center(
                            child: ElevatedButton.icon(
                              onPressed:
                                  () => _openPrecisionColorSelector(context),
                              icon: const Icon(Icons.color_lens, size: 20),
                              label: Text(
                                'Pick Colors',
                                style: TextStyle(
                                  fontFamily: GoogleFonts.poppins().fontFamily,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? AppTheme.marineOrange
                                        : AppTheme.marineBlue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Botón de cerrar
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        widget.onImageSelected(File(''));
                        setState(() {
                          _selectedColorPoints = [];
                          _notifyColorsChanged();
                        });
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withOpacity(0.5),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              );
            },
          )
        else
          Container(
            width: double.infinity,
            height: 250,
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[850] : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Mensaje para seleccionar imagen
                Icon(
                  Icons.image,
                  size: 48,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
                const SizedBox(height: 16),
                Text(
                  'Select an image to find matching paints',
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 24),

                // Botones centrados de cámara y galería
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildImageSourceButton(
                      context,
                      icon: Icons.camera_alt,
                      label: 'Camera',
                      onTap: () => _getImage(ImageSource.camera),
                    ),
                    const SizedBox(width: 20),
                    _buildImageSourceButton(
                      context,
                      icon: Icons.photo_library,
                      label: 'Gallery',
                      onTap: () => _getImage(ImageSource.gallery),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  // Botón estilizado para fuentes de imágenes
  Widget _buildImageSourceButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 130,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color:
              isDarkMode
                  ? AppTheme.marineBlue.withOpacity(0.9)
                  : AppTheme.marineBlue,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontFamily: GoogleFonts.poppins().fontFamily,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isLightColor(Color color) {
    return (0.299 * color.red + 0.587 * color.green + 0.114 * color.blue) /
            255 >
        0.5;
  }
}

class _ColorPoint {
  final double x;
  final double y;
  final Color color;
  final String hex;

  _ColorPoint({
    required this.x,
    required this.y,
    required this.color,
    required this.hex,
  });
}

// Clase para pintar los puntos de color en la imagen
class ColorPointsPainter extends CustomPainter {
  final List<_ColorPoint> points;

  ColorPointsPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    for (var point in points) {
      // Ajustar coordenadas al tamaño actual
      final double x = point.x;
      final double y = point.y;

      // Dibujar círculo de color en la posición
      final paint =
          Paint()
            ..color = point.color.withOpacity(0.7)
            ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), 8, paint);

      // Borde del círculo
      final borderPaint =
          Paint()
            ..color = _isLightColor(point.color) ? Colors.black : Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5;

      canvas.drawCircle(Offset(x, y), 8, borderPaint);
    }
  }

  @override
  bool shouldRepaint(ColorPointsPainter oldDelegate) {
    return oldDelegate.points != points;
  }

  bool _isLightColor(Color color) {
    return (0.299 * color.red + 0.587 * color.green + 0.114 * color.blue) /
            255 >
        0.5;
  }
}
