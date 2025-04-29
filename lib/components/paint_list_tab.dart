import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:miniature_paint_finder/components/barcode_scanner_card.dart';
import 'package:miniature_paint_finder/components/category_card.dart';
import 'package:miniature_paint_finder/components/image_color_picker.dart';
import 'package:miniature_paint_finder/components/paint_card.dart';
import 'package:miniature_paint_finder/components/palette_card.dart';
import 'package:miniature_paint_finder/components/palette_modal.dart';
import 'package:miniature_paint_finder/components/palette_skeleton.dart';
import 'package:miniature_paint_finder/data/sample_data.dart';
import 'package:miniature_paint_finder/models/most_used_paint.dart';
import 'package:miniature_paint_finder/models/paint.dart';
import 'package:miniature_paint_finder/screens/barcode_scanner_screen.dart';
import 'package:miniature_paint_finder/services/palette_service.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';
import 'package:miniature_paint_finder/theme/app_responsive.dart';
import 'package:miniature_paint_finder/services/paint_brand_service.dart';
import 'package:miniature_paint_finder/services/paint_match_service.dart';
import 'package:miniature_paint_finder/services/color_search_service.dart';
import 'package:miniature_paint_finder/models/paint_brand.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:miniature_paint_finder/components/add_to_wishlist_modal.dart';
import 'package:miniature_paint_finder/components/add_to_inventory_modal.dart';
import 'package:miniature_paint_finder/screens/wishlist_screen.dart';
import 'package:miniature_paint_finder/screens/inventory_screen.dart';
import 'package:provider/provider.dart';
import 'package:miniature_paint_finder/controllers/palette_controller.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:miniature_paint_finder/models/palette.dart';
import 'package:miniature_paint_finder/services/paint_service.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:miniature_paint_finder/widgets/guest_promo_modal.dart';
import 'package:miniature_paint_finder/services/auth_service.dart';
import 'package:provider/provider.dart';

// Clase para crear el recorte diagonal en la tarjeta de promoción
class DiagonalClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, 0);
    path.lineTo(size.width * 0.7, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return true;
  }
}

class PaintListTab extends StatefulWidget {
  const PaintListTab({super.key});

  @override
  State<PaintListTab> createState() => _PaintListTabState();
}

class _PaintListTabState extends State<PaintListTab> {
  List<MostUsedPaint>? _mostUsedPaints;
  bool _isLoadingMostUsed = false;
  String? _mostUsedError;

  final Map<int, List<dynamic>> _matchingPaints = {};
  final Map<int, int> _currentPages = {};
  final Map<int, int> _totalPages = {};
  final Map<int, bool> _isLoadingMore = {};
  final Map<int, ScrollController> _scrollControllers = {};
  bool _isSavingPalette = false;
  File? _imageFile;
  String? _uploadedImageUrl;
  bool _showColorPicker = false;
  final ImagePicker _picker = ImagePicker();
  Color _selectedColor = Colors.white;
  final PaintBrandService _paintBrandService = PaintBrandService();
  final PaletteService _paletteService = PaletteService();

  // Track both colors and selected matching paints
  List<Map<String, dynamic>> _pickedColors = [];

  // Lista de marcas de pintura y su estado de selección
  List<Map<String, dynamic>> _paintBrands = [];

  // Text controller for palette name
  final TextEditingController _paletteNameController = TextEditingController();

  // Parámetros para la creación de una paleta desde otra pantalla
  String? _pendingPaletteName;
  bool _isCreatingPaletteFromExternal = false;

