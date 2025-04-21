import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:vector_math/vector_math_64.dart' hide Colors;
import 'package:miniature_paint_finder/theme/app_theme.dart';
import 'dart:async';

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
  ui.Image? _uiImage; // Para el magnificador
  Completer<ui.Image>? _imageCompleter;

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

    // Añadir listener para el controlador de transformación para actualizar el punto del magnificador
    _transformationController.addListener(_onTransformationChange);
  }

  Future<void> _loadImage() async {
    setState(() => _isLoading = true);

    try {
      final bytes = await widget.imageFile.readAsBytes();
      _decodedImage = img.decodeImage(bytes);

      if (_decodedImage != null) {
        // Cargar la imagen UI para el magnificador
        final imgBytes = await widget.imageFile.readAsBytes();
        final completer = Completer<ui.Image>();
        ui.decodeImageFromList(imgBytes, (image) {
          completer.complete(image);
        });
        _uiImage = await completer.future;

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
    _transformationController.removeListener(_onTransformationChange);
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onTransformationChange() {
    // Si hay una posición de magnificador activa, actualizarla para mantenerla en sincronía con el zoom
    if (_magnifierMode &&
        _magnifierPosition != null &&
        _magnifierPoint != null) {
      // Al hacer zoom, necesitamos recalcular la posición en la imagen
      final scale = _transformationController.value.getMaxScaleOnAxis();
      setState(() {
        // Actualizar el nivel de zoom en la UI
      });
    }
  }

  // Función para ajustar el zoom centrado en un punto específico
  void _zoomToPoint(Offset point, double targetScale) {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();

    // No hacer nada si ya estamos en el nivel de zoom deseado
    if ((targetScale - currentScale).abs() < 0.1) return;

    // Convertir el punto de la pantalla a coordenadas de imagen
    final imagePoint = _getImagePositionFromViewport(point);

    // Calcular la matriz de transformación para centrar el zoom en el punto
    final Matrix4 matrix =
        Matrix4.identity()
          ..translate(
            -imagePoint.dx * (targetScale - 1),
            -imagePoint.dy * (targetScale - 1),
          )
          ..scale(targetScale);

    // Animar la transición al nuevo nivel de zoom
    _animation = Matrix4Tween(
      begin: _transformationController.value,
      end: matrix,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutQuad),
    );

    _animationController.reset();
    _animationController.forward();

    _animationController.addListener(() {
      if (_animation != null) {
        _transformationController.value = _animation!.value;
      }
    });
  }

  // Mejorar la detección de doble tap para zoom
  void _handleDoubleTap(TapDownDetails details) {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();

    // Alternar entre zoom normal y zoom aumentado
    if (currentScale > 1.5) {
      // Si ya estamos en zoom, volver a escala 1
      _zoomToPoint(details.localPosition, 1.0);
    } else {
      // Hacer zoom en el punto donde el usuario hizo doble tap
      _zoomToPoint(details.localPosition, 3.0); // Zoom 3x
    }
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

    // Calculamos el punto exacto en la imagen donde está tocando el usuario
    final imagePosition = _getImagePositionFromViewport(position);

    // Posición fija de la lupa - siempre en el centro superior
    final screenSize = MediaQuery.of(context).size;
    double x = screenSize.width / 2;
    double y = 120; // Margen desde arriba para el header

    // Obtener el color exacto en la posición actual
    final color = _getColorAt(imagePosition.dx, imagePosition.dy);
    final hexCode =
        '#${color.value.toRadixString(16).substring(2).padLeft(6, '0').toUpperCase()}';

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

  // Calculamos el tamaño real de la imagen mostrada en pantalla
  Size _getImageDisplaySize(RenderBox containerBox) {
    // Obtenemos el tamaño del contenedor
    final containerSize = containerBox.size;

    // Calculamos el ratio para ajustar la imagen manteniendo la proporción
    final aspectRatio = _imageSize.width / _imageSize.height;

    double width, height;

    // Si la imagen es más ancha que alta
    if (aspectRatio > containerSize.width / containerSize.height) {
      width = containerSize.width;
      height = width / aspectRatio;
    } else {
      // Si la imagen es más alta que ancha
      height = containerSize.height;
      width = height * aspectRatio;
    }

    return Size(width, height);
  }

  // Convertir coordenadas de la pantalla a coordenadas de la imagen considerando zoom
  Offset _getImagePositionFromViewport(Offset viewportPosition) {
    // Obtener el RenderBox del widget de imagen para obtener el tamaño real en pantalla
    RenderBox? box = _imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) {
      return viewportPosition;
    }

    // Convertir la posición global a local dentro del widget de la imagen
    final localPosition = box.globalToLocal(viewportPosition);

    // Obtener la matriz de transformación inversa para convertir entre coordenadas
    final Matrix4 inverseMatrix = Matrix4.inverted(
      _transformationController.value,
    );
    final Vector3 untransformedPosition = inverseMatrix.transform3(
      Vector3(localPosition.dx, localPosition.dy, 0),
    );

    // Aplicar límites a las coordenadas para asegurar que estén dentro de la imagen
    return Offset(
      untransformedPosition.x.clamp(0.0, _imageSize.width),
      untransformedPosition.y.clamp(0.0, _imageSize.height),
    );
  }

  // Obtener el color en una posición con mejor precisión
  Color _getColorAt(double x, double y) {
    if (_decodedImage == null) {
      return Colors.transparent;
    }

    // Calcular la posición en píxeles en la imagen original
    final pixelX =
        (x * _decodedImage!.width / _imageSize.width)
            .clamp(0.0, _decodedImage!.width - 1)
            .toInt();
    final pixelY =
        (y * _decodedImage!.height / _imageSize.height)
            .clamp(0.0, _decodedImage!.height - 1)
            .toInt();

    // Utilizar interpolación bilineal para obtener un color más preciso
    // Obtener los colores de los píxeles vecinos
    final pixel = _decodedImage!.getPixel(pixelX, pixelY);

    // Convertir a color Flutter
    return Color.fromARGB(
      255,
      pixel.r.toInt(),
      pixel.g.toInt(),
      pixel.b.toInt(),
    );
  }

  void _handleTap(TapDownDetails details) {
    // Convertir tap a posición real en la imagen
    final imagePosition = _getImagePositionFromViewport(details.localPosition);

    // Verificar si el tap fue en un punto existente (para seleccionar)
    for (int i = 0; i < _points.length; i++) {
      final point = _points[i];
      final distance = (Offset(point.x, point.y) - imagePosition).distance;

      // Usar una distancia más sensible basada en el nivel de zoom actual
      final selectThreshold =
          20 / _transformationController.value.getMaxScaleOnAxis();

      if (distance < selectThreshold) {
        setState(() {
          _selectedPointIndex = i;
          _isMovingPoint = true;
        });
        return;
      }
    }

    // Solo añadir un nuevo punto si no estamos moviendo uno existente
    if (!_isMovingPoint) {
      // Obtener el color exacto en la posición del tap usando nuestra nueva función
      final color = _getColorAt(imagePosition.dx, imagePosition.dy);

      // Convertir el color a formato hexadecimal
      final hexCode =
          '#${color.value.toRadixString(16).substring(2).padLeft(6, '0').toUpperCase()}';

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

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_isMovingPoint && _selectedPointIndex != null) {
      // Mover punto seleccionado
      final imagePosition = _getImagePositionFromViewport(
        details.localPosition,
      );

      // Obtener el color exacto en la posición actual usando nuestra función mejorada
      final color = _getColorAt(imagePosition.dx, imagePosition.dy);
      final hexCode =
          '#${color.value.toRadixString(16).substring(2).padLeft(6, '0').toUpperCase()}';

      setState(() {
        _points[_selectedPointIndex!] = ColorPoint(
          x: imagePosition.dx,
          y: imagePosition.dy,
          color: color,
          hex: hexCode,
        );
      });
    } else {
      // Si no estamos moviendo ningún punto, actualizar la lupa
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
                  // Añadir instrucciones breves pero claras
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 8),
                    child: Text(
                      'Toca la imagen para seleccionar colores. La lupa muestra el color exacto bajo tu dedo.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
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
                                _magnifierMode = true;
                              }),
                        ),
                        _buildToolButton(
                          icon: Icons.pan_tool,
                          label: 'Move',
                          isActive: _currentMode == ToolMode.move,
                          onTap:
                              () => setState(() {
                                _currentMode = ToolMode.move;
                                _magnifierMode = false;
                              }),
                        ),
                        _buildToolButton(
                          icon: Icons.zoom_in,
                          label: 'Zoom In',
                          onTap: () {
                            final center = MediaQuery.of(
                              context,
                            ).size.center(Offset.zero);
                            _zoomToPoint(
                              center,
                              _transformationController.value
                                      .getMaxScaleOnAxis() *
                                  1.5,
                            );
                          },
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
                        onDoubleTapDown: _handleDoubleTap,
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
                                // Imagen ampliada con mejor cálculo de coordenadas
                                Builder(
                                  builder: (context) {
                                    // Calcular proporción entre imagen original y tamaño en pantalla
                                    RenderBox? box =
                                        _imageKey.currentContext
                                                ?.findRenderObject()
                                            as RenderBox?;
                                    if (box == null || _decodedImage == null) {
                                      return const SizedBox();
                                    }

                                    final displaySize = _getImageDisplaySize(
                                      box,
                                    );

                                    // Estos factores ayudan a posicionar correctamente la imagen en la lupa
                                    final factorX =
                                        _decodedImage!.width /
                                        displaySize.width;
                                    final factorY =
                                        _decodedImage!.height /
                                        displaySize.height;

                                    return Transform.scale(
                                      scale: _magnifierScale,
                                      alignment: Alignment.center,
                                      child: OverflowBox(
                                        maxWidth: double.infinity,
                                        maxHeight: double.infinity,
                                        child: Transform.translate(
                                          offset: Offset(
                                            -(_magnifierPoint!.x) *
                                                    _magnifierScale +
                                                _magnifierSize / 2,
                                            -(_magnifierPoint!.y) *
                                                    _magnifierScale +
                                                _magnifierSize / 2,
                                          ),
                                          child: Image.file(
                                            widget.imageFile,
                                            fit: BoxFit.none,
                                            width:
                                                displaySize.width *
                                                _magnifierScale,
                                            height:
                                                displaySize.height *
                                                _magnifierScale,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),

                                // Crosshair más preciso
                                Center(
                                  child: Container(
                                    width: 1,
                                    height: 10,
                                    color: Colors.red,
                                  ),
                                ),
                                Center(
                                  child: Container(
                                    width: 10,
                                    height: 1,
                                    color: Colors.red,
                                  ),
                                ),
                                // Círculo pequeño para punto exacto
                                Center(
                                  child: Container(
                                    width: 3,
                                    height: 3,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.red.withOpacity(0.5),
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 0.5,
                                      ),
                                    ),
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
                                      vertical: 4,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _magnifierPoint!.hex,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Container(
                                          height: 6,
                                          width: 24,
                                          margin: const EdgeInsets.only(top: 2),
                                          decoration: BoxDecoration(
                                            color: _magnifierPoint!.color,
                                            borderRadius: BorderRadius.circular(
                                              3,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Instrucciones según el modo activo - Mejora del panel de ayuda
                  Positioned(
                    left: 16,
                    bottom: 16,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.help_outline,
                                color: Colors.white,
                                size: 14,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Tips:',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          if (_currentMode == ToolMode.picker)
                            const Row(
                              children: [
                                Icon(
                                  Icons.touch_app,
                                  color: Colors.white,
                                  size: 12,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Toca para añadir color',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 2),
                          const Row(
                            children: [
                              Icon(Icons.pinch, color: Colors.white, size: 12),
                              SizedBox(width: 6),
                              Text(
                                'Pellizca para zoom',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          const Row(
                            children: [
                              Icon(
                                Icons.touch_app,
                                color: Colors.white,
                                size: 12,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Doble tap para zoom rápido',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          if (_currentMode == ToolMode.move)
                            const Row(
                              children: [
                                Icon(
                                  Icons.swipe,
                                  color: Colors.white,
                                  size: 12,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Arrastra para mover',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Indicador de nivel de zoom mejorado
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.zoom_in, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            '${_transformationController.value.getMaxScaleOnAxis().toStringAsFixed(1)}x',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
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
