            // Paletas
            if (paint.palettes.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Paletas (${paint.palettes.length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: paint.palettes.map((palette) {
                  return Chip(
                    label: Text(palette),
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  );
                }).toList(),
              ),
            ], 