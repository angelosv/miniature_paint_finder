import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:miniature_paint_finder/components/barcode_scanner_card.dart';
import 'package:miniature_paint_finder/components/category_card.dart';
import 'package:miniature_paint_finder/components/image_color_picker.dart';
import 'package:miniature_paint_finder/components/paint_card.dart';
import 'package:miniature_paint_finder/components/palette_card.dart';
import 'package:miniature_paint_finder/data/sample_data.dart';
import 'package:miniature_paint_finder/models/paint.dart';
import 'package:miniature_paint_finder/screens/barcode_scanner_screen.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';

class PaintListTab extends StatefulWidget {
  const PaintListTab({super.key});

  @override
  State<PaintListTab> createState() => _PaintListTabState();
}

class _PaintListTabState extends State<PaintListTab> {
  File? _imageFile;
  bool _showColorPicker = false;
  final ImagePicker _picker = ImagePicker();
  Color _selectedColor = Colors.white;

  // Track both colors and selected matching paints
  final List<Map<String, dynamic>> _pickedColors = [];

  // Lista de marcas de pintura y su estado de selección
  final List<Map<String, dynamic>> _paintBrands = [
    {'name': 'Citadel', 'color': null, 'selected': false, 'avatar': 'C'},
    {'name': 'Vallejo', 'color': null, 'selected': false, 'avatar': 'V'},
    {'name': 'Army Painter', 'color': null, 'selected': false, 'avatar': 'A'},
    {'name': 'Scale75', 'color': null, 'selected': false, 'avatar': 'S'},
  ];

  // Text controller for palette name
  final TextEditingController _paletteNameController = TextEditingController();

  // Parámetros para la creación de una paleta desde otra pantalla
  String? _pendingPaletteName;
  bool _isCreatingPaletteFromExternal = false;

