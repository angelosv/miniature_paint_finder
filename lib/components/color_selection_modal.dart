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
  // Controlador para el zoom y transformación
  final TransformationController _transformationController =
      TransformationController();

  // Clave para obtener el tamaño y posición de la imagen
  final GlobalKey _imageKey = GlobalKey();

  // Datos de la imagen
  img.Image? _decodedImage;
  Size _imageSize = Size.zero;

  // Lista de puntos seleccionados
  List<ColorPoint> _points = [];

  // Estado del selector
  bool _isLoading = true;
  ToolMode _currentMode = ToolMode.picker;

  // Para mostrar el marcador de selección
  Offset? _lastTapPosition;
  Color _selectedColor = Colors.transparent;
  String _selectedHex = '';
  bool _isDragging = false;

  // Variables para la lupa
  bool _showMagnifier = true;
  Offset? _magnifierPosition;
  double _magnifierSize = 120.0;

  // Para mover los puntos existentes
  int? _selectedPointIndex;
  bool _isMovingExistingPoint = false;

  @override
  void initState() {
    super.initState();
    _points = List.from(widget.selectedPoints);
    _loadImage();
  }

  // Cargar la imagen
  Future<void> _loadImage() async {
    setState(() => _isLoading = true);

    try {
      // Leer y decodificar la imagen
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
      print('Error cargando imagen: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Obtener color de un pixel de la imagen
  Color? _getPixelColor(Offset localPosition) {
    if (_decodedImage == null) return null;

    // Obtener el RenderBox de la imagen
    RenderBox? box = _imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return null;

    // Obtener tamaño real de la imagen mostrada
    final boxSize = box.size;

    // Calcular la relación entre el tamaño de la imagen original y la mostrada
    final double scaleX = _decodedImage!.width / boxSize.width;
    final double scaleY = _decodedImage!.height / boxSize.height;

    // Convertir coordenadas considerando el zoom actual
    final Matrix4 inverseMatrix = Matrix4.inverted(
      _transformationController.value,
    );
    final Vector3 untransformedPosition = inverseMatrix.transform3(
      Vector3(localPosition.dx, localPosition.dy, 0),
    );

    // Calcular el pixel correspondiente en la imagen original
    final int pixelX = (untransformedPosition.x * scaleX).round();
    final int pixelY = (untransformedPosition.y * scaleY).round();

    // Verificar que las coordenadas estén dentro de la imagen
    if (pixelX >= 0 &&
        pixelX < _decodedImage!.width &&
        pixelY >= 0 &&
        pixelY < _decodedImage!.height) {
      // Obtener el color del pixel
      final pixel = _decodedImage!.getPixel(pixelX, pixelY);
      return Color.fromARGB(
        255,
        pixel.r.toInt(),
        pixel.g.toInt(),
        pixel.b.toInt(),
      );
    }

    return null;
  }

  // Manejar el toque en la imagen
  void _handleImageTap(TapDownDetails details) {
    if (_isLoading || _decodedImage == null) return;
    if (_currentMode != ToolMode.picker) return;

    // Guardar la posición del toque
    setState(() {
      _lastTapPosition = details.localPosition;
    });

    // Verificar si estamos tocando un punto existente para moverlo
    _checkTapOnExistingPoint(details.localPosition);

    if (_selectedPointIndex != null) {
      // Ya tenemos un punto seleccionado, no continuamos
      return;
    }

    // Obtener el color del pixel
    final Color? color = _getPixelColor(details.localPosition);
    if (color == null) return;

    // Convertir a hexadecimal
    final String hexCode =
        '#${color.value.toRadixString(16).substring(2).padLeft(6, '0').toUpperCase()}';

    // Actualizar el estado
    setState(() {
      _selectedColor = color;
      _selectedHex = hexCode;
    });

    // Si no estamos arrastrando, añadir el punto
    if (!_isDragging) {
      // Calcular coordenadas originales para guardar
      RenderBox? box =
          _imageKey.currentContext?.findRenderObject() as RenderBox?;
      if (box != null) {
        final boxSize = box.size;
        final Matrix4 inverseMatrix = Matrix4.inverted(
          _transformationController.value,
        );
        final Vector3 untransformedPosition = inverseMatrix.transform3(
          Vector3(details.localPosition.dx, details.localPosition.dy, 0),
        );

        // Calcular la posición relativa (0-1) y luego convertir a coordenadas absolutas
        final double relativeX = untransformedPosition.x / boxSize.width;
        final double relativeY = untransformedPosition.y / boxSize.height;

        final double imageX = relativeX * _imageSize.width;
        final double imageY = relativeY * _imageSize.height;

        // Crear el punto
        final newPoint = ColorPoint(
          x: imageX,
          y: imageY,
          color: color,
          hex: hexCode,
        );

        // Añadir a la lista
        setState(() {
          _points.add(newPoint);
        });

        // Notificar al padre
        widget.onPointsUpdated(_points);
      }
    }

    // Actualizar la posición de la lupa
    _updateMagnifier(details.localPosition);
  }

  // Verificar si tocamos un punto existente
  void _checkTapOnExistingPoint(Offset touchPosition) {
    RenderBox? box = _imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;

    // Convertir coordenadas considerando zoom
    final Matrix4 inverseMatrix = Matrix4.inverted(
      _transformationController.value,
    );
    final Vector3 untransformedPosition = inverseMatrix.transform3(
      Vector3(touchPosition.dx, touchPosition.dy, 0),
    );

    // Verificar cada punto
    for (int i = 0; i < _points.length; i++) {
      final point = _points[i];

      // Convertir coordenadas del punto al espacio de la pantalla
      final double screenX = (point.x / _imageSize.width) * box.size.width;
      final double screenY = (point.y / _imageSize.height) * box.size.height;

      // Calcular distancia entre el toque y el punto
      final distance =
          (Offset(screenX, screenY) -
                  Offset(untransformedPosition.x, untransformedPosition.y))
              .distance;

      // Si estamos cerca del punto (ajustar este valor según necesidad)
      if (distance < 20) {
        setState(() {
          _selectedPointIndex = i;
          _isMovingExistingPoint = true;
          _selectedColor = point.color;
          _selectedHex = point.hex;
        });
        return;
      }
    }

    // No se encontró ningún punto bajo el toque
    setState(() {
      _selectedPointIndex = null;
      _isMovingExistingPoint = false;
    });
  }

  // Actualizar la lupa
  void _updateMagnifier(Offset touchPosition) {
    if (!_showMagnifier) return;

    // Color bajo el toque
    final Color? color = _getPixelColor(touchPosition);
    if (color == null) return;

    // Posicionar la lupa en la esquina superior derecha
    final screenSize = MediaQuery.of(context).size;
    final lupaPosition = Offset(
      screenSize.width - _magnifierSize / 2 - 20,
      _magnifierSize / 2 + 20,
    );

    setState(() {
      _magnifierPosition = lupaPosition;
      _selectedColor = color;
      _selectedHex =
          '#${color.value.toRadixString(16).substring(2).padLeft(6, '0').toUpperCase()}';
    });
  }

  // Manejar el arrastre
  void _handlePanStart(DragStartDetails details) {
    _isDragging = true;

    // Verificar si tocamos un punto existente
    _checkTapOnExistingPoint(details.localPosition);

    // Si no estamos moviendo un punto existente, simular un toque inicial
    if (!_isMovingExistingPoint) {
      _handleImageTap(
        TapDownDetails(
          globalPosition: details.globalPosition,
          localPosition: details.localPosition,
        ),
      );
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;

    // Actualizar la posición
    setState(() {
      _lastTapPosition = details.localPosition;
    });

    // Si estamos moviendo un punto existente
    if (_isMovingExistingPoint && _selectedPointIndex != null) {
      // Calcular nuevas coordenadas
      RenderBox? box =
          _imageKey.currentContext?.findRenderObject() as RenderBox?;
      if (box != null) {
        final boxSize = box.size;
        final Matrix4 inverseMatrix = Matrix4.inverted(
          _transformationController.value,
        );
        final Vector3 untransformedPosition = inverseMatrix.transform3(
          Vector3(details.localPosition.dx, details.localPosition.dy, 0),
        );

        // Calcular la posición relativa y convertir a coordenadas absolutas
        final double relativeX = untransformedPosition.x / boxSize.width;
        final double relativeY = untransformedPosition.y / boxSize.height;

        final double imageX = relativeX * _imageSize.width;
        final double imageY = relativeY * _imageSize.height;

        // Obtener el color del pixel
        final Color? color = _getPixelColor(details.localPosition);
        if (color != null) {
          final String hexCode =
              '#${color.value.toRadixString(16).substring(2).padLeft(6, '0').toUpperCase()}';

          // Actualizar el punto existente
          setState(() {
            _points[_selectedPointIndex!] = ColorPoint(
              x: imageX,
              y: imageY,
              color: color,
              hex: hexCode,
            );
            _selectedColor = color;
            _selectedHex = hexCode;
          });
        }
      }
    } else {
      // Obtener el color del pixel si no estamos moviendo un punto
      final Color? color = _getPixelColor(details.localPosition);
      if (color != null) {
        setState(() {
          _selectedColor = color;
          _selectedHex =
              '#${color.value.toRadixString(16).substring(2).padLeft(6, '0').toUpperCase()}';
        });
      }
    }

    // Actualizar la lupa
    _updateMagnifier(details.localPosition);
  }

  void _handlePanEnd(DragEndDetails details) {
    // Si estábamos moviendo un punto existente, notificar cambios
    if (_isMovingExistingPoint && _selectedPointIndex != null) {
      widget.onPointsUpdated(_points);
    }
    // Si no estamos moviendo un punto existente, añadir uno nuevo
    else if (_isDragging && _selectedColor != Colors.transparent) {
      // Calcular coordenadas originales para guardar
      RenderBox? box =
          _imageKey.currentContext?.findRenderObject() as RenderBox?;
      if (box != null && _lastTapPosition != null) {
        final boxSize = box.size;
        final Matrix4 inverseMatrix = Matrix4.inverted(
          _transformationController.value,
        );
        final Vector3 untransformedPosition = inverseMatrix.transform3(
          Vector3(_lastTapPosition!.dx, _lastTapPosition!.dy, 0),
        );

        // Calcular la posición relativa (0-1) y luego convertir a coordenadas absolutas
        final double relativeX = untransformedPosition.x / boxSize.width;
        final double relativeY = untransformedPosition.y / boxSize.height;

        final double imageX = relativeX * _imageSize.width;
        final double imageY = relativeY * _imageSize.height;

        // Crear el punto
        final newPoint = ColorPoint(
          x: imageX,
          y: imageY,
          color: _selectedColor,
          hex: _selectedHex,
        );

        // Añadir a la lista
        setState(() {
          _points.add(newPoint);
        });

        // Notificar al padre
        widget.onPointsUpdated(_points);
      }
    }

    // Resetear el estado
    setState(() {
      _isDragging = false;
      _isMovingExistingPoint = false;
      _selectedPointIndex = null;
      _lastTapPosition = null;
    });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
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
            // Cabecera
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Selector de Color',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.close),
                    label: const Text('Cerrar'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Barra de herramientas
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  _buildToolButton(
                    icon: Icons.colorize,
                    label: 'Seleccionar Color',
                    isActive: _currentMode == ToolMode.picker,
                    onTap: () => setState(() => _currentMode = ToolMode.picker),
                  ),
                  const SizedBox(width: 8),
                  _buildToolButton(
                    icon: Icons.pan_tool,
                    label: 'Mover',
                    isActive: _currentMode == ToolMode.move,
                    onTap: () => setState(() => _currentMode = ToolMode.move),
                  ),
                  const SizedBox(width: 8),
                  _buildToolButton(
                    icon: Icons.restart_alt,
                    label: 'Resetear',
                    onTap:
                        () => setState(
                          () =>
                              _transformationController.value =
                                  Matrix4.identity(),
                        ),
                  ),
                ],
              ),
            ),

            // Área de la imagen
            Expanded(
              child: Stack(
                children: [
                  // Imagen con gestos
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : GestureDetector(
                        onTapDown: _handleImageTap,
                        onPanStart: _handlePanStart,
                        onPanUpdate: _handlePanUpdate,
                        onPanEnd: _handlePanEnd,
                        child: InteractiveViewer(
                          transformationController: _transformationController,
                          minScale: 0.5,
                          maxScale: 5.0,
                          panEnabled: _currentMode == ToolMode.move,
                          scaleEnabled: true,
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

                                // Calcular posición relativa para mostrar en la UI
                                final relativeX = point.x / _imageSize.width;
                                final relativeY = point.y / _imageSize.height;

                                return Positioned(
                                  left:
                                      relativeX *
                                          MediaQuery.of(context).size.width -
                                      15,
                                  top:
                                      relativeY *
                                          MediaQuery.of(context).size.height -
                                      15,
                                  child: Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: point.color.withOpacity(0.8),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color:
                                            _isLightColor(point.color)
                                                ? Colors.black
                                                : Colors.white,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          color:
                                              _isLightColor(point.color)
                                                  ? Colors.black
                                                  : Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
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

                  // Indicador de selección
                  if (_lastTapPosition != null)
                    Positioned(
                      left: _lastTapPosition!.dx - 15,
                      top: _lastTapPosition!.dy - 15,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.red, width: 2),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: _selectedColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Lupa en esquina
                  if (_showMagnifier &&
                      _magnifierPosition != null &&
                      _selectedColor != Colors.transparent)
                    Positioned(
                      left: _magnifierPosition!.dx - _magnifierSize / 2,
                      top: _magnifierPosition!.dy - _magnifierSize / 2,
                      child: Container(
                        width: _magnifierSize,
                        height: _magnifierSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                            color: Colors.grey[400]!,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // Color sólido
                            ClipOval(
                              child: Container(
                                width: _magnifierSize,
                                height: _magnifierSize,
                                color: _selectedColor,
                              ),
                            ),

                            // Cruz central
                            Center(
                              child: Container(
                                width: 20,
                                height: 2,
                                color:
                                    _isLightColor(_selectedColor)
                                        ? Colors.black
                                        : Colors.white,
                              ),
                            ),
                            Center(
                              child: Container(
                                width: 2,
                                height: 20,
                                color:
                                    _isLightColor(_selectedColor)
                                        ? Colors.black
                                        : Colors.white,
                              ),
                            ),

                            // Información del color
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                color: Colors.black.withOpacity(0.7),
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _selectedHex,
                                      textAlign: TextAlign.center,
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
                    ),

                  // Toggle para la lupa
                  Positioned(
                    top: 16,
                    right: 16,
                    child: IconButton(
                      icon: Icon(
                        _showMagnifier
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed:
                          () =>
                              setState(() => _showMagnifier = !_showMagnifier),
                      tooltip: _showMagnifier ? 'Ocultar lupa' : 'Mostrar lupa',
                      color: Colors.black.withOpacity(0.5),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Barra inferior con colores seleccionados
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[850] : Colors.grey[100],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Colores Seleccionados (${_points.length})',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          widget.onPointsUpdated(_points);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Aplicar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 70,
                    child:
                        _points.isEmpty
                            ? const Center(
                              child: Text(
                                'Aún no hay colores seleccionados',
                                style: TextStyle(fontStyle: FontStyle.italic),
                              ),
                            )
                            : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _points.length,
                              itemBuilder: (context, index) {
                                final point = _points[index];
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
                                      Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          color:
                                              _isLightColor(point.color)
                                                  ? Colors.black
                                                  : Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Positioned(
                                        top: 2,
                                        right: 2,
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _points.removeAt(index);
                                              widget.onPointsUpdated(_points);
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                              color:
                                                  _isLightColor(point.color)
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
                                                  _isLightColor(point.color)
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.marineBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
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

  bool _isLightColor(Color color) {
    return (0.299 * color.red + 0.587 * color.green + 0.114 * color.blue) /
            255 >
        0.5;
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
