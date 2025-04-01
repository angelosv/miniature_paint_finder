import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:vector_math/vector_math_64.dart' hide Colors;
import 'package:miniature_paint_finder/theme/app_theme.dart';

// Modos de herramientas para el selector de colores
enum ToolMode { picker, move }

class ColorSelectionModal extends StatefulWidget {
  final File imageFile;
  final List<ColorPoint> selectedPoints;
  final Function(List<ColorPoint>) onPointsUpdated;

  const ColorSelectionModal({
    Key? key,
    required this.imageFile,
    required this.selectedPoints,
    required this.onPointsUpdated,
  }) : super(key: key);

  static Future<void> show({
    required BuildContext context,
    required File imageFile,
    required List<ColorPoint> selectedPoints,
    required Function(List<ColorPoint>) onPointsUpdated,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder:
          (_) => ColorSelectionModal(
            imageFile: imageFile,
            selectedPoints: selectedPoints,
            onPointsUpdated: onPointsUpdated,
          ),
    );
  }

  @override
  State<ColorSelectionModal> createState() => _ColorSelectionModalState();
}

class _ColorSelectionModalState extends State<ColorSelectionModal>
    with SingleTickerProviderStateMixin {
  // Transformación para el zoom
  final TransformationController _transformationController =
      TransformationController();
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;

  // Tamaño de la imagen y contenedor
  final GlobalKey _imageKey = GlobalKey();
  Size _imageSize = Size.zero;
  img.Image? _decodedImage;

  // Estado de selección
  List<ColorPoint> _points = [];
  ColorPoint? _magnifierPoint;
  Offset? _magnifierPosition;
  int? _selectedPointIndex;
  bool _isMovingPoint = false;
  Offset? _doubleTapPosition;

  // Modo de lupa activo
  bool _magnifierMode = false;
  double _magnifierScale = 4.0;
  double _magnifierSize = 120.0;

  // Modos de herramientas
  ToolMode _currentMode = ToolMode.picker;

  // Estado de carga
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _points = List.from(widget.selectedPoints);
    _loadImage();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  Future<void> _loadImage() async {
    setState(() => _isLoading = true);

    try {
      final bytes = await widget.imageFile.readAsBytes();
      _decodedImage = img.decodeImage(bytes);

      if (_decodedImage != null) {
        setState(() {
          _imageSize = Size(
            _decodedImage!.width.toDouble(),
            _decodedImage!.height.toDouble(),
          );
        });
      }
    } catch (e) {
      print('Error loading image: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _animation = Matrix4Tween(
      begin: _transformationController.value,
      end: Matrix4.identity(),
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward(from: 0.0).then((_) {
      setState(() {
        _magnifierMode = false;
        _magnifierPoint = null;
      });
    });

    _animationController.addListener(() {
      if (_animation != null) {
        _transformationController.value = _animation!.value;
      }
    });
  }

  void _activateMagnifier(Offset position) {
    if (!_magnifierMode) {
      setState(() {
        _magnifierMode = true;
        _updateMagnifierPosition(position);
      });
    } else {
      _updateMagnifierPosition(position);
    }
  }

  void _deactivateMagnifier() {
    if (_magnifierMode) {
      setState(() {
        _magnifierMode = false;
        _magnifierPoint = null;
        _magnifierPosition = null;
      });
    }
  }

  void _updateMagnifierPosition(Offset position) {
    if (!_magnifierMode) return;

    // Ajustar la posición para que el magnificador no se salga de la pantalla
    final screenSize = MediaQuery.of(context).size;
    double x = position.dx;
    double y = position.dy - _magnifierSize - 20; // Mostrar arriba del dedo

    // Si está muy arriba, mostrar debajo
    if (y < 0) {
      y = position.dy + 60;
    }

    // Ajustar si está muy a la izquierda o derecha
    if (x < _magnifierSize / 2) {
      x = _magnifierSize / 2;
    } else if (x > screenSize.width - _magnifierSize / 2) {
      x = screenSize.width - _magnifierSize / 2;
    }

    // Obtenemos la posición exacta en la imagen (considerando el zoom)
    final imagePosition = _getImagePositionFromViewport(position);

    if (_decodedImage != null) {
      RenderBox? box =
          _imageKey.currentContext?.findRenderObject() as RenderBox?;
      if (box != null) {
        // Para obtener el color exacto, calculamos la proporción entre la imagen original y la mostrada
        final visibleImageSize = _getVisibleImageSize(box);

        // Ajustamos la posición considerando las proporciones de la imagen y el contenedor
        final adjustedX =
            (imagePosition.dx / visibleImageSize.width) * _decodedImage!.width;
        final adjustedY =
            (imagePosition.dy / visibleImageSize.height) *
            _decodedImage!.height;

        // Aseguramos que estamos dentro de los límites de la imagen
        final pixelX = adjustedX.round().clamp(0, _decodedImage!.width - 1);
        final pixelY = adjustedY.round().clamp(0, _decodedImage!.height - 1);

        // Obtener color desde la imagen original
        final pixel = _decodedImage!.getPixel(pixelX, pixelY);
        final color = Color.fromARGB(
          255,
          pixel.r.toInt(),
          pixel.g.toInt(),
          pixel.b.toInt(),
        );

        final hexCode =
            '#${color.value.toRadixString(16).substring(2).toUpperCase()}';

        setState(() {
          _magnifierPosition = Offset(x, y);
          _magnifierPoint = ColorPoint(
            x: imagePosition.dx,
            y: imagePosition.dy,
            color: color,
            hex: hexCode,
          );
        });
      }
    }
  }

  // Obtiene el tamaño visible actual de la imagen considerando zoom y posición
  Size _getVisibleImageSize(RenderBox box) {
    // Obtenemos el factor de escala actual
    final scale = _transformationController.value.getMaxScaleOnAxis();

    // Calculamos el tamaño de la imagen visible considerando el zoom
    return Size(box.size.width / scale, box.size.height / scale);
  }

  // Convertir coordenadas de la pantalla a coordenadas de la imagen considerando zoom
  Offset _getImagePositionFromViewport(Offset viewportPosition) {
    final Matrix4 inverseMatrix = Matrix4.inverted(
      _transformationController.value,
    );
    final Vector3 untransformedPosition = inverseMatrix.transform3(
      Vector3(viewportPosition.dx, viewportPosition.dy, 0),
    );
    return Offset(untransformedPosition.x, untransformedPosition.y);
  }

  void _handleTap(TapDownDetails details) {
    // Convertir tap a posición real en la imagen
    final imagePosition = _getImagePositionFromViewport(details.localPosition);

    // Verificar si el tap fue en un punto existente (para seleccionar)
    for (int i = 0; i < _points.length; i++) {
      final point = _points[i];
      final distance = (Offset(point.x, point.y) - imagePosition).distance;

      if (distance < 20 / _transformationController.value.getMaxScaleOnAxis()) {
        setState(() {
          _selectedPointIndex = i;
          _isMovingPoint = true;
        });
        return;
      }
    }

    // Solo añadir un nuevo punto si no estamos moviendo uno existente
    if (!_isMovingPoint) {
      // Si no tocó un punto existente, crear un nuevo punto
      if (_decodedImage != null) {
        RenderBox? box =
            _imageKey.currentContext?.findRenderObject() as RenderBox?;
        if (box != null) {
          // Para obtener el color exacto, calculamos la proporción entre la imagen original y la mostrada
          final visibleImageSize = _getVisibleImageSize(box);

          // Ajustamos la posición considerando las proporciones de la imagen y el contenedor
          final adjustedX =
              (imagePosition.dx / visibleImageSize.width) *
              _decodedImage!.width;
          final adjustedY =
              (imagePosition.dy / visibleImageSize.height) *
              _decodedImage!.height;

          // Aseguramos que estamos dentro de los límites de la imagen
          final pixelX = adjustedX.round().clamp(0, _decodedImage!.width - 1);
          final pixelY = adjustedY.round().clamp(0, _decodedImage!.height - 1);

          final pixel = _decodedImage!.getPixel(pixelX, pixelY);
          final color = Color.fromARGB(
            255,
            pixel.r.toInt(),
            pixel.g.toInt(),
            pixel.b.toInt(),
          );

          final hexCode =
              '#${color.value.toRadixString(16).substring(2).toUpperCase()}';

          final newPoint = ColorPoint(
            x: imagePosition.dx,
            y: imagePosition.dy,
            color: color,
            hex: hexCode,
          );

          setState(() {
            _points.add(newPoint);
            widget.onPointsUpdated(_points);
          });
        }
      }
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_isMovingPoint && _selectedPointIndex != null) {
      // Mover punto seleccionado
      final imagePosition = _getImagePositionFromViewport(
        details.localPosition,
      );

      if (_decodedImage != null) {
        RenderBox? box =
            _imageKey.currentContext?.findRenderObject() as RenderBox?;
        if (box != null) {
          // Para obtener el color exacto, calculamos la proporción entre la imagen original y la mostrada
          final visibleImageSize = _getVisibleImageSize(box);

          // Ajustamos la posición considerando las proporciones de la imagen y el contenedor
          final adjustedX =
              (imagePosition.dx / visibleImageSize.width) *
              _decodedImage!.width;
          final adjustedY =
              (imagePosition.dy / visibleImageSize.height) *
              _decodedImage!.height;

          // Aseguramos que estamos dentro de los límites de la imagen
          final pixelX = adjustedX.round().clamp(0, _decodedImage!.width - 1);
          final pixelY = adjustedY.round().clamp(0, _decodedImage!.height - 1);

          final pixel = _decodedImage!.getPixel(pixelX, pixelY);
          final color = Color.fromARGB(
            255,
            pixel.r.toInt(),
            pixel.g.toInt(),
            pixel.b.toInt(),
          );

          final hexCode =
              '#${color.value.toRadixString(16).substring(2).toUpperCase()}';

          setState(() {
            _points[_selectedPointIndex!] = ColorPoint(
              x: imagePosition.dx,
              y: imagePosition.dy,
              color: color,
              hex: hexCode,
            );
          });
        }
      }
    } else {
      // Actualizar posición de la lupa
      _activateMagnifier(details.localPosition);
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    if (_isMovingPoint) {
      setState(() {
        _isMovingPoint = false;
        _selectedPointIndex = null;
        widget.onPointsUpdated(_points);
      });
    }

    _deactivateMagnifier();
  }

  void _deletePoint(int index) {
    setState(() {
      _points.removeAt(index);
      widget.onPointsUpdated(_points);
    });
  }

  bool _isLightColor(Color color) {
    return (0.299 * color.red + 0.587 * color.green + 0.114 * color.blue) /
            255 >
        0.5;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.grey[900] : Colors.white;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header con botones de herramientas
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Precision Color Selector',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.close),
                        label: const Text("Close"),
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          foregroundColor:
                              isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Barra de herramientas
                  Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[850] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildToolButton(
                          icon: Icons.colorize,
                          label: 'Color Picker',
                          isActive: _currentMode == ToolMode.picker,
                          onTap:
                              () => setState(() {
                                _currentMode = ToolMode.picker;
                                _magnifierMode =
                                    true; // Activar lupa en modo selector
                              }),
                        ),
                        _buildToolButton(
                          icon: Icons.pan_tool,
                          label: 'Move',
                          isActive: _currentMode == ToolMode.move,
                          onTap:
                              () => setState(() {
                                _currentMode = ToolMode.move;
                                _magnifierMode =
                                    false; // Desactivar lupa en modo movimiento
                              }),
                        ),
                        _buildToolButton(
                          icon: Icons.restart_alt,
                          label: 'Reset',
                          onTap: () {
                            _resetZoom();
                            setState(() {
                              _currentMode = ToolMode.picker;
                              _magnifierMode = true;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Imagen con gestos
            Expanded(
              child: Stack(
                children: [
                  // Imagen principal con gestos
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : GestureDetector(
                        onTapDown:
                            _currentMode == ToolMode.picker ? _handleTap : null,
                        onPanUpdate: _handlePanUpdate,
                        onPanEnd: _handlePanEnd,
                        child: InteractiveViewer(
                          transformationController: _transformationController,
                          minScale: 0.5,
                          maxScale: 5.0,
                          panEnabled:
                              _currentMode ==
                              ToolMode
                                  .move, // Solo permitir pan en modo movimiento
                          scaleEnabled:
                              true, // Permitir zoom en todos los modos
                          child: Stack(
                            key: _imageKey,
                            children: [
                              // Imagen
                              Center(
                                child: Image.file(
                                  widget.imageFile,
                                  fit: BoxFit.contain,
                                  width: double.infinity,
                                ),
                              ),

                              // Puntos seleccionados
                              ..._points.asMap().entries.map((entry) {
                                final index = entry.key;
                                final point = entry.value;
                                final isSelected = index == _selectedPointIndex;
                                final isLight = _isLightColor(point.color);

                                return Positioned(
                                  left: point.x - 15,
                                  top: point.y - 15,
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
                                        width: isSelected ? 2.0 : 1.5,
                                      ),
                                      boxShadow:
                                          isSelected
                                              ? [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.3),
                                                  blurRadius: 3,
                                                  spreadRadius: 1,
                                                ),
                                              ]
                                              : null,
                                    ),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        // Número del punto
                                        Text(
                                          '${index + 1}',
                                          style: TextStyle(
                                            color:
                                                isLight
                                                    ? Colors.black
                                                    : Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),

                                        // Botón para eliminar el punto
                                        Positioned(
                                          top: 0,
                                          right: 0,
                                          child: GestureDetector(
                                            onTap: () => _deletePoint(index),
                                            child: Container(
                                              width: 12,
                                              height: 12,
                                              decoration: BoxDecoration(
                                                color:
                                                    isLight
                                                        ? Colors.black
                                                            .withOpacity(0.7)
                                                        : Colors.white
                                                            .withOpacity(0.7),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.close,
                                                size: 8,
                                                color:
                                                    isLight
                                                        ? Colors.white
                                                        : Colors.black,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                      ),

                  // Lupa (magnificador)
                  if (_magnifierMode &&
                      _magnifierPosition != null &&
                      _magnifierPoint != null)
                    Positioned(
                      left: _magnifierPosition!.dx - _magnifierSize / 2,
                      top: _magnifierPosition!.dy - _magnifierSize / 2,
                      child: GestureDetector(
                        onTap: () {
                          // Añadir el color actual al tocar la lupa
                          setState(() {
                            _points.add(_magnifierPoint!);
                            widget.onPointsUpdated(_points);
                          });
                        },
                        child: Container(
                          width: _magnifierSize,
                          height: _magnifierSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(color: Colors.grey, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Stack(
                              children: [
                                // Imagen ampliada
                                Transform.scale(
                                  scale: _magnifierScale,
                                  alignment: Alignment(
                                    2 *
                                        (((_magnifierPoint!.x) /
                                                _imageSize.width) -
                                            0.5),
                                    2 *
                                        (((_magnifierPoint!.y) /
                                                _imageSize.height) -
                                            0.5),
                                  ),
                                  child: Image.file(
                                    widget.imageFile,
                                    fit: BoxFit.contain,
                                    width: double.infinity,
                                  ),
                                ),

                                // Crosshair en el centro de la lupa
                                Center(
                                  child: Container(
                                    width: 2,
                                    height: 10,
                                    color: Colors.red,
                                  ),
                                ),
                                Center(
                                  child: Container(
                                    width: 10,
                                    height: 2,
                                    color: Colors.red,
                                  ),
                                ),

                                // Información del color
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    color: Colors.black.withOpacity(0.7),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 2,
                                    ),
                                    child: Text(
                                      _magnifierPoint!.hex,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Instrucciones según el modo activo
                  Positioned(
                    left: 16,
                    bottom: 16,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_currentMode == ToolMode.picker)
                            const Text(
                              '• Tap to add a color point',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          const Text(
                            '• Pinch to zoom in/out',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          if (_currentMode == ToolMode.move)
                            const Text(
                              '• Drag to move the image',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Indicador de nivel de zoom
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_transformationController.value.getMaxScaleOnAxis().toStringAsFixed(1)}x',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Panel inferior con colores seleccionados
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[850] : Colors.grey[100],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Selected Colors (${_points.length})',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          widget.onPointsUpdated(_points);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Apply'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 70,
                    child:
                        _points.isEmpty
                            ? Center(
                              child: Text(
                                'No colors selected yet',
                                style: TextStyle(
                                  color:
                                      isDarkMode
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            )
                            : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _points.length,
                              itemBuilder: (context, index) {
                                final point = _points[index];
                                final isLight = _isLightColor(point.color);

                                return Container(
                                  width: 60,
                                  height: 60,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: point.color,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color:
                                          isDarkMode
                                              ? Colors.grey[700]!
                                              : Colors.grey[300]!,
                                    ),
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            '${index + 1}',
                                            style: TextStyle(
                                              color:
                                                  isLight
                                                      ? Colors.black
                                                      : Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            point.hex,
                                            style: TextStyle(
                                              color:
                                                  isLight
                                                      ? Colors.black
                                                      : Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Positioned(
                                        top: 2,
                                        right: 2,
                                        child: GestureDetector(
                                          onTap: () => _deletePoint(index),
                                          child: Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                              color:
                                                  isLight
                                                      ? Colors.black
                                                          .withOpacity(0.5)
                                                      : Colors.white
                                                          .withOpacity(0.5),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.close,
                                              size: 10,
                                              color:
                                                  isLight
                                                      ? Colors.white
                                                      : Colors.black,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Botón de herramienta para la barra de herramientas
  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.marineBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isActive ? Colors.white : Colors.grey, size: 18),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ColorPoint {
  final double x;
  final double y;
  final Color color;
  final String hex;

  ColorPoint({
    required this.x,
    required this.y,
    required this.color,
    required this.hex,
  });
}
