import 'package:flutter/material.dart';

/// Componente para mostrar y controlar la paginación
class PaginationControls extends StatelessWidget {
  /// Página actual
  final int currentPage;

  /// Número total de páginas
  final int totalPages;

  /// Función a llamar cuando cambia la página
  final Function(int) onPageChanged;

  /// Constructor del componente de paginación
  const PaginationControls({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Si solo hay una página, no mostramos los controles
    if (totalPages <= 1) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Botón para ir a la primera página
          IconButton(
            icon: const Icon(Icons.first_page),
            onPressed: currentPage > 1 ? () => onPageChanged(1) : null,
            tooltip: 'First Page',
          ),

          // Botón para ir a la página anterior
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed:
                currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
            tooltip: 'Previous Page',
          ),

          const SizedBox(width: 8),

          // Muestra la página actual y el total
          Text(
            'Page $currentPage of $totalPages',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),

          const SizedBox(width: 8),

          // Botón para ir a la página siguiente
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed:
                currentPage < totalPages
                    ? () => onPageChanged(currentPage + 1)
                    : null,
            tooltip: 'Next Page',
          ),

          // Botón para ir a la última página
          IconButton(
            icon: const Icon(Icons.last_page),
            onPressed:
                currentPage < totalPages
                    ? () => onPageChanged(totalPages)
                    : null,
            tooltip: 'Last Page',
          ),
        ],
      ),
    );
  }
}

/// Selector de tamaño de página
class PageSizeSelector extends StatelessWidget {
  /// Opciones de tamaño de página
  final List<int> pageSizeOptions;

  /// Tamaño de página actual
  final int currentPageSize;

  /// Función a llamar cuando cambia el tamaño de página
  final Function(int) onPageSizeChanged;

  /// Constructor del selector de tamaño de página
  const PageSizeSelector({
    super.key,
    required this.pageSizeOptions,
    required this.currentPageSize,
    required this.onPageSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('Show: '),
        ...pageSizeOptions.map((size) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text('$size'),
              selected: currentPageSize == size,
              onSelected: (selected) {
                if (selected) {
                  onPageSizeChanged(size);
                }
              },
              labelStyle: TextStyle(
                fontSize: 12,
                color:
                    currentPageSize == size
                        ? Theme.of(context).primaryColor
                        : null,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          );
        }).toList(),
      ],
    );
  }
}
