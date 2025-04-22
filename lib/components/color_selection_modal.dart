import 'dart:io';
import 'dart:ui' as ui;
import 'dart:math'; // Importar para sqrt y pow
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
  double _magnificationFactor = 2.5;

  // Para el seguimiento preciso de los pixeles
  int _exactPixelX = 0;
  int _exactPixelY = 0;

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
      print('Error loading image: $e');
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

    // Convertir la posición local a posición relativa dentro del RenderBox
    final Offset position = box.globalToLocal(box.localToGlobal(localPosition));

    // Si la posición está fuera de los límites del box, retornar null
    if (!box.paintBounds.contains(position)) return null;

    // Obtener las dimensiones reales de la imagen visualizada (después del escalado del InteractiveViewer)
    final Rect displayRect = Rect.fromLTWH(
      0,
      0,
      box.size.width,
      box.size.height,
    );

    // Calcular la posición relativa en la imagen (0.0 - 1.0)
    final double relX = (position.dx - displayRect.left) / displayRect.width;
    final double relY = (position.dy - displayRect.top) / displayRect.height;

    // Convertir coordenadas relativas a las coordenadas absolutas de la imagen original
    // Considerar la transformación actual para el zoom y el desplazamiento
    final Matrix4 matrix = _transformationController.value;
    final Matrix4 inverseMatrix = Matrix4.inverted(matrix);
    final Vector3 untransformedPoint = inverseMatrix.transform3(
      Vector3(position.dx, position.dy, 0),
    );

    // Calcular las coordenadas exactas del pixel basadas en la posición transformada
    _exactPixelX =
        (untransformedPoint.x / box.size.width * _decodedImage!.width).round();
    _exactPixelY =
        (untransformedPoint.y / box.size.height * _decodedImage!.height)
            .round();

    // Verificar que las coordenadas estén dentro de los límites de la imagen
    if (_exactPixelX >= 0 &&
        _exactPixelX < _decodedImage!.width &&
        _exactPixelY >= 0 &&
        _exactPixelY < _decodedImage!.height) {
      print('Pixel seleccionado en: ($_exactPixelX, $_exactPixelY)');

      // Obtener el color del pixel
      final pixel = _decodedImage!.getPixel(_exactPixelX, _exactPixelY);
      return Color.fromARGB(
        255,
        pixel.r.toInt(),
        pixel.g.toInt(),
        pixel.b.toInt(),
      );
    }

    return null;
  }

  // Calcular exactamente dónde está el pixel
  Offset _calculateExactPixelPosition(Offset touchPosition) {
    if (_decodedImage == null) return touchPosition;

    // Obtener el RenderBox de la imagen
    RenderBox? box = _imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return touchPosition;

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
      Vector3(touchPosition.dx, touchPosition.dy, 0),
    );

    // Calcular y registrar las coordenadas exactas
    final int pixelX = (untransformedPosition.x * scaleX).round();
    final int pixelY = (untransformedPosition.y * scaleY).round();
    print('Exact coordinates: ($pixelX, $pixelY)');

    // Esta es la posición exacta del pixel en la imagen
    return Offset(untransformedPosition.x, untransformedPosition.y);
  }

  // Manejar el toque en la imagen
  void _handleImageTap(TapDownDetails details) {
    if (_isLoading || _decodedImage == null) return;

    print('Tap detected at: ${details.localPosition}');

    // Verificar primero si estamos tocando un punto existente
    _checkTapOnExistingPoint(details.localPosition);

    // Si hemos seleccionado un punto existente, no continuamos con la creación de uno nuevo
    if (_selectedPointIndex != null) {
      // Actualizar la lupa pero no crear un nuevo punto
      final Color? color = _getPixelColor(details.localPosition);
      if (color != null) {
        setState(() {
          _lastTapPosition = details.localPosition;
        });
        _updateMagnifier(details.localPosition);
      }
      return;
    }

    // Obtener el color del pixel (esto también guarda _exactPixelX y _exactPixelY)
    final Color? color = _getPixelColor(details.localPosition);
    if (color == null) {
      print(
        'No se pudo obtener el color en la posición: ${details.localPosition}',
      );
      return;
    }

    print(
      'Color obtained: ${color.toString()} in pixel ($_exactPixelX, $_exactPixelY)',
    );

    // Guardar la posición del toque
    setState(() {
      _lastTapPosition = details.localPosition;
    });

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
      // Crear el punto usando las coordenadas exactas del pixel
      final double pixelToImageX = _exactPixelX.toDouble();
      final double pixelToImageY = _exactPixelY.toDouble();

      print(
        'Adding point at pixel coordinates: ($_exactPixelX, $_exactPixelY)',
      );

      // Crear el punto
      final newPoint = ColorPoint(
        x: pixelToImageX,
        y: pixelToImageY,
        color: color,
        hex: hexCode,
        pixelX: _exactPixelX,
        pixelY: _exactPixelY,
      );

      // Añadir a la lista
      setState(() {
        _points.add(newPoint);
      });

      // Notificar al padre
      widget.onPointsUpdated(_points);
    }

    // Actualizar la posición de la lupa
    _updateMagnifier(details.localPosition);
  }

  // Verificar si tocamos un punto existente
  void _checkTapOnExistingPoint(Offset touchPosition) {
    RenderBox? box = _imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;

    // Obtener el pixel exacto donde tocamos
    final Color? color = _getPixelColor(touchPosition);
    if (color == null) return;

    // Ahora tenemos _exactPixelX y _exactPixelY con las coordenadas exactas del pixel

    // Aumentar el radio de detección para facilitar la selección
    final double detectionRadius =
        10.0; // Aumentado para hacer más fácil seleccionar puntos existentes

    // Verificar cada punto
    for (int i = 0; i < _points.length; i++) {
      final point = _points[i];

      // Comparar las coordenadas de pixel (más preciso)
      final distance = sqrt(
        pow(point.pixelX - _exactPixelX, 2) +
            pow(point.pixelY - _exactPixelY, 2),
      );

      // Si estamos cerca del punto, seleccionarlo
      if (distance < detectionRadius) {
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

    // Color bajo el toque (esto actualiza _exactPixelX y _exactPixelY)
    final Color? color = _getPixelColor(touchPosition);
    if (color == null) return;

    // Posicionar la lupa en la esquina superior
    final screenSize = MediaQuery.of(context).size;
    final lupaPosition = Offset(
      screenSize.width - _magnifierSize / 2 - 20,
      _magnifierSize / 2 + 20,
    );

    // Actualizar el estado con las coordenadas precisas
    setState(() {
      _magnifierPosition = lupaPosition;
      _lastTapPosition = touchPosition;
      _selectedColor = color;
      _selectedHex =
          '#${color.value.toRadixString(16).substring(2).padLeft(6, '0').toUpperCase()}';
    });
  }

  // Manejar el arrastre
  void _handlePanStart(DragStartDetails details) {
    _isDragging = true;

    // Verificar primero si estamos tocando un punto existente
    _checkTapOnExistingPoint(details.localPosition);

    // Si estamos moviendo un punto existente, solo configuramos el estado para el arrastre
    if (_isMovingExistingPoint && _selectedPointIndex != null) {
      // No necesitamos hacer nada más, ya tenemos el punto seleccionado
      return;
    }

    // Si no estamos moviendo un punto existente, simular un toque inicial para crear uno nuevo
    _handleImageTap(
      TapDownDetails(
        globalPosition: details.globalPosition,
        localPosition: details.localPosition,
      ),
    );
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;

    // Actualizar la posición
    setState(() {
      _lastTapPosition = details.localPosition;
    });

    // Si estamos moviendo un punto existente
    if (_isMovingExistingPoint && _selectedPointIndex != null) {
      // Obtener el color del pixel (actualiza _exactPixelX y _exactPixelY)
      final Color? color = _getPixelColor(details.localPosition);
      if (color != null) {
        final String hexCode =
            '#${color.value.toRadixString(16).substring(2).padLeft(6, '0').toUpperCase()}';

        // Actualizar el punto existente con las coordenadas exactas de pixel
        setState(() {
          _points[_selectedPointIndex!] = ColorPoint(
            x: _exactPixelX.toDouble(),
            y: _exactPixelY.toDouble(),
            color: color,
            hex: hexCode,
            pixelX: _exactPixelX,
            pixelY: _exactPixelY,
          );
          _selectedColor = color;
          _selectedHex = hexCode;
        });
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

      // No borrar completamente la selección para permitir continuar el desplazamiento
      setState(() {
        _isDragging = false;
        _isMovingExistingPoint = false;
        // Mantenemos _selectedPointIndex para recordar cuál fue el último punto seleccionado
      });
    }
    // Si no estamos moviendo un punto existente, añadir uno nuevo
    else if (_isDragging && _selectedColor != Colors.transparent) {
      // Crear el punto usando las coordenadas exactas de pixel
      final newPoint = ColorPoint(
        x: _exactPixelX.toDouble(),
        y: _exactPixelY.toDouble(),
        color: _selectedColor,
        hex: _selectedHex,
        pixelX: _exactPixelX,
        pixelY: _exactPixelY,
      );

      // Añadir a la lista
      setState(() {
        _points.add(newPoint);
        _selectedPointIndex = _points.length - 1;
      });

      // Notificar al padre
      widget.onPointsUpdated(_points);

      // Resetear solo el estado de arrastre pero mantener la selección
      setState(() {
        _isDragging = false;
        _isMovingExistingPoint = false;
        // No reseteamos _lastTapPosition ni _selectedPointIndex para permitir continuar
      });
    } else {
      // Si simplemente tocamos sin hacer nada específico
      setState(() {
        _isDragging = false;
        _isMovingExistingPoint = false;
        _lastTapPosition = null;
        // Podemos dejar _selectedPointIndex para recordar el último punto seleccionado
      });
    }
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
      height: MediaQuery.of(context).size.height * 0.95,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Cabecera simplificada
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Color Selector',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.close),
                    label: const Text('Close'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Área de la imagen (ahora sin barra de herramientas)
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
                          panEnabled: true,
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

                                // Convertir las coordenadas de pixel a las de pantalla considerando el zoom
                                RenderBox? box =
                                    _imageKey.currentContext?.findRenderObject()
                                        as RenderBox?;
                                if (box == null) {
                                  return Container(); // Si no hay context, devolver un widget vacío
                                }

                                // Calcular la relación entre la imagen y la pantalla
                                final double scaleX =
                                    box.size.width / _imageSize.width;
                                final double scaleY =
                                    box.size.height / _imageSize.height;

                                // Calcular la posición exacta en la pantalla considerando la transformación
                                // Esto garantiza que los puntos se posicionen correctamente incluso con zoom
                                final Matrix4 transform =
                                    _transformationController.value;
                                final Vector3 position = transform.transform3(
                                  Vector3(
                                    point.pixelX.toDouble() *
                                        (box.size.width / _decodedImage!.width),
                                    point.pixelY.toDouble() *
                                        (box.size.height /
                                            _decodedImage!.height),
                                    0,
                                  ),
                                );

                                // Tamaño del punto para centrarlo correctamente
                                final bool isPointSelected =
                                    _selectedPointIndex == index;
                                final double pointSize =
                                    isPointSelected ? 30.0 : 24.0;

                                return Positioned(
                                  left:
                                      position.x -
                                      (pointSize / 2), // Centrado exacto
                                  top:
                                      position.y -
                                      (pointSize / 2), // Centrado exacto
                                  child: GestureDetector(
                                    onTap: () {
                                      // Al tocar un punto, lo seleccionamos para poder moverlo después
                                      setState(() {
                                        _selectedPointIndex = index;
                                        _selectedColor = point.color;
                                        _selectedHex = point.hex;
                                      });
                                    },
                                    onPanStart: (details) {
                                      // Activar el modo de movimiento al arrastrar un punto
                                      setState(() {
                                        _selectedPointIndex = index;
                                        _isMovingExistingPoint = true;
                                        _isDragging = true;
                                        _selectedColor = point.color;
                                        _selectedHex = point.hex;
                                      });
                                    },
                                    onPanUpdate: (details) {
                                      if (_selectedPointIndex != index) return;

                                      // Actualizar posición mientras arrastramos
                                      RenderBox? box =
                                          _imageKey.currentContext
                                                  ?.findRenderObject()
                                              as RenderBox?;
                                      if (box != null) {
                                        // Convertir la posición global a local
                                        final Offset localPosition = box
                                            .globalToLocal(
                                              details.globalPosition,
                                            );

                                        _handlePanUpdate(
                                          DragUpdateDetails(
                                            globalPosition:
                                                details.globalPosition,
                                            localPosition: localPosition,
                                            delta: details.delta,
                                          ),
                                        );
                                      }
                                    },
                                    onPanEnd: _handlePanEnd,
                                    child: _buildColorPoint(point, index),
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
                      left: _lastTapPosition!.dx - 5, // Exactamente 5px
                      top: _lastTapPosition!.dy - 5, // Exactamente 5px
                      child: Container(
                        width: 10, // 10px total (5px de radio)
                        height: 10, // 10px total (5px de radio)
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.red, width: 1.5),
                        ),
                        child: Center(
                          child: Container(
                            width:
                                2, // Punto central mínimo para precisión exacta
                            height: 2,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Lupa en esquina superior
                  if (_showMagnifier &&
                      _magnifierPosition != null &&
                      _selectedColor != Colors.transparent)
                    Positioned(
                      left: _magnifierPosition!.dx - _magnifierSize / 2,
                      top: 20,
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
                            // Color magnificado
                            ClipOval(
                              child: CustomPaint(
                                painter: MagnifierPainter(
                                  image: _decodedImage,
                                  pixelX: _exactPixelX,
                                  pixelY: _exactPixelY,
                                  zoom: _magnificationFactor,
                                  color: _selectedColor,
                                ),
                                size: Size(_magnifierSize, _magnifierSize),
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

                            // Círculo indicador
                            Center(
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color:
                                        _isLightColor(_selectedColor)
                                            ? Colors.black
                                            : Colors.white,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),

                            // Información del color y coordenadas
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
                                    const SizedBox(height: 2),
                                    Text(
                                      'x: $_exactPixelX, y: $_exactPixelY',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
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
                      tooltip:
                          _showMagnifier ? 'Hide Magnifier' : 'Show Magnifier',
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
                        'Selected Colors (${_points.length})',
                        style: const TextStyle(fontWeight: FontWeight.bold),
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
                                'No colors selected yet',
                                style: TextStyle(fontStyle: FontStyle.italic),
                              ),
                            )
                            : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _points.length,
                              itemBuilder: (context, index) {
                                final point = _points[index];
                                final bool isSelected =
                                    _selectedPointIndex == index;

                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedPointIndex = index;
                                      _selectedColor = point.color;
                                      _selectedHex = point.hex;
                                    });
                                  },
                                  child: Container(
                                    width: 60,
                                    height: 60,
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      color: point.color,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color:
                                            isSelected
                                                ? Colors.yellow.withOpacity(0.8)
                                                : (isDarkMode
                                                    ? Colors.grey[700]!
                                                    : Colors.grey[300]!),
                                        width: isSelected ? 2.5 : 1.0,
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
                                                // Si estamos eliminando el punto seleccionado, limpiamos la selección
                                                if (_selectedPointIndex ==
                                                    index) {
                                                  _selectedPointIndex = null;
                                                }
                                                // Si eliminamos un punto con índice menor al seleccionado, ajustamos el índice
                                                else if (_selectedPointIndex !=
                                                        null &&
                                                    _selectedPointIndex! >
                                                        index) {
                                                  _selectedPointIndex =
                                                      _selectedPointIndex! - 1;
                                                }

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
                                  ),
                                );
                              },
                            ),
                  ),

                  // Botón de Apply a ancho completo
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
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
                      child: const Text(
                        'Apply',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

  Widget _buildColorPoint(ColorPoint point, int index) {
    final bool isSelected = _selectedPointIndex == index;
    final double size =
        isSelected
            ? 30.0
            : 24.0; // Puntos más grandes para facilitar su selección
    final double borderWidth = isSelected ? 2.5 : 1.5;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: point.color.withOpacity(0.8),
        shape: BoxShape.circle,
        border: Border.all(
          color:
              isSelected
                  ? Colors.yellow
                  : (_isLightColor(point.color) ? Colors.black : Colors.white),
          width: borderWidth,
        ),
        boxShadow:
            isSelected
                ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 3,
                    spreadRadius: 1,
                  ),
                ]
                : null,
      ),
      child: Center(
        child: Text(
          '${index + 1}',
          style: TextStyle(
            color: _isLightColor(point.color) ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize:
                isSelected ? 14 : 12, // Texto más grande para mejor visibilidad
          ),
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
  final int pixelX; // Añadido para guardar la coordenada exacta del pixel
  final int pixelY;

  ColorPoint({
    required this.x,
    required this.y,
    required this.color,
    required this.hex,
    this.pixelX = 0, // Valor por defecto para compatibilidad
    this.pixelY = 0,
  });
}

// Añadir esta clase para la visualización en la lupa
class MagnifierPainter extends CustomPainter {
  final img.Image? image;
  final int pixelX;
  final int pixelY;
  final double zoom;
  final Color color;

  MagnifierPainter({
    this.image,
    required this.pixelX,
    required this.pixelY,
    required this.zoom,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (image == null) {
      // Si no hay imagen, simplemente muestra el color seleccionado
      final paint = Paint()..color = color;
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
      return;
    }

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Primero dibujar el fondo
    final backgroundPaint = Paint()..color = Colors.grey.withOpacity(0.3);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      backgroundPaint,
    );

    // Dibujar los píxeles ampliados alrededor del punto seleccionado
    final pixelSize = zoom * 5.0; // Tamaño de cada pixel en la lupa
    final pixelsToShow = (size.width / pixelSize).floor() / 2;

    for (int y = -pixelsToShow.floor(); y <= pixelsToShow.floor(); y++) {
      for (int x = -pixelsToShow.floor(); x <= pixelsToShow.floor(); x++) {
        final currentPixelX = pixelX + x;
        final currentPixelY = pixelY + y;

        // Verificar que estemos dentro de los límites de la imagen
        if (currentPixelX >= 0 &&
            currentPixelX < image!.width &&
            currentPixelY >= 0 &&
            currentPixelY < image!.height) {
          // Obtener el color del pixel actual
          final pixel = image!.getPixel(currentPixelX, currentPixelY);
          final pixelColor = Color.fromARGB(
            255,
            pixel.r.toInt(),
            pixel.g.toInt(),
            pixel.b.toInt(),
          );

          // Dibujar el pixel ampliado
          final pixelPaint = Paint()..color = pixelColor;
          final pixelRect = Rect.fromLTWH(
            centerX + (x * pixelSize) - pixelSize / 2,
            centerY + (y * pixelSize) - pixelSize / 2,
            pixelSize,
            pixelSize,
          );

          canvas.drawRect(pixelRect, pixelPaint);

          // Dibujar el borde del pixel
          final borderPaint =
              Paint()
                ..color = Colors.black.withOpacity(0.3)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 0.5;
          canvas.drawRect(pixelRect, borderPaint);
        }
      }
    }

    // Destacar el pixel central (seleccionado)
    final selectedPixelRect = Rect.fromLTWH(
      centerX - pixelSize / 2,
      centerY - pixelSize / 2,
      pixelSize,
      pixelSize,
    );

    // Borde del pixel seleccionado - más destacado
    final selectedBorderPaint =
        Paint()
          ..color = Colors.red
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
    canvas.drawRect(selectedPixelRect, selectedBorderPaint);

    // Dibujar un punto en el centro exacto del píxel para mayor precisión
    final centerPoint = Paint()..color = Colors.red;
    canvas.drawCircle(Offset(centerX, centerY), 2.0, centerPoint);
  }

  @override
  bool shouldRepaint(MagnifierPainter oldDelegate) {
    return oldDelegate.pixelX != pixelX ||
        oldDelegate.pixelY != pixelY ||
        oldDelegate.zoom != zoom ||
        oldDelegate.color != color;
  }
}