  @override
  void initState() {
    super.initState();
    // Inicializar colores para las marcas
    _paintBrands[0]['color'] = AppTheme.primaryBlue;
    _paintBrands[1]['color'] = AppTheme.pinkColor;
    _paintBrands[2]['color'] = AppTheme.purpleColor;
    _paintBrands[3]['color'] = AppTheme.orangeColor;

    // Verificar si hay argumentos para crear una paleta automáticamente
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForPaletteCreationArguments();
    });
  }

  @override
  void dispose() {
    _paletteNameController.dispose();
    super.dispose();
  }

  Future<void> _getImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _showColorPicker = true;
      });
    }
  }

  void _onColorPicked(Color color) {
    setState(() {
      _selectedColor = color;
    });
  }

  void _onColorsSelected(List<Color> colors) {
    setState(() {
      if (colors.isNotEmpty) {
        _selectedColor = colors.last;

        // Clear previous colors and add new ones in a structured format
        _pickedColors.clear();
        for (var color in colors) {
          final hexCode =
              '#${color.value.toRadixString(16).toUpperCase().substring(2)}';
          _pickedColors.add({
            'color': color,
            'hexCode': hexCode,
            'paintName': null,
            'paintBrand': null,
            'paintColor': null,
            'brandAvatar': null,
            'matchPercentage': null,
          });
        }
      }
    });
  }

  void _reset() {
    setState(() {
      _showColorPicker = false;
      _imageFile = null;
      _pickedColors.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final paints = SampleData.getPaints();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.05, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child:
          _showColorPicker
              ? _buildSearchStepsView(context)
              : _buildHomeView(context, paints),
    );
  }

  // Vista principal cuando no se está en modo búsqueda
  Widget _buildHomeView(BuildContext context, List<Paint> paints) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tarjeta de acción para búsqueda con un diseño más moderno
            GestureDetector(
              onTap: () {
                // Si ya estamos creando una paleta desde otra pantalla, usamos ese nombre
                // Si no, simplemente activamos el modo de búsqueda
                setState(() {
                  _showColorPicker = true;

                  // Si venimos de crear una paleta desde otra pantalla,
                  // establecemos el nombre en el controlador
                  if (_isCreatingPaletteFromExternal &&
                      _pendingPaletteName != null) {
                    _paletteNameController.text = _pendingPaletteName!;
                  }
                });
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.marineBlue, AppTheme.marineBlueLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.marineBlue.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.color_lens,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Paint Search',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Find matching paints for your images',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 20,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Start Searching',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.marineBlue,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.arrow_forward, color: AppTheme.marineBlue),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Barcode Scanner Card
            const BarcodeScannerCard(),

            const SizedBox(height: 24),

            // Sección de Recent Palettes y resto del contenido original
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Palettes',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton(onPressed: () {}, child: const Text('See all')),
              ],
            ),

            const SizedBox(height: 12),

            // Lista horizontal de paletas
            SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: SampleData.getPalettes().length,
                itemBuilder: (context, index) {
                  return PaletteCard(
                    palette: SampleData.getPalettes()[index],
                    onTap: () {
                      // TODO: Implementar acción al tocar una paleta
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // Sección de Categorías
            Text('Categories', style: Theme.of(context).textTheme.titleMedium),

            const SizedBox(height: 12),

            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.5,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                CategoryCard(
                  title: 'Citadel',
                  count: 7,
                  color: AppTheme.primaryBlue,
                  onTap: () {},
                ),
                CategoryCard(
                  title: 'Vallejo',
                  count: 3,
                  color: AppTheme.pinkColor,
                  onTap: () {},
                ),
                CategoryCard(
                  title: 'Army Painter',
                  count: 0,
                  color: AppTheme.purpleColor,
                  onTap: () {},
                ),
                CategoryCard(
                  title: 'Scale75',
                  count: 0,
                  color: AppTheme.orangeColor,
                  onTap: () {},
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Lista de todas las pinturas
            Text('All Paints', style: Theme.of(context).textTheme.titleMedium),

            const SizedBox(height: 12),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: paints.length,
              itemBuilder: (context, index) {
                final paint = paints[index];
                return PaintCard(paint: paint);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Vista de búsqueda con pasos
  Widget _buildSearchStepsView(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paint Search'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _reset,
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 100,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Paso 1: Elegir marcas
                _buildStepCard(
                  context,
                  stepNumber: 1,
                  title: 'Choose your brands',
                  subtitle: 'Select brands where to search for matching colors',
                  icon: Icons.palette_outlined,
                  color: AppTheme.marineBlue,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 10),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: () => _showBrandSelectionModal(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Select Paint Brands'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.marineBlue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Show selected brands preview in a scrollable row
                      SizedBox(
                        height: 110, // Fixed height for the scrollable area
                        child:
                            _paintBrands
                                    .where((brand) => brand['selected'] == true)
                                    .isEmpty
                                ? Center(
                                  child: Text(
                                    'No brands selected yet',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.grey[400]
                                              : Colors.grey[600],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                )
                                : ListView(
                                  scrollDirection: Axis.horizontal,
                                  children:
                                      _paintBrands
                                          .where(
                                            (brand) =>
                                                brand['selected'] == true,
                                          )
                                          .map(
                                            (brand) => Padding(
                                              padding: const EdgeInsets.only(
                                                right: 8.0,
                                              ),
                                              child: _buildBrandChip(
                                                name: brand['name'],
                                                color: brand['color'],
                                                isSelected: true,
                                                context: context,
                                              ),
                                            ),
                                          )
                                          .toList(),
                                ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Paso 2: Elegir imagen
                _buildStepCard(
                  context,
                  stepNumber: 2,
                  title: 'Choose your image',
                  subtitle: 'Select or take a photo to find matching colors',
                  icon: Icons.image_search,
                  color: AppTheme.marineOrange,
                  content: ImageColorPicker(
                    imageFile: _imageFile,
                    onColorsSelected: _onColorsSelected,
                    onImageSelected: (file) {
                      setState(() {
                        _imageFile = file;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Paso 3: Seleccionar colores (siempre visible)
                _buildStepCard(
                  context,
                  stepNumber: 3,
                  title: 'Selected colors',
                  subtitle: 'Review and save your selected color palette',
                  icon: Icons.search,
                  color: AppTheme.purpleColor,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 10),

                      // Añadir el botón Clear all si hay colores seleccionados
                      if (_pickedColors.isNotEmpty)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Flexible(
                              child: Text(
                                'Selected colors (${_pickedColors.length})',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color:
                                      Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white
                                          : null,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _pickedColors.clear();
                                });
                              },
                              child: Text(
                                'Clear all',
                                style: TextStyle(
                                  color:
                                      Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.lightBlue[300]
                                          : null,
                                ),
                              ),
                            ),
                          ],
                        ),

                      // Lista de colores seleccionados
                      _pickedColors.isEmpty
                          ? const Text(
                            'No colors selected yet. Add colors from the image above.',
                          )
                          : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                height: 90,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _pickedColors.length,
                                  itemBuilder: (context, index) {
                                    return _buildColorSwatchItem(
                                      _pickedColors[index],
                                      index,
                                    );
                                  },
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Botón para buscar pinturas coincidentes
                              Center(
                                child:
                                    _pickedColors.isNotEmpty
                                        ? ElevatedButton.icon(
                                          onPressed: () {
                                            _showSelectedColorsModal(context);
                                          },
                                          icon: const Icon(Icons.search),
                                          label: const Text(
                                            'Find matching paints',
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                AppTheme.purpleColor,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                              horizontal: 16,
                                            ),
                                          ),
                                        )
                                        : Container(),
                              ),
                            ],
                          ),
                    ],
                  ),
                ),

                // Espacio adicional al final para evitar overflow
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Método para crear tarjetas de pasos
  Widget _buildStepCard(
    BuildContext context, {
    required int stepNumber,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget content,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título del paso
            Row(
              children: [
                // Número de paso
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      stepNumber.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Título e icono
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            subtitle,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      Icon(icon, color: color),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Contenido del paso
            content,
          ],
        ),
      ),
    );
  }

  // Widget para mostrar chips de marcas
  Widget _buildBrandChip({
    required String name,
    required Color color,
    required bool isSelected,
    required BuildContext context,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color:
            isSelected
                ? (isDarkMode ? color.withOpacity(0.3) : color.withOpacity(0.1))
                : (isDarkMode ? Colors.grey[850] : Colors.white),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isSelected
                  ? color
                  : (isDarkMode ? Colors.grey[700]! : Colors.grey[300]!),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 40,
            width: 40,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                name.substring(0, 1),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12,
              color: isDarkMode ? Colors.white : null,
            ),
          ),
          if (isSelected) Icon(Icons.check_circle, color: color, size: 14),
        ],
      ),
    );
  }

  // Modal para mostrar colores seleccionados y buscar coincidencias
  void _showSelectedColorsModal(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Generate default palette name based on date
    final now = DateTime.now();
    final defaultName = 'Palette ${now.day}-${now.month}-${now.year}';
    _paletteNameController.text = defaultName;

    // Function to build the modal content - extracted to allow rebuilding
    Widget buildModalContent(
      BuildContext context,
      ScrollController scrollController,
      Function setState,
    ) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Selected Colors',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: isDarkMode ? Colors.white : null,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: isDarkMode ? Colors.white : null,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Text(
              'Find matching paints for your selected colors',
              style: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                fontSize: 14,
              ),
            ),
            Divider(color: isDarkMode ? Colors.grey[700] : null),

            // Palette name field
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: TextField(
                controller: _paletteNameController,
                decoration: InputDecoration(
                  labelText: 'Palette Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                  prefixIcon: const Icon(Icons.palette),
                ),
                style: TextStyle(color: isDarkMode ? Colors.white : null),
              ),
            ),

            const SizedBox(height: 10),
            Expanded(
              child: Stack(
                children: [
                  ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.only(bottom: 70),
                    itemCount: _pickedColors.length,
                    itemBuilder: (context, index) {
                      final colorData = _pickedColors[index];
                      final color = colorData['color'] as Color;
                      final hexCode = colorData['hexCode'] as String;

                      // Diseño común de las tarjetas siempre simple como en la imagen
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color:
                                isDarkMode
                                    ? Colors.grey[700]!
                                    : Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        color: isDarkMode ? Colors.grey[850] : Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Color swatch
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Color info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Color Point ${index + 1}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color:
                                            isDarkMode
                                                ? Colors.white
                                                : Colors.black,
                                      ),
                                    ),
                                    Text(
                                      hexCode,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color:
                                            isDarkMode
                                                ? Colors.grey[400]
                                                : Colors.grey[600],
                                      ),
                                    ),

                                    // Show selected paint info if available
                                    if (colorData['paintName'] != null)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 8.0,
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 20,
                                              height: 20,
                                              decoration: BoxDecoration(
                                                color:
                                                    isDarkMode
                                                        ? Colors.grey[800]
                                                        : Colors.grey[200],
                                                shape: BoxShape.circle,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  colorData['brandAvatar']
                                                      as String,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        isDarkMode
                                                            ? Colors.white
                                                            : Colors.black,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              "${colorData['paintName']}",
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color:
                                                    isDarkMode
                                                        ? Colors.white
                                                        : Colors.black,
                                              ),
                                            ),

                                            // Add match percentage
                                            if (colorData['matchPercentage'] !=
                                                null)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  left: 8.0,
                                                ),
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: _getMatchColor(
                                                      colorData['matchPercentage']
                                                          as int,
                                                    ).withOpacity(0.2),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    '${colorData['matchPercentage']}%',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: _getMatchColor(
                                                        colorData['matchPercentage']
                                                            as int,
                                                      ),
                                                      fontWeight:
                                                          FontWeight.bold,
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

                              // Find button
                              SizedBox(
                                width: 60,
                                height: 60,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    // Key change: await the result and rebuild modal after returning
                                    await _showMatchingPaintsModal(
                                      context,
                                      index,
                                    );
                                    setState(
                                      () {},
                                    ); // Rebuild the modal after returning from paint selection
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.marineBlue,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.color_lens, size: 20),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Find',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  // Fixed position Save Palette button
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[900] : Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Palette "${_paletteNameController.text}" saved!',
                                ),
                              ),
                            );
                            _reset();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.purpleColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Save Palette'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              maxChildSize: 0.9,
              minChildSize: 0.5,
              expand: false,
              builder: (context, scrollController) {
                return buildModalContent(
                  context,
                  scrollController,
                  setModalState,
                );
              },
            );
          },
        );
      },
    );
  }

  // Nuevo método para construir la tarjeta de pintura en el modal "Selected Colors"
  Widget _buildPaintCardForSelectedColors(
    Map<String, dynamic> colorData,
    int index,
  ) {
    final paintName = colorData['paintName'] as String;
    final paintBrand = colorData['paintBrand'] as String?;
    final brandAvatar = colorData['brandAvatar'] as String;
    final matchPercentage = colorData['matchPercentage'] as int?;
    final colorCode = colorData['colorCode'] as String?;
    final barcode = colorData['barcode'] as String?;
    final paintColor = colorData['paintColor'] as Color?;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Avatar de marca (círculo con letra)
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              brandAvatar,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Nombre, marca y detalles
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Nombre de la pintura
              Text(
                paintName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black,
                ),
                overflow: TextOverflow.ellipsis,
              ),

              // Marca de la pintura
              Text(
                paintBrand ?? '',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),

              // Fila de código de color y barcode
              if (colorCode != null || barcode != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      // Código de color con swatch
                      if (colorCode != null && paintColor != null)
                        Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: paintColor,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              colorCode,
                              style: const TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(width: 12),

                      // Código de barras
                      if (barcode != null)
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.qr_code,
                                size: 11,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  barcode,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        // Porcentaje de coincidencia
        if (matchPercentage != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _getMatchColor(matchPercentage).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$matchPercentage% match',
              style: TextStyle(
                fontSize: 12,
                color: _getMatchColor(matchPercentage),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  // Modal para mostrar pinturas coincidentes (simulado)
  Future<void> _showMatchingPaintsModal(BuildContext context, int colorIndex) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorData = _pickedColors[colorIndex];
    final color = colorData['color'] as Color;
    final hexCode = colorData['hexCode'] as String;

    // Simulated paint matches with color codes
    final List<Map<String, dynamic>> matchingPaints = [
      {
        'name': 'Abaddon Black',
        'brand': 'Citadel',
        'color': const Color(0xFF231F20),
        'match': 92,
        'brandAvatar': 'C',
        'colorCode': '49-33',
        'barcode': '5011921026340',
      },
      {
        'name': 'Evil Sunz Scarlet',
        'brand': 'Citadel',
        'color': const Color(0xFFD1262C),
        'match': 88,
        'brandAvatar': 'C',
        'colorCode': '52-12',
        'barcode': '5011921027132',
      },
      {
        'name': 'Mephiston Red',
        'brand': 'Citadel',
        'color': const Color(0xFFA22127),
        'match': 86,
        'brandAvatar': 'C',
        'colorCode': '22-7A',
        'barcode': '5011921027163',
      },
      {
        'name': 'Model Color Black',
        'brand': 'Vallejo',
        'color': Colors.black,
        'match': 84,
        'brandAvatar': 'V',
        'colorCode': '70.950',
        'barcode': '8429551708512',
      },
      {
        'name': 'Game Color Heavy Red',
        'brand': 'Vallejo',
        'color': const Color(0xFFC43E3E),
        'match': 82,
        'brandAvatar': 'V',
        'colorCode': '72.143',
        'barcode': '8429551725052',
      },
    ];

    // Track selected paint for confirmation
    int? selectedPaintIndex;
    if (colorData['paintName'] != null) {
      for (int i = 0; i < matchingPaints.length; i++) {
        if (matchingPaints[i]['name'] == colorData['paintName'] &&
            matchingPaints[i]['brand'] == colorData['paintBrand']) {
          selectedPaintIndex = i;
          break;
        }
      }
    }

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              maxChildSize: 0.9,
              minChildSize: 0.5,
              expand: false,
              builder: (context, scrollController) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Matching Paints',
                            style: Theme.of(
                              context,
                            ).textTheme.titleLarge?.copyWith(
                              color: isDarkMode ? Colors.white : null,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              color: isDarkMode ? Colors.white : null,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'For color: $hexCode',
                            style: TextStyle(
                              color:
                                  isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      Divider(color: isDarkMode ? Colors.grey[700] : null),
                      const SizedBox(height: 10),
                      Text(
                        'Select a paint to match with this color:',
                        style: TextStyle(
                          color:
                              isDarkMode ? Colors.grey[300] : Colors.grey[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: matchingPaints.length,
                          itemBuilder: (context, index) {
                            final paint = matchingPaints[index];
                            final isSelected = selectedPaintIndex == index;

                            return GestureDetector(
                              onTap: () {
                                // Update selected paint index
                                setModalState(() {
                                  selectedPaintIndex =
                                      isSelected ? null : index;
                                });
                              },
                              child: Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(
                                    color:
                                        isSelected
                                            ? Colors.blue
                                            : isDarkMode
                                            ? Colors.grey[700]!
                                            : Colors.grey[300]!,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                color:
                                    isSelected
                                        ? (isDarkMode
                                            ? Colors.blue.withOpacity(0.1)
                                            : Colors.blue.withOpacity(0.05))
                                        : (isDarkMode
                                            ? Colors.grey[850]
                                            : null),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          // Brand avatar instead of color swatch
                                          Container(
                                            width: 50,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              color:
                                                  isDarkMode
                                                      ? Colors.grey[800]
                                                      : Colors.grey[200],
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Text(
                                                paint['brandAvatar'] as String,
                                                style: TextStyle(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      isDarkMode
                                                          ? Colors.white
                                                          : Colors.black,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),

                                          // Paint info
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  paint['name'] as String,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color:
                                                        isDarkMode
                                                            ? Colors.white
                                                            : Colors.black,
                                                  ),
                                                ),
                                                Text(
                                                  paint['brand'] as String,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color:
                                                        isDarkMode
                                                            ? Colors.grey[400]
                                                            : Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Match percentage
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getMatchColor(
                                                paint['match'] as int,
                                              ).withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              '${paint['match']}% match',
                                              style: TextStyle(
                                                color: _getMatchColor(
                                                  paint['match'] as int,
                                                ),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),

                                          // Selection tick on the right
                                          if (isSelected)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                left: 8,
                                              ),
                                              child: Icon(
                                                Icons.check_circle,
                                                color: Colors.blue,
                                                size: 22,
                                              ),
                                            ),
                                        ],
                                      ),

                                      // Color info and barcode section
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color:
                                              isDarkMode
                                                  ? Colors.grey[800]
                                                  : Colors.grey[100],
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            // Color swatch and code
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  width: 24,
                                                  height: 24,
                                                  decoration: BoxDecoration(
                                                    color:
                                                        paint['color'] as Color,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      'Color code:',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color:
                                                            isDarkMode
                                                                ? Colors
                                                                    .grey[400]
                                                                : Colors
                                                                    .grey[600],
                                                      ),
                                                    ),
                                                    Text(
                                                      paint['colorCode']
                                                          as String,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontFamily: 'monospace',
                                                        color:
                                                            isDarkMode
                                                                ? Colors.white
                                                                : Colors.black,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),

                                            // Barcode
                                            Flexible(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    'Barcode:',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color:
                                                          isDarkMode
                                                              ? Colors.grey[400]
                                                              : Colors
                                                                  .grey[600],
                                                    ),
                                                  ),
                                                  Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.qr_code,
                                                        size: 14,
                                                        color:
                                                            isDarkMode
                                                                ? Colors
                                                                    .grey[400]
                                                                : Colors
                                                                    .grey[600],
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Flexible(
                                                        child: Text(
                                                          paint['barcode']
                                                              as String,
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            fontFamily:
                                                                'monospace',
                                                            color:
                                                                isDarkMode
                                                                    ? Colors
                                                                        .white
                                                                    : Colors
                                                                        .black,
                                                          ),
                                                          overflow:
                                                              TextOverflow
                                                                  .ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // Confirm button
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              selectedPaintIndex != null
                                  ? () {
                                    // Save selected paint
                                    final paint =
                                        matchingPaints[selectedPaintIndex!];
                                    setState(() {
                                      _pickedColors[colorIndex] = {
                                        ..._pickedColors[colorIndex],
                                        'paintName': paint['name'],
                                        'paintBrand': paint['brand'],
                                        'paintColor': paint['color'],
                                        'brandAvatar': paint['brandAvatar'],
                                        'matchPercentage': paint['match'],
                                        'colorCode': paint['colorCode'],
                                        'barcode': paint['barcode'],
                                      };
                                    });

                                    // Show confirmation and close modal
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${paint['name']} selected for Color Point ${colorIndex + 1}',
                                        ),
                                        duration: const Duration(
                                          milliseconds: 1500,
                                        ),
                                      ),
                                    );
                                    Navigator.pop(context);
                                  }
                                  : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.marineBlue,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey.withOpacity(
                              0.3,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            'Confirm Selection',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // Helper method to get color based on match percentage
  Color _getMatchColor(int matchPercentage) {
    if (matchPercentage >= 90) {
      return Colors.green;
    } else if (matchPercentage >= 80) {
      return Colors.amber;
    } else {
      return Colors.red;
    }
  }

  // Update color display in the Selected Colors card
  Widget _buildColorSwatchItem(Map<String, dynamic> colorData, int index) {
    final color = colorData['color'] as Color;
    final hexCode = colorData['hexCode'] as String;
    final paintName = colorData['paintName'];
    final paintBrand = colorData['paintBrand'];
    final matchPercentage = colorData['matchPercentage'];
    final brandAvatar = colorData['brandAvatar'];
    final colorCode = colorData['colorCode'];
    final barcode = colorData['barcode'];
    final paintColor = colorData['paintColor'];
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Si hay una pintura seleccionada, mostrar tarjeta como en la imagen
    if (paintName != null) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar de marca (círculo con letra)
              Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    brandAvatar as String,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Nombre y marca
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      paintName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      paintBrand ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Código de color y barcode en una fila
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Color box y código
                        if (colorCode != null)
                          Row(
                            children: [
                              Container(
                                width: 15,
                                height: 15,
                                decoration: BoxDecoration(
                                  color: paintColor as Color,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                colorCode,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      isDarkMode ? Colors.white : Colors.black,
                                ),
                              ),
                            ],
                          ),

                        const SizedBox(width: 16),

                        // Barcode
                        if (barcode != null)
                          Row(
                            children: [
                              Icon(
                                Icons.qr_code,
                                size: 10,
                                color:
                                    isDarkMode
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                barcode,
                                style: TextStyle(
                                  fontSize: 10,
                                  color:
                                      isDarkMode
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Porcentaje de coincidencia
              if (matchPercentage != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getMatchColor(
                      matchPercentage as int,
                    ).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$matchPercentage% match',
                    style: TextStyle(
                      fontSize: 12,
                      color: _getMatchColor(matchPercentage as int),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // Si no hay pintura seleccionada, mostrar el diseño original
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              // Paint color container
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),

              // Remove button
              Positioned(
                right: -4,
                top: -4,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _pickedColors.removeAt(index);
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[800] : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDarkMode ? Colors.grey[700]! : Colors.white,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.close,
                      size: 10,
                      color: isDarkMode ? Colors.red[300] : Colors.red,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Show hex code
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              hexCode,
              style: TextStyle(
                fontSize: 9,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Modal para seleccionar marcas de pintura
  void _showBrandSelectionModal(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Crear una copia local de los datos para manipularlos en el modal
    final List<Map<String, dynamic>> tempBrands =
        List<Map<String, dynamic>>.from(
          _paintBrands.map((brand) => Map<String, dynamic>.from(brand)),
        );

    // Asignar colores del tema Space Marine
    tempBrands[0]['color'] = AppTheme.marineBlue;
    tempBrands[1]['color'] = AppTheme.marineOrange;
    tempBrands[2]['color'] = AppTheme.marineGold;
    tempBrands[3]['color'] = AppTheme.marineBlueLight;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              maxChildSize: 0.9,
              minChildSize: 0.5,
              expand: false,
              builder: (context, scrollController) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Select Paint Brands',
                            style: Theme.of(
                              context,
                            ).textTheme.titleLarge?.copyWith(
                              color: isDarkMode ? Colors.white : null,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              color: isDarkMode ? Colors.white : null,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      Divider(color: isDarkMode ? Colors.grey[700] : null),
                      const SizedBox(height: 10),
                      Expanded(
                        child: GridView.builder(
                          controller: scrollController,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 1.5,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                              ),
                          itemCount: tempBrands.length,
                          itemBuilder: (context, index) {
                            final brand = tempBrands[index];
                            return GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  // Toggle selection
                                  brand['selected'] =
                                      !(brand['selected'] as bool);
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color:
                                      (brand['selected'] as bool)
                                          ? (brand['color'] as Color)
                                              .withOpacity(
                                                isDarkMode ? 0.3 : 0.1,
                                              )
                                          : (isDarkMode
                                              ? Colors.grey[850]
                                              : Colors.white),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color:
                                        (brand['selected'] as bool)
                                            ? (brand['color'] as Color)
                                            : (isDarkMode
                                                ? Colors.grey[700]!
                                                : Colors.grey[300]!),
                                    width: (brand['selected'] as bool) ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      height: 40,
                                      width: 40,
                                      decoration: BoxDecoration(
                                        color:
                                            isDarkMode
                                                ? Colors.grey[800]
                                                : Colors.grey[200],
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          (brand['name'] as String).substring(
                                            0,
                                            1,
                                          ),
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color:
                                                isDarkMode
                                                    ? Colors.grey[300]
                                                    : Colors.grey[700],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Flexible(
                                      child: Text(
                                        brand['name'] as String,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color:
                                              isDarkMode ? Colors.white : null,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (brand['selected'] as bool)
                                      Icon(
                                        Icons.check_circle,
                                        color: brand['color'] as Color,
                                        size: 18,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            // Actualizar el estado global con las selecciones del modal
                            setState(() {
                              for (int i = 0; i < _paintBrands.length; i++) {
                                _paintBrands[i]['selected'] =
                                    tempBrands[i]['selected'];
                              }
                            });
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.marineBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // Método para verificar si se inició con argumentos para crear una paleta
  void _checkForPaletteCreationArguments() {
    final modalRoute = ModalRoute.of(context);
    if (modalRoute != null && modalRoute.settings.arguments != null) {
      final args = modalRoute.settings.arguments as Map<String, dynamic>?;

      if (args != null && args.containsKey('paletteInfo')) {
        final paletteInfo = args['paletteInfo'] as Map<String, dynamic>;
        if (paletteInfo['isCreatingPalette'] == true &&
            paletteInfo.containsKey('paletteName')) {
          // Almacenar el nombre de la paleta pendiente
          _pendingPaletteName = paletteInfo['paletteName'] as String;
          _isCreatingPaletteFromExternal = true;

          // Activar directamente el flujo de búsqueda de colores
          setState(() {
            _showColorPicker = true;
          });
        }
      }
    }
  }
}