  @override
  void initState() {
    super.initState();
    // Forzar una carga fresca desde la API la primera vez
    _refreshPaintBrands();
    _loadMostUsedPaints();

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

  // Callback cuando se seleccionan colores de la imagen
  void _onColorsSelected(List<Map<String, dynamic>> colors) {
    // Verificar si el widget está montado antes de actualizar el estado
    if (!mounted) return;

    // Usar un post-frame callback para asegurar que las dependencias se actualicen correctamente
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      setState(() {
        _pickedColors =
            colors.map((colorData) {
              final Color color = colorData['color'] as Color;
              final String hexCode = colorData['hexCode'] as String;

              return {'color': color, 'hexCode': hexCode};
            }).toList();
      });
    });
  }

  // Callback cuando se selecciona una imagen
  void _onImageSelected(File imageFile) {
    // Verificar si el widget está montado antes de actualizar el estado
    if (!mounted) return;

    // Usar un post-frame callback para asegurar que las dependencias se actualicen correctamente
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      setState(() {
        if (imageFile.path.isEmpty) {
          _imageFile = null;
          _pickedColors.clear();
        } else {
          _imageFile = imageFile;
        }
      });
    });
  }

  void _onImageUploaded(String url) {
    // Verificar si el widget está montado antes de actualizar el estado
    if (!mounted) return;

    // Usar un post-frame callback para asegurar que las dependencias se actualicen correctamente
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      setState(() {
        _uploadedImageUrl = url;
      });
    });
  }

  void _reset() {
    // Verificar si el widget está montado antes de actualizar el estado
    if (!mounted) return;

    // Usar un post-frame callback para asegurar que las dependencias se actualicen correctamente
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      setState(() {
        _showColorPicker = false;
        _imageFile = null;
        _uploadedImageUrl = null;
        _pickedColors.clear();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
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
              : _buildHomeView(context),
    );
  }

  /// Vista principal cuando no se está en modo búsqueda
  Widget _buildHomeView(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === Botón de inicio de búsqueda ===
            GestureDetector(
              onTap: () {
                setState(() {
                  _showColorPicker = true;
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

            // === Barcode Scanner ===
            const BarcodeScannerCard(),

            const SizedBox(height: 24),

            // === Promoción ===
            // Commenting out the promotion card as requested
            // _buildPromotionCard(context),

            // const SizedBox(height: 24),

            // === Recent Palettes ===
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Palettes',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton(
                  onPressed: () {
                    // Check if user is a guest
                    final currentUser = FirebaseAuth.instance.currentUser;
                    final isGuestUser =
                        currentUser == null || currentUser.isAnonymous;

                    if (isGuestUser) {
                      // Show guest promo modal
                      GuestPromoModal.showForRestrictedFeature(
                        context,
                        'Palettes',
                      );
                    } else {
                      // Navigate to palettes screen
                      Navigator.pushNamed(context, '/palettes');
                    }
                  },
                  child: const Text('See all'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Consumer<PaletteController>(
              builder: (context, paletteController, child) {
                final currentUser = FirebaseAuth.instance.currentUser;
                final isGuestUser = currentUser == null || currentUser.isAnonymous;
                final isDarkMode = Theme.of(context).brightness == Brightness.dark;
                // Forzar la carga de paletas si el usuario está autenticado
                if (!isGuestUser && !paletteController.isLoading && paletteController.palettes.isEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    paletteController.loadPalettes();
                  });
                }

                if(isGuestUser) {
                  return Column(
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 48,
                        color:
                            isDarkMode ? AppTheme.marineOrange : AppTheme.marineBlue,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Track your recent palettes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create a free account to see which paints you use most across your palettes',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () async {
                          final authService = Provider.of<IAuthService>(context, listen: false);
                          await authService.signOut();
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            '/',
                            (route) => false,
                            arguments: {'showRegistration': true},
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isDarkMode
                                  ? AppTheme.marineOrange
                                  : AppTheme.marineBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: const Text('Sign Up - It\'s Free!'),
                      ),
                    ],
                  );
                } else {
                  print('***call recent');
                  final recent = paletteController.palettes.take(10).toList();
                  print('recent $recent');
                  if (paletteController.isLoading || recent.isEmpty) {
                    return const PaletteSkeletonList(count: 3);
                  }
                  return SizedBox(
                    height: 220,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: recent.length,
                      itemBuilder: (_, i) {
                        final p = recent[i];
                        return PaletteCard(
                          palette: p,
                          onTap: () {
                            // Check if user is a guest
                            final currentUser = FirebaseAuth.instance.currentUser;
                            final isGuestUser =
                                currentUser == null || currentUser.isAnonymous;

                            if (isGuestUser) {
                              // Show guest promo modal
                              GuestPromoModal.showForRestrictedFeature(
                                context,
                                'Palettes',
                              );
                            } else {
                              // Show palette modal
                              showPaletteModal(
                                context,
                                p.name,
                                p.paintSelections ?? [],
                                imagePath: p.imagePath,
                              );
                            }
                          },
                        );
                      },
                    ),
                  );
                }
              },
            ),

            const SizedBox(height: 24),

            // === Categorías ===
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Paints', style: Theme.of(context).textTheme.titleMedium),
                TextButton(
                  onPressed: () => _showAllCategoriesModal(context),
                  child: const Text('See all'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _paintBrands.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.5,
                  ),
                  itemCount: _paintBrands.length > 6 ? 6 : _paintBrands.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (ctx, idx) {
                    final b = _paintBrands[idx];
                    return CategoryCard(
                      title: b['name'] as String,
                      count: b['paintCount'] as int,
                      color: b['color'] as Color,
                      onTap: () {
                        // First navigate to the library screen
                        Navigator.pushNamed(
                          context,
                          '/library',
                          arguments: {
                            'brandName': b['id'],
                            'showPalettesPromo': true,
                          },
                        );
                      },
                    );
                  },
                ),

            const SizedBox(height: 24),

            // === Most Used Paints ===
            _buildMostUsedPaintsSection(context),
          ],
        ),
      ),
    );
  }

  // Vista de búsqueda con pasos
  Widget _buildSearchStepsView(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isGuestUser = currentUser == null || currentUser.isAnonymous;
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
                                      fontFamily:
                                          GoogleFonts.poppins().fontFamily,
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
                                                logoUrl: brand['logoUrl'],
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
                  color: AppTheme.marineOrange,
                  content: ImageColorPicker(
                    imageFile: _imageFile,
                    onColorsSelected: _onColorsSelected,
                    onImageSelected: _onImageSelected,
                    onImageUploaded: _onImageUploaded,
                  ),
                ),

                const SizedBox(height: 16),

                // Paso 3: Seleccionar colores (siempre visible)
                _buildStepCard(
                  context,
                  stepNumber: 3,
                  title: 'Selected colors',
                  subtitle: 'Review and save your selected color palette',
                  color: AppTheme.marineBlue,
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
                                  fontFamily: GoogleFonts.poppins().fontFamily,
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
                                  fontFamily: GoogleFonts.poppins().fontFamily,
                                  color:
                                      Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? AppTheme.marineBlueLight
                                          : AppTheme.marineBlue,
                                ),
                              ),
                            ),
                          ],
                        ),

                      // Lista de colores seleccionados
                      _pickedColors.isEmpty
                          ? Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 16.0,
                              ),
                              child: Text(
                                'No colors selected yet. Use the "Pick Colors" button to select colors from your image.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: GoogleFonts.poppins().fontFamily,
                                  color:
                                      Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                ),
                              ),
                            ),
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
                                            //if (isGuestUser) {
                                              //GuestPromoModal.showForRestrictedFeature(
                                                //context,
                                                //'Find matching paints',
                                              //);
                                            //} else {
                                              _showSelectedColorsModal(context);
                                            //}                                            
                                          },
                                          icon: const Icon(Icons.search),
                                          label: const Text(
                                            'Find matching paints',
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Theme.of(context).brightness ==
                                                        Brightness.dark
                                                    ? AppTheme.marineBlue
                                                    : AppTheme.marineBlue,
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
                      style: TextStyle(
                        fontFamily: GoogleFonts.poppins().fontFamily,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Título e icono
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: GoogleFonts.poppins().fontFamily,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color:
                              Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.black87,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontFamily: GoogleFonts.poppins().fontFamily,
                          fontSize: 14,
                          color:
                              Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                        ),
                      ),
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
    String? logoUrl,
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
          if (logoUrl != null)
            Container(
              height: 40,
              width: 40,
              margin: const EdgeInsets.only(top: 2),
              child: Image.network(logoUrl, fit: BoxFit.contain),
            )
          else
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

    // Si venimos de crear una paleta desde otra pantalla, usamos ese nombre
    // Si no, generamos un nombre por defecto basado en la fecha
    if (_isCreatingPaletteFromExternal && _pendingPaletteName != null) {
      _paletteNameController.text = _pendingPaletteName!;
    } else {
      final now = DateTime.now();
      final defaultName = 'Palette ${now.day}-${now.month}-${now.year}';
      _paletteNameController.text = defaultName;
    }

    // Hacer una copia de los colores seleccionados para manipular en el modal
    List<Map<String, dynamic>> modalColorList = List.from(_pickedColors);

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
                              style: Theme.of(
                                context,
                              ).textTheme.titleLarge?.copyWith(
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
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[600],
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
                            fillColor:
                                isDarkMode
                                    ? Colors.grey[800]
                                    : Colors.grey[100],
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : null,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),
                      Text(
                        'Tap any color card to find matching paints',
                        style: TextStyle(
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: Stack(
                          children: [
                            ListView.builder(
                              controller: scrollController,
                              padding: const EdgeInsets.only(bottom: 70),
                              itemCount: modalColorList.length,
                              itemBuilder: (context, index) {
                                final colorData = modalColorList[index];
                                final color = colorData['color'] as Color;
                                final hexCode = colorData['hexCode'] as String;

                                // Diseño común de las tarjetas, ahora toda la tarjeta es seleccionable
                                return GestureDetector(
                                  onTap: () async {
                                    final result = await _selectPaint(
                                      context,
                                      colorData,
                                    );
                                    if (result != null && context.mounted) {
                                      // Si hay un resultado, actualizar el estado
                                      setModalState(() {
                                        modalColorList[index] = result;
                                      });

                                      // También actualizar el estado general
                                      setState(() {
                                        _pickedColors = List.from(
                                          modalColorList,
                                        );
                                      });
                                    }
                                  },
                                  child: Card(
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
                                    color:
                                        isDarkMode
                                            ? Colors.grey[850]
                                            : Colors.white,
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          // Color swatch
                                          Container(
                                            width: 50,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              color: color,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          const SizedBox(width: 16),

                                          // Color info
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
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
                                                if (colorData['paintName'] !=
                                                    null)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
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
                                                                    ? Colors
                                                                        .grey[800]
                                                                    : Colors
                                                                        .grey[200],
                                                            shape:
                                                                BoxShape.circle,
                                                          ),
                                                          child: Center(
                                                            child: Text(
                                                              colorData['brandAvatar']
                                                                  as String,
                                                              style: TextStyle(
                                                                fontSize: 10,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color:
                                                                    isDarkMode
                                                                        ? Colors
                                                                            .white
                                                                        : Colors
                                                                            .black,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        Text(
                                                          "${colorData['paintName']}",
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            color:
                                                                isDarkMode
                                                                    ? Colors
                                                                        .white
                                                                    : Colors
                                                                        .black,
                                                          ),
                                                        ),

                                                        // Add match percentage
                                                        if (colorData['matchPercentage'] !=
                                                            null)
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets.only(
                                                                  left: 8.0,
                                                                ),
                                                            child: Container(
                                                              padding:
                                                                  const EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        6,
                                                                    vertical: 2,
                                                                  ),
                                                              decoration: BoxDecoration(
                                                                color: _getMatchColor(
                                                                  colorData['matchPercentage']
                                                                      as int,
                                                                ).withOpacity(
                                                                  0.2,
                                                                ),
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
                                                                      FontWeight
                                                                          .bold,
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

                                          // Indicador de acción
                                          Icon(
                                            Icons.search,
                                            color: AppTheme.marineBlue,
                                            size: 24,
                                          ),
                                        ],
                                      ),
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
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      isDarkMode
                                          ? Colors.grey[900]
                                          : Colors.white,
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
                                    onPressed:
                                        _isSavingPalette
                                            ? null
                                            : () async {
                                              final currentUser = FirebaseAuth.instance.currentUser;
                                              final isGuestUser = currentUser == null || currentUser.isAnonymous;

                                              if (isGuestUser) {
                                                GuestPromoModal.showForRestrictedFeature(
                                                  context,
                                                  'Save Palette',
                                                );
                                              } else {
                                                if (_paletteNameController.text
                                                    .trim()
                                                    .isEmpty) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Please enter a palette name',
                                                      ),
                                                    ),
                                                  );
                                                  return;
                                                }

                                                setModalState(() {
                                                  _isSavingPalette = true;
                                                });

                                                try {
                                                  debugPrint(
                                                    '🎨 Iniciando proceso de guardado de paleta...',
                                                  );
                                                  debugPrint(
                                                    '📝 Nombre de la paleta: ${_paletteNameController.text}',
                                                  );
                                                  debugPrint(
                                                    '🖼️ URL de imagen: $_uploadedImageUrl',
                                                  );

                                                  // Si venimos de crear una paleta desde otra pantalla,
                                                  // asegurarnos de usar el nombre correcto
                                                  final paletteName =
                                                      _isCreatingPaletteFromExternal &&
                                                              _pendingPaletteName !=
                                                                  null
                                                          ? _pendingPaletteName!
                                                          : _paletteNameController
                                                              .text;

                                                  final paintsToSend =
                                                      modalColorList
                                                          .where(
                                                            (c) =>
                                                                c['paintName'] !=
                                                                null,
                                                          )
                                                          .map(
                                                            (c) => {
                                                              'id': c['paintId'],
                                                              'brand_id':
                                                                  c['brandId'],
                                                              'hex': c['hexCode'],
                                                              'name':
                                                                  c['paintName'],
                                                              'brand':
                                                                  c['paintBrand'],
                                                              'colorCode':
                                                                  c['colorCode'],
                                                              'barcode':
                                                                  c['barcode'],
                                                            },
                                                          )
                                                          .toList();

                                                  debugPrint(
                                                    '🎨 Pinturas seleccionadas: ${paintsToSend.length}',
                                                  );

                                                  final _colorSearchService =
                                                      ColorSearchService();
                                                  final token =
                                                      await FirebaseAuth
                                                          .instance
                                                          .currentUser
                                                          ?.getIdToken();

                                                  if (token == null) {
                                                    throw Exception(
                                                      'No se encontró el token de autenticación',
                                                    );
                                                  }

                                                  // Guardar una referencia al contexto actual antes de la operación asíncrona
                                                  final currentContext = context;
                                                  final scaffoldMessenger =
                                                      ScaffoldMessenger.of(
                                                        currentContext,
                                                      );

                                                  await _colorSearchService
                                                      .saveColorSearch(
                                                        token: token,
                                                        name: paletteName,
                                                        paints: paintsToSend,
                                                        imagePath:
                                                            _uploadedImageUrl ??
                                                            '',
                                                      );

                                                  // Verificar si el widget sigue montado después de la operación asíncrona
                                                  if (!mounted) return;

                                                  // Guardar cambios en el estado general antes de cerrar
                                                  setState(() {
                                                    _pickedColors = List.from(
                                                      modalColorList,
                                                    );
                                                  });

                                                  // Importante: Restaurar estado del modal antes de cerrarlo
                                                  if (context.mounted) {
                                                    setModalState(() {
                                                      _isSavingPalette = false;
                                                    });

                                                    // Cerrar el modal primero
                                                    Navigator.pop(context);
                                                    // ** ACAAAAAA
                                                    // Usar un post-frame callback para mostrar el snackbar y resetear
                                                    WidgetsBinding.instance.addPostFrameCallback((
                                                      _,
                                                    ) {
                                                      // Verificar si el contexto sigue montado antes de mostrar el snackbar
                                                      if (currentContext
                                                          .mounted) {
                                                        scaffoldMessenger
                                                            .showSnackBar(
                                                              SnackBar(
                                                                content: Text(
                                                                  'Color search "${_paletteNameController.text}" saved!',
                                                                ),
                                                              ),
                                                            );

                                                        // Resetear el estado después de un pequeño retraso
                                                        Future.delayed(
                                                          const Duration(
                                                            milliseconds: 100,
                                                          ),
                                                          () {
                                                            if (mounted) {
                                                              _reset();
                                                              // Refrescar el widget de paletas recientes
                                                              context
                                                                  .read<
                                                                    PaletteController
                                                                  >()
                                                                  .loadPalettes();
                                                            }
                                                          },
                                                        );
                                                      }
                                                    });
                                                  }
                                                } catch (e) {
                                                  debugPrint(
                                                    '❌ Error al guardar la paleta: $e',
                                                  );
                                                  if (context.mounted) {
                                                    setModalState(() {
                                                      _isSavingPalette = false;
                                                    });

                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          'Error al guardar: $e',
                                                        ),
                                                        backgroundColor:
                                                            Colors.red,
                                                      ),
                                                    );
                                                  }
                                                }
                                              }
                                            },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.marineBlue,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                    ),
                                    child:
                                        _isSavingPalette
                                            ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                            : const Text(
                                              'Save Palette',
                                              style: TextStyle(fontSize: 16),
                                            ),
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
              },
            );
          },
        );
      },
    );
  }

  // Nuevo método para seleccionar una pintura con diseño del primer componente
  Future<Map<String, dynamic>?> _selectPaint(
    BuildContext context,
    Map<String, dynamic> colorData,
  ) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final hexCode = colorData['hexCode'] as String;

    // Autenticación Firebase
    // final user = FirebaseAuth.instance.currentUser;
    // final token = await user?.getIdToken();
    // if (token == null || !context.mounted) {
      // if (context.mounted) {
        // ScaffoldMessenger.of(context).showSnackBar(
          // const SnackBar(content: Text('Authentication required')),
        // );
      // }
      // return null;
    // }

    // Filtrar marcas seleccionadas
    final brandIds =
        _paintBrands
            .where((b) => b['selected'] == true)
            .map((b) => b['id'] as String)
            .toList();
    if (brandIds.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one brand')),
        );
      }
      return null;
    }

    // Limpieza de hex para la API
    final cleanHex = hexCode.startsWith('#') ? hexCode.substring(1) : hexCode;

    try {
      // Fetch remoto
      final data = await PaintMatchService().fetchMatchingPaints(
        hexColor: cleanHex,
        brandIds: brandIds,
        page: 1,
      );
      if (!context.mounted) return null;

      final paints = data['paints'] as List<dynamic>;
      if (paints.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No matching paints found')),
        );
        return null;
      }

      // Variables de estado
      Map<String, dynamic>? selectedPaint;
      int? selectedIndex;

      // Modal con diseño de tarjetas
      final bool? confirmed = await showModalBottomSheet<bool>(
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
                builder: (_, scrollController) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
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
                              onPressed: () => Navigator.pop(context, false),
                            ),
                          ],
                        ),

                        // Color punto de referencia
                        Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: Color(
                                  int.parse(cleanHex, radix: 16) | 0xFF000000,
                                ),
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
                                isDarkMode
                                    ? Colors.grey[300]
                                    : Colors.grey[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Lista de tarjetas
                        Expanded(
                          child: ListView.builder(
                            controller: scrollController,
                            itemCount: paints.length,
                            itemBuilder: (_, i) {
                              final paint = paints[i] as Map<String, dynamic>;
                              final isSelected = selectedIndex == i;

                              // Normalizar hex de la pintura
                              String paintHex = (paint['hex'] as String)
                                  .replaceFirst('#', '')
                                  .padLeft(6, '0');
                              Color paintColor;
                              try {
                                paintColor = Color(
                                  int.parse(paintHex, radix: 16) | 0xFF000000,
                                );
                              } catch (_) {
                                paintColor = Colors.red;
                              }

                              return GestureDetector(
                                onTap:
                                    () => setModalState(() {
                                      if (isSelected) {
                                        selectedIndex = null;
                                        selectedPaint = null;
                                      } else {
                                        selectedIndex = i;
                                        selectedPaint = paint;
                                      }
                                    }),
                                child: Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    side: BorderSide(
                                      color:
                                          isSelected
                                              ? Colors.blue
                                              : (isDarkMode
                                                  ? Colors.grey[700]!
                                                  : Colors.grey[300]!),
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
                                      children: [
                                        // Fila principal: avatar, info, match y tick
                                        Row(
                                          children: [
                                            // Brand avatar
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
                                                  (paint['brand']['name']
                                                      as String)[0],
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

                                            // Nombre y marca
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    paint['name'] as String,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                      color:
                                                          isDarkMode
                                                              ? Colors.white
                                                              : Colors.black,
                                                    ),
                                                  ),
                                                  Text(
                                                    paint['brand']['name']
                                                        as String,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color:
                                                          isDarkMode
                                                              ? Colors.grey[400]
                                                              : Colors
                                                                  .grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            // Match percentage
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: _getMatchColor(
                                                  (paint['similarity']
                                                          as double)
                                                      .toInt(),
                                                ).withOpacity(0.2),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                '${(paint['similarity'] as double).toInt()}% match',
                                                style: TextStyle(
                                                  color: _getMatchColor(
                                                    (paint['similarity']
                                                            as double)
                                                        .toInt(),
                                                  ),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),

                                            // Ícono de seleccionado
                                            if (isSelected)
                                              const Padding(
                                                padding: EdgeInsets.only(
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

                                        const SizedBox(height: 8),

                                        // Sección color + barcode
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
                                              // Color swatch y code
                                              Row(
                                                children: [
                                                  Container(
                                                    width: 24,
                                                    height: 24,
                                                    decoration: BoxDecoration(
                                                      color: paintColor,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
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
                                                        paint['code'] as String,
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontFamily:
                                                              'monospace',
                                                          color:
                                                              isDarkMode
                                                                  ? Colors.white
                                                                  : Colors
                                                                      .black,
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
                                                  children: [
                                                    Text(
                                                      'Barcode:',
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
                                                    Row(
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
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        Flexible(
                                                          child: Text(
                                                            paint['barcode']
                                                                as String,
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 12,
                                                                  fontFamily:
                                                                      'monospace',
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

                        // Botón Confirmar
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed:
                                selectedPaint != null
                                    ? () => Navigator.pop(context, true)
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

      // Validar resultado
      if (!context.mounted || confirmed != true || selectedPaint == null) {
        return null;
      }

      // Procesar color de la pintura seleccionada
      String finalHex = (selectedPaint!['hex'] as String)
          .replaceFirst('#', '')
          .padLeft(6, '0');
      Color finalColor;
      try {
        finalColor = Color(int.parse(finalHex, radix: 16) | 0xFF000000);
      } catch (_) {
        finalColor = Colors.red;
      }

      // Retornar datos combinados
      return {
        ...colorData,
        'paintName': selectedPaint!['name'],
        'paintBrand': selectedPaint!['brand']['name'],
        'paintColor': finalColor,
        'brandAvatar': (selectedPaint!['brand']['name'] as String)[0],
        'matchPercentage': (selectedPaint!['similarity'] as double).toInt(),
        'colorCode': selectedPaint!['code'],
        'barcode': selectedPaint!['barcode'],
        'paintId': selectedPaint!['id'],
        'brandId': selectedPaint!['brand']['id'],
      };
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
      return null;
    }
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

  // Actualizar el método _buildColorSwatchItem para usar los logos
  Widget _buildColorSwatchItem(Map<String, dynamic> colorData, int index) {
    final color = colorData['color'] as Color;
    final hexCode = colorData['hexCode'] as String;
    final paintName = colorData['paintName'];
    final paintBrand = colorData['paintBrand'];
    final matchPercentage = colorData['matchPercentage'];
    final brandAvatar = colorData['brandAvatar'];
    final colorCode = colorData['colorCode'] as String?;
    final barcode = colorData['barcode'] as String?;
    final paintColor = colorData['paintColor'] as Color?;
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
                                  fontFamily: GoogleFonts.poppins().fontFamily,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
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
                                  fontFamily: GoogleFonts.poppins().fontFamily,
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
                      fontFamily: GoogleFonts.poppins().fontFamily,
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
                fontFamily: GoogleFonts.poppins().fontFamily,
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
                                  children: [
                                    if (brand['logoUrl'] != null)
                                      Container(
                                        height: 40,
                                        width: 40,
                                        margin: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        child: Image.network(
                                          brand['logoUrl'],
                                          fit: BoxFit.contain,
                                        ),
                                      )
                                    else
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor:
                                            brand['color'] as Color,
                                        child: Text(
                                          (brand['name'] as String)[0],
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
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

          // Actualizar el controlador del nombre de la paleta
          _paletteNameController.text = _pendingPaletteName!;

          // Activar directamente el flujo de búsqueda de colores
          setState(() {
            _showColorPicker = true;
          });
        }
      }
    }
  }

  // Widget para mostrar la tarjeta promocional de Warhammer 40,000: Paints + Tools Set
  Widget _buildPromotionCard(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Valores responsivos utilizando AppResponsive
    final cardHeight = AppResponsive.getAdaptiveValue(
      context: context,
      defaultValue: 180.0,
      mobile: 150.0,
    );

    final imageWidth = AppResponsive.getAdaptiveValue(
      context: context,
      defaultValue: 140.0,
      mobile: 120.0,
    );

    final contentPadding = AppResponsive.getAdaptiveValue(
      context: context,
      defaultValue: 16.0,
      mobile: 12.0,
    );

    final titleFontSize = AppResponsive.getAdaptiveFontSize(
      context,
      18.0,
      minFontSize: 16.0,
    );

    final subtitleFontSize = AppResponsive.getAdaptiveFontSize(
      context,
      16.0,
      minFontSize: 14.0,
    );

    final priceFontSize = AppResponsive.getAdaptiveFontSize(
      context,
      20.0,
      minFontSize: 18.0,
    );

    final oldPriceFontSize = AppResponsive.getAdaptiveFontSize(
      context,
      14.0,
      minFontSize: 12.0,
    );

    return GestureDetector(
      onTap: () {
        // Aquí puedes agregar alguna acción al tocar la promoción
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Warhammer 40,000 Paints + Tools Set promotion'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        height: cardHeight,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.marineBlueDark, AppTheme.marineBlue],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Fondo con efecto de resplandor en la esquina
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.marineGold.withOpacity(0.2),
                ),
              ),
            ),

            // Separador diagonal
            Positioned.fill(
              child: ClipPath(
                clipper: DiagonalClipper(),
                child: Container(color: Colors.black.withOpacity(0.15)),
              ),
            ),

            // Contenido
            Padding(
              padding: EdgeInsets.all(contentPadding),
              child: Row(
                children: [
                  // Imagen de la promoción con la imagen proporcionada
                  Container(
                    width: imageWidth,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        'https://www.games-workshop.com/resources/catalog/product/920x950/99170299029_WH40kPaintsTools01.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[800],
                            child: const Center(
                              child: Icon(
                                Icons.image_not_supported,
                                size: 40,
                                color: Colors.white54,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  SizedBox(width: contentPadding),

                  // Información del producto
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Etiqueta de promoción
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.marineGold,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'SPECIAL OFFER',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Título
                        Text(
                          'Warhammer 40,000',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: titleFontSize,
                          ),
                        ),

                        Text(
                          'Paints + Tools Set',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: subtitleFontSize,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Precio con descuento
                        Row(
                          children: [
                            Text(
                              '\$75.99',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                decoration: TextDecoration.lineThrough,
                                fontSize: oldPriceFontSize,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '\$59.99',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: priceFontSize,
                              ),
                            ),
                          ],
                        ),

                        // El botón "View Offer" ha sido eliminado
                      ],
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

  // Add this new method for showing paint details, ahora usando paletteInfo real
  void _showPaintDetailsModal(
    BuildContext context,
    Paint paint,
    List<PaletteInfo> paletteInfo,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final count = paletteInfo.length;
        return Container(
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1E2229) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // → Encabezado
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Paint Details',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: isDarkMode ? Colors.white : Colors.black54,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  Divider(
                    color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                  ),
                  const SizedBox(height: 16),

                  // → Nombre y marca
                  Text(
                    paint.name,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  Text(
                    paint.brand,
                    style: TextStyle(
                      fontSize: 20,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),

                  const SizedBox(height: 24),
                  // → Color code
                  Row(
                    children: [
                      Text(
                        'Color Code:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[700],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        paint.hex,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                  // → Conteo real
                  Text(
                    'Used in $count palette${count == 1 ? '' : 's'}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 16),
                  // → Si no hay paletas
                  if (count == 0)
                    Center(
                      child: Text(
                        'This paint hasn\'t been used in any palette yet.',
                        style: TextStyle(
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    )
                  else
                    // → Iteramos lista real
                    for (final info in paletteInfo)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Color(
                                  int.parse(paint.hex.substring(1), radix: 16) |
                                      0xFF000000,
                                ).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Icon(Icons.palette, size: 20),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    info.name,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color:
                                          isDarkMode
                                              ? Colors.white
                                              : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${info.createdAt.year}-'
                                    '${info.createdAt.month.toString().padLeft(2, '0')}-'
                                    '${info.createdAt.day.toString().padLeft(2, '0')}',
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
                          ],
                        ),
                      ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Método para abrir el modal de añadir a wishlist
  void _showAddToWishlistModal(BuildContext context, Paint paint) {
    AddToWishlistModal.show(
      context: context,
      paint: paint,
      onAddToWishlist: (paint, priority, _) async {
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        final paintService = PaintService();

        // Show loading indicator
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
                SizedBox(width: 16),
                Text('Adding to wishlist...'),
              ],
            ),
            duration: Duration(seconds: 10),
            behavior: SnackBarBehavior.floating,
          ),
        );

        try {
          // Get current Firebase user
          final firebaseUser = FirebaseAuth.instance.currentUser;
          if (firebaseUser == null) {
            // Show error if not logged in
            scaffoldMessenger.hideCurrentSnackBar();
            scaffoldMessenger.showSnackBar(
              const SnackBar(
                content: Text('You need to be logged in to add to wishlist'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }

          final userId = firebaseUser.uid;

          // Call API directly
          final result = await paintService.addToWishlistDirect(
            paint,
            priority,
            userId,
          );

          scaffoldMessenger.hideCurrentSnackBar();

          if (result['success'] == true) {
            // Determine the correct message based on if the paint was already in the wishlist
            final String message =
                result['alreadyExists'] == true
                    ? '${paint.name} is already in your wishlist'
                    : 'Added ${paint.name} to wishlist${priority > 0 ? " with priority $priority" : ""}';

            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: Colors.green,
                action: SnackBarAction(
                  label: 'VIEW',
                  textColor: Colors.white,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WishlistScreen(),
                      ),
                    );
                  },
                ),
              ),
            );
          } else {
            // Show error with details
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text('Error: ${result['message']}'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        } catch (e) {
          scaffoldMessenger.hideCurrentSnackBar();
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      },
    );
  }

  // Método para abrir el modal de añadir al inventario
  void _showAddToInventoryModal(BuildContext context, Paint paint) {
    AddToInventoryModal.show(
      context: context,
      paint: paint,
      onAddToInventory: (paint, quantity, notes, _) {
        // Aquí manejamos la lógica para añadir al inventario
        // Por ahora solo mostramos un mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added $quantity ${paint.name} to inventory'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'VIEW',
              textColor: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const InventoryScreen(),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadPaintBrands() async {
    print('🔄 Iniciando carga de marcas de pinturas en PaintListTab...');
    try {
      print('📱 Llamando a PaintBrandService.getPaintBrands()');
      final brands = await _paintBrandService.getPaintBrands();
      print('✅ Recibidas ${brands.length} marcas de pinturas del servicio');

      final mappedBrands =
          brands
              .map(
                (brand) => {
                  'id': brand.id,
                  'name': brand.name,
                  'logoUrl': brand.logoUrl,
                  'selected': false,
                  'color': _getBrandColor(brand.name),
                  'paintCount': brand.paintCount,
                },
              )
              .toList();

      print('🎨 Mapped brands para UI:');
      for (var i = 0; i < min(5, mappedBrands.length); i++) {
        final brand = mappedBrands[i];
        print(
          '  • ${brand['name']}: ${brand['paintCount']} paints, ID: ${brand['id']}',
        );
      }

      // Ordenar por contador (descendente)
      mappedBrands.sort(
        (a, b) => (b['paintCount'] as int).compareTo(a['paintCount'] as int),
      );
      print('📋 Marcas ordenadas por cantidad de pinturas (descendente)');

      setState(() {
        _paintBrands = mappedBrands;

        // Log del total de pinturas que se mostrarán en la UI
        final totalPaints = _paintBrands.fold(
          0,
          (sum, brand) => sum + (brand['paintCount'] as int),
        );
        print('🔢 Total de pinturas en todas las marcas: $totalPaints');
        print(
          '🎭 Mostrando ${_paintBrands.length} marcas en la sección de categorías',
        );
      });
    } catch (e) {
      print('❌ Error cargando marcas de pinturas: $e');
      print('⚠️ Usando datos de fallback para las marcas');
      // Fallback a marcas por defecto en caso de error
      setState(() {
        _paintBrands = [
          {
            'id': 'citadel',
            'name': 'Citadel',
            'color': AppTheme.primaryBlue,
            'selected': false,
            'logoUrl': null,
            'paintCount': 0,
          },
          {
            'id': 'vallejo',
            'name': 'Vallejo',
            'color': AppTheme.pinkColor,
            'selected': false,
            'logoUrl': null,
            'paintCount': 0,
          },
          {
            'id': 'army_painter',
            'name': 'Army Painter',
            'color': AppTheme.purpleColor,
            'selected': false,
            'logoUrl': null,
            'paintCount': 0,
          },
          {
            'id': 'scale75',
            'name': 'Scale75',
            'color': AppTheme.orangeColor,
            'selected': false,
            'logoUrl': null,
            'paintCount': 0,
          },
        ];
      });
    }
  }

  Color _getBrandColor(String brandName) {
    switch (brandName.toLowerCase()) {
      case 'ak interactive':
        return const Color(0xFF003366); // Un azul oscuro
      case 'apple barrel':
        return const Color(0xFFFF7043); // Naranja brillante
      case 'the army painter':
      case 'army painter':
        return AppTheme.purpleColor; // Púrpura (según lo asignado previamente)
      case 'arteza':
        return const Color(0xFF009688); // Un tono teal
      case 'citadel colour':
        return AppTheme.primaryBlue; // Azul primario para Citadel
      case 'coat d\'arms':
      case 'coat darms':
        return const Color(0xFF424242); // Gris oscuro
      case 'creature caster':
        return const Color(0xFF4CAF50); // Verde (un tono fresco)
      case 'folkart':
        return const Color(0xFFFFC107); // Amarillo mostaza
      case 'wargames foundry':
        return const Color(0xFF9E9E9E); // Gris medio (industrial)
      case 'golden artist colors':
        return const Color(0xFFFFD700); // Dorado
      case 'green stuff world':
        return const Color(0xFF8BC34A); // Verde vibrante
      case 'humbrol':
        return const Color(0xFF43A047); // Verde oscurecido
      case 'italeri':
        return const Color(0xFF1565C0); // Azul intenso
      case 'kimera kolors':
        return const Color(0xFFE91E63); // Rosa o fucsia
      case 'liquitex':
        return const Color(0xFFD32F2F); // Rojo intenso
      case 'ammo by mig jimenez':
        return const Color(0xFF283593); // Azul con matices profundos
      case 'monument hobbies':
        return const Color(0xFF00796B); // Azul-verde oscuro
      case 'formula p3':
        return const Color(0xFFFF9800); // Naranja
      case 'pantone':
        return const Color(0xFF0A74DA); // Azul característico de Pantone
      case 'ral colours':
      case 'ral':
        return const Color(0xFF757575); // Gris estándar
      case 'reaper miniatures':
      case 'reaper':
        return const Color(0xFF212121); // Negro/gris muy oscuro
      case 'revell':
        return const Color(0xFFB71C1C); // Rojo oscuro, casi burdeos
      case 'scale75':
        return AppTheme
            .orangeColor; // Usamos el valor que ya teníamos para Scale75
      case 'tamiya':
        return const Color(0xFFFFEB3B); // Amarillo brillante (típico de Tamiya)
      case 'vallejo':
        return const Color(0xFFFF4081); // Un rosa fuerte
      case 'warcolours':
        return const Color(0xFFD50000); // Rojo vibrante
      default:
        return AppTheme.marineBlue; // Color por defecto
    }
  }

  // Nuevo método para mostrar todas las categorías en un modal
  void _showAllCategoriesModal(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header con título y botón de cierre
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'All Paint Brands',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),

                  // Información de actualización
                  Row(
                    children: [
                      Text(
                        'Showing all ${_paintBrands.length} paint brands',
                        style: TextStyle(
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[700],
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text(
                          'Refresh',
                          style: TextStyle(fontSize: 14),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _refreshPaintBrands();
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Divisor
                  Divider(
                    color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                  ),

                  // Lista de todas las categorías
                  Expanded(
                    child: GridView.builder(
                      controller: scrollController,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 2.5,
                          ),
                      itemCount: _paintBrands.length,
                      itemBuilder: (context, index) {
                        final brand = _paintBrands[index];
                        final paintCount = brand['paintCount'] as int;

                        return CategoryCard(
                          title: brand['name'] as String,
                          count: paintCount,
                          color: brand['color'] as Color,
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(
                              context,
                              '/library',
                              arguments: {'brandName': brand['id']},
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Método para forzar la actualización de las marcas
  Future<void> _refreshPaintBrands() async {
    setState(() {
      _paintBrands = []; // Vaciar para mostrar el cargador
    });

    try {
      final brands = await _paintBrandService.refreshPaintBrands();

      print('✅ Marcas actualizadas correctamente: ${brands.length} marcas');

      final mappedBrands =
          brands
              .map(
                (brand) => {
                  'id': brand.id,
                  'name': brand.name,
                  'logoUrl': brand.logoUrl,
                  'selected': false,
                  'color': _getBrandColor(brand.name),
                  'paintCount': brand.paintCount,
                },
              )
              .toList();

      setState(() {
        _paintBrands = mappedBrands;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Categories refreshed successfully'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('❌ Error al actualizar marcas: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating categories: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _loadMostUsedPaints() async {
    setState(() {
      _isLoadingMostUsed = true;
      _mostUsedError = null;
    });

    // Check if user is a guest
    final currentUser = FirebaseAuth.instance.currentUser;
    final isGuestUser = currentUser == null || currentUser.isAnonymous;

    if (isGuestUser) {
      // For guest users, don't try to load data
      setState(() {
        _isLoadingMostUsed = false;
        _mostUsedPaints = null; // Keep it null to show the guest UI
      });
      return;
    }

    try {
      final token = await currentUser!.getIdToken();
      _mostUsedPaints = await _paletteService.getMostUsedPaints(
        token as String,
      );
    } catch (e) {
      _mostUsedError = e.toString();
    } finally {
      setState(() => _isLoadingMostUsed = false);
    }
  }

  // Build Most Used Paints section with guest user handling
  Widget _buildMostUsedPaintsSection(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final currentUser = FirebaseAuth.instance.currentUser;
    final isGuestUser = currentUser == null || currentUser.isAnonymous;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your most used paints',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),

        if (isGuestUser)
          // Guest user UI
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[850] : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 48,
                  color:
                      isDarkMode ? AppTheme.marineOrange : AppTheme.marineBlue,
                ),
                const SizedBox(height: 12),
                Text(
                  'Track your most used paints',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create a free account to see which paints you use most across your palettes',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    final authService = Provider.of<IAuthService>(context, listen: false);
                    await authService.signOut();
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/',
                      (route) => false,
                      arguments: {'showRegistration': true},
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDarkMode
                            ? AppTheme.marineOrange
                            : AppTheme.marineBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Sign Up - It\'s Free!'),
                ),
              ],
            ),
          )
        else if (_isLoadingMostUsed)
          const Center(child: CircularProgressIndicator())
        else if (_mostUsedError != null)
          Center(child: Text('Error: $_mostUsedError'))
        else if (_mostUsedPaints == null || _mostUsedPaints!.isEmpty)
          const Center(child: Text('No paints found.'))
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _mostUsedPaints!.length,
            itemBuilder: (ctx, i) {
              final m = _mostUsedPaints![i];
              // Convertimos MostUsedPaint → Paint para usar PaintCard
              final paint = Paint.fromHex(
                id: m.paintId,
                name: m.paint.name,
                brand: m.brand.name,
                hex: m.paint.hex,
                set: m.paint.set,
                code: m.paint.code,
                category: m.paint.set,
                isMetallic: false,
                isTransparent: false,
              );
              return PaintCard(
                paint: paint,
                paletteCount: m.count,
                paletteInfo: m.paletteInfo,
                inInventory: m.inInventory,
                inWishlist: m.inWhitelist,
                inventoryId: m.inventoryId,
                wishlistId: m.wishlistId,
                onTap: (p, pInfo) => _showPaintDetailsModal(context, p, pInfo),
              );
            },
          ),
      ],
    );
  }
}
