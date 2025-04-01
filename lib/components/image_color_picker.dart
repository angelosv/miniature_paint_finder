import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;
import 'package:image_picker/image_picker.dart';
import 'package:miniature_paint_finder/services/image_upload_service.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';
import 'package:image/image.dart' as img;

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

  // Tamaño del contenedor de la imagen
  Size _containerSize = Size.zero;
  // Tamaño de la imagen actual
  Size _imageSize = Size.zero;
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

  @override
  void initState() {
    super.initState();
    _loadImageDimensions();
  }

  // Cargar las dimensiones de la imagen
  Future<void> _loadImageDimensions() async {
    if (widget.imageFile != null && widget.imageFile!.existsSync()) {
      setState(() {
        _isImageLoading = true;
      });

      try {
        final image = img.decodeImage(widget.imageFile!.readAsBytesSync());
        if (image != null) {
          setState(() {
            _imageSize = Size(image.width.toDouble(), image.height.toDouble());
          });
        }
      } catch (e) {
        print('Error loading image dimensions: $e');
      } finally {
        setState(() {
          _isImageLoading = false;
        });
      }
    }
  }

  @override
  void didUpdateWidget(ImageColorPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageFile?.path != widget.imageFile?.path) {
      _loadImageDimensions();
      // Limpiar los colores seleccionados al cambiar la imagen
      setState(() {
        _selectedColorPoints = [];
      });
      // Notificar que los colores han cambiado
      _notifyColorsChanged();
    }
  }

  @override
  void dispose() {
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

  void _handleImageTap(TapDownDetails details) {
    if (widget.imageFile == null || _isImageLoading) return;

    final Offset localPosition = details.localPosition;

    // Calcular la posición del tap considerando el zoom actual
    final Offset imagePosition = _transformPositionToImageCoordinates(
      localPosition,
    );

    // Asegurarse de que el punto está dentro de los límites del contenedor
    if (imagePosition.dx < 0 ||
        imagePosition.dx > _containerSize.width ||
        imagePosition.dy < 0 ||
        imagePosition.dy > _containerSize.height) {
      return; // El tap está fuera de los límites
    }

    // Calcular la posición relativa en la imagen
    final double x = imagePosition.dx / _containerSize.width;
    final double y = imagePosition.dy / _containerSize.height;

    // Obtener el color en la posición seleccionada
    final image = img.decodeImage(widget.imageFile!.readAsBytesSync());
    if (image != null) {
      final pixelX = (x * image.width).round();
      final pixelY = (y * image.height).round();

      if (pixelX >= 0 &&
          pixelX < image.width &&
          pixelY >= 0 &&
          pixelY < image.height) {
        final pixel = image.getPixel(pixelX, pixelY);
        final color = Color.fromARGB(
          255, // Alpha fijo a 255 (opaco)
          pixel.r.toInt(), // Red
          pixel.g.toInt(), // Green
          pixel.b.toInt(), // Blue
        );

        // Convertir el color a formato hexadecimal
        final hexCode =
            '#${color.value.toRadixString(16).substring(2).toUpperCase()}';

        setState(() {
          if (_selectedColorPoints.length < 5) {
            // Limitar a 5 colores
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
          } else {
            // Mostrar un mensaje si ya se han seleccionado 5 colores
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Maximum 5 colors can be selected.'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        });
      }
    }
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
                      child: GestureDetector(
                        onTapDown: _handleImageTap,
                        onDoubleTapDown: (details) {
                          // Guardar la posición del doble tap
                          setState(() {
                            _doubleTapPosition = details.localPosition;
                          });
                        },
                        onDoubleTap: _handleDoubleTap,
                        child: InteractiveViewer(
                          transformationController: _transformationController,
                          minScale: 1.0,
                          maxScale: 4.0,
                          onInteractionUpdate: (details) {
                            setState(() {
                              _currentScale = details.scale;
                            });
                          },
                          child: Stack(
                            children: [
                              // Imagen de fondo
                              Image.file(
                                widget.imageFile!,
                                fit: BoxFit.contain,
                                width: constraints.maxWidth,
                                height: 250,
                              ),

                              // Puntos seleccionados
                              ..._selectedColorPoints.map((point) {
                                // Determinar si el texto debe ser claro u oscuro según el color de fondo
                                final bool isLight = _isLightColor(point.color);
                                return Positioned(
                                  left: point.x - 15, // Centrar el marcador
                                  top: point.y - 15, // Centrar el marcador
                                  child: GestureDetector(
                                    onTap: () {
                                      final index = _selectedColorPoints
                                          .indexOf(point);
                                      if (index != -1) {
                                        _removeColorPoint(index);
                                      }
                                    },
                                    child: Container(
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        color: point.color.withOpacity(0.8),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color:
                                              isLight
                                                  ? Colors.black
                                                  : Colors.white,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${_selectedColorPoints.indexOf(point) + 1}',
                                          style: TextStyle(
                                            color:
                                                isLight
                                                    ? Colors.black
                                                    : Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        ),
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
                          _transformationController.value = Matrix4.identity();
                          _currentScale = 1.0;
                        });
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withOpacity(0.5),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  // Indicador de zoom
                  if (_currentScale > 1.0)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_currentScale.toStringAsFixed(1)}x',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  // Instrucciones de ayuda
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Tap: select color\nDouble tap: zoom',
                        style: TextStyle(color: Colors.white, fontSize: 10),
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
            height: 200,
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
                Icon(
                  Icons.image,
                  size: 48,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
                const SizedBox(height: 8),
                Text(
                  'No image selected',
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        if (widget.imageFile != null) ...[
          const SizedBox(height: 8),
          Text(
            'Tap on the image to select colors (max 5)\nDouble tap to zoom in/out',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          if (_selectedColorPoints.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children:
                  _selectedColorPoints.map((point) {
                    final isLight = _isLightColor(point.color);
                    return Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: point.color,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              isDarkMode
                                  ? Colors.grey[700]!
                                  : Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Text(
                              point.hex,
                              style: TextStyle(
                                color: isLight ? Colors.black : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 2,
                            right: 2,
                            child: GestureDetector(
                              onTap: () {
                                final index = _selectedColorPoints.indexOf(
                                  point,
                                );
                                if (index != -1) {
                                  _removeColorPoint(index);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color:
                                      isLight
                                          ? Colors.black.withOpacity(0.5)
                                          : Colors.white.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close,
                                  size: 10,
                                  color: isLight ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
            ),
          ],
        ],
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildOptionButton(
              icon: Icons.photo_camera,
              label: 'Camera',
              onTap: _isUploading ? null : () => _getImage(ImageSource.camera),
            ),
            const SizedBox(width: 40),
            _buildOptionButton(
              icon: Icons.photo_library,
              label: 'Gallery',
              onTap: _isUploading ? null : () => _getImage(ImageSource.gallery),
            ),
          ],
        ),
        if (_isUploading)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
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
