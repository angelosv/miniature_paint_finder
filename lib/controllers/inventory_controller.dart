import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/models/paint.dart';
import 'package:miniature_paint_finder/repositories/paint_repository.dart';

/// Representa un elemento de inventario con cantidad y notas
class InventoryItem {
  /// ID de la pintura
  final String paintId;

  /// Cantidad en inventario
  int quantity;

  /// Notas opcionales sobre el item
  String? notes;

  /// Fecha de la última actualización
  DateTime updatedAt;

  /// Constructor para un item de inventario
  InventoryItem({
    required this.paintId,
    this.quantity = 1,
    this.notes,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  /// Crear un item desde un mapa JSON
  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      paintId: json['paintId'],
      quantity: json['quantity'] ?? 1,
      notes: json['notes'],
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  /// Convertir a un mapa JSON
  Map<String, dynamic> toJson() {
    return {
      'paintId': paintId,
      'quantity': quantity,
      'notes': notes,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Crear una copia con valores actualizados
  InventoryItem copyWith({int? quantity, String? notes}) {
    return InventoryItem(
      paintId: this.paintId,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
      updatedAt: DateTime.now(),
    );
  }
}

/// Controlador para gestionar el inventario de pinturas del usuario
class InventoryController extends ChangeNotifier {
  /// Repositorio para acceder a datos de pinturas
  final PaintRepository _paintRepository;

  /// Mapa de items en el inventario, con paintId como clave
  final Map<String, InventoryItem> _inventory = {};

  /// Estado de la carga
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';

  /// Constructor que recibe el repositorio
  InventoryController(this._paintRepository);

  /// Getters para acceder a los datos desde la UI
  Map<String, InventoryItem> get inventory => _inventory;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;

  /// Verificar si una pintura está en el inventario
  bool isPaintInInventory(String paintId) => _inventory.containsKey(paintId);

  /// Obtener un item del inventario por ID de pintura
  InventoryItem? getInventoryItem(String paintId) => _inventory[paintId];

  /// Obtener la cantidad de un item en el inventario
  int getQuantity(String paintId) => _inventory[paintId]?.quantity ?? 0;

  /// Añadir o actualizar un item en el inventario
  void addToInventory(String paintId, {int quantity = 1, String? notes}) {
    if (_inventory.containsKey(paintId)) {
      // Actualizar item existente
      final item = _inventory[paintId]!;
      _inventory[paintId] = item.copyWith(
        quantity: item.quantity + quantity,
        notes: notes ?? item.notes,
      );
    } else {
      // Crear nuevo item
      _inventory[paintId] = InventoryItem(
        paintId: paintId,
        quantity: quantity,
        notes: notes,
      );
    }

    notifyListeners();
    _saveInventory();
  }

  /// Actualizar la cantidad de un item
  void updateQuantity(String paintId, int quantity) {
    if (quantity <= 0) {
      // Si la cantidad es 0 o menos, eliminar del inventario
      removeFromInventory(paintId);
      return;
    }

    if (_inventory.containsKey(paintId)) {
      final item = _inventory[paintId]!;
      _inventory[paintId] = item.copyWith(quantity: quantity);

      notifyListeners();
      _saveInventory();
    }
  }

  /// Actualizar las notas de un item
  void updateNotes(String paintId, String? notes) {
    if (_inventory.containsKey(paintId)) {
      final item = _inventory[paintId]!;
      _inventory[paintId] = item.copyWith(notes: notes);

      notifyListeners();
      _saveInventory();
    }
  }

  /// Eliminar un item del inventario
  void removeFromInventory(String paintId) {
    if (_inventory.containsKey(paintId)) {
      _inventory.remove(paintId);

      notifyListeners();
      _saveInventory();
    }
  }

  /// Obtener pinturas completas para los items del inventario
  Future<List<Paint>> getInventoryPaints() async {
    _isLoading = true;
    notifyListeners();

    try {
      final List<Paint> paints = [];

      for (final paintId in _inventory.keys) {
        final paint = await _paintRepository.getById(paintId);
        if (paint != null) {
          paints.add(paint);
        }
      }

      return paints;
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Error al cargar pinturas del inventario: $e';
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cargar el inventario guardado
  Future<void> _loadInventory() async {
    // En una implementación real, cargaríamos desde almacenamiento local o API
    // Por ahora, inicializamos datos de ejemplo
    _inventory.clear();

    _inventory['cit-base-001'] = InventoryItem(
      paintId: 'cit-base-001',
      quantity: 1,
      notes: 'Casi vacío, comprar nuevo',
    );

    _inventory['val-model-003'] = InventoryItem(
      paintId: 'val-model-003',
      quantity: 2,
    );

    notifyListeners();
  }

  /// Guardar el inventario
  Future<void> _saveInventory() async {
    // En una implementación real, guardaríamos en almacenamiento local o API
    // Por ahora no hacemos nada
  }

  /// Inicializar el controlador
  void init() {
    _loadInventory();
  }

  @override
  void dispose() {
    _saveInventory();
    super.dispose();
  }
}
